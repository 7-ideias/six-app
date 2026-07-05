import 'package:flutter/material.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_web.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_lista_web_page.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_web_page.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_web_page.dart';
import 'package:sixpos/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:sixpos/top_navigation_bar.dart';

class PDVWeb extends StatefulWidget {
  const PDVWeb({super.key});

  @override
  State<PDVWeb> createState() => _PDVWebState();
}

enum _ModuloPDVWeb {
  inicio,
  vendaRapida,
  novoAtendimentoTecnico,
  resumoAtendimentosTecnicos,
  operacoesCaixa,
  agendaFinanceira,
}

class _PDVWebState extends State<PDVWeb> {
  _ModuloPDVWeb _moduloAtual = _ModuloPDVWeb.inicio;

  void _abrir(_ModuloPDVWeb modulo) {
    setState(() {
      _moduloAtual = modulo;
    });
  }

  void _voltarInicio() {
    setState(() {
      _moduloAtual = _ModuloPDVWeb.inicio;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: TopNavigationBar(
        items: <TopNavItemData>[
          TopNavItemData(
            title: 'Início',
            subItems: const <String>['Painel do PDV'],
            onSelect: (_) => _voltarInicio(),
          ),
          TopNavItemData(
            title: 'Atendimento',
            subItems: const <String>['Resumo de atendimentos', 'Novo atendimento técnico'],
            onSelect: (value) {
              if (value == 'Novo atendimento técnico') {
                _abrir(_ModuloPDVWeb.novoAtendimentoTecnico);
                return;
              }
              _abrir(_ModuloPDVWeb.resumoAtendimentosTecnicos);
            },
          ),
          TopNavItemData(
            title: 'Operação',
            subItems: const <String>['Venda rápida', 'Operações de caixa', 'Agenda financeira'],
            onSelect: (value) {
              if (value == 'Venda rápida') {
                _abrir(_ModuloPDVWeb.vendaRapida);
              }
              if (value == 'Operações de caixa') {
                _abrir(_ModuloPDVWeb.operacoesCaixa);
              }
              if (value == 'Agenda financeira') {
                _abrir(_ModuloPDVWeb.agendaFinanceira);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _buildConteudo(),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    switch (_moduloAtual) {
      case _ModuloPDVWeb.inicio:
        return _PDVWebInicio(onOpen: _abrir);
      case _ModuloPDVWeb.vendaRapida:
        return _SubPainelWebShell(
          title: 'Venda rápida',
          subtitle: 'Selecione produtos e serviços do catálogo.',
          onBack: _voltarInicio,
          child: const SubPainelWebProdutoLista(isSelecao: false, modoEdicao: false),
        );
      case _ModuloPDVWeb.novoAtendimentoTecnico:
        return AtendimentosTecnicosWebPage(embedded: true, onBack: _voltarInicio);
      case _ModuloPDVWeb.resumoAtendimentosTecnicos:
        return AtendimentosTecnicosListaWebPage(embedded: true, onBack: _voltarInicio);
      case _ModuloPDVWeb.operacoesCaixa:
        return OperacoesCaixaWebPage(embedded: true, onBack: _voltarInicio);
      case _ModuloPDVWeb.agendaFinanceira:
        return AgendaFinanceiraWeb(embedded: true, onBack: _voltarInicio);
    }
  }
}

class _PDVWebInicio extends StatelessWidget {
  const _PDVWebInicio({required this.onOpen});

  final ValueChanged<_ModuloPDVWeb> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.16)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Icon(Icons.handyman_outlined, color: theme.colorScheme.primary, size: 34),
                SizedBox(
                  width: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Atendimento técnico',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fluxo web para acompanhar atendimentos técnicos, produtos, serviços, recebimentos fracionados, assinatura e histórico.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth < 760 ? constraints.maxWidth : (constraints.maxWidth - 40) / 3;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: <Widget>[
                  _ModuloCard(
                    width: width,
                    icon: Icons.handyman_outlined,
                    badge: 'Atendimento',
                    title: 'Atendimento técnico',
                    description: 'Abra o resumo de atendimentos técnicos criados para consultar, editar e receber valores.',
                    highlighted: true,
                    onTap: () => onOpen(_ModuloPDVWeb.resumoAtendimentosTecnicos),
                  ),
                  _ModuloCard(
                    width: width,
                    icon: Icons.add_task_outlined,
                    badge: 'Novo fluxo',
                    title: 'Novo atendimento',
                    description: 'Cadastre cliente, equipamento, defeito, produtos, serviços, validade e vencimento financeiro.',
                    onTap: () => onOpen(_ModuloPDVWeb.novoAtendimentoTecnico),
                  ),
                  _ModuloCard(
                    width: width,
                    icon: Icons.point_of_sale_rounded,
                    badge: 'Venda',
                    title: 'Venda rápida',
                    description: 'Acesse o catálogo web para operações rápidas de balcão.',
                    onTap: () => onOpen(_ModuloPDVWeb.vendaRapida),
                  ),
                  _ModuloCard(
                    width: width,
                    icon: Icons.account_balance_wallet_outlined,
                    badge: 'Caixa',
                    title: 'Operações de caixa',
                    description: 'Consulte entradas, movimentações e recebimentos vinculados ao caixa.',
                    onTap: () => onOpen(_ModuloPDVWeb.operacoesCaixa),
                  ),
                  _ModuloCard(
                    width: width,
                    icon: Icons.event_note_outlined,
                    badge: 'Financeiro',
                    title: 'Agenda financeira',
                    description: 'Acompanhe vencimentos e liquidações parciais dos atendimentos.',
                    onTap: () => onOpen(_ModuloPDVWeb.agendaFinanceira),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubPainelWebShell extends StatelessWidget {
  const _SubPainelWebShell({required this.title, required this.subtitle, required this.onBack, required this.child});

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        Expanded(child: child),
      ],
    );
  }
}

class _ModuloCard extends StatelessWidget {
  const _ModuloCard({required this.width, required this.icon, required this.badge, required this.title, required this.description, required this.onTap, this.highlighted = false});

  final double width;
  final IconData icon;
  final String badge;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      height: 252,
      child: Card(
        elevation: highlighted ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: highlighted ? colorScheme.primary.withValues(alpha: 0.34) : colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: colorScheme.primary),
                    ),
                    const Spacer(),
                    Icon(Icons.north_east_rounded, color: colorScheme.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(badge, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 6),
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.42, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
