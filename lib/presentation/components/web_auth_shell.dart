import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sixpos/design_system/components/auth/six_auth_input.dart';
import 'package:sixpos/design_system/components/auth/six_auth_or_divider.dart';
import 'package:sixpos/design_system/components/auth/six_auth_primary_button.dart';
import 'package:sixpos/design_system/components/auth/six_auth_title.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';
import 'package:sixpos/presentation/components/web_root/web_language_switcher.dart';

class WebAuthShell extends StatelessWidget {
  const WebAuthShell({
    super.key,
    required this.child,
    this.onBack,
    this.showBack = false,
  });

  final Widget child;
  final VoidCallback? onBack;
  final bool showBack;

  static Color fieldFill() => SixAuthTokens.colorFieldFill;
  static Color labelGrey() => SixAuthTokens.colorDividerText;
  static Color textDark() => SixAuthTokens.colorTextPrimary;

  static Route<T> smoothRoute<T>({
    required WidgetBuilder builder,
    String? name,
  }) {
    return PageRouteBuilder<T>(
      settings: name == null ? null : RouteSettings(name: name),
      transitionDuration: const Duration(milliseconds: 620),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        final Animation<double> curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final Animation<double> secondary = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.018, 0.018), end: Offset.zero).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: SlideTransition(
                position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.018, -0.008)).animate(secondary),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SixAuthTokens.colorShellBackground,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _BrandBackdrop(),
          const _AuthBackgroundVeil(),
          SafeArea(
            child: Stack(
              children: <Widget>[
                const Positioned(
                  top: 14,
                  right: 18,
                  child: WebLanguageSwitcher(),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 78),
                    child: _FormPane(showBack: showBack, onBack: onBack, child: child),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSlide {
  const _BrandSlide({
    required this.image,
    required this.title,
    required this.description,
  });

  final String image;
  final String title;
  final String description;
}

const List<_BrandSlide> _brandSlides = <_BrandSlide>[
  _BrandSlide(
    image: 'assets/images/onboading/1-bem-vindo.JPG',
    title: 'Bem-vindo ao Six.',
    description: 'PDV, financeiro e CRM em um só app — pronto pra começar hoje.',
  ),
  _BrandSlide(
    image: 'assets/images/onboading/2-cadastro-rapido.jpg',
    title: 'Cadastro rápido com IA.',
    description: 'Tire foto do produto e a IA cadastra preço, categoria e estoque.',
  ),
  _BrandSlide(
    image: 'assets/images/onboading/3-gestao-tecnica.jpg',
    title: 'Gestão técnica sem planilha.',
    description: 'Controle ordens de serviço, fila, SLA e comunicação com o cliente.',
  ),
  _BrandSlide(
    image: 'assets/images/onboading/4-controle-financeiro.jpg',
    title: 'Financeiro preditivo.',
    description: 'Previsão de caixa, alertas de risco e painel executivo com IA.',
  ),
  _BrandSlide(
    image: 'assets/images/unsplash-1.jpg',
    title: 'Suporte humano de verdade.',
    description: 'Atendimento na hora — sem bot, sem FAQ enlatado.',
  ),
];

class _BrandBackdrop extends StatefulWidget {
  const _BrandBackdrop();

  @override
  State<_BrandBackdrop> createState() => _BrandBackdropState();
}

class _BrandBackdropState extends State<_BrandBackdrop> {
  static const Duration _slideDuration = Duration(seconds: 6);
  static const Duration _crossFadeDuration = Duration(milliseconds: 1100);

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoplay() {
    _timer?.cancel();
    _timer = Timer.periodic(_slideDuration, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _brandSlides.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _BrandSlide slide = _brandSlides[_index];
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedSwitcher(
          duration: _crossFadeDuration,
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          child: Image.asset(
            slide.image,
            key: ValueKey<String>(slide.image),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 2.4, sigmaY: 2.4),
          child: const SizedBox.expand(),
        ),
        Positioned(
          left: -120,
          top: -90,
          child: _Blob(color: const Color(0xFF2563EB).withOpacity(0.22), size: 360),
        ),
        Positioned(
          right: -160,
          bottom: -140,
          child: _Blob(color: const Color(0xFF0B1F3A).withOpacity(0.24), size: 440),
        ),
        Positioned(
          left: 52,
          bottom: 42,
          child: _AmbientBrandCopy(slide: slide),
        ),
      ],
    );
  }
}

class _AuthBackgroundVeil extends StatelessWidget {
  const _AuthBackgroundVeil();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF03111F).withOpacity(0.78),
            const Color(0xFF0B1F3A).withOpacity(0.62),
            const Color(0xFFF8FAFC).withOpacity(0.58),
          ],
          stops: const <double>[0, 0.54, 1],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _AmbientBrandCopy extends StatelessWidget {
  const _AmbientBrandCopy({required this.slide});

  final _BrandSlide slide;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width < 1040) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 850),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
        child: SizedBox(
          key: ValueKey<String>(slide.title),
          width: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                slide.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FormPane extends StatelessWidget {
  const _FormPane({
    required this.child,
    required this.showBack,
    required this.onBack,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final WebRootL10n l10n = WebRootL10n.of(context);
    final double width = MediaQuery.of(context).size.width;
    final bool compacto = width < 640;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - value)),
            child: Transform.scale(scale: 0.982 + (0.018 * value), child: child),
          ),
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compacto ? 440 : 500),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(compacto ? 28 : 34),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(compacto ? 28 : 34),
                border: Border.all(color: Colors.white.withOpacity(0.62), width: 1.1),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF03111F).withOpacity(0.22),
                    blurRadius: 60,
                    offset: const Offset(0, 28),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.16),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(compacto ? 22 : 34, compacto ? 24 : 34, compacto ? 22 : 34, compacto ? 26 : 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (showBack)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onBack ?? () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18, color: SixAuthTokens.colorTextPrimary),
                          label: Text(
                            l10n.authBack,
                            style: const TextStyle(color: SixAuthTokens.colorTextPrimary, fontWeight: FontWeight.w700),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                      ),
                    if (showBack) const SizedBox(height: 8),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WebAuthStaggeredColumn extends StatelessWidget {
  const WebAuthStaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        children.length,
        (int index) => _WebAuthStaggeredEntry(order: index, child: children[index]),
      ),
    );
  }
}

