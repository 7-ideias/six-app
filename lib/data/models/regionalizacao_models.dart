class ConfiguracaoRegionalizacaoResponse {
  ConfiguracaoRegionalizacaoResponse({
    this.id,
    this.idEmpresa,
    required this.languageCode,
    required this.countryCode,
    required this.currencyCode,
    required this.timeZone,
    required this.dateFormat,
    required this.timeFormat,
    required this.decimalSeparator,
    required this.thousandSeparator,
    required this.firstDayOfWeek,
    required this.numberPattern,
    required this.decimalPlaces,
    required this.allowMultipleCurrencies,
    required this.applyFinancialRounding,
  });

  final String? id;
  final String? idEmpresa;
  final String languageCode;
  final String countryCode;
  final String currencyCode;
  final String timeZone;
  final String dateFormat;
  final String timeFormat;
  final String decimalSeparator;
  final String thousandSeparator;
  final String firstDayOfWeek;
  final String numberPattern;
  final int decimalPlaces;
  final bool allowMultipleCurrencies;
  final bool applyFinancialRounding;

  factory ConfiguracaoRegionalizacaoResponse.fromJson(Map<String, dynamic> json) {
    final regionalizacao = json['regionalizacao'] is Map<String, dynamic>
        ? json['regionalizacao'] as Map<String, dynamic>
        : json;

    return ConfiguracaoRegionalizacaoResponse(
      id: regionalizacao['id']?.toString(),
      idEmpresa: regionalizacao['idEmpresa']?.toString(),
      languageCode: regionalizacao['languageCode']?.toString() ?? 'pt',
      countryCode: regionalizacao['countryCode']?.toString() ?? 'BR',
      currencyCode: regionalizacao['currencyCode']?.toString() ?? 'BRL',
      timeZone: regionalizacao['timeZone']?.toString() ?? 'America/Sao_Paulo',
      dateFormat: regionalizacao['dateFormat']?.toString() ?? 'dd/MM/yyyy',
      timeFormat: regionalizacao['timeFormat']?.toString() ?? '24h',
      decimalSeparator: regionalizacao['decimalSeparator']?.toString() ?? ',',
      thousandSeparator: regionalizacao['thousandSeparator']?.toString() ?? '.',
      firstDayOfWeek: regionalizacao['firstDayOfWeek']?.toString() ?? 'MONDAY',
      numberPattern: regionalizacao['numberPattern']?.toString() ?? '#,##0.00',
      decimalPlaces: (regionalizacao['decimalPlaces'] as num?)?.toInt() ?? 2,
      allowMultipleCurrencies: regionalizacao['allowMultipleCurrencies'] == true,
      applyFinancialRounding: regionalizacao['applyFinancialRounding'] != false,
    );
  }
}

class SalvarConfiguracaoRegionalizacaoRequest {
  const SalvarConfiguracaoRegionalizacaoRequest({
    required this.languageCode,
    required this.countryCode,
    required this.currencyCode,
    required this.timeZone,
    required this.dateFormat,
    required this.timeFormat,
    required this.decimalSeparator,
    required this.thousandSeparator,
    required this.firstDayOfWeek,
    required this.numberPattern,
    required this.decimalPlaces,
    required this.allowMultipleCurrencies,
    required this.applyFinancialRounding,
  });

  final String languageCode;
  final String countryCode;
  final String currencyCode;
  final String timeZone;
  final String dateFormat;
  final String timeFormat;
  final String decimalSeparator;
  final String thousandSeparator;
  final String firstDayOfWeek;
  final String numberPattern;
  final int decimalPlaces;
  final bool allowMultipleCurrencies;
  final bool applyFinancialRounding;

  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'timeZone': timeZone,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'decimalSeparator': decimalSeparator,
      'thousandSeparator': thousandSeparator,
      'firstDayOfWeek': firstDayOfWeek,
      'numberPattern': numberPattern,
      'decimalPlaces': decimalPlaces,
      'allowMultipleCurrencies': allowMultipleCurrencies,
      'applyFinancialRounding': applyFinancialRounding,
    };
  }
}
