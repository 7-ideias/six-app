import 'caixa_models.dart';

class InformacoesCaixaComSomatorioResponse {
  final double tipo1;
  final double tipo2;
  final double tipo3;
  final double tipo4;
  final double tipo5;
  final double tipo6;
  final double tipo7;
  final double tipo8;
  final double tipo9;
  final double tipo10;

  final List<MovimentoCaixa> movimento;

  InformacoesCaixaComSomatorioResponse({
    required this.tipo1,
    required this.tipo2,
    required this.tipo3,
    required this.tipo4,
    required this.tipo5,
    required this.tipo6,
    required this.tipo7,
    required this.tipo8,
    required this.tipo9,
    required this.tipo10,
    required this.movimento,
  });

  factory InformacoesCaixaComSomatorioResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return InformacoesCaixaComSomatorioResponse(
      tipo1: (json['tipo1'] as num?)?.toDouble() ?? 0,
      tipo2: (json['tipo2'] as num?)?.toDouble() ?? 0,
      tipo3: (json['tipo3'] as num?)?.toDouble() ?? 0,
      tipo4: (json['tipo4'] as num?)?.toDouble() ?? 0,
      tipo5: (json['tipo5'] as num?)?.toDouble() ?? 0,
      tipo6: (json['tipo6'] as num?)?.toDouble() ?? 0,
      tipo7: (json['tipo7'] as num?)?.toDouble() ?? 0,
      tipo8: (json['tipo8'] as num?)?.toDouble() ?? 0,
      tipo9: (json['tipo9'] as num?)?.toDouble() ?? 0,
      tipo10: (json['tipo10'] as num?)?.toDouble() ?? 0,
      movimento: (json['movimento'] as List<dynamic>?)
          ?.map((item) => MovimentoCaixa.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}