import 'package:flutter/material.dart';

/// Margens únicas para páginas operacionais, medidas após a barra lateral.
class SixWebPageShell extends StatelessWidget {
  const SixWebPageShell({super.key, required this.child});

  static const double maxContentWidth = 1680;
  static const double sectionSpacing = 16;

  static double gutterFor(double availableWidth) {
    if (availableWidth < 1200) return 16;
    if (availableWidth < 1600) return 24;
    return 32;
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: gutterFor(constraints.maxWidth),
            vertical: 20,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        );
      },
    );
  }
}
