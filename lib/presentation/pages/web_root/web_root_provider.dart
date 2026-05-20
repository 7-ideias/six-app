import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/widgets.dart';

// Estados de viewport que o WebRoot conhece. Tablet usa o mesmo layout
// que mobile (decisão do design — não há terceira variação).
enum WebRootDevice { mobile, tablet, desktop }

// State imutável exposto pelo provider. Inclui o computed `isMobileLayout`
// para evitar duplicar a regra "tablet renderiza como mobile" em cada
// consumer.
@immutable
class WebRootViewport {
  const WebRootViewport({required this.size, required this.device});

  final Size size;
  final WebRootDevice device;

  bool get isDesktop => device == WebRootDevice.desktop;
  bool get isTablet => device == WebRootDevice.tablet;
  bool get isMobile => device == WebRootDevice.mobile;

  // True quando o layout mobile deve ser usado (mobile real + tablet).
  bool get isMobileLayout => device != WebRootDevice.desktop;

  double get width => size.width;
  double get height => size.height;

  static WebRootDevice deviceFromWidth(double width) {
    if (width >= WebRootTokens.bpDesktopMin) return WebRootDevice.desktop;
    if (width > WebRootTokens.bpMobileMax) return WebRootDevice.tablet;
    return WebRootDevice.mobile;
  }

  factory WebRootViewport.fromSize(Size size) => WebRootViewport(
        size: size,
        device: deviceFromWidth(size.width),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebRootViewport &&
          other.size == size &&
          other.device == device;

  @override
  int get hashCode => Object.hash(size, device);
}

// ChangeNotifier (provider package — não Riverpod, conforme stack do projeto).
// Mantém o último viewport e só notifica quando o *device* muda. Isso evita
// rebuilds em resizes que não cruzam breakpoint.
class WebRootProvider extends ChangeNotifier {
  WebRootProvider();

  WebRootViewport? _viewport;

  WebRootViewport get viewport =>
      _viewport ?? const WebRootViewport(
        size: Size.zero,
        device: WebRootDevice.mobile,
      );

  // Chamado pelo LayoutBuilder em WebRootPage a cada constraint change.
  // Compara só o device — se largura mudou mas continua no mesmo bucket,
  // não notifica (rebuild fica isolado no LayoutBuilder).
  void updateFromConstraints(BoxConstraints constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final next = WebRootViewport.fromSize(size);
    final prev = _viewport;
    _viewport = next;
    if (prev == null || prev.device != next.device) {
      notifyListeners();
    }
  }
}
