import 'package:flutter/material.dart';

/// Utilitários de contraste usados pelos temas e pelos tokens semânticos.
///
/// As cores de marca podem ser alteradas por empresa. Por isso, os componentes
/// interativos não devem assumir que a cor recebida continuará legível quando o
/// tema mudar. Esta classe preserva a cor original sempre que ela já atende ao
/// contraste mínimo e só a aproxima de preto ou branco quando necessário.
abstract final class SixColorContrast {
  SixColorContrast._();

  /// WCAG 2.x para textos de tamanho normal.
  static const double minimumTextRatio = 4.5;

  /// WCAG 2.x para limites e elementos gráficos essenciais.
  static const double minimumComponentRatio = 3.0;

  static const Color _lightForeground = Colors.white;
  static const Color _darkForeground = Colors.black;

  /// Calcula a razão de contraste considerando a transparência do foreground.
  static double ratio(Color foreground, Color background) {
    final Color opaqueForeground = Color.alphaBlend(foreground, background);
    final double foregroundLuminance = opaqueForeground.computeLuminance();
    final double backgroundLuminance = background.computeLuminance();
    final double lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final double darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Escolhe a melhor cor de conteúdo para um fundo sólido.
  static Color onColor(
    Color background, {
    Color light = _lightForeground,
    Color dark = _darkForeground,
  }) {
    return ratio(light, background) >= ratio(dark, background) ? light : dark;
  }

  /// Torna uma cor de conteúdo legível sobre [background].
  ///
  /// O resultado mantém a tonalidade original até o ponto mínimo necessário.
  static Color ensureForeground(
    Color foreground,
    Color background, {
    double minimumRatio = minimumTextRatio,
  }) {
    if (ratio(foreground, background) >= minimumRatio) {
      return foreground;
    }

    final Color target = onColor(background);
    if (ratio(target, background) < minimumRatio) {
      return target;
    }

    double lowerBound = 0;
    double upperBound = 1;
    Color candidate = target;

    // Busca a menor alteração possível que alcance o contraste solicitado.
    for (int index = 0; index < 18; index++) {
      final double amount = (lowerBound + upperBound) / 2;
      final Color mixed = Color.lerp(foreground, target, amount)!;
      if (ratio(mixed, background) >= minimumRatio) {
        candidate = mixed;
        upperBound = amount;
      } else {
        lowerBound = amount;
      }
    }

    return candidate;
  }
}
