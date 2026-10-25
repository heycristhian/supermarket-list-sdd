# Research: Listas de Supermercado

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-10-24

Ambiente verificado em 2026-10-24: Flutter 3.47.8 (stable), Dart 3.13.7, Android SDK 36.1,
Chrome disponível, host Windows 10.

## R1. Framework e plataformas

- **Decision**: Flutter 3.47 / Dart 3.13, um único código para Android, iOS e web.
- **Rationale**: escolha do usuário; já instalado na máquina; um só código atende celular e web.
- **Alternatives considered**: PWA puro em HTML/CSS/JS (menos dependências, mas sem app nativo
  Android/iOS); React Native (não atende web tão bem e não está instalado).
- **Constraint**: builds e testes em iOS exigem macOS + Xcode. O host atual é Windows, então iOS
  fica "suportado no código, validado quando houver um Mac ou CI com macOS". Android e web são
  validados localmente.

## R2. Armazenamento local nas três plataformas

- **Decision**: `drift` (2.35.x) + `drift_flutter` (0.3.x), com geração de código via `drift_dev`
  + `build_runner` (somente dev).
- **Rationale**: drift funciona em Android, iOS e web com a mesma API; oferece transações (para a
  importação tudo-ou-nada, FR-033), índices únicos (unicidade de nomes, FR-027), streams reativos
  (a UI atualiza sozinha) e migrações de schema versionadas.
- **Web**: `driftDatabase(name: ..., web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'),
  driftWorker: Uri.parse('drift_worker.js')))`. Os dois arquivos ficam em `web/`, sempre da
  mesma release do drift. O drift escolhe sozinho OPFS ou IndexedDB. Sem os headers COOP/COEP ele
  usa IndexedDB, que é suficiente para este volume de dados; não exigimos headers especiais da
  hospedagem.
- **Risco web**: o armazenamento do navegador pode ser apagado pelo browser sob pressão de disco.
  Mitigação: pedir armazenamento persistente (`navigator.storage.persist()` via `dart:js_interop`,
  sem pacote extra) e o backup manual com lembrete (User Story 5). Se o drift cair no modo
  `inMemory` (ex.: janela anônima do Firefox), o app MUST exibir um aviso de que os dados não serão
  salvos.
- **Alternatives considered**: `sqflite` (sem suporte web); `shared_preferences`/`hive` (sem
  transações nem índices únicos, regras ficariam todas em código); `isar` (manutenção instável).

## R3. Testes do banco no host Windows

- **Decision**: testes de repositório usam `NativeDatabase.memory()` (`package:drift/native.dart`)
  injetado pelo construtor do banco, com `closeStreamsSynchronously: true` em widget tests.
- **Rationale**: drift recomenda esse padrão; roda no computador sem device. O pacote `sqlite3`
  3.x (dependência do drift) empacota a biblioteca SQLite nativa via build hooks, por isso não é
  preciso instalar SQLite no Windows. **Verificar na primeira tarefa de setup**: se `flutter test`
  falhar ao carregar SQLite, documentar no quickstart a instalação da `sqlite3.dll`.

## R4. Gerenciamento de estado

- **Decision**: `flutter_riverpod` 3.x **sem geração de código** (sem `riverpod_generator`), usando
  `Provider`, `StreamProvider` e `Notifier` escritos à mão.
- **Rationale**: overrides de provider deixam os testes simples (trocar o banco real por um em
  memória e o relógio por um fixo) sem `BuildContext`. Dispensar o gerador evita mais uma
  dependência de dev e código gerado.
- **Alternatives considered**: `provider` (igualmente simples, mas testar fora da árvore de widgets
  dá mais trabalho); `setState` puro (espalharia o acesso ao banco pelas telas).

## R5. Arrastar para reordenar com alça

- **Decision**: `ReorderableListView` / `SliverReorderableList` do próprio Flutter, com
  `buildDefaultDragHandles: false` e um `ReorderableDragStartListener` envolvendo **só** a alça
  ⋮⋮.
- **Rationale**: atende exatamente o esclarecimento "a alça é a única área de arraste" (FR-016a) sem
  dependências. Na tela de listas, um `CustomScrollView` mostra a lista ativa fixa no topo (sliver
  comum) e as não ativas em um `SliverReorderableList`.
