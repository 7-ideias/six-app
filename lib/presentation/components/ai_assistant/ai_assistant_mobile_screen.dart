import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/six_i18n.dart';
import 'ai_assistant_panel.dart';

class AiAssistantMobileScreen extends StatelessWidget {
  const AiAssistantMobileScreen({
    super.key,
    required this.modulo,
    required this.telaAtual,
    this.onOpenSupport,
  });

  final String modulo;
  final String telaAtual;
  final VoidCallback? onOpenSupport;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      l10n?.aiAssistantAsk ?? 'Perguntar a IA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onOpenSupport != null)
                    TextButton.icon(
                      onPressed: onOpenSupport,
                      icon: const Icon(Icons.support_agent_rounded),
                      label: Text(
                        context.t(
                          'chatSupport.lis.open',
                          fallback: 'Suporte',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: AiAssistantConversationBody(
                  modulo: modulo,
                  telaAtual: telaAtual,
                  isMobile: true,
                  onOpenSupport: onOpenSupport,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
