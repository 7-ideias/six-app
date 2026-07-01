import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/venda_nao_liquidada_models.dart';
import '../../data/services/caixa/venda_nao_liquidada_api_client.dart';
import 'pdv_mobile_screen.dart';

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

  bool _loading = true;
  String? _erro;
  List<VendaNaoLiquidadaModel> _vendas = <VendaNaoLiquidadaModel>[];

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

  Future<void> _abrirVendaNoPdv(VendaNaoLiquidadaModel venda) async {
    final bool? recebeu = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PdvMobileScreen(vendaNaoLiquidada: venda),
      ),
    );

    if (recebeu == true) {
      await _carregar();
    }
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
    final int quantidadeItens = venda.itens.fold<int>(0, (soma, item) => soma + item.quantidade);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirVendaNoPdv(venda),
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
                child: const Icon(Icons.receipt_long_outlined, color: _accentColor),
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
                    Text('${_formatarData(venda.dataCompetencia)} • $quantidadeItens item(ns)', style: const TextStyle(color: _mutedTextColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(_formatarValor(venda.valorAberto), style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 4),
                  const Text('Abrir PDV', style: TextStyle(color: _accentColor, fontWeight: FontWeight.w900, fontSize: 12)),
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
