import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/domain/errors.dart';
import 'package:supermarket_list/ui/strings.dart';
import 'package:supermarket_list/ui/widgets/name_dialog.dart';

import '../support/pump_app.dart';

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

Finder _menuOf(String name) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(Card)),
  matching: find.byTooltip(Strings.listMenu),
);

Finder get _uncheckAllButton => find.ancestor(
  of: find.byTooltip(Strings.uncheckAll),
  matching: find.byType(IconButton),
);

Future<void> _openCopyDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip(Strings.openLists));
  await tester.pumpAndSettle();
  await tester.tap(_menuOf('Semanal'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(Strings.copy));
  await tester.pumpAndSettle();
}

Finder _dialogButton(String label) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

void main() {
  group('Copiar', () {
    testWidgets('abre o diálogo já preenchido com "X (cópia)"', (tester) async {
      await pumpApp(tester, seed: (repo) => seedList(repo, ['Arroz']));

      await _openCopyDialog(tester);

      final field = tester.widget<TextField>(find.byKey(NameDialog.fieldKey));
      expect(field.controller!.text, 'Semanal (cópia)');

      await tester.tap(_dialogButton(Strings.copy));
      await tester.pumpAndSettle();
      expect(find.text('Semanal (cópia)'), findsOneWidget);
    });

    testWidgets('cancelar não cria lista', (tester) async {
      await pumpApp(tester, seed: (repo) => seedList(repo, ['Arroz']));

      await _openCopyDialog(tester);
      await tester.tap(find.text(Strings.cancel));
      await tester.pumpAndSettle();

      expect(find.text('Semanal (cópia)'), findsNothing);
      expect(find.text(Strings.otherListsSection), findsNothing);
    });

    testWidgets('título existente mostra erro e mantém o texto', (
      tester,
    ) async {
      await pumpApp(tester, seed: (repo) => seedList(repo, ['Arroz']));

      await _openCopyDialog(tester);
      await tester.enterText(find.byKey(NameDialog.fieldKey), 'semanal');
      await tester.tap(_dialogButton(Strings.copy));
      await tester.pumpAndSettle();

      expect(
        find.text(const DuplicateNameException.list().message),
        findsOneWidget,
      );
      final field = tester.widget<TextField>(find.byKey(NameDialog.fieldKey));
      expect(field.controller!.text, 'semanal');
    });
  });

  group('Desmarcar todos', () {
    testWidgets('pede confirmação e volta à ordem original', (tester) async {
      await pumpApp(
        tester,
        seed: (repo) => seedList(repo, ['A', 'B', 'C'], checked: ['A']),
      );
      expect(_top(tester, 'C'), lessThan(_top(tester, 'A')));

      await tester.tap(_uncheckAllButton);
      await tester.pumpAndSettle();
      await tester.tap(_dialogButton(Strings.uncheckAllConfirm));
      await tester.pumpAndSettle();

      expect(_top(tester, 'A'), lessThan(_top(tester, 'B')));
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('cancelar não altera nada', (tester) async {
      await pumpApp(
        tester,
        seed: (repo) => seedList(repo, ['A', 'B'], checked: ['A']),
      );

      await tester.tap(_uncheckAllButton);
      await tester.pumpAndSettle();
      expect(find.text(Strings.uncheckAllTitle), findsOneWidget);
      await tester.tap(find.text(Strings.cancel));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('fica desabilitado sem itens comprados', (tester) async {
      await pumpApp(tester, seed: (repo) => seedList(repo, ['A', 'B']));

      expect(tester.widget<IconButton>(_uncheckAllButton).onPressed, isNull);
    });
  });
}
