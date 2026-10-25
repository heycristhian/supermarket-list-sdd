class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    required this.position,
    this.totalItems = 0,
    this.checkedItems = 0,
  });

  final int id;
  final String name;
  final int position;
  final int totalItems;
  final int checkedItems;

  bool get isComplete => totalItems > 0 && checkedItems == totalItems;
}

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.position,
    this.quantity,
    this.checkedSeq,
  });

  final int id;
  final int listId;
  final String name;
  final String? quantity;

  /// Slot na ordem original da lista.
  final int position;

  /// `null` = não comprado; senão, a ordem em que foi marcado.
  final int? checkedSeq;

  bool get isChecked => checkedSeq != null;
}

/// Tela de listas: a ativa (se houver) e as demais na ordem do usuário.
class ListsOverview {
  const ListsOverview({required this.active, required this.others});

  final ShoppingList? active;
  final List<ShoppingList> others;

  bool get isEmpty => active == null && others.isEmpty;
}

/// Tudo o que é preciso para desfazer a remoção de um item.
class DeletedItem {
  const DeletedItem({
    required this.listId,
    required this.name,
    required this.position,
    this.quantity,
    this.checkedSeq,
  });

  final int listId;
  final String name;
  final String? quantity;
  final int position;
  final int? checkedSeq;
}
