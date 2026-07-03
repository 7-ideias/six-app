class UsuarioModel {
  final String nome;
  final String sobrenome;
  final String cpf;
  final String registroProfissional;
  final String email;
  final String nomeDeGuerra;
  final String celular;
  final String senha;
  final String salt;
  final String rg;
  final String dataNascimento;
  final EnderecoModel? objEndereco;
  final PreferenciasIndividuaisDoUsuarioModel preferenciasIndividuaisDoUsuario;
  final bool enviarPreferenciasIndividuaisDoUsuario;

  UsuarioModel({
    required this.nome,
    required this.sobrenome,
    required this.cpf,
    required this.registroProfissional,
    required this.email,
    this.nomeDeGuerra = '',
    this.celular = '',
    this.senha = '',
    this.salt = '',
    this.rg = '',
    this.dataNascimento = '',
    this.objEndereco,
    PreferenciasIndividuaisDoUsuarioModel? preferenciasIndividuaisDoUsuario,
    bool? enviarPreferenciasIndividuaisDoUsuario,
  })  : preferenciasIndividuaisDoUsuario = preferenciasIndividuaisDoUsuario ??
            PreferenciasIndividuaisDoUsuarioModel.padrao(),
        enviarPreferenciasIndividuaisDoUsuario =
            enviarPreferenciasIndividuaisDoUsuario ??
                preferenciasIndividuaisDoUsuario != null;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      nome: json['nome'] ?? '',
      sobrenome: json['sobrenome'] ?? '',
      cpf: json['cpf'] ?? '',
      registroProfissional: json['registroProfissional'] ?? '',
      email: json['email'] ?? '',
      nomeDeGuerra: json['nomeDeGuerra'] ?? '',
      celular: json['celular'] ?? '',
      senha: json['senha'] ?? '',
      salt: json['salt'] ?? '',
      rg: json['rg'] ?? '',
      dataNascimento: json['dataNascimento'] ?? '',
      objEndereco: json['objEndereco'] != null
          ? EnderecoModel.fromJson(json['objEndereco'])
          : null,
      preferenciasIndividuaisDoUsuario:
          PreferenciasIndividuaisDoUsuarioModel.fromJson(
        json['preferenciasIndividuaisDoUsuario'],
      ),
      enviarPreferenciasIndividuaisDoUsuario: true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'nome': nome,
      'sobrenome': sobrenome,
      'cpf': cpf,
      'registroProfissional': registroProfissional,
      'email': email,
      'nomeDeGuerra': nomeDeGuerra,
      'celular': celular,
      'senha': senha,
      'salt': salt,
      'rg': rg,
      'dataNascimento': dataNascimento,
      'objEndereco': objEndereco?.toJson(),
    };

    if (enviarPreferenciasIndividuaisDoUsuario) {
      json['preferenciasIndividuaisDoUsuario'] =
          preferenciasIndividuaisDoUsuario.toJson();
    }

    return json;
  }
}

class EnderecoModel {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;

  EnderecoModel({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  factory EnderecoModel.fromJson(Map<String, dynamic> json) {
    return EnderecoModel(
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      complemento: json['complemento'] ?? '',
      bairro: json['bairro'] ?? '',
      localidade: json['localidade'] ?? '',
      uf: json['uf'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cep': cep,
      'logradouro': logradouro,
      'complemento': complemento,
      'bairro': bairro,
      'localidade': localidade,
      'uf': uf,
    };
  }
}

enum ModoDeExibicaoUsuario {
  horizontal,
  vertical,
  grade,
  lista,
}

extension ModoDeExibicaoUsuarioApi on ModoDeExibicaoUsuario {
  String get codigo {
    switch (this) {
      case ModoDeExibicaoUsuario.horizontal:
        return 'HORIZONTAL';
      case ModoDeExibicaoUsuario.vertical:
        return 'VERTICAL';
      case ModoDeExibicaoUsuario.grade:
        return 'GRADE';
      case ModoDeExibicaoUsuario.lista:
        return 'LISTA';
    }
  }

  static ModoDeExibicaoUsuario fromCodigo(dynamic value, ModoDeExibicaoUsuario fallback) {
    final String codigo = value?.toString().toUpperCase() ?? '';
    switch (codigo) {
      case 'HORIZONTAL':
        return ModoDeExibicaoUsuario.horizontal;
      case 'VERTICAL':
        return ModoDeExibicaoUsuario.vertical;
      case 'GRADE':
        return ModoDeExibicaoUsuario.grade;
      case 'LISTA':
        return ModoDeExibicaoUsuario.lista;
      default:
        return fallback;
    }
  }
}

class PreferenciasIndividuaisDoUsuarioModel {
  final ModoDeExibicaoUsuario modoDeExibicaoProdutos;
  final ModoDeExibicaoUsuario modoDeExibicaoServicos;
  final bool ocultarValoresFinanceirosWeb;

  PreferenciasIndividuaisDoUsuarioModel({
    required this.modoDeExibicaoProdutos,
    required this.modoDeExibicaoServicos,
    required this.ocultarValoresFinanceirosWeb,
  });

  factory PreferenciasIndividuaisDoUsuarioModel.padrao() {
    return PreferenciasIndividuaisDoUsuarioModel(
      modoDeExibicaoProdutos: ModoDeExibicaoUsuario.horizontal,
      modoDeExibicaoServicos: ModoDeExibicaoUsuario.grade,
      ocultarValoresFinanceirosWeb: false,
    );
  }

  factory PreferenciasIndividuaisDoUsuarioModel.fromJson(dynamic json) {
    final PreferenciasIndividuaisDoUsuarioModel padrao =
        PreferenciasIndividuaisDoUsuarioModel.padrao();

    if (json is! Map<String, dynamic>) {
      return padrao;
    }

    return PreferenciasIndividuaisDoUsuarioModel(
      modoDeExibicaoProdutos: ModoDeExibicaoUsuarioApi.fromCodigo(
        json['modoDeExibicaoProdutos'],
        padrao.modoDeExibicaoProdutos,
      ),
      modoDeExibicaoServicos: ModoDeExibicaoUsuarioApi.fromCodigo(
        json['modoDeExibicaoServicos'],
        padrao.modoDeExibicaoServicos,
      ),
      ocultarValoresFinanceirosWeb:
          json['ocultarValoresFinanceirosWeb'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modoDeExibicaoProdutos': modoDeExibicaoProdutos.codigo,
      'modoDeExibicaoServicos': modoDeExibicaoServicos.codigo,
      'ocultarValoresFinanceirosWeb': ocultarValoresFinanceirosWeb,
    };
  }

  PreferenciasIndividuaisDoUsuarioModel copyWith({
    ModoDeExibicaoUsuario? modoDeExibicaoProdutos,
    ModoDeExibicaoUsuario? modoDeExibicaoServicos,
    bool? ocultarValoresFinanceirosWeb,
  }) {
    return PreferenciasIndividuaisDoUsuarioModel(
      modoDeExibicaoProdutos:
          modoDeExibicaoProdutos ?? this.modoDeExibicaoProdutos,
      modoDeExibicaoServicos:
          modoDeExibicaoServicos ?? this.modoDeExibicaoServicos,
      ocultarValoresFinanceirosWeb:
          ocultarValoresFinanceirosWeb ?? this.ocultarValoresFinanceirosWeb,
    );
  }
}
