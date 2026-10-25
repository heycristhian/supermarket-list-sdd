import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/ui/theme/app_theme.dart';
import 'package:supermarket_list/ui/theme/brand_colors.dart';
import 'package:supermarket_list/ui/theme/brand_theme.dart';

/// Luminância relativa do WCAG 2.1.
double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void _expectContrast(String role, Color fg, Color bg, double minimum) {
  expect(
    contrast(fg, bg),
    greaterThanOrEqualTo(minimum),
    reason: '$role: contraste ${contrast(fg, bg).toStringAsFixed(2)}:1',
  );
}

void main() {
  test('a fórmula reproduz o contraste branco × cinza escuro', () {
    expect(
      contrast(BrandColors.white, BrandColors.grayDark),
      closeTo(8.26, 0.02),
    );
  });

  for (final (name, theme) in [
    ('claro', AppTheme.light()),
    ('escuro', AppTheme.dark()),
  ]) {
    group('tema $name', () {
      final scheme = theme.colorScheme;
      final brand = theme.extension<BrandTheme>()!;
      final backgrounds = {
        'superfície': scheme.surface,
        'fundo da tela': theme.scaffoldBackgroundColor,
      };

      backgrounds.forEach((bgName, bg) {
        test('texto principal sobre $bgName ≥ 4,5:1', () {
          _expectContrast('onSurface', scheme.onSurface, bg, 4.5);
        });
        test('texto secundário sobre $bgName ≥ 4,5:1', () {
          _expectContrast('onSurfaceVariant', scheme.onSurfaceVariant, bg, 4.5);
        });
        test('destaque/foco sobre $bgName ≥ 3:1', () {
          _expectContrast('primary', scheme.primary, bg, 3);
        });
        test('ícones neutros e alça sobre $bgName ≥ 3:1', () {
          _expectContrast('neutralIcon', brand.neutralIcon, bg, 3);
        });
      });

      test('item comprado sobre a superfície ≥ 4,5:1', () {
        _expectContrast(
          'checkedItemText',
          brand.checkedItemText,
          scheme.surface,
          4.5,
        );
      });
      test('texto sobre destaque ≥ 4,5:1', () {
        _expectContrast('onPrimary', scheme.onPrimary, scheme.primary, 4.5);
      });
      test('SnackBar ≥ 4,5:1', () {
        _expectContrast(
          'onInverseSurface',
          scheme.onInverseSurface,
          scheme.inverseSurface,
          4.5,
        );
        _expectContrast(
          'inversePrimary',
          scheme.inversePrimary,
          scheme.inverseSurface,
          4.5,
        );
      });
    });
  }

  test('nenhuma cor fora da paleta T_YOU e dos 4 tons de acessibilidade', () {
    const allowed = {
      0xFF4C4E53, 0xFF767678, 0xFF00A5B4, 0xFFFEFEFE, 0xFFE6E7E8, // marca
      0xFF006B75, 0xFF7FD2D9, 0xFF6B6B6D, 0xFFC4C5C7, // acessibilidade
    };
    for (final color in BrandColors.all) {
      expect(allowed, contains(color.toARGB32()));
    }
  });
}
