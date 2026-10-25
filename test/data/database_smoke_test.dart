import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/database.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  Future<int> insertList(String name) => db
      .into(db.shoppingLists)
      .insert(
        ShoppingListsCompanion.insert(name: name, nameKey: name, position: 0),
      );

  test('a linha única de app_settings existe', () async {
    final settings = await db.select(db.appSettings).get();
    expect(settings.single.id, 1);
  });

  test('apagar uma lista apaga seus itens (CASCADE)', () async {
    final listId = await insertList('Semanal');
    await db
        .into(db.shoppingItems)
        .insert(
          ShoppingItemsCompanion.insert(
            listId: listId,
            name: 'Arroz',
            nameKey: 'arroz',
            position: 0,
          ),
        );

    await (db.delete(db.shoppingLists)..where((l) => l.id.equals(listId))).go();

    expect(await db.select(db.shoppingItems).get(), isEmpty);
  });

  test('apagar a lista ativa zera activeListId (SET NULL)', () async {
    final listId = await insertList('Semanal');
    await db
        .update(db.appSettings)
        .write(AppSettingsCompanion(activeListId: Value(listId)));

    await (db.delete(db.shoppingLists)..where((l) => l.id.equals(listId))).go();

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.activeListId, isNull);
  });
}
