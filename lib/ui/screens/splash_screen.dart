import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../strings.dart';
import '../theme/brand_theme.dart';
import '../theme/tokens.dart';

/// Mostra a [SplashScreen] na abertura a frio e depois [child]. A troca
/// acontece quando a animação termina e o banco abre, o que vier por
/// último, com teto de `Tokens.splashMaxDuration` (FR-029, research.md R8).
/// Voltar do segundo plano não recria este estado, então a splash não
/// reaparece (FR-030).
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Tokens.durationSlow,
  );
  late final Timer _cap;
  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _cap = Timer(Tokens.splashMaxDuration, _finish);
    _controller.addStatusListener((_) => _maybeFinish());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _cap.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _maybeFinish() {
    if (_controller.isCompleted && ref.read(activeListIdProvider).hasValue) {
      _finish();
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _cap.cancel();
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeListIdProvider, (_, _) => _maybeFinish());
    final animate = !MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: animate ? Tokens.durationMedium : Duration.zero,
      child: _done ? widget.child : SplashScreen(animation: _controller),
    );
  }
}

/// Fundo da marca com o logo T_YOU surgindo (fade + escala) e uma linha fina
/// turquesa se desenhando sob ele.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final logo = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final line = CurvedAnimation(
      parent: animation,
      curve: const Interval(Tokens.splashLineStart, 1, curve: Curves.easeOut),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.splashBackground,
        gradient: brand.splashGradient,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: logo,
              child: ScaleTransition(
                scale: Tween(
                  begin: Tokens.splashLogoStartScale,
                  end: 1.0,
                ).animate(logo),
                child: Image.asset(
                  'assets/images/logo_light.png',
                  width: Tokens.splashLogoWidth,
                  semanticLabel: Strings.appTitle,
                ),
              ),
            ),
            const SizedBox(height: Tokens.spaceLg),
            SizedBox(
              width: Tokens.splashLogoWidth,
              height: Tokens.accentLineThickness,
              child: AnimatedBuilder(
                animation: line,
                builder: (_, _) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: line.value,
                  child: ColoredBox(color: brand.accentLine),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
