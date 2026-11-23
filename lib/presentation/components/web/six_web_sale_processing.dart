import 'package:flutter/material.dart';

import '../../theme/web_theme_tokens.dart';

class SixWebSaleProcessing extends StatelessWidget {
  const SixWebSaleProcessing({
    super.key,
    required this.processing,
    required this.label,
    required this.child,
    this.description,
  });

  final bool processing;
  final String label;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: processing,
          child: ExcludeSemantics(excluding: processing, child: child),
        ),
        if (processing) ...[
          ModalBarrier(
            dismissible: false,
            color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.38),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: tokens.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: tokens.cardBorder),
                  ),
                  elevation: 6,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 24,
                            child: MediaQuery.disableAnimationsOf(context)
                                ? Icon(Icons.hourglass_top, color: tokens.info)
                                : CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: tokens.info,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: tokens.primaryText),
                                ),
                                if (description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    description!,
                                    style: TextStyle(color: tokens.secondaryText),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
