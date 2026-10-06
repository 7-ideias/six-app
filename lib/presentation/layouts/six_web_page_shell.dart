import 'package:flutter/material.dart';
import '../theme/six_web_action_styles.dart';

/// Margens únicas para páginas operacionais, medidas após a barra lateral.
class SixWebPageShell extends StatelessWidget {
  const SixWebPageShell({super.key, required this.child});

  static const double maxContentWidth = 1680;
  static const double verticalPadding = 20;
  static const double sectionSpacing = 16;
  static const EdgeInsets scrollPadding = EdgeInsets.only(bottom: 12);
  static const EdgeInsets bodyPadding = EdgeInsets.only(top: sectionSpacing);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    vertical: sectionSpacing,
  );
  static const Widget sectionGap = SizedBox(height: sectionSpacing);
  static const Widget columnGap = SizedBox(width: sectionSpacing);

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
            vertical: verticalPadding,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Theme(
                data: SixWebActionStyles.apply(Theme.of(context)),
                child: SizedBox(width: double.infinity, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mantém o intervalo após o cabeçalho em dados, loading, vazio e erro.
class SixWebPageBody extends StatelessWidget {
  const SixWebPageBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: SixWebPageShell.bodyPadding, child: child);
}
