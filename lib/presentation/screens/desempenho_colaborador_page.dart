import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/desempenho_colaborador_model.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../data/services/desempenho_colaborador/desempenho_colaborador_api_client.dart';
import '../components/six_backend_loading.dart';

class DesempenhoColaboradorPage extends StatefulWidget {
  const DesempenhoColaboradorPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<DesempenhoColaboradorPage> createState() =>
      _DesempenhoColaboradorPageState();
}

class _DesempenhoColaboradorPageState extends State<DesempenhoColaboradorPage> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final DesempenhoColaboradorApiClient _api =
      HttpDesempenhoColaboradorApiClient();
  final ColaboradorUsuarioApiClient _colaboradorApi =
      HttpColaboradorUsuarioApiClient();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  late DateTime _dataInicio;
  late DateTime _dataFim;
  String? _idColaboradorSelecionado;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<ColaboradorUsuarioResumo> _colaboradores = <ColaboradorUsuarioResumo>[];
  List<MetaColaboradorModel> _metas = <MetaColaboradorModel>[];
  DesempenhoColaboradorResumoModel _resumo =
      DesempenhoColaboradorResumoModel.empty();

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _dataInicio = DateTime(now.year, now.month);
    _dataFim = DateTime(now.year, now.month, now.day);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<ColaboradorUsuarioResumo> colaboradores =
          await _colaboradorApi.listarColaboradores();
      final List<MetaColaboradorModel> metas = await _api.listarMetas();
      final DesempenhoColaboradorResumoModel resumo = await _api.buscarResumo(
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        idColaborador: _idColaboradorSelecionado,
      );

      if (!mounted) return;
      setState(() {
        _colaboradores = colaboradores;
        _metas = metas;
        _resumo = resumo;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      color: _backgroundColor,
      child: Column(
        children: <Widget>[
          _buildHeader(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Desempenho',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: content,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(widget.embedded ? 20 : 16, 16, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, Color(0xFF123B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            if (widget.onBack != null)
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: 'Fechar',
              ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Desempenho do colaborador',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Metas, resultado e evolução por período.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFFD7E3F5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
              onPressed: _saving ? null : () => _abrirFormularioMeta(),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Nova meta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SixBackendLoading.messages(
          compact: false,
          animation: SixBackendLoadingAnimation.skeletonPulse,
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 900;
          return ListView(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 18, wide ? 24 : 16, 28),
            children: <Widget>[
              _buildFilters(wide: wide),
              const SizedBox(height: 16),
              _buildSummaryCards(wide: wide),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 7, child: _buildResultadosCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _buildMetasCard()),
                  ],
                )
              else ...<Widget>[
                _buildResultadosCard(),
                const SizedBox(height: 16),
                _buildMetasCard(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
              const SizedBox(height: 10),
              const Text(
                'Não foi possível carregar o desempenho.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _mutedColor),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters({required bool wide}) {
    return _Panel(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _buildPeriodChip(
            label: 'Mês atual',
            selected: _isCurrentMonth(),
            onTap: () {
              final DateTime now = DateTime.now();
              _setPeriodo(DateTime(now.year, now.month), DateTime(now.year, now.month, now.day));
            },
          ),
          _buildPeriodChip(
            label: 'Últimos 30 dias',
            selected: _isLastThirtyDays(),
            onTap: () {
              final DateTime now = DateTime.now();
              _setPeriodo(now.subtract(const Duration(days: 29)), now);
            },
          ),
          _buildPeriodChip(
            label: 'Hoje',
            selected: _isTodayOnly(),
            onTap: () {
              final DateTime now = DateTime.now();
              _setPeriodo(now, now);
            },
          ),
          SizedBox(
            width: wide ? 300 : double.infinity,
            child: _buildColaboradorSelector(),
          ),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('${_dateFormat.format(_dataInicio)} até ${_dateFormat.format(_dataFim)}'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFDCEBFF),
      labelStyle: TextStyle(
        color: selected ? _primaryColor : _mutedColor,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _buildColaboradorSelector() {
    final String label = _nomeColaboradorSelecionado();
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _selecionarColaboradorFiltro,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.badge_outlined, color: _accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _mutedColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards({required bool wide}) {
    final List<Widget> cards = <Widget>[
      _KpiCard(
        title: 'Score médio',
        value: '${_resumo.scoreMedio.toStringAsFixed(0)}%',
        subtitle: 'Média ponderada das metas',
        icon: Icons.speed_rounded,
      ),
      _KpiCard(
        title: 'Metas batidas',
        value: '${_resumo.metasBatidas}/${_resumo.totalMetas}',
        subtitle: 'Dentro do período filtrado',
        icon: Icons.emoji_events_outlined,
      ),
      _KpiCard(
        title: 'Vendas',
        value: _currencyFormat.format(_resumo.valorTotalVendido),
        subtitle: '${_resumo.quantidadeVendas} operações no período',
        icon: Icons.point_of_sale_rounded,
      ),
      _KpiCard(
        title: 'Atendimentos',
        value: _resumo.quantidadeAtendimentos.toString(),
        subtitle: 'Assistências técnicas no período',
        icon: Icons.build_circle_outlined,
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children:
          cards
              .map(
                (Widget card) => SizedBox(
                  width: wide ? 230 : double.infinity,
                  child: card,
                ),
              )
              .toList(growable: false),
    );
  }

  Widget _buildResultadosCard() {
    return _Panel(
      title: 'Meta x realizado',
      subtitle: 'Resultado calculado automaticamente pelo período selecionado.',
      action: IconButton(
        onPressed: _loadData,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Atualizar',
      ),
      child:
          _resumo.resultados.isEmpty
              ? _EmptyState(
                icon: Icons.flag_outlined,
                title: 'Nenhuma meta ativa no período',
                subtitle: 'Cadastre uma meta para acompanhar a evolução do colaborador.',
              )
              : Column(
                children:
                    _resumo.resultados
                        .map(_buildResultadoTile)
                        .toList(growable: false),
              ),
    );
  }

  Widget _buildResultadoTile(DesempenhoColaboradorItemModel item) {
    final DesempenhoIndicadorOption indicador = indicadorPorCodigo(item.indicador);
    final double progress = (item.percentualAtingido / 100).clamp(0, 1);
    final Color statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.nomeColaborador.isEmpty ? 'Colaborador' : item.nomeColaborador,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusPill(label: _statusLabel(item.status), color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            indicador.label,
            style: const TextStyle(color: _mutedColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${_formatValor(item.valorRealizado, indicador)} de ${_formatValor(item.valorAlvo, indicador)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${item.percentualAtingido.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetasCard() {
    final List<MetaColaboradorModel> metasFiltradas = _metas
        .where(
          (MetaColaboradorModel meta) =>
              _idColaboradorSelecionado == null ||
              meta.idColaborador == _idColaboradorSelecionado,
        )
        .toList(growable: false);

    return _Panel(
      title: 'Metas cadastradas',
      subtitle: 'Administre metas sem gerar relatórios nesta etapa.',
      action: IconButton(
        onPressed: () => _abrirFormularioMeta(),
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Nova meta',
      ),
      child:
          metasFiltradas.isEmpty
              ? const _EmptyState(
                icon: Icons.playlist_add_check_rounded,
                title: 'Sem metas cadastradas',
                subtitle: 'Crie metas por colaborador para acompanhar o resultado.',
              )
              : Column(
                children:
                    metasFiltradas
                        .map(_buildMetaTile)
                        .toList(growable: false),
              ),
    );
  }

  Widget _buildMetaTile(MetaColaboradorModel meta) {
    final DesempenhoIndicadorOption indicador = indicadorPorCodigo(meta.indicador);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirFormularioMeta(meta: meta),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.flag_outlined, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      meta.nomeColaborador.isEmpty ? 'Colaborador' : meta.nomeColaborador,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${indicador.label} • ${_formatPeriodo(meta.dataInicio, meta.dataFim)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: _mutedColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFormularioMeta({MetaColaboradorModel? meta}) async {
    if (_colaboradores.isEmpty) {
      _showSnack('Cadastre ou carregue colaboradores antes de criar metas.');
      return;
    }

    final Map<String, dynamic>? payload;
    if (MediaQuery.of(context).size.width >= 720) {
      payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder:
            (BuildContext dialogContext) => Dialog(
              insetPadding: const EdgeInsets.all(24),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _MetaForm(
                  colaboradores: _colaboradores,
                  meta: meta,
                  dataInicioPadrao: _dataInicio,
                  dataFimPadrao: _dataFim,
                ),
              ),
            ),
      );
    } else {
      payload = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (BuildContext bottomSheetContext) => _MetaForm(
              colaboradores: _colaboradores,
              meta: meta,
              dataInicioPadrao: _dataInicio,
              dataFimPadrao: _dataFim,
            ),
      );
    }

    if (payload == null) return;
    await _salvarMeta(meta: meta, payload: payload);
  }

  Future<void> _salvarMeta({
    required MetaColaboradorModel? meta,
    required Map<String, dynamic> payload,
  }) async {
    setState(() => _saving = true);
    try {
      if (meta == null) {
        await _api.criarMeta(payload);
      } else {
        await _api.editarMeta(meta.id, payload);
      }
      await _loadData();
      if (!mounted) return;
      _showSnack(meta == null ? 'Meta cadastrada.' : 'Meta atualizada.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Não foi possível salvar a meta: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selecionarColaboradorFiltro() async {
    final String? selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (BuildContext context) => _ColaboradorSelectorSheet(
            colaboradores: _colaboradores,
            selectedId: _idColaboradorSelecionado,
            allowAll: true,
          ),
    );

    if (!mounted) return;
    setState(() => _idColaboradorSelecionado = selected);
    await _loadData();
  }

  void _setPeriodo(DateTime inicio, DateTime fim) {
    setState(() {
      _dataInicio = DateTime(inicio.year, inicio.month, inicio.day);
      _dataFim = DateTime(fim.year, fim.month, fim.day);
    });
    _loadData();
  }

  bool _isCurrentMonth() {
    final DateTime now = DateTime.now();
    return _sameDay(_dataInicio, DateTime(now.year, now.month)) &&
        _sameDay(_dataFim, DateTime(now.year, now.month, now.day));
  }

  bool _isLastThirtyDays() {
    final DateTime now = DateTime.now();
    return _sameDay(_dataInicio, now.subtract(const Duration(days: 29))) &&
        _sameDay(_dataFim, now);
  }

  bool _isTodayOnly() {
    final DateTime now = DateTime.now();
    return _sameDay(_dataInicio, now) && _sameDay(_dataFim, now);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _nomeColaboradorSelecionado() {
    if (_idColaboradorSelecionado == null) {
      return 'Todos os colaboradores';
    }
    return _colaboradores
        .firstWhere(
          (ColaboradorUsuarioResumo item) =>
              item.idUnicoPessoal == _idColaboradorSelecionado,
          orElse:
              () => ColaboradorUsuarioResumo(
                idUnicoPessoal: _idColaboradorSelecionado ?? '',
                nome: 'Colaborador',
                nomeDeGuerra: '',
                celularDeAcesso: '',
                email: '',
                foto: '',
                dataCadastro: null,
              ),
        )
        .displayName;
  }

  String _formatValor(double value, DesempenhoIndicadorOption indicador) {
    if (indicador.valorMonetario) {
      return _currencyFormat.format(value);
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  String _formatPeriodo(DateTime? inicio, DateTime? fim) {
    if (inicio == null || fim == null) return 'sem período';
    return '${_dateFormat.format(inicio)} a ${_dateFormat.format(fim)}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACIMA_DA_META':
        return 'Acima da meta';
      case 'EM_PROGRESSO':
        return 'Em progresso';
      case 'EM_RISCO':
        return 'Em risco';
      case 'CRITICO':
        return 'Crítico';
      default:
        return status.isEmpty ? 'Sem status' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACIMA_DA_META':
        return const Color(0xFF16A34A);
      case 'EM_PROGRESSO':
        return _accentColor;
      case 'EM_RISCO':
        return const Color(0xFFD97706);
      case 'CRITICO':
        return const Color(0xFFDC2626);
      default:
        return _mutedColor;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _MetaForm extends StatefulWidget {
  const _MetaForm({
    required this.colaboradores,
    required this.dataInicioPadrao,
    required this.dataFimPadrao,
    this.meta,
  });

  final List<ColaboradorUsuarioResumo> colaboradores;
  final DateTime dataInicioPadrao;
  final DateTime dataFimPadrao;
  final MetaColaboradorModel? meta;

  @override
  State<_MetaForm> createState() => _MetaFormState();
}

class _MetaFormState extends State<_MetaForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late ColaboradorUsuarioResumo _colaborador;
  late String _indicador;
  late String _status;
  late TextEditingController _valorController;
  late TextEditingController _pesoController;
  late TextEditingController _inicioController;
  late TextEditingController _fimController;

  @override
  void initState() {
    super.initState();
    _colaborador = widget.colaboradores.firstWhere(
      (ColaboradorUsuarioResumo item) =>
          item.idUnicoPessoal == widget.meta?.idColaborador,
      orElse: () => widget.colaboradores.first,
    );
    _indicador = widget.meta?.indicador ?? desempenhoIndicadores.first.codigo;
    _status = widget.meta?.status ?? 'ATIVA';
    _valorController = TextEditingController(
      text: widget.meta == null ? '' : widget.meta!.valorAlvo.toStringAsFixed(2),
    );
    _pesoController = TextEditingController(
      text: widget.meta == null ? '1' : widget.meta!.peso.toStringAsFixed(2),
    );
    _inicioController = TextEditingController(
      text: _formatDate(widget.meta?.dataInicio ?? widget.dataInicioPadrao),
    );
    _fimController = TextEditingController(
      text: _formatDate(widget.meta?.dataFim ?? widget.dataFimPadrao),
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    _pesoController.dispose();
    _inicioController.dispose();
    _fimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.meta == null ? 'Nova meta' : 'Editar meta',
                        style: const TextStyle(
                          color: Color(0xFF0B1F3A),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildColaboradorField(),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _indicador,
                  decoration: const InputDecoration(
                    labelText: 'Indicador',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      desempenhoIndicadores
                          .map(
                            (DesempenhoIndicadorOption option) =>
                                DropdownMenuItem<String>(
                                  value: option.codigo,
                                  child: Text(option.label),
                                ),
                          )
                          .toList(growable: false),
                  onChanged:
                      (String? value) => setState(
                        () => _indicador = value ?? desempenhoIndicadores.first.codigo,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _valorController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor alvo',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validatePositiveNumber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _pesoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validatePositiveNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _inicioController,
                        decoration: const InputDecoration(
                          labelText: 'Início',
                          hintText: 'dd/mm/aaaa',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _fimController,
                        decoration: const InputDecoration(
                          labelText: 'Fim',
                          hintText: 'dd/mm/aaaa',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'ATIVA', child: Text('Ativa')),
                    DropdownMenuItem<String>(value: 'PAUSADA', child: Text('Pausada')),
                    DropdownMenuItem<String>(
                      value: 'ENCERRADA',
                      child: Text('Encerrada'),
                    ),
                  ],
                  onChanged:
                      (String? value) => setState(() => _status = value ?? 'ATIVA'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(widget.meta == null ? 'Cadastrar meta' : 'Salvar meta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColaboradorField() {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _selecionarColaborador,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Colaborador',
            border: OutlineInputBorder(),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _colaborador.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selecionarColaborador() async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (BuildContext context) => _ColaboradorSelectorSheet(
            colaboradores: widget.colaboradores,
            selectedId: _colaborador.idUnicoPessoal,
            allowAll: false,
          ),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _colaborador = widget.colaboradores.firstWhere(
        (ColaboradorUsuarioResumo item) => item.idUnicoPessoal == selected,
        orElse: () => _colaborador,
      );
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final DateTime inicio = _parseDate(_inicioController.text)!;
    final DateTime fim = _parseDate(_fimController.text)!;
    if (fim.isBefore(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data final não pode ser menor que a inicial.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final DesempenhoIndicadorOption indicador = indicadorPorCodigo(_indicador);
    Navigator.of(context).pop(<String, dynamic>{
      'idColaborador': _colaborador.idUnicoPessoal,
      'nomeColaborador': _colaborador.displayName,
      'tipoMeta': indicador.tipoMeta,
      'indicador': indicador.codigo,
      'valorAlvo': _parseNumber(_valorController.text),
      'peso': _parseNumber(_pesoController.text),
      'dataInicio': _formatApiDate(inicio),
      'dataFim': _formatApiDate(fim),
      'status': _status,
    });
  }

  String? _validatePositiveNumber(String? value) {
    final double number = _parseNumber(value ?? '');
    if (number <= 0) {
      return 'Informe um valor maior que zero';
    }
    return null;
  }

  String? _validateDate(String? value) {
    if (_parseDate(value ?? '') == null) {
      return 'Use dd/mm/aaaa';
    }
    return null;
  }

  DateTime? _parseDate(String value) {
    final List<String> parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (year < 2000 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    return DateTime(year, month, day);
  }

  double _parseNumber(String value) {
    return double.tryParse(
          value.trim().replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatApiDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}

class _ColaboradorSelectorSheet extends StatelessWidget {
  const _ColaboradorSelectorSheet({
    required this.colaboradores,
    required this.selectedId,
    required this.allowAll,
  });

  final List<ColaboradorUsuarioResumo> colaboradores;
  final String? selectedId;
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selecionar colaborador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            if (allowAll)
              _SelectorTile(
                title: 'Todos os colaboradores',
                subtitle: 'Visão consolidada da equipe',
                selected: selectedId == null,
                icon: Icons.groups_2_outlined,
                onTap: () => Navigator.of(context).pop(null),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: colaboradores.length,
                itemBuilder: (BuildContext context, int index) {
                  final ColaboradorUsuarioResumo colaborador = colaboradores[index];
                  return _SelectorTile(
                    title: colaborador.displayName,
                    subtitle: colaborador.email.isEmpty ? 'Colaborador' : colaborador.email,
                    selected: colaborador.idUnicoPessoal == selectedId,
                    icon: Icons.badge_outlined,
                    onTap: () => Navigator.of(context).pop(colaborador.idUnicoPessoal),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEFF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFDCEBFF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.title,
    this.subtitle,
    this.action,
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0B1F3A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title!,
                        style: const TextStyle(
                          color: Color(0xFF0B1F3A),
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0B1F3A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B1F3A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF64748B)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

extension _ColaboradorDisplayName on ColaboradorUsuarioResumo {
  String get displayName {
    if (nomeDeGuerra.trim().isNotEmpty) return nomeDeGuerra.trim();
    if (nome.trim().isNotEmpty) return nome.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return 'Colaborador';
  }
}
