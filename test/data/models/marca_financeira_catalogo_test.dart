import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';
import 'package:sixpos/data/models/marca_financeira_catalogo.dart';

void main() {
  const brasil = CatalogoInstituicoesBrasil(
    habilitado: true,
    instituicoes: [
      InstituicaoOpenFinance(
        nome: 'BTG Pactual',
        logotipoUrl: 'https://example.com/btg.svg',
        marcaOpenFinanceId: 'auth-btg',
      ),
    ],
  );

  test('marca da conta respeita país BR e tipo BANCO', () {
    const btg = ConfiguracaoFinanceira(
      id: '1', nome: 'BTG', tipo: 'BANCO', instituicao: '',
      marcaId: 'OF:auth-btg',
    );
    const carteira = ConfiguracaoFinanceira(
      id: '2', nome: 'BTG', tipo: 'CARTEIRA', instituicao: 'BTG Pactual',
    );
    expect(MarcaFinanceiraCatalogo.logoConta(btg, brasil),
        contains('30306294.svg'));
    expect(MarcaFinanceiraCatalogo.logoConta(btg,
        CatalogoInstituicoesBrasil.vazio), isNull);
    expect(MarcaFinanceiraCatalogo.logoConta(carteira, brasil), isNull);
  });

  test('operadora por codigo e por nome exato, nao por substring', () {
    expect(MarcaFinanceiraCatalogo.operadoraDe(
        'OPERADORA:STONE', 'Stone')?.codigo, 'STONE');
    expect(MarcaFinanceiraCatalogo.operadoraDe(
        null, 'PagSeguro')?.codigo, 'PAGBANK');
    expect(MarcaFinanceiraCatalogo.operadoraDe(null, 'Stone Store'), isNull);
    expect(MarcaFinanceiraCatalogo.logoOperadora(
        'Cielo', 'OPERADORA:CIELO', habilitadoBrasil: true),
        contains('01027058.svg'));
    expect(MarcaFinanceiraCatalogo.logoOperadora(
        'Cielo', 'OPERADORA:CIELO', habilitadoBrasil: false), isNull);
  });

  test('bancos e maquinas legados continuam sem ID e sem quebrar parsing', () {
    final conta = ConfiguracaoFinanceira.fromJson({
      'id': 'old', 'nome': 'Conta antiga', 'tipo': 'BANCO',
      'instituicao': 'Sem cadastro', 'ativo': true,
    });
    expect(conta.marcaId, isNull);
    expect(MarcaFinanceiraCatalogo.logoConta(conta, brasil), isNull);

    final maquina = ConfiguracaoFinanceira.fromJson({
      'id': 'machine', 'nome': 'Terminal', 'tipo': 'MAQUININHA',
      'instituicao': 'Stone', 'ativo': true,
      'contaDestinoId': 'conta',
      'marcaId': 'OPERADORA:STONE',
    });
    expect(maquina.contaDestinoId, 'conta');
    expect(MarcaFinanceiraCatalogo.logoDaConfiguracao(
        maquina, 'MAQUININHAS', brasil), contains('16501555.svg'));
  });
}
