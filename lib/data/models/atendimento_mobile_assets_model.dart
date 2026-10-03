import 'perfil_negocio_model.dart';

enum AtendimentoMobileAssetSlot {
  vendas('VENDAS'),
  servicos('SERVICOS'),
  receber('RECEBER'),
  operacoesCaixa('OPERACOES_CAIXA'),
  devolucao('DEVOLUCAO');

  const AtendimentoMobileAssetSlot(this.backendCode);
  final String backendCode;

  static AtendimentoMobileAssetSlot? fromBackend(String? value) {
    for (final AtendimentoMobileAssetSlot slot in values) {
      if (slot.backendCode == value) return slot;
    }
    return null;
  }
}

enum AtendimentoMobileAssetDisplayMode {
  fullCard('FULL_CARD'),
  contain('CONTAIN');

  const AtendimentoMobileAssetDisplayMode(this.backendCode);
  final String backendCode;

  static AtendimentoMobileAssetDisplayMode fromBackend(String? value) =>
      value == 'FULL_CARD'
          ? AtendimentoMobileAssetDisplayMode.fullCard
          : AtendimentoMobileAssetDisplayMode.contain;
}

class AtendimentoMobileAssetModel {
  const AtendimentoMobileAssetModel({
    required this.id,
    required this.slot,
    required this.imagemUrl,
    required this.modoExibicao,
    required this.imagemFallback,
  });

  final String id;
  final AtendimentoMobileAssetSlot slot;
  final String imagemUrl;
  final AtendimentoMobileAssetDisplayMode modoExibicao;
  final bool imagemFallback;

  factory AtendimentoMobileAssetModel.fromJson(Map<String, dynamic> json) {
    final AtendimentoMobileAssetSlot? slot =
        AtendimentoMobileAssetSlot.fromBackend(json['slot']?.toString());
    final String? imagemUrl = _https(json['imagemUrl']);

    if (slot == null || imagemUrl == null) {
      throw const FormatException('Asset de Atendimento Mobile inválido.');
    }

    return AtendimentoMobileAssetModel(
      id: json['id']?.toString() ?? slot.backendCode,
      slot: slot,
      imagemUrl: imagemUrl,
      modoExibicao: AtendimentoMobileAssetDisplayMode.fromBackend(
        json['modoExibicao']?.toString(),
      ),
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

class AtendimentoMobileAssetsModel {
  const AtendimentoMobileAssetsModel({
    required this.perfilNegocio,
    required this.assets,
  });

  final PerfilNegocioEmpresaModel perfilNegocio;
  final List<AtendimentoMobileAssetModel> assets;

  factory AtendimentoMobileAssetsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> perfil = Map<String, dynamic>.from(
      json['perfilNegocio'] as Map,
    );
    final List<dynamic> itens = json['assets'] as List<dynamic>? ?? const [];

    return AtendimentoMobileAssetsModel(
      perfilNegocio: PerfilNegocioEmpresaModel.fromJson(perfil),
      assets: List<AtendimentoMobileAssetModel>.unmodifiable(
        itens.map(
          (dynamic item) => AtendimentoMobileAssetModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      ),
    );
  }

  AtendimentoMobileAssetModel? asset(AtendimentoMobileAssetSlot slot) {
    for (final AtendimentoMobileAssetModel item in assets) {
      if (item.slot == slot) return item;
    }
    return null;
  }
}
