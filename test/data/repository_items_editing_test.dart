import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/database.dart';
import 'package:supermarket_list/data/shopping_repository.dart';
import 'package:supermarket_list/domain/errors.dart';
import 'package:supermarket_list/domain/models.dart';

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

  Future<List<ShoppingItem>> items() => repo.watchItems(listId).first;

  Future<List<String>> names() async =>
      (await items()).map((i) => i.name).toList();

  Future<int> idOf(String name) async =>
      (await items()).firstWhere((i) => i.name == name).id;

  Future<void> addAll(List<String> names) async {
    for (final name in names) {
      await repo.addItem(listId, name);
    }
  }

  group('editItem', () {
    test('muda nome e quantidade mantendo posição e estado', () async {
      await addAll(['A', 'B', 'C']);
      await repo.toggleChecked(await idOf('B'));

      await repo.editItem(await idOf('B'), 'Banana', quantity: '1 dúzia');

      expect(await names(), ['A', 'C', 'Banana']);
      final banana = (await items()).last;
      expect(banana.quantity, '1 dúzia');
      expect(banana.isChecked, isTrue);
      expect(banana.position, 1);
    });

    test('quantidade vazia vira nula', () async {
      await repo.addItem(listId, 'Arroz', quantity: '5 kg');

      await repo.editItem(await idOf('Arroz'), 'Arroz', quantity: '   ');

      expect((await items()).single.quantity, isNull);
    });

    test('nome de outro item da lista é rejeitado', () async {
      await addAll(['Arroz', 'Feijão']);

      await expectLater(
        repo.editItem(await idOf('Feijão'), ' arroz '),
        throwsA(isA<DuplicateNameException>()),
      );
      expect(await names(), ['Arroz', 'Feijão']);
    });

    test(
      'mudar só maiúsculas/minúsculas do próprio nome é permitido',
      () async {
        await repo.addItem(listId, 'arroz');

        await repo.editItem(await idOf('arroz'), 'Arroz');

        expect(await names(), ['Arroz']);
      },
    );

    test('nome vazio é rejeitado', () async {
      await repo.addItem(listId, 'Arroz');

      await expectLater(
        repo.editItem(await idOf('Arroz'), '  '),
        throwsA(isA<EmptyNameException>()),
      );
    });
  });

  group('deleteItem e restoreItem', () {
    test('desfazer devolve o item à mesma posição', () async {
      await addAll(['A', 'B', 'C']);

      final deleted = await repo.deleteItem(await idOf('B'));
      expect(await names(), ['A', 'C']);

      await repo.restoreItem(deleted);
      expect(await names(), ['A', 'B', 'C']);
    });

    test(
      'desfazer mantém o estado de comprado e a ordem de marcação',
      () async {
        await addAll(['A', 'B', 'C']);
        await repo.toggleChecked(await idOf('A'));
        await repo.toggleChecked(await idOf('C'));
        expect(await names(), ['B', 'A', 'C']);

        final deleted = await repo.deleteItem(await idOf('A'));
        await repo.restoreItem(deleted);

        expect(await names(), ['B', 'A', 'C']);
        expect((await items())[1].isChecked, isTrue);
      },
    );

    test('desfazer depois de adicionar outro item não perde a ordem', () async {
      await addAll(['A', 'B', 'C']);

      final deleted = await repo.deleteItem(await idOf('C'));
      await repo.addItem(listId, 'D');
      await repo.restoreItem(deleted);

      expect(await names(), ['A', 'B', 'C', 'D']);
    });
  });

  group('reorderUncheckedItems', () {
    test('exemplo de R9: os comprados conservam seus slots', () async {
      await addAll(['A', 'B', 'C', 'D']);
      await repo.toggleChecked(await idOf('B'));
      expect(await names(), ['A', 'C', 'D', 'B']);

      // D (índice 2 entre os não comprados) vai para o início.
      await repo.reorderUncheckedItems(listId, 2, 0);
      expect(await names(), ['D', 'A', 'C', 'B']);

      await repo.toggleChecked(await idOf('B'));
      expect(await names(), ['D', 'B', 'A', 'C']);
    });

    test('mover para o mesmo índice não altera nada', () async {
      await addAll(['A', 'B', 'C']);

      await repo.reorderUncheckedItems(listId, 1, 1);

      expect(await names(), ['A', 'B', 'C']);
    });
  });

  group('moveItem', () {
    test('sobe e desce um item não comprado', () async {
      await addAll(['A', 'B', 'C']);

      await repo.moveItem(await idOf('C'), -1);
      expect(await names(), ['A', 'C', 'B']);

      await repo.moveItem(await idOf('A'), 1);
      expect(await names(), ['C', 'A', 'B']);
    });

    test('nos limites não faz nada', () async {
      await addAll(['A', 'B', 'C']);

      await repo.moveItem(await idOf('A'), -1);
      await repo.moveItem(await idOf('C'), 1);

      expect(await names(), ['A', 'B', 'C']);
    });

    test('pula os comprados e não move itens comprados', () async {
      await addAll(['A', 'B', 'C']);
      await repo.toggleChecked(await idOf('B'));

      await repo.moveItem(await idOf('C'), -1);
      expect(await names(), ['C', 'A', 'B']);

      await repo.moveItem(await idOf('B'), -1);
      expect(await names(), ['C', 'A', 'B']);
    });
  });
}
