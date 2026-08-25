import 'package:flutter/material.dart';
import 'package:sixpos/data/models/dashboard_inicio_model.dart';

/// Fonte de dados mockada para a dashboard inicial.
///
/// Organização intencional: os dados ficam aqui, separados dos widgets.
/// Na integração real, substitua as chamadas a [DashboardInicioMock.forPeriod]
/// por um repositório/client que consuma o backend — sem reescrever modelos
/// nem widgets.
///
/// Cada período possui valores internamente coerentes:
/// - Vendas realizadas ≥ Valor recebido + Valor a receber
/// - Resultado = receitas − despesas operacionais simuladas
/// - Variações percentuais calculadas a partir de valores do período anterior
class DashboardInicioMock {
  DashboardInicioMock._();

  /// Retorna o cenário mockado correspondente ao período selecionado.
  static DashboardInicioModel forPeriod(
    DashboardPeriod period, {
    String? collaboratorKey,
  }) {
    final DashboardInicioModel base;
    switch (period) {
      case DashboardPeriod.today:
        base = _today();
        break;
      case DashboardPeriod.last7Days:
        base = _last7Days();
        break;
      case DashboardPeriod.last30Days:
        base = _last30Days();
        break;
      case DashboardPeriod.currentMonth:
        base = _currentMonth();
        break;
    }

    final String normalizedCollaboratorKey = collaboratorKey?.trim() ?? '';
    if (normalizedCollaboratorKey.isEmpty) {
      return base;
    }

    return _withCollaboratorFilter(base, normalizedCollaboratorKey);
  }

  // ─── HOJE ──────────────────────────────────────────────────────────────────

  static DashboardInicioModel _today() {
    final now = DateTime.now();
    return DashboardInicioModel(
      period: DashboardPeriod.today,
      lastUpdated: now,
      vendasRealizadas: const DashboardKpi(
        value: 3250,
        previousValue: 2800,
        icon: Icons.shopping_cart_checkout_rounded,
      ),
      valorRecebido: const DashboardKpi(
        value: 2680,
        previousValue: 2200,
        icon: Icons.account_balance_wallet_outlined,
        highlight: true,
      ),
      valorAReceber: const DashboardKpi(
        value: 570,
        previousValue: 600,
        icon: Icons.pending_actions_rounded,
      ),
      resultado: const DashboardKpi(
        value: 1140,
        previousValue: 920,
        icon: Icons.trending_up_rounded,
      ),
      chartData: const <DashboardChartPoint>[
        DashboardChartPoint(label: '08h', vendas: 0, recebimentos: 0),
        DashboardChartPoint(label: '10h', vendas: 480, recebimentos: 380),
        DashboardChartPoint(label: '12h', vendas: 1100, recebimentos: 820),
        DashboardChartPoint(label: '14h', vendas: 1850, recebimentos: 1400),
        DashboardChartPoint(label: '16h', vendas: 2600, recebimentos: 2050),
        DashboardChartPoint(label: '18h', vendas: 3250, recebimentos: 2680),
      ],
      alerts: <DashboardAlertItem>[
        const DashboardAlertItem(
          tipo: 'cobrancas',
          titulo: 'Recebimentos vencidos',
          descricao: '2 clientes com pagamentos em atraso hoje',
          quantidade: 2,
          valor: 870,
          severity: DashboardAlertSeverity.critical,
          routeHint: 'atendimentos_tecnicos',
        ),
        const DashboardAlertItem(
          tipo: 'atendimentos',
          titulo: 'Atendimentos em atraso',
          descricao: '3 ordens de serviço com prazo expirado',
          quantidade: 3,
          severity: DashboardAlertSeverity.warning,
          routeHint: 'atendimentos_tecnicos',
        ),
      ],
      upcoming: <DashboardUpcomingItem>[
        DashboardUpcomingItem(
          tipo: 'receber',
          descricao: 'Pagamento · Carlos Mendes',
          valor: 350,
          dataPrevista: now.add(const Duration(days: 1)),
        ),
        DashboardUpcomingItem(
          tipo: 'pagar',
          descricao: 'Fornecedor · Distribuidora ABC',
          valor: 1200,
          dataPrevista: now.add(const Duration(days: 2)),
        ),
        DashboardUpcomingItem(
          tipo: 'entrega',
          descricao: 'Notebook Dell · Retirada confirmada',
          valor: 0,
          dataPrevista: now.add(const Duration(days: 1)),
        ),
      ],
      operations: const DashboardOperationSummary(
        atendimentosEmAndamento: 5,
        orcamentosAguardando: 3,
        equipamentosParaRetirada: 2,
        caixasAbertos: 1,
      ),
      team: _teamData(multiplier: 0.12),
    );
  }

