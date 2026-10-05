import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/web_header_assets_model.dart';

void main() {
  test('parseia headers Web resolvidos pelo backend', () {
    final WebHeaderAssetsModel
    model = WebHeaderAssetsModel.fromJson(<String, dynamic>{
      'perfilNegocio': <String, dynamic>{
        'perfil': <String, dynamic>{
          'segmentoPrincipal': 'AUTOMOTIVO',
          'subsegmento': 'CARROS',
          'descricaoOutro': null,
          'atividades': <String>['VENDA_PRODUTOS'],
          'objetivoPrincipal': 'VENDAS',
        },
        'configurado': true,
        'podeEditar': true,
        'versao': 1,
      },
      'assets': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'automotivo-clientes-hero-v1',
          'pagina': 'CLIENTES',
          'imagemUrl':
              'https://assets.sixappback.com/web/clientes/hero-v1.png?rev=20261003-web-automotivo',
          'modoExibicao': 'HEADER_HERO',
          'imagemFallback': false,
        },
        <String, dynamic>{
          'id': 'automotivo-vendas-hero-v1',
          'pagina': 'VENDAS',
          'imagemUrl':
              'https://assets.sixappback.com/web/vendas/hero-v1.png?rev=20261003-web-automotivo',
          'modoExibicao': 'HEADER_HERO',
          'imagemFallback': false,
        },
        for (final WebHeaderAssetPage page in <WebHeaderAssetPage>[
          WebHeaderAssetPage.devolucoes,
          WebHeaderAssetPage.caixa,
          WebHeaderAssetPage.assistencias,
          WebHeaderAssetPage.compras,
          WebHeaderAssetPage.reservas,
          WebHeaderAssetPage.produtos,
          WebHeaderAssetPage.estoque,
          WebHeaderAssetPage.desempenho,
          WebHeaderAssetPage.agendaFinanceira,
          WebHeaderAssetPage.usuariosSixo,
          WebHeaderAssetPage.inicio,
        ])
          <String, dynamic>{
            'id': 'fallback-${page.backendCode}',
            'pagina': page.backendCode,
            'imagemUrl':
                'https://assets.sixappback.com/atendimento/mobile/fallback/vendas-v1.webp?rev=1',
            'modoExibicao': 'HEADER_HERO',
            'imagemFallback': true,
          },
      ],
    });

    expect(model.perfilNegocio.perfil.segmentoPrincipal, 'AUTOMOTIVO');
    expect(model.assets.length, 13);
    expect(model.asset(WebHeaderAssetPage.estoque)!.imagemFallback, isTrue);
    expect(model.asset(WebHeaderAssetPage.desempenho)!.imagemFallback, isTrue);
    expect(model.asset(WebHeaderAssetPage.inicio)!.imagemFallback, isTrue);
    expect(
      model.asset(WebHeaderAssetPage.agendaFinanceira)!.imagemFallback,
      isTrue,
    );
    expect(
      model.asset(WebHeaderAssetPage.usuariosSixo)!.imagemFallback,
      isTrue,
    );

    final WebHeaderAssetModel? clientes = model.asset(
      WebHeaderAssetPage.clientes,
    );
    expect(clientes, isNotNull);
    expect(clientes!.imagemFallback, isFalse);
    expect(clientes.imagemUrl, contains('/web/clientes/hero-v1.png'));
    expect(clientes.modoExibicao, WebHeaderAssetDisplayMode.headerHero);
  });

  test('aceita resposta sem imagem para perfil ainda não ilustrado', () {
    final WebHeaderAssetsModel model = WebHeaderAssetsModel.fromJson(
      <String, dynamic>{
        'perfilNegocio': <String, dynamic>{
          'perfil': <String, dynamic>{
            'segmentoPrincipal': 'MODA',
            'subsegmento': 'ROUPAS',
            'descricaoOutro': null,
            'atividades': <String>['VENDA_PRODUTOS'],
            'objetivoPrincipal': 'VENDAS',
          },
          'configurado': true,
          'podeEditar': true,
          'versao': 2,
        },
        'assets': <Map<String, dynamic>>[],
      },
    );

    expect(model.assets, isEmpty);
    expect(model.asset(WebHeaderAssetPage.vendas), isNull);
  });

  test('rejeita URL não HTTPS', () {
    expect(
      () => WebHeaderAssetModel.fromJson(<String, dynamic>{
        'id': 'invalido',
        'pagina': 'VENDAS',
        'imagemUrl': 'http://example.com/vendas.png',
        'modoExibicao': 'HEADER_HERO',
        'imagemFallback': false,
      }),
      throwsFormatException,
    );
  });

  test('rejeita página desconhecida', () {
    expect(
      () => WebHeaderAssetModel.fromJson(<String, dynamic>{
        'id': 'invalido',
        'pagina': 'PAGINA_FUTURA',
        'imagemUrl': 'https://assets.sixappback.com/web/estoque/hero-v1.png',
        'modoExibicao': 'HEADER_HERO',
        'imagemFallback': false,
      }),
      throwsFormatException,
    );
  });
}
