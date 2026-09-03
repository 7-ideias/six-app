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
    this.quantidadeAtendimentosFinalizados = 0,
    this.quantidadeAtendimentosEmAndamento = 0,
    this.valorTotalAssistencias = 0,
    this.comparativos = const <DesempenhoColaboradorComparativoModel>[],
    this.caixa = const DesempenhoCaixaModel.indisponivel(),
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
  final int quantidadeAtendimentosFinalizados;
  final int quantidadeAtendimentosEmAndamento;
  final double valorTotalAssistencias;
  final List<DesempenhoColaboradorComparativoModel> comparativos;
  final DesempenhoCaixaModel caixa;

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
      quantidadeAtendimentosFinalizados: 0,
      quantidadeAtendimentosEmAndamento: 0,
      valorTotalAssistencias: 0,
      comparativos: <DesempenhoColaboradorComparativoModel>[],
      caixa: DesempenhoCaixaModel.indisponivel(),
    );
  }

  factory DesempenhoColaboradorResumoModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawResultados =
        json['resultados'] is List<dynamic>
            ? json['resultados'] as List<dynamic>
            : <dynamic>[];
    final List<dynamic> rawComparativos =
        json['comparativos'] is List<dynamic>
            ? json['comparativos'] as List<dynamic>
            : <dynamic>[];
    final List<DesempenhoColaboradorItemModel> resultados = rawResultados
        .whereType<Map<String, dynamic>>()
        .map(DesempenhoColaboradorItemModel.fromJson)
        .toList(growable: false);
    final List<DesempenhoColaboradorComparativoModel> comparativos =
        rawComparativos
            .whereType<Map<String, dynamic>>()
            .map(DesempenhoColaboradorComparativoModel.fromJson)
            .toList(growable: false);

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
      quantidadeAtendimentosFinalizados: _toInt(
        json['quantidadeAtendimentosFinalizados'],
      ),
      quantidadeAtendimentosEmAndamento: _toInt(
        json['quantidadeAtendimentosEmAndamento'],
      ),
      valorTotalAssistencias: _toDouble(json['valorTotalAssistencias']),
      resultados: resultados,
      comparativos:
          comparativos.isNotEmpty
              ? comparativos
              : DesempenhoColaboradorComparativoModel.fromResultados(
                resultados,
              ),
      caixa: DesempenhoCaixaModel.fromJson(json['caixa']),
    );
  }
}

class DesempenhoColaboradorComparativoModel {
  const DesempenhoColaboradorComparativoModel({
    required this.idColaborador,
    required this.nomeColaborador,
    required this.totalMetas,
    required this.metasBatidas,
    required this.metasEmRisco,
    required this.scoreMedio,
    required this.valorTotalVendido,
    required this.quantidadeVendas,
    required this.quantidadeAtendimentos,
    required this.quantidadeAtendimentosFinalizados,
  });

  final String idColaborador;
  final String nomeColaborador;
  final int totalMetas;
  final int metasBatidas;
  final int metasEmRisco;
  final double scoreMedio;
  final double valorTotalVendido;
  final int quantidadeVendas;
  final int quantidadeAtendimentos;
  final int quantidadeAtendimentosFinalizados;

  factory DesempenhoColaboradorComparativoModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DesempenhoColaboradorComparativoModel(
      idColaborador: json['idColaborador']?.toString() ?? '',
      nomeColaborador: json['nomeColaborador']?.toString() ?? '',
      totalMetas: _toInt(json['totalMetas']),
      metasBatidas: _toInt(json['metasBatidas']),
      metasEmRisco: _toInt(json['metasEmRisco']),
      scoreMedio: _toDouble(json['scoreMedio']),
      valorTotalVendido: _toDouble(json['valorTotalVendido']),
      quantidadeVendas: _toInt(json['quantidadeVendas']),
      quantidadeAtendimentos: _toInt(json['quantidadeAtendimentos']),
      quantidadeAtendimentosFinalizados: _toInt(
        json['quantidadeAtendimentosFinalizados'],
      ),
    );
  }

  static List<DesempenhoColaboradorComparativoModel> fromResultados(
    List<DesempenhoColaboradorItemModel> resultados,
  ) {
    final Map<String, List<DesempenhoColaboradorItemModel>> agrupados =
        <String, List<DesempenhoColaboradorItemModel>>{};
    for (final DesempenhoColaboradorItemModel item in resultados) {
      agrupados
          .putIfAbsent(
            item.idColaborador,
            () => <DesempenhoColaboradorItemModel>[],
          )
          .add(item);
    }

    return agrupados.entries
        .map((entry) {
          final List<DesempenhoColaboradorItemModel> metas = entry.value;
          final double somaPesos = metas.fold<double>(
            0,
            (double total, DesempenhoColaboradorItemModel item) =>
                total + (item.peso <= 0 ? 1 : item.peso),
          );
          final double score =
              somaPesos == 0
                  ? 0
                  : metas.fold<double>(
                        0,
                        (double total, DesempenhoColaboradorItemModel item) =>
                            total +
                            item.percentualAtingido *
                                (item.peso <= 0 ? 1 : item.peso),
                      ) /
                      somaPesos;
          return DesempenhoColaboradorComparativoModel(
            idColaborador: entry.key,
            nomeColaborador: metas.first.nomeColaborador,
            totalMetas: metas.length,
            metasBatidas:
                metas.where((item) => item.percentualAtingido >= 100).length,
            metasEmRisco:
                metas.where((item) => item.percentualAtingido < 70).length,
            scoreMedio: score,
            valorTotalVendido: 0,
            quantidadeVendas: 0,
            quantidadeAtendimentos: 0,
            quantidadeAtendimentosFinalizados: 0,
          );
        })
        .toList(growable: false);
  }
}

class DesempenhoCaixaModel {
  const DesempenhoCaixaModel({
    required this.disponivel,
    required this.aberto,
    required this.idSessao,
    required this.abertoEm,
    required this.responsavel,
  });

  const DesempenhoCaixaModel.indisponivel()
    : disponivel = false,
      aberto = null,
      idSessao = '',
      abertoEm = null,
      responsavel = '';

  final bool disponivel;
  final bool? aberto;
  final String idSessao;
  final DateTime? abertoEm;
  final String responsavel;

  factory DesempenhoCaixaModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const DesempenhoCaixaModel.indisponivel();
    }
    return DesempenhoCaixaModel(
      disponivel: json['disponivel'] == true || json['available'] == true,
      aberto:
          json['aberto'] is bool
              ? json['aberto'] as bool
              : json['open'] is bool
              ? json['open'] as bool
              : null,
      idSessao: (json['idSessao'] ?? json['sessionId'])?.toString() ?? '',
      abertoEm: _parseDate(json['abertoEm'] ?? json['openedAt']),
      responsavel:
          (json['responsavel'] ?? json['responsibleName'])?.toString() ?? '',
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
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
      fallback;
}
