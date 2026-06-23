import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../../domain/models/aparencia_models.dart';
import '../../domain/services/aparencia/aparencia_service.dart';
import '../../l10n/web_i18n_store.dart';
import '../../providers/locale_settings_provider.dart';

class ConfiguracoesSixWebPage extends StatefulWidget {
  const ConfiguracoesSixWebPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<ConfiguracoesSixWebPage> createState() => _ConfiguracoesSixWebPageState();
}

class _ConfiguracoesSixWebPageState extends State<ConfiguracoesSixWebPage> {
  late final AparenciaService _aparenciaService;

  String _idiomaSelecionado = 'pt-BR';
  String _temaSelecionado = 'Claro';
  bool _salvando = false;
  bool _carregando = false;

  final _nomeEmpresaController = TextEditingController(text: 'Six Assistência Premium');
  final _nomeFantasiaController = TextEditingController(text: 'Six Repair Center');
  final _emailController = TextEditingController(text: 'contato@sixrepair.com');

  _SettingsI18n get _i18n => _SettingsI18n(_idiomaSelecionado);

  @override
  void initState() {
    super.initState();
    _aparenciaService = AparenciaService(apiClient: HttpAparenciaApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<LocaleSettingsProvider>();
      setState(() => _idiomaSelecionado = _localeParaCodigo(provider.currentLocale));
      if (!WebI18nStore.instance.hasLanguage(_idiomaSelecionado)) {
        await provider.reloadWebTranslations();
      }
      await _carregarAparencia();
    });
  }

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _nomeFantasiaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _carregarAparencia() async {
    if (!mounted) return;
    setState(() => _carregando = true);
    try {
      final config = await _aparenciaService.buscarAparencia();
      SixThemeResolver().atualizarConfiguracao(config);
      if (mounted) setState(() => _temaSelecionado = config.tema.label);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _aplicarTemaVisual(String value) {
    setState(() => _temaSelecionado = value);
    final resolver = SixThemeResolver();
    resolver.atualizarConfiguracao(
      ConfiguracaoAparenciaSistema(
        tema: TemaSistema.fromLabel(value),
        paleta: resolver.paleta,
      ),
    );
  }

  Future<void> _alterarIdioma(String value) async {
    setState(() => _idiomaSelecionado = value);
    await context.read<LocaleSettingsProvider>().setUserLocale(_mapIdiomaParaLocale(value));
    if (mounted) setState(() {});
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final resolver = SixThemeResolver();
      final aparencia = ConfiguracaoAparenciaSistema(
        tema: TemaSistema.fromLabel(_temaSelecionado),
        paleta: resolver.paleta,
      );
      await _aparenciaService.salvarAparencia(aparencia);
      resolver.atualizarConfiguracao(aparencia);

      await context.read<LocaleSettingsProvider>().setUserLocale(_mapIdiomaParaLocale(_idiomaSelecionado));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_i18n.t('settingsSaved'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_i18n.t('settingsSaveError')}: $e')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleSettingsProvider>();
    final loading = _carregando || provider.i18nLoading;
    final body = Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_i18n.t('pageTitle'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                            Text(_i18n.t('pageSubtitle')),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _salvando ? null : _salvar,
                        icon: _salvando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                        label: Text(_i18n.t('save')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      _dropdown(_i18n.t('systemLanguage'), _idiomaSelecionado, const ['pt-BR', 'en-US', 'es-ES'], (v) => v == null ? null : _alterarIdioma(v)),
                      _dropdown(_i18n.t('visualTheme'), _temaSelecionado, const ['Claro', 'Escuro', 'Automático'], (v) => v == null ? null : _aplicarTemaVisual(v)),
                      _text(_i18n.t('companyName'), _nomeEmpresaController),
                      _text(_i18n.t('tradeName'), _nomeFantasiaController),
                      _text(_i18n.t('mainEmail'), _emailController),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (loading) const Positioned.fill(child: ColoredBox(color: Color(0x66FFFFFF), child: Center(child: CircularProgressIndicator()))),
      ],
    );

    return widget.embedded ? body : Scaffold(body: SafeArea(child: body));
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(_i18n.o(item)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _text(String label, TextEditingController controller) {
    return SizedBox(
      width: 300,
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
    );
  }

  Locale _mapIdiomaParaLocale(String idioma) => switch (idioma) {
    'en-US' => const Locale('en', 'US'),
    'es-ES' => const Locale('es', 'ES'),
    _ => const Locale('pt', 'BR'),
  };

  String _localeParaCodigo(Locale locale) {
    if (locale.languageCode == 'en') return 'en-US';
    if (locale.languageCode == 'es') return 'es-ES';
    return 'pt-BR';
  }
}

class _SettingsI18n {
  const _SettingsI18n(this.localeCode);

  final String localeCode;

  String get _lang {
    if (localeCode.startsWith('en')) return 'en';
    if (localeCode.startsWith('es')) return 'es';
    return 'pt';
  }

  String t(String key) => WebI18nStore.instance.string(localeCode, 'configuracoes.$key') ?? _fallback[_lang]?[key] ?? _fallback['pt']?[key] ?? key;

  String o(String value) => WebI18nStore.instance.string(localeCode, 'configuracoes.options.$value') ?? _options[_lang]?[value] ?? _options['pt']?[value] ?? value;

  static const _fallback = {
    'pt': {'pageTitle': 'Configurações Six', 'pageSubtitle': 'Configurações gerais do Six.', 'save': 'Salvar', 'settingsSaved': 'Configurações salvas com sucesso.', 'settingsSaveError': 'Erro ao salvar configurações', 'systemLanguage': 'Idioma do sistema', 'visualTheme': 'Tema visual', 'companyName': 'Nome da empresa', 'tradeName': 'Nome fantasia', 'mainEmail': 'Email principal'},
    'en': {'pageTitle': 'Six Settings', 'pageSubtitle': 'Six general settings.', 'save': 'Save', 'settingsSaved': 'Settings saved successfully.', 'settingsSaveError': 'Error saving settings', 'systemLanguage': 'System language', 'visualTheme': 'Visual theme', 'companyName': 'Company name', 'tradeName': 'Trade name', 'mainEmail': 'Main email'},
    'es': {'pageTitle': 'Configuración Six', 'pageSubtitle': 'Configuración general de Six.', 'save': 'Guardar', 'settingsSaved': 'Configuración guardada con éxito.', 'settingsSaveError': 'Error al guardar configuración', 'systemLanguage': 'Idioma del sistema', 'visualTheme': 'Tema visual', 'companyName': 'Nombre de la empresa', 'tradeName': 'Nombre comercial', 'mainEmail': 'Email principal'},
  };

  static const _options = {
    'pt': {'pt-BR': 'Português (Brasil)', 'en-US': 'English (US)', 'es-ES': 'Español', 'Claro': 'Claro', 'Escuro': 'Escuro', 'Automático': 'Automático'},
    'en': {'pt-BR': 'Portuguese (Brazil)', 'en-US': 'English (US)', 'es-ES': 'Spanish', 'Claro': 'Light', 'Escuro': 'Dark', 'Automático': 'Automatic'},
    'es': {'pt-BR': 'Portugués (Brasil)', 'en-US': 'Inglés (US)', 'es-ES': 'Español', 'Claro': 'Claro', 'Escuro': 'Oscuro', 'Automático': 'Automático'},
  };
}
