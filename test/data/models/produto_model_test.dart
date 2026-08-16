import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/produto_model.dart';

void main() {
  test('fromJson assume false quando campos novos estao ausentes', () {
    final ProdutoModel model = ProdutoModel.fromJson(<String, dynamic>{
      'id': 'p1',
      'ativo': true,
      'codigoDeBarras': '789123',
      'nomeProduto': 'Cabo USB',
      'tipoPoduto': 'PRODUTO',
      'modeloProduto': 'UNIDADE',
      'estoqueMaximo': 10,
      'estoqueMinimo': 1,
      'precoVenda': 25.9,
    });

    expect(model.favorito, isFalse);
    expect(model.disponivelParaCatalogo, isFalse);
  });

  test('fromJson le corretamente os quatro estados possiveis', () {
    final List<({bool favorito, bool catalogo})> estados =
        <({bool favorito, bool catalogo})>[
          (favorito: false, catalogo: false),
          (favorito: true, catalogo: false),
          (favorito: false, catalogo: true),
          (favorito: true, catalogo: true),
        ];

    for (final estado in estados) {
      final ProdutoModel model = ProdutoModel.fromJson(<String, dynamic>{
        'id': 'p1',
        'ativo': true,
        'favorito': estado.favorito,
        'disponivelParaCatalogo': estado.catalogo,
        'codigoDeBarras': '789123',
        'nomeProduto': 'Cabo USB',
        'tipoPoduto': 'PRODUTO',
        'modeloProduto': 'UNIDADE',
        'estoqueMaximo': 10,
        'estoqueMinimo': 1,
        'precoVenda': 25.9,
      });

      expect(model.favorito, estado.favorito);
      expect(model.disponivelParaCatalogo, estado.catalogo);
    }
  });

  test('toJson envia os nomes corretos', () {
    final ProdutoModel model = ProdutoModel(
      id: 'p1',
      ativo: true,
      favorito: true,
      disponivelParaCatalogo: false,
      codigoDeBarras: '789123',
      nomeProduto: 'Cabo USB',
      tipoProduto: 'PRODUTO',
      modeloProduto: 'UNIDADE',
      estoqueMaximo: 10,
      estoqueMinimo: 1,
      precoVenda: 25.9,
      objComissao: ObjComissao(
        produtoTemComissaoEspecial: false,
        valorFixoDeComissaoParaEsseProduto: 0,
      ),
    );

    final Map<String, dynamic> json = model.toJson();

    expect(json['favorito'], isTrue);
    expect(json['disponivelParaCatalogo'], isFalse);
  });
}
