import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/empresa_service.dart';
import '../../data/models/onboarding_inicial_model.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/onboarding_inicial_provider.dart';
import '../theme/web_theme_tokens.dart';

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

    final bool showBusinessStep = estado.podeConfigurarEmpresa;
    final int totalSteps = showBusinessStep ? 2 : 1;
    final bool finalStep = _step == totalSteps - 1;

    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              tokens.workspaceBackground,
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  padding: const EdgeInsets.all(34),
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: tokens.cardBorder),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 34,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Column(
                      key: ValueKey<int>(_step),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildHeader(context, totalSteps),
                        const SizedBox(height: 30),
                        if (_step == 0)
                          _buildIdentityStep(context, estado)
                        else
                          _buildBusinessStep(context),
                        if (_errorKey != null) ...<Widget>[
                          const SizedBox(height: 18),
                          _OnboardingWebError(
                            message: context.t(
                              _errorKey!,
                              fallback: 'Revise as informações e tente novamente.',
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          children: <Widget>[
                            if (_step > 0)
                              TextButton.icon(
                                onPressed: provider.salvando
                                    ? null
                                    : () => setState(() {
                                        _step -= 1;
                                        _errorKey = null;
                                      }),
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: Text(
                                  context.t('common.back', fallback: 'Voltar'),
                                ),
                              ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: provider.salvando
                                  ? null
                                  : finalStep
                                  ? () => _finish(estado)
                                  : () => _next(estado),
                              icon: provider.salvando
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
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
                                    : context.t(
                                        'common.continue',
                                        fallback: 'Continuar',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalSteps) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.asset('assets/images/sixoapp_splash_symbol.png'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.t(
                  'initialOnboarding.eyebrow',
                  fallback: 'Configuração inicial',
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${context.t('initialOnboarding.step', fallback: 'Etapa')} '
              '${_step + 1} ${context.t('initialOnboarding.of', fallback: 'de')} '
              '$totalSteps',
              style: TextStyle(
                color: tokens.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
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
            fontSize: 28,
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
          style: TextStyle(color: tokens.secondaryText, height: 1.45),
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
        Text(
          context.t(
            'initialOnboarding.languageQuestion',
            fallback: 'Em qual idioma deseja continuar?',
          ),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _languageChoice(context, 'pt-BR', 'Português (Brasil)'),
            _languageChoice(context, 'en-US', 'English (US)'),
            _languageChoice(context, 'es-ES', 'Español'),
          ],
        ),
        const SizedBox(height: 24),
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
          const SizedBox(height: 18),
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
    final bool selected = _idioma == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      avatar: Icon(
        selected ? Icons.check_circle_rounded : Icons.language_rounded,
        size: 18,
      ),
      onSelected: (_) => _changeLanguage(value),
    );
  }

  Widget _buildBusinessStep(BuildContext context) {
    return Column(
      children: <Widget>[
        _BusinessChoiceWeb(
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
        _BusinessChoiceWeb(
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

class _BusinessChoiceWeb extends StatelessWidget {
  const _BusinessChoiceWeb({
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.09)
                : tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : tokens.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: selected ? accent : tokens.secondaryText),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? accent : tokens.mutedText,
              ),
            ],
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
    return Container(
      width: double.infinity,
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
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
