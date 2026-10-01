import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/perfil_negocio_model.dart';
import 'package:sixpos/presentation/models/atendimento_mobile_business_assets.dart';

void main() {
  PerfilNegocioModel perfil(String segmento, [String? subsegmento]) {
    return PerfilNegocioModel(
      segmentoPrincipal: segmento,
      subsegmento: subsegmento,
      atividades: const <String>{'VENDA_PRODUTOS'},
      objetivoPrincipal: 'GERAL',
    );
  }

  test('resolve oficina automotiva sem subsegmento', () {
    final assets = AtendimentoMobileBusinessAssets.fromPerfil(
      perfil('AUTOMOTIVO'),
    );

    expect(assets, isNotNull);
    expect(assets!.profileFolder, 'automotivo');
    expect(
      assets.url(AtendimentoMobileBusinessAsset.servicos),
      'https://assets.sixappback.com/atendimento/mobile/automotivo/servicos-v1.webp?rev=20261001-fullcard',
    );
  });

  test('resolve moda para roupas e costura', () {
    expect(
      AtendimentoMobileBusinessAssets.fromPerfil(
        perfil('MODA', 'ROUPAS'),
      )?.profileFolder,
      'moda',
    );
    expect(
      AtendimentoMobileBusinessAssets.fromPerfil(
        perfil('MODA', 'COSTURA_AJUSTES'),
      )?.profileFolder,
      'moda',
    );
  });

  test('resolve eletrônicos apenas para celulares', () {
    expect(
      AtendimentoMobileBusinessAssets.fromPerfil(
        perfil('ELETRONICOS', 'CELULARES'),
      )?.profileFolder,
      'eletronicos-celulares',
    );
    expect(
      AtendimentoMobileBusinessAssets.fromPerfil(
        perfil('ELETRONICOS', 'TV_AUDIO'),
      ),
      isNull,
    );
  });

  test('não usa imagem de carros para motos', () {
    expect(
      AtendimentoMobileBusinessAssets.fromPerfil(
        perfil('AUTOMOTIVO', 'MOTOS'),
      ),
      isNull,
    );
  });
}
