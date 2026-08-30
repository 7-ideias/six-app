import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'http_client_factory.dart';

class AutoCustomerPublicCompany {
  const AutoCustomerPublicCompany({
    required this.nomeEmpresa,
    required this.nomeFantasia,
    required this.telefone,
    required this.whatsapp,
    required this.email,
    required this.site,
    required this.endereco,
    required this.logoBase64,
  });

  final String nomeEmpresa;
  final String nomeFantasia;
  final String telefone;
  final String whatsapp;
  final String email;
  final String site;
  final String endereco;
  final String logoBase64;

  factory AutoCustomerPublicCompany.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> data = json ?? <String, dynamic>{};
    return AutoCustomerPublicCompany(
      nomeEmpresa: _string(data['nomeEmpresa']),
      nomeFantasia: _string(data['nomeFantasia']),
      telefone: _string(data['telefone']),
      whatsapp: _string(data['whatsapp']),
      email: _string(data['email']),
      site: _string(data['site']),
      endereco: _string(data['endereco']),
      logoBase64: _string(data['logoBase64']),
    );
  }
}

class AutoCustomerPublicCustomer {
  const AutoCustomerPublicCustomer({
    required this.tipoCadastro,
    required this.percentualQualidadeCadastro,
    required this.tipoPessoa,
    required this.documento,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.enderecoCompleto,
    required this.observacoes,
  });

  final String tipoCadastro;
  final int percentualQualidadeCadastro;
  final String tipoPessoa;
  final String documento;
  final String nome;
  final String telefone;
  final String email;
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String enderecoCompleto;
  final String observacoes;

  factory AutoCustomerPublicCustomer.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> data = json ?? <String, dynamic>{};
    return AutoCustomerPublicCustomer(
      tipoCadastro: _normalizedTipoCadastro(data['tipoCadastro']),
      percentualQualidadeCadastro:
          _intValue(data['percentualQualidadeCadastro']).clamp(0, 100).toInt(),
      tipoPessoa: _normalizedTipoPessoa(data['tipoPessoa']),
      documento: _string(data['documento']),
      nome: _string(data['nome']),
      telefone: _string(data['telefone']),
      email: _string(data['email']),
      cep: _string(data['cep']),
      logradouro: _string(data['logradouro']),
      numero: _string(data['numero']),
      complemento: _string(data['complemento']),
      bairro: _string(data['bairro']),
      cidade: _string(data['cidade']),
      uf: _string(data['uf']).toUpperCase(),
      enderecoCompleto: _string(data['enderecoCompleto']),
      observacoes: _string(data['observacoes']),
    );
  }

  bool get hasDetailedData =>
      tipoCadastro == 'COMPLETO' ||
      <String>[
        cep,
        logradouro,
        numero,
        complemento,
        bairro,
        cidade,
        uf,
        observacoes,
      ].any((String value) => value.trim().isNotEmpty);
}

class AutoCustomerPublicResponse {
  const AutoCustomerPublicResponse({
    required this.statusCode,
    required this.body,
    required this.status,
    required this.code,
    required this.message,
    required this.company,
    required this.customer,
  });

  final int statusCode;
  final String body;
  final String status;
  final String code;
  final String message;
  final AutoCustomerPublicCompany? company;
  final AutoCustomerPublicCustomer? customer;

