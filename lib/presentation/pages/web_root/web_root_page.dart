import 'package:sixpos/core/platform_detector.dart';
import 'package:sixpos/presentation/pages/web_root/desktop_layout.dart';
import 'package:sixpos/presentation/pages/web_root/mobile_layout.dart';
import 'package:sixpos/presentation/components/web_root/web_i18n_gate.dart';
import 'package:sixpos/presentation/pages/web_root/web_root_provider.dart';
import 'package:sixpos/presentation/screens/login_page_web.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Container raiz da rota "/" em ambiente web.
//
// Responsabilidades:
//   1. Gate kIsWeb — em não-web, mostra placeholder (a rota nem deveria ser
//      atingida porque main.dart só registra onGenerateRoute em kIsWeb).
//   2. Cria/expõe um WebRootProvider local (scope curto, sem poluir o
//      MultiProvider global).
//   3. LayoutBuilder + WebRootProvider.updateFromConstraints decide entre
//      DesktopLayout e MobileLayout. O provider só notifica quando o
//      *device* muda (resize dentro do mesmo bucket não causa rebuild).
class WebRootPage extends StatelessWidget {
  const WebRootPage({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isWeb) {
      // Defensive: não deve acontecer no fluxo normal (main.dart só usa
      // onGenerateRoute em kIsWeb), mas se alguém empurrar essa rota em
      // mobile nativo, falhamos de forma legível em vez de quebrar layout.
      return const _NonWebFallback();
    }

    // O conteúdo da landing depende das traduções do backend; o gate só o
    // constrói quando as mensagens do locale corrente estão carregadas.
    return WebI18nGate(
      builder: (context) => ChangeNotifierProvider<WebRootProvider>(
      create: (_) => WebRootProvider(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Side-effect: atualiza o provider DEPOIS deste frame para evitar
          // chamar notifyListeners durante build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context
                .read<WebRootProvider>()
                .updateFromConstraints(constraints);
          });

          // Decisão imediata baseada em width — o provider serve para que
          // consumers internos saibam o device sem precisar refazer o cálculo.
          final isDesktop =
              PlatformDetector.isDesktopWidth(constraints.maxWidth);

          return isDesktop
              ? DesktopLayout(
                  onLogin: () => _goLogin(context),
                  onSignup: () => _goLogin(context),
                  onChoosePlan: (_) => _goLogin(context),
                )
              : MobileLayout(
                  onSignup: () => _goLogin(context),
                  onChoosePlan: (_) => _goLogin(context),
                );
        },
      ),
      ),
    );
  }

  void _goLogin(BuildContext context) {
    Navigator.of(context).pushNamed('/login');
  }
}

class _NonWebFallback extends StatelessWidget {
  const _NonWebFallback();

  @override
  Widget build(BuildContext context) {
    // Em mobile nativo redirecionamos pro fluxo existente — manter
    // consistência com hasSeenOnboarding seria responsabilidade do main.dart.
    return const LoginPageWeb();
  }
}
