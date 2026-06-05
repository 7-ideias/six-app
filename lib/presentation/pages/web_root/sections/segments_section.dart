import 'package:sixpos/design_system/tokens/web_root_tokens.dart';
import 'package:flutter/material.dart';

class _Segment {
  const _Segment(this.icon, this.label);
  final IconData icon;
  final String label;
}

// "Feito para" strip — bloco entre Features e Pricing no mobile (CSS
// .segments). 4 ícones em grid 2x2. Não existe no design desktop (segments
// vai no footer).
class SegmentsSection extends StatelessWidget {
  const SegmentsSection({super.key});

  static const _items = <_Segment>[
    _Segment(Icons.pets_outlined, 'Pet shop'),
    _Segment(Icons.build_outlined, 'Assistência técnica'),
    _Segment(Icons.checkroom_outlined, 'Loja de roupas'),
    _Segment(Icons.menu_book_outlined, 'Papelaria'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebRootTokens.surface,
      padding: const EdgeInsets.fromLTRB(
        WebRootTokens.gutterMobile,
        40,
        WebRootTokens.gutterMobile,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'FEITO PARA',
              style: TextStyle(
                fontFamily: WebRootTokens.fontFamily,
                fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                color: WebRootTokens.fgMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              // h ~= 56 pra ficar próximo do design (padding 12 14 + content)
              childAspectRatio: 3.1,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) => _SegmentTile(_items[i]),
          ),
        ],
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile(this.s);
  final _Segment s;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WebRootTokens.bgCanvas,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(s.icon, size: 18, color: WebRootTokens.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.label,
              style: const TextStyle(
                fontFamily: WebRootTokens.fontFamily,
                fontFamilyFallback: WebRootTokens.fontFamilyFallback,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: WebRootTokens.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
