import 'errors.dart';

const maxNameLength = 80;
const maxQuantityLength = 40;

final _spaces = RegExp(r'\s+');

/// O nome como será guardado: sem espaços nas pontas.
String normalizeName(String raw) => raw.trim();

/// Chave de comparação: espaços colapsados e minúsculas, acentos mantidos.
String normalizeKey(String name) =>
    name.trim().replaceAll(_spaces, ' ').toLowerCase();

/// Valida e normaliza um nome de lista ou de item.
String validateName(String raw) {
  final name = normalizeName(raw);
  if (name.isEmpty) throw const EmptyNameException();
  if (name.length > maxNameLength) {
    throw const NameTooLongException(maxNameLength);
  }
  return name;
}

/// Nome sugerido para a cópia de [original]: "X (cópia)", ou "X (cópia N)"
/// se já existir (FR-004). [existingKeys] são as chaves (`normalizeKey`) das
/// listas existentes. O nome base é encurtado para caber em
/// [maxNameLength].
String suggestCopyName(String original, Set<String> existingKeys) {
  String build(int n) {
    final suffix = n == 1 ? ' (cópia)' : ' (cópia $n)';
    final base = original.length + suffix.length > maxNameLength
        ? original.substring(0, maxNameLength - suffix.length).trimRight()
        : original;
    return '$base$suffix';
  }

  var n = 1;
  while (existingKeys.contains(normalizeKey(build(n)))) {
    n++;
  }
  return build(n);
}

/// Quantidade em texto livre; vazia vira `null`.
String? normalizeQuantity(String? raw) {
  final quantity = raw?.trim();
  if (quantity == null || quantity.isEmpty) return null;
  if (quantity.length > maxQuantityLength) {
    throw const NameTooLongException(maxQuantityLength);
  }
  return quantity;
}
