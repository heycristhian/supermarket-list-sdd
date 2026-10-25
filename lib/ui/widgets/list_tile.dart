import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../strings.dart';
import '../theme/brand_theme.dart';
import '../theme/tokens.dart';

enum _ListAction { activate, rename, copy, moveUp, moveDown, delete }

/// Uma lista na tela de listas. Chama-se `ShoppingListTile` para não colidir
/// com o `ListTile` do Material. A área principal abre a lista; a alça ⋮⋮
/// (só nas não ativas) arrasta; o menu ⋯ reúne as demais ações.
class ShoppingListTile extends StatelessWidget {
  const ShoppingListTile({
    super.key,
    required this.list,
    required this.isActive,
    required this.onOpen,
    this.reorderIndex,
    this.onActivate,
    this.onRename,
    this.onCopy,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final ShoppingList list;
  final bool isActive;
  final VoidCallback onOpen;

  /// Índice no `SliverReorderableList`; `null` esconde a alça.
  final int? reorderIndex;
  final VoidCallback? onActivate;
  final VoidCallback? onRename;

  /// `null` esconde "Copiar".
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  /// `null` desabilita a ação (lista no limite).
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showHandle = reorderIndex != null && !isActive;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isActive)
              ColoredBox(
                color: context.brand.activeListAccent,
                child: const SizedBox(width: Tokens.activeAccentWidth),
              ),
            if (showHandle)
              ReorderableDragStartListener(
                index: reorderIndex!,
                child: Tooltip(
                  message: Strings.reorderHandle,
                  child: SizedBox(
                    width: Tokens.minTouchTarget,
                    child: Icon(
                      Icons.drag_indicator,
                      color: context.brand.neutralIcon,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: InkWell(
                onTap: onOpen,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: Tokens.itemRowMinHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: showHandle ? 0 : Tokens.spaceLg,
                      top: Tokens.spaceSm,
                      bottom: Tokens.spaceSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isActive)
                          Text(
                            Strings.activeBadge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        Text(
                          list.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          Strings.progress(list.checkedItems, list.totalItems),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(child: _menu(context)),
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return PopupMenuButton<_ListAction>(
      tooltip: Strings.listMenu,
      icon: Icon(Icons.more_horiz, color: context.brand.neutralIcon),
      onSelected: (action) => switch (action) {
        _ListAction.activate => onActivate?.call(),
        _ListAction.rename => onRename?.call(),
        _ListAction.copy => onCopy?.call(),
        _ListAction.moveUp => onMoveUp?.call(),
        _ListAction.moveDown => onMoveDown?.call(),
        _ListAction.delete => onDelete?.call(),
      },
      itemBuilder: (_) => [
        if (!isActive)
          const PopupMenuItem(
            value: _ListAction.activate,
            child: Text(Strings.activate),
          ),
        const PopupMenuItem(
          value: _ListAction.rename,
          child: Text(Strings.rename),
        ),
        if (onCopy != null)
          const PopupMenuItem(
            value: _ListAction.copy,
            child: Text(Strings.copy),
          ),
        if (!isActive) ...[
          PopupMenuItem(
            value: _ListAction.moveUp,
            enabled: onMoveUp != null,
            child: const Text(Strings.moveUp),
          ),
          PopupMenuItem(
            value: _ListAction.moveDown,
            enabled: onMoveDown != null,
            child: const Text(Strings.moveDown),
          ),
        ],
        const PopupMenuItem(
          value: _ListAction.delete,
          child: Text(Strings.delete),
        ),
      ],
    );
  }
}
