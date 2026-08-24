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
    expect(model.tipoCadastro, 'RESUMIDO');
    expect(model.detalhes, isNull);
    expect(model.regrasOperacionais, isNull);
    expect(model.dadosFiscais, isNull);
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
      tipoCadastro: 'COMPLETO',
      detalhes: const ProdutoDetalhesModel(
        descricao: 'Cabo reforçado',
        codigoInterno: 'CB-USB-01',
        marca: 'Six',
        fabricante: 'Fornecedor A',
      ),
      regrasOperacionais: const ProdutoRegrasOperacionaisModel(
        categoriaUnidadeMedida: 'PESO',
        unidadeMedida: 'KG',
        controlaEstoque: true,
        permiteVendaFracionada: true,
        permiteEstoqueNegativo: false,
        quantidadeMinimaVenda: 0.25,
      ),
      dadosFiscais: const ProdutoDadosFiscaisModel(
        ncm: '85444200',
        cest: '1234567',
        cfop: '5102',
        origemMercadoria: '0',
        cstIcms: '00',
        csosn: '102',
        cstPis: '01',
        cstCofins: '01',
      ),
      objComissao: ObjComissao(
        produtoTemComissaoEspecial: false,
        valorFixoDeComissaoParaEsseProduto: 0,
      ),
    );

    final Map<String, dynamic> json = model.toJson();

    expect(json['favorito'], isTrue);
    expect(json['disponivelParaCatalogo'], isFalse);
    expect(json['tipoCadastro'], 'COMPLETO');
    expect(json['objServico'], isNull);
    expect(json.containsKey('objetoServico'), isFalse);
    expect(json['detalhes']['codigoInterno'], 'CB-USB-01');
    expect(json['regrasOperacionais']['categoriaUnidadeMedida'], 'PESO');
    expect(json['regrasOperacionais']['quantidadeMinimaVenda'], 0.25);
    expect(json['dadosFiscais']['ncm'], '85444200');
  });

  test('fromJson le cadastro completo persistido pelo backend', () {
    final ProdutoModel model = ProdutoModel.fromJson(<String, dynamic>{
      'id': 'p2',
      'nomeProduto': 'Tecido por metro',
      'tipoCadastro': 'COMPLETO',
      'detalhes': <String, dynamic>{
        'descricao': 'Tecido técnico',
        'marca': 'Six',
      },
      'regrasOperacionais': <String, dynamic>{
        'categoriaUnidadeMedida': 'DISTANCIA',
        'unidadeMedida': 'M',
        'controlaEstoque': true,
        'permiteVendaFracionada': true,
        'permiteEstoqueNegativo': false,
        'quantidadeMinimaVenda': 0.5,
      },
      'dadosFiscais': <String, dynamic>{'ncm': '59030000', 'cfop': '5102'},
    });

    expect(model.tipoCadastro, 'COMPLETO');
    expect(model.detalhes?.descricao, 'Tecido técnico');
    expect(model.regrasOperacionais?.unidadeMedida, 'M');
    expect(model.regrasOperacionais?.permiteVendaFracionada, isTrue);
    expect(model.dadosFiscais?.cfop, '5102');
  });
}
