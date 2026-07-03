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
    SixI18nApiClient? i18nApiClient,
    WebI18nApiClient? webI18nApiClient,
  }) : _regionalizacaoService = regionalizacaoService,
       _i18nApiClient = i18nApiClient ?? webI18nApiClient ?? SixI18nApiClient();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt', 'BR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  static const Locale _systemFallbackLocale = Locale('pt', 'BR');
  static const String _languageCodeKey = 'user_language_code';
  static const String _countryCodeKey = 'user_country_code';
  static const String idiomaPreferenciaDefault = 'DEFAULT';

  final RegionalizacaoService _regionalizacaoService;
  final SixI18nApiClient _i18nApiClient;

  ConfiguracaoRegionalizacaoSistema _companyConfig =
      ConfiguracaoRegionalizacaoSistema.defaultConfiguration();
  Locale? _userOverrideLocale;
  bool _initialized = false;
  bool _i18nLoading = false;

  bool get initialized => _initialized;

  /// `true` enquanto uma busca de traduções de UI está em andamento.
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

    await _loadTranslations(currentLocale, force: false);
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

  /// Aplica a ordem de decisão do idioma para usuário autenticado:
  /// 1. preferência individual, quando diferente de DEFAULT;
  /// 2. regionalização da empresa;
  /// 3. locale detectado anteriormente no sistema/navegador;
  /// 4. pt-BR.
  Future<void> applyAuthenticatedLocale({
    String? idiomaDePreferencia,
    ConfiguracaoRegionalizacaoResponse? regionalizacao,
  }) async {
    if (regionalizacao != null) {
      _companyConfig = _regionalizacaoService.converterResponseParaDominio(
        regionalizacao,
      );
    }

    final preferenceLocale = _localeFromIdiomaDePreferencia(
      idiomaDePreferencia,
    );

    if (preferenceLocale != null) {
      await setUserLocale(preferenceLocale);
      return;
    }

    await clearUserOverride(loadTranslations: false);
    await _loadTranslations(currentLocale, force: true);
  }

  Future<void> setUserLocale(Locale locale) async {
    final sanitized = _sanitizeLocale(locale);
    _userOverrideLocale = sanitized;
    _i18nLoading = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, sanitized.languageCode);
    await prefs.setString(
      _countryCodeKey,
      sanitized.countryCode ?? _systemFallbackLocale.countryCode!,
    );

    notifyListeners();

    // Troca de idioma deve baixar o pacote completo do idioma ativo, persistir
    // localmente e remover os pacotes anteriores para economizar espaço.
    await _loadTranslations(sanitized, force: true, alreadyLoading: true);
  }

  /// Força uma nova busca das traduções do locale corrente.
  Future<void> reloadWebTranslations() => reloadTranslations();

  Future<void> reloadTranslations() =>
      _loadTranslations(currentLocale, force: true);

  Future<void> _loadTranslations(
    Locale locale, {
    bool force = false,
    bool alreadyLoading = false,
  }) async {
    final tag = locale.toLanguageTag();

    if (!alreadyLoading) {
      _i18nLoading = true;
      notifyListeners();
    }

    try {
      final messages = await _i18nApiClient.fetchMessages(tag, force: force);
      if (messages != null) {
        SixI18nStore.instance.setMessages(tag, messages);
        SixI18nStore.instance.keepOnly(tag);
      }
    } finally {
      _i18nLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearUserOverride({bool loadTranslations = true}) async {
    _userOverrideLocale = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageCodeKey);
    await prefs.remove(_countryCodeKey);

    notifyListeners();

    if (loadTranslations) {
      await _loadTranslations(currentLocale, force: true);
    }
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

  Locale? _localeFromIdiomaDePreferencia(String? idiomaDePreferencia) {
    if (idiomaDePreferencia == null || idiomaDePreferencia.trim().isEmpty) {
      return null;
    }

    final normalized = idiomaDePreferencia.trim().replaceAll('_', '-');
    if (normalized.toUpperCase() == idiomaPreferenciaDefault) {
      return null;
    }

    if (normalized.toLowerCase().startsWith('en')) {
      return const Locale('en', 'US');
    }
    if (normalized.toLowerCase().startsWith('es')) {
      return const Locale('es', 'ES');
    }
    if (normalized.toLowerCase().startsWith('pt')) {
      return const Locale('pt', 'BR');
    }

    return null;
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