- **Acessibilidade (FR-025)**: o menu ⋯ de cada item e de cada lista oferece "Mover para cima" e
  "Mover para baixo", que chamam a mesma operação de reordenar.

## R6. PWA e funcionamento offline na web

- **Decision**: manifest próprio em `web/manifest.json` + **service worker escrito à mão**
  (`web/sw.js`, ~60 linhas) registrado em `web/index.html`; build com
  `flutter build web --release --no-web-resources-cdn`.
- **Rationale**: a partir do Flutter 3.41 o `flutter_service_worker.js` padrão deixou de fazer
  cache offline (agora apenas remove workers antigos), então o offline precisa de um worker
  próprio. Estratégia do `sw.js`:
  - no `install`, pré-cachear **todos os arquivos do build**. Como um service worker só
    pré-carrega arquivos individuais e os nomes do CanvasKit/skwasm variam por build, o script
    `tool/generate_sw_manifest.dart` (só `dart:io` + `dart:convert`) roda depois de
    `flutter build web`, lista `build/web/**` (exceto `sw.js` e o próprio manifesto) e grava
    `build/web/sw_manifest.js` com `self.SW_PRECACHE = [...]` e
    `self.SW_VERSION = <hash do conteúdo>`. O `sw.js` faz `importScripts('sw_manifest.js')` e
    usa a lista e a versão;
  - em navegações, network-first com fallback para o cache (assim versões novas chegam quando há
    rede);
  - nos demais arquivos do mesmo domínio, cache-first com atualização em segundo plano;
  - um nome de cache versionado; versões antigas são apagadas no `activate`.
- **Descoberto na implementação (2026-10-24)**: o `flutter_bootstrap.js` padrão registra o
  `flutter_service_worker.js` (um worker de limpeza que se desregistra e recarrega a página)
  sempre que já existe um registro na origem, o que derrubaria o `sw.js`. Por isso o projeto
  tem um `web/flutter_bootstrap.js` próprio que chama `_flutter.loader.load()` **sem**
  `serviceWorkerSettings`, e o `index.html` registra o `sw.js` só quando o build tem
  `sw_manifest.js` (em `flutter run`/debug ele não existe). O gerador pré-carrega só as
  variantes de renderer usadas pelo build (`canvaskit/` e `canvaskit/chromium/`; inclui
  `skwasm` se o build usar) e ignora `*.symbols`: ~19 MB em vez de ~35 MB.
- `--no-web-resources-cdn` faz o CanvasKit ser servido pelo próprio app, em vez de vir do CDN do
  Google (sem isso o app não abre offline).
- **Fontes**: as fontes da marca (R15) são assets do app (arquivos, não pacote), para que a web
  não busque fontes no Google Fonts em tempo de execução.
- **Alternatives considered**: Workbox CLI (exige Node e mais uma etapa de build); confiar no
  worker padrão do Flutter (não faz mais cache offline).

## R7. Exportar e importar backup

- **Decision**: `file_picker` 13.x: `saveFile(fileName:, bytes:)` para exportar e
  `pickFiles()` + `readAsBytes()` para importar. Formato JSON versionado (ver
  [contracts/backup-file.md](contracts/backup-file.md)), codificado com `dart:convert`.
- **Rationale**: um único pacote cobre Android, iOS e web. Na web, `saveFile` faz download do
  arquivo; não usamos `FilePickerWebOptions`, o que evita imports condicionais.
- **Constraint**: `file_picker` exige iOS 14+, que passa a ser a versão mínima do iOS
  (`platform :ios, '14.0'` em `ios/Podfile` e `IPHONEOS_DEPLOYMENT_TARGET = 14.0` no
  `ios/Runner.xcodeproj`).
- **Alternatives considered**: `share_plus` + `file_picker` (dois pacotes); `path_provider` +
  escrita manual (não funciona na web e o arquivo fica escondido no sandbox do app).

## R8. Splash screen animada

