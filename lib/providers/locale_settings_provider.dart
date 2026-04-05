import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/regionalizacao_models.dart';
import '../domain/models/regionalizacao_models.dart';
import '../domain/services/regionalizacao/regionalizacao_service.dart';

class LocaleSettingsProvider extends ChangeNotifier {
  LocaleSettingsProvider({
    required RegionalizacaoService regionalizacaoService,
  }) : _regionalizacaoService = regionalizacaoService;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt', 'BR'),
    Locale('en', 'US'),
  ];

  static const Locale _systemFallbackLocale = Locale('pt', 'BR');
  static const String _languageCodeKey = 'user_language_code';
  static const String _countryCodeKey = 'user_country_code';

  final RegionalizacaoService _regionalizacaoService;

  ConfiguracaoRegionalizacaoSistema _companyConfig =
  ConfiguracaoRegionalizacaoSistema.defaultConfiguration();
  Locale? _userOverrideLocale;
  bool _initialized = false;

  bool get initialized => _initialized;

  ConfiguracaoRegionalizacaoSistema get companyConfig => _companyConfig;

  Locale get currentLocale =>
      _sanitizeLocale(_userOverrideLocale ?? _companyConfig.locale);

  AppRegionalFormatting get currentFormatting => _companyConfig.formatting;

  Future<void> initialize() async {
    await _loadUserOverride();
    _initialized = true;
    notifyListeners();
  }

  Future<void> refreshCompanyConfig() async {
    notifyListeners();
  }

  Future<void> atualizarConfiguracaoDaEmpresaPorResponse(
      ConfiguracaoRegionalizacaoResponse response,
      ) async {
    _companyConfig = _regionalizacaoService.converterResponseParaDominio(response);
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
}
