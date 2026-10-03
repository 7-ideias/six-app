import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/atendimento_mobile_assets_model.dart';

void main() {
  test('parseia assets de Atendimento Mobile vindos do backend', () {
    final AtendimentoMobileAssetsModel model =
        AtendimentoMobileAssetsModel.fromJson(<String, dynamic>{
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
            'versao': 2,
          },
          'assets': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'fallback-vendas-v1',
              'slot': 'VENDAS',
              'imagemUrl':
                  'https://assets.sixappback.com/atendimento/mobile/fallback/vendas-v1.webp?rev=20261003-fallback',
              'modoExibicao': 'FULL_CARD',
              'imagemFallback': true,
            },
            <String, dynamic>{
              'id': 'fallback-servicos-v1',
              'slot': 'SERVICOS',
              'imagemUrl':
                  'https://assets.sixappback.com/atendimento/mobile/fallback/servicos-v1.webp?rev=20261003-fallback',
              'modoExibicao': 'FULL_CARD',
              'imagemFallback': true,
            },
          ],
        });

    expect(model.perfilNegocio.perfil.segmentoPrincipal, 'LIMPEZA');

    final AtendimentoMobileAssetModel? vendas = model.asset(
      AtendimentoMobileAssetSlot.vendas,
    );
    expect(vendas, isNotNull);
    expect(vendas!.imagemFallback, isTrue);
    expect(vendas.modoExibicao, AtendimentoMobileAssetDisplayMode.fullCard);
    expect(vendas.imagemUrl, contains('/fallback/vendas-v1.webp'));
  });

  test('mantém modo contain quando backend resolve arte contextual antiga', () {
    final AtendimentoMobileAssetModel model =
        AtendimentoMobileAssetModel.fromJson(<String, dynamic>{
          'id': 'eletronicos-celulares-receber-v1',
          'slot': 'RECEBER',
          'imagemUrl':
              'https://assets.sixappback.com/atendimento/mobile/eletronicos-celulares/receber-v1.webp',
          'modoExibicao': 'CONTAIN',
          'imagemFallback': false,
        });

    expect(model.slot, AtendimentoMobileAssetSlot.receber);
    expect(model.modoExibicao, AtendimentoMobileAssetDisplayMode.contain);
    expect(model.imagemFallback, isFalse);
  });

  test('rejeita URL não HTTPS recebida do backend', () {
    expect(
      () => AtendimentoMobileAssetModel.fromJson(<String, dynamic>{
        'id': 'asset-invalido',
        'slot': 'VENDAS',
        'imagemUrl': 'http://example.com/vendas.webp',
        'modoExibicao': 'FULL_CARD',
        'imagemFallback': true,
      }),
      throwsFormatException,
    );
  });
}
