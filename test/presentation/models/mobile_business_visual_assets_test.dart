import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/perfil_negocio_model.dart';
import 'package:sixpos/presentation/models/mobile_business_visual_assets.dart';

void main() {
  PerfilNegocioModel perfil(String segmento, [String? subsegmento]) {
    return PerfilNegocioModel(
      segmentoPrincipal: segmento,
      subsegmento: subsegmento,
      atividades: const <String>{'VENDA_PRODUTOS', 'PRESTACAO_SERVICOS'},
      objetivoPrincipal: 'GERAL',
    );
  }

  test('resolve automotivo sem subsegmento e carros', () {
    expect(
      MobileBusinessVisualAssets.fromPerfil(
        perfil('AUTOMOTIVO'),
      )?.profileFolder,
      'automotivo',
    );
    expect(
      MobileBusinessVisualAssets.fromPerfil(
        perfil('AUTOMOTIVO', 'CARROS'),
      )?.profileFolder,
      'automotivo',
    );
  });

  test('não reaproveita arte de carros para motos', () {
    expect(
      MobileBusinessVisualAssets.fromPerfil(perfil('AUTOMOTIVO', 'MOTOS')),
      isNull,
    );
  });

  test('gera urls versionadas de vendas e gestão', () {
    final MobileBusinessVisualAssets assets =
        MobileBusinessVisualAssets.fromPerfil(perfil('AUTOMOTIVO'))!;

    expect(
      assets.vendasUrl(VendasMobileBusinessAsset.vendas),
      'https://assets.sixappback.com/mobile/automotivo/vendas/vendas-v1.webp'
      '?rev=20261001-vendas-gestao',
    );
  });

  test('perfil sem arte mantém fallback local', () {
    expect(
      MobileBusinessVisualAssets.fromPerfil(perfil('MODA', 'ROUPAS')),
      isNull,
    );
  });
}
