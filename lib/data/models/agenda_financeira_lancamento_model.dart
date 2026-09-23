import 'agenda_financeira_recorrencia.dart';
import 'recebimento_forma_input.dart';

class LancamentoAgendaFinanceiraRequest {
  LancamentoAgendaFinanceiraRequest({
    required this.uuidOperacaoApp,
    required this.descricao,
    required this.tipoOperacao,
    required this.statusOperacao,
    required this.dataOperacao,
    required this.dataVencimento,
    required this.dataCompetencia,
    this.dataQuitacao,
    required this.statusQuitada,
    required this.operacaoFinalizadaProntaCaixa,
    required this.clientePediuParaApagar,
    required this.origem,
    required this.formaPagamento,
    required this.empresa,
    required this.categoria,
    required this.idColaborador,
    required this.nomeColaborador,
    this.idCliente,
    this.nomeCliente,
    this.idFornecedor,
    this.nomeFornecedor,
    this.referenciaExterna,
    this.documentoFiscal,
    this.centroDeCusto,
    this.centroCustoId,
    required this.valorTotalProdutos,
    required this.valorTotalServicos,
    required this.valorTotalOperacao,
    this.observacoes,
    this.configuracaoRecorrencia,
    this.recorrente = false,
    this.frequenciaRecorrencia = 'NAO_RECORRENTE',
    this.recorrenciaInicio,
    this.recorrenciaFim,
    this.quantidadeParcelas = 1,
    this.diaVencimentoRecorrencia,
    required this.payloadOriginalJson,
  });

  final String uuidOperacaoApp;
  final String descricao;
  final String tipoOperacao;
  final String statusOperacao;
  final DateTime dataOperacao;
  final DateTime dataVencimento;
  final DateTime dataCompetencia;
  final DateTime? dataQuitacao;
  final bool statusQuitada;
  final bool operacaoFinalizadaProntaCaixa;
  final bool clientePediuParaApagar;
  final String origem;
  final String formaPagamento;
  final String empresa;
  final String categoria;
  final String idColaborador;
  final String nomeColaborador;
  final String? idCliente;
  final String? nomeCliente;
  final String? idFornecedor;
  final String? nomeFornecedor;
  final String? referenciaExterna;
  final String? documentoFiscal;
  final String? centroDeCusto;
  final String? centroCustoId;
  final double valorTotalProdutos;
  final double valorTotalServicos;
  final double valorTotalOperacao;
  final String? observacoes;
  final AgendaFinanceiraRecorrencia? configuracaoRecorrencia;
  final bool recorrente;
  final String frequenciaRecorrencia;
  final DateTime? recorrenciaInicio;
  final DateTime? recorrenciaFim;
  final int? quantidadeParcelas;
  final int? diaVencimentoRecorrencia;
  final Map<String, dynamic> payloadOriginalJson;

  Map<String, dynamic> get dadosRecorrencia =>
      configuracaoRecorrencia?.toJson(dataVencimento) ??
      {
        'recorrente': recorrente,
        'frequenciaRecorrencia': frequenciaRecorrencia,
        'recorrenciaInicio': (recorrenciaInicio ?? dataVencimento)
            .toIso8601String(),
        'recorrenciaFim': recorrenciaFim?.toIso8601String(),
        'quantidadeParcelas': quantidadeParcelas,
        'diaVencimentoRecorrencia':
            diaVencimentoRecorrencia ?? dataVencimento.day,
      };

  /// Indicadores de vencimento não são estados financeiros persistidos.
  static String normalizarStatus(String status) {
    final codigo = status.trim().toUpperCase().replaceAll(' ', '_');
    return switch (codigo) {
      'VENCE_HOJE' || 'VENCIDO' || 'VENCIDA' => 'PENDENTE',
      'CANCELADA' => 'CANCELADO',
      _ => codigo,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'uuidOperacaoApp': uuidOperacaoApp,
      'descricao': descricao,
      'tipoOperacao': tipoOperacao,
      'statusOperacao': normalizarStatus(statusOperacao),
      'statusQuitada': statusQuitada,
      'operacaoFinalizadaProntaCaixa': operacaoFinalizadaProntaCaixa,
      'clientePediuParaApagar': clientePediuParaApagar,
      'dataOperacao': dataOperacao.toIso8601String(),
      'dataVencimento': dataVencimento.toIso8601String(),
      'dataCompetencia': dataCompetencia.toIso8601String(),
      'dataQuitacao': dataQuitacao?.toIso8601String(),
      'origem': origem,
      'formaPagamento': formaPagamento,
      'empresa': empresa,
      'categoria': categoria,
      'idCliente': idCliente,
      'nomeCliente': nomeCliente,
      'idFornecedor': idFornecedor,
      'nomeFornecedor': nomeFornecedor,
      'referenciaExterna': referenciaExterna,
      'documentoFiscal': documentoFiscal,
      'centroDeCusto': centroDeCusto,
      'centroCustoId': centroCustoId,
      'valorTotalProdutos': valorTotalProdutos,
      'valorTotalServicos': valorTotalServicos,
      'valorTotalOperacao': valorTotalOperacao,
      'idColaborador': idColaborador,
      'nomeColaborador': nomeColaborador,
      'observacoes': observacoes,
      ...dadosRecorrencia,
      'payloadOriginalJson': {
        ...payloadOriginalJson,
        'agendaFinanceira': {
          ...Map<String, dynamic>.from(
            payloadOriginalJson['agendaFinanceira'] as Map? ?? const {},
          ),
          'statusFiltro': normalizarStatus(statusOperacao),
        },
        'recorrencia': {
          'recorrente': dadosRecorrencia['recorrente'],
          'frequencia': dadosRecorrencia['frequenciaRecorrencia'],
          'inicio': dadosRecorrencia['recorrenciaInicio'],
          'fim': dadosRecorrencia['recorrenciaFim'],
          'quantidadeParcelas': dadosRecorrencia['quantidadeParcelas'],
        },
      },
    };
  }

