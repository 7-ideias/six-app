class OnboardingInicialModel {
  const OnboardingInicialModel({
    required this.fezOnboardingInicial,
    required this.podeConfigurarEmpresa,
    required this.idiomaPreferencial,
    required this.nomeUsuario,
    required this.nomeEmpresa,
    required this.realizaVendas,
    required this.prestaServicosTecnicos,
  });

  final bool fezOnboardingInicial;
  final bool podeConfigurarEmpresa;
  final String idiomaPreferencial;
  final String nomeUsuario;
  final String nomeEmpresa;
  final bool realizaVendas;
  final bool prestaServicosTecnicos;

  factory OnboardingInicialModel.fromJson(Map<String, dynamic> json) {
    return OnboardingInicialModel(
      fezOnboardingInicial: json['fezOnboardingInicial'] == true,
      podeConfigurarEmpresa: json['podeConfigurarEmpresa'] == true,
      idiomaPreferencial: json['idiomaPreferencial']?.toString() ?? '',
      nomeUsuario: json['nomeUsuario']?.toString() ?? '',
      nomeEmpresa: json['nomeEmpresa']?.toString() ?? '',
      realizaVendas: json['realizaVendas'] == true,
      prestaServicosTecnicos: json['prestaServicosTecnicos'] == true,
    );
  }
}

class ConcluirOnboardingInicialRequest {
  const ConcluirOnboardingInicialRequest({
    required this.idiomaPreferencial,
    required this.nomeUsuario,
    required this.nomeEmpresa,
    required this.realizaVendas,
    required this.prestaServicosTecnicos,
  });

  final String idiomaPreferencial;
  final String nomeUsuario;
  final String nomeEmpresa;
  final bool realizaVendas;
  final bool prestaServicosTecnicos;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'idiomaPreferencial': idiomaPreferencial,
    'nomeUsuario': nomeUsuario,
    'nomeEmpresa': nomeEmpresa,
    'realizaVendas': realizaVendas,
    'prestaServicosTecnicos': prestaServicosTecnicos,
  };
}
