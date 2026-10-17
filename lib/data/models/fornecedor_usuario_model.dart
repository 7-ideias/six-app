class FornecedorUsuario {
  const FornecedorUsuario({
    required this.id,
    required this.idUnicoDaEmpresa,
    required this.ativo,
    required this.tipoPessoa,
    required this.nome,
    required this.documento,
    required this.telefone,
    required this.email,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.pais,
    required this.contatoResponsavel,
    required this.condicoesPagamento,
    required this.observacoes,
  });

  final String id, idUnicoDaEmpresa, tipoPessoa, nome, documento, telefone,
      email, cep, logradouro, numero, complemento, bairro, cidade, uf, pais,
      contatoResponsavel, condicoesPagamento, observacoes;
  final bool ativo;

  factory FornecedorUsuario.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key]?.toString() ?? '';
    return FornecedorUsuario(
      id: text('id'),
      idUnicoDaEmpresa: text('idUnicoDaEmpresa'),
      ativo: json['ativo'] == true || json['ativo'] == 'true',
      tipoPessoa: text('tipoPessoa'),
      nome: text('nome'),
      documento: text('documento'),
      telefone: text('telefone'),
      email: text('email'),
      cep: text('cep'),
      logradouro: text('logradouro'),
      numero: text('numero'),
      complemento: text('complemento'),
      bairro: text('bairro'),
      cidade: text('cidade'),
      uf: text('uf'),
      pais: text('pais'),
      contatoResponsavel: text('contatoResponsavel'),
      condicoesPagamento: text('condicoesPagamento'),
      observacoes: text('observacoes'),
    );
  }
}

class FornecedorUsuarioDraft {
  const FornecedorUsuarioDraft({
    required this.ativo,
    required this.tipoPessoa,
    required this.nome,
    required this.documento,
    required this.telefone,
    required this.email,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.pais,
    required this.contatoResponsavel,
    required this.condicoesPagamento,
    required this.observacoes,
  });

  final bool ativo;
  final String tipoPessoa, nome, documento, telefone, email, cep, logradouro,
      numero, complemento, bairro, cidade, uf, pais, contatoResponsavel,
      condicoesPagamento, observacoes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ativo': ativo,
    'tipoPessoa': tipoPessoa,
    'nome': nome.trim(),
    'documento': documento.trim(),
    'telefone': telefone.trim(),
    'email': email.trim(),
    'cep': cep.trim(),
    'logradouro': logradouro.trim(),
    'numero': numero.trim(),
    'complemento': complemento.trim(),
    'bairro': bairro.trim(),
    'cidade': cidade.trim(),
    'uf': uf.trim(),
    'pais': pais.trim(),
    'contatoResponsavel': contatoResponsavel.trim(),
    'condicoesPagamento': condicoesPagamento.trim(),
    'observacoes': observacoes.trim(),
  };
}
