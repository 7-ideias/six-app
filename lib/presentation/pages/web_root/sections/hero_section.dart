import 'package:appplanilha/design_system/helpers/six_theme_resolver.dart';
import 'package:appplanilha/design_system/tokens/web_root_scheme.dart';
import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/l10n/web_root_l10n.dart';
import 'package:appplanilha/presentation/components/web_root/eyebrow.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_button.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_container.dart';
import 'package:appplanilha/presentation/components/web_root/store_badge.dart';
import 'package:appplanilha/presentation/components/web_root/typewriter_text.dart';
import 'package:appplanilha/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    context.watch<ThemeProvider>();
    final l10n = WebRootL10n.of(context);
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);

    return Container(
      color: scheme.surfacePage,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 88 : 0),
      child: ResponsiveContainer(
        isDesktop: isDesktop,
        child: isDesktop ? _desktop(l10n, scheme) : _mobile(l10n, scheme),
      ),
    );
  }

  Widget _desktop(WebRootL10n l10n, WebRootScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 105, child: _copy(isDesktop: true, l10n: l10n, scheme: scheme)),
        const SizedBox(width: 56),
        Expanded(flex: 100, child: _PhoneVisual(isDesktop: true, l10n: l10n)),
      ],
    );
  }

  Widget _mobile(WebRootL10n l10n, WebRootScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _copy(isDesktop: false, l10n: l10n, scheme: scheme),
          const SizedBox(height: 16),
          _stores(l10n),
          const SizedBox(height: 16),
          _trustStrip(l10n, scheme),
          const SizedBox(height: 8),
          _PhoneVisual(isDesktop: false, l10n: l10n),
        ],
      ),
    );
  }

  Widget _copy({
    required bool isDesktop,
    required WebRootL10n l10n,
    required WebRootScheme scheme,
  }) {
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
          text: isDesktop ? l10n.heroEyebrowDesktop : l10n.heroEyebrowMobile,
          isDesktop: isDesktop,
        ),
        SizedBox(height: isDesktop ? 20 : 18),
        _heroTitle(isDesktop: isDesktop, titleStyle: titleStyle, l10n: l10n, scheme: scheme),
        SizedBox(height: isDesktop ? 18 : 14),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 520 : double.infinity),
          child: Text(
            isDesktop ? l10n.heroLeadDesktop : l10n.heroLeadMobile,
            style: leadStyle.copyWith(color: scheme.textSoft),
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        if (isDesktop) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveButton(
                label: l10n.heroCtaPrimary,
                onPressed: onStart,
                size: WebButtonSize.lg,
                trailing: const Icon(Icons.arrow_forward, size: 18),
              ),
              const SizedBox(width: 12),
              ResponsiveButton(
                label: l10n.heroCtaSecondary,
                onPressed: onWatch,
                variant: WebButtonVariant.secondary,
                size: WebButtonSize.md,
              ),
            ],
          ),
          const SizedBox(height: 28),
          _trustStripChecks(l10n, scheme),
        ],
      ],
    );
  }

  Widget _heroTitle({
    required bool isDesktop,
    required TextStyle titleStyle,
    required WebRootL10n l10n,
    required WebRootScheme scheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.heroTitlePrefix,
          style: titleStyle.copyWith(color: scheme.textPrimary),
        ),
        TypewriterText(
          words: l10n.heroWords,
          style: titleStyle.copyWith(color: WebRootTokens.accent),
          cursorColor: WebRootTokens.accent,
          cursorWidth: isDesktop ? 3 : 2,
        ),
      ],
    );
  }

  Widget _stores(WebRootL10n l10n) {
    return Row(
      children: [
        Expanded(child: StoreBadge(store: AppStore.apple, onTap: onStart)),
        const SizedBox(width: 10),
        Expanded(child: StoreBadge(store: AppStore.google, onTap: onStart)),
      ],
    );
  }

  Widget _trustStripChecks(WebRootL10n l10n, WebRootScheme scheme) {
    Widget item(String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16, color: WebRootTokens.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: WebRootTokens.fontFamily,
                fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                fontSize: 13,
                color: scheme.textMuted,
              ),
            ),
          ],
        );
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        item(l10n.trustFree),
        item(l10n.trustNoCard),
        item(l10n.trustSupport),
      ],
    );
  }

  Widget _trustStrip(WebRootL10n l10n, WebRootScheme scheme) {
    return Row(
      children: [
        Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        Icon(Icons.star, size: 14, color: WebRootTokens.accent),
        const SizedBox(width: 8),
        Text(
          l10n.trustRating,
          style: TextStyle(
            color: scheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            fontFamily: WebRootTokens.fontFamily,
            fontFamilyFallback: WebRootTokens.fontFamilyFallback,
          ),
        ),
        Text(
          ' ${l10n.trustReviews}',
          style: TextStyle(
            color: scheme.textMuted,
            fontSize: 12,
            fontFamily: WebRootTokens.fontFamily,
            fontFamilyFallback: WebRootTokens.fontFamilyFallback,
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 1, height: 14, color: scheme.border),
        const SizedBox(width: 12),
        Text(
          l10n.trustFree,
          style: TextStyle(
            color: scheme.textMuted,
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
  const _PhoneVisual({required this.isDesktop, required this.l10n});
  final bool isDesktop;
  final WebRootL10n l10n;

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
            if (isDesktop)
              Positioned(top: 100, right: -8, child: _LightChip(l10n: l10n))
            else
              Positioned(top: 64, left: -2, child: _LightChip(l10n: l10n)),
            if (isDesktop)
              Positioned(bottom: 60, left: -10, child: _RatingChip(l10n: l10n))
            else
              Positioned(bottom: 60, right: -4, child: _RatingChip(l10n: l10n)),
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
            Positioned(
              left: 18,
              right: 18,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.phoneScreenTitle,
                    style: const TextStyle(
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
                    l10n.phoneScreenBody,
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

class _LightChip extends StatelessWidget {
  const _LightChip({required this.l10n});
  final WebRootL10n l10n;

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
              children: [
                Text(
                  l10n.chipIaLabel,
                  style: const TextStyle(
                    color: WebRootTokens.fgMuted,
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l10n.chipIaValue,
                  style: const TextStyle(
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
  const _RatingChip({required this.l10n});
  final WebRootL10n l10n;

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.star, color: WebRootTokens.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chipRatingStore,
                  style: const TextStyle(
                    color: WebRootTokens.fgMuted,
                    fontFamily: WebRootTokens.fontFamily,
                    fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.chipRatingValue,
                  style: const TextStyle(
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
