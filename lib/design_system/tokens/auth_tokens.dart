import 'package:flutter/material.dart';

/// Design tokens para as telas de autenticação (Login + Cadastro).
///
/// Todos os valores derivam do Figma:
/// https://www.figma.com/design/MfjBPME2K7ZfclAAhJQ8T7/Six?node-id=307-64
///
/// Nenhuma tela deve usar cores/espaçamentos/raios hardcoded —
/// todos devem referenciar estas constantes.
abstract final class SixAuthTokens {
  SixAuthTokens._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color colorBrand = Color(0xFF0F2D3A);

  // ── Campos (input) ────────────────────────────────────────────────────────
  /// Fundo branco — Figma: campo com fill white
  static const Color colorFieldFill = Color(0xFFFFFFFF);

  /// Borda padrão — Figma: #BCBCBC
  static const Color colorFieldBorder = Color(0xFFBCBCBC);

  /// Borda com foco — usa o brand
  static const Color colorFieldBorderFocused = colorBrand;

  /// Placeholder/hint — Figma: #555555
  static const Color colorFieldHint = Color(0xFF555555);

  /// Rótulo acima do campo — Figma: 12px Regular black
  static const Color colorFieldLabel = Color(0xFF000000);

  /// Raio de borda — Figma: 6px
  static const double radiusInput = 6.0;

  /// Altura do campo — Figma: 51px
  static const double heightInput = 51.0;

  static const EdgeInsets paddingInput = EdgeInsets.symmetric(
    vertical: 16,
    horizontal: 16,
  );

  // ── Botão primário ────────────────────────────────────────────────────────
  /// Fundo do botão principal — Figma: #0F2D3A
  static const Color colorButtonPrimaryBg = colorBrand;
  static const Color colorButtonPrimaryFg = Color(0xFFFFFFFF);

  /// Raio pill — Figma: 24px → aparência de pílula
  static const double radiusButtonPrimary = 24.0;

  /// Altura do botão primário — Figma: 51px
  static const double heightButtonPrimary = 51.0;

  static const double fontSizeButtonPrimary = 16.0;
  static const FontWeight fontWeightButtonPrimary = FontWeight.w600;

  // ── Botão Google (secundário) ─────────────────────────────────────────────
  static const Color colorButtonGoogleBg = Color(0xFFFFFFFF);
  static const Color colorButtonGoogleBorder = colorFieldBorder;

  /// Raio igual ao campo — Figma: 6px
  static const double radiusButtonGoogle = 6.0;

  /// Altura do botão Google — Figma: 50px
  static const double heightButtonGoogle = 50.0;

  // ── Tipografia ────────────────────────────────────────────────────────────
  static const Color colorTextPrimary = Color(0xFF000000);
  static const Color colorTextMuted = Color(0xFF555555);
  static const Color colorTextBrand = colorBrand;

  /// Título da tela — Figma: Inter Medium 24px
  static const double fontSizeTitle = 24.0;
  static const FontWeight fontWeightTitle = FontWeight.w500;

  /// Subtítulo / descrição — Figma: 14px Regular
  static const double fontSizeSubtitle = 14.0;
  static const FontWeight fontWeightSubtitle = FontWeight.w400;

  /// Rótulo do campo — Figma: 12px Regular
  static const double fontSizeLabel = 12.0;
  static const FontWeight fontWeightLabel = FontWeight.w400;

  /// Texto do campo — Figma: 14px Regular
  static const double fontSizeBody = 14.0;

  /// "Esqueci a senha" — Figma: Medium 12px underlined
  static const double fontSizeForgotPassword = 12.0;
  static const FontWeight fontWeightForgotPassword = FontWeight.w500;

  // ── Divisor ───────────────────────────────────────────────────────────────
  static const Color colorDivider = Color(0xFFE3E6E5);
  static const Color colorDividerText = Color(0xFF8A8F8D);

  // ── Shell ─────────────────────────────────────────────────────────────────
  static const Color colorShellBackground = Color(0xFFFFFFFF);

  /// Painel brand (web, lado esquerdo)
  static const Color colorBrandPanel = Color(0xFF0F1A14);

  static const double formPaneMaxWidth = 440.0;
  static const EdgeInsets formPanePaddingWeb = EdgeInsets.symmetric(
    horizontal: 48,
    vertical: 32,
  );
  static const EdgeInsets formPanePaddingMobile = EdgeInsets.fromLTRB(
    24,
    32,
    24,
    24,
  );

  // ── Back button (mobile) ──────────────────────────────────────────────────
  static const Color colorBackButtonBg = Color(0xFF1A1A1A);
  static const Color colorBackButtonFg = Color(0xFFFFFFFF);
  static const double sizeBackButton = 40.0;
  static const double radiusBackButton = 20.0;
}
