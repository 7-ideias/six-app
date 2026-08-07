import 'recebimento_forma_input.dart';

class VendaNaoLiquidadaModel {
  VendaNaoLiquidadaModel({
    required this.idRecebimento,
    required this.idOperacaoFinanceira,
    required this.idOperacaoApp,
    required this.descricao,
    required this.valorOriginal,
    required this.valorAberto,
    required this.status,
    required this.codigoTipoRecebimento,
    required this.dataCompetencia,
    required this.dataVencimento,
    required this.idCliente,
    required this.nomeCliente,
    required this.idColaboradorCriacao,
    required this.nomeColaboradorCriacao,
    required this.itens,
    required this.recebimentos,
  });

  final String idRecebimento;
  final String idOperacaoFinanceira;
  final String idOperacaoApp;
  final String descricao;
  final double valorOriginal;
  final double valorAberto;
  final String status;
  final String codigoTipoRecebimento;
  final DateTime? dataCompetencia;
  final DateTime? dataVencimento;
  final String idCliente;
  final String nomeCliente;
  final String idColaboradorCriacao;
  final String nomeColaboradorCriacao;
  final List<VendaNaoLiquidadaItemModel> itens;
  final List<VendaNaoLiquidadaRecebimentoModel> recebimentos;

  factory VendaNaoLiquidadaModel.fromJson(Map<String, dynamic> json) {
    final dynamic itensJson = json['itens'];
    final dynamic recebimentosJson =
        json['recebimentos'] ?? json['liquidacoes'];
    return VendaNaoLiquidadaModel(
      idRecebimento: (json['idRecebimento'] ?? '').toString(),
      idOperacaoFinanceira: (json['idOperacaoFinanceira'] ?? '').toString(),
      idOperacaoApp: (json['idOperacaoApp'] ?? '').toString(),
      descricao: (json['descricao'] ?? 'Venda não liquidada').toString(),
      valorOriginal: _toDouble(json['valorOriginal']),
      valorAberto: _toDouble(json['valorAberto']),
      status: (json['status'] ?? '').toString(),
      codigoTipoRecebimento: (json['codigoTipoRecebimento'] ?? '').toString(),
      dataCompetencia: _toDateTime(json['dataCompetencia']),
      dataVencimento: _toDateTime(json['dataVencimento']),
      idCliente: (json['idCliente'] ?? '').toString(),
      nomeCliente: (json['nomeCliente'] ?? '').toString(),
      idColaboradorCriacao: (json['idColaboradorCriacao'] ?? '').toString(),
      nomeColaboradorCriacao: (json['nomeColaboradorCriacao'] ?? '').toString(),
      itens:
          itensJson is List
              ? itensJson
                  .whereType<Map<String, dynamic>>()
                  .map(VendaNaoLiquidadaItemModel.fromJson)
                  .toList(growable: false)
              : <VendaNaoLiquidadaItemModel>[],
      recebimentos: _parseRecebimentos(recebimentosJson),
    );
  }

