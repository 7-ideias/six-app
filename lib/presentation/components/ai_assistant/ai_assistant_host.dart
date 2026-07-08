import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'ai_assistant_button.dart';
import 'ai_assistant_mobile_screen.dart';
import 'ai_assistant_panel.dart';

class AiAssistantHost extends StatefulWidget {
  const AiAssistantHost({
    super.key,
    required this.child,
    required this.modulo,
    required this.telaAtual,
  });

  final Widget child;
  final String modulo;
  final String telaAtual;

  @override
  State<AiAssistantHost> createState() => _AiAssistantHostState();
}

class _AiAssistantHostState extends State<AiAssistantHost> {
  bool _panelOpen = false;

  void _togglePanel() {
    if (kIsWeb) {
      setState(() => _panelOpen = !_panelOpen);
      return;
    }
    _openMobileAssistant();
  }

  Future<void> _openMobileAssistant() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: AiAssistantMobileScreen(
              modulo: widget.modulo,
              telaAtual: widget.telaAtual,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String label = l10n?.aiAssistantAsk ?? 'Perguntar a IA';

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (kIsWeb && _panelOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePanel,
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),
          ),
        Positioned(
          right: 16,
          bottom: kIsWeb ? 18 : 90,
          child: AiAssistantButton(
            onTap: _togglePanel,
            label: label,
            extended: kIsWeb,
          ),
        ),
        if (kIsWeb && _panelOpen)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: AiAssistantPanel(
              modulo: widget.modulo,
              telaAtual: widget.telaAtual,
              onClose: _togglePanel,
            ),
          ),
      ],
    );
  }
}
