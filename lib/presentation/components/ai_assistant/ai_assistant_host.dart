import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'ai_assistant_button.dart';
import 'ai_assistant_mobile_screen.dart';
import 'ai_assistant_panel.dart';

class AiAssistantWebBridge {
  AiAssistantWebBridge._();

  static final ValueNotifier<int> _toggleSignal = ValueNotifier<int>(0);

  static ValueListenable<int> get toggleSignal = _toggleSignal;

  static void toggle() {
    _toggleSignal.value = _toggleSignal.value + 1;
  }
}

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
  static const Duration _webPanelAnimationDuration = Duration(milliseconds: 320);
  static const Curve _webPanelOpenCurve = Curves.easeOutCubic;
  static const Curve _webPanelCloseCurve = Curves.easeInOutCubic;

  bool _panelOpen = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      AiAssistantWebBridge.toggleSignal.addListener(_togglePanelFromTopbar);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      AiAssistantWebBridge.toggleSignal.removeListener(_togglePanelFromTopbar);
    }
    super.dispose();
  }

  void _togglePanelFromTopbar() {
    if (!mounted) return;
    setState(() => _panelOpen = !_panelOpen);
  }

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
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (kIsWeb) _buildWebAnimatedBackdrop(),
        if (!kIsWeb)
          Positioned(
            right: 16,
            bottom: 90,
            child: AiAssistantButton(
              onTap: _togglePanel,
              label: 'Perguntar a IA',
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
            onTap: _togglePanel,
            child: Container(color: Colors.black.withOpacity(0.18)),
          ),
        ),
      ),
    );
  }

  Widget _buildWebAnimatedPanel() {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_panelOpen,
        child: AnimatedSlide(
          offset: _panelOpen ? Offset.zero : const Offset(0.10, 0),
          duration: _webPanelAnimationDuration,
          curve: _panelOpen ? _webPanelOpenCurve : _webPanelCloseCurve,
          child: AnimatedOpacity(
            opacity: _panelOpen ? 1 : 0,
            duration: _webPanelAnimationDuration,
            curve: _panelOpen ? _webPanelOpenCurve : _webPanelCloseCurve,
            child: RepaintBoundary(
              child: AiAssistantPanel(
                modulo: widget.modulo,
                telaAtual: widget.telaAtual,
                onClose: _togglePanel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
