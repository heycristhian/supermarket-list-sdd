/// Intervalo do lembrete de backup e do adiamento ao dispensá-lo (FR-034).
const backupReminderInterval = Duration(days: 7);

/// Regra de research.md R12: há alterações desde o último backup, ele foi
/// feito há 7 dias ou mais (ou nunca), e o lembrete não está adiado.
bool shouldShowReminder({
  required DateTime now,
  required DateTime? lastBackupAt,
  required DateTime? lastChangeAt,
  required DateTime? snoozedUntil,
}) {
  if (lastChangeAt == null) return false;
  if (lastBackupAt != null) {
    if (!lastChangeAt.isAfter(lastBackupAt)) return false;
    if (now.isBefore(lastBackupAt.add(backupReminderInterval))) return false;
  }
  return snoozedUntil == null || !now.isBefore(snoozedUntil);
}
