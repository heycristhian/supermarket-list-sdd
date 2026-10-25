import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/state/providers.dart';
import 'package:supermarket_list/ui/strings.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('sem armazenamento persistente, o aviso aparece nas duas telas', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (repo) => seedList(repo, ['Arroz']),
      overrides: [
        storageVolatileProvider.overrideWithValue(ValueNotifier(true)),
      ],
    );
    expect(find.text(Strings.volatileStorage), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.openLists));
    await tester.pumpAndSettle();
    expect(find.text(Strings.volatileStorage), findsOneWidget);
  });

  testWidgets('com armazenamento persistente, não há aviso', (tester) async {
    await pumpApp(tester, seed: (repo) => seedList(repo, ['Arroz']));
    expect(find.text(Strings.volatileStorage), findsNothing);
  });
}
