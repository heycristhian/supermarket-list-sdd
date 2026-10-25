# Feature Specification: Listas de Supermercado

**Feature Branch**: `001-supermarket-lists` (identificador da feature; sem branch git dedicada)

**Created**: 2026-10-24

**Status**: Draft

**Input**: User description: "Quero um aplicativo de listas de supermercado para uso pessoal no meu
celular, principalmente dentro do mercado durante as compras. Neste primeiro momento, só eu vou
usar, e o app precisa funcionar totalmente sem internet; os dados não podem se perder ao fechar o
app. Listas: criar quantas quiser com nome; editar (renomear), apagar e copiar; ao copiar, pedir
título; a cópia leva todos os itens, desmarcados. Lista ativa: apenas uma por vez; fica no topo e
destacada; as não ativas ficam abaixo e podem ser reordenadas arrastando. Itens: nome obrigatório e
quantidade opcional em texto livre; editar, apagar e reordenar arrastando. Compras: marcar item
como comprado o envia ao final da lista com visual diferente; desmarcar devolve à posição anterior;
opção de desmarcar todos, voltando à ordem original."

## Clarifications

### Session 2026-10-24

- Q: Nomes repetidos são permitidos? → A: Não. Nomes de lista são únicos entre todas as listas, e
  nomes de item são únicos dentro de cada lista; o mesmo item pode existir em listas diferentes.
- Q: O que aparece ao abrir o app? → A: Os itens da lista ativa. Sem lista ativa, a tela de
  listas. Uma splash screen animada e breve é exibida na abertura (prioridade baixa).
- Q: Deve haver backup das listas? → A: Sim. Exportar todas as listas para um arquivo e importá-lo
  depois (a importação substitui os dados atuais, com confirmação), mais um lembrete periódico
  para fazer o backup.
- Q: Como marcar, editar e arrastar um item, se o toque simples marca? → A: Tocar no item
  marca/desmarca; uma alça lateral é a única área de arraste; um botão de menu abre editar e
  apagar. O mesmo padrão vale para as listas (tocar abre a lista).
- Q: Após adicionar um item, o campo continua pronto para o próximo? → A: Sim. Campo fixo no
  rodapé da lista (nome + quantidade) que limpa e continua pronto após cada item; fecha ao tocar
  fora.
- Q: Nomes muito longos são aceitos? → A: Até 80 caracteres para nomes de lista e item e até 40
  para quantidade; acima disso o texto é rejeitado com mensagem (decisão de 2026-10-24, após a
  análise de consistência).
- Q: Após restaurar um backup, o lembrete de backup deve aparecer? → A: Não. Os dados restaurados
  equivalem a um backup recém-feito, então o lembrete volta a contar 7 dias a partir da
  importação.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Montar uma lista e usá-la no mercado (Priority: P1)

O usuário cria uma lista com um nome (ex.: "Lista semanal"), adiciona itens com nome e, se quiser,
uma quantidade em texto livre (ex.: "2 kg"). No mercado, abre a lista e toca em cada item para
marcá-lo como comprado: o item vai para o final da lista e passa a ter aparência diferente. Se
marcou por engano, desmarca o item e ele volta para onde estava. Tudo funciona sem internet e nada
se perde ao fechar o app.

**Why this priority**: é o núcleo do produto. Sozinha, esta jornada já substitui a lista de papel
e entrega o valor principal: saber o que falta comprar enquanto se anda pelo mercado.

**Independent Test**: criar uma lista, adicionar 5 itens, marcar 2, desmarcar 1, fechar e reabrir
o app em modo avião e confirmar que a lista, os itens, as quantidades e o estado de cada item
foram preservados.

**Acceptance Scenarios**:

1. **Given** não há nenhuma lista, **When** o usuário cria a lista "Lista semanal", **Then** a
   lista aparece com esse nome e sem itens.
2. **Given** a lista "Lista semanal" está aberta, **When** o usuário adiciona o item "Arroz" com
   quantidade "5 kg", **Then** o item aparece na lista exibindo nome e quantidade.
3. **Given** a lista está aberta, **When** o usuário tenta adicionar um item com o nome vazio ou
   só com espaços, **Then** o item não é criado e o usuário é informado de que o nome é
   obrigatório.
