import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/empresa_service.dart';
import '../../data/models/onboarding_inicial_model.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
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
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHero(context, totalSteps),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 230),
                  child: ListView(
                    key: ValueKey<int>(_step),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
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
                          color: colors.titleText,
                          fontSize: 24,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                    'Isso apenas organiza módulos e atalhos. Você poderá alterar depois.',
                              ),
                        style: TextStyle(
                          color: colors.mutedText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
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
              _buildActions(context, estado, finalStep, provider.salvando),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, int totalSteps) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.primary, colors.secondary],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.heroShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Image.asset('assets/images/sixoapp_splash_symbol.png'),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'SixoApp',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      context.t(
                        'initialOnboarding.eyebrow',
                        fallback: 'Configuração inicial',
                      ),
                      style: TextStyle(
                        color: colors.heroSupportingText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_step + 1}/$totalSteps',
                style: TextStyle(
                  color: colors.heroLabelText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: (_step + 1) / totalSteps,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityStep(
    BuildContext context,
    OnboardingInicialModel estado,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(
            'initialOnboarding.languageQuestion',
            fallback: 'Em qual idioma deseja continuar?',
          ),
          style: TextStyle(
            color: context.sixMobileColors.titleText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        Column(
          children: <Widget>[
            _languageChoice(context, 'pt-BR', 'Português (Brasil)'),
            const SizedBox(height: 8),
            _languageChoice(context, 'en-US', 'English (US)'),
            const SizedBox(height: 8),
            _languageChoice(context, 'es-ES', 'Español'),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nomeController,
          textInputAction: estado.podeConfigurarEmpresa
              ? TextInputAction.next
              : TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.t(
              'initialOnboarding.userName',
              fallback: 'Como podemos chamar você?',
            ),
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),
        if (estado.podeConfigurarEmpresa) ...<Widget>[
          const SizedBox(height: 16),
          TextField(
            controller: _empresaController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: context.t(
                'initialOnboarding.companyName',
                fallback: 'Nome do seu negócio',
              ),
              prefixIcon: const Icon(Icons.storefront_outlined),
            ),
          ),
        ],
      ],
    );
  }

  Widget _languageChoice(BuildContext context, String value, String label) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool selected = _idioma == value;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => _changeLanguage(value),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? colors.softAccentSurface : colors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.language_rounded,
                color: selected ? colors.accent : colors.mutedText,
                size: 20,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.accent : colors.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessStep(BuildContext context) {
    return Column(
      children: <Widget>[
        _BusinessChoiceMobile(
          icon: Icons.point_of_sale_rounded,
          title: context.t(
            'initialOnboarding.salesTitle',
            fallback: 'Vende produtos',
          ),
          subtitle: context.t(
            'initialOnboarding.salesSubtitle',
            fallback: 'PDV, catálogo, estoque e vendas.',
          ),
          selected: _realizaVendas,
          onTap: () => setState(() => _realizaVendas = !_realizaVendas),
        ),
        const SizedBox(height: 12),
        _BusinessChoiceMobile(
          icon: Icons.build_circle_outlined,
          title: context.t(
            'initialOnboarding.servicesTitle',
            fallback: 'Presta serviços ou assistência técnica',
          ),
          subtitle: context.t(
            'initialOnboarding.servicesSubtitle',
            fallback: 'Atendimentos, ordens de serviço e acompanhamento.',
          ),
          selected: _prestaServicos,
          onTap: () => setState(() => _prestaServicos = !_prestaServicos),
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: <Widget>[
          if (_step > 0) ...<Widget>[
            IconButton.filledTonal(
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
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: saving
                    ? null
                    : finalStep
                    ? () => _finish(estado)
                    : () => _next(estado),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Icon(
                        finalStep
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  finalStep
                      ? context.t(
                          'initialOnboarding.start',
                          fallback: 'Começar a usar o SixoApp',
                        )
                      : context.t('common.continue', fallback: 'Continuar'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
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
    setState(() => _idioma = value);
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

class _BusinessChoiceMobile extends StatelessWidget {
  const _BusinessChoiceMobile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? colors.softAccentSurface : colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.navigationShadow,
                blurRadius: selected ? 13 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.iconSurface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: selected ? colors.accent : colors.mutedText,
                ),
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
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.accent : colors.mutedText,
              ),
            ],
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
    return Container(
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
              style: TextStyle(color: colors.titleText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
