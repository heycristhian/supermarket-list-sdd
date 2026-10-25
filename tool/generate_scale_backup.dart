// Gera test/fixtures/backup_50x100.json (research.md R20): 50 listas com 100
// itens cada, metade comprados, para o teste de escala.
//
//   dart run tool/generate_scale_backup.dart
import 'dart:io';

import 'package:supermarket_list/domain/backup_codec.dart';

const _lists = 50;
const _itemsPerList = 100;
const _quantities = [null, '1 kg', '2 un', '500 g', '1 dúzia', '3 latas'];

void main() {
  String pad(int n, int width) => n.toString().padLeft(width, '0');

  final data = BackupData(
    exportedAt: DateTime.utc(2026, 10, 24),
    activeListIndex: 0,
    lists: [
      for (var l = 0; l < _lists; l++)
        BackupList(
          name: 'Lista ${pad(l + 1, 2)}',
          position: l,
          items: [
            for (var i = 0; i < _itemsPerList; i++)
              BackupItem(
                name: 'Item ${pad(i + 1, 3)}',
                quantity: _quantities[i % _quantities.length],
                position: i,
                // Metade comprada: os ímpares, na ordem em que aparecem.
                checkedSeq: i.isOdd ? i ~/ 2 + 1 : null,
              ),
          ],
        ),
    ],
  );

  final file = File('test/fixtures/backup_50x100.json')
    ..createSync(recursive: true)
    ..writeAsBytesSync(encodeBackup(data));
  stdout.writeln(
    '${file.path}: ${(file.lengthSync() / 1024).toStringAsFixed(0)} KB',
  );
}
