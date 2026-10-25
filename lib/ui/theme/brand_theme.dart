import 'package:flutter/material.dart';

/// Papéis de cor da marca que o `ColorScheme` não cobre (research.md R14).
@immutable
class BrandTheme extends ThemeExtension<BrandTheme> {
  const BrandTheme({
    required this.activeListAccent,
    required this.accentLine,
    required this.checkedItemText,
    required this.neutralIcon,
    required this.splashBackground,
    required this.splashGradient,
  });

  /// Barra lateral fina da lista ativa (acento decorativo).
  final Color activeListAccent;

  /// Linhas finas de destaque.
  final Color accentLine;

  /// Texto riscado de item comprado.
  final Color checkedItemText;

  /// Ícones neutros e alça de arraste.
  final Color neutralIcon;

  final Color splashBackground;
  final Gradient splashGradient;

  @override
  BrandTheme copyWith({
    Color? activeListAccent,
    Color? accentLine,
    Color? checkedItemText,
    Color? neutralIcon,
    Color? splashBackground,
    Gradient? splashGradient,
  }) => BrandTheme(
    activeListAccent: activeListAccent ?? this.activeListAccent,
    accentLine: accentLine ?? this.accentLine,
    checkedItemText: checkedItemText ?? this.checkedItemText,
    neutralIcon: neutralIcon ?? this.neutralIcon,
    splashBackground: splashBackground ?? this.splashBackground,
    splashGradient: splashGradient ?? this.splashGradient,
  );

  @override
  BrandTheme lerp(BrandTheme? other, double t) {
    if (other == null) return this;
    return BrandTheme(
      activeListAccent: Color.lerp(
        activeListAccent,
        other.activeListAccent,
        t,
      )!,
      accentLine: Color.lerp(accentLine, other.accentLine, t)!,
      checkedItemText: Color.lerp(checkedItemText, other.checkedItemText, t)!,
      neutralIcon: Color.lerp(neutralIcon, other.neutralIcon, t)!,
      splashBackground: Color.lerp(
        splashBackground,
        other.splashBackground,
        t,
      )!,
      splashGradient: Gradient.lerp(splashGradient, other.splashGradient, t)!,
    );
  }
}

extension BrandThemeContext on BuildContext {
  BrandTheme get brand => Theme.of(this).extension<BrandTheme>()!;
}
