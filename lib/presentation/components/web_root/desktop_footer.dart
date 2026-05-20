import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_container.dart';
import 'package:flutter/material.dart';

class _FooterCol {
  const _FooterCol(this.title, this.items);
  final String title;
  final List<String> items;
}

// Footer desktop: 5 colunas (1.4fr + 4*1fr), ink-deep bg.
class DesktopFooter extends StatelessWidget {
  const DesktopFooter({super.key});

  static const _cols = <_FooterCol>[
    _FooterCol('Produto', ['Recursos', 'Planos', 'Cockpit', 'IA cadastro']),
    _FooterCol('Segmentos', [
      'Pet shop',
      'Assistência técnica',
      'Loja de roupas',
      'Papelaria'
    ]),
    _FooterCol('Empresa', ['Sobre', 'Carreiras', 'Imprensa', 'Contato']),
    _FooterCol('Suporte', [
      'Central de ajuda',
      'Status',
      'Termos',
      'Privacidade'
    ]),
  ];

  @override
  Widget build(BuildContext context) {
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
                Expanded(flex: 14, child: _brandCol()),
                ..._cols.expand((c) => [
                      const SizedBox(width: 32),
                      Expanded(flex: 10, child: _col(c)),
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
                  _legalText('© 2026 Six POS — feito no Brasil'),
                  _legalText('v1.0.1 · CNPJ 00.000.000/0001-00'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CSS do design: `filter: invert(1) brightness(1.5)` — inverte o logo
        // pra clarear em cima do bg ink-deep. ColorFiltered replica o mesmo.
        SizedBox(
          height: 40,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              -1.5,  0,   0,   0, 255,
               0,  -1.5,  0,   0, 255,
               0,   0,  -1.5,  0, 255,
               0,   0,   0,   1,   0,
            ]),
            child: Image.asset(
              'assets/images/six-logo-flecha.png',
              height: 60,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 280,
          child: Text(
            'PDV para pequenos negócios brasileiros. Frente de caixa, '
            'estoque, OS e financeiro, tudo num só lugar.',
            style: TextStyle(
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

  Widget _col(_FooterCol c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.title.toUpperCase(), style: WebRootTokens.footerColHeader),
        const SizedBox(height: 14),
        ...c.items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FooterLink(it),
            )),
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
