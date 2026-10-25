import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/database.dart';
import 'package:supermarket_list/data/shopping_repository.dart';
import 'package:supermarket_list/domain/errors.dart';
import 'package:supermarket_list/domain/models.dart';

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

  /// Retrato legível de tudo o que o usuário vê.
  Future<List<String>> snapshot(ShoppingRepository repo) async {
    final overview = await repo.watchLists().first;
    final lines = <String>[];
    for (final list in [?overview.active, ...overview.others]) {
      final active = list.id == overview.active?.id ? ' (ativa)' : '';
      lines.add('${list.name}$active');
      for (final ShoppingItem item in await repo.watchItems(list.id).first) {
        lines.add(
          '  ${item.name} | ${item.quantity} | ${item.isChecked ? 'x' : ' '}',
        );
      }
    }
    return lines;
  }

  Future<void> seed() async {
    final semanal = await repo.createList('Semanal');
    final pizza = await repo.createList('Pizza');
    await repo.createList('Vazia');
    final arroz = await repo.addItem(semanal, 'Arroz', quantity: '5 kg');
    await repo.addItem(semanal, 'Feijão');
    final leite = await repo.addItem(semanal, 'Leite', quantity: '12');
    await repo.addItem(pizza, 'Massa');
    await repo.toggleChecked(leite);
    await repo.toggleChecked(arroz);
    await repo.activateList(pizza);
    await repo.moveList(semanal, 1);
  }

  test('exportar ⇒ importar num banco novo reproduz tudo', () async {
    await seed();
    final before = await snapshot(repo);

    final bytes = await repo.exportBackup();

    final db2 = createTestDatabase();
    addTearDown(db2.close);
    final repo2 = ShoppingRepository(db2, clock.call);
    await repo2.importBackup(repo2.parseBackup(bytes));

    expect(await snapshot(repo2), before);
    expect(before.first, 'Pizza (ativa)');
  });

  test(
    'marcar a exportação define lastBackupAt sem contar como alteração',
    () async {
      await repo.createList('Semanal');
      clock.advance(const Duration(hours: 1));

      await repo.markBackupDone();

      final settings = await db.select(db.appSettings).getSingle();
      expect(settings.lastBackupAt, clock.now);
      expect(
        settings.lastChangeAt,
        clock.now.subtract(const Duration(hours: 1)),
      );
      expect(await repo.watchBackupReminder().first, isFalse);
    },
  );

  test('importar substitui tudo e não mostra o lembrete', () async {
    await seed();
    final bytes = await repo.exportBackup();
    await repo.createList('Outra');
    await repo.deleteList((await repo.watchLists().first).others.first.id);

    clock.advance(const Duration(days: 30));
    await repo.importBackup(repo.parseBackup(bytes));

    final names = await snapshot(repo);
    expect(names, isNot(contains('Outra')));
    expect(names, contains('Vazia'));
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.lastBackupAt, clock.now);
    expect(settings.lastChangeAt, clock.now);
    expect(await repo.watchBackupReminder().first, isFalse);
  });

  test('importar num banco vazio não mostra o lembrete', () async {
    await seed();
    final bytes = await repo.exportBackup();

    final db2 = createTestDatabase();
    addTearDown(db2.close);
    final repo2 = ShoppingRepository(db2, clock.call);
    await repo2.importBackup(repo2.parseBackup(bytes));

    expect(await repo2.watchBackupReminder().first, isFalse);
  });

  test('um arquivo inválido deixa 100% dos dados intactos', () async {
    await seed();
    final before = await snapshot(repo);

    expect(
      () => repo.parseBackup(Uint8List.fromList(utf8.encode('{"x": 1}'))),
      throwsA(isA<InvalidBackupException>()),
    );

    expect(await snapshot(repo), before);
  });

  group('lembrete', () {
    test('aparece após alterações sem backup', () async {
      await repo.createList('Semanal');
      expect(await repo.watchBackupReminder().first, isTrue);
    });

    test('some ao dispensar e volta depois de 7 dias', () async {
      await repo.createList('Semanal');

      await repo.snoozeBackupReminder();
      expect(await repo.watchBackupReminder().first, isFalse);
      final settings = await db.select(db.appSettings).getSingle();
      expect(
        settings.backupReminderSnoozedUntil,
        clock.now.add(const Duration(days: 7)),
      );

      clock.advance(const Duration(days: 7));
      expect(await repo.watchBackupReminder().first, isTrue);
    });

    test('reage ao relógio depois de um backup', () async {
      await repo.createList('Semanal');
      await repo.markBackupDone();
      clock.advance(const Duration(days: 1));
      await repo.createList('Pizza');
      expect(await repo.watchBackupReminder().first, isFalse);

      clock.advance(const Duration(days: 6));
      expect(await repo.watchBackupReminder().first, isTrue);
    });
  });
}
