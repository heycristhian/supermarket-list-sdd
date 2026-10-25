import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../state/providers.dart';
import '../backup_actions.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import '../widgets/backup_reminder_banner.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/list_tile.dart';
import '../widgets/name_dialog.dart';
import '../widgets/volatile_storage_banner.dart';
import 'list_items_screen.dart';

enum _BackupAction { export, import }

/// Todas as listas: a ativa no topo, com destaque, e as demais abaixo, na
/// ordem do usuário (FR-008 a FR-011).
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  void _open(BuildContext context, int listId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ListItemsScreen(listId: listId)),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    int? createdId;
    final created = await showNameDialog(
      context,
      title: Strings.newListTitle,
      label: Strings.listNameLabel,
      confirmLabel: Strings.create,
      onSubmit: (name) async =>
          createdId = await ref.read(repositoryProvider).createList(name),
    );
    if (created && createdId != null && context.mounted) {
      _open(context, createdId!);
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) => showNameDialog(
    context,
    title: Strings.renameListTitle,
    label: Strings.listNameLabel,
    confirmLabel: Strings.save,
    initialValue: list.name,
    onSubmit: (name) => ref.read(repositoryProvider).renameList(list.id, name),
  );

  Future<void> _copy(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final repo = ref.read(repositoryProvider);
    final suggestion = await repo.suggestCopyName(list.id);
    if (!context.mounted) return;
    await showNameDialog(
      context,
      title: Strings.copyListTitle,
      label: Strings.listNameLabel,
      confirmLabel: Strings.copy,
      initialValue: suggestion,
      onSubmit: (name) => repo.copyList(list.id, name),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: Strings.deleteListTitle,
      message: Strings.deleteListMessage(list.name),
      confirmLabel: Strings.delete,
    );
    if (confirmed) await ref.read(repositoryProvider).deleteList(list.id);
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list, {
    required bool isActive,
    int? reorderIndex,
    int inactiveCount = 0,
  }) {
    final repo = ref.read(repositoryProvider);
    final index = reorderIndex;
    return ShoppingListTile(
      list: list,
      isActive: isActive,
      reorderIndex: index,
      onOpen: () => _open(context, list.id),
      onActivate: () => repo.activateList(list.id),
      onRename: () => _rename(context, ref, list),
      onCopy: () => _copy(context, ref, list),
      onDelete: () => _delete(context, ref, list),
      onMoveUp: index != null && index > 0
          ? () => repo.moveList(list.id, -1)
          : null,
      onMoveDown: index != null && index < inactiveCount - 1
          ? () => repo.moveList(list.id, 1)
          : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(listsOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.listsTitle),
        actions: [
          PopupMenuButton<_BackupAction>(
            tooltip: Strings.backupMenu,
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => switch (action) {
              _BackupAction.export => exportBackup(context, ref),
              _BackupAction.import => importBackup(context, ref),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _BackupAction.export,
                child: Text(Strings.exportBackup),
              ),
              PopupMenuItem(
                value: _BackupAction.import,
                child: Text(Strings.importBackup),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(Strings.newList),
      ),
      body: Column(
        children: [
          const VolatileStorageBanner(),
          const BackupReminderBanner(),
          Expanded(
            child: switch (overview) {
              AsyncData(:final value) when value.isEmpty => const EmptyState(
                icon: Icons.playlist_add,
                title: Strings.noListsTitle,
                message: Strings.noListsBody,
              ),
              AsyncData(:final value) => _buildLists(context, ref, value),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLists(
    BuildContext context,
    WidgetRef ref,
    ListsOverview overview,
  ) {
    final others = overview.others;
    final repo = ref.read(repositoryProvider);
    const sidePadding = EdgeInsets.symmetric(horizontal: Tokens.spaceLg);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: Tokens.spaceLg)),
        if (overview.active case final active?)
          SliverPadding(
            padding: sidePadding,
            sliver: SliverToBoxAdapter(
              child: _tile(context, ref, active, isActive: true),
            ),
          ),
        if (others.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.spaceLg,
              Tokens.spaceXl,
              Tokens.spaceLg,
              Tokens.spaceSm,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                Strings.otherListsSection,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          SliverPadding(
            padding: sidePadding,
            sliver: SliverReorderableList(
              itemCount: others.length,
              onReorderItem: repo.reorderInactiveLists,
              proxyDecorator: (child, _, _) => Material(
                type: MaterialType.transparency,
                elevation: Tokens.elevationMid,
                child: child,
              ),
              itemBuilder: (context, index) => Padding(
                key: ValueKey(others[index].id),
                padding: const EdgeInsets.only(bottom: Tokens.spaceSm),
                child: _tile(
                  context,
                  ref,
                  others[index],
                  isActive: false,
                  reorderIndex: index,
                  inactiveCount: others.length,
                ),
              ),
            ),
          ),
        ],
        // Espaço para o FAB não cobrir a última lista.
        const SliverToBoxAdapter(child: SizedBox(height: Tokens.spaceXxl * 3)),
      ],
    );
  }
}
