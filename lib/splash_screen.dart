import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_mobile_loading_scene.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _splashDuration = Duration(milliseconds: 1600);
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(_splashDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => _resolveNextPage()),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  Widget _resolveNextPage() {
    if (kIsWeb) {
      return LoginPageWeb();
    }

    return widget.hasSeenOnboarding ? AuthGateMobile() : OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(body: SixWebSplashScene());
    }

    return Scaffold(body: SixoAppMobileLoadingScene());
  }
}
