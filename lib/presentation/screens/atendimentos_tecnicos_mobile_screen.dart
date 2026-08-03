import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import 'atendimento_tecnico_editar_mobile_screen.dart';
import 'atendimento_tecnico_mobile_screen.dart';

class AtendimentosTecnicosMobileScreen extends StatefulWidget {
  const AtendimentosTecnicosMobileScreen({super.key});

  @override
  State<AtendimentosTecnicosMobileScreen> createState() =>
      _AtendimentosTecnicosMobileScreenState();
}

class _AtendimentosTecnicosMobileScreenState
    extends State<AtendimentosTecnicosMobileScreen> {
  static const String _semTecnicoKey = '__sem_tecnico__';

  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _surfaceColor = SixMobilePalette.surface;
  static const Color _mutedTextColor = SixMobilePalette.mutedText;
  static const Color _titleTextColor = SixMobilePalette.titleText;
  static const Color _borderColor = SixMobilePalette.activeBorder;

  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<AtendimentoTecnicoModel>> _future;
  String? _statusSelecionado;
  DateTime? _dataInicioFiltro;
  DateTime? _dataFimFiltro;
  String? _tecnicoFiltroKey;

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

  bool get _hasAdvancedFilters =>
      _dataInicioFiltro != null ||
      _dataFimFiltro != null ||
      _tecnicoFiltroKey != null;

  bool get _hasAnyFilter =>
      _hasAdvancedFilters ||
      _statusSelecionado != null ||
      _searchController.text.trim().isNotEmpty;

  void _limparFiltros() {
    setState(() {
      _statusSelecionado = null;
      _dataInicioFiltro = null;
      _dataFimFiltro = null;
      _tecnicoFiltroKey = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}',
    );

    return SixMobilePageShell(
      title: _t('atendimentoTecnico.mobile.listTitle', 'Atendimentos técnicos'),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 8,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      leading: IconButton(
        tooltip: _t('common.back', 'Voltar'),
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: Stack(
            children: <Widget>[
              _buildBody(scrollController, topInset),
              Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  minimum: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.extended(
                    backgroundColor: _accentColor,
                    foregroundColor: SixMobilePalette.onPrimary,
                    elevation: 5,
                    onPressed: _novoAtendimento,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      _t(
                        'atendimentoTecnico.mobile.newFab',
                        'Novo atendimento',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController, double topInset) {
    return FutureBuilder<List<AtendimentoTecnicoModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _loadingState(scrollController, topInset);
        }

        if (snapshot.hasError) {
          return _errorState(
            snapshot.error.toString(),
            scrollController,
            topInset,
          );
        }

        final List<AtendimentoTecnicoModel> atendimentos =
            snapshot.data ?? const <AtendimentoTecnicoModel>[];
        final List<AtendimentoTecnicoModel> filtrados = _filtrar(atendimentos);

        return RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 104),
            children: <Widget>[
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 60),
                child: _hero(filtrados, totalGeral: atendimentos.length),
              ),
              const SizedBox(height: 16),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 120),
                child: _summaryGrid(filtrados),
              ),
              const SizedBox(height: 16),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 180),
                child: _statusOverview(atendimentos),
              ),
              const SizedBox(height: 14),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 220),
                child: _statusFilter(atendimentos),
              ),
              const SizedBox(height: 14),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 260),
                child: _advancedFilters(atendimentos),
              ),
              const SizedBox(height: 14),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 300),
                child: _searchBox(),
              ),
              const SizedBox(height: 16),
              _sectionTitle(
                !_hasAnyFilter
                    ? 'Atendimentos recentes'
                    : 'Resultado do filtro',
              ),
              const SizedBox(height: 12),
              if (filtrados.isEmpty)
                _emptyState()
              else
                ...filtrados
                    .take(20)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SixStaggeredEntry(
                          delay: Duration(milliseconds: 340 + entry.key * 45),
                          child: _atendimentoCard(entry.value),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _loadingState(ScrollController scrollController, double topInset) {
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 104),
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

  Widget _errorState(
    String message,
    ScrollController scrollController,
    double topInset,
  ) {
    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 104),
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

  Widget _hero(
    List<AtendimentoTecnicoModel> atendimentos, {
    required int totalGeral,
  }) {
    final int pendentes = _totalPendentes(atendimentos);
    final bool filtrando =
        _statusSelecionado != null || _searchController.text.trim().isNotEmpty;

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
                  filtrando
                      ? '${atendimentos.length} de $totalGeral atendimento(s) no filtro.'
                      : pendentes == 1
                      ? '1 atendimento ainda precisa de atenção.'
                      : '$pendentes atendimentos ainda precisam de atenção.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD7E3F5),
                    height: 1.35,
                  ),
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
        helper: 'Total exibido',
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
              .map((item) => SizedBox(width: width, child: _summaryCard(item)))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    final Color background = item.highlight ? _primaryColor : _surfaceColor;
    final Color foreground = item.highlight ? Colors.white : _titleTextColor;
    final Color muted =
        item.highlight ? const Color(0xFFD7E3F5) : _mutedTextColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.highlight ? _primaryColor : _borderColor,
        ),
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
              color:
                  item.highlight
                      ? const Color(0x1AFFFFFF)
                      : const Color(0xFFEFF6FF),
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
        ? Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        )
        : SixAnimatedNumberText(value: value, style: style);
  }

  Widget _statusOverview(List<AtendimentoTecnicoModel> atendimentos) {
    final List<_StatusCount> status =
        _statusCounts(atendimentos).take(4).toList();

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

  Widget _statusFilter(List<AtendimentoTecnicoModel> atendimentos) {
    final List<_StatusCount> statuses = _statusCounts(atendimentos);
    final int total = atendimentos.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Filtrar por status',
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _statusChip(
                  label: 'Todos',
                  count: total,
                  selected: _statusSelecionado == null,
                  onSelected: () => setState(() => _statusSelecionado = null),
                ),
                const SizedBox(width: 8),
                ...statuses.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _statusChip(
                      label: status.label,
                      count: status.count,
                      selected: _statusSelecionado == status.label,
                      onSelected:
                          () => setState(() {
                            _statusSelecionado = status.label;
                          }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text('$label · $count'),
      onSelected: (_) => onSelected(),
      selectedColor: _accentColor,
      backgroundColor: const Color(0xFFF8FAFC),
      side: BorderSide(color: selected ? _accentColor : _borderColor),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _primaryColor,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _advancedFilters(List<AtendimentoTecnicoModel> atendimentos) {
    final List<_TecnicoFiltroOption> tecnicos = _tecnicoOptions(atendimentos);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Filtros do atendimento',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_hasAnyFilter)
                TextButton.icon(
                  onPressed: _limparFiltros,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 17),
                  label: const Text('Limpar'),
                  style: TextButton.styleFrom(
                    foregroundColor: _accentColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _filterField(
            label: 'Data',
            value: _periodoFiltroLabel(),
            icon: Icons.event_outlined,
            active: _dataInicioFiltro != null || _dataFimFiltro != null,
            onTap: _abrirFiltroPeriodo,
          ),
          const SizedBox(height: 10),
          _filterField(
            label: 'Técnico responsável',
            value: _tecnicoFiltroLabel(tecnicos),
            icon: Icons.engineering_outlined,
            active: _tecnicoFiltroKey != null,
            onTap: () => _abrirFiltroTecnico(tecnicos),
          ),
        ],
      ),
    );
  }

  Widget _filterField({
    required String label,
    required String value,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? const Color(0xFFBFDBFE) : _borderColor,
            ),
          ),
          child: Row(
            children: <Widget>[
              _iconBox(
                icon,
                size: 38,
                backgroundColor:
                    active ? const Color(0xFFDCEBFF) : const Color(0xFFEFF6FF),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFiltroPeriodo() async {
    final _PeriodoFiltro? result = await showModalBottomSheet<_PeriodoFiltro>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (BuildContext context) {
        return _PeriodoFiltroMobileSheet(
          dataInicio: _dataInicioFiltro,
          dataFim: _dataFimFiltro,
          formatarData: _formatarData,
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _dataInicioFiltro = result.dataInicio;
      _dataFimFiltro = result.dataFim;
    });
  }

  Future<void> _abrirFiltroTecnico(List<_TecnicoFiltroOption> tecnicos) async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (BuildContext context) {
        return _TecnicoFiltroMobileSheet(
          tecnicos: tecnicos,
          selectedKey: _tecnicoFiltroKey,
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _tecnicoFiltroKey =
          result == _TecnicoFiltroMobileSheet.todosKey ? null : result;
    });
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por cliente, status, equipamento ou número',
        prefixIcon: const Icon(Icons.search_rounded, color: _accentColor),
        suffixIcon:
            _searchController.text.trim().isEmpty
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
        onTap: () => _editarAtendimento(atendimento),
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
                    if ((atendimento.defeitoRelatado ?? '')
                        .trim()
                        .isNotEmpty) ...<Widget>[
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
                        _chip(
                          '${atendimento.itens.length} item(ns)',
                          Icons.inventory_2_outlined,
                        ),
                        _chip(
                          _tecnicoLabelAtendimento(atendimento),
                          Icons.engineering_outlined,
                        ),
                        _chip(
                          _formatarData(_dataReferenciaFiltro(atendimento)),
                          Icons.update_rounded,
                        ),
                        if (atendimento.assinaturaAprovada)
                          _chip('Assinado', Icons.verified_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_note_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editarAtendimento(AtendimentoTecnicoModel atendimento) async {
    final bool? alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) =>
                AtendimentoTecnicoEditarMobileScreen(atendimento: atendimento),
      ),
    );

    if (alterou == true && mounted) {
      await _recarregar();
    }
  }

  Future<void> _novoAtendimento() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AtendimentoTecnicoMobileScreen(),
      ),
    );

    if (mounted) await _recarregar();
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

  List<AtendimentoTecnicoModel> _filtrar(
    List<AtendimentoTecnicoModel> atendimentos,
  ) {
    final String termo = _searchController.text.trim().toLowerCase();
    final String? statusSelecionado = _statusSelecionado;
    final DateTime? inicio =
        _dataInicioFiltro == null ? null : _inicioDoDia(_dataInicioFiltro!);
    final DateTime? fim =
        _dataFimFiltro == null ? null : _fimDoDia(_dataFimFiltro!);
    final String? tecnicoKey = _tecnicoFiltroKey;
    final List<AtendimentoTecnicoModel> sorted =
        List<AtendimentoTecnicoModel>.from(atendimentos)
          ..sort(_compareRecentes);

    return sorted
        .where((AtendimentoTecnicoModel atendimento) {
          final DateTime? dataReferencia = _dataReferenciaFiltro(atendimento);
          if (inicio != null) {
            if (dataReferencia == null || dataReferencia.isBefore(inicio)) {
              return false;
            }
          }
          if (fim != null) {
            if (dataReferencia == null || dataReferencia.isAfter(fim)) {
              return false;
            }
          }
          if (tecnicoKey != null &&
              _tecnicoKeyAtendimento(atendimento) != tecnicoKey) {
            return false;
          }
          if (statusSelecionado != null &&
              _statusLabel(atendimento) != statusSelecionado) {
            return false;
          }

          if (termo.isEmpty) return true;

          final AtendimentoTecnicoEquipamentoModel? equipamento =
              atendimento.equipamento;
          final String source =
              <String>[
                atendimento.numero,
                _clienteLabel(atendimento),
                _tecnicoLabelAtendimento(atendimento),
                _statusLabel(atendimento),
                equipamento?.tipo ?? '',
                equipamento?.marca ?? '',
                equipamento?.modelo ?? '',
                equipamento?.imei ?? '',
                atendimento.defeitoRelatado ?? '',
                atendimento.diagnosticoTecnico ?? '',
              ].join(' ').toLowerCase();
          return source.contains(termo);
        })
        .toList(growable: false);
  }

  int _compareRecentes(
    AtendimentoTecnicoModel first,
    AtendimentoTecnicoModel second,
  ) {
    final DateTime firstDate = first.dataAtualizacao ?? DateTime(1900);
    final DateTime secondDate = second.dataAtualizacao ?? DateTime(1900);
    return secondDate.compareTo(firstDate);
  }

  DateTime _inicioDoDia(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _fimDoDia(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  DateTime? _dataReferenciaFiltro(AtendimentoTecnicoModel atendimento) {
    return atendimento.dataAtualizacao ??
        atendimento.dataUltimaAlteracaoOrcamento ??
        atendimento.dataVencimentoEm ??
        atendimento.validadeOrcamentoEm;
  }

  String _tecnicoKeyAtendimento(AtendimentoTecnicoModel atendimento) {
    final String id = atendimento.idTecnicoResponsavel?.trim() ?? '';
    if (id.isNotEmpty) return id;
    final String nome =
        atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    if (nome.isNotEmpty) return nome.toLowerCase();
    return _semTecnicoKey;
  }

  String _tecnicoLabelAtendimento(AtendimentoTecnicoModel atendimento) {
    final String nome =
        atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    return nome.isEmpty ? 'Sem técnico responsável' : nome;
  }

  List<_TecnicoFiltroOption> _tecnicoOptions(
    List<AtendimentoTecnicoModel> atendimentos,
  ) {
    final Map<String, _TecnicoFiltroOption> mapa =
        <String, _TecnicoFiltroOption>{};
    for (final AtendimentoTecnicoModel atendimento in atendimentos) {
      final String key = _tecnicoKeyAtendimento(atendimento);
      mapa[key] = _TecnicoFiltroOption(
        key: key,
        label: _tecnicoLabelAtendimento(atendimento),
      );
    }
    final List<_TecnicoFiltroOption> options = mapa.values.toList(
      growable: false,
    )..sort((_TecnicoFiltroOption a, _TecnicoFiltroOption b) {
      if (a.key == _semTecnicoKey) return 1;
      if (b.key == _semTecnicoKey) return -1;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return options;
  }

  String _tecnicoFiltroLabel(List<_TecnicoFiltroOption> options) {
    final String? selected = _tecnicoFiltroKey;
    if (selected == null) return 'Todos os técnicos';
    for (final _TecnicoFiltroOption option in options) {
      if (option.key == selected) return option.label;
    }
    return 'Técnico selecionado';
  }

  String _periodoFiltroLabel() {
    final DateTime? inicio = _dataInicioFiltro;
    final DateTime? fim = _dataFimFiltro;
    if (inicio == null && fim == null) return 'Todas as datas';
    if (inicio != null && fim != null) {
      return '${_formatarData(inicio)} até ${_formatarData(fim)}';
    }
    if (inicio != null) return 'A partir de ${_formatarData(inicio)}';
    return 'Até ${_formatarData(fim!)}';
  }

  List<_StatusCount> _statusCounts(List<AtendimentoTecnicoModel> atendimentos) {
    final Map<String, int> counts = <String, int>{};
    for (final AtendimentoTecnicoModel atendimento in atendimentos) {
      final String label = _statusLabel(atendimento);
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final List<_StatusCount> result = counts.entries
      .map((entry) => _StatusCount(entry.key, entry.value))
      .toList(growable: false)..sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  int _totalPendentes(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos
        .where(
          (AtendimentoTecnicoModel atendimento) =>
              !atendimento.operacaoLiquidada ||
              atendimento.requerNovaAssinatura,
        )
        .length;
  }

  int _totalEmAberto(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos
        .where(
          (AtendimentoTecnicoModel atendimento) =>
              !atendimento.operacaoLiquidada,
        )
        .length;
  }

  int _totalAssinados(List<AtendimentoTecnicoModel> atendimentos) {
    return atendimentos
        .where(
          (AtendimentoTecnicoModel atendimento) =>
              atendimento.assinaturaAprovada,
        )
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
    final AtendimentoTecnicoEquipamentoModel? equipamento =
        atendimento.equipamento;
    final List<String> partes = <String>[
      equipamento?.tipo ?? '',
      equipamento?.marca ?? '',
      equipamento?.modelo ?? '',
    ].where((String value) => value.trim().isNotEmpty).toList(growable: false);
    return partes.isEmpty ? atendimento.numero : partes.join(' ');
  }

  String _formatarMoeda(double value) {
    return context.read<LocaleSettingsProvider>().formatCurrency(value);
  }

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);
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

class _PeriodoFiltro {
  const _PeriodoFiltro({required this.dataInicio, required this.dataFim});

  final DateTime? dataInicio;
  final DateTime? dataFim;
}

class _TecnicoFiltroOption {
  const _TecnicoFiltroOption({required this.key, required this.label});

  final String key;
  final String label;
}

class _PeriodoFiltroMobileSheet extends StatefulWidget {
  const _PeriodoFiltroMobileSheet({
    required this.dataInicio,
    required this.dataFim,
    required this.formatarData,
  });

  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String Function(DateTime?) formatarData;

  @override
  State<_PeriodoFiltroMobileSheet> createState() =>
      _PeriodoFiltroMobileSheetState();
}

class _PeriodoFiltroMobileSheetState extends State<_PeriodoFiltroMobileSheet> {
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _surfaceColor = SixMobilePalette.surface;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _mutedTextColor = SixMobilePalette.mutedText;
  static const Color _titleTextColor = SixMobilePalette.titleText;
  static const Color _borderColor = SixMobilePalette.activeBorder;

  late DateTime? _inicio = widget.dataInicio;
  late DateTime? _fim = widget.dataFim;
  bool _editandoInicio = true;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime initialDate = (_editandoInicio ? _inicio : _fim) ?? now;
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
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
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    _sheetIcon(Icons.event_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Filtrar por data',
                            style: TextStyle(
                              color: _titleTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Use a data de atualização do atendimento.',
                            style: TextStyle(
                              color: _mutedTextColor,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: <Widget>[
                    _dateTargetChip(
                      label: 'Início',
                      value: widget.formatarData(_inicio),
                      selected: _editandoInicio,
                      onTap: () => setState(() => _editandoInicio = true),
                    ),
                    _dateTargetChip(
                      label: 'Fim',
                      value: widget.formatarData(_fim),
                      selected: !_editandoInicio,
                      onTap: () => setState(() => _editandoInicio = false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _shortcutChip('Hoje', () => _setPeriodo(now, now)),
                    _shortcutChip(
                      'Últimos 7 dias',
                      () => _setPeriodo(
                        now.subtract(const Duration(days: 6)),
                        now,
                      ),
                    ),
                    _shortcutChip(
                      'Últimos 30 dias',
                      () => _setPeriodo(
                        now.subtract(const Duration(days: 29)),
                        now,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _borderColor),
                  ),
                  child: CalendarDatePicker(
                    key: ValueKey<String>(
                      '${_editandoInicio ? 'inicio' : 'fim'}-${initialDate.toIso8601String()}',
                    ),
                    initialDate: initialDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(now.year + 5, 12, 31),
                    onDateChanged: _selecionarData,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            () => Navigator.of(context).pop(
                              const _PeriodoFiltro(
                                dataInicio: null,
                                dataFim: null,
                              ),
                            ),
                        child: const Text('Limpar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            () => Navigator.of(context).pop(
                              _PeriodoFiltro(
                                dataInicio: _inicio,
                                dataFim: _fim,
                              ),
                            ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: _accentColor),
    );
  }

  Widget _dateTargetChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text('$label: $value'),
      onSelected: (_) => onTap(),
      selectedColor: _accentColor,
      backgroundColor: const Color(0xFFF8FAFC),
      side: BorderSide(color: selected ? _accentColor : _borderColor),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _titleTextColor,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );
  }

  Widget _shortcutChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: const Color(0xFFF8FAFC),
      side: const BorderSide(color: _borderColor),
      labelStyle: const TextStyle(
        color: _titleTextColor,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  void _selecionarData(DateTime value) {
    final DateTime normalized = DateTime(value.year, value.month, value.day);
    setState(() {
      if (_editandoInicio) {
        _inicio = normalized;
        if (_fim != null && _fim!.isBefore(normalized)) {
          _fim = normalized;
        }
      } else {
        _fim = normalized;
        if (_inicio != null && _inicio!.isAfter(normalized)) {
          _inicio = normalized;
        }
      }
    });
  }

  void _setPeriodo(DateTime inicio, DateTime fim) {
    setState(() {
      _inicio = DateTime(inicio.year, inicio.month, inicio.day);
      _fim = DateTime(fim.year, fim.month, fim.day);
    });
  }
}

class _TecnicoFiltroMobileSheet extends StatefulWidget {
  const _TecnicoFiltroMobileSheet({
    required this.tecnicos,
    required this.selectedKey,
  });

  static const String todosKey = '__todos__';

  final List<_TecnicoFiltroOption> tecnicos;
  final String? selectedKey;

  @override
  State<_TecnicoFiltroMobileSheet> createState() =>
      _TecnicoFiltroMobileSheetState();
}

class _TecnicoFiltroMobileSheetState extends State<_TecnicoFiltroMobileSheet> {
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _surfaceColor = SixMobilePalette.surface;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _mutedTextColor = SixMobilePalette.mutedText;
  static const Color _titleTextColor = SixMobilePalette.titleText;
  static const Color _borderColor = SixMobilePalette.activeBorder;

  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_TecnicoFiltroOption> get _filtrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.tecnicos;
    return widget.tecnicos
        .where((_TecnicoFiltroOption item) {
          return _normalize(item.label).contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        final List<_TecnicoFiltroOption> tecnicos = _filtrados;
        return Container(
          decoration: const BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.engineering_outlined,
                          color: _accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Técnico responsável',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Filtre pelos responsáveis dos atendimentos.',
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _searchController,
                    onChanged:
                        (String value) => setState(() => _filter = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar técnico',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon:
                          _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _filter = '');
                                },
                              ),
                      filled: true,
                      fillColor: _surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _accentColor,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return _tecnicoItem(
                          label: 'Todos os técnicos',
                          selected: widget.selectedKey == null,
                          icon: Icons.groups_outlined,
                          onTap:
                              () => Navigator.of(
                                context,
                              ).pop(_TecnicoFiltroMobileSheet.todosKey),
                        );
                      }
                      final _TecnicoFiltroOption tecnico = tecnicos[index - 1];
                      return _tecnicoItem(
                        label: tecnico.label,
                        selected: widget.selectedKey == tecnico.key,
                        icon: Icons.engineering_outlined,
                        onTap: () => Navigator.of(context).pop(tecnico.key),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: tecnicos.length + 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tecnicoItem({
    required String label,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFFBFDBFE) : _borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 21,
                backgroundColor:
                    selected
                        ? const Color(0xFFDCEBFF)
                        : const Color(0xFFF1F5F9),
                child: Icon(icon, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _accentColor : _mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
