import 'package:drift/drift.dart';

part 'database.g.dart';

// Schema v1 conforme specs/001-supermarket-lists/data-model.md. Após alterar
// este arquivo, rodar `dart run build_runner build --delete-conflicting-outputs`.

@DataClassName('ListRow')
class ShoppingLists extends Table {
  @override
  String get tableName => 'shopping_lists';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get nameKey => text().unique()();
  IntColumn get position => integer()();
}

@DataClassName('ItemRow')
@TableIndex(name: 'shopping_items_list_position', columns: {#listId, #position})
class ShoppingItems extends Table {
  @override
  String get tableName => 'shopping_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get nameKey => text()();
  TextColumn get quantity => text().nullable()();
  IntColumn get position => integer()();
  IntColumn get checkedSeq => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {listId, nameKey},
  ];
}

/// Uma única linha (`id = 1`) com o estado global do app.
@DataClassName('SettingsRow')
class AppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  // A autorreferência é a forma do drift declarar CHECK (id = 1).
  // ignore: recursive_getters
  IntColumn get id => integer().check(id.equals(1))();
  IntColumn get activeListId => integer().nullable().references(
    ShoppingLists,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
  DateTimeColumn get lastChangeAt => dateTime().nullable()();
  DateTimeColumn get backupReminderSnoozedUntil => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [ShoppingLists, ShoppingItems, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(appSettings)
          .insert(AppSettingsCompanion.insert(id: const Value(1)));
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
