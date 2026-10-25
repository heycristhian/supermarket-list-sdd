import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/shopping_repository.dart';
import 'package:supermarket_list/ui/strings.dart';
import 'package:supermarket_list/ui/theme/brand_theme.dart';
import 'package:supermarket_list/ui/widgets/name_dialog.dart';

import '../support/pump_app.dart';

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

Finder _card(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(Card));

Finder _menuOf(String name) => find.descendant(
  of: _card(name),
  matching: find.byTooltip(Strings.listMenu),
);

Finder _handleOf(String name) => find.descendant(
  of: _card(name),
  matching: find.byTooltip(Strings.reorderHandle),
);

/// "Semanal" fica ativa por ser a primeira; abre a tela de listas.
Future<ShoppingRepository> _pumpLists(WidgetTester tester) async {
  final repo = await pumpApp(
    tester,
    seed: (repo) async {
      for (final name in ['Semanal', 'Pizza', 'Churrasco', 'Festa']) {
        await repo.createList(name);
      }
    },
  );
  await tester.tap(find.byTooltip(Strings.openLists));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _openMenu(WidgetTester tester, String name) async {
  await tester.tap(_menuOf(name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a ativa aparece primeiro, com selo e barra de destaque', (
    tester,
  ) async {
    await _pumpLists(tester);

    expect(_top(tester, 'Semanal'), lessThan(_top(tester, 'Pizza')));
    expect(_top(tester, Strings.activeBadge), lessThan(_top(tester, 'Pizza')));
    final context = tester.element(find.text('Semanal'));
    final accent = find.descendant(
      of: _card('Semanal'),
      matching: find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == context.brand.activeListAccent,
      ),
    );
    expect(accent, findsOneWidget);
    expect(_handleOf('Semanal'), findsNothing);
    expect(_handleOf('Pizza'), findsOneWidget);
  });

  testWidgets('o menu ⋯ oferece as ações da lista', (tester) async {
    await _pumpLists(tester);

    await _openMenu(tester, 'Pizza');

    for (final action in [
      Strings.activate,
      Strings.rename,
      Strings.moveUp,
      Strings.moveDown,
      Strings.delete,
    ]) {
      expect(find.text(action), findsOneWidget, reason: action);
    }
  });

  testWidgets('a ativa não oferece "Ativar" nem "Mover"', (tester) async {
    await _pumpLists(tester);

    await _openMenu(tester, 'Semanal');

    expect(find.text(Strings.activate), findsNothing);
    expect(find.text(Strings.moveUp), findsNothing);
    expect(find.text(Strings.rename), findsOneWidget);
    expect(find.text(Strings.delete), findsOneWidget);
  });

  testWidgets('Ativar leva a lista para o topo', (tester) async {
    await _pumpLists(tester);

    await _openMenu(tester, 'Churrasco');
    await tester.tap(find.text(Strings.activate));
    await tester.pumpAndSettle();

    expect(_top(tester, 'Churrasco'), lessThan(_top(tester, 'Semanal')));
    expect(_top(tester, 'Semanal'), lessThan(_top(tester, 'Pizza')));
  });

  testWidgets('Renomear muda o nome da lista', (tester) async {
    await _pumpLists(tester);

    await _openMenu(tester, 'Pizza');
    await tester.tap(find.text(Strings.rename));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(NameDialog.fieldKey), 'Pizzaria');
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    expect(find.text('Pizzaria'), findsOneWidget);
    expect(find.text('Pizza'), findsNothing);
  });

  testWidgets('Apagar pede confirmação, e cancelar não apaga', (tester) async {
    await _pumpLists(tester);

    await _openMenu(tester, 'Pizza');
    await tester.tap(find.text(Strings.delete));
    await tester.pumpAndSettle();
    expect(find.text(Strings.deleteListTitle), findsOneWidget);

    await tester.tap(find.text(Strings.cancel));
    await tester.pumpAndSettle();
    expect(find.text('Pizza'), findsOneWidget);

    await _openMenu(tester, 'Pizza');
    await tester.tap(find.text(Strings.delete));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(Strings.delete),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pizza'), findsNothing);
  });

  testWidgets('arrastar pela alça reordena as não ativas', (tester) async {
    await _pumpLists(tester);
    final rowHeight = _top(tester, 'Churrasco') - _top(tester, 'Pizza');

    final gesture = await tester.startGesture(
      tester.getCenter(_handleOf('Pizza')),
    );
    await tester.pump();
    const steps = 20;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(0, rowHeight * 2 / steps));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_top(tester, 'Churrasco'), lessThan(_top(tester, 'Pizza')));
    expect(_top(tester, 'Semanal'), lessThan(_top(tester, 'Churrasco')));
  });
}
