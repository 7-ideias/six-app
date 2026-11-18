import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/empresa_service.dart';
import '../../core/services/perfil_negocio_service.dart';
import '../../data/models/onboarding_inicial_model.dart';
import '../../data/models/perfil_negocio_model.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/perfil_negocio_texts.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/onboarding_inicial_provider.dart';
import '../../providers/perfil_negocio_editor_controller.dart';
import '../components/web/perfil_negocio_web_form.dart';
import '../theme/web_theme_tokens.dart';

class OnboardingInicialWebPage extends StatefulWidget {
  const OnboardingInicialWebPage({
    super.key,
    required this.onCompleted,
    this.createPerfilService = PerfilNegocioService.new,
  });

  final VoidCallback onCompleted;
  final PerfilNegocioService Function() createPerfilService;

  @override
  State<OnboardingInicialWebPage> createState() =>
      _OnboardingInicialWebPageState();
}

class _OnboardingInicialWebPageState extends State<OnboardingInicialWebPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();

  bool _initialized = false;
  bool _perfilBootstrapStarted = false;
  int _step = 0;
  String? _errorKey;
  PerfilNegocioEditorController? _perfilController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final OnboardingInicialModel? estado =
        context.read<OnboardingInicialProvider>().estado;
    if (estado == null) return;

    _initialized = true;
    _nomeController.text = estado.nomeUsuario;
    _empresaController.text = estado.nomeEmpresa;

    if (estado.podeConfigurarEmpresa) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _inicializarPerfil());
    }
  }

  Future<void> _inicializarPerfil() async {
    if (!mounted || _perfilBootstrapStarted) return;
    _perfilBootstrapStarted = true;
    final PerfilNegocioService service = widget.createPerfilService();
    try {
      final String empresaId = await service.empresaAtual();
      if (!mounted) {
        service.dispose();
        return;
      }
      final PerfilNegocioEditorController controller =
          PerfilNegocioEditorController(empresaId: empresaId, service: service);
      controller.addListener(_onPerfilChanged);
      setState(() => _perfilController = controller);
      await controller.carregar();
    } catch (_) {
      service.dispose();
      if (mounted) {
        setState(() => _errorKey = 'initialOnboarding.saveError');
      }
    }
  }

  void _onPerfilChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _empresaController.dispose();
    _perfilController?.removeListener(_onPerfilChanged);
    _perfilController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final OnboardingInicialProvider provider =
        context.watch<OnboardingInicialProvider>();
    final OnboardingInicialModel? estado = provider.estado;
    if (estado == null) return const SizedBox.shrink();

    final int totalSteps = estado.podeConfigurarEmpresa ? 4 : 1;
    final bool finalStep = _step == totalSteps - 1;

    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 600;
            final double inset = compact ? 16 : 32;
            return Center(
              child: Padding(
                padding: EdgeInsets.all(compact ? 8 : 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 2,
                    color: tokens.surfaceElevated,
                    surfaceTintColor: Colors.transparent,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: tokens.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            key: ValueKey(_step),
                            padding: EdgeInsets.all(inset),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _header(context, totalSteps),
                                const SizedBox(height: 24),
                                if (_step == 0)
                                  _identityStep(context, estado)
                                else if (_perfilController == null)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else
                                  PerfilNegocioWebForm(
                                    controller: _perfilController!,
                                    etapa: _step - 1,
                                  ),
                                if (_errorKey != null) ...[
                                  const SizedBox(height: 16),
                                  _error(context),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, thickness: 1, color: tokens.divider),
                        ColoredBox(
                          color: tokens.surface,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: inset,
                              vertical: 12,
                            ),
                            child: _actions(
                              context,
                              estado,
                              finalStep,
                              provider.salvando,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int totalSteps) {
    final tokens = WebThemeTokens.of(context);
    final label = "${context.t('initialOnboarding.step')} ${_step + 1} "
        "${context.t('initialOnboarding.of')} $totalSteps";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/sixoapp_splash_symbol.png',
                  height: 30,
                  width: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  'SixoApp',
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: TextStyle(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LinearProgressIndicator(
          value: (_step + 1) / totalSteps,
          color: tokens.info,
          backgroundColor: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(4),
          semanticsValue: label,
        ),
      ],
    );
  }

  Widget _identityStep(BuildContext context, OnboardingInicialModel estado) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t('initialOnboarding.identityTitle'),
          style: TextStyle(
            color: tokens.primaryText,
            fontSize: 29,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.t('initialOnboarding.identitySubtitle'),
          style: TextStyle(color: tokens.secondaryText, height: 1.45),
        ),
        const SizedBox(height: 22),
        Text(
          context.t('initialOnboarding.languageQuestion'),
          style: TextStyle(
            color: tokens.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: <Widget>[
            _language('Português', const Locale('pt', 'BR')),
            _language('English', const Locale('en', 'US')),
            _language('Español', const Locale('es', 'ES')),
          ],
        ),
        const SizedBox(height: 22),
        _field(
          controller: _nomeController,
          label: context.t('initialOnboarding.userName'),
          icon: Icons.person_outline_rounded,
        ),
        if (estado.podeConfigurarEmpresa) ...<Widget>[
          const SizedBox(height: 13),
          _field(
            controller: _empresaController,
            label: context.t('initialOnboarding.companyName'),
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            perfilNegocioText(context, 'notice'),
            style: TextStyle(color: tokens.secondaryText, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _language(String label, Locale locale) {
    final tokens = WebThemeTokens.of(context);
    final selected = Localizations.localeOf(context) == locale;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _changeLanguage(locale),
      showCheckmark: true,
      checkmarkColor: tokens.info,
      selectedColor: tokens.selectedBackground,
      backgroundColor: tokens.inputBackground,
      labelStyle: TextStyle(color: tokens.primaryText),
      side: BorderSide(
        color: selected ? tokens.selectedBorder : tokens.cardBorder,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return TextField(
      controller: controller,
      style: TextStyle(
        color: tokens.primaryText,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tokens.secondaryText),
        filled: true,
        fillColor: tokens.inputBackground,
        prefixIcon: Icon(icon, color: tokens.info),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: tokens.info, width: 1.6),
        ),
      ),
    );
  }

  Widget _error(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.28)),
      ),
      child: Text(
        context.t(_errorKey!),
        style: TextStyle(color: tokens.primaryText, fontSize: 13),
      ),
    );
  }

  Widget _actions(
    BuildContext context,
    OnboardingInicialModel estado,
    bool finalStep,
    bool saving,
  ) {
    final tokens = WebThemeTokens.of(context);
    final bool profileLoading =
        _step > 0 &&
        (_perfilController == null ||
            _perfilController!.carregando ||
            _perfilController!.catalogo == null);

    return OverflowBar(
      alignment: _step > 0
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      spacing: 10,
      overflowSpacing: 8,
      children: <Widget>[
        if (_step > 0)
          OutlinedButton.icon(
            onPressed: saving ? null : () => setState(() => _step--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(perfilNegocioText(context, 'back')),
          ),
        FilledButton.icon(
          onPressed: saving || profileLoading
              ? null
              : finalStep
              ? () => _finish(estado)
              : () => _next(estado),
          style: FilledButton.styleFrom(
            backgroundColor: tokens.info,
            foregroundColor: tokens.onInfo,
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
          ),
          icon: saving
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.onInfo,
                  ),
                )
              : Icon(
                  finalStep
                      ? Icons.auto_awesome_rounded
                      : Icons.arrow_forward_rounded,
                ),
          label: Text(
            finalStep
                ? context.t('initialOnboarding.start')
                : perfilNegocioText(context, 'continue'),
          ),
        ),
      ],
    );
  }

  void _next(OnboardingInicialModel estado) {
    if (_step == 0) {
      if (!_validateIdentity(estado)) return;
      setState(() {
        _step = 1;
        _errorKey = null;
      });
      return;
    }
    final PerfilNegocioEditorController? controller = _perfilController;
    if (controller == null || !controller.validarEtapa(_step - 1)) return;
    setState(() {
      _step++;
      _errorKey = null;
    });
  }

  Future<void> _finish(OnboardingInicialModel estado) async {
    if (!_validateIdentity(estado)) return;

    AtualizarPerfilNegocioRequest? perfilRequest;
    if (estado.podeConfigurarEmpresa) {
      final PerfilNegocioEditorController? controller = _perfilController;
      if (controller == null || !controller.validarEtapa(2)) return;
      perfilRequest = controller.preparar();
      if (perfilRequest == null) return;
    }

    final Set<String> atividades =
        perfilRequest?.perfil.atividades ?? const <String>{};
    try {
      await context.read<OnboardingInicialProvider>().concluir(
        ConcluirOnboardingInicialRequest(
          idiomaPreferencial: context
              .read<LocaleSettingsProvider>()
              .currentLocale
              .toLanguageTag(),
          nomeUsuario: _nomeController.text.trim(),
          nomeDeGuerra: _nomeController.text.trim(),
          nomeEmpresa: _empresaController.text.trim(),
          realizaVendas: perfilRequest == null
              ? estado.realizaVendas
              : atividades.contains('VENDA_PRODUTOS'),
          prestaServicosTecnicos: perfilRequest == null
              ? estado.prestaServicosTecnicos
              : atividades.contains('REPAROS_MANUTENCAO'),
          perfilNegocio: perfilRequest,
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

  Future<void> _changeLanguage(Locale locale) async {
    final settings = context.read<LocaleSettingsProvider>();
    if (settings.currentLocale == locale) return;
    setState(() => _errorKey = null);
    await settings.setUserLocale(locale);
  }
}
