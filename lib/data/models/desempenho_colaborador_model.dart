class MetaColaboradorModel {
  const MetaColaboradorModel({
    required this.id,
    required this.idColaborador,
    required this.nomeColaborador,
    required this.tipoMeta,
    required this.indicador,
    required this.valorAlvo,
    required this.peso,
    required this.dataInicio,
    required this.dataFim,
    required this.status,
  });

  final String id;
  final String idColaborador;
  final String nomeColaborador;
  final String tipoMeta;
  final String indicador;
  final double valorAlvo;
  final double peso;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String status;

  factory MetaColaboradorModel.fromJson(Map<String, dynamic> json) {
    return MetaColaboradorModel(
      id: json['id']?.toString() ?? '',
      idColaborador: json['idColaborador']?.toString() ?? '',
      nomeColaborador: json['nomeColaborador']?.toString() ?? '',
      tipoMeta: json['tipoMeta']?.toString() ?? '',
      indicador: json['indicador']?.toString() ?? '',
      valorAlvo: _toDouble(json['valorAlvo']),
      peso: _toDouble(json['peso'], fallback: 1),
      dataInicio: _parseDate(json['dataInicio']),
      dataFim: _parseDate(json['dataFim']),
      status: json['status']?.toString() ?? 'ATIVA',
    );
  }
}

class DesempenhoColaboradorResumoModel {
  const DesempenhoColaboradorResumoModel({
    required this.periodoInicio,
    required this.periodoFim,
    required this.totalMetas,
    required this.metasBatidas,
    required this.metasEmRisco,
    required this.scoreMedio,
    required this.valorTotalVendido,
    required this.quantidadeVendas,
    required this.quantidadeAtendimentos,
    required this.resultados,
  });

  final DateTime? periodoInicio;
  final DateTime? periodoFim;
  final int totalMetas;
  final int metasBatidas;
  final int metasEmRisco;
  final double scoreMedio;
  final double valorTotalVendido;
  final int quantidadeVendas;
  final int quantidadeAtendimentos;
  final List<DesempenhoColaboradorItemModel> resultados;

  factory DesempenhoColaboradorResumoModel.empty() {
    return const DesempenhoColaboradorResumoModel(
      periodoInicio: null,
      periodoFim: null,
      totalMetas: 0,
      metasBatidas: 0,
      metasEmRisco: 0,
      scoreMedio: 0,
      valorTotalVendido: 0,
      quantidadeVendas: 0,
      quantidadeAtendimentos: 0,
      resultados: <DesempenhoColaboradorItemModel>[],
    );
  }

  factory DesempenhoColaboradorResumoModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawResultados =
        json['resultados'] is List<dynamic>
            ? json['resultados'] as List<dynamic>
            : <dynamic>[];

    return DesempenhoColaboradorResumoModel(
      periodoInicio: _parseDate(json['periodoInicio']),
      periodoFim: _parseDate(json['periodoFim']),
      totalMetas: _toInt(json['totalMetas']),
      metasBatidas: _toInt(json['metasBatidas']),
      metasEmRisco: _toInt(json['metasEmRisco']),
      scoreMedio: _toDouble(json['scoreMedio']),
      valorTotalVendido: _toDouble(json['valorTotalVendido']),
      quantidadeVendas: _toInt(json['quantidadeVendas']),
      quantidadeAtendimentos: _toInt(json['quantidadeAtendimentos']),
      resultados:
          rawResultados
              .whereType<Map<String, dynamic>>()
              .map(DesempenhoColaboradorItemModel.fromJson)
              .toList(growable: false),
    );
  }
}

class DesempenhoColaboradorItemModel {
  const DesempenhoColaboradorItemModel({
    required this.idMeta,
    required this.idColaborador,
    required this.nomeColaborador,
    required this.tipoMeta,
    required this.indicador,
    required this.valorAlvo,
    required this.valorRealizado,
    required this.percentualAtingido,
    required this.peso,
    required this.score,
    required this.status,
    required this.dataInicio,
    required this.dataFim,
  });

  final String idMeta;
  final String idColaborador;
  final String nomeColaborador;
  final String tipoMeta;
  final String indicador;
  final double valorAlvo;
  final double valorRealizado;
  final double percentualAtingido;
  final double peso;
  final double score;
  final String status;
  final DateTime? dataInicio;
  final DateTime? dataFim;

  factory DesempenhoColaboradorItemModel.fromJson(Map<String, dynamic> json) {
    return DesempenhoColaboradorItemModel(
      idMeta: json['idMeta']?.toString() ?? '',
      idColaborador: json['idColaborador']?.toString() ?? '',
      nomeColaborador: json['nomeColaborador']?.toString() ?? '',
      tipoMeta: json['tipoMeta']?.toString() ?? '',
      indicador: json['indicador']?.toString() ?? '',
      valorAlvo: _toDouble(json['valorAlvo']),
      valorRealizado: _toDouble(json['valorRealizado']),
      percentualAtingido: _toDouble(json['percentualAtingido']),
      peso: _toDouble(json['peso'], fallback: 1),
      score: _toDouble(json['score']),
      status: json['status']?.toString() ?? '',
      dataInicio: _parseDate(json['dataInicio']),
      dataFim: _parseDate(json['dataFim']),
    );
  }
}

class DesempenhoIndicadorOption {
  const DesempenhoIndicadorOption({
    required this.codigo,
    required this.label,
    required this.tipoMeta,
    required this.valorMonetario,
  });

  final String codigo;
  final String label;
  final String tipoMeta;
  final bool valorMonetario;
}

const List<DesempenhoIndicadorOption> desempenhoIndicadores =
    <DesempenhoIndicadorOption>[
      DesempenhoIndicadorOption(
        codigo: 'VENDA_VALOR',
        label: 'Valor vendido',
        tipoMeta: 'COMERCIAL',
        valorMonetario: true,
      ),
      DesempenhoIndicadorOption(
        codigo: 'VENDA_QUANTIDADE',
        label: 'Quantidade de vendas',
        tipoMeta: 'COMERCIAL',
        valorMonetario: false,
      ),
      DesempenhoIndicadorOption(
        codigo: 'SERVICO_VALOR',
        label: 'Valor em serviços',
        tipoMeta: 'TECNICO',
        valorMonetario: true,
      ),
      DesempenhoIndicadorOption(
        codigo: 'ATENDIMENTO_QUANTIDADE',
        label: 'Atendimentos técnicos',
        tipoMeta: 'TECNICO',
        valorMonetario: false,
      ),
      DesempenhoIndicadorOption(
        codigo: 'ATENDIMENTO_FINALIZADO',
        label: 'Atendimentos finalizados',
        tipoMeta: 'TECNICO',
        valorMonetario: false,
      ),
      DesempenhoIndicadorOption(
        codigo: 'ATENDIMENTO_VALOR',
        label: 'Valor em atendimentos',
        tipoMeta: 'TECNICO',
        valorMonetario: true,
      ),
    ];

DesempenhoIndicadorOption indicadorPorCodigo(String codigo) {
  return desempenhoIndicadores.firstWhere(
    (DesempenhoIndicadorOption option) => option.codigo == codigo,
    orElse: () => desempenhoIndicadores.first,
  );
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? fallback;
}
