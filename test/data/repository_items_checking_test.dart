import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/database.dart';
import 'package:supermarket_list/data/shopping_repository.dart';
import 'package:supermarket_list/domain/errors.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ShoppingRepository repo;
  late int listId;

  setUp(() async {
    db = createTestDatabase();
    repo = ShoppingRepository(db, FakeClock().call);
    listId = await repo.createList('Semanal');
  });
  tearDown(() => db.close());

  Future<List<String>> names() async =>
      (await repo.watchItems(listId).first).map((i) => i.name).toList();

  Future<int> idOf(String name) async => (await repo.watchItems(listId).first)
      .firstWhere((i) => i.name == name)
      .id;

  test(
    'teste obrigatório: comprado vai para o fim e volta ao seu lugar',
    () async {
      for (final name in ['A', 'B', 'C', 'D']) {
        await repo.addItem(listId, name);
      }
      expect(await names(), ['A', 'B', 'C', 'D']);

      await repo.toggleChecked(await idOf('B'));
      expect(await names(), ['A', 'C', 'D', 'B']);

      await repo.toggleChecked(await idOf('A'));
      expect(await names(), ['C', 'D', 'B', 'A']);

      await repo.toggleChecked(await idOf('B'));
      expect(await names(), ['B', 'C', 'D', 'A']);

      final items = await repo.watchItems(listId).first;
      expect(items.map((i) => i.isChecked), [false, false, false, true]);
    },
  );

  test('item repetido na mesma lista é rejeitado', () async {
    await repo.addItem(listId, 'Arroz');

    await expectLater(
      repo.addItem(listId, 'arroz'),
      throwsA(isA<DuplicateNameException>()),
    );
    await expectLater(
      repo.addItem(listId, ' Arroz '),
      throwsA(isA<DuplicateNameException>()),
    );
    expect(await names(), ['Arroz']);
  });

  test('o mesmo item em outra lista é permitido', () async {
    await repo.addItem(listId, 'Arroz');
    final other = await repo.createList('Pizza');

    await repo.addItem(other, 'Arroz');

    final items = await repo.watchItems(other).first;
    expect(items.single.name, 'Arroz');
  });

  test('quantidade: vazia vira null e o texto é normalizado', () async {
    await repo.addItem(listId, 'Arroz', quantity: '  ');
    await repo.addItem(listId, 'Feijão', quantity: ' 2 kg ');

    final items = await repo.watchItems(listId).first;
    expect(items.map((i) => i.quantity), [null, '2 kg']);
  });

  test('item novo entra antes dos comprados', () async {
    await repo.addItem(listId, 'A');
    await repo.addItem(listId, 'B');
    await repo.toggleChecked(await idOf('A'));

    await repo.addItem(listId, 'C');

    expect(await names(), ['B', 'C', 'A']);
  });

  test('tudo persiste ao fechar e reabrir o banco', () async {
    final dir = await Directory.systemTemp.createTemp('supermarket_list_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    var fileDb = AppDatabase(NativeDatabase(file));
    var fileRepo = ShoppingRepository(fileDb, FakeClock().call);
    final id = await fileRepo.createList('Semanal');
    await fileRepo.addItem(id, 'Arroz', quantity: '5 kg');
    await fileRepo.addItem(id, 'Feijão');
    final arroz = (await fileRepo.watchItems(id).first).first.id;
    await fileRepo.toggleChecked(arroz);
    await fileDb.close();

    fileDb = AppDatabase(NativeDatabase(file));
    fileRepo = ShoppingRepository(fileDb, FakeClock().call);
    final items = await fileRepo.watchItems(id).first;
    await fileDb.close();

    expect(items.map((i) => i.name), ['Feijão', 'Arroz']);
    expect(items.last.quantity, '5 kg');
    expect(items.last.isChecked, isTrue);
  });
}
