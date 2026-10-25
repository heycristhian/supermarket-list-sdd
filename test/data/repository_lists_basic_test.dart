import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/database.dart';
import 'package:supermarket_list/data/shopping_repository.dart';
import 'package:supermarket_list/domain/errors.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late ShoppingRepository repo;

  setUp(() {
    db = createTestDatabase();
    clock = FakeClock();
    repo = ShoppingRepository(db, clock.call);
  });
  tearDown(() => db.close());

  test('createList cria a lista e ela aparece em watchLists', () async {
    final id = await repo.createList('  Lista semanal ');

    final overview = await repo.watchLists().first;
    expect(overview.active?.id, id);
    expect(overview.active?.name, 'Lista semanal');
  });

  test('a 1ª lista vira ativa; a 2ª não altera a ativa', () async {
    final first = await repo.createList('Semanal');
    final second = await repo.createList('Pizza');

    expect(await repo.watchActiveListId().first, first);
    final overview = await repo.watchLists().first;
    expect(overview.active?.id, first);
    expect(overview.others.map((l) => l.id), [second]);
  });

  test('nome vazio é rejeitado e nada é criado', () async {
    await expectLater(
      repo.createList('   '),
      throwsA(isA<EmptyNameException>()),
    );
    expect((await repo.watchLists().first).isEmpty, isTrue);
  });

  test('nome com mais de 80 caracteres é rejeitado', () async {
    await expectLater(
      repo.createList('a' * 81),
      throwsA(isA<NameTooLongException>()),
    );
    expect((await repo.watchLists().first).isEmpty, isTrue);
  });

  test('nome repetido (ignorando maiúsculas) é rejeitado', () async {
    await repo.createList('Lista semanal');

    await expectLater(
      repo.createList('lista  SEMANAL'),
      throwsA(isA<DuplicateNameException>()),
    );
    final overview = await repo.watchLists().first;
    expect(overview.others, isEmpty);
  });

  test('toda escrita atualiza lastChangeAt com o relógio', () async {
    clock.now = DateTime(2026, 10, 24, 9);
    await repo.createList('Semanal');

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.lastChangeAt, DateTime(2026, 10, 24, 9));
  });
}
