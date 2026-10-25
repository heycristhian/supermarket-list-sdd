import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/app.dart';
import 'package:supermarket_list/data/shopping_repository.dart';
import 'package:supermarket_list/state/providers.dart';

import 'test_database.dart';

/// Sobe o app com banco em memória; [seed] prepara os dados antes.
Future<ShoppingRepository> pumpApp(
  WidgetTester tester, {
  Future<void> Function(ShoppingRepository repo)? seed,
  List overrides = const [],
}) async {
  final db = createTestDatabase();
  addTearDown(db.close);
  final clock = FakeClock();
  final repo = ShoppingRepository(db, clock.call);
  // O drift usa timers reais: o seed roda fora do relógio falso do teste.
  if (seed != null) await tester.runAsync(() => seed(repo));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock.call),
        ...overrides,
      ],
      child: const SupermarketApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Cria a lista "Semanal" (que vira ativa) com [items], marcando [checked].
Future<void> seedList(
  ShoppingRepository repo,
  List<String> items, {
  List<String> checked = const [],
}) async {
  final listId = await repo.createList('Semanal');
  for (final name in items) {
    await repo.addItem(listId, name);
  }
  final all = await repo.watchItems(listId).first;
  for (final item in all.where((i) => checked.contains(i.name))) {
    await repo.toggleChecked(item.id);
  }
}
