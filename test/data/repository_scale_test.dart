// Escala de SC-007: 50 listas × 100 itens. Só corretude; os tempos são
// conferidos à mão no quickstart, para o teste continuar determinístico.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/database.dart';
import 'package:supermarket_list/data/shopping_repository.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ShoppingRepository repo;

  setUp(() async {
    db = createTestDatabase();
    repo = ShoppingRepository(db, FakeClock().call);
    final bytes = File('test/fixtures/backup_50x100.json').readAsBytesSync();
    await repo.importBackup(repo.parseBackup(bytes));
  });
  tearDown(() => db.close());

  test('watchLists traz as 50 listas com seus totais', () async {
    final overview = await repo.watchLists().first;

    expect(overview.active?.name, 'Lista 01');
    expect(overview.others, hasLength(49));
    expect(overview.others.first.name, 'Lista 02');
    expect(overview.others.last.name, 'Lista 50');
    for (final list in [overview.active!, ...overview.others]) {
      expect(list.totalItems, 100);
      expect(list.checkedItems, 50);
    }
  });

  test(
    'toggleChecked e reorderUncheckedItems numa lista de 100 itens',
    () async {
      final listId = (await repo.watchLists().first).others.last.id;
      var items = await repo.watchItems(listId).first;
      expect(items, hasLength(100));
      expect(items.take(50).every((i) => !i.isChecked), isTrue);

      // Marca o 1º não comprado: ele vai para o fim.
      await repo.toggleChecked(items.first.id);
      items = await repo.watchItems(listId).first;
      expect(items.last.name, 'Item 001');

      // Último não comprado (índice 48) para o início.
      final moved = items[48].name;
      await repo.reorderUncheckedItems(listId, 48, 0);
      items = await repo.watchItems(listId).first;
      expect(items.first.name, moved);
      expect(items.where((i) => !i.isChecked), hasLength(49));
    },
  );

  test('ida e volta do backup preserva tudo', () async {
    final exported = await repo.exportBackup();

    final db2 = createTestDatabase();
    addTearDown(db2.close);
    final repo2 = ShoppingRepository(db2, FakeClock().call);
    await repo2.importBackup(repo2.parseBackup(exported));

    final a = await repo.watchLists().first;
    final b = await repo2.watchLists().first;
    expect(b.active?.name, a.active?.name);
    expect(
      b.others.map((l) => l.name).toList(),
      a.others.map((l) => l.name).toList(),
    );
    final lastA = await repo.watchItems(a.others.last.id).first;
    final lastB = await repo2.watchItems(b.others.last.id).first;
    expect(
      lastB.map((i) => '${i.name}|${i.quantity}|${i.isChecked}').toList(),
      lastA.map((i) => '${i.name}|${i.quantity}|${i.isChecked}').toList(),
    );
  });
}
