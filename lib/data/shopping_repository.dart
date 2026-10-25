import 'package:drift/drift.dart';

import '../domain/backup_codec.dart';
import '../domain/backup_reminder.dart';
import '../domain/errors.dart';
import '../domain/models.dart';
import '../domain/name_rules.dart';
import '../domain/name_rules.dart' as name_rules show suggestCopyName;
import '../domain/ordering.dart';
import 'database.dart';

/// Fronteira entre a UI e o banco (specs/001-supermarket-lists/contracts/repository.md).
class ShoppingRepository {
  ShoppingRepository(this._db, this._now);

  final AppDatabase _db;
  final DateTime Function() _now;

  // ---------------------------------------------------------------- Leitura

  Stream<ListsOverview> watchLists() {
    return _db
        .customSelect(
          'SELECT l.id, l.name, l.position, '
          '(SELECT COUNT(*) FROM shopping_items i WHERE i.list_id = l.id) AS total, '
          '(SELECT COUNT(*) FROM shopping_items i '
          'WHERE i.list_id = l.id AND i.checked_seq IS NOT NULL) AS checked, '
          '(SELECT active_list_id FROM app_settings WHERE id = 1) AS active_id '
          'FROM shopping_lists l ORDER BY l.position',
          readsFrom: {_db.shoppingLists, _db.shoppingItems, _db.appSettings},
        )
        .watch()
        .map((rows) {
          ShoppingList? active;
          final others = <ShoppingList>[];
          for (final row in rows) {
            final list = ShoppingList(
              id: row.read<int>('id'),
              name: row.read<String>('name'),
              position: row.read<int>('position'),
              totalItems: row.read<int>('total'),
              checkedItems: row.read<int>('checked'),
            );
            if (row.readNullable<int>('active_id') == list.id) {
              active = list;
            } else {
              others.add(list);
            }
          }
          return ListsOverview(active: active, others: others);
        });
  }

  /// Uma lista com seus totais; `null` se ela não existir mais.
  Stream<ShoppingList?> watchList(int listId) => watchLists().map((overview) {
    if (overview.active?.id == listId) return overview.active;
    for (final list in overview.others) {
      if (list.id == listId) return list;
    }
    return null;
  });

  Stream<int?> watchActiveListId() => _db
      .select(_db.appSettings)
      .watchSingle()
      .map((settings) => settings.activeListId);

  /// Itens na ordem de exibição: não comprados, depois comprados.
  Stream<List<ShoppingItem>> watchItems(int listId) =>
      (_db.select(_db.shoppingItems)..where((i) => i.listId.equals(listId)))
          .watch()
          .map((rows) => displayOrder(rows.map(_toItem)));

  // ----------------------------------------------------------------- Listas

