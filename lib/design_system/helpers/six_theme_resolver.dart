import 'package:flutter/material.dart';
import '../../domain/models/aparencia_models.dart';

/// Classe responsável por centralizar a lógica de resolução do tema e paleta.
/// Atua como um ChangeNotifier para notificar a UI sobre mudanças globais.
class SixThemeResolver extends ChangeNotifier {
  static final SixThemeResolver _instance = SixThemeResolver._internal();
  factory SixThemeResolver() => _instance;
  SixThemeResolver._internal();

  PaletaSistema _paletaAtual = PaletaSistema.defaultPalette();
  TemaSistema _temaAtual = TemaSistema.claro;

  void atualizarConfiguracao(ConfiguracaoAparenciaSistema configuracao) {
    _paletaAtual = configuracao.paleta;
    _temaAtual = configuracao.tema;
    notifyListeners();
  }

  PaletaSistema get paleta => _paletaAtual;
  TemaSistema get tema => _temaAtual;

  /// Retorna as cores principais de forma fácil de consumir
  Color get primary => _paletaAtual.primaria;
  Color get secondary => _paletaAtual.secundaria;
  Color get accent => _paletaAtual.destaque;
  Color get alert => _paletaAtual.alerta;
  Color get background => _paletaAtual.fundo;
  Color get surface => _paletaAtual.superficie;
  Color get textPrimary => _paletaAtual.textoPrimario;
  Color get textSecondary => _paletaAtual.textoSecundario;

  /// Converte TemaSistema para ThemeMode do Flutter
  ThemeMode get themeMode {
    switch (_temaAtual) {
      case TemaSistema.claro:
        return ThemeMode.light;
      case TemaSistema.escuro:
        return ThemeMode.dark;
      case TemaSistema.automatico:
        return ThemeMode.system;
    }
  }

  /// Gera um ColorScheme baseado na paleta atual
  ColorScheme getLightScheme() {
    return ColorScheme.light(
      primary: primary,
      onPrimary: _getContrastColor(primary),
      secondary: secondary,
      onSecondary: _getContrastColor(secondary),
      tertiary: accent,
      onTertiary: _getContrastColor(accent),
      error: alert,
      onError: _getContrastColor(alert),
      surface: surface,
      onSurface: textPrimary,
    );
  }

  ColorScheme getDarkScheme() {
    return ColorScheme.dark(
      primary: primary,
      onPrimary: _getContrastColor(primary),
      secondary: secondary,
      onSecondary: _getContrastColor(secondary),
      tertiary: accent,
      onTertiary: _getContrastColor(accent),
      error: alert,
      onError: _getContrastColor(alert),
      surface: const Color(0xFF121212), // Padrão Material Dark
      onSurface: Colors.white,
    );
  }

  Color _getContrastColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
