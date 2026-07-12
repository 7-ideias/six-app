import 'package:flutter/material.dart';

/// Fonte única das cores da experiência mobile do Six.
///
/// A base visual é neutra para que ícones, bordas e estados de interação
/// tenham mais destaque. O tema e as telas web permanecem independentes.
abstract final class SixMobilePalette {
  const SixMobilePalette._();

  // Identidade principal
  static const Color primary = Color(0xFF252A31);
  static const Color secondary = Color(0xFF4B5563);
  static const Color accent = Color(0xFF2563EB);

  // Estrutura
  static const Color background = Color(0xFFF3F4F6);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFD1D5DB);
  static const Color softAccentSurface = Color(0xFFF4F6F8);
  static const Color softNeutralSurface = Color(0xFFF8FAFC);

  // Tipografia
  static const Color titleText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color onPrimary = Colors.white;
  static const Color heroSupportingText = Color(0xFFE5E7EB);
  static const Color heroLabelText = Color(0xFFD1D5DB);

  // Estados e detalhes
  static const Color notificationBadge = Color(0xFFDC2626);
  static const Color activeBorder = Color(0xFFCBD5E1);
  static const Color highlightedBorder = Color(0xFF93C5FD);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorBorder = Color(0xFFFCA5A5);

  // Sombras relacionadas à identidade visual
  static const Color heroShadow = Color(0x1F111827);
  static const Color navigationShadow = Color(0x14111827);
}
