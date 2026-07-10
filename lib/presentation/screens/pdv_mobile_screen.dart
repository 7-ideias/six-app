import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/di/operacao_module.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/produto_helper.dart';
import '../../data/models/operacao_models.dart';
import '../../data/models/produto_model.dart';
import '../../data/models/venda_nao_liquidada_models.dart';
import '../../data/services/caixa/venda_nao_liquidada_api_client.dart';
import '../../domain/services/operacao/operacao_service.dart';
import '../../providers/usuario_provider.dart';
import 'produto_list_mobile_screen.dart';

class PdvMobileScreen extends StatefulWidget {
  const PdvMobileScreen({super.key, this.vendaNaoLiquidada});

  final VendaNaoLiquidadaModel? vendaNaoLiquidada;

  @override
  State<PdvMobileScreen> createState() => _PdvMobileScreenState();
}

class _PdvMobileScreenState extends State<PdvMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  final OperacaoService _operacaoService = OperacaoModule.operacaoService;
  final VendaNaoLiquidadaApiClient _vendaNaoLiquidadaApiClient =
      VendaNaoLiquidadaApiClient();
  final List<_VendaItemMobile> _itens = <_VendaItemMobile>[];
  final Set<String> _formasSelecionadas = <String>{};
  final Map<String, TextEditingController> _valorPorForma =
      <String, TextEditingController>{};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _pagamentoKey = GlobalKey();

  final List<_FormaPagamentoMobile>
  _formasPagamento = const <_FormaPagamentoMobile>[
    _FormaPagamentoMobile('TIPO1', 'Dinheiro', Icons.payments_outlined),
    _FormaPagamentoMobile('TIPO2', 'Pix', Icons.qr_code_2_outlined),
    _FormaPagamentoMobile(
      'TIPO3',
      'Cartão crédito',
      Icons.credit_card_outlined,
    ),
    _FormaPagamentoMobile(
      'TIPO4',
      'Cartão débito',
      Icons.point_of_sale_outlined,
    ),
    _FormaPagamentoMobile('TIPO5', 'Boleto', Icons.receipt_long_outlined),
    _FormaPagamentoMobile('TIPO6', 'Fiado', Icons.history_toggle_off_outlined),
    _FormaPagamentoMobile('TIPO7', 'Crediário', Icons.event_note_outlined),
    _FormaPagamentoMobile('TIPO8', 'Convênio', Icons.people_outline),
    _FormaPagamentoMobile('TIPO9', 'Vale', Icons.confirmation_number_outlined),
    _FormaPagamentoMobile('TIPO10', 'Outros', Icons.more_horiz_outlined),
  ];

  bool _enviando = false;
  bool _buscandoCodigo = false;
  bool _acoesRapidasVisiveis = false;
  bool _destacarPagamento = false;

  bool get _editandoVendaNaoLiquidada => widget.vendaNaoLiquidada != null;
  double get _total => _itens.fold<double>(0, (s, item) => s + item.subtotal);
  int get _quantidadeItens =>
      _itens.fold<int>(0, (s, item) => s + item.quantidade);

  @override
  void initState() {
    super.initState();
    final venda = widget.vendaNaoLiquidada;
    if (venda != null) {
      _itens.addAll(
        venda.itens.map(_VendaItemMobile.fromVendaNaoLiquidadaItem),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _valorPorForma.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _abrirSelecaoProduto() async {
    final dynamic result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder:
            (_) => const ProdutolistMobileScreen(
              isSelecao: true,
              permitirSelecaoMultipla: true,
            ),
      ),
    );

    if (!mounted || result == null) return;

    if (result is ProdutoModel) {
      _adicionarProdutoSelecionado(result);
      return;
    }

    if (result is List) {
      final produtos = result.whereType<ProdutoModel>().toList(growable: false);
      if (produtos.isNotEmpty) _adicionarProdutosSelecionados(produtos);
    }
  }

  Future<void> _abrirScannerCodigoBarras() async {
    if (_enviando || _buscandoCodigo) return;

    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const _BarcodeScannerMobileScreen(),
      ),
    );

    if (codigo == null || codigo.trim().isEmpty) return;
    await _buscarEAdicionarProdutoPorCodigo(codigo.trim());
  }

  Future<void> _buscarEAdicionarProdutoPorCodigo(String codigo) async {
    if (_buscandoCodigo) return;

    setState(() => _buscandoCodigo = true);
    try {
      List<ProdutoModel> produtos = <ProdutoModel>[];
      await ProdutoHelper.retornarProdutosList(
        context,
        tipo: 'PRODUTO',
        onSucesso: (lista) => produtos = lista,
      );

      final codigoNormalizado = codigo.toLowerCase();
      ProdutoModel? encontrado;
      for (final produto in produtos) {
        if (produto.codigoDeBarras.trim().toLowerCase() == codigoNormalizado) {
          encontrado = produto;
          break;
        }
      }

      if (!mounted) return;
      if (encontrado == null) {
        _mostrarSnack('Produto não encontrado para o código $codigo.');
        return;
      }

      _adicionarProdutoSelecionado(encontrado);
      _mostrarSnack('${encontrado.nomeProduto} adicionado à venda.');
    } catch (_) {
      if (mounted)
        _mostrarSnack('Não foi possível buscar o produto pelo código.');
    } finally {
      if (mounted) setState(() => _buscandoCodigo = false);
    }
  }

  void _adicionarProdutoSelecionado(ProdutoModel produto) {
    setState(() => _adicionarProdutoNaListaSemSetState(produto));
  }

  void _adicionarProdutosSelecionados(List<ProdutoModel> produtos) {
    if (produtos.isEmpty) return;
    setState(() {
      for (final produto in produtos) {
        _adicionarProdutoNaListaSemSetState(produto);
      }
    });
  }

  void _adicionarProdutoNaListaSemSetState(ProdutoModel produto) {
    final idProduto = produto.id ?? produto.codigoDeBarras;
    final tipoNormalizado = produto.tipoProduto.toUpperCase();
    final ehServico =
        tipoNormalizado == 'SERVICO' || tipoNormalizado == 'SERVIÇO';
    final index = _itens.indexWhere((item) => item.idProduto == idProduto);

    if (index >= 0) {
      _itens[index] = _itens[index].copyWith(
        quantidade: _itens[index].quantidade + 1,
      );
      return;
    }

    _itens.add(
      _VendaItemMobile(
        idProduto: idProduto,
        nome: produto.nomeProduto,
        valorUnitario: produto.precoVenda,
        quantidade: 1,
        ehServico: ehServico,
      ),
    );
  }

  Future<void> _finalizarVenda() async {
    if (_itens.isEmpty) {
      _mostrarSnack('Inclua pelo menos um item para finalizar.');
      return;
    }
    if (_formasSelecionadas.isEmpty) {
      await _avisarPagamentoObrigatorio();
      return;
    }
    if (_editandoVendaNaoLiquidada && _formasSelecionadas.length > 1) {
      _mostrarSnack(
        'Para receber uma venda em aberto, selecione uma única forma de pagamento.',
      );
      return;
    }

    final formas = _montarFormasPagamento();
    final totalPago = formas.fold<double>(
      0,
      (soma, forma) => soma + forma.valor,
    );
    if ((totalPago - _total).abs() > 0.009) {
      _mostrarSnack('A soma dos pagamentos precisa fechar o total da venda.');
      return;
    }

    await _enviarVenda(receberDepois: false, formasPagamento: formas);
  }

  Future<void> _avisarPagamentoObrigatorio() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (!_destacarPagamento && mounted)
      setState(() => _destacarPagamento = true);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    final pagamentoContext = _pagamentoKey.currentContext;
    if (pagamentoContext != null && mounted) {
      await Scrollable.ensureVisible(
        pagamentoContext,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        alignment: 0.10,
      );
    }

    _mostrarSnack('Selecione uma forma de pagamento ou use Receber depois.');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => _destacarPagamento = false);
  }

  Future<void> _receberDepois() async {
    if (_editandoVendaNaoLiquidada) {
      Navigator.of(context).pop(false);
      return;
    }
    if (_itens.isEmpty) {
      _mostrarSnack('Inclua pelo menos um item para registrar a venda.');
      return;
    }

    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    _modalIcon(Icons.schedule_send_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Receber depois',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'A venda ficará em aberto para liquidação no caixa.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildResumoReceberDepois(),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Registrar para receber depois'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Voltar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmou == true) {
      await _enviarVenda(
        receberDepois: true,
        formasPagamento: <FormaPagamentoSelecionada>[],
      );
    }
  }

  Future<void> _enviarVenda({
    required bool receberDepois,
    required List<FormaPagamentoSelecionada> formasPagamento,
  }) async {
    setState(() => _enviando = true);
    try {
      if (_editandoVendaNaoLiquidada && !receberDepois) {
        await _liquidarVendaNaoLiquidada(formasPagamento.first);
        return;
      }

      final idColaborador = await AuthService().getUserId() ?? '';
      final nomeColaborador = _nomeColaboradorAtual();
      final dataOperacao = DateTime.now();
      final input = OperacaoVendaInput(
        descricao:
            receberDepois
                ? 'Venda mobile para receber depois ${dataOperacao.toIso8601String()}'
                : 'Venda mobile ${dataOperacao.toIso8601String()}',
        idColaborador: idColaborador,
        nomeColaborador: nomeColaborador,
        itens: _itens.map((item) => item.toInput()).toList(growable: false),
        formasPagamento: formasPagamento,
        dataOperacao: dataOperacao,
        receberDepois: receberDepois,
      );

      await _operacaoService.finalizarVenda(input);
      if (!mounted) return;
      _limparVenda();
      _mostrarSnack(
        receberDepois
            ? 'Venda registrada para receber depois.'
            : 'Venda finalizada com sucesso.',
      );
    } catch (e) {
      if (mounted) _mostrarSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _liquidarVendaNaoLiquidada(
    FormaPagamentoSelecionada formaPagamento,
  ) async {
    final venda = widget.vendaNaoLiquidada!;
    await _vendaNaoLiquidadaApiClient.liquidar(
      idRecebimento: venda.idRecebimento,
      input: LiquidarVendaNaoLiquidadaInput(
        codigoTipoRecebimento: formaPagamento.codigo.toLowerCase(),
        valorRecebido: _total,
        itens: _itens
            .map((item) => item.toVendaNaoLiquidadaItem())
            .toList(growable: false),
        observacao: 'Recebido pelo PDV mobile',
      ),
    );

    if (!mounted) return;
    _mostrarSnack('Venda recebida com sucesso.');
    Navigator.of(context).pop(true);
  }

  void _limparVenda() {
    setState(() {
      _itens.clear();
      _formasSelecionadas.clear();
      _destacarPagamento = false;
      for (final controller in _valorPorForma.values) {
        controller.clear();
      }
    });
  }

  void _cancelarVenda() {
    if (_editandoVendaNaoLiquidada) {
      Navigator.of(context).pop(false);
      return;
    }
    _limparVenda();
    _mostrarSnack('Venda cancelada.');
  }

  Widget _modalIcon(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: _accentColor),
    );
  }

  Widget _buildResumoReceberDepois() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accentColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              'Valor em aberto',
              style: TextStyle(
                color: _titleTextColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            _formatarValor(_total),
            style: const TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  List<FormaPagamentoSelecionada> _montarFormasPagamento() {
    if (_formasSelecionadas.length == 1) {
      final codigo = _formasSelecionadas.first;
      final valorDigitado = _valorDigitadoForma(codigo);
      return <FormaPagamentoSelecionada>[
        FormaPagamentoSelecionada(
          codigo: codigo,
          valor: valorDigitado > 0 ? valorDigitado : _total,
        ),
      ];
    }
    return _formasSelecionadas
        .map(
          (codigo) => FormaPagamentoSelecionada(
            codigo: codigo,
            valor: _valorDigitadoForma(codigo),
          ),
        )
        .toList(growable: false);
  }

  double _valorDigitadoForma(String codigoForma) {
    final raw = _valorPorForma[codigoForma]?.text ?? '';
    final normalizado = raw.replaceAll('R\$', '').replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0.0;
  }

  double _valorSelecionadoTotal() {
    if (_formasSelecionadas.isEmpty) return 0.0;
    return _montarFormasPagamento().fold<double>(
      0.0,
      (soma, forma) => soma + forma.valor,
    );
  }

  double _valorRestante() => _total - _valorSelecionadoTotal();

  void _preencherValorRestante(String codigoForma) {
    _valorPorForma.putIfAbsent(codigoForma, () => TextEditingController());
    final controller = _valorPorForma[codigoForma]!;
    final atual = _valorDigitadoForma(codigoForma);
    final restante = _valorRestante();
    final novoValor = (atual + restante).clamp(0.0, _total).toDouble();

    setState(() {
      controller.text = novoValor.toStringAsFixed(2);
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      _formasSelecionadas.add(codigoForma);
      _destacarPagamento = false;
    });
  }

  String _nomeColaboradorAtual() {
    final usuario = UsuarioProvider().usuario;
    if (usuario == null) return 'Colaborador';
    if (usuario.nomeDeGuerra.trim().isNotEmpty)
      return usuario.nomeDeGuerra.trim();
    final nomeCompleto = '${usuario.nome} ${usuario.sobrenome}'.trim();
    return nomeCompleto.isEmpty ? 'Colaborador' : nomeCompleto;
  }

  String _formatarValor(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temItens = _itens.isNotEmpty;
    final bottomPadding =
        temItens ? (_acoesRapidasVisiveis ? 218.0 : 142.0) : 110.0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _editandoVendaNaoLiquidada ? 'Receber venda' : 'PDV - Ponto de Venda',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          children: <Widget>[
            _buildHeader()
                .animate()
                .fade(duration: 320.ms)
                .slideY(begin: 0.04, curve: Curves.easeOut),
            const SizedBox(height: 16),
            if (_itens.isEmpty)
              _buildEstadoVazio()
            else ...<Widget>[
              _buildItensCard(),
              const SizedBox(height: 14),
              _buildPagamentoCard(),
            ],
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
      bottomNavigationBar: _itens.isEmpty ? null : _buildBottomActions(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, Color(0xFF123B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _editandoVendaNaoLiquidada
                  ? Icons.receipt_long_outlined
                  : Icons.point_of_sale_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _editandoVendaNaoLiquidada
                      ? 'Venda em aberto'
                      : 'Balcão de venda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_quantidadeItens item(ns) • ${_formatarValor(_total)}',
                  style: const TextStyle(
                    color: Color(0xFFD7E3F5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: _accentColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _editandoVendaNaoLiquidada
                ? 'Venda sem itens carregados'
                : 'Venda ainda vazia',
            style: const TextStyle(
              color: _titleTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _editandoVendaNaoLiquidada
                ? 'Inclua novamente os itens antes de receber esta venda.'
                : 'Inclua produtos ou serviços para liberar a finalização ou o recebimento posterior.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedTextColor, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _abrirSelecaoProduto,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar produto ou serviço'),
          ),
        ],
      ),
    );
  }

  Widget _buildItensCard() {
    return _buildSectionCard(
      titulo: 'Itens da venda',
      icone: Icons.inventory_2_outlined,
      child: Column(
        children: _itens.map(_buildItemTile).toList(growable: false),
      ),
    );
  }

  Widget _buildPagamentoCard() {
    return _buildSectionCard(
      sectionKey: _pagamentoKey,
      destacar: _destacarPagamento,
      titulo: 'Pagamento',
      icone: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildFormasPagamentoAdaptativas(),
          if (_formasSelecionadas.isEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _buildPagamentoHint(),
          ] else ...<Widget>[
            const SizedBox(height: 12),
            ..._formasSelecionadas.map(_buildValorFormaField),
          ],
        ],
      ),
    );
  }

  Widget _buildFormasPagamentoAdaptativas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final linhas = _montarLinhasPagamento(constraints.maxWidth);
        return Column(
          children: linhas
              .map((linha) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: linha
                        .asMap()
                        .entries
                        .map((entry) {
                          final forma = entry.value;
                          return Expanded(
                            flex: _flexFormaPagamento(forma),
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: entry.key == 0 ? 0 : 8,
                              ),
                              child: _buildPillPagamento(forma),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  List<List<_FormaPagamentoMobile>> _montarLinhasPagamento(double largura) {
    if (largura < 340) {
      return <List<_FormaPagamentoMobile>>[
        <_FormaPagamentoMobile>[_formasPagamento[0], _formasPagamento[1]],
        <_FormaPagamentoMobile>[_formasPagamento[2]],
        <_FormaPagamentoMobile>[_formasPagamento[3], _formasPagamento[4]],
        <_FormaPagamentoMobile>[_formasPagamento[5], _formasPagamento[6]],
        <_FormaPagamentoMobile>[
          _formasPagamento[7],
          _formasPagamento[8],
          _formasPagamento[9],
        ],
      ];
    }

    if (largura < 430) {
      return <List<_FormaPagamentoMobile>>[
        <_FormaPagamentoMobile>[
          _formasPagamento[0],
          _formasPagamento[1],
          _formasPagamento[4],
        ],
        <_FormaPagamentoMobile>[_formasPagamento[2], _formasPagamento[3]],
        <_FormaPagamentoMobile>[
          _formasPagamento[5],
          _formasPagamento[6],
          _formasPagamento[8],
        ],
        <_FormaPagamentoMobile>[_formasPagamento[7], _formasPagamento[9]],
      ];
    }

    return <List<_FormaPagamentoMobile>>[
      <_FormaPagamentoMobile>[
        _formasPagamento[0],
        _formasPagamento[1],
        _formasPagamento[4],
        _formasPagamento[9],
      ],
      <_FormaPagamentoMobile>[
        _formasPagamento[2],
        _formasPagamento[3],
        _formasPagamento[6],
      ],
      <_FormaPagamentoMobile>[
        _formasPagamento[5],
        _formasPagamento[7],
        _formasPagamento[8],
      ],
    ];
  }

  int _flexFormaPagamento(_FormaPagamentoMobile forma) {
    final tamanho = forma.titulo.length;
    if (tamanho >= 17) return 18;
    if (tamanho >= 12) return 14;
    if (tamanho <= 4) return 8;
    return 10;
  }

  Widget _buildPillPagamento(_FormaPagamentoMobile forma) {
    final selecionado = _formasSelecionadas.contains(forma.codigo);
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      scale: selecionado ? 1.025 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        decoration: BoxDecoration(
          color: selecionado ? _accentColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selecionado ? _accentColor : const Color(0xFFCBD5E1),
          ),
          boxShadow:
              selecionado
                  ? <BoxShadow>[
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : const <BoxShadow>[],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _enviando ? null : () => _alternarFormaPagamento(forma),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  forma.icone,
                  size: 14,
                  color: selecionado ? Colors.white : _accentColor,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    forma.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: selecionado ? Colors.white : _titleTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _alternarFormaPagamento(_FormaPagamentoMobile forma) {
    final selecionado = _formasSelecionadas.contains(forma.codigo);
    setState(() {
      if (selecionado) {
        _formasSelecionadas.remove(forma.codigo);
        _valorPorForma[forma.codigo]?.clear();
        return;
      }
      if (_editandoVendaNaoLiquidada) {
        for (final codigo in List<String>.from(_formasSelecionadas)) {
          _valorPorForma[codigo]?.clear();
        }
        _formasSelecionadas.clear();
      }
      _formasSelecionadas.add(forma.codigo);
      _valorPorForma.putIfAbsent(forma.codigo, () => TextEditingController());
      _destacarPagamento = false;
    });

    if (_editandoVendaNaoLiquidada && !selecionado) {
      _preencherValorRestante(forma.codigo);
    }
  }

  Widget _buildPagamentoHint() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            _destacarPagamento
                ? const Color(0xFFFFF7ED)
                : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _destacarPagamento
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.touch_app_outlined, color: _accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _editandoVendaNaoLiquidada
                  ? 'Revise itens, quantidades e escolha uma forma para receber esta venda.'
                  : 'Toque em uma forma para receber agora ou use Receber depois para deixar a venda em aberto.',
              style: const TextStyle(
                color: _mutedTextColor,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    Key? sectionKey,
    required String titulo,
    required IconData icone,
    required Widget child,
    bool destacar = false,
  }) {
    return AnimatedScale(
      key: sectionKey,
      scale: destacar ? 1.015 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: destacar ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            width: destacar ? 1.6 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color:
                  destacar ? const Color(0x40F59E0B) : const Color(0x0F000000),
              blurRadius: destacar ? 18 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icone, color: _accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(_VendaItemMobile item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.ehServico
                  ? Icons.handyman_outlined
                  : Icons.shopping_bag_outlined,
              color: _accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _titleTextColor,
                  ),
                ),
                Text(
                  _formatarValor(item.valorUnitario),
                  style: const TextStyle(
                    color: _mutedTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _enviando ? null : () => _alterarQuantidade(item, -1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '${item.quantidade}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          IconButton(
            onPressed: _enviando ? null : () => _alterarQuantidade(item, 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  void _alterarQuantidade(_VendaItemMobile item, int delta) {
    setState(() {
      final index = _itens.indexWhere(
        (element) => element.idProduto == item.idProduto,
      );
      if (index < 0) return;
      final novaQuantidade = _itens[index].quantidade + delta;
      if (novaQuantidade <= 0) {
        _itens.removeAt(index);
      } else {
        _itens[index] = _itens[index].copyWith(quantidade: novaQuantidade);
      }
    });

    if (_editandoVendaNaoLiquidada && _formasSelecionadas.length == 1) {
      _preencherValorRestante(_formasSelecionadas.first);
    }
  }

  Widget _buildValorFormaField(String codigo) {
    final forma = _formasPagamento.firstWhere((item) => item.codigo == codigo);
    _valorPorForma.putIfAbsent(codigo, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(forma.icone, size: 19, color: _accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    forma.titulo,
                    style: const TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _enviando ? null : () => _preencherValorRestante(codigo),
                  child: const Text('Completar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valorPorForma[codigo],
              enabled: !_enviando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Valor recebido',
                prefixText: 'R\$ ',
                helperText:
                    _formasSelecionadas.length == 1
                        ? 'Se ficar vazio, o total da venda será usado.'
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total ${_formatarValor(_total)}',
                    style: const TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '$_quantidadeItens item(ns)',
                  style: const TextStyle(
                    color: _mutedTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _enviando ? null : _finalizarVenda,
              icon:
                  _enviando
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        _editandoVendaNaoLiquidada
                            ? Icons.point_of_sale_outlined
                            : Icons.fact_check_outlined,
                      ),
              label: Text(
                _enviando
                    ? 'Enviando...'
                    : (_editandoVendaNaoLiquidada
                        ? 'Receber venda'
                        : 'Finalizar venda'),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _enviando ? null : _receberDepois,
                    icon: Icon(
                      _editandoVendaNaoLiquidada
                          ? Icons.arrow_back_rounded
                          : Icons.schedule_send_outlined,
                    ),
                    label: Text(
                      _editandoVendaNaoLiquidada ? 'Voltar' : 'Receber depois',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _enviando ? null : _cancelarVenda,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 230),
            child:
                _acoesRapidasVisiveis
                    ? Column(
                      key: const ValueKey<String>('acoes-visiveis'),
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildExpandableFabAction(
                          label: 'Código',
                          icon: Icons.qr_code_scanner_rounded,
                          onTap:
                              _enviando || _buscandoCodigo
                                  ? null
                                  : _abrirScannerCodigoBarras,
                          loading: _buscandoCodigo,
                        ),
                        const SizedBox(height: 12),
                        _buildExpandableFabAction(
                          label: 'Item',
                          icon: Icons.add_shopping_cart,
                          onTap: _enviando ? null : _abrirSelecaoProduto,
                        ),
                        const SizedBox(height: 12),
                      ],
                    )
                    : const SizedBox.shrink(
                      key: ValueKey<String>('acoes-ocultas'),
                    ),
          ),
          SizedBox(
            width: 58,
            height: 58,
            child: FloatingActionButton(
              heroTag: 'toggle-actions',
              tooltip:
                  _acoesRapidasVisiveis ? 'Ocultar ações' : 'Mostrar ações',
              onPressed:
                  () => setState(
                    () => _acoesRapidasVisiveis = !_acoesRapidasVisiveis,
                  ),
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: const CircleBorder(),
              child: Icon(
                _acoesRapidasVisiveis ? Icons.close_rounded : Icons.add_rounded,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableFabAction({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    final disabled = onTap == null;
    return Tooltip(
      message: label,
      preferBelow: false,
      child: Semantics(
        label: label,
        button: true,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: disabled ? 0.58 : 1,
          child: Material(
            color: Colors.white,
            elevation: disabled ? 1 : 7,
            shadowColor: Colors.black.withValues(alpha: 0.22),
            shape: const CircleBorder(
              side: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: disabled ? null : onTap,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child:
                      loading
                          ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(
                            icon,
                            size: 20,
                            color: disabled ? _mutedTextColor : _accentColor,
                          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VendaItemMobile {
  const _VendaItemMobile({
    required this.idProduto,
    required this.nome,
    required this.valorUnitario,
    required this.quantidade,
    required this.ehServico,
  });

  factory _VendaItemMobile.fromVendaNaoLiquidadaItem(
    VendaNaoLiquidadaItemModel item,
  ) {
    return _VendaItemMobile(
      idProduto: item.idProduto,
      nome: item.nome,
      valorUnitario: item.valorUnitario,
      quantidade: item.quantidade,
      ehServico: item.ehServico,
    );
  }

  final String idProduto;
  final String nome;
  final double valorUnitario;
  final int quantidade;
  final bool ehServico;

  double get subtotal => valorUnitario * quantidade;

  _VendaItemMobile copyWith({int? quantidade}) {
    return _VendaItemMobile(
      idProduto: idProduto,
      nome: nome,
      valorUnitario: valorUnitario,
      quantidade: quantidade ?? this.quantidade,
      ehServico: ehServico,
    );
  }

  ItemVendaAtual toInput() {
    return ItemVendaAtual(
      idProduto: idProduto,
      nome: nome,
      quantidade: quantidade,
      valorUnitario: valorUnitario,
      ehServico: ehServico,
    );
  }

  VendaNaoLiquidadaItemModel toVendaNaoLiquidadaItem() {
    return VendaNaoLiquidadaItemModel(
      idProduto: idProduto,
      nome: nome,
      quantidade: quantidade,
      valorUnitario: valorUnitario,
      ehServico: ehServico,
    );
  }
}

class _FormaPagamentoMobile {
  const _FormaPagamentoMobile(this.codigo, this.titulo, this.icone);

  final String codigo;
  final String titulo;
  final IconData icone;
}

class _BarcodeScannerMobileScreen extends StatefulWidget {
  const _BarcodeScannerMobileScreen();

  @override
  State<_BarcodeScannerMobileScreen> createState() =>
      _BarcodeScannerMobileScreenState();
}

class _BarcodeScannerMobileScreenState
    extends State<_BarcodeScannerMobileScreen> {
  late final MobileScannerController _controller;
  bool _codigoLido = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ler código de barras'),
      ),
      body: Stack(
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_codigoLido) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final codigo = barcodes.first.rawValue;
              if (codigo == null || codigo.trim().isEmpty) return;
              _codigoLido = true;
              Navigator.of(context).pop(codigo.trim());
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Aponte a câmera para o código do produto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
