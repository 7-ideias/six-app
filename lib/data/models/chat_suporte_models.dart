import 'dart:typed_data';

enum ChatSuporteStatus {
  aguardandoSuporte,
  emAtendimento,
  encerrada;

  static ChatSuporteStatus fromApi(dynamic value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'EM_ATENDIMENTO' => ChatSuporteStatus.emAtendimento,
      'ENCERRADA' => ChatSuporteStatus.encerrada,
      _ => ChatSuporteStatus.aguardandoSuporte,
    };
  }

  String get apiValue => switch (this) {
    ChatSuporteStatus.aguardandoSuporte => 'AGUARDANDO_SUPORTE',
    ChatSuporteStatus.emAtendimento => 'EM_ATENDIMENTO',
    ChatSuporteStatus.encerrada => 'ENCERRADA',
  };
}

enum ChatSuporteRemetenteTipo {
  usuario,
  superUsuario;

  static ChatSuporteRemetenteTipo fromApi(dynamic value) {
    return value?.toString().trim().toUpperCase() == 'SUPER'
        ? ChatSuporteRemetenteTipo.superUsuario
        : ChatSuporteRemetenteTipo.usuario;
  }
}

enum ChatSuporteMensagemTipo {
  texto,
  imagem,
  textoEImagem;

  static ChatSuporteMensagemTipo fromApi(dynamic value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'IMAGEM' => ChatSuporteMensagemTipo.imagem,
      'TEXTO_E_IMAGEM' => ChatSuporteMensagemTipo.textoEImagem,
      _ => ChatSuporteMensagemTipo.texto,
    };
  }
}

class ChatSuporteConversaModel {
  const ChatSuporteConversaModel({
    required this.id,
    required this.idUnicoDaEmpresa,
    required this.nomeEmpresa,
    required this.idSolicitante,
    required this.nomeSolicitante,
    required this.status,
    required this.criadaEm,
    required this.atualizadaEm,
    required this.naoLidasPeloSuporte,
    required this.naoLidasPeloSolicitante,
    required this.retencaoDias,
    this.emailSolicitante,
    this.idSuperResponsavel,
    this.nomeSuperResponsavel,
    this.ultimaMensagemEm,
    this.ultimoRemetenteTipo,
  });

  final String id;
  final String idUnicoDaEmpresa;
  final String nomeEmpresa;
  final String idSolicitante;
  final String nomeSolicitante;
  final String? emailSolicitante;
  final ChatSuporteStatus status;
  final String? idSuperResponsavel;
  final String? nomeSuperResponsavel;
  final DateTime criadaEm;
  final DateTime atualizadaEm;
  final DateTime? ultimaMensagemEm;
  final ChatSuporteRemetenteTipo? ultimoRemetenteTipo;
  final int naoLidasPeloSuporte;
  final int naoLidasPeloSolicitante;
  final int retencaoDias;

  factory ChatSuporteConversaModel.fromJson(Map<String, dynamic> json) {
    return ChatSuporteConversaModel(
      id: _text(json['id']),
      idUnicoDaEmpresa: _text(json['idUnicoDaEmpresa']),
      nomeEmpresa: _text(json['nomeEmpresa'], fallback: 'Comércio'),
      idSolicitante: _text(json['idSolicitante']),
      nomeSolicitante: _text(json['nomeSolicitante'], fallback: 'Usuário Sixo'),
      emailSolicitante: _nullableText(json['emailSolicitante']),
      status: ChatSuporteStatus.fromApi(json['status']),
      idSuperResponsavel: _nullableText(json['idSuperResponsavel']),
      nomeSuperResponsavel: _nullableText(json['nomeSuperResponsavel']),
      criadaEm: _date(json['criadaEm']) ?? DateTime.now(),
      atualizadaEm: _date(json['atualizadaEm']) ?? DateTime.now(),
      ultimaMensagemEm: _date(json['ultimaMensagemEm']),
      ultimoRemetenteTipo: json['ultimoRemetenteTipo'] == null
          ? null
          : ChatSuporteRemetenteTipo.fromApi(json['ultimoRemetenteTipo']),
      naoLidasPeloSuporte: _integer(json['naoLidasPeloSuporte']),
      naoLidasPeloSolicitante: _integer(json['naoLidasPeloSolicitante']),
      retencaoDias: _integer(json['retencaoDias'], fallback: 30),
    );
  }
}

class ChatSuporteArquivoModel {
  const ChatSuporteArquivoModel({
    required this.id,
    required this.nomeArquivo,
    required this.contentType,
    required this.tamanhoBytes,
  });

  final String id;
  final String nomeArquivo;
  final String contentType;
  final int tamanhoBytes;

