import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/errors.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../strings.dart';
import '../theme/brand_theme.dart';
import '../theme/tokens.dart';
import '../widgets/add_item_bar.dart';
import '../widgets/backup_reminder_banner.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/item_dialog.dart';
import '../widgets/item_tile.dart';
import '../widgets/volatile_storage_banner.dart';
import 'lists_screen.dart';

/// Itens de uma lista: marcar no mercado e adicionar pelo rodapé.
class ListItemsScreen extends ConsumerWidget {
  const ListItemsScreen({super.key, required this.listId});

  final int listId;

  void _openLists(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // Aberta como home: a tela de listas passa a ser a raiz, para que
      // apagar esta lista nunca deixe uma tela órfã na pilha.
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ListsScreen()),
      );
    }
  }

  Future<void> _uncheckAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: Strings.uncheckAllTitle,
      message: Strings.uncheckAllMessage,
      confirmLabel: Strings.uncheckAllConfirm,
    );
    if (confirmed) await ref.read(repositoryProvider).uncheckAll(listId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(listProvider(listId)).value;
    final items = ref.watch(itemsProvider(listId));
    final repo = ref.read(repositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.name ?? ''),
        actions: [
          IconButton(
            tooltip: Strings.uncheckAll,
            icon: const Icon(Icons.remove_done),
            onPressed: list != null && list.checkedItems > 0
                ? () => _uncheckAll(context, ref)
                : null,
          ),
          IconButton(
            tooltip: Strings.openLists,
            icon: const Icon(Icons.view_list_outlined),
            onPressed: () => _openLists(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const VolatileStorageBanner(),
          const BackupReminderBanner(),
          if (list != null && list.totalItems > 0) _ProgressHeader(list: list),
          Expanded(
            child: switch (items) {
              AsyncData(:final value) when value.isEmpty => const EmptyState(
                icon: Icons.shopping_basket_outlined,
                title: Strings.emptyListTitle,
                message: Strings.emptyListBody,
              ),
              AsyncData(:final value) => _ItemsView(
                listId: listId,
                items: value,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          AddItemBar(
            onAdd: (name, quantity) =>
                repo.addItem(listId, name, quantity: quantity),
          ),
        ],
      ),
    );
  }
}

/// Não comprados reordenáveis pela alça; comprados abaixo, na ordem em que
/// foram marcados (FR-016, FR-019).
class _ItemsView extends ConsumerWidget {
  const _ItemsView({required this.listId, required this.items});

  final int listId;
  final List<ShoppingItem> items;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
  ) async {
    final repo = ref.read(repositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await repo.deleteItem(item.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(Strings.itemDeleted(item.name)),
          duration: Tokens.undoSnackBarDuration,
          action: SnackBarAction(
            label: Strings.undo,
            onPressed: () async {
              try {
                await repo.restoreItem(deleted);
              } on DomainException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
          ),
        ),
      );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item, {
    int? reorderIndex,
    int uncheckedCount = 0,
  }) {
    final repo = ref.read(repositoryProvider);
    final index = reorderIndex;
    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.only(bottom: Tokens.spaceSm),
      child: ItemTile(
        item: item,
        reorderIndex: index,
        onToggle: () => repo.toggleChecked(item.id),
        onEdit: () => showItemDialog(
          context,
          item: item,
          onSubmit: (name, quantity) =>
              repo.editItem(item.id, name, quantity: quantity),
        ),
        onDelete: () => _delete(context, ref, item),
        onMoveUp: index != null && index > 0
            ? () => repo.moveItem(item.id, -1)
            : null,
        onMoveDown: index != null && index < uncheckedCount - 1
            ? () => repo.moveItem(item.id, 1)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unchecked = items.where((i) => !i.isChecked).toList();
    final checked = items.where((i) => i.isChecked).toList();
    final repo = ref.read(repositoryProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.spaceLg,
            Tokens.spaceLg,
            Tokens.spaceLg,
            0,
          ),
          sliver: SliverReorderableList(
            itemCount: unchecked.length,
            onReorderItem: (oldIndex, newIndex) =>
                repo.reorderUncheckedItems(listId, oldIndex, newIndex),
            proxyDecorator: (child, _, _) => Material(
              type: MaterialType.transparency,
              elevation: Tokens.elevationMid,
              child: child,
            ),
            itemBuilder: (context, index) => _tile(
              context,
              ref,
              unchecked[index],
              reorderIndex: index,
              uncheckedCount: unchecked.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.spaceLg,
            0,
            Tokens.spaceLg,
            Tokens.spaceLg,
          ),
          sliver: SliverList.builder(
            itemCount: checked.length,
            itemBuilder: (context, index) =>
                _tile(context, ref, checked[index]),
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Tokens.spaceLg,
        Tokens.spaceSm,
        Tokens.spaceLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                Strings.progress(list.checkedItems, list.totalItems),
                style: textTheme.titleLarge,
              ),
              const Spacer(),
              if (list.isComplete)
                Text(Strings.listComplete, style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: Tokens.spaceSm),
          LinearProgressIndicator(
            value: list.checkedItems / list.totalItems,
            minHeight: Tokens.accentLineThickness * 2,
            color: context.brand.accentLine,
            backgroundColor: Theme.of(context).colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
