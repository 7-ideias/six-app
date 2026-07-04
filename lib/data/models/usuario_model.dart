import 'package:flutter/foundation.dart';

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
                (preferenciasIndividuaisDoUsuario != null);

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

  static ModoDeExibicaoUsuario? tryFromCodigo(dynamic value) {
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
        return null;
    }
  }

  static ModoDeExibicaoUsuario fromCodigo(
    dynamic value,
    ModoDeExibicaoUsuario fallback,
  ) {
    return tryFromCodigo(value) ?? fallback;
  }
}

class PreferenciasIndividuaisDoUsuarioModel {
  final ModoDeExibicaoUsuario modoDeExibicaoProdutosWeb;
  final ModoDeExibicaoUsuario modoDeExibicaoProdutosMobile;
  final ModoDeExibicaoUsuario modoDeExibicaoServicosWeb;
  final ModoDeExibicaoUsuario modoDeExibicaoServicosMobile;
  final bool ocultarValoresFinanceirosWeb;

  PreferenciasIndividuaisDoUsuarioModel({
    ModoDeExibicaoUsuario? modoDeExibicaoProdutos,
    ModoDeExibicaoUsuario? modoDeExibicaoServicos,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutosWeb,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutosMobile,
    ModoDeExibicaoUsuario? modoDeExibicaoServicosWeb,
    ModoDeExibicaoUsuario? modoDeExibicaoServicosMobile,
    required this.ocultarValoresFinanceirosWeb,
  })  : modoDeExibicaoProdutosWeb = modoDeExibicaoProdutosWeb ??
            modoDeExibicaoProdutos ??
            ModoDeExibicaoUsuario.vertical,
        modoDeExibicaoProdutosMobile = modoDeExibicaoProdutosMobile ??
            modoDeExibicaoProdutos ??
            ModoDeExibicaoUsuario.vertical,
        modoDeExibicaoServicosWeb = modoDeExibicaoServicosWeb ??
            modoDeExibicaoServicos ??
            ModoDeExibicaoUsuario.grade,
        modoDeExibicaoServicosMobile = modoDeExibicaoServicosMobile ??
            modoDeExibicaoServicos ??
            ModoDeExibicaoUsuario.vertical;

  ModoDeExibicaoUsuario get modoDeExibicaoProdutos =>
      kIsWeb ? modoDeExibicaoProdutosWeb : modoDeExibicaoProdutosMobile;

  ModoDeExibicaoUsuario get modoDeExibicaoServicos =>
      kIsWeb ? modoDeExibicaoServicosWeb : modoDeExibicaoServicosMobile;

  factory PreferenciasIndividuaisDoUsuarioModel.padrao() {
    return PreferenciasIndividuaisDoUsuarioModel(
      modoDeExibicaoProdutosWeb: ModoDeExibicaoUsuario.vertical,
      modoDeExibicaoProdutosMobile: ModoDeExibicaoUsuario.vertical,
      modoDeExibicaoServicosWeb: ModoDeExibicaoUsuario.grade,
      modoDeExibicaoServicosMobile: ModoDeExibicaoUsuario.vertical,
      ocultarValoresFinanceirosWeb: false,
    );
  }

  factory PreferenciasIndividuaisDoUsuarioModel.fromJson(dynamic json) {
    final PreferenciasIndividuaisDoUsuarioModel padrao =
        PreferenciasIndividuaisDoUsuarioModel.padrao();

    if (json is! Map<String, dynamic>) {
      return padrao;
    }

    final ModoDeExibicaoUsuario? modoProdutosLegado =
        ModoDeExibicaoUsuarioApi.tryFromCodigo(
      json['modoDeExibicaoProdutos'],
    );
    final ModoDeExibicaoUsuario? modoServicosLegado =
        ModoDeExibicaoUsuarioApi.tryFromCodigo(
      json['modoDeExibicaoServicos'],
    );

    return PreferenciasIndividuaisDoUsuarioModel(
      modoDeExibicaoProdutosWeb:
          ModoDeExibicaoUsuarioApi.tryFromCodigo(
                json['modoDeExibicaoProdutosWeb'],
              ) ??
              modoProdutosLegado ??
              padrao.modoDeExibicaoProdutosWeb,
      modoDeExibicaoProdutosMobile:
          ModoDeExibicaoUsuarioApi.tryFromCodigo(
                json['modoDeExibicaoProdutosMobile'],
              ) ??
              modoProdutosLegado ??
              padrao.modoDeExibicaoProdutosMobile,
      modoDeExibicaoServicosWeb:
          ModoDeExibicaoUsuarioApi.tryFromCodigo(
                json['modoDeExibicaoServicosWeb'],
              ) ??
              modoServicosLegado ??
              padrao.modoDeExibicaoServicosWeb,
      modoDeExibicaoServicosMobile:
          ModoDeExibicaoUsuarioApi.tryFromCodigo(
                json['modoDeExibicaoServicosMobile'],
              ) ??
              modoServicosLegado ??
              padrao.modoDeExibicaoServicosMobile,
      ocultarValoresFinanceirosWeb:
          json['ocultarValoresFinanceirosWeb'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modoDeExibicaoProdutos': modoDeExibicaoProdutos.codigo,
      'modoDeExibicaoServicos': modoDeExibicaoServicos.codigo,
      'modoDeExibicaoProdutosWeb': modoDeExibicaoProdutosWeb.codigo,
      'modoDeExibicaoProdutosMobile': modoDeExibicaoProdutosMobile.codigo,
      'modoDeExibicaoServicosWeb': modoDeExibicaoServicosWeb.codigo,
      'modoDeExibicaoServicosMobile': modoDeExibicaoServicosMobile.codigo,
      'ocultarValoresFinanceirosWeb': ocultarValoresFinanceirosWeb,
    };
  }

  PreferenciasIndividuaisDoUsuarioModel copyWith({
    ModoDeExibicaoUsuario? modoDeExibicaoProdutos,
    ModoDeExibicaoUsuario? modoDeExibicaoServicos,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutosWeb,
    ModoDeExibicaoUsuario? modoDeExibicaoProdutosMobile,
    ModoDeExibicaoUsuario? modoDeExibicaoServicosWeb,
    ModoDeExibicaoUsuario? modoDeExibicaoServicosMobile,
    bool? ocultarValoresFinanceirosWeb,
  }) {
    return PreferenciasIndividuaisDoUsuarioModel(
      modoDeExibicaoProdutosWeb: modoDeExibicaoProdutosWeb ??
          (modoDeExibicaoProdutos != null && kIsWeb
              ? modoDeExibicaoProdutos
              : this.modoDeExibicaoProdutosWeb),
      modoDeExibicaoProdutosMobile: modoDeExibicaoProdutosMobile ??
          (modoDeExibicaoProdutos != null && !kIsWeb
              ? modoDeExibicaoProdutos
              : this.modoDeExibicaoProdutosMobile),
      modoDeExibicaoServicosWeb: modoDeExibicaoServicosWeb ??
          (modoDeExibicaoServicos != null && kIsWeb
              ? modoDeExibicaoServicos
              : this.modoDeExibicaoServicosWeb),
      modoDeExibicaoServicosMobile: modoDeExibicaoServicosMobile ??
          (modoDeExibicaoServicos != null && !kIsWeb
              ? modoDeExibicaoServicos
              : this.modoDeExibicaoServicosMobile),
      ocultarValoresFinanceirosWeb:
          ocultarValoresFinanceirosWeb ?? this.ocultarValoresFinanceirosWeb,
    );
  }
}
