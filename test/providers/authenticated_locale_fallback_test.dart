import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/data/services/i18n/web_i18n_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class Regionalization implements RegionalizacaoService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Translations implements SixI18nApiClient {
  @override
  Future<Map<String, dynamic>?> fetchMessages(
    String languageTag, {
    bool force = false,
  }) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'missing authenticated configuration does not inherit public language',
    () async {
      final provider = LocaleSettingsProvider(
        regionalizacaoService: Regionalization(),
        i18nApiClient: Translations(),
      );
      addTearDown(provider.dispose);
      await provider.setUserLocale(const Locale('en', 'US'));
      final currency = provider.currencyCode;
      await provider.applyAuthenticatedLocale(idiomaDePreferencia: 'DEFAULT');
      expect(provider.currentLocale, const Locale('pt', 'BR'));
      expect(provider.currencyCode, currency);
    },
  );
  test(
    'saved individual preference remains canonical without company locale',
    () async {
      final provider = LocaleSettingsProvider(
        regionalizacaoService: Regionalization(),
        i18nApiClient: Translations(),
      );
      addTearDown(provider.dispose);
      await provider.applyAuthenticatedLocale(idiomaDePreferencia: 'es-ES');
      expect(provider.currentLocale, const Locale('es', 'ES'));
    },
  );
}
