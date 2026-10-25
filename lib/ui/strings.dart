/// Textos da interface em pt-BR (idioma único; sem pacote de i18n).
abstract final class Strings {
  static const appTitle = 'Listas de Supermercado';

  // Listas.
  static const listsTitle = 'Minhas listas';
  static const activeBadge = 'ATIVA';
  static const otherListsSection = 'OUTRAS LISTAS';
  static const newList = 'Nova lista';
  static const newListTitle = 'Nova lista';
  static const listNameLabel = 'Nome da lista';
  static const noListsTitle = 'Crie sua primeira lista';
  static const noListsBody =
      'Monte a lista em casa e marque os itens enquanto compra.';
  static const openLists = 'Ver todas as listas';
  static const listMenu = 'Mais opções da lista';
  static const activate = 'Ativar';
  static const rename = 'Renomear';
  static const renameListTitle = 'Renomear lista';
  static const deleteListTitle = 'Apagar lista?';
  static const copy = 'Copiar';
  static const copyListTitle = 'Copiar lista';

  static String deleteListMessage(String name) =>
      'A lista "$name" e todos os seus itens serão apagados.';

  // Itens.
  static const itemNameLabel = 'Item';
  static const itemNameHint = 'Ex.: Arroz';
  static const quantityLabel = 'Qtd.';
  static const quantityHint = 'Ex.: 2 kg';
  static const addItem = 'Adicionar item';
  static const emptyListTitle = 'Lista vazia';
  static const emptyListBody = 'Adicione o primeiro item no campo abaixo.';
  static const listComplete = 'Lista concluída!';
  static const checked = 'comprado';
  static const notChecked = 'não comprado';
  static const editItemTitle = 'Editar item';
  static const uncheckAll = 'Desmarcar todos';
  static const uncheckAllTitle = 'Desmarcar todos os itens?';
  static const uncheckAllMessage =
      'Todos os itens voltam a ficar sem marcação, na ordem original.';
  static const uncheckAllConfirm = 'Desmarcar';
  static const reorderHandle = 'Arrastar para reordenar';
  static const itemMenu = 'Mais opções do item';

  static String itemDeleted(String name) => '"$name" apagado';

  static String progress(int checked, int total) => '$checked de $total';

  /// Rótulo de acessibilidade de um item: "Arroz, 5 kg, comprado".
  static String itemSemantics(String name, String? quantity, bool isChecked) =>
      [name, ?quantity, isChecked ? checked : notChecked].join(', ');

  // Backup.
  static const backupMenu = 'Backup';
  static const exportBackup = 'Exportar backup';
  static const importBackup = 'Importar backup';
  static const backupSaved = 'Backup salvo.';
  static const backupSaveFailed = 'Não foi possível salvar o backup.';
  static const importTitle = 'Substituir todos os dados?';
  static const importMessage =
      'As listas atuais serão substituídas pelas do arquivo. '
      'Isso não pode ser desfeito.';
  static const importConfirm = 'Substituir';
  static const importDone = 'Backup importado.';
  static const importFailed =
      'Não foi possível importar o backup. Seus dados não foram alterados.';
  static const reminderText =
      'Faça um backup para não perder suas listas se trocar de aparelho.';
  static const reminderAction = 'Fazer backup';
  static const reminderDismiss = 'Agora não';

  static const volatileStorage =
      'Seus dados não serão salvos neste navegador. '
      'Exporte um backup antes de fechar a página.';

  // Ações gerais.
  static const cancel = 'Cancelar';
  static const save = 'Salvar';
  static const create = 'Criar';
  static const edit = 'Editar';
  static const moveUp = 'Mover para cima';
  static const moveDown = 'Mover para baixo';
  static const delete = 'Apagar';
  static const undo = 'Desfazer';
}
