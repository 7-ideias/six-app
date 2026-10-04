import 'package:flutter/material.dart';

class SixVisualAssetShimmer extends StatefulWidget {
  const SixVisualAssetShimmer({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 20,
  });

  final double? height;
  final double? width;
  final double borderRadius;

  @override
  State<SixVisualAssetShimmer> createState() => _SixVisualAssetShimmerState();
}

class _SixVisualAssetShimmerState extends State<SixVisualAssetShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color base = Color.alphaBlend(
      Colors.grey.withValues(alpha: 0.16),
      colors.surfaceContainerHighest,
    );
    final Color highlight = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.28),
      colors.surfaceContainerHighest,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double position = (_controller.value * 2.4) - 1.2;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),
            gradient: LinearGradient(
              begin: Alignment(position - 1, 0),
              end: Alignment(position + 1, 0),
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.18, 0.5, 0.82],
            ),
          ),
        );
      },
    );
  }
}
