# Listas de Supermercado

App pessoal de listas de compras, offline, para Android, iOS e web (PWA instalável), com a
identidade visual T_YOU. Um único código em Flutter, sem backend: os dados ficam no aparelho
(SQLite) e podem ir para outro aparelho por um arquivo de backup.

O que o app faz:

- várias listas, uma ativa por vez, que aparece no topo e abre direto ao iniciar o app;
- itens com nome e quantidade livre; marcar como comprado manda o item para o fim, e desmarcar
  o devolve ao seu lugar; "Desmarcar todos" volta à ordem original;
- reordenar itens e listas pela alça ⋮⋮ (ou por "Mover para cima/baixo" no menu ⋯);
- copiar uma lista (a cópia vem toda desmarcada), renomear, apagar e desfazer a remoção de itens;
- nomes únicos (sem diferenciar maiúsculas/minúsculas) por lista e dentro de cada lista;
- backup em arquivo JSON, com lembrete a cada 7 dias.

A especificação completa está em [specs/001-supermarket-lists/](specs/001-supermarket-lists/), e a
constituição do projeto em [.specify/memory/constitution.md](.specify/memory/constitution.md).

## Setup

Requer Flutter 3.47 ou mais novo (Dart 3.13).

```sh
flutter pub get
flutter run -d chrome        # web, sem modo offline
flutter run                  # Android/iOS com aparelho ou emulador conectado
```

Depois de mudar `lib/data/database.dart`, gere o código do drift de novo:

```sh
dart run build_runner build
```

## Gates de qualidade

Os três precisam passar antes de cada commit (constituição, quality gates):

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

`flutter test` inclui o teste [test/theme/no_visual_literals_test.dart](test/theme/no_visual_literals_test.dart),
que falha se alguma tela usar cor, fonte, tamanho ou duração escritos direto no código.

### Hook de pre-commit (opcional)

O hook [tool/git-hooks/pre-commit](tool/git-hooks/pre-commit) roda os três gates antes de cada
commit. Para instalar:

```sh
cp tool/git-hooks/pre-commit .git/hooks/pre-commit
```

## Build da web (PWA offline)

```sh
flutter build web --release --no-web-resources-cdn
dart run tool/generate_sw_manifest.dart
```

O segundo comando gera `build/web/sw_manifest.js`, a lista de arquivos que o service worker
([web/sw.js](web/sw.js)) guarda para funcionar offline. Para testar localmente:

```sh
dart pub global activate dhttpd
dhttpd --path build/web --port 8080
```

## Onde fica cada coisa

| Pasta | Conteúdo |
|---|---|
| `lib/domain/` | regras puras (nomes, ordenação, backup, lembrete), sem Flutter |
| `lib/data/` | banco drift, repositório e arquivos de backup |
| `lib/state/` | providers do Riverpod |
| `lib/ui/` | telas, widgets e textos (`strings.dart`) |
| `lib/ui/theme/` | **tema central**: cores, tipografia, medidas e durações |
| `docs/` | identidade visual T_YOU em [docs/marca.md](docs/marca.md) (o manual em PDF não é versionado) |
| `tool/` | geradores (manifesto do service worker, backup de escala) e o hook de pre-commit |

Para mudar a aparência do app, mexa só em `lib/ui/theme/`: telas e widgets leem tudo de lá.
