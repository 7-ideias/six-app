import '../data/models/regionalizacao_models.dart';
import '../domain/models/regionalizacao_models.dart';

class ConfiguracaoRegionalizacaoMapper {
  static ConfiguracaoRegionalizacaoSistema fromResponse(
    ConfiguracaoRegionalizacaoResponse response,
  ) {
    return ConfiguracaoRegionalizacaoSistema(
      id: response.id,
      idEmpresa: response.idEmpresa,
      languageCode: response.languageCode,
      countryCode: response.countryCode,
      formatting: AppRegionalFormatting(
        currencyCode: response.currencyCode,
        timeZone: response.timeZone,
        dateFormat: response.dateFormat,
        timeFormat: response.timeFormat,
        decimalSeparator: response.decimalSeparator,
        thousandSeparator: response.thousandSeparator,
        firstDayOfWeek: response.firstDayOfWeek,
        numberPattern: response.numberPattern,
        decimalPlaces: response.decimalPlaces,
        allowMultipleCurrencies: response.allowMultipleCurrencies,
        applyFinancialRounding: response.applyFinancialRounding,
      ),
    );
  }

  static SalvarConfiguracaoRegionalizacaoRequest toRequest(
    ConfiguracaoRegionalizacaoSistema dominio,
  ) {
    return SalvarConfiguracaoRegionalizacaoRequest(
      languageCode: dominio.languageCode,
      countryCode: dominio.countryCode,
      currencyCode: dominio.formatting.currencyCode,
      timeZone: dominio.formatting.timeZone,
      dateFormat: dominio.formatting.dateFormat,
      timeFormat: dominio.formatting.timeFormat,
      decimalSeparator: dominio.formatting.decimalSeparator,
      thousandSeparator: dominio.formatting.thousandSeparator,
      firstDayOfWeek: dominio.formatting.firstDayOfWeek,
      numberPattern: dominio.formatting.numberPattern,
      decimalPlaces: dominio.formatting.decimalPlaces,
      allowMultipleCurrencies: dominio.formatting.allowMultipleCurrencies,
      applyFinancialRounding: dominio.formatting.applyFinancialRounding,
    );
  }
}