- **Decision**: duas etapas, ambas sem pacotes:
  1. splash nativa estática (Android 12+ SplashScreen API via tema, `LaunchScreen.storyboard` no
     iOS e HTML/CSS inline em `web/index.html`) com fundo `#4C4E53` e o logo T_YOU na versão
     clara (R16);
  2. widget Flutter `SplashScreen`: mesmo fundo, com o gradiente suave cinza → turquesa da marca
     (`context.brand.splashGradient`), o logo com fade + escala e uma linha fina turquesa que se
     desenha sob ele, em animação curta (≤ 600 ms). A transição para a tela inicial acontece
     quando a animação termina e o banco abre, o que ocorrer por último, dentro do teto de 1,5 s
     (FR-029).
- Com `MediaQuery.disableAnimations` (reduzir movimento) a animação é pulada (FR-030). A splash só
  existe na inicialização a frio; voltar do segundo plano não recria o widget.
- **Alternatives considered**: `flutter_native_splash` (dependência para algo configurável à mão);
  Lottie/Rive (dependência pesada para uma animação curta).

## R9. Ordem dos itens e das listas ("slots")

- **Decision**: cada item tem `position` (a ordem original) e `checkedSeq` (null = não comprado;
  número crescente = ordem em que foi marcado). A exibição é: não comprados por `position`, depois
  comprados por `checkedSeq`.
  - Marcar: `checkedSeq = maior checkedSeq da lista + 1`. Desmarcar: `checkedSeq = null`; o item
    volta sozinho ao seu lugar (FR-020). "Desmarcar todos": todos `null` (FR-021).
  - Reordenar não comprados: os não comprados recebem a nova ordem **nos mesmos "slots" de
    position que ocupavam**; os comprados mantêm seus slots. Exemplo: original A,B,C,D com B
    comprado; arrastar D para o início ⇒ slots 0,2,3 recebem D,A,C ⇒ ordem original D,B,A,C.
  - Item novo: `position = maior position + 1` (fica no fim dos não comprados, FR-017).
- **Listas**: o mesmo algoritmo de slots. A lista ativa conserva sua `position`, apenas é
  exibida no topo; ao deixar de ser ativa ela reaparece no seu slot (FR-011).
- **Rationale**: regra pura, sem banco, fácil de testar exaustivamente em `domain/ordering.dart`.

## R10. Lista ativa única

- **Decision**: o id da lista ativa fica em uma única linha da tabela `app_settings`
  (`activeListId`, nullable, FK com `ON DELETE SET NULL`).
- **Rationale**: "no máximo uma ativa" passa a ser garantido pela estrutura dos dados, não por
  código que precisa desligar as outras (FR-007). Apagar a lista ativa deixa o campo nulo
  (cenário 6 da US3).
- **Alternatives considered**: coluna `isActive` em cada lista (exige transação e testes para
  evitar duas ativas).

## R11. Unicidade de nomes

- **Decision**: cada lista e cada item guardam `name` (como digitado, sem espaços nas pontas) e
  `nameKey` = `name` com espaços colapsados e `toLowerCase()`, sem remover acentos. Índices
  únicos: `lists(nameKey)` e `items(listId, nameKey)`. O repositório valida antes e traduz a
  violação do índice em um erro de domínio `DuplicateNameException`.
- **Rationale**: o banco garante a regra (SC-009) e a UI recebe um erro claro para mostrar
  (FR-028). Renomear mudando só maiúsculas/minúsculas passa, porque o conflito é com o próprio
  registro.
- **Sugestão de nome da cópia**: função pura `suggestCopyName(original, existingKeys)` ⇒
  "X (cópia)", "X (cópia 2)", ...

## R12. Tempo e lembrete de backup

- **Decision**: `app_settings` guarda `lastBackupAt`, `lastChangeAt` e `backupReminderSnoozedUntil`.
  Toda escrita no repositório atualiza `lastChangeAt`. O relógio é injetado
  (`DateTime Function() now` via provider), sem o pacote `clock`.
- **Regra**: mostrar o lembrete se `lastChangeAt > (lastBackupAt ?? -∞)` e
  `now ≥ (lastBackupAt ?? -∞) + 7 dias` e `now ≥ (snoozedUntil ?? -∞)`. Dispensar ⇒
  `snoozedUntil = now + 7 dias`. Exportar ⇒ `lastBackupAt = now`. Importar ⇒
  `lastBackupAt = lastChangeAt = now`, porque os dados restaurados equivalem a um backup
  recém-feito. Isso evita que o lembrete apareça logo após restaurar em um celular novo.

