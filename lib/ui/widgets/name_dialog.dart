import 'package:flutter/material.dart';

import '../../domain/errors.dart';
import '../../domain/name_rules.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'error_message.dart';

/// Pede um nome (criar, renomear, copiar). [onSubmit] grava o valor; um
/// [DomainException] vira mensagem e o texto digitado é mantido.
/// Devolve `true` se o nome foi aceito.
Future<bool> showNameDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  required Future<void> Function(String name) onSubmit,
  String initialValue = '',
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (_) => NameDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      onSubmit: onSubmit,
      initialValue: initialValue,
    ),
  );
  return accepted ?? false;
}

class NameDialog extends StatefulWidget {
  const NameDialog({
    super.key,
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.onSubmit,
    this.initialValue = '',
  });

  static const fieldKey = Key('name-dialog-field');

  final String title;
  final String label;
  final String confirmLabel;
  final Future<void> Function(String name) onSubmit;
  final String initialValue;

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late final _controller = TextEditingController(text: widget.initialValue)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialValue.length,
    );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_controller.text);
      if (mounted) Navigator.of(context).pop(true);
    } on DomainException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: NameDialog.fieldKey,
            controller: _controller,
            autofocus: true,
            maxLength: maxNameLength + 1,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: widget.label,
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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(Strings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
