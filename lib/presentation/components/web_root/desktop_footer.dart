import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/l10n/web_root_l10n.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_container.dart';
import 'package:flutter/material.dart';

// Footer desktop: 5 colunas (1.4fr + 4*1fr), ink-deep bg.
// Sempre escuro (o footer é black/ink-deep em ambos os modos).
// Suporta l10n.
class DesktopFooter extends StatelessWidget {
  const DesktopFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = WebRootL10n.of(context);
    final cols = l10n.footerColumns;

    return Container(
      color: WebRootTokens.inkDeep,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: ResponsiveContainer(
        isDesktop: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 14, child: _brandCol(l10n)),
                ...cols.expand((c) => [
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 10,
                        child: _col(title: c.$1, items: c.$2),
                      ),
                    ]),
              ],
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x1AFFFFFF)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _legalText(l10n.footerRights),
                  _legalText(l10n.footerMadeBr),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandCol(WebRootL10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              -1.5,  0,    0,   0, 255,
               0,   -1.5,  0,   0, 255,
               0,    0,   -1.5, 0, 255,
               0,    0,    0,   1,   0,
            ]),
            child: Image.asset(
              'assets/images/six-logo-flecha.png',
              height: 96,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 280,
          child: Text(
            l10n.footerTagline,
            style: const TextStyle(
              color: Color(0xA6FFFFFF),
              fontFamily: WebRootTokens.fontFamily,
              fontFamilyFallback: WebRootTokens.fontFamilyFallback,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  Widget _col({required String title, required List<String> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: WebRootTokens.footerColHeader),
        const SizedBox(height: 14),
        ...items.map(
          (it) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FooterLink(it),
          ),
        ),
      ],
    );
  }

  Widget _legalText(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0x80FFFFFF),
          fontFamily: WebRootTokens.fontFamily,
          fontFamilyFallback: WebRootTokens.fontFamilyFallback,
          fontSize: 12,
        ),
      );
}

class _FooterLink extends StatefulWidget {
  const _FooterLink(this.label);
  final String label;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {},
        child: Text(
          widget.label,
          style: WebRootTokens.footerLink.copyWith(
            color: _hover ? Colors.white : const Color(0xBFFFFFFF),
          ),
        ),
      ),
    );
  }
}
