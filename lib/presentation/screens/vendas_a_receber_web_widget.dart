import 'package:flutter/material.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/venda_nao_liquidada_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/caixa/venda_nao_liquidada_api_client.dart';

class VendasAReceberWebWidget extends StatefulWidget {
  const VendasAReceberWebWidget({super.key});

  @override
  State<VendasAReceberWebWidget> createState() => _VendasAReceberWebWidgetState();
}

class _VendasAReceberWebWidgetState extends State<VendasAReceberWebWidget> {
  static const Color _bg = Color(0xFFF4F7FB);
  static const Color _primary = Color(0xFF0B1F3A);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _muted = Color(0xFF64748B);
  static const Color _title = Color(0xFF0F172A);

  final VendaNaoLiquidadaApiClient _api = VendaNaoLiquidadaApiClient();
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();

  bool _loading = true;
  bool _processando = false;
  String? _erro;
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now().add(const Duration(days: 30));
  List<VendaNaoLiquidadaModel> _vendas = <VendaNaoLiquidadaModel>[];
  List<_TipoRecebimentoOpcao> _tiposRecebimento = <_TipoRecebimentoOpcao>[
    const _TipoRecebimentoOpcao(codigo: 'TIPO1', descricao: 'Dinheiro'),
    const _TipoRecebimentoOpcao(codigo: 'TIPO2', descricao: 'Pix'),
    const _TipoRecebimentoOpcao(codigo: 'TIPO3', descricao: 'Cartão de crédito'),
    const _TipoRecebimentoOpcao(codigo: 'TIPO4', descricao: 'Cartão de débito'),
    const _TipoRecebimentoOpcao(codigo: 'TIPO5', descricao: 'Boleto'),
  ];

  List<VendaNaoLiquidadaModel> get _vendasFiltradas {
    final DateTime inicio = _inicioDoDia(_dataInicio);
    final DateTime fim = _fimDoDia(_dataFim);
    return _vendas.where((VendaNaoLiquidadaModel venda) {
      final DateTime? data = venda.dataVencimento ?? venda.dataCompetencia;
      if (data == null) return true;
      return !data.isBefore(inicio) && !data.isAfter(fim);
    }).toList(growable: false);
  }

  double get _totalAberto => _vendasFiltradas.fold<double>(0, (double soma, VendaNaoLiquidadaModel venda) => soma + venda.valorAberto);
  double get _ticketMedio => _vendasFiltradas.isEmpty ? 0 : _totalAberto / _vendasFiltradas.length;
  int get _totalItens => _vendasFiltradas.fold<int>(0, (int soma, VendaNaoLiquidadaModel venda) => soma + venda.itens.fold<int>(0, (int itens, VendaNaoLiquidadaItemModel item) => itens + item.quantidade));

  int get _vencidas {
    final DateTime hoje = DateTime.now();
    final DateTime inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    return _vendasFiltradas.where((VendaNaoLiquidadaModel venda) => venda.dataVencimento != null && venda.dataVencimento!.isBefore(inicioHoje)).length;
  }

  int get _venceHoje {
    final DateTime hoje = DateTime.now();
    return _vendasFiltradas.where((VendaNaoLiquidadaModel venda) {
      final DateTime? vencimento = venda.dataVencimento;
      return vencimento != null && vencimento.year == hoje.year && vencimento.month == hoje.month && vencimento.day == hoje.day;
    }).length;
  }

  double get _previsaoSeteDias {
    final DateTime hoje = _inicioDoDia(DateTime.now());
    final DateTime seteDias = _fimDoDia(hoje.add(const Duration(days: 7)));
    return _vendas.where((VendaNaoLiquidadaModel venda) {
      final DateTime? data = venda.dataVencimento ?? venda.dataCompetencia;
      if (data == null) return false;
      return !data.isBefore(hoje) && !data.isAfter(seteDias);
    }).fold<double>(0, (double soma, VendaNaoLiquidadaModel venda) => soma + venda.valorAberto);
  }

