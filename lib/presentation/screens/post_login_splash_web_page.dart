import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../../domain/services/aparencia/aparencia_service.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../domain/services/telainicial_web/tela_inicial_web_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';

class PostLoginSplashWebPage extends StatefulWidget {
  const PostLoginSplashWebPage({
    super.key,
    required this.nextRoute,
  });

  final String nextRoute;

  @override
  State<PostLoginSplashWebPage> createState() => _PostLoginSplashWebPageState();
}

class _PostLoginSplashWebPageState extends State<PostLoginSplashWebPage>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumDuration = Duration(seconds: 3);

  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _prepareSessionAndNavigate();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _prepareSessionAndNavigate() async {
    await Future.wait<void>([
      _guardedBootstrap(),
      Future<void>.delayed(_minimumDuration),
    ]);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      widget.nextRoute,
      (route) => false,
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
    final idiomaDePreferencia =
        await UsuarioService().buscarDadosDoUsuario_atualizaProviders();

    if (!mounted) return;
    await context
        .read<ColaboradorAutorizacoesProvider>()
        .carregarAutorizacoesDoUsuarioLogado(force: true);

    try {
      final regionalizacaoService = RegionalizacaoService(
        apiClient: HttpRegionalizacaoApiClient(),
      );
      final regionalizacao = await regionalizacaoService.buscarRegionalizacao();
      if (!mounted) return;
      await context.read<LocaleSettingsProvider>().applyAuthenticatedLocale(
            idiomaDePreferencia: idiomaDePreferencia,
            regionalizacao: regionalizacao,
          );
    } catch (e) {
      debugPrint('Erro ao aplicar idioma/regionalização no login: $e');
    }

    try {
      final aparenciaService = AparenciaService(
        apiClient: HttpAparenciaApiClient(),
      );
      final config = await aparenciaService.buscarAparencia();
      SixThemeResolver().atualizarConfiguracao(config);
    } catch (e) {
      debugPrint('Erro ao carregar aparência no login: $e');
    }

    await TelaInicialWebService().atualizaProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = width < 640;
          final horizontalPadding = isCompact ? 20.0 : 40.0;
          final logoSize = _clampDouble(
            isCompact ? width * 0.42 : 210,
            118,
            isCompact ? 168 : 220,
          );
          final panelPadding = isCompact ? 28.0 : 44.0;
          final panelMaxWidth = isCompact ? 400.0 : 520.0;
          final backgroundMarkSize = _clampDouble(
            isCompact ? width * 0.84 : width * 0.26,
            isCompact ? 210 : 260,
            isCompact ? 360 : 460,
          );

          return AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, _) {
              final progress = _backgroundController.value;

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + progress * 0.42, -1),
                    end: Alignment(1, 1 - progress * 0.34),
                    colors: <Color>[
                      Color.lerp(
                        _SplashPalette.navy950,
                        _SplashPalette.navy900,
                        progress,
                      )!,
                      Color.lerp(
                        _SplashPalette.navy900,
                        _SplashPalette.blue900,
                        progress,
                      )!,
                      Color.lerp(
                        _SplashPalette.blue800,
                        _SplashPalette.navy950,
                        progress,
                      )!,
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SixSplashBackgroundPainter(
                          progress: progress,
                          compact: isCompact,
                        ),
                      ),
                    ),
                    _SplashBackgroundWatermark(
                      size: backgroundMarkSize,
                      progress: progress,
                      opacity: 0.10,
                    ),
                    _GlowOrb(
                      diameter: isCompact ? 210 : 360,
                      left: -60 + progress * 28,
                      top: isCompact ? 48 : 86,
                      opacity: 0.24,
                    ),
                    _GlowOrb(
                      diameter: isCompact ? 180 : 300,
                      right: -72 + progress * 34,
                      bottom: isCompact ? 70 : 86,
                      opacity: 0.18,
                    ),
                    Positioned(
                      right: isCompact ? -46 : -34,
                      bottom: isCompact ? 20 : -70,
                      child: IgnorePointer(
                        child: Text(
                          '6',
                          style: TextStyle(
                            color: Colors.white.withOpacity(
                              isCompact ? 0.05 : 0.06,
                            ),
                            fontSize: isCompact ? 260 : 460,
                            fontWeight: FontWeight.w900,
                            height: 0.86,
                            letterSpacing: -28,
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 28,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: panelMaxWidth),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 28 : 36,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 56,
                                    offset: Offset(0, 28),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(panelPadding),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _SixLogoConstellation(
                                      size: logoSize,
                                      progress: progress,
                                    ),
                                    SizedBox(height: isCompact ? 30 : 38),
                                    _SixProgressDots(compact: isCompact),
                                  ],
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 520.ms, curve: Curves.easeOut)
                                .slideY(
                                  begin: 0.045,
                                  end: 0,
                                  duration: 640.ms,
                                  curve: Curves.easeOutCubic,
                                ),
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
      ),
    );
  }

  double _clampDouble(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}

