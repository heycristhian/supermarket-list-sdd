import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../strings.dart';
import '../theme/brand_theme.dart';
import '../theme/tokens.dart';

enum _ItemAction { edit, moveUp, moveDown, delete }

/// Um item da lista. A área principal marca/desmarca (FR-018); a alça ⋮⋮
/// arrasta e o menu ⋯ edita, move e apaga, sem marcar (FR-016a).
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.reorderIndex,
    this.onEdit,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final ShoppingItem item;
  final VoidCallback onToggle;

  /// Índice no `SliverReorderableList`; `null` esconde a alça.
  final int? reorderIndex;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// `null` desabilita a ação (item já no limite). Itens comprados não
  /// mostram "Mover".
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final showHandle = reorderIndex != null && !item.isChecked;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (showHandle)
            ReorderableDragStartListener(
              index: reorderIndex!,
              child: Tooltip(
                message: Strings.reorderHandle,
                child: SizedBox(
                  width: Tokens.minTouchTarget,
                  height: Tokens.itemRowMinHeight,
                  child: Icon(
                    Icons.drag_indicator,
                    color: context.brand.neutralIcon,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _MainArea(
              item: item,
              onToggle: onToggle,
              hasHandle: showHandle,
            ),
          ),
          _menu(context),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context) {
    final movable = !item.isChecked;
    return PopupMenuButton<_ItemAction>(
      tooltip: Strings.itemMenu,
      icon: Icon(Icons.more_horiz, color: context.brand.neutralIcon),
      onSelected: (action) => switch (action) {
        _ItemAction.edit => onEdit?.call(),
        _ItemAction.moveUp => onMoveUp?.call(),
        _ItemAction.moveDown => onMoveDown?.call(),
        _ItemAction.delete => onDelete?.call(),
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: _ItemAction.edit, child: Text(Strings.edit)),
        if (movable) ...[
          PopupMenuItem(
            value: _ItemAction.moveUp,
            enabled: onMoveUp != null,
            child: const Text(Strings.moveUp),
          ),
          PopupMenuItem(
            value: _ItemAction.moveDown,
            enabled: onMoveDown != null,
            child: const Text(Strings.moveDown),
          ),
        ],
        const PopupMenuItem(
          value: _ItemAction.delete,
          child: Text(Strings.delete),
        ),
      ],
    );
  }
}

class _MainArea extends StatelessWidget {
  const _MainArea({
    required this.item,
    required this.onToggle,
    required this.hasHandle,
  });

  final ShoppingItem item;
  final VoidCallback onToggle;
  final bool hasHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checked = item.isChecked;
    final checkedStyle = TextStyle(
      color: context.brand.checkedItemText,
      decoration: TextDecoration.lineThrough,
      decorationColor: context.brand.checkedItemText,
    );

    return Semantics(
      button: true,
      checked: checked,
      label: Strings.itemSemantics(item.name, item.quantity, checked),
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Tokens.itemRowMinHeight),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: hasHandle ? 0 : Tokens.spaceLg,
              top: Tokens.spaceSm,
              bottom: Tokens.spaceSm,
            ),
            child: Row(
              children: [
                Icon(
                  checked ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: checked
                      ? theme.colorScheme.primary
                      : context.brand.neutralIcon,
                ),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: checked
                            ? theme.textTheme.bodyLarge?.merge(checkedStyle)
                            : theme.textTheme.bodyLarge,
                      ),
                      if (item.quantity != null)
                        Text(
                          item.quantity!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: checked
                              ? theme.textTheme.bodyMedium?.merge(checkedStyle)
                              : theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
