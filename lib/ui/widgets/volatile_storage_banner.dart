import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../strings.dart';
import '../theme/tokens.dart';

/// Aviso fixo quando o navegador não consegue guardar os dados
/// (research.md R2): sem ação para dispensar, porque o risco continua.
class VolatileStorageBanner extends ConsumerWidget {
  const VolatileStorageBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<bool>(
      valueListenable: ref.watch(storageVolatileProvider),
      builder: (context, volatile, _) {
        if (!volatile) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final banner = theme.bannerTheme;
        return Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: banner.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: banner.dividerColor ?? theme.dividerColor,
                  width: Tokens.accentLineThickness,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Tokens.spaceLg,
                vertical: Tokens.spaceMd,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: Tokens.spaceMd),
                  Expanded(
                    child: Text(
                      Strings.volatileStorage,
                      style: banner.contentTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
