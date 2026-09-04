import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/helpers/six_color_contrast.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/app_modal_side_sheet.dart';
import 'package:sixpos/presentation/components/six_mobile_animated_gradient_background.dart';

typedef SixMobileBodyBuilder =
    Widget Function(
      BuildContext context,
      ScrollController scrollController,
      double topInset,
    );
typedef SixMobileBackgroundBuilder =
    Widget Function(BuildContext context, Widget child);

class SixMobilePageShell extends StatefulWidget {
  const SixMobilePageShell({
    super.key,
    required this.title,
    required this.bodyBuilder,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.drawer,
    this.leading,
    this.actions = const <Widget>[],
    this.bottomNavigationBar,
    this.titleTextStyle,
    this.scrollController,
    this.backgroundBuilder,
    this.toolbarHeight = 52,
    this.initialContentSpacing = 8,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.enableAnimatedBackground = true,
    this.enableAppBarBlur = true,
    this.backgroundIntensity = 0.80,
    this.scrolledSurfaceOpacity = 0.72,
    this.maxBlurSigma = 16,
    this.scrollEffectOffset = 32,
    this.appBarAnimationDuration = const Duration(milliseconds: 260),
    this.appBarAnimationCurve = Curves.easeOutCubic,
    this.onScrollProgressChanged,
  });

  final String title;
  final Widget? drawer;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;
  final TextStyle? titleTextStyle;
  final ScrollController? scrollController;
  final SixMobileBodyBuilder bodyBuilder;
  final SixMobileBackgroundBuilder? backgroundBuilder;
  final ValueChanged<double>? onScrollProgressChanged;
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final double toolbarHeight;
  final double initialContentSpacing;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final bool enableAnimatedBackground;
  final bool enableAppBarBlur;
  final double backgroundIntensity;
  final double scrolledSurfaceOpacity;
  final double maxBlurSigma;
  final double scrollEffectOffset;
  final Duration appBarAnimationDuration;
  final Curve appBarAnimationCurve;

  @override
  State<SixMobilePageShell> createState() => _SixMobilePageShellState();
}

class _SixMobilePageShellState extends State<SixMobilePageShell> {
  final ValueNotifier<double> _scrollProgress = ValueNotifier<double>(0);
  ScrollController? _internalScrollController;
  late ScrollController _activeScrollController;

  @override
  void initState() {
    super.initState();
    _bindScrollController(widget.scrollController);
  }

