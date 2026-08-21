class ConsultaVendasFiltro {
  const ConsultaVendasFiltro({
    required this.dataInicial,
    required this.dataFinal,
    this.busca,
    this.idCliente,
    this.idColaborador,
    this.idProduto,
    this.statusFinanceiro,
    this.statusDevolucao,
    this.valorMinimo,
    this.valorMaximo,
    this.ordenacao = 'MAIS_RECENTES',
    this.pagina = 0,
    this.tamanho = 25,
  });

  final DateTime dataInicial;
  final DateTime dataFinal;
  final String? busca;
  final String? idCliente;
  final String? idColaborador;
  final String? idProduto;
  final String? statusFinanceiro;
  final String? statusDevolucao;
  final double? valorMinimo;
  final double? valorMaximo;
  final String ordenacao;
  final int pagina;
  final int tamanho;

  Map<String, String> toQueryParameters() {
    final Map<String, String> query = <String, String>{
      'dataInicial': _dateOnly(dataInicial),
      'dataFinal': _dateOnly(dataFinal),
      'ordenacao': ordenacao,
      'pagina': pagina.toString(),
      'tamanho': tamanho.toString(),
    };

    void addText(String key, String? value) {
      final String normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) query[key] = normalized;
    }

    addText('busca', busca);
    addText('idCliente', idCliente);
    addText('idColaborador', idColaborador);
    addText('idProduto', idProduto);
    addText('statusFinanceiro', statusFinanceiro);
    addText('statusDevolucao', statusDevolucao);
    if (valorMinimo != null) query['valorMinimo'] = valorMinimo!.toString();
    if (valorMaximo != null) query['valorMaximo'] = valorMaximo!.toString();
    return query;
  }

  ConsultaVendasFiltro copyWith({
    DateTime? dataInicial,
    DateTime? dataFinal,
    String? busca,
    String? idCliente,
    String? idColaborador,
    String? idProduto,
    String? statusFinanceiro,
    String? statusDevolucao,
    double? valorMinimo,
    double? valorMaximo,
    String? ordenacao,
    int? pagina,
    int? tamanho,
    bool limparStatusFinanceiro = false,
    bool limparStatusDevolucao = false,
    bool limparValorMinimo = false,
    bool limparValorMaximo = false,
  }) {
    return ConsultaVendasFiltro(
      dataInicial: dataInicial ?? this.dataInicial,
      dataFinal: dataFinal ?? this.dataFinal,
      busca: busca ?? this.busca,
      idCliente: idCliente ?? this.idCliente,
      idColaborador: idColaborador ?? this.idColaborador,
      idProduto: idProduto ?? this.idProduto,
      statusFinanceiro: limparStatusFinanceiro
          ? null
          : statusFinanceiro ?? this.statusFinanceiro,
      statusDevolucao: limparStatusDevolucao
          ? null
          : statusDevolucao ?? this.statusDevolucao,
      valorMinimo: limparValorMinimo ? null : valorMinimo ?? this.valorMinimo,
      valorMaximo: limparValorMaximo ? null : valorMaximo ?? this.valorMaximo,
      ordenacao: ordenacao ?? this.ordenacao,
      pagina: pagina ?? this.pagina,
      tamanho: tamanho ?? this.tamanho,
    );
  }
}

class ConsultaVendasResponse {
  const ConsultaVendasResponse({
    required this.resumo,
    required this.paginaAtual,
    required this.tamanhoPagina,
    required this.totalElementos,
    required this.totalPaginas,
    required this.vendas,
  });

  final ResumoConsultaVendas resumo;
  final int paginaAtual;
  final int tamanhoPagina;
  final int totalElementos;
  final int totalPaginas;
  final List<VendaConsultaResumo> vendas;

