# Implementation Plan: Listas de Supermercado

**Branch**: `001-supermarket-lists` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-supermarket-lists/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

App pessoal de listas de supermercado, mobile-first e 100% offline: várias listas com nomes
únicos, uma lista ativa, itens com quantidade em texto livre, marcar como comprado (o item vai para
o fim e, ao ser desmarcado, volta ao seu lugar), copiar listas, "desmarcar todos", backup em arquivo
com lembrete e uma splash animada.

Abordagem técnica: **Flutter** com um único código para Android, iOS e web (PWA). Os dados ficam
em um banco **drift/SQLite** local (WASM na web), o estado é gerenciado com **Riverpod** sem
geração de código e o arraste usa os componentes nativos de reordenação do Flutter. As regras de
negócio (ordem por slots, nomes únicos, sugestão de nome da cópia, lembrete) ficam em funções
puras de domínio, testadas à parte do banco e da UI.

A interface segue a identidade visual **T_YOU** ([docs/marca.md](../../docs/marca.md)) por meio de
um tema central em `lib/ui/theme/`: paleta da marca com tons ajustados apenas onde o contraste AA
exige, fontes Michroma + Inter (alternativas previstas pela marca, até que a licença de Tactic
Sans/Neue Plak seja confirmada) e o logo original. Um teste automático impede valores visuais
literais fora do tema (Constituição v1.1.0, Princípio VI).

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 (stable)

**Primary Dependencies**: `drift` 2.35.3 + `drift_flutter` 0.3.1 (banco local),
`flutter_riverpod` 3.4.3 (estado), `file_picker` 13.2.0 (exportar/importar backup). Dev:
`drift_dev`, `build_runner`, `flutter_lints`. Todas com **versão exata** no `pubspec.yaml` e
`pubspec.lock` versionado (R18). Sem backend.

**Storage**: SQLite local via drift (nativo no Android/iOS; WASM + OPFS/IndexedDB na web)

**Testing**: `flutter_test` (testes unitários de domínio, de repositório com
`NativeDatabase.memory()` e widget tests)

**Target Platform**: Android (minSdk padrão do Flutter 3.47), iOS 14+, web (Chrome/Edge/Safari
atuais, instalável como PWA)

**Project Type**: mobile-app (Flutter multiplataforma, projeto único)

**Performance Goals**: marcar/desmarcar refletido em < 0,5 s; abrir lista/reordenar < 1 s com 50
listas × 100 itens; tela inicial utilizável em ≤ 1,5 s; exportar/importar < 5 s; 60 fps no arraste

**Constraints**: 100% offline; nenhuma perda de dados em fechamento abrupto (cada ação é gravada em
transação antes de a UI confirmar); importação tudo-ou-nada; alvos de toque ≥ 48 dp; usável a partir
de 360 px de largura; WCAG 2.1 AA; claro (padrão)/escuro; respeitar "reduzir movimento";
somente cores da paleta T_YOU e seus tons; nenhum valor visual literal fora de `lib/ui/theme/`

**Scale/Scope**: 1 usuário; até ~50 listas × ~100 itens; 2 telas principais (Itens da lista, Listas)
+ splash + diálogos (nome, copiar, confirmar, backup)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano atende | Status |
|---|---|---|
| **I. Simplicidade** | Projeto único, sem backend; 3 tabelas; um repositório; regras como funções puras; lista ativa garantida pela estrutura dos dados (R10), não por código de sincronização | ✅ |
| **II. Testes (inegociável)** | Testes unitários para `ordering`, `name_rules`, `backup_codec` e `backup_reminder`; testes de repositório com banco em memória para toda operação de [contracts/repository.md](contracts/repository.md), incluindo os 3 testes pedidos; widget tests para os gestos (FR-016a) e para o campo de adição; relógio injetado garante determinismo; `flutter test` é o comando único | ✅ |
| **III. Código legível** | `flutter_lints` + `flutter analyze` sem avisos + `dart format`; camadas `domain`/`data`/`state`/`ui` com nomes descritivos | ✅ |
| **IV. Dependências mínimas** | 3 dependências de runtime, cada uma justificada abaixo, todas com versão exata + `pubspec.lock` versionado (R18); splash, service worker, tema, persistência do storage e i18n feitos sem pacotes | ✅ (justificadas) |
| **V. Visual moderno e acessível** | Material 3, tema central (VI), claro e escuro, contraste AA conferido por token ([research.md](research.md) R14) e por `textContrastGuideline` nos widget tests, alternativa ao arraste no menu, foco visível, `disableAnimations` respeitado, mobile-first a partir de 360 px | ✅ |
| **VI. Identidade T_YOU e tema central** | `ColorScheme` montado à mão só com a paleta + 4 tons de acessibilidade justificados (R14); turquesa puro só como acento; Michroma/Inter como alternativas da marca, com troca em um único arquivo (R15); logo original em PNG, sem recriação (R16); `no_visual_literals_test.dart` como quality gate 5 (R17) | ✅ |
| **Restrições técnicas** | Sem backend; dados preservados após recarregar; sem segredos no repositório | ✅ |

