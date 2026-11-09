import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/colaborador_autorizacoes_model.dart';

void main() {
  test('autorizacoes indisponiveis nunca concedem permissoes', () {
    final ColaboradorAutorizacoesModel denied =
        ColaboradorAutorizacoesModel.negarTudo();
    expect(denied.podeCadastrarProduto, isFalse);
    expect(denied.podeFazerDevolucao, isFalse);
    expect(denied.objVendasPode.fazVenda, isFalse);
    expect(denied.objProdutosPode.podeEditarProduto, isFalse);
    expect(denied.objAssistenciaTecnicaPode.lancaServico, isFalse);
    expect(denied.objClientesPode.podeEditarCliente, isFalse);
    expect(denied.objLancamentosFinanceirosPode.podeReceberNoCaixa, isFalse);
  });
}