4. **Given** a lista tem os itens A, B, C e D, nenhum comprado, **When** o usuário marca B,
   **Then** a ordem passa a ser A, C, D, B e B fica visualmente diferente dos demais.
5. **Given** a ordem é A, C, D, B com B comprado, **When** o usuário marca A, **Then** a ordem
   passa a ser C, D, B, A (o item marcado por último fica no final).
6. **Given** a ordem é C, D, B, A com B e A comprados, **When** o usuário desmarca B, **Then** B
   volta à sua posição original entre os não comprados: B, C, D, A.
7. **Given** a lista tem itens e alguns estão comprados, **When** o usuário fecha o app e o abre
   de novo sem conexão com a internet, **Then** todos os itens, quantidades, estados e a ordem
   estão exatamente como antes.
8. **Given** a lista já tem o item "Arroz", **When** o usuário tenta adicionar "arroz" ou
   " Arroz ", **Then** o item não é criado e o usuário é informado de que ele já está na lista.
9. **Given** existe a lista "Lista semanal", **When** o usuário tenta criar outra lista chamada
   "lista semanal", **Then** a lista não é criada e o usuário é informado de que o nome já existe.
10. **Given** "Arroz" está na lista "Lista semanal", **When** o usuário adiciona "Arroz" à
    "Lista Pizza", **Then** o item é criado normalmente.
11. **Given** existe uma lista ativa, **When** o usuário abre o app, **Then** os itens da lista
    ativa são exibidos diretamente, e ele pode navegar para a tela de listas.
12. **Given** não existe lista ativa, **When** o usuário abre o app, **Then** a tela de listas é
    exibida.
13. **Given** o usuário acabou de adicionar "Arroz" pelo campo do rodapé, **When** o item aparece
    na lista, **Then** o campo está vazio e pronto para digitar o próximo item, sem novos toques.

---

### User Story 2 - Manter os itens da lista (Priority: P2)

O usuário corrige o nome ou a quantidade de um item, apaga itens que não quer mais e reorganiza a
ordem dos itens arrastando-os com o dedo, por exemplo para seguir o caminho que faz no mercado.

**Why this priority**: listas mudam com frequência; sem edição e reordenação o usuário teria de
apagar e recriar itens, o que torna o app pouco prático no dia a dia.

**Independent Test**: em uma lista com itens, renomear um item, alterar e depois apagar a
quantidade de outro, apagar um terceiro e arrastar um quarto para outra posição; fechar e reabrir
o app e confirmar que tudo foi preservado.

**Acceptance Scenarios**:

1. **Given** o item "Arroz – 5 kg", **When** o usuário o edita para "Arroz integral – 2 kg",
   **Then** o item passa a exibir os novos valores na mesma posição.
2. **Given** um item com quantidade, **When** o usuário apaga a quantidade e salva, **Then** o
   item passa a exibir apenas o nome.
3. **Given** um item existente, **When** o usuário tenta salvar a edição com o nome vazio ou com o
   nome de outro item da mesma lista, **Then** a edição não é aceita, o motivo é informado e o
   nome anterior é mantido.
4. **Given** um item, **When** o usuário o apaga, **Then** o item some da lista e é oferecida a
   opção de desfazer por alguns segundos.
5. **Given** os itens não comprados A, B, C, **When** o usuário arrasta C pela alça para antes
   de A, **Then** a ordem passa a ser C, A, B e essa passa a ser a ordem original da lista.
6. **Given** um item não comprado, **When** o usuário toca no botão de menu do item, **Then** são
   oferecidas as opções editar e apagar, e o item não é marcado.
7. **Given** a lista está aberta, **When** o usuário rola a tela passando o dedo sobre os itens,
   **Then** nenhum item é movido nem marcado.

---

### User Story 3 - Organizar várias listas e a lista ativa (Priority: P3)

O usuário mantém várias listas (ex.: "Lista semanal", "Lista Hambúrguer", "Lista Pizza"). Ele
escolhe qual é a lista ativa, a que está usando no momento: ela aparece sempre no topo e com
destaque. As demais aparecem abaixo, na ordem que o usuário definir arrastando-as com o dedo. O
usuário também pode renomear e apagar listas.

