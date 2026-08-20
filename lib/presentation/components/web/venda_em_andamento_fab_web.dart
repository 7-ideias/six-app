import 'package:flutter/material.dart';

import '../../theme/web_theme_tokens.dart';

class VendaEmAndamentoFabWeb extends StatelessWidget {
  const VendaEmAndamentoFabWeb({
    super.key,
    required this.titulo,
    required this.resumo,
    required this.tooltip,
    required this.onPressed,
  });

  final String titulo;
  final String resumo;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    final bool reduzirMovimento =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);

    final Widget botao = Semantics(
      button: true,
      excludeSemantics: true,
      label: '$titulo. $resumo. $tooltip',
      child: FloatingActionButton.extended(
        key: const Key('venda-em-andamento-fab-web'),
        heroTag: null,
        tooltip: tooltip,
        onPressed: onPressed,
        elevation: 5,
        hoverElevation: 8,
        focusElevation: 7,
        backgroundColor: tokens.surfaceElevated,
        foregroundColor: tokens.primaryText,
        shape: StadiumBorder(
          side: BorderSide(
            color: tokens.warning.withValues(alpha: 0.58),
            width: 1.4,
          ),
        ),
        icon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: tokens.warning.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_cart_checkout_rounded,
            size: 19,
            color: tokens.warning,
          ),
        ),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 238),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      resumo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.secondaryText,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: tokens.warning,
              ),
            ],
          ),
        ),
      ),
    );

    if (reduzirMovimento) {
      return botao;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double progresso, Widget? child) {
        return Opacity(
          opacity: progresso,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - progresso)),
            child: Transform.scale(
              alignment: Alignment.bottomRight,
              scale: 0.96 + (0.04 * progresso),
              child: child,
            ),
          ),
        );
      },
      child: botao,
    );
  }
}
