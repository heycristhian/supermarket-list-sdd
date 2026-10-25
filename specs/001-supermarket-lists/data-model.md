# Data Model: Listas de Supermercado

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Research**: [research.md](research.md)

Banco local drift (SQLite), schema versão 1. Três tabelas. As regras de ordem e de nomes estão em
[research.md](research.md) (R9, R10 e R11) e são implementadas como funções puras em `lib/domain/`.

## Tabela `shopping_lists`

| Campo | Tipo | Regras |
|---|---|---|
| `id` | int, PK autoincrement | — |
| `name` | text, não nulo | sem espaços nas pontas; 1–80 caracteres após normalização |
| `nameKey` | text, não nulo, **UNIQUE** | `normalizeKey(name)`: espaços colapsados + minúsculas; acentos mantidos |
| `position` | int, não nulo | ordem definida pelo usuário entre todas as listas (inclui a ativa) |

## Tabela `shopping_items`

| Campo | Tipo | Regras |
|---|---|---|
| `id` | int, PK autoincrement | — |
| `listId` | int, FK → `shopping_lists.id` **ON DELETE CASCADE** | apagar a lista apaga os itens (FR-003) |
| `name` | text, não nulo | sem espaços nas pontas; 1–80 caracteres |
| `nameKey` | text, não nulo | **UNIQUE (`listId`, `nameKey`)**: único dentro da lista (FR-013) |
| `quantity` | text, nulo | texto livre, sem espaços nas pontas; vazio ⇒ `null`; até 40 caracteres |
| `position` | int, não nulo | slot na ordem original da lista |
| `checkedSeq` | int, nulo | `null` = não comprado; senão, a ordem em que foi marcado |

Índice adicional: `(listId, position)` para leitura ordenada.

## Tabela `app_settings` (uma única linha, `id = 1`)

| Campo | Tipo | Regras |
|---|---|---|
| `id` | int, PK, sempre 1 | `CHECK (id = 1)` |
| `activeListId` | int, nulo, FK → `shopping_lists.id` **ON DELETE SET NULL** | no máximo uma lista ativa, garantido pela estrutura (FR-007) |
| `lastBackupAt` | datetime, nulo | atualizado ao exportar com sucesso e ao importar (= `now`) |
| `lastChangeAt` | datetime, nulo | atualizado em toda escrita em listas ou itens; ao importar, = `lastBackupAt` |
| `backupReminderSnoozedUntil` | datetime, nulo | definido ao dispensar o lembrete |

`PRAGMA foreign_keys = ON` é ativado na abertura do banco (necessário para CASCADE e SET NULL).

## Relações

```text
app_settings (1) ──activeListId──▶ (0..1) shopping_lists (1) ──▶ (0..N) shopping_items
```

## Ordem de exibição

- **Itens de uma lista**: `checkedSeq IS NULL` ordenados por `position`; depois `checkedSeq IS NOT
  NULL` ordenados por `checkedSeq`.
- **Tela de listas**: a lista `activeListId` (se houver) primeiro; depois as demais por `position`.

## Transições de estado de um item

```text
            marcar: checkedSeq = max(checkedSeq na lista) + 1
 [não comprado] ───────────────────────────────────────▶ [comprado]
       ▲                                                     │
       └──── desmarcar / desmarcar todos: checkedSeq = null ─┘
```

- Um item comprado não pode ser reordenado (FR-016); editar o nome ou a quantidade não muda o
  estado.
- Copiar a lista: os itens são copiados com o mesmo `name`, `quantity` e `position`, e
  `checkedSeq = null` (FR-005).

## Transições da lista ativa

| Ação | Efeito em `activeListId` |
|---|---|
| Criar a 1ª lista quando `activeListId` é nulo | passa a ser a nova lista |
| Criar outras listas | sem alteração; a nova lista entra com `position = max + 1` |
| Ativar a lista X | `= X` (a anterior deixa de ser ativa automaticamente) |
| Apagar a lista ativa | `null` (SET NULL) |
| Importar backup | `= ` lista indicada no arquivo, ou `null` |

## Validações (erros de domínio)

| Erro | Quando |
|---|---|
| `EmptyNameException` | nome vazio após normalização (lista, item ou título da cópia) |
| `NameTooLongException` | nome com mais de 80 caracteres ou quantidade com mais de 40 |
| `DuplicateNameException` | `nameKey` já existe no escopo (todas as listas, ou a mesma lista para itens) |
| `InvalidBackupException` | arquivo de backup ilegível ou fora do contrato ([contracts/backup-file.md](contracts/backup-file.md)) |

Os limites de 80 e 40 caracteres vêm da spec (FR-001, FR-002, FR-013 e o caso de borda "nomes
longos"). O layout quebra a linha ou trunca o texto com reticências.
