import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/di/operacao_module.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/produto_helper.dart';
import '../../data/models/operacao_models.dart';
import '../../data/models/produto_model.dart';
import '../../domain/services/operacao/operacao_service.dart';
import '../../providers/usuario_provider.dart';
import 'produto_list_mobile_screen.dart';

class PdvMobileScreen extends StatefulWidget {
  const PdvMobileScreen({super.key});

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
  final List<_VendaItemMobile> _itens = <_VendaItemMobile>[];
  final Set<String> _formasSelecionadas = <String>{};
  final Map<String, TextEditingController> _valorPorForma = <String, TextEditingController>{};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _pagamentoKey = GlobalKey();

  final List<_FormaPagamentoMobile> _formasPagamento = const <_FormaPagamentoMobile>[
    _FormaPagamentoMobile(codigo: 'TIPO1', titulo: 'Dinheiro', descricao: 'Recebimento no caixa com conferência imediata.', icone: Icons.payments_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO2', titulo: 'Pix', descricao: 'Confirmação rápida por chave, QR Code ou copia e cola.', icone: Icons.qr_code_2_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO3', titulo: 'Cartão de crédito', descricao: 'Recebimento à vista ou parcelado pela operadora.', icone: Icons.credit_card_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO4', titulo: 'Cartão de débito', descricao: 'Liquidação imediata pela maquininha.', icone: Icons.point_of_sale_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO5', titulo: 'Boleto', descricao: 'Pagamento posterior com baixa futura.', icone: Icons.receipt_long_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO6', titulo: 'Fiado', descricao: 'Lançamento em aberto para cobrança posterior.', icone: Icons.history_toggle_off_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO7', titulo: 'Crediário', descricao: 'Parcelamento próprio para cobrança futura.', icone: Icons.event_note_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO8', titulo: 'Convênio', descricao: 'Recebimento vinculado a convênio ou parceria.', icone: Icons.people_outline),
    _FormaPagamentoMobile(codigo: 'TIPO9', titulo: 'Vale', descricao: 'Uso de vale, crédito interno ou voucher.', icone: Icons.confirmation_number_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO10', titulo: 'Outros', descricao: 'Outra forma de recebimento aceita pelo comércio.', icone: Icons.more_horiz_outlined),
  ];

  bool _enviando = false;
  bool _buscandoCodigo = false;
  bool _acoesRapidasVisiveis = false;
  bool _destacarPagamento = false;

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _valorPorForma.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _abrirSelecaoProduto() async {
    final ProdutoModel? produto = await Navigator.push<ProdutoModel>(
      context,
      MaterialPageRoute<ProdutoModel>(builder: (_) => const ProdutolistMobileScreen(isSelecao: true)),
    );
    if (produto == null) return;
    _adicionarProdutoSelecionado(produto);
  }

  Future<void> _abrirScannerCodigoBarras() async {
    if (_enviando || _buscandoCodigo) return;

    final String? codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const _BarcodeScannerMobileScreen()),
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
        onSucesso: (List<ProdutoModel> lista) => produtos = lista,
      );

      final String codigoNormalizado = codigo.toLowerCase();
      ProdutoModel? encontrado;
      for (final ProdutoModel produto in produtos) {
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
      if (!mounted) return;
      _mostrarSnack('Não foi possível buscar o produto pelo código.');
    } finally {
      if (mounted) setState(() => _buscandoCodigo = false);
    }
  }