  factory ChatSuporteArquivoModel.fromJson(Map<String, dynamic> json) {
    return ChatSuporteArquivoModel(
      id: _text(json['id']),
      nomeArquivo: _text(json['nomeArquivo'], fallback: 'imagem'),
      contentType: _text(json['contentType'], fallback: 'image/jpeg'),
      tamanhoBytes: _integer(json['tamanhoBytes']),
    );
  }
}

class ChatSuporteMensagemModel {
  const ChatSuporteMensagemModel({
    required this.id,
    required this.idConversa,
    required this.idRemetente,
    required this.nomeRemetente,
    required this.remetenteTipo,
    required this.tipo,
    required this.arquivos,
    required this.criadaEm,
    required this.expiraEm,
    this.texto,
    this.lidaPeloSuporteEm,
    this.lidaPeloSolicitanteEm,
  });

  final String id;
  final String idConversa;
  final String idRemetente;
  final String nomeRemetente;
  final ChatSuporteRemetenteTipo remetenteTipo;
  final ChatSuporteMensagemTipo tipo;
  final String? texto;
  final List<ChatSuporteArquivoModel> arquivos;
  final DateTime criadaEm;
  final DateTime? lidaPeloSuporteEm;
  final DateTime? lidaPeloSolicitanteEm;
  final DateTime expiraEm;

  factory ChatSuporteMensagemModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawArquivos = json['arquivos'];
    return ChatSuporteMensagemModel(
      id: _text(json['id']),
      idConversa: _text(json['idConversa']),
      idRemetente: _text(json['idRemetente']),
      nomeRemetente: _text(json['nomeRemetente'], fallback: 'SixoApp'),
      remetenteTipo: ChatSuporteRemetenteTipo.fromApi(json['remetenteTipo']),
      tipo: ChatSuporteMensagemTipo.fromApi(json['tipo']),
      texto: _nullableText(json['texto']),
      arquivos: rawArquivos is List
          ? rawArquivos
                .whereType<Map>()
                .map(
                  (Map<dynamic, dynamic> value) =>
                      ChatSuporteArquivoModel.fromJson(
                        Map<String, dynamic>.from(value),
                      ),
                )
                .toList(growable: false)
          : const <ChatSuporteArquivoModel>[],
      criadaEm: _date(json['criadaEm']) ?? DateTime.now(),
      lidaPeloSuporteEm: _date(json['lidaPeloSuporteEm']),
      lidaPeloSolicitanteEm: _date(json['lidaPeloSolicitanteEm']),
      expiraEm:
          _date(json['expiraEm']) ??
          DateTime.now().add(const Duration(days: 30)),
    );
  }
}

class ChatSuporteMensagensPageModel {
  const ChatSuporteMensagensPageModel({
    required this.mensagens,
    required this.possuiMais,
    this.proximoAntesDe,
  });

  final List<ChatSuporteMensagemModel> mensagens;
  final bool possuiMais;
  final DateTime? proximoAntesDe;

  factory ChatSuporteMensagensPageModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawMensagens = json['mensagens'];
    return ChatSuporteMensagensPageModel(
      mensagens: rawMensagens is List
          ? rawMensagens
                .whereType<Map>()
                .map(
                  (Map<dynamic, dynamic> value) =>
                      ChatSuporteMensagemModel.fromJson(
                        Map<String, dynamic>.from(value),
                      ),
                )
                .toList(growable: false)
          : const <ChatSuporteMensagemModel>[],
      possuiMais: json['possuiMais'] == true,
      proximoAntesDe: _date(json['proximoAntesDe']),
    );
  }
}

class ChatSuporteEnvioMensagemModel {
  const ChatSuporteEnvioMensagemModel({
    required this.conversa,
    required this.mensagem,
  });

  final ChatSuporteConversaModel conversa;
  final ChatSuporteMensagemModel mensagem;

  factory ChatSuporteEnvioMensagemModel.fromJson(Map<String, dynamic> json) {
    return ChatSuporteEnvioMensagemModel(
      conversa: ChatSuporteConversaModel.fromJson(
        Map<String, dynamic>.from(json['conversa'] as Map),
      ),
      mensagem: ChatSuporteMensagemModel.fromJson(
        Map<String, dynamic>.from(json['mensagem'] as Map),
      ),
    );
  }
}

class ChatSuporteImagemUpload {
  const ChatSuporteImagemUpload({
    required this.nomeArquivo,
    required this.dados,
  });

  final String nomeArquivo;
  final Uint8List dados;
}

String _text(dynamic value, {String fallback = ''}) {
  final String text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(dynamic value) {
  final String text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _integer(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _date(dynamic value) {
  final DateTime? parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed?.toLocal();
}
