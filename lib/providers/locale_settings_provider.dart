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
  bool _regionalizacaoLoading = false;
  bool _regionalizacaoSaving = false;
  String? _regionalizacaoError;

  bool get initialized => _initialized;

  /// `true` enquanto uma busca de traduções de UI está em andamento.
  bool get i18nLoading => _i18nLoading;

  bool get regionalizacaoLoading => _regionalizacaoLoading;

  bool get regionalizacaoSaving => _regionalizacaoSaving;

  String? get regionalizacaoError => _regionalizacaoError;

  ConfiguracaoRegionalizacaoSistema get companyConfig => _companyConfig;

  Locale get currentLocale =>
      _sanitizeLocale(_userOverrideLocale ?? _companyConfig.locale);

  AppRegionalFormatting get currentFormatting => _companyConfig.formatting;

  String get languageCode => _companyConfig.languageCode;

  String get countryCode => _companyConfig.countryCode;

  String get currencyCode => currentFormatting.currencyCode;

  String get timeZone => currentFormatting.timeZone;

  String get dateFormat => currentFormatting.dateFormat;

  String get timeFormat => currentFormatting.timeFormat;

  String get decimalSeparator => currentFormatting.decimalSeparator;

  String get thousandSeparator => currentFormatting.thousandSeparator;

  String get firstDayOfWeek => currentFormatting.firstDayOfWeek;

  String get numberPattern => currentFormatting.numberPattern;

  int get decimalPlaces => currentFormatting.decimalPlaces;

  bool get allowMultipleCurrencies => currentFormatting.allowMultipleCurrencies;

  bool get applyFinancialRounding => currentFormatting.applyFinancialRounding;

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

  Future<ConfiguracaoRegionalizacaoSistema> carregarRegionalizacaoDaEmpresa() async {
    _regionalizacaoLoading = true;
    _regionalizacaoError = null;
    notifyListeners();

    try {
      final response = await _regionalizacaoService.buscarRegionalizacao();
      final config = _regionalizacaoService.converterResponseParaDominio(
        response,
      );
      _companyConfig = config;
      return config;
    } catch (e) {
      _regionalizacaoError = _normalizarErro(e);
      rethrow;
    } finally {
      _regionalizacaoLoading = false;
      notifyListeners();
    }
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

  Future<ConfiguracaoRegionalizacaoSistema> saveCompanyConfig(
    ConfiguracaoRegionalizacaoSistema config,
  ) {
    return _salvarConfiguracaoRegionalizacao(
      config,
      aplicarIdiomaDaEmpresa: false,
    );
  }

  /// Salva a regionalização da empresa e aplica o idioma da empresa no app.
  ///
  /// Essa chamada é usada pela tela de Regionalização. Ela não persiste
  /// preferência individual de usuário; apenas remove o override local para que
  /// o locale corrente volte a ser o da configuração da empresa recém-salva.
  Future<ConfiguracaoRegionalizacaoSistema> saveCompanyConfigAndApply(
    ConfiguracaoRegionalizacaoSistema config,
  ) {
    return _salvarConfiguracaoRegionalizacao(
      config,
      aplicarIdiomaDaEmpresa: true,
    );
  }

  Future<ConfiguracaoRegionalizacaoSistema> _salvarConfiguracaoRegionalizacao(
    ConfiguracaoRegionalizacaoSistema config, {
    required bool aplicarIdiomaDaEmpresa,
  }) async {
    _regionalizacaoSaving = true;
    _regionalizacaoError = null;
    notifyListeners();

    try {
      final configSalva = await _regionalizacaoService.salvarRegionalizacao(
        config,
      );
      _companyConfig = configSalva;

      if (aplicarIdiomaDaEmpresa) {
        await clearUserOverride(loadTranslations: false);
        await _loadTranslations(configSalva.locale, force: true);
      } else {
        notifyListeners();
      }

      return configSalva;
    } catch (e) {
      _regionalizacaoError = _normalizarErro(e);
      rethrow;
    } finally {
      _regionalizacaoSaving = false;
      notifyListeners();
    }
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

  String formatDecimal(num value) {
    final int casasDecimais = decimalPlaces.clamp(0, 6).toInt();
    final String normalizado = value.toStringAsFixed(casasDecimais);
    final bool negativo = normalizado.startsWith('-');
    final List<String> partes = normalizado.replaceFirst('-', '').split('.');
    final String inteiro = _aplicarSeparadorDeMilhar(partes.first);
    final String decimal = casasDecimais > 0 && partes.length > 1
        ? '$decimalSeparator${partes[1]}'
        : '';

    return '${negativo ? '-' : ''}$inteiro$decimal';
  }

  String formatCurrency(num value, {bool showCurrencyCode = true}) {
    final String valor = formatDecimal(value);
    return showCurrencyCode ? '$currencyCode $valor' : valor;
  }

  String formatDate(DateTime value) {
    final String day = _twoDigits(value.day);
    final String month = _twoDigits(value.month);
    final String year = value.year.toString().padLeft(4, '0');

    switch (dateFormat) {
      case 'MM/dd/yyyy':
        return '$month/$day/$year';
      case 'yyyy-MM-dd':
        return '$year-$month-$day';
      case 'dd-MM-yyyy':
        return '$day-$month-$year';
      case 'dd/MM/yyyy':
      default:
        return '$day/$month/$year';
    }
  }

  String formatTime(DateTime value) {
    if (timeFormat.toLowerCase() == '12h') {
      final bool afternoon = value.hour >= 12;
      final int hour12 = value.hour == 0
          ? 12
          : value.hour > 12
              ? value.hour - 12
              : value.hour;
      return '${_twoDigits(hour12)}:${_twoDigits(value.minute)} ${afternoon ? 'PM' : 'AM'}';
    }

    return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }

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

  String _aplicarSeparadorDeMilhar(String value) {
    final buffer = StringBuffer();
    int contador = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      if (contador > 0 && contador % 3 == 0) {
        buffer.write(thousandSeparator);
      }
      buffer.write(value[i]);
      contador++;
    }

    return buffer.toString().split('').reversed.join();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _normalizarErro(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }
}
