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
    with TickerProviderStateMixin {
  static const Duration _minimumDuration = Duration(seconds: 3);

  /// Gradiente de fundo — deslocamento lento, quase imperceptível (10 s).
  late final AnimationController _bgController;

  /// Halo respirando atrás do logo (5 s).
  late final AnimationController _haloController;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);

    _prepareSessionAndNavigate();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _haloController.dispose();
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
          final isCompact = constraints.maxWidth < 640;
          final logoSize = _clamp(
            isCompact ? constraints.maxWidth * 0.38 : 200,
            108,
            isCompact ? 156 : 210,
          );

          return AnimatedBuilder(
            animation: Listenable.merge([_bgController, _haloController]),
            builder: (context, _) {
              final bgT = _bgController.value;
              final haloT = _haloController.value;

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  // Gradiente com deslocamento muito sutil — quase imperceptível.
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + bgT * 0.12, -1.0),
                    end: Alignment(1.0, 1.0 - bgT * 0.08),
                    colors: <Color>[
                      Color.lerp(
                        _SplashPalette.navy950,
                        _SplashPalette.navy900,
                        bgT * 0.5,
                      )!,
                      Color.lerp(
                        _SplashPalette.navy900,
                        _SplashPalette.blue900,
                        bgT * 0.4,
                      )!,
                      Color.lerp(
                        _SplashPalette.blue800,
                        _SplashPalette.navy950,
                        bgT * 0.3,
                      )!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 20.0 : 40.0,
                        vertical: 28,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? 360.0 : 480.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo com halo respirando.
                            _SixLogoWithHalo(
                              size: logoSize,
                              haloProgress: haloT,
                            ),
                            SizedBox(height: isCompact ? 36 : 48),
                            // Seis pontos acendendo em sequência.
                            _SixSequentialDots(compact: isCompact),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                            duration: 540.ms,
                            curve: Curves.easeOut,
                          )
                          .slideY(
                            begin: 0.04,
                            end: 0,
                            duration: 660.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  double _clamp(double value, double min, double max) =>
      value.clamp(min, max).toDouble();
}

// ---------------------------------------------------------------------------
// Logo com halo
// ---------------------------------------------------------------------------

class _SixLogoWithHalo extends StatelessWidget {
  const _SixLogoWithHalo({
    required this.size,
    required this.haloProgress,
  });

  final double size;

  /// Valor 0..1 do AnimationController de halo (reverse: true).
  final double haloProgress;

  @override
  Widget build(BuildContext context) {
    // Halo: scale entre 1.18 e 1.56, opacidade entre 0.08 e 0.22.
    final haloScale = 1.18 + haloProgress * 0.38;
    final haloOpacity = 0.08 + haloProgress * 0.14;

    return SizedBox(
      width: size * 1.8,
      height: size * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo externo — respira devagar.
          Container(
            width: size * haloScale,
            height: size * haloScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(haloOpacity),
                  Colors.white.withOpacity(haloOpacity * 0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Logo — círculo branco, fade-in na entrada.
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.14),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
                const BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 36,
                  offset: Offset(0, 16),
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
              .fadeIn(duration: 600.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.90, 0.90),
                end: const Offset(1, 1),
                duration: 720.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seis pontos acendendo em sequência
// ---------------------------------------------------------------------------

class _SixSequentialDots extends StatefulWidget {
  const _SixSequentialDots({required this.compact});

  final bool compact;

  @override
  State<_SixSequentialDots> createState() => _SixSequentialDotsState();
}

class _SixSequentialDotsState extends State<_SixSequentialDots>
    with SingleTickerProviderStateMixin {
  // Um único controller para toda a sequência de 6 pontos.
  // Cada ponto tem janela de 1/6 do ciclo.
  late final AnimationController _ctrl;

  static const int _dotCount = 6;
  static const Duration _cycleDuration = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _cycleDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.compact ? 7.0 : 8.0;
    final spacing = widget.compact ? 9.0 : 11.0;

    return Semantics(
      label: 'Carregando',
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_dotCount, (index) {
              // Cada ponto ocupa 1/_dotCount do ciclo.
              // A "janela ativa" de cada ponto dura 40% do ciclo,
              // centrada em sua posição.
              const window = 1.0 / _dotCount;
              final center = window * (index + 0.5);
              final distance = _circularDistance(_ctrl.value, center);
              // Pico quando distance == 0, cai à medida que se afasta.
              final brightness = _clamp(1.0 - distance / (window * 1.2), 0, 1);
              final opacity = 0.22 + brightness * 0.76;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(opacity),
                    boxShadow: brightness > 0.5
                        ? [
                            BoxShadow(
                              color: Colors.white
                                  .withOpacity(brightness * 0.28),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// Distância circular normalizada entre dois valores 0..1.
  double _circularDistance(double a, double b) {
    final diff = (a - b).abs();
    return diff > 0.5 ? 1.0 - diff : diff;
  }

  double _clamp(double v, double min, double max) =>
      v.clamp(min, max).toDouble();
}

// ---------------------------------------------------------------------------
// Paleta
// ---------------------------------------------------------------------------

class _SplashPalette {
  const _SplashPalette._();

  static const Color navy950 = Color(0xFF03111F);
  static const Color navy900 = Color(0xFF06243A);
  static const Color blue900 = Color(0xFF0A3555);
  static const Color blue800 = Color(0xFF0F4C75);
}


