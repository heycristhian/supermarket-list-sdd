import 'package:flutter/material.dart';

/// Tipografia T_YOU com as alternativas gratuitas previstas em docs/marca.md
/// (research.md R15). Trocar de fonte é mudar só estas duas constantes.
abstract final class AppTypography {
  /// Títulos curtos e números de destaque (no lugar de Tactic Sans).
  static const headingFamily = 'Michroma';

  /// Textos de interface (no lugar de Neue Plak).
  static const bodyFamily = 'Inter';

  /// Michroma é larga: só em tamanhos ≥ 20.
  static const TextTheme textTheme = TextTheme(
    displaySmall: TextStyle(fontFamily: headingFamily, fontSize: 36),
    headlineMedium: TextStyle(fontFamily: headingFamily, fontSize: 28),
    headlineSmall: TextStyle(fontFamily: headingFamily, fontSize: 24),
    titleLarge: TextStyle(fontFamily: headingFamily, fontSize: 20),
    titleMedium: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontFamily: bodyFamily, fontSize: 17),
    bodyMedium: TextStyle(fontFamily: bodyFamily, fontSize: 15),
    bodySmall: TextStyle(fontFamily: bodyFamily, fontSize: 14),
    labelLarge: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    // Rótulos de apoio em caixa alta e espaçamento largo ("ATIVA").
    labelSmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    ),
  );
}
