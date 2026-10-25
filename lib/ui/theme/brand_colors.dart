import 'package:flutter/painting.dart';

/// Paleta T_YOU (docs/marca.md) e os únicos tons derivados permitidos
/// (Constituição VI). Contrastes calculados pela fórmula do WCAG 2.1 e
/// verificados em test/theme/contrast_test.dart.
abstract final class BrandColors {
  // Paleta oficial.
  static const grayDark = Color(0xFF4C4E53); // PANTONE 7540 C
  static const grayMedium = Color(0xFF767678); // PANTONE Cool Gray 9 C
  static const turquoise = Color(0xFF00A5B4); // PANTONE 7710 C
  static const white = Color(0xFFFEFEFE); // PANTONE Trans White

  // Cor de apoio, confirmada no vetor do manual (pág. 17).
  static const grayLight = Color(0xFFE6E7E8);

  // Tons de acessibilidade (research.md R14).

  /// Turquesa escurecido: branco sobre ele 6,2:1; sobre [grayLight] 5,05:1.
  /// O turquesa oficial com texto branco fica em 2,96:1.
  static const turquoiseDark = Color(0xFF006B75);

  /// Turquesa clareado 50%: sobre [grayDark] 4,81:1 (o oficial dá 2,79:1).
  static const turquoiseLight = Color(0xFF7FD2D9);

  /// Cinza médio escurecido para texto de item comprado sobre [white]:
  /// 5,27:1 ([grayMedium] fica em 4,49:1).
  static const grayMediumAccessible = Color(0xFF6B6B6D);

  /// Item comprado no tema escuro: 4,82:1 sobre [grayDark]
  /// ([grayMedium] fica em 1,84:1).
  static const grayCheckedOnDark = Color(0xFFC4C5C7);

  static const all = [
    grayDark,
    grayMedium,
    turquoise,
    white,
    grayLight,
    turquoiseDark,
    turquoiseLight,
    grayMediumAccessible,
    grayCheckedOnDark,
  ];
}
