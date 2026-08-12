import 'package:flutter/material.dart';

class AiAssistantButton extends StatelessWidget {
  const AiAssistantButton({
    super.key,
    required this.onTap,
    required this.label,
    this.extended = false,
    this.highlighted = false,
    this.tooltip,
  });

  final VoidCallback onTap;
  final String label;
  final bool extended;
  final bool highlighted;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String resolvedTooltip = tooltip ?? label;
    final Color backgroundColor = colorScheme.primary;

    if (extended) {
      return _AiAssistantButtonHighlight(
        highlighted: highlighted,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        child: FloatingActionButton.extended(
          heroTag: null,
          tooltip: resolvedTooltip,
          onPressed: onTap,
          backgroundColor: backgroundColor,
          foregroundColor: colorScheme.onPrimary,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return _AiAssistantButtonHighlight(
      highlighted: highlighted,
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: FloatingActionButton.small(
        heroTag: null,
        onPressed: onTap,
        backgroundColor: backgroundColor,
        foregroundColor: colorScheme.onPrimary,
        tooltip: resolvedTooltip,
        child: const Icon(Icons.auto_awesome_outlined),
      ),
    );
  }
}

class _AiAssistantButtonHighlight extends StatefulWidget {
  const _AiAssistantButtonHighlight({
    required this.highlighted,
    required this.color,
    required this.borderRadius,
    required this.child,
  });

  final bool highlighted;
  final Color color;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<_AiAssistantButtonHighlight> createState() =>
      _AiAssistantButtonHighlightState();
}

class _AiAssistantButtonHighlightState
    extends State<_AiAssistantButtonHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.highlighted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AiAssistantButtonHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlighted == widget.highlighted) return;
    if (widget.highlighted) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.highlighted) {
      return widget.child;
    }

    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.color.withValues(alpha: 0.30),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: widget.child,
      );
    }

    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        final double progress = _animation.value;
        return Transform.scale(
          scale: 1 + (progress * 0.035),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.22 + progress * 0.16),
                  blurRadius: 18 + progress * 10,
                  spreadRadius: 1 + progress * 2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
