import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/domain/errors.dart';
import 'package:supermarket_list/domain/name_rules.dart';

void main() {
  group('normalizeName', () {
    test('remove espaços das pontas', () {
      expect(normalizeName(' Arroz '), 'Arroz');
    });
  });

  group('normalizeKey', () {
    test('colapsa espaços e ignora maiúsculas/minúsculas', () {
      expect(normalizeKey('  Arroz   Integral '), 'arroz integral');
      expect(normalizeKey('ARROZ'), normalizeKey('arroz'));
    });

    test('mantém acentos', () {
      expect(normalizeKey('Feijão'), isNot(normalizeKey('Feijao')));
    });
  });

  group('validateName', () {
    test('devolve o nome normalizado', () {
      expect(validateName('  Lista semanal '), 'Lista semanal');
    });

    test('vazio ou só espaços é rejeitado', () {
      expect(() => validateName(''), throwsA(isA<EmptyNameException>()));
      expect(() => validateName('   '), throwsA(isA<EmptyNameException>()));
    });

    test('aceita 80 caracteres e rejeita 81', () {
      expect(validateName('a' * maxNameLength), hasLength(maxNameLength));
      expect(
        () => validateName('a' * (maxNameLength + 1)),
        throwsA(isA<NameTooLongException>()),
      );
    });

    test('o limite é contado depois de remover as pontas', () {
      expect(validateName('  ${'a' * maxNameLength}  '), hasLength(80));
    });
  });

  group('suggestCopyName', () {
    Set<String> keys(List<String> names) => names.map(normalizeKey).toSet();

    test('sugere "X (cópia)"', () {
      expect(
        suggestCopyName('Lista Hambúrguer', keys(['Lista Hambúrguer'])),
        'Lista Hambúrguer (cópia)',
      );
    });

    test('numera quando a cópia já existe', () {
      expect(
        suggestCopyName(
          'Lista Hambúrguer',
          keys(['Lista Hambúrguer', 'Lista Hambúrguer (cópia)']),
        ),
        'Lista Hambúrguer (cópia 2)',
      );
      expect(
        suggestCopyName(
          'Lista Hambúrguer',
          keys([
            'Lista Hambúrguer',
            'Lista Hambúrguer (cópia)',
            'Lista Hambúrguer (cópia 2)',
          ]),
        ),
        'Lista Hambúrguer (cópia 3)',
      );
    });

    test('compara com normalizeKey', () {
      expect(
        suggestCopyName('Pizza', keys(['Pizza', 'PIZZA  (CÓPIA)'])),
        'Pizza (cópia 2)',
      );
    });

    test('encurta o nome para a sugestão caber no limite', () {
      final suggestion = suggestCopyName('a' * maxNameLength, {});
      expect(suggestion, hasLength(maxNameLength));
      expect(suggestion, endsWith(' (cópia)'));
    });
  });

  group('normalizeQuantity', () {
    test('vazia ou só espaços vira null', () {
      expect(normalizeQuantity(null), isNull);
      expect(normalizeQuantity('  '), isNull);
    });

    test('remove espaços das pontas', () {
      expect(normalizeQuantity(' 2 kg '), '2 kg');
    });

    test('rejeita mais de 40 caracteres', () {
      expect(normalizeQuantity('a' * maxQuantityLength), hasLength(40));
      expect(
        () => normalizeQuantity('a' * (maxQuantityLength + 1)),
        throwsA(isA<NameTooLongException>()),
      );
    });
  });
}
