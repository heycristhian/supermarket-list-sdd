import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
import 'ui/screens/list_items_screen.dart';
import 'ui/screens/lists_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/strings.dart';
import 'ui/theme/app_theme.dart';

class SupermarketApp extends StatelessWidget {
  const SupermarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SplashGate(child: HomeGate()),
    );
  }
}

/// Decide a tela inicial uma única vez, na abertura (FR-012): a lista ativa
/// ou, sem ela, a tela de listas.
class HomeGate extends ConsumerStatefulWidget {
  const HomeGate({super.key});

  @override
  ConsumerState<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends ConsumerState<HomeGate> {
  Widget? _home;

  @override
  Widget build(BuildContext context) {
    if (_home != null) return _home!;
    return switch (ref.watch(activeListIdProvider)) {
      AsyncData(:final value) =>
        _home = value == null
            ? const ListsScreen()
            : ListItemsScreen(listId: value),
      AsyncError(:final error) => Scaffold(body: Center(child: Text('$error'))),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}
