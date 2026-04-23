import 'package:flutter/material.dart';

import '../components/web_auth_shell.dart';
import 'login_page_web.dart';

class ContaCriadaWeb extends StatelessWidget {
  const ContaCriadaWeb({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPageWeb()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: false,
      child: WebAuthShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _SuccessIllustration(primary: primary)),
            const SizedBox(height: 32),
            const WebAuthTitle(
              title: 'Tudo certo!',
              subtitle:
                  'Sua conta foi criada com sucesso. Faça login para começar a usar o Six.',
            ),
            const SizedBox(height: 32),
            WebAuthPrimaryButton(
              label: 'Ir para o login',
              onPressed: () => _goToLogin(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessIllustration extends StatefulWidget {
  final Color primary;

  const _SuccessIllustration({required this.primary});

  @override
  State<_SuccessIllustration> createState() => _SuccessIllustrationState();
}

class _SuccessIllustrationState extends State<_SuccessIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;

    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.5 + 0.10 * t,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08 - 0.05 * t),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.3 + 0.06 * t,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12 - 0.05 * t),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.0 + 0.03 * t,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25 + 0.10 * t),
                        blurRadius: 20 + 8 * t,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 56,
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
