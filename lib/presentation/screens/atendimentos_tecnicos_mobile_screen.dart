import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../components/mobile_motion.dart';

class AtendimentosTecnicosMobileScreen extends StatefulWidget {
  const AtendimentosTecnicosMobileScreen({super.key});

  @override
  State<AtendimentosTecnicosMobileScreen> createState() =>
      _AtendimentosTecnicosMobileScreenState();
}

class _AtendimentosTecnicosMobileScreenState
    extends State<AtendimentosTecnicosMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<AtendimentoTecnicoModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<AtendimentoTecnicoModel>> _carregar() {
    return _service.listar();
  }

  Future<void> _recarregar() async {
    setState(() {
      _future = _carregar();
    });
    await _future;
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
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
        title: const Text(
          'Atendimentos Técnicos',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<AtendimentoTecnicoModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _loadingState();
            }

            if (snapshot.hasError) {
              return _errorState(snapshot.error.toString());
            }

            final List<AtendimentoTecnicoModel> atendimentos =
                snapshot.data ?? const <AtendimentoTecnicoModel>[];
            final List<AtendimentoTecnicoModel> filtrados =
                _filtrar(atendimentos);

            return RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: <Widget>[
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 60),
                    child: _hero(atendimentos),
                  ),
                  const SizedBox(height: 16),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 120),
                    child: _summaryGrid(atendimentos),
                  ),
                  const SizedBox(height: 16),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 180),
                    child: _statusOverview(atendimentos),
                  ),
                  const SizedBox(height: 16),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 240),
                    child: _searchBox(),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle(
                    _searchController.text.trim().isEmpty
                        ? 'Atendimentos recentes'
                        : 'Resultado da busca',
                  ),
                  const SizedBox(height: 12),
                  if (filtrados.isEmpty)
                    _emptyState()
                  else
                    ...filtrados.take(12).toList().asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SixStaggeredEntry(
                              delay: Duration(milliseconds: 300 + entry.key * 45),
                              child: _atendimentoCard(entry.value),
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _loadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: <Widget>[
        _loadingBlock(height: 128),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(child: _loadingBlock(height: 94)),
            const SizedBox(width: 12),
            Expanded(child: _loadingBlock(height: 94)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _loadingBlock(height: 94)),
            const SizedBox(width: 12),
            Expanded(child: _loadingBlock(height: 94)),
          ],
        ),
        const SizedBox(height: 16),
        _loadingBlock(height: 96),
        const SizedBox(height: 16),
        _loadingBlock(height: 132),
        const SizedBox(height: 12),
        _loadingBlock(height: 132),
      ],
    );
  }

  Widget _loadingBlock({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _iconBox(Icons.cloud_off_rounded),
                const SizedBox(height: 14),
                const Text(
                  'Não foi possível carregar os atendimentos',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _mutedTextColor, height: 1.3),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _recarregar,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(List<AtendimentoTecnicoModel> atendimentos) {
    final int pendentes = _totalPendentes(atendimentos);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _iconBox(
            Icons.fact_check_outlined,
            backgroundColor: const Color(0x1AFFFFFF),
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Dashboard técnico',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pendentes == 1
                      ? '1 atendimento ainda precisa de atenção.'
                      : '$pendentes atendimentos ainda precisam de atenção.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFD7E3F5), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(List<AtendimentoTecnicoModel> atendimentos) {
    final List<_SummaryItem> items = <_SummaryItem>[
      _SummaryItem(
        label: 'Atendimentos',
        value: atendimentos.length.toString(),
        helper: 'Total criado',
        icon: Icons.assignment_turned_in_outlined,
      ),
      _SummaryItem(
        label: 'Em aberto',
        value: _totalEmAberto(atendimentos).toString(),
        helper: 'Aguardam recebimento',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _SummaryItem(
        label: 'Assinados',
        value: _totalAssinados(atendimentos).toString(),
        helper: 'Com aceite do cliente',
        icon: Icons.verified_rounded,
      ),
      _SummaryItem(
        label: 'Valor aberto',
        value: _formatarMoeda(_valorAberto(atendimentos)),
        helper: 'Saldo pendente',
        icon: Icons.payments_outlined,
        highlight: true,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(width: width, child: _summaryCard(item)),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    final Color background = item.highlight ? _primaryColor : _surfaceColor;
    final Color foreground = item.highlight ? Colors.white : _titleTextColor;
    final Color muted = item.highlight ? const Color(0xFFD7E3F5) : _mutedTextColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.highlight ? _primaryColor : _borderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.highlight ? const Color(0x1AFFFFFF) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.highlight ? Colors.white : _accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          _animatedValue(item.value, foreground),
          const SizedBox(height: 2),
          Text(
            item.helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _animatedValue(String value, Color color) {
    final TextStyle style = TextStyle(
      color: color,
      fontSize: 22,
      fontWeight: FontWeight.w900,
    );
    return int.tryParse(value) == null
        ? Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)
        : SixAnimatedNumberText(value: value, style: style);
  }

  Widget _statusOverview(List<AtendimentoTecnicoModel> atendimentos) {
    final List<_StatusCount> status = _statusCounts(atendimentos).take(4).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _iconBox(Icons.flag_outlined, size: 42),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Visão por status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Acompanhe onde estão os atendimentos.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _mutedTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (status.isEmpty)
            const Text(
              'Nenhum status para exibir.',
              style: TextStyle(color: _mutedTextColor),
            )
          else
            ...status.map(_statusRow),
        ],
      ),
    );
  }

  Widget _statusRow(_StatusCount item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _titleTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              item.count.toString(),
              style: const TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por cliente, status, equipamento ou número',
        prefixIcon: const Icon(Icons.search_rounded, color: _accentColor),
        suffixIcon: _searchController.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.clear_rounded),
              ),
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _accentColor, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _atendimentoCard(AtendimentoTecnicoModel atendimento) {
    final String cliente = _clienteLabel(atendimento);
    final String status = _statusLabel(atendimento);
    final String equipamento = _equipamentoTitulo(atendimento);
    final bool pendente = !atendimento.operacaoLiquidada;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showDetails(atendimento),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _iconBox(Icons.devices_other_outlined, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      equipamento,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${atendimento.numero} • $cliente',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        atendimento.defeitoRelatado!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedTextColor,
                          height: 1.25,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: <Widget>[
                        _chip(
                          pendente ? 'Em aberto' : 'Liquidado',
                          pendente
                              ? Icons.account_balance_wallet_outlined
                              : Icons.price_check_rounded,
                        ),
                        _chip(status, Icons.flag_outlined),
                        _chip('${atendimento.itens.length} item(ns)', Icons.inventory_2_outlined),
                        if (atendimento.assinaturaAprovada)
                          _chip('Assinado', Icons.verified_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return _card(
      child: Column(
        children: <Widget>[
          _iconBox(Icons.search_off_rounded),
          const SizedBox(height: 12),
          const Text(
            'Nenhum atendimento encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tente buscar por cliente, equipamento, status ou número.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(
    IconData icon, {
    Color backgroundColor = const Color(0xFFEFF6FF),
    Color foregroundColor = _accentColor,
    double size = 44,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: foregroundColor, size: size * 0.52),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: _accentColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _titleTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _titleTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
    );
  }

  void _showDetails(AtendimentoTecnicoModel atendimento) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.36,
          maxChildSize: 0.88,
          expand: false,
          builder: (BuildContext context, ScrollController controller) {
            return Container(
              decoration: const BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _equipamentoTitulo(atendimento),
                            style: const TextStyle(
                              color: _titleTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${atendimento.numero} • ${_clienteLabel(atendimento)}',
                            style: const TextStyle(
                              color: _mutedTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _detailRow('Status', _statusLabel(atendimento)),
                          _detailRow('Total', _formatarMoeda(atendimento.valorTotalAtendimento)),
                          _detailRow('Em aberto', _formatarMoeda(atendimento.valorEmAberto)),
                          _detailRow('Itens', atendimento.itens.length.toString()),
                          _detailRow('Versão', atendimento.versaoOrcamento.toString()),
                          _detailRow('Validade', _formatarData(atendimento.validadeOrcamentoEm)),
                          if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty)
                            _detailRow('Defeito', atendimento.defeitoRelatado!.trim()),
                          if ((atendimento.diagnosticoTecnico ?? '').trim().isNotEmpty)
                            _detailRow('Diagnóstico', atendimento.diagnosticoTecnico!.trim()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: _mutedTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _titleTextColor,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AtendimentoTecnicoModel> _filtrar(
    List<AtendimentoTecnicoModel> atendimentos,
  ) {
    final String termo = _searchController.text.trim().toLowerCase();
    final List<AtendimentoTecnicoModel> sorted = List<AtendimentoTecnicoModel>.from(
      atendimentos,
    )..sort(_compareRecentes);

    if (termo.isEmpty) return sorted;

    return sorted.where((AtendimentoTecnicoModel atendimento) {
      final AtendimentoTecnicoEquipamentoModel? equipamento = atendimento.equipamento;
      final String source = <String>[
        atendimento.numero,
        _clienteLabel(atendimento),
        _statusLabel(atendimento),
        equipamento?.tipo ?? '',
        equipamento?.marca ?? '',
        equipamento?.modelo ?? '',
        equipamento?.imei ?? '',
        atendimento.defeitoRelatado ?? '',
        atendimento.diagnosticoTecnico ?? '',
      ].join(' ').toLowerCase();
      return source.contains(termo);
    }).toList(growable: false);
  }

  int _compareRecentes(
    AtendimentoTecnicoModel first,
    AtendimentoTecnicoModel second,
  ) {
    final DateTime firstDate = first.dataAtualizacao ?? DateTime(1900);
    final DateTime secondDate = second.dataAtualizacao ?? DateTime(1900);
    return secondDate.compareTo(firstDate);
  }

  List<_StatusCount> _statusCounts(List<AtendimentoTecnicoModel> atendimentos) {
    final Map<String, int> counts = <String, int>{};
    for (final AtendimentoTecnicoModel atendimento in atendimentos) {
      final String label = _statusLabel(atendimento);
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final List<_StatusCount> result = counts.entries
        .map((entry) => _StatusCount(entry.key, entry.value))
        .toList(growable: false)
      ..sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  int _totalPendentes(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos
        .where((AtendimentoTecnicoModel atendimento) =>
            !atendimento.operacaoLiquidada || atendimento.requerNovaAssinatura)
        .length;
  }

  int _totalEmAberto(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos
        .where((AtendimentoTecnicoModel atendimento) => !atendimento.operacaoLiquidada)
        .length;
  }

  int _totalAssinados(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos
        .where((AtendimentoTecnicoModel atendimento) => atendimento.assinaturaAprovada)
        .length;
  }

  double _valorAberto(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos.fold<double>(
      0,
      (double total, AtendimentoTecnicoModel atendimento) =>
          total + atendimento.valorEmAberto,
    );
  }

  String _clienteLabel(AtendimentoTecnicoModel atendimento) {
    final String cliente = atendimento.nomeClienteSnapshot?.trim() ?? '';
    return cliente.isEmpty ? 'Cliente não informado' : cliente;
  }

  String _statusLabel(AtendimentoTecnicoModel atendimento) {
    final String statusBackend = atendimento.statusNomePtBr?.trim() ?? '';
    if (statusBackend.isNotEmpty) return statusBackend;
    final String codigo = atendimento.statusCodigo.trim();
    return codigo.isEmpty ? 'Sem status' : codigo;
  }

  String _equipamentoTitulo(AtendimentoTecnicoModel atendimento) {
    final AtendimentoTecnicoEquipamentoModel? equipamento = atendimento.equipamento;
    final List<String> partes = <String>[
      equipamento?.tipo ?? '',
      equipamento?.marca ?? '',
      equipamento?.modelo ?? '',
    ].where((String value) => value.trim().isNotEmpty).toList(growable: false);
    return partes.isEmpty ? atendimento.numero : partes.join(' ');
  }

  String _formatarMoeda(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    final String dia = value.day.toString().padLeft(2, '0');
    final String mes = value.month.toString().padLeft(2, '0');
    return '$dia/$mes/${value.year}';
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final bool highlight;
}

class _StatusCount {
  const _StatusCount(this.label, this.count);

  final String label;
  final int count;
}
