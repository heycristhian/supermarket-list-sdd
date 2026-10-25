<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0 (MINOR: novo princípio + orientação materialmente expandida)
- Modified principles:
  - V. Visual Moderno e Acessível: tokens passam a ser regidos pelo Princípio VI; fontes
    deixam de ser "preferencialmente nativas" e passam a seguir a marca
- Added sections:
  - Princípio VI. Identidade Visual T_YOU e Tema Central
  - Quality gate 5: verificação de valores visuais literais fora do tema
- Removed sections: nenhuma
- Templates: não modificados (lêem a constituição em tempo de execução)
- Artefatos impactados (a atualizar fora deste comando):
  - specs/001-supermarket-lists/plan.md e research.md (R14: tema, fontes, logo)
  - specs/001-supermarket-lists/tasks.md (T005 fontes, T018 tema, T060/T061 logo e ícones)
- Deferred TODOs: nenhum (resolvidos em 2026-10-24)
  - BRAND_LIGHT_GRAY: #E6E7E8 confirmado no vetor do manual (pág. 17)
  - BRAND_FONTS_LICENSE: sem licença de app ⇒ Michroma + Inter
  - BRAND_LOGO_ASSET: logo e ícones em assets/images/
-->


# Supermarket List Constitution

## Core Principles

### I. Simplicidade Primeiro

- Toda solução MUST começar pela forma mais simples que atende à spec (YAGNI).
- Abstrações, camadas ou padrões novos MUST ser justificados por uma necessidade presente
  na spec ou no plano, nunca por uma necessidade hipotética futura.
- Funcionalidades fora do escopo da spec ativa MUST NOT ser implementadas.
- Qualquer complexidade adicional MUST ser registrada na seção "Complexity Tracking" do
  `plan.md`, com a alternativa mais simples que foi rejeitada e o motivo.

**Rationale**: um app de lista de compras é pequeno; complexidade desnecessária custa mais
em manutenção do que entrega em valor.

### II. Testes Automatizados (INEGOCIÁVEL)

- Toda regra de negócio (adicionar, editar, remover, marcar item, agrupar por categoria etc.)
  MUST ter testes automatizados.
- Testes MUST ser escritos antes ou junto da implementação de cada tarefa; uma tarefa só é
  concluída quando seus testes passam.
- Cada cenário de aceitação da spec MUST ser coberto por ao menos um teste.
- A suíte completa MUST rodar com um único comando documentado e MUST passar antes de
  qualquer commit na branch principal.
- Testes MUST ser determinísticos: sem dependência de rede, relógio ou ordem de execução.

**Rationale**: testes são a prova objetiva de que o código atende à spec e permitem
refatorar com segurança.

### III. Código Legível

- Nomes de variáveis, funções e arquivos MUST descrever intenção; abreviações obscuras
  MUST NOT ser usadas.
- Funções SHOULD ter uma única responsabilidade e caber na tela sem rolagem.
- Formatação e lint MUST ser automatizados e aplicados de forma consistente em todo o código.
- Comentários SHOULD explicar o *porquê*, não o *o quê*; código que precisa de comentário
  para ser entendido SHOULD ser simplificado primeiro.
- Código morto e código comentado MUST NOT ser commitados.

**Rationale**: código é lido muito mais vezes do que escrito, inclusive por agentes de IA
que dependem de clareza para trabalhar corretamente.

### IV. Dependências Mínimas

- Recursos nativos da plataforma (linguagem, browser, biblioteca padrão) MUST ser preferidos
  a bibliotecas externas.
- Toda nova dependência de runtime MUST ser justificada no `plan.md`: problema resolvido,
  por que a solução nativa não basta e tamanho/custo de manutenção.
- Dependências que resolvem problemas triviais (poucas linhas de código próprio) MUST NOT
  ser adicionadas.
- Dependências MUST ter versão fixada e MUST ser removidas assim que deixarem de ser usadas.

**Rationale**: cada dependência é superfície de bugs, vulnerabilidades e atualizações;
menos dependências significa um projeto mais leve e duradouro.

### V. Visual Moderno e Acessível

- A interface MUST ser responsiva e mobile-first, utilizável de 360px de largura até desktop,
  sem rolagem horizontal.
- Cores, tipografia, espaçamentos, raios e demais medidas MUST vir do tema central definido
  no Princípio VI.
- A interface MUST suportar tema claro (padrão) e escuro, ambos derivados da identidade visual.
- Contraste de texto MUST atender WCAG 2.1 AA; todas as ações MUST ser operáveis por teclado
  e ter foco visível.
- Ações do usuário MUST ter feedback visual imediato (estados de hover, ativo, vazio,
  carregando e erro), com transições sutis que respeitem `prefers-reduced-motion`.
- O visual moderno MUST ser alcançado com os recursos de estilo nativos da plataforma, sem
  bibliotecas de UI extras, em conformidade com o Princípio IV.

