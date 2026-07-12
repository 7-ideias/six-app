import 'package:flutter/material.dart';

/// Fonte única das cores da experiência mobile do Six.
///
/// Alterações neste arquivo afetam somente telas e componentes mobile que
/// consomem esta paleta. O tema e as telas web permanecem independentes.
abstract final class SixMobilePalette {
  const SixMobilePalette._();

  // Identidade principal
  static const Color primary = Color(0xFF0B1F3A);
  static const Color secondary = Color(0xFF123B69);
  static const Color accent = Color(0xFF2563EB);

  // Estrutura
  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color softAccentSurface = Color(0xFFEFF6FF);
  static const Color softNeutralSurface = Color(0xFFF1F5F9);

  // Tipografia
  static const Color titleText = Color(0xFF0F172A);
  static const Color mutedText = Color(0xFF64748B);
  static const Color onPrimary = Colors.white;
  static const Color heroSupportingText = Color(0xFFD7E3F5);
  static const Color heroLabelText = Color(0xFFBFD0EA);

  // Estados e detalhes
  static const Color notificationBadge = Color(0xFFEF4444);
  static const Color activeBorder = Color(0xFFDCEBFF);
  static const Color highlightedBorder = Color(0xFFBFDBFE);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorBorder = Color(0xFFFCA5A5);

  // Sombras relacionadas à identidade visual
  static const Color heroShadow = Color(0x260B1F3A);
  static const Color navigationShadow = Color(0x1A0B1F3A);
}
