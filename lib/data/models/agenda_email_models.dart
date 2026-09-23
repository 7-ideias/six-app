import 'dart:convert';
import 'package:http/http.dart' as http;

class AgendaEmailDestino {
  const AgendaEmailDestino({
    required this.idEmpresa,
    required this.nomeEmpresa,
    required this.email,
  });
  final String idEmpresa;
  final String nomeEmpresa;
  final String email;
  factory AgendaEmailDestino.fromJson(Map<String, dynamic> json) =>
      AgendaEmailDestino(
        idEmpresa: json['idEmpresa'] as String,
        nomeEmpresa: json['nomeEmpresa'] as String,
        email: json['email'] as String,
      );
}

class AgendaEmailResultado {
  const AgendaEmailResultado({required this.idEnvio, required this.status});
  final String idEnvio;
  final String status;
  factory AgendaEmailResultado.fromJson(Map<String, dynamic> json) =>
      AgendaEmailResultado(
        idEnvio: json['idEnvio'] as String,
        status: json['status'] as String,
      );
}

class AgendaEmailException implements Exception {
  const AgendaEmailException(this.codigo);
  final String codigo;
  factory AgendaEmailException.fromResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return const AgendaEmailException('PERMISSAO_NEGADA');
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['codigo'] is String) {
        return AgendaEmailException(decoded['codigo'] as String);
      }
    } catch (_) {
      /* Never expose the raw response. */
    }
    return const AgendaEmailException('FALHA');
  }
}
