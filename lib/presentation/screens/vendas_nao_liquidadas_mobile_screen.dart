import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/venda_nao_liquidada_models.dart';
import '../../data/services/caixa/venda_nao_liquidada_api_client.dart';

class VendasNaoLiquidadasMobileScreen extends StatefulWidget {
  const VendasNaoLiquidadasMobileScreen({super.key});

  @override
  State<VendasNaoLiquidadasMobileScreen> createState() => _VendasNaoLiquidadasMobileScreenState();
}

class _VendasNaoLiquidadasMobileScreenState extends State<VendasNaoLiquidadasMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  final VendaNaoLiquidadaApiClient _apiClient = VendaNaoLiquidadaApiClient();
  final List<_FormaRecebimentoMobile> _formas = const <_FormaRecebimentoMobile>[
    _FormaRecebimentoMobile(codigo: 'tipo1', titulo: 'Dinheiro', icone: Icons.payments_outlined),
    _FormaRecebimentoMobile(codigo: 'tipo2', titulo: 'Pix', icone: Icons.qr_code_2_outlined),
    _FormaRecebimentoMobile(codigo: 'tipo3', titulo: 'Cartão crédito', icone: Icons.credit_card_outlined),
    _FormaRecebimentoMobile(codigo: 'tipo4', titulo: 'Cartão débito', icone: Icons.point_of_sale_outlined),
    _FormaRecebimentoMobile(codigo: 'tipo10', titulo: 'Outros', icone: Icons.more_horiz_outlined),
  ];

  bool _loading = true;
  String? _erro;
  List<VendaNaoLiquidadaModel> _vendas = <VendaNaoLiquidadaModel>[];
  String _formaSelecionada = 'tipo1';
  String? _liquidandoId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final vendas = await _apiClient.listar();
      if (!mounted) return;
      setState(() => _vendas = vendas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmarLiquidacao(VendaNaoLiquidadaModel venda) async {
    final bool? confirmou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        final ThemeData theme = Theme.of(bottomSheetContext);
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Row(
                  children: <Widget>[
                    _modalIcon(Icons.point_of_sale_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Receber venda', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          Text('Confirme a forma de recebimento.', style: theme.textTheme.bodyMedium?.copyWith(color: _mutedTextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildResumoLiquidacao(venda),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _formas.map((forma) => _buildFormaChip(forma)).toList(growable: false),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Receber ${_formatarValor(venda.valorAberto)}'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmou == true) {
      await _liquidar(venda);
    }
  }

  Future<void> _liquidar(VendaNaoLiquidadaModel venda) async {
    setState(() => _liquidandoId = venda.idRecebimento);
    try {
      await _apiClient.liquidar(
        idRecebimento: venda.idRecebimento,
        input: LiquidarVendaNaoLiquidadaInput(
          codigoTipoRecebimento: _formaSelecionada,
          valorRecebido: venda.valorAberto,
          observacao: 'Recebido pelo mobile',
        ),
      );
      if (!mounted) return;
      _mostrarSnack('Venda recebida com sucesso.');
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _mostrarSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _liquidandoId = null);
    }
  }

  Widget _modalIcon(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: _accentColor.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: _accentColor),
    );
  }

  Widget _buildResumoLiquidacao(VendaNaoLiquidadaModel venda) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accentColor.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(venda.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: _titleTextColor)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Expanded(child: Text('Valor em aberto', style: TextStyle(color: _mutedTextColor, fontWeight: FontWeight.w700))),
              Text(_formatarValor(venda.valorAberto), style: const TextStyle(color: _titleTextColor, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormaChip(_FormaRecebimentoMobile forma) {
    final bool selecionada = _formaSelecionada == forma.codigo;
    return ChoiceChip(
      selected: selecionada,
      avatar: Icon(forma.icone, size: 16, color: selecionada ? Colors.white : _accentColor),
      label: Text(forma.titulo),
      selectedColor: _accentColor,
      labelStyle: TextStyle(color: selecionada ? Colors.white : _titleTextColor, fontWeight: FontWeight.w800),
      onSelected: (_) => setState(() => _formaSelecionada = forma.codigo),
    );
  }

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _formatarValor(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  String _formatarData(DateTime? data) {
    if (data == null) return 'Sem data';
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(data.day)}/${twoDigits(data.month)}/${data.year} ${twoDigits(data.hour)}:${twoDigits(data.minute)}';
  }

  double get _totalAberto => _vendas.fold<double>(0, (soma, venda) => soma + venda.valorAberto);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Vendas a receber', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: <Widget>[
          IconButton(onPressed: _loading ? null : _carregar, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return _buildEstadoMensagem(Icons.error_outline, 'Não foi possível carregar', _erro!, recarregar: true);
    }

    if (_vendas.isEmpty) {
      return _buildEstadoMensagem(Icons.check_circle_outline, 'Nenhuma venda em aberto', 'Quando uma venda for marcada para receber depois, ela aparecerá aqui.', recarregar: true);
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          _buildHeaderResumo().animate().fade(duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOut),
          const SizedBox(height: 16),
          ..._vendas.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildVendaCard(entry.value).animate().fade(duration: 320.ms, delay: (70 + entry.key * 35).ms).slideY(begin: 0.04, curve: Curves.easeOut),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderResumo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primaryColor, Color(0xFF123B69)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x260B1F3A), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x33FFFFFF))),
            child: const Icon(Icons.point_of_sale_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Caixa a receber', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${_vendas.length} venda(s) aguardando liquidação', style: const TextStyle(color: Color(0xFFD7E3F5), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(_formatarValor(_totalAberto), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildVendaCard(VendaNaoLiquidadaModel venda) {
    final bool liquidando = _liquidandoId == venda.idRecebimento;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: liquidando ? null : () => _confirmarLiquidacao(venda),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
                child: liquidando
                    ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.receipt_long_outlined, color: _accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(venda.descricao, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Criada por ${venda.nomeColaboradorCriacao.isEmpty ? 'colaborador' : venda.nomeColaboradorCriacao}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_formatarData(venda.dataCompetencia), style: const TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(_formatarValor(venda.valorAberto), style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 4),
                  const Text('Receber', style: TextStyle(color: _accentColor, fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoMensagem(IconData icon, String titulo, String mensagem, {bool recarregar = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: _accentColor.withOpacity(0.10), borderRadius: BorderRadius.circular(24)),
              child: Icon(icon, color: _accentColor, size: 36),
            ),
            const SizedBox(height: 18),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(color: _titleTextColor, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: _mutedTextColor, height: 1.4)),
            if (recarregar) ...<Widget>[
              const SizedBox(height: 18),
              OutlinedButton.icon(onPressed: _carregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormaRecebimentoMobile {
  const _FormaRecebimentoMobile({required this.codigo, required this.titulo, required this.icone});

  final String codigo;
  final String titulo;
  final IconData icone;
}
