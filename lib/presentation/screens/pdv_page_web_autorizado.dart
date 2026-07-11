import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/components/ai_assistant/ai_assistant_host.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import 'pdv_page_web_dashboard.dart';

const Color _primary = Color(0xFF24458F);
const Color _text = Color(0xFF111827);
const Color _muted = Color(0xFF596579);
const Color _surface = Color(0xFFFFFFFF);
const Color _border = Color(0x1F24458F);

class PdvPageWebAutorizado extends StatefulWidget {
  const PdvPageWebAutorizado({super.key});

  @override
  State<PdvPageWebAutorizado> createState() => _PdvPageWebAutorizadoState();
}

class _PdvPageWebAutorizadoState extends State<PdvPageWebAutorizado> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<ColaboradorAutorizacoesProvider>()
          .carregarAutorizacoesDoUsuarioLogado();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool podeFazerVenda = context
        .select<ColaboradorAutorizacoesProvider, bool>(
          (ColaboradorAutorizacoesProvider provider) => provider.podeFazerVenda,
        );
    final bool loading = context.select<ColaboradorAutorizacoesProvider, bool>(
      (ColaboradorAutorizacoesProvider provider) => provider.loading,
    );

    if (loading) {
      return const _PdvAutorizacoesLoading();
    }

    if (podeFazerVenda) {
      return const AiAssistantHost(
        modulo: 'geral',
        telaAtual: 'inicio_web',
        child: _WebBrandWatermark(child: PDVWeb()),
      );
    }

    return const AiAssistantHost(
      modulo: 'geral',
      telaAtual: 'inicio_web_sem_vendas',
      child: _WebBrandWatermark(child: _PdvSemVendasWeb()),
    );
  }
}

class _WebBrandWatermark extends StatelessWidget {
  const _WebBrandWatermark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxWidth < 720;
            final double size =
                (isCompact
                        ? constraints.maxWidth * 0.42
                        : constraints.maxWidth * 0.16)
                    .clamp(isCompact ? 140.0 : 190.0, isCompact ? 240.0 : 300.0)
                    .toDouble();

            return IgnorePointer(
              child: Align(
                alignment:
                    isCompact
                        ? const Alignment(0.80, 0.86)
                        : const Alignment(0.88, 0.80),
                child: Opacity(
                  opacity: 0.045,
                  child: Image.asset(
                    'assets/images/six-logo-flecha.png',
                    width: size,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PdvAutorizacoesLoading extends StatelessWidget {
  const _PdvAutorizacoesLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F8FB),
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class _PdvSemVendasWeb extends StatelessWidget {
  const _PdvSemVendasWeb();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Início',
                          style: TextStyle(
                            color: _text,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ações disponíveis conforme as permissões do colaborador.',
                          style: TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      context
                          .read<ColaboradorAutorizacoesProvider>()
                          .carregarAutorizacoesDoUsuarioLogado(force: true);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Atualizar permissões'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: const <Widget>[
                      _ModuloPermitidoCard(
                        icon: Icons.space_dashboard_rounded,
                        badge: 'Gestão visionária',
                        title: 'Cockpit',
                        description:
                            'Antecipe riscos de margem, vendas e atendimento com foco em resultado sustentável.',
                      ),
                      _ModuloPermitidoCard(
                        icon: Icons.account_balance_wallet,
                        badge: 'Operação interna',
                        title: 'Operações de caixa',
                        description:
                            'Controle operacional e financeiro da rotina do balcão.',
                      ),
                      _ModuloPermitidoCard(
                        icon: Icons.monetization_on,
                        badge: 'Operação interna',
                        title: 'Agenda Financeira',
                        description:
                            'Acompanhe contas, compromissos financeiros e previsões.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _PermissaoInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuloPermitidoCard extends StatelessWidget {
  const _ModuloPermitidoCard({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Icon(icon, color: _primary, size: 36),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: _muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissaoInfoCard extends StatelessWidget {
  const _PermissaoInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: _primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'As opções exibidas respeitam as permissões configuradas pelo administrador.',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
