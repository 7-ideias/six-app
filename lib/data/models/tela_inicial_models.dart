class TelaInicialModel {
  final int totalVendasAbertas;
  final int totalAtendimentoTecnicosNaoEntregues;
  final int totalAtendimentoTecnicoEmAndamento;
  final int totalAtendimentoTecnicoAguardandoAssinatura;
  final int totalOrdensDeServicoAbertas;

  TelaInicialModel({
    required this.totalVendasAbertas,
    required this.totalAtendimentoTecnicosNaoEntregues,
    required this.totalAtendimentoTecnicoEmAndamento,
    required this.totalAtendimentoTecnicoAguardandoAssinatura,
    required this.totalOrdensDeServicoAbertas,
  });

  factory TelaInicialModel.fromJson(Map<String, dynamic> json) {
    return TelaInicialModel(
      totalVendasAbertas: json['totalVendasAbertas'] ?? 0,
      totalAtendimentoTecnicosNaoEntregues:
          json['totalAtendimentoTecnicosNaoEntregues'] ?? 0,
      totalAtendimentoTecnicoEmAndamento:
          json['totalAtendimentoTecnicoEmAndamento'] ?? 0,
      totalAtendimentoTecnicoAguardandoAssinatura:
          json['totalAtendimentoTecnicoAguardandoAssinatura'] ??
          json['totalAntedimentoTecnicoAguardandoAssinatura'] ??
          0,
      totalOrdensDeServicoAbertas: json['totalOrdensDeServicoAbertas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVendasAbertas': totalVendasAbertas,
      'totalAtendimentoTecnicosNaoEntregues':
          totalAtendimentoTecnicosNaoEntregues,
      'totalAtendimentoTecnicoEmAndamento': totalAtendimentoTecnicoEmAndamento,
      'totalAtendimentoTecnicoAguardandoAssinatura':
          totalAtendimentoTecnicoAguardandoAssinatura,
      'totalOrdensDeServicoAbertas': totalOrdensDeServicoAbertas,
    };
  }
}
