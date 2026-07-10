import 'dart:async';

import 'package:sixpos/design_system/components/auth/six_auth_input.dart';
import 'package:sixpos/design_system/components/auth/six_auth_or_divider.dart';
import 'package:sixpos/design_system/components/auth/six_auth_primary_button.dart';
import 'package:sixpos/design_system/components/auth/six_auth_title.dart';
import 'package:sixpos/design_system/tokens/auth_tokens.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';
import 'package:sixpos/presentation/components/web_root/web_language_switcher.dart';
import 'package:flutter/material.dart';

// Shell web de autenticação: painel de marca (lado esq.) + painel de formulário.
// Todos os estilos herdados de SixAuthTokens — sem valores hardcoded aqui.
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

  // Helpers estáticos de compatibilidade (usados pelas telas enquanto migram).
  // Delegam para SixAuthTokens — não adicionar novos valores aqui.
  static Color fieldFill() => SixAuthTokens.colorFieldFill;
  static Color labelGrey() => SixAuthTokens.colorDividerText;
  static Color textDark() => SixAuthTokens.colorTextPrimary;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showBrandPanel = width >= 960;

    return Scaffold(
      backgroundColor: SixAuthTokens.colorShellBackground,
      body: Row(
        children: [
          if (showBrandPanel) const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(
            flex: showBrandPanel ? 4 : 10,
            child: _FormPane(showBack: showBack, onBack: onBack, child: child),
          ),
        ],
      ),
    );
  }
}

// ── Painel de marca (esquerda, desktop) ────────────────────────────────────
//
// Carousel auto-rotativo: troca a cada 5s entre slides com imagem de fundo,
// título e descrição. O usuário pode pular para qualquer slide clicando nos
// indicadores (dots) abaixo do texto.
//
// As imagens são reaproveitadas do onboarding mobile — todas relacionadas
// ao dia-a-dia de quem usa o app (caixa, gestão técnica, financeiro, etc.).

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

const List<_BrandSlide> _brandSlides = [
  _BrandSlide(
    image: 'assets/images/onboading/1-bem-vindo.JPG',
    title: 'Bem-vindo ao Six.',
    description:
        'PDV, financeiro e CRM em um só app — pronto pra começar hoje.',
  ),
  _BrandSlide(
    image: 'assets/images/onboading/2-cadastro-rapido.jpg',
    title: 'Cadastro rápido\ncom IA.',
    description:
        'Tire foto do produto e a IA cadastra preço, categoria e estoque.',
  ),
  _BrandSlide(
    image: 'assets/images/onboading/3-gestao-tecnica.jpg',
    title: 'Gestão técnica\nsem planilha.',
    description:
        'Controle ordens de serviço, fila, SLA e comunicação com o cliente.',
  ),
  _BrandSlide(
    image: 'assets/images/onboading/4-controle-financeiro.jpg',
    title: 'Financeiro\npreditivo.',
    description:
        'Previsão de caixa, alertas de risco e painel executivo com IA.',
  ),
  _BrandSlide(
    image: 'assets/images/unsplash-1.jpg',
    title: 'Suporte humano\nde verdade.',
    description: 'Atendimento na hora — sem bot, sem FAQ enlatado.',
  ),
];

class _BrandPanel extends StatefulWidget {
  const _BrandPanel();

  @override
  State<_BrandPanel> createState() => _BrandPanelState();
}

class _BrandPanelState extends State<_BrandPanel> {
  static const Duration _slideDuration = Duration(seconds: 5);
  static const Duration _crossFadeDuration = Duration(milliseconds: 700);

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

  void _goTo(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _startAutoplay(); // reinicia o timer ao interagir
  }

