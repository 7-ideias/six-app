class TelaInicialModel {
  final int totalVendasAbertas;
  final int totalOrdensDeServicoAbertas;

  TelaInicialModel({
    required this.totalVendasAbertas,
    required this.totalOrdensDeServicoAbertas,
  });

  factory TelaInicialModel.fromJson(Map<String, dynamic> json) {
    return TelaInicialModel(
      totalVendasAbertas: json['totalVendasAbertas'] ?? 0,
      totalOrdensDeServicoAbertas: json['totalOrdensDeServicoAbertas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVendasAbertas': totalVendasAbertas,
      'totalOrdensDeServicoAbertas': totalOrdensDeServicoAbertas,
    };
  }
}

