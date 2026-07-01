import '../data/models/operacao_models.dart';

class OperacaoRequestMapper {
  OperacaoInserirRequest toRequest(OperacaoVendaInput input) {
    final dataOperacao = (input.dataOperacao ?? DateTime.now()).toIso8601String();
    final receberDepois = input.receberDepois;

    final vendaList = input.itens
        .where((item) => !item.ehServico)
        .map(
          (item) => VendaItemRequest(
            idSKU: item.idProduto,
            descricaoProduto: item.nome,
            qt: item.quantidade,
            vlUnitario: item.valorUnitario,
            idColaboradorResponsavelPeloServico: input.idColaborador,
            nomeColaboradorResponsavel: input.nomeColaborador,
          ),
        )
        .toList();

    final servicoList = input.itens
        .where((item) => item.ehServico)
        .map(
          (item) => ServicoItemRequest(
            idCodigoUnicoDoProduto: item.idProduto,
            descricaoProduto: item.nome,
            qt: item.quantidade,
            vlUnitario: item.valorUnitario,
            idColaboradorResponsavelPeloServico: input.idColaborador,
            nomeColaboradorResponsavel: input.nomeColaborador,
          ),
        )
        .toList();

    final totalTIPO1 = _somarPorCodigo(input.formasPagamento, 'TIPO1');
    final totalTIPO2 = _somarPorCodigo(input.formasPagamento, 'TIPO2');
    final totalTIPO3 = _somarPorCodigo(input.formasPagamento, 'TIPO3');
    final totalTIPO4 = _somarPorCodigo(input.formasPagamento, 'TIPO4');
    final totalTIPO5 = _somarPorCodigo(input.formasPagamento, 'TIPO5');
    final totalTIPO6 = _somarPorCodigo(input.formasPagamento, 'TIPO6');
    final totalTIPO7 = _somarPorCodigo(input.formasPagamento, 'TIPO7');
    final totalTIPO8 = _somarPorCodigo(input.formasPagamento, 'TIPO8');
    final totalTIPO9 = _somarPorCodigo(input.formasPagamento, 'TIPO9');
    final totalTIPO10 = _somarPorCodigo(input.formasPagamento, 'TIPO10');

    return OperacaoInserirRequest(
      descricao: input.descricao,
      dataOperacao: dataOperacao,
      tipoDeOperacaoEnum: 'VENDA',
      statusQuitada: !receberDepois,
      operacaoFinalizadaEProntaParaOCaixa: !receberDepois,
      clientePediuParaApagar: false,
      vendaList: vendaList,
      servicoList: servicoList,
      objRecebimentosList: receberDepois
          ? <RecebimentoRequest>[]
          : [
              RecebimentoRequest(
                localDateTimeDoRecebimento: dataOperacao,
                idUnicoDoColaborador: input.idColaborador,
                objGrana: GranaRequest(
                  tipo1: totalTIPO1,
                  tipo2: totalTIPO2,
                  tipo3: totalTIPO3,
                  tipo4: totalTIPO4,
                  tipo5: totalTIPO5,
                  tipo6: totalTIPO6,
                  tipo7: totalTIPO7,
                  tipo8: totalTIPO8,
                  tipo9: totalTIPO9,
                  tipo10: totalTIPO10,
                ),
              ),
            ],
      objLogsList: [
        OperacaoLogRequest(
          objInformacoesDoCadastro: InformacoesCadastroRequest(
            idDeQuemCadastrou: input.idColaborador,
            dataCadastro: dataOperacao,
          ),
          ocorrencia: receberDepois
              ? 'OPERACAO_DE_VENDA_NAO_LIQUIDADA'
              : 'OPERACAO_DE_VENDA',
        ),
      ],
    );
  }

  double _somarPorCodigo(List<FormaPagamentoSelecionada> formas, String codigo) {
    return formas
        .where((forma) => forma.codigo == codigo)
        .fold<double>(0.0, (soma, forma) => soma + forma.valor);
  }
}
