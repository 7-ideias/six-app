import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/empresa_service.dart';
import '../../data/models/onboarding_inicial_model.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/onboarding_inicial_provider.dart';
import '../theme/web_theme_tokens.dart';

const Color _navy = Color(0xFF061D4B);
const Color _blue = Color(0xFF145BFF);
const Color _cyan = Color(0xFF10D9F0);

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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              _blue.withValues(alpha: 0.10),
              tokens.workspaceBackground,
              _cyan.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool wide = constraints.maxWidth >= 900;
              final Widget card = Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: tokens.cardBorder),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _navy.withValues(alpha: 0.15),
                      blurRadius: 48,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: wide
                    ? SizedBox(
                        height: 650,
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 370,
                              child: _buildBrandPanel(context),
                            ),
                            Expanded(
                              child: _buildForm(
                                context,
                                estado,
                                totalSteps,
                                finalStep,
                                provider.salvando,
                                wide: true,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: <Widget>[
                          _buildCompactHeader(context),
                          _buildForm(
                            context,
                            estado,
                            totalSteps,
                            finalStep,
                            provider.salvando,
                            wide: false,
                          ),
                        ],
                      ),
              );

              return SingleChildScrollView(
                padding: EdgeInsets.all(wide ? 30 : 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: card,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_navy, Color(0xFF0A327D), _blue],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _brandLockup(context),
          const Spacer(),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(
              _step == 0
                  ? Icons.auto_awesome_rounded
                  : Icons.dashboard_customize_rounded,
              color: _cyan,
              size: 35,
            ),
          ),
          const SizedBox(height: 24),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
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
                        'Isso organiza módulos e atalhos. Você poderá alterar depois.',
                  ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              const Icon(Icons.schedule_rounded, color: _cyan, size: 17),
              const SizedBox(width: 8),
              Text(
                context.t(
                  'initialOnboarding.eyebrow',
                  fallback: 'Configuração inicial',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: <Color>[_navy, _blue]),
      ),
      child: _brandLockup(context),
    );
  }

  Widget _brandLockup(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 45,
          height: 45,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
                ),
              ),
              Text(
                context.t(
                  'initialOnboarding.eyebrow',
                  fallback: 'Configuração inicial',
                ),
                style: const TextStyle(
                  color: Color(0xFFA8C6EE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(
    BuildContext context,
    OnboardingInicialModel estado,
    int totalSteps,
    bool finalStep,
    bool saving, {
    required bool wide,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Widget content = _step == 0
        ? _identityStep(context, estado)
        : _businessStep(context, wide);

    return Container(
      color: tokens.surfaceElevated,
      padding: EdgeInsets.all(wide ? 42 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '${context.t('initialOnboarding.step', fallback: 'Etapa')} '
                '${_step + 1} ${context.t('initialOnboarding.of', fallback: 'de')} '
                '$totalSteps',
                style: TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: (_step + 1) / totalSteps,
                    backgroundColor: tokens.surfaceMuted,
                    valueColor: const AlwaysStoppedAnimation<Color>(_blue),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 31),
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
              fontSize: 29,
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
                        'Isso organiza módulos e atalhos. Você poderá alterar depois.',
                  ),
            style: TextStyle(
              color: tokens.secondaryText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          content,
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 16),
            _error(context),
          ],
          if (wide) const Spacer() else const SizedBox(height: 28),
          Divider(color: tokens.divider),
          const SizedBox(height: 16),
          _actions(context, estado, finalStep, saving),
        ],
      ),
    );
  }

  Widget _identityStep(
    BuildContext context,
    OnboardingInicialModel estado,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(
            'initialOnboarding.languageQuestion',
            fallback: 'Em qual idioma deseja continuar?',
          ),
          style: TextStyle(
            color: tokens.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: <Widget>[
            _language('PT', 'Português', 'pt-BR'),
            _language('EN', 'English', 'en-US'),
            _language('ES', 'Español', 'es-ES'),
          ],
        ),
        const SizedBox(height: 24),
        _field(
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
        ),
        if (estado.podeConfigurarEmpresa) ...<Widget>[
          const SizedBox(height: 14),
          _field(
            context,
            controller: _empresaController,
            label: context.t(
              'initialOnboarding.companyName',
              fallback: 'Nome do seu negócio',
            ),
            icon: Icons.storefront_outlined,
            action: TextInputAction.done,
          ),
        ],
      ],
    );
  }

  Widget _language(String code, String label, String value) {
    return _WebLanguageTile(
      code: code,
      label: label,
      selected: _idioma == value,
      onTap: () => _changeLanguage(value),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputAction action,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return TextField(
      controller: controller,
      textInputAction: action,
      style: TextStyle(color: tokens.primaryText, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: tokens.inputBackground,
        prefixIcon: Icon(icon, color: _blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _blue, width: 1.6),
        ),
      ),
    );
  }

  Widget _businessStep(BuildContext context, bool wide) {
    final Widget sales = _WebActivityTile(
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
    final Widget services = _WebActivityTile(
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
    if (!wide) {
      return Column(
        children: <Widget>[
          sales,
          const SizedBox(height: 12),
          services,
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: sales),
        const SizedBox(width: 13),
        Expanded(child: services),
      ],
    );
  }

  Widget _error(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.danger.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: tokens.danger, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                context.t(
                  _errorKey!,
                  fallback: 'Revise as informações e tente novamente.',
                ),
                style: TextStyle(color: tokens.primaryText, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(
    BuildContext context,
    OnboardingInicialModel estado,
    bool finalStep,
    bool saving,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Row(
      children: <Widget>[
        if (_step > 0) ...<Widget>[
          IconButton.outlined(
            onPressed: saving
                ? null
                : () => setState(() {
                    _step = 0;
                    _errorKey = null;
                  }),
            tooltip: context.t('common.back', fallback: 'Voltar'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
        ] else
          Icon(Icons.lock_outline_rounded, color: tokens.mutedText, size: 18),
        const Spacer(),
        FilledButton.icon(
          onPressed: saving
              ? null
              : finalStep
              ? () => _finish(estado)
              : () => _next(estado),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  finalStep
                      ? Icons.auto_awesome_rounded
                      : Icons.arrow_forward_rounded,
                ),
          label: Text(
            finalStep
                ? context.t(
                    'initialOnboarding.start',
                    fallback: 'Começar a usar o SixoApp',
                  )
                : context.t('common.continue', fallback: 'Continuar'),
          ),
        ),
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
    return fallback.languageCode == 'en'
        ? 'en-US'
        : fallback.languageCode == 'es'
        ? 'es-ES'
        : 'pt-BR';
  }
}

class _WebLanguageTile extends StatelessWidget {
  const _WebLanguageTile({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 145,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected
                ? _blue.withValues(alpha: 0.08)
                : tokens.inputBackground,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? _blue : tokens.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 29,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _blue : tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: _blue, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebActivityTile extends StatelessWidget {
  const _WebActivityTile({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.08)
                : tokens.inputBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : tokens.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: accent, size: 25),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? accent : tokens.mutedText,
                    size: 25,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  color: tokens.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  color: tokens.secondaryText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
