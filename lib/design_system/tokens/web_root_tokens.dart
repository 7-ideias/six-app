import 'package:flutter/material.dart';

// Design tokens extraídos do Six POS Design System (ui_kits/web + mobile/index.html).
// Mantém paridade com colors_and_type.css e o mood "corporate" do LandingSections.jsx.
class WebRootTokens {
  WebRootTokens._();

  // ── Paleta ────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF0F2D3A);
  static const Color inkDeep = Color(0xFF0F1A14);
  static const Color accent = Color(0xFFF5A12C);
  static const Color bgCanvas = Color(0xFFF4F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color field = Color(0xFFF1F3F2);
  static const Color fg = Color(0xFF1A1A1A);
  static const Color fgSoft = Color(0xFF555555);
  static const Color fgMuted = Color(0xFF8A8F8D);
  static const Color line = Color(0xFFE3E6E5);
  static const Color lineSoft = Color(0x140F2D3A); // rgba(15,45,58,0.08)
  static const Color success = Color(0xFF16A34A);
  // Hover bg leve para botões/triggers no header (equivalent a hsl(210 8% 95%))
  static const Color surfaceAlt = Color(0xFFF0F2F3);

  // Cores auxiliares dos cards de features
  static const Color featureTeal = Color(0xFF0F766E);
  static const Color featureBlue = Color(0xFF1D4ED8);
  static const Color featurePurple = Color(0xFF7C3AED);
  static const Color featureCyan = Color(0xFF0EA5E9);

  // ── Tipografia ────────────────────────────────────────────────────────
  // Inter é a font do design (Google Fonts). Como o projeto não usa
  // google_fonts, caímos no system stack (-apple-system/Segoe UI/Roboto).
  static const String fontFamily = 'Inter';
  static const List<String> fontFamilyFallback = <String>[
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'system-ui',
    'sans-serif',
  ];

  // ── Raios ─────────────────────────────────────────────────────────────
  static const double radiusBtn = 14;
  static const double radiusCard = 16;
  static const double radiusBig = 20;
  static const double radiusPill = 999;

  // ── Spacing / gutter ──────────────────────────────────────────────────
  // Mobile: --gutter: 20px (CSS). Desktop usa container padding 56.
  static const double gutterMobile = 20;
  static const double gutterDesktop = 56;
  static const double containerMaxWidth = 1200;
  static const double mobileContentMaxWidth = 480; // body max-width no CSS mobile

  // ── Shadows ───────────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A0F2D3A), // rgba(15,45,58,0.04)
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x080F2D3A), // rgba(15,45,58,0.03)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> cardHoverShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A0F2D3A),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x0D0F2D3A),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> featuredPlanShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x400F2D3A),
      blurRadius: 48,
      offset: Offset(0, 24),
    ),
  ];

  static const List<BoxShadow> phoneShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x590F2D3A), // 0.35
      blurRadius: 80,
      offset: Offset(0, 50),
    ),
    BoxShadow(
      color: Color(0x2E0F2D3A), // 0.18
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];

  // ── Breakpoints ───────────────────────────────────────────────────────
  // Centralizados aqui (NÃO duplicar em outros lugares). web_root_provider
  // e platform_detector consomem estes valores.
  static const double bpMobileMax = 767;   // <768 = mobile
  static const double bpTabletMax = 1023;  // 768..1023 = tablet (renderiza mobile)
  static const double bpDesktopMin = 1024; // >=1024 = desktop

  // ── Tipografia: estilos derivados ─────────────────────────────────────
  // Helpers para evitar hardcode de TextStyle nas seções. Cada chamada
  // já aplica fontFamily + fallback + color default.
  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = fg,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // Hero h1: 56/38 (desktop/mobile), weight 700, line-height 1.05
  static TextStyle heroTitleDesktop = _base(
    size: 56,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: -1,
    height: 1.05,
  );
  static TextStyle heroTitleMobile = _base(
    size: 38,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: -1,
    height: 1.05,
  );

  // Section h2: 38/28
  static TextStyle sectionTitleDesktop = _base(
    size: 38,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.4,
    height: 1.15,
  );
  static TextStyle sectionTitleMobile = _base(
    size: 28,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.4,
    height: 1.15,
  );

  // Body lead (sub): 18/16
  static TextStyle leadDesktop = _base(
    size: 18,
    weight: FontWeight.w400,
    color: fgSoft,
    height: 1.55,
  );
  static TextStyle leadMobile = _base(
    size: 16,
    weight: FontWeight.w400,
    color: fgSoft,
    height: 1.55,
  );

  // Eyebrow: uppercase 12px (desktop) / 11px (mobile), weight 700, tracking 1.4
  static TextStyle eyebrowDesktop = _base(
    size: 12,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: 1.4,
  );
  static TextStyle eyebrowMobile = _base(
    size: 11,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: 1.4,
  );

  // Botões: 15/16
  static TextStyle buttonLg = _base(size: 16, weight: FontWeight.w600);
  static TextStyle buttonMd = _base(size: 15, weight: FontWeight.w600);
  static TextStyle buttonSm = _base(size: 14, weight: FontWeight.w600);

  // Feature card
  static TextStyle featureTitle = _base(
    size: 18,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.2,
  );
  static TextStyle featureTitleMobile = _base(
    size: 16,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.2,
  );
  static TextStyle featureBody = _base(
    size: 14,
    weight: FontWeight.w400,
    color: fgSoft,
    height: 1.55,
  );

  // Plan / pricing
  static TextStyle planName = _base(
    size: 14,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: 0.5,
  );
  static TextStyle planPriceDesktop = _base(
    size: 40,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.5,
    height: 1.05,
  );
  static TextStyle planPriceMobile = _base(
    size: 34,
    weight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.5,
    height: 1,
  );

  // Footer
  static TextStyle footerColHeader = _base(
    size: 12,
    weight: FontWeight.w700,
    color: accent,
    letterSpacing: 1.2,
  );
  static TextStyle footerLink = _base(
    size: 13,
    weight: FontWeight.w400,
    color: Color(0xBFFFFFFF),
  );
}
