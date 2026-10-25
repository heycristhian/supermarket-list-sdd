# CLAUDE.md

App Flutter de listas de supermercado, offline, para Android, iOS e web (PWA). Spec, plano e
tarefas em `specs/001-supermarket-lists/`; regras do projeto na constituição
(`.specify/memory/constitution.md`), que prevalece sobre este arquivo.

## Comandos

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .   # gate 1
flutter analyze                                     # gate 2: zero avisos
flutter test                                        # gate 3: tudo verde
dart run build_runner build                         # após mudar lib/data/database.dart
flutter build web --release --no-web-resources-cdn && dart run tool/generate_sw_manifest.dart
```

Widget tests que gravam no banco antes do `pumpWidget` usam `tester.runAsync` (o drift usa
timers reais); veja `test/support/pump_app.dart`.

## Camadas

- `lib/domain/`: regras puras. **O domínio não importa Flutter** (só `dart:`).
- `lib/data/`: drift (SQLite; WASM na web) e `ShoppingRepository`, a única porta da UI para o
  banco (`specs/001-supermarket-lists/contracts/repository.md`).
- `lib/state/`: providers do Riverpod 3, sem geração de código.
- `lib/ui/`: telas e widgets; todos os textos em `lib/ui/strings.dart` (pt-BR).

## Regras que os testes cobram

- **Valores visuais só em `lib/ui/theme/`.** Fora dali, nada de `Color(`, `Colors.`, hex,
  `fontSize`, `fontFamily`, números em `EdgeInsets`/`SizedBox`/`size:`/`elevation:`/`Duration(`.
  Use `Theme.of(context)`, `context.brand` e `Tokens`. Verificado por
  `test/theme/no_visual_literals_test.dart`.
- Cores fora do Dart (`web/manifest.json`, splash da web e do Android) iguais a
  `BrandColors.grayDark`: `test/theme/platform_colors_test.dart`.
- Contraste WCAG AA dos papéis de cor: `test/theme/contrast_test.dart`.
- Identidade visual: `docs/marca.md` (resumo do manual T_YOU; o PDF fica fora do git).

## Dependências

Versões **exatas, sem `^`**, e `pubspec.lock` versionado. Antes de adicionar um pacote, confira
se ele é mesmo necessário (constituição, Princípio IV). Ao atualizar o drift, baixe
`web/sqlite3.wasm` e `web/drift_worker.js` da mesma release (comentário em `web/index.html`).
