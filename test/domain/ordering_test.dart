import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/domain/models.dart';
import 'package:supermarket_list/domain/ordering.dart';

ShoppingItem _item(int id, String name, int position, [int? checkedSeq]) =>
    ShoppingItem(
      id: id,
      listId: 1,
      name: name,
      position: position,
      checkedSeq: checkedSeq,
    );

void main() {
  group('displayOrder', () {
    test('não comprados por position, depois comprados por checkedSeq', () {
      final items = [
        _item(1, 'A', 0, 2),
        _item(2, 'B', 1),
        _item(3, 'C', 2, 1),
        _item(4, 'D', 3),
      ];
      expect(displayOrder(items).map((i) => i.name), ['B', 'D', 'C', 'A']);
    });
  });

  group('nextCheckedSeq', () {
    test('é 1 quando nada foi marcado', () {
      expect(nextCheckedSeq([_item(1, 'A', 0)]), 1);
    });

    test('é o maior checkedSeq + 1', () {
      expect(nextCheckedSeq([_item(1, 'A', 0, 3), _item(2, 'B', 1, 7)]), 8);
    });
  });

  group('reorderIntoSlots', () {
    // Exemplo de research.md R9: A,B,C,D com B comprado; D vai para o início
    // dos não comprados.
    test('usa os slots dos itens móveis e preserva os fixos', () {
      final positions = reorderIntoSlots(
        idsByPosition: [1, 2, 3, 4],
        isMovable: (id) => id != 2,
        oldIndex: 2,
        newIndex: 0,
      );
      expect(positions, {4: 0, 2: 1, 1: 2, 3: 3});
    });

    test('mover para o mesmo índice não altera nada', () {
      final positions = reorderIntoSlots(
        idsByPosition: [1, 2, 3],
        isMovable: (_) => true,
        oldIndex: 1,
        newIndex: 1,
      );
      expect(positions, {1: 0, 2: 1, 3: 2});
    });

    test('mover para baixo coloca o item no índice final indicado', () {
      final positions = reorderIntoSlots(
        idsByPosition: [1, 2, 3],
        isMovable: (_) => true,
        oldIndex: 0,
        newIndex: 2,
      );
      expect(positions, {2: 0, 3: 1, 1: 2});
    });

    test('compacta positions com buracos', () {
      final positions = reorderIntoSlots(
        idsByPosition: [5, 9],
        isMovable: (_) => true,
        oldIndex: 0,
        newIndex: 0,
      );
      expect(positions, {5: 0, 9: 1});
    });
  });
}
