import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/servico_dashboard_model.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';

class ServicoDashboardWebPage extends StatefulWidget {
  const ServicoDashboardWebPage({super.key, this.onBack, this.onNovoServico, this.onOpenListaCompleta});

  final VoidCallback? onBack;
  final VoidCallback? onNovoServico;
  final VoidCallback? onOpenListaCompleta;

  @override
  State<ServicoDashboardWebPage> createState() => _ServicoDashboardWebPageState();
}

class _ServicoDashboardWebPageState extends State<ServicoDashboardWebPage> {
  final ProdutoService _produtoService = ProdutoService();
  late Future<ServicoDashboardModel> _future;
  final NumberFormat _money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final NumberFormat _number = NumberFormat.decimalPattern('pt_BR');

  @override
  void initState() {
    super.initState();
    _future = _produtoService.buscarDashboardServicos();
  }

  void _reload() => setState(() => _future = _produtoService.buscarDashboardServicos());
  String _currency(double value) => _money.format(value);
  String _whole(double value) => _number.format(value.round());

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder<ServicoDashboardModel>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<ServicoDashboardModel> snapshot) {
          final Widget child;
          if (snapshot.connectionState == ConnectionState.waiting) {
            child = _loading();
          } else if (snapshot.hasError) {
            child = _error(snapshot.error);
          } else {
            final ServicoDashboardModel data = snapshot.data ?? _empty();
            child = data.isEmpty ? _emptyState() : _dashboard(data);
          }

          return Column(
            children: <Widget>[
              SixWebDashboardHeader(
                icon: Icons.home_repair_service_outlined,
                title: 'Serviços',
                subtitle: 'Resumo executivo do catálogo técnico, preços, garantias e pontos de atenção operacional.',
                onBack: widget.onBack,
                actions: <Widget>[
                  OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
                  FilledButton.icon(onPressed: widget.onNovoServico, icon: const Icon(Icons.add_rounded), label: const Text('Novo serviço')),
                  OutlinedButton.icon(onPressed: widget.onOpenListaCompleta, icon: const Icon(Icons.table_rows_rounded), label: const Text('Lista completa')),
                ],
              ),
              Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 280), child: child)),
            ],
          );
        },
      ),
    );
  }

  ServicoDashboardModel _empty() => const ServicoDashboardModel(
        totalServicos: 0,
        servicosAtivos: 0,
        precoMedio: 0,
        servicosSemPreco: 0,
        servicosComGarantia: 0,
        servicosSemGarantia: 0,
        servicosValorAlteravel: 0,
        servicosSemCategoria: 0,
        servicosCadastroIncompleto: 0,
        servicosPorCategoria: <ServicoDashboardSerieItem>[],
        servicosPorFaixaPreco: <ServicoDashboardSerieItem>[],
        configuracaoOperacional: <ServicoDashboardSerieItem>[],
        servicosAtencao: <ServicoDashboardItem>[],
        servicosEstrategicos: <ServicoDashboardItem>[],
        alertas: <ServicoDashboardAlerta>[],
      );

  Widget _loading() => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 1180;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: <Widget>[
              _loadingKpis(compact),
              const SizedBox(height: 18),
              sixWebResponsiveGroup(compact: compact, children: const <Widget>[SixWebLoadingBlock(height: 280), SixWebLoadingBlock(height: 280), SixWebLoadingBlock(height: 280)]),
              const SizedBox(height: 18),
              sixWebResponsiveGroup(compact: compact, children: const <Widget>[SixWebLoadingBlock(height: 240), SixWebLoadingBlock(height: 240)]),
            ]),
          );
        },
      );

  Widget _loadingKpis(bool compact) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: compact ? 2 : 4, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 118),
        itemBuilder: (BuildContext context, int index) => SixWebEntry(order: index, child: SixWebLoadingBlock(height: 118, highlight: index == 2)),
      );

  Widget _dashboard(ServicoDashboardModel data) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 1180;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              _kpis(data, compact),
              const SizedBox(height: 18),
              sixWebResponsiveGroup(compact: compact, children: <Widget>[
                SixWebEntry(order: 8, child: _serieCard('Serviços por categoria', 'Organização do catálogo por tipo de serviço técnico.', data.servicosPorCategoria)),
                SixWebEntry(order: 9, child: _serieCard('Faixa de preço', 'Distribuição dos serviços por posicionamento comercial.', data.servicosPorFaixaPreco)),
                SixWebEntry(order: 10, child: _serieCard('Configuração operacional', 'Garantia e flexibilidade de valor no atendimento.', data.configuracaoOperacional)),
              ]),
              const SizedBox(height: 18),
              sixWebResponsiveGroup(compact: compact, children: <Widget>[
                SixWebEntry(order: 11, child: _alerts(data.alertas)),
                SixWebEntry(order: 12, child: _attention(data.servicosAtencao)),
              ]),
              const SizedBox(height: 18),
              SixWebEntry(order: 13, child: _strategic(data.servicosEstrategicos)),
            ]),
          );
        },
      );

  Widget _kpis(ServicoDashboardModel data, bool compact) {
    final List<_Kpi> items = <_Kpi>[
      _Kpi(Icons.design_services_outlined, 'Serviços cadastrados', data.totalServicos.toDouble(), _whole),
      _Kpi(Icons.verified_outlined, 'Serviços ativos', data.servicosAtivos.toDouble(), _whole),
      _Kpi(Icons.sell_outlined, 'Preço médio', data.precoMedio, _currency, true),
      _Kpi(Icons.money_off_outlined, 'Sem preço', data.servicosSemPreco.toDouble(), _whole),
      _Kpi(Icons.workspace_premium_outlined, 'Com garantia', data.servicosComGarantia.toDouble(), _whole),
      _Kpi(Icons.no_accounts_outlined, 'Sem garantia', data.servicosSemGarantia.toDouble(), _whole),
      _Kpi(Icons.edit_note_rounded, 'Valor alterável', data.servicosValorAlteravel.toDouble(), _whole),
      _Kpi(Icons.rule_folder_outlined, 'Cadastro incompleto', data.servicosCadastroIncompleto.toDouble(), _whole),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: compact ? 2 : 4, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 118),
      itemBuilder: (BuildContext context, int index) {
        final _Kpi kpi = items[index];
        return SixWebEntry(order: index, child: SixWebKpiCard(icon: kpi.icon, label: kpi.label, value: kpi.value, formatter: kpi.formatter, highlight: kpi.highlight));
      },
    );
  }

  Widget _serieCard(String title, String subtitle, List<ServicoDashboardSerieItem> items) {
    final ThemeData theme = Theme.of(context);
    final List<ServicoDashboardSerieItem> visible = items.where((ServicoDashboardSerieItem item) => item.quantidade > 0).take(5).toList();
    final double maxValue = visible.fold<double>(0, (double max, ServicoDashboardSerieItem item) => item.quantidade > max ? item.quantidade : max);
    return SixWebSectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.insights_outlined,
      child: visible.isEmpty
          ? const SixWebNoData(height: 180)
          : Column(
              children: visible.asMap().entries.map((MapEntry<int, ServicoDashboardSerieItem> entry) {
                final ServicoDashboardSerieItem item = entry.value;
                final double percent = maxValue <= 0 ? 0 : (item.quantidade / maxValue).clamp(0.0, 1.0).toDouble();
                return Padding(
                  padding: EdgeInsets.only(bottom: entry.key == visible.length - 1 ? 0 : 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Row(children: <Widget>[
                      Expanded(child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800))),
                      const SizedBox(width: 12),
                      Text(_whole(item.quantidade), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      key: ValueKey<String>('$title:${item.label}:${item.quantidade}'),
                      tween: Tween<double>(begin: 0, end: percent),
                      duration: Duration(milliseconds: 650 + (entry.key * 90)),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double value, Widget? child) => ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(value: value, minHeight: 12, backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.65)),
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  Widget _alerts(List<ServicoDashboardAlerta> alerts) {
    final ThemeData theme = Theme.of(context);
    return SixWebSectionCard(
      title: 'Atenção necessária',
      icon: Icons.tips_and_updates_outlined,
      child: alerts.isEmpty
          ? const SixWebNoData(text: 'Nenhum alerta operacional encontrado.')
          : Column(children: alerts.map((ServicoDashboardAlerta alert) => _notice(icon: _alertIcon(alert.tipo), color: _alertColor(theme, alert.tipo), title: alert.titulo, subtitle: alert.descricao, value: _whole(alert.quantidade.toDouble()))).toList()),
    );
  }

  Widget _attention(List<ServicoDashboardItem> items) => SixWebSectionCard(
        title: 'Serviços que precisam de atenção',
        icon: Icons.rule_folder_outlined,
        child: items.isEmpty ? const SixWebNoData(text: 'Nenhum serviço com pendência cadastral.') : Column(children: items.map((ServicoDashboardItem item) => _serviceTile(item, showProblem: true)).toList()),
      );

  Widget _strategic(List<ServicoDashboardItem> items) => SixWebSectionCard(
        title: 'Serviços estratégicos por preço',
        icon: Icons.leaderboard_outlined,
        child: items.isEmpty ? const SixWebNoData() : Column(children: items.map((ServicoDashboardItem item) => _serviceTile(item, showProblem: false)).toList()),
      );

  Widget _serviceTile(ServicoDashboardItem item, {required bool showProblem}) {
    final ThemeData theme = Theme.of(context);
    final String title = item.nome.trim().isEmpty ? 'Serviço sem nome' : item.nome.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.35), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Row(children: <Widget>[
        Icon(Icons.home_repair_service_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('${item.categoria.trim().isEmpty ? 'Sem categoria' : item.categoria} • ${_warranty(item.tempoGarantia)} • ${item.podeAlterarValorNaHora ? 'Alterável' : 'Fixo'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
          Text(_currency(item.precoVenda), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(showProblem ? item.problema : _warranty(item.tempoGarantia), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: showProblem ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  Widget _notice({required IconData icon, required Color color, required String title, required String subtitle, required String value}) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.22))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
        ])),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
      ]),
    );
  }

  Widget _error(Object? error) {
    final ThemeData theme = Theme.of(context);
    return Center(child: Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withOpacity(0.30), borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.colorScheme.error.withOpacity(0.25))),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(Icons.cloud_off_rounded, size: 42, color: theme.colorScheme.error),
        const SizedBox(height: 14),
        Text('Não foi possível carregar o resumo de serviços.', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(error?.toString() ?? 'Erro desconhecido', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
      ]),
    ));
  }

  Widget _emptyState() {
    final ThemeData theme = Theme.of(context);
    return Center(child: Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(Icons.home_repair_service_outlined, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 14),
        Text('Nenhum serviço cadastrado ainda.', textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Cadastre os primeiros serviços para acompanhar preços, garantias, categorias e pendências operacionais.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: widget.onNovoServico, icon: const Icon(Icons.add_rounded), label: const Text('Cadastrar serviço')),
      ]),
    ));
  }

  String _warranty(String value) => value.trim().isEmpty ? 'Sem garantia' : value.trim();

  Color _alertColor(ThemeData theme, String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CRITICO':
      case 'ALTO':
        return theme.colorScheme.error;
      case 'MEDIO':
        return Colors.orange.shade700;
      case 'OK':
        return Colors.green.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _alertIcon(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CRITICO':
      case 'ALTO':
        return Icons.priority_high_rounded;
      case 'MEDIO':
        return Icons.warning_amber_rounded;
      case 'OK':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _Kpi {
  const _Kpi(this.icon, this.label, this.value, this.formatter, [this.highlight = false]);
  final IconData icon;
  final String label;
  final double value;
  final SixWebMetricFormatter formatter;
  final bool highlight;
}