**Rationale**: o app é usado no celular, muitas vezes dentro do mercado; precisa ser
agradável, rápido de operar e acessível a todos.

### VI. Identidade Visual T_YOU e Tema Central

- Toda a interface MUST seguir a identidade visual documentada em `docs/` (`docs/marca.md`,
  derivado do manual de marca em PDF; em caso de divergência, o PDF prevalece).
- Paleta oficial: `#4C4E53` (cinza escuro), `#767678` (cinza médio), `#00A5B4` (turquesa,
  destaque) e `#FEFEFE` (branco); `#E6E7E8` (cinza claro) como cor de apoio. Nenhuma outra
  matiz MUST ser introduzida; variações de tom dessas cores são permitidas somente quando
  exigidas pela acessibilidade e MUST ser definidas e justificadas no tema central.
- O turquesa MUST ser usado com moderação, como acento (botões, seleção, lista ativa, linhas
  finas), e MUST NOT ser usado como fundo de áreas grandes.
- Tipografia: Tactic Sans para títulos e números de destaque, Neue Plak para textos de
  interface, desde que exista licença para uso em app; sem essa licença, MUST ser usadas as
  alternativas definidas em `docs/marca.md` (Michroma para títulos, Inter para texto), embutidas
  como assets do app.
- O logo MUST ser o arquivo exportado do material original da marca, nunca recriado.
- **Tema central**: cores, fontes, tamanhos de fonte, espaçamentos, raios, tamanhos de ícone,
  alturas, larguras, elevações e durações de animação MUST ser definidos exclusivamente no tema
  central (no Flutter, em `lib/ui/theme/`) e consumidos pelas telas via tema/tokens.
- Telas e widgets fora de `lib/ui/theme/` MUST NOT conter valores visuais literais: nenhuma cor
  (`Color(...)`, `Colors.*`, hex), nenhum nome de fonte, nenhum tamanho de fonte e nenhuma medida
  numérica (padding, margem, raio, altura, largura, tamanho de ícone). Exceção: `0` e valores
  derivados do layout em tempo de execução (ex.: largura da tela).
- **Precedência**: quando uma regra de cor da marca conflitar com o contraste WCAG 2.1 AA do
  Princípio V, a acessibilidade prevalece; o tema MUST resolver o conflito (ex.: turquesa em
  elementos que não são texto, com o estado também indicado por texto ou ícone) e documentar a
  decisão junto ao token.

**Rationale**: o app carrega a marca T_YOU; centralizar o visual garante consistência entre
telas, permite ajustar a marca em um único lugar e torna a regra verificável automaticamente.

## Restrições Técnicas

- A stack é definida no `plan.md` de cada feature e MUST respeitar os Princípios I e IV.
- O app SHOULD funcionar sem backend obrigatório enquanto nenhuma spec exigir
  sincronização ou múltiplos usuários.
- Dados do usuário MUST NOT ser perdidos em recarregamentos de página.
- Segredos e credenciais MUST NOT ser commitados no repositório.

## Fluxo de Desenvolvimento e Quality Gates

- Toda feature MUST seguir o fluxo Spec Kit: `/speckit-specify` → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement` → `/speckit-converge`; `/speckit-clarify` e
  `/speckit-analyze` SHOULD ser usados quando a spec tiver ambiguidades.
- O `plan.md` MUST conter o "Constitution Check" e só avança se todos os princípios forem
  atendidos ou as exceções estiverem justificadas.
- Quality gates antes de considerar uma feature concluída:
  1. Suíte de testes passando.
  2. Lint e formatação sem erros.
  3. `/speckit-converge` reportando `Converged`.
  4. Verificação manual da interface em largura mobile e desktop, nos temas claro e escuro.
  5. Verificação automatizada (teste ou script) de que não há valores visuais literais fora
     de `lib/ui/theme/`, conforme o Princípio VI.
- Commits SHOULD ser pequenos e descrever a mudança de forma clara.

## Governance

- Esta constituição prevalece sobre qualquer outra prática ou preferência do projeto.
- Emendas MUST ser feitas via `/speckit-constitution`, com Sync Impact Report e incremento
  de versão semântico:
  - MAJOR: remoção ou redefinição incompatível de princípio.
  - MINOR: princípio ou seção nova, ou expansão material de orientação.
  - PATCH: esclarecimentos e correções de redação.
- Toda spec, plano e revisão de código MUST verificar conformidade com os princípios;
  violações MUST ser corrigidas ou justificadas explicitamente no `plan.md`.
- Orientações operacionais do dia a dia (comandos, convenções) SHOULD ficar no `CLAUDE.md`
  do projeto, que MUST NOT contradizer esta constituição.

**Version**: 1.1.0 | **Ratified**: 2026-10-24 | **Last Amended**: 2026-10-24
