import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

class SixMobileRotatingIntroCard extends StatefulWidget {
  const SixMobileRotatingIntroCard({
    super.key,
    required this.title,
    required this.subtitles,
    required this.markChild,
  });

  final String title;
  final List<String> subtitles;
  final Widget markChild;

  @override
  State<SixMobileRotatingIntroCard> createState() =>
      _SixMobileRotatingIntroCardState();
}

class _SixMobileRotatingIntroCardState
    extends State<SixMobileRotatingIntroCard> {
  static const Duration _typingStep = Duration(milliseconds: 72);
  static const Duration _deletingStep = Duration(milliseconds: 38);
  static const Duration _pauseAfterTyping = Duration(milliseconds: 980);
  static const Duration _pauseBeforeTyping = Duration(milliseconds: 240);
  static const Duration _initialDelay = Duration(milliseconds: 420);
  static const Duration _cursorBlinkStep = Duration(milliseconds: 430);

  Timer? _typingTimer;
  Timer? _cursorTimer;
  int _phraseIndex = 0;
  int _visibleCharacters = 0;
  bool _isDeleting = false;
  bool _showCursor = true;
  double _rotationTurns = 0;

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  @override
  void didUpdateWidget(covariant SixMobileRotatingIntroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.subtitles, widget.subtitles)) {
      _resetLoop();
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _startLoop() {
    if (widget.subtitles.isEmpty) return;
    _cursorTimer = Timer.periodic(_cursorBlinkStep, (_) {
      if (!mounted) return;
      setState(() {
        _showCursor = !_showCursor;
      });
    });
    _scheduleNextStep(_initialDelay);
  }

  void _resetLoop() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    setState(() {
      _phraseIndex = 0;
      _visibleCharacters = 0;
      _isDeleting = false;
      _showCursor = true;
      _rotationTurns = 0;
    });
    _startLoop();
  }

  void _scheduleNextStep(Duration duration) {
    _typingTimer?.cancel();
    _typingTimer = Timer(duration, _advanceLoop);
  }

  void _advanceLoop() {
    if (!mounted || widget.subtitles.isEmpty) return;

    final String currentPhrase = widget.subtitles[_phraseIndex];
    if (!_isDeleting) {
      if (_visibleCharacters < currentPhrase.length) {
        setState(() {
          _visibleCharacters += 1;
          _rotationTurns += 0.028;
        });
        _scheduleNextStep(_typingStep);
        return;
      }

      _isDeleting = true;
      _scheduleNextStep(_pauseAfterTyping);
      return;
    }

    if (_visibleCharacters > 0) {
      setState(() {
        _visibleCharacters -= 1;
        _rotationTurns -= 0.02;
      });
      _scheduleNextStep(_deletingStep);
      return;
    }

    _isDeleting = false;
    _phraseIndex = (_phraseIndex + 1) % widget.subtitles.length;
    _scheduleNextStep(_pauseBeforeTyping);
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final String semanticSubtitle = widget.subtitles.join('. ');
    final String displayedText =
        widget.subtitles.isEmpty
            ? ''
            : (disableAnimations
                ? widget.subtitles.first
                : widget.subtitles[_phraseIndex].substring(
                  0,
                  _visibleCharacters.clamp(
                    0,
                    widget.subtitles[_phraseIndex].length,
                  ),
                ));
    final TextStyle terminalStyle = TextStyle(
      color: colors.mutedText,
      fontSize: 12.2,
      height: 1.28,
      fontWeight: FontWeight.w600,
      fontFamily: 'monospace',
    );
    final Color cursorColor =
        _showCursor ? SixMobilePalette.brandBlue : Colors.transparent;

    return Semantics(
      container: true,
      header: true,
      label: '${widget.title}. $semanticSubtitle',
      child: Container(
        height: 124,
        padding: const EdgeInsets.fromLTRB(18, 17, 14, 17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                SixMobilePalette.brandBlue.withAlpha(isDark ? 28 : 12),
                colors.surface,
              ),
              Color.alphaBlend(
                SixMobilePalette.brandViolet.withAlpha(isDark ? 20 : 8),
                colors.surface,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: SixMobilePalette.brandBlue.withAlpha(isDark ? 74 : 36),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.navigationShadow.withAlpha(isDark ? 38 : 22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 20,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: displayedText, style: terminalStyle),
                        TextSpan(
                          text: '|',
                          style: terminalStyle.copyWith(color: cursorColor),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.softAccentSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SixMobilePalette.brandBlue.withAlpha(
                      isDark ? 86 : 48,
                    ),
                  ),
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: disableAnimations ? 0 : _rotationTurns,
                    duration:
                        disableAnimations
                            ? Duration.zero
                            : (_isDeleting ? _deletingStep : _typingStep),
                    curve: Curves.linear,
                    child: widget.markChild,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
