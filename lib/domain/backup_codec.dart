import 'dart:convert';
import 'dart:typed_data';

import 'errors.dart';
import 'name_rules.dart';

/// Arquivo de backup (specs/001-supermarket-lists/contracts/backup-file.md).
const backupFormat = 'supermarket-list-backup';
const backupVersion = 1;

class BackupData {
  const BackupData({
    required this.exportedAt,
    required this.activeListIndex,
    required this.lists,
  });

  final DateTime exportedAt;

  /// Índice em [lists] da lista ativa, ou `null`.
  final int? activeListIndex;
  final List<BackupList> lists;
}

class BackupList {
  const BackupList({
    required this.name,
    required this.position,
    required this.items,
  });

  final String name;
  final int position;
  final List<BackupItem> items;
}

class BackupItem {
  const BackupItem({
    required this.name,
    required this.position,
    this.quantity,
    this.checkedSeq,
  });

  final String name;
  final String? quantity;
  final int position;
  final int? checkedSeq;
}

Uint8List encodeBackup(BackupData data) {
  final json = {
    'format': backupFormat,
    'version': backupVersion,
    'exportedAt': data.exportedAt.toUtc().toIso8601String(),
    'activeListIndex': data.activeListIndex,
    'lists': [
      for (final list in data.lists)
        {
          'name': list.name,
          'position': list.position,
          'items': [
            for (final item in list.items)
              {
                'name': item.name,
                'quantity': item.quantity,
                'position': item.position,
                'checkedSeq': item.checkedSeq,
              },
          ],
        },
    ],
  };
  return Uint8List.fromList(
    utf8.encode(const JsonEncoder.withIndent('  ').convert(json)),
  );
}

/// Valida o arquivo inteiro sem tocar no banco. Qualquer problema vira
/// [InvalidBackupException]. As listas voltam ordenadas por `position`, com
/// `position` e `checkedSeq` renumerados de forma compacta.
BackupData decodeBackup(Uint8List bytes) {
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw const InvalidBackupException(_notABackup);
  }
  if (json is! Map<String, dynamic> || json['format'] != backupFormat) {
    throw const InvalidBackupException(_notABackup);
  }

  final version = _field<int>(json, 'version');
  if (version > backupVersion) {
    throw const InvalidBackupException(
      'Este backup foi criado por uma versão mais nova do app. '
      'Atualize o app para importá-lo.',
    );
  }
  if (version < 1) throw const InvalidBackupException(_corrupted);

  _field<String>(json, 'exportedAt');
  final exportedAt = DateTime.tryParse(json['exportedAt'] as String);
  if (exportedAt == null) throw const InvalidBackupException(_corrupted);

  final rawLists = _field<List<dynamic>>(json, 'lists');
  final activeIndex = _nullableField<int>(json, 'activeListIndex');
  if (activeIndex != null &&
      (activeIndex < 0 || activeIndex >= rawLists.length)) {
    throw const InvalidBackupException(_corrupted);
  }

  final lists = [for (final raw in rawLists) _decodeList(raw)];
  _ensureUnique(
    lists.map((l) => l.name),
    'O backup tem listas com nomes repetidos.',
  );

  // Ordena por position mantendo a referência da lista ativa.
  final active = activeIndex == null ? null : lists[activeIndex];
  final ordered = [...lists]..sort((a, b) => a.position.compareTo(b.position));
  return BackupData(
    exportedAt: exportedAt,
    activeListIndex: active == null ? null : ordered.indexOf(active),
    lists: [
      for (final (index, list) in ordered.indexed)
        BackupList(name: list.name, position: index, items: list.items),
    ],
  );
}

const _notABackup = 'Este arquivo não é um backup das listas de supermercado.';
const _corrupted = 'O arquivo de backup está incompleto ou corrompido.';

BackupList _decodeList(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    throw const InvalidBackupException(_corrupted);
  }
  final name = _validName(_field<String>(raw, 'name'));
  final position = _field<int>(raw, 'position');
  if (position < 0) throw const InvalidBackupException(_corrupted);
  final items = [
    for (final item in _field<List<dynamic>>(raw, 'items')) _decodeItem(item),
  ];
  _ensureUnique(
    items.map((i) => i.name),
    'O backup tem itens repetidos na lista "$name".',
  );

  items.sort((a, b) => a.position.compareTo(b.position));
  final checked = items.where((i) => i.checkedSeq != null).toList()
    ..sort((a, b) => a.checkedSeq!.compareTo(b.checkedSeq!));
  return BackupList(
    name: name,
    position: position,
    items: [
      for (final (index, item) in items.indexed)
        BackupItem(
          name: item.name,
          quantity: item.quantity,
          position: index,
          checkedSeq: item.checkedSeq == null
              ? null
              : checked.indexOf(item) + 1,
        ),
    ],
  );
}

BackupItem _decodeItem(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    throw const InvalidBackupException(_corrupted);
  }
  final name = _validName(_field<String>(raw, 'name'));
  final position = _field<int>(raw, 'position');
  final checkedSeq = _nullableField<int>(raw, 'checkedSeq');
  if (position < 0 || (checkedSeq != null && checkedSeq < 1)) {
    throw const InvalidBackupException(_corrupted);
  }
  final String? quantity;
  try {
    quantity = normalizeQuantity(_nullableField<String>(raw, 'quantity'));
  } on DomainException catch (e) {
    throw InvalidBackupException(
      'O backup tem uma quantidade inválida: ${e.message}',
    );
  }
  return BackupItem(
    name: name,
    quantity: quantity,
    position: position,
    checkedSeq: checkedSeq,
  );
}

String _validName(String raw) {
  try {
    return validateName(raw);
  } on DomainException catch (e) {
    throw InvalidBackupException('O backup tem um nome inválido: ${e.message}');
  }
}

void _ensureUnique(Iterable<String> names, String message) {
  final keys = <String>{};
  for (final name in names) {
    if (!keys.add(normalizeKey(name))) throw InvalidBackupException(message);
  }
}

/// Campo obrigatório e não nulo do tipo [T].
T _field<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! T) throw const InvalidBackupException(_corrupted);
  return value;
}

/// Campo obrigatório que pode ser `null`.
T? _nullableField<T>(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) throw const InvalidBackupException(_corrupted);
  final value = json[key];
  if (value != null && value is! T) {
    throw const InvalidBackupException(_corrupted);
  }
  return value as T?;
}
