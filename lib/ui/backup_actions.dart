import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/backup_codec.dart';
import '../domain/errors.dart';
import '../state/providers.dart';
import 'strings.dart';
import 'theme/tokens.dart';
import 'widgets/confirm_dialog.dart';

/// Exporta para um arquivo; só conta como backup feito se o arquivo foi
/// salvo (FR-031).
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(repositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await repo.exportBackup();
    final saved = await ref
        .read(backupFilesProvider)
        .saveBackup(bytes, ref.read(clockProvider)());
    if (!saved) return;
    await repo.markBackupDone();
    messenger.showSnackBar(const SnackBar(content: Text(Strings.backupSaved)));
  } on Exception {
    _showError(messenger, Strings.backupSaveFailed);
  }
}

/// Escolhe um arquivo, valida tudo e só então pede confirmação para
/// substituir os dados (FR-032, FR-033).
Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(repositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final bytes = await ref.read(backupFilesProvider).pickBackup();
  if (bytes == null) return;

  final BackupData data;
  try {
    data = repo.parseBackup(bytes);
  } on InvalidBackupException catch (e) {
    _showError(messenger, e.message);
    return;
  }
  if (!context.mounted) return;

  final confirmed = await showConfirmDialog(
    context,
    title: Strings.importTitle,
    message: Strings.importMessage,
    confirmLabel: Strings.importConfirm,
  );
  if (!confirmed) return;
  try {
    await repo.importBackup(data);
    messenger.showSnackBar(const SnackBar(content: Text(Strings.importDone)));
  } on Exception {
    _showError(messenger, Strings.importFailed);
  }
}

/// Erro com ícone + texto: a marca não tem cor de erro (research.md R14).
void _showError(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(
    SnackBar(
      content: Builder(
        builder: (context) {
          final color = Theme.of(context).colorScheme.onInverseSurface;
          return Row(
            children: [
              Icon(Icons.error_outline, color: color),
              const SizedBox(width: Tokens.spaceSm),
              Expanded(child: Text(message)),
            ],
          );
        },
      ),
    ),
  );
}
