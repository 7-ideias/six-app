import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/empresa_service.dart';
import '../../data/models/onboarding_inicial_model.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/onboarding_inicial_provider.dart';

class OnboardingInicialMobileScreen extends StatefulWidget {
  const OnboardingInicialMobileScreen({
    super.key,
    required this.onCompleted,
  });

  final ValueChanged<BuildContext> onCompleted;

  @override
  State<OnboardingInicialMobileScreen> createState() =>
      _OnboardingInicialMobileScreenState();
}

class _OnboardingInicialMobileScreenState
    extends State<OnboardingInicialMobileScreen> {
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
      : const Duration(milliseconds: 250);

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
    final SixMobileColorScheme colors = context.sixMobileColors;
    final OnboardingInicialProvider provider = context
        .watch<OnboardingInicialProvider>();
    final OnboardingInicialModel? estado = provider.estado;
    if (estado == null) return const SizedBox.shrink();

    final int totalSteps = estado.podeConfigurarEmpresa ? 2 : 1;
    final bool finalStep = _step == totalSteps - 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SixMobilePalette.brandNavyDeep,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                SixMobilePalette.brandNavyDeep,
                SixMobilePalette.brandNavyBright,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                _buildBrandHeader(context, totalSteps),
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 28,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: _transitionDuration,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (
                              Widget child,
                              Animation<double> animation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.035, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: ListView(
                              key: ValueKey<int>(_step),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
                              children: <Widget>[
                                _buildStepHeading(context),
                                const SizedBox(height: 26),
                                if (_step == 0)
                                  _buildIdentityStep(context, estado)
                                else
                                  _buildBusinessStep(context),
                                if (_errorKey != null) ...<Widget>[
                                  const SizedBox(height: 16),
                                  _MobileOnboardingError(
                                    message: context.t(
                                      _errorKey!,
                                      fallback:
                                          'Revise as informações e tente novamente.',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        _buildActions(
                          context,
                          estado,
                          finalStep,
                          provider.salvando,
                        ),
                      ],
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

  Widget _buildBrandHeader(BuildContext context, int totalSteps) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 22),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 15,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Image.asset('assets/images/sixoapp_splash_symbol.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'SixoApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      context.t(
                        'initialOnboarding.eyebrow',
                        fallback: 'Configuração inicial',
                      ),
                      style: const TextStyle(
                        color: SixMobilePalette.brandSupportingText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  '${context.t('initialOnboarding.step', fallback: 'Etapa')} '
                  '${_step + 1} ${context.t('initialOnboarding.of', fallback: 'de')} '
                  '$totalSteps',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: List<Widget>.generate(totalSteps, (int index) {
              final bool reached = index <= _step;
              return Expanded(
                child: AnimatedContainer(
                  duration: _transitionDuration,
                  height: 5,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 7 : 0),
                  decoration: BoxDecoration(
                    color: reached
                        ? SixMobilePalette.brandCyan
                        : Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: reached
                        ? <BoxShadow>[
                            BoxShadow(
                              color: SixMobilePalette.brandCyan.withValues(
                                alpha: 0.30,
                              ),
                              blurRadius: 8,
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeading(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _step == 0
                    ? Icons.person_outline_rounded
                    : Icons.storefront_outlined,
                color: colors.accent,
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              _step == 0
                  ? context.t(
                      'initialOnboarding.identityStepLabel',
                      fallback: 'Você e sua empresa',
                    )
                  : context.t(
                      'initialOnboarding.businessStepLabel',
                      fallback: 'Seu negócio',
                    ),
              style: TextStyle(
                color: colors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
            color: colors.titleText,
            fontSize: 27,
            height: 1.1,
            letterSpacing: -0.65,
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
            color: colors.mutedText,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityStep(
    BuildContext context,
    OnboardingInicialModel estado,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MobileSectionLabel(
          icon: Icons.translate_rounded,
          label: context.t(
            'initialOnboarding.languageQuestion',
            fallback: 'Em qual idioma deseja continuar?',
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: <Widget>[
            Expanded(
              child: _MobileLanguageChoice(
                code: 'PT',
                label: 'Português',
                selected: _idioma == 'pt-BR',
                onTap: () => _changeLanguage('pt-BR'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MobileLanguageChoice(
                code: 'EN',
                label: 'English',
                selected: _idioma == 'en-US',
                onTap: () => _changeLanguage('en-US'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MobileLanguageChoice(
                code: 'ES',
                label: 'Español',
                selected: _idioma == 'es-ES',
                onTap: () => _changeLanguage('es-ES'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        _MobileSectionLabel(
          icon: Icons.badge_outlined,
          label: context.t(
            'initialOnboarding.yourDetails',
            fallback: 'Seus dados',
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
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
        ),
        if (estado.podeConfigurarEmpresa) ...<Widget>[
          const SizedBox(height: 15),
          _buildTextField(
            context,
            controller: _empresaController,
            label: context.t(
              'initialOnboarding.companyName',
              fallback: 'Nome do seu negócio',
            ),
            icon: Icons.storefront_outlined,
            action: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.organizationName],
          ),
        ],
        const SizedBox(height: 18),
        _MobileReassurance(
          icon: Icons.schedule_rounded,
          text: context.t(
            'initialOnboarding.timeBadge',
            fallback: 'Leva menos de um minuto.',
          ),
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: colors.titleText,
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
            color: colors.titleText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.softSurface,
            prefixIcon: Icon(icon, color: colors.accent, size: 21),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: colors.accent, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: colors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessStep(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.touch_app_rounded, color: colors.accent, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.t(
                    'initialOnboarding.chooseHint',
                    fallback: 'Escolha uma opção ou as duas.',
                  ),
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _BusinessChoiceMobile(
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
        ),
        const SizedBox(height: 12),
        _BusinessChoiceMobile(
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
        ),
        const SizedBox(height: 17),
        _MobileReassurance(
          icon: Icons.tune_rounded,
          text: context.t(
            'initialOnboarding.privacyNote',
            fallback: 'Você poderá alterar essas informações depois.',
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    OnboardingInicialModel estado,
    bool finalStep,
    bool saving,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 18,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: <Widget>[
            if (_step > 0) ...<Widget>[
              SizedBox(
                width: 52,
                height: 52,
                child: OutlinedButton(
                  onPressed: saving
                      ? null
                      : () => setState(() {
                          _step -= 1;
                          _errorKey = null;
                        }),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: colors.titleText,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _MobilePrimaryAction(
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
                onTap: finalStep
                    ? () => _finish(estado)
                    : () => _next(estado),
              ),
            ),
          ],
        ),
      ),
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
      widget.onCompleted(context);
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

class _MobileSectionLabel extends StatelessWidget {
  const _MobileSectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Row(
      children: <Widget>[
        Icon(icon, color: colors.accent, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.titleText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileLanguageChoice extends StatelessWidget {
  const _MobileLanguageChoice({
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 170),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? colors.softAccentSurface : colors.softSurface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? colors.accent : colors.iconSurface,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        code,
                        style: TextStyle(
                          color: selected ? colors.onAccent : colors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: colors.accent,
                            size: 17,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 11,
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

class _BusinessChoiceMobile extends StatelessWidget {
  const _BusinessChoiceMobile({
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 185),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.075)
                  : colors.softSurface,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: selected ? accent : colors.border,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.10),
                        blurRadius: 17,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.titleText,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? accent : colors.mutedText,
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
          ),
        ),
      ),
    );
  }
}

class _MobileReassurance extends StatelessWidget {
  const _MobileReassurance({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Row(
      children: <Widget>[
        Icon(icon, color: colors.mutedText, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _MobilePrimaryAction extends StatelessWidget {
  const _MobilePrimaryAction({
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
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: saving
                    ? const <Color>[Color(0xFF64748B), Color(0xFF94A3B8)]
                    : const <Color>[
                        SixMobilePalette.brandNavyBright,
                        SixMobilePalette.brandBlue,
                      ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: saving
                  ? const <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: SixMobilePalette.brandBlue.withValues(
                          alpha: 0.24,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

class _MobileOnboardingError extends StatelessWidget {
  const _MobileOnboardingError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.errorBorder),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.titleText,
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