  // ─── ÚLTIMOS 7 DIAS ────────────────────────────────────────────────────────

  static DashboardInicioModel _last7Days() {
    final now = DateTime.now();
    return DashboardInicioModel(
      period: DashboardPeriod.last7Days,
      lastUpdated: now,
      vendasRealizadas: const DashboardKpi(
        value: 14800,
        previousValue: 12200,
        icon: Icons.shopping_cart_checkout_rounded,
      ),
      valorRecebido: const DashboardKpi(
        value: 11500,
        previousValue: 9800,
        icon: Icons.account_balance_wallet_outlined,
        highlight: true,
      ),
      valorAReceber: const DashboardKpi(
        value: 3300,
        previousValue: 2400,
        icon: Icons.pending_actions_rounded,
      ),
      resultado: const DashboardKpi(
        value: 3920,
        previousValue: 3100,
        icon: Icons.trending_up_rounded,
      ),
      chartData: const <DashboardChartPoint>[
        DashboardChartPoint(label: 'Seg', vendas: 1800, recebimentos: 1350),
        DashboardChartPoint(label: 'Ter', vendas: 2400, recebimentos: 1900),
        DashboardChartPoint(label: 'Qua', vendas: 1950, recebimentos: 1580),
        DashboardChartPoint(label: 'Qui', vendas: 2800, recebimentos: 2100),
        DashboardChartPoint(label: 'Sex', vendas: 3200, recebimentos: 2450),
        DashboardChartPoint(label: 'Sáb', vendas: 1650, recebimentos: 1320),
        DashboardChartPoint(label: 'Dom', vendas: 1000, recebimentos: 800),
      ],
      alerts: const <DashboardAlertItem>[
        DashboardAlertItem(
          tipo: 'cobrancas',
          titulo: 'Recebimentos vencidos',
          descricao: '5 clientes com pagamentos em atraso',
          quantidade: 5,
          valor: 2340,
          severity: DashboardAlertSeverity.critical,
        ),
        DashboardAlertItem(
          tipo: 'contas',
          titulo: 'Contas a pagar próximas',
          descricao: '2 vencimentos nos próximos 3 dias',
          quantidade: 2,
          valor: 1800,
          severity: DashboardAlertSeverity.warning,
        ),
        DashboardAlertItem(
          tipo: 'atendimentos',
          titulo: 'Atendimentos em atraso',
          descricao: '4 ordens de serviço com prazo expirado',
          quantidade: 4,
          severity: DashboardAlertSeverity.warning,
          routeHint: 'atendimentos_tecnicos',
        ),
        DashboardAlertItem(
          tipo: 'estoque',
          titulo: 'Estoque crítico',
          descricao: '3 produtos abaixo do estoque mínimo',
          quantidade: 3,
          severity: DashboardAlertSeverity.info,
        ),
      ],
      upcoming: <DashboardUpcomingItem>[
        DashboardUpcomingItem(
          tipo: 'receber',
          descricao: '4 cobranças previstas',
          valor: 4850,
          dataPrevista: now.add(const Duration(days: 2)),
        ),
        DashboardUpcomingItem(
          tipo: 'pagar',
          descricao: 'Fornecedor · Distribuidora ABC',
          valor: 1200,
          dataPrevista: now.add(const Duration(days: 3)),
        ),
        DashboardUpcomingItem(
          tipo: 'entrega',
          descricao: '6 equipamentos com entrega prevista',
          valor: 0,
          dataPrevista: now.add(const Duration(days: 4)),
        ),
      ],
      operations: const DashboardOperationSummary(
        atendimentosEmAndamento: 12,
        orcamentosAguardando: 7,
        equipamentosParaRetirada: 5,
        caixasAbertos: 2,
      ),
      team: _teamData(multiplier: 0.35),
    );
  }

