import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/di/operacao_module.dart';
import '../../core/services/auth_service.dart';
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

  final List<_FormaPagamentoMobile> _formasPagamento = const <_FormaPagamentoMobile>[
    _FormaPagamentoMobile(codigo: 'TIPO1', titulo: 'Dinheiro', icone: Icons.payments_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO2', titulo: 'Pix', icone: Icons.qr_code_2_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO3', titulo: 'Crédito', icone: Icons.credit_card_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO4', titulo: 'Débito', icone: Icons.point_of_sale_outlined),
    _FormaPagamentoMobile(codigo: 'TIPO10', titulo: 'Outros', icone: Icons.more_horiz_outlined),
  ];

  bool _enviando = false;

  @override
  void dispose() {
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
      _mostrarSnack('Selecione uma forma de pagamento ou use Receber depois.');
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 126),
          children: <Widget>[
            _buildHeader().animate().fade(duration: 320.ms).slideY(begin: 0.04, curve: Curves.easeOut),
            const SizedBox(height: 16),
            if (_itens.isEmpty) _buildEstadoVazio() else ...<Widget>[_buildItensCard(), const SizedBox(height: 14), _buildPagamentoCard()],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enviando ? null : _abrirSelecaoProduto,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Item'),
      ),
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
      titulo: 'Pagamento',
      icone: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(spacing: 8, runSpacing: 8, children: _formasPagamento.map(_buildFormaChip).toList(growable: false)),
          if (_formasSelecionadas.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ..._formasSelecionadas.map(_buildValorFormaField),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String titulo, required IconData icone, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[Icon(icone, color: _accentColor), const SizedBox(width: 8), Text(titulo, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900, fontSize: 16))]),
          const SizedBox(height: 12),
          child,
        ],
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

  Widget _buildFormaChip(_FormaPagamentoMobile forma) {
    final bool selecionada = _formasSelecionadas.contains(forma.codigo);
    return FilterChip(
      selected: selecionada,
      avatar: Icon(forma.icone, size: 16, color: selecionada ? Colors.white : _accentColor),
      label: Text(forma.titulo),
      selectedColor: _accentColor,
      labelStyle: TextStyle(color: selecionada ? Colors.white : _titleTextColor, fontWeight: FontWeight.w800),
      onSelected: _enviando
          ? null
          : (bool value) {
              setState(() {
                if (value) {
                  _formasSelecionadas.add(forma.codigo);
                  _valorPorForma.putIfAbsent(forma.codigo, () => TextEditingController(text: _formasSelecionadas.length == 1 ? _total.toStringAsFixed(2) : ''));
                } else {
                  _formasSelecionadas.remove(forma.codigo);
                  _valorPorForma[forma.codigo]?.clear();
                }
              });
            },
    );
  }

  Widget _buildValorFormaField(String codigo) {
    final forma = _formasPagamento.firstWhere((item) => item.codigo == codigo);
    _valorPorForma.putIfAbsent(codigo, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _valorPorForma[codigo],
        enabled: !_enviando,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: 'Valor ${forma.titulo}', prefixText: 'R\$ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), isDense: true),
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
  const _FormaPagamentoMobile({required this.codigo, required this.titulo, required this.icone});

  final String codigo;
  final String titulo;
  final IconData icone;
}
