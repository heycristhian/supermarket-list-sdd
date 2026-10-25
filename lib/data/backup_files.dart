import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Salva e abre arquivos de backup pelo seletor do sistema (research.md R7).
/// Na web, salvar faz o download do arquivo.
class BackupFiles {
  const BackupFiles();

  /// `true` se o arquivo foi salvo; `false` se o usuário cancelou.
  Future<bool> saveBackup(Uint8List bytes, DateTime now) async {
    final uri = await FilePicker.saveFile(
      fileName: backupFileName(now),
      bytes: bytes,
      mimeType: 'application/json',
    );
    return uri != null;
  }

  /// O conteúdo do arquivo escolhido, ou `null` se o usuário cancelou.
  /// Aceita qualquer tipo de arquivo: filtrar por `.json` falha em alguns
  /// Androids, e a validação do conteúdo já rejeita o que não for backup.
  Future<Uint8List?> pickBackup() async {
    final file = await FilePicker.pickFile();
    return file?.readAsBytes();
  }
}

/// `listas-supermercado-AAAA-MM-DD.json` (contracts/backup-file.md).
String backupFileName(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'listas-supermercado-${now.year}-${two(now.month)}-${two(now.day)}.json';
}
