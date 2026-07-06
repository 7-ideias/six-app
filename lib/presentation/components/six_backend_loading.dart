import 'package:flutter/material.dart';

/// Tipos de animação disponíveis para carregamento de mensagens vindas do backend.
///
/// Para trocar globalmente a animação padrão, altere
/// [SixBackendLoadingDefaults.messageLoadingAnimation].
enum SixBackendLoadingAnimation {
  skeletonPulse,
  waveDots,
  progressSweep,
}

class SixBackendLoadingDefaults {
  const SixBackendLoadingDefaults._();

  static const SixBackendLoadingAnimation messageLoadingAnimation =
      SixBackendLoadingAnimation.skeletonPulse;
}

class SixBackendLoading extends StatefulWidget {
  const SixBackendLoading({
    super.key,
    required this.title,
    required this.subtitle,
    this.animation = SixBackendLoadingDefaults.messageLoadingAnimation,
    this.leadingIcon = Icons.cloud_sync_outlined,
    this.compact = false,
    this.onTap,
    this.padding,
    this.borderRadius = 18,
    this.backgroundColor,
    this.borderColor,
  });

  const SixBackendLoading.messages({
    super.key,
    this.title = 'Carregando mensagens do backend',
    this.subtitle =
        'Estamos sincronizando as mensagens e eventos mais recentes desta empresa.',
    this.animation = SixBackendLoadingDefaults.messageLoadingAnimation,
    this.leadingIcon = Icons.cloud_sync_outlined,
    this.compact = false,
    this.onTap,
    this.padding,
    this.borderRadius = 18,
    this.backgroundColor,
    this.borderColor,
  });

  final String title;
  final String subtitle;
  final SixBackendLoadingAnimation animation;
  final IconData leadingIcon;
  final bool compact;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  State<SixBackendLoading> createState() => _SixBackendLoadingState();
}

class _SixBackendLoadingState extends State<SixBackendLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(
        reverse: widget.animation == SixBackendLoadingAnimation.skeletonPulse,
      );
  }

  @override
  void didUpdateWidget(covariant SixBackendLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation == widget.animation) return;
    _controller
      ..stop()
      ..reset()
      ..repeat(
        reverse: widget.animation == SixBackendLoadingAnimation.skeletonPulse,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color background = widget.backgroundColor ?? colorScheme.surface;
    final Color border = widget.borderColor ??
        colorScheme.outline.withValues(alpha: widget.compact ? 0.10 : 0.12);

    final Widget content = Container(
      width: double.infinity,
      padding: widget.padding ?? EdgeInsets.all(widget.compact ? 14 : 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: border),
        boxShadow: widget.compact
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool vertical = widget.compact || constraints.maxWidth < 520;
          final Widget icon = _buildIcon(theme);
          final Widget text = _buildText(theme);
          final Widget animation = _buildAnimation(theme, vertical: vertical);

          if (vertical) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 12),
                animation,
              ],
            );
          }

          return Row(
            children: <Widget>[
              icon,
              const SizedBox(width: 12),
              Expanded(child: text),
              const SizedBox(width: 16),
              SizedBox(width: 180, child: animation),
            ],
          );
        },
      ),
    );

    if (widget.onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onTap: widget.onTap,
        child: content,
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double pulse = 0.96 + (_controller.value * 0.08);
        return Transform.scale(scale: pulse, child: child);
      },
      child: Container(
        width: widget.compact ? 42 : 46,
        height: widget.compact ? 42 : 46,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(widget.compact ? 14 : 16),
        ),
        child: Icon(widget.leadingIcon, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildText(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          maxLines: widget.compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimation(ThemeData theme, {required bool vertical}) {
    switch (widget.animation) {
      case SixBackendLoadingAnimation.waveDots:
        return _buildWaveDots(theme);
      case SixBackendLoadingAnimation.progressSweep:
        return _buildProgressSweep(theme);
      case SixBackendLoadingAnimation.skeletonPulse:
        return _buildSkeletonPulse(theme, vertical: vertical);
    }
  }

  Widget _buildSkeletonPulse(ThemeData theme, {required bool vertical}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double opacity = 0.32 + (_controller.value * 0.28);
        final Color color = theme.colorScheme.primary.withValues(alpha: opacity);
        final Color muted = theme.colorScheme.outlineVariant.withValues(
          alpha: 0.36 + (_controller.value * 0.20),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _skeletonLine(color: color, width: vertical ? 160 : 140),
            const SizedBox(height: 8),
            _skeletonLine(color: muted, width: vertical ? 240 : 180),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                _skeletonDot(color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: _skeletonLine(color: muted, width: double.infinity),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaveDots(ThemeData theme) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final double phase = (_controller.value + (index * 0.18)) % 1.0;
            final double intensity = 1 - ((phase - 0.5).abs() * 2);
            final double scale = 0.72 + (intensity * 0.34);
            final double opacity = 0.38 + (intensity * 0.46);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProgressSweep(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 6,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _skeletonLine({required Color color, required double width}) {
    return Container(
      width: width,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _skeletonDot({required Color color}) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
