import 'package:flutter/material.dart';
import '../components/six_web_splash_scene.dart';
import '../services/web_authenticated_bootstrap_service.dart';

class PostLoginSplashWebPage extends StatefulWidget {
  const PostLoginSplashWebPage({super.key, required this.nextRoute});

  final String nextRoute;

  @override
  State<PostLoginSplashWebPage> createState() => _PostLoginSplashWebPageState();
}

class _PostLoginSplashWebPageState extends State<PostLoginSplashWebPage> {
  static const Duration _minimumDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _prepareSessionAndNavigate();
  }

  Future<void> _prepareSessionAndNavigate() async {
    await Future.wait<void>(<Future<void>>[
      _guardedBootstrap(),
      Future<void>.delayed(_minimumDuration),
    ]);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      widget.nextRoute,
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _guardedBootstrap() async {
    try {
      await _bootstrapAuthenticatedSession();
    } catch (error, stackTrace) {
      debugPrint('Erro ao preparar sessão pós-login web: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _bootstrapAuthenticatedSession() async {
    await WebAuthenticatedBootstrapService().bootstrap(context, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SixWebSplashScene());
  }
}
