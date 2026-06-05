import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/widgets.dart';

// Equivalente Flutter ao <Container> do Primitives.jsx:
//   max-width 1200; padding 0 56 no desktop; gutter 20 no mobile.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    required this.isDesktop,
    this.verticalPadding = 0,
  });

  final Widget child;
  final bool isDesktop;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final horizontal = isDesktop
        ? WebRootTokens.gutterDesktop
        : WebRootTokens.gutterMobile;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: WebRootTokens.containerMaxWidth,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