## R13. Desfazer ao apagar item

- **Decision**: `SnackBar` com ação "Desfazer" (≈ 5 s). O repositório apaga o item e devolve um
  snapshot dele; desfazer reinsere o mesmo nome, quantidade, `position` e `checkedSeq`.
- **Rationale**: componente nativo do Material; nenhum estado "apagado" no banco.

## R14. Tema central com a identidade T_YOU (Constituição v1.1.0, Princípio VI)

- **Decision**: Material 3 com `ColorScheme` **montado à mão** a partir da paleta da marca (sem
  `ColorScheme.fromSeed`, que geraria matizes fora da paleta), mais uma `ThemeExtension`
  `BrandTheme` para os papéis que o `ColorScheme` não cobre. Todo o tema fica em
  `lib/ui/theme/`:
  - `brand_colors.dart`: as 5 cores de [docs/marca.md](../../docs/marca.md) e os tons de
    acessibilidade abaixo, cada um com o motivo em comentário;
  - `tokens.dart`: espaçamentos, raios, alturas, tamanhos de ícone e de toque, elevações e
    durações;
  - `app_typography.dart`: famílias de fonte e escala de texto (R15);
  - `brand_theme.dart`: a `ThemeExtension` (acento da lista ativa, texto de item comprado,
    linha de destaque, gradiente da splash) + o atalho `context.brand`;
  - `app_theme.dart`: `ThemeData` claro e escuro com os temas de componentes (AppBar, botões,
    campos, diálogos, SnackBar, menus, MaterialBanner, ListTile e foco).
- **Rationale**: o Princípio VI proíbe valores visuais nas telas e matizes fora da paleta;
  centralizar em `ThemeData` + extensão permite que os widgets usem só `Theme.of(context)` e
  `context.brand`.

### Contraste: marca × WCAG AA (a acessibilidade prevalece)

Valores aproximados de contraste, calculados com a fórmula de luminância relativa do WCAG 2.1.

| Uso | Combinação da marca | Contraste | Decisão no tema |
|---|---|---|---|
| Texto/botão de destaque no tema claro | branco sobre `#00A5B4` | ~3,0:1 ❌ | **Turquesa escuro `#006B75`** (mesma matiz, mais escuro): branco sobre ele ~6,2:1; sobre `#E6E7E8` ~5,0:1 |
| Texto de destaque no tema escuro | `#00A5B4` sobre `#4C4E53` | ~2,8:1 ❌ | **Turquesa claro `#7FD2D9`** (turquesa 50% clareado): sobre `#4C4E53` ~4,8:1; botão preenchido com texto `#4C4E53` |
| Texto de item comprado no tema claro | `#767678` sobre `#E6E7E8` | ~3,6:1 ❌ | Os itens ficam em cards `#FEFEFE`; texto comprado em **`#6B6B6D`** (cinza médio escurecido) ~5,3:1. `#767678` fica para ícones e alça (≥ 3:1) |
| Texto secundário no tema escuro | `#767678` sobre `#4C4E53` | ~1,8:1 ❌ | `#E6E7E8` (~6,7:1); item comprado em **`#C4C5C7`** (~4,8:1) |
| Texto principal | `#4C4E53` sobre `#FEFEFE`/`#E6E7E8`; `#FEFEFE` sobre `#4C4E53` | ~8,3 / 6,7 / 8,3:1 ✅ | Mantido |

- O turquesa puro `#00A5B4` fica para os **acentos que não são texto**: a barra lateral fina da
  lista ativa, as linhas finas divisórias de destaque, o traço do logo e o gradiente da splash.
  Como ele não atinge 3:1 sobre fundos claros, nenhum estado depende só dele: a lista ativa
  também tem o selo de texto "ATIVA", e o item comprado também tem riscado + ícone de check.
- Anel de foco: `#006B75` no tema claro e `#7FD2D9` no escuro (≥ 3:1 em ambos).
- Esses 4 tons derivados são as únicas cores além da paleta, todos variações de tom permitidas
  pelo Princípio VI.

### Papéis de cor

