import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

class SixMobileThemeTransitionOverlay extends StatefulWidget {
  const SixMobileThemeTransitionOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<SixMobileThemeTransitionOverlay> createState() =>
      _SixMobileThemeTransitionOverlayState();
}

class _SixMobileThemeTransitionOverlayState
    extends State<SixMobileThemeTransitionOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 260);

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  Brightness? _lastBrightness;
  Color? _lastBackgroundColor;
  Color? _overlayColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..value = 1;
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ).drive(Tween<double>(begin: 0.30, end: 0));
    _controller.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;
    final Color currentBackground = _backgroundForBrightness(brightness);
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (_lastBrightness == null) {
      _lastBrightness = brightness;
      _lastBackgroundColor = currentBackground;
      return;
    }

    if (_lastBrightness != brightness) {
      _overlayColor = _lastBackgroundColor ?? currentBackground;
      _lastBrightness = brightness;
      _lastBackgroundColor = currentBackground;

      if (reduceMotion) {
        _controller.value = 1;
        _overlayColor = null;
      } else {
        _controller.forward(from: 0);
      }
      return;
    }

    _lastBackgroundColor = currentBackground;
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _overlayColor == null) return;
    setState(() => _overlayColor = null);
  }

  Color _backgroundForBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? SixMobilePalette.backgroundDark
        : SixMobilePalette.backgroundLight;
  }

  @override
  Widget build(BuildContext context) {
    final Color? overlayColor = _overlayColor;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (overlayColor != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _opacity,
                builder: (BuildContext context, Widget? child) {
                  return ColoredBox(
                    color: overlayColor.withValues(alpha: _opacity.value),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
