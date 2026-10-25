import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/app.dart';
import 'package:supermarket_list/state/providers.dart';
import 'package:supermarket_list/ui/screens/splash_screen.dart';
import 'package:supermarket_list/ui/strings.dart';
import 'package:supermarket_list/ui/theme/tokens.dart';

import '../support/test_database.dart';

/// Sobe o app sem esperar a splash terminar.
Future<void> _pumpRawApp(
  WidgetTester tester, {
  List overrides = const [],
}) async {
  final db = createTestDatabase();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), ...overrides],
      child: const SupermarketApp(),
    ),
  );
}

final _splash = find.byType(SplashScreen);

void main() {
  testWidgets('a splash dá lugar à home quando a animação termina', (
    tester,
  ) async {
    await _pumpRawApp(tester);
    expect(_splash, findsOneWidget);

    await tester.pump(Tokens.durationSlow ~/ 2);
    expect(_splash, findsOneWidget);

    await tester.pump(Tokens.durationSlow);
    await tester.pumpAndSettle();
    expect(_splash, findsNothing);
    expect(find.text(Strings.noListsTitle), findsOneWidget);
  });

  testWidgets('com o banco lento, o teto é splashMaxDuration', (tester) async {
    final neverReady = StreamController<int?>();
    addTearDown(neverReady.close);
    await _pumpRawApp(
      tester,
      overrides: [
        activeListIdProvider.overrideWith((ref) => neverReady.stream),
      ],
    );

    await tester.pump(Tokens.splashMaxDuration - Tokens.durationFast);
    expect(_splash, findsOneWidget);

    await tester.pump(Tokens.durationFast);
    await tester.pump(Tokens.durationMedium);
    await tester.pump();
    expect(_splash, findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('com "reduzir movimento" não há animação', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _pumpRawApp(tester);
    expect(_splash, findsOneWidget);
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(of: _splash, matching: find.byType(FadeTransition)),
    );
    expect(fades.every((f) => f.opacity.value == 1), isTrue);

    // Sem animação, a home aparece assim que o banco abre, bem antes dos
    // 600 ms da animação.
    for (var i = 0; i < 6; i++) {
      await tester.pump(Tokens.durationFast ~/ 10);
    }
    expect(_splash, findsNothing);
  });

  testWidgets('voltar do segundo plano não reexibe a splash', (tester) async {
    await _pumpRawApp(tester);
    await tester.pump(Tokens.splashMaxDuration);
    await tester.pumpAndSettle();
    expect(_splash, findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(_splash, findsNothing);
    expect(find.text(Strings.noListsTitle), findsOneWidget);
  });
}
