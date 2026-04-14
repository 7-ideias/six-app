import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'login_mobile.dart';

// ── Widget de efeito "digitando" ────────────────────────────────────────────
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _TypewriterText({super.key, required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  Timer? _charTimer;

  // Velocidade: ~30ms por caractere → texto de ~55 chars termina em ~1.7s
  static const Duration _charInterval = Duration(milliseconds: 28);

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(_TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _charTimer?.cancel();
      _displayed = '';
      _startTyping();
    }
  }

  void _startTyping() {
    int index = 0;
    _charTimer = Timer.periodic(_charInterval, (t) {
      if (!mounted) { t.cancel(); return; }
      if (index >= widget.text.length) { t.cancel(); return; }
      setState(() => _displayed = widget.text.substring(0, ++index));
    });
  }

  @override
  void dispose() {
    _charTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed, style: widget.style);
  }
}

// ── Tela de onboarding ──────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Timer? _timer;
  int _currentPage = 0;
  bool _showVamosLa = false;
  double _dragStartX = 0;

  static const int _totalPages = 4;
  static const Duration _pageInterval = Duration(seconds: 6);
  static const Duration _fadeDuration = Duration(milliseconds: 1100);

  static const List<Map<String, String>> _pages = [
    {
      'title': 'Bem-vindo ao Six!',
      'subtitle': 'Gerencie suas ordens de serviço com facilidade e agilidade.',
      'image': 'assets/images/onboading/1-bem-vindo.jpg',
    },
    {
      'title': 'Cadastro Rápido',
      'subtitle': 'Entre em segundos e comece a trabalhar imediatamente.',
      'image': 'assets/images/onboading/2-cadastro-rapido.jpg',
    },
    {
      'title': 'Gestão Técnica',
      'subtitle': 'Acompanhe seus serviços e notificações em tempo real.',
      'image': 'assets/images/onboading/3-gestao-tecnica.jpg',
    },
    {
      'title': 'Controle Financeiro',
      'subtitle': 'Gerencie suas contas a pagar e a receber com precisão.',
      'image': 'assets/images/onboading/4-controle-financeiro.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      _pageInterval,
      (_) => _goToPage((_currentPage + 1) % _totalPages),
    );
  }

  void _goToPage(int index) {
    if (!mounted) return;
    setState(() {
      _currentPage = index;
      if (index == _totalPages - 1) _showVamosLa = true;
    });
    _startTimer();
  }

  Future<void> _goToLogin() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPageMobile()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragStart: (d) => _dragStartX = d.globalPosition.dx,
        onHorizontalDragEnd: (d) {
          final diff = d.globalPosition.dx - _dragStartX;
          if (diff < -40) {
            _goToPage((_currentPage + 1) % _totalPages);
          } else if (diff > 40) {
            _goToPage((_currentPage - 1 + _totalPages) % _totalPages);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Imagem de fundo com crossfade suave ─────────────────────
            AnimatedSwitcher(
              duration: _fadeDuration,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: SizedBox.expand(
                key: ValueKey(_currentPage),
                child: Image.asset(page['image']!, fit: BoxFit.cover),
              ),
            ),

            // ── Gradiente inferior ───────────────────────────────────────
            const Positioned(
              bottom: 0, left: 0, right: 0, height: 380,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.0, 0.6, 1.0],
                    colors: [Color(0xCC000000), Color(0x99000000), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Gradiente superior ───────────────────────────────────────
            const Positioned(
              top: 0, left: 0, right: 0, height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x88000000), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Textos ───────────────────────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título: fade + slide (igual antes)
                      AnimatedSwitcher(
                        duration: _fadeDuration,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.06),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            )),
                            child: child,
                          ),
                        ),
                        child: Align(
                          key: ValueKey(_currentPage),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            page['title']!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Subtítulo: efeito digitando
                      _TypewriterText(
                        key: ValueKey('sub_$_currentPage'),
                        text: page['subtitle']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xCCFFFFFF),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Indicador de páginas ─────────────────────────────────────
            Positioned(
              bottom: 44, left: 0, right: 0,
              child: Center(
                child: AnimatedSmoothIndicator(
                  activeIndex: _currentPage,
                  count: _totalPages,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: Colors.white,
                    dotColor: Color(0x66FFFFFF),
                    dotHeight: 7,
                    dotWidth: 7,
                    expansionFactor: 3,
                  ),
                ),
              ),
            ),

            // ── Botão "Vamos lá" ─────────────────────────────────────────
            Positioned(
              bottom: 28, right: 24,
              child: AnimatedOpacity(
                opacity: _showVamosLa ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: IgnorePointer(
                  ignoring: !_showVamosLa,
                  child: TextButton(
                    onPressed: _goToLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      overlayColor: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Vamos lá',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                      ],
                    ),
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