| Papel | Claro | Escuro |
|---|---|---|
| Fundo da tela | `#E6E7E8` | `#4C4E53` |
| Cards/superfícies | `#FEFEFE` | `#4C4E53` + borda fina `#767678` |
| Texto principal | `#4C4E53` | `#FEFEFE` |
| Texto secundário (quantidade, progresso) | `#4C4E53` em peso regular | `#E6E7E8` |
| Destaque (botões, seleção, check) | `#006B75` | `#7FD2D9` |
| Texto sobre destaque | `#FEFEFE` | `#4C4E53` |
| Acento decorativo (lista ativa, linhas) | `#00A5B4` | `#00A5B4` |
| Item comprado (texto + riscado) | `#6B6B6D` | `#C4C5C7` |
| Ícones neutros, alça ⋮⋮ | `#767678` | `#E6E7E8` |
| Erro | sem cor de erro na marca ⇒ `#4C4E53` / `#FEFEFE` com ícone de alerta e texto explícito (não introduz uma nova matiz) | idem |

- **Medidas** (em `tokens.dart`): espaçamentos 4/8/12/16/24/32; raios 8/12/20; `minTouchTarget = 48`;
  `itemRowMinHeight = 64`; `activeAccentWidth = 4`; `accentLineThickness = 1`; ícones 20/24/32;
  durações 150/250/600 ms; `undoSnackBarDuration = 5 s`.
- **Visual**: limpo, com bastante espaço vazio; poucos elementos por tela; linhas finas
  turquesa como detalhe; rótulos de apoio em caixa alta com espaçamento largo (ex.: "ATIVA",
  "OUTRAS LISTAS").
- **Qualidade**: `flutter_lints` + `dart format` + `flutter analyze` sem avisos. Textos da UI em
  pt-BR, centralizados em `lib/ui/strings.dart`, sem pacote de i18n.

## R15. Tipografia

- **Decision**: usar as **alternativas gratuitas de [docs/marca.md](../../docs/marca.md)**:
  **Michroma** (títulos curtos e números de destaque: título da tela, "3 de 10", splash) e
  **Inter** (todo o resto), embutidas como assets (OFL). A Inter entra como **arquivos estáticos**
  (`Inter-Regular`, `Inter-Medium`, `Inter-SemiBold` e `Inter-Bold`, declarados com `weight:`
  400/500/600/700), não como fonte variável: o Flutter não associa `fontWeight` aos pesos de uma
  fonte variável declarada no `pubspec`, e o negrito sairia sintetizado. Confirmado em 2026-10-24: não há
  licença de app para Tactic Sans/Neue Plak. `app_typography.dart` define as constantes
  `headingFamily` e `bodyFamily`, que são o único ponto de troca caso uma licença seja obtida
  no futuro.
- **Escala**: Michroma só em tamanhos ≥ 20 sp (é larga e perde legibilidade em tamanhos
  pequenos); Inter 14–18 sp no corpo; rótulos de apoio em Inter caixa alta com `letterSpacing`
  largo. A escala respeita o `textScaler` do sistema.
- **Rationale**: Tactic Sans e Neue Plak são comerciais; sem os arquivos licenciados, as
  alternativas previstas pela própria marca evitam bloquear a implementação.
- **Alternatives considered**: Orbitron no lugar de Michroma (mais "futurista", menos fiel à
  forma larga e limpa); `google_fonts` (busca as fontes na internet, o que quebra o offline, e é
  mais uma dependência).

## R16. Logo e ícones

- **Decision**: arquivos originais em **PNG**, já entregues em `assets/images/`:
  - `logo_light.png`: logo horizontal 2836×378, letras brancas e "_" turquesa, fundo
    transparente. Usado na splash (Flutter, nativa e web), sempre sobre fundo escuro. A
    resolução dispensa variantes 2.0x/3.0x.
  - `icon_square_dark.png`: 1024×1024, a aplicação quadrada do manual (pág. 17, arte do boné):
    logo branco sobre `#4C4E53`. Base dos ícones do app, do PWA e do favicon.
  - `icon_foreground.png`: 1024×1024, o mesmo logo com fundo transparente, para o ícone
    adaptativo do Android (fundo `#4C4E53`).
  - Os ícones foram extraídos dos **traços vetoriais originais** do PDF (PyMuPDF), sem redesenho,
    e recolocados sobre a cor exata da marca. A renderização direta alterava o cinza por causa
    do perfil de cor.
