// Gera build/web/sw_manifest.js com a lista de pré-cache do service worker
// (research.md R6). Rodar depois de `flutter build web`:
//
//   dart run tool/generate_sw_manifest.dart
import 'dart:convert';
import 'dart:io';

const _buildDir = 'build/web';

/// Arquivos que nunca entram no pré-cache.
bool _isExcluded(String path) =>
    path == 'sw.js' ||
    path == 'sw_manifest.js' ||
    path == '.last_build_id' ||
    path == 'flutter_service_worker.js' ||
    path.endsWith('.symbols');

/// Só as variantes do CanvasKit/skwasm que este build pode carregar.
bool _isUnusedRenderer(String path, {required bool usesSkwasm}) {
  if (!path.startsWith('canvaskit/')) return false;
  final isCanvasKit =
      path == 'canvaskit/canvaskit.js' ||
      path == 'canvaskit/canvaskit.wasm' ||
      path.startsWith('canvaskit/chromium/');
  final isSkwasm = path.startsWith('canvaskit/skwasm');
  return !(isCanvasKit || (usesSkwasm && isSkwasm));
}

/// FNV-1a 32 bits: identifica a versão do build sem depender de pacotes.
int _fnv1a(int hash, List<int> bytes) {
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

void main() {
  final root = Directory(_buildDir);
  if (!root.existsSync()) {
    stderr.writeln('$_buildDir não existe. Rode `flutter build web` antes.');
    exit(1);
  }
  final bootstrap = File('$_buildDir/flutter_bootstrap.js').readAsStringSync();
  final usesSkwasm = bootstrap.contains('"renderer":"skwasm"');

  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .map(
            (f) => f.path
                .replaceAll(r'\', '/')
                .substring(root.path.replaceAll(r'\', '/').length + 1),
          )
          .where((p) => !_isExcluded(p))
          .where((p) => !_isUnusedRenderer(p, usesSkwasm: usesSkwasm))
          .toList()
        ..sort();

  var hash = 0x811C9DC5;
  var totalBytes = 0;
  for (final path in files) {
    final bytes = File('$_buildDir/$path').readAsBytesSync();
    totalBytes += bytes.length;
    hash = _fnv1a(hash, utf8.encode(path));
    hash = _fnv1a(hash, bytes);
  }
  final version = hash.toRadixString(16).padLeft(8, '0');

  File('$_buildDir/sw_manifest.js').writeAsStringSync(
    '// Gerado por tool/generate_sw_manifest.dart. Não editar.\n'
    "self.SW_VERSION = '$version';\n"
    'self.SW_PRECACHE = ${jsonEncode(['.', ...files])};\n',
  );
  stdout.writeln(
    'sw_manifest.js: ${files.length} arquivos, '
    '${(totalBytes / 1048576).toStringAsFixed(1)} MB, versão $version',
  );
}
