import '../../core/config/app_config.dart';
import '../../data/models/perfil_negocio_model.dart';

enum AtendimentoMobileBusinessAsset {
  vendas('vendas-v1.webp'),
  servicos('servicos-v1.webp'),
  receber('receber-v1.webp'),
  operacoesCaixa('operacoes-caixa-v1.webp'),
  devolucao('devolucao-v1.webp');

  const AtendimentoMobileBusinessAsset(this.fileName);

  final String fileName;
}

class AtendimentoMobileBusinessAssets {
  const AtendimentoMobileBusinessAssets._(this.profileFolder);

  final String profileFolder;

  static AtendimentoMobileBusinessAssets? fromPerfil(
    PerfilNegocioModel perfil,
  ) {
    final String segmento = perfil.segmentoPrincipal.trim().toUpperCase();
    final String? subsegmento = perfil.subsegmento?.trim().toUpperCase();

    if (segmento == 'AUTOMOTIVO' &&
        (subsegmento == null ||
            subsegmento.isEmpty ||
            subsegmento == 'CARROS')) {
      return const AtendimentoMobileBusinessAssets._('automotivo');
    }

    if (segmento == 'MODA' &&
        (subsegmento == null ||
            subsegmento.isEmpty ||
            subsegmento == 'ROUPAS' ||
            subsegmento == 'COSTURA_AJUSTES')) {
      return const AtendimentoMobileBusinessAssets._('moda');
    }

    if (segmento == 'ELETRONICOS' && subsegmento == 'CELULARES') {
      return const AtendimentoMobileBusinessAssets._(
        'eletronicos-celulares',
      );
    }

    return null;
  }

  String url(AtendimentoMobileBusinessAsset asset) {
    final String base = AppConfig.assetsBaseUrl.replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    return '$base/atendimento/mobile/$profileFolder/${asset.fileName}';
  }
}
