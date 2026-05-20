import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/eyebrow.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_button.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_container.dart';
import 'package:appplanilha/presentation/components/web_root/store_badge.dart';
import 'package:flutter/material.dart';

// Hero: copy + visual.
// Desktop: 2-col grid 1.05fr/1fr, h1 56px, "Começar agora" + "Ver demonstração".
// Mobile: stack vertical, h1 38px, store badges + phone mockup.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.isDesktop,
    this.onStart,
    this.onWatch,
  });

  final bool isDesktop;
  final VoidCallback? onStart;
  final VoidCallback? onWatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebRootTokens.surface,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 88 : 0),
      child: ResponsiveContainer(
        isDesktop: isDesktop,
        child: isDesktop ? _desktop() : _mobile(),
      ),
    );
  }

  Widget _desktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 105, child: _copy(isDesktop: true)),
        const SizedBox(width: 56),
        const Expanded(flex: 100, child: _PhoneVisual(isDesktop: true)),
      ],
    );
  }

  Widget _mobile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _copy(isDesktop: false),
          const SizedBox(height: 16),
          _stores(),
          const SizedBox(height: 16),
          _trustStrip(),
          const SizedBox(height: 8),
          const _PhoneVisual(isDesktop: false),
        ],
      ),
    );
  }

  Widget _copy({required bool isDesktop}) {
    final titleStyle = isDesktop
        ? WebRootTokens.heroTitleDesktop
        : WebRootTokens.heroTitleMobile;
    final leadStyle =
        isDesktop ? WebRootTokens.leadDesktop : WebRootTokens.leadMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(
          text: 'PDV para pequenos negócios',
          isDesktop: isDesktop,
        ),
        SizedBox(height: isDesktop ? 20 : 18),
        // O design usa "resultados reais." em accent no mobile — usamos
        // RichText pra reproduzir essa quebra.
        RichText(
          text: TextSpan(
            style: titleStyle,
            children: [
              const TextSpan(text: 'Gestão simples,\n'),
              TextSpan(
                text: 'resultados reais.',
                style: titleStyle.copyWith(color: WebRootTokens.accent),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 18 : 14),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 520 : double.infinity),
          child: Text(
            // Lead matches design exactly:
            //   desktop hero__copy <p> + mobile hero__sub
            isDesktop
                ? 'Controle financeiro, frente de caixa, ordens de serviço e estoque '
                    '— tudo em um só lugar, com IA para cadastrar produtos, recomendar '
                    'preços, prever caixa e gerar relatórios em segundos.'
                : 'Frente de caixa, estoque, ordens de serviço e financeiro preditivo '
                    '— tudo em um só app, com IA para cadastrar produtos e prever caixa.',
            style: leadStyle,
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        if (isDesktop) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveButton(
                label: 'Começar agora',
                onPressed: onStart,
                size: WebButtonSize.lg,
                trailing: const Icon(Icons.arrow_forward, size: 18),
              ),
              const SizedBox(width: 12),
              ResponsiveButton(
                label: 'Ver demonstração',
                onPressed: onWatch,
                variant: WebButtonVariant.secondary,
                size: WebButtonSize.md,
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Desktop usa a versão "3 checks" (CSS .hero__trust), mobile usa
          // a strip com 5 estrelas + reviews.
          _trustStripChecks(),
        ],
      ],
    );
  }

  Widget _stores() {
    return Row(
      children: [
        Expanded(
          child: StoreBadge(store: AppStore.apple, onTap: onStart),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StoreBadge(store: AppStore.google, onTap: onStart),
        ),
      ],
    );
  }

  // 3-checks horizontal — desktop hero
  Widget _trustStripChecks() {
    Widget item(String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 16, color: WebRootTokens.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: WebRootTokens.fontFamily,
                fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                fontSize: 13,
                color: WebRootTokens.fgMuted,
              ),
            ),
          ],
        );
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        // Copy matches CSS .hero__trust > .trust__item (web standalone)
        item('14 dias grátis'),
        item('Sem cartão'),
        item('Suporte pt-BR'),
      ],
    );
  }

  Widget _trustStrip() {
    return Row(
      children: [
        const Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        const Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        const Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        const Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        const Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        const SizedBox(width: 8),
        const Text(
          '4,9',
          style: TextStyle(
            color: WebRootTokens.ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            fontFamily: WebRootTokens.fontFamily,
            fontFamilyFallback: WebRootTokens.fontFamilyFallback,
          ),
        ),
        const Text(
          ' · 2.348 avaliações',
          style: TextStyle(
            color: WebRootTokens.fgMuted,
            fontSize: 12,
            fontFamily: WebRootTokens.fontFamily,
            fontFamilyFallback: WebRootTokens.fontFamilyFallback,
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 1, height: 14, color: WebRootTokens.line),
        const SizedBox(width: 12),
        const Text(
          '14 dias grátis',
          style: TextStyle(
            color: WebRootTokens.fgMuted,
            fontSize: 12,
            fontFamily: WebRootTokens.fontFamily,
            fontFamilyFallback: WebRootTokens.fontFamilyFallback,
          ),
        ),
      ],
    );
  }
}

