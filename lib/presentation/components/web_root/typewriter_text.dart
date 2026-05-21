import 'dart:async';

import 'package:flutter/material.dart';

// Typewriter custom — sem dependência externa (animated_text_kit é overkill
// pra um caso só). Estados: typing → pausing → deleting → next word.
// Altura fixa (via SizedBox no consumer) evita layout shift quando o texto
// muda de comprimento.
//
// Tunables — passados via construtor para serem fáceis de ajustar:
//   typeStep      45–70  ms por caractere (suggested 55ms)
//   pauseAfter    900–1400 ms parado depois de digitar a palavra completa
//   deleteStep    30–60  ms por caractere durante apagar
//   pauseBetween  300–500 ms entre apagar e digitar a próxima palavra
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.words,
    required this.style,
    this.cursorColor,
    this.cursorWidth = 2,
    this.typeStep = const Duration(milliseconds: 55),
    this.pauseAfter = const Duration(milliseconds: 1200),
    this.deleteStep = const Duration(milliseconds: 40),
    this.pauseBetween = const Duration(milliseconds: 380),
  });

  /// Palavras que o cursor digita em loop.
  final List<String> words;

  /// Estilo aplicado ao texto e ao cursor (mesma cor por padrão).
  final TextStyle style;

  /// Cor do cursor — se null, usa `style.color`.
  final Color? cursorColor;
  final double cursorWidth;

  final Duration typeStep;
  final Duration pauseAfter;
  final Duration deleteStep;
  final Duration pauseBetween;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

enum _Phase { typing, pausing, deleting, switching }

class _TypewriterTextState extends State<TypewriterText> {
  int _wordIndex = 0;
  int _charCount = 0;
  _Phase _phase = _Phase.typing;
  Timer? _timer;

  // Cursor blink (1Hz) — independente do timer de typing.
  late final Stream<bool> _blink = Stream<bool>.periodic(
    const Duration(milliseconds: 500),
    (n) => n.isEven,
  ).asBroadcastStream();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _currentWord => widget.words[_wordIndex];

  void _schedule() {
    _timer?.cancel();
    Duration delay;
    switch (_phase) {
      case _Phase.typing:
        delay = widget.typeStep;
        break;
      case _Phase.pausing:
        delay = widget.pauseAfter;
        break;
      case _Phase.deleting:
        delay = widget.deleteStep;
        break;
      case _Phase.switching:
        delay = widget.pauseBetween;
        break;
    }
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      switch (_phase) {
        case _Phase.typing:
          if (_charCount < _currentWord.length) {
            _charCount++;
          } else {
            _phase = _Phase.pausing;
          }
          break;
        case _Phase.pausing:
          _phase = _Phase.deleting;
          break;
        case _Phase.deleting:
          if (_charCount > 0) {
            _charCount--;
          } else {
            _phase = _Phase.switching;
          }
          break;
        case _Phase.switching:
          _wordIndex = (_wordIndex + 1) % widget.words.length;
          _phase = _Phase.typing;
          break;
      }
    });
    _schedule();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = _currentWord.substring(0, _charCount);
    final cursorColor =
        widget.cursorColor ?? widget.style.color ?? Colors.black;

    return Semantics(
      // Para leitores de tela exibimos todas as palavras juntas, evitando
      // que o cursor digitando seja anunciado caractere a caractere.
      label: widget.words.join(', '),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(visibleText, style: widget.style),
          // Cursor pisca em 1Hz — usa StreamBuilder pra não acoplar ao
          // tick do typing.
          StreamBuilder<bool>(
            stream: _blink,
            initialData: true,
            builder: (context, snap) {
              final on = snap.data ?? true;
              return Opacity(
                opacity: on ? 1 : 0,
                child: Container(
                  width: widget.cursorWidth,
                  height: (widget.style.fontSize ?? 16) * 0.95,
                  margin: const EdgeInsets.only(left: 4),
                  color: cursorColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
