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
                _header(context, totalSteps),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
                            children: <Widget>[
                              _heading(context),
                              const SizedBox(height: 25),
                              if (_step == 0)
                                _identityStep(context, estado)
                              else
                                _businessStep(context),
                              if (_errorKey != null) ...<Widget>[
                                const SizedBox(height: 16),
                                _error(context),
                              ],
                            ],
                          ),
                        ),
                        _actions(
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

  Widget _header(BuildContext context, int totalSteps) {
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
                        color: SixMobilePalette.brandSupportingText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_step + 1}/$totalSteps',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List<Widget>.generate(totalSteps, (int index) {
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 7 : 0),
                  decoration: BoxDecoration(
                    color: index <= _step
                        ? SixMobilePalette.brandCyan
                        : Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _step == 0
                ? Icons.person_outline_rounded
                : Icons.dashboard_customize_outlined,
            color: colors.accent,
            size: 19,
          ),
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
            color: colors.mutedText,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _identityStep(
    BuildContext context,
    OnboardingInicialModel estado,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(
            'initialOnboarding.languageQuestion',
            fallback: 'Em qual idioma deseja continuar?',
          ),
          style: TextStyle(
            color: colors.titleText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: <Widget>[
            Expanded(child: _language('PT', 'Português', 'pt-BR')),
            const SizedBox(width: 8),
            Expanded(child: _language('EN', 'English', 'en-US')),
            const SizedBox(width: 8),
            Expanded(child: _language('ES', 'Español', 'es-ES')),
          ],
        ),
        const SizedBox(height: 23),
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
    return _MobileLanguageTile(
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return TextField(
      controller: controller,
      textInputAction: action,
      style: TextStyle(color: colors.titleText, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colors.softSurface,
        prefixIcon: Icon(icon, color: colors.accent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.accent, width: 1.6),
        ),
      ),
    );
  }

  Widget _businessStep(BuildContext context) {
    return Column(
      children: <Widget>[
        _MobileActivityTile(
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
        _MobileActivityTile(
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
      ],
    );
  }

  Widget _error(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: colors.errorBorder),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                context.t(
                  _errorKey!,
                  fallback: 'Revise as informações e tente novamente.',
                ),
                style: TextStyle(color: colors.titleText, fontSize: 13),
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 16,
            offset: const Offset(0, -6),
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
                width: 51,
                height: 51,
                child: OutlinedButton(
                  onPressed: saving
                      ? null
                      : () => setState(() {
                          _step = 0;
                          _errorKey = null;
                        }),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
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
              child: SizedBox(
                height: 51,
                child: FilledButton.icon(
                  onPressed: saving
                      ? null
                      : finalStep
                      ? () => _finish(estado)
                      : () => _next(estado),
                  style: FilledButton.styleFrom(
                    backgroundColor: SixMobilePalette.brandNavyBright,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
    return fallback.languageCode == 'en'
        ? 'en-US'
        : fallback.languageCode == 'es'
        ? 'es-ES'
        : 'pt-BR';
  }
}

class _MobileLanguageTile extends StatelessWidget {
  const _MobileLanguageTile({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? colors.softAccentSurface : colors.softSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 33,
                height: 33,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colors.accent : colors.iconSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: selected ? colors.onAccent : colors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.titleText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileActivityTile extends StatelessWidget {
  const _MobileActivityTile({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.08)
                : colors.softSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(width: 13),
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
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? accent : colors.mutedText,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
