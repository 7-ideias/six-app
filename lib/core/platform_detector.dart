import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// Detecção centralizada de plataforma + viewport.
// Use SEMPRE este helper em vez de chamar kIsWeb / MediaQuery diretamente
// em pontos de decisão de layout — assim quando o breakpoint mudar, muda só
// em web_root_tokens.dart.
class PlatformDetector {
  PlatformDetector._();

  static bool get isWeb => kIsWeb;

  // Versões puras (não exigem BuildContext) — úteis em locais sem contexto.
  // Para uso em widgets, prefira as variantes `of(context)`.
  static bool isDesktopWidth(double width) =>
      width >= WebRootTokens.bpDesktopMin;
  static bool isMobileWidth(double width) =>
      width <= WebRootTokens.bpMobileMax;
  static bool isTabletWidth(double width) =>
      width > WebRootTokens.bpMobileMax &&
      width < WebRootTokens.bpDesktopMin;

  // ── Versões com BuildContext ──────────────────────────────────────────
  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isDesktopWebOf(BuildContext context) =>
      isWeb && isDesktopWidth(widthOf(context));

  static bool isMobileWebOf(BuildContext context) =>
      isWeb && !isDesktopWidth(widthOf(context));

  // Conveniente para gating: a rota / só faz sentido em contexto navegador.
  static bool shouldRenderWebRoot(BuildContext context) => isWeb;
}