**Why this priority**: amplia o app de uma lista para várias; útil, mas o valor central já existe
com uma única lista.

**Independent Test**: criar três listas, ativar a segunda, reordenar as não ativas, ativar a
terceira, renomear uma e apagar outra; fechar e reabrir o app e confirmar a lista ativa, a ordem
e os nomes.

**Acceptance Scenarios**:

1. **Given** existem as listas X, Y e Z e nenhuma está ativa, **When** o usuário ativa Y,
   **Then** Y aparece no topo com destaque e X e Z aparecem abaixo.
2. **Given** Y está ativa, **When** o usuário ativa Z, **Then** Z passa a ser a única ativa, fica
   no topo com destaque, e Y volta a ser uma lista comum na sua posição anterior entre as não
   ativas.
3. **Given** as listas não ativas X, Y, W, **When** o usuário arrasta W para antes de X,
   **Then** a ordem passa a ser W, X, Y e é preservada ao reabrir o app.
4. **Given** uma lista "Lista Pizza", **When** o usuário a renomeia para "Pizza de sexta",
   **Then** o novo nome aparece no mesmo lugar; renomear para o nome de outra lista existente não
   é aceito.
5. **Given** uma lista com itens, **When** o usuário pede para apagá-la, **Then** o app pede
   confirmação e, se confirmado, a lista e todos os seus itens são removidos.
6. **Given** a lista ativa, **When** o usuário a apaga, **Then** nenhuma lista fica ativa até o
   usuário ativar outra.

---

### User Story 4 - Reutilizar listas (Priority: P4)

Depois das compras, o usuário desmarca todos os itens de uma vez para usar a mesma lista na semana
seguinte, com os itens voltando à ordem original. Ele também pode copiar uma lista existente como
ponto de partida para outra (ex.: copiar "Lista Hambúrguer" como "Hambúrguer do aniversário"); o
app pede o título da nova lista antes de criá-la.

**Why this priority**: economiza tempo em compras recorrentes, mas depende das jornadas
anteriores para ter valor.

**Independent Test**: em uma lista com metade dos itens comprados, usar "desmarcar todos" e
confirmar que todos estão desmarcados e na ordem original; copiar a lista com um novo título e
confirmar que a cópia tem os mesmos itens, desmarcados, e que a original não mudou.

**Acceptance Scenarios**:

1. **Given** a lista com ordem original A, B, C, D e B e D comprados, **When** o usuário usa
   "desmarcar todos" e confirma, **Then** nenhum item fica comprado e a ordem volta a ser
   A, B, C, D.
2. **Given** a lista "Lista Hambúrguer" com itens, alguns comprados, **When** o usuário escolhe
   copiar, **Then** o app pede um título, já sugerindo "Lista Hambúrguer (cópia)" (ou
   "Lista Hambúrguer (cópia 2)", "(cópia 3)"... se o nome sugerido já existir).
3. **Given** o pedido de título da cópia, **When** o usuário informa "Hambúrguer do aniversário"
   e confirma, **Then** uma nova lista é criada com esse nome, com todos os itens e quantidades
   da original na ordem original, todos desmarcados.
4. **Given** o pedido de título da cópia, **When** o usuário cancela, deixa o título vazio ou
   informa o nome de uma lista existente, **Then** nenhuma lista é criada (nos dois últimos casos,
   o motivo é informado e o usuário pode corrigir o título).
5. **Given** uma cópia recém-criada, **When** o usuário altera os itens da cópia, **Then** a lista
   original permanece inalterada (e vice-versa).

---

### User Story 5 - Fazer e restaurar backup das listas (Priority: P5)

O usuário exporta todas as suas listas para um arquivo no celular (ou o envia para onde quiser) e,
mais tarde, importa esse arquivo, por exemplo em um celular novo. Como os dados ficam só no
aparelho, o app lembra o usuário de tempos em tempos de fazer o backup.

**Why this priority**: protege contra perda total de dados (desinstalar o app, limpar dados, trocar
de celular), mas o uso diário do app não depende disso.

