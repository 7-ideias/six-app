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
  static const Duration _webPanelAnimationDuration = Duration(
    milliseconds: 320,
  );
  static const Curve _webPanelOpenCurve = Curves.easeOutCubic;
  static const Curve _webPanelCloseCurve = Curves.easeInOutCubic;

  bool _panelOpen = false;
  bool _webPanelExpanded = false;
  bool _webPanelMinimized = false;

  void _handleAssistantButtonTap() {
    if (kIsWeb) {
      _openWebPanel();
      return;
    }
    _openMobileAssistant();
  }

  void _openWebPanel() {
    setState(() {
      _panelOpen = true;
      _webPanelMinimized = false;
    });
  }

  void _closeWebPanel() {
    setState(() {
      _panelOpen = false;
      _webPanelExpanded = false;
      _webPanelMinimized = false;
    });
  }

  void _minimizeWebPanel() {
    setState(() {
      _panelOpen = false;
      _webPanelExpanded = false;
      _webPanelMinimized = true;
    });
  }

  void _toggleWebPanelExpanded() {
    setState(() => _webPanelExpanded = !_webPanelExpanded);
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
    final String label =
        _webPanelMinimized
            ? l10n?.aiAssistantMinimizedLabel ?? 'Lis minimizada'
            : l10n?.aiAssistantAsk ?? 'Perguntar à IA';
    final String tooltip =
        _webPanelMinimized
            ? l10n?.aiAssistantMinimizedTooltip ?? 'Abrir assistente minimizado'
            : label;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (kIsWeb) _buildWebAnimatedBackdrop(),
        if (!kIsWeb || !_panelOpen)
          Positioned(
            right: 16,
            bottom: kIsWeb ? 18 : 90,
            child: AnimatedScale(
              scale: kIsWeb && _panelOpen ? 0.96 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AiAssistantButton(
                onTap: _handleAssistantButtonTap,
                label: label,
                tooltip: tooltip,
                extended: kIsWeb,
                highlighted: kIsWeb && _webPanelMinimized,
              ),
            ),
          ),
        if (kIsWeb) _buildWebAnimatedPanel(),
      ],
    );
  }

  Widget _buildWebAnimatedBackdrop() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_panelOpen,
        child: AnimatedOpacity(
          opacity: _panelOpen ? 1 : 0,
          duration: _webPanelAnimationDuration,
          curve: _panelOpen ? _webPanelOpenCurve : _webPanelCloseCurve,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeWebPanel,
            child: Container(color: Colors.black.withValues(alpha: 0.18)),
          ),
        ),
      ),
    );
  }

  Widget _buildWebAnimatedPanel() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_panelOpen,
        child: AnimatedSlide(
          offset: _panelOpen ? Offset.zero : const Offset(0, 0.04),
          duration: _webPanelAnimationDuration,
          curve: _panelOpen ? _webPanelOpenCurve : _webPanelCloseCurve,
          child: AnimatedOpacity(
            opacity: _panelOpen ? 1 : 0,
            duration: _webPanelAnimationDuration,
            curve: _panelOpen ? _webPanelOpenCurve : _webPanelCloseCurve,
            child: RepaintBoundary(
              child: SafeArea(
                minimum: const EdgeInsets.all(14),
                child: Center(
                  child: AiAssistantPanel(
                    modulo: widget.modulo,
                    telaAtual: widget.telaAtual,
                    onClose: _closeWebPanel,
                    onMinimize: _minimizeWebPanel,
                    expanded: _webPanelExpanded,
                    onToggleExpanded: _toggleWebPanelExpanded,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