**Justificativa das dependências de runtime (Princípio IV)**

| Dependência | Problema resolvido | Por que o nativo não basta |
|---|---|---|
| `drift` + `drift_flutter` | Banco local transacional com índices únicos nas 3 plataformas | O Flutter não tem armazenamento estruturado nativo; `shared_preferences` não tem transações nem unicidade; `sqflite` não roda na web |
| `flutter_riverpod` | Estado reativo e injeção do banco e do relógio para testes | `setState`/`InheritedWidget` à mão exigiriam reescrever o que o Riverpod já oferece, com mais código |
| `file_picker` | Salvar e abrir o arquivo de backup no Android, iOS e web | O Flutter não tem seletor nem salvamento de arquivos nativo multiplataforma |

Dependências de dev: `drift_dev` + `build_runner` (geração do código do schema, sem custo em
runtime) e `flutter_lints` (Princípio III). A identidade visual não adiciona dependências:
fontes e logo são assets, o logo é PNG (sem `flutter_svg`) e as fontes não usam `google_fonts`.

**Gate (pré-pesquisa)**: ✅ PASS. **Gate (pós-design)**: ✅ PASS (reavaliado com a constituição
v1.1.0). O design de [data-model.md](data-model.md) e [contracts/](contracts/) não introduziu
camadas, serviços nem dependências além das listadas; o Princípio VI afeta só a camada `ui/` e os
arquivos de plataforma.

## Project Structure

### Documentation (this feature)

```text
specs/001-supermarket-lists/
├── plan.md              # Este arquivo
├── research.md          # Fase 0: decisões técnicas (R1–R20)
├── data-model.md        # Fase 1: tabelas, ordem, transições, validações
├── quickstart.md        # Fase 1: como rodar e validar
├── contracts/
│   ├── backup-file.md   # Formato do arquivo de backup (interface externa)
│   └── repository.md    # Operações UI ↔ dados e testes obrigatórios
├── checklists/
│   └── requirements.md
└── tasks.md             # Fase 2 (/speckit-tasks; não criado aqui)
```

### Source Code (repository root)

O projeto Flutter fica na raiz de `projetos/supermarket-list`, ao lado de `.specify/` e `specs/`
(criado com `flutter create --platforms android,ios,web --project-name supermarket_list .`).