class _PhoneVisual extends StatelessWidget {
  const _PhoneVisual({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final w = isDesktop ? 286.0 : 252.0;
    final h = isDesktop ? 580.0 : 510.0;

    return SizedBox(
      height: isDesktop ? 540 : (h + 40),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _gradientHalo(),
            Transform.rotate(
              angle: isDesktop ? -0.035 : 0,
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0C0C),
                  borderRadius: BorderRadius.circular(isDesktop ? 44 : 40),
                  boxShadow: WebRootTokens.phoneShadow,
                ),
                padding: EdgeInsets.all(isDesktop ? 9 : 8),
                child: _phoneScreen(isDesktop),
              ),
            ),
            // Chips flutuantes — espelha exatamente o CSS:
            //   .chip--ia     { top: 100; right: -8;  rotate( 4deg) } (desktop)
            //                 { top:  64; left: -2;  rotate(-4deg) } (mobile)
            //   .chip--rating { bottom: 60; left: -10; rotate(-4deg) } (desktop)
            //                 { bottom: 60; right: -4; rotate( 4deg) } (mobile)
            if (isDesktop)
              const Positioned(top: 100, right: -8, child: _LightChip())
            else
              const Positioned(top: 64, left: -2, child: _LightChip()),
            if (isDesktop)
              const Positioned(bottom: 60, left: -10, child: _RatingChip())
            else
              const Positioned(bottom: 60, right: -4, child: _RatingChip()),
          ],
        ),
      ),
    );
  }

  Widget _gradientHalo() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.2),
            radius: 0.7,
            colors: [
              WebRootTokens.accent.withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneScreen(bool isDesktop) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isDesktop ? 36 : 32),
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto (asset opcional — fallback gradient se asset não existir)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    WebRootTokens.ink,
                    WebRootTokens.accent.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            // Scrim inferior
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xE0000000),
                      Color(0xA6000000),
                      Color(0x00000000),
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Dynamic island / notch
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 84,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            // Copy
            Positioned(
              left: 18,
              right: 18,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Gerencie suas vendas em tempo real',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: WebRootTokens.fontFamily,
                      fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use IA para cadastrar produtos, recomendar preços e prever caixa.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontFamily: WebRootTokens.fontFamily,
                      fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(active: true),
                      _dot(),
                      _dot(),
                      _dot(),
                    ],
                  ),
                ],
              ),
            ),
            // Home indicator
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 90,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot({bool active = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Container(
          width: active ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
}

// _DarkChip (TEMPO DE VENDA / 14s -62%) foi removido em prol de fidelidade
// com o design web — onde apenas dois chips aparecem: chip--ia (claro) e
// chip--rating (claro). Mantida apenas a definição abaixo.

class _LightChip extends StatelessWidget {
  const _LightChip();
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: WebRootTokens.lineSoft),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x290F2D3A),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: WebRootTokens.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: WebRootTokens.accent, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'IA CADASTROU',
                  style: TextStyle(
                    color: WebRootTokens.fgMuted,
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 1),
                // Design (.chip--ia): só label + value, sem delta extra.
                Text(
                  '12 produtos',
                  style: TextStyle(
                    color: WebRootTokens.ink,
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip();
  @override
  Widget build(BuildContext context) {
    // Design: .chip--rating no desktop tem rotate(-4deg) e fica bottom-left.
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 210),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: WebRootTokens.lineSoft),
          borderRadius: BorderRadius.circular(WebRootTokens.radiusBtn),
          boxShadow: const [
            BoxShadow(
              color: Color(0x290F2D3A),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: WebRootTokens.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star,
                  color: WebRootTokens.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Design (.chip--rating): label "App Store Brasil" +
                // value "4,9 ★ · top finanças".
                Text(
                  'APP STORE BRASIL',
                  style: TextStyle(
                    color: WebRootTokens.fgMuted,
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '4,9 ★ · top finanças',
                  style: TextStyle(
                    color: WebRootTokens.ink,
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
