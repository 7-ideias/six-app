import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/desempenho_colaborador_model.dart';
import '../../data/services/desempenho_colaborador/desempenho_colaborador_api_client.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/date_selector_mobile_bottom_sheet.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_selection_sheet.dart';
import '../components/mobile_motion.dart';

class DesempenhoColaboradorMobileScreen extends StatefulWidget {
  const DesempenhoColaboradorMobileScreen({super.key, this.apiClient});

  final DesempenhoColaboradorApiClient? apiClient;

  @override
  State<DesempenhoColaboradorMobileScreen> createState() =>
      _DesempenhoColaboradorMobileScreenState();
}

enum _SituacaoParticipanteMobile { ativos, inativos, todos }

class _DesempenhoColaboradorMobileScreenState
    extends State<DesempenhoColaboradorMobileScreen> {
  static const Color _success = Color(0xFF15803D);
  static const Color _warning = Color(0xFFB45309);

  late final DesempenhoColaboradorApiClient _apiClient;
  late DateTime _inicio;
  late DateTime _fim;

  String? _idParticipante;
  _SituacaoParticipanteMobile _situacao = _SituacaoParticipanteMobile.ativos;
  int _selectedSection = 0;
  bool _loading = true;
  bool _saving = false;
  bool _hasError = false;
  List<ColaboradorUsuarioResumo> _participantes = <ColaboradorUsuarioResumo>[];
  List<MetaColaboradorModel> _metas = <MetaColaboradorModel>[];
  DesempenhoColaboradorResumoModel _resumo =
      DesempenhoColaboradorResumoModel.empty();

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? HttpDesempenhoColaboradorApiClient();
    final DateTime now = DateTime.now();
    _inicio = DateTime(now.year, now.month);
    _fim = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (mounted) {
      setState(() {
        if (showLoading) _loading = true;
        _hasError = false;
      });
    }

    try {
      final List<Object> response = await Future.wait<Object>(<Future<Object>>[
        _apiClient.listarParticipantes(),
        _apiClient.listarMetas(),
        _apiClient.buscarResumo(
          dataInicio: _inicio,
          dataFim: _fim,
          idColaborador: _idParticipante,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _participantes = response[0] as List<ColaboradorUsuarioResumo>;
        _metas = response[1] as List<MetaColaboradorModel>;
        _resumo = response[2] as DesempenhoColaboradorResumoModel;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  List<ColaboradorUsuarioResumo> get _participantesVisiveis {
    return switch (_situacao) {
      _SituacaoParticipanteMobile.ativos =>
        _participantes.where((item) => item.ativo).toList(growable: false),
      _SituacaoParticipanteMobile.inativos =>
        _participantes.where((item) => !item.ativo).toList(growable: false),
      _SituacaoParticipanteMobile.todos => _participantes,
    };
  }

  Set<String> get _idsParticipantesVisiveis => _participantesVisiveis
      .map((item) => item.idUnicoPessoal)
      .where((id) => id.trim().isNotEmpty)
      .toSet();

  List<MetaColaboradorModel> get _metasVisiveis {
    return _metas
        .where((meta) {
          if (_idParticipante != null) {
            return meta.idColaborador == _idParticipante;
          }
          return _idsParticipantesVisiveis.contains(meta.idColaborador);
        })
        .toList(growable: false);
  }

  List<DesempenhoColaboradorItemModel> get _resultadosVisiveis {
    return _resumo.resultados
        .where((item) {
          if (_idParticipante != null) {
            return item.idColaborador == _idParticipante;
          }
          return _idsParticipantesVisiveis.contains(item.idColaborador);
        })
        .toList(growable: false);
  }

  int get _totalAtivos => _participantes.where((item) => item.ativo).length;

  int get _totalInativos => _participantes.where((item) => !item.ativo).length;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    context.watch<LocaleSettingsProvider>();

    return SixMobilePageShell(
      title: context.t('performance.mobile.title', fallback: 'Desempenho'),
      backgroundColor: colors.background,
      primaryColor: colors.primary,
      secondaryColor: colors.secondary,
      accentColor: colors.accent,
      actions: <Widget>[
        IconButton(
          tooltip: context.t(
            'performance.mobile.refresh',
            fallback: 'Atualizar desempenho',
          ),
          onPressed: _loading ? null : () => _load(showLoading: false),
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: context.t(
            'performance.mobile.newGoal',
            fallback: 'Nova meta',
          ),
          onPressed: _loading || _saving ? null : () => _openGoalForm(),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      bodyBuilder: _buildBody,
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    if (_loading) {
      return _PerformanceLoadingBody(
        scrollController: scrollController,
        topInset: topInset,
      );
    }

    if (_hasError) {
      return _buildErrorBody(context, scrollController, topInset);
    }

    return RefreshIndicator(
      onRefresh: () => _load(showLoading: false),
      color: context.sixMobileColors.accent,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
        children: <Widget>[
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 40),
            child: _buildHero(context),
          ),
          const SizedBox(height: 14),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 90),
            child: _buildFilters(context),
          ),
          const SizedBox(height: 14),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 140),
            child: _buildKpis(context),
          ),
          const SizedBox(height: 16),
          SixStaggeredEntry(
            delay: const Duration(milliseconds: 190),
            child: _PerformanceSectionTabs(
              selectedIndex: _selectedSection,
              resultsLabel: context.t(
                'performance.mobile.resultsTab',
                fallback: 'Resultados',
              ),
              goalsLabel: context.t(
                'performance.mobile.goalsTab',
                fallback: 'Metas',
              ),
              onChanged: (value) => setState(() => _selectedSection = value),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _selectedSection == 0
                ? _buildResultados(context)
                : _buildMetas(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBody(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, topInset + 36, 16, 28),
      children: <Widget>[
        _PerformancePanel(
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    color: colors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.t(
                    'performance.mobile.loadError',
                    fallback: 'Não foi possível carregar o desempenho.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t(
                    'performance.mobile.loadErrorDesc',
                    fallback: 'Verifique sua conexão e tente novamente.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.mutedText, height: 1.35),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    context.t(
                      'performance.mobile.tryAgain',
                      fallback: 'Tentar novamente',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.heroShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.onPrimary.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: colors.onPrimary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'performance.mobile.heroTitle',
                    fallback: 'Desempenho da equipe',
                  ),
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.t(
                    'performance.mobile.heroSubtitle',
                    fallback:
                        'Acompanhe metas, vendas, serviços e atendimentos por participante.',
                  ),
                  style: TextStyle(
                    color: colors.heroSupportingText,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.calendar_month_outlined,
                      color: colors.heroLabelText,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${locale.formatDate(_inicio)} — ${locale.formatDate(_fim)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.heroLabelText,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return _PerformancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _periodChip(
                context,
                context.t(
                  'performance.mobile.currentMonth',
                  fallback: 'Mês atual',
                ),
                _isCurrentMonth(),
                () {
                  final DateTime now = DateTime.now();
                  _setPeriod(DateTime(now.year, now.month), now);
                },
              ),
              _periodChip(
                context,
                context.t(
                  'performance.mobile.lastThirtyDays',
                  fallback: 'Últimos 30 dias',
                ),
                _isLastThirtyDays(),
                () {
                  final DateTime now = DateTime.now();
                  _setPeriod(now.subtract(const Duration(days: 29)), now);
                },
              ),
              _periodChip(
                context,
                context.t('performance.mobile.today', fallback: 'Hoje'),
                _isToday(),
                () {
                  final DateTime now = DateTime.now();
                  _setPeriod(now, now);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SixMobileSelectionField(
            label: context.t(
              'performance.mobile.participant',
              fallback: 'Participante',
            ),
            value: _selectedParticipantName(context),
            icon: Icons.badge_outlined,
            onTap: _selectParticipant,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _situationChip(
                  context,
                  context.t('performance.mobile.active', fallback: 'Ativos'),
                  _SituacaoParticipanteMobile.ativos,
                  _totalAtivos,
                ),
                const SizedBox(width: 8),
                _situationChip(
                  context,
                  context.t(
                    'performance.mobile.inactive',
                    fallback: 'Não ativos',
                  ),
                  _SituacaoParticipanteMobile.inativos,
                  _totalInativos,
                ),
                const SizedBox(width: 8),
                _situationChip(
                  context,
                  context.t('performance.mobile.both', fallback: 'Ambos'),
                  _SituacaoParticipanteMobile.todos,
                  _participantes.length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colors.mutedText,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  context.t(
                    'performance.mobile.goalsReachedDesc',
                    fallback: 'No período selecionado',
                  ),
                  style: TextStyle(color: colors.mutedText, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodChip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return ChoiceChip(
      selected: selected,
      showCheckmark: selected,
      avatar: selected
          ? null
          : const Icon(Icons.calendar_today_outlined, size: 15),
      label: Text(label),
      selectedColor: colors.softAccentSurface,
      backgroundColor: colors.softSurface,
      checkmarkColor: colors.accent,
      side: BorderSide(color: selected ? colors.accent : colors.border),
      labelStyle: TextStyle(
        color: selected ? colors.accent : colors.titleText,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _situationChip(
    BuildContext context,
    String label,
    _SituacaoParticipanteMobile value,
    int count,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool selected = _situacao == value;
    return ChoiceChip(
      selected: selected,
      label: Text('$label ($count)'),
      showCheckmark: false,
      selectedColor: colors.accent,
      backgroundColor: colors.softSurface,
      side: BorderSide(color: selected ? colors.accent : colors.border),
      labelStyle: TextStyle(
        color: selected ? colors.onAccent : colors.titleText,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      onSelected: (_) async {
        bool precisaRecarregarResumo = false;
        setState(() {
          _situacao = value;
          if (_idParticipante != null &&
              !_participantesVisiveis.any(
                (item) => item.idUnicoPessoal == _idParticipante,
              )) {
            _idParticipante = null;
            precisaRecarregarResumo = true;
          }
        });
        if (precisaRecarregarResumo) {
          await _load();
        }
      },
    );
  }

  Widget _buildKpis(BuildContext context) {
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    final String operations = context
        .t(
          'performance.mobile.salesOperations',
          fallback: '{count} operações no período',
        )
        .replaceAll(
          '{count}',
          _formatInteger(_resumo.quantidadeVendas, locale),
        );
    final List<_PerformanceMetricData> metrics = <_PerformanceMetricData>[
      _PerformanceMetricData(
        title: context.t('performance.mobile.score', fallback: 'Score médio'),
        subtitle: context.t(
          'performance.mobile.scoreDesc',
          fallback: 'Média ponderada das metas',
        ),
        icon: Icons.speed_rounded,
        numericValue: _resumo.scoreMedio,
        formatter: (value) => locale.formatPercent(value),
      ),
      _PerformanceMetricData(
        title: context.t(
          'performance.mobile.goalsReached',
          fallback: 'Metas batidas',
        ),
        subtitle: context.t(
          'performance.mobile.goalsReachedDesc',
          fallback: 'No período selecionado',
        ),
        icon: Icons.emoji_events_outlined,
        displayValue:
            '${_formatInteger(_resumo.metasBatidas, locale)}/${_formatInteger(_resumo.totalMetas, locale)}',
      ),
      _PerformanceMetricData(
        title: context.t('performance.mobile.sales', fallback: 'Vendas'),
        subtitle: operations,
        icon: Icons.point_of_sale_rounded,
        numericValue: _resumo.valorTotalVendido,
        formatter: locale.formatCurrency,
      ),
      _PerformanceMetricData(
        title: context.t(
          'performance.mobile.serviceCalls',
          fallback: 'Atendimentos',
        ),
        subtitle: context.t(
          'performance.mobile.serviceCallsDesc',
          fallback: 'Assistências técnicas no período',
        ),
        icon: Icons.build_circle_outlined,
        numericValue: _resumo.quantidadeAtendimentos.toDouble(),
        formatter: (value) => _formatInteger(value.round(), locale),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double spacing = 10;
        final double itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _PerformanceMetricCard(data: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildResultados(BuildContext context) {
    final List<DesempenhoColaboradorItemModel> resultados = _resultadosVisiveis;
    return KeyedSubtree(
      key: const ValueKey<String>('performance-results'),
      child: _PerformancePanel(
        title: context.t(
          'performance.mobile.resultsTitle',
          fallback: 'Meta x realizado',
        ),
        subtitle: context.t(
          'performance.mobile.resultsSubtitle',
          fallback: 'Evolução calculada para o período selecionado.',
        ),
        child: resultados.isEmpty
            ? _PerformanceEmptyState(
                icon: Icons.flag_outlined,
                title: context.t(
                  'performance.mobile.noResults',
                  fallback: 'Nenhuma meta ativa para exibir',
                ),
                subtitle: context.t(
                  'performance.mobile.noResultsDesc',
                  fallback: 'Ajuste os filtros ou cadastre uma nova meta.',
                ),
              )
            : Column(
                children: resultados
                    .map((item) => _buildResultTile(context, item))
                    .toList(growable: false),
              ),
      ),
    );
  }

  Widget _buildResultTile(
    BuildContext context,
    DesempenhoColaboradorItemModel item,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final DesempenhoIndicadorOption indicator = indicadorPorCodigo(
      item.indicador,
    );
    final Color statusColor = _statusColor(item.status, colors);
    final double progress = (item.percentualAtingido / 100).clamp(0.0, 1.0);
    final String valueText = context
        .t('performance.mobile.valueOfTarget', fallback: '{value} de {target}')
        .replaceAll('{value}', _formatValue(item.valorRealizado, indicator))
        .replaceAll('{target}', _formatValue(item.valorAlvo, indicator));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  item.nomeColaborador.trim().isEmpty
                      ? context.t(
                          'performance.mobile.participantFallback',
                          fallback: 'Participante',
                        )
                      : item.nomeColaborador,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _PerformanceStatusPill(
                label: _statusLabel(context, item.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _indicatorLabel(context, indicator.codigo),
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: _indicatorLabel(context, indicator.codigo),
            value: context.read<LocaleSettingsProvider>().formatPercent(
              item.percentualAtingido,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 560),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => LinearProgressIndicator(
                  minHeight: 8,
                  value: value,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  valueText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.read<LocaleSettingsProvider>().formatPercent(
                  item.percentualAtingido,
                ),
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

  Widget _buildMetas(BuildContext context) {
    final List<MetaColaboradorModel> metas = _metasVisiveis;
    return KeyedSubtree(
      key: const ValueKey<String>('performance-goals'),
      child: _PerformancePanel(
        title: context.t(
          'performance.mobile.goalsTitle',
          fallback: 'Metas cadastradas',
        ),
        subtitle: context.t(
          'performance.mobile.goalsSubtitle',
          fallback: 'Toque em uma meta para consultar ou editar.',
        ),
        child: metas.isEmpty
            ? _PerformanceEmptyState(
                icon: Icons.playlist_add_check_rounded,
                title: context.t(
                  'performance.mobile.noGoals',
                  fallback: 'Sem metas cadastradas',
                ),
                subtitle: context.t(
                  'performance.mobile.noGoalsDesc',
                  fallback:
                      'Crie metas para acompanhar o desempenho da equipe.',
                ),
              )
            : Column(
                children: metas
                    .map((meta) => _buildGoalTile(context, meta))
                    .toList(growable: false),
              ),
      ),
    );
  }

  Widget _buildGoalTile(BuildContext context, MetaColaboradorModel meta) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      button: true,
      label:
          '${meta.nomeColaborador}, ${_indicatorLabel(context, meta.indicador)}',
      child: Material(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openGoalForm(meta: meta),
          child: Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.softAccentSurface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    color: colors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        meta.nomeColaborador.trim().isEmpty
                            ? context.t(
                                'performance.mobile.participantFallback',
                                fallback: 'Participante',
                              )
                            : meta.nomeColaborador,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_indicatorLabel(context, meta.indicador)} • ${_formatPeriod(context, meta.dataInicio, meta.dataFim)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined, color: colors.mutedText, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectParticipant() async {
    final String allValue = '__ALL__';
    final List<SixMobileSelectionOption<String>>
    options = <SixMobileSelectionOption<String>>[
      SixMobileSelectionOption<String>(
        value: allValue,
        title: _allParticipantsLabel(context),
        subtitle: context.t(
          'performance.mobile.heroSubtitle',
          fallback:
              'Acompanhe metas, vendas, serviços e atendimentos por participante.',
        ),
        icon: Icons.groups_2_outlined,
      ),
      ..._participantesVisiveis.map(
        (item) => SixMobileSelectionOption<String>(
          value: item.idUnicoPessoal,
          title: _participantDisplayName(context, item),
          subtitle: item.email.trim().isEmpty
              ? context.t(
                  'performance.mobile.participantFallback',
                  fallback: 'Participante',
                )
              : item.email,
          icon: Icons.badge_outlined,
        ),
      ),
    ];

    final String? selected = await showSixMobileSelectionSheet<String>(
      context: context,
      title: context.t(
        'performance.mobile.selectParticipant',
        fallback: 'Selecionar participante',
      ),
      options: options,
      selectedValue: _idParticipante ?? allValue,
      searchHint: context.t(
        'performance.mobile.searchParticipant',
        fallback: 'Buscar participante',
      ),
      emptyTitle: context.t(
        'performance.mobile.noParticipant',
        fallback: 'Nenhum participante encontrado',
      ),
      emptyMessage: context.t(
        'performance.mobile.noParticipantMessage',
        fallback: 'Ajuste o filtro ou cadastre colaboradores para continuar.',
      ),
    );

    if (!mounted || selected == null) return;
    setState(() => _idParticipante = selected == allValue ? null : selected);
    await _load();
  }

  Future<void> _openGoalForm({MetaColaboradorModel? meta}) async {
    final List<ColaboradorUsuarioResumo> participantes = _participantesVisiveis;
    if (participantes.isEmpty) {
      _showSnack(
        context.t(
          'performance.mobile.noFilteredParticipant',
          fallback: 'Não há participantes para o filtro selecionado.',
        ),
      );
      return;
    }

    final Map<String, dynamic>? payload =
        await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.48),
          builder: (context) => _GoalFormMobile(
            participantes: participantes,
            inicioPadrao: _inicio,
            fimPadrao: _fim,
            meta: meta,
          ),
        );

    if (payload == null || !mounted) return;
    await _saveGoal(meta, payload);
  }

  Future<void> _saveGoal(
    MetaColaboradorModel? meta,
    Map<String, dynamic> payload,
  ) async {
    setState(() => _saving = true);
    try {
      if (meta == null) {
        await _apiClient.criarMeta(payload);
      } else {
        await _apiClient.editarMeta(meta.id, payload);
      }
      await _load(showLoading: false);
      if (!mounted) return;
      _showSnack(
        meta == null
            ? context.t(
                'performance.mobile.goalSaved',
                fallback: 'Meta cadastrada.',
              )
            : context.t(
                'performance.mobile.goalUpdated',
                fallback: 'Meta atualizada.',
              ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        context.t(
          'performance.mobile.goalSaveError',
          fallback: 'Não foi possível salvar a meta. Tente novamente.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setPeriod(DateTime inicio, DateTime fim) {
    setState(() {
      _inicio = DateTime(inicio.year, inicio.month, inicio.day);
      _fim = DateTime(fim.year, fim.month, fim.day);
    });
    _load();
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  bool _isCurrentMonth() {
    final DateTime now = DateTime.now();
    return _sameDay(_inicio, DateTime(now.year, now.month)) &&
        _sameDay(_fim, now);
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

  String _selectedParticipantName(BuildContext context) {
    if (_idParticipante == null) return _allParticipantsLabel(context);
    final ColaboradorUsuarioResumo participant = _participantes.firstWhere(
      (item) => item.idUnicoPessoal == _idParticipante,
      orElse: () => ColaboradorUsuarioResumo(
        idUnicoPessoal: _idParticipante ?? '',
        nome: '',
        nomeDeGuerra: '',
        celularDeAcesso: '',
        email: '',
        foto: '',
        dataCadastro: null,
      ),
    );
    return _participantDisplayName(context, participant);
  }

  String _allParticipantsLabel(BuildContext context) {
    return switch (_situacao) {
      _SituacaoParticipanteMobile.ativos => context.t(
        'performance.mobile.allActive',
        fallback: 'Todos os ativos',
      ),
      _SituacaoParticipanteMobile.inativos => context.t(
        'performance.mobile.allInactive',
        fallback: 'Todos os não ativos',
      ),
      _SituacaoParticipanteMobile.todos => context.t(
        'performance.mobile.allParticipants',
        fallback: 'Todos os participantes',
      ),
    };
  }

  String _formatValue(double value, DesempenhoIndicadorOption indicator) {
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    if (indicator.valorMonetario) return locale.formatCurrency(value);
    final NumberFormat format = NumberFormat.decimalPattern(
      locale.currentLocale.toLanguageTag(),
    )..maximumFractionDigits = value.truncateToDouble() == value ? 0 : 1;
    return format.format(value);
  }

  String _formatPeriod(BuildContext context, DateTime? inicio, DateTime? fim) {
    if (inicio == null || fim == null) {
      return context.t('performance.mobile.noPeriod', fallback: 'Sem período');
    }
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    return '${locale.formatDate(inicio)} — ${locale.formatDate(fim)}';
  }

  String _formatInteger(int value, LocaleSettingsProvider locale) {
    return NumberFormat.decimalPattern(
      locale.currentLocale.toLanguageTag(),
    ).format(value);
  }

  String _indicatorLabel(BuildContext context, String code) {
    return switch (code) {
      'VENDA_VALOR' => context.t(
        'performance.mobile.indicator.salesValue',
        fallback: 'Valor vendido',
      ),
      'VENDA_QUANTIDADE' => context.t(
        'performance.mobile.indicator.salesQuantity',
        fallback: 'Quantidade de vendas',
      ),
      'SERVICO_VALOR' => context.t(
        'performance.mobile.indicator.servicesValue',
        fallback: 'Valor em serviços',
      ),
      'ATENDIMENTO_QUANTIDADE' => context.t(
        'performance.mobile.indicator.serviceCalls',
        fallback: 'Atendimentos técnicos',
      ),
      'ATENDIMENTO_FINALIZADO' => context.t(
        'performance.mobile.indicator.finishedServiceCalls',
        fallback: 'Atendimentos finalizados',
      ),
      'ATENDIMENTO_VALOR' => context.t(
        'performance.mobile.indicator.serviceCallsValue',
        fallback: 'Valor em atendimentos',
      ),
      _ => indicadorPorCodigo(code).label,
    };
  }

  String _statusLabel(BuildContext context, String status) {
    return switch (status) {
      'ACIMA_DA_META' => context.t(
        'performance.mobile.statusAboveGoal',
        fallback: 'Acima da meta',
      ),
      'EM_PROGRESSO' => context.t(
        'performance.mobile.statusInProgress',
        fallback: 'Em progresso',
      ),
      'EM_RISCO' => context.t(
        'performance.mobile.statusAtRisk',
        fallback: 'Em risco',
      ),
      'CRITICO' => context.t(
        'performance.mobile.statusCritical',
        fallback: 'Crítico',
      ),
      _ => context.t(
        'performance.mobile.statusUnknown',
        fallback: 'Sem status',
      ),
    };
  }

  Color _statusColor(String status, SixMobileColorScheme colors) {
    return switch (status) {
      'ACIMA_DA_META' => _success,
      'EM_PROGRESSO' => colors.accent,
      'EM_RISCO' => _warning,
      'CRITICO' => colors.error,
      _ => colors.mutedText,
    };
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _GoalFormMobile extends StatefulWidget {
  const _GoalFormMobile({
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
  State<_GoalFormMobile> createState() => _GoalFormMobileState();
}

class _GoalFormMobileState extends State<_GoalFormMobile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late ColaboradorUsuarioResumo _participante;
  late String _indicador;
  late String _status;
  late DateTime _inicio;
  late DateTime _fim;
  late TextEditingController _valorController;
  late TextEditingController _pesoController;
  bool _inputsInitialized = false;

  @override
  void initState() {
    super.initState();
    _participante = widget.participantes.firstWhere(
      (item) => item.idUnicoPessoal == widget.meta?.idColaborador,
      orElse: () => widget.participantes.first,
    );
    _indicador = widget.meta?.indicador ?? desempenhoIndicadores.first.codigo;
    _status = widget.meta?.status ?? 'ATIVA';
    _inicio = widget.meta?.dataInicio ?? widget.inicioPadrao;
    _fim = widget.meta?.dataFim ?? widget.fimPadrao;
    _valorController = TextEditingController();
    _pesoController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inputsInitialized) return;
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    _valorController.text = widget.meta == null
        ? ''
        : locale.formatDecimal(widget.meta!.valorAlvo);
    _pesoController.text = widget.meta == null
        ? locale.formatDecimal(1)
        : locale.formatDecimal(widget.meta!.peso);
    _inputsInitialized = true;
  }

  @override
  void dispose() {
    _valorController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final LocaleSettingsProvider locale = context
        .watch<LocaleSettingsProvider>();
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.68,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  MediaQuery.viewInsetsOf(context).bottom + 22,
                ),
                children: <Widget>[
                  Align(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.strongBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.meta == null
                              ? context.t(
                                  'performance.mobile.newGoal',
                                  fallback: 'Nova meta',
                                )
                              : context.t(
                                  'performance.mobile.editGoal',
                                  fallback: 'Editar meta',
                                ),
                          style: TextStyle(
                            color: colors.titleText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SixMobileSelectionField(
                    label: context.t(
                      'performance.mobile.participant',
                      fallback: 'Participante',
                    ),
                    value: _participantDisplayName(context, _participante),
                    icon: Icons.badge_outlined,
                    onTap: _selectParticipant,
                  ),
                  const SizedBox(height: 12),
                  SixMobileSelectionField(
                    label: context.t(
                      'performance.mobile.indicator',
                      fallback: 'Indicador',
                    ),
                    value: _indicatorLabel(context, _indicador),
                    icon: Icons.insights_outlined,
                    onTap: _selectIndicator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      context,
                      label: context.t(
                        'performance.mobile.targetValue',
                        fallback: 'Valor alvo',
                      ),
                      icon: Icons.track_changes_rounded,
                    ),
                    validator: _validatePositiveNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pesoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      context,
                      label: context.t(
                        'performance.mobile.weight',
                        fallback: 'Peso',
                      ),
                      icon: Icons.balance_outlined,
                    ),
                    validator: _validatePositiveNumber,
                  ),
                  const SizedBox(height: 12),
                  _PerformanceDateField(
                    label: context.t(
                      'performance.mobile.startDate',
                      fallback: 'Data inicial',
                    ),
                    value: locale.formatDate(_inicio),
                    onTap: () => _selectDate(
                      title: context.t(
                        'performance.mobile.startDate',
                        fallback: 'Data inicial',
                      ),
                      current: _inicio,
                      onSelected: (date) => setState(() => _inicio = date),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PerformanceDateField(
                    label: context.t(
                      'performance.mobile.endDate',
                      fallback: 'Data final',
                    ),
                    value: locale.formatDate(_fim),
                    onTap: () => _selectDate(
                      title: context.t(
                        'performance.mobile.endDate',
                        fallback: 'Data final',
                      ),
                      current: _fim,
                      onSelected: (date) => setState(() => _fim = date),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.t(
                      'performance.mobile.status',
                      fallback: 'Situação da meta',
                    ),
                    style: TextStyle(
                      color: colors.titleText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <String>['ATIVA', 'PAUSADA', 'ENCERRADA']
                        .map(
                          (status) => ChoiceChip(
                            selected: _status == status,
                            showCheckmark: false,
                            label: Text(_goalStatusLabel(context, status)),
                            selectedColor: colors.accent,
                            backgroundColor: colors.softSurface,
                            side: BorderSide(
                              color: _status == status
                                  ? colors.accent
                                  : colors.border,
                            ),
                            labelStyle: TextStyle(
                              color: _status == status
                                  ? colors.onAccent
                                  : colors.titleText,
                              fontWeight: FontWeight.w800,
                            ),
                            onSelected: (_) => setState(() => _status = status),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      widget.meta == null
                          ? context.t(
                              'performance.mobile.createGoal',
                              fallback: 'Cadastrar meta',
                            )
                          : context.t(
                              'performance.mobile.saveGoal',
                              fallback: 'Salvar meta',
                            ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final OutlineInputBorder enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.border),
    );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colors.softSurface,
      enabledBorder: enabledBorder,
      border: enabledBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.error),
      ),
    );
  }

  Future<void> _selectParticipant() async {
    final String? selected = await showSixMobileSelectionSheet<String>(
      context: context,
      title: context.t(
        'performance.mobile.selectParticipant',
        fallback: 'Selecionar participante',
      ),
      options: widget.participantes
          .map(
            (item) => SixMobileSelectionOption<String>(
              value: item.idUnicoPessoal,
              title: _participantDisplayName(context, item),
              subtitle: item.email.trim().isEmpty ? null : item.email,
              icon: Icons.badge_outlined,
            ),
          )
          .toList(growable: false),
      selectedValue: _participante.idUnicoPessoal,
      searchHint: context.t(
        'performance.mobile.searchParticipant',
        fallback: 'Buscar participante',
      ),
      emptyTitle: context.t(
        'performance.mobile.noParticipant',
        fallback: 'Nenhum participante encontrado',
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _participante = widget.participantes.firstWhere(
        (item) => item.idUnicoPessoal == selected,
        orElse: () => _participante,
      );
    });
  }

  Future<void> _selectIndicator() async {
    final String? selected = await showSixMobileSelectionSheet<String>(
      context: context,
      title: context.t(
        'performance.mobile.selectIndicator',
        fallback: 'Selecionar indicador',
      ),
      options: desempenhoIndicadores
          .map(
            (item) => SixMobileSelectionOption<String>(
              value: item.codigo,
              title: _indicatorLabel(context, item.codigo),
              icon: item.valorMonetario
                  ? Icons.payments_outlined
                  : Icons.numbers_rounded,
            ),
          )
          .toList(growable: false),
      selectedValue: _indicador,
      emptyTitle: context.t(
        'performance.mobile.indicator',
        fallback: 'Indicador',
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _indicador = selected);
  }

  Future<void> _selectDate({
    required String title,
    required DateTime current,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final DateTime? selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (context) => DateSelectorMobileBottomSheet(
        title: title,
        initialDate: current,
        firstDate: DateTime(2000),
        lastDate: DateTime(DateTime.now().year + 10, 12, 31),
        applyButtonLabel: context.t(
          'performance.mobile.applyDate',
          fallback: 'Aplicar data',
        ),
      ),
    );
    if (!mounted || selected == null) return;
    onSelected(DateTime(selected.year, selected.month, selected.day));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fim.isBefore(_inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'performance.mobile.invalidDateRange',
              fallback: 'A data final não pode ser anterior à data inicial.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final DesempenhoIndicadorOption indicator = indicadorPorCodigo(_indicador);
    Navigator.of(context).pop(<String, dynamic>{
      'idColaborador': _participante.idUnicoPessoal,
      'nomeColaborador': _participantDisplayName(context, _participante),
      'tipoMeta': indicator.tipoMeta,
      'indicador': indicator.codigo,
      'valorAlvo': _parseNumber(_valorController.text),
      'peso': _parseNumber(_pesoController.text),
      'dataInicio': _formatApiDate(_inicio),
      'dataFim': _formatApiDate(_fim),
      'status': _status,
    });
  }

  String? _validatePositiveNumber(String? value) {
    if (_parseNumber(value ?? '') <= 0) {
      return context.t(
        'performance.mobile.invalidPositiveNumber',
        fallback: 'Informe um valor maior que zero',
      );
    }
    return null;
  }

  double _parseNumber(String value) {
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    String normalized = value.trim().replaceAll(' ', '');
    final String thousand = locale.thousandSeparator;
    final String decimal = locale.decimalSeparator;
    if (thousand.isNotEmpty && thousand != decimal) {
      normalized = normalized.replaceAll(thousand, '');
    }
    if (decimal.isNotEmpty && decimal != '.') {
      normalized = normalized.replaceAll(decimal, '.');
    }
    return double.tryParse(normalized) ?? 0;
  }

  String _formatApiDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _indicatorLabel(BuildContext context, String code) {
    return switch (code) {
      'VENDA_VALOR' => context.t(
        'performance.mobile.indicator.salesValue',
        fallback: 'Valor vendido',
      ),
      'VENDA_QUANTIDADE' => context.t(
        'performance.mobile.indicator.salesQuantity',
        fallback: 'Quantidade de vendas',
      ),
      'SERVICO_VALOR' => context.t(
        'performance.mobile.indicator.servicesValue',
        fallback: 'Valor em serviços',
      ),
      'ATENDIMENTO_QUANTIDADE' => context.t(
        'performance.mobile.indicator.serviceCalls',
        fallback: 'Atendimentos técnicos',
      ),
      'ATENDIMENTO_FINALIZADO' => context.t(
        'performance.mobile.indicator.finishedServiceCalls',
        fallback: 'Atendimentos finalizados',
      ),
      'ATENDIMENTO_VALOR' => context.t(
        'performance.mobile.indicator.serviceCallsValue',
        fallback: 'Valor em atendimentos',
      ),
      _ => indicadorPorCodigo(code).label,
    };
  }

  String _goalStatusLabel(BuildContext context, String status) {
    return switch (status) {
      'PAUSADA' => context.t(
        'performance.mobile.goalPaused',
        fallback: 'Pausada',
      ),
      'ENCERRADA' => context.t(
        'performance.mobile.goalClosed',
        fallback: 'Encerrada',
      ),
      _ => context.t('performance.mobile.goalActive', fallback: 'Ativa'),
    };
  }
}

class _PerformanceDateField extends StatelessWidget {
  const _PerformanceDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      button: true,
      label: '$label. $value',
      child: Material(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.calendar_month_outlined, color: colors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: TextStyle(
                          color: colors.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformanceSectionTabs extends StatelessWidget {
  const _PerformanceSectionTabs({
    required this.selectedIndex,
    required this.resultsLabel,
    required this.goalsLabel,
    required this.onChanged,
  });

  final int selectedIndex;
  final String resultsLabel;
  final String goalsLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          _tab(context, index: 0, label: resultsLabel, icon: Icons.insights),
          _tab(context, index: 1, label: goalsLabel, icon: Icons.flag_outlined),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
  }) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool selected = selectedIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? colors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected ? colors.strongBorder : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? colors.accent : colors.mutedText,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? colors.titleText : colors.mutedText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformanceMetricData {
  const _PerformanceMetricData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.numericValue,
    this.formatter,
    this.displayValue,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double? numericValue;
  final String Function(double value)? formatter;
  final String? displayValue;
}

class _PerformanceMetricCard extends StatelessWidget {
  const _PerformanceMetricCard({required this.data});

  final _PerformanceMetricData data;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.softAccentSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: colors.accent, size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          if (data.numericValue != null && data.formatter != null)
            TweenAnimationBuilder<double>(
              key: ValueKey<String>('${data.title}-${data.numericValue}'),
              tween: Tween<double>(begin: 0, end: data.numericValue),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 620),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Text(
                data.formatter!(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.titleText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            Text(
              data.displayValue ?? '--',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 10.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel({required this.child, this.title, this.subtitle});

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title!,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: colors.mutedText, height: 1.3),
              ),
            ],
            const SizedBox(height: 13),
          ],
          child,
        ],
      ),
    );
  }
}

class _PerformanceStatusPill extends StatelessWidget {
  const _PerformanceStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PerformanceEmptyState extends StatelessWidget {
  const _PerformanceEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: colors.mutedText, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.mutedText, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _PerformanceLoadingBody extends StatelessWidget {
  const _PerformanceLoadingBody({
    required this.scrollController,
    required this.topInset,
  });

  final ScrollController scrollController;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.t(
        'performance.mobile.loading',
        fallback: 'Carregando desempenho da equipe',
      ),
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
        children: <Widget>[
          _SkeletonBlock(height: 158, color: colors.surface),
          const SizedBox(height: 14),
          _SkeletonBlock(height: 214, color: colors.surface),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 10;
              final double width = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List<Widget>.generate(
                  4,
                  (index) => SizedBox(
                    width: width,
                    child: _SkeletonBlock(
                      height: 142,
                      color: colors.surface,
                      icon: index.isEven
                          ? Icons.insights_outlined
                          : Icons.flag_outlined,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _SkeletonBlock(height: 220, color: colors.surface),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, required this.color, this.icon});

  final double height;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.42, end: 0.78),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 780),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) => Container(
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.softAccentSurface.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon ?? Icons.trending_up_rounded,
              color: colors.accent.withValues(alpha: opacity),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

extension _PerformanceParticipantName on ColaboradorUsuarioResumo {
  String get performanceDisplayNameOrEmpty {
    if (nomeDeGuerra.trim().isNotEmpty) return nomeDeGuerra.trim();
    if (nome.trim().isNotEmpty) return nome.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return '';
  }
}

String _participantDisplayName(
  BuildContext context,
  ColaboradorUsuarioResumo participant,
) {
  final String displayName = participant.performanceDisplayNameOrEmpty;
  if (displayName.isNotEmpty) return displayName;
  return context.t(
    'performance.mobile.participantFallback',
    fallback: 'Participante',
  );
}
