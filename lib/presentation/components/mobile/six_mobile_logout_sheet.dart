import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';

Future<bool> showSixMobileLogoutSheet(BuildContext context) async {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final bool? confirmed = await showCupertinoModalPopup<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.40),
    barrierDismissible: true,
    semanticsDismissible: true,
    builder: (BuildContext popupContext) {
      return _SixMobileLogoutSheet(
        title: context.t(
          'account.settings.logout.confirmTitle',
          fallback: 'Sair da conta?',
        ),
        subtitle: context.t(
          'account.settings.logout.confirmSubtitle',
          fallback: 'Deslize para encerrar sua sessão neste aparelho.',
        ),
        swipeLabel: context.t(
          'account.settings.logout.swipeHint',
          fallback: 'Deslize para sair',
        ),
        swipeSemantics: context.t(
          'account.settings.logout.swipeSemantics',
          fallback: 'Deslize para confirmar a saída da conta',
        ),
        onConfirmed: () => Navigator.of(popupContext).pop(true),
      );
    },
  );

  return confirmed ?? false;
}

class _SixMobileLogoutSheet extends StatefulWidget {
  const _SixMobileLogoutSheet({
    required this.title,
    required this.subtitle,
    required this.swipeLabel,
    required this.swipeSemantics,
    required this.onConfirmed,
  });

  final String title;
  final String subtitle;
  final String swipeLabel;
  final String swipeSemantics;
  final VoidCallback onConfirmed;

  @override
  State<_SixMobileLogoutSheet> createState() => _SixMobileLogoutSheetState();
}

class _SixMobileLogoutSheetState extends State<_SixMobileLogoutSheet> {
  double _dragDistance = 0;
  bool _dismissed = false;

  void _updateDismissDrag(DragUpdateDetails details) {
    if (_dismissed) return;
    _dragDistance = (_dragDistance + (details.primaryDelta ?? 0)).clamp(
      0,
      double.infinity,
    );
    if (_dragDistance >= 56) {
      _dismiss();
    }
  }

