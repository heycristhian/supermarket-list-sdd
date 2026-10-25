import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../backup_actions.dart';
import '../strings.dart';

/// Faixa discreta que lembra de fazer backup; não cobre a lista nem exige
/// resposta (FR-034, FR-035).
class BackupReminderBanner extends ConsumerWidget {
  const BackupReminderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(backupReminderProvider).value ?? false;
    if (!show) return const SizedBox.shrink();

    return MaterialBanner(
      leading: const Icon(Icons.backup_outlined),
      content: const Text(Strings.reminderText),
      actions: [
        TextButton(
          onPressed: () => ref.read(repositoryProvider).snoozeBackupReminder(),
          child: const Text(Strings.reminderDismiss),
        ),
        TextButton(
          onPressed: () => exportBackup(context, ref),
          child: const Text(Strings.reminderAction),
        ),
      ],
    );
  }
}