  // ─── ÚLTIMOS 30 DIAS ───────────────────────────────────────────────────────

  static DashboardInicioModel _last30Days() {
    final now = DateTime.now();
    return DashboardInicioModel(
      period: DashboardPeriod.last30Days,
      lastUpdated: now,
      vendasRealizadas: const DashboardKpi(
        value: 48750,
        previousValue: 43200,
        icon: Icons.shopping_cart_checkout_rounded,
      ),
      valorRecebido: const DashboardKpi(
        value: 39200,
        previousValue: 35800,
        icon: Icons.account_balance_wallet_outlined,
        highlight: true,
      ),
      valorAReceber: const DashboardKpi(
        value: 9550,
        previousValue: 7400,
        icon: Icons.pending_actions_rounded,
      ),
      resultado: const DashboardKpi(
        value: 12400,
        previousValue: 10800,
        icon: Icons.trending_up_rounded,
      ),
      chartData: const <DashboardChartPoint>[
        DashboardChartPoint(label: 'Sem 1', vendas: 9800, recebimentos: 7200),
        DashboardChartPoint(label: 'Sem 2', vendas: 13200, recebimentos: 10400),
        DashboardChartPoint(label: 'Sem 3', vendas: 11500, recebimentos: 9800),
        DashboardChartPoint(label: 'Sem 4', vendas: 14250, recebimentos: 11800),
      ],
      alerts: const <DashboardAlertItem>[
        DashboardAlertItem(
          tipo: 'cobrancas',
          titulo: 'Recebimentos vencidos',
          descricao: '8 clientes com pagamentos em atraso',
          quantidade: 8,
          valor: 4320,
          severity: DashboardAlertSeverity.critical,
        ),
        DashboardAlertItem(
          tipo: 'contas',
          titulo: 'Contas a pagar próximas',
          descricao: '3 vencimentos nos próximos 7 dias',
          quantidade: 3,
          valor: 3600,
          severity: DashboardAlertSeverity.warning,
        ),
        DashboardAlertItem(
          tipo: 'atendimentos',
          titulo: 'Atendimentos em atraso',
          descricao: '7 ordens de serviço com prazo expirado',
          quantidade: 7,
          severity: DashboardAlertSeverity.warning,
          routeHint: 'atendimentos_tecnicos',
        ),
        DashboardAlertItem(
          tipo: 'estoque',
          titulo: 'Estoque crítico',
          descricao: '5 produtos abaixo do estoque mínimo',
          quantidade: 5,
          severity: DashboardAlertSeverity.info,
        ),
      ],
      upcoming: <DashboardUpcomingItem>[
        DashboardUpcomingItem(
          tipo: 'receber',
          descricao: '7 cobranças previstas',
          valor: 8950,
          dataPrevista: now.add(const Duration(days: 2)),
        ),
        DashboardUpcomingItem(
          tipo: 'pagar',
          descricao: '2 contas a pagar',
          valor: 3200,
          dataPrevista: now.add(const Duration(days: 3)),
        ),
        DashboardUpcomingItem(
          tipo: 'entrega',
          descricao: '11 equipamentos com entrega prevista',
          valor: 0,
          dataPrevista: now.add(const Duration(days: 5)),
        ),
      ],
      operations: const DashboardOperationSummary(
        atendimentosEmAndamento: 18,
        orcamentosAguardando: 11,
        equipamentosParaRetirada: 8,
        caixasAbertos: 2,
      ),
      team: _teamData(multiplier: 1.0),
    );
  }

  // ─── MÊS ATUAL ────────────────────────────────────────────────────────────

