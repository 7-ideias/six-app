class ServicoDashboardModel {
  final int totalServicos;
  final int servicosAtivos;
  final double precoMedio;
  final int servicosSemPreco;
  final int servicosComGarantia;
  final int servicosSemGarantia;
  final int servicosValorAlteravel;
  final int servicosSemCategoria;
  final int servicosCadastroIncompleto;
  final List<ServicoDashboardSerieItem> servicosPorCategoria;
  final List<ServicoDashboardSerieItem> servicosPorFaixaPreco;
  final List<ServicoDashboardSerieItem> configuracaoOperacional;
  final List<ServicoDashboardItem> servicosAtencao;
  final List<ServicoDashboardItem> servicosEstrategicos;
  final List<ServicoDashboardAlerta> alertas;

  const ServicoDashboardModel({
    required this.totalServicos,
    required this.servicosAtivos,
    required this.precoMedio,
    required this.servicosSemPreco,
    required this.servicosComGarantia,
    required this.servicosSemGarantia,
    required this.servicosValorAlteravel,
    required this.servicosSemCategoria,
    required this.servicosCadastroIncompleto,
    required this.servicosPorCategoria,
    required this.servicosPorFaixaPreco,
    required this.configuracaoOperacional,
    required this.servicosAtencao,
    required this.servicosEstrategicos,
    required this.alertas,
  });

  factory ServicoDashboardModel.fromJson(Map<String, dynamic> json) {
    return ServicoDashboardModel(
      totalServicos: _toInt(json['totalServicos']),
      servicosAtivos: _toInt(json['servicosAtivos']),
      precoMedio: _toDouble(json['precoMedio']),
      servicosSemPreco: _toInt(json['servicosSemPreco']),
      servicosComGarantia: _toInt(json['servicosComGarantia']),
      servicosSemGarantia: _toInt(json['servicosSemGarantia']),
      servicosValorAlteravel: _toInt(json['servicosValorAlteravel']),
      servicosSemCategoria: _toInt(json['servicosSemCategoria']),
      servicosCadastroIncompleto: _toInt(json['servicosCadastroIncompleto']),
      servicosPorCategoria: _parseList(
        json['servicosPorCategoria'],
        ServicoDashboardSerieItem.fromJson,
      ),
      servicosPorFaixaPreco: _parseList(
        json['servicosPorFaixaPreco'],
        ServicoDashboardSerieItem.fromJson,
      ),
      configuracaoOperacional: _parseList(
        json['configuracaoOperacional'],
        ServicoDashboardSerieItem.fromJson,
      ),
      servicosAtencao: _parseList(
        json['servicosAtencao'],
        ServicoDashboardItem.fromJson,
      ),
      servicosEstrategicos: _parseList(
        json['servicosEstrategicos'],
        ServicoDashboardItem.fromJson,
      ),
      alertas: _parseList(json['alertas'], ServicoDashboardAlerta.fromJson),
    );
  }

  bool get isEmpty => totalServicos == 0;
}

class ServicoDashboardSerieItem {
  final String label;
  final double quantidade;
  final double valor;

  const ServicoDashboardSerieItem({
    required this.label,
    required this.quantidade,
    required this.valor,
  });

  factory ServicoDashboardSerieItem.fromJson(Map<String, dynamic> json) {
    return ServicoDashboardSerieItem(
      label: json['label']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      valor: _toDouble(json['valor']),
    );
  }
}

class ServicoDashboardItem {
  final String id;
  final String nome;
  final String codigoDeBarras;
  final String categoria;
  final double precoVenda;
  final String tempoGarantia;
  final bool podeAlterarValorNaHora;
  final bool ativo;
  final String problema;

  const ServicoDashboardItem({
    required this.id,
    required this.nome,
    required this.codigoDeBarras,
    required this.categoria,
    required this.precoVenda,
    required this.tempoGarantia,
    required this.podeAlterarValorNaHora,
    required this.ativo,
    required this.problema,
  });

  factory ServicoDashboardItem.fromJson(Map<String, dynamic> json) {
    return ServicoDashboardItem(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      codigoDeBarras: json['codigoDeBarras']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'Sem categoria',
      precoVenda: _toDouble(json['precoVenda']),
      tempoGarantia: json['tempoGarantia']?.toString() ?? '',
      podeAlterarValorNaHora: _toBool(json['podeAlterarValorNaHora']),
      ativo: _toBool(json['ativo'], fallback: true),
      problema: json['problema']?.toString() ?? '',
    );
  }
}

class ServicoDashboardAlerta {
  final String tipo;
  final String titulo;
  final String descricao;
  final int quantidade;

  const ServicoDashboardAlerta({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.quantidade,
  });

  factory ServicoDashboardAlerta.fromJson(Map<String, dynamic> json) {
    return ServicoDashboardAlerta(
      tipo: json['tipo']?.toString() ?? 'INFO',
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      quantidade: _toInt(json['quantidade']),
    );
  }
}

List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map>()
      .map((item) => parser(Map<String, dynamic>.from(item)))
      .toList();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0.0;
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final String normalized = value?.toString().toLowerCase().trim() ?? '';
  if (normalized == 'true' || normalized == 'sim' || normalized == '1') return true;
  if (normalized == 'false' || normalized == 'nao' || normalized == 'não' || normalized == '0') return false;
  return fallback;
}
