import 'package:flutter/material.dart';

import '../../domain/errors.dart';
import '../../domain/name_rules.dart';
import '../strings.dart';
import '../theme/brand_theme.dart';
import '../theme/tokens.dart';
import 'error_message.dart';

/// Campo fixo no rodapé para adicionar itens em sequência (FR-013a).
class AddItemBar extends StatefulWidget {
  const AddItemBar({super.key, required this.onAdd});

  static const nameFieldKey = Key('add-item-name');
  static const quantityFieldKey = Key('add-item-quantity');

  /// Grava o item; um [DomainException] vira mensagem e o texto é mantido.
  final Future<void> Function(String name, String quantity) onAdd;

  @override
  State<AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<AddItemBar> {
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _nameFocus = FocusNode();
  final _tapGroup = Object();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await widget.onAdd(_name.text, _quantity.text);
      _name.clear();
      _quantity.clear();
      setState(() => _error = null);
    } on DomainException catch (e) {
      setState(() => _error = e.message);
    }
    _nameFocus.requestFocus();
  }

  void _unfocus(PointerDownEvent _) => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: _unfocus,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: context.brand.accentLine,
              width: Tokens.accentLineThickness,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Tokens.spaceMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  ErrorMessage(_error!),
                  const SizedBox(height: Tokens.spaceSm),
                ],
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        key: AddItemBar.nameFieldKey,
                        controller: _name,
                        focusNode: _nameFocus,
                        groupId: _tapGroup,
                        maxLength: maxNameLength + 1,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: Strings.itemNameLabel,
                          hintText: Strings.itemNameHint,
                          counterText: '',
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: Tokens.spaceSm),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        key: AddItemBar.quantityFieldKey,
                        controller: _quantity,
                        groupId: _tapGroup,
                        maxLength: maxQuantityLength + 1,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: Strings.quantityLabel,
                          hintText: Strings.quantityHint,
                          counterText: '',
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: Tokens.spaceSm),
                    IconButton.filled(
                      tooltip: Strings.addItem,
                      icon: const Icon(Icons.add),
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