  Map<String, dynamic> toAgendaItem({String? idFallback}) {
    final tipoRecebimento = tipoOperacao.toLowerCase() == 'receber';

    return {
      'id': idFallback ?? uuidOperacaoApp,
      'tipo': tipoRecebimento ? 'receber' : 'pagar',
      'descricao': descricao,
      'contato': nomeCliente ?? nomeFornecedor ?? 'Não informado',
      'valor': valorTotalOperacao,
      'vencimento': _formatarDataBr(dataVencimento),
      'status': statusOperacao,
      'origem': origem,
      'formaPagamento': formaPagamento,
      'empresa': empresa,
      'categoria': categoria,
      'responsavel': nomeColaborador,
      'observacoes': observacoes ?? '',
      'uuidOperacaoApp': uuidOperacaoApp,
      'idContato': idCliente ?? idFornecedor,
      'referenciaExterna': referenciaExterna,
      'documentoFiscal': documentoFiscal,
      'centroDeCusto': centroDeCusto,
      'centroCustoId': centroCustoId,
      'dataOperacao': dataOperacao.toIso8601String(),
      'dataCompetencia': dataCompetencia.toIso8601String(),
      ...dadosRecorrencia,
      'serieRecorrenciaId': configuracaoRecorrencia?.serieId,
      'historico': [
        'Lançamento criado em ${_formatarDataHoraBr(DateTime.now())}',
      ],
      'acoes': tipoRecebimento
          ? ['Receber', 'Enviar cobrança', 'Detalhes']
          : ['Pagar', 'Reagendar', 'Detalhes'],
    };
  }

  static String _formatarDataBr(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  static String _formatarDataHoraBr(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} $hora:$minuto';
  }
}

class LancamentoAgendaFinanceiraResponse {
  LancamentoAgendaFinanceiraResponse({
    required this.id,
    required this.status,
    this.mensagem,
  });

  final String id;
  final String status;
  final String? mensagem;

  factory LancamentoAgendaFinanceiraResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return LancamentoAgendaFinanceiraResponse(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'CRIADO',
      mensagem: json['mensagem']?.toString(),
    );
  }
}

class AgendaFinanceiraLancamentoDetalhe {
  AgendaFinanceiraLancamentoDetalhe._({
    required this.idLancamento,
    required this.codigoOperacao,
    required this.dados,
  });

  final String idLancamento;
  final String? codigoOperacao;
  final Map<String, dynamic> dados;

  factory AgendaFinanceiraLancamentoDetalhe.fromJson(
    Map<String, dynamic> json,
  ) {
    final String idLancamento = json['idLancamento']?.toString().trim() ?? '';
    final String codigo = json['codigoOperacao']?.toString().trim() ?? '';
    return AgendaFinanceiraLancamentoDetalhe._(
      idLancamento: idLancamento,
      codigoOperacao: codigo.isEmpty ? null : codigo,
      dados: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...dados,
    'idLancamento': idLancamento,
    'codigoOperacao': codigoOperacao,
  };
}

class AgendaFinanceiraLiquidacaoRequest {
  AgendaFinanceiraLiquidacaoRequest({
    required this.tipoLiquidacao,
    required this.dataLiquidacao,
    required this.valorLiquidado,
    required this.formaPagamentoRealizada,
    this.observacoes,
    this.referenciaExterna,
    this.anexarComprovante = false,
    this.idSessaoCaixa,
    this.recebimentos,
  });

  final String tipoLiquidacao;
  final DateTime dataLiquidacao;
  final double valorLiquidado;
  final String formaPagamentoRealizada;
  final String? observacoes;
  final String? referenciaExterna;
  final bool anexarComprovante;
  final String? idSessaoCaixa;
  final List<RecebimentoFormaInput>? recebimentos;