  @override
  void didUpdateWidget(covariant SixMobilePageShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scrollController != widget.scrollController) {
      _unbindScrollController(_activeScrollController);
      _bindScrollController(widget.scrollController);
    }
  }

  @override
  void dispose() {
    _unbindScrollController(_activeScrollController);
    _internalScrollController?.dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  void _bindScrollController(ScrollController? externalController) {
    _activeScrollController =
        externalController ??
        (_internalScrollController ??= ScrollController());
    _activeScrollController.addListener(_handleScrollChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleScrollChanged();
    });
  }

  void _unbindScrollController(ScrollController controller) {
    controller.removeListener(_handleScrollChanged);
  }

  void _handleScrollChanged() {
    final double offset =
        _activeScrollController.hasClients ? _activeScrollController.offset : 0;
    final double normalized = (offset / widget.scrollEffectOffset).clamp(
      0.0,
      1.0,
    );

    if ((normalized - _scrollProgress.value).abs() < 0.01 &&
        normalized != 0 &&
        normalized != 1) {
      return;
    }

    _scrollProgress.value = normalized;
    widget.onScrollProgressChanged?.call(normalized);
  }

  Color _effectiveColor({
    required BuildContext context,
    required Color configuredColor,
    required Color lightToken,
    required Color darkToken,
  }) {
    if (Theme.of(context).brightness == Brightness.dark &&
        configuredColor == lightToken) {
      return darkToken;
    }
    return configuredColor;
  }

  Color _effectiveBackgroundColor(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return _effectiveColor(
      context: context,
      configuredColor: widget.backgroundColor,
      lightToken: SixMobilePalette.backgroundLight,
      darkToken: colors.background,
    );
  }

  Color _effectivePrimaryColor(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return _effectiveColor(
      context: context,
      configuredColor: widget.primaryColor,
      lightToken: SixMobilePalette.primaryLight,
      darkToken: colors.primary,
    );
  }

  Color _effectiveSecondaryColor(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return _effectiveColor(
      context: context,
      configuredColor: widget.secondaryColor,
      lightToken: SixMobilePalette.secondaryLight,
      darkToken: colors.secondary,
    );
  }

  Color _effectiveAccentColor(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return _effectiveColor(
      context: context,
      configuredColor: widget.accentColor,
      lightToken: SixMobilePalette.accentLight,
      darkToken: colors.accent,
    );
  }

  Widget _buildBackground(BuildContext context, Widget child) {
    if (widget.backgroundBuilder != null) {
      return widget.backgroundBuilder!(context, child);
    }

    return SixMobileAnimatedGradientBackground(
      enabled: widget.enableAnimatedBackground,
      intensity: widget.backgroundIntensity,
      baseColor: _effectiveBackgroundColor(context),
      primaryColor: _effectivePrimaryColor(context),
      secondaryColor: _effectiveSecondaryColor(context),
      accentColor: _effectiveAccentColor(context),
      child: child,
    );
  }

  double _resolveTopInset(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    return statusBarHeight +
        widget.toolbarHeight +
        widget.initialContentSpacing;
  }

  double _resolveTopBarHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + widget.toolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final Color backgroundColor = _effectiveBackgroundColor(context);
    final Color primaryColor = _effectivePrimaryColor(context);
    final double topBarHeight = _resolveTopBarHeight(context);
    final Widget? leading = widget.leading ?? _buildMenuLeading(context);
    final Widget body = _buildBackground(
      context,
      widget.bodyBuilder(
        context,
        _activeScrollController,
        _resolveTopInset(context),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,
      appBar: _SixMobileScrollableAppBar(
        title: widget.title,
        leading: leading,
        actions: widget.actions,
        titleTextStyle: widget.titleTextStyle,
        centerTitle: widget.centerTitle,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        topBackgroundColor: primaryColor,
        scrollProgress: _scrollProgress,
        enableBlur: widget.enableAppBarBlur,
        maxOverlayOpacity: widget.scrolledSurfaceOpacity,
        toolbarHeight: widget.toolbarHeight,
        animationDuration: widget.appBarAnimationDuration,
        animationCurve: widget.appBarAnimationCurve,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(child: body),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBarHeight,
            child: IgnorePointer(
              child: _SixMobileTopBlurLayer(
                enabled: widget.enableAppBarBlur,
                progressListenable: _scrollProgress,
                blurSigma: widget.maxBlurSigma,
                maxOverlayOpacity: widget.scrolledSurfaceOpacity,
                overlayColor: colors.surface,
                borderColor: colors.border,
                animationDuration: widget.appBarAnimationDuration,
                animationCurve: widget.appBarAnimationCurve,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }

  Widget? _buildMenuLeading(BuildContext context) {
    final Widget? drawer = widget.drawer;
    if (drawer == null || !widget.automaticallyImplyLeading) return null;

    return IconButton(
      tooltip: 'Menu',
      icon: Icon(Icons.menu_rounded),
      onPressed: () {
        showAppModalSideSheet<void>(context: context, child: drawer);
      },
    );
  }
}

class _SixMobileScrollableAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _SixMobileScrollableAppBar({
    required this.title,
    required this.actions,
    required this.scrollProgress,
    required this.topBackgroundColor,
    required this.enableBlur,
    required this.maxOverlayOpacity,
    required this.toolbarHeight,
    required this.animationDuration,
    required this.animationCurve,
    this.leading,
    this.titleTextStyle,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final TextStyle? titleTextStyle;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Color topBackgroundColor;
  final ValueListenable<double> scrollProgress;
  final bool enableBlur;
  final double maxOverlayOpacity;
  final double toolbarHeight;
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollProgress,
      builder: (BuildContext context, double targetProgress, Widget? child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: targetProgress),
          duration: animationDuration,
          curve: animationCurve,
          builder: (
            BuildContext context,
            double animatedProgress,
            Widget? child,
          ) {
            final _AppBarVisualState visualState = _resolveVisualState(
              context: context,
              progress: animatedProgress,
            );
            final ThemeData theme = Theme.of(context);
            final TextStyle baseTitleStyle =
                theme.appBarTheme.titleTextStyle ??
                theme.textTheme.titleLarge ??
                TextStyle(fontSize: 20, fontWeight: FontWeight.w700);

            return AppBar(
              automaticallyImplyLeading: automaticallyImplyLeading,
              leading: leading,
              centerTitle: centerTitle,
              title: Text(
                title,
                style: baseTitleStyle
                    .copyWith(
                      color: visualState.foregroundColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    )
                    .merge(titleTextStyle),
              ),
              actions: actions,
              foregroundColor: visualState.foregroundColor,
              backgroundColor: Colors.transparent,
              toolbarHeight: toolbarHeight,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              systemOverlayStyle: visualState.systemOverlayStyle,
            );
          },
        );
      },
    );
  }

  _AppBarVisualState _resolveVisualState({
    required BuildContext context,
    required double progress,
  }) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final Color surfaceColor = colors.surface;
    final double opacity =
        enableBlur ? (maxOverlayOpacity * progress).clamp(0.0, 1.0) : 0;
    final Color effectiveBackground = Color.alphaBlend(
      surfaceColor.withValues(alpha: opacity),
      topBackgroundColor,
    );
    final Brightness estimatedBrightness = ThemeData.estimateBrightnessForColor(
      effectiveBackground,
    );
    final bool useLightForeground = estimatedBrightness == Brightness.dark;
    final Color foregroundColor = SixColorContrast.onColor(
      effectiveBackground,
      light: colors.onPrimary,
      dark: SixMobileColorScheme.light.titleText,
    );
    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          useLightForeground ? Brightness.light : Brightness.dark,
      statusBarBrightness:
          useLightForeground ? Brightness.dark : Brightness.light,
    );

    return _AppBarVisualState(
      foregroundColor: foregroundColor,
      systemOverlayStyle: overlayStyle,
    );
  }
}

