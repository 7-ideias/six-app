import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'six_web_animated_dialog.dart';

/// Standard Web overlay for financial settings and their nested lists.
Future<T?> showFinanceiroConfiguracaoWebDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) => showSixWebAnimatedDialog<T>(
  context: context,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  padding: const EdgeInsets.all(16),
  builder: (dialogContext) => LayoutBuilder(
    builder: (context, constraints) {
      final tokens = WebThemeTokens.of(context);
      return Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                if (ModalRoute.of(dialogContext)?.isCurrent ?? false) {
                  Navigator.of(dialogContext).maybePop();
                }
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Semantics(
              namesRoute: true,
              label: title,
              child: Dialog(
                insetPadding: EdgeInsets.zero,
                backgroundColor: tokens.surfaceElevated,
                surfaceTintColor: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: tokens.cardBorder),
                ),
                child: SizedBox(
                  width: constraints.maxWidth.clamp(0, 1180).toDouble(),
                  height: constraints.maxHeight * .9,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  ),
);
