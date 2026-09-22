/// Configuração de domínio compartilhada. Labels e widgets pertencem à UI.
class AgendaFinanceiraRecorrencia {
  static const frequencias = [
    'DIARIA',
    'SEMANAL',
    'MENSAL',
    'BIMESTRAL',
    'TRIMESTRAL',
    'SEMESTRAL',
    'ANUAL',
  ];
  bool ativa = false;
  String frequencia = 'MENSAL';
  String termino = 'SEM_FIM';
  int quantidade = 12;
  DateTime? fim;
  DateTime? inicioSerie;
  String? serieId;
  String escopo = 'ESTE';

  bool get permiteConfigurar => serieId == null || escopo == 'ESTE_E_PROXIMOS';

  AgendaFinanceiraRecorrencia();

  factory AgendaFinanceiraRecorrencia.fromJson(Map<String, dynamic> json) {
    final config = AgendaFinanceiraRecorrencia();
    config.serieId = json['serieRecorrenciaId']?.toString();
    config.ativa = json['recorrente'] == true || config.serieId != null;
    final codigo = json['frequenciaRecorrencia']?.toString().toUpperCase();
    if (frequencias.contains(codigo)) config.frequencia = codigo!;
    config.inicioSerie = DateTime.tryParse(
      json['recorrenciaInicio']?.toString() ?? '',
    );
    config.fim = DateTime.tryParse(json['recorrenciaFim']?.toString() ?? '');
    final total = int.tryParse(json['quantidadeParcelas']?.toString() ?? '');
    final numero =
        int.tryParse(json['numeroOcorrencia']?.toString() ?? '') ?? 1;
    if (total != null && total > 0) {
      config.termino = 'QUANTIDADE';
      config.quantidade = (total - numero + 1).clamp(1, 10000);
    } else if (config.fim != null) {
      config.termino = 'DATA';
    }
    return config;
  }

  String? validar(DateTime vencimento) {
    if (!ativa || !permiteConfigurar) return null;
    if (termino == 'QUANTIDADE' && (quantidade < 1 || quantidade > 10000))
      return 'quantityError';
    if (termino == 'DATA' &&
        (fim == null || _dia(fim!).isBefore(_dia(vencimento))))
      return 'endError';
    return null;
  }

  Map<String, dynamic> toJson(DateTime vencimento) {
    final inicio =
        !permiteConfigurar ? (inicioSerie ?? vencimento) : vencimento;
    return {
      'recorrente': ativa,
      'frequenciaRecorrencia': ativa ? frequencia : 'NAO_RECORRENTE',
      'recorrenciaInicio': _dia(inicio).toIso8601String(),
      'recorrenciaFim':
          ativa
              ? (termino == 'DATA' ? fim?.toIso8601String() : null)
              : _dia(vencimento).toIso8601String(),
      'quantidadeParcelas':
          ativa ? (termino == 'QUANTIDADE' ? quantidade : null) : 1,
      'diaVencimentoRecorrencia': inicio.day,
    };
  }

  static DateTime _dia(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