  factory AutoCustomerPublicResponse.fromHttpResponse(http.Response response) {
    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      try {
        final Object json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          decoded = json;
        }
      } catch (_) {}
    }

    return AutoCustomerPublicResponse(
      statusCode: response.statusCode,
      body: response.body,
      status: _string(decoded['status']),
      code: _string(decoded['code']),
      message: _string(decoded['message'] ?? decoded['mensagem']),
      company:
          decoded['empresa'] is Map<String, dynamic>
              ? AutoCustomerPublicCompany.fromJson(
                decoded['empresa'] as Map<String, dynamic>,
              )
              : null,
      customer:
          decoded['cliente'] is Map<String, dynamic>
              ? AutoCustomerPublicCustomer.fromJson(
                decoded['cliente'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class AutoCustomerPublicService {
  AutoCustomerPublicService({http.Client? client})
    : _client = client ?? createHttpClient();

  final http.Client _client;

  Uri get _endpoint =>
      Uri.parse('${AppConfig.baseUrl}/public/api/auto-customer');

  Future<AutoCustomerPublicResponse> validarToken({
    required String idUnicoDaEmpresa,
    required String token,
    String? documento,
  }) async {
    final Map<String, String> queryParameters = <String, String>{
      'idUnicoDaEmpresa': idUnicoDaEmpresa,
      'token': token,
    };
    final String documentoNormalizado = (documento ?? '').trim();
    if (documentoNormalizado.isNotEmpty) {
      queryParameters['doc'] = documentoNormalizado;
    }

    final Uri endpoint = Uri.parse(
      '${AppConfig.baseUrl}/public/api/auto-customer/token',
    ).replace(queryParameters: queryParameters);

    final http.Response response = await _client.get(
      endpoint,
      headers: <String, String>{'idUnicoDaEmpresa': idUnicoDaEmpresa},
    );

    return AutoCustomerPublicResponse.fromHttpResponse(response);
  }

  Future<AutoCustomerPublicResponse> enviarAutoCadastro({
    required String idUnicoDaEmpresa,
    required String token,
    required String documentoOriginal,
    required String tipoPessoa,
    required String tipoCadastro,
    required int percentualQualidadeCadastro,
    required String documento,
    required String nome,
    required String telefone,
    required String email,
    required String cep,
    required String logradouro,
    required String numero,
    required String complemento,
    required String bairro,
    required String cidade,
    required String uf,
    required String observacoes,
    required String origem,
  }) async {
    final String normalizedTipoCadastro = _normalizedTipoCadastro(tipoCadastro);
    final String normalizedUf = uf.trim().toUpperCase();
    final Map<String, dynamic> payload = <String, dynamic>{
      'idUnicoDaEmpresa': idUnicoDaEmpresa,
      'token': token,
      'documentoOriginal': documentoOriginal.trim(),
      'tipoCadastro': normalizedTipoCadastro,
      'percentualQualidadeCadastro': percentualQualidadeCadastro.clamp(0, 100),
      'tipoPessoa': _normalizedTipoPessoa(tipoPessoa),
      'documento': documento.trim(),
      'nome': nome.trim(),
      'telefone': telefone.trim(),
      'email': email.trim().toLowerCase(),
      'cep': cep.trim(),
      'logradouro': logradouro.trim(),
      'numero': numero.trim(),
      'complemento': complemento.trim(),
      'bairro': bairro.trim(),
      'cidade': cidade.trim(),
      'uf': normalizedUf,
      'enderecoCompleto': _buildEnderecoCompleto(
        logradouro: logradouro,
        numero: numero,
        complemento: complemento,
        bairro: bairro,
        cidade: cidade,
        uf: normalizedUf,
        cep: cep,
      ),
      'observacoes': observacoes.trim(),
      'origem': origem.trim(),
      'enviadoEm': DateTime.now().toUtc().toIso8601String(),
    };

    final http.Response response = await _client.post(
      _endpoint,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'idUnicoDaEmpresa': idUnicoDaEmpresa,
      },
      body: jsonEncode(payload),
    );

    return AutoCustomerPublicResponse.fromHttpResponse(response);
  }
}

String _buildEnderecoCompleto({
  required String logradouro,
  required String numero,
  required String complemento,
  required String bairro,
  required String cidade,
  required String uf,
  required String cep,
}) {
  return <String>[logradouro, numero, complemento, bairro, cidade, uf, cep]
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .join(', ');
}

String _string(Object? value) => value?.toString().trim() ?? '';

String _normalizedTipoPessoa(Object? value) =>
    _string(value).toUpperCase() == 'PJ' ? 'PJ' : 'PF';

String _normalizedTipoCadastro(Object? value) =>
    _string(value).toUpperCase() == 'COMPLETO' ? 'COMPLETO' : 'SIMPLES';

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
