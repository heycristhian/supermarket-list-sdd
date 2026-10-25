import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_files.dart';
import '../data/database.dart';
import '../data/shopping_repository.dart';
import '../domain/models.dart';

/// Sobrescrito em `main` (banco real) e nos testes (banco em memória).
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider precisa de override'),
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final repositoryProvider = Provider<ShoppingRepository>(
  (ref) =>
      ShoppingRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final listsOverviewProvider = StreamProvider<ListsOverview>(
  (ref) => ref.watch(repositoryProvider).watchLists(),
);

final activeListIdProvider = StreamProvider<int?>(
  (ref) => ref.watch(repositoryProvider).watchActiveListId(),
);

final listProvider = StreamProvider.family<ShoppingList?, int>(
  (ref, listId) => ref.watch(repositoryProvider).watchList(listId),
);

final itemsProvider = StreamProvider.family<List<ShoppingItem>, int>(
  (ref, listId) => ref.watch(repositoryProvider).watchItems(listId),
);

final backupReminderProvider = StreamProvider<bool>(
  (ref) => ref.watch(repositoryProvider).watchBackupReminder(),
);

/// Seletor de arquivos do backup; sobrescrito nos testes.
final backupFilesProvider = Provider<BackupFiles>((ref) => const BackupFiles());

/// `true` quando a web não consegue persistir os dados (research.md R2).
final storageVolatileProvider = Provider<ValueListenable<bool>>(
  (ref) => ValueNotifier(false),
);
