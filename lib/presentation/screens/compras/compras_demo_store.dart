part of 'compras_web_page.dart';

class _ComprasDemoStore {
  _ComprasDemoStore._() {
    reset();
  }

  static final _ComprasDemoStore instance = _ComprasDemoStore._();

  final List<_CompraDemo> compras = <_CompraDemo>[];
  final List<_FornecedorDemo> fornecedores = <_FornecedorDemo>[];
  final List<_ProdutoCompraDemo> produtos = <_ProdutoCompraDemo>[];
  int _proximoNumero = 1048;
  int _sequence = 1;

  String novoId(String prefixo) {
    final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    return '$prefixo-$timestamp-${_sequence++}';
  }

  void reset() {
    // A fase 2 não carrega dados fictícios. Apenas a API alimenta estas listas.
    compras.clear();
    fornecedores.clear();
    produtos.clear();
    _proximoNumero = 1;
    _sequence = 1;
  }

  _CompraDemo criarRascunho({required String moeda}) {
    final DateTime agora = DateTime.now();
    final _CompraDemo compra = _CompraDemo(
      id: novoId('compra'),
      criadaEm: agora,
      atualizadaEm: agora,
      moeda: moeda,
    );
    compras.insert(0, compra);
    return compra;
  }

  _FornecedorDemo criarFornecedor({
    required String nome,
    required String documento,
    required String email,
    required String telefone,
  }) {
    final _FornecedorDemo fornecedor = _FornecedorDemo(
      id: novoId('fornecedor'),
      nome: nome,
      documento: documento,
      email: email,
      telefone: telefone,
    );
    fornecedores.insert(0, fornecedor);
    return fornecedor;
  }

  _ProdutoCompraDemo criarProduto({
    required String nome,
    required String codigo,
    required String unidade,
    required double custo,
  }) {
    final _ProdutoCompraDemo produto = _ProdutoCompraDemo(
      id: novoId('produto'),
      nome: nome,
      codigo: codigo,
      unidade: unidade,
      ultimoCusto: custo,
      estoqueAtual: 0,
    );
    produtos.insert(0, produto);
    return produto;
  }

  void salvar(_CompraDemo compra) {
    compra.atualizadaEm = DateTime.now();
  }

  int confirmar(_CompraDemo compra) {
    if (compra.status == _CompraDemoStatus.confirmada) {
      return compra.numero ?? _proximoNumero;
    }
    final int numero = _proximoNumero++;
    compra
      ..numero = numero
      ..status = _CompraDemoStatus.confirmada
      ..confirmadaEm = DateTime.now()
      ..atualizadaEm = DateTime.now();
    return numero;
  }

  void cancelar(_CompraDemo compra, String motivo) {
    compra
      ..status = _CompraDemoStatus.cancelada
      ..canceladaEm = DateTime.now()
      ..motivoCancelamento = motivo
      ..atualizadaEm = DateTime.now();
  }

  _CompraDemo duplicar(_CompraDemo origem) {
    final _CompraDemo copia = origem.duplicar(
      novoId: novoId('compra'),
      agora: DateTime.now(),
    );
    compras.insert(0, copia);
    return copia;
  }

  List<_ParcelaDemo> parcelasDa(_CompraDemo compra) {
    if (!compra.gerarContaPagar || compra.jaPago || compra.totalCompra <= 0) {
      return const <_ParcelaDemo>[];
    }
    final int quantidade = compra.quantidadeParcelas.clamp(1, 12).toInt();
    final double valorBase = compra.totalCompra / quantidade;
    double acumulado = 0;
    return List<_ParcelaDemo>.generate(quantidade, (int index) {
      final bool ultima = index == quantidade - 1;
      final double valor = ultima ? compra.totalCompra - acumulado : valorBase;
      acumulado += valor;
      return _ParcelaDemo(
        numero: index + 1,
        vencimento: compra.primeiroVencimento.add(
          Duration(days: compra.intervaloDias * index),
        ),
        valor: valor,
      );
    });
  }
}
