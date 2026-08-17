part of 'compras_web_page.dart';

enum _CompraDemoStatus { rascunho, confirmada, cancelada }

enum _CompraDemoStep { dados, itens, financeiro, anexos, resumo }

enum _CompraFiltroStatus { todos, rascunho, confirmada, cancelada }

enum _CompraOrdenacao { maisRecentes, maisAntigas, maiorValor, menorValor }

enum _CompraPeriodo { todos, seteDias, trintaDias, mesAtual }

class _FornecedorDemo {
  const _FornecedorDemo({
    required this.id,
    required this.nome,
    required this.documento,
    required this.email,
    required this.telefone,
  });

  final String id;
  final String nome;
  final String documento;
  final String email;
  final String telefone;
}

class _ProdutoCompraDemo {
  const _ProdutoCompraDemo({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.unidade,
    required this.ultimoCusto,
    required this.estoqueAtual,
  });

  final String id;
  final String nome;
  final String codigo;
  final String unidade;
  final double ultimoCusto;
  final double estoqueAtual;
}

class _CompraDemoItem {
  _CompraDemoItem({
    required this.id,
    required this.descricao,
    this.produtoId,
    this.codigo = '',
    this.unidade = 'UN',
    this.quantidade = 1,
    this.valorUnitario = 0,
    this.desconto = 0,
    this.acrescimo = 0,
    this.movimentaEstoque = true,
  });

  final String id;
  String? produtoId;
  String descricao;
  String codigo;
  String unidade;
  double quantidade;
  double valorUnitario;
  double desconto;
  double acrescimo;
  bool movimentaEstoque;

  double get subtotal => quantidade * valorUnitario;

  double get total => math.max(0.0, subtotal - desconto + acrescimo);

  _CompraDemoItem copy() {
    return _CompraDemoItem(
      id: id,
      produtoId: produtoId,
      descricao: descricao,
      codigo: codigo,
      unidade: unidade,
      quantidade: quantidade,
      valorUnitario: valorUnitario,
      desconto: desconto,
      acrescimo: acrescimo,
      movimentaEstoque: movimentaEstoque,
    );
  }
}

class _CompraDemoAnexo {
  const _CompraDemoAnexo({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.tamanho,
    required this.adicionadoEm,
  });

  final String id;
  final String nome;
  final String tipo;
  final String tamanho;
  final DateTime adicionadoEm;
}

class _CompraDemo {
  _CompraDemo({
    required this.id,
    required this.criadaEm,
    required this.atualizadaEm,
    this.numero,
    this.status = _CompraDemoStatus.rascunho,
    this.fornecedorId,
    this.fornecedorNome = '',
    this.fornecedorDocumento = '',
    this.tipoDocumento = 'NF-e',
    this.numeroDocumento = '',
    this.serieDocumento = '',
    DateTime? dataEmissao,
    DateTime? dataEntrada,
    this.moeda = 'BRL',
    this.observacoes = '',
    List<_CompraDemoItem>? itens,
    this.frete = 0,
    this.descontoGeral = 0,
    this.outrosAcrescimos = 0,
    this.gerarContaPagar = true,
    this.jaPago = false,
    this.formaPagamento = 'Boleto',
    this.quantidadeParcelas = 1,
    DateTime? primeiroVencimento,
    this.intervaloDias = 30,
    this.contaFinanceira = 'Conta principal',
    this.observacaoFinanceira = '',
    List<_CompraDemoAnexo>? anexos,
    this.confirmadaEm,
    this.canceladaEm,
    this.motivoCancelamento,
  })  : dataEmissao = dataEmissao ?? DateTime.now(),
        dataEntrada = dataEntrada ?? DateTime.now(),
        primeiroVencimento =
            primeiroVencimento ?? DateTime.now().add(const Duration(days: 30)),
        itens = itens ?? <_CompraDemoItem>[],
        anexos = anexos ?? <_CompraDemoAnexo>[];

  final String id;
  int? numero;
  _CompraDemoStatus status;
  String? fornecedorId;
  String fornecedorNome;
  String fornecedorDocumento;
  String tipoDocumento;
  String numeroDocumento;
  String serieDocumento;
  DateTime dataEmissao;
  DateTime dataEntrada;
  String moeda;
  String observacoes;
  final List<_CompraDemoItem> itens;
  double frete;
  double descontoGeral;
  double outrosAcrescimos;
  bool gerarContaPagar;
  bool jaPago;
  String formaPagamento;
  int quantidadeParcelas;
  DateTime primeiroVencimento;
  int intervaloDias;
  String contaFinanceira;
  String observacaoFinanceira;
  final List<_CompraDemoAnexo> anexos;
  final DateTime criadaEm;
  DateTime atualizadaEm;
  DateTime? confirmadaEm;
  DateTime? canceladaEm;
  String? motivoCancelamento;

  bool get editavel => status == _CompraDemoStatus.rascunho;

  double get subtotalItens => itens.fold<double>(0, (sum, item) => sum + item.subtotal);

  double get descontoItens => itens.fold<double>(0, (sum, item) => sum + item.desconto);

  double get acrescimoItens => itens.fold<double>(0, (sum, item) => sum + item.acrescimo);

  double get totalItens => itens.fold<double>(0, (sum, item) => sum + item.total);

  double get totalCompra => math.max(
        0.0,
        totalItens + frete + outrosAcrescimos - descontoGeral,
      );

  int get itensComEstoque => itens.where((item) => item.movimentaEstoque).length;

  String get identificadorVisual {
    if (numero != null) {
      return '#${numero.toString().padLeft(6, '0')}';
    }
    return 'Rascunho ${id.substring(math.max(0, id.length - 4)).toUpperCase()}';
  }

  _CompraDemo duplicar({required String novoId, required DateTime agora}) {
    return _CompraDemo(
      id: novoId,
      criadaEm: agora,
      atualizadaEm: agora,
      fornecedorId: fornecedorId,
      fornecedorNome: fornecedorNome,
      fornecedorDocumento: fornecedorDocumento,
      tipoDocumento: tipoDocumento,
      numeroDocumento: numeroDocumento,
      serieDocumento: serieDocumento,
      dataEmissao: agora,
      dataEntrada: agora,
      moeda: moeda,
      observacoes: observacoes,
      itens: itens.map((item) => item.copy()).toList(growable: true),
      frete: frete,
      descontoGeral: descontoGeral,
      outrosAcrescimos: outrosAcrescimos,
      gerarContaPagar: gerarContaPagar,
      jaPago: false,
      formaPagamento: formaPagamento,
      quantidadeParcelas: quantidadeParcelas,
      primeiroVencimento: agora.add(const Duration(days: 30)),
      intervaloDias: intervaloDias,
      contaFinanceira: contaFinanceira,
      observacaoFinanceira: observacaoFinanceira,
      anexos: <_CompraDemoAnexo>[],
    );
  }
}

class _ParcelaDemo {
  const _ParcelaDemo({
    required this.numero,
    required this.vencimento,
    required this.valor,
  });

  final int numero;
  final DateTime vencimento;
  final double valor;
}
