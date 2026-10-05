import 'package:flutter/foundation.dart' show kDebugMode;
import 'perfil_negocio_model.dart';

enum WebHeaderAssetPage {
  clientes('CLIENTES'),
  colaboradores('COLABORADORES'),
  vendas('VENDAS'),
  devolucoes('DEVOLUCOES'),
  caixa('CAIXA'),
  assistencias('ASSISTENCIAS'),
  compras('COMPRAS'),
  reservas('RESERVAS'),
  produtos('PRODUTOS'),
  estoque('ESTOQUE'),
  desempenho('DESEMPENHO'),
  agendaFinanceira('AGENDA_FINANCEIRA'),
  usuariosSixo('USUARIOS_SIXO');

  const WebHeaderAssetPage(this.backendCode);
  final String backendCode;

  static WebHeaderAssetPage? fromBackend(String? value) {
    for (final WebHeaderAssetPage page in values) {
      if (page.backendCode == value) return page;
    }
    return null;
  }
}

enum WebHeaderAssetDisplayMode {
  headerHero('HEADER_HERO');

  const WebHeaderAssetDisplayMode(this.backendCode);
  final String backendCode;

  static WebHeaderAssetDisplayMode? fromBackend(String? value) {
    for (final WebHeaderAssetDisplayMode mode in values) {
      if (mode.backendCode == value) return mode;
    }
    return null;
  }
}

class WebHeaderAssetModel {
  const WebHeaderAssetModel({
    required this.id,
    required this.pagina,
    required this.imagemUrl,
    required this.modoExibicao,
    required this.imagemFallback,
  });

  final String id;
  final WebHeaderAssetPage pagina;
  final String imagemUrl;
  final WebHeaderAssetDisplayMode modoExibicao;
  final bool imagemFallback;

  factory WebHeaderAssetModel.fromJson(Map<String, dynamic> json) {
    final WebHeaderAssetPage? pagina = WebHeaderAssetPage.fromBackend(
      json['pagina']?.toString(),
    );
    final WebHeaderAssetDisplayMode? modo =
        WebHeaderAssetDisplayMode.fromBackend(json['modoExibicao']?.toString());
    final String? imagemUrl = _https(json['imagemUrl']);

    if (pagina == null || modo == null || imagemUrl == null) {
      throw const FormatException('Asset de header Web inválido.');
    }

    return WebHeaderAssetModel(
      id: json['id']?.toString() ?? pagina.backendCode,
      pagina: pagina,
      imagemUrl: imagemUrl,
      modoExibicao: modo,
      imagemFallback: json['imagemFallback'] == true,
    );
  }

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

class WebHeaderAssetsModel {
  const WebHeaderAssetsModel({
    required this.perfilNegocio,
    required this.assets,
  });

  final PerfilNegocioEmpresaModel perfilNegocio;
  final List<WebHeaderAssetModel> assets;

  factory WebHeaderAssetsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> perfil = Map<String, dynamic>.from(
      json['perfilNegocio'] as Map,
    );
    final List<dynamic> itens = json['assets'] as List<dynamic>? ?? const [];

    return WebHeaderAssetsModel(
      perfilNegocio: PerfilNegocioEmpresaModel.fromJson(perfil),
      assets: List<WebHeaderAssetModel>.unmodifiable(
        itens.map(
          (dynamic item) => WebHeaderAssetModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      ),
    );
  }

  WebHeaderAssetModel? asset(WebHeaderAssetPage pagina) {
    for (final WebHeaderAssetModel item in assets) {
      if (item.pagina == pagina) return item;
    }
    return null;
  }
}