  void _adicionarProdutoSelecionado(ProdutoModel produto) {
    final String idProduto = produto.id ?? produto.codigoDeBarras;
    final String tipoNormalizado = produto.tipoProduto.toUpperCase();
    final bool ehServico = tipoNormalizado == 'SERVICO' || tipoNormalizado == 'SERVIÇO';

    setState(() {
      final int index = _itens.indexWhere((item) => item.idProduto == idProduto);
      if (index >= 0) {
        _itens[index] = _itens[index].copyWith(quantidade: _itens[index].quantidade + 1);
      } else {
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
    });
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

    final formas = _montarFormasPagamento();
    final double totalPago = formas.fold<double>(0, (soma, forma) => soma + forma.valor);
    if ((totalPago - _total).abs() > 0.009) {
      _mostrarSnack('A soma dos pagamentos precisa fechar o total da venda.');
      return;
    }

    await _enviarVenda(receberDepois: false, formasPagamento: formas);
  }

  Future<void> _avisarPagamentoObrigatorio() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (!_destacarPagamento && mounted) setState(() => _destacarPagamento = true);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    final BuildContext? pagamentoContext = _pagamentoKey.currentContext;
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
    if (_itens.isEmpty) {
      _mostrarSnack('Inclua pelo menos um item para registrar a venda.');
      return;
    }

    final bool? confirmou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(999)),
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
                          Text('Receber depois', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          Text('A venda ficará em aberto para liquidação no caixa.', style: theme.textTheme.bodyMedium?.copyWith(color: _mutedTextColor)),
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
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Voltar'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmou == true) {
      await _enviarVenda(receberDepois: true, formasPagamento: <FormaPagamentoSelecionada>[]);
    }
  }

  Future<void> _enviarVenda({required bool receberDepois, required List<FormaPagamentoSelecionada> formasPagamento}) async {
    setState(() => _enviando = true);
    try {
      final String idColaborador = await AuthService().getUserId() ?? '';
      final String nomeColaborador = _nomeColaboradorAtual();
      final DateTime dataOperacao = DateTime.now();

      final input = OperacaoVendaInput(
        descricao: receberDepois ? 'Venda mobile para receber depois ${dataOperacao.toIso8601String()}' : 'Venda mobile ${dataOperacao.toIso8601String()}',
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
      _mostrarSnack(receberDepois ? 'Venda registrada para receber depois.' : 'Venda finalizada com sucesso.');
    } catch (e) {
      if (!mounted) return;
      _mostrarSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
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
    _limparVenda();
    _mostrarSnack('Venda cancelada.');
  }

  Widget _modalIcon(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: _accentColor.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: _accentColor),
    );
  }

  Widget _buildResumoReceberDepois() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _accentColor.withOpacity(0.07), borderRadius: BorderRadius.circular(22), border: Border.all(color: _accentColor.withOpacity(0.16))),
      child: Row(
        children: <Widget>[
          const Expanded(child: Text('Valor em aberto', style: TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900))),
          Text(_formatarValor(_total), style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  List<FormaPagamentoSelecionada> _montarFormasPagamento() {
    if (_formasSelecionadas.length == 1) {
      final String codigo = _formasSelecionadas.first;
      final double valorDigitado = _valorDigitadoForma(codigo);
      return <FormaPagamentoSelecionada>[FormaPagamentoSelecionada(codigo: codigo, valor: valorDigitado > 0 ? valorDigitado : _total)];
    }
    return _formasSelecionadas.map((codigo) => FormaPagamentoSelecionada(codigo: codigo, valor: _valorDigitadoForma(codigo))).toList(growable: false);
  }

  double _valorDigitadoForma(String codigoForma) {
    final raw = _valorPorForma[codigoForma]?.text ?? '';
    final normalizado = raw.replaceAll('R\$', '').replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0.0;
  }

  double _valorSelecionadoTotal() {
    if (_formasSelecionadas.isEmpty) return 0.0;
    return _montarFormasPagamento().fold<double>(0.0, (double soma, FormaPagamentoSelecionada forma) => soma + forma.valor);
  }

  double _valorRestante() => _total - _valorSelecionadoTotal();

  void _preencherValorRestante(String codigoForma) {
    _valorPorForma.putIfAbsent(codigoForma, () => TextEditingController());
    final TextEditingController controller = _valorPorForma[codigoForma]!;
    final double atual = _valorDigitadoForma(codigoForma);
    final double restante = _valorRestante();
    final double novoValor = (atual + restante).clamp(0.0, _total).toDouble();

    setState(() {
      controller.text = novoValor.toStringAsFixed(2);
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      _formasSelecionadas.add(codigoForma);
      _destacarPagamento = false;
    });
  }

  String _nomeColaboradorAtual() {
    final usuario = UsuarioProvider().usuario;
    if (usuario == null) return 'Colaborador';
    if (usuario.nomeDeGuerra.trim().isNotEmpty) return usuario.nomeDeGuerra.trim();
    final nomeCompleto = '${usuario.nome} ${usuario.sobrenome}'.trim();
    return nomeCompleto.isEmpty ? 'Colaborador' : nomeCompleto;
  }

  double get _total => _itens.fold<double>(0, (soma, item) => soma + item.subtotal);

  int get _quantidadeItens => _itens.fold<int>(0, (soma, item) => soma + item.quantidade);

  String _formatarValor(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final bool temItens = _itens.isNotEmpty;
    final double bottomPadding = temItens ? (_acoesRapidasVisiveis ? 218 : 142) : 110;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text('PDV - Ponto de Venda', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          children: <Widget>[
            _buildHeader().animate().fade(duration: 320.ms).slideY(begin: 0.04, curve: Curves.easeOut),
            const SizedBox(height: 16),
            if (_itens.isEmpty) _buildEstadoVazio() else ...<Widget>[_buildItensCard(), const SizedBox(height: 14), _buildPagamentoCard()],
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
        gradient: const LinearGradient(colors: [_primaryColor, Color(0xFF123B69)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x260B1F3A), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        children: <Widget>[
          Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.point_of_sale_outlined, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Balcão de venda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('$_quantidadeItens item(ns) • ${_formatarValor(_total)}', style: const TextStyle(color: Color(0xFFD7E3F5), fontWeight: FontWeight.w700)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: <Widget>[
          Container(width: 76, height: 76, decoration: BoxDecoration(color: _accentColor.withOpacity(0.10), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.add_shopping_cart, color: _accentColor, size: 36)),
          const SizedBox(height: 16),
          const Text('Venda ainda vazia', style: TextStyle(color: _titleTextColor, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Inclua produtos ou serviços para liberar a finalização ou o recebimento posterior.', textAlign: TextAlign.center, style: TextStyle(color: _mutedTextColor, height: 1.4)),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: _abrirSelecaoProduto, icon: const Icon(Icons.add_rounded), label: const Text('Adicionar produto ou serviço')),
        ],
      ),
    );
  }

  Widget _buildItensCard() {
    return _buildSectionCard(
      titulo: 'Itens da venda',
      icone: Icons.inventory_2_outlined,
      child: Column(children: _itens.map(_buildItemTile).toList(growable: false)),
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<List<_FormaPagamentoMobile>> linhas = _montarLinhasPagamento(constraints.maxWidth);

        return Column(
          children: linhas.map((List<_FormaPagamentoMobile> linha) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: linha.asMap().entries.map((MapEntry<int, _FormaPagamentoMobile> entry) {
                  final _FormaPagamentoMobile forma = entry.value;
                  return Expanded(
                    flex: _flexFormaPagamento(forma),
                    child: Padding(
                      padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 8),
                      child: _buildPillPagamento(forma),
                    ),
                  );
                }).toList(growable: false),
              ),
            );
          }).toList(growable: false),
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
        <_FormaPagamentoMobile>[_formasPagamento[7], _formasPagamento[8], _formasPagamento[9]],
      ];
    }

    if (largura < 430) {
      return <List<_FormaPagamentoMobile>>[
        <_FormaPagamentoMobile>[_formasPagamento[0], _formasPagamento[1], _formasPagamento[4]],
        <_FormaPagamentoMobile>[_formasPagamento[2], _formasPagamento[3]],
        <_FormaPagamentoMobile>[_formasPagamento[5], _formasPagamento[6], _formasPagamento[8]],
        <_FormaPagamentoMobile>[_formasPagamento[7], _formasPagamento[9]],
      ];
    }

    return <List<_FormaPagamentoMobile>>[
      <_FormaPagamentoMobile>[_formasPagamento[0], _formasPagamento[1], _formasPagamento[4], _formasPagamento[9]],
      <_FormaPagamentoMobile>[_formasPagamento[2], _formasPagamento[3], _formasPagamento[6]],
      <_FormaPagamentoMobile>[_formasPagamento[5], _formasPagamento[7], _formasPagamento[8]],
    ];
  }

  int _flexFormaPagamento(_FormaPagamentoMobile forma) {
    final int tamanho = forma.titulo.length;
    if (tamanho >= 17) return 18;
    if (tamanho >= 12) return 14;
    if (tamanho <= 4) return 8;
    return 10;
  }

  Widget _buildPillPagamento(_FormaPagamentoMobile forma) {
    final bool selecionado = _formasSelecionadas.contains(forma.codigo);

    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      scale: selecionado ? 1.025 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 36,
        decoration: BoxDecoration(
          color: selecionado ? _accentColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selecionado ? _accentColor : const Color(0xFFCBD5E1), width: selecionado ? 1.25 : 1),
          boxShadow: selecionado ? <BoxShadow>[BoxShadow(color: _accentColor.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4))] : const <BoxShadow>[],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _enviando
                ? null
                : () {
                    setState(() {
                      if (selecionado) {
                        _formasSelecionadas.remove(forma.codigo);
                        _valorPorForma[forma.codigo]?.clear();
                      } else {
                        _formasSelecionadas.add(forma.codigo);
                        _valorPorForma.putIfAbsent(forma.codigo, () => TextEditingController());
                        _destacarPagamento = false;
                      }
                    });
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(forma.icone, size: 14, color: selecionado ? Colors.white : _accentColor),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      forma.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1, fontWeight: FontWeight.w900, color: selecionado ? Colors.white : _titleTextColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagamentoHint() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _destacarPagamento ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _destacarPagamento ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: const <Widget>[
          Icon(Icons.touch_app_outlined, color: _accentColor),
          SizedBox(width: 10),
          Expanded(child: Text('Toque em uma forma para receber agora ou use Receber depois para deixar a venda em aberto.', style: TextStyle(color: _mutedTextColor, height: 1.35, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildSectionCard({Key? sectionKey, required String titulo, required IconData icone, required Widget child, bool destacar = false}) {
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
          border: Border.all(color: destacar ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0), width: destacar ? 1.6 : 1),
          boxShadow: <BoxShadow>[BoxShadow(color: destacar ? const Color(0x40F59E0B) : const Color(0x0F000000), blurRadius: destacar ? 18 : 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[Icon(icone, color: _accentColor), const SizedBox(width: 8), Text(titulo, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900, fontSize: 16))]),
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
          Container(width: 44, height: 44, decoration: BoxDecoration(color: _accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(14)), child: Icon(item.ehServico ? Icons.handyman_outlined : Icons.shopping_bag_outlined, color: _accentColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(item.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: _titleTextColor)), Text(_formatarValor(item.valorUnitario), style: const TextStyle(color: _mutedTextColor, fontWeight: FontWeight.w700))]),
          ),
          IconButton(onPressed: _enviando ? null : () => _alterarQuantidade(item, -1), icon: const Icon(Icons.remove_circle_outline)),
          Text('${item.quantidade}', style: const TextStyle(fontWeight: FontWeight.w900)),
          IconButton(onPressed: _enviando ? null : () => _alterarQuantidade(item, 1), icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
    );
  }

  void _alterarQuantidade(_VendaItemMobile item, int delta) {
    setState(() {
      final index = _itens.indexWhere((element) => element.idProduto == item.idProduto);
      if (index < 0) return;
      final novaQuantidade = _itens[index].quantidade + delta;
      if (novaQuantidade <= 0) {
        _itens.removeAt(index);
      } else {
        _itens[index] = _itens[index].copyWith(quantidade: novaQuantidade);
      }
    });
  }

  Widget _buildValorFormaField(String codigo) {
    final forma = _formasPagamento.firstWhere((item) => item.codigo == codigo);
    _valorPorForma.putIfAbsent(codigo, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(forma.icone, size: 19, color: _accentColor),
                const SizedBox(width: 8),
                Expanded(child: Text(forma.titulo, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900))),
                TextButton(onPressed: _enviando ? null : () => _preencherValorRestante(codigo), child: const Text('Completar')),
              ],
            ),
            const SizedBox(height: 2),
            Text(forma.descricao, style: const TextStyle(color: _mutedTextColor, height: 1.3, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _valorPorForma[codigo],
              enabled: !_enviando,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Valor recebido',
                prefixText: 'R\$ ',
                helperText: _formasSelecionadas.length == 1 ? 'Se ficar vazio, o total da venda será usado.' : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(children: <Widget>[Expanded(child: Text('Total ${_formatarValor(_total)}', style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900, fontSize: 16))), Text('$_quantidadeItens item(ns)', style: const TextStyle(color: _mutedTextColor, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: _enviando ? null : _finalizarVenda, icon: _enviando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.fact_check_outlined), label: Text(_enviando ? 'Enviando...' : 'Finalizar venda'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(child: OutlinedButton.icon(onPressed: _enviando ? null : _receberDepois, icon: const Icon(Icons.schedule_send_outlined), label: const Text('Receber depois'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: _enviando ? null : _cancelarVenda, icon: const Icon(Icons.close_rounded), label: const Text('Cancelar'), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
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
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: 1,
                  child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1).animate(animation), child: child),
                ),
              );
            },
            child: _acoesRapidasVisiveis
                ? Column(
                    key: const ValueKey<String>('acoes-visiveis'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _buildExpandableFabAction(label: 'Código', icon: Icons.qr_code_scanner_rounded, onTap: _enviando || _buscandoCodigo ? null : _abrirScannerCodigoBarras, loading: _buscandoCodigo),
                      const SizedBox(height: 12),
                      _buildExpandableFabAction(label: 'Item', icon: Icons.add_shopping_cart, onTap: _enviando ? null : _abrirSelecaoProduto),
                      const SizedBox(height: 12),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey<String>('acoes-ocultas')),
          ),
          SizedBox(
            width: 58,
            height: 58,
            child: FloatingActionButton(
              heroTag: 'toggle-actions',
              tooltip: _acoesRapidasVisiveis ? 'Ocultar ações' : 'Mostrar ações',
              onPressed: () => setState(() => _acoesRapidasVisiveis = !_acoesRapidasVisiveis),
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: const CircleBorder(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return RotationTransition(turns: Tween<double>(begin: -0.12, end: 0).animate(animation), child: FadeTransition(opacity: animation, child: child));
                },
                child: Icon(_acoesRapidasVisiveis ? Icons.close_rounded : Icons.add_rounded, key: ValueKey<bool>(_acoesRapidasVisiveis), size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableFabAction({required String label, required IconData icon, required VoidCallback? onTap, bool loading = false}) {
    final bool disabled = onTap == null;
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
            shadowColor: Colors.black.withOpacity(0.22),
            shape: const CircleBorder(side: BorderSide(color: Color(0xFFE2E8F0))),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: disabled ? null : onTap,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: loading ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 20, color: disabled ? _mutedTextColor : _accentColor),
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
  const _VendaItemMobile({required this.idProduto, required this.nome, required this.valorUnitario, required this.quantidade, required this.ehServico});

  final String idProduto;
  final String nome;
  final double valorUnitario;
  final int quantidade;
  final bool ehServico;

  double get subtotal => valorUnitario * quantidade;

  _VendaItemMobile copyWith({int? quantidade}) {
    return _VendaItemMobile(idProduto: idProduto, nome: nome, valorUnitario: valorUnitario, quantidade: quantidade ?? this.quantidade, ehServico: ehServico);
  }

  ItemVendaAtual toInput() {
    return ItemVendaAtual(idProduto: idProduto, nome: nome, quantidade: quantidade, valorUnitario: valorUnitario, ehServico: ehServico);
  }
}

class _FormaPagamentoMobile {
  const _FormaPagamentoMobile({required this.codigo, required this.titulo, required this.descricao, required this.icone});

  final String codigo;
  final String titulo;
  final String descricao;
  final IconData icone;
}

class _BarcodeScannerMobileScreen extends StatefulWidget {
  const _BarcodeScannerMobileScreen();

  @override
  State<_BarcodeScannerMobileScreen> createState() => _BarcodeScannerMobileScreenState();
}

class _BarcodeScannerMobileScreenState extends State<_BarcodeScannerMobileScreen> {
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
            onDetect: (BarcodeCapture capture) {
              if (_codigoLido) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final String? codigo = barcodes.first.rawValue;
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
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(20)),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.58), borderRadius: BorderRadius.circular(18)),
              child: const Text('Aponte a câmera para o código do produto.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
