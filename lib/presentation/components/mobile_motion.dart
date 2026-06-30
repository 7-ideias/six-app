import 'dart:async';

import 'package:flutter/material.dart';

class SixStaggeredEntry extends StatefulWidget {
  const SixStaggeredEntry({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.beginOffset = const Offset(0, 0.08),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  @override
  State<SixStaggeredEntry> createState() => _SixStaggeredEntryState();
}

class _SixStaggeredEntryState extends State<SixStaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final CurvedAnimation curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class SixAnimatedNumberText extends StatelessWidget {
  const SixAnimatedNumberText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 650),
  });

  final String value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final int? target = int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));

    if (target == null) {
      return Text(value, style: style);
    }

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, int animatedValue, Widget? child) {
        return Text(animatedValue.toString(), style: style);
      },
    );
  }
}

class SixPulsingBadge extends StatefulWidget {
  const SixPulsingBadge({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 1300),
  });

  final Widget child;
  final bool enabled;
  final Duration duration;

  @override
  State<SixPulsingBadge> createState() => _SixPulsingBadgeState();
}

class _SixPulsingBadgeState extends State<SixPulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.14), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.14, end: 1), weight: 55),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SixPulsingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    }

    if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