```text
lib/
├── main.dart                     # bootstrap: ProviderScope + abertura do banco
├── app.dart                      # MaterialApp, tema, rota inicial (FR-012)
├── domain/                       # regras puras, sem Flutter nem banco
│   ├── models.dart               # ShoppingList, ShoppingItem, ListsOverview, DeletedItem
│   ├── errors.dart               # EmptyName/NameTooLong/DuplicateName/InvalidBackup
│   ├── name_rules.dart           # normalizeName, normalizeKey, suggestCopyName
│   ├── ordering.dart             # displayOrder, reorderIntoSlots, nextCheckedSeq
│   ├── backup_codec.dart         # encode/decode/validate do JSON v1
│   └── backup_reminder.dart      # shouldShowReminder(now, settings)
├── data/
│   ├── database.dart             # tabelas drift + migrações (schema v1)
│   ├── connection.dart           # driftDatabase() nativo/web + storage.persist na web
│   └── shopping_repository.dart  # implementa contracts/repository.md
├── state/
│   └── providers.dart            # database, repository, clock, streams, notifiers
└── ui/
    ├── strings.dart              # textos pt-BR
    ├── theme/                    # ÚNICO lugar com valores visuais (Princípio VI)
    │   ├── brand_colors.dart     # paleta T_YOU + tons de acessibilidade justificados
    │   ├── tokens.dart           # espaços, raios, alturas, ícones, toque, elevações, durações
    │   ├── app_typography.dart   # headingFamily/bodyFamily + escala de texto
    │   ├── brand_theme.dart      # ThemeExtension BrandTheme + context.brand
    │   └── app_theme.dart        # ThemeData claro/escuro + temas de componentes
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── list_items_screen.dart  # tela inicial com lista ativa
    │   └── lists_screen.dart
    └── widgets/
        ├── item_tile.dart        # área principal + alça + menu (FR-016a)
        ├── add_item_bar.dart     # campo fixo no rodapé (FR-013a)
        ├── list_tile.dart        # classe ShoppingListTile (evita colidir com ListTile do Material)
        ├── name_dialog.dart      # criar/renomear/copiar com validação
        ├── backup_reminder_banner.dart
        └── empty_state.dart

web/
├── index.html                    # splash inline + registro do sw.js
├── manifest.json                 # PWA instalável
├── sw.js                         # service worker offline; lê sw_manifest.js gerado no build (R6)
├── sqlite3.wasm                  # drift web (R2)
└── drift_worker.js

tool/
├── generate_sw_manifest.dart     # lista de pré-cache do build web (R6)
├── generate_scale_backup.dart    # fixture 50×100 para validar tempos (R20)
└── git-hooks/pre-commit          # gates antes do commit (R19)

assets/
├── fonts/                        # Michroma + Inter estática 400/500/600/700 (OFL) (R15)
└── images/                       # logo_light.png, icon_square_dark.png, icon_foreground.png (R16, já entregues)

test/
├── domain/                       # ordering, name_rules, backup_codec, backup_reminder
├── data/                         # shopping_repository (banco em memória)
├── theme/                        # no_visual_literals_test (gate 5), contraste dos tokens
├── fixtures/                     # backup_50x100.json (R20)
└── ui/                           # widget tests: gestos, campo de adição, tela inicial, splash
```

**Structure Decision**: projeto Flutter único na raiz do diretório do projeto, com `android/`,
`ios/` e `web/` gerados pelo `flutter create`. O código fica em 4 camadas finas: `domain` (puro,
testado de forma exaustiva), `data` (drift + repositório), `state` (providers) e `ui`. Não há
pacotes internos separados nem camada de "use cases": o repositório já é a fronteira (Princípio I).

## Complexity Tracking

Nenhuma violação da constituição a justificar. As dependências de runtime estão justificadas na
seção Constitution Check, como exige o Princípio IV.

## Riscos e pontos de atenção

| Risco | Mitigação |
|---|---|
| iOS não pode ser compilado no host Windows | Código sem APIs específicas de plataforma; validar quando houver macOS/CI |
| O navegador pode apagar os dados do PWA | `navigator.storage.persist()` + backup com lembrete + aviso se o drift cair em `inMemory` |
| O service worker pode servir uma versão antiga após o deploy | Network-first em navegações + cache versionado e limpo no `activate` |
| `sqlite3.wasm`/worker fora de sincronia com o drift | Fixar a versão no `pubspec.yaml`; o quickstart lembra de atualizar os dois juntos |
| SQLite nativo ausente nos testes no Windows | Verificar na tarefa de setup (R3) |
| Michroma pouco legível em tamanhos pequenos | Usada só em ≥ 20 sp (R15) |
| Logo pequeno em ícones de 48 px | É a aplicação quadrada oficial da marca; conferir no cenário 19 do quickstart |
| Turquesa da marca abaixo do AA | Tons derivados para texto/botões e turquesa puro só decorativo (R14) |
