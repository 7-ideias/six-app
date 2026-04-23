import 'package:flutter/material.dart';

import 'login_mobile.dart';

class ContaCriadaMobile extends StatelessWidget {
  const ContaCriadaMobile({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPageMobile()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const labelGrey = Color(0xFF8A8F8D);
    const textDark = Color(0xFF1A1A1A);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── Ilustração ────────────────────────────────────────
                _SuccessIllustration(primary: primary),

                const SizedBox(height: 40),

                // ── Título ────────────────────────────────────────────
                const Text(
                  'Tudo certo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Subtítulo ─────────────────────────────────────────
                const Text(
                  'Sua conta foi criada com sucesso.\nFaça login para começar a usar o Six.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: labelGrey,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 4),

                // ── Botão ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _goToLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ir para o login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ilustração de sucesso (check com halo + sparkles) ──────────────────────
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
          final t = _pulse.value; // 0..1
          return Stack(
            alignment: Alignment.center,
            children: [
              // Halo externo — escala maior + fade mais forte
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
              // Halo interno
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
              // Círculo principal — breathing sutil
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
              // Sparkles estáticos
              Positioned(
                top: 16,
                left: 24,
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: primary.withValues(alpha: 0.55),
                ),
              ),
              Positioned(
                top: 36,
                right: 18,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: primary.withValues(alpha: 0.4),
                ),
              ),
              Positioned(
                bottom: 28,
                left: 18,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: primary.withValues(alpha: 0.4),
                ),
              ),
              Positioned(
                bottom: 14,
                right: 30,
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: primary.withValues(alpha: 0.55),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
