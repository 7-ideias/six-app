import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/tokens/web_root_scheme.dart';
import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:sixpos/l10n/web_root_l10n.dart';
import 'package:sixpos/presentation/components/web_root/eyebrow.dart';
import 'package:sixpos/presentation/components/web_root/feature_card.dart';
import 'package:sixpos/presentation/components/web_root/responsive_container.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key, required this.isDesktop});

  final bool isDesktop;

  // Cores dos ícones — não mudam com dark mode (são cores de feature vibrantes)
  static const _iconColors = [
    WebRootTokens.featureTeal,
    WebRootTokens.featureBlue,
    WebRootTokens.ink,
    WebRootTokens.featurePurple,
    WebRootTokens.accent,
    WebRootTokens.featureCyan,
  ];

  static const _iconData = [
    Icons.shopping_cart_outlined,
    Icons.work_outline,
    Icons.trending_up,
    Icons.insights,
    Icons.auto_awesome,
    Icons.support_agent,
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final l10n = WebRootL10n.of(context);
    final scheme = WebRootScheme(isDark: SixThemeResolver().isDark);
    final cards = l10n.featureCards;

    return Container(
      color: scheme.bgCanvas,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 96 : 48),
      child: ResponsiveContainer(
        isDesktop: isDesktop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _head(l10n: l10n, scheme: scheme),
            ),
            SizedBox(height: isDesktop ? 56 : 28),
            if (isDesktop)
              _gridDesktop(cards)
            else
              _listMobile(cards),
          ],
        ),
      ),
    );
  }

  Widget _head({required WebRootL10n l10n, required WebRootScheme scheme}) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: isDesktop ? 720 : double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(text: l10n.featuresEyebrow, isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 16 : 14),
          Text(
            l10n.featuresSectionTitle,
            style: isDesktop
                ? WebRootTokens.sectionTitleDesktop.copyWith(
                    color: scheme.textPrimary)
                : WebRootTokens.sectionTitleMobile.copyWith(
                    color: scheme.textPrimary),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 12),
          Text(
            isDesktop
                ? l10n.featuresSectionLeadDesktop
                : l10n.featuresSectionLeadMobile,
            style: isDesktop
                ? WebRootTokens.leadDesktop.copyWith(
                    fontSize: 16, color: scheme.textSoft)
                : WebRootTokens.leadMobile.copyWith(
                    fontSize: 15, color: scheme.textSoft),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _gridDesktop(List<(String, String)> cards) {
    // Cards organizados em linhas de 3 colunas. Cada linha usa IntrinsicHeight
    // para que todos os cards estiquem até a altura do mais alto, garantindo
    // uniformidade visual independentemente do tamanho do título/descrição.
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 3;
        const gap = 20.0;
        final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
        final rows = <Widget>[];

        for (int row = 0; row * cols < cards.length; row++) {
          final rowItems = <Widget>[];
          for (int col = 0; col < cols; col++) {
            final i = row * cols + col;
            if (i >= cards.length) {
              // Slot vazio para manter a grade alinhada caso o número de
              // cards não seja múltiplo do número de colunas.
              rowItems.add(SizedBox(width: cardW));
            } else {
              final (title, body) = cards[i];
              rowItems.add(
                SizedBox(
                  width: cardW,
                  // stretch: estica o card até a altura do IntrinsicHeight da linha.
                  child: FeatureCard(
                    icon: _iconData[i],
                    iconColor: _iconColors[i],
                    title: title,
                    description: body,
                    isDesktop: true,
                  ),
                ),
              );
            }
            if (col < cols - 1) rowItems.add(const SizedBox(width: gap));
          }
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rowItems,
              ),
            ),
          );
          if ((row + 1) * cols < cards.length) {
            rows.add(const SizedBox(height: gap));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  Widget _listMobile(List<(String, String)> cards) {
    return Column(
      children: List.generate(cards.length, (i) {
        final (title, body) = cards[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FeatureCard(
            icon: _iconData[i],
            iconColor: _iconColors[i],
            title: title,
            description: body,
            isDesktop: false,
          ),
        );
      }),
    );
  }
}
