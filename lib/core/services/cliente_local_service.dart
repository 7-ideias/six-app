import 'dart:convert';

import '../../data/models/cliente_cadastro_model.dart';

class ClienteLocalService {
  Future<ClienteLocalResponse> cadastrarCliente(ClienteCadastroRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    return ClienteLocalResponse(
      statusCode: 201,
      body: jsonEncode(<String, dynamic>{
        'ok': true,
        'message': 'Cadastro de cliente salvo localmente (backend ainda não integrado).',
        'data': request.toJson(),
      }),
    );
  }

  Future<ClienteLocalResponse> atualizarCliente(ClienteAtualizacaoRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return ClienteLocalResponse(
      statusCode: 200,
      body: jsonEncode(<String, dynamic>{
        'ok': true,
        'message': 'Atualização de cliente simulada localmente (backend ainda não integrado).',
        'data': request.toJson(),
      }),
    );
  }
}

class ClienteLocalResponse {
  const ClienteLocalResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}