**Independent Test**: criar listas com itens, alguns comprados e uma lista ativa; exportar; apagar
tudo; importar o arquivo e confirmar que listas, itens, quantidades, estados, ordens e lista ativa
voltaram exatamente como estavam. Avançar o relógio 7 dias após uma alteração e confirmar que o
lembrete aparece.

**Acceptance Scenarios**:

1. **Given** existem listas e itens, **When** o usuário escolhe exportar, **Then** é gerado um
   arquivo com todas as listas, itens e estados, sem precisar de internet.
2. **Given** um arquivo de backup válido, **When** o usuário escolhe importá-lo, **Then** o app
   avisa que os dados atuais serão substituídos e pede confirmação.
3. **Given** a confirmação da importação, **When** o usuário confirma, **Then** todos os dados
   atuais são substituídos pelos do arquivo, incluindo a lista ativa, a ordem das listas e dos
   itens e o estado de comprado.
4. **Given** um arquivo inválido, corrompido ou que não é um backup do app, **When** o usuário
   tenta importá-lo, **Then** o app informa o erro e os dados atuais permanecem intactos.
5. **Given** houve alterações e o último backup foi há 7 dias ou mais (ou nunca foi feito),
   **When** o usuário abre o app, **Then** um lembrete discreto oferece fazer o backup, sem
   bloquear o uso.
6. **Given** o lembrete está visível, **When** o usuário o dispensa, **Then** ele não reaparece
   até se passarem mais 7 dias.
7. **Given** um celular novo sem dados, **When** o usuário importa um backup, **Then** o lembrete
   de backup não aparece até se passarem 7 dias com alterações.

---

### User Story 6 - Splash screen animada na abertura (Priority: P6)

Ao abrir o app, o usuário vê por um instante uma splash screen animada com a identidade do app,
que logo dá lugar à tela inicial (os itens da lista ativa, ou a tela de listas).

**Why this priority**: é um acabamento visual que reforça o "visual modernizado"; não muda o que o
usuário consegue fazer e pode ser cortado sem prejuízo às demais histórias.

**Independent Test**: abrir o app do zero e cronometrar o tempo até a tela inicial ficar
utilizável; repetir com a preferência de "reduzir movimento" ativada no celular.

**Acceptance Scenarios**:

1. **Given** o app está fechado, **When** o usuário o abre, **Then** uma splash screen animada é
   exibida e a tela inicial fica utilizável em no máximo 1,5 segundo.
2. **Given** o celular está com "reduzir movimento" ativado, **When** o usuário abre o app,
   **Then** a splash é exibida sem animação (ou com animação mínima), no mesmo tempo máximo.
3. **Given** o app já está aberto em segundo plano, **When** o usuário volta para ele, **Then** a
   splash não é exibida novamente.

---

### Edge Cases

- **Nomes repetidos**: nomes de lista não se repetem entre listas, e nomes de item não se repetem
  dentro de uma mesma lista. A comparação ignora maiúsculas/minúsculas e espaços no início, no fim
  e repetidos no meio ("Arroz", "arroz" e " Arroz  " são o mesmo nome); acentos contam ("Feijão" e
  "Feijao" são nomes diferentes).
- **Mesmo item em listas diferentes**: permitido ("Arroz" pode estar em várias listas).
- **Renomear para o próprio nome**: salvar um item ou lista apenas mudando maiúsculas/minúsculas
  (ex.: "arroz" → "Arroz") é aceito, pois não conflita com outro registro.
- **Nomes com espaços**: espaços no início e no fim de nomes e quantidades são descartados; um nome
  que fica vazio após isso é rejeitado.
- **Nomes longos**: nomes de lista e de item aceitam até 80 caracteres e quantidades até 40
  (contados após descartar os espaços das pontas); acima disso o texto é rejeitado com uma
  mensagem clara e o texto digitado é mantido para correção. Nomes no limite são exibidos sem
  quebrar o layout (quebrando linha ou truncando com indicação visual).
- **Lista vazia**: uma lista sem itens mostra um estado vazio que convida a adicionar o primeiro
  item; "desmarcar todos" fica indisponível quando não há itens comprados.
- **Nenhuma lista**: no primeiro uso, o app mostra um estado vazio que convida a criar a primeira
  lista.
