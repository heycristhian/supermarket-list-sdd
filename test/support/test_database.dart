import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:supermarket_list/data/database.dart';

AppDatabase createTestDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Relógio ajustável para testes determinísticos.
class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime(2026, 10, 24, 12);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}
