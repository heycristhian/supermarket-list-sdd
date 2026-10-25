import 'package:flutter/material.dart';

import '../../domain/errors.dart';
import '../../domain/models.dart';
import '../../domain/name_rules.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'error_message.dart';

/// Edita nome e quantidade de [item]. Mesmo comportamento de erro do
/// `NameDialog`: a mensagem aparece e o texto digitado é mantido.
Future<void> showItemDialog(
  BuildContext context, {
  required ShoppingItem item,
  required Future<void> Function(String name, String quantity) onSubmit,
}) => showDialog<void>(
  context: context,
  builder: (_) => ItemDialog(item: item, onSubmit: onSubmit),
);

class ItemDialog extends StatefulWidget {
  const ItemDialog({super.key, required this.item, required this.onSubmit});

  static const nameFieldKey = Key('item-dialog-name');
  static const quantityFieldKey = Key('item-dialog-quantity');

  final ShoppingItem item;
  final Future<void> Function(String name, String quantity) onSubmit;

  @override
  State<ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<ItemDialog> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _quantity = TextEditingController(
    text: widget.item.quantity ?? '',
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_name.text, _quantity.text);
      if (mounted) Navigator.of(context).pop();
    } on DomainException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Strings.editItemTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: ItemDialog.nameFieldKey,
            controller: _name,
            autofocus: true,
            maxLength: maxNameLength + 1,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: Strings.itemNameLabel,
              counterText: '',
            ),
          ),
          const SizedBox(height: Tokens.spaceMd),
          TextField(
            key: ItemDialog.quantityFieldKey,
            controller: _quantity,
            maxLength: maxQuantityLength + 1,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: Strings.quantityLabel,
              hintText: Strings.quantityHint,
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: Tokens.spaceSm),
            ErrorMessage(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Strings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text(Strings.save),
        ),
      ],
    );
  }
}
