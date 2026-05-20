import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/eyebrow.dart';
import 'package:appplanilha/presentation/components/web_root/plan_card.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_container.dart';
import 'package:flutter/material.dart';

class PricingSection extends StatelessWidget {
  const PricingSection({super.key, required this.isDesktop, this.onChoose});

  final bool isDesktop;
  final ValueChanged<String>? onChoose;

  static const _plans = <PlanData>[
    PlanData(
      name: 'Inicial',
      price: 'R\$ 0',
      cadence: 'para sempre',
      pitch: 'Comece a vender hoje, sem assinar nada.',
      features: [
        'Frente de caixa',
        'Até 50 produtos',
        'Relatórios básicos',
        'Suporte por e-mail',
      ],
      cta: 'Começar grátis',
    ),
    PlanData(
      name: 'Profissional',
      price: 'R\$ 89',
      cadence: 'por mês',
      pitch: 'Para a maioria das lojas que vivem do balcão e do WhatsApp.',
      features: [
        'Tudo do Inicial',
        'Estoque + IA de cadastro',
        'Ordens de serviço',
        'Financeiro preditivo',
        'Suporte em português',
      ],
      cta: 'Assinar Profissional',
      featured: true,
    ),
    PlanData(
      name: 'Cockpit',
      price: 'R\$ 189',
      cadence: 'por mês',
      pitch: 'Para quem cresce e precisa de painel executivo.',
      features: [
        'Tudo do Profissional',
        'Cockpit estratégico',
        'Múltiplas filiais',
        'Acesso por colaborador',
        'Suporte dedicado',
      ],
      cta: 'Falar com vendas',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebRootTokens.surface,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 96 : 48),
      child: ResponsiveContainer(
        isDesktop: isDesktop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _head(),
            SizedBox(height: isDesktop ? 56 : 28),
            if (isDesktop) _gridDesktop() else _scrollMobile(),
          ],
        ),
      ),
    );
  }

  Widget _head() {
    // Design (.section__head): text-align LEFT, max-width 720.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: isDesktop ? 720 : double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(text: 'Planos', isDesktop: isDesktop),
            SizedBox(height: isDesktop ? 16 : 14),
            Text(
              'Preço justo, sem pegadinha.',
              style: isDesktop
                  ? WebRootTokens.sectionTitleDesktop
                  : WebRootTokens.sectionTitleMobile,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 12),
            Text(
              'Cancele a qualquer momento. Você só paga depois dos 14 dias de teste.',
              style: isDesktop
                  ? WebRootTokens.leadDesktop.copyWith(fontSize: 16)
                  : WebRootTokens.leadMobile.copyWith(fontSize: 15),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridDesktop() {
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 3;
        const gap = 20.0;
        final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _plans.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: cardW,
                child: PlanCard(
                  plan: _plans[i],
                  isDesktop: true,
                  onChoose: () => onChoose?.call(_plans[i].name),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _scrollMobile() {
    // Snap-scroll horizontal (mirror do CSS .pricing-scroll).
    return SizedBox(
      height: 460,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: 280,
          child: PlanCard(
            plan: _plans[i],
            isDesktop: false,
            onChoose: () => onChoose?.call(_plans[i].name),
          ),
        ),
      ),
    );
  }
}
