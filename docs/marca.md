# Identidade visual — T_YOU

Fonte original: `docs/manual-da-marca.pdf`. Em caso de dúvida, o PDF prevalece.

## Cores oficiais

| Nº | Nome (Pantone)        | Hex       | RGB           | Uso sugerido no app                          |
|----|-----------------------|-----------|---------------|----------------------------------------------|
| 01 | PANTONE 7540 C        | `#4C4E53` | 76, 78, 83    | Cinza escuro: texto principal, barras, fundo escuro |
| 02 | PANTONE Cool Gray 9 C | `#767678` | 118, 118, 120 | Cinza médio: texto secundário, ícones, itens comprados |
| 03 | PANTONE 7710 C        | `#00A5B4` | 0, 165, 180   | Azul-turquesa: cor de destaque (botões, lista ativa, seleção) |
| 04 | PANTONE Trans White   | `#FEFEFE` | 254, 254, 254 | Branco: fundo de cards e texto sobre fundo escuro |

### Cor de apoio (observada no manual, não listada como oficial)

| Nome         | Hex aproximado | Uso                                  |
|--------------|----------------|--------------------------------------|
| Cinza claro  | `#E6E7E8`      | Fundo geral em telas claras          |

> Confirmar este tom com quem fez o manual antes de usar como padrão.

### Regras de cor percebidas nas aplicações
- O turquesa (`#00A5B4`) é usado com moderação, como acento: no traço do logo, em linhas finas e em palavras de destaque. Não usar como fundo de áreas grandes.
- Combinações principais: elementos brancos sobre cinza escuro (`#4C4E53`) ou elementos cinza (`#767678`) sobre cinza claro/branco.

## Tipografia

| Papel          | Fonte        | Características                                      |
|----------------|--------------|------------------------------------------------------|
| Títulos        | Tactic Sans  | Sans-serif larga e geométrica; usada em títulos curtos e números de destaque |
| Texto corrido  | Neue Plak    | Sans-serif de leitura; usada em parágrafos, rótulos e textos de interface |

- Os números e símbolos de destaque (`0123456789`, `#$%&`) aparecem em Tactic Sans, às vezes em turquesa.
- Nas aplicações, textos de apoio aparecem em caixa alta com espaçamento largo (ex.: "SOLUÇÕES TECNOLÓGICAS").

> **Licença:** Tactic Sans e Neue Plak são fontes comerciais. Para embutir no app é preciso ter os arquivos (`.ttf`/`.otf`) com licença que permita uso em aplicativo (app/embedding). Colocar os arquivos em `assets/fonts/`.
>
> **Se não houver licença para app**, usar alternativas gratuitas parecidas (Google Fonts):
> - Títulos: **Michroma** ou **Orbitron** (larga, geométrica) no lugar de Tactic Sans
> - Texto: **Inter** no lugar de Neue Plak

## Logo

- Nome: **T_YOU®**, com o traço "_" sempre em turquesa (`#00A5B4`).
- Versão clara: letras brancas sobre fundo cinza escuro.
- Versão escura: letras cinza (`#767678`) sobre fundo claro.
- Pode aparecer na horizontal ou na vertical.
- Assinatura opcional: "SOLUÇÕES TECNOLÓGICAS", separada do logo por uma barra vertical fina.
- Arquivo do logo para o app: `assets/images/logo.png` (ou `.svg`) — exportar do material original, não recriar.

## Elementos gráficos

- Linhas finas retas em turquesa como divisores e detalhes.
- Fundos com gradientes suaves de cinza e turquesa (usados em fundos de tela e publicidade).
- Visual limpo, com bastante espaço vazio e poucos elementos por tela.

## Aplicação no app (tema)

- Tema claro como padrão: fundo `#E6E7E8` ou `#FEFEFE`, texto `#4C4E53`, destaque `#00A5B4`.
- Tema escuro (opcional): fundo `#4C4E53`, texto `#FEFEFE`, destaque `#00A5B4`.
- Itens marcados como "comprado": texto em `#767678`, com riscado.
- Lista ativa: borda ou barra lateral fina em `#00A5B4`.
