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
      isDark ? const Color(0xFF0D1B2A) : WebRootTokens.surface;

  /// Fundo alternado das sections (features) — visivelmente mais escuro que surfacePage.
  Color get bgCanvas =>
      isDark ? const Color(0xFF081422) : WebRootTokens.bgCanvas;

  /// Fundo de cards (feature cards, plan cards não-featured) — destaca sobre o fundo.
  Color get cardBg =>
      isDark ? const Color(0xFF1B2F47) : WebRootTokens.surface;

  /// Fundo do header desktop (sólido).
  Color get headerBgDesktop =>
      isDark ? const Color(0xFF0A1624) : WebRootTokens.surface;

  /// Fundo do header mobile (semi-transparente, igual ao light original).
  Color get headerBgMobile =>
      isDark ? const Color(0xF00A1624) : const Color(0xEBFFFFFF);

  /// Banner CTA e featured plan — sempre escuro.
  Color get ctaBannerBg => WebRootTokens.ink;

  // ── Text ─────────────────────────────────────────────────────────────────
  Color get textPrimary =>
      isDark ? const Color(0xFFEDF3F9) : WebRootTokens.ink;
  Color get textSoft =>
      isDark ? const Color(0xFFB8C4CE) : WebRootTokens.fgSoft;
  Color get textMuted =>
      isDark ? const Color(0xFF7A8FA0) : WebRootTokens.fgMuted;

  // ── Borders ───────────────────────────────────────────────────────────────
  Color get border =>
      isDark ? const Color(0xFF243650) : WebRootTokens.line;
  Color get borderSoft =>
      isDark ? const Color(0x22FFFFFF) : WebRootTokens.lineSoft;

  // ── Eyebrow pill ──────────────────────────────────────────────────────────
  Color get eyebrowBg =>
      isDark ? const Color(0xFF1C3350) : WebRootTokens.lineSoft;

  // ── Language/dark toggle hover ────────────────────────────────────────────
  Color get hoverBg =>
      isDark ? const Color(0xFF182A3E) : WebRootTokens.surfaceAlt;
}
