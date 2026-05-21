import 'package:appplanilha/design_system/tokens/web_root_tokens.dart';
import 'package:appplanilha/presentation/components/web_root/eyebrow.dart';
import 'package:appplanilha/presentation/components/web_root/plan_card.dart';
import 'package:appplanilha/presentation/components/web_root/responsive_container.dart';
import 'package:flutter/material.dart';

class PricingSection extends StatefulWidget {
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
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  // Tunables do perspective stack
  static const double _centerScale = 1.04;
  static const double _sideScale = 0.92;
  static const double _sideTranslateY = 10;
  static const double _sideOpacity = 0.62;
  static const double _viewportFraction = 0.82;

  late final PageController _page = PageController(
    initialPage: 1, // Profissional (featured) começa centrado
    viewportFraction: _viewportFraction,
  );

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebRootTokens.surface,
      padding: EdgeInsets.symmetric(vertical: widget.isDesktop ? 96 : 48),
      child: ResponsiveContainer(
        isDesktop: widget.isDesktop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _head(),
            SizedBox(height: widget.isDesktop ? 56 : 28),
            if (widget.isDesktop) _gridDesktop() else _perspectiveMobile(),
          ],
        ),
      ),
    );
  }

  Widget _head() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: widget.isDesktop ? 720 : double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(text: 'Planos', isDesktop: widget.isDesktop),
            SizedBox(height: widget.isDesktop ? 16 : 14),
            Text(
              // Copy "média" do SIX_COPY (pricing.title.medio).
              'Escolha o plano certo para seu negócio',
              style: widget.isDesktop
                  ? WebRootTokens.sectionTitleDesktop
                  : WebRootTokens.sectionTitleMobile,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 12),
            Text(
              // Copy "média" (pricing.subtitle.medio).
              'Comece com Inicial, escale para Profissional conforme crescer. '
              'Cockpit disponível para operações complexas.',
              style: widget.isDesktop
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
            for (var i = 0; i < PricingSection._plans.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: cardW,
                child: PlanCard(
                  plan: PricingSection._plans[i],
                  isDesktop: true,
                  // Pula o translateY hardcoded do PlanCard featured (que é
                  // só relevante no grid clássico). Sem effect aqui.
                  emphasizeFeatured: true,
                  onChoose: () =>
                      widget.onChoose?.call(PricingSection._plans[i].name),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// PageView com transform: scale/translate/opacity baseado na distância
  /// do índice corrente. Tap em card lateral anima para ele.
  /// Dots indicator embaixo dá feedback visual da página corrente.
  Widget _perspectiveMobile() {
    return Column(
      children: [
        SizedBox(
          // Altura levemente maior que o card pra acomodar o centro escalado
          // sem clip vertical (que aparece no shadow do featured).
          height: 560,
          child: PageView.builder(
            controller: _page,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: PricingSection._plans.length,
            onPageChanged: (_) => setState(() {}),
            itemBuilder: (context, i) {
              return AnimatedBuilder(
                animation: _page,
                builder: (context, child) {
                  // delta = distância do índice ao "page" atual.
                  // Usa hasClients pra evitar erro no primeiro frame.
                  final page = _page.hasClients && _page.page != null
                      ? _page.page!
                      : _page.initialPage.toDouble();
                  final delta = (page - i).abs().clamp(0.0, 1.0);

                  // Lerp center → side
                  final scale = _lerp(_centerScale, _sideScale, delta);
                  final ty = _lerp(0, _sideTranslateY, delta);
                  final op = _lerp(1.0, _sideOpacity, delta);

                  return Center(
                    child: Opacity(
                      opacity: op,
                      child: Transform.translate(
                        offset: Offset(0, ty),
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: Padding(
                  // Pequena folga lateral pra ver os "ombros" das laterais.
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      // Tap em card lateral → traz pro centro.
                      _page.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: PlanCard(
                      plan: PricingSection._plans[i],
                      isDesktop: false,
                      // No mobile com perspective, NÃO aplicamos o translateY
                      // hardcoded do PlanCard featured (a perspective já lida).
                      emphasizeFeatured: false,
                      onChoose: () =>
                          widget.onChoose?.call(PricingSection._plans[i].name),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _dotsIndicator(),
      ],
    );
  }

  /// Dots indicator — feedback visual da página atual.
  /// Acompanha _page.page com AnimatedBuilder pra ficar suave durante o
  /// arrasto, não só nos snaps.
  Widget _dotsIndicator() {
    return AnimatedBuilder(
      animation: _page,
      builder: (context, _) {
        final page = _page.hasClients && _page.page != null
            ? _page.page!
            : _page.initialPage.toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < PricingSection._plans.length; i++)
              _dot(distance: (page - i).abs().clamp(0.0, 1.0)),
          ],
        );
      },
    );
  }

  Widget _dot({required double distance}) {
    // Dot ativo: 22w x 6h, accent. Dot inativo: 6w x 6h, line.
    final width = _lerp(22, 6, distance);
    final color = Color.lerp(
      WebRootTokens.accent,
      WebRootTokens.line,
      distance,
    )!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
