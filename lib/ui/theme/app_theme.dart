import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'brand_colors.dart';
import 'brand_theme.dart';
import 'tokens.dart';

/// Temas claro (padrão) e escuro montados à mão a partir da paleta T_YOU,
/// sem `ColorScheme.fromSeed`, que geraria matizes fora da marca
/// (research.md R14, papéis de cor).
abstract final class AppTheme {
  static ThemeData light() => _build(
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: BrandColors.turquoiseDark,
      onPrimary: BrandColors.white,
      secondary: BrandColors.grayDark,
      onSecondary: BrandColors.white,
      // A marca não tem cor de erro: o erro é comunicado por ícone + texto.
      error: BrandColors.grayDark,
      onError: BrandColors.white,
      surface: BrandColors.white,
      onSurface: BrandColors.grayDark,
      onSurfaceVariant: BrandColors.grayDark,
      outline: BrandColors.grayMedium,
      outlineVariant: BrandColors.grayLight,
      inverseSurface: BrandColors.grayDark,
      onInverseSurface: BrandColors.white,
      inversePrimary: BrandColors.turquoiseLight,
      shadow: BrandColors.grayDark,
      scrim: BrandColors.grayDark,
      surfaceTint: BrandColors.white,
    ),
    scaffoldBackground: BrandColors.grayLight,
    cardBorder: BorderSide.none,
    brand: const BrandTheme(
      activeListAccent: BrandColors.turquoise,
      accentLine: BrandColors.turquoise,
      checkedItemText: BrandColors.grayMediumAccessible,
      neutralIcon: BrandColors.grayMedium,
      splashBackground: BrandColors.grayDark,
      splashGradient: _splashGradient,
    ),
  );

  static ThemeData dark() => _build(
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: BrandColors.turquoiseLight,
      onPrimary: BrandColors.grayDark,
      secondary: BrandColors.grayLight,
      onSecondary: BrandColors.grayDark,
      error: BrandColors.grayLight,
      onError: BrandColors.grayDark,
      surface: BrandColors.grayDark,
      onSurface: BrandColors.white,
      onSurfaceVariant: BrandColors.grayLight,
      outline: BrandColors.grayMedium,
      outlineVariant: BrandColors.grayMedium,
      inverseSurface: BrandColors.white,
      onInverseSurface: BrandColors.grayDark,
      inversePrimary: BrandColors.turquoiseDark,
      shadow: BrandColors.grayDark,
      scrim: BrandColors.grayDark,
      surfaceTint: BrandColors.grayDark,
    ),
    scaffoldBackground: BrandColors.grayDark,
    cardBorder: const BorderSide(
      color: BrandColors.grayMedium,
      width: Tokens.accentLineThickness,
    ),
    brand: const BrandTheme(
      activeListAccent: BrandColors.turquoise,
      accentLine: BrandColors.turquoise,
      checkedItemText: BrandColors.grayCheckedOnDark,
      neutralIcon: BrandColors.grayLight,
      splashBackground: BrandColors.grayDark,
      splashGradient: _splashGradient,
    ),
  );

  /// Gradiente suave cinza → turquesa dos fundos da marca.
  static const _splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      BrandColors.grayDark,
      BrandColors.grayDark,
      Color(0x5900A5B4), // turquesa a 35% sobre o cinza escuro
    ],
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required BorderSide cardBorder,
    required BrandTheme brand,
  }) {
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    const minButtonSize = Size(Tokens.minTouchTarget, Tokens.minTouchTarget);
    final smallRadius = BorderRadius.circular(Tokens.radiusSm);
    final mediumShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: smallRadius,
      borderSide: BorderSide(color: scheme.primary, width: 2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: AppTypography.bodyFamily,
      textTheme: textTheme,
      extensions: [brand],
      focusColor: scheme.primary.withValues(alpha: 0.16),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scaffoldBackground,
        elevation: Tokens.elevationNone,
        scrolledUnderElevation: Tokens.elevationNone,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: scheme.surface,
        elevation: Tokens.elevationNone,
        margin: EdgeInsets.zero,
        shape: mediumShape.copyWith(side: cardBorder),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minButtonSize,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: smallRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minButtonSize,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: minButtonSize,
          iconSize: Tokens.iconMd,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: Tokens.elevationMid,
        extendedTextStyle: textTheme.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceMd,
          vertical: Tokens.spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: smallRadius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: smallRadius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: focusBorder,
        errorBorder: focusBorder.copyWith(
          borderSide: BorderSide(color: scheme.onSurface, width: 2),
        ),
        focusedErrorBorder: focusBorder,
        errorStyle: textTheme.bodySmall,
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: brand.neutralIcon),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusLg),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: smallRadius),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: scheme.surface,
        textStyle: textTheme.bodyLarge,
        shape: mediumShape,
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        contentTextStyle: textTheme.bodyMedium,
        dividerColor: brand.accentLine,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: Tokens.accentLineThickness,
        space: Tokens.spaceLg,
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: Tokens.itemRowMinHeight,
        iconColor: brand.neutralIcon,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
