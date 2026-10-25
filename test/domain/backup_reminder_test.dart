import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/domain/backup_reminder.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));

  test('nunca fez backup e há alterações ⇒ mostra', () {
    expect(
      shouldShowReminder(
        now: now,
        lastBackupAt: null,
        lastChangeAt: daysAgo(0),
        snoozedUntil: null,
      ),
      isTrue,
    );
  });

  test('nenhuma alteração ⇒ não mostra', () {
    expect(
      shouldShowReminder(
        now: now,
        lastBackupAt: null,
        lastChangeAt: null,
        snoozedUntil: null,
      ),
      isFalse,
    );
  });

  test('backup há 6 dias ⇒ não mostra', () {
    expect(
      shouldShowReminder(
        now: now,
        lastBackupAt: daysAgo(6),
        lastChangeAt: daysAgo(1),
        snoozedUntil: null,
      ),
      isFalse,
    );
  });

  test('backup há 7 dias e alterações depois ⇒ mostra', () {
    expect(
      shouldShowReminder(
        now: now,
        lastBackupAt: daysAgo(7),
        lastChangeAt: daysAgo(3),
        snoozedUntil: null,
      ),
      isTrue,
    );
  });

  test('backup há 7 dias sem alterações desde então ⇒ não mostra', () {
    expect(
      shouldShowReminder(
        now: now,
        lastBackupAt: daysAgo(7),
        lastChangeAt: daysAgo(7),
        snoozedUntil: null,
      ),
      isFalse,
    );
  });

  test('dispensado ⇒ não mostra até snoozedUntil', () {
    bool show(DateTime snoozedUntil) => shouldShowReminder(
      now: now,
      lastBackupAt: daysAgo(30),
      lastChangeAt: daysAgo(1),
      snoozedUntil: snoozedUntil,
    );
    expect(show(now.add(const Duration(minutes: 1))), isFalse);
    expect(show(now), isTrue);
  });
}
