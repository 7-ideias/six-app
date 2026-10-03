import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/gestao_mobile_assets_model.dart';

void main() {
  test('parseia fallbacks da Gestão Mobile vindos do backend', () {
    final GestaoMobileAssetsModel
    model = GestaoMobileAssetsModel.fromJson(<String, dynamic>{
      'perfilNegocio': <String, dynamic>{
        'perfil': <String, dynamic>{
          'segmentoPrincipal': 'LIMPEZA',
          'subsegmento': 'SERVICOS_LIMPEZA',
          'descricaoOutro': null,
          'atividades': <String>['PRESTACAO_SERVICOS'],
          'objetivoPrincipal': 'SERVICOS',
        },
        'configurado': true,
        'podeEditar': true,
        'versao': 3,
      },
      'assets': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'fallback-hero-v1',
          'slot': 'HERO',
          'imagemUrl':
              'https://assets.sixappback.com/mobile/gestao/fallback/hero-v1.webp?rev=20261003-fallback',
          'modoExibicao': 'FULL_CARD',
          'imagemFallback': true,
        },
        <String, dynamic>{
          'id': 'fallback-catalogo-v1',
          'slot': 'CATALOGO',
          'imagemUrl':
              'https://assets.sixappback.com/mobile/gestao/fallback/catalogo-v1.webp?rev=20261003-fallback',
          'modoExibicao': 'FULL_CARD',
          'imagemFallback': true,
        },
      ],
    });

    expect(model.perfilNegocio.perfil.segmentoPrincipal, 'LIMPEZA');

    final GestaoMobileAssetModel? hero = model.asset(
      GestaoMobileAssetSlot.hero,
    );
    expect(hero, isNotNull);
    expect(hero!.imagemFallback, isTrue);
    expect(hero.modoExibicao, GestaoMobileAssetDisplayMode.fullCard);
    expect(hero.imagemUrl, contains('/mobile/gestao/fallback/hero-v1.webp'));
  });

  test('aceita arte específica resolvida pelo backend', () {
    final GestaoMobileAssetModel
    model = GestaoMobileAssetModel.fromJson(<String, dynamic>{
      'id': 'automotivo-financeiro-v1',
      'slot': 'FINANCEIRO',
      'imagemUrl':
          'https://assets.sixappback.com/mobile/automotivo/gestao/financeiro-v1.webp',
      'modoExibicao': 'FULL_CARD',
      'imagemFallback': false,
    });

    expect(model.slot, GestaoMobileAssetSlot.financeiro);
    expect(model.imagemFallback, isFalse);
  });

  test('rejeita modo de exibição desconhecido', () {
    expect(
      () => GestaoMobileAssetModel.fromJson(<String, dynamic>{
        'id': 'asset-invalido',
        'slot': 'PESSOAS',
        'imagemUrl':
            'https://assets.sixappback.com/mobile/gestao/fallback/pessoas-v1.webp',
        'modoExibicao': 'STRETCH',
        'imagemFallback': true,
      }),
      throwsFormatException,
    );
  });

  test('rejeita URL não HTTPS', () {
    expect(
      () => GestaoMobileAssetModel.fromJson(<String, dynamic>{
        'id': 'asset-invalido',
        'slot': 'CATALOGO',
        'imagemUrl': 'http://example.com/catalogo.webp',
        'modoExibicao': 'FULL_CARD',
        'imagemFallback': true,
      }),
      throwsFormatException,
    );
  });
}