- **Rationale**: o Princípio VI proíbe recriar o logo. PNG evita adicionar `flutter_svg`
  (Princípio IV).
- **Sem versão escura** (`logo_dark.png`): o logo só aparece sobre fundo escuro nesta feature.
- **Observação**: no quadrado, o logo ocupa ~67% da largura; em ícones de 48 px as letras
  ficam pequenas, mas é a aplicação quadrada definida pela marca.

## R17. Verificação automática de valores visuais literais (quality gate 5)

- **Decision**: teste `test/theme/no_visual_literals_test.dart` (só `dart:io`, sem pacotes) que
  percorre **`lib/ui/**/*.dart` e `lib/app.dart`, exceto `lib/ui/theme/`**, e falha ao
  encontrar os padrões abaixo. `lib/domain/`, `lib/data/` e `lib/state/` ficam fora: eles não são
  telas nem widgets (Princípio VI), e o domínio usa durações de regra de negócio (ex.: 7 dias do
  lembrete). O teste falha ao
  encontrar: `Color(`, `Colors.`, literais `0xFF…`, `fontFamily:`, `fontSize:`, `letterSpacing:`,
  `EdgeInsets.*(` com número diferente de 0, `SizedBox(width:|height:` com número,
  `BorderRadius.circular(` com número, `size:` com número, `elevation:` com número e
  `Duration(` com número. A mensagem aponta o arquivo e a linha.
- **Complemento**: o mesmo teste confere se as cores nos arquivos de plataforma (que não podem
  ler o tema Dart) são iguais às de `brand_colors.dart`: `theme_color`/`background_color` em
  `web/manifest.json` e a cor de fundo da splash em `android/.../values/colors.xml` e
  `web/index.html`.
- **Rationale**: transforma o Princípio VI em um gate objetivo que roda dentro do `flutter test`
  (Princípio II: um comando único).
- **Alternatives considered**: regra de lint customizada (`custom_lint`, mais dependências);
  revisão manual (não é verificável).

## R18. Fixação de versões (Constituição IV)

- **Decision**: todas as dependências (runtime e dev) com **versão exata** no `pubspec.yaml`
  (ex.: `drift: 2.35.3`, sem `^`), mais o `pubspec.lock` versionado no git. Atualizar uma
  dependência é uma mudança explícita: editar a versão, rodar `flutter pub get` e os gates.
- **Rationale**: o Princípio IV exige "versão fixada"; as faixas com `^` permitiriam versões
  diferentes entre máquinas. O lockfile sozinho não protege contra um `flutter pub upgrade`
  acidental.
- **Alternatives considered**: só o `pubspec.lock` (fixa, mas não deixa a intenção explícita no
  `pubspec.yaml`).

## R19. Gate de testes antes do commit (Constituição, Fluxo)

- **Decision**: hook de git versionado em `tool/git-hooks/pre-commit` (script `sh`, que o Git for
  Windows também executa). Ele roda `dart format --output=none --set-exit-if-changed`,
  `flutter analyze` e `flutter test` **somente quando há arquivos staged em
  `projetos/supermarket-list/`**, porque o repositório git é o workspace inteiro. A instalação é
  manual e documentada no README: copiar o script para `.git/hooks/pre-commit` na raiz do
  workspace (não usar `core.hooksPath`, para não afetar os outros projetos).
- **Rationale**: a constituição exige a suíte verde antes de commits; um hook torna isso
  automático sem CI.

## R20. Dados de escala para validar tempos (SC-005, SC-010)

- **Decision**: o script `tool/generate_scale_backup.dart` usa o `backup_codec` do domínio para
  gerar `test/fixtures/backup_50x100.json` (50 listas × 100 itens, metade comprados, uma lista
  ativa). O teste de escala usa o arquivo, e no quickstart o usuário o **importa pelo próprio
  app** e cronometra as operações. Nada de código de "seed" dentro do app.
- **Rationale**: reaproveita o fluxo de backup que já existe e mantém o app sem código só de
  depuração (Princípio I).
