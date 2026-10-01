import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/empresa_service.dart';
import '../../core/services/perfil_negocio_service.dart';
import '../../data/models/onboarding_inicial_model.dart';
import '../../data/models/perfil_negocio_model.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/perfil_negocio_texts.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/onboarding_inicial_provider.dart';
import '../../providers/perfil_negocio_editor_controller.dart';
import '../components/mobile/perfil_negocio_mobile_form.dart';

class OnboardingInicialMobileScreen extends StatefulWidget {
  const OnboardingInicialMobileScreen({super.key, required this.onCompleted});

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
  bool _perfilBootstrapStarted = false;
  int _step = 0;
  String _idioma = 'pt-BR';
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
    _idioma = _normalizarIdioma(estado.idiomaPreferencial);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyLocale(_idioma);
      if (estado.podeConfigurarEmpresa) _inicializarPerfil();
    });
  }

  Future<void> _inicializarPerfil() async {
    if (_perfilBootstrapStarted) return;
    _perfilBootstrapStarted = true;
    final PerfilNegocioService service = PerfilNegocioService();
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    final OnboardingInicialProvider provider =
        context.watch<OnboardingInicialProvider>();
    final OnboardingInicialModel? estado = provider.estado;
    if (estado == null) return const SizedBox.shrink();

    final int totalSteps = estado.podeConfigurarEmpresa ? 5 : 2;
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
                              _content(context, estado),
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
              const Expanded(
                child: Text(
                  'SixoApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: (_step + 1) / totalSteps,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                SixMobilePalette.brandCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, OnboardingInicialModel estado) {
    if (_step == 0) return _languageStep(context);
    if (_step == 1) return _identityStep(context, estado);

    final PerfilNegocioEditorController? controller = _perfilController;
    if (controller == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: CircularProgressIndicator(
            color: context.sixMobileColors.accent,
          ),
        ),
      );
    }
    return PerfilNegocioMobileForm(
      controller: controller,
      etapa: _step - 2,
    );
  }

  Widget _languageStep(BuildContext context) {
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
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        _languageTile('PT', 'Português', 'pt-BR'),
        const SizedBox(height: 10),
        _languageTile('EN', 'English', 'en-US'),
        const SizedBox(height: 10),
        _languageTile('ES', 'Español', 'es-ES'),
      ],
    );
  }

  Widget _languageTile(String code, String label, String value) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool selected = _idioma == value;
    return Material(
      color: selected ? colors.softAccentSurface : colors.surfaceElevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _changeLanguage(value),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colors.accent : colors.iconSurface,
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? colors.accent : colors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityStep(BuildContext context, OnboardingInicialModel estado) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(
            'initialOnboarding.identityTitle',
            fallback: 'Vamos começar pelo essencial',
          ),
          style: TextStyle(
            color: colors.titleText,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.t(
            'initialOnboarding.identitySubtitle',
            fallback: 'Confirme seus dados para personalizarmos sua experiência.',
          ),
          style: TextStyle(
            color: colors.mutedText,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        _field(
          controller: _nomeController,
          label: context.t(
            'initialOnboarding.userName',
            fallback: 'Como podemos chamar você?',
          ),
          icon: Icons.person_outline_rounded,
        ),
        if (estado.podeConfigurarEmpresa) ...<Widget>[
          const SizedBox(height: 13),
          _field(
            controller: _empresaController,
            label: context.t(
              'initialOnboarding.companyName',
              fallback: 'Nome do seu negócio',
            ),
            icon: Icons.storefront_outlined,
          ),
        ],
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return TextField(
      controller: controller,
      style: TextStyle(
        color: colors.titleText,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.mutedText),
        filled: true,
        fillColor: colors.softSurface,
        prefixIcon: Icon(icon, color: colors.accent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _error(BuildContext context) {
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
          Icon(Icons.error_outline_rounded, color: colors.error, size: 19),
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
    );
  }

  Widget _actions(
    BuildContext context,
    OnboardingInicialModel estado,
    bool finalStep,
    bool saving,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool profileLoading =
        _step >= 2 &&
        (_perfilController == null ||
            _perfilController!.carregando ||
            _perfilController!.catalogo == null);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: <Widget>[
          if (_step > 0) ...<Widget>[
            OutlinedButton(
              onPressed: saving ? null : () => setState(() => _step--),
              child: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton.icon(
              onPressed: saving || profileLoading
                  ? null
                  : finalStep
                  ? () => _finish(estado)
                  : () => _next(estado),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: saving
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onAccent,
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
                    : perfilNegocioText(context, 'continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _next(OnboardingInicialModel estado) {
    if (_step == 0) {
      setState(() {
        _step = 1;
        _errorKey = null;
      });
      return;
    }
    if (_step == 1) {
      if (!_validateIdentity(estado)) return;
      setState(() {
        _step = 2;
        _errorKey = null;
      });
      return;
    }

    final PerfilNegocioEditorController? controller = _perfilController;
    if (controller == null || !controller.validarEtapa(_step - 2)) return;
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
          idiomaPreferencial: _idioma,
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
    await _applyLocale(value);
  }

  Future<void> _applyLocale(String value) async {
    final Locale locale = switch (value) {
      'en-US' => const Locale('en', 'US'),
      'es-ES' => const Locale('es', 'ES'),
      _ => const Locale('pt', 'BR'),
    };
    await context.read<LocaleSettingsProvider>().setUserLocale(locale);
  }

  String _normalizarIdioma(String value) {
    final String normalized = value.trim().toLowerCase();
    if (normalized.startsWith('en')) return 'en-US';
    if (normalized.startsWith('es')) return 'es-ES';
    return 'pt-BR';
  }
}
