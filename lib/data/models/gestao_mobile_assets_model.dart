import 'perfil_negocio_model.dart';

enum GestaoMobileAssetSlot {
  hero('HERO'),
  catalogo('CATALOGO'),
  pessoas('PESSOAS'),
  financeiro('FINANCEIRO'),
  configuracoes('CONFIGURACOES');

  const GestaoMobileAssetSlot(this.backendCode);
  final String backendCode;

  static GestaoMobileAssetSlot? fromBackend(String? value) {
    for (final GestaoMobileAssetSlot slot in values) {
      if (slot.backendCode == value) return slot;
    }
    return null;
  }
}

enum GestaoMobileAssetDisplayMode {
  fullCard('FULL_CARD');

  const GestaoMobileAssetDisplayMode(this.backendCode);
  final String backendCode;

  static GestaoMobileAssetDisplayMode? fromBackend(String? value) {
    for (final GestaoMobileAssetDisplayMode mode in values) {
      if (mode.backendCode == value) return mode;
    }
    return null;
  }
}

class GestaoMobileAssetModel {
  const GestaoMobileAssetModel({
    required this.id,
    required this.slot,
    required this.imagemUrl,
    required this.modoExibicao,
    required this.imagemFallback,
  });

  final String id;
  final GestaoMobileAssetSlot slot;
  final String imagemUrl;
  final GestaoMobileAssetDisplayMode modoExibicao;
  final bool imagemFallback;

  factory GestaoMobileAssetModel.fromJson(Map<String, dynamic> json) {
    final GestaoMobileAssetSlot? slot = GestaoMobileAssetSlot.fromBackend(
      json['slot']?.toString(),
    );
    final GestaoMobileAssetDisplayMode? modoExibicao =
        GestaoMobileAssetDisplayMode.fromBackend(
          json['modoExibicao']?.toString(),
        );
    final String? imagemUrl = _https(json['imagemUrl']);

    if (slot == null || modoExibicao == null || imagemUrl == null) {
      throw const FormatException('Asset de Gestão Mobile inválido.');
    }

    return GestaoMobileAssetModel(
      id: json['id']?.toString() ?? slot.backendCode,
      slot: slot,
      imagemUrl: imagemUrl,
      modoExibicao: modoExibicao,
      imagemFallback: json['imagemFallback'] == true,
    );
  }

  static String? _https(dynamic value) {
    final Uri? uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.toString();
  }
}

class GestaoMobileAssetsModel {
  const GestaoMobileAssetsModel({
    required this.perfilNegocio,
    required this.assets,
  });

  final PerfilNegocioEmpresaModel perfilNegocio;
  final List<GestaoMobileAssetModel> assets;

  factory GestaoMobileAssetsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> perfil = Map<String, dynamic>.from(
      json['perfilNegocio'] as Map,
    );
    final List<dynamic> itens = json['assets'] as List<dynamic>? ?? const [];

    return GestaoMobileAssetsModel(
      perfilNegocio: PerfilNegocioEmpresaModel.fromJson(perfil),
      assets: List<GestaoMobileAssetModel>.unmodifiable(
        itens.map(
          (dynamic item) => GestaoMobileAssetModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      ),
    );
  }

  GestaoMobileAssetModel? asset(GestaoMobileAssetSlot slot) {
    for (final GestaoMobileAssetModel item in assets) {
      if (item.slot == slot) return item;
    }
    return null;
  }
}
