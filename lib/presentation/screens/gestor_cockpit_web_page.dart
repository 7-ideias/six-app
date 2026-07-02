import 'package:flutter/material.dart';

class GestorCockpitWebPage extends StatefulWidget {
  final VoidCallback? onBack;

  const GestorCockpitWebPage({super.key, this.onBack});

  @override
  State<GestorCockpitWebPage> createState() => _GestorCockpitWebPageState();
}

class _GestorCockpitWebPageState extends State<GestorCockpitWebPage> {
  String _periodo = 'Últimos 30 dias';
  String _produto = 'Todos os produtos';
  String _cliente = 'Todos os clientes';
  String _vendedor = 'Todos os vendedores';

  static const List<String> _periodos = <String>[
    'Hoje',
    'Últimos 7 dias',
    'Últimos 30 dias',
    'Este mês',
    'Este trimestre',
    'Este ano',
  ];

  static const List<String> _produtos = <String>[
    'Todos os produtos',
    'Celulares',
    'Peças e componentes',
    'Serviços técnicos',
    'Acessórios',
  ];

  static const List<String> _clientes = <String>[
    'Todos os clientes',
    'Novos clientes',
    'Clientes recorrentes',
    'Clientes em risco',
    'Clientes B2B',
  ];

  static const List<String> _vendedores = <String>[
    'Todos os vendedores',
    'Ana Souza',
    'Bruno Lima',
    'Carla Mendes',
    'Diego Rocha',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return DefaultTabController(
      length: 6,
      child: Container(
        color: colors.surface,
        child: Column(
          children: <Widget>[
            _buildHeader(theme),
            Divider(height: 1, color: colors.outlineVariant),
            Material(
              color: colors.surface,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                indicatorColor: colors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                tabs: const <Widget>[
                  Tab(text: 'Vendas, orçamentos e assistências'),
                  Tab(text: 'Clientes'),
                  Tab(text: 'Vendedores'),
                  Tab(text: 'Produtos'),
                  Tab(text: 'Estoque'),
                  Tab(text: 'Satisfação do atendimento'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _buildVendasAssistenciasTab(theme),
                  _buildClientesTab(theme),
                  _buildVendedoresTab(theme),
                  _buildProdutosTab(theme),
                  _buildEstoqueTab(theme),
                  _buildSatisfacaoTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.primary.withOpacity(0.16)),
                ),
                child: Icon(
                  Icons.space_dashboard_rounded,
                  color: colors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Cockpit do gestor',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Visão executiva para acompanhar vendas, assistência técnica, clientes, vendedores, produtos, estoque e satisfação em uma única central.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildDemoBadge(theme),
              if (widget.onBack != null) ...<Widget>[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Voltar'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _buildFilters(theme),
        ],
      ),
    );
  }

  Widget _buildDemoBadge(ThemeData theme) {
    final ColorScheme colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.science_outlined, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            'Dados demonstrativos',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _buildFilterDropdown(
          theme: theme,
          label: 'Período',
          icon: Icons.date_range_rounded,
          value: _periodo,
          items: _periodos,
          onChanged: (String value) => setState(() => _periodo = value),
        ),
        _buildFilterDropdown(
          theme: theme,
          label: 'Produto',
          icon: Icons.inventory_2_outlined,
          value: _produto,
          items: _produtos,
          onChanged: (String value) => setState(() => _produto = value),
        ),
        _buildFilterDropdown(
          theme: theme,
          label: 'Cliente',
          icon: Icons.person_search_rounded,
          value: _cliente,
          items: _clientes,
          onChanged: (String value) => setState(() => _cliente = value),
        ),
        _buildFilterDropdown(
          theme: theme,
          label: 'Vendedor',
          icon: Icons.badge_outlined,
          value: _vendedor,
          items: _vendedores,
          onChanged: (String value) => setState(() => _vendedor = value),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final ColorScheme colors = theme.colorScheme;

    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          filled: true,
          fillColor: colors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: (String? value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  Widget _buildVendasAssistenciasTab(ThemeData theme) {
    return _buildTabScaffold(
      theme: theme,
      children: <Widget>[
        _buildKpiGrid(
          theme: theme,
          kpis: <_CockpitKpi>[
            _CockpitKpi('Receita líquida', 486300, 'R\$ ', '+8,6% vs período anterior', Icons.trending_up_rounded),
            _CockpitKpi('Vendas concluídas', 1248, '', '+12,4% no balcão', Icons.point_of_sale_rounded),
            _CockpitKpi('Orçamentos pendentes', 86, '', '37 com follow-up atrasado', Icons.request_quote_outlined),
            _CockpitKpi('Assistências abertas', 142, '', '18 próximas do SLA', Icons.build_circle_outlined),
          ],
        ),
        _buildResponsiveTwoColumns(
          left: _buildVerticalBarsCard(
            theme: theme,
            title: 'Resultado por mês',
            subtitle: 'Receita, vendas e assistência técnica em visão agregada.',
            bars: const <_ChartItem>[
              _ChartItem('Jan', 62),
              _ChartItem('Fev', 74),
              _ChartItem('Mar', 81),
              _ChartItem('Abr', 92),
              _ChartItem('Mai', 88),
              _ChartItem('Jun', 100),
            ],
          ),
          right: _buildHorizontalBarsCard(
            theme: theme,
            title: 'Funil comercial',
            subtitle: 'Da oportunidade ao fechamento.',
            items: const <_ChartItem>[
              _ChartItem('Orçamentos criados', 100),
              _ChartItem('Aguardando cliente', 72),
              _ChartItem('Aprovados', 48),
              _ChartItem('Convertidos em venda', 39),
            ],
          ),
        ),
        _buildInsightGrid(
          theme: theme,
          insights: const <_InsightItem>[
            _InsightItem('Prioridade do dia', '18 assistências estão próximas do SLA e devem aparecer no topo da fila técnica.', Icons.priority_high_rounded),
            _InsightItem('Oportunidade', 'Orçamentos acima de R\$ 500 têm 22% mais conversão quando recebem retorno no mesmo dia.', Icons.auto_awesome_rounded),
            _InsightItem('Atenção', 'A queda de ticket em acessórios sugere revisar kits e combos no balcão.', Icons.warning_amber_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildClientesTab(ThemeData theme) {
    return _buildTabScaffold(
      theme: theme,
      children: <Widget>[
        _buildKpiGrid(
          theme: theme,
          kpis: <_CockpitKpi>[
            _CockpitKpi('Clientes ativos', 3420, '', '+7,8% no período', Icons.groups_rounded),
            _CockpitKpi('Novos clientes', 186, '', 'Origem principal: indicação', Icons.person_add_alt_1_rounded),
            _CockpitKpi('Recorrência', 38.4, '', '+3,1 p.p', Icons.repeat_rounded, suffix: '%'),
            _CockpitKpi('Ticket médio por cliente', 312, 'R\$ ', '+5,4%', Icons.payments_outlined),
          ],
        ),
        _buildResponsiveTwoColumns(
          left: _buildHorizontalBarsCard(
            theme: theme,
            title: 'Segmentos de clientes',
            subtitle: 'Distribuição por comportamento de compra e atendimento.',
            items: const <_ChartItem>[
              _ChartItem('Recorrentes', 82),
              _ChartItem('Novos', 54),
              _ChartItem('B2B', 36),
              _ChartItem('Em risco', 18),
            ],
          ),
          right: _buildInsightCard(
            theme: theme,
            title: 'Próximas evoluções sugeridas',
            icon: Icons.hub_outlined,
            lines: const <String>[
              'Ranking de clientes por margem, frequência e risco de churn.',
              'Ações rápidas para WhatsApp quando houver orçamento parado.',
              'Filtro por origem, bairro, tipo de serviço e recorrência.',
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendedoresTab(ThemeData theme) {
    return _buildTabScaffold(
      theme: theme,
      children: <Widget>[
        _buildKpiGrid(
          theme: theme,
          kpis: <_CockpitKpi>[
            _CockpitKpi('Vendas por vendedor', 1248, '', 'Equipe completa', Icons.badge_outlined),
            _CockpitKpi('Conversão média', 42.6, '', '+4,2 p.p', Icons.published_with_changes_rounded, suffix: '%'),
            _CockpitKpi('Comissão estimada', 18640, 'R\$ ', 'Prévia do período', Icons.workspace_premium_outlined),
            _CockpitKpi('Atendimentos por hora', 7.4, '', 'Pico às 15h', Icons.timer_outlined),
          ],
        ),
        _buildHorizontalBarsCard(
          theme: theme,
          title: 'Ranking de performance',
          subtitle: 'Vendas ponderadas por conversão, ticket médio e satisfação.',
          items: const <_ChartItem>[
            _ChartItem('Ana Souza', 96),
            _ChartItem('Bruno Lima', 84),
            _ChartItem('Carla Mendes', 73),
            _ChartItem('Diego Rocha', 65),
          ],
        ),
        _buildInsightGrid(
          theme: theme,
          insights: const <_InsightItem>[
            _InsightItem('Coaching comercial', 'Bruno vende muito, mas perde margem em descontos acima da média.', Icons.school_outlined),
            _InsightItem('Melhor prática', 'Ana combina orçamento com retorno rápido e tem maior conversão em assistência.', Icons.verified_outlined),
            _InsightItem('Risco operacional', 'Diego concentra atendimentos longos em horários de pico.', Icons.schedule_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildProdutosTab(ThemeData theme) {
    return _buildTabScaffold(
      theme: theme,
      children: <Widget>[
        _buildKpiGrid(
          theme: theme,
          kpis: <_CockpitKpi>[
            _CockpitKpi('Produtos vendidos', 2196, '', '+14,1%', Icons.inventory_2_outlined),
            _CockpitKpi('Serviços executados', 438, '', 'Alta em telas', Icons.handyman_outlined),
            _CockpitKpi('Margem média', 27.8, '', '+1,9 p.p', Icons.percent_rounded, suffix: '%'),
            _CockpitKpi('Mix com baixa saída', 43, '', 'Revisar exposição', Icons.low_priority_rounded),
          ],
        ),
        _buildResponsiveTwoColumns(
          left: _buildVerticalBarsCard(
            theme: theme,
            title: 'Produtos mais vendidos',
            subtitle: 'Volume por categoria no período filtrado.',
            bars: const <_ChartItem>[
              _ChartItem('Capas', 92),
              _ChartItem('Películas', 100),
              _ChartItem('Cabos', 74),
              _ChartItem('Telas', 68),
              _ChartItem('Baterias', 51),
            ],
          ),
          right: _buildHorizontalBarsCard(
            theme: theme,
            title: 'Margem por categoria',
            subtitle: 'Leitura rápida para política comercial.',
            items: const <_ChartItem>[
              _ChartItem('Serviços técnicos', 88),
              _ChartItem('Acessórios', 72),
              _ChartItem('Peças', 58),
              _ChartItem('Produtos de giro', 43),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstoqueTab(ThemeData theme) {
    return _buildTabScaffold(
      theme: theme,
      children: <Widget>[
        _buildKpiGrid(
          theme: theme,
          kpis: <_CockpitKpi>[
            _CockpitKpi('Itens em estoque', 18420, '', '5 lojas conectadas', Icons.warehouse_outlined),
            _CockpitKpi('Ruptura crítica', 27, '', 'Ação imediata', Icons.report_problem_outlined),
            _CockpitKpi('Estoque parado', 116, '', 'Mais de 90 dias', Icons.inventory_outlined),
            _CockpitKpi('Cobertura média', 38, '', 'Dias de venda', Icons.event_available_outlined),
          ],
        ),
        _buildResponsiveTwoColumns(
          left: _buildHorizontalBarsCard(
            theme: theme,
            title: 'Risco de ruptura',
            subtitle: 'Itens com maior chance de faltar nos próximos dias.',
            items: const <_ChartItem>[
              _ChartItem('Película iPhone', 96),
              _ChartItem('Tela Samsung A', 81),
              _ChartItem('Bateria Moto G', 64),
              _ChartItem('Cabo USB-C', 49),
            ],
          ),
          right: _buildInsightCard(
            theme: theme,
            title: 'Regras inteligentes de estoque',
            icon: Icons.rule_rounded,
            lines: const <String>[
              'Sugerir compra com base em giro, lead time e margem.',
              'Separar estoque técnico de estoque de venda.',
              'Alertar venda negativa conforme regra operacional da empresa.',
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSatisfacaoTab(ThemeData theme) {
    return _buildTabScaffold(
      theme: theme,
      children: <Widget>[
        _buildKpiGrid(
          theme: theme,
          kpis: <_CockpitKpi>[
            _CockpitKpi('NPS', 74, '', 'Meta: 80', Icons.sentiment_satisfied_alt_rounded),
            _CockpitKpi('Avaliações recebidas', 318, '', 'Via link do cliente', Icons.rate_review_outlined),
            _CockpitKpi('CSAT', 91.2, '', '+2,7 p.p', Icons.thumb_up_alt_outlined, suffix: '%'),
            _CockpitKpi('Tempo médio resposta', 2.4, '', 'Horas', Icons.quickreply_outlined, suffix: 'h'),
          ],
        ),
        _buildResponsiveTwoColumns(
          left: _buildSatisfactionScore(theme),
          right: _buildInsightCard(
            theme: theme,
            title: 'Coleta via link gerado',
            icon: Icons.link_rounded,
            lines: const <String>[
              'Ao finalizar venda, orçamento ou ordem de serviço, o Six poderá gerar um link de avaliação.',
              'O cliente responde pelo celular, sem login, e a nota alimenta este painel.',
              'A próxima etapa pode vincular nota ao vendedor, técnico, produto e tipo de atendimento.',
            ],
          ),
        ),
        _buildHorizontalBarsCard(
          theme: theme,
          title: 'Motivos mais citados',
          subtitle: 'Base demonstrativa para orientar treinamento e melhoria contínua.',
          items: const <_ChartItem>[
            _ChartItem('Rapidez do atendimento', 92),
            _ChartItem('Clareza no orçamento', 76),
            _ChartItem('Preço percebido', 51),
            _ChartItem('Comunicação da OS', 43),
          ],
        ),
      ],
    );
  }

  Widget _buildTabScaffold({
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...children.expand((Widget child) => <Widget>[child, const SizedBox(height: 18)]),
        ],
      ),
    );
  }

  Widget _buildKpiGrid({required ThemeData theme, required List<_CockpitKpi> kpis}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = constraints.maxWidth;
        final int columns = available >= 1180
            ? 4
            : available >= 880
                ? 3
                : available >= 580
                    ? 2
                    : 1;
        final double width = (available - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: kpis.map(( _CockpitKpi kpi) {
            return SizedBox(width: width, child: _buildKpiCard(theme, kpi));
          }).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(ThemeData theme, _CockpitKpi kpi) {
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(kpi.icon, color: colors.primary, size: 22),
              ),
              const Spacer(),
              Icon(Icons.north_east_rounded, size: 18, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: kpi.value),
            duration: const Duration(milliseconds: 720),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Text(
                '${kpi.prefix}${_formatNumber(value)}${kpi.suffix}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            kpi.hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveTwoColumns({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: <Widget>[left, const SizedBox(height: 18), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: left),
            const SizedBox(width: 18),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildVerticalBarsCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required List<_ChartItem> bars,
  }) {
    final ColorScheme colors = theme.colorScheme;
    final double maxValue = bars.fold<double>(0, (double current, _ChartItem item) => item.value > current ? item.value : current);

    return _buildPanel(
      theme: theme,
      title: title,
      subtitle: subtitle,
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 250,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars.map((_ChartItem item) {
            final double factor = maxValue == 0 ? 0 : item.value / maxValue;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: factor),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          builder: (BuildContext context, double animated, Widget? child) {
                            return FractionallySizedBox(
                              heightFactor: animated.clamp(0.04, 1.0),
                              widthFactor: 0.72,
                              alignment: Alignment.bottomCenter,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.82),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHorizontalBarsCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required List<_ChartItem> items,
  }) {
    final ColorScheme colors = theme.colorScheme;
    final double maxValue = items.fold<double>(0, (double current, _ChartItem item) => item.value > current ? item.value : current);

    return _buildPanel(
      theme: theme,
      title: title,
      subtitle: subtitle,
      icon: Icons.stacked_bar_chart_rounded,
      child: Column(
        children: items.map((_ChartItem item) {
          final double factor = maxValue == 0 ? 0 : item.value / maxValue;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${item.value.toInt()}%',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: factor),
                    duration: const Duration(milliseconds: 680),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double animated, Widget? child) {
                      return LinearProgressIndicator(
                        value: animated,
                        minHeight: 11,
                        backgroundColor: colors.primary.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary.withOpacity(0.78)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPanel({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final ColorScheme colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInsightGrid({required ThemeData theme, required List<_InsightItem> insights}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 920;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: insights.map((_InsightItem insight) {
            return SizedBox(
              width: compact ? constraints.maxWidth : (constraints.maxWidth - 28) / 3,
              child: _buildInsightTile(theme, insight),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInsightTile(ThemeData theme, _InsightItem insight) {
    final ColorScheme colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(insight.icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  insight.title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.description,
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<String> lines,
  }) {
    return _buildPanel(
      theme: theme,
      title: title,
      subtitle: 'Hipóteses para a próxima evolução do cockpit.',
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((String line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.check_circle_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSatisfactionScore(ThemeData theme) {
    final ColorScheme colors = theme.colorScheme;
    return _buildPanel(
      theme: theme,
      title: 'Pulso de satisfação',
      subtitle: 'Consolidação das respostas recebidas pelo link do cliente.',
      icon: Icons.sentiment_very_satisfied_rounded,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 0.91),
          duration: const Duration(milliseconds: 760),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double value, Widget? child) {
            return SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 18,
                      backgroundColor: colors.primary.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CSAT',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000) {
      return value.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]}.',
      );
    }
    if (value % 1 == 0) return value.round().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _CockpitKpi {
  final String label;
  final double value;
  final String prefix;
  final String hint;
  final IconData icon;
  final String suffix;

  const _CockpitKpi(
    this.label,
    this.value,
    this.prefix,
    this.hint,
    this.icon, {
    this.suffix = '',
  });
}

class _ChartItem {
  final String label;
  final double value;

  const _ChartItem(this.label, this.value);
}

class _InsightItem {
  final String title;
  final String description;
  final IconData icon;

  const _InsightItem(this.title, this.description, this.icon);
}