  factory ConsultaVendasResponse.fromJson(Map<String, dynamic> json) {
    return ConsultaVendasResponse(
      resumo: ResumoConsultaVendas.fromJson(_asMap(json['resumo'])),
      paginaAtual: _asInt(json['paginaAtual']),
      tamanhoPagina: _asInt(json['tamanhoPagina'], fallback: 25),
      totalElementos: _asInt(json['totalElementos']),
      totalPaginas: _asInt(json['totalPaginas']),
      vendas: _asList(json['vendas'])
          .whereType<Map>()
          .map(
            (Map item) =>
                VendaConsultaResumo.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }
}

class ResumoConsultaVendas {
  const ResumoConsultaVendas({
    required this.quantidadeVendas,
    required this.valorTotalVendido,
    required this.valorTotalRecebido,
    required this.valorTotalEmAberto,
    required this.valorTotalDevolvido,
  });

  final int quantidadeVendas;
  final double valorTotalVendido;
  final double valorTotalRecebido;
  final double valorTotalEmAberto;
  final double valorTotalDevolvido;

  double get ticketMedio =>
      quantidadeVendas == 0 ? 0 : valorTotalVendido / quantidadeVendas;

  factory ResumoConsultaVendas.fromJson(Map<String, dynamic> json) {
    return ResumoConsultaVendas(
      quantidadeVendas: _asInt(json['quantidadeVendas']),
      valorTotalVendido: _asDouble(json['valorTotalVendido']),
      valorTotalRecebido: _asDouble(json['valorTotalRecebido']),
      valorTotalEmAberto: _asDouble(json['valorTotalEmAberto']),
      valorTotalDevolvido: _asDouble(json['valorTotalDevolvido']),
    );
  }
}

class VendaConsultaResumo {
  const VendaConsultaResumo({
    required this.idOperacao,
    required this.codigoOperacao,
    required this.dataOperacao,
    required this.idCliente,
    required this.nomeCliente,
    required this.documentoCliente,
    required this.idColaborador,
    required this.nomeColaborador,
    required this.quantidadeLinhas,
    required this.quantidadeItens,
    required this.valorTotal,
    required this.valorRecebido,
    required this.valorEmAberto,
    required this.valorDevolvido,
    required this.statusFinanceiro,
    required this.statusDevolucao,
    required this.permiteDevolucao,
  });

  final String idOperacao;
  final String codigoOperacao;
  final DateTime? dataOperacao;
  final String idCliente;
  final String nomeCliente;
  final String documentoCliente;
  final String idColaborador;
  final String nomeColaborador;
  final int quantidadeLinhas;
  final double quantidadeItens;
  final double valorTotal;
  final double valorRecebido;
  final double valorEmAberto;
  final double valorDevolvido;
  final String statusFinanceiro;
  final String statusDevolucao;
  final bool permiteDevolucao;

  String get identificadorPreferencial =>
      codigoOperacao.trim().isNotEmpty ? codigoOperacao : idOperacao;

  factory VendaConsultaResumo.fromJson(Map<String, dynamic> json) {
    return VendaConsultaResumo(
      idOperacao: json['idOperacao']?.toString() ?? '',
      codigoOperacao: json['codigoOperacao']?.toString() ?? '',
      dataOperacao: _asDateTime(json['dataOperacao']),
      idCliente: json['idCliente']?.toString() ?? '',
      nomeCliente: json['nomeCliente']?.toString() ?? '',
      documentoCliente: json['documentoCliente']?.toString() ?? '',
      idColaborador: json['idColaborador']?.toString() ?? '',
      nomeColaborador: json['nomeColaborador']?.toString() ?? '',
      quantidadeLinhas: _asInt(json['quantidadeLinhas']),
      quantidadeItens: _asDouble(json['quantidadeItens']),
      valorTotal: _asDouble(json['valorTotal']),
      valorRecebido: _asDouble(json['valorRecebido']),
      valorEmAberto: _asDouble(json['valorEmAberto']),
      valorDevolvido: _asDouble(json['valorDevolvido']),
      statusFinanceiro: json['statusFinanceiro']?.toString() ?? '',
      statusDevolucao: json['statusDevolucao']?.toString() ?? '',
      permiteDevolucao: json['permiteDevolucao'] == true,
    );
  }
}

class VendaDetalheResponse {
  const VendaDetalheResponse({
    required this.resumo,
    required this.descricao,
    required this.itens,
    required this.recebimentos,
    required this.devolucoes,
    required this.historico,
  });

  final VendaConsultaResumo resumo;
  final String descricao;
  final List<ItemVendaDetalhe> itens;
  final List<RecebimentoVendaDetalhe> recebimentos;
  final List<DevolucaoVendaDetalhe> devolucoes;
  final List<EventoVendaDetalhe> historico;

  factory VendaDetalheResponse.fromJson(Map<String, dynamic> json) {
    return VendaDetalheResponse(
      resumo: VendaConsultaResumo.fromJson(_asMap(json['resumo'])),
      descricao: json['descricao']?.toString() ?? '',
      itens: _asList(json['itens'])
          .whereType<Map>()
          .map(
            (Map item) =>
                ItemVendaDetalhe.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      recebimentos: _asList(json['recebimentos'])
          .whereType<Map>()
          .map(
            (Map item) =>
                RecebimentoVendaDetalhe.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      devolucoes: _asList(json['devolucoes'])
          .whereType<Map>()
          .map(
            (Map item) =>
                DevolucaoVendaDetalhe.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      historico: _asList(json['historico'])
          .whereType<Map>()
          .map(
            (Map item) =>
                EventoVendaDetalhe.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }
}

class ItemVendaDetalhe {
  const ItemVendaDetalhe({
    required this.idItemVenda,
    required this.idProduto,
    required this.codigoProduto,
    required this.nomeProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
    required this.quantidadeDevolvida,
    required this.quantidadeDisponivel,
  });

  final String idItemVenda;
  final String idProduto;
  final String codigoProduto;
  final String nomeProduto;
  final double quantidade;
  final double valorUnitario;
  final double valorTotal;
  final double quantidadeDevolvida;
  final double quantidadeDisponivel;

  factory ItemVendaDetalhe.fromJson(Map<String, dynamic> json) {
    return ItemVendaDetalhe(
      idItemVenda: json['idItemVenda']?.toString() ?? '',
      idProduto: json['idProduto']?.toString() ?? '',
      codigoProduto: json['codigoProduto']?.toString() ?? '',
      nomeProduto: json['nomeProduto']?.toString() ?? '',
      quantidade: _asDouble(json['quantidade']),
      valorUnitario: _asDouble(json['valorUnitario']),
      valorTotal: _asDouble(json['valorTotal']),
      quantidadeDevolvida: _asDouble(json['quantidadeDevolvida']),
      quantidadeDisponivel: _asDouble(json['quantidadeDisponivel']),
    );
  }
}

class RecebimentoVendaDetalhe {
  const RecebimentoVendaDetalhe({
    required this.idRecebimento,
    required this.origem,
    required this.dataHora,
    required this.codigoTipoRecebimento,
    required this.descricaoTipoRecebimento,
    required this.valorOriginal,
    required this.valorRecebido,
    required this.valorEmAberto,
    required this.status,
    required this.idColaborador,
    required this.nomeColaborador,
    required this.idSessaoCaixa,
  });

  final String idRecebimento;
  final String origem;
  final DateTime? dataHora;
  final String codigoTipoRecebimento;
  final String descricaoTipoRecebimento;
  final double valorOriginal;
  final double valorRecebido;
  final double valorEmAberto;
  final String status;
  final String idColaborador;
  final String nomeColaborador;
  final String idSessaoCaixa;

  factory RecebimentoVendaDetalhe.fromJson(Map<String, dynamic> json) {
    return RecebimentoVendaDetalhe(
      idRecebimento: json['idRecebimento']?.toString() ?? '',
      origem: json['origem']?.toString() ?? '',
      dataHora: _asDateTime(json['dataHora']),
      codigoTipoRecebimento: json['codigoTipoRecebimento']?.toString() ?? '',
      descricaoTipoRecebimento:
          json['descricaoTipoRecebimento']?.toString() ?? '',
      valorOriginal: _asDouble(json['valorOriginal']),
      valorRecebido: _asDouble(json['valorRecebido']),
      valorEmAberto: _asDouble(json['valorEmAberto']),
      status: json['status']?.toString() ?? '',
      idColaborador: json['idColaborador']?.toString() ?? '',
      nomeColaborador: json['nomeColaborador']?.toString() ?? '',
      idSessaoCaixa: json['idSessaoCaixa']?.toString() ?? '',
    );
  }
}

class DevolucaoVendaDetalhe {
  const DevolucaoVendaDetalhe({
    required this.idDevolucao,
    required this.codigoDevolucao,
    required this.dataHora,
    required this.tipo,
    required this.status,
    required this.idColaborador,
    required this.nomeColaborador,
    required this.valorTotalDevolvido,
    required this.valorTotalTroca,
    required this.saldoFinanceiro,
    required this.itensDevolvidos,
    required this.itensTroca,
  });

  final String idDevolucao;
  final String codigoDevolucao;
  final DateTime? dataHora;
  final String tipo;
  final String status;
  final String idColaborador;
  final String nomeColaborador;
  final double valorTotalDevolvido;
  final double valorTotalTroca;
  final double saldoFinanceiro;
  final List<ItemDevolucaoDetalhe> itensDevolvidos;
  final List<ItemTrocaDetalhe> itensTroca;

  factory DevolucaoVendaDetalhe.fromJson(Map<String, dynamic> json) {
    return DevolucaoVendaDetalhe(
      idDevolucao: json['idDevolucao']?.toString() ?? '',
      codigoDevolucao: json['codigoDevolucao']?.toString() ?? '',
      dataHora: _asDateTime(json['dataHora']),
      tipo: json['tipo']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      idColaborador: json['idColaborador']?.toString() ?? '',
      nomeColaborador: json['nomeColaborador']?.toString() ?? '',
      valorTotalDevolvido: _asDouble(json['valorTotalDevolvido']),
      valorTotalTroca: _asDouble(json['valorTotalTroca']),
      saldoFinanceiro: _asDouble(json['saldoFinanceiro']),
      itensDevolvidos: _asList(json['itensDevolvidos'])
          .whereType<Map>()
          .map(
            (Map item) =>
                ItemDevolucaoDetalhe.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      itensTroca: _asList(json['itensTroca'])
          .whereType<Map>()
          .map(
            (Map item) =>
                ItemTrocaDetalhe.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }
}

class ItemDevolucaoDetalhe {
  const ItemDevolucaoDetalhe({
    required this.idProduto,
    required this.nomeProduto,
    required this.quantidade,
    required this.valorTotal,
    required this.motivo,
    required this.condicao,
    required this.retornouAoEstoque,
  });

  final String idProduto;
  final String nomeProduto;
  final double quantidade;
  final double valorTotal;
  final String motivo;
  final String condicao;
  final bool retornouAoEstoque;

  factory ItemDevolucaoDetalhe.fromJson(Map<String, dynamic> json) {
    return ItemDevolucaoDetalhe(
      idProduto: json['idProduto']?.toString() ?? '',
      nomeProduto: json['nomeProduto']?.toString() ?? '',
      quantidade: _asDouble(json['quantidade']),
      valorTotal: _asDouble(json['valorTotal']),
      motivo: json['motivo']?.toString() ?? '',
      condicao: json['condicao']?.toString() ?? '',
      retornouAoEstoque: json['retornouAoEstoque'] == true,
    );
  }
}

class ItemTrocaDetalhe {
  const ItemTrocaDetalhe({
    required this.idProduto,
    required this.nomeProduto,
    required this.quantidade,
    required this.valorTotal,
  });

  final String idProduto;
  final String nomeProduto;
  final double quantidade;
  final double valorTotal;

  factory ItemTrocaDetalhe.fromJson(Map<String, dynamic> json) {
    return ItemTrocaDetalhe(
      idProduto: json['idProduto']?.toString() ?? '',
      nomeProduto: json['nomeProduto']?.toString() ?? '',
      quantidade: _asDouble(json['quantidade']),
      valorTotal: _asDouble(json['valorTotal']),
    );
  }
}

class EventoVendaDetalhe {
  const EventoVendaDetalhe({
    required this.dataHora,
    required this.tipo,
    required this.referencia,
    required this.valor,
  });

  final DateTime? dataHora;
  final String tipo;
  final String referencia;
  final double valor;

  factory EventoVendaDetalhe.fromJson(Map<String, dynamic> json) {
    return EventoVendaDetalhe(
      dataHora: _asDateTime(json['dataHora']),
      tipo: json['tipo']?.toString() ?? '',
      referencia: json['referencia']?.toString() ?? '',
      valor: _asDouble(json['valor']),
    );
  }
}

String _dateOnly(DateTime value) {
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) =>
    value is List ? value : const <dynamic>[];

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDateTime(dynamic value) {
  final String text = value?.toString() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}