- **Todos comprados**: quando todos os itens estão comprados, o app deixa claro que a lista foi
  concluída.
- **Novo item com itens comprados**: um item adicionado entra no final dos itens não comprados,
  antes dos comprados.
- **Reordenar itens comprados**: apenas os itens não comprados podem ser reordenados; itens
  comprados ficam no final, na ordem em que foram marcados.
- **Item apagado e "desmarcar todos"**: itens apagados não reaparecem; os restantes voltam à
  ordem original relativa entre si.
- **Arrasto acidental**: soltar um item ou lista no mesmo lugar não altera nada; arrastar fora da
  alça (por exemplo, rolar a tela passando o dedo sobre um item) não move o item nem o marca.
- **Toque na alça ou no menu**: tocar na alça ou no botão de menu não marca nem desmarca o item.
- **Fechamento abrupto**: se o app for fechado ou o celular desligar logo após uma ação, a ação
  já confirmada na tela não pode ser perdida.
- **Importação interrompida**: se a importação falhar no meio (arquivo inválido, app fechado), os
  dados anteriores permanecem intactos; nunca fica um estado misturado.
- **Backup de versão diferente**: um arquivo gerado por uma versão mais antiga do app é
  importado normalmente; um arquivo que o app não reconhece é rejeitado com mensagem clara.
- **Backup sem listas**: exportar sem nenhuma lista é permitido e gera um backup vazio; importá-lo
  (após confirmação) deixa o app sem listas.
- **Lembrete sem alterações**: se nada mudou desde o último backup, o lembrete não aparece.

## Requirements *(mandatory)*

### Functional Requirements

**Listas**

- **FR-001**: Usuários MUST poder criar quantas listas quiserem, informando um nome obrigatório,
  com até 80 caracteres e único entre todas as listas.
- **FR-002**: Usuários MUST poder renomear uma lista; o nome continua obrigatório, com até 80
  caracteres e único.
- **FR-003**: Usuários MUST poder apagar uma lista, mediante confirmação; apagar uma lista remove
  todos os seus itens.
- **FR-004**: Usuários MUST poder copiar uma lista; o app MUST pedir o título da nova lista antes
  de criá-la, sugerindo "<nome original> (cópia)" ou, se já existir, o próximo nome livre
  "<nome original> (cópia N)".
- **FR-005**: A cópia MUST conter todos os itens da original, com nomes, quantidades e ordem
  original, todos desmarcados; a cópia e a original MUST ser independentes entre si.
- **FR-006**: Cancelar a cópia ou confirmar com título vazio ou já existente MUST NOT criar
  nenhuma lista.

**Lista ativa**

- **FR-007**: No máximo uma lista MUST estar ativa por vez; ativar uma lista MUST desativar a
  anterior automaticamente.
- **FR-008**: A lista ativa MUST aparecer sempre no topo da tela de listas, com destaque visual
  inequívoco.
- **FR-009**: As listas não ativas MUST aparecer abaixo da ativa, na ordem definida pelo usuário.
- **FR-010**: Usuários MUST poder reordenar as listas não ativas arrastando-as pela alça de
  arraste. Na tela de listas, tocar em uma lista MUST abri-la, e o botão de menu de cada lista
  MUST oferecer ativar, renomear, copiar e apagar.
- **FR-011**: Quando uma lista deixa de ser ativa, ela MUST voltar à sua posição anterior na ordem
  das listas não ativas.
- **FR-012**: Ao abrir o app, MUST ser exibida diretamente a tela de itens da lista ativa; se não
  houver lista ativa, MUST ser exibida a tela de listas. A tela de listas MUST ser acessível a
  partir da tela de itens com um toque.

**Itens**

- **FR-013**: Usuários MUST poder adicionar itens a qualquer lista, com nome obrigatório (até 80
  caracteres) e único dentro da lista, e quantidade opcional em texto livre (até 40 caracteres).
- **FR-013a**: A tela da lista MUST ter um campo de adição fixo no rodapé, com nome e quantidade.
  Após adicionar um item, o campo MUST ser limpo e continuar pronto para digitar o próximo item,
  sem toques extras; ele MUST deixar de ter o foco ao tocar fora dele. Se o item for rejeitado
  (nome vazio ou repetido), o texto digitado MUST permanecer no campo.
