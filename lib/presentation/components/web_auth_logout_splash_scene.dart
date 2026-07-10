import 'package:flutter/material.dart';

import 'six_splash_scene.dart';

/// Splash exibido brevemente durante o logout, antes de exibir a tela de login.
/// Usa o mesmo componente visual do pós-login para consistência.
class WebAuthLogoutSplashScene extends StatelessWidget {
  const WebAuthLogoutSplashScene({super.key});

  @override
  Widget build(BuildContext context) {
    return const SixSplashScene();
  }
}
