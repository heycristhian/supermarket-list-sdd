// Complemento do quality gate 5 (research.md R17): as cores que vivem fora
// do Dart (PWA, splash da web e do Android) precisam bater com o tema.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_list/ui/theme/brand_colors.dart';

String _hex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  final grayDark = _hex(BrandColors.grayDark.toARGB32());

  test('manifest.json usa o cinza escuro da marca', () {
    final manifest = jsonDecode(
      File('web/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect((manifest['theme_color'] as String).toUpperCase(), grayDark);
    expect((manifest['background_color'] as String).toUpperCase(), grayDark);
  });

  test('a splash da web usa o cinza escuro da marca', () {
    final html = File('web/index.html').readAsStringSync();
    final splash = RegExp(r'#splash\s*\{[^}]*background:\s*(#[0-9A-Fa-f]{6})')
        .firstMatch(html);
    expect(splash, isNotNull, reason: 'regra CSS de #splash não encontrada');
    expect(splash!.group(1)!.toUpperCase(), grayDark);
  });

  test('a splash do Android usa o cinza escuro da marca', () {
    final xml = File('android/app/src/main/res/values/colors.xml')
        .readAsStringSync();
    final color = RegExp(
      r'<color name="splash_background">(#[0-9A-Fa-f]{6})</color>',
    ).firstMatch(xml);
    expect(color, isNotNull, reason: 'splash_background não encontrada');
    expect(color!.group(1)!.toUpperCase(), grayDark);
  });
}
