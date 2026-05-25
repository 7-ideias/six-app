import 'package:flutter/material.dart';
import 'web_root_tokens.dart';

/// Semantic color scheme para a landing page, com suporte a dark/light mode.
///
/// Uso dentro de um [build]:
/// ```dart
/// final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);
/// Container(color: scheme.surfacePage, child: Text('…', style: TextStyle(color: scheme.textPrimary)));
/// ```
class WebRootScheme {
  const WebRootScheme({required this.isDark});
  final bool isDark;

  // ── Backgrounds ──────────────────────────────────────────────────────────
  /// Fundo principal das sections brancas (hero, pricing).
  Color get surfacePage =>
      isDark ? const Color(0xFF0B1820) : WebRootTokens.surface;

  /// Fundo alternado das sections (features).
  Color get bgCanvas =>
      isDark ? const Color(0xFF071320) : WebRootTokens.bgCanvas;

  /// Fundo de cards (feature cards, plan cards não-featured).
  Color get cardBg =>
      isDark ? const Color(0xFF132538) : WebRootTokens.surface;

  /// Fundo do header desktop (sólido).
  Color get headerBgDesktop =>
      isDark ? const Color(0xFF0B1820) : WebRootTokens.surface;

  /// Fundo do header mobile (semi-transparente, igual ao light original).
  Color get headerBgMobile =>
      isDark ? const Color(0xEB0B1820) : const Color(0xEBFFFFFF);

  /// Banner CTA e featured plan — sempre escuro.
  Color get ctaBannerBg => WebRootTokens.ink;

  // ── Text ─────────────────────────────────────────────────────────────────
  Color get textPrimary =>
      isDark ? const Color(0xFFE8EEF3) : WebRootTokens.ink;
  Color get textSoft =>
      isDark ? const Color(0xFFB0BAC3) : WebRootTokens.fgSoft;
  Color get textMuted =>
      isDark ? const Color(0xFF7A8A95) : WebRootTokens.fgMuted;

  // ── Borders ───────────────────────────────────────────────────────────────
  Color get border =>
      isDark ? const Color(0xFF1E3040) : WebRootTokens.line;
  Color get borderSoft =>
      isDark ? const Color(0x1AFFFFFF) : WebRootTokens.lineSoft;

  // ── Eyebrow pill ──────────────────────────────────────────────────────────
  Color get eyebrowBg =>
      isDark ? const Color(0xFF1E3040) : WebRootTokens.lineSoft;

  // ── Language/dark toggle hover ────────────────────────────────────────────
  Color get hoverBg =>
      isDark ? const Color(0xFF162534) : WebRootTokens.surfaceAlt;
}
