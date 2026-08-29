enum CriterioQualidadeCadastroColaborador {
  nome,
  email,
  celular,
  permissoes,
  documentos,
  endereco,
  funcao,
  contrato,
  remuneracao,
  pagamento,
}

enum NivelQualidadeCadastroColaborador {
  essencial,
  prontoParaConvidar,
  bemPreparado,
  excelente,
}

class EntradaQualidadeCadastroColaborador {
  const EntradaQualidadeCadastroColaborador({
    required this.nomeInformado,
    required this.emailInformado,
    required this.celularInformado,
    required this.permissoesConfiguradas,
    required this.documentosInformados,
    required this.enderecoInformado,
    required this.funcaoInformada,
    required this.contratoInformado,
    required this.remuneracaoInformada,
    required this.pagamentoInformado,
  });

  final bool nomeInformado;
  final bool emailInformado;
  final bool celularInformado;
  final bool permissoesConfiguradas;
  final bool documentosInformados;
  final bool enderecoInformado;
  final bool funcaoInformada;
  final bool contratoInformado;
  final bool remuneracaoInformada;
  final bool pagamentoInformado;

  bool atende(CriterioQualidadeCadastroColaborador criterio) {
    return switch (criterio) {
      CriterioQualidadeCadastroColaborador.nome => nomeInformado,
      CriterioQualidadeCadastroColaborador.email => emailInformado,
      CriterioQualidadeCadastroColaborador.celular => celularInformado,
      CriterioQualidadeCadastroColaborador.permissoes => permissoesConfiguradas,
      CriterioQualidadeCadastroColaborador.documentos => documentosInformados,
      CriterioQualidadeCadastroColaborador.endereco => enderecoInformado,
      CriterioQualidadeCadastroColaborador.funcao => funcaoInformada,
      CriterioQualidadeCadastroColaborador.contrato => contratoInformado,
      CriterioQualidadeCadastroColaborador.remuneracao => remuneracaoInformada,
      CriterioQualidadeCadastroColaborador.pagamento => pagamentoInformado,
    };
  }
}

class MelhoriaQualidadeCadastroColaborador {
  const MelhoriaQualidadeCadastroColaborador({
    required this.criterio,
    required this.pontos,
  });

  final CriterioQualidadeCadastroColaborador criterio;
  final int pontos;
}

class QualidadeCadastroColaborador {
  const QualidadeCadastroColaborador({
    required this.percentual,
    required this.nivel,
    required this.melhorias,
  });

  final int percentual;
  final NivelQualidadeCadastroColaborador nivel;
  final List<MelhoriaQualidadeCadastroColaborador> melhorias;
}

class ColaboradorCadastroQuality {
  ColaboradorCadastroQuality._();

  static const String tipoSimples = 'SIMPLES';
  static const String tipoCompleto = 'COMPLETO';

  // Centralize os pesos aqui. A soma de cada jornada deve permanecer em 100.
  // Assim, a estratégia de qualidade pode evoluir sem alterar as telas.
  static const Map<CriterioQualidadeCadastroColaborador, int> pesosSimples =
      <CriterioQualidadeCadastroColaborador, int>{
        CriterioQualidadeCadastroColaborador.nome: 30,
        CriterioQualidadeCadastroColaborador.email: 30,
        CriterioQualidadeCadastroColaborador.celular: 20,
        CriterioQualidadeCadastroColaborador.permissoes: 20,
      };

  static const Map<CriterioQualidadeCadastroColaborador, int> pesosCompletos =
      <CriterioQualidadeCadastroColaborador, int>{
        CriterioQualidadeCadastroColaborador.nome: 15,
        CriterioQualidadeCadastroColaborador.email: 15,
        CriterioQualidadeCadastroColaborador.celular: 10,
        CriterioQualidadeCadastroColaborador.permissoes: 10,
        CriterioQualidadeCadastroColaborador.documentos: 10,
        CriterioQualidadeCadastroColaborador.endereco: 5,
        CriterioQualidadeCadastroColaborador.funcao: 10,
        CriterioQualidadeCadastroColaborador.contrato: 10,
        CriterioQualidadeCadastroColaborador.remuneracao: 8,
        CriterioQualidadeCadastroColaborador.pagamento: 7,
      };

  static QualidadeCadastroColaborador calcular({
    required String tipoCadastro,
    required EntradaQualidadeCadastroColaborador entrada,
  }) {
    final Map<CriterioQualidadeCadastroColaborador, int> pesos =
        tipoCadastro.trim().toUpperCase() == tipoCompleto
        ? pesosCompletos
        : pesosSimples;

    int percentual = 0;
    final List<MelhoriaQualidadeCadastroColaborador> melhorias =
        <MelhoriaQualidadeCadastroColaborador>[];

    for (final MapEntry<CriterioQualidadeCadastroColaborador, int> peso
        in pesos.entries) {
      if (entrada.atende(peso.key)) {
        percentual += peso.value;
      } else {
        melhorias.add(
          MelhoriaQualidadeCadastroColaborador(
            criterio: peso.key,
            pontos: peso.value,
          ),
        );
      }
    }

    melhorias.sort(
      (
        MelhoriaQualidadeCadastroColaborador a,
        MelhoriaQualidadeCadastroColaborador b,
      ) => b.pontos.compareTo(a.pontos),
    );

    return QualidadeCadastroColaborador(
      percentual: percentual.clamp(0, 100).toInt(),
      nivel: switch (percentual) {
        >= 90 => NivelQualidadeCadastroColaborador.excelente,
        >= 70 => NivelQualidadeCadastroColaborador.bemPreparado,
        >= 40 => NivelQualidadeCadastroColaborador.prontoParaConvidar,
        _ => NivelQualidadeCadastroColaborador.essencial,
      },
      melhorias: List<MelhoriaQualidadeCadastroColaborador>.unmodifiable(
        melhorias,
      ),
    );
  }
}
