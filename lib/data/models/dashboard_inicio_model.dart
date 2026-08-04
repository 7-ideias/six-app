import 'package:flutter/material.dart';

/// Período de filtro global da dashboard inicial.
enum DashboardPeriod { today, last7Days, last30Days, currentMonth }

/// Severidade de um alerta operacional.
enum DashboardAlertSeverity { critical, warning, info }

/// KPI individual com valor atual e valor de comparação (período anterior).
class DashboardKpi {
  const DashboardKpi({
    required this.value,
    this.previousValue,
    required this.icon,
    this.highlight = false,
  });

  final double value;

  /// Valor do período anterior para exibir comparação percentual.
  final double? previousValue;

  final IconData icon;

  /// Quando true, o card recebe destaque visual (fundo primário).
  final bool highlight;

  /// Variação percentual em relação ao período anterior.
  /// Retorna null quando não há dado anterior ou o anterior é zero.
  double? get deltaPercent {
    final prev = previousValue;
    if (prev == null || prev == 0) return null;
    return ((value - prev) / prev) * 100;
  }

  /// true = crescimento, false = queda, null = sem dado anterior.
  bool? get isPositive {
    final delta = deltaPercent;
    if (delta == null) return null;
    return delta >= 0;
  }
}

/// Ponto de dados do gráfico principal de evolução do período.
class DashboardChartPoint {
  const DashboardChartPoint({
    required this.label,
    required this.vendas,
    required this.recebimentos,
  });

  final String label;
  final double vendas;
  final double recebimentos;
}

/// Item de alerta na seção "Atenção necessária".
class DashboardAlertItem {
  const DashboardAlertItem({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.quantidade,
    this.valor,
    required this.severity,
    this.routeHint,
  });

  /// Categoria do alerta: 'cobrancas', 'contas', 'atendimentos', 'estoque'.
  final String tipo;
  final String titulo;
  final String descricao;
  final double quantidade;
  final double? valor;
  final DashboardAlertSeverity severity;

  /// Identificador de rota para navegação futura (opcional).
  /// Não utilizado como rota literal — serve apenas como hint.
  final String? routeHint;
}

/// Compromisso futuro para a seção "Próximos 7 dias".
class DashboardUpcomingItem {
  const DashboardUpcomingItem({
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.dataPrevista,
  });

  /// Tipo: 'receber', 'pagar', 'entrega'.
  final String tipo;
  final String descricao;
  final double valor;
  final DateTime dataPrevista;
}

/// Resumo da operação corrente.
class DashboardOperationSummary {
  const DashboardOperationSummary({
    required this.atendimentosEmAndamento,
    required this.orcamentosAguardando,
    required this.equipamentosParaRetirada,
    required this.caixasAbertos,
  });

  final int atendimentosEmAndamento;
  final int orcamentosAguardando;
  final int equipamentosParaRetirada;
  final int caixasAbertos;
}

/// Colaborador na visão de equipe.
class DashboardTeamMember {
  const DashboardTeamMember({
    required this.nome,
    required this.iniciais,
    required this.atendimentosEmAndamento,
    required this.pendencias,
    required this.vendasPeriodo,
    required this.carga,
  });

  final String nome;
  final String iniciais;
  final int atendimentosEmAndamento;
  final int pendencias;
  final double vendasPeriodo;

  /// Carga operacional: 'baixa', 'normal', 'alta', 'critica'.
  final String carga;
}

/// Modelo raiz da dashboard inicial.
/// Agrupa todos os dados necessários para renderizar a tela de Início.
///
/// Na integração futura, este modelo será preenchido por um repository/client
/// compartilhado entre Web e Mobile — sem necessidade de alterar os widgets.
class DashboardInicioModel {
  const DashboardInicioModel({
    required this.period,
    required this.lastUpdated,
    required this.vendasRealizadas,
    required this.valorRecebido,
    required this.valorAReceber,
    required this.resultado,
    required this.chartData,
    required this.alerts,
    required this.upcoming,
    required this.operations,
    required this.team,
  });

  final DashboardPeriod period;
  final DateTime lastUpdated;

  /// Vendas realizadas no período (valor bruto das operações fechadas).
  final DashboardKpi vendasRealizadas;

  /// Valor efetivamente recebido (liquidado) no período.
  final DashboardKpi valorRecebido;

  /// Valor de vendas ainda não recebido (em aberto).
  final DashboardKpi valorAReceber;

  /// Resultado do período (receitas − despesas operacionais simuladas).
  final DashboardKpi resultado;

  /// Série temporal para o gráfico principal de evolução.
  final List<DashboardChartPoint> chartData;

  /// Alertas que exigem atenção imediata ou próxima.
  final List<DashboardAlertItem> alerts;

  /// Compromissos futuros conhecidos (cobranças, pagamentos, entregas).
  final List<DashboardUpcomingItem> upcoming;

  /// Resumo operacional da situação atual.
  final DashboardOperationSummary operations;

  /// Colaboradores com seus indicadores para a visão de Equipe.
  final List<DashboardTeamMember> team;
}