  static List<VendaNaoLiquidadaRecebimentoModel> _parseRecebimentos(
    dynamic value,
  ) {
    if (value is! List) return <VendaNaoLiquidadaRecebimentoModel>[];
    return value
        .whereType<Map>()
        .map(
          (Map item) => VendaNaoLiquidadaRecebimentoModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '0').toString().replaceAll(',', '.')) ??
        0.0;
  }

  static DateTime? _toDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class VendaNaoLiquidadaRecebimentoModel {
  const VendaNaoLiquidadaRecebimentoModel({
    required this.id,
    required this.tipoLiquidacao,
    required this.valorLiquidado,
    required this.valorRestanteAntes,
    required this.valorRestanteDepois,
    required this.codigoTipoRecebimento,
    required this.formaPagamentoRealizada,
    required this.descricaoTipoRecebimento,
    this.observacoes,
    this.referencia,
    this.dataLiquidacao,
    this.registradoEm,
  });

  final String id;
  final String tipoLiquidacao;
  final double valorLiquidado;
  final double valorRestanteAntes;
  final double valorRestanteDepois;
  final String codigoTipoRecebimento;
  final String formaPagamentoRealizada;
  final String descricaoTipoRecebimento;
  final String? observacoes;
  final String? referencia;
  final DateTime? dataLiquidacao;
  final DateTime? registradoEm;

  factory VendaNaoLiquidadaRecebimentoModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VendaNaoLiquidadaRecebimentoModel(
      id: (json['id'] ?? '').toString(),
      tipoLiquidacao: (json['tipoLiquidacao'] ?? json['tipo'] ?? '').toString(),
      valorLiquidado: VendaNaoLiquidadaModel._toDouble(
        json['valorLiquidado'] ?? json['valorRecebido'],
      ),
      valorRestanteAntes: VendaNaoLiquidadaModel._toDouble(
        json['valorRestanteAntes'],
      ),
      valorRestanteDepois: VendaNaoLiquidadaModel._toDouble(
        json['valorRestanteDepois'],
      ),
      codigoTipoRecebimento:
          (json['codigoTipoRecebimento'] ??
                  json['formaPagamentoRealizada'] ??
                  '')
              .toString(),
      formaPagamentoRealizada:
          (json['formaPagamentoRealizada'] ??
                  json['codigoTipoRecebimento'] ??
                  '')
              .toString(),
      descricaoTipoRecebimento:
          (json['descricaoTipoRecebimento'] ?? '').toString(),
      observacoes: (json['observacoes'] ?? json['observacao'])?.toString(),
      referencia: (json['referencia'] ?? json['referenciaExterna'])?.toString(),
      dataLiquidacao: VendaNaoLiquidadaModel._toDateTime(
        json['dataLiquidacao'],
      ),
      registradoEm: VendaNaoLiquidadaModel._toDateTime(json['registradoEm']),
    );
  }
}

class VendaNaoLiquidadaItemModel {
  VendaNaoLiquidadaItemModel({
    required this.idProduto,
    required this.nome,
    required this.quantidade,
    required this.valorUnitario,
    required this.ehServico,
  });

  final String idProduto;
  final String nome;
  final int quantidade;
  final double valorUnitario;
  final bool ehServico;

  factory VendaNaoLiquidadaItemModel.fromJson(Map<String, dynamic> json) {
    return VendaNaoLiquidadaItemModel(
      idProduto: (json['idProduto'] ?? '').toString(),
      nome: (json['nome'] ?? 'Item da venda').toString(),
      quantidade: _toInt(json['quantidade']),
      valorUnitario: _toDouble(json['valorUnitario']),
      ehServico: json['ehServico'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idProduto': idProduto,
      'nome': nome,
      'quantidade': quantidade,
      'valorUnitario': valorUnitario,
      'ehServico': ehServico,
    };
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '1').toString()) ?? 1;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '0').toString().replaceAll(',', '.')) ??
        0.0;
  }
}

class LiquidarVendaNaoLiquidadaInput {
  LiquidarVendaNaoLiquidadaInput({
    required this.codigoTipoRecebimento,
    required this.valorRecebido,
    required this.itens,
    this.observacao,
    this.referencia,
    this.idSessaoCaixa,
    this.recebimentos,
  });

  final String codigoTipoRecebimento;
  final double valorRecebido;
  final List<VendaNaoLiquidadaItemModel> itens;
  final String? observacao;
  final String? referencia;
  final String? idSessaoCaixa;
  final List<RecebimentoFormaInput>? recebimentos;

  Map<String, dynamic> toJson() {
    return {
      'codigoTipoRecebimento': codigoTipoRecebimento,
      'valorRecebido': valorRecebido,
      'itens': itens.map((item) => item.toJson()).toList(growable: false),
      'observacao': observacao,
      'referencia': referencia,
      'idSessaoCaixa': idSessaoCaixa,
      if (recebimentos != null && recebimentos!.isNotEmpty)
        'recebimentos': recebimentos!
            .map((item) => item.toJson())
            .toList(growable: false),
    };
  }
}