  String get _riscoAtraso {
    if (_vencidas >= 5 || (_vendasFiltradas.isNotEmpty && _vencidas / _vendasFiltradas.length >= 0.35)) return 'Alto';
    if (_vencidas > 0 || _venceHoje > 3) return 'Médio';
    return 'Baixo';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _carregarTiposRecebimento();
      await _carregar();
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final List<VendaNaoLiquidadaModel> vendas = await _api.listar();
      if (!mounted) return;
      setState(() => _vendas = vendas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _carregarTiposRecebimento() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes = await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<_TipoRecebimentoOpcao> ativos = informacoes.tiposRecebimento
          .where((TiposRecebimento tipo) => tipo.ativo)
          .toList()
        ..sort((TiposRecebimento a, TiposRecebimento b) => a.ordemExibicao.compareTo(b.ordemExibicao));
      final List<_TipoRecebimentoOpcao> opcoes = ativos
          .map((TiposRecebimento tipo) => _TipoRecebimentoOpcao(
                codigo: tipo.codigoTipo.trim().isEmpty ? 'TIPO2' : tipo.codigoTipo.trim().toUpperCase(),
                descricao: tipo.descricaoExibicao.trim().isEmpty ? tipo.codigoTipo.trim().toUpperCase() : tipo.descricaoExibicao.trim(),
              ))
          .where((_TipoRecebimentoOpcao opcao) => opcao.codigo.isNotEmpty && opcao.descricao.isNotEmpty)
          .toList(growable: false);
      if (!mounted || opcoes.isEmpty) return;
      setState(() => _tiposRecebimento = opcoes);
    } catch (_) {
      // O mobile também mantém a tela operacional mesmo se as configurações auxiliares falharem.
    }
  }

