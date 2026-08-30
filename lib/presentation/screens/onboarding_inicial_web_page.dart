import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/empresa_service.dart';
import '../../data/models/onboarding_inicial_model.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/onboarding_inicial_provider.dart';
import '../theme/web_theme_tokens.dart';

const Color _brandNavy = Color(0xFF061D4B);
const Color _brandBlue = Color(0xFF1647D8);
const Color _brandCyan = Color(0xFF12D5E8);

class OnboardingInicialWebPage extends StatefulWidget {
  const OnboardingInicialWebPage({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<OnboardingInicialWebPage> createState() =>
      _OnboardingInicialWebPageState();
}

class _OnboardingInicialWebPageState extends State<OnboardingInicialWebPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();

  bool _initialized = false;
  int _step = 0;
  String _idioma = 'pt-BR';
  bool _realizaVendas = false;
  bool _prestaServicos = false;
  String? _errorKey;

  Duration get _transitionDuration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 260);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final OnboardingInicialModel? estado = context
        .read<OnboardingInicialProvider>()
        .estado;
    if (estado == null) return;
    _initialized = true;
    _nomeController.text = estado.nomeUsuario;
    _empresaController.text = estado.nomeEmpresa;
    _idioma = _normalizarIdioma(
      estado.idiomaPreferencial,
      context.read<LocaleSettingsProvider>().currentLocale,
    );
    _realizaVendas = estado.realizaVendas;
    _prestaServicos = estado.prestaServicosTecnicos;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final OnboardingInicialProvider provider = context
        .watch<OnboardingInicialProvider>();
    final OnboardingInicialModel? estado = provider.estado;
    if (estado == null) return const SizedBox.shrink();

