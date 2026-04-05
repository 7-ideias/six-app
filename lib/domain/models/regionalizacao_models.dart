import 'package:flutter/material.dart';

class AppRegionalFormatting {
  const AppRegionalFormatting({
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

  factory AppRegionalFormatting.defaultFormatting() {
    return const AppRegionalFormatting(
      currencyCode: 'BRL',
      timeZone: 'America/Sao_Paulo',
      dateFormat: 'dd/MM/yyyy',
      timeFormat: '24h',
      decimalSeparator: ',',
      thousandSeparator: '.',
      firstDayOfWeek: 'MONDAY',
      numberPattern: '#,##0.00',
      decimalPlaces: 2,
      allowMultipleCurrencies: false,
      applyFinancialRounding: true,
    );
  }
}

class ConfiguracaoRegionalizacaoSistema {
  const ConfiguracaoRegionalizacaoSistema({
    this.id,
    this.idEmpresa,
    required this.languageCode,
    required this.countryCode,
    required this.formatting,
  });

  final String? id;
  final String? idEmpresa;
  final String languageCode;
  final String countryCode;
  final AppRegionalFormatting formatting;

  Locale get locale => Locale(languageCode, countryCode);

  factory ConfiguracaoRegionalizacaoSistema.defaultConfiguration() {
    return ConfiguracaoRegionalizacaoSistema(
      languageCode: 'pt',
      countryCode: 'BR',
      formatting: AppRegionalFormatting.defaultFormatting(),
    );
  }

  ConfiguracaoRegionalizacaoSistema copyWith({
    String? id,
    String? idEmpresa,
    String? languageCode,
    String? countryCode,
    AppRegionalFormatting? formatting,
  }) {
    return ConfiguracaoRegionalizacaoSistema(
      id: id ?? this.id,
      idEmpresa: idEmpresa ?? this.idEmpresa,
      languageCode: languageCode ?? this.languageCode,
      countryCode: countryCode ?? this.countryCode,
      formatting: formatting ?? this.formatting,
    );
  }
}
