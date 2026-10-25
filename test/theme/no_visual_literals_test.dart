// Quality gate 5 da constituição (Princípio VI; research.md R17): telas e
// widgets não podem conter cores, fontes, tamanhos ou durações literais.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _nonZero = r'\d*[1-9]\d*(?:\.\d+)?|0\.\d*[1-9]\d*';

final _rules = <String, RegExp>{
  'cor literal (Color(...))': RegExp(r'\bColor\('),
  'cor literal (Colors.*)': RegExp(r'\bColors\.'),
  'cor em hexadecimal': RegExp(r'\b0x[0-9A-Fa-f]{6,8}\b'),
  'nome de fonte': RegExp(r'\bfontFamily\s*:'),
  'tamanho de fonte': RegExp(r'\bfontSize\s*:'),
  'espaçamento de letras': RegExp(r'\bletterSpacing\s*:'),
  'EdgeInsets numérico': RegExp(
    'EdgeInsets\\.\\w+\\([^)]*?\\b(?:$_nonZero)\\b',
  ),
  'SizedBox numérico': RegExp(
    'SizedBox\\([^)]*?\\b(?:width|height)\\s*:\\s*(?:$_nonZero)\\b',
  ),
  'raio numérico': RegExp('BorderRadius\\.circular\\(\\s*(?:$_nonZero)\\b'),
  'tamanho numérico (size:)': RegExp('\\bsize\\s*:\\s*(?:$_nonZero)\\b'),
  'elevação numérica': RegExp('\\belevation\\s*:\\s*(?:$_nonZero)\\b'),
  'duração numérica': RegExp('Duration\\([^)]*?:\\s*(?:$_nonZero)\\b'),
};

/// Devolve as violações de [source] como "linha: regra".
List<String> findViolations(String source) {
  final violations = <String>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimLeft();
    if (line.startsWith('//')) continue;
    _rules.forEach((rule, pattern) {
      if (pattern.hasMatch(line)) violations.add('${i + 1}: $rule');
    });
  }
  return violations;
}

Iterable<File> _uiSources() sync* {
  final app = File('lib/app.dart');
  if (app.existsSync()) yield app;
  final ui = Directory('lib/ui');
  if (!ui.existsSync()) return;
  for (final entity in ui.listSync(recursive: true)) {
    final path = entity.path.replaceAll(r'\', '/');
    if (entity is File &&
        path.endsWith('.dart') &&
        !path.endsWith('.g.dart') &&
        !path.startsWith('lib/ui/theme/')) {
      yield entity;
    }
  }
}

void main() {
  test('o detector encontra cada tipo de valor literal', () {
    const sample = '''
final a = Color(0xFF123456);
final b = Colors.red;
final c = TextStyle(fontSize: 14, fontFamily: 'X', letterSpacing: 1);
const d = EdgeInsets.all(8);
const e = SizedBox(height: 12);
final f = BorderRadius.circular(4);
const g = Icon(Icons.add, size: 24);
const h = Material(elevation: 2);
const i = Duration(milliseconds: 300);
''';
    final found = findViolations(sample).join('\n');
    for (final rule in _rules.keys) {
      expect(found, contains(rule), reason: 'regra não detectada: $rule');
    }
  });

  test('zeros, tokens e comentários são permitidos', () {
    const sample = '''
// Color(0xFF000000) em comentário
const a = EdgeInsets.zero;
const b = EdgeInsets.all(Tokens.spaceSm);
const c = SizedBox(height: 0);
final d = BorderRadius.circular(Tokens.radiusMd);
const e = Duration(seconds: 0);
final f = Theme.of(context).colorScheme.primary;
''';
    expect(findViolations(sample), isEmpty);
  });

  test('telas e widgets não contêm valores visuais literais', () {
    final problems = <String>[];
    for (final file in _uiSources()) {
      for (final v in findViolations(file.readAsStringSync())) {
        problems.add('${file.path}:$v');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
