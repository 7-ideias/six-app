import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/regionalizacao_models.dart';
import '../data/services/i18n/web_i18n_api_client.dart';
import '../domain/models/regionalizacao_models.dart';
import '../domain/services/regionalizacao/regionalizacao_service.dart';
import '../l10n/web_i18n_store.dart';

class LocaleSettingsProvider extends ChangeNotifier {
  LocaleSettingsProvider({
    required RegionalizacaoService regionalizacaoService,
    WebI18nApiClient? webI18nApiClient,
  }) : _regionalizacaoService = regionalizacaoService,
       _webI18nApiClient = webI18nApiClient ?? WebI18nApiClient();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt', 'BR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  static const Locale _systemFallbackLocale = Locale('pt', 'BR');
  static const String _languageCodeKey = 'user_language_code';
  static const String _countryCodeKey = 'user_country_code';

  final RegionalizacaoService _regionalizacaoService;
  final WebI18nApiClient _webI18nApiClient;

  /// Locales cujas traduções de UI já foram buscadas no backend nesta sessão.
  final Set<String> _loadedI18nTags = <String>{};

  ConfiguracaoRegionalizacaoSistema _companyConfig =
      ConfiguracaoRegionalizacaoSistema.defaultConfiguration();
  Locale? _userOverrideLocale;
  bool _initialized = false;
  bool _i18nLoading = false;

  bool get initialized => _initialized;

  /// `true` enquanto uma busca de traduções de UI está em andamento. Usado pelo
  /// `WebI18nGate` para exibir carregamento vs. estado de erro.
  bool get i18nLoading => _i18nLoading;

  ConfiguracaoRegionalizacaoSistema get companyConfig => _companyConfig;

  Locale get currentLocale =>
      _sanitizeLocale(_userOverrideLocale ?? _companyConfig.locale);

  AppRegionalFormatting get currentFormatting => _companyConfig.formatting;

  Future<void> initialize() async {
    await _loadUserOverride();
    if (_userOverrideLocale == null) {
      final browserLocale = _detectSystemLocale();
      _companyConfig = _companyConfig.copyWith(
        languageCode: browserLocale.languageCode,
        countryCode:
            browserLocale.countryCode ?? _systemFallbackLocale.countryCode!,
      );
    }
    _initialized = true;
    notifyListeners();

    // Busca as traduções de UI do backend (única fonte de conteúdo). O
    // WebI18nGate exibe carregamento até o store estar pronto.
    await _loadWebTranslations(currentLocale);
  }

  Future<void> refreshCompanyConfig() async {
    notifyListeners();
  }

  Future<void> atualizarConfiguracaoDaEmpresaPorResponse(
    ConfiguracaoRegionalizacaoResponse response,
  ) async {
    _companyConfig = _regionalizacaoService.converterResponseParaDominio(
      response,
    );
    notifyListeners();
  }

  Future<void> atualizarConfiguracaoDaEmpresa(
    ConfiguracaoRegionalizacaoSistema config,
  ) async {
    _companyConfig = config;
    notifyListeners();
  }

  Future<void> saveCompanyConfig(
    ConfiguracaoRegionalizacaoSistema config,
  ) async {
    await _regionalizacaoService.salvarRegionalizacao(config);
    _companyConfig = config;
    notifyListeners();
  }

  Future<void> setUserLocale(Locale locale) async {
    final sanitized = _sanitizeLocale(locale);
    _userOverrideLocale = sanitized;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, sanitized.languageCode);
    await prefs.setString(
      _countryCodeKey,
      sanitized.countryCode ?? _systemFallbackLocale.countryCode!,
    );

    notifyListeners();

    await _loadWebTranslations(sanitized);
  }

  /// Força uma nova busca das traduções do locale corrente (botão "tentar
  /// novamente" do `WebI18nGate` após uma falha de rede).
  Future<void> reloadWebTranslations() =>
      _loadWebTranslations(currentLocale, force: true);

  /// Busca as traduções de UI do backend para [locale] e as injeta no
  /// [WebI18nStore].
  ///
  /// Idempotente por sessão: um idioma já carregado não é rebuscado (atende
  /// "só chama o backend ao trocar de idioma"), salvo [force] = `true`.
  Future<void> _loadWebTranslations(Locale locale, {bool force = false}) async {
    final tag = locale.toLanguageTag();
    if (!force && _loadedI18nTags.contains(tag)) return;

    _i18nLoading = true;
    notifyListeners();

    final messages = await _webI18nApiClient.fetchMessages(tag);
    if (messages != null) {
      WebI18nStore.instance.setMessages(locale.languageCode, messages);
      _loadedI18nTags.add(tag);
    }

    _i18nLoading = false;
    notifyListeners();
  }

  Future<void> clearUserOverride() async {
    _userOverrideLocale = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageCodeKey);
    await prefs.remove(_countryCodeKey);

    notifyListeners();
  }

  Future<void> _loadUserOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    final countryCode = prefs.getString(_countryCodeKey);

    if (languageCode == null || languageCode.isEmpty) {
      _userOverrideLocale = null;
      return;
    }

    _userOverrideLocale = _sanitizeLocale(Locale(languageCode, countryCode));
  }

  Locale _sanitizeLocale(Locale locale) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode &&
          supported.countryCode == locale.countryCode) {
        return supported;
      }
    }

    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }

    return _systemFallbackLocale;
  }

  Locale _detectSystemLocale() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    for (final locale in locales) {
      for (final supported in supportedLocales) {
        if (supported.languageCode == locale.languageCode) {
          return supported;
        }
      }
    }

    return _systemFallbackLocale;
  }
}