class _SixMobileTopBlurLayer extends StatelessWidget {
  const _SixMobileTopBlurLayer({
    required this.enabled,
    required this.progressListenable,
    required this.blurSigma,
    required this.maxOverlayOpacity,
    required this.overlayColor,
    required this.borderColor,
    required this.animationDuration,
    required this.animationCurve,
  });

  final bool enabled;
  final ValueListenable<double> progressListenable;
  final double blurSigma;
  final double maxOverlayOpacity;
  final Color overlayColor;
  final Color borderColor;
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progressListenable,
      builder: (BuildContext context, double targetProgress, Widget? child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: targetProgress),
          duration: animationDuration,
          curve: animationCurve,
          builder: (BuildContext context, double progress, Widget? child) {
            if (!enabled || progress <= 0) {
              return SizedBox.shrink();
            }

            final double overlayOpacity = (maxOverlayOpacity * progress).clamp(
              0.0,
              1.0,
            );
            final double borderOpacity = (0.08 * progress).clamp(0.0, 0.08);

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: SizedBox.expand(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: overlayColor.withValues(alpha: overlayOpacity),
                      border: Border(
                        bottom: BorderSide(
                          color: borderColor.withValues(alpha: borderOpacity),
                          width: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AppBarVisualState {
  const _AppBarVisualState({
    required this.foregroundColor,
    required this.systemOverlayStyle,
  });

  final Color foregroundColor;
  final SystemUiOverlayStyle systemOverlayStyle;
}
