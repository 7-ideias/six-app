
class OperacaoInserirRequest {
  OperacaoInserirRequest({
    required this.descricao,
    required this.dataOperacao,
    required this.tipoDeOperacaoEnum,
    required this.statusQuitada,
    required this.operacaoFinalizadaEProntaParaOCaixa,
    required this.clientePediuParaApagar,
    required this.vendaList,
    required this.servicoList,
    required this.objRecebimentosList,
    required this.objLogsList,
  });

  final String descricao;
  final String dataOperacao;
  final String tipoDeOperacaoEnum;
  final bool statusQuitada;
  final bool operacaoFinalizadaEProntaParaOCaixa;
  final bool clientePediuParaApagar;
  final List<VendaItemRequest> vendaList;
  final List<ServicoItemRequest> servicoList;
  final List<RecebimentoRequest> objRecebimentosList;
  final List<OperacaoLogRequest> objLogsList;

  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'dataOperacao': dataOperacao,
      'tipoDeOperacaoEnum': tipoDeOperacaoEnum,
      'statusQuitada': statusQuitada,
      'operacaoFinalizadaEProntaParaOCaixa': operacaoFinalizadaEProntaParaOCaixa,
      'clientePediuParaApagar': clientePediuParaApagar,
      'vendaList': vendaList.map((item) => item.toJson()).toList(),
      'servicoList': servicoList.map((item) => item.toJson()).toList(),
      'objRecebimentosList':
          objRecebimentosList.map((item) => item.toJson()).toList(),
      'objLogsList': objLogsList.map((item) => item.toJson()).toList(),
    };
  }
}

class VendaItemRequest {
  VendaItemRequest({
    required this.idSKU,
    required this.qt,
    required this.vlUnitario,
    required this.idColaboradorResponsavelPeloServico,
    required this.nomeColaboradorResponsavel,
  });

  final String idSKU;
  final int qt;
  final double vlUnitario;
  final String idColaboradorResponsavelPeloServico;
  final String nomeColaboradorResponsavel;

  Map<String, dynamic> toJson() {
    return {
      'idSKU': idSKU,
      'qt': qt,
      'vlUnitario': vlUnitario,
      'idColaboradorResponsavelPeloServico':
          idColaboradorResponsavelPeloServico,
      'nomeColaboradorResponsavel': nomeColaboradorResponsavel,
    };
  }
}

class ServicoItemRequest {
  ServicoItemRequest({
    required this.idCodigoUnicoDoProduto,
    required this.qt,
    required this.vlUnitario,
    required this.idColaboradorResponsavelPeloServico,
    required this.nomeColaboradorResponsavel,
  });

  final String idCodigoUnicoDoProduto;
  final int qt;
  final double vlUnitario;
  final String idColaboradorResponsavelPeloServico;
  final String nomeColaboradorResponsavel;

  Map<String, dynamic> toJson() {
    return {
      'idCodigoUnicoDoProduto': idCodigoUnicoDoProduto,
      'qt': qt,
      'vlUnitario': vlUnitario,
      'idColaboradorResponsavelPeloServico':
          idColaboradorResponsavelPeloServico,
      'nomeColaboradorResponsavel': nomeColaboradorResponsavel,
    };
  }
}

class RecebimentoRequest {
  RecebimentoRequest({
    required this.localDateTimeDoRecebimento,
    required this.idUnicoDoColaborador,
    required this.objGrana,
  });

  final String? localDateTimeDoRecebimento;
  final String idUnicoDoColaborador;
  final GranaRequest objGrana;

  Map<String, dynamic> toJson() {
    return {
      'localDateTimeDoRecebimento': localDateTimeDoRecebimento,
      'idUnicoDoColaborador': idUnicoDoColaborador,
      'objGrana': objGrana.toJson(),
    };
  }
}

class GranaRequest {
  GranaRequest({
    required this.tipo1,
    required this.tipo2,
    required this.tipo3,
    required this.tipo4,
    required this.tipo5,
  });

  final double tipo1;
  final double tipo2;
  final double tipo3;
  final double tipo4;
  final double tipo5;

  Map<String, dynamic> toJson() {
    return {
      'tipo1': tipo1,
      'tipo2': tipo2,
      'tipo3': tipo3,
      'tipo4': tipo4,
      'tipo5': tipo5,
    };
  }
}

class OperacaoLogRequest {
  OperacaoLogRequest({
    required this.objInformacoesDoCadastro,
    required this.ocorrencia,
  });

  final InformacoesCadastroRequest objInformacoesDoCadastro;
  final String ocorrencia;

  Map<String, dynamic> toJson() {
    return {
      'objInformacoesDoCadastro': objInformacoesDoCadastro.toJson(),
      'ocorrencia': ocorrencia,
    };
  }
}

class InformacoesCadastroRequest {
  InformacoesCadastroRequest({
    required this.idDeQuemCadastrou,
    required this.dataCadastro,
  });

  final String idDeQuemCadastrou;
  final String? dataCadastro;

  Map<String, dynamic> toJson() {
    return {
      'idDeQuemCadastrou': idDeQuemCadastrou,
      'dataCadastro': dataCadastro,
    };
  }
}

class OperacaoInserirResponse {
  OperacaoInserirResponse({
    required this.uuid,
  });

  final String uuid;

  factory OperacaoInserirResponse.fromJson(Map<String, dynamic> json) {
    return OperacaoInserirResponse(
      uuid: (json['uuid'] ?? '').toString(),
    );
  }
}

class FormaPagamentoSelecionada {
  FormaPagamentoSelecionada({
    required this.codigo,
    required this.valor,
  });

  final String codigo;
  final double valor;
}

class ItemVendaAtual {
  ItemVendaAtual({
    required this.idProduto,
    required this.nome,
    required this.quantidade,
    required this.valorUnitario,
    this.ehServico = false,
  });

  final String idProduto;
  final String nome;
  final int quantidade;
  final double valorUnitario;
  final bool ehServico;
}

class OperacaoVendaInput {
  OperacaoVendaInput({
    required this.descricao,
    required this.idColaborador,
    required this.nomeColaborador,
    required this.itens,
    required this.formasPagamento,
    this.dataOperacao,
  });

  final String descricao;
  final String idColaborador;
  final String nomeColaborador;
  final List<ItemVendaAtual> itens;
  final List<FormaPagamentoSelecionada> formasPagamento;
  final DateTime? dataOperacao;
}
