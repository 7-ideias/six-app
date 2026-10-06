import 'package:flutter/foundation.dart' show kDebugMode;
import 'perfil_negocio_model.dart';

enum VendasMobileAssetSlot {
  vendas('VENDAS'),
  vendasAReceber('RECEBER'),
  consultarVendas('CONSULTAR');

  const VendasMobileAssetSlot(this.backendCode);
  final String backendCode;

  static VendasMobileAssetSlot? fromBackend(String? value) {
    for (final VendasMobileAssetSlot slot in values) {
      if (slot.backendCode == value) return slot;
    }
    return null;
  }
}

enum VendasMobileAssetDisplayMode {
  fullCard('FULL_CARD');

  const VendasMobileAssetDisplayMode(this.backendCode);
  final String backendCode;

  static VendasMobileAssetDisplayMode? fromBackend(String? value) {
    for (final VendasMobileAssetDisplayMode mode in values) {
      if (mode.backendCode == value) return mode;
    }
    return null;
  }
}

class VendasMobileAssetModel {
  const VendasMobileAssetModel({
    required this.id,
    required this.slot,
    required this.imagemUrl,
    required this.modoExibicao,
    required this.imagemFallback,
  });

  final String id;
  final VendasMobileAssetSlot slot;
  final String imagemUrl;
  final VendasMobileAssetDisplayMode modoExibicao;
  final bool imagemFallback;

  factory VendasMobileAssetModel.fromJson(Map<String, dynamic> json) {
    final VendasMobileAssetSlot? slot = VendasMobileAssetSlot.fromBackend(
      json['slot']?.toString(),
    );
    final VendasMobileAssetDisplayMode? modoExibicao =
        VendasMobileAssetDisplayMode.fromBackend(
          json['modoExibicao']?.toString(),
        );
    final String? imagemUrl = _https(json['imagemUrl']);

    if (slot == null || modoExibicao == null || imagemUrl == null) {
      throw const FormatException('Asset de Vendas Mobile inválido.');
    }

    return VendasMobileAssetModel(
      id: json['id']?.toString() ?? slot.backendCode,
      slot: slot,
      imagemUrl: imagemUrl,
      modoExibicao: modoExibicao,
      imagemFallback: json['imagemFallback'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'slot': slot.backendCode,
    'imagemUrl': imagemUrl,
    'modoExibicao': modoExibicao.backendCode,
    'imagemFallback': imagemFallback,
  };

  static String? _https(dynamic value) {
    final Uri? uri = value is String ? Uri.tryParse(value) : null;
    final bool secure = uri?.scheme == 'https';
    final bool debugHttp =
        kDebugMode &&
        uri?.scheme == 'http' &&
        (uri?.host == 'localhost' || uri?.host == '127.0.0.1');
    if (uri == null ||
        (!secure && !debugHttp) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.toString();
  }
}

class VendasMobileAssetsModel {
  const VendasMobileAssetsModel({
    required this.perfilNegocio,
    required this.assets,
  });

  final PerfilNegocioEmpresaModel perfilNegocio;
  final List<VendasMobileAssetModel> assets;

  factory VendasMobileAssetsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> perfil = Map<String, dynamic>.from(
      json['perfilNegocio'] as Map,
    );
    final List<dynamic> itens = json['assets'] as List<dynamic>? ?? const [];

    return VendasMobileAssetsModel(
      perfilNegocio: PerfilNegocioEmpresaModel.fromJson(perfil),
      assets: List<VendasMobileAssetModel>.unmodifiable(
        itens.map(
          (dynamic item) => VendasMobileAssetModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'perfilNegocio': perfilNegocio.toJson(),
    'assets': assets
        .map((VendasMobileAssetModel item) => item.toJson())
        .toList(growable: false),
  };

  VendasMobileAssetModel? asset(VendasMobileAssetSlot slot) {
    for (final VendasMobileAssetModel item in assets) {
      if (item.slot == slot) return item;
    }
    return null;
  }
}