  Future<void> _selecionarData({required bool inicio}) async {
    final DateTime dataAtual = inicio ? _dataInicio : _dataFim;
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: dataAtual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selecionada == null) return;
    setState(() {
      if (inicio) {
        _dataInicio = _inicioDoDia(selecionada);
        if (_dataFim.isBefore(_dataInicio)) _dataFim = _dataInicio;
      } else {
        _dataFim = _inicioDoDia(selecionada);
        if (_dataInicio.isAfter(_dataFim)) _dataInicio = _dataFim;
      }
    });
  }

  Future<void> _receberVenda(VendaNaoLiquidadaModel venda) async {
    if (_processando) return;
    final _TipoRecebimentoOpcao opcaoInicial = _opcaoInicial(venda.codigoTipoRecebimento);
    _TipoRecebimentoOpcao opcaoSelecionada = opcaoInicial;

    final bool confirmou = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return StatefulBuilder(
              builder: (BuildContext dialogContext, StateSetter setDialogState) {
                return AlertDialog(
                  title: const Text('Receber venda em aberto'),
                  content: SizedBox(
                    width: 440,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(venda.descricao, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Cliente: ${venda.nomeCliente.trim().isEmpty ? 'Não informado' : venda.nomeCliente.trim()}'),
                        const SizedBox(height: 8),
                        Text('Valor em aberto: ${_formatarValor(venda.valorAberto)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<_TipoRecebimentoOpcao>(
                          value: opcaoSelecionada,
                          decoration: const InputDecoration(labelText: 'Forma de recebimento'),
                          items: _tiposRecebimento
                              .map((_TipoRecebimentoOpcao opcao) => DropdownMenuItem<_TipoRecebimentoOpcao>(value: opcao, child: Text(opcao.descricao)))
                              .toList(growable: false),
                          onChanged: (_TipoRecebimentoOpcao? value) {
                            if (value == null) return;
                            setDialogState(() => opcaoSelecionada = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Confirmar recebimento'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!confirmou) return;

    setState(() => _processando = true);
    try {
      await _api.liquidar(
        idRecebimento: venda.idRecebimento,
        input: LiquidarVendaNaoLiquidadaInput(
          codigoTipoRecebimento: opcaoSelecionada.codigo,
          valorRecebido: venda.valorAberto,
          itens: venda.itens,
          observacao: 'Recebimento realizado no frente de caixa web.',
          referencia: venda.idOperacaoApp.isNotEmpty ? venda.idOperacaoApp : venda.idOperacaoFinanceira,
        ),
      );
      if (!mounted) return;
      _snack('Venda recebida com sucesso.');
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _confirmarCancelamentoVenda(VendaNaoLiquidadaModel venda) async {
    if (_processando) return;
    final bool confirmou = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Cancelar venda em aberto?'),
            content: Text(
              '${venda.descricao}\n${_formatarValor(venda.valorAberto)}\n\n'
              'Esta ação apaga a operação e devolve os produtos ao estoque quando aplicável.',
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Voltar')),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirmar')),
            ],
          ),
        ) ??
        false;
    if (confirmou) await _cancelarVendaNaoLiquidada(venda);
  }

  Future<void> _cancelarVendaNaoLiquidada(VendaNaoLiquidadaModel venda) async {
    if (_processando) return;
    setState(() => _processando = true);
    try {
      await _api.cancelar(idRecebimento: venda.idRecebimento);
      if (!mounted) return;
      _snack('Venda em aberto cancelada.');
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  _TipoRecebimentoOpcao _opcaoInicial(String codigoTipoRecebimento) {
    final String codigo = codigoTipoRecebimento.trim().toUpperCase();
    if (codigo.isNotEmpty) {
      for (final _TipoRecebimentoOpcao opcao in _tiposRecebimento) {
        if (opcao.codigo == codigo) return opcao;
      }
    }
    return _tiposRecebimento.isEmpty ? const _TipoRecebimentoOpcao(codigo: 'TIPO2', descricao: 'Pix') : _tiposRecebimento.first;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                _topBar(),
                Expanded(child: _body()),
              ],
            ),
            if (_processando)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.08),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: const BoxDecoration(color: _primary),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              'Vendas a receber',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: _loading || _processando ? null : _carregar,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Atualizar',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) return _estado(Icons.error_outline, 'Não foi possível carregar', _erro!);

    final List<VendaNaoLiquidadaModel> vendas = _vendasFiltradas;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: <Widget>[
          _header(),
          const SizedBox(height: 14),
          _filtrosData(),
          const SizedBox(height: 14),
          _metrics(),
          const SizedBox(height: 14),
          _planejados(),
          const SizedBox(height: 18),
          _section('Vendas em aberto'),
          const SizedBox(height: 12),
          if (vendas.isEmpty)
            _empty()
          else
            ...vendas.map(
              (VendaNaoLiquidadaModel venda) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _vendaCard(venda),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: <Color>[_primary, Color(0xFF123B69)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x260B1F3A), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        children: <Widget>[
          _icon(Icons.point_of_sale_outlined, bg: const Color(0x1AFFFFFF), fg: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Dashboard de recebimentos', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${_vendasFiltradas.length} venda(s) aguardando liquidação', style: const TextStyle(color: Color(0xFFD7E3F5), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(_formatarValor(_totalAberto), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _filtrosData() {
    return _baseCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _dateButton('Data inicial', _dataInicio, () => _selecionarData(inicio: true)),
          _dateButton('Data final', _dataFim, () => _selecionarData(inicio: false)),
          FilledButton.icon(
            onPressed: _loading || _processando ? null : _carregar,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Filtrar'),
          ),
          OutlinedButton.icon(
            onPressed: _loading || _processando
                ? null
                : () {
                    final DateTime hoje = DateTime.now();
                    setState(() {
                      _dataInicio = _inicioDoDia(hoje);
                      _dataFim = _inicioDoDia(hoje);
                    });
                  },
            icon: const Icon(Icons.today_outlined),
            label: const Text('Hoje'),
          ),
        ],
      ),
    );
  }

  Widget _dateButton(String label, DateTime data, VoidCallback onTap) {
    return SizedBox(
      width: 190,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text(_formatarDataDia(data), style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _metrics() {
    final List<_Metric> metrics = <_Metric>[
      _Metric('Total aberto', _formatarValor(_totalAberto), Icons.account_balance_wallet_outlined),
      _Metric('Vendas', _vendasFiltradas.length.toString(), Icons.receipt_long_outlined),
      _Metric('Ticket médio', _formatarValor(_ticketMedio), Icons.trending_up_rounded),
      _Metric('Itens', _totalItens.toString(), Icons.inventory_2_outlined),
      _Metric('Vencidas', _vencidas.toString(), Icons.warning_amber_rounded),
      _Metric('Vence hoje', _venceHoje.toString(), Icons.today_rounded),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 980 ? 3 : 2;
        final double width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics.map((metric) {
            return SizedBox(
              width: width,
              child: _baseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _icon(metric.icon, bg: const Color(0xFFEFF6FF), fg: _accent, size: 38),
                    const SizedBox(height: 10),
                    Text(metric.title, style: const TextStyle(color: _muted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(metric.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontSize: 17, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _planejados() {
    return Row(
      children: <Widget>[
        Expanded(child: _planned('Previsão 7 dias', _formatarValor(_previsaoSeteDias), Icons.auto_graph_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _planned('Risco de atraso', _riscoAtraso, Icons.insights_rounded)),
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
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(999)),
                child: const Text('Planejado', style: TextStyle(color: Color(0xFFC2410C), fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text('Calculado com as vendas em aberto', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _vendaCard(VendaNaoLiquidadaModel venda) {
    final int quantidadeItens = venda.itens.fold<int>(0, (int soma, VendaNaoLiquidadaItemModel item) => soma + item.quantidade);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Row(
          children: <Widget>[
            _icon(Icons.receipt_long_outlined, bg: const Color(0xFFEFF6FF), fg: _accent, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(venda.descricao, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Criada por ${venda.nomeColaboradorCriacao.isEmpty ? 'colaborador' : venda.nomeColaboradorCriacao}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${_formatarData(venda.dataCompetencia)} • $quantidadeItens item(ns)', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
                  if (venda.nomeCliente.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(venda.nomeCliente.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(_formatarValor(venda.valorAberto), style: const TextStyle(color: _title, fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton(onPressed: _processando ? null : () => _confirmarCancelamentoVenda(venda), child: const Text('Cancelar')),
                    FilledButton.icon(onPressed: _processando ? null : () => _receberVenda(venda), icon: const Icon(Icons.payments_rounded, size: 18), label: const Text('Receber')),
                  ],
                ),
              ],
            ),
          ],
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
          Text('Quando uma venda for marcada para receber depois, ela aparecerá aqui.', textAlign: TextAlign.center, style: TextStyle(color: _muted, height: 1.4)),
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
            _icon(icon, bg: _accent.withOpacity(0.10), fg: _accent, size: 76),
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
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))],
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
    return Text(title, style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w900));
  }

  DateTime _inicioDoDia(DateTime data) => DateTime(data.year, data.month, data.day);
  DateTime _fimDoDia(DateTime data) => DateTime(data.year, data.month, data.day, 23, 59, 59, 999);

  String _formatarValor(double valor) => 'R${String.fromCharCode(36)} ${valor.toStringAsFixed(2)}';

  String _formatarData(DateTime? data) {
    if (data == null) return 'Sem data';
    String d(int value) => value.toString().padLeft(2, '0');
    return '${d(data.day)}/${d(data.month)}/${data.year} ${d(data.hour)}:${d(data.minute)}';
  }

  String _formatarDataDia(DateTime data) {
    String d(int value) => value.toString().padLeft(2, '0');
    return '${d(data.day)}/${d(data.month)}/${data.year}';
  }
}

class _Metric {
  const _Metric(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}

class _TipoRecebimentoOpcao {
  const _TipoRecebimentoOpcao({required this.codigo, required this.descricao});

  final String codigo;
  final String descricao;
}
