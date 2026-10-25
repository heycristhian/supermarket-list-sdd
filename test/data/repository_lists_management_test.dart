import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/database.dart';
import 'package:supermarket_list/data/shopping_repository.dart';
import 'package:supermarket_list/domain/errors.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ShoppingRepository repo;
  late int w, x, y, z;

  setUp(() async {
    db = createTestDatabase();
    repo = ShoppingRepository(db, FakeClock().call);
    // W é a 1ª lista e por isso fica ativa.
    w = await repo.createList('W');
    x = await repo.createList('X');
    y = await repo.createList('Y');
    z = await repo.createList('Z');
  });
  tearDown(() => db.close());

  Future<List<String>> others() async =>
      (await repo.watchLists().first).others.map((l) => l.name).toList();

  Future<String?> active() async =>
      (await repo.watchLists().first).active?.name;

  test('teste obrigatório: lista ativa única', () async {
    await repo.activateList(x);
    expect(await active(), 'X');
    expect(await others(), ['W', 'Y', 'Z']);

    await repo.activateList(y);
    expect(await active(), 'Y');
    // X volta para o seu slot original entre as demais (FR-011).
    expect(await others(), ['W', 'X', 'Z']);
    expect(await repo.watchActiveListId().first, y);
  });

  test('apagar a ativa deixa nenhuma ativa e remove os itens', () async {
    await repo.addItem(w, 'Arroz');

    await repo.deleteList(w);

    expect(await active(), isNull);
    expect(await others(), ['X', 'Y', 'Z']);
    expect(await db.select(db.shoppingItems).get(), isEmpty);
  });

  test('apagar uma não ativa mantém a ativa', () async {
    await repo.deleteList(y);

    expect(await active(), 'W');
    expect(await others(), ['X', 'Z']);
  });

  group('renameList', () {
    test('renomeia', () async {
      await repo.renameList(x, '  Churrasco ');
      expect(await others(), ['Churrasco', 'Y', 'Z']);
    });

    test('nome de outra lista é rejeitado', () async {
      await expectLater(
        repo.renameList(x, 'y'),
        throwsA(isA<DuplicateNameException>()),
      );
      expect(await others(), ['X', 'Y', 'Z']);
    });

    test(
      'mudar só maiúsculas/minúsculas do próprio nome é permitido',
      () async {
        await repo.renameList(x, 'x');
        expect(await others(), ['x', 'Y', 'Z']);
      },
    );

    test('nome vazio é rejeitado', () async {
      await expectLater(
        repo.renameList(x, ' '),
        throwsA(isA<EmptyNameException>()),
      );
    });
  });

  group('reorderInactiveLists', () {
    test('reordena as não ativas; a ativa conserva seu slot', () async {
      await repo.activateList(y);
      expect(await others(), ['W', 'X', 'Z']);

      // Z (índice 2 entre as não ativas) vai para o início.
      await repo.reorderInactiveLists(2, 0);
      expect(await others(), ['Z', 'W', 'X']);

      // Ao deixar de ser ativa, Y reaparece no slot que ocupava.
      await repo.activateList(z);
      expect(await others(), ['W', 'Y', 'X']);
    });
  });

  group('moveList', () {
    test('sobe e desce uma lista não ativa', () async {
      await repo.moveList(z, -1);
      expect(await others(), ['X', 'Z', 'Y']);

      await repo.moveList(x, 1);
      expect(await others(), ['Z', 'X', 'Y']);
    });

    test('nos limites e na lista ativa não faz nada', () async {
      await repo.moveList(x, -1);
      await repo.moveList(z, 1);
      await repo.moveList(w, 1);

      expect(await active(), 'W');
      expect(await others(), ['X', 'Y', 'Z']);
    });
  });
}
