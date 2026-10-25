import 'models.dart';

/// Não comprados pela ordem original; depois os comprados, na ordem em que
/// foram marcados.
List<ShoppingItem> displayOrder(Iterable<ShoppingItem> items) {
  final unchecked = items.where((i) => !i.isChecked).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  final checked = items.where((i) => i.isChecked).toList()
    ..sort((a, b) => a.checkedSeq!.compareTo(b.checkedSeq!));
  return [...unchecked, ...checked];
}

int nextCheckedSeq(Iterable<ShoppingItem> items) =>
    items.fold(0, (max, i) => (i.checkedSeq ?? 0) > max ? i.checkedSeq! : max) +
    1;

/// Reordena só os registros móveis, devolvendo-os aos mesmos "slots" que
/// ocupavam; os fixos não saem do lugar (research.md R9).
///
/// [oldIndex] e [newIndex] são índices dentro da sequência de móveis, e
/// [newIndex] já é o índice final do registro movido. Devolve a nova
/// `position` (0..n-1) de todos os ids.
Map<int, int> reorderIntoSlots({
  required List<int> idsByPosition,
  required bool Function(int id) isMovable,
  required int oldIndex,
  required int newIndex,
}) {
  final slots = <int>[];
  final movable = <int>[];
  for (var slot = 0; slot < idsByPosition.length; slot++) {
    if (isMovable(idsByPosition[slot])) {
      slots.add(slot);
      movable.add(idsByPosition[slot]);
    }
  }
  movable.insert(newIndex, movable.removeAt(oldIndex));

  final result = List.of(idsByPosition);
  for (var i = 0; i < slots.length; i++) {
    result[slots[i]] = movable[i];
  }
  return {for (var i = 0; i < result.length; i++) result[i]: i};
}
