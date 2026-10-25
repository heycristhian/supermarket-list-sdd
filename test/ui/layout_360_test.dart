import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/shopping_repository.dart';
import 'package:supermarket_list/domain/name_rules.dart';
import 'package:supermarket_list/ui/strings.dart';

import '../support/pump_app.dart';

final _longList = 'L${'ista comprida ' * 6}'.substring(0, maxNameLength);
final _longItem = 'I${'tem com nome longo ' * 5}'.substring(0, maxNameLength);
final _longQuantity = 'Q${'uantidade ' * 5}'.substring(0, maxQuantityLength);

/// Nomes no limite de 80 caracteres, com itens comprados e não comprados.
Future<void> _seed(ShoppingRepository repo) async {
  final active = await repo.createList(_longList);
  await repo.createList('${_longList.substring(0, 70)} (cópia)');
  await repo.createList('Pizza');
  final first = await repo.addItem(active, _longItem, quantity: _longQuantity);
  await repo.addItem(active, 'Arroz', quantity: '5 kg');
  await repo.addItem(active, 'Feijão');
  await repo.toggleChecked(first);
}

Future<void> _setSmallPhone(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

Future<void> _openDialogAndClose(
  WidgetTester tester,
  Future<void> Function() open,
) async {
  await open();
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  await _expectAccessible(tester);
  await tester.tap(find.text(Strings.cancel));
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    group('tema ${brightness.name}, 360 × 740', () {
      testWidgets('tela de itens e diálogos sem overflow e acessíveis', (
        tester,
      ) async {
        await _setSmallPhone(tester, brightness);
        await pumpApp(tester, seed: _seed);
        expect(find.text(_longItem), findsOneWidget);
        await _expectAccessible(tester);

        // Editar item.
        await _openDialogAndClose(tester, () async {
          await tester.tap(find.byTooltip(Strings.itemMenu).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(Strings.edit));
        });

        // Desmarcar todos (confirmação).
        await _openDialogAndClose(
          tester,
          () => tester.tap(find.byTooltip(Strings.uncheckAll)),
        );
      });

      testWidgets('tela de listas e diálogos sem overflow e acessíveis', (
        tester,
      ) async {
        await _setSmallPhone(tester, brightness);
        await pumpApp(tester, seed: _seed);
        await tester.tap(find.byTooltip(Strings.openLists));
        await tester.pumpAndSettle();
        await _expectAccessible(tester);

        // Nova lista.
        await _openDialogAndClose(
          tester,
          () => tester.tap(find.text(Strings.newList)),
        );

        // Renomear, já com 80 caracteres.
        await _openDialogAndClose(tester, () async {
          await tester.tap(find.byTooltip(Strings.listMenu).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(Strings.rename));
        });

        // Apagar (confirmação com o nome longo na mensagem).
        await _openDialogAndClose(tester, () async {
          await tester.tap(find.byTooltip(Strings.listMenu).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(Strings.delete));
        });
      });
    });
  }

  testWidgets(
    'com "reduzir movimento", as transições do app são instantâneas',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await pumpApp(tester, seed: _seed);

      final switchers = tester.widgetList<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(switchers, isNotEmpty);
      for (final switcher in switchers) {
        expect(switcher.duration, Duration.zero);
      }
    },
  );
}
