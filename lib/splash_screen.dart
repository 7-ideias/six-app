import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/six_web_splash_scene.dart';
import 'package:sixpos/presentation/screens/auth_gate_mobile.dart';
import 'package:sixpos/presentation/screens/login_page_web.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _splashDuration = Duration(milliseconds: 1600);
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      return;
    }

    _navTimer = Timer(_splashDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => LoginPageWeb()),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(body: SixWebSplashScene());
    }

    return const AuthGateMobile();
  }
}
