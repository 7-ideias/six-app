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
  });

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'sobrenome': sobrenome,
      'cpf': cpf,
      'registroProfissional': registroProfissional,
      'email': email,
      'nomeDeGuerra': nomeDeGuerra,
      'celular': celular,
      'senha': senha,
      'salt': salt,
      'cpf': cpf, // Note: O CURL repete CPF no body
      'rg': rg,
      'dataNascimento': dataNascimento,
      'email': email,
      'objEndereco': objEndereco?.toJson(),
    };
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
