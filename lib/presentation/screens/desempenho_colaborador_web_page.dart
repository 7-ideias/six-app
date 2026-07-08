import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/desempenho_colaborador_model.dart';
import '../../data/services/desempenho_colaborador/desempenho_colaborador_api_client.dart';
import '../components/six_backend_loading.dart';

class DesempenhoColaboradorWebPage extends StatefulWidget {
  const DesempenhoColaboradorWebPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<DesempenhoColaboradorWebPage> createState() =>
      _DesempenhoColaboradorWebPageState();
}

enum _SituacaoParticipante { ativos, inativos, todos }

class _DesempenhoColaboradorWebPageState
    extends State<DesempenhoColaboradorWebPage> {
  final DesempenhoColaboradorApiClient _api =
      HttpDesempenhoColaboradorApiClient();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
  );

  late DateTime _inicio;
  late DateTime _fim;
  String? _idParticipante;
  _SituacaoParticipante _situacao = _SituacaoParticipante.ativos;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<ColaboradorUsuarioResumo> _participantes = <ColaboradorUsuarioResumo>[];
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
      final List<ColaboradorUsuarioResumo> participantes =
          await _api.listarParticipantes();
      final List<MetaColaboradorModel> metas = await _api.listarMetas();
      final DesempenhoColaboradorResumoModel resumo = await _api.buscarResumo(
        dataInicio: _inicio,
        dataFim: _fim,
        idColaborador: _idParticipante,
      );

      if (!mounted) return;
      setState(() {
        _participantes = participantes;
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

  List<ColaboradorUsuarioResumo> get _participantesVisiveis {
    switch (_situacao) {
      case _SituacaoParticipante.ativos:
        return _participantes.where((item) => item.ativo).toList(growable: false);
      case _SituacaoParticipante.inativos:
        return _participantes.where((item) => !item.ativo).toList(growable: false);
      case _SituacaoParticipante.todos:
        return _participantes;
    }
  }

  Set<String> get _idsVisiveis => _participantesVisiveis
      .map((item) => item.idUnicoPessoal)
      .where((id) => id.trim().isNotEmpty)
      .toSet();

  List<MetaColaboradorModel> get _metasVisiveis {
    return _metas.where((meta) {
      if (_idParticipante != null) return meta.idColaborador == _idParticipante;
      return _idsVisiveis.contains(meta.idColaborador);
    }).toList(growable: false);
  }

  List<DesempenhoColaboradorItemModel> get _resultadosVisiveis {
    return _resumo.resultados.where((item) {
      if (_idParticipante != null) return item.idColaborador == _idParticipante;
      return _idsVisiveis.contains(item.idColaborador);
    }).toList(growable: false);
  }

  int get _totalAtivos => _participantes.where((item) => item.ativo).length;

  int get _totalInativos => _participantes.where((item) => !item.ativo).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: <Widget>[
          _buildHeader(theme),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildBody(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          _headerIcon(theme, Icons.trending_up_rounded),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Desempenho do colaborador',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resumo executivo de metas, vendas, serviços e atendimentos por participante.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : () => _openGoalForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova meta'),
              ),
              IconButton.filledTonal(
                onPressed: widget.onBack,
                tooltip: 'Fechar',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(ThemeData theme, IconData icon) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 28),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(
        key: ValueKey<String>('desempenho-loading'),
        child: SixBackendLoading.messages(
          compact: false,
          animation: SixBackendLoadingAnimation.skeletonPulse,
        ),
      );
    }

    if (_error != null) {
      return Center(
        key: const ValueKey<String>('desempenho-error'),
        child: _InfoCard(
          maxWidth: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
              const SizedBox(height: 10),
              Text(
                'Não foi possível carregar o desempenho.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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

    return LayoutBuilder(
      key: const ValueKey<String>('desempenho-content'),
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 1180;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildFilters(theme, compact),
              const SizedBox(height: 18),
              _buildKpis(theme, compact),
              const SizedBox(height: 18),
              if (compact) ...<Widget>[
                _buildResultados(theme),
                const SizedBox(height: 18),
                _buildMetas(theme),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 7, child: _buildResultados(theme)),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: _buildMetas(theme)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(ThemeData theme, bool compact) {
    return _InfoCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _periodChip(theme, 'Mês atual', _isCurrentMonth(), () {
            final DateTime now = DateTime.now();
            _setPeriod(DateTime(now.year, now.month), now);
          }),
          _periodChip(theme, 'Últimos 30 dias', _isLastThirtyDays(), () {
            final DateTime now = DateTime.now();
            _setPeriod(now.subtract(const Duration(days: 29)), now);
          }),
          _periodChip(theme, 'Hoje', _isToday(), () {
            final DateTime now = DateTime.now();
            _setPeriod(now, now);
          }),
          SizedBox(
            width: compact ? 320 : 340,
            child: _SelectorButton(
              icon: Icons.badge_outlined,
              label: _selectedParticipantName,
              onTap: _selectParticipant,
            ),
          ),
          _situacaoChip(theme, 'Ativos', _SituacaoParticipante.ativos, _totalAtivos),
          _situacaoChip(theme, 'Não ativos', _SituacaoParticipante.inativos, _totalInativos),
          _situacaoChip(theme, 'Ambos', _SituacaoParticipante.todos, _participantes.length),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.event_repeat_rounded, size: 18),
            label: Text('${_dateFormat.format(_inicio)} até ${_dateFormat.format(_fim)}'),
          ),
        ],
      ),
    );
  }

  Widget _periodChip(
    ThemeData theme,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: theme.colorScheme.primary.withOpacity(0.12),
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: (_) => onTap(),
    );
  }

  Widget _situacaoChip(
    ThemeData theme,
    String label,
    _SituacaoParticipante value,
    int total,
  ) {
    final bool selected = _situacao == value;
    return ChoiceChip(
      selected: selected,
      label: Text('$label ($total)'),
      selectedColor: theme.colorScheme.primary.withOpacity(0.12),
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: (_) {
        setState(() {
          _situacao = value;
          if (_idParticipante != null &&
              !_participantesVisiveis.any((item) => item.idUnicoPessoal == _idParticipante)) {
            _idParticipante = null;
          }
        });
      },
    );
  }

  Widget _buildKpis(ThemeData theme, bool compact) {
    final List<_KpiData> items = <_KpiData>[
      _KpiData('Score médio', '${_resumo.scoreMedio.toStringAsFixed(0)}%', 'Média ponderada das metas', Icons.speed_rounded),
      _KpiData('Metas batidas', '${_resumo.metasBatidas}/${_resumo.totalMetas}', 'Dentro do período filtrado', Icons.emoji_events_outlined),
      _KpiData('Vendas', _currencyFormat.format(_resumo.valorTotalVendido), '${_resumo.quantidadeVendas} operações no período', Icons.point_of_sale_rounded),
      _KpiData('Atendimentos', _resumo.quantidadeAtendimentos.toString(), 'Assistências técnicas no período', Icons.build_circle_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) => _KpiCard(data: items[index]),
    );
  }

  Widget _buildResultados(ThemeData theme) {
    final resultados = _resultadosVisiveis;
    return _InfoCard(
      title: 'Meta x realizado',
      subtitle: 'Resultado calculado automaticamente pelo período selecionado.',
      action: IconButton(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Atualizar',
      ),
      child: resultados.isEmpty
          ? const _EmptyState(
              icon: Icons.flag_outlined,
              title: 'Nenhuma meta ativa para exibir',
              subtitle: 'Ajuste o filtro de participantes ou cadastre uma nova meta.',
            )
          : Column(
              children: resultados.map((item) => _resultTile(theme, item)).toList(growable: false),
            ),
    );
  }

  Widget _resultTile(ThemeData theme, DesempenhoColaboradorItemModel item) {
    final DesempenhoIndicadorOption indicador = indicadorPorCodigo(item.indicador);
    final Color color = _statusColor(item.status);
    final double progress = (item.percentualAtingido / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _StatusPill(label: _statusLabel(item.status), color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            indicador.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: theme.colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
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
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${item.percentualAtingido.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetas(ThemeData theme) {
    final metas = _metasVisiveis;
    return _InfoCard(
      title: 'Metas cadastradas',
      subtitle: 'Participantes filtrados por situação sem alterar o cálculo.',
      action: IconButton(
        onPressed: _saving ? null : () => _openGoalForm(),
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Nova meta',
      ),
      child: metas.isEmpty
          ? const _EmptyState(
              icon: Icons.playlist_add_check_rounded,
              title: 'Sem metas cadastradas',
              subtitle: 'Crie metas para os participantes exibidos.',
            )
          : Column(children: metas.map((meta) => _metaTile(theme, meta)).toList(growable: false)),
    );
  }

  Widget _metaTile(ThemeData theme, MetaColaboradorModel meta) {
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
            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.flag_outlined, color: theme.colorScheme.primary, size: 20),
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
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${indicador.label} • ${_formatPeriod(meta.dataInicio, meta.dataFim)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGoalForm({MetaColaboradorModel? meta}) async {
    final participantes = _participantesVisiveis;
    if (participantes.isEmpty) {
      _showSnack('Não há participantes para o filtro selecionado.');
      return;
    }

    final Map<String, dynamic>? payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: _GoalForm(
            participantes: participantes,
            inicioPadrao: _inicio,
            fimPadrao: _fim,
            meta: meta,
          ),
        ),
      ),
    );

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

  Future<void> _selectParticipant() async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: _ParticipantSelectorDialog(
            participantes: _participantesVisiveis,
            selectedId: _idParticipante,
            allowAll: true,
          ),
        ),
      ),
    );

    if (!mounted || selected == null) return;
    setState(() => _idParticipante = selected == '__ALL__' ? null : selected);
    await _load();
  }

  void _setPeriod(DateTime inicio, DateTime fim) {
    setState(() {
      _inicio = DateTime(inicio.year, inicio.month, inicio.day);
      _fim = DateTime(fim.year, fim.month, fim.day);
    });
    _load();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

  String get _selectedParticipantName {
    if (_idParticipante == null) {
      switch (_situacao) {
        case _SituacaoParticipante.ativos:
          return 'Todos os ativos';
        case _SituacaoParticipante.inativos:
          return 'Todos os não ativos';
        case _SituacaoParticipante.todos:
          return 'Todos os participantes';
      }
    }
    return _participantes.firstWhere(
      (item) => item.idUnicoPessoal == _idParticipante,
      orElse: () => ColaboradorUsuarioResumo(
        idUnicoPessoal: _idParticipante ?? '',
        nome: 'Participante',
        nomeDeGuerra: '',
        celularDeAcesso: '',
        email: '',
        foto: '',
        dataCadastro: null,
      ),
    ).displayName;
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
        return const Color(0xFF2563EB);
      case 'EM_RISCO':
        return const Color(0xFFD97706);
      case 'CRITICO':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _GoalForm extends StatefulWidget {
  const _GoalForm({
    required this.participantes,
    required this.inicioPadrao,
    required this.fimPadrao,
    this.meta,
  });

  final List<ColaboradorUsuarioResumo> participantes;
  final DateTime inicioPadrao;
  final DateTime fimPadrao;
  final MetaColaboradorModel? meta;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late ColaboradorUsuarioResumo _participante;
  late String _indicador;
  late String _status;
  late TextEditingController _valorController;
  late TextEditingController _pesoController;
  late TextEditingController _inicioController;
  late TextEditingController _fimController;

  @override
  void initState() {
    super.initState();
    _participante = widget.participantes.firstWhere(
      (item) => item.idUnicoPessoal == widget.meta?.idColaborador,
      orElse: () => widget.participantes.first,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(18),
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
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
                label: _participante.displayName,
                onTap: _selectParticipant,
              ),
              const SizedBox(height: 14),
              Text('Indicador', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: desempenhoIndicadores.map((option) {
                  return ChoiceChip(
                    selected: _indicador == option.codigo,
                    label: Text(option.label),
                    onSelected: (_) => setState(() => _indicador = option.codigo),
                  );
                }).toList(growable: false),
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
                children: <String>['ATIVA', 'PAUSADA', 'ENCERRADA'].map((status) {
                  return ChoiceChip(
                    selected: _status == status,
                    label: Text(_statusText(status)),
                    onSelected: (_) => setState(() => _status = status),
                  );
                }).toList(growable: false),
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
    );
  }

  Future<void> _selectParticipant() async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: _ParticipantSelectorDialog(
            participantes: widget.participantes,
            selectedId: _participante.idUnicoPessoal,
            allowAll: false,
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _participante = widget.participantes.firstWhere(
        (item) => item.idUnicoPessoal == selected,
        orElse: () => _participante,
      );
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final DateTime inicio = _parseDate(_inicioController.text)!;
    final DateTime fim = _parseDate(_fimController.text)!;
    if (fim.isBefore(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data final não pode ser menor que a inicial.')),
      );
      return;
    }
    final indicador = indicadorPorCodigo(_indicador);
    Navigator.of(context).pop(<String, dynamic>{
      'idColaborador': _participante.idUnicoPessoal,
      'nomeColaborador': _participante.displayName,
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
    final parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
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

  String _decimalToPt(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _formatApiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

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

class _ParticipantSelectorDialog extends StatelessWidget {
  const _ParticipantSelectorDialog({
    required this.participantes,
    required this.selectedId,
    required this.allowAll,
  });

  final List<ColaboradorUsuarioResumo> participantes;
  final String? selectedId;
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Selecionar participante',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (allowAll)
            _SelectorTile(
              title: 'Todos os participantes',
              subtitle: 'Visão consolidada conforme o filtro de situação',
              selected: selectedId == null,
              icon: Icons.groups_2_outlined,
              onTap: () => Navigator.of(context).pop('__ALL__'),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: participantes.length,
              itemBuilder: (BuildContext context, int index) {
                final item = participantes[index];
                return _SelectorTile(
                  title: item.displayName,
                  subtitle: item.email.isEmpty ? _statusParticipante(item) : '${item.email} • ${_statusParticipante(item)}',
                  selected: item.idUnicoPessoal == selectedId,
                  icon: item.ativo ? Icons.badge_outlined : Icons.block_outlined,
                  onTap: () => Navigator.of(context).pop(item.idUnicoPessoal),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusParticipante(ColaboradorUsuarioResumo item) {
    if (item.ativo) return 'Ativo';
    if (item.status.trim().isNotEmpty) return item.status;
    return 'Não ativo';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
    final theme = Theme.of(context);
    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F0B1F3A), blurRadius: 18, offset: Offset(0, 8)),
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
                      Text(title!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
    if (maxWidth == null) return card;
    return ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: card);
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F0B1F3A), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  const _SelectorButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? theme.colorScheme.primary.withOpacity(0.10) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
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
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

extension _ParticipanteDisplayName on ColaboradorUsuarioResumo {
  String get displayName {
    if (nomeDeGuerra.trim().isNotEmpty) return nomeDeGuerra.trim();
    if (nome.trim().isNotEmpty) return nome.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return 'Participante';
  }
}
