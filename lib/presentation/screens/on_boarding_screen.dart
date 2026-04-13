import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'login_mobile.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;
  bool _showVamosLa = false;

  static const int _totalPages = 4;
  static const Duration _pageInterval = Duration(seconds: 4);

  /// Para adicionar ou trocar animações, basta alterar o campo 'lottie'
  /// com o path do arquivo .json dentro de assets/lottie/onboarding/images/
  static const List<Map<String, String>> _pages = [
    {
      'title': 'Bem-vindo ao Six!',
      'subtitle': 'Gerencie suas ordens de serviço com facilidade e agilidade.',
      'lottie': 'assets/lottie/onboarding/images/bem-vindo.json',
    },
    {
      'title': 'Cadastro Rápido',
      'subtitle': 'Entre em segundos e comece a trabalhar imediatamente.',
      'lottie': 'assets/lottie/onboarding/images/cadastro-rapido.json',
    },
    {
      'title': 'Gestão Técnica',
      'subtitle': 'Acompanhe seus serviços e notificações em tempo real.',
      'lottie': 'assets/lottie/onboarding/images/gestao-tecnica.json',
    },
    {
      'title': 'Controle Financeiro',
      'subtitle': 'Gerencie suas contas a pagar e a receber com precisão.',
      'lottie': 'assets/lottie/onboarding/images/controle-financeiro.json',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  /// Inicia (ou reinicia) o timer de avanço automático.
  /// Chamado após cada troca de página — manual ou automática —
  /// para que o intervalo seja contado a partir da página atual.
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_pageInterval, (_) => _advance());
  }

  void _advance() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % _totalPages;
    _controller.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      // Botão aparece ao chegar na última página e permanece para sempre
      if (index == _totalPages - 1) {
        _showVamosLa = true;
      }
    });
    // Reinicia o timer para que cada página tenha o intervalo completo
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Carrossel de páginas
          PageView.builder(
            controller: _controller,
            onPageChanged: _onPageChanged,
            itemCount: _totalPages,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(
                theme,
                page['title']!,
                page['subtitle']!,
                page['lottie']!,
              );
            },
          ),

          // Indicador de progresso — centro inferior
          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: _totalPages,
                effect: ExpandingDotsEffect(
                  activeDotColor: theme.colorScheme.primary,
                  dotColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                ),
              ),
            ),
          ),

          // Botão "Vamos lá" — canto inferior direito
          Positioned(
            bottom: 28,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showVamosLa ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: !_showVamosLa,
                child: TextButton(
                  onPressed: _goToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    overlayColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Vamos lá',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    ThemeData theme,
    String title,
    String subtitle,
    String lottiePath,
  ) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Título no topo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Animação ocupa o espaço disponível no meio
          Expanded(
            child: Lottie.asset(
              lottiePath,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          // Descrição abaixo da animação
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
                fontSize: 21
              ),
            ),
          ),
          const SizedBox(height: 80), // espaço para os controles inferiores
        ],
      ),
    );
  }
}