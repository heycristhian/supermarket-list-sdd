import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/domain/backup_codec.dart';
import 'package:supermarket_list/domain/errors.dart';

Uint8List _bytes(Object json) =>
    Uint8List.fromList(utf8.encode(jsonEncode(json)));

Map<String, dynamic> _validJson() => {
  'format': 'supermarket-list-backup',
  'version': 1,
  'exportedAt': '2026-10-24T18:30:00.000Z',
  'activeListIndex': 0,
  'lists': [
    {
      'name': 'Lista semanal',
      'position': 0,
      'items': [
        {
          'name': 'Arroz',
          'quantity': '5 kg',
          'position': 0,
          'checkedSeq': null,
        },
        {'name': 'Feijão', 'quantity': null, 'position': 1, 'checkedSeq': 1},
      ],
    },
    {'name': 'Pizza', 'position': 1, 'items': <Object>[]},
  ],
};

Matcher _invalid([String? containing]) => throwsA(
  isA<InvalidBackupException>().having(
    (e) => e.message,
    'message',
    containing == null ? isNotEmpty : contains(containing),
  ),
);

void main() {
  test('ida e volta: encode ⇒ decode preserva tudo', () {
    final data = BackupData(
      exportedAt: DateTime.utc(2026, 10, 24, 18, 30),
      activeListIndex: 1,
      lists: const [
        BackupList(
          name: 'Semanal',
          position: 0,
          items: [
            BackupItem(name: 'Arroz', quantity: '5 kg', position: 0),
            BackupItem(name: 'Feijão', position: 1, checkedSeq: 1),
          ],
        ),
        BackupList(name: 'Pizza', position: 1, items: []),
      ],
    );

    final decoded = decodeBackup(encodeBackup(data));

    expect(decoded.exportedAt, data.exportedAt);
    expect(decoded.activeListIndex, 1);
    expect(decoded.lists.map((l) => l.name), ['Semanal', 'Pizza']);
    final items = decoded.lists.first.items;
    expect(items.map((i) => i.name), ['Arroz', 'Feijão']);
    expect(items.map((i) => i.quantity), ['5 kg', null]);
    expect(items.map((i) => i.checkedSeq), [null, 1]);
  });

  test('o arquivo usa o formato do contrato', () {
    final json = jsonDecode(
      utf8.decode(
        encodeBackup(
          BackupData(
            exportedAt: DateTime.utc(2026),
            activeListIndex: null,
            lists: const [],
          ),
        ),
      ),
    );
    expect(json['format'], 'supermarket-list-backup');
    expect(json['version'], 1);
    expect(json['activeListIndex'], isNull);
    expect(json['lists'], isEmpty);
  });

  test('aceita o exemplo do contrato', () {
    final data = decodeBackup(_bytes(_validJson()));
    expect(data.lists, hasLength(2));
    expect(data.activeListIndex, 0);
  });

  group('rejeita', () {
    test('JSON inválido', () {
      expect(
        () => decodeBackup(Uint8List.fromList(utf8.encode('{nada'))),
        _invalid(),
      );
      expect(() => decodeBackup(_bytes([1, 2])), _invalid());
    });

    test('format errado', () {
      expect(
        () => decodeBackup(_bytes(_validJson()..['format'] = 'outro')),
        _invalid(),
      );
    });

    test('versão mais nova', () {
      expect(
        () => decodeBackup(_bytes(_validJson()..['version'] = 2)),
        _invalid('versão mais nova'),
      );
    });

    test('campo obrigatório ausente', () {
      for (final field in ['format', 'version', 'activeListIndex', 'lists']) {
        expect(
          () => decodeBackup(_bytes(_validJson()..remove(field))),
          _invalid(),
          reason: field,
        );
      }
      final json = _validJson();
      (json['lists'] as List).first['items'].first.remove('quantity');
      expect(() => decodeBackup(_bytes(json)), _invalid());
    });

    test('tipo errado', () {
      final json = _validJson();
      (json['lists'] as List).first['position'] = 'zero';
      expect(() => decodeBackup(_bytes(json)), _invalid());

      final json2 = _validJson();
      (json2['lists'] as List).first['items'].first['checkedSeq'] = 0;
      expect(() => decodeBackup(_bytes(json2)), _invalid());
    });

    test('nomes de lista repetidos', () {
      final json = _validJson();
      (json['lists'] as List)[1]['name'] = ' lista  SEMANAL ';
      expect(() => decodeBackup(_bytes(json)), _invalid('repetid'));
    });

    test('itens repetidos na mesma lista', () {
      final json = _validJson();
      (json['lists'] as List).first['items'][1]['name'] = 'arroz';
      expect(() => decodeBackup(_bytes(json)), _invalid('repetid'));
    });

    test('nome vazio ou longo demais', () {
      final json = _validJson();
      (json['lists'] as List).first['name'] = '   ';
      expect(() => decodeBackup(_bytes(json)), _invalid());

      final json2 = _validJson();
      (json2['lists'] as List).first['items'].first['name'] = 'a' * 81;
      expect(() => decodeBackup(_bytes(json2)), _invalid());
    });

    test('activeListIndex fora dos limites', () {
      expect(
        () => decodeBackup(_bytes(_validJson()..['activeListIndex'] = 2)),
        _invalid(),
      );
      expect(
        () => decodeBackup(_bytes(_validJson()..['activeListIndex'] = -1)),
        _invalid(),
      );
    });
  });

  test('ignora campos desconhecidos', () {
    final json = _validJson()..['extra'] = {'qualquer': true};
    (json['lists'] as List).first['cor'] = 'azul';
    expect(decodeBackup(_bytes(json)).lists, hasLength(2));
  });

  test('renumera position e checkedSeq mantendo a ordem relativa', () {
    final json = _validJson();
    json['activeListIndex'] = 0;
    json['lists'] = [
      {
        'name': 'Segunda',
        'position': 50,
        'items': [
          {'name': 'C', 'quantity': null, 'position': 30, 'checkedSeq': 9},
          {'name': 'A', 'quantity': null, 'position': 10, 'checkedSeq': null},
          {'name': 'B', 'quantity': null, 'position': 20, 'checkedSeq': 4},
        ],
      },
      {'name': 'Primeira', 'position': 7, 'items': <Object>[]},
    ];

    final data = decodeBackup(_bytes(json));

    expect(data.lists.map((l) => l.name), ['Primeira', 'Segunda']);
    expect(data.lists.map((l) => l.position), [0, 1]);
    // O índice ativo continua apontando para a mesma lista.
    expect(data.lists[data.activeListIndex!].name, 'Segunda');
    final items = data.lists[1].items;
    expect(items.map((i) => i.name), ['A', 'B', 'C']);
    expect(items.map((i) => i.position), [0, 1, 2]);
    expect(items.map((i) => i.checkedSeq), [null, 1, 2]);
  });
}