class _WebAuthStaggeredEntry extends StatefulWidget {
  const _WebAuthStaggeredEntry({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  State<_WebAuthStaggeredEntry> createState() => _WebAuthStaggeredEntryState();
}

class _WebAuthStaggeredEntryState extends State<_WebAuthStaggeredEntry> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: 90 + widget.order * 58), () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.055),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _visible ? 1 : 0.992,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class WebAuthTextField extends StatelessWidget {
  const WebAuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SixAuthInput(
      controller: controller,
      hint: hint,
      label: label,
      suffix: suffix,
      obscure: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }
}

class WebAuthPrimaryButton extends StatelessWidget {
  const WebAuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SixAuthPrimaryButton(label: label, onPressed: onPressed, isLoading: isLoading);
  }
}

class WebAuthSecondaryButton extends StatelessWidget {
  const WebAuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SixAuthTokens.heightButtonGoogle,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: SixAuthTokens.colorButtonGoogleBg,
          foregroundColor: SixAuthTokens.colorTextPrimary,
          elevation: 0,
          side: const BorderSide(color: SixAuthTokens.colorButtonGoogleBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SixAuthTokens.radiusButtonGoogle)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (leading != null) ...<Widget>[leading!, const SizedBox(width: 10)],
            Text(
              label,
              style: const TextStyle(
                fontSize: SixAuthTokens.fontSizeBody,
                fontWeight: FontWeight.w500,
                color: SixAuthTokens.colorTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebAuthTitle extends StatelessWidget {
  const WebAuthTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SixAuthTitle(title: title, subtitle: subtitle);
  }
}

class WebAuthOrDivider extends StatelessWidget {
  const WebAuthOrDivider({super.key, this.text = 'ou continue com'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SixAuthOrDivider(text: text);
  }
}

class WebAuthGoogleGlyph extends StatelessWidget {
  const WebAuthGoogleGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4), height: 1),
    );
  }
}
