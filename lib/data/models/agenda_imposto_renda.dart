import 'dart:convert';
import 'dart:typed_data';

class AgendaComprovanteIr {
  AgendaComprovanteIr({required this.nome, required this.conteudoBase64});
  final String nome;
  final String conteudoBase64;
  Uint8List get bytes => base64Decode(conteudoBase64);
  Map<String, dynamic> toJson() => {
    'nome': nome,
    'conteudoBase64': conteudoBase64,
  };

  static bool imagemValida(Uint8List b) {
    if (b.length < 3 || b.length > 2 * 1024 * 1024) return false;
    if (b[0] == 255 && b[1] == 216 && b[2] == 255) return true;
    if (b.length >= 8 && base64Encode(b.sublist(0, 8)) == 'iVBORw0KGgo=')
      return true;
    return b.length >= 12 &&
        String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(b.sublist(8, 12)) == 'WEBP';
  }
}

class AgendaImpostoRenda {
  bool marcado = false;
  bool carregando = false;
  final List<AgendaComprovanteIr> comprovantes = [];

  AgendaImpostoRenda();
  factory AgendaImpostoRenda.fromJson(Map<String, dynamic> json) {
    final edicao = json['dadosEdicao'];
    final campos =
        edicao is Map ? {...json, ...Map<String, dynamic>.from(edicao)} : json;
    final result =
        AgendaImpostoRenda()..marcado = campos['separarImpostoRenda'] == true;
    final arquivos = campos['comprovantesImpostoRenda'];
    if (arquivos is List) {
      for (final arquivo in arquivos.whereType<Map>()) {
        result.comprovantes.add(
          AgendaComprovanteIr(
            nome: arquivo['nome']?.toString() ?? '',
            conteudoBase64: arquivo['conteudoBase64']?.toString() ?? '',
          ),
        );
      }
    }
    return result;
  }

  Map<String, dynamic> toPayload() => {
    'atualizarImpostoRenda': true,
    'separarImpostoRenda': marcado,
    'comprovantesImpostoRenda': comprovantes.map((e) => e.toJson()).toList(),
  };
}
