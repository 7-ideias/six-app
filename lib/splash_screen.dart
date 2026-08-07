import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/core/constants/six_animation_assets.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/six_web_splash_scene.dart';
import 'package:sixpos/presentation/screens/auth_gate_mobile.dart';
import 'package:sixpos/presentation/screens/login_page_web.dart';
import 'package:sixpos/presentation/screens/on_boarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.hasSeenOnboarding = true});

  final bool hasSeenOnboarding;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _splashDuration = Duration(seconds: 3);
  static const Duration _frameFadeDuration = Duration(milliseconds: 260);

  late final AnimationController _frameController;
  late final Animation<double> _sceneOpacity;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _frameController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();

    _sceneOpacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 16,
      ),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 72),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 12,
      ),
    ]).animate(_frameController);

    _navTimer = Timer(_splashDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => _resolveNextPage()),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in SixAnimationAssets.splashFrames) {
      unawaited(precacheImage(AssetImage(asset), context));
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _frameController.dispose();
    super.dispose();
  }

  Widget _resolveNextPage() {
    if (kIsWeb) {
      return const LoginPageWeb();
    }

    return widget.hasSeenOnboarding
        ? const AuthGateMobile()
        : OnboardingScreen();
  }

  int _currentFrameIndex() {
    final index =
        (_frameController.value * SixAnimationAssets.splashFrames.length)
            .floor();
    return index.clamp(0, SixAnimationAssets.splashFrames.length - 1).toInt();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(
        body: SixWebSplashScene(subtitle: 'Preparando sua experiência web...'),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: SixMobilePalette.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SixMobilePalette.surface,
        body: Semantics(
          container: true,
          image: true,
          label: 'SixApp',
          child: AnimatedBuilder(
            animation: _frameController,
            builder: (context, _) {
              final frameAsset =
                  SixAnimationAssets.splashFrames[reduceMotion
                      ? 0
                      : _currentFrameIndex()];

              return Opacity(
                opacity: reduceMotion ? 1 : _sceneOpacity.value,
                child: AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : _frameFadeDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: LayoutBuilder(
                    key: ValueKey<String>(frameAsset),
                    builder: (context, constraints) {
                      final aspectRatio =
                          constraints.maxHeight == 0
                              ? 0.56
                              : constraints.maxWidth / constraints.maxHeight;
                      final fit =
                          aspectRatio > 0.68 ? BoxFit.contain : BoxFit.cover;

                      return Image.asset(
                        frameAsset,
                        width: double.infinity,
                        height: double.infinity,
                        fit: fit,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
