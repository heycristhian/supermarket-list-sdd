import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/data/backup_files.dart';
import 'package:supermarket_list/domain/backup_codec.dart';
import 'package:supermarket_list/state/providers.dart';
import 'package:supermarket_list/ui/strings.dart';

import '../support/pump_app.dart';

/// Seletor de arquivos em memória.
class FakeBackupFiles extends BackupFiles {
  FakeBackupFiles({this.toPick, this.cancelSave = false});

  Uint8List? toPick;
  final bool cancelSave;
  Uint8List? saved;
  String? savedName;

  @override
  Future<bool> saveBackup(Uint8List bytes, DateTime now) async {
    if (cancelSave) return false;
    saved = bytes;
    savedName = backupFileName(now);
    return true;
  }

  @override
  Future<Uint8List?> pickBackup() async => toPick;
}

final _backupWithPizza = encodeBackup(
  BackupData(
    exportedAt: DateTime.utc(2026, 10, 1),
    activeListIndex: 0,
    lists: const [
      BackupList(
        name: 'Pizza',
        position: 0,
        items: [BackupItem(name: 'Massa', position: 0)],
      ),
    ],
  ),
);

Future<void> _pumpLists(WidgetTester tester, FakeBackupFiles files) async {
  await pumpApp(
    tester,
    seed: (repo) => seedList(repo, ['Arroz']),
    overrides: [backupFilesProvider.overrideWithValue(files)],
  );
  await tester.tap(find.byTooltip(Strings.openLists));
  await tester.pumpAndSettle();
}

Future<void> _chooseBackupAction(WidgetTester tester, String action) async {
  await tester.tap(find.byTooltip(Strings.backupMenu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

Finder _dialogButton(String label) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

void main() {
  testWidgets('o lembrete aparece e "Agora não" o esconde', (tester) async {
    await _pumpLists(tester, FakeBackupFiles());
    expect(find.text(Strings.reminderText), findsOneWidget);

    await tester.tap(find.text(Strings.reminderDismiss));
    await tester.pumpAndSettle();

    expect(find.text(Strings.reminderText), findsNothing);
  });

  testWidgets('exportar salva o arquivo e esconde o lembrete', (tester) async {
    final files = FakeBackupFiles();
    await _pumpLists(tester, files);

    await _chooseBackupAction(tester, Strings.exportBackup);

    expect(files.saved, isNotNull);
    expect(files.savedName, 'listas-supermercado-2026-10-24.json');
    final json = jsonDecode(utf8.decode(files.saved!));
    expect(json['lists'].single['name'], 'Semanal');
    expect(find.text(Strings.backupSaved), findsOneWidget);
    expect(find.text(Strings.reminderText), findsNothing);
  });

  testWidgets('cancelar a exportação mantém o lembrete', (tester) async {
    await _pumpLists(tester, FakeBackupFiles(cancelSave: true));

    await _chooseBackupAction(tester, Strings.exportBackup);

    expect(find.text(Strings.backupSaved), findsNothing);
    expect(find.text(Strings.reminderText), findsOneWidget);
  });

  testWidgets('"Fazer backup" no lembrete exporta', (tester) async {
    final files = FakeBackupFiles();
    await _pumpLists(tester, files);

    await tester.tap(find.text(Strings.reminderAction));
    await tester.pumpAndSettle();

    expect(files.saved, isNotNull);
  });

  testWidgets('arquivo inválido mostra o motivo e não altera nada', (
    tester,
  ) async {
    await _pumpLists(
      tester,
      FakeBackupFiles(toPick: Uint8List.fromList(utf8.encode('olá'))),
    );

    await _chooseBackupAction(tester, Strings.importBackup);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('não é um backup'), findsOneWidget);
    expect(find.text('Semanal'), findsOneWidget);
  });

  testWidgets('importar pede confirmação, e cancelar não altera nada', (
    tester,
  ) async {
    await _pumpLists(tester, FakeBackupFiles(toPick: _backupWithPizza));

    await _chooseBackupAction(tester, Strings.importBackup);
    expect(find.text(Strings.importTitle), findsOneWidget);
    await tester.tap(_dialogButton(Strings.cancel));
    await tester.pumpAndSettle();

    expect(find.text('Semanal'), findsOneWidget);
    expect(find.text('Pizza'), findsNothing);
  });

  testWidgets('importar confirmado substitui todos os dados', (tester) async {
    await _pumpLists(tester, FakeBackupFiles(toPick: _backupWithPizza));

    await _chooseBackupAction(tester, Strings.importBackup);
    await tester.tap(_dialogButton(Strings.importConfirm));
    await tester.pumpAndSettle();

    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Semanal'), findsNothing);
    expect(find.text(Strings.activeBadge), findsOneWidget);
    expect(find.text(Strings.importDone), findsOneWidget);
    expect(find.text(Strings.reminderText), findsNothing);
  });
}