- **FR-014**: Usuários MUST poder editar o nome e a quantidade de um item, inclusive removendo a
  quantidade; o nome continua obrigatório e único dentro da lista.
- **FR-015**: Usuários MUST poder apagar um item, com opção de desfazer disponível por alguns
  segundos após a remoção.
- **FR-016**: Usuários MUST poder reordenar os itens não comprados arrastando-os pela alça de
  arraste; a nova ordem passa a ser a ordem original da lista. Itens comprados MUST NOT exibir a
  alça.
- **FR-016a**: Cada item MUST ter três áreas de interação distintas: a área principal (toque
  marca/desmarca), a alça de arraste (única forma de iniciar o arraste) e o botão de menu (abre
  editar e apagar). Uma interação em uma área MUST NOT disparar a ação de outra.
- **FR-017**: Itens novos MUST entrar no final dos itens não comprados.

**Compras**

- **FR-018**: Usuários MUST poder marcar um item como comprado com um único toque na área
  principal do item.
- **FR-019**: Um item marcado MUST ir para o final da lista e MUST ter aparência visualmente
  diferente dos não comprados; itens comprados ficam na ordem em que foram marcados.
- **FR-020**: Usuários MUST poder desmarcar um item comprado individualmente; ao ser desmarcado, o
  item MUST voltar à sua posição na ordem original, entre os itens não comprados.
- **FR-021**: Usuários MUST poder desmarcar todos os itens de uma lista de uma vez, mediante
  confirmação; todos os itens MUST voltar à ordem original.
- **FR-022**: O app MUST indicar o progresso da lista (quantos itens comprados do total) e
  sinalizar quando todos estiverem comprados.

**Unicidade de nomes**

- **FR-027**: Dois nomes MUST ser considerados iguais quando coincidem após ignorar maiúsculas e
  minúsculas e normalizar espaços (remover os das pontas e reduzir repetidos a um); acentos MUST
  ser considerados.
- **FR-028**: Ao rejeitar um nome repetido, o app MUST informar o motivo e manter o texto digitado
  para que o usuário possa corrigi-lo.

**Backup**

- **FR-031**: Usuários MUST poder exportar todas as listas, itens, quantidades, estados de
  comprado, ordens e a lista ativa para um único arquivo, sem conexão com a internet.
- **FR-032**: Usuários MUST poder importar um arquivo de backup; a importação MUST substituir
  todos os dados atuais, somente após confirmação explícita.
- **FR-033**: A importação MUST ser tudo-ou-nada: se o arquivo for inválido ou a importação falhar,
  os dados atuais MUST permanecer intactos e o motivo MUST ser informado.
- **FR-034**: O app MUST exibir, ao ser aberto, um lembrete não modal (uma faixa que não cobre a
  lista nem exige resposta) e dispensável para fazer
  backup quando houver alterações desde o último backup e ele tiver sido feito há 7 dias ou mais
  (ou nunca); dispensar o lembrete o adia por mais 7 dias.
- **FR-035**: O lembrete MUST NOT bloquear o uso do app nem atrasar a exibição da tela inicial.

**Abertura do app**

- **FR-029**: Ao abrir o app do zero, MUST ser exibida uma splash screen animada e breve; a tela
  inicial MUST ficar utilizável em no máximo 1,5 segundo após a abertura.
- **FR-030**: A splash MUST respeitar a preferência de "reduzir movimento" do aparelho e MUST NOT
  ser exibida ao retornar ao app que já estava aberto em segundo plano.

**Dados, uso offline e acessibilidade**

- **FR-023**: Todas as funcionalidades MUST funcionar sem conexão com a internet.
- **FR-024**: Toda alteração MUST ser salva automaticamente no próprio aparelho, sem ação explícita
  de "salvar", e MUST ser preservada ao fechar e reabrir o app ou reiniciar o celular.
- **FR-025**: Toda reordenação feita por arrasto MUST ter também uma alternativa sem arrasto (por
  exemplo, mover para cima ou para baixo), para uso por teclado e tecnologias assistivas.
