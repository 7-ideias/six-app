import 'package:flutter/material.dart';

import '../../data/models/venda_nao_liquidada_models.dart';
import '../../data/services/caixa/venda_nao_liquidada_api_client.dart';
import 'pdv_mobile_screen.dart';

class VendasNaoLiquidadasMobileScreen extends StatefulWidget {
  const VendasNaoLiquidadasMobileScreen({super.key});

  @override
  State<VendasNaoLiquidadasMobileScreen> createState() =>
      _VendasNaoLiquidadasMobileScreenState();
}

class _VendasNaoLiquidadasMobileScreenState
    extends State<VendasNaoLiquidadasMobileScreen> {
  static const Color _bg = Color(0xFFF4F7FB);
  static const Color _primary = Color(0xFF0B1F3A);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _muted = Color(0xFF64748B);
  static const Color _title = Color(0xFF0F172A);

  final VendaNaoLiquidadaApiClient _api = VendaNaoLiquidadaApiClient();

  bool _loading = true;
  bool _cancelando = false;
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
      final vendas = await _api.listar();
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

    if (!mounted) return;
    if (recebeu == true) {
      await _carregar();
    } else if (recebeu == false) {
      await _confirmarCancelamentoVenda(venda);
    }
  }

  Future<void> _confirmarCancelamentoVenda(VendaNaoLiquidadaModel venda) async {
    final bool? confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar venda em aberto?'),
        content: Text(
          '${venda.descricao}\n${_formatarValor(venda.valorAberto)}\n\n'
          'Esta ação apaga a operação e devolve os produtos ao estoque quando aplicável.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmou == true) await _cancelarVendaNaoLiquidada(venda);
  }

  Future<void> _cancelarVendaNaoLiquidada(VendaNaoLiquidadaModel venda) async {
    if (_cancelando) return;
    setState(() => _cancelando = true);
    try {
      await _api.cancelar(idRecebimento: venda.idRecebimento);
      if (!mounted) return;
      _snack('Venda em aberto cancelada.');
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatarValor(double valor) =>
      'R${String.fromCharCode(36)} ${valor.toStringAsFixed(2)}';

  String _formatarData(DateTime? data) {
    if (data == null) return 'Sem data';
    String d(int value) => value.toString().padLeft(2, '0');
    return '${d(data.day)}/${d(data.month)}/${data.year} ${d(data.hour)}:${d(data.minute)}';
  }

  double get _totalAberto =>
      _vendas.fold<double>(0, (soma, venda) => soma + venda.valorAberto);

  double get _ticketMedio => _vendas.isEmpty ? 0 : _totalAberto / _vendas.length;

  int get _totalItens => _vendas.fold<int>(
        0,
        (soma, venda) =>
            soma + venda.itens.fold<int>(0, (itens, item) => itens + item.quantidade),
      );

  int get _vencidas {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    return _vendas
        .where((venda) =>
            venda.dataVencimento != null && venda.dataVencimento!.isBefore(inicioHoje))
        .length;
  }

  int get _venceHoje {
    final hoje = DateTime.now();
    return _vendas.where((venda) {
      final vencimento = venda.dataVencimento;
      return vencimento != null &&
          vencimento.year == hoje.year &&
          vencimento.month == hoje.month &&
          vencimento.day == hoje.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Vendas a receber',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _loading || _cancelando ? null : _carregar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return _estado(Icons.error_outline, 'Não foi possível carregar', _erro!);
    }

    return Stack(
      children: <Widget>[
        RefreshIndicator(
          onRefresh: _carregar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: <Widget>[
              _header(),
              const SizedBox(height: 14),
              _metrics(),
              const SizedBox(height: 14),
              _planejados(),
              const SizedBox(height: 18),
              _section('Vendas em aberto'),
              const SizedBox(height: 12),
              if (_vendas.isEmpty)
                _empty()
              else
                ..._vendas.map(
                  (venda) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _vendaCard(venda),
                  ),
                ),
            ],
          ),
        ),
        if (_cancelando)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_primary, Color(0xFF123B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x260B1F3A), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: <Widget>[
          _icon(Icons.point_of_sale_outlined, bg: const Color(0x1AFFFFFF), fg: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Dashboard de recebimentos',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_vendas.length} venda(s) aguardando liquidação',
                  style: const TextStyle(color: Color(0xFFD7E3F5), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Text(
            _formatarValor(_totalAberto),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _metrics() {
    final metrics = <_Metric>[
      _Metric('Total aberto', _formatarValor(_totalAberto), Icons.account_balance_wallet_outlined),
      _Metric('Vendas', _vendas.length.toString(), Icons.receipt_long_outlined),
      _Metric('Ticket médio', _formatarValor(_ticketMedio), Icons.trending_up_rounded),
      _Metric('Itens', _totalItens.toString(), Icons.inventory_2_outlined),
      _Metric('Vencidas', _vencidas.toString(), Icons.warning_amber_rounded),
      _Metric('Vence hoje', _venceHoje.toString(), Icons.today_rounded),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics.map((metric) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 42) / 2,
          child: _baseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _icon(metric.icon, bg: const Color(0xFFEFF6FF), fg: _accent, size: 38),
                const SizedBox(height: 10),
                Text(metric.title, style: const TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _title, fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _planejados() {
    return Row(
      children: <Widget>[
        Expanded(child: _planned('Previsão 7 dias', 'Em breve', Icons.auto_graph_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _planned('Risco de atraso', 'Baixo', Icons.insights_rounded)),
      ],
    );
  }

  Widget _planned(String title, String value, IconData icon) {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(icon, bg: const Color(0xFFF1F5F9), fg: _primary, size: 36),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Planejado',
                  style: TextStyle(color: Color(0xFFC2410C), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text(
            'Mockado para futuro painel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _vendaCard(VendaNaoLiquidadaModel venda) {
    final int quantidadeItens =
        venda.itens.fold<int>(0, (soma, item) => soma + item.quantidade);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _cancelando ? null : () => _abrirVendaNoPdv(venda),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            children: <Widget>[
              _icon(Icons.receipt_long_outlined, bg: const Color(0xFFEFF6FF), fg: _accent, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      venda.descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _title, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Criada por ${venda.nomeColaboradorCriacao.isEmpty ? 'colaborador' : venda.nomeColaboradorCriacao}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatarData(venda.dataCompetencia)} • $quantidadeItens item(ns)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    _formatarValor(venda.valorAberto),
                    style: const TextStyle(color: _title, fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  const Text('Abrir PDV', style: TextStyle(color: _accent, fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return _baseCard(
      child: const Column(
        children: <Widget>[
          Icon(Icons.check_circle_outline, color: _accent, size: 34),
          SizedBox(height: 10),
          Text('Nenhuma venda em aberto', style: TextStyle(color: _title, fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text(
            'Quando uma venda for marcada para receber depois, ela aparecerá aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _estado(IconData icon, String titulo, String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _icon(icon, bg: _accent.withValues(alpha: 0.10), fg: _accent, size: 76),
            const SizedBox(height: 18),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(color: _title, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.4)),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: _carregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
          ],
        ),
      ),
    );
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Widget _icon(IconData icon, {required Color bg, required Color fg, double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size >= 48 ? 18 : 14)),
      child: Icon(icon, color: fg, size: size >= 48 ? 24 : 20),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}

class _Metric {
  const _Metric(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}
