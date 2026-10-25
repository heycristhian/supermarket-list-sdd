# Quickstart: validar a feature Listas de Supermercado

Guia para rodar o app e provar que a feature funciona de ponta a ponta. Detalhes de dados e
contratos: [data-model.md](data-model.md), [contracts/](contracts/).

## Pré-requisitos

- Flutter 3.47+ (stable) / Dart 3.13+. Confira com `flutter doctor`.
- Android: SDK instalado e um emulador ou celular com depuração USB.
- Web: Chrome.
- iOS: somente em macOS com Xcode (não validável neste host Windows).

## Setup

Na raiz do projeto (`projetos/supermarket-list`):

```powershell
flutter pub get
dart run build_runner build   # gera o código do drift
```

Os arquivos `web/sqlite3.wasm` e `web/drift_worker.js` precisam ser da mesma release do drift
declarada no `pubspec.lock` (ver [research.md](research.md) R2).

## Gates automáticos (constituição)

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Esperado: nenhuma alteração de formatação, nenhum aviso do analyzer e todos os testes passando,
incluindo os três testes exigidos em [contracts/repository.md](contracts/repository.md#testes-obrigatórios-mínimos-pedidos-explicitamente)
e o gate 5 da constituição (`test/theme/no_visual_literals_test.dart`: nenhum valor visual
literal fora de `lib/ui/theme/`; ver [research.md](research.md) R17). Para rodar só esse gate:

```powershell
flutter test test/theme
```

## Rodar

```powershell
flutter run -d <id-do-android>   # celular/emulador
flutter run -d chrome            # web em modo debug (sem service worker)
```

PWA de produção (offline):

```powershell
flutter build web --release --no-web-resources-cdn
dart run tool/generate_sw_manifest.dart          # gera build/web/sw_manifest.js (R6)
# servir build/web em qualquer servidor estático, ex.:
dart pub global activate dhttpd
dhttpd --path build/web --port 8080
```

## Cenários de validação manual

| # | Cenário | Resultado esperado | Spec |
|---|---|---|---|
| 1 | Abrir o app pela 1ª vez | splash breve ⇒ tela de listas vazia convidando a criar uma lista, em ≤ 1,5 s | FR-029, FR-012 |
| 2 | Criar "Lista semanal" | lista criada e ativa | US1, Assumptions |
| 3 | Adicionar 10 itens seguidos pelo campo do rodapé | o campo limpa e continua pronto após cada item; ≤ 60 s no total | FR-013a, SC-001 |
| 4 | Adicionar "arroz" com "Arroz" já na lista | rejeitado com mensagem; o texto continua no campo | FR-027, FR-028 |
| 5 | Marcar B e depois A em A,B,C,D; desmarcar B | C,D,B,A ⇒ B,C,D,A | US1 cenários 4–6 |
| 6 | Arrastar um item pela alça ⋮⋮; rolar a tela passando o dedo sobre os itens | só a alça move; rolar não marca nem move | FR-016a |
| 7 | Apagar um item e tocar em "Desfazer" | o item volta à mesma posição e estado | FR-015 |
| 8 | Criar mais 2 listas, ativar outra, reordenar as não ativas | ativa no topo com destaque; a anterior volta ao seu slot | US3 |
| 9 | Copiar uma lista com itens comprados | sugere "X (cópia)"; a cópia sai toda desmarcada | US4 |
| 10 | "Desmarcar todos" | confirmação ⇒ todos desmarcados na ordem original | FR-021 |
| 11 | Fechar o app à força 20× após alterações | nenhuma perda | SC-004 |
| 12 | Exportar, apagar todas as listas e importar | tudo restaurado, inclusive a lista ativa e as ordens | US5, SC-010 |
| 13 | Importar um `.json` qualquer que não seja backup | erro amigável; dados intactos | SC-011 |
| 14 | **Web**: abrir o PWA uma vez online, instalar, ativar o modo avião e reabrir | abre e funciona 100%, com os dados preservados | FR-023, SC-003 |
| 15 | Ativar "reduzir movimento" no sistema e abrir o app | splash sem animação | FR-030 |
| 16 | Alternar o tema do sistema entre claro e escuro; usar em 360 px de largura | ambos legíveis, sem rolagem horizontal | Constituição V |
| 17 | Gerar `test/fixtures/backup_50x100.json` com `dart run tool/generate_scale_backup.dart`, copiar para o celular e importar pelo app; cronometrar abrir o app, abrir uma lista, marcar um item, reordenar, exportar e importar | abrir/marcar/reordenar < 1 s cada; marcar reflete em < 0,5 s; exportar e importar < 5 s | SC-002, SC-005, SC-010 |
| 18 | Com uma lista ativa, fechar o app por completo e tocar no ícone | itens da lista ativa visíveis em ≤ 1,5 s, sem toques extras | SC-008 |
| 19 | Comparar as telas com [docs/marca.md](../../docs/marca.md) | só cores da paleta (e tons de R14); turquesa apenas como acento (barra da lista ativa, linhas, botões); títulos em Michroma (ou Tactic Sans), textos em Inter (ou Neue Plak); logo original na splash e no ícone; item comprado cinza e riscado; visual limpo | Constituição VI |

## Critério de pronto

Gates automáticos verdes + cenários 1–19 conferidos em Android e na web +
`/speckit-converge` reportando `Converged`.
