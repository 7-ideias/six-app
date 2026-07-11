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
  static const Duration _webPanelAnimationDuration = Duration(milliseconds: 320);
  static const Curve _webPanelOpenCurve = Curves.easeOutCubic;
  static const Curve _webPanelCloseCurve = Curves.easeInOutCubic;

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
        if (kIsWeb) _buildWebAnimatedBackdrop(),
        if (kIsWeb)
          _buildWebTopbarButton(label)
        else
          Positioned(
            right: 16,
            bottom: 90,
            child: AiAssistantButton(
              onTap: _togglePanel,
              label: label,
            ),
          ),
        if (kIsWeb) _buildWebAnimatedPanel(),
      ],
    );
  }

  Widget _buildWebTopbarButton(String label) {
    return Positioned(
      top: 27,
      right: 292,
      child: AnimatedScale(
        scale: _panelOpen ? 0.98 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _WebAiAssistantTopbarButton(
          onTap: _togglePanel,
          label: label,
          selected: _panelOpen,
        ),
      ),
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
            child: Container(color: Colors.black.withValues(alpha: 0.18)),
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

class _WebAiAssistantTopbarButton extends StatelessWidget {
  const _WebAiAssistantTopbarButton({
    required this.onTap,
    required this.label,
    required this.selected,
  });

  final VoidCallback onTap;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0B1F3A).withOpacity(isDark ? 0.18 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.auto_awesome_outlined,
                size: 17,
                color: selected ? colorScheme.onPrimary : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? colorScheme.onPrimary : colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
