import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'database.dart';
import 'storage_persistence_stub.dart'
    if (dart.library.js_interop) 'storage_persistence_web.dart';

/// Banco aberto + se o armazenamento é volátil (web sem persistência).
class AppStorage {
  AppStorage(this.database, this.isStorageVolatile);

  final AppDatabase database;

  /// `true` quando o navegador só oferece banco em memória: os dados se perdem
  /// ao fechar a aba (research.md R2).
  final ValueListenable<bool> isStorageVolatile;
}

AppStorage openAppStorage() {
  final volatile = ValueNotifier(false);
  final connection = driftDatabase(
    name: 'supermarket_list',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        volatile.value =
            result.chosenImplementation == WasmStorageImplementation.inMemory;
      },
    ),
  );
  requestPersistentStorage();
  return AppStorage(AppDatabase(connection), volatile);
}
