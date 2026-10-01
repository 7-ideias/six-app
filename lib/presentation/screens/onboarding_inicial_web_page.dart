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
    _idioma = _normalizarIdioma(
      estado.idiomaPreferencial,
      context.read<LocaleSettingsProvider>().currentLocale,
    );

    if (estado.podeConfigurarEmpresa) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _inicializarPerfil());
    }
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final OnboardingInicialProvider provider =
        context.watch<OnboardingInicialProvider>();
    final OnboardingInicialModel? estado = provider.estado;
    if (estado == null) return const SizedBox.shrink();

    final int totalSteps = estado.podeConfigurarEmpresa ? 4 : 1;
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
              return SingleChildScrollView(
                padding: EdgeInsets.all(wide ? 30 : 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Container(
                      constraints: BoxConstraints(minHeight: wide ? 680 : 0),
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
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                SizedBox(
                                  width: 340,
                                  child: _brandPanel(context),
                                ),
                                Expanded(
                                  child: _form(
                                    context,
                                    estado,
                                    totalSteps,
                                    finalStep,
                                    provider.salvando,
                                    wide: true,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: <Widget>[
                                _compactHeader(context),
                                _form(
                                  context,
                                  estado,
                                  totalSteps,
                                  finalStep,
                                  provider.salvando,
                                  wide: false,
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
      ),
    );
  }

  Widget _brandPanel(BuildContext context) {
    final String title = _step == 0
        ? context.t(
            'initialOnboarding.identityTitle',
            fallback: 'Vamos começar pelo essencial',
          )
        : perfilNegocioText(
            context,
            _step == 1
                ? 'segmentTitle'
                : _step == 2
                ? 'activityTitle'
                : 'goalTitle',
          );
    final String subtitle = _step == 0
        ? context.t(
            'initialOnboarding.identitySubtitle',
            fallback: 'Confirme seus dados para personalizarmos sua experiência.',
          )
        : perfilNegocioText(
            context,
            _step == 1
                ? 'segmentSubtitle'
                : _step == 2
                ? 'activitySubtitle'
                : 'goalSubtitle',
          );

    return Container(
      padding: const EdgeInsets.all(34),
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
          Icon(
            _step == 0
                ? Icons.auto_awesome_rounded
                : Icons.storefront_rounded,
            color: _cyan,
            size: 42,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              height: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            perfilNegocioText(context, 'notice'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactHeader(BuildContext context) {
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
      ],
    );
  }

  Widget _form(
    BuildContext context,
    OnboardingInicialModel estado,
    int totalSteps,
    bool finalStep,
    bool saving, {
    required bool wide,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      color: tokens.surfaceElevated,
      padding: EdgeInsets.all(wide ? 38 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '${context.t('initialOnboarding.step', fallback: 'Etapa')} '
                '${_step + 1} ${context.t('initialOnboarding.of', fallback: 'de')} '
                '$totalSteps',
                style: const TextStyle(
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
          const SizedBox(height: 28),
          if (_step == 0)
            _identityStep(context, estado)
          else if (_perfilController == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            PerfilNegocioWebForm(
              controller: _perfilController!,
              etapa: _step - 1,
            ),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 16),
            _error(context),
          ],
          const SizedBox(height: 28),
          Divider(color: tokens.divider),
          const SizedBox(height: 16),
          _actions(context, estado, finalStep, saving),
        ],
      ),
    );
  }

  Widget _identityStep(BuildContext context, OnboardingInicialModel estado) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(
            'initialOnboarding.identityTitle',
            fallback: 'Vamos começar pelo essencial',
          ),
          style: TextStyle(
            color: tokens.primaryText,
            fontSize: 29,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.t(
            'initialOnboarding.identitySubtitle',
            fallback: 'Confirme seus dados para personalizarmos sua experiência.',
          ),
          style: TextStyle(color: tokens.secondaryText, height: 1.45),
        ),
        const SizedBox(height: 22),
        Text(
          context.t(
            'initialOnboarding.languageQuestion',
            fallback: 'Em qual idioma deseja continuar?',
          ),
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
            _language('PT', 'Português', 'pt-BR'),
            _language('EN', 'English', 'en-US'),
            _language('ES', 'Español', 'es-ES'),
          ],
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

  Widget _language(String code, String label, String value) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool selected = _idioma == value;
    return InkWell(
      onTap: () => _changeLanguage(value),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected
              ? _blue.withValues(alpha: 0.08)
              : tokens.inputBackground,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? _blue : tokens.cardBorder,
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
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
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
        context.t(
          _errorKey!,
          fallback: 'Revise as informações e tente novamente.',
        ),
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
    final bool profileLoading =
        _step > 0 &&
        (_perfilController == null ||
            _perfilController!.carregando ||
            _perfilController!.catalogo == null);

    return Row(
      children: <Widget>[
        if (_step > 0)
          OutlinedButton.icon(
            onPressed: saving ? null : () => setState(() => _step--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(perfilNegocioText(context, 'back')),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: saving || profileLoading
              ? null
              : finalStep
              ? () => _finish(estado)
              : () => _next(estado),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
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
          idiomaPreferencial: _idioma,
          nomeUsuario: _nomeController.text.trim(),
          nomeDeGuerra: _nomeController.text.trim(),
          nomeEmpresa: _empresaController.text.trim(),
          realizaVendas: perfilRequest == null
              ? estado.realizaVendas
              : atividades.contains('VENDA_PRODUTOS'),
          prestaServicosTecnicos: perfilRequest == null
              ? estado.prestaServicosTecnicos
              : atividades.contains('PRESTACAO_SERVICOS'),
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
