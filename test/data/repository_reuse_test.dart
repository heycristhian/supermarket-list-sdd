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
    listId = await repo.createList('Lista Hambúrguer');
  });
  tearDown(() => db.close());

  Future<List<ShoppingItem>> itemsOf(int id) => repo.watchItems(id).first;

  Future<List<String>> names(int id) async =>
      (await itemsOf(id)).map((i) => i.name).toList();

  Future<int> idOf(String name) async =>
      (await itemsOf(listId)).firstWhere((i) => i.name == name).id;

  Future<void> addAll(List<String> names) async {
    for (final name in names) {
      await repo.addItem(listId, name);
    }
  }

  group('copyList', () {
    test('teste obrigatório: a cópia vem toda desmarcada', () async {
      await repo.addItem(listId, 'Pão', quantity: '6');
      await repo.addItem(listId, 'Carne', quantity: '1 kg');
      await repo.addItem(listId, 'Queijo');
      await repo.toggleChecked(await idOf('Pão'));
      await repo.toggleChecked(await idOf('Queijo'));

      final copyId = await repo.copyList(listId, 'Hambúrguer de sábado');

      final copy = await itemsOf(copyId);
      expect(copy.map((i) => i.name), ['Pão', 'Carne', 'Queijo']);
      expect(copy.map((i) => i.quantity), ['6', '1 kg', null]);
      expect(copy.every((i) => i.checkedSeq == null), isTrue);

      final original = await itemsOf(listId);
      expect(original.map((i) => i.name), ['Carne', 'Pão', 'Queijo']);
      expect(original.where((i) => i.isChecked), hasLength(2));
    });

    test('a cópia não altera a lista ativa e entra no fim', () async {
      final other = await repo.createList('Pizza');

      final copyId = await repo.copyList(listId, 'Cópia');

      final overview = await repo.watchLists().first;
      expect(overview.active?.id, listId);
      expect(overview.others.map((l) => l.id), [other, copyId]);
    });

    test('alterar a cópia não altera a original', () async {
      await addAll(['A', 'B']);
      final copyId = await repo.copyList(listId, 'Cópia');

      final copyA = (await itemsOf(copyId)).first;
      await repo.toggleChecked(copyA.id);
      await repo.editItem(copyA.id, 'A2');

      expect(await names(listId), ['A', 'B']);
      expect((await itemsOf(listId)).any((i) => i.isChecked), isFalse);
    });

    test('título vazio ou existente é rejeitado e nada é criado', () async {
      await expectLater(
        repo.copyList(listId, '  '),
        throwsA(isA<EmptyNameException>()),
      );
      await expectLater(
        repo.copyList(listId, 'lista hambúrguer'),
        throwsA(isA<DuplicateNameException>()),
      );
      final overview = await repo.watchLists().first;
      expect(overview.others, isEmpty);
    });

    test('suggestCopyName considera as listas existentes', () async {
      expect(await repo.suggestCopyName(listId), 'Lista Hambúrguer (cópia)');

      await repo.copyList(listId, 'Lista Hambúrguer (cópia)');
      expect(await repo.suggestCopyName(listId), 'Lista Hambúrguer (cópia 2)');
    });
  });

  group('uncheckAll', () {
    test('desmarca tudo e volta à ordem original', () async {
      await addAll(['A', 'B', 'C', 'D']);
      await repo.toggleChecked(await idOf('D'));
      await repo.toggleChecked(await idOf('B'));
      expect(await names(listId), ['A', 'C', 'D', 'B']);

      await repo.uncheckAll(listId);

      expect(await names(listId), ['A', 'B', 'C', 'D']);
      expect((await itemsOf(listId)).any((i) => i.isChecked), isFalse);
    });

    test('depois de apagar um item mantém a ordem dos restantes', () async {
      await addAll(['A', 'B', 'C', 'D']);
      await repo.toggleChecked(await idOf('A'));
      await repo.toggleChecked(await idOf('C'));
      await repo.deleteItem(await idOf('B'));

      await repo.uncheckAll(listId);

      expect(await names(listId), ['A', 'C', 'D']);
    });

    test('não mexe em outras listas', () async {
      final other = await repo.createList('Pizza');
      final pizzaItem = await repo.addItem(other, 'Massa');
      await repo.toggleChecked(pizzaItem);
      await repo.addItem(listId, 'A');

      await repo.uncheckAll(listId);

      expect((await itemsOf(other)).single.isChecked, isTrue);
    });
  });
}
