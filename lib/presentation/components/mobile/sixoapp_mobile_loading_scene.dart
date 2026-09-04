import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_mobile_animated_gradient_background.dart';

enum SixoAppMobileLoadingBackground { brand, currentTheme }

/// Mantém a tela atual montada e apresenta o loading mobile do SixoApp com
/// entrada e saída suaves. Use em operações bloqueantes de rota.
class SixoAppMobileLoadingOverlay extends StatelessWidget {
  const SixoAppMobileLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.message,
    required this.child,
    this.semanticLabel,
    this.supportingMessage,
    this.visibleKey = const ValueKey<String>('sixoapp-mobile-loading-visible'),
    this.blockBackNavigation = false,
    this.isSuccess = false,
    this.successMessage,
    this.successSemanticLabel,
  });

  final bool isLoading;
  final String message;
  final String? semanticLabel;
  final String? supportingMessage;
  final Key visibleKey;
  final bool blockBackNavigation;
  final bool isSuccess;
  final String? successMessage;
  final String? successSemanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final Duration duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
    final bool isVisible = isLoading || isSuccess;
    final bool showSuccess = isSuccess && !isLoading;
    final String visibleMessage =
        showSuccess
            ? successMessage ?? context.t('common.completed')
            : message;
    final String? visibleSemanticLabel =
        showSuccess ? successSemanticLabel : semanticLabel;

    return PopScope(
      canPop: !blockBackNavigation || !isVisible,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ExcludeSemantics(excluding: isVisible, child: child),
          Positioned.fill(
            child: ExcludeSemantics(
              excluding: !isVisible,
              child: IgnorePointer(
                ignoring: !isVisible,
                child: AbsorbPointer(
                  child: AnimatedSwitcher(
                    duration: duration,
                    reverseDuration:
                        reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (
                      Widget? currentChild,
                      List<Widget> previousChildren,
                    ) {
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      final Animation<double> curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                        reverseCurve: Curves.easeInCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: child,
                      );
                    },
                    child:
                        isVisible
                            ? Material(
                              type: MaterialType.transparency,
                              child: _SixoAppMobileContextualLoading(
                                key: visibleKey,
                                isSuccess: showSuccess,
                                message: visibleMessage,
                                semanticLabel: visibleSemanticLabel,
                                supportingMessage:
                                    showSuccess ? null : supportingMessage,
                              ),
                            )
                            : const SizedBox.shrink(
                              key: ValueKey<String>(
                                'sixoapp-mobile-loading-hidden',
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

class _SixoAppMobileContextualLoading extends StatefulWidget {
  const _SixoAppMobileContextualLoading({
    super.key,
    required this.isSuccess,
    required this.message,
    this.semanticLabel,
    this.supportingMessage,
  });

  final bool isSuccess;
  final String message;
  final String? semanticLabel;
  final String? supportingMessage;

  @override
  State<_SixoAppMobileContextualLoading> createState() =>
      _SixoAppMobileContextualLoadingState();
}

class _SixoAppMobileContextualLoadingState
    extends State<_SixoAppMobileContextualLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _messageTimer;
  bool _reduceMotion = false;
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (widget.isSuccess) {
      _pulseController.value = 0.25;
    } else {
      _pulseController.repeat();
    }
    _scheduleMessage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    if (reduceMotion == _reduceMotion) return;

    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _messageTimer?.cancel();
      _showMessage = true;
      _pulseController
        ..stop()
        ..value = 0.25;
    } else if (!widget.isSuccess && !_pulseController.isAnimating) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _SixoAppMobileContextualLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess == oldWidget.isSuccess) return;

    if (widget.isSuccess) {
      _messageTimer?.cancel();
      _showMessage = true;
      _pulseController.stop();
    } else {
      _showMessage = _reduceMotion;
      if (!_reduceMotion) {
        _pulseController.repeat();
        _scheduleMessage();
      }
    }
  }

  void _scheduleMessage() {
    _messageTimer?.cancel();
    if (widget.isSuccess || _reduceMotion) {
      _showMessage = true;
      return;
    }
    _messageTimer = Timer(const Duration(milliseconds: 480), () {
      if (!mounted) return;
      setState(() => _showMessage = true);
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String supportingMessage = widget.supportingMessage?.trim() ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.background,
        systemNavigationBarDividerColor: colors.background,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Semantics(
        container: true,
        liveRegion: true,
        label: widget.semanticLabel ?? 'SixoApp. ${widget.message}',
        child: ExcludeSemantics(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ClipRect(
                key: const ValueKey<String>('sixoapp-mobile-loading-blur'),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: DecoratedBox(
                    key: const ValueKey<String>('sixoapp-mobile-loading-tint'),
                    decoration: BoxDecoration(
                      color: colors.background.withValues(
                        alpha: isDark ? 0.76 : 0.72,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    final bool compact = constraints.maxHeight < 560;
                    final double logoSize =
                        (constraints.maxWidth * 0.24)
                            .clamp(
                              compact ? 72.0 : 80.0,
                              compact ? 84.0 : 96.0,
                            )
                            .toDouble();

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (BuildContext context, Widget? child) {
                                final double pulse =
                                    _reduceMotion || widget.isSuccess
                                        ? 1
                                        : 1 +
                                            (math.sin(
                                                  _pulseController.value *
                                                      math.pi *
                                                      2,
                                                ) *
                                                0.025);
                                return AnimatedSwitcher(
                                  duration:
                                      _reduceMotion
                                          ? Duration.zero
                                          : const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (
                                    Widget child,
                                    Animation<double> animation,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                          begin: 0.90,
                                          end: 1,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child:
                                      widget.isSuccess
                                          ? _SixoAppSuccessMark(
                                            key: const ValueKey<String>(
                                              'sixoapp-mobile-loading-success',
                                            ),
                                            size: logoSize * 0.82,
                                            colors: colors,
                                          )
                                          : Transform.scale(
                                            key: const ValueKey<String>(
                                              'sixoapp-mobile-loading-logo',
                                            ),
                                            scale: pulse,
                                            child: _SixoAppAnimatedSymbol(
                                              size: logoSize,
                                              progress: _pulseController.value,
                                              reduceMotion: _reduceMotion,
                                              enableSweep: false,
                                            ),
                                          ),
                                );
                              },
                            ),
                            SizedBox(height: compact ? 12 : 16),
                            AnimatedOpacity(
                              opacity: _showMessage ? 1 : 0,
                              duration:
                                  _reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: Text(
                                  widget.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.titleText.withValues(
                                      alpha: 0.90,
                                    ),
                                    fontSize: compact ? 14 : 15,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (supportingMessage.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 5),
                              AnimatedOpacity(
                                opacity: _showMessage ? 1 : 0,
                                duration:
                                    _reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 300,
                                  ),
                                  child: Text(
                                    supportingMessage,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.mutedText,
                                      fontSize: compact ? 12 : 13,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SixoAppSuccessMark extends StatelessWidget {
  const _SixoAppSuccessMark({
    super.key,
    required this.size,
    required this.colors,
  });

  final double size;
  final SixMobileColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.softAccentSurface.withValues(alpha: 0.96),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.38),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        CupertinoIcons.check_mark,
        color: colors.accent,
        size: size * 0.46,
        semanticLabel: null,
      ),
    );
  }
}

class SixoAppMobileLoadingScene extends StatefulWidget {
  const SixoAppMobileLoadingScene({
    super.key,
    this.message,
    this.semanticLabel,
    this.supportingMessage,
  }) : background = SixoAppMobileLoadingBackground.brand;

  const SixoAppMobileLoadingScene.themed({
    super.key,
    this.message,
    this.semanticLabel,
    this.supportingMessage,
  }) : background = SixoAppMobileLoadingBackground.currentTheme;

  final String? message;
  final String? semanticLabel;
  final String? supportingMessage;
  final SixoAppMobileLoadingBackground background;

  @override
  State<SixoAppMobileLoadingScene> createState() =>
      _SixoAppMobileLoadingSceneState();
}

class _SixoAppMobileLoadingSceneState extends State<SixoAppMobileLoadingScene>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _loopController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..forward();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    if (reduceMotion == _reduceMotion) return;

    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _entryController.value = 1;
      _loopController
        ..stop()
        ..value = 0.42;
    } else {
      if (!_entryController.isCompleted) {
        _entryController.forward();
      }
      if (!_loopController.isAnimating) {
        _loopController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool useCurrentTheme =
        widget.background == SixoAppMobileLoadingBackground.currentTheme;
    final String message =
        widget.message ??
        context.t(
          'splash.preparingWorkspace',
          fallback: 'Preparando seu espaço...',
        );
    final String footer = context.t(
      'splash.connectedTagline',
      fallback: 'Tudo conectado. Tudo sob controle.',
    );
    final String supportingMessage = widget.supportingMessage?.trim() ?? '';
    final Color baseColor =
        useCurrentTheme ? colors.background : _SixoAppSplashColors.navy950;
    final bool navigationBarIsDark =
        ThemeData.estimateBrightnessForColor(baseColor) == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: baseColor,
        systemNavigationBarDividerColor: baseColor,
        systemNavigationBarIconBrightness:
            navigationBarIsDark ? Brightness.light : Brightness.dark,
      ),
      child: ColoredBox(
        key: const ValueKey<String>('sixoapp-mobile-loading-background'),
        color: baseColor,
        child: Semantics(
          container: true,
          liveRegion: true,
          label: widget.semanticLabel ?? 'SixoApp. $message',
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _entryController,
                _loopController,
              ]),
              builder: (BuildContext context, Widget? child) {
                final double entry = Curves.easeOutCubic.transform(
                  _entryController.value,
                );
                final double progress = _loopController.value;
                if (useCurrentTheme) {
                  return _buildThemedScene(
                    colors: colors,
                    entry: entry,
                    progress: progress,
                    message: message,
                    supportingMessage: supportingMessage,
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.08),
                          radius: 1.05,
                          colors: <Color>[
                            _SixoAppSplashColors.navy800,
                            _SixoAppSplashColors.navy920,
                            _SixoAppSplashColors.navy950,
                          ],
                          stops: <double>[0, 0.52, 1],
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _SixoAppSplashBackgroundPainter(
                          progress: progress,
                          reduceMotion: _reduceMotion,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          final bool compact = constraints.maxHeight < 670;
                          final double logoSize = math.min(
                            constraints.maxWidth * (compact ? 0.54 : 0.62),
                            compact ? 210.0 : 272.0,
                          );
                          final double titleSize =
                              (constraints.maxWidth * 0.105)
                                  .clamp(36.0, 48.0)
                                  .toDouble();

                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              compact ? 18 : 28,
                              24,
                              compact ? 20 : 30,
                            ),
                            child: Column(
                              children: <Widget>[
                                const Spacer(flex: 5),
                                Opacity(
                                  opacity: entry,
                                  child: Transform.scale(
                                    scale:
                                        (0.92 + (entry * 0.08)) *
                                        (_reduceMotion
                                            ? 1.0
                                            : 1.0 +
                                                (math.sin(
                                                      progress * math.pi * 2,
                                                    ) *
                                                    0.008)),
                                    child: _SixoAppAnimatedSymbol(
                                      size: logoSize,
                                      progress: progress,
                                      reduceMotion: _reduceMotion,
                                    ),
                                  ),
                                ),
                                SizedBox(height: compact ? 12 : 18),
                                Opacity(
                                  opacity: entry,
                                  child: Text(
                                    'SixoApp',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: SixMobilePalette.onPrimary,
                                      fontSize: titleSize,
                                      height: 1,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.4,
                                    ),
                                  ),
                                ),
                                SizedBox(height: compact ? 20 : 28),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _SixoAppSplashColors.supportingText,
                                    fontSize: compact ? 15 : 17,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: compact ? 18 : 24),
                                _SixoAppSweepProgress(
                                  progress: progress,
                                  reduceMotion: _reduceMotion,
                                ),
                                const Spacer(flex: 4),
                                Text(
                                  footer,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _SixoAppSplashColors.footerText,
                                    fontSize: compact ? 12 : 14,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemedScene({
    required SixMobileColorScheme colors,
    required double entry,
    required double progress,
    required String message,
    required String supportingMessage,
  }) {
    return SixMobileAnimatedGradientBackground(
      enabled: !_reduceMotion,
      intensity: 0.26,
      baseColor: colors.background,
      primaryColor: colors.primary,
      secondaryColor: colors.secondary,
      accentColor: colors.accent,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxHeight < 620;
            final double logoSize =
                (constraints.maxWidth * 0.30)
                    .clamp(compact ? 88.0 : 96.0, compact ? 112.0 : 128.0)
                    .toDouble();
            final double pulse =
                _reduceMotion
                    ? 1
                    : 1 + (math.sin(progress * math.pi * 2) * 0.018);

            return Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Opacity(
                  opacity: entry,
                  child: Transform.translate(
                    offset: Offset(0, (1 - entry) * 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Transform.scale(
                          scale: (0.94 + (entry * 0.06)) * pulse,
                          child: _SixoAppAnimatedSymbol(
                            size: logoSize,
                            progress: progress,
                            reduceMotion: _reduceMotion,
                            enableSweep: false,
                          ),
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.mutedText,
                              fontSize: compact ? 14 : 15,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (supportingMessage.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              supportingMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.mutedText.withValues(alpha: 0.82),
                                fontSize: compact ? 12 : 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SixoAppAnimatedSymbol extends StatelessWidget {
  const _SixoAppAnimatedSymbol({
    super.key,
    required this.size,
    required this.progress,
    required this.reduceMotion,
    this.enableSweep = true,
  });

  final double size;
  final double progress;
  final bool reduceMotion;
  final bool enableSweep;

  @override
  Widget build(BuildContext context) {
    final Widget symbol = Image.asset(
      'assets/images/sixoapp_splash_symbol.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  _SixoAppSplashColors.electricBlue.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
                stops: const <double>[0, 0.72],
              ),
            ),
          ),
          symbol,
          if (!reduceMotion && enableSweep)
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                final double center = -1.45 + (progress * 2.9);
                return LinearGradient(
                  begin: Alignment(center - 0.45, -1),
                  end: Alignment(center + 0.45, 1),
                  colors: const <Color>[
                    Colors.transparent,
                    Color(0xD9FFFFFF),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.36, 0.5, 0.64],
                ).createShader(bounds);
              },
              child: Image.asset(
                'assets/images/sixoapp_splash_symbol.png',
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

class _SixoAppSweepProgress extends StatelessWidget {
  const _SixoAppSweepProgress({
    required this.progress,
    required this.reduceMotion,
    this.trackColor = _SixoAppSplashColors.progressTrack,
    this.startColor = _SixoAppSplashColors.cyan,
    this.endColor = _SixoAppSplashColors.electricBlue,
    this.glowColor = const Color(0x8010D9F0),
  });

  final double progress;
  final bool reduceMotion;
  final Color trackColor;
  final Color startColor;
  final Color endColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 224,
      height: 5,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double segmentWidth = constraints.maxWidth * 0.30;
          final double left =
              (reduceMotion ? 0.35 : progress) *
              (constraints.maxWidth - segmentWidth);
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: left,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: <Color>[startColor, endColor],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: glowColor, blurRadius: 9),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SixoAppSplashBackgroundPainter extends CustomPainter {
  const _SixoAppSplashBackgroundPainter({
    required this.progress,
    required this.reduceMotion,
  });

  final double progress;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final double phase = reduceMotion ? 0.32 : progress;
    final Paint arcPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _SixoAppSplashColors.electricBlue.withValues(alpha: 0.13);

    final Path upperArc =
        Path()
          ..moveTo(-size.width * 0.08, size.height * 0.29)
          ..quadraticBezierTo(
            size.width * 0.38,
            -size.height * 0.07,
            size.width * 1.05,
            size.height * 0.17,
          );
    canvas.drawPath(upperArc, arcPaint);

    for (int index = 0; index < 4; index++) {
      final double y = size.height * (0.73 + (index * 0.035));
      final double amplitude = size.height * (0.032 + (index * 0.004));
      final double drift = math.sin((phase + index * 0.16) * math.pi * 2) * 8;
      final Path wave =
          Path()
            ..moveTo(-size.width * 0.08, y + drift)
            ..cubicTo(
              size.width * 0.18,
              y - amplitude,
              size.width * 0.31,
              y + amplitude,
              size.width * 0.50,
              y,
            )
            ..cubicTo(
              size.width * 0.70,
              y - amplitude,
              size.width * 0.82,
              y + amplitude,
              size.width * 1.08,
              y - (amplitude * 0.35),
            );
      canvas.drawPath(
        wave,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == 0 ? 1.2 : 0.7
          ..color = _SixoAppSplashColors.electricBlue.withValues(
            alpha: index == 0 ? 0.28 : 0.12,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SixoAppSplashBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}

abstract final class _SixoAppSplashColors {
  const _SixoAppSplashColors._();

  static const Color navy950 = Color(0xFF00163A);
  static const Color navy920 = Color(0xFF021D48);
  static const Color navy800 = Color(0xFF063071);
  static const Color cyan = Color(0xFF10D9F0);
  static const Color electricBlue = Color(0xFF145BFF);
  static const Color supportingText = Color(0xFFA8C6EE);
  static const Color footerText = Color(0xFF8FB2E3);
  static const Color progressTrack = Color(0xFF082754);
}