  void _finishDismissDrag(DragEndDetails details) {
    if (_dismissed) return;
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity > 360 || _dragDistance >= 40) {
      _dismiss();
      return;
    }
    _dragDistance = 0;
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                onVerticalDragUpdate: _updateDismissDrag,
                onVerticalDragEnd: _finishDismissDrag,
                onVerticalDragCancel: () => _dragDistance = 0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colors.navigationShadow.withValues(
                            alpha: 0.72,
                          ),
                          blurRadius: 34,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: colors.strongBorder.withValues(
                                alpha: 0.58,
                              ),
                              width: 0.7,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: 36,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: colors.strongBorder.withValues(
                                      alpha: 0.72,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.error.withValues(alpha: 0.10),
                                    border: Border.all(
                                      color: colors.error.withValues(
                                        alpha: 0.24,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.power,
                                    color: colors.error,
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.titleText,
                                    fontSize: 20,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.subtitle,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.mutedText,
                                    fontSize: 13,
                                    height: 1.38,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _SixMobileLogoutSlider(
                                  label: widget.swipeLabel,
                                  semanticsLabel: widget.swipeSemantics,
                                  onConfirmed: widget.onConfirmed,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SixMobileLogoutSlider extends StatefulWidget {
  const _SixMobileLogoutSlider({
    required this.label,
    required this.semanticsLabel,
    required this.onConfirmed,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback onConfirmed;

  @override
  State<_SixMobileLogoutSlider> createState() => _SixMobileLogoutSliderState();
}

class _SixMobileLogoutSliderState extends State<_SixMobileLogoutSlider>
    with SingleTickerProviderStateMixin {
  static const double _height = 62;
  static const double _inset = 5;
  static const double _thumbSize = 52;
  static const double _confirmationThreshold = 0.84;

  late final AnimationController _progressController;
  bool _dragging = false;
  bool _confirmed = false;
  bool _midpointFeedbackSent = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
      value: 0,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startDrag() {
    if (_confirmed) return;
    _progressController.stop();
    setState(() => _dragging = true);
    HapticFeedback.selectionClick();
  }

  void _updateDrag(DragUpdateDetails details, double maxTravel) {
    if (_confirmed || maxTravel <= 0) return;
    final double next = (_progressController.value +
            details.delta.dx / maxTravel)
        .clamp(0.0, 1.0);
    _progressController.value = next;

    if (next >= 0.52 && !_midpointFeedbackSent) {
      _midpointFeedbackSent = true;
      HapticFeedback.selectionClick();
    } else if (next < 0.42) {
      _midpointFeedbackSent = false;
    }
  }

  Future<void> _finishDrag(DragEndDetails details, double maxTravel) async {
    if (_confirmed) return;
    final double velocity = details.primaryVelocity ?? 0;
    final bool fastForward =
        maxTravel > 0 && velocity > 850 && _progressController.value >= 0.48;
    final bool shouldConfirm =
        _progressController.value >= _confirmationThreshold || fastForward;

    if (mounted) setState(() => _dragging = false);
    if (shouldConfirm) {
      await _confirm();
      return;
    }
    await _returnToStart();
  }

  Future<void> _returnToStart() async {
    if (_confirmed) return;
    _midpointFeedbackSent = false;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    await _progressController.animateTo(
      0,
      duration:
          reduceMotion
              ? Duration.zero
              : Duration(
                milliseconds: 210 + (_progressController.value * 130).round(),
              ),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirm() async {
    if (_confirmed) return;
    setState(() {
      _confirmed = true;
      _dragging = false;
    });
    HapticFeedback.heavyImpact();

    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    await _progressController.animateTo(
      1,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxTravel = (constraints.maxWidth -
                _thumbSize -
                (_inset * 2))
            .clamp(0, double.infinity);

        return Semantics(
          key: const ValueKey<String>('six-mobile-logout-slider'),
          button: true,
          enabled: !_confirmed,
          label: widget.semanticsLabel,
          hint: widget.label,
          onTap: _confirmed ? null : _confirm,
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _startDrag(),
              onHorizontalDragUpdate:
                  (DragUpdateDetails details) =>
                      _updateDrag(details, maxTravel),
              onHorizontalDragEnd:
                  (DragEndDetails details) => _finishDrag(details, maxTravel),
              onHorizontalDragCancel: () {
                if (mounted) setState(() => _dragging = false);
                _returnToStart();
              },
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (BuildContext context, Widget? child) {
                  final double progress = _progressController.value;
                  final double visualProgress = Curves.easeOutCubic.transform(
                    progress,
                  );
                  final double labelOpacity = (1 - (progress * 1.05)).clamp(
                    0.18,
                    1.0,
                  );
                  final Color thumbColor =
                      Color.lerp(
                        colors.surfaceElevated,
                        colors.error.withValues(alpha: 0.92),
                        visualProgress,
                      )!;
                  final Color iconColor =
                      progress > 0.58 ? colors.surface : colors.error;

                  return SizedBox(
                    height: _height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(_height / 2),
                        border: Border.all(
                          color:
                              Color.lerp(
                                colors.border,
                                colors.errorBorder,
                                progress,
                              )!,
                          width: 0.8,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: colors.navigationShadow.withValues(
                              alpha: 0.24,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_height / 2),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Positioned(
                              left: _inset,
                              top: _inset,
                              bottom: _inset,
                              width: _thumbSize + (visualProgress * maxTravel),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: <Color>[
                                      colors.error.withValues(alpha: 0.08),
                                      colors.error.withValues(
                                        alpha: 0.12 + (visualProgress * 0.12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 20 - (visualProgress * 8),
                              child: Opacity(
                                opacity: (0.30 - (visualProgress * 0.24)).clamp(
                                  0.0,
                                  0.30,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: colors.mutedText,
                                      size: 13,
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: colors.mutedText,
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 64,
                              ),
                              child: Transform.translate(
                                offset: Offset(visualProgress * 8, 0),
                                child: Opacity(
                                  opacity: labelOpacity,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          widget.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color.lerp(
                                              colors.mutedText,
                                              colors.titleText,
                                              visualProgress * 0.45,
                                            ),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        CupertinoIcons.chevron_right,
                                        color: colors.mutedText.withValues(
                                          alpha: 0.74,
                                        ),
                                        size: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: _inset + (progress * maxTravel),
                              top: _inset,
                              child: AnimatedScale(
                                scale: _dragging ? 1.035 : 1,
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  width: _thumbSize,
                                  height: _thumbSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: thumbColor,
                                    border: Border.all(
                                      color: colors.error.withValues(
                                        alpha: 0.24 + (visualProgress * 0.34),
                                      ),
                                      width: 0.9,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: colors.navigationShadow
                                            .withValues(alpha: 0.42),
                                        blurRadius: _dragging ? 18 : 12,
                                        offset: Offset(0, _dragging ? 7 : 4),
                                      ),
                                      BoxShadow(
                                        color: colors.error.withValues(
                                          alpha: visualProgress * 0.20,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _confirmed
                                        ? CupertinoIcons.check_mark
                                        : CupertinoIcons.power,
                                    color: iconColor,
                                    size: _confirmed ? 22 : 23,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
