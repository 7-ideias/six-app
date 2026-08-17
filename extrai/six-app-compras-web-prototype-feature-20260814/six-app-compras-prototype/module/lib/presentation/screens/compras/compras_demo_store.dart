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
    compras.clear();
    fornecedores
      ..clear()
      ..addAll(const <_FornecedorDemo>[
        _FornecedorDemo(
          id: 'fornecedor-1',
          nome: 'Distribuidora TecBrasil',
          documento: '12.345.678/0001-90',
          email: 'compras@tecbrasil.demo',
          telefone: '+55 11 4000-1010',
        ),
        _FornecedorDemo(
          id: 'fornecedor-2',
          nome: 'Global Parts Importação',
          documento: '45.890.123/0001-18',
          email: 'pedidos@globalparts.demo',
          telefone: '+55 47 3200-8899',
        ),
        _FornecedorDemo(
          id: 'fornecedor-3',
          nome: 'Insumos Sul Assistência',
          documento: '83.444.555/0001-03',
          email: 'vendas@insumossul.demo',
          telefone: '+55 48 3300-2000',
        ),
        _FornecedorDemo(
          id: 'fornecedor-4',
          nome: 'Mobile Components Europe',
          documento: 'EU-DEMO-92831',
          email: 'orders@mobilecomponents.demo',
          telefone: '+49 30 555 0101',
        ),
      ]);

    produtos
      ..clear()
      ..addAll(const <_ProdutoCompraDemo>[
        _ProdutoCompraDemo(
          id: 'produto-1',
          nome: 'Tela OLED compatível com iPhone 13',
          codigo: 'TEL-IP13-OLED',
          unidade: 'UN',
          ultimoCusto: 279.90,
          estoqueAtual: 3,
        ),
        _ProdutoCompraDemo(
          id: 'produto-2',
          nome: 'Bateria compatível com Samsung A54',
          codigo: 'BAT-A54-5000',
          unidade: 'UN',
          ultimoCusto: 89.50,
          estoqueAtual: 7,
        ),
        _ProdutoCompraDemo(
          id: 'produto-3',
          nome: 'Conector de carga USB-C universal',
          codigo: 'CON-USBC-10',
          unidade: 'UN',
          ultimoCusto: 11.80,
          estoqueAtual: 22,
        ),
        _ProdutoCompraDemo(
          id: 'produto-4',
          nome: 'Película 3D premium',
          codigo: 'PEL-3D-PREM',
          unidade: 'UN',
          ultimoCusto: 7.20,
          estoqueAtual: 15,
        ),
        _ProdutoCompraDemo(
          id: 'produto-5',
          nome: 'Álcool isopropílico 99,8%',
          codigo: 'ALC-ISO-1L',
          unidade: 'LT',
          ultimoCusto: 42.00,
          estoqueAtual: 4,
        ),
        _ProdutoCompraDemo(
          id: 'produto-6',
          nome: 'Kit de chaves para manutenção',
          codigo: 'KIT-CHV-38',
          unidade: 'UN',
          ultimoCusto: 118.00,
          estoqueAtual: 2,
        ),
      ]);

    final DateTime agora = DateTime.now();
    compras.addAll(<_CompraDemo>[
      _CompraDemo(
        id: 'compra-demo-1',
        numero: 1047,
        status: _CompraDemoStatus.confirmada,
        criadaEm: agora.subtract(const Duration(days: 3, hours: 2)),
        atualizadaEm: agora.subtract(const Duration(days: 2, hours: 20)),
        confirmadaEm: agora.subtract(const Duration(days: 2, hours: 20)),
        fornecedorId: 'fornecedor-1',
        fornecedorNome: 'Distribuidora TecBrasil',
        fornecedorDocumento: '12.345.678/0001-90',
        tipoDocumento: 'NF-e',
        numeroDocumento: '000028741',
        serieDocumento: '1',
        dataEmissao: agora.subtract(const Duration(days: 3)),
        dataEntrada: agora.subtract(const Duration(days: 2)),
        moeda: 'BRL',
        itens: <_CompraDemoItem>[
          _CompraDemoItem(
            id: 'item-demo-1',
            produtoId: 'produto-1',
            descricao: 'Tela OLED compatível com iPhone 13',
            codigo: 'TEL-IP13-OLED',
            quantidade: 6,
            valorUnitario: 268.00,
          ),
          _CompraDemoItem(
            id: 'item-demo-2',
            produtoId: 'produto-2',
            descricao: 'Bateria compatível com Samsung A54',
            codigo: 'BAT-A54-5000',
            quantidade: 10,
            valorUnitario: 84.90,
            desconto: 49,
          ),
          _CompraDemoItem(
            id: 'item-demo-3',
            descricao: 'Frete expresso informado pelo fornecedor',
            codigo: 'SERV-FRETE',
            unidade: 'SV',
            quantidade: 1,
            valorUnitario: 0,
            movimentaEstoque: false,
          ),
        ],
        frete: 135,
        descontoGeral: 80,
        gerarContaPagar: true,
        formaPagamento: 'Boleto',
        quantidadeParcelas: 3,
        primeiroVencimento: agora.add(const Duration(days: 12)),
        intervaloDias: 30,
        contaFinanceira: 'Conta principal',
        anexos: <_CompraDemoAnexo>[
          _CompraDemoAnexo(
            id: 'anexo-demo-1',
            nome: 'nfe-000028741.xml',
            tipo: 'XML',
            tamanho: '18 KB',
            adicionadoEm: agora.subtract(const Duration(days: 2)),
          ),
        ],
      ),
      _CompraDemo(
        id: 'compra-demo-2',
        status: _CompraDemoStatus.rascunho,
        criadaEm: agora.subtract(const Duration(hours: 6)),
        atualizadaEm: agora.subtract(const Duration(minutes: 48)),
        fornecedorId: 'fornecedor-2',
        fornecedorNome: 'Global Parts Importação',
        fornecedorDocumento: '45.890.123/0001-18',
        tipoDocumento: 'Invoice',
        numeroDocumento: 'INV-2026-8841',
        dataEmissao: agora.subtract(const Duration(days: 1)),
        dataEntrada: agora,
        moeda: 'USD',
        itens: <_CompraDemoItem>[
          _CompraDemoItem(
            id: 'item-demo-4',
            produtoId: 'produto-3',
            descricao: 'Conector de carga USB-C universal',
            codigo: 'CON-USBC-10',
            quantidade: 50,
            valorUnitario: 2.05,
          ),
          _CompraDemoItem(
            id: 'item-demo-5',
            produtoId: 'produto-4',
            descricao: 'Película 3D premium',
            codigo: 'PEL-3D-PREM',
            quantidade: 100,
            valorUnitario: 1.28,
          ),
        ],
        frete: 46,
        gerarContaPagar: true,
        formaPagamento: 'Transferência',
        quantidadeParcelas: 1,
        primeiroVencimento: agora.add(const Duration(days: 7)),
        contaFinanceira: 'Conta internacional',
      ),
      _CompraDemo(
        id: 'compra-demo-3',
        numero: 1046,
        status: _CompraDemoStatus.cancelada,
        criadaEm: agora.subtract(const Duration(days: 10)),
        atualizadaEm: agora.subtract(const Duration(days: 8)),
        canceladaEm: agora.subtract(const Duration(days: 8)),
        motivoCancelamento: 'Documento emitido com valores incorretos.',
        fornecedorId: 'fornecedor-3',
        fornecedorNome: 'Insumos Sul Assistência',
        fornecedorDocumento: '83.444.555/0001-03',
        tipoDocumento: 'Recibo',
        numeroDocumento: 'REC-3921',
        dataEmissao: agora.subtract(const Duration(days: 10)),
        dataEntrada: agora.subtract(const Duration(days: 10)),
        itens: <_CompraDemoItem>[
          _CompraDemoItem(
            id: 'item-demo-6',
            produtoId: 'produto-5',
            descricao: 'Álcool isopropílico 99,8%',
            codigo: 'ALC-ISO-1L',
            unidade: 'LT',
            quantidade: 12,
            valorUnitario: 39,
          ),
        ],
        gerarContaPagar: false,
      ),
    ]);
    _proximoNumero = 1048;
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