    final int totalSteps = estado.podeConfigurarEmpresa ? 2 : 1;
    final bool finalStep = _step == totalSteps - 1;

    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _OnboardingWebBackdrop(tokens: tokens)),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 900;
                final double horizontalPadding = compact ? 18 : 32;
                final double targetHeight = (constraints.maxHeight - 64)
                    .clamp(610.0, 720.0)
                    .toDouble();

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: compact ? 18 : 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: compact ? 0 : targetHeight,
                        ),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(compact ? 26 : 32),
                          border: Border.all(
                            color: tokens.cardBorder.withValues(alpha: 0.82),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: _brandNavy.withValues(alpha: 0.15),
                              blurRadius: 54,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: compact
                            ? Column(
                                children: <Widget>[
                                  const _OnboardingWebCompactBrand(),
                                  _buildFormPanel(
                                    context,
                                    estado,
                                    totalSteps,
                                    finalStep,
                                    provider.salvando,
                                    compact: true,
                                  ),
                                ],
                              )
                            : IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    SizedBox(
                                      width: math.min(
                                        410.0,
                                        constraints.maxWidth * 0.38,
                                      ),
                                      child: _OnboardingWebBrandPanel(
                                        step: _step,
                                        realizaVendas: _realizaVendas,
                                        prestaServicos: _prestaServicos,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildFormPanel(
                                        context,
                                        estado,
                                        totalSteps,
                                        finalStep,
                                        provider.salvando,
                                        compact: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(
    BuildContext context,
    OnboardingInicialModel estado,
    int totalSteps,
    bool finalStep,
    bool saving, {
    required bool compact,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      color: tokens.surfaceElevated,
      padding: EdgeInsets.fromLTRB(
        compact ? 22 : 48,
        compact ? 24 : 38,
        compact ? 22 : 48,
        compact ? 22 : 34,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _OnboardingWebProgress(
            currentStep: _step,
            totalSteps: totalSteps,
          ),
          SizedBox(height: compact ? 28 : 40),
          AnimatedSwitcher(
            duration: _transitionDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.025, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<int>(_step),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildStepHeading(context),
                SizedBox(height: compact ? 26 : 32),
                if (_step == 0)
                  _buildIdentityStep(context, estado)
                else
                  _buildBusinessStep(context, compact: compact),
              ],
            ),
          ),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 18),
            _OnboardingWebError(
              message: context.t(
                _errorKey!,
                fallback: 'Revise as informações e tente novamente.',
              ),
            ),
          ],
          SizedBox(height: compact ? 26 : 34),
          Divider(height: 1, color: tokens.divider),
          const SizedBox(height: 22),
          _buildActions(
            context,
            estado,
            finalStep,
            saving,
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeading(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _step == 0
              ? context.t(
                  'initialOnboarding.identityTitle',
                  fallback: 'Vamos começar pelo essencial',
                )
              : context.t(
                  'initialOnboarding.businessTitle',
                  fallback: 'O que seu negócio faz?',
                ),
          style: TextStyle(
            color: tokens.primaryText,
            fontSize: 30,
            height: 1.12,
            letterSpacing: -0.7,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _step == 0
              ? context.t(
                  'initialOnboarding.identitySubtitle',
                  fallback:
                      'Confirme seus dados para personalizarmos sua experiência.',
                )
              : context.t(
                  'initialOnboarding.businessSubtitle',
                  fallback:
                      'Isso organiza seus módulos e atalhos. Você poderá alterar depois.',
                ),
          style: TextStyle(
            color: tokens.secondaryText,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityStep(
    BuildContext context,
    OnboardingInicialModel estado,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _OnboardingSectionLabel(
          icon: Icons.translate_rounded,
          title: context.t(
            'initialOnboarding.languageQuestion',
            fallback: 'Em qual idioma deseja continuar?',
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stack = constraints.maxWidth < 510;
            final List<Widget> choices = <Widget>[
              _WebLanguageChoice(
                code: 'PT',
                label: 'Português',
                selected: _idioma == 'pt-BR',
                onTap: () => _changeLanguage('pt-BR'),
              ),
              _WebLanguageChoice(
                code: 'EN',
                label: 'English',
                selected: _idioma == 'en-US',
                onTap: () => _changeLanguage('en-US'),
              ),
              _WebLanguageChoice(
                code: 'ES',
                label: 'Español',
                selected: _idioma == 'es-ES',
                onTap: () => _changeLanguage('es-ES'),
              ),
            ];
            if (stack) {
              return Column(
                children: <Widget>[
                  choices[0],
                  const SizedBox(height: 8),
                  choices[1],
                  const SizedBox(height: 8),
                  choices[2],
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: choices[0]),
                const SizedBox(width: 9),
                Expanded(child: choices[1]),
                const SizedBox(width: 9),
                Expanded(child: choices[2]),
              ],
            );
          },
        ),
        const SizedBox(height: 27),
        Row(
          children: <Widget>[
            Expanded(
              child: _OnboardingSectionLabel(
                icon: Icons.badge_outlined,
                title: context.t(
                  'initialOnboarding.yourDetails',
                  fallback: 'Seus dados',
                ),
              ),
            ),
            Text(
              context.t(
                'initialOnboarding.requiredHint',
                fallback: 'Campos obrigatórios',
              ),
              style: TextStyle(
                color: tokens.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stack = !estado.podeConfigurarEmpresa ||
                constraints.maxWidth < 620;
            final Widget nameField = _buildTextField(
              context,
              controller: _nomeController,
              label: context.t(
                'initialOnboarding.userName',
                fallback: 'Como podemos chamar você?',
              ),
              icon: Icons.person_outline_rounded,
              action: estado.podeConfigurarEmpresa
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: const <String>[AutofillHints.name],
            );
            if (!estado.podeConfigurarEmpresa) return nameField;

            final Widget companyField = _buildTextField(
              context,
              controller: _empresaController,
              label: context.t(
                'initialOnboarding.companyName',
                fallback: 'Nome do seu negócio',
              ),
              icon: Icons.storefront_outlined,
              action: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.organizationName],
            );
            if (stack) {
              return Column(
                children: <Widget>[
                  nameField,
                  const SizedBox(height: 13),
                  companyField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: nameField),
                const SizedBox(width: 13),
                Expanded(child: companyField),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputAction action,
    required Iterable<String> autofillHints,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: tokens.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofillHints: autofillHints,
          textInputAction: action,
          style: TextStyle(
            color: tokens.primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: tokens.inputBackground,
            prefixIcon: Icon(icon, color: _brandBlue, size: 21),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _brandBlue, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.danger),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessStep(
    BuildContext context, {
    required bool compact,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Widget sales = _BusinessChoiceWeb(
      icon: Icons.point_of_sale_rounded,
      accent: const Color(0xFF2563EB),
      title: context.t(
        'initialOnboarding.salesTitle',
        fallback: 'Vende produtos',
      ),
      subtitle: context.t(
        'initialOnboarding.salesSubtitle',
        fallback: 'PDV, catálogo, estoque e vendas.',
      ),
      selected: _realizaVendas,
      onTap: () => setState(() {
        _realizaVendas = !_realizaVendas;
        _errorKey = null;
      }),
    );
    final Widget services = _BusinessChoiceWeb(
      icon: Icons.home_repair_service_rounded,
      accent: const Color(0xFF7C3AED),
      title: context.t(
        'initialOnboarding.servicesTitle',
        fallback: 'Presta serviços técnicos',
      ),
      subtitle: context.t(
        'initialOnboarding.servicesSubtitle',
        fallback: 'Atendimentos, ordens de serviço e procedimentos.',
      ),
      selected: _prestaServicos,
      onTap: () => setState(() {
        _prestaServicos = !_prestaServicos;
        _errorKey = null;
      }),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: tokens.info.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.touch_app_rounded, color: tokens.info, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.t(
                    'initialOnboarding.chooseHint',
                    fallback: 'Escolha uma opção ou as duas.',
                  ),
                  style: TextStyle(
                    color: tokens.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (compact || constraints.maxWidth < 650) {
              return Column(
                children: <Widget>[
                  sales,
                  const SizedBox(height: 12),
                  services,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: sales),
                  const SizedBox(width: 14),
                  Expanded(child: services),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    OnboardingInicialModel estado,
    bool finalStep,
    bool saving, {
    required bool compact,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Widget action = _OnboardingWebPrimaryAction(
      saving: saving,
      label: finalStep
          ? context.t(
              'initialOnboarding.start',
              fallback: 'Começar a usar o SixoApp',
            )
          : context.t('common.continue', fallback: 'Continuar'),
      icon: finalStep
          ? Icons.auto_awesome_rounded
          : Icons.arrow_forward_rounded,
      onTap: finalStep ? () => _finish(estado) : () => _next(estado),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t(
              'initialOnboarding.privacyNote',
              fallback: 'Você poderá alterar essas informações depois.',
            ),
            style: TextStyle(
              color: tokens.mutedText,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: <Widget>[
              if (_step > 0) ...<Widget>[
                IconButton.outlined(
                  onPressed: saving
                      ? null
                      : () => setState(() {
                          _step -= 1;
                          _errorKey = null;
                        }),
                  tooltip: context.t('common.back', fallback: 'Voltar'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(child: action),
            ],
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        if (_step > 0)
          TextButton.icon(
            onPressed: saving
                ? null
                : () => setState(() {
                    _step -= 1;
                    _errorKey = null;
                  }),
            icon: const Icon(Icons.arrow_back_rounded, size: 19),
            label: Text(context.t('common.back', fallback: 'Voltar')),
            style: TextButton.styleFrom(
              foregroundColor: tokens.secondaryText,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            ),
          )
        else
          Expanded(
            child: Text(
              context.t(
                'initialOnboarding.privacyNote',
                fallback: 'Você poderá alterar essas informações depois.',
              ),
              style: TextStyle(
                color: tokens.mutedText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        if (_step > 0) const Spacer(),
        const SizedBox(width: 18),
        action,
      ],
    );
  }

  void _next(OnboardingInicialModel estado) {
    if (!_validateIdentity(estado)) return;
    setState(() {
      _step = 1;
      _errorKey = null;
    });
  }

  Future<void> _finish(OnboardingInicialModel estado) async {
    if (!_validateIdentity(estado)) return;
    if (estado.podeConfigurarEmpresa &&
        !_realizaVendas &&
        !_prestaServicos) {
      setState(() => _errorKey = 'initialOnboarding.activityRequired');
      return;
    }

    try {
      await context.read<OnboardingInicialProvider>().concluir(
        ConcluirOnboardingInicialRequest(
          idiomaPreferencial: _idioma,
          nomeUsuario: _nomeController.text.trim(),
          nomeEmpresa: _empresaController.text.trim(),
          realizaVendas: _realizaVendas,
          prestaServicosTecnicos: _prestaServicos,
        ),
      );
      await Future.wait<void>(<Future<void>>[
        UsuarioService().buscarDadosDoUsuario_atualizaProviders().then((_) {}),
        EmpresaService().buscarDadosDaEmpresa().then((_) {}),
      ]);
      if (!mounted) return;
      widget.onCompleted();
    } catch (_) {
      if (mounted) {
        setState(() => _errorKey = 'initialOnboarding.saveError');
      }
    }
  }

  bool _validateIdentity(OnboardingInicialModel estado) {
    if (_nomeController.text.trim().isEmpty) {
      setState(() => _errorKey = 'initialOnboarding.userNameRequired');
      return false;
    }
    if (estado.podeConfigurarEmpresa &&
        _empresaController.text.trim().isEmpty) {
      setState(() => _errorKey = 'initialOnboarding.companyNameRequired');
      return false;
    }
    return true;
  }

  Future<void> _changeLanguage(String value) async {
    setState(() {
      _idioma = value;
      _errorKey = null;
    });
    final Locale locale = switch (value) {
      'en-US' => const Locale('en', 'US'),
      'es-ES' => const Locale('es', 'ES'),
      _ => const Locale('pt', 'BR'),
    };
    await context.read<LocaleSettingsProvider>().setUserLocale(locale);
  }

  String _normalizarIdioma(String value, Locale fallback) {
    final String normalized = value.trim().toLowerCase();
    if (normalized.startsWith('en')) return 'en-US';
    if (normalized.startsWith('es')) return 'es-ES';
    if (normalized.startsWith('pt')) return 'pt-BR';
    return switch (fallback.languageCode) {
      'en' => 'en-US',
      'es' => 'es-ES',
      _ => 'pt-BR',
    };
  }
}

class _OnboardingWebBackdrop extends StatelessWidget {
  const _OnboardingWebBackdrop({required this.tokens});

  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    _brandBlue.withValues(alpha: 0.09),
                    tokens.workspaceBackground,
                    _brandCyan.withValues(alpha: 0.08),
                  ],
                  stops: const <double>[0, 0.48, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: -160,
            top: -190,
            child: _GlowOrb(
              size: 430,
              color: _brandBlue.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: -120,
            bottom: -210,
            child: _GlowOrb(
              size: 430,
              color: _brandCyan.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _OnboardingWebBrandPanel extends StatelessWidget {
  const _OnboardingWebBrandPanel({
    required this.step,
    required this.realizaVendas,
    required this.prestaServicos,
  });

  final int step;
  final bool realizaVendas;
  final bool prestaServicos;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_brandNavy, Color(0xFF0B3183), _brandBlue],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -92,
            top: -54,
            child: _GlowOrb(
              size: 250,
              color: _brandCyan.withValues(alpha: 0.13),
            ),
          ),
          Positioned(
            left: -100,
            bottom: -115,
            child: _GlowOrb(
              size: 285,
              color: Colors.white.withValues(alpha: 0.045),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 36, 38, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _OnboardingBrandLockup(),
                const SizedBox(height: 58),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  child: Column(
                    key: ValueKey<int>(step),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.13),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: _brandCyan,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              context.t(
                                'initialOnboarding.timeBadge',
                                fallback: 'Menos de 1 minuto',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step == 0
                            ? context.t(
                                'initialOnboarding.identityBenefitTitle',
                                fallback:
                                    'Seu espaço, pronto para trabalhar do seu jeito.',
                              )
                            : context.t(
                                'initialOnboarding.businessBenefitTitle',
                                fallback: 'Menos ruído. Mais do que importa.',
                              ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          height: 1.12,
                          letterSpacing: -0.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        step == 0
                            ? context.t(
                                'initialOnboarding.identityBenefitSubtitle',
                                fallback:
                                    'Idioma, perfil e empresa prontos antes da primeira tela.',
                              )
                            : context.t(
                                'initialOnboarding.businessBenefitSubtitle',
                                fallback:
                                    'Organizamos a experiência a partir da rotina real do seu negócio.',
                              ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.74),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _BrandPreviewCard(
                  step: step,
                  realizaVendas: realizaVendas,
                  prestaServicos: prestaServicos,
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: _brandCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        context.t(
                          'initialOnboarding.privacyNote',
                          fallback:
                              'Você poderá alterar essas informações depois.',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBrandLockup extends StatelessWidget {
  const _OnboardingBrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 47,
          height: 47,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset('assets/images/sixoapp_splash_symbol.png'),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'SixoApp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              context.t(
                'initialOnboarding.brandTagline',
                fallback: 'Tudo começa aqui',
              ),
              style: const TextStyle(
                color: Color(0xFF99AEDA),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OnboardingWebCompactBrand extends StatelessWidget {
  const _OnboardingWebCompactBrand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: <Color>[_brandNavy, _brandBlue]),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Image.asset('assets/images/sixoapp_splash_symbol.png'),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'SixoApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  context.t(
                    'initialOnboarding.eyebrow',
                    fallback: 'Configuração inicial',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF99AEDA),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: _brandCyan,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPreviewCard extends StatelessWidget {
  const _BrandPreviewCard({
    required this.step,
    required this.realizaVendas,
    required this.prestaServicos,
  });

  final int step;
  final bool realizaVendas;
  final bool prestaServicos;

  @override
  Widget build(BuildContext context) {
    final List<({IconData icon, String label, bool active})> items = step == 0
        ? <({IconData icon, String label, bool active})>[
            (
              icon: Icons.translate_rounded,
              label: context.t(
                'initialOnboarding.previewLanguage',
                fallback: 'Idioma preferido',
              ),
              active: true,
            ),
            (
              icon: Icons.person_outline_rounded,
              label: context.t(
                'initialOnboarding.previewProfile',
                fallback: 'Perfil pessoal',
              ),
              active: true,
            ),
            (
              icon: Icons.storefront_outlined,
              label: context.t(
                'initialOnboarding.previewCompany',
                fallback: 'Identidade da empresa',
              ),
              active: true,
            ),
          ]
        : <({IconData icon, String label, bool active})>[
            (
              icon: Icons.point_of_sale_rounded,
              label: context.t(
                'initialOnboarding.salesTitle',
                fallback: 'Vende produtos',
              ),
              active: realizaVendas,
            ),
            (
              icon: Icons.home_repair_service_rounded,
              label: context.t(
                'initialOnboarding.servicesTitle',
                fallback: 'Presta serviços técnicos',
              ),
              active: prestaServicos,
            ),
            (
              icon: Icons.auto_awesome_rounded,
              label: context.t(
                'initialOnboarding.previewPersonalized',
                fallback: 'Experiência personalizada',
              ),
              active: realizaVendas || prestaServicos,
            ),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: item.active
                            ? _brandCyan.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.active
                            ? _brandCyan
                            : Colors.white.withValues(alpha: 0.42),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: item.active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.50),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      item.active
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: item.active
                          ? _brandCyan
                          : Colors.white.withValues(alpha: 0.30),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OnboardingWebProgress extends StatelessWidget {
  const _OnboardingWebProgress({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    if (totalSteps == 1) {
      return Row(
        children: <Widget>[
          const _ProgressDot(number: 1, active: true, complete: false),
          const SizedBox(width: 10),
          Text(
            context.t(
              'initialOnboarding.identityStepLabel',
              fallback: 'Você e suas preferências',
            ),
            style: TextStyle(
              color: tokens.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        _ProgressDot(
          number: 1,
          active: currentStep == 0,
          complete: currentStep > 0,
        ),
        const SizedBox(width: 9),
        Text(
          context.t(
            'initialOnboarding.identityStepLabel',
            fallback: 'Você e sua empresa',
          ),
          style: TextStyle(
            color: currentStep == 0 ? tokens.primaryText : tokens.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: currentStep > 0 ? _brandBlue : tokens.cardBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        _ProgressDot(
          number: 2,
          active: currentStep == 1,
          complete: false,
        ),
        const SizedBox(width: 9),
        Text(
          context.t(
            'initialOnboarding.businessStepLabel',
            fallback: 'Seu negócio',
          ),
          style: TextStyle(
            color: currentStep == 1 ? tokens.primaryText : tokens.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({
    required this.number,
    required this.active,
    required this.complete,
  });

  final int number;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool highlighted = active || complete;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: highlighted ? _brandBlue : tokens.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: highlighted ? _brandBlue : tokens.cardBorder,
        ),
      ),
      alignment: Alignment.center,
      child: complete
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : Text(
              '$number',
              style: TextStyle(
                color: active ? Colors.white : tokens.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _OnboardingSectionLabel extends StatelessWidget {
  const _OnboardingSectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, color: _brandBlue, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: tokens.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _WebLanguageChoice extends StatelessWidget {
  const _WebLanguageChoice({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 170),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? _brandBlue.withValues(alpha: 0.08)
                  : tokens.inputBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _brandBlue : tokens.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 31,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _brandBlue : tokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      color: selected ? Colors.white : tokens.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _brandBlue,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessChoiceWeb extends StatelessWidget {
  const _BusinessChoiceWeb({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 190),
            constraints: const BoxConstraints(minHeight: 188),
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.075)
                  : tokens.inputBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? accent : tokens.cardBorder,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.10),
                        blurRadius: 22,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: accent, size: 27),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: selected ? accent : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? accent : tokens.mutedText,
                          width: 1.4,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 17,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: tokens.secondaryText,
                    fontSize: 13,
                    height: 1.4,
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

class _OnboardingWebPrimaryAction extends StatelessWidget {
  const _OnboardingWebPrimaryAction({
    required this.saving,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool saving;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !saving,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: saving ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: saving
                    ? const <Color>[Color(0xFF64748B), Color(0xFF94A3B8)]
                    : const <Color>[_brandNavy, _brandBlue],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: saving
                  ? const <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: _brandBlue.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (saving)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _OnboardingWebError extends StatelessWidget {
  const _OnboardingWebError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tokens.danger.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: tokens.danger.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: tokens.danger, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: tokens.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
