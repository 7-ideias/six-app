import 'package:flutter/material.dart';
import '../../domain/models/aparencia_models.dart';
import 'six_color_contrast.dart';

enum DensidadeVisualSistema {
  compacta,
  confortavel,
  expandida;

  String get label {
    switch (this) {
      case DensidadeVisualSistema.compacta:
        return 'Compacta';
      case DensidadeVisualSistema.confortavel:
        return 'Confortável';
      case DensidadeVisualSistema.expandida:
        return 'Expandida';
    }
  }

  static DensidadeVisualSistema fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'compacta':
        return DensidadeVisualSistema.compacta;
      case 'expandida':
        return DensidadeVisualSistema.expandida;
      case 'confortavel':
      case 'confortável':
      default:
        return DensidadeVisualSistema.confortavel;
    }
  }
}

/// Classe responsável por centralizar a lógica de resolução do tema e paleta.
/// Atua como um ChangeNotifier para notificar a UI sobre mudanças globais.
class SixThemeResolver extends ChangeNotifier {
  static final SixThemeResolver _instance = SixThemeResolver._internal();
  factory SixThemeResolver() => _instance;
  SixThemeResolver._internal();

  PaletaSistema _paletaAtual = PaletaSistema.defaultPalette();
  TemaSistema _temaAtual = TemaSistema.claro;
  DensidadeVisualSistema _densidadeAtual = DensidadeVisualSistema.confortavel;

  void atualizarConfiguracao(ConfiguracaoAparenciaSistema configuracao) {
    _paletaAtual = configuracao.paleta;
    _temaAtual = configuracao.tema;
    notifyListeners();
  }

  /// Alterna entre claro e escuro sem alterar a paleta atual.
  /// Usado pelo toggle de dark mode nos headers web.
  void toggleDarkLight() {
    atualizarTema(
      _temaAtual == TemaSistema.escuro ? TemaSistema.claro : TemaSistema.escuro,
    );
  }

  /// Define o tema sem alterar paleta ou densidade visual.
  void atualizarTema(TemaSistema tema) {
    if (_temaAtual == tema) {
      return;
    }

    _temaAtual = tema;
    notifyListeners();
  }

  bool get isDark => _temaAtual == TemaSistema.escuro;

  PaletaSistema get paleta => _paletaAtual;
  TemaSistema get tema => _temaAtual;
  DensidadeVisualSistema get densidade => _densidadeAtual;

  void atualizarDensidade(DensidadeVisualSistema densidade) {
    if (_densidadeAtual == densidade) {
      return;
    }
    _densidadeAtual = densidade;
    notifyListeners();
  }

  VisualDensity get visualDensity {
    switch (_densidadeAtual) {
      case DensidadeVisualSistema.compacta:
        return const VisualDensity(horizontal: -1.0, vertical: -1.0);
      case DensidadeVisualSistema.expandida:
        return const VisualDensity(horizontal: 1.0, vertical: 1.0);
      case DensidadeVisualSistema.confortavel:
        return VisualDensity.standard;
    }
  }

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
    final Color accessiblePrimary = SixColorContrast.ensureForeground(
      primary,
      surface,
    );
    final Color accessibleSecondary = SixColorContrast.ensureForeground(
      secondary,
      surface,
    );
    final Color accessibleAccent = SixColorContrast.ensureForeground(
      accent,
      surface,
    );
    final Color accessibleAlert = SixColorContrast.ensureForeground(
      alert,
      surface,
    );

    return ColorScheme.light(
      primary: accessiblePrimary,
      onPrimary: SixColorContrast.onColor(accessiblePrimary),
      primaryContainer: primary,
      onPrimaryContainer: SixColorContrast.onColor(primary),
      secondary: accessibleSecondary,
      onSecondary: SixColorContrast.onColor(accessibleSecondary),
      secondaryContainer: secondary,
      onSecondaryContainer: SixColorContrast.onColor(secondary),
      tertiary: accessibleAccent,
      onTertiary: SixColorContrast.onColor(accessibleAccent),
      tertiaryContainer: accent,
      onTertiaryContainer: SixColorContrast.onColor(accent),
      error: accessibleAlert,
      onError: SixColorContrast.onColor(accessibleAlert),
      errorContainer: alert,
      onErrorContainer: SixColorContrast.onColor(alert),
      surface: surface,
      onSurface: SixColorContrast.ensureForeground(textPrimary, surface),
    );
  }

  ColorScheme getDarkScheme() {
    // Superfície canônica do SIX Web. Ela também é suficientemente próxima das
    // superfícies mobile para servir como referência segura para as paletas de
    // empresa no modo escuro.
    const Color darkSurface = Color(0xFF0F1B2D);
    final Color accessiblePrimary = SixColorContrast.ensureForeground(
      primary,
      darkSurface,
    );
    final Color accessibleSecondary = SixColorContrast.ensureForeground(
      secondary,
      darkSurface,
    );
    final Color accessibleAccent = SixColorContrast.ensureForeground(
      accent,
      darkSurface,
    );
    final Color accessibleAlert = SixColorContrast.ensureForeground(
      alert,
      darkSurface,
    );

    return ColorScheme.dark(
      primary: accessiblePrimary,
      onPrimary: SixColorContrast.onColor(accessiblePrimary),
      primaryContainer: primary,
      onPrimaryContainer: SixColorContrast.onColor(primary),
      secondary: accessibleSecondary,
      onSecondary: SixColorContrast.onColor(accessibleSecondary),
      secondaryContainer: secondary,
      onSecondaryContainer: SixColorContrast.onColor(secondary),
      tertiary: accessibleAccent,
      onTertiary: SixColorContrast.onColor(accessibleAccent),
      tertiaryContainer: accent,
      onTertiaryContainer: SixColorContrast.onColor(accent),
      error: accessibleAlert,
      onError: SixColorContrast.onColor(accessibleAlert),
      errorContainer: alert,
      onErrorContainer: SixColorContrast.onColor(alert),
      surface: darkSurface,
      onSurface: Colors.white,
    );
  }
}