  Map<String, dynamic> toJson() {
    return {
      'tipoLiquidacao': tipoLiquidacao,
      'dataLiquidacao': _toIsoDate(dataLiquidacao),
      'valorLiquidado': valorLiquidado,
      'formaPagamentoRealizada': formaPagamentoRealizada,
      'observacoes': observacoes,
      'referenciaExterna': referenciaExterna,
      'anexarComprovante': anexarComprovante,
      'idSessaoCaixa': idSessaoCaixa,
      if (recebimentos != null && recebimentos!.isNotEmpty)
        'recebimentos': recebimentos!
            .map((item) => item.toJson())
            .toList(growable: false),
    };
  }
}

class AgendaFinanceiraParcialRequest {
  AgendaFinanceiraParcialRequest({
    required this.tipoLiquidacao,
    required this.dataLiquidacao,
    required this.valorLiquidado,
    required this.formaPagamentoRealizada,
    this.observacoes,
    this.idSessaoCaixa,
    this.recebimentos,
  });

  final String tipoLiquidacao;
  final DateTime dataLiquidacao;
  final double valorLiquidado;
  final String formaPagamentoRealizada;
  final String? observacoes;
  final String? idSessaoCaixa;
  final List<RecebimentoFormaInput>? recebimentos;

  Map<String, dynamic> toJson() {
    return {
      'tipoLiquidacao': tipoLiquidacao,
      'dataLiquidacao': _toIsoDate(dataLiquidacao),
      'valorLiquidado': valorLiquidado,
      'formaPagamentoRealizada': formaPagamentoRealizada,
      'observacoes': observacoes,
      'idSessaoCaixa': idSessaoCaixa,
      if (recebimentos != null && recebimentos!.isNotEmpty)
        'recebimentos': recebimentos!
            .map((item) => item.toJson())
            .toList(growable: false),
    };
  }
}

class AgendaFinanceiraConsultaRequest {
  AgendaFinanceiraConsultaRequest({
    required this.periodo,
    required this.filtros,
    required this.visaoSelecionada,
  });

  final AgendaFinanceiraPeriodoRequest periodo;
  final AgendaFinanceiraFiltrosRequest filtros;
  final String visaoSelecionada;

  Map<String, dynamic> toJson() {
    return {
      'periodo': periodo.toJson(),
      'filtros': filtros.toJson(),
      'visaoSelecionada': visaoSelecionada,
    };
  }
}

class AgendaFinanceiraPeriodoRequest {
  AgendaFinanceiraPeriodoRequest({
    required this.modo,
    required this.dataInicio,
    required this.dataFim,
  });

  final String modo;
  final DateTime dataInicio;
  final DateTime dataFim;

  Map<String, dynamic> toJson() {
    return {
      'modo': modo,
      'dataInicio': _toIsoDate(dataInicio),
      'dataFim': _toIsoDate(dataFim),
    };
  }
}

class AgendaFinanceiraFiltrosRequest {
  AgendaFinanceiraFiltrosRequest({
    required this.tipo,
    required this.status,
    required this.origens,
    required this.categorias,
    required this.formasPagamento,
    required this.codigosTipoRecebimento,
    required this.centrosCusto,
    this.clienteFornecedor,
    required this.somenteCriticos,
  });

  final String tipo;
  final List<String> status;
  final List<String> origens;
  final List<String> categorias;
  final List<String> formasPagamento;
  final List<String> codigosTipoRecebimento;
  final List<String> centrosCusto;
  final String? clienteFornecedor;
  final bool somenteCriticos;

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'status': status,
      'origens': origens,
      'categorias': categorias,
      'formasPagamento': formasPagamento,
      'codigosTipoRecebimento': codigosTipoRecebimento,
      'centrosCusto': centrosCusto,
      'clienteFornecedor': clienteFornecedor,
      'somenteCriticos': somenteCriticos,
    };
  }
}

class CentroCustoModel {
  const CentroCustoModel({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.tipo,
    required this.ativo,
    this.centroPaiId,
  });

  final String id;
  final String codigo;
  final String nome;
  final String tipo;
  final bool ativo;
  final String? centroPaiId;

  String get descricao {
    final String nomeLimpo = nome.trim();
    final String codigoLimpo = codigo.trim();
    if (codigoLimpo.isEmpty ||
        codigoLimpo.toUpperCase() == nomeLimpo.toUpperCase()) {
      return nomeLimpo;
    }
    return '$nomeLimpo • $codigoLimpo';
  }

  factory CentroCustoModel.fromJson(Map<String, dynamic> json) {
    return CentroCustoModel(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'AMBOS',
      ativo: json['ativo'] != false,
      centroPaiId: json['centroPaiId']?.toString(),
    );
  }
}

String _toIsoDate(DateTime data) {
  final ano = data.year.toString().padLeft(4, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final dia = data.day.toString().padLeft(2, '0');
  return '$ano-$mes-$dia';
}
