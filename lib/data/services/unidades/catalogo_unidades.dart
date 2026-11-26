import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/http_client_factory.dart';

class Unidade {
  Unidade(this.dados);

  factory Unidade.legada(String codigo, String categoria) => Unidade({
    'codigo': codigo,
    'categoria': categoria,
    'nome': codigo,
    'ativa': true,
  });
  final Map<String, dynamic> dados;
  String get codigo => dados['codigo'] as String;
  String get categoria => dados['categoria'] as String;
  bool get ativa => dados['ativa'] == true;
  String nome(String idioma) {
    final override = dados['nome'] as String?;
    if (override != null && override.isNotEmpty) return override;
    return (dados[idioma] ?? dados['pt'] ?? codigo) as String;
  }

  String label(String idioma) => '${nome(idioma)} ($codigo)';
}

class CatalogoUnidades {
  CatalogoUnidades(Map<String, dynamic> json)
    : empresa = json['catalogo']['empresa'] as String,
      versao = json['catalogo']['versao'] as int?,
      padrao = json['catalogo']['padrao'] as String,
      podeEditar = json['podeEditar'] == true,
      podeConfigurar = json['podeConfigurar'] == true,
      unidades =
          (json['catalogo']['unidades'] as List)
              .map((e) => Unidade(e as Map<String, dynamic>))
              .toList();
  final String empresa, padrao;
  final int? versao;
  final bool podeEditar, podeConfigurar;
  final List<Unidade> unidades;
  Unidade? buscar(String codigo) {
    for (final unidade in unidades) {
      if (unidade.codigo.toLowerCase() == codigo.toLowerCase()) return unidade;
    }
    return null;
  }
}

class UnidadesApi {
  static Future<CatalogoUnidades> carregar() => _request();
  static Future<CatalogoUnidades> salvar(
    CatalogoUnidades anterior,
    Map<String, dynamic> dados,
  ) => _request(
    empresa: anterior.empresa,
    dados: {...dados, 'versao': anterior.versao},
  );

  static Future<CatalogoUnidades> _request({
    String? empresa,
    Map<String, dynamic>? dados,
  }) async {
    final auth = AuthService();
    final atual = await auth.getEmpresaId();
    if (atual == null || (empresa != null && atual != empresa))
      throw StateError('empresa');
    final headers = {
      'Authorization': 'Bearer ${await auth.getAccessToken()}',
      'idUnicoDaEmpresa': atual,
      'Content-Type': 'application/json',
    };
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/private/api/configuracoes/unidades',
    );
    final client = createHttpClient();
    try {
      final response =
          dados == null
              ? await client.get(uri, headers: headers)
              : await client.put(
                uri,
                headers: headers,
                body: jsonEncode(dados),
              );
      if (response.statusCode != 200) throw UnidadeApiErro(response.statusCode);
      return CatalogoUnidades(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      client.close();
    }
  }
}

class UnidadeApiErro implements Exception {
  UnidadeApiErro(this.status);
  final int status;
}