- **FR-026**: A interface MUST ser operável com uma mão em telas de celular a partir de 360px de
  largura, com áreas de toque de no mínimo 48 × 48 pontos (≈ 9 mm) para todas as ações e de no
  mínimo 64 pontos de altura para a linha de cada item.

### Key Entities

- **Lista de compras**: um conjunto nomeado de itens. Atributos: nome (único entre as listas),
  posição na ordem definida pelo usuário, se é a lista ativa. Contém zero ou mais itens.
- **Item**: algo a comprar, pertencente a exatamente uma lista. Atributos: nome (único na lista), quantidade
  opcional (texto livre), posição na ordem original da lista, se está comprado e, quando
  comprado, a ordem em que foi marcado (para posicioná-lo entre os comprados).
- **Backup**: um arquivo com a cópia completa de todas as listas e itens em um momento. O app
  também guarda a data do último backup, se houve alterações depois dele e até quando o lembrete
  foi adiado.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O usuário adiciona um item a uma lista aberta em até 5 segundos, sem sair da tela da
  lista, e adiciona 10 itens seguidos em até 60 segundos.
- **SC-002**: Marcar ou desmarcar um item exige um único toque e o resultado aparece na tela
  em menos de 0,5 segundo.
- **SC-003**: 100% das funcionalidades estão disponíveis com o celular em modo avião.
- **SC-004**: 0 perdas de dados em 20 ciclos seguidos de "alterar → fechar o app à força →
  reabrir".
- **SC-005**: Com 50 listas de 100 itens cada, abrir o app, abrir uma lista, marcar um item e
  reordenar levam menos de 1 segundo cada para refletir na tela.
- **SC-006**: Após usar "desmarcar todos", 100% dos itens restantes estão desmarcados e na ordem
  original.
- **SC-007**: O usuário consegue fazer uma compra completa (abrir a lista ativa e marcar todos os
  itens) usando apenas uma mão.
- **SC-008**: Com uma lista ativa, o usuário vê os itens dela em no máximo 1,5 segundo após tocar
  no ícone do app, sem nenhum toque adicional.
- **SC-009**: 0 listas com nome repetido e 0 itens com nome repetido dentro da mesma lista, em
  qualquer combinação de criar, renomear e copiar.
- **SC-010**: Exportar e importar o backup em outro aparelho restaura 100% das listas, itens,
  estados e ordens; exportar ou importar leva menos de 5 segundos com 50 listas de 100 itens.
- **SC-011**: Uma importação com arquivo inválido deixa 100% dos dados atuais intactos.

## Assumptions

- **Usuário único**: não há contas, login, compartilhamento nem sincronização entre aparelhos nesta
  versão.
- **Armazenamento só local**: os dados ficam apenas no aparelho; não há nuvem nem sincronização
  automática. Desinstalar o app ou limpar os dados dele apaga as listas; a proteção contra isso é
  o backup manual em arquivo (User Story 5), que o usuário guarda onde quiser.
- **Importação substitui**: não há mesclagem de dados na importação nesta versão.
- **Lembrete de backup**: intervalo fixo de 7 dias, não configurável nesta versão.
- **Primeira lista**: quando ainda não existe lista ativa, a primeira lista criada se torna ativa
  automaticamente; depois disso, a ativação é sempre uma escolha do usuário.
- **Lista ativa é opcional**: pode não haver nenhuma lista ativa (por exemplo, após apagar a
  ativa).
- **Marcar em qualquer lista**: itens podem ser marcados em qualquer lista, não só na ativa; ser
  ativa define o destaque e a posição no topo.
- **Novas listas**: entram no final da ordem das listas não ativas (exceto a primeira, que se torna
  ativa).
- **Quantidade não calculada**: a quantidade é apenas um texto exibido; o app não soma, converte
  nem valida unidades.
- **Sem categorias, preços ou busca** nesta versão.
- **Splash**: a splash é um acabamento de baixa prioridade (P6); se conflitar com o tempo de
  abertura ou com a simplicidade, ela é reduzida ou removida, nunca o contrário.
- **Idioma**: interface em português do Brasil.
- **Confirmações**: pedem confirmação apenas ações destrutivas em massa (apagar lista, desmarcar
  todos); apagar um item usa "desfazer" para não interromper o uso no mercado.
