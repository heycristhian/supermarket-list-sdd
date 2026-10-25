import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/domain/errors.dart';
import 'package:supermarket_list/ui/strings.dart';
import 'package:supermarket_list/ui/theme/brand_theme.dart';
import 'package:supermarket_list/ui/widgets/add_item_bar.dart';

import '../support/pump_app.dart';

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

final _nameField = find.byKey(AddItemBar.nameFieldKey);

bool _nameFieldHasFocus(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(of: _nameField, matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

Future<void> _addItem(WidgetTester tester, String name) async {
  await tester.enterText(_nameField, name);
  await tester.tap(find.byTooltip(Strings.addItem));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem lista ativa, a home é a tela de listas', (tester) async {
    await pumpApp(tester);
    expect(find.text(Strings.noListsTitle), findsOneWidget);
  });

  testWidgets('com lista ativa, a home é a tela de itens dela', (tester) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['Arroz']));
    expect(find.text('Semanal'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
  });

  testWidgets('tocar no item marca, manda para o fim e muda o estilo', (
    tester,
  ) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['A', 'B', 'C']));

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    expect(_top(tester, 'B'), lessThan(_top(tester, 'C')));
    expect(_top(tester, 'C'), lessThan(_top(tester, 'A')));
    final style = tester.widget<Text>(find.text('A')).style!;
    final context = tester.element(find.text('A'));
    expect(style.decoration, TextDecoration.lineThrough);
    expect(style.color, context.brand.checkedItemText);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('o campo do rodapé limpa e mantém o foco após adicionar', (
    tester,
  ) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, []));

    await _addItem(tester, 'Arroz');

    expect(find.text('Arroz'), findsOneWidget);
    final field = tester.widget<TextField>(_nameField);
    expect(field.controller!.text, isEmpty);
    expect(_nameFieldHasFocus(tester), isTrue);
  });

  testWidgets('nome repetido mostra o erro e mantém o texto', (tester) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['Arroz']));

    await _addItem(tester, 'arroz');

    expect(
      find.text(const DuplicateNameException.item().message),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(_nameField).controller!.text, 'arroz');
  });

  testWidgets('nome com 81 caracteres é rejeitado e o texto é mantido', (
    tester,
  ) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, []));
    final longName = 'a' * 81;

    await _addItem(tester, longName);

    expect(find.text(const NameTooLongException(80).message), findsOneWidget);
    expect(tester.widget<TextField>(_nameField).controller!.text, longName);
  });

  testWidgets('um toque na tela de itens abre a tela de listas', (
    tester,
  ) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['Arroz']));

    await tester.tap(find.byTooltip(Strings.openLists));
    await tester.pumpAndSettle();

    expect(find.text(Strings.listsTitle), findsOneWidget);
  });

  testWidgets('mostra o progresso e avisa quando a lista é concluída', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (repo) =>
          seedList(repo, ['A', 'B', 'C', 'D', 'E'], checked: ['A', 'B']),
    );
    expect(find.text(Strings.progress(2, 5)), findsOneWidget);
    expect(find.text(Strings.listComplete), findsNothing);

    for (final name in ['C', 'D', 'E']) {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    expect(find.text(Strings.progress(5, 5)), findsOneWidget);
    expect(find.text(Strings.listComplete), findsOneWidget);
  });
}
