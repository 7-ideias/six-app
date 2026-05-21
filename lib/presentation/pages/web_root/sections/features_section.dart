import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/eyebrow.dart';
import 'package:appplanilha/presentation/components/web_root/feature_card.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_container.dart';
import 'package:flutter/material.dart';

class _FeatureData {
  const _FeatureData(this.icon, this.color, this.title, this.body);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key, required this.isDesktop});

  final bool isDesktop;

  static final _features = <_FeatureData>[
    _FeatureData(
      Icons.shopping_cart_outlined,
      WebRootTokens.featureTeal,
      'Frente de caixa em tempo real',
      'Venda em segundos no balcão, leitor ou celular. Sincroniza estoque na hora.',
    ),
    _FeatureData(
      Icons.work_outline,
      WebRootTokens.featureBlue,
      'Ordens de serviço completas',
      'Controle fila técnica, SLA, peças e comunicação com o cliente sem planilha.',
    ),
    _FeatureData(
      Icons.trending_up,
      WebRootTokens.ink,
      'Financeiro preditivo',
      'Previsão de fluxo de caixa, alertas de risco e painel executivo com IA.',
    ),
    _FeatureData(
      Icons.insights,
      WebRootTokens.featurePurple,
      'Cockpit estratégico',
      'Cruza caixa, margem, vendas e atendimento em um único painel.',
    ),
    _FeatureData(
      Icons.auto_awesome,
      WebRootTokens.accent,
      'Cadastro com IA',
      'Tire foto do produto — a IA cadastra com preço sugerido e categoria.',
    ),
    _FeatureData(
      Icons.support_agent,
      WebRootTokens.featureCyan,
      'Suporte humano em português',
      'Atendimento na hora — não bot, não FAQ enlatado.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebRootTokens.bgCanvas,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 96 : 48),
      child: ResponsiveContainer(
        isDesktop: isDesktop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alinha à esquerda (não Stretch) — section head é left-aligned
            // com max-width 720 (CSS .section__head).
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _head(isDesktop: isDesktop),
            ),
            SizedBox(height: isDesktop ? 56 : 28),
            if (isDesktop) _gridDesktop() else _listMobile(),
          ],
        ),
      ),
    );
  }

  Widget _head({required bool isDesktop}) {
    // Design (.section__head): text-align LEFT, max-width 720, margin-bottom 56
    // Aplica para desktop e mobile — alinhamento à esquerda padronizado.
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: isDesktop ? 720 : double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(text: 'Recursos', isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 16 : 14),
          Text(
            'Tudo que sua loja precisa, sem a planilha do tio.',
            style: isDesktop
                ? WebRootTokens.sectionTitleDesktop
                : WebRootTokens.sectionTitleMobile,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 12),
          Text(
            isDesktop
                ? 'Pet shop, papelaria, assistência técnica, loja de roupas — o Six '
                    'atende o mesmo dia-a-dia que você já vive, só que organizado.'
                : 'Pet shop, papelaria, assistência técnica, loja de roupas — o Six '
                    'atende o seu dia-a-dia, organizado.',
            style: isDesktop
                ? WebRootTokens.leadDesktop.copyWith(fontSize: 16)
                : WebRootTokens.leadMobile.copyWith(fontSize: 15),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _gridDesktop() {
    // 3 colunas fixas, gap 20. Usa Wrap pra evitar problemas de Intrinsic em
    // contextos com Column.shrink; LayoutBuilder calcula a largura por card.
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 3;
        const gap = 20.0;
        final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: _features
              .map(
                (f) => SizedBox(
                  width: cardW,
                  child: FeatureCard(
                    icon: f.icon,
                    iconColor: f.color,
                    title: f.title,
                    description: f.body,
                    isDesktop: true,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _listMobile() {
    return Column(
      children: _features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeatureCard(
                icon: f.icon,
                iconColor: f.color,
                title: f.title,
                description: f.body,
                isDesktop: false,
              ),
            ),
          )
          .toList(),
    );
  }
}
