class LancamentoAgendaFinanceiraRequest {
  LancamentoAgendaFinanceiraRequest({
    this.uuidOperacaoApp,
    required this.descricao,
    required this.tipoOperacao,
    required this.statusOperacao,
    required this.dataOperacao,
    required this.dataVencimento,
    this.dataCompetencia,
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
    required this.valorTotalProdutos,
    required this.valorTotalServicos,
    required this.valorTotalOperacao,
    this.observacoes,
    required this.recorrente,
    this.frequenciaRecorrencia,
    this.recorrenciaInicio,
    this.recorrenciaFim,
    this.quantidadeParcelas,
    this.diaVencimentoRecorrencia,
    this.payloadOriginalJson,
  });

  final String? uuidOperacaoApp;
  final String descricao;
  final String tipoOperacao;
  final String statusOperacao;
  final DateTime dataOperacao;
  final DateTime dataVencimento;
  final DateTime? dataCompetencia;
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
  final double valorTotalProdutos;
  final double valorTotalServicos;
  final double valorTotalOperacao;
  final String? observacoes;
  final bool recorrente;
  final String? frequenciaRecorrencia;
  final DateTime? recorrenciaInicio;
  final DateTime? recorrenciaFim;
  final int? quantidadeParcelas;
  final int? diaVencimentoRecorrencia;
  final Map<String, dynamic>? payloadOriginalJson;

  Map<String, dynamic> toJson() {
    return {
      'uuidOperacaoApp': uuidOperacaoApp,
      'descricao': descricao,
      'tipoOperacao': tipoOperacao,
      'statusOperacao': statusOperacao,
      'statusQuitada': statusQuitada,
      'operacaoFinalizadaProntaCaixa': operacaoFinalizadaProntaCaixa,
      'clientePediuParaApagar': clientePediuParaApagar,
      'dataOperacao': dataOperacao.toIso8601String(),
      'dataVencimento': dataVencimento.toIso8601String(),
      'dataCompetencia': dataCompetencia?.toIso8601String(),
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
      'valorTotalProdutos': valorTotalProdutos,
      'valorTotalServicos': valorTotalServicos,
      'valorTotalOperacao': valorTotalOperacao,
      'idColaborador': idColaborador,
      'nomeColaborador': nomeColaborador,
      'observacoes': observacoes,
      'recorrente': recorrente,
      'frequenciaRecorrencia': frequenciaRecorrencia,
      'recorrenciaInicio': recorrenciaInicio?.toIso8601String(),
      'recorrenciaFim': recorrenciaFim?.toIso8601String(),
      'quantidadeParcelas': quantidadeParcelas,
      'diaVencimentoRecorrencia': diaVencimentoRecorrencia,
      'payloadOriginalJson': payloadOriginalJson,
    };
  }

  Map<String, dynamic> toAgendaItem({String? idFallback}) {
    final tipoRecebimento = tipoOperacao.toLowerCase() == 'receber';

    return {
      'id':
          idFallback ??
          uuidOperacaoApp ??
          DateTime.now().millisecondsSinceEpoch.toString(),
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
      'historico': [
        'Lançamento criado em ${_formatarDataHoraBr(DateTime.now())}',
        if (recorrente)
          'Recorrência ${frequenciaRecorrencia ?? 'configurada'} iniciada em ${_formatarDataBr(recorrenciaInicio ?? dataOperacao)}',
      ],
      'acoes':
          tipoRecebimento
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
