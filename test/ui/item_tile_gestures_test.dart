import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/ui/strings.dart';

import '../support/pump_app.dart';

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

Finder _handleOf(String name) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(Card)),
  matching: find.byTooltip(Strings.reorderHandle),
);

Finder _menuOf(String name) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(Card)),
  matching: find.byTooltip(Strings.itemMenu),
);

Future<void> _openMenu(WidgetTester tester, String name) async {
  await tester.tap(_menuOf(name));
  await tester.pumpAndSettle();
}

/// Arrasta pela alça em passos, como um dedo de verdade.
Future<void> _dragHandle(WidgetTester tester, String name, double dy) async {
  final gesture = await tester.startGesture(tester.getCenter(_handleOf(name)));
  await tester.pump();
  const steps = 20;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, dy / steps));
    // Tempo para a animação do espaço livre acompanhar o dedo.
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tocar na alça não marca o item', (tester) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['A', 'B']));

    await tester.tap(_handleOf('A'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('o menu ⋯ não marca e oferece as ações do item', (tester) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['A', 'B']));

    await _openMenu(tester, 'A');

    expect(find.text(Strings.edit), findsOneWidget);
    expect(find.text(Strings.moveUp), findsOneWidget);
    expect(find.text(Strings.moveDown), findsOneWidget);
    expect(find.text(Strings.delete), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('Mover para baixo pelo menu reordena', (tester) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['A', 'B', 'C']));

    await _openMenu(tester, 'A');
    await tester.tap(find.text(Strings.moveDown));
    await tester.pumpAndSettle();

    expect(_top(tester, 'B'), lessThan(_top(tester, 'A')));
    expect(_top(tester, 'A'), lessThan(_top(tester, 'C')));
  });

  testWidgets('arrastar pela alça reordena', (tester) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['A', 'B', 'C']));
    final rowHeight = _top(tester, 'B') - _top(tester, 'A');

    await _dragHandle(tester, 'A', rowHeight * 2);

    expect(_top(tester, 'B'), lessThan(_top(tester, 'A')));
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('rolar com o dedo sobre os itens não move nem marca', (
    tester,
  ) async {
    final names = [for (var i = 1; i <= 20; i++) 'Item $i'];
    await pumpApp(tester, seed: (repo) => seedList(repo, names));

    await tester.drag(find.text('Item 3'), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Item 8'), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(_top(tester, 'Item 1'), lessThan(_top(tester, 'Item 2')));
    expect(_top(tester, 'Item 2'), lessThan(_top(tester, 'Item 3')));
  });

  testWidgets('item comprado não exibe a alça nem "Mover"', (tester) async {
    await pumpApp(
      tester,
      seed: (repo) => seedList(repo, ['A', 'B'], checked: ['B']),
    );

    expect(_handleOf('A'), findsOneWidget);
    expect(_handleOf('B'), findsNothing);

    await _openMenu(tester, 'B');
    expect(find.text(Strings.moveUp), findsNothing);
    expect(find.text(Strings.moveDown), findsNothing);
    expect(find.text(Strings.delete), findsOneWidget);
  });

  testWidgets('editar pelo menu muda nome e quantidade', (tester) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['Arroz']));

    await _openMenu(tester, 'Arroz');
    await tester.tap(find.text(Strings.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-dialog-name')), 'Feijão');
    await tester.enterText(
      find.byKey(const Key('item-dialog-quantity')),
      '2 kg',
    );
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    expect(find.text('Feijão'), findsOneWidget);
    expect(find.text('2 kg'), findsOneWidget);
    expect(find.text('Arroz'), findsNothing);
  });

  testWidgets('apagar mostra "Desfazer", e desfazer restaura o item', (
    tester,
  ) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['A', 'B', 'C']));

    await _openMenu(tester, 'B');
    await tester.tap(find.text(Strings.delete));
    await tester.pumpAndSettle();

    expect(find.text('B'), findsNothing);
    expect(find.text(Strings.itemDeleted('B')), findsOneWidget);

    await tester.tap(find.text(Strings.undo));
    await tester.pumpAndSettle();

    expect(_top(tester, 'A'), lessThan(_top(tester, 'B')));
    expect(_top(tester, 'B'), lessThan(_top(tester, 'C')));
  });
}
