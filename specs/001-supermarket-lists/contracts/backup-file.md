# Contract: Arquivo de backup

Interface externa do app: o arquivo que o usuário exporta e importa (FR-031 a FR-033). Ele precisa
continuar importável por versões futuras do app.

## Arquivo

- Nome sugerido: `listas-supermercado-AAAA-MM-DD.json`
- Codificação: UTF-8, JSON
- Tamanho esperado: menos de 1 MB para 50 listas de 100 itens

## Estrutura (versão 1)

```json
{
  "format": "supermarket-list-backup",
  "version": 1,
  "exportedAt": "2026-10-24T18:30:00.000Z",
  "activeListIndex": 0,
  "lists": [
    {
      "name": "Lista semanal",
      "position": 0,
      "items": [
        { "name": "Arroz", "quantity": "5 kg", "position": 0, "checkedSeq": null },
        { "name": "Feijão", "quantity": null, "position": 1, "checkedSeq": 1 }
      ]
    }
  ]
}
```

| Campo | Tipo | Obrigatório | Regra |
|---|---|---|---|
| `format` | string | sim | exatamente `"supermarket-list-backup"` |
| `version` | int | sim | `1` nesta versão do app |
| `exportedAt` | string ISO-8601 UTC | sim | apenas informativo |
| `activeListIndex` | int ou null | sim | índice em `lists`, ou `null` se não houver lista ativa |
| `lists` | array | sim | pode ser vazio |
| `lists[].name` | string | sim | regras de nome de [data-model.md](../data-model.md); `nameKey` único entre as listas |
| `lists[].position` | int ≥ 0 | sim | ordem das listas |
| `lists[].items` | array | sim | pode ser vazio |
| `items[].name` | string | sim | `nameKey` único dentro da lista |
| `items[].quantity` | string ou null | sim | até 40 caracteres |
| `items[].position` | int ≥ 0 | sim | ordem original |
| `items[].checkedSeq` | int ≥ 1 ou null | sim | estado e ordem de compra |

IDs internos do banco **não** são exportados; a importação gera IDs novos.

## Regras de importação

1. Ler o arquivo inteiro e validar **tudo** antes de tocar no banco: JSON válido, `format`
   correto, `version` suportada, todos os campos obrigatórios e tipos, nomes válidos, sem nomes
   repetidos no escopo e `activeListIndex` dentro dos limites.
2. Qualquer falha ⇒ `InvalidBackupException` com uma mensagem amigável; o banco não é alterado
   (FR-033, SC-011).
3. Com o arquivo válido e a confirmação do usuário: **uma única transação** apaga todas as listas e
   itens, insere os dados do arquivo, define `activeListId` e grava
   `lastBackupAt = lastChangeAt = now`. Se algo falhar, a transação é desfeita.
4. `position` e `checkedSeq` são renumerados de forma compacta (0..n-1 e 1..k), mantendo a ordem
   relativa do arquivo.

## Compatibilidade

- `version` maior que a suportada ⇒ rejeitar com "Este backup foi criado por uma versão mais nova
  do app".
- Versões futuras do app MUST continuar importando `version: 1` (caso de borda "backup de versão
  diferente").
- Campos desconhecidos são ignorados.
