import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/utils/catalogo_selecao_pdv.dart';
import 'package:sixpos/data/models/permissao_colaborador.dart';
import 'package:sixpos/data/models/produto_model.dart';

void main() {
  test(
    '19 permissões fazem ida e volta preservando comissões e campos antigos',
    () {
      final dados = <String, dynamic>{
        'podeFazerDevolucao': true,
        'objVendasPode': {'comissaoDeVendas': 4},
      };
      expect(PermissaoColaborador.values.length, 19);
      for (final p in PermissaoColaborador.values) {
        PermissaoColaborador.aplicar(dados, {p});
        expect(PermissaoColaborador.ler(dados), {p});
        expect(dados['objVendasPode']['comissaoDeVendas'], 4);
        expect(dados['podeFazerDevolucao'], true);
      }
      expect(PermissaoColaborador.iniciais(), {
        PermissaoColaborador.vendas,
        PermissaoColaborador.assistencia,
        PermissaoColaborador.clientes,
      });
    },
  );

  test('catálogo vazio orienta segundo cada autorização', () {
    final vazio = CatalogoSelecaoPdv({'PRODUTO': [], 'SERVICO': []});
    expect(
      vazio
          .orientacao('PRODUTO', criarProduto: false, criarServico: false)
          .acao,
      AcaoCatalogo.voltar,
    );
    expect(
      vazio.orientacao('PRODUTO', criarProduto: true, criarServico: false).acao,
      AcaoCatalogo.criarProduto,
    );
    expect(
      vazio.orientacao('PRODUTO', criarProduto: false, criarServico: true).acao,
      AcaoCatalogo.criarServico,
    );
  });

  test(
    'inatividade, falha de consulta e busca sem resultado têm estados próprios',
    () {
      final item = ProdutoModel.fromJson({'ativo': false});
      final catalogo = CatalogoSelecaoPdv({
        'PRODUTO': [item],
        'SERVICO': [],
      });
      expect(
        catalogo
            .orientacao('PRODUTO', criarProduto: false, criarServico: false)
            .titulo,
        'pdv.empty.inactiveProducts',
      );
      expect(
        CatalogoSelecaoPdv({
          'PRODUTO': null,
          'SERVICO': [],
        }).orientacao('PRODUTO', criarProduto: false, criarServico: false),
        OrientacaoCatalogo.erro,
      );
      final ativos = CatalogoSelecaoPdv({
        'PRODUTO': [item.copyWith(ativo: true)],
        'SERVICO': [],
      });
      expect(
        ativos.orientacao('PRODUTO', criarProduto: true, criarServico: true),
        OrientacaoCatalogo.filtro,
      );
    },
  );
}
