
import '../data/models/operacao_models.dart';

class OperacaoRequestMapper {
  OperacaoInserirRequest toRequest(OperacaoVendaInput input) {
    final dataOperacao = (input.dataOperacao ?? DateTime.now()).toIso8601String();

    final vendaList = input.itens
        .where((item) => !item.ehServico)
        .map(
          (item) => VendaItemRequest(
            idSKU: item.idProduto,
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
            qt: item.quantidade,
            vlUnitario: item.valorUnitario,
            idColaboradorResponsavelPeloServico: input.idColaborador,
            nomeColaboradorResponsavel: input.nomeColaborador,
          ),
        )
        .toList();

    final totalDinheiro = _somarPorCodigo(input.formasPagamento, 'DINHEIRO');
    final totalPix = _somarPorCodigo(input.formasPagamento, 'PIX');
    final totalCartaoCredito =
        _somarPorCodigo(input.formasPagamento, 'CARTAO_CREDITO');
    final totalCartaoDebito =
        _somarPorCodigo(input.formasPagamento, 'CARTAO_DEBITO');
    final totalBoletoFiado = _somarPorCodigo(
      input.formasPagamento,
      'BOLETO',
    ) +
        _somarPorCodigo(input.formasPagamento, 'FIADO');

    return OperacaoInserirRequest(
      descricao: input.descricao,
      dataOperacao: dataOperacao,
      tipoDeOperacaoEnum: 'VENDA',
      statusQuitada: true,
      operacaoFinalizadaEProntaParaOCaixa: true,
      clientePediuParaApagar: false,
      vendaList: vendaList,
      servicoList: servicoList,
      objRecebimentosList: [
        RecebimentoRequest(
          localDateTimeDoRecebimento: dataOperacao,
          idUnicoDoColaborador: input.idColaborador,
          objGrana: GranaRequest(
            tipo1: totalDinheiro,
            tipo2: totalPix,
            tipo3: totalCartaoCredito,
            tipo4: totalCartaoDebito,
            tipo5: totalBoletoFiado,
          ),
        ),
      ],
      objLogsList: [
        OperacaoLogRequest(
          objInformacoesDoCadastro: InformacoesCadastroRequest(
            idDeQuemCadastrou: input.idColaborador,
            dataCadastro: dataOperacao,
          ),
          ocorrencia: 'OPERACAO_DE_VENDA',
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