  static DashboardInicioModel _currentMonth() {
    final now = DateTime.now();
    final daysElapsed = now.day.clamp(1, 30);
    final fraction = daysElapsed / 30.0;

    final weeks = ((daysElapsed / 7).ceil()).clamp(1, 4);
    final List<DashboardChartPoint> chart = <DashboardChartPoint>[];
    const weeklyVendas = <double>[12000, 13500, 11800, 14200];
    const weeklyReceb = <double>[9200, 10800, 9500, 11200];
    for (int w = 0; w < weeks; w++) {
      final partial = w == weeks - 1 && daysElapsed % 7 != 0;
      final ratio = partial ? (daysElapsed % 7) / 7.0 : 1.0;
      chart.add(
        DashboardChartPoint(
          label: 'Sem ${w + 1}',
          vendas: weeklyVendas[w] * ratio,
          recebimentos: weeklyReceb[w] * ratio,
        ),
      );
    }

    return DashboardInicioModel(
      period: DashboardPeriod.currentMonth,
      lastUpdated: now,
      vendasRealizadas: DashboardKpi(
        value: double.parse((48750 * fraction).toStringAsFixed(2)),
        previousValue: 43200,
        icon: Icons.shopping_cart_checkout_rounded,
      ),
      valorRecebido: DashboardKpi(
        value: double.parse((39200 * fraction).toStringAsFixed(2)),
        previousValue: 35800,
        icon: Icons.account_balance_wallet_outlined,
        highlight: true,
      ),
      valorAReceber: DashboardKpi(
        value: double.parse((9550 * fraction).toStringAsFixed(2)),
        previousValue: 7400,
        icon: Icons.pending_actions_rounded,
      ),
      resultado: DashboardKpi(
        value: double.parse((12400 * fraction).toStringAsFixed(2)),
        previousValue: 10800,
        icon: Icons.trending_up_rounded,
      ),
      chartData: chart,
      alerts: _last30Days().alerts,
      upcoming: _last30Days().upcoming,
      operations: const DashboardOperationSummary(
        atendimentosEmAndamento: 15,
        orcamentosAguardando: 9,
        equipamentosParaRetirada: 6,
        caixasAbertos: 2,
      ),
      team: _teamData(multiplier: fraction),
    );
  }

  // ─── DADOS COMPARTILHADOS ─────────────────────────────────────────────────

  static List<DashboardTeamMember> _teamData({required double multiplier}) {
    final double m = multiplier.clamp(0.05, 1.0);
    return <DashboardTeamMember>[
      DashboardTeamMember(
        nome: 'Ana Paula Ferreira',
        iniciais: 'AP',
        atendimentosEmAndamento: (6 * m).round().clamp(1, 6),
        pendencias: (2 * m).round(),
        vendasPeriodo: 15800 * m,
        carga:
            m > 0.75
                ? 'alta'
                : m > 0.40
                ? 'normal'
                : 'baixa',
      ),
      DashboardTeamMember(
        nome: 'Carlos Silva',
        iniciais: 'CS',
        atendimentosEmAndamento: (4 * m).round().clamp(1, 4),
        pendencias: (3 * m).round(),
        vendasPeriodo: 12400 * m,
        carga: m > 0.75 ? 'alta' : 'normal',
      ),
      DashboardTeamMember(
        nome: 'Fernanda Costa',
        iniciais: 'FC',
        atendimentosEmAndamento: (8 * m).round().clamp(1, 8),
        pendencias: (5 * m).round(),
        vendasPeriodo: 18200 * m,
        carga: m > 0.55 ? 'critica' : 'alta',
      ),
      DashboardTeamMember(
        nome: 'João Marcos Lima',
        iniciais: 'JM',
        atendimentosEmAndamento: (2 * m).round().clamp(1, 2),
        pendencias: 0,
        vendasPeriodo: 8350 * m,
        carga: 'baixa',
      ),
    ];
  }

  static DashboardInicioModel _withCollaboratorFilter(
    DashboardInicioModel base,
    String collaboratorKey,
  ) {
    final double share = _collaboratorShare(collaboratorKey);

    return DashboardInicioModel(
      period: base.period,
      lastUpdated: base.lastUpdated,
      vendasRealizadas: _scaleKpi(base.vendasRealizadas, share),
      valorRecebido: _scaleKpi(base.valorRecebido, share),
      valorAReceber: _scaleKpi(base.valorAReceber, share),
      resultado: _scaleKpi(base.resultado, share),
      chartData: base.chartData
          .map(
            (DashboardChartPoint point) => DashboardChartPoint(
              label: point.label,
              vendas: _roundMoney(point.vendas * share),
              recebimentos: _roundMoney(point.recebimentos * share),
            ),
          )
          .toList(growable: false),
      alerts: base.alerts
          .map((DashboardAlertItem alert) => _scaleAlert(alert, share))
          .toList(growable: false),
      upcoming: base.upcoming
          .map((DashboardUpcomingItem item) => _scaleUpcoming(item, share))
          .toList(growable: false),
      operations: _scaleOperations(base.operations, share),
      team: base.team
          .map((DashboardTeamMember member) => _scaleTeamMember(member, share))
          .toList(growable: false),
    );
  }

