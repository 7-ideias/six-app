import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/material.dart';

class _Col {
  const _Col(this.title, this.items);
  final String title;
  final List<String> items;
}

// Footer mobile: grid 2 colunas, logo + descrição + legais.
class MobileFooter extends StatelessWidget {
  const MobileFooter({super.key});

  static const _cols = <_Col>[
    _Col('Produto', ['Recursos', 'Planos', 'Cockpit', 'IA cadastro']),
    _Col('Segmentos', ['Pet shop', 'Assistência técnica', 'Loja de roupas', 'Papelaria']),
    _Col('Empresa', ['Sobre', 'Carreiras', 'Contato']),
    _Col('Suporte', ['Central de ajuda', 'Termos', 'Privacidade']),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebRootTokens.inkDeep,
      padding: const EdgeInsets.fromLTRB(
        WebRootTokens.gutterMobile,
        40,
        WebRootTokens.gutterMobile,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mesma técnica do desktop footer — inverte para clarear o logo
          // sobre o fundo ink-deep.
          // Logo footer mobile maior — antes 36h/56 asset, agora 48h/80 asset.
          SizedBox(
            height: 48,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                -1.5,  0,   0,   0, 255,
                 0,  -1.5,  0,   0, 255,
                 0,   0,  -1.5,  0, 255,
                 0,   0,   0,   1,   0,
              ]),
              child: Image.asset(
                'assets/images/six-logo-flecha.png',
                height: 80,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PDV para pequenos negócios brasileiros. Frente de caixa, '
            'estoque, OS e financeiro — tudo num só app.',
            style: TextStyle(
              color: Color(0x9EFFFFFF),
              fontFamily: WebRootTokens.fontFamily,
              fontFamilyFallback: WebRootTokens.fontFamilyFallback,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 24,
              childAspectRatio: 1.4,
            ),
            itemCount: _cols.length,
            itemBuilder: (_, i) => _column(_cols[i]),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legal('© 2026 Six POS — feito no Brasil'),
                const SizedBox(height: 4),
                _legal('CNPJ 00.000.000/0001-00 · v1.0.1'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(_Col c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.title.toUpperCase(), style: WebRootTokens.footerColHeader),
        const SizedBox(height: 10),
        ...c.items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                it,
                style: const TextStyle(
                  color: Color(0xB8FFFFFF),
                  fontFamily: WebRootTokens.fontFamily,
                  fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                  fontSize: 13,
                ),
              ),
            )),
      ],
    );
  }

  Widget _legal(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0x73FFFFFF),
          fontFamily: WebRootTokens.fontFamily,
          fontFamilyFallback: WebRootTokens.fontFamilyFallback,
          fontSize: 11,
        ),
      );
}