  @override
  Widget build(BuildContext context) {
    final slide = _brandSlides[_index];

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camada 1: imagem de fundo com crossfade ────────────────────
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: _crossFadeDuration,
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: Image.asset(
                slide.image,
                key: ValueKey(slide.image),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Camada 2: overlay de cor (legibilidade) ────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xE60F1A14), // 90% opacity
                  Color(0xCC0F2D3A), // 80% opacity
                ],
              ),
            ),
            child: SizedBox.expand(),
          ),

          // ── Camada 3: blobs decorativos ────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: _Blob(
              color: SixAuthTokens.colorBrand.withValues(alpha: 0.18),
              size: 320,
            ),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: _Blob(
              color: SixAuthTokens.colorBrand.withValues(alpha: 0.10),
              size: 380,
            ),
          ),

          // ── Camada 4: conteúdo (título, descrição, dots) ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 48, 56, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                AnimatedSwitcher(
                  duration: _crossFadeDuration,
                  transitionBuilder: (child, anim) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOut),
                    );
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: Column(
                    key: ValueKey('text-${slide.title}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slide.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        slide.description,
                        style: const TextStyle(
                          color: Color(0xBFFFFFFF),
                          fontSize: 15.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(_brandSlides.length, (i) {
                    final active = i == _index;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i == _brandSlides.length - 1 ? 0 : 6,
                      ),
                      child: _Dot(active: active, onTap: () => _goTo(i)),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
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

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          width: active ? 32 : 18,
          height: 4,
          decoration: BoxDecoration(
            color:
                active
                    ? const Color(0xE6FFFFFF) // 90% white
                    : const Color(0x59FFFFFF), // 35% white
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ── Painel de formulário ───────────────────────────────────────────────────

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
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra superior com seletor de idioma alinhado à direita.
          Padding(
            padding: const EdgeInsets.only(top: 12, right: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: const WebLanguageSwitcher(),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: SixAuthTokens.formPanePaddingWeb,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SixAuthTokens.formPaneMaxWidth,
                  ),
                  child: _AnimatedFormContent(
                    showBack: showBack,
                    onBack: onBack,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anima a entrada do conteúdo do formulário — usado como wrapper interno
/// no [_FormPane]. O [child] já deve usar [WebAuthStaggeredItems] internamente
/// para o stagger top-down dos seus campos.
class _AnimatedFormContent extends StatefulWidget {
  const _AnimatedFormContent({
    required this.child,
    required this.showBack,
    required this.onBack,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  State<_AnimatedFormContent> createState() => _AnimatedFormContentState();
}

class _AnimatedFormContentState extends State<_AnimatedFormContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Duração curta — só para o botão "Voltar" aparecer suavemente.
    // O stagger real dos campos fica em WebAuthStaggeredItems.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WebRootL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showBack)
          FadeTransition(
            opacity: _ctrl,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onBack ?? () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: SixAuthTokens.colorTextPrimary,
                ),
                label: Text(
                  l10n.authBack,
                  style: const TextStyle(
                    color: SixAuthTokens.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ),
          ),
        if (widget.showBack) const SizedBox(height: 8),
        widget.child,
      ],
    );
  }
}

/// Widget público que anima cada filho de cima para baixo com fade.
///
/// Uso típico dentro de telas de auth:
/// ```dart
/// WebAuthStaggeredItems(
///   children: [
///     WebAuthTitle(...),
///     SizedBox(height: 28),
///     WebAuthTextField(...),
///     WebAuthPrimaryButton(...),
///   ],
/// )
/// ```
class WebAuthStaggeredItems extends StatefulWidget {
  const WebAuthStaggeredItems({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 380),
    this.stagger = const Duration(milliseconds: 90),
  });

  final List<Widget> children;

  /// Duração da animação de cada item individual.
  final Duration itemDuration;

  /// Atraso entre o início da animação de itens consecutivos.
  final Duration stagger;

  @override
  State<WebAuthStaggeredItems> createState() => _WebAuthStaggeredItemsState();
}

class _WebAuthStaggeredItemsState extends State<WebAuthStaggeredItems>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  Duration get _totalDuration {
    final ms = widget.itemDuration.inMilliseconds +
        widget.stagger.inMilliseconds * (widget.children.length - 1).clamp(0, 99);
    return Duration(milliseconds: ms);
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _totalDuration);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _opacityFor(int i) {
    final total = _totalDuration.inMilliseconds.toDouble();
    final start = (i * widget.stagger.inMilliseconds) / total;
    final end = start + widget.itemDuration.inMilliseconds / total;
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );
  }

  Animation<Offset> _slideFor(int i) {
    final total = _totalDuration.inMilliseconds.toDouble();
    final start = (i * widget.stagger.inMilliseconds) / total;
    final end = start + widget.itemDuration.inMilliseconds / total;
    return Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          FadeTransition(
            opacity: _opacityFor(i),
            child: SlideTransition(
              position: _slideFor(i),
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}

// ── Componentes de compatibilidade ─────────────────────────────────────────
// Wrappers finos que delegam para os componentes do design system.
// Permitem que as telas existentes compilem sem alteração enquanto migram.

/// Campo de texto para auth — usa SixAuthInput internamente.
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
  // Mantido por compatibilidade; SixAuthInput não usa ícone prefix conforme Figma.
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

/// Botão primário para auth — usa SixAuthPrimaryButton internamente.
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
    return SixAuthPrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

/// Botão secundário para auth (ex.: Google).
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              SixAuthTokens.radiusButtonGoogle,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
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

/// Título + subtítulo para auth — usa SixAuthTitle internamente.
class WebAuthTitle extends StatelessWidget {
  const WebAuthTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SixAuthTitle(title: title, subtitle: subtitle);
  }
}

/// Divisor "ou continue com" — usa SixAuthOrDivider internamente.
class WebAuthOrDivider extends StatelessWidget {
  const WebAuthOrDivider({super.key, this.text = 'ou continue com'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SixAuthOrDivider(text: text);
  }
}

/// Glyph "G" do Google — mantido por compatibilidade.
class WebAuthGoogleGlyph extends StatelessWidget {
  const WebAuthGoogleGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}