  static double _collaboratorShare(String collaboratorKey) {
    final int hash = collaboratorKey.runes.fold<int>(
      0,
      (int value, int rune) => (value + rune) % 997,
    );
    return 0.18 + ((hash % 33) / 100.0);
  }

  static DashboardKpi _scaleKpi(DashboardKpi kpi, double share) {
    return DashboardKpi(
      value: _roundMoney(kpi.value * share),
      previousValue:
          kpi.previousValue == null
              ? null
              : _roundMoney(kpi.previousValue! * share),
      icon: kpi.icon,
      highlight: kpi.highlight,
    );
  }

  static DashboardAlertItem _scaleAlert(
    DashboardAlertItem alert,
    double share,
  ) {
    final int quantidade = _scaleCount(alert.quantidade, share);
    return DashboardAlertItem(
      tipo: alert.tipo,
      titulo: alert.titulo,
      descricao: _filteredAlertDescription(alert.tipo, quantidade),
      quantidade: quantidade.toDouble(),
      valor: alert.valor == null ? null : _roundMoney(alert.valor! * share),
      severity: alert.severity,
      routeHint: alert.routeHint,
    );
  }

  static DashboardUpcomingItem _scaleUpcoming(
    DashboardUpcomingItem item,
    double share,
  ) {
    return DashboardUpcomingItem(
      tipo: item.tipo,
      descricao: _filteredUpcomingDescription(item.tipo),
      valor: item.valor <= 0 ? 0 : _roundMoney(item.valor * share),
      dataPrevista: item.dataPrevista,
    );
  }

  static DashboardOperationSummary _scaleOperations(
    DashboardOperationSummary operations,
    double share,
  ) {
    return DashboardOperationSummary(
      atendimentosEmAndamento: _scaleCount(
        operations.atendimentosEmAndamento.toDouble(),
        share,
      ),
      orcamentosAguardando: _scaleCount(
        operations.orcamentosAguardando.toDouble(),
        share,
      ),
      equipamentosParaRetirada: _scaleCount(
        operations.equipamentosParaRetirada.toDouble(),
        share,
      ),
      caixasAbertos: _scaleCount(operations.caixasAbertos.toDouble(), share),
    );
  }

  static DashboardTeamMember _scaleTeamMember(
    DashboardTeamMember member,
    double share,
  ) {
    return DashboardTeamMember(
      nome: member.nome,
      iniciais: member.iniciais,
      atendimentosEmAndamento: _scaleCount(
        member.atendimentosEmAndamento.toDouble(),
        share,
      ),
      pendencias: _scaleCount(member.pendencias.toDouble(), share),
      vendasPeriodo: _roundMoney(member.vendasPeriodo * share),
      carga: member.carga,
    );
  }

  static String _filteredAlertDescription(String tipo, int quantidade) {
    switch (tipo) {
      case 'cobrancas':
        return '$quantidade recebimentos em atraso na carteira deste colaborador';
      case 'contas':
        return '$quantidade vencimentos ligados ao fluxo deste colaborador';
      case 'atendimentos':
        return '$quantidade ordens em acompanhamento deste colaborador';
      case 'estoque':
        return '$quantidade itens pedem retorno na operação deste colaborador';
      default:
        return '$quantidade itens exigem atenção neste filtro';
    }
  }

  static String _filteredUpcomingDescription(String tipo) {
    switch (tipo) {
      case 'receber':
        return 'Recebimentos previstos deste colaborador';
      case 'pagar':
        return 'Compromissos financeiros ligados a este colaborador';
      case 'entrega':
        return 'Entregas previstas na carteira deste colaborador';
      default:
        return 'Compromissos previstos neste filtro';
    }
  }

  static int _scaleCount(double value, double share) {
    if (value <= 0) return 0;
    return (value * share).round().clamp(1, value.round());
  }

  static double _roundMoney(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}
