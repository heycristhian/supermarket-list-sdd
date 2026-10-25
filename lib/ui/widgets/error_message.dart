import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Mensagem de erro com ícone de alerta. A marca não tem cor de erro, então o
/// erro é comunicado por ícone + texto (research.md R14).
class ErrorMessage extends StatelessWidget {
  const ErrorMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: Tokens.iconSm,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: Tokens.spaceSm),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
