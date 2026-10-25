---

description: "Task list for feature 001-supermarket-lists"
---

# Tasks: Listas de Supermercado

**Input**: Design documents from `/specs/001-supermarket-lists/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md),
constituição v1.1.0

**Tests**: INCLUÍDOS. A constituição exige testes para toda regra de negócio (Princípio II,
inegociável) e uma verificação automática de valores visuais literais (quality gate 5,
Princípio VI). O usuário pediu explicitamente testes para lista ativa única, cópia desmarcada e
item comprado indo para o fim. Em cada história, os testes são escritos primeiro e MUST falhar
antes da implementação.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Projeto Flutter único na raiz de `projetos/supermarket-list` (ver [plan.md](plan.md#source-code-repository-root)):
código em `lib/`, testes em `test/`, arquivos web em `web/` e assets em `assets/`. Todos os caminhos
são relativos a essa raiz.

## Regra visual para TODAS as tarefas de UI (Princípio VI)

Telas e widgets fora de `lib/ui/theme/` MUST NOT conter cores, nomes de fonte, tamanhos de fonte,
medidas numéricas (padding, margem, raio, altura, largura, ícone, elevação) nem durações
literais. Tudo vem de `Theme.of(context)` (`colorScheme`, `textTheme`, temas de componentes),
de `context.brand` (`BrandTheme`) e de `Tokens`. O teste T024 falha se essa regra for violada.
Os papéis de cor estão em [research.md](research.md) R14.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Criar o projeto Flutter e configurar dependências, lint e assets

- [X] T001 Criar o projeto Flutter na raiz com `flutter create --platforms android,ios,web --project-name supermarket_list --org dev.heycristhian .`, sem apagar `.specify/`, `.claude/`, `docs/` e `specs/`; substituir o app contador em `lib/main.dart` por um `MaterialApp` vazio e apagar `test/widget_test.dart`
- [X] T002 Configurar `pubspec.yaml` com **versões exatas, sem `^`** (Princípio IV, R18): `environment: sdk: ^3.13.0`, `flutter: ">=3.47.0"`; dependências `drift: 2.35.3`, `drift_flutter: 0.3.1`, `flutter_riverpod: 3.4.3`, `file_picker: 13.2.0`; dev_dependencies `drift_dev`, `build_runner` e `flutter_lints` também em versão exata (a do `drift_dev` igual à do drift; as outras, as atuais resolvidas pelo `flutter pub add`); rodar `flutter pub get`, garantir que `pubspec.lock` **não** está no `.gitignore` (ele será versionado) e confirmar que não entrou nenhuma outra dependência de runtime (sem `google_fonts` e sem `flutter_svg`); definir iOS 14 como versão mínima (`platform :ios, '14.0'` em `ios/Podfile` e `IPHONEOS_DEPLOYMENT_TARGET = 14.0` em `ios/Runner.xcodeproj/project.pbxproj`, exigência do `file_picker`, R7)
- [X] T003 [P] Configurar `analysis_options.yaml` incluindo `package:flutter_lints/flutter.yaml`, mais `prefer_single_quotes`, `prefer_final_locals`, `always_declare_return_types` e `unawaited_futures`, e excluindo `**/*.g.dart`
- [X] T004 [P] Baixar `web/sqlite3.wasm` (release do `sqlite3.dart` compatível com a versão de `sqlite3` no `pubspec.lock`) e `web/drift_worker.js` (release do drift igual à do `pubspec.lock`), conforme [research.md](research.md) R2; anotar as versões em um comentário no topo de `web/index.html`
- [X] T005 [P] Adicionar as fontes alternativas da marca (R15), ambas OFL: `assets/fonts/Michroma-Regular.ttf` (títulos) e a Inter **estática** em `assets/fonts/Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf` e `Inter-Bold.ttf` (não usar a variável; R15), com `assets/fonts/OFL-Michroma.txt` e `assets/fonts/OFL-Inter.txt`; declarar em `pubspec.yaml` a família `Michroma` e a família `Inter` com cada arquivo e seu `weight:` 400/500/600/700 (decisão final: não há licença de app para Tactic Sans/Neue Plak)
- [X] T006 [P] Declarar `assets/images/` em `pubspec.yaml` com os arquivos já entregues (R16): `assets/images/logo_light.png` (logo horizontal 2836×378, letras brancas, fundo transparente, para fundo escuro), `assets/images/icon_square_dark.png` (1024×1024, logo sobre `#4C4E53`, extraído do manual, pág. 17) e `assets/images/icon_foreground.png` (1024×1024, só o logo, transparente); não criar variantes 2.0x/3.0x (a resolução já basta) nem `logo_dark.png` (o logo só aparece sobre fundo escuro)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domínio puro, banco, providers e o tema central T_YOU, que todas as histórias usam

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests (escrever primeiro)

- [X] T007 [P] Testes de `normalizeName`, `normalizeKey`, `normalizeQuantity` e validações em `test/domain/name_rules_test.dart`: `" Arroz "` ⇒ `"Arroz"`; `normalizeKey("  Arroz   Integral ")` ⇒ `"arroz integral"`; `"Feijão"` e `"Feijao"` têm chaves diferentes; vazio/só espaços ⇒ `EmptyNameException`; nome com mais de 80 caracteres ⇒ `NameTooLongException`; quantidade `"  "` ⇒ `null`; quantidade com mais de 40 caracteres ⇒ `NameTooLongException`
- [X] T008 [P] Testes de ordenação em `test/domain/ordering_test.dart`: `displayOrder` (não comprados por `position`, depois comprados por `checkedSeq`); `nextCheckedSeq` (max + 1, ou 1 se não houver); `reorderIntoSlots` com o exemplo de R9 (original A,B,C,D com B comprado; mover D para o índice 0 entre os não comprados ⇒ positions D=0, B=1, A=2, C=3); mover para o mesmo índice não altera nada
- [X] T009 [P] Teste de contraste dos tokens em `test/theme/contrast_test.dart`: implementar no próprio teste a fórmula de luminância relativa do WCAG 2.1 e verificar, para os temas claro e escuro, cada par de papéis da tabela "Papéis de cor" de [research.md](research.md) R14: texto principal, texto secundário, item comprado e texto sobre destaque ≥ 4,5:1; anel de foco, ícones neutros e alça ≥ 3:1; e que nenhuma cor em `BrandColors` fica fora da paleta + os 4 tons (`#006B75`, `#7FD2D9`, `#6B6B6D`, `#C4C5C7`)

### Implementation

- [X] T010 [P] Criar os erros de domínio em `lib/domain/errors.dart`: `EmptyNameException`, `NameTooLongException`, `DuplicateNameException`, `InvalidBackupException(message)`, todos com mensagem pt-BR exibível
- [X] T011 [P] Criar os modelos imutáveis em `lib/domain/models.dart`: `ShoppingList {id, name, position, totalItems, checkedItems}`, `ShoppingItem {id, listId, name, quantity?, position, checkedSeq?; bool get isChecked}`, `ListsOverview {ShoppingList? active, List<ShoppingList> others}`, `DeletedItem {listId, name, quantity?, position, checkedSeq?}`
- [X] T012 Implementar `lib/domain/name_rules.dart` (`normalizeName`, `normalizeKey`, `normalizeQuantity`, `validateName` com limite "1–80 caracteres após normalização" e quantidade "até 40 caracteres") até T007 passar
- [X] T013 Implementar `lib/domain/ordering.dart` (`displayOrder`, `nextCheckedSeq`, `reorderIntoSlots(allByPosition, isMovable, oldIndex, newIndex)`, que devolve as novas positions) até T008 passar
- [X] T014 Definir o schema drift v1 em `lib/data/database.dart` exatamente como em [data-model.md](data-model.md): `shopping_lists` (`name` "não nulo", `nameKey` "**UNIQUE**", `position` int), `shopping_items` (`listId` "FK → `shopping_lists.id` **ON DELETE CASCADE**", `quantity` "nulo", `checkedSeq` "nulo", "**UNIQUE (`listId`, `nameKey`)**", índice `(listId, position)`), `app_settings` (`id` "`CHECK (id = 1)`", `activeListId` "FK **ON DELETE SET NULL**", `lastBackupAt`, `lastChangeAt`, `backupReminderSnoozedUntil`, todos nulos); `AppDatabase(QueryExecutor e)`; `schemaVersion = 1`; `onCreate` insere a linha `app_settings(id: 1)`; `beforeOpen` executa `PRAGMA foreign_keys = ON`
- [X] T015 Gerar `lib/data/database.g.dart` com `dart run build_runner build`
- [X] T016 Criar `lib/data/connection.dart` com `openAppDatabase()` usando `driftDatabase(name: 'supermarket_list', web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')))`; detectar quando a web cai no armazenamento `inMemory` (callback de resultado do `DriftWebOptions` ou `WasmDatabase.open` como alternativa) e expor isso como `bool isStorageVolatile`; na web, chamar `navigator.storage.persist()` via `dart:js_interop` em `lib/data/storage_persistence_web.dart`, com um stub vazio em `lib/data/storage_persistence_stub.dart` (import condicional)
- [X] T017 Criar o helper de testes `test/support/test_database.dart` (`AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true))` e `FakeClock` ajustável) e o teste de fumaça `test/data/database_smoke_test.dart`: a linha `app_settings` existe; apagar uma lista remove os itens (CASCADE); apagar a lista ativa zera `activeListId` (SET NULL). Isso também valida R3: se o SQLite nativo não carregar no Windows, documentar a solução em [quickstart.md](quickstart.md)
- [X] T018 Criar o esqueleto de `lib/data/shopping_repository.dart`: `ShoppingRepository(AppDatabase db, DateTime Function() now)`; helper privado `_write(Future<T> Function())` que roda em transação, grava `lastChangeAt = now()` e traduz violações UNIQUE de `nameKey` em `DuplicateNameException`
- [X] T019 Criar `lib/state/providers.dart`: `databaseProvider` (sobrescrito em `main` e nos testes), `clockProvider` (`DateTime Function()`, padrão `DateTime.now`), `repositoryProvider` e `storageVolatileProvider`
- [X] T020 [P] Criar `lib/ui/theme/brand_colors.dart` com `abstract final class BrandColors`: paleta oficial `grayDark = #4C4E53`, `grayMedium = #767678`, `turquoise = #00A5B4`, `white = #FEFEFE`, apoio `grayLight = #E6E7E8` (confirmado no vetor do manual, pág. 17), e os tons de acessibilidade `turquoiseDark = #006B75`, `turquoiseLight = #7FD2D9`, `grayMediumAccessible = #6B6B6D`, `grayCheckedOnDark = #C4C5C7`, cada tom com um comentário citando o contraste que o justifica (R14); nenhuma outra cor
- [X] T021 [P] Criar `lib/ui/theme/tokens.dart` com `abstract final class Tokens`: espaçamentos 4/8/12/16/24/32, raios 8/12/20, `minTouchTarget = 48`, `itemRowMinHeight = 64`, `activeAccentWidth = 4`, `accentLineThickness = 1`, ícones 20/24/32, elevações 0/1/3, durações 150/250/600 ms, `undoSnackBarDuration = 5 s` e `splashMaxDuration = 1500 ms`
- [X] T022 [P] Criar `lib/ui/theme/app_typography.dart`: `headingFamily = 'Michroma'` e `bodyFamily = 'Inter'` (alternativas da marca; ponto único de troca de fonte); `TextTheme` com `display*`/`headline*`/`titleLarge` em `headingFamily`, sempre ≥ 20 sp; `titleMedium`/`body*`/`label*` em `bodyFamily` 14–18 sp; `labelSmall` em caixa alta com `letterSpacing` largo, para rótulos de apoio ("ATIVA", "OUTRAS LISTAS")
- [X] T023 Criar `lib/ui/theme/brand_theme.dart` (`BrandTheme extends ThemeExtension` com `activeListAccent`, `accentLine`, `checkedItemText`, `neutralIcon`, `splashBackground`, `splashGradient`, mais `copyWith`/`lerp`; extensão `BuildContext.brand`) e `lib/ui/theme/app_theme.dart` (`AppTheme.light()`/`AppTheme.dark()` com `ColorScheme(...)` montado à mão conforme a tabela "Papéis de cor" de R14, sem `fromSeed`; `scaffoldBackgroundColor` `#E6E7E8`/`#4C4E53`; cards `#FEFEFE` no claro e borda fina `#767678` no escuro; temas de componentes para AppBar, FilledButton, TextButton, IconButton (≥ 48 dp), InputDecoration, Dialog, SnackBar, PopupMenu, MaterialBanner, ListTile, Divider e foco visível; erro sem nova matiz, em `#4C4E53`/`#FEFEFE`), até T009 passar
- [X] T024 Criar o **quality gate 5** em `test/theme/no_visual_literals_test.dart` (só `dart:io`), conforme R17: percorrer **somente `lib/ui/**/*.dart` e `lib/app.dart`**, exceto `lib/ui/theme/` (`lib/domain/`, `lib/data/` e `lib/state/` ficam fora, porque não são telas e usam durações de regra de negócio como os 7 dias do lembrete), e falhar indicando arquivo:linha ao encontrar `Color(`, `Colors.`, `0xFF`, `fontFamily:`, `fontSize:`, `letterSpacing:`, `EdgeInsets.` com número ≠ 0, `SizedBox(` com `width:`/`height:` numérico, `BorderRadius.circular(` numérico, `size:` numérico, `elevation:` numérico ou `Duration(` numérico; incluir um auto-teste com um trecho de exemplo que deve ser detectado
- [X] T025 [P] Criar `lib/ui/strings.dart` com todos os textos pt-BR da UI como constantes ou funções (ex.: `progress(checked, total)` ⇒ `"3 de 10"`, `activeBadge` ⇒ `"ATIVA"`)
- [X] T026 Ligar o bootstrap em `lib/main.dart` (abrir o banco, `ProviderScope` com o override de `databaseProvider` e `storageVolatileProvider`) e em `lib/app.dart` (`MaterialApp` com `theme: AppTheme.light()`, `darkTheme: AppTheme.dark()`, `themeMode: ThemeMode.system` e uma home provisória); rodar `flutter test` (T007–T009, T017 e T024 verdes)

**Checkpoint**: `flutter test` verde; `flutter analyze` sem avisos; tema T_YOU disponível

---

## Phase 3: User Story 1 - Montar uma lista e usá-la no mercado (Priority: P1) 🎯 MVP

**Goal**: Criar lista, adicionar itens pelo campo do rodapé, marcar/desmarcar (comprado vai para o fim e volta ao seu lugar), nomes únicos, abrir o app direto na lista ativa, tudo persistido offline, inclusive na web como PWA instalável (T039–T040)

**Independent Test**: criar uma lista, adicionar 5 itens, marcar 2, desmarcar 1, fechar e reabrir o app em modo avião ⇒ tudo preservado ([spec.md](spec.md) US1)

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T027 [P] [US1] Testes de repositório em `test/data/repository_lists_basic_test.dart`: `createList` cria e emite em `watchLists()`; **a 1ª lista criada vira ativa** e a 2ª não altera a ativa (parte do teste "lista ativa única"); nome vazio, nome com mais de 80 caracteres e `"lista semanal"` com "Lista semanal" já existente ⇒ erros corretos e nenhuma lista criada; `lastChangeAt` atualizado com o `FakeClock`
- [X] T028 [P] [US1] Testes de repositório em `test/data/repository_items_checking_test.dart`: **teste obrigatório "comprado vai para o fim"**: A,B,C,D ⇒ `toggleChecked(B)` ⇒ A,C,D,B ⇒ `toggleChecked(A)` ⇒ C,D,B,A ⇒ `toggleChecked(B)` ⇒ B,C,D,A; `addItem` com `"arroz"`/`" Arroz "` com "Arroz" já na lista ⇒ `DuplicateNameException`; "Arroz" em outra lista ⇒ ok; quantidade `"  "` ⇒ `null`; item novo com itens comprados entra antes dos comprados (FR-017); persistência: com um banco em arquivo temporário (`NativeDatabase(File)`), fechar e reabrir mantém itens, quantidades, estados e ordem
- [X] T029 [P] [US1] Widget tests em `test/ui/list_items_screen_test.dart` (com `AppTheme.light()` e o override de `databaseProvider` do banco em memória): tocar na área principal marca e o item vai para o fim, com texto `context.brand.checkedItemText`, riscado e ícone de check; adicionar pelo campo do rodapé limpa o campo e mantém o foco (FR-013a); nome repetido mostra o erro e mantém o texto digitado (FR-028); com lista ativa, a home é a tela de itens dela; sem lista ativa, a home é a tela de listas (FR-012); da tela de itens, um único toque abre a tela de listas (US1 cenário 11); nome com 81 caracteres é rejeitado com mensagem e o texto é mantido; o progresso exibe `"2 de 5"` e "Lista concluída" quando tudo está comprado (FR-022)

### Implementation for User Story 1

- [X] T030 [US1] Implementar em `lib/data/shopping_repository.dart`: `createList` (`position = max + 1`; define `activeListId` se for nulo), `watchLists()` (`ListsOverview` com totais), `watchActiveListId()`, `addItem` (`position = max + 1`), `watchItems(listId)` (usa `displayOrder`) e `toggleChecked` (usa `nextCheckedSeq`), até T027 e T028 passarem
- [X] T031 [US1] Adicionar a `lib/state/providers.dart`: `listsOverviewProvider` (StreamProvider), `activeListIdProvider` (StreamProvider) e `itemsProvider` (StreamProvider.family por `listId`)
- [X] T032 [P] [US1] Criar `lib/ui/widgets/empty_state.dart` (ícone `Tokens` grande em `brand.neutralIcon`, título em `textTheme.titleLarge`, texto e ação opcional; usado em "nenhuma lista" e "lista vazia"), sem valores literais
- [X] T033 [P] [US1] Criar `lib/ui/widgets/name_dialog.dart`: diálogo com título, valor inicial e um callback `Future<void> onSubmit(String)`; mostra a mensagem do erro de domínio (ícone de alerta + texto) abaixo do campo e mantém o texto digitado; cancelar fecha sem efeito; estilo vindo de `dialogTheme`/`inputDecorationTheme`
- [X] T034 [US1] Criar `lib/ui/widgets/item_tile.dart`: card `#FEFEFE` do tema; área principal (InkWell, altura mínima `Tokens.itemRowMinHeight`) que chama `onToggle`; nome em `bodyLarge` e quantidade em `bodyMedium` (quebra de linha ou reticências para textos longos); comprado com `brand.checkedItemText`, riscado e ícone de check em `colorScheme.primary` (não depender só de cor); `Semantics` com `"Arroz, 5 kg, comprado"`; sem valores literais
- [X] T035 [US1] Criar `lib/ui/widgets/add_item_bar.dart` fixo no rodapé dentro de `SafeArea`/acima do teclado, com a linha fina `brand.accentLine` no topo: campos nome + quantidade; enviar pelo teclado ou `FilledButton` (≥ `Tokens.minTouchTarget`); em sucesso limpa e mantém o foco no nome; em erro mantém o texto e mostra a mensagem; perde o foco ao tocar fora (FR-013a)
- [X] T036 [US1] Criar `lib/ui/screens/list_items_screen.dart`: AppBar com o nome da lista (`titleLarge`, família de título), o progresso `strings.progress` (números de destaque) e um botão de um toque para a tela de listas; lista de `ItemTile` com espaçamentos `Tokens`; estado vazio; aviso "Lista concluída"; `AddItemBar` no rodapé
- [X] T037 [US1] Criar `lib/ui/screens/lists_screen.dart` (versão inicial): lista ativa no topo com barra lateral `brand.activeListAccent` de largura `Tokens.activeAccentWidth` + selo `strings.activeBadge` em `labelSmall` caixa alta; rótulo de seção "OUTRAS LISTAS"; demais listas abaixo por `position`; tocar abre `ListItemsScreen`; FAB "Nova lista" com `NameDialog`; estado vazio "Crie sua primeira lista"
- [X] T038 [US1] Implementar a home em `lib/app.dart`: com `activeListIdProvider` não nulo ⇒ `ListItemsScreen(activeId)`; nulo ⇒ `ListsScreen`; indicador neutro enquanto o banco carrega (FR-012); rodar `flutter test` até T029 e T024 passarem
- [X] T039 [P] [US1] Configurar o PWA em `web/manifest.json` (`name` "Listas de Supermercado", `short_name` "Listas", `display: standalone`, `start_url: "."`, `theme_color: "#4C4E53"`, `background_color: "#4C4E53"`) e gerar a partir de `assets/images/icon_square_dark.png` (e de `icon_foreground.png` + fundo `#4C4E53` para o ícone adaptativo do Android em `mipmap-anydpi-v26/ic_launcher.xml`) os ícones `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`, `web/favicon.png` e os ícones de launcher em `android/app/src/main/res/mipmap-*/ic_launcher.png` e `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- [X] T040 [US1] Criar `tool/generate_sw_manifest.dart` (só `dart:io`/`dart:convert`; lista `build/web/**`, exceto `sw.js` e `sw_manifest.js`, e grava `build/web/sw_manifest.js` com `self.SW_PRECACHE = [...]` e `self.SW_VERSION = '<hash>'`) e `web/sw.js` conforme [research.md](research.md) R6 (`importScripts('sw_manifest.js')`; pré-cache de todos os arquivos de `SW_PRECACHE` no `install`; network-first em navegações; cache-first com atualização em segundo plano no restante do mesmo domínio; cache com o nome `SW_VERSION`, limpo no `activate`); registrar o `sw.js` em `web/index.html` fora do modo debug; documentar `flutter build web --release --no-web-resources-cdn && dart run tool/generate_sw_manifest.dart` no [quickstart.md](quickstart.md)

**Checkpoint**: US1 completa e testável sozinha (MVP)

---

## Phase 4: User Story 2 - Manter os itens da lista (Priority: P2)

**Goal**: Editar nome/quantidade, apagar com desfazer, reordenar não comprados pela alça ⋮⋮, alternativa acessível no menu ⋯

**Independent Test**: renomear um item, limpar a quantidade de outro, apagar um terceiro (e desfazer), arrastar um quarto; reabrir ⇒ tudo preservado ([spec.md](spec.md) US2)

### Tests for User Story 2 ⚠️

- [X] T041 [P] [US2] Testes de repositório em `test/data/repository_items_editing_test.dart`: `editItem` mantém position e estado; quantidade vazia ⇒ `null`; nome de outro item da lista ⇒ `DuplicateNameException`; `"arroz"` ⇒ `"Arroz"` no próprio item é permitido; `deleteItem` + `restoreItem` voltam à mesma posição e `checkedSeq`; `reorderUncheckedItems` com o exemplo de R9 (D,B,A,C após desmarcar B); `moveItem(-1/+1)` nos limites não faz nada; itens comprados não se movem
- [X] T042 [P] [US2] Widget tests em `test/ui/item_tile_gestures_test.dart`: tocar na alça não marca; tocar no ⋯ não marca e abre Editar / Mover para cima / Mover para baixo / Apagar; arrastar pela alça reordena; rolar a lista com o dedo sobre os itens não move nem marca (FR-016a); item comprado não exibe a alça; apagar mostra o SnackBar "Desfazer" e desfazer restaura o item

### Implementation for User Story 2

- [X] T043 [US2] Implementar em `lib/data/shopping_repository.dart`: `editItem`, `deleteItem → DeletedItem`, `restoreItem`, `reorderUncheckedItems(listId, oldIndex, newIndex)` (via `reorderIntoSlots`) e `moveItem(id, delta)`, até T041 passar
- [X] T044 [P] [US2] Criar `lib/ui/widgets/item_dialog.dart`: diálogo de edição com nome + quantidade, mesmo comportamento de erro e mesmo estilo de tema do `NameDialog`
- [X] T045 [US2] Estender `lib/ui/widgets/item_tile.dart`: alça ⋮⋮ (`ReorderableDragStartListener`, ≥ `Tokens.minTouchTarget`, ícone em `brand.neutralIcon`, só em itens não comprados) e `PopupMenuButton` ⋯ (≥ `Tokens.minTouchTarget`, estilo de `popupMenuTheme`) com Editar, Mover para cima, Mover para baixo (só não comprados) e Apagar; nenhuma das duas áreas dispara `onToggle`
- [X] T046 [US2] Atualizar `lib/ui/screens/list_items_screen.dart` para `CustomScrollView` com `SliverReorderableList` (não comprados, `onReorder` ⇒ `reorderUncheckedItems`) + `SliverList` (comprados); apagar mostra um `SnackBar` com "Desfazer" (`Tokens.undoSnackBarDuration`) chamando `restoreItem`; editar abre `ItemDialog`; rodar até T042 e T024 passarem

**Checkpoint**: US1 e US2 funcionam de forma independente

---

## Phase 5: User Story 3 - Organizar várias listas e a lista ativa (Priority: P3)

**Goal**: Ativar listas (uma por vez, no topo e destacada), reordenar as não ativas pela alça, renomear e apagar com confirmação

**Independent Test**: criar 3 listas, ativar a 2ª, reordenar, ativar a 3ª, renomear uma, apagar outra; reabrir ⇒ estado preservado ([spec.md](spec.md) US3)

### Tests for User Story 3 ⚠️

- [X] T047 [P] [US3] Testes de repositório em `test/data/repository_lists_management_test.dart`: **teste obrigatório "lista ativa única"**: com X, Y e Z, `activateList(X)` e depois `activateList(Y)` ⇒ `overview.active == Y` e X volta para `others` no seu slot original (FR-011); apagar a ativa ⇒ `active == null` e os itens dela removidos; `renameList` para um nome existente ⇒ `DuplicateNameException`, e só mudar maiúsculas/minúsculas ⇒ ok; `reorderInactiveLists` com slots (a ativa mantém sua `position`); `moveList(±1)`
- [X] T048 [P] [US3] Widget tests em `test/ui/lists_screen_test.dart`: a ativa aparece primeiro com o selo "ATIVA" e a barra `brand.activeListAccent`; o menu ⋯ oferece Ativar / Renomear / Mover para cima / Mover para baixo / Apagar; Apagar pede confirmação, e cancelar não apaga; arrastar pela alça reordena as não ativas

### Implementation for User Story 3

- [X] T049 [US3] Implementar em `lib/data/shopping_repository.dart`: `activateList`, `renameList`, `deleteList`, `reorderInactiveLists(oldIndex, newIndex)` (via `reorderIntoSlots`, ignorando a ativa) e `moveList(id, delta)`, até T047 passar
- [X] T050 [P] [US3] Criar `lib/ui/widgets/confirm_dialog.dart` (título, mensagem, rótulo da ação destrutiva; devolve `bool`; estilo de `dialogTheme`)
- [X] T051 [P] [US3] Criar `lib/ui/widgets/list_tile.dart` com a classe `ShoppingListTile` (para não colidir com o `ListTile` do Material): área principal abre a lista; mostra o nome e `"3 de 10"`; variante ativa com a barra `brand.activeListAccent` (`Tokens.activeAccentWidth`) + selo "ATIVA"; alça ⋮⋮ só nas não ativas; menu ⋯ com Ativar (escondido se já ativa), Renomear, Mover para cima/baixo (só não ativas) e Apagar; sem valores literais
- [X] T052 [US3] Atualizar `lib/ui/screens/lists_screen.dart` para `CustomScrollView`: sliver da ativa fixo no topo + `SliverReorderableList` das não ativas (`onReorder` ⇒ `reorderInactiveLists`); ligar as ações do menu (Renomear via `NameDialog`, Apagar via `ConfirmDialog`); rodar até T048 e T024 passarem

**Checkpoint**: US1–US3 funcionam de forma independente

---

## Phase 6: User Story 4 - Reutilizar listas (Priority: P4)

**Goal**: "Desmarcar todos" voltando à ordem original; copiar uma lista com título sugerido, cópia toda desmarcada

**Independent Test**: com metade dos itens comprados, "desmarcar todos" ⇒ ordem original; copiar com um novo título ⇒ mesmos itens desmarcados, original intacta ([spec.md](spec.md) US4)

### Tests for User Story 4 ⚠️

- [X] T053 [P] [US4] Adicionar a `test/domain/name_rules_test.dart` os testes de `suggestCopyName`: "Lista Hambúrguer" ⇒ "Lista Hambúrguer (cópia)"; se já existir ⇒ "(cópia 2)"; se a 2 também existir ⇒ "(cópia 3)"; a comparação usa `normalizeKey`
- [X] T054 [P] [US4] Testes de repositório em `test/data/repository_reuse_test.dart`: **teste obrigatório "cópia desmarcada"**: copiar uma lista com itens comprados ⇒ a cópia tem os mesmos nomes, quantidades e ordem original, todos com `checkedSeq == null`, e a original continua com seus itens comprados; alterar a cópia não altera a original; `copyList` com título vazio ou existente ⇒ erro e nenhuma lista criada; `uncheckAll` com A,B,C,D e B e D comprados ⇒ todos desmarcados em A,B,C,D; `uncheckAll` depois de apagar um item mantém a ordem relativa dos restantes

### Implementation for User Story 4

- [X] T055 [US4] Implementar `suggestCopyName(original, existingKeys)` em `lib/domain/name_rules.dart` até T053 passar
- [X] T056 [US4] Implementar em `lib/data/shopping_repository.dart`: `suggestCopyName(listId)`, `copyList(listId, newName)` (nova lista com `position = max + 1`, itens copiados com `checkedSeq = null`, sem alterar a ativa) e `uncheckAll(listId)`, até T054 passar
- [X] T057 [US4] UI: adicionar "Copiar" ao menu de `lib/ui/widgets/list_tile.dart`, abrindo um `NameDialog` com o valor sugerido; adicionar a ação "Desmarcar todos" em `lib/ui/screens/list_items_screen.dart` com `ConfirmDialog`, desabilitada quando não há itens comprados; widget tests em `test/ui/reuse_actions_test.dart` cobrindo: "Copiar" abre o diálogo já preenchido com "X (cópia)" (US4 cenário 2); cancelar o diálogo não cria lista (cenário 4); título existente mostra erro e mantém o texto (cenário 4); "Desmarcar todos" pede confirmação, e cancelar não altera nada (cenário 1); a ação fica desabilitada sem itens comprados (caso de borda "lista vazia"); rodar T024

**Checkpoint**: US1–US4 funcionam de forma independente

---

## Phase 7: User Story 5 - Fazer e restaurar backup das listas (Priority: P5)

**Goal**: Exportar para arquivo, importar substituindo tudo (com confirmação, tudo-ou-nada), lembrete a cada 7 dias

**Independent Test**: exportar, apagar tudo, importar ⇒ estado idêntico; arquivo inválido ⇒ dados intactos; relógio +7 dias após uma alteração ⇒ lembrete ([spec.md](spec.md) US5)

### Tests for User Story 5 ⚠️

- [X] T058 [P] [US5] Testes em `test/domain/backup_codec_test.dart` seguindo [contracts/backup-file.md](contracts/backup-file.md): ida e volta encode ⇒ decode; rejeitar JSON inválido, `format` errado, `version` 2 ("versão mais nova do app"), campo obrigatório ausente, tipo errado, nomes de lista repetidos (por `normalizeKey`), nomes de item repetidos na mesma lista e `activeListIndex` fora dos limites; campos desconhecidos ignorados; `position`/`checkedSeq` renumerados de forma compacta mantendo a ordem relativa
- [X] T059 [P] [US5] Testes em `test/domain/backup_reminder_test.dart` (regra R12): nunca fez backup + alterações ⇒ mostra; backup há 6 dias ⇒ não; 7 dias + alterações ⇒ mostra; 7 dias sem alterações desde o backup ⇒ não; dispensado ⇒ não até `snoozedUntil`
- [X] T060 [P] [US5] Testes de repositório em `test/data/repository_backup_test.dart`: exportar ⇒ importar em um banco novo reproduz listas, itens, estados, ordens e lista ativa; `lastBackupAt` definido ao marcar a exportação; importar substitui tudo e grava `lastBackupAt = lastChangeAt = now`, de modo que `watchBackupReminder` emite `false` logo após importar num banco vazio (US5 cenário 7); um arquivo inválido deixa 100% dos dados intactos; `snoozeBackupReminder` ⇒ `now + 7 dias`; `watchBackupReminder` reage ao `FakeClock`

### Implementation for User Story 5

- [X] T061 [US5] Implementar `lib/domain/backup_codec.dart` (`BackupData`, `encodeBackup` ⇒ `Uint8List` UTF-8 JSON, `decodeBackup` com validação completa ⇒ `InvalidBackupException` com mensagem pt-BR) até T058 passar
- [X] T062 [US5] Implementar `lib/domain/backup_reminder.dart` (`shouldShowReminder(now, lastBackupAt, lastChangeAt, snoozedUntil)`, intervalo fixo de 7 dias) até T059 passar
- [X] T063 [US5] Implementar em `lib/data/shopping_repository.dart`: `exportBackup()`, `markBackupDone()`, `parseBackup(bytes)`, `importBackup(data)` (uma transação: apagar tudo, inserir, definir `activeListId` e gravar `lastBackupAt = lastChangeAt = now`), `snoozeBackupReminder()` e `watchBackupReminder()`, até T060 passar
- [X] T064 [US5] Criar `lib/data/backup_files.dart` com `BackupFiles` (`saveBackup(bytes)` via `FilePicker.saveFile(fileName: 'listas-supermercado-AAAA-MM-DD.json', bytes:)` e `pickBackup()` via `pickFiles` + `readAsBytes`; cancelar ⇒ `null`) e o `backupFilesProvider` em `lib/state/providers.dart` (sobrescrevível em testes)
- [X] T065 [US5] UI: menu da AppBar em `lib/ui/screens/lists_screen.dart` com "Exportar backup" (salva e chama `markBackupDone` só em sucesso) e "Importar backup" (`ConfirmDialog` "substituir todos os dados"; erros mostrados em SnackBar com ícone de alerta); `lib/ui/widgets/backup_reminder_banner.dart` (MaterialBanner discreto do `bannerTheme`, com "Fazer backup" e "Agora não", exibido em `ListItemsScreen` e `ListsScreen` sem bloquear o uso); widget test em `test/ui/backup_flow_test.dart` com `BackupFiles` falso; rodar T024

**Checkpoint**: US1–US5 funcionam de forma independente

---

## Phase 8: User Story 6 - Splash screen animada na abertura (Priority: P6)

**Goal**: Splash breve e animada com o logo T_YOU na abertura a frio, tela utilizável em ≤ 1,5 s, respeitando "reduzir movimento"

**Independent Test**: abrir do zero e cronometrar; repetir com "reduzir movimento" ativado ([spec.md](spec.md) US6)

**Dependência**: T006 (declaração dos assets do logo, já entregues).

### Tests for User Story 6 ⚠️

- [X] T066 [P] [US6] Widget tests em `test/ui/splash_screen_test.dart` com `fakeAsync`/`pump`: a splash dá lugar à home quando a animação (`Tokens` 600 ms) termina e o banco está pronto; o teto absoluto é `Tokens.splashMaxDuration` mesmo com o banco lento (mostra a home com o indicador de carregamento); com `MediaQuery(disableAnimations: true)` não há animação; voltar do segundo plano (`AppLifecycleState.resumed`) não reexibe a splash

### Implementation for User Story 6

- [X] T067 [US6] Criar `lib/ui/screens/splash_screen.dart`: fundo `brand.splashBackground` com o gradiente suave `brand.splashGradient` (cinza → turquesa); `assets/images/logo_light.png` com fade + escala; linha fina `brand.accentLine` se desenhando sob o logo; durações de `Tokens`; integrar em `lib/app.dart` como a primeira tela, até T066 e T024 passarem
- [X] T068 [P] [US6] Configurar as splashes nativas estáticas com fundo `#4C4E53` e o logo claro: `android/app/src/main/res/values/colors.xml` (`splash_background`), `values/styles.xml`, `values-night/styles.xml`, `values-v31/styles.xml` (`windowSplashScreenBackground` = `splash_background` e `windowSplashScreenAnimatedIcon` = `@drawable/splash_icon`, gerado a partir de `assets/images/icon_foreground.png`, que é **quadrado**, porque o Android 12+ recorta o ícone num círculo e o logo horizontal sairia cortado), `android/app/src/main/res/drawable*/splash_logo.png` (logo horizontal, só para Android < 12); `ios/Runner/Base.lproj/LaunchScreen.storyboard` (cor de fundo + imagem `LaunchImage` em `ios/Runner/Assets.xcassets`); splash HTML/CSS inline em `web/index.html` (fundo `#4C4E53` + `<img>` do logo), removida no primeiro frame do Flutter

**Checkpoint**: todas as histórias funcionam de forma independente

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Cores de plataforma, aviso de armazenamento volátil, acessibilidade, escala, documentação, hook de pre-commit e gates finais

- [X] T069 [P] Teste de consistência das cores de plataforma em `test/theme/platform_colors_test.dart` (R17, complemento do gate 5): `theme_color`/`background_color` de `web/manifest.json`, a cor de fundo da splash em `web/index.html` e `splash_background` em `android/app/src/main/res/values/colors.xml` são iguais a `BrandColors.grayDark`
- [X] T070 Exibir um aviso persistente "Seus dados não serão salvos neste navegador" quando `storageVolatileProvider` for `true`, em `lib/ui/widgets/volatile_storage_banner.dart` (`bannerTheme`, ícone de alerta + texto), incluído em `ListItemsScreen` e `ListsScreen`
- [X] T071 [P] Teste de layout e acessibilidade em `test/ui/layout_360_test.dart`: com `tester.view.physicalSize` 360×740 (dpr 1), com `AppTheme.light()` e `AppTheme.dark()` e nomes de 80 caracteres, nenhuma exceção de overflow em `ListItemsScreen`, `ListsScreen` e nos diálogos; `meetsGuideline(androidTapTargetGuideline)`, `meetsGuideline(textContrastGuideline)` e `meetsGuideline(labeledTapTargetGuideline)` em ambos os temas; e, com `MediaQuery(disableAnimations: true)`, as transições próprias do app (splash, aparecimento dos banners, mudança de estado do item) usam duração zero (Constituição V, "reduzir movimento")
- [X] T072 Criar `tool/generate_scale_backup.dart` (R20), que usa `encodeBackup` de `lib/domain/backup_codec.dart` para gerar `test/fixtures/backup_50x100.json` (50 listas × 100 itens com nomes únicos, quantidades variadas, metade dos itens comprados, a lista de índice 0 ativa); rodar o script e versionar o arquivo gerado
- [X] T073 Teste de escala em `test/data/repository_scale_test.dart`: importar `test/fixtures/backup_50x100.json` via `parseBackup` + `importBackup` (50 listas × 100 itens) e verificar a corretude de `watchLists`, `toggleChecked`, `reorderUncheckedItems` e de uma ida e volta de backup (sem asserções de tempo, para manter o teste determinístico; os tempos são conferidos manualmente no quickstart)
- [X] T074 [P] Escrever `README.md` (o que é o app, setup, comandos de gate, build PWA, onde fica o tema) e `CLAUDE.md` do projeto (comandos; camadas `domain`/`data`/`state`/`ui`; "o domínio não importa Flutter"; "valores visuais só em `lib/ui/theme/`, verificado por `test/theme/no_visual_literals_test.dart`"; "identidade visual em `docs/marca.md`"; "rodar build_runner após mudar `database.dart`"; "versões de dependência exatas, sem `^`"), sem contradizer a constituição; o README inclui como instalar o hook da tarefa seguinte
- [X] T075 Criar o hook versionado `tool/git-hooks/pre-commit` (R19): script `sh` que, se houver arquivos staged em `projetos/supermarket-list/`, entra nessa pasta e roda `dart format --output=none --set-exit-if-changed .`, `flutter analyze` e `flutter test`, abortando o commit se algum falhar; não fazer nada se não houver arquivos staged desse projeto; instalação manual (copiar para `.git/hooks/pre-commit` na raiz do workspace), sem `core.hooksPath`
- [X] T076 Rodar os gates da constituição: `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (zero avisos) e `flutter test` (tudo verde, incluindo `test/theme/`); corrigir o que falhar
- [ ] T077 Executar os cenários 1–19 de [quickstart.md](quickstart.md) no Android (emulador ou celular) e no PWA gerado por `flutter build web --release --no-web-resources-cdn` + `dart run tool/generate_sw_manifest.dart`, incluindo o modo avião e a comparação com [docs/marca.md](../../docs/marca.md); registrar o resultado no fim de `quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências
- **Foundational (Phase 2)**: depende do Setup e BLOQUEIA todas as histórias. O tema (T020–T024) precisa estar pronto antes de qualquer widget
- **User Stories (Phases 3–8)**: dependem da Foundational; recomenda-se a ordem P1 ⇒ P6 (ver abaixo)
- **Polish (Phase 9)**: depois das histórias desejadas; T070 pode começar logo após a US1; T072 depende da T061 (`backup_codec`)

### User Story Dependencies

- **US1 (P1)**: só depende da Foundational
- **US2 (P2)**: estende `item_tile.dart` e `list_items_screen.dart` da US1 ⇒ depois da US1
- **US3 (P3)**: estende `lists_screen.dart` da US1 ⇒ depois da US1 (independente da US2)
- **US4 (P4)**: usa `list_tile.dart` e `confirm_dialog.dart` da US3 ⇒ depois da US3
- **US5 (P5)**: usa `lists_screen.dart` e `confirm_dialog.dart` ⇒ depois da US3 (independente da US2 e da US4)
- **US6 (P6)**: só toca `app.dart`, a splash e os arquivos nativos ⇒ depois da US1, em paralelo às demais

### Within Each User Story

- Testes escritos e FALHANDO antes da implementação
- Domínio ⇒ repositório ⇒ providers ⇒ widgets ⇒ telas
- Toda tarefa de UI termina com T024 (gate 5) verde
- Tarefas no mesmo arquivo (`shopping_repository.dart`, `providers.dart`, telas) são sequenciais
- História concluída (checkpoint) antes de passar para a próxima

### Parallel Opportunities

- Setup: T003, T004, T005 e T006 juntos
- Foundational: T007, T008 e T009 (testes) + T010 e T011 (erros/modelos) + T020, T021, T022 e T025 (tema e textos) juntos
- Em cada história, todas as tarefas de teste marcadas [P] juntas
- US3 e US6 podem andar em paralelo à US2; US5 em paralelo à US4

---

## Parallel Example: Foundational (tema)

```text
Task: "T020 Criar lib/ui/theme/brand_colors.dart"
Task: "T021 Criar lib/ui/theme/tokens.dart"
Task: "T022 Criar lib/ui/theme/app_typography.dart"
Task: "T009 Teste de contraste em test/theme/contrast_test.dart"
```

## Parallel Example: User Story 1

```text
# Testes da US1 juntos (arquivos diferentes):
Task: "T027 Testes de repositório em test/data/repository_lists_basic_test.dart"
Task: "T028 Testes de repositório em test/data/repository_items_checking_test.dart"
Task: "T029 Widget tests em test/ui/list_items_screen_test.dart"

# Widgets independentes da US1 juntos:
Task: "T032 Criar lib/ui/widgets/empty_state.dart"
Task: "T033 Criar lib/ui/widgets/name_dialog.dart"
```

## Parallel Example: User Story 5

```text
Task: "T058 Testes em test/domain/backup_codec_test.dart"
Task: "T059 Testes em test/domain/backup_reminder_test.dart"
Task: "T060 Testes de repositório em test/data/repository_backup_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup
2. Phase 2: Foundational, incluindo o tema T_YOU e o gate 5 (bloqueia tudo)
3. Phase 3: US1
4. **STOP and VALIDATE**: cenários 1–5, 11, 14 (PWA em modo avião) e 19 (marca) do [quickstart.md](quickstart.md) no Android e na web
5. A partir daqui o app já substitui a lista de papel, com a identidade T_YOU

### Incremental Delivery

1. Setup + Foundational ⇒ base e tema prontos
2. US1 ⇒ validar ⇒ MVP
3. US2 (manter itens) ⇒ validar
4. US3 (várias listas) ⇒ validar
5. US4 (reutilizar) ⇒ validar
6. US5 (backup) ⇒ validar; recomendado antes de usar o app "pra valer" na web
7. US6 (splash) + Polish ⇒ `/speckit-converge` até `Converged`

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Rodar `dart run build_runner build` sempre que `lib/data/database.dart` mudar
- Pendências de marca resolvidas em 2026-10-24: logo e ícones entregues em `assets/images/`; sem licença de Tactic Sans/Neue Plak (usar Michroma + Inter); `#E6E7E8` confirmado no manual
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
