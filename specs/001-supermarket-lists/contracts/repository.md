# Contract: Repositório de listas (fronteira UI ↔ dados)

Contrato interno entre a camada de estado/UI e a camada de dados. A UI só conversa com o banco por
este contrato, que é o que os testes de repositório exercitam. Todas as operações são `async`, rodam
em transação e atualizam `lastChangeAt`. Os erros de domínio estão em
[data-model.md](../data-model.md#validações-erros-de-domínio).

## Leitura (streams reativos)

| Operação | Retorno | Observação |
|---|---|---|
| `watchLists()` | `Stream<ListsOverview>` | `active: ShoppingList?` + `others: List<ShoppingList>` por `position`; cada lista com `total` e `checked` |
| `watchItems(listId)` | `Stream<List<ShoppingItem>>` | já na ordem de exibição (não comprados, depois comprados) |
| `watchActiveListId()` | `Stream<int?>` | define a tela inicial (FR-012) |
| `watchBackupReminder()` | `Stream<bool>` | regra de R12 em [research.md](../research.md) |

## Listas

| Operação | Regras / erros | Requisitos |
|---|---|---|
| `createList(name) → int` | vazio/longo/duplicado ⇒ erro; vira ativa se não houver nenhuma ativa | FR-001 |
| `renameList(id, name)` | idem; mudar só maiúsculas/minúsculas do próprio nome é permitido | FR-002 |
| `deleteList(id)` | apaga os itens em cascata; se era ativa ⇒ nenhuma ativa | FR-003 |
| `suggestCopyName(id) → String` | "X (cópia)", "X (cópia N)" | FR-004 |
| `copyList(id, newName) → int` | valida o nome; copia os itens desmarcados na mesma ordem original | FR-005, FR-006 |
| `activateList(id)` | substitui a ativa anterior | FR-007 |
| `reorderInactiveLists(oldIndex, newIndex)` | índices dentro de `others`; algoritmo de slots | FR-010, FR-011 |
| `moveList(id, delta: -1 \| +1)` | alternativa acessível ao arraste | FR-025 |

## Itens

| Operação | Regras / erros | Requisitos |
|---|---|---|
| `addItem(listId, name, quantity?) → int` | vazio/longo/duplicado na lista ⇒ erro; entra no fim dos não comprados | FR-013, FR-017 |
| `editItem(id, name, quantity?)` | idem; quantidade vazia ⇒ `null`; posição e estado mantidos | FR-014 |
| `deleteItem(id) → DeletedItem` | devolve um snapshot para desfazer | FR-015 |
| `restoreItem(DeletedItem)` | reinsere com a mesma posição e estado | FR-015 |
| `reorderUncheckedItems(listId, oldIndex, newIndex)` | índices dentro dos não comprados; algoritmo de slots | FR-016 |
| `moveItem(id, delta: -1 \| +1)` | só itens não comprados | FR-025 |
| `toggleChecked(id)` | marcar ⇒ vai para o fim; desmarcar ⇒ volta ao slot | FR-018–FR-020 |
| `uncheckAll(listId)` | todos desmarcados, ordem original | FR-021 |

## Backup

| Operação | Regras / erros | Requisitos |
|---|---|---|
| `exportBackup() → Uint8List` | JSON de [backup-file.md](backup-file.md); define `lastBackupAt = now` depois de salvar com sucesso | FR-031 |
| `parseBackup(bytes) → BackupData` | validação completa, sem tocar no banco; `InvalidBackupException` | FR-033 |
| `importBackup(BackupData)` | transação única que substitui tudo; ao final, `lastBackupAt = lastChangeAt = now` (o lembrete não aparece logo após restaurar) | FR-032, FR-033, FR-034 |
| `snoozeBackupReminder()` | `snoozedUntil = now + 7 dias` | FR-034 |

## Testes obrigatórios mínimos (pedidos explicitamente)

- **Lista ativa única**: ativar X e depois Y ⇒ apenas Y ativa; apagar a ativa ⇒ nenhuma ativa; a 1ª
  lista criada vira ativa.
- **Cópia desmarcada**: copiar uma lista com itens comprados ⇒ a cópia tem os mesmos itens e
  quantidades, na ordem original, todos com `checkedSeq = null`; a original fica intacta.
- **Comprado vai para o fim**: A,B,C,D ⇒ marcar B ⇒ A,C,D,B ⇒ marcar A ⇒ C,D,B,A ⇒ desmarcar B
  ⇒ B,C,D,A.
