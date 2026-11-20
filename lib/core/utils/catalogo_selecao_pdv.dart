import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';
import 'produto_helper.dart';

class CatalogoSelecaoPdv {
  CatalogoSelecaoPdv(this.porTipo);
  // Uma falha em uma aba não impede a venda de itens da outra.
  final Map<String, List<ProdutoModel>?> porTipo;

  static Future<CatalogoSelecaoPdv> carregar(
    ProdutosListProvider<ProdutoModel> provider,
  ) async {
    final Map<String, String> headers;
    try {
      headers = await ProdutoHelper.headersListagem('PRODUTO');
    } catch (_) {
      return CatalogoSelecaoPdv({});
    }
    final abas = await Future.wait(
      ['PRODUTO', 'SERVICO'].map((tipo) async {
        try {
          return MapEntry(
            tipo,
            await provider.consultar({...headers, 'tipo': tipo}),
          );
        } catch (_) {
          return MapEntry<String, List<ProdutoModel>?>(tipo, null);
        }
      }),
    );
    return CatalogoSelecaoPdv(Map.fromEntries(abas));
  }

  List<ProdutoModel> ativos(String tipo) =>
      (porTipo[tipo] ?? []).where((p) => p.ativo).toList();

  OrientacaoCatalogo orientacao(
    String tipo, {
    required bool criarProduto,
    required bool criarServico,
  }) {
    final produto = tipo == 'PRODUTO';
    final outroTipo = produto ? 'SERVICO' : 'PRODUTO';
    final itens = porTipo[tipo];
    if (itens == null) return OrientacaoCatalogo.erro;
    if (ativos(tipo).isNotEmpty) return OrientacaoCatalogo.filtro;
    final titulo =
        itens.isEmpty
            ? (produto ? 'pdv.empty.products' : 'pdv.empty.services')
            : (produto
                ? 'pdv.empty.inactiveProducts'
                : 'pdv.empty.inactiveServices');
    final verOutro = ativos(outroTipo).isNotEmpty;
    final cadastrar =
        (produto ? criarProduto : criarServico)
            ? (produto ? AcaoCatalogo.criarProduto : AcaoCatalogo.criarServico)
            : criarProduto
            ? AcaoCatalogo.criarProduto
            : criarServico
            ? AcaoCatalogo.criarServico
            : null;
    if (verOutro) {
      return OrientacaoCatalogo(
        titulo,
        produto ? 'pdv.empty.sellService' : 'pdv.empty.sellProduct',
        produto ? AcaoCatalogo.verServicos : AcaoCatalogo.verProdutos,
        secundaria: cadastrar,
      );
    }
    if (cadastrar != null)
      return OrientacaoCatalogo(titulo, 'pdv.empty.create', cadastrar);
    if (porTipo[outroTipo] == null) return OrientacaoCatalogo.erro;
    return OrientacaoCatalogo(
      titulo,
      'pdv.empty.askAdmin',
      AcaoCatalogo.voltar,
    );
  }
}

enum AcaoCatalogo {
  verServicos('pdv.empty.viewServices'),
  verProdutos('pdv.empty.viewProducts'),
  criarProduto('staff.permission.produtos'),
  criarServico('staff.permission.servicos'),
  voltar('pdv.empty.back'),
  limpar('pdv.empty.clear'),
  recarregar('pdv.empty.retry');

  const AcaoCatalogo(this.chave);
  final String chave;
}

class OrientacaoCatalogo {
  const OrientacaoCatalogo(
    this.titulo,
    this.descricao,
    this.acao, {
    this.secundaria,
  });
  final String titulo;
  final String? descricao;
  final AcaoCatalogo acao;
  final AcaoCatalogo? secundaria;
  static const erro = OrientacaoCatalogo(
    'pdv.empty.error',
    null,
    AcaoCatalogo.recarregar,
  );
  static const filtro = OrientacaoCatalogo(
    'pdv.empty.noMatch',
    null,
    AcaoCatalogo.limpar,
  );
}
