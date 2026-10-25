import 'package:flutter/material.dart';

import '../theme/brand_theme.dart';
import '../theme/tokens.dart';

/// Estado vazio com ícone, título, texto e uma ação opcional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Tokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Tokens.iconXl, color: context.brand.neutralIcon),
            const SizedBox(height: Tokens.spaceLg),
            Text(
              title,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Tokens.spaceSm),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: Tokens.spaceXl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