  Future<int> createList(String rawName) async {
    final name = validateName(rawName);
    return _write(() async {
      await _ensureUniqueListName(name);
      final id = await _db
          .into(_db.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              name: name,
              nameKey: normalizeKey(name),
              position: await _nextListPosition(),
            ),
          );
      if ((await _settings()).activeListId == null) {
        await _updateSettings(AppSettingsCompanion(activeListId: Value(id)));
      }
      return id;
    });
  }

  /// "X (cópia)", ou "X (cópia N)" se já existir (FR-004).
  Future<String> suggestCopyName(int listId) async {
    final lists = await _db.select(_db.shoppingLists).get();
    final original = lists.firstWhere((l) => l.id == listId);
    return name_rules.suggestCopyName(original.name, {
      for (final list in lists) list.nameKey,
    });
  }

  /// Nova lista com os mesmos itens, na ordem original e todos desmarcados;
  /// entra no fim e não muda a lista ativa (FR-005, FR-006).
  Future<int> copyList(int listId, String rawName) async {
    final name = validateName(rawName);
    return _write(() async {
      await _ensureUniqueListName(name);
      final copyId = await _db
          .into(_db.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              name: name,
              nameKey: normalizeKey(name),
              position: await _nextListPosition(),
            ),
          );
      final items = (await _itemsOf(listId))
        ..sort((a, b) => a.position.compareTo(b.position));
      for (final (index, item) in items.indexed) {
        await _db
            .into(_db.shoppingItems)
            .insert(
              ShoppingItemsCompanion.insert(
                listId: copyId,
                name: item.name,
                nameKey: normalizeKey(item.name),
                quantity: Value(item.quantity),
                position: index,
              ),
            );
      }
      return copyId;
    });
  }

  /// Mudar só maiúsculas/minúsculas do próprio nome é permitido.
  Future<void> renameList(int listId, String rawName) async {
    final name = validateName(rawName);
    await _write(() async {
      await _ensureUniqueListName(name, exceptId: listId);
      await (_db.update(
        _db.shoppingLists,
      )..where((l) => l.id.equals(listId))).write(
        ShoppingListsCompanion(
          name: Value(name),
          nameKey: Value(normalizeKey(name)),
        ),
      );
    });
  }

  /// Apaga a lista e seus itens (CASCADE); se era a ativa, nenhuma fica
  /// ativa (SET NULL).
  Future<void> deleteList(int listId) => _write(() async {
    await (_db.delete(
      _db.shoppingLists,
    )..where((l) => l.id.equals(listId))).go();
  });

  /// Torna [listId] a única lista ativa (FR-007).
  Future<void> activateList(int listId) => _write(
    () => _updateSettings(AppSettingsCompanion(activeListId: Value(listId))),
  );

  /// Índices dentro das listas não ativas, com [newIndex] já final; a ativa
  /// conserva seu slot (FR-011).
  Future<void> reorderInactiveLists(int oldIndex, int newIndex) =>
      _write(() async {
        if (oldIndex == newIndex) return;
        await _reorderLists(oldIndex, newIndex);
      });

  /// Sobe (`-1`) ou desce (`+1`) uma lista não ativa (FR-025).
  Future<void> moveList(int listId, int delta) => _write(() async {
    final activeId = (await _settings()).activeListId;
    if (listId == activeId) return;
    final inactive = [
      for (final list in await _listsByPosition())
        if (list.id != activeId) list.id,
    ];
    final index = inactive.indexOf(listId);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= inactive.length) return;
    await _reorderLists(index, target);
  });

  // ------------------------------------------------------------------ Itens

  Future<int> addItem(int listId, String rawName, {String? quantity}) async {
    final name = validateName(rawName);
    final normalizedQuantity = normalizeQuantity(quantity);
    return _write(isItem: true, () async {
      await _ensureUniqueItemName(listId, name);
      return _db
          .into(_db.shoppingItems)
          .insert(
            ShoppingItemsCompanion.insert(
              listId: listId,
              name: name,
              nameKey: normalizeKey(name),
              quantity: Value(normalizedQuantity),
              position: await _nextItemPosition(listId),
            ),
          );
    });
  }

  /// Muda nome e quantidade; posição e estado de comprado não mudam.
  Future<void> editItem(int itemId, String rawName, {String? quantity}) async {
    final name = validateName(rawName);
    final normalizedQuantity = normalizeQuantity(quantity);
    await _write(isItem: true, () async {
      final item = await _itemRow(itemId);
      await _ensureUniqueItemName(item.listId, name, exceptId: itemId);
      await (_db.update(
        _db.shoppingItems,
      )..where((i) => i.id.equals(itemId))).write(
        ShoppingItemsCompanion(
          name: Value(name),
          nameKey: Value(normalizeKey(name)),
          quantity: Value(normalizedQuantity),
        ),
      );
    });
  }

  /// Apaga o item e devolve o que é preciso para desfazer.
  Future<DeletedItem> deleteItem(int itemId) => _write(() async {
    final item = await _itemRow(itemId);
    await (_db.delete(
      _db.shoppingItems,
    )..where((i) => i.id.equals(itemId))).go();
    return DeletedItem(
      listId: item.listId,
      name: item.name,
      quantity: item.quantity,
      position: item.position,
      checkedSeq: item.checkedSeq,
    );
  });

  /// Reinsere um item apagado no mesmo slot e com o mesmo estado.
  Future<void> restoreItem(DeletedItem deleted) =>
      _write(isItem: true, () async {
        await _ensureUniqueItemName(deleted.listId, deleted.name);
        final taken =
            await (_db.select(_db.shoppingItems)..where(
                  (i) =>
                      i.listId.equals(deleted.listId) &
                      i.position.equals(deleted.position),
                ))
                .get();
        if (taken.isNotEmpty) {
          // O slot foi ocupado depois da remoção: abre espaço.
          await _db.customUpdate(
            'UPDATE shopping_items SET position = position + 1 '
            'WHERE list_id = ? AND position >= ?',
            variables: [
              Variable.withInt(deleted.listId),
              Variable.withInt(deleted.position),
            ],
            updates: {_db.shoppingItems},
          );
        }
        await _db
            .into(_db.shoppingItems)
            .insert(
              ShoppingItemsCompanion.insert(
                listId: deleted.listId,
                name: deleted.name,
                nameKey: normalizeKey(deleted.name),
                quantity: Value(deleted.quantity),
                position: deleted.position,
                checkedSeq: Value(deleted.checkedSeq),
              ),
            );
      });

  /// [oldIndex] e [newIndex] são índices entre os não comprados, e
  /// [newIndex] já é o índice final do item. Os comprados mantêm seus slots.
  Future<void> reorderUncheckedItems(int listId, int oldIndex, int newIndex) =>
      _write(() async {
        if (oldIndex == newIndex) return;
        await _reorderItems(listId, oldIndex, newIndex);
      });

  /// Sobe (`-1`) ou desce (`+1`) um item não comprado; alternativa acessível
  /// ao arraste (FR-025). Nos limites, ou se o item estiver comprado, nada
  /// acontece.
  Future<void> moveItem(int itemId, int delta) => _write(() async {
    final item = await _itemRow(itemId);
    if (item.checkedSeq != null) return;
    final unchecked = displayOrder(await _itemsOf(item.listId))
        .where((i) => !i.isChecked)
        .toList();
    final index = unchecked.indexWhere((i) => i.id == itemId);
    final target = index + delta;
    if (target < 0 || target >= unchecked.length) return;
    await _reorderItems(item.listId, index, target);
  });

  /// Marcar manda o item para o fim; desmarcar o devolve ao seu slot.
  Future<void> toggleChecked(int itemId) => _write(() async {
    final item = await _itemRow(itemId);
    final int? checkedSeq;
    if (item.checkedSeq != null) {
      checkedSeq = null;
    } else {
      checkedSeq = nextCheckedSeq(await _itemsOf(item.listId));
    }
    await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(itemId)))
        .write(ShoppingItemsCompanion(checkedSeq: Value(checkedSeq)));
  });

  /// Todos desmarcados; cada item volta ao seu slot original (FR-021).
  Future<void> uncheckAll(int listId) => _write(() async {
    await (_db.update(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId) & i.checkedSeq.isNotNull()))
        .write(const ShoppingItemsCompanion(checkedSeq: Value(null)));
  });

  // ----------------------------------------------------------------- Backup

  /// Lembrete de backup (research.md R12), reavaliado a cada alteração.
  Stream<bool> watchBackupReminder() => _db
      .select(_db.appSettings)
      .watchSingle()
      .map(
        (s) => shouldShowReminder(
          now: _now(),
          lastBackupAt: s.lastBackupAt,
          lastChangeAt: s.lastChangeAt,
          snoozedUntil: s.backupReminderSnoozedUntil,
        ),
      );

  /// Todos os dados no formato de contracts/backup-file.md.
  Future<Uint8List> exportBackup() async {
    final lists = await _listsByPosition();
    final activeId = (await _settings()).activeListId;
    final items = await (_db.select(
      _db.shoppingItems,
    )..orderBy([(i) => OrderingTerm.asc(i.position)])).get();
    return encodeBackup(
      BackupData(
        exportedAt: _now(),
        activeListIndex: activeId == null
            ? null
            : lists.indexWhere((l) => l.id == activeId),
        lists: [
          for (final list in lists)
            BackupList(
              name: list.name,
              position: list.position,
              items: [
                for (final item in items)
                  if (item.listId == list.id)
                    BackupItem(
                      name: item.name,
                      quantity: item.quantity,
                      position: item.position,
                      checkedSeq: item.checkedSeq,
                    ),
              ],
            ),
        ],
      ),
    );
  }

  /// Chamado depois que o arquivo foi salvo com sucesso. Não conta como
  /// alteração dos dados.
  Future<void> markBackupDone() =>
      _updateSettings(AppSettingsCompanion(lastBackupAt: Value(_now())));

  /// Valida o arquivo sem tocar no banco (FR-033).
  BackupData parseBackup(Uint8List bytes) => decodeBackup(bytes);

  /// Substitui todos os dados numa única transação (FR-032, FR-033). Os
  /// dados restaurados equivalem a um backup recém-feito, então o lembrete
  /// não aparece logo depois.
  Future<void> importBackup(BackupData data) => _db.transaction(() async {
    await _db.delete(_db.shoppingLists).go();
    int? activeId;
    for (final (index, list) in data.lists.indexed) {
      final listId = await _db
          .into(_db.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              name: list.name,
              nameKey: normalizeKey(list.name),
              position: list.position,
            ),
          );
      if (index == data.activeListIndex) activeId = listId;
      for (final item in list.items) {
        await _db
            .into(_db.shoppingItems)
            .insert(
              ShoppingItemsCompanion.insert(
                listId: listId,
                name: item.name,
                nameKey: normalizeKey(item.name),
                quantity: Value(item.quantity),
                position: item.position,
                checkedSeq: Value(item.checkedSeq),
              ),
            );
      }
    }
    final now = _now();
    await _updateSettings(
      AppSettingsCompanion(
        activeListId: Value(activeId),
        lastBackupAt: Value(now),
        lastChangeAt: Value(now),
        backupReminderSnoozedUntil: const Value(null),
      ),
    );
  });

  /// Adia o lembrete por mais 7 dias (FR-034).
  Future<void> snoozeBackupReminder() => _updateSettings(
    AppSettingsCompanion(
      backupReminderSnoozedUntil: Value(_now().add(backupReminderInterval)),
    ),
  );

  // --------------------------------------------------------------- Internos

  /// Roda [action] numa transação e registra a alteração em `lastChangeAt`.
  /// Violações de nome único que escaparem das validações viram
  /// [DuplicateNameException].
  Future<T> _write<T>(
    Future<T> Function() action, {
    bool isItem = false,
  }) async {
    try {
      return await _db.transaction(() async {
        final result = await action();
        await _updateSettings(
          AppSettingsCompanion(lastChangeAt: Value(_now())),
        );
        return result;
      });
    } catch (e) {
      if (e is! DomainException &&
          e.toString().contains('UNIQUE constraint failed')) {
        throw isItem
            ? const DuplicateNameException.item()
            : const DuplicateNameException.list();
      }
      rethrow;
    }
  }

  Future<SettingsRow> _settings() => _db.select(_db.appSettings).getSingle();

  Future<void> _updateSettings(AppSettingsCompanion changes) =>
      _db.update(_db.appSettings).write(changes);

  Future<void> _ensureUniqueListName(String name, {int? exceptId}) async {
    final query = _db.select(_db.shoppingLists)
      ..where((l) => l.nameKey.equals(normalizeKey(name)));
    if (exceptId != null) query.where((l) => l.id.equals(exceptId).not());
    if (await query.get().then((rows) => rows.isNotEmpty)) {
      throw const DuplicateNameException.list();
    }
  }

  Future<void> _ensureUniqueItemName(
    int listId,
    String name, {
    int? exceptId,
  }) async {
    final query = _db.select(_db.shoppingItems)
      ..where(
        (i) => i.listId.equals(listId) & i.nameKey.equals(normalizeKey(name)),
      );
    if (exceptId != null) query.where((i) => i.id.equals(exceptId).not());
    if (await query.get().then((rows) => rows.isNotEmpty)) {
      throw const DuplicateNameException.item();
    }
  }

  Future<int> _nextListPosition() async {
    final max = _db.shoppingLists.position.max();
    final row = await (_db.selectOnly(
      _db.shoppingLists,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<int> _nextItemPosition(int listId) async {
    final max = _db.shoppingItems.position.max();
    final row =
        await (_db.selectOnly(_db.shoppingItems)
              ..addColumns([max])
              ..where(_db.shoppingItems.listId.equals(listId)))
            .getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<List<ListRow>> _listsByPosition() => (_db.select(
    _db.shoppingLists,
  )..orderBy([(l) => OrderingTerm.asc(l.position)])).get();

  Future<void> _reorderLists(int oldIndex, int newIndex) async {
    final activeId = (await _settings()).activeListId;
    final positions = reorderIntoSlots(
      idsByPosition: [for (final list in await _listsByPosition()) list.id],
      isMovable: (id) => id != activeId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    for (final MapEntry(key: id, value: position) in positions.entries) {
      await (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id)))
          .write(ShoppingListsCompanion(position: Value(position)));
    }
  }

  Future<void> _reorderItems(int listId, int oldIndex, int newIndex) async {
    final items = (await _itemsOf(listId))
      ..sort((a, b) => a.position.compareTo(b.position));
    final unchecked = {
      for (final item in items)
        if (!item.isChecked) item.id,
    };
    final positions = reorderIntoSlots(
      idsByPosition: [for (final item in items) item.id],
      isMovable: unchecked.contains,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    for (final MapEntry(key: id, value: position) in positions.entries) {
      await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id)))
          .write(ShoppingItemsCompanion(position: Value(position)));
    }
  }

  Future<ItemRow> _itemRow(int itemId) => (_db.select(
    _db.shoppingItems,
  )..where((i) => i.id.equals(itemId))).getSingle();

  Future<List<ShoppingItem>> _itemsOf(int listId) async => (await (_db.select(
    _db.shoppingItems,
  )..where((i) => i.listId.equals(listId))).get()).map(_toItem).toList();

  ShoppingItem _toItem(ItemRow row) => ShoppingItem(
    id: row.id,
    listId: row.listId,
    name: row.name,
    quantity: row.quantity,
    position: row.position,
    checkedSeq: row.checkedSeq,
  );
}
