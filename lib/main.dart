import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/connection.dart';
import 'state/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = openAppStorage();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(storage.database),
        storageVolatileProvider.overrideWithValue(storage.isStorageVolatile),
      ],
      child: const SupermarketApp(),
    ),
  );
}