class _SplashBackgroundWatermark extends StatelessWidget {
  const _SplashBackgroundWatermark({
    required this.size,
    required this.progress,
    required this.opacity,
  });

  final double size;
  final double progress;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0.05, -0.02),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: 1.9,
              child: _SixLogoConstellation(
                size: size,
                progress: progress,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SixLogoConstellation extends StatelessWidget {
  const _SixLogoConstellation({
    required this.size,
    required this.progress,
  });

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final orbitRadius = size * 0.64;
    final dotSize = _clamp(size * 0.055, 6, 10);

    return SizedBox(
      width: size * 1.72,
      height: size * 1.72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 1.34,
            height: size * 1.34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.24),
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.00),
                ],
              ),
            ),
          ),
          for (int index = 0; index < 6; index++)
            Transform.translate(
              offset: Offset.fromDirection(
                (math.pi * 2 * index / 6) + (progress * math.pi * 0.22),
                orbitRadius,
              ),
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(index.isEven ? 0.82 : 0.52),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.34),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                    delay: (index * 90).ms,
                  )
                  .scale(
                    begin: const Offset(0.74, 0.74),
                    end: const Offset(1.16, 1.16),
                    duration: 860.ms,
                    curve: Curves.easeInOut,
                  ),
            ),
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.84),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/six-logo-flecha.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          )
              .animate()
              .fadeIn(duration: 620.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.88, 0.88),
                end: const Offset(1, 1),
                duration: 820.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }

  double _clamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}

class _SixProgressDots extends StatelessWidget {
  const _SixProgressDots({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dotSize = compact ? 7.0 : 8.0;

    return Semantics(
      label: 'Six',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: compact ? 8 : 10,
        runSpacing: 8,
        children: List.generate(6, (index) {
          return Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.26),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
                delay: (index * 110).ms,
              )
              .scale(
                begin: const Offset(0.74, 1),
                end: Offset(index == 5 ? 2.2 : 1.45, 1),
                duration: 760.ms,
                curve: Curves.easeInOutCubic,
              )
              .fade(
                begin: 0.42,
                end: 1,
                duration: 760.ms,
                curve: Curves.easeInOut,
              );
        }),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.diameter,
    required this.opacity,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  final double diameter;
  final double opacity;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(opacity),
                _SplashPalette.blue600.withOpacity(opacity * 0.44),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SixSplashBackgroundPainter extends CustomPainter {
  const _SixSplashBackgroundPainter({
    required this.progress,
    required this.compact,
  });

  final double progress;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 0.8 : 1.1;

    for (int index = 0; index < 6; index++) {
      final dx = size.width * (0.12 + index * 0.16) +
          math.sin(progress * math.pi + index) * 12;
      final dy = size.height * (index.isEven ? 0.20 : 0.72) +
          math.cos(progress * math.pi + index) * 18;
      final radius = (compact ? 36.0 : 58.0) + index * (compact ? 8 : 12);
      strokePaint.color = Colors.white.withOpacity(0.030 + index * 0.006);
      canvas.drawCircle(Offset(dx, dy), radius, strokePaint);
    }

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.1 : 1.4
      ..color = Colors.white.withOpacity(0.07);

    final wave = Path();
    final baseY = size.height * (compact ? 0.66 : 0.58);
    for (double x = -20; x <= size.width + 20; x += 18) {
      final y = baseY +
          math.sin((x / 96) + progress * math.pi * 2) * (compact ? 10 : 16);
      if (x == -20) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }
    canvas.drawPath(wave, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _SixSplashBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.compact != compact;
  }
}

class _SplashPalette {
  const _SplashPalette._();

  static const Color navy950 = Color(0xFF03111F);
  static const Color navy900 = Color(0xFF06243A);
  static const Color blue900 = Color(0xFF0A3555);
  static const Color blue800 = Color(0xFF0F4C75);
  static const Color blue600 = Color(0xFF2B8FDB);
}
