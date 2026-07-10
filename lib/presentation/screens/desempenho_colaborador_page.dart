import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/desempenho_colaborador_model.dart';
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
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _primary = Color(0xFF0B1F3A);
  static const Color _secondary = Color(0xFF123B69);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  final DesempenhoColaboradorApiClient _api =
      HttpDesempenhoColaboradorApiClient();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  late DateTime _inicio;
  late DateTime _fim;
  String? _idColaborador;
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
    _inicio = DateTime(now.year, now.month);
    _fim = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<ColaboradorUsuarioResumo> colaboradores =
          await _api.listarParticipantes();
      final List<MetaColaboradorModel> metas = await _api.listarMetas();
      final DesempenhoColaboradorResumoModel resumo = await _api.buscarResumo(
        dataInicio: _inicio,
        dataFim: _fim,
        idColaborador: _idColaborador,
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
      color: _background,
      child: Column(
        children: <Widget>[
          _Header(
            embedded: widget.embedded,
            onBack: widget.onBack,
            saving: _saving,
            onNewGoal: () => _openGoalForm(),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
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

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: SixBackendLoading.messages(
          animation: SixBackendLoadingAnimation.skeletonPulse,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: _Panel(
          maxWidth: 520,
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
                _error!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 920;
          return ListView(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 18, wide ? 24 : 16, 28),
            children: <Widget>[
              _buildFilters(wide),
              const SizedBox(height: 16),
              _buildKpis(wide),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 7, child: _buildResultados()),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _buildMetas()),
                  ],
                )
              else ...<Widget>[
                _buildResultados(),
                const SizedBox(height: 16),
                _buildMetas(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(bool wide) {
    return _Panel(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _periodChip('Mês atual', _isCurrentMonth(), () {
            final DateTime now = DateTime.now();
            _setPeriod(DateTime(now.year, now.month), now);
          }),
          _periodChip('Últimos 30 dias', _isLastThirtyDays(), () {
            final DateTime now = DateTime.now();
            _setPeriod(now.subtract(const Duration(days: 29)), now);
          }),
          _periodChip('Hoje', _isToday(), () {
            final DateTime now = DateTime.now();
            _setPeriod(now, now);
          }),
          SizedBox(
            width: wide ? 310 : double.infinity,
            child: _SelectorButton(
              icon: Icons.badge_outlined,
              label: _selectedCollaboratorName,
              onTap: _selectCollaboratorFilter,
            ),
          ),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('${_dateFormat.format(_inicio)} até ${_dateFormat.format(_fim)}'),
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: const Color(0xFFDCEBFF),
      labelStyle: TextStyle(
        color: selected ? _primary : _muted,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildKpis(bool wide) {
    final List<_KpiData> kpis = <_KpiData>[
      _KpiData(
        'Score médio',
        '${_resumo.scoreMedio.toStringAsFixed(0)}%',
        'Média ponderada das metas',
        Icons.speed_rounded,
      ),
      _KpiData(
        'Metas batidas',
        '${_resumo.metasBatidas}/${_resumo.totalMetas}',
        'Dentro do período filtrado',
        Icons.emoji_events_outlined,
      ),
      _KpiData(
        'Vendas',
        _currencyFormat.format(_resumo.valorTotalVendido),
        '${_resumo.quantidadeVendas} operações no período',
        Icons.point_of_sale_rounded,
      ),
      _KpiData(
        'Atendimentos',
        _resumo.quantidadeAtendimentos.toString(),
        'Assistências técnicas no período',
        Icons.build_circle_outlined,
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: kpis
          .map(
            (_KpiData item) => SizedBox(
              width: wide ? 230 : double.infinity,
              child: _KpiCard(data: item),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildResultados() {
    return _Panel(
      title: 'Meta x realizado',
      subtitle: 'Resultado calculado automaticamente pelo período selecionado.',
      action: IconButton(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Atualizar',
      ),
      child: _resumo.resultados.isEmpty
          ? const _EmptyState(
              icon: Icons.flag_outlined,
              title: 'Nenhuma meta ativa no período',
              subtitle: 'Cadastre uma meta para acompanhar a evolução do colaborador.',
            )
          : Column(
              children: _resumo.resultados.map(_resultTile).toList(growable: false),
            ),
    );
  }

  Widget _resultTile(DesempenhoColaboradorItemModel item) {
    final DesempenhoIndicadorOption indicador = indicadorPorCodigo(item.indicador);
    final Color statusColor = _statusColor(item.status);
    final double progress = (item.percentualAtingido / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.nomeColaborador.isEmpty ? 'Participante' : item.nomeColaborador,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primary,
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
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${_formatValue(item.valorRealizado, indicador)} de ${_formatValue(item.valorAlvo, indicador)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${item.percentualAtingido.toStringAsFixed(0)}%',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetas() {
    final List<MetaColaboradorModel> metas = _metas
        .where(
          (MetaColaboradorModel meta) =>
              _idColaborador == null || meta.idColaborador == _idColaborador,
        )
        .toList(growable: false);

    return _Panel(
      title: 'Metas cadastradas',
      subtitle: 'Administre metas sem gerar relatórios nesta etapa.',
      action: IconButton(
        onPressed: () => _openGoalForm(),
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Nova meta',
      ),
      child: metas.isEmpty
          ? const _EmptyState(
              icon: Icons.playlist_add_check_rounded,
              title: 'Sem metas cadastradas',
              subtitle: 'Crie metas por colaborador para acompanhar o resultado.',
            )
          : Column(children: metas.map(_metaTile).toList(growable: false)),
    );
  }

  Widget _metaTile(MetaColaboradorModel meta) {
    final DesempenhoIndicadorOption indicador = indicadorPorCodigo(meta.indicador);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openGoalForm(meta: meta),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
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
                child: const Icon(Icons.flag_outlined, color: _accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      meta.nomeColaborador.isEmpty ? 'Participante' : meta.nomeColaborador,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${indicador.label} • ${_formatPeriod(meta.dataInicio, meta.dataFim)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: _muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGoalForm({MetaColaboradorModel? meta}) async {
    if (_colaboradores.isEmpty) {
      _showSnack('Cadastre ou carregue participantes antes de criar metas.');
      return;
    }

    final Map<String, dynamic>? payload;
    if (MediaQuery.of(context).size.width >= 720) {
      payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _GoalForm(
              colaboradores: _colaboradores,
              inicioPadrao: _inicio,
              fimPadrao: _fim,
              meta: meta,
            ),
          ),
        ),
      );
    } else {
      payload = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) => _GoalForm(
          colaboradores: _colaboradores,
          inicioPadrao: _inicio,
          fimPadrao: _fim,
          meta: meta,
        ),
      );
    }

    if (payload == null) return;
    await _saveGoal(meta, payload);
  }

  Future<void> _saveGoal(MetaColaboradorModel? meta, Map<String, dynamic> payload) async {
    setState(() => _saving = true);
    try {
      if (meta == null) {
        await _api.criarMeta(payload);
      } else {
        await _api.editarMeta(meta.id, payload);
      }
      await _load();
      if (!mounted) return;
      _showSnack(meta == null ? 'Meta cadastrada.' : 'Meta atualizada.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Não foi possível salvar a meta: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectCollaboratorFilter() async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _CollaboratorSheet(
        colaboradores: _colaboradores,
        selectedId: _idColaborador,
        allowAll: true,
      ),
    );

    if (!mounted || selected == null) return;
    setState(() => _idColaborador = selected == '__ALL__' ? null : selected);
    await _load();
  }

  void _setPeriod(DateTime inicio, DateTime fim) {
    setState(() {
      _inicio = DateTime(inicio.year, inicio.month, inicio.day);
      _fim = DateTime(fim.year, fim.month, fim.day);
    });
    _load();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentMonth() {
    final DateTime now = DateTime.now();
    return _sameDay(_inicio, DateTime(now.year, now.month)) &&
        _sameDay(_fim, DateTime(now.year, now.month, now.day));
  }

  bool _isLastThirtyDays() {
    final DateTime now = DateTime.now();
    return _sameDay(_inicio, now.subtract(const Duration(days: 29))) &&
        _sameDay(_fim, now);
  }

  bool _isToday() {
    final DateTime now = DateTime.now();
    return _sameDay(_inicio, now) && _sameDay(_fim, now);
  }

  String get _selectedCollaboratorName {
    if (_idColaborador == null) return 'Todos os participantes';
    return _colaboradores
        .firstWhere(
          (ColaboradorUsuarioResumo item) => item.idUnicoPessoal == _idColaborador,
          orElse: () => ColaboradorUsuarioResumo(
            idUnicoPessoal: _idColaborador ?? '',
            nome: 'Participante',
            nomeDeGuerra: '',
            celularDeAcesso: '',
            email: '',
            foto: '',
            dataCadastro: null,
          ),
        )
        .displayName;
  }

  String _formatValue(double value, DesempenhoIndicadorOption indicador) {
    if (indicador.valorMonetario) return _currencyFormat.format(value);
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  String _formatPeriod(DateTime? inicio, DateTime? fim) {
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
        return _accent;
      case 'EM_RISCO':
        return const Color(0xFFD97706);
      case 'CRITICO':
        return const Color(0xFFDC2626);
      default:
        return _muted;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.embedded,
    required this.saving,
    required this.onNewGoal,
    this.onBack,
  });

  final bool embedded;
  final bool saving;
  final VoidCallback onNewGoal;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(embedded ? 18 : 16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_DesempenhoColaboradorPageState._primary, _DesempenhoColaboradorPageState._secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: 'Fechar',
              ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: const Icon(Icons.trending_up_rounded, color: Colors.white),
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
                foregroundColor: _DesempenhoColaboradorPageState._primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: saving ? null : onNewGoal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nova meta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalForm extends StatefulWidget {
  const _GoalForm({
    required this.colaboradores,
    required this.inicioPadrao,
    required this.fimPadrao,
    this.meta,
  });

  final List<ColaboradorUsuarioResumo> colaboradores;
  final DateTime inicioPadrao;
  final DateTime fimPadrao;
  final MetaColaboradorModel? meta;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
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
      text: widget.meta == null ? '' : _decimalToPt(widget.meta!.valorAlvo),
    );
    _pesoController = TextEditingController(
      text: widget.meta == null ? '1' : _decimalToPt(widget.meta!.peso),
    );
    _inicioController = TextEditingController(
      text: _formatDate(widget.meta?.dataInicio ?? widget.inicioPadrao),
    );
    _fimController = TextEditingController(
      text: _formatDate(widget.meta?.dataFim ?? widget.fimPadrao),
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
                          color: _DesempenhoColaboradorPageState._primary,
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
                _SelectorButton(
                  icon: Icons.badge_outlined,
                  label: _colaborador.displayName,
                  onTap: _selectCollaborator,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Indicador',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: desempenhoIndicadores
                      .map(
                        (DesempenhoIndicadorOption option) => ChoiceChip(
                          selected: _indicador == option.codigo,
                          label: Text(option.label),
                          selectedColor: const Color(0xFFDCEBFF),
                          onSelected: (_) => setState(() => _indicador = option.codigo),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _valorController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: <String>['ATIVA', 'PAUSADA', 'ENCERRADA']
                      .map(
                        (String status) => ChoiceChip(
                          selected: _status == status,
                          label: Text(_statusText(status)),
                          selectedColor: const Color(0xFFDCEBFF),
                          onSelected: (_) => setState(() => _status = status),
                        ),
                      )
                      .toList(growable: false),
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

  Future<void> _selectCollaborator() async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _CollaboratorSheet(
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
    if (_parseNumber(value ?? '') <= 0) return 'Informe um valor maior que zero';
    return null;
  }

  String? _validateDate(String? value) {
    if (_parseDate(value ?? '') == null) return 'Use dd/mm/aaaa';
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
    final DateTime date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) return null;
    return date;
  }

  double _parseNumber(String value) {
    String normalized = value.trim().replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }

  String _decimalToPt(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatApiDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _statusText(String status) {
    switch (status) {
      case 'PAUSADA':
        return 'Pausada';
      case 'ENCERRADA':
        return 'Encerrada';
      default:
        return 'Ativa';
    }
  }
}

class _CollaboratorSheet extends StatelessWidget {
  const _CollaboratorSheet({
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
                'Selecionar participante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            if (allowAll)
              _SelectorTile(
                title: 'Todos os participantes',
                subtitle: 'Visão consolidada da equipe e do ADMIN',
                selected: selectedId == null,
                icon: Icons.groups_2_outlined,
                onTap: () => Navigator.of(context).pop('__ALL__'),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: colaboradores.length,
                itemBuilder: (BuildContext context, int index) {
                  final ColaboradorUsuarioResumo colaborador = colaboradores[index];
                  return _SelectorTile(
                    title: colaborador.displayName,
                    subtitle: colaborador.email.isEmpty ? 'Participante' : colaborador.email,
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

class _SelectorButton extends StatelessWidget {
  const _SelectorButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _DesempenhoColaboradorPageState._border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: _DesempenhoColaboradorPageState._accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _DesempenhoColaboradorPageState._muted),
            ],
          ),
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
                child: Icon(icon, color: _DesempenhoColaboradorPageState._accent, size: 20),
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
                      style: const TextStyle(color: _DesempenhoColaboradorPageState._muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: _DesempenhoColaboradorPageState._accent),
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
    this.maxWidth,
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final Widget panel = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _DesempenhoColaboradorPageState._border),
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
                          color: _DesempenhoColaboradorPageState._primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(color: _DesempenhoColaboradorPageState._muted),
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

    if (maxWidth == null) return panel;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: panel,
    );
  }
}

class _KpiData {
  const _KpiData(this.title, this.value, this.subtitle, this.icon);

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DesempenhoColaboradorPageState._border),
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
            child: Icon(data.icon, color: _DesempenhoColaboradorPageState._accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DesempenhoColaboradorPageState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DesempenhoColaboradorPageState._primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _DesempenhoColaboradorPageState._muted, fontSize: 11),
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
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
        border: Border.all(color: _DesempenhoColaboradorPageState._border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: _DesempenhoColaboradorPageState._muted),
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
            style: const TextStyle(color: _DesempenhoColaboradorPageState._muted),
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
    return 'Participante';
  }
}
