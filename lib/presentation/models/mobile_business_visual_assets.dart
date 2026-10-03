import '../../core/config/app_config.dart';
import '../../data/models/perfil_negocio_model.dart';

enum VendasMobileBusinessAsset {
  vendas('vendas-v1.webp'),
  vendasAReceber('vendas-a-receber-v1.webp'),
  consultarVendas('consultar-vendas-v1.webp');

  const VendasMobileBusinessAsset(this.fileName);
  final String fileName;
}

class MobileBusinessVisualAssets {
  const MobileBusinessVisualAssets._(this.profileFolder);

  static const String assetRevision = '20261001-vendas-gestao';

  final String profileFolder;

  static MobileBusinessVisualAssets? fromPerfil(PerfilNegocioModel perfil) {
    final String segmento = perfil.segmentoPrincipal.trim().toUpperCase();
    final String? subsegmento = perfil.subsegmento?.trim().toUpperCase();

    if (segmento == 'AUTOMOTIVO' &&
        (subsegmento == null ||
            subsegmento.isEmpty ||
            subsegmento == 'CARROS')) {
      return const MobileBusinessVisualAssets._('automotivo');
    }

    return null;
  }

  String vendasUrl(VendasMobileBusinessAsset asset) =>
      _url('vendas', asset.fileName);

  String _url(String area, String fileName) {
    final String base = AppConfig.assetsBaseUrl.replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    final Uri uri = Uri.parse('$base/mobile/$profileFolder/$area/$fileName');
    return uri
        .replace(queryParameters: <String, String>{'rev': assetRevision})
        .toString();
  }
}
