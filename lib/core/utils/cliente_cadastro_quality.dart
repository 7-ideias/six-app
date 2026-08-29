enum CriterioQualidadeCadastroCliente {
  nome,
  documento,
  telefone,
  email,
  cep,
  endereco,
  credito,
  observacoes,
}

enum NivelQualidadeCadastroCliente {
  inicial,
  essencial,
  bemDetalhado,
  excelente,
}

class EntradaQualidadeCadastroCliente {
  const EntradaQualidadeCadastroCliente({
    required this.nomeInformado,
    required this.documentoInformado,
    required this.telefoneInformado,
    required this.emailInformado,
    required this.cepInformado,
    required this.enderecoInformado,
    required this.creditoConfigurado,
    required this.observacoesInformadas,
  });

  final bool nomeInformado;
  final bool documentoInformado;
  final bool telefoneInformado;
  final bool emailInformado;
  final bool cepInformado;
  final bool enderecoInformado;
  final bool creditoConfigurado;
  final bool observacoesInformadas;

  bool atende(CriterioQualidadeCadastroCliente criterio) => switch (criterio) {
    CriterioQualidadeCadastroCliente.nome => nomeInformado,
    CriterioQualidadeCadastroCliente.documento => documentoInformado,
    CriterioQualidadeCadastroCliente.telefone => telefoneInformado,
    CriterioQualidadeCadastroCliente.email => emailInformado,
    CriterioQualidadeCadastroCliente.cep => cepInformado,
    CriterioQualidadeCadastroCliente.endereco => enderecoInformado,
    CriterioQualidadeCadastroCliente.credito => creditoConfigurado,
    CriterioQualidadeCadastroCliente.observacoes => observacoesInformadas,
  };
}

class MelhoriaQualidadeCadastroCliente {
  const MelhoriaQualidadeCadastroCliente({
    required this.criterio,
    required this.pontos,
  });

  final CriterioQualidadeCadastroCliente criterio;
  final int pontos;
}

class QualidadeCadastroCliente {
  const QualidadeCadastroCliente({
    required this.percentual,
    required this.nivel,
    required this.melhorias,
  });

  final int percentual;
  final NivelQualidadeCadastroCliente nivel;
  final List<MelhoriaQualidadeCadastroCliente> melhorias;
}

class ClienteCadastroQuality {
  ClienteCadastroQuality._();

  static const String tipoSimples = 'SIMPLES';
  static const String tipoCompleto = 'COMPLETO';

  // Pesos centralizados para ajustes futuros sem alterar Web e Mobile.
  static const Map<CriterioQualidadeCadastroCliente, int> pesosSimples =
      <CriterioQualidadeCadastroCliente, int>{
        CriterioQualidadeCadastroCliente.nome: 35,
        CriterioQualidadeCadastroCliente.documento: 30,
        CriterioQualidadeCadastroCliente.telefone: 20,
        CriterioQualidadeCadastroCliente.email: 15,
      };

  static const Map<CriterioQualidadeCadastroCliente, int> pesosCompletos =
      <CriterioQualidadeCadastroCliente, int>{
        CriterioQualidadeCadastroCliente.nome: 15,
        CriterioQualidadeCadastroCliente.documento: 15,
        CriterioQualidadeCadastroCliente.telefone: 10,
        CriterioQualidadeCadastroCliente.email: 10,
        CriterioQualidadeCadastroCliente.cep: 10,
        CriterioQualidadeCadastroCliente.endereco: 20,
        CriterioQualidadeCadastroCliente.credito: 15,
        CriterioQualidadeCadastroCliente.observacoes: 5,
      };

  static QualidadeCadastroCliente calcular({
    required String tipoCadastro,
    required EntradaQualidadeCadastroCliente entrada,
  }) {
    final Map<CriterioQualidadeCadastroCliente, int> pesos =
        tipoCadastro == tipoCompleto ? pesosCompletos : pesosSimples;
    int percentual = 0;
    final List<MelhoriaQualidadeCadastroCliente> melhorias =
        <MelhoriaQualidadeCadastroCliente>[];

    for (final MapEntry<CriterioQualidadeCadastroCliente, int> peso
        in pesos.entries) {
      if (entrada.atende(peso.key)) {
        percentual += peso.value;
      } else {
        melhorias.add(
          MelhoriaQualidadeCadastroCliente(
            criterio: peso.key,
            pontos: peso.value,
          ),
        );
      }
    }

    melhorias.sort(
      (
        MelhoriaQualidadeCadastroCliente a,
        MelhoriaQualidadeCadastroCliente b,
      ) => b.pontos.compareTo(a.pontos),
    );

    return QualidadeCadastroCliente(
      percentual: percentual.clamp(0, 100).toInt(),
      nivel: switch (percentual) {
        >= 90 => NivelQualidadeCadastroCliente.excelente,
        >= 70 => NivelQualidadeCadastroCliente.bemDetalhado,
        >= 40 => NivelQualidadeCadastroCliente.essencial,
        _ => NivelQualidadeCadastroCliente.inicial,
      },
      melhorias: List<MelhoriaQualidadeCadastroCliente>.unmodifiable(melhorias),
    );
  }
}
