import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/consulta_vendas_models.dart';
import '../../data/services/vendas/consulta_vendas_api_client.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_selection_sheet.dart';
import '../components/mobile_motion.dart';
import '../components/six_backend_loading.dart';

class ConsultaVendasMobileScreen extends StatefulWidget {
  const ConsultaVendasMobileScreen({super.key, this.apiClient});

  final ConsultaVendasApiClient? apiClient;

  @override
  State<ConsultaVendasMobileScreen> createState() =>
      _ConsultaVendasMobileScreenState();
}

class _ConsultaVendasMobileScreenState
    extends State<ConsultaVendasMobileScreen> {
  static const String _periodoHoje = 'HOJE';
  static const String _periodoUltimos7Dias = 'ULTIMOS_7_DIAS';
  static const String _periodoUltimos30Dias = 'ULTIMOS_30_DIAS';
  static const String _periodoEsteMes = 'ESTE_MES';
  static const String _periodoMesPassado = 'MES_PASSADO';
  static const String _periodoPersonalizado = 'PERSONALIZADO';
  static const List<String> _periodos = <String>[
    _periodoHoje,
    _periodoUltimos7Dias,
    _periodoUltimos30Dias,
    _periodoEsteMes,
    _periodoMesPassado,
    _periodoPersonalizado,
  ];

  static const List<String> _statusFinanceiros = <String>[
    'QUITADA',
    'PARCIAL',
    'EM_ABERTO',
    'CANCELADA',
  ];

  static const List<String> _statusDevolucao = <String>[
    'SEM_DEVOLUCAO',
    'PARCIAL',
    'TOTAL',
  ];

  static const List<String> _ordenacoes = <String>[
    'MAIS_RECENTES',
    'MAIS_ANTIGAS',
    'MAIOR_VALOR',
    'MENOR_VALOR',
  ];

  late final ConsultaVendasApiClient _api;
  final TextEditingController _buscaController = TextEditingController();

  ConsultaVendasResponse? _resultado;
  bool _carregando = false;
  String? _erro;

  late DateTime _dataInicial;
  late DateTime _dataFinal;
  late DateTime _dataInicioPersonalizada;
  late DateTime _dataFimPersonalizada;
  String _periodoSelecionado = _periodoHoje;
  String? _statusFinanceiroSelecionado;
  String? _statusDevolucaoSelecionado;
  String _ordenacaoSelecionada = 'MAIS_RECENTES';
  String _valorMinimoTexto = '';
  String _valorMaximoTexto = '';
  final int _tamanhoPagina = 25;

  SixMobileColorScheme get _colors => context.sixMobileColors;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpConsultaVendasApiClient();
    final DateTime hoje = _hojeNormalizado();
    _dataFinal = hoje;
    _dataInicial = hoje;
    _dataInicioPersonalizada = _dataInicial;
    _dataFimPersonalizada = _dataFinal;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consultar();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _txt(String key, String pt, String en, String es) {
    final String language = Localizations.localeOf(context).languageCode;
    final String fallback = switch (language) {
      'en' => en,
      'es' => es,
      _ => pt,
    };
    return context.t(key, fallback: fallback);
  }

  Future<void> _consultar({int? pagina, bool mostrarFeedback = false}) async {
    if (_carregando) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final ConsultaVendasResponse resultado = await _api.consultar(
        _filtro(pagina: pagina ?? _resultado?.paginaAtual ?? 0),
      );
      if (!mounted) return;
      setState(() => _resultado = resultado);
      if (mostrarFeedback) {
        _snack(
          _txt(
            'sales.query.mobile.updated',
            'Consulta atualizada.',
            'Sales refreshed.',
            'Consulta actualizada.',
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  ConsultaVendasFiltro _filtro({required int pagina}) {
    return ConsultaVendasFiltro(
      dataInicial: _dataInicial,
      dataFinal: _dataFinal,
      busca: _buscaController.text,
      statusFinanceiro: _statusFinanceiroSelecionado,
      statusDevolucao: _statusDevolucaoSelecionado,
      valorMinimo: _parseNumero(_valorMinimoTexto),
      valorMaximo: _parseNumero(_valorMaximoTexto),
      ordenacao: _ordenacaoSelecionada,
      pagina: pagina,
      tamanho: _tamanhoPagina,
    );
  }

  bool get _temFiltrosAtivos =>
      _buscaController.text.trim().isNotEmpty ||
      _periodoSelecionado != _periodoHoje ||
      _statusFinanceiroSelecionado != null ||
      _statusDevolucaoSelecionado != null ||
      _valorMinimoTexto.trim().isNotEmpty ||
      _valorMaximoTexto.trim().isNotEmpty ||
      _ordenacaoSelecionada != 'MAIS_RECENTES';

  DateTime _hojeNormalizado() {
    final DateTime agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  DateTime _normalizarData(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTimeRange _resolverPeriodoSelecionado() {
    final DateTime hoje = _hojeNormalizado();
    switch (_periodoSelecionado) {
      case _periodoHoje:
        return DateTimeRange(start: hoje, end: hoje);
      case _periodoUltimos7Dias:
        return DateTimeRange(
          start: hoje.subtract(const Duration(days: 6)),
          end: hoje,
        );
      case _periodoEsteMes:
        return DateTimeRange(
          start: DateTime(hoje.year, hoje.month, 1),
          end: hoje,
        );
      case _periodoMesPassado:
        final DateTime inicioMesAtual = DateTime(hoje.year, hoje.month, 1);
        final DateTime ultimoDiaMesPassado = inicioMesAtual.subtract(
          const Duration(days: 1),
        );
        return DateTimeRange(
          start: DateTime(
            ultimoDiaMesPassado.year,
            ultimoDiaMesPassado.month,
            1,
          ),
          end: ultimoDiaMesPassado,
        );
      case _periodoPersonalizado:
        final DateTime inicio = _normalizarData(_dataInicioPersonalizada);
        final DateTime fim = _normalizarData(_dataFimPersonalizada);
        return DateTimeRange(
          start: inicio.isAfter(fim) ? fim : inicio,
          end: fim.isBefore(inicio) ? inicio : fim,
        );
      case _periodoUltimos30Dias:
      default:
        return DateTimeRange(start: hoje, end: hoje);
    }
  }

  void _sincronizarPeriodoComDatas() {
    final DateTimeRange periodo = _resolverPeriodoSelecionado();
    _dataInicial = periodo.start;
    _dataFinal = periodo.end;
  }

  Future<void> _abrirFiltros() async {
    final LocaleSettingsProvider regionalizacao =
        context.read<LocaleSettingsProvider>();
    final _ConsultaVendasFilterDraft?
    draft = await showModalBottomSheet<_ConsultaVendasFilterDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (BuildContext context) {
        return _ConsultaVendasFilterSheet(
          initialDraft: _ConsultaVendasFilterDraft(
            periodo: _periodoSelecionado,
            dataInicio: _dataInicioPersonalizada,
            dataFim: _dataFimPersonalizada,
            statusFinanceiro: _statusFinanceiroSelecionado,
            statusDevolucao: _statusDevolucaoSelecionado,
            ordenacao: _ordenacaoSelecionada,
            valorMinimo: _valorMinimoTexto,
            valorMaximo: _valorMaximoTexto,
          ),
          formatDate: regionalizacao.formatDate,
          periodLabelBuilder: (String value) => _periodoLabel(context, value),
          financialStatusLabelBuilder:
              (String value) => _statusFinanceiroLabel(context, value),
          returnStatusLabelBuilder:
              (String value) => _statusDevolucaoLabel(context, value),
          orderLabelBuilder: (String value) => _ordenacaoLabel(context, value),
          showDateSheet: ({
            required DateTime initialDate,
            required DateTime minimumDate,
            required String title,
          }) {
            return _showDatePickerSheet(
              initialDate: initialDate,
              minimumDate: minimumDate,
              title: title,
            );
          },
        );
      },
    );

    if (draft == null || !mounted) return;

    setState(() {
      _periodoSelecionado = draft.periodo;
      _dataInicioPersonalizada = draft.dataInicio;
      _dataFimPersonalizada =
          draft.dataFim.isBefore(draft.dataInicio)
              ? draft.dataInicio
              : draft.dataFim;
      _statusFinanceiroSelecionado = draft.statusFinanceiro;
      _statusDevolucaoSelecionado = draft.statusDevolucao;
      _ordenacaoSelecionada = draft.ordenacao;
      _valorMinimoTexto = draft.valorMinimo;
      _valorMaximoTexto = draft.valorMaximo;
      _sincronizarPeriodoComDatas();
    });

    await _consultar(pagina: 0);
  }

  Future<DateTime?> _showDatePickerSheet({
    required DateTime initialDate,
    required DateTime minimumDate,
    required String title,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (BuildContext context) {
        return _ConsultaVendasDateSheet(
          title: title,
          initialDate: initialDate,
          minimumDate: minimumDate,
          maximumDate: DateTime.now().add(const Duration(days: 365)),
        );
      },
    );
  }

  Future<void> _limparFiltros() async {
    final DateTime hoje = _hojeNormalizado();
    setState(() {
      _periodoSelecionado = _periodoHoje;
      _dataFinal = hoje;
      _dataInicial = hoje;
      _dataInicioPersonalizada = _dataInicial;
      _dataFimPersonalizada = _dataFinal;
      _statusFinanceiroSelecionado = null;
      _statusDevolucaoSelecionado = null;
      _ordenacaoSelecionada = 'MAIS_RECENTES';
      _valorMinimoTexto = '';
      _valorMaximoTexto = '';
      _buscaController.clear();
    });
    await _consultar(pagina: 0);
  }

  Future<void> _abrirDetalhe(VendaConsultaResumo venda) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (BuildContext context) {
        return _VendaDetalheMobileSheet(
          api: _api,
          identificador: venda.idOperacao,
          title: venda.identificadorPreferencial,
        );
      },
    );
  }

  void _snack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    final ResumoConsultaVendas resumo =
        _resultado?.resumo ??
        const ResumoConsultaVendas(
          quantidadeVendas: 0,
          valorTotalVendido: 0,
          valorTotalRecebido: 0,
          valorTotalEmAberto: 0,
          valorTotalDevolvido: 0,
        );

    return SixMobilePageShell(
      title: _txt(
        'atendimento.mobile.consultSalesTitle',
        'Consultar vendas',
        'View sales',
        'Consultar ventas',
      ),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      leading: IconButton(
        tooltip: context.t('common.back', fallback: 'Voltar'),
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: _txt(
            'sales.query.mobile.manageFilters',
            'Abrir filtros',
            'Open filters',
            'Abrir filtros',
          ),
          icon: const Icon(Icons.tune_rounded),
          onPressed: _carregando ? null : _abrirFiltros,
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => _consultar(mostrarFeedback: true),
            color: _colors.accent,
            backgroundColor: _colors.surface,
            child: ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
              children: <Widget>[
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 40),
                  child: _ConsultaVendasHeroCard(
                    title: _txt(
                      'sales.query.mobile.title',
                      'Histórico de vendas',
                      'Sales history',
                      'Historial de ventas',
                    ),
                    subtitle: _txt(
                      'sales.query.mobile.subtitle',
                      'Consulte vendas, acompanhe recebimentos e revise devoluções sem sair do fluxo mobile.',
                      'Review sales, track receipts and inspect returns without leaving the mobile workflow.',
                      'Consulte ventas, siga cobros y revise devoluciones sin salir del flujo móvil.',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 90),
                  child: _ConsultaVendasSummaryGrid(
                    resumo: resumo,
                    regionalizacao: regionalizacao,
                    ticketMedio: resumo.ticketMedio,
                  ),
                ),
                const SizedBox(height: 14),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 130),
                  child: _buildSearchAndFilters(),
                ),
                if (_temFiltrosAtivos) ...<Widget>[
                  const SizedBox(height: 10),
                  _buildActiveFilters(regionalizacao),
                ],
                if (_erro != null && _resultado != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _InlineErrorCard(message: _erro!),
                ],
                const SizedBox(height: 16),
                SixStaggeredEntry(
                  delay: const Duration(milliseconds: 170),
                  child: _buildResultsHeader(),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration:
                      MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildResultsBody(regionalizacao),
                ),
                if (_resultado != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _PaginationCard(
                    resultado: _resultado!,
                    carregando: _carregando,
                    onPrevious:
                        _resultado!.paginaAtual > 0
                            ? () =>
                                _consultar(pagina: _resultado!.paginaAtual - 1)
                            : null,
                    onNext:
                        _resultado!.paginaAtual + 1 < _resultado!.totalPaginas
                            ? () =>
                                _consultar(pagina: _resultado!.paginaAtual + 1)
                            : null,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _colors.heroShadow.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.search_rounded, color: _colors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _txt(
                    'sales.query.mobile.searchTitle',
                    'Busca',
                    'Search',
                    'Búsqueda',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _colors.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_temFiltrosAtivos)
                TextButton.icon(
                  onPressed: _carregando ? null : _limparFiltros,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(context.t('common.clear', fallback: 'Limpar')),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buscaController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _consultar(pagina: 0),
            decoration: InputDecoration(
              hintText: _txt(
                'sales.query.search',
                'Venda, cliente, documento ou produto',
                'Sale, customer, document or product',
                'Venta, cliente, documento o producto',
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: _txt(
                  'sales.query.mobile.applySearch',
                  'Aplicar busca',
                  'Apply search',
                  'Aplicar búsqueda',
                ),
                onPressed: _carregando ? null : () => _consultar(pagina: 0),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              filled: true,
              fillColor: _colors.softSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: _colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: _colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: _colors.accent, width: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(LocaleSettingsProvider regionalizacao) {
    final List<Widget> chips = <Widget>[
      _ActiveFilterChip(
        icon: Icons.date_range_rounded,
        label: _periodoResumoLabel(regionalizacao),
      ),
      if (_statusFinanceiroSelecionado != null)
        _ActiveFilterChip(
          icon: Icons.account_balance_wallet_outlined,
          label: _statusFinanceiroLabel(context, _statusFinanceiroSelecionado!),
        ),
      if (_statusDevolucaoSelecionado != null)
        _ActiveFilterChip(
          icon: Icons.assignment_return_outlined,
          label: _statusDevolucaoLabel(context, _statusDevolucaoSelecionado!),
        ),
      if (_valorMinimoTexto.trim().isNotEmpty)
        _ActiveFilterChip(
          icon: Icons.south_rounded,
          label:
              '${_txt('sales.query.minimumValue', 'Mínimo', 'Minimum', 'Mínimo')}: ${_valorMinimoTexto.trim()}',
        ),
      if (_valorMaximoTexto.trim().isNotEmpty)
        _ActiveFilterChip(
          icon: Icons.north_rounded,
          label:
              '${_txt('sales.query.maximumValue', 'Máximo', 'Maximum', 'Máximo')}: ${_valorMaximoTexto.trim()}',
        ),
    ];

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildResultsHeader() {
    final int total = _resultado?.totalElementos ?? 0;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _txt(
                  'sales.query.results',
                  'Vendas encontradas',
                  'Sales found',
                  'Ventas encontradas',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _colors.titleText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _txt(
                  'sales.query.mobile.resultsHint',
                  'Toque em uma venda para ver itens, recebimentos, devoluções e histórico.',
                  'Tap a sale to review items, receipts, returns and history.',
                  'Toque una venta para ver artículos, cobros, devoluciones e historial.',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _colors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _colors.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _colors.strongBorder),
          ),
          child: Text(
            total.toString(),
            style: TextStyle(
              color: _colors.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsBody(LocaleSettingsProvider regionalizacao) {
    final ConsultaVendasResponse? resultado = _resultado;

    if (_carregando && resultado == null) {
      return const _InitialLoadingState(key: ValueKey<String>('loading-state'));
    }

    if (_erro != null && resultado == null) {
      return _ErrorStateCard(
        key: const ValueKey<String>('error-state'),
        message: _erro!,
        onRetry: () => _consultar(pagina: 0),
      );
    }

    if (resultado == null || resultado.vendas.isEmpty) {
      return _EmptyStateCard(
        key: const ValueKey<String>('empty-state'),
        title: _txt(
          'sales.query.mobile.emptyTitle',
          'Nenhuma venda encontrada',
          'No sales found',
          'No se encontraron ventas',
        ),
        subtitle: _txt(
          'sales.query.mobile.emptySubtitle',
          'Ajuste o período ou remova alguns filtros para ampliar a consulta.',
          'Adjust the period or remove some filters to broaden the search.',
          'Ajuste el período o quite algunos filtros para ampliar la consulta.',
        ),
      );
    }

    return Column(
      key: const ValueKey<String>('success-state'),
      children: <Widget>[
        if (_carregando)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                color: _colors.accent,
                backgroundColor: _colors.softSurface,
              ),
            ),
          ),
        for (final MapEntry<int, VendaConsultaResumo> entry
            in resultado.vendas.asMap().entries) ...<Widget>[
          SixStaggeredEntry(
            delay: Duration(
              milliseconds: 30 + ((entry.key * 26).clamp(0, 220)),
            ),
            child: _VendaResumoMobileCard(
              venda: entry.value,
              regionalizacao: regionalizacao,
              onTap: () => _abrirDetalhe(entry.value),
            ),
          ),
          if (entry.key + 1 < resultado.vendas.length)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _periodoResumoLabel(LocaleSettingsProvider regionalizacao) {
    if (_periodoSelecionado == _periodoPersonalizado) {
      return '${regionalizacao.formatDate(_dataInicioPersonalizada)} ${context.t('common.rangeTo', fallback: 'a')} ${regionalizacao.formatDate(_dataFimPersonalizada)}';
    }
    return _periodoLabel(context, _periodoSelecionado);
  }

  String _periodoLabel(BuildContext context, String value) {
    switch (value) {
      case _periodoHoje:
        return _txt('sales.query.period.today', 'Hoje', 'Today', 'Hoy');
      case _periodoUltimos7Dias:
        return _txt(
          'sales.query.period.last7Days',
          'Últimos 7 dias',
          'Last 7 days',
          'Últimos 7 días',
        );
      case _periodoEsteMes:
        return _txt(
          'sales.query.period.thisMonth',
          'Este mês',
          'This month',
          'Este mes',
        );
      case _periodoMesPassado:
        return _txt(
          'sales.query.period.lastMonth',
          'Mês passado',
          'Last month',
          'Mes pasado',
        );
      case _periodoPersonalizado:
        return _txt(
          'sales.query.period.custom',
          'Intervalo personalizado',
          'Custom range',
          'Intervalo personalizado',
        );
      case _periodoUltimos30Dias:
      default:
        return _txt(
          'sales.query.period.last30Days',
          'Últimos 30 dias',
          'Last 30 days',
          'Últimos 30 días',
        );
    }
  }

  String _statusFinanceiroLabel(BuildContext context, String value) {
    switch (value) {
      case 'QUITADA':
        return _txt('sales.query.financial.paid', 'Quitada', 'Paid', 'Pagada');
      case 'PARCIAL':
        return _txt(
          'sales.query.financial.partial',
          'Parcial',
          'Partial',
          'Parcial',
        );
      case 'EM_ABERTO':
        return _txt(
          'sales.query.financial.open',
          'Em aberto',
          'Open',
          'Abierta',
        );
      case 'CANCELADA':
        return _txt(
          'sales.query.financial.cancelled',
          'Cancelada',
          'Cancelled',
          'Cancelada',
        );
      default:
        return _humanizeCode(value);
    }
  }

  String _statusDevolucaoLabel(BuildContext context, String value) {
    switch (value) {
      case 'SEM_DEVOLUCAO':
        return _txt(
          'sales.query.return.none',
          'Sem devolução',
          'No return',
          'Sin devolución',
        );
      case 'PARCIAL':
        return _txt(
          'sales.query.return.partial',
          'Parcial',
          'Partial',
          'Parcial',
        );
      case 'TOTAL':
        return _txt('sales.query.return.total', 'Total', 'Full', 'Total');
      default:
        return _humanizeCode(value);
    }
  }

  String _ordenacaoLabel(BuildContext context, String value) {
    switch (value) {
      case 'MAIS_ANTIGAS':
        return _txt(
          'sales.query.sort.oldest',
          'Mais antigas',
          'Oldest first',
          'Más antiguas',
        );
      case 'MAIOR_VALOR':
        return _txt(
          'sales.query.sort.highestValue',
          'Maior valor',
          'Highest value',
          'Mayor valor',
        );
      case 'MENOR_VALOR':
        return _txt(
          'sales.query.sort.lowestValue',
          'Menor valor',
          'Lowest value',
          'Menor valor',
        );
      case 'MAIS_RECENTES':
      default:
        return _txt(
          'sales.query.sort.mostRecent',
          'Mais recentes',
          'Most recent',
          'Más recientes',
        );
    }
  }
}

class _ConsultaVendasHeroCard extends StatelessWidget {
  const _ConsultaVendasHeroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, 0.72) ??
                colors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.heroShadow,
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultaVendasSummaryGrid extends StatelessWidget {
  const _ConsultaVendasSummaryGrid({
    required this.resumo,
    required this.regionalizacao,
    required this.ticketMedio,
  });

  final ResumoConsultaVendas resumo;
  final LocaleSettingsProvider regionalizacao;
  final double ticketMedio;

  @override
  Widget build(BuildContext context) {
    final List<_MetricConfig> metrics = <_MetricConfig>[
      _MetricConfig(
        label: _triple(
          context,
          'sales.query.kpi.count',
          'Vendas',
          'Sales',
          'Ventas',
        ),
        valueBuilder: () => resumo.quantidadeVendas.toString(),
        accent: context.sixMobileColors.accent,
        icon: Icons.receipt_long_outlined,
      ),
      _MetricConfig(
        label: _triple(
          context,
          'sales.query.kpi.sold',
          'Valor vendido',
          'Sold amount',
          'Valor vendido',
        ),
        valueBuilder:
            () => regionalizacao.formatCurrency(resumo.valorTotalVendido),
        numericValue: resumo.valorTotalVendido,
        formatter: regionalizacao.formatCurrency,
        accent: const Color(0xFF0F9D58),
        icon: Icons.trending_up_rounded,
      ),
      _MetricConfig(
        label: _triple(
          context,
          'sales.query.kpi.received',
          'Valor recebido',
          'Received amount',
          'Valor recibido',
        ),
        valueBuilder:
            () => regionalizacao.formatCurrency(resumo.valorTotalRecebido),
        numericValue: resumo.valorTotalRecebido,
        formatter: regionalizacao.formatCurrency,
        accent: const Color(0xFF16A34A),
        icon: Icons.payments_outlined,
      ),
      _MetricConfig(
        label: _triple(
          context,
          'sales.query.kpi.open',
          'Saldo em aberto',
          'Open balance',
          'Saldo abierto',
        ),
        valueBuilder:
            () => regionalizacao.formatCurrency(resumo.valorTotalEmAberto),
        numericValue: resumo.valorTotalEmAberto,
        formatter: regionalizacao.formatCurrency,
        accent: const Color(0xFFF59E0B),
        icon: Icons.schedule_outlined,
      ),
      _MetricConfig(
        label: _triple(
          context,
          'sales.query.kpi.returned',
          'Valor devolvido',
          'Returned amount',
          'Valor devuelto',
        ),
        valueBuilder:
            () => regionalizacao.formatCurrency(resumo.valorTotalDevolvido),
        numericValue: resumo.valorTotalDevolvido,
        formatter: regionalizacao.formatCurrency,
        accent: const Color(0xFFEF4444),
        icon: Icons.assignment_return_outlined,
      ),
      _MetricConfig(
        label: _triple(
          context,
          'sales.query.kpi.average',
          'Ticket médio',
          'Average ticket',
          'Ticket promedio',
        ),
        valueBuilder: () => regionalizacao.formatCurrency(ticketMedio),
        numericValue: ticketMedio,
        formatter: regionalizacao.formatCurrency,
        accent: SixMobilePalette.secondary,
        icon: Icons.analytics_outlined,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics
          .map((config) => _SummaryMetricCard(config: config))
          .toList(growable: false),
    );
  }
}

class _MetricConfig {
  const _MetricConfig({
    required this.label,
    required this.valueBuilder,
    required this.accent,
    required this.icon,
    this.numericValue,
    this.formatter,
  });

  final String label;
  final String Function() valueBuilder;
  final double? numericValue;
  final String Function(num value)? formatter;
  final Color accent;
  final IconData icon;
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({required this.config});

  final _MetricConfig config;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final double width = (MediaQuery.sizeOf(context).width - 42) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: config.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, size: 20, color: config.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  config.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                config.numericValue != null && config.formatter != null
                    ? _AnimatedMetricValue(
                      value: config.numericValue!,
                      formatter: config.formatter!,
                    )
                    : Text(
                      config.valueBuilder(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.titleText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMetricValue extends StatelessWidget {
  const _AnimatedMetricValue({required this.value, required this.formatter});

  final double value;
  final String Function(num value) formatter;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return Text(
          formatter(animatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.titleText,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        );
      },
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.softAccentSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: colors.accent),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendaResumoMobileCard extends StatelessWidget {
  const _VendaResumoMobileCard({
    required this.venda,
    required this.regionalizacao,
    required this.onTap,
  });

  final VendaConsultaResumo venda;
  final LocaleSettingsProvider regionalizacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.heroShadow.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          venda.identificadorPreferencial,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.titleText,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _fallback(
                            venda.nomeCliente,
                            _triple(
                              context,
                              'sales.query.mobile.unknownCustomer',
                              'Cliente não identificado',
                              'Unidentified customer',
                              'Cliente no identificado',
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        regionalizacao.formatCurrency(venda.valorTotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.titleText,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDateTime(regionalizacao, venda.dataOperacao),
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _CardMetaChip(
                    icon: Icons.person_outline_rounded,
                    label: _fallback(
                      venda.nomeColaborador,
                      _triple(
                        context,
                        'sales.query.mobile.system',
                        'Sistema',
                        'System',
                        'Sistema',
                      ),
                    ),
                  ),
                  _CardMetaChip(
                    icon: Icons.shopping_bag_outlined,
                    label:
                        '${venda.quantidadeLinhas} ${_triple(context, 'sales.query.mobile.lines', 'linhas', 'lines', 'líneas')} · ${_formatQuantity(venda.quantidadeItens)} ${_triple(context, 'sales.query.mobile.items', 'itens', 'items', 'artículos')}',
                  ),
                  _StatusPill(
                    label: _financialStatusLabel(
                      context,
                      venda.statusFinanceiro,
                    ),
                    color: _financialStatusColor(venda.statusFinanceiro),
                  ),
                  _StatusPill(
                    label: _returnStatusLabel(context, venda.statusDevolucao),
                    color: _returnStatusColor(venda.statusDevolucao),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ValueInfoBlock(
                      label: _triple(
                        context,
                        'sales.query.mobile.received',
                        'Recebido',
                        'Received',
                        'Recibido',
                      ),
                      value: regionalizacao.formatCurrency(venda.valorRecebido),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ValueInfoBlock(
                      label: _triple(
                        context,
                        'sales.query.mobile.openAmount',
                        'Em aberto',
                        'Open',
                        'Abierto',
                      ),
                      value: regionalizacao.formatCurrency(venda.valorEmAberto),
                      highlight: venda.valorEmAberto > 0.0001,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chevron_right_rounded, color: colors.mutedText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMetaChip extends StatelessWidget {
  const _CardMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: colors.mutedText),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ValueInfoBlock extends StatelessWidget {
  const _ValueInfoBlock({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? colors.softAccentSurface : colors.softSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? colors.strongBorder : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.titleText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationCard extends StatelessWidget {
  const _PaginationCard({
    required this.resultado,
    required this.carregando,
    required this.onPrevious,
    required this.onNext,
  });

  final ConsultaVendasResponse resultado;
  final bool carregando;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final int totalPaginas =
        resultado.totalPaginas == 0 ? 1 : resultado.totalPaginas;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _triple(
                    context,
                    'sales.query.mobile.page',
                    'Página ${resultado.paginaAtual + 1} de $totalPaginas',
                    'Page ${resultado.paginaAtual + 1} of $totalPaginas',
                    'Página ${resultado.paginaAtual + 1} de $totalPaginas',
                  ),
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${resultado.totalElementos} ${_triple(context, 'sales.query.mobile.records', 'registros', 'records', 'registros')}',
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _triple(
              context,
              'sales.query.mobile.previousPage',
              'Página anterior',
              'Previous page',
              'Página anterior',
            ),
            onPressed: carregando ? null : onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: _triple(
              context,
              'sales.query.mobile.nextPage',
              'Próxima página',
              'Next page',
              'Página siguiente',
            ),
            onPressed: carregando ? null : onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _InitialLoadingState extends StatelessWidget {
  const _InitialLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      children: <Widget>[
        Semantics(
          container: true,
          liveRegion: true,
          label: context.t('common.loading', fallback: 'Carregando...'),
          child: SixBackendLoading(
            title: _triple(
              context,
              'sales.query.loadingTitle',
              'Carregando vendas',
              'Loading sales',
              'Cargando ventas',
            ),
            subtitle: _triple(
              context,
              'sales.query.loadingSubtitle',
              'Buscando os dados operacionais desta empresa.',
              'Fetching operational data for this business.',
              'Buscando los datos operativos de este comercio.',
            ),
            leadingIcon: Icons.receipt_long_outlined,
            animation: SixBackendLoadingAnimation.skeletonPulse,
            backgroundColor: colors.surface,
            borderColor: colors.border,
          ),
        ),
        const SizedBox(height: 10),
        for (int index = 0; index < 2; index++) ...<Widget>[
          _LoadingSaleCard(index: index),
          if (index == 0) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LoadingSaleCard extends StatelessWidget {
  const _LoadingSaleCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _skeletonLine(colors, 120 + (index * 20)),
          const SizedBox(height: 8),
          _skeletonLine(colors, 180),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _skeletonPill(colors, 88),
              const SizedBox(width: 8),
              _skeletonPill(colors, 94),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: _skeletonBlock(colors)),
              const SizedBox(width: 10),
              Expanded(child: _skeletonBlock(colors)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine(SixMobileColorScheme colors, double width) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _skeletonPill(SixMobileColorScheme colors, double width) {
    return Container(
      width: width,
      height: 28,
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _skeletonBlock(SixMobileColorScheme colors) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.errorBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 38, color: colors.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.titleText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.softSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: colors.mutedText,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
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

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.errorBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: colors.error),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.titleText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultaVendasFilterDraft {
  const _ConsultaVendasFilterDraft({
    required this.periodo,
    required this.dataInicio,
    required this.dataFim,
    required this.statusFinanceiro,
    required this.statusDevolucao,
    required this.ordenacao,
    required this.valorMinimo,
    required this.valorMaximo,
  });

  final String periodo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? statusFinanceiro;
  final String? statusDevolucao;
  final String ordenacao;
  final String valorMinimo;
  final String valorMaximo;

  _ConsultaVendasFilterDraft copyWith({
    String? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? statusFinanceiro,
    String? statusDevolucao,
    String? ordenacao,
    String? valorMinimo,
    String? valorMaximo,
    bool limparStatusFinanceiro = false,
    bool limparStatusDevolucao = false,
  }) {
    return _ConsultaVendasFilterDraft(
      periodo: periodo ?? this.periodo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      statusFinanceiro:
          limparStatusFinanceiro
              ? null
              : statusFinanceiro ?? this.statusFinanceiro,
      statusDevolucao:
          limparStatusDevolucao
              ? null
              : statusDevolucao ?? this.statusDevolucao,
      ordenacao: ordenacao ?? this.ordenacao,
      valorMinimo: valorMinimo ?? this.valorMinimo,
      valorMaximo: valorMaximo ?? this.valorMaximo,
    );
  }
}

class _ConsultaVendasFilterSheet extends StatefulWidget {
  const _ConsultaVendasFilterSheet({
    required this.initialDraft,
    required this.formatDate,
    required this.periodLabelBuilder,
    required this.financialStatusLabelBuilder,
    required this.returnStatusLabelBuilder,
    required this.orderLabelBuilder,
    required this.showDateSheet,
  });

  final _ConsultaVendasFilterDraft initialDraft;
  final String Function(DateTime value) formatDate;
  final String Function(String value) periodLabelBuilder;
  final String Function(String value) financialStatusLabelBuilder;
  final String Function(String value) returnStatusLabelBuilder;
  final String Function(String value) orderLabelBuilder;
  final Future<DateTime?> Function({
    required DateTime initialDate,
    required DateTime minimumDate,
    required String title,
  })
  showDateSheet;

  @override
  State<_ConsultaVendasFilterSheet> createState() =>
      _ConsultaVendasFilterSheetState();
}

class _ConsultaVendasFilterSheetState
    extends State<_ConsultaVendasFilterSheet> {
  late _ConsultaVendasFilterDraft _draft;
  late final TextEditingController _valorMinimoController;
  late final TextEditingController _valorMaximoController;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _valorMinimoController = TextEditingController(text: _draft.valorMinimo);
    _valorMaximoController = TextEditingController(text: _draft.valorMaximo);
  }

  @override
  void dispose() {
    _valorMinimoController.dispose();
    _valorMaximoController.dispose();
    super.dispose();
  }

  Future<void> _pickPeriodo() async {
    final String? selected = await showSixMobileSelectionSheet<String>(
      context: context,
      title: _triple(
        context,
        'sales.query.period',
        'Período',
        'Period',
        'Período',
      ),
      subtitle: _triple(
        context,
        'sales.query.mobile.periodSubtitle',
        'Defina o recorte principal da consulta.',
        'Choose the main range for the query.',
        'Defina el rango principal de la consulta.',
      ),
      options: _ConsultaVendasMobileScreenState._periodos
          .map(
            (String value) => SixMobileSelectionOption<String>(
              value: value,
              title: widget.periodLabelBuilder(value),
              icon: Icons.date_range_rounded,
            ),
          )
          .toList(growable: false),
      selectedValue: _draft.periodo,
      emptyTitle: context.t('common.noResults', fallback: 'Nenhum resultado'),
    );

    if (selected == null || !mounted) return;
    setState(() => _draft = _draft.copyWith(periodo: selected));
  }

  Future<void> _pickStatusFinanceiro() async {
    final List<SixMobileSelectionOption<String?>> options =
        <SixMobileSelectionOption<String?>>[
          SixMobileSelectionOption<String?>(
            value: null,
            title: context.t('common.all', fallback: 'Todos'),
            icon: Icons.filter_alt_outlined,
          ),
          ..._ConsultaVendasMobileScreenState._statusFinanceiros.map(
            (String value) => SixMobileSelectionOption<String?>(
              value: value,
              title: widget.financialStatusLabelBuilder(value),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
        ];
    final String? selected = await showSixMobileSelectionSheet<String?>(
      context: context,
      title: _triple(
        context,
        'sales.query.financialStatus',
        'Situação financeira',
        'Financial status',
        'Situación financiera',
      ),
      options: options,
      selectedValue: _draft.statusFinanceiro,
      emptyTitle: context.t('common.noResults', fallback: 'Nenhum resultado'),
    );
    if (!mounted) return;
    setState(() {
      _draft = _draft.copyWith(
        statusFinanceiro: selected,
        limparStatusFinanceiro: selected == null,
      );
    });
  }

  Future<void> _pickStatusDevolucao() async {
    final List<SixMobileSelectionOption<String?>> options =
        <SixMobileSelectionOption<String?>>[
          SixMobileSelectionOption<String?>(
            value: null,
            title: context.t('common.all', fallback: 'Todos'),
            icon: Icons.filter_alt_outlined,
          ),
          ..._ConsultaVendasMobileScreenState._statusDevolucao.map(
            (String value) => SixMobileSelectionOption<String?>(
              value: value,
              title: widget.returnStatusLabelBuilder(value),
              icon: Icons.assignment_return_outlined,
            ),
          ),
        ];
    final String? selected = await showSixMobileSelectionSheet<String?>(
      context: context,
      title: _triple(
        context,
        'sales.query.returnStatus',
        'Situação da devolução',
        'Return status',
        'Situación de devolución',
      ),
      options: options,
      selectedValue: _draft.statusDevolucao,
      emptyTitle: context.t('common.noResults', fallback: 'Nenhum resultado'),
    );
    if (!mounted) return;
    setState(() {
      _draft = _draft.copyWith(
        statusDevolucao: selected,
        limparStatusDevolucao: selected == null,
      );
    });
  }

  Future<void> _pickOrdenacao() async {
    final String? selected = await showSixMobileSelectionSheet<String>(
      context: context,
      title: _triple(
        context,
        'sales.query.order',
        'Ordenar por',
        'Sort by',
        'Ordenar por',
      ),
      options: _ConsultaVendasMobileScreenState._ordenacoes
          .map(
            (String value) => SixMobileSelectionOption<String>(
              value: value,
              title: widget.orderLabelBuilder(value),
              icon: Icons.swap_vert_rounded,
            ),
          )
          .toList(growable: false),
      selectedValue: _draft.ordenacao,
      emptyTitle: context.t('common.noResults', fallback: 'Nenhum resultado'),
    );

    if (selected == null || !mounted) return;
    setState(() => _draft = _draft.copyWith(ordenacao: selected));
  }

  Future<void> _pickData({required bool inicio}) async {
    final DateTime initial = inicio ? _draft.dataInicio : _draft.dataFim;
    final DateTime minimum = inicio ? DateTime(2020) : _draft.dataInicio;
    final DateTime? result = await widget.showDateSheet(
      initialDate: initial,
      minimumDate: minimum,
      title:
          inicio
              ? _triple(
                context,
                'sales.query.startDate',
                'Data inicial',
                'Start date',
                'Fecha inicial',
              )
              : _triple(
                context,
                'sales.query.endDate',
                'Data final',
                'End date',
                'Fecha final',
              ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (inicio) {
        _draft = _draft.copyWith(dataInicio: result);
        if (_draft.dataFim.isBefore(result)) {
          _draft = _draft.copyWith(dataFim: result);
        }
      } else {
        _draft = _draft.copyWith(dataFim: result);
      }
    });
  }

  void _clear() {
    setState(() {
      _draft = _draft.copyWith(
        periodo: _ConsultaVendasMobileScreenState._periodoHoje,
        dataInicio: DateTime.now(),
        dataFim: DateTime.now(),
        statusFinanceiro: null,
        statusDevolucao: null,
        ordenacao: 'MAIS_RECENTES',
        valorMinimo: '',
        valorMaximo: '',
        limparStatusFinanceiro: true,
        limparStatusDevolucao: true,
      );
      _valorMinimoController.clear();
      _valorMaximoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: DraggableScrollableSheet(
          initialChildSize: 0.84,
          minChildSize: 0.58,
          maxChildSize: 0.94,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.strongBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _triple(
                                  context,
                                  'sales.query.mobile.sheetTitle',
                                  'Filtros da consulta',
                                  'Query filters',
                                  'Filtros de la consulta',
                                ),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: colors.titleText,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _triple(
                                  context,
                                  'sales.query.mobile.sheetSubtitle',
                                  'Ajuste período, situação e valores antes de aplicar.',
                                  'Adjust range, status and values before applying.',
                                  'Ajuste período, estado y valores antes de aplicar.',
                                ),
                                style: TextStyle(
                                  color: colors.mutedText,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip:
                              MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      children: <Widget>[
                        SixMobileSelectionField(
                          label: _triple(
                            context,
                            'sales.query.period',
                            'Período',
                            'Period',
                            'Período',
                          ),
                          value: widget.periodLabelBuilder(_draft.periodo),
                          icon: Icons.date_range_rounded,
                          onTap: _pickPeriodo,
                        ),
                        if (_draft.periodo ==
                            _ConsultaVendasMobileScreenState
                                ._periodoPersonalizado) ...<Widget>[
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: SixMobileSelectionField(
                                  label: _triple(
                                    context,
                                    'sales.query.startDate',
                                    'Data inicial',
                                    'Start date',
                                    'Fecha inicial',
                                  ),
                                  value: widget.formatDate(_draft.dataInicio),
                                  icon: Icons.event_rounded,
                                  onTap: () => _pickData(inicio: true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SixMobileSelectionField(
                                  label: _triple(
                                    context,
                                    'sales.query.endDate',
                                    'Data final',
                                    'End date',
                                    'Fecha final',
                                  ),
                                  value: widget.formatDate(_draft.dataFim),
                                  icon: Icons.event_available_rounded,
                                  onTap: () => _pickData(inicio: false),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        SixMobileSelectionField(
                          label: _triple(
                            context,
                            'sales.query.financialStatus',
                            'Situação financeira',
                            'Financial status',
                            'Situación financiera',
                          ),
                          value:
                              _draft.statusFinanceiro == null
                                  ? context.t('common.all', fallback: 'Todos')
                                  : widget.financialStatusLabelBuilder(
                                    _draft.statusFinanceiro!,
                                  ),
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: _pickStatusFinanceiro,
                        ),
                        const SizedBox(height: 12),
                        SixMobileSelectionField(
                          label: _triple(
                            context,
                            'sales.query.returnStatus',
                            'Situação da devolução',
                            'Return status',
                            'Situación de devolución',
                          ),
                          value:
                              _draft.statusDevolucao == null
                                  ? context.t('common.all', fallback: 'Todos')
                                  : widget.returnStatusLabelBuilder(
                                    _draft.statusDevolucao!,
                                  ),
                          icon: Icons.assignment_return_outlined,
                          onTap: _pickStatusDevolucao,
                        ),
                        const SizedBox(height: 12),
                        SixMobileSelectionField(
                          label: _triple(
                            context,
                            'sales.query.order',
                            'Ordenar por',
                            'Sort by',
                            'Ordenar por',
                          ),
                          value: widget.orderLabelBuilder(_draft.ordenacao),
                          icon: Icons.swap_vert_rounded,
                          onTap: _pickOrdenacao,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _valorMinimoController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: _triple(
                                    context,
                                    'sales.query.minimumValue',
                                    'Valor mínimo',
                                    'Minimum value',
                                    'Valor mínimo',
                                  ),
                                  filled: true,
                                  fillColor: colors.softSurface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _valorMaximoController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: _triple(
                                    context,
                                    'sales.query.maximumValue',
                                    'Valor máximo',
                                    'Maximum value',
                                    'Valor máximo',
                                  ),
                                  filled: true,
                                  fillColor: colors.softSurface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clear,
                            child: Text(
                              context.t('common.clear', fallback: 'Limpar'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                _draft.copyWith(
                                  valorMinimo: _valorMinimoController.text,
                                  valorMaximo: _valorMaximoController.text,
                                ),
                              );
                            },
                            child: Text(
                              context.t('common.apply', fallback: 'Aplicar'),
                            ),
                          ),
                        ),
                      ],
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
}

class _ConsultaVendasDateSheet extends StatefulWidget {
  const _ConsultaVendasDateSheet({
    required this.title,
    required this.initialDate,
    required this.minimumDate,
    required this.maximumDate,
  });

  final String title;
  final DateTime initialDate;
  final DateTime minimumDate;
  final DateTime maximumDate;

  @override
  State<_ConsultaVendasDateSheet> createState() =>
      _ConsultaVendasDateSheetState();
}

class _ConsultaVendasDateSheetState extends State<_ConsultaVendasDateSheet> {
  late DateTime _selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.strongBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: widget.minimumDate,
                  lastDate: widget.maximumDate,
                  onDateChanged: (DateTime value) {
                    setState(() => _selectedDate = value);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          context.t('common.cancel', fallback: 'Cancelar'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            () => Navigator.of(context).pop(_selectedDate),
                        child: Text(
                          context.t('common.apply', fallback: 'Aplicar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VendaDetalheMobileSheet extends StatefulWidget {
  const _VendaDetalheMobileSheet({
    required this.api,
    required this.identificador,
    required this.title,
  });

  final ConsultaVendasApiClient api;
  final String identificador;
  final String title;

  @override
  State<_VendaDetalheMobileSheet> createState() =>
      _VendaDetalheMobileSheetState();
}

class _VendaDetalheMobileSheetState extends State<_VendaDetalheMobileSheet> {
  VendaDetalheResponse? _detalhe;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final VendaDetalheResponse detalhe = await widget.api.detalhar(
        widget.identificador,
      );
      if (!mounted) return;
      setState(() => _detalhe = detalhe);
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _copiarNumeroDaVenda(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _triple(
            context,
            'sales.query.mobile.saleCodeCopied',
            'Número da venda copiado.',
            'Sale number copied.',
            'Número de venta copiado.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: DraggableScrollableSheet(
          initialChildSize: 0.90,
          minChildSize: 0.60,
          maxChildSize: 0.96,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.strongBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _triple(
                                  context,
                                  'sales.query.mobile.detailTitle',
                                  'Detalhes da venda',
                                  'Sale details',
                                  'Detalles de la venta',
                                ),
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: colors.titleText,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip:
                              MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  Expanded(
                    child: _buildBody(scrollController, colors, regionalizacao),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    ScrollController controller,
    SixMobileColorScheme colors,
    LocaleSettingsProvider regionalizacao,
  ) {
    if (_carregando && _detalhe == null) {
      return ListView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SixBackendLoading(
            title: _triple(
              context,
              'sales.query.mobile.loadingDetails',
              'Carregando detalhes',
              'Loading details',
              'Cargando detalles',
            ),
            subtitle: _triple(
              context,
              'sales.query.mobile.loadingDetailsSubtitle',
              'Reunindo itens, recebimentos, devoluções e histórico.',
              'Gathering items, receipts, returns and history.',
              'Reuniendo artículos, cobros, devoluciones e historial.',
            ),
            leadingIcon: Icons.manage_search_rounded,
            backgroundColor: colors.surface,
            borderColor: colors.border,
          ),
        ],
      );
    }

    if (_erro != null && _detalhe == null) {
      return ListView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _ErrorStateCard(message: _erro!, onRetry: _carregar),
        ],
      );
    }

    final VendaDetalheResponse detalhe = _detalhe!;
    final VendaConsultaResumo resumo = detalhe.resumo;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.softSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      resumo.identificadorPreferencial,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.titleText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _triple(
                      context,
                      'sales.query.mobile.copySaleCode',
                      'Copiar número da venda',
                      'Copy sale number',
                      'Copiar número de venta',
                    ),
                    onPressed:
                        () => _copiarNumeroDaVenda(
                          resumo.identificadorPreferencial,
                        ),
                    icon: Icon(
                      Icons.content_copy_rounded,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _StatusPill(
                    label: _financialStatusLabel(
                      context,
                      resumo.statusFinanceiro,
                    ),
                    color: _financialStatusColor(resumo.statusFinanceiro),
                  ),
                  _StatusPill(
                    label: _returnStatusLabel(context, resumo.statusDevolucao),
                    color: _returnStatusColor(resumo.statusDevolucao),
                  ),
                ],
              ),
              if (detalhe.descricao.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  detalhe.descricao,
                  style: TextStyle(
                    color: colors.mutedText,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Column(
                children: <Widget>[
                  _DetailMetricRow(
                    label: _triple(
                      context,
                      'sales.query.mobile.detailDate',
                      'Data',
                      'Date',
                      'Fecha',
                    ),
                    value: _formatDateTime(regionalizacao, resumo.dataOperacao),
                  ),
                  _DetailMetricRow(
                    label: _triple(
                      context,
                      'sales.query.mobile.detailCustomer',
                      'Cliente',
                      'Customer',
                      'Cliente',
                    ),
                    value: _fallback(
                      resumo.nomeCliente,
                      _triple(
                        context,
                        'sales.query.mobile.unknownCustomer',
                        'Cliente não identificado',
                        'Unidentified customer',
                        'Cliente no identificado',
                      ),
                    ),
                  ),
                  _DetailMetricRow(
                    label: _triple(
                      context,
                      'sales.query.mobile.detailSeller',
                      'Vendedor',
                      'Seller',
                      'Vendedor',
                    ),
                    value: _fallback(
                      resumo.nomeColaborador,
                      _triple(
                        context,
                        'sales.query.mobile.system',
                        'Sistema',
                        'System',
                        'Sistema',
                      ),
                    ),
                  ),
                  _DetailMetricRow(
                    label: _triple(
                      context,
                      'sales.query.mobile.detailTotal',
                      'Total',
                      'Total',
                      'Total',
                    ),
                    value: regionalizacao.formatCurrency(resumo.valorTotal),
                    emphasize: true,
                  ),
                  _DetailMetricRow(
                    label: _triple(
                      context,
                      'sales.query.mobile.received',
                      'Recebido',
                      'Received',
                      'Recibido',
                    ),
                    value: regionalizacao.formatCurrency(resumo.valorRecebido),
                  ),
                  _DetailMetricRow(
                    label: _triple(
                      context,
                      'sales.query.mobile.openAmount',
                      'Em aberto',
                      'Open',
                      'Abierto',
                    ),
                    value: regionalizacao.formatCurrency(resumo.valorEmAberto),
                  ),
                  _DetailMetricRow(
                    label: _triple(
                      context,
                      'sales.query.mobile.returnedAmount',
                      'Devolvido',
                      'Returned',
                      'Devuelto',
                    ),
                    value: regionalizacao.formatCurrency(resumo.valorDevolvido),
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: _triple(
            context,
            'sales.query.mobile.itemsSection',
            'Itens',
            'Items',
            'Artículos',
          ),
          emptyMessage: _triple(
            context,
            'sales.query.mobile.itemsEmpty',
            'Nenhum item encontrado nesta venda.',
            'No items found for this sale.',
            'No se encontraron artículos en esta venta.',
          ),
          children: detalhe.itens
              .map(
                (ItemVendaDetalhe item) => _DetailListTile(
                  title: _fallback(item.nomeProduto, item.idProduto),
                  subtitle: item.codigoProduto,
                  trailing: regionalizacao.formatCurrency(item.valorTotal),
                  content: <Widget>[
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.quantity', 'Quantidade', 'Quantity', 'Cantidad')}: ${_formatQuantity(item.quantidade)}',
                    ),
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.unitPrice', 'Valor unitário', 'Unit price', 'Valor unitario')}: ${regionalizacao.formatCurrency(item.valorUnitario)}',
                    ),
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.returnedQuantity', 'Já devolvida', 'Already returned', 'Ya devuelta')}: ${_formatQuantity(item.quantidadeDevolvida)}',
                    ),
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.availableQuantity', 'Ainda devolvível', 'Still returnable', 'Aún devolvible')}: ${_formatQuantity(item.quantidadeDisponivel)}',
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: _triple(
            context,
            'sales.query.mobile.receiptsSection',
            'Recebimentos',
            'Receipts',
            'Cobros',
          ),
          emptyMessage: _triple(
            context,
            'sales.query.mobile.receiptsEmpty',
            'Nenhum recebimento registrado.',
            'No receipts recorded.',
            'No hay cobros registrados.',
          ),
          children: detalhe.recebimentos
              .map(
                (RecebimentoVendaDetalhe recebimento) => _DetailListTile(
                  title: _fallback(
                    recebimento.descricaoTipoRecebimento,
                    recebimento.codigoTipoRecebimento,
                  ),
                  subtitle: _formatDateTime(
                    regionalizacao,
                    recebimento.dataHora,
                  ),
                  trailing: regionalizacao.formatCurrency(
                    recebimento.valorRecebido,
                  ),
                  content: <Widget>[
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.origin', 'Origem', 'Source', 'Origen')}: ${_humanizeCode(recebimento.origem)}',
                    ),
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.status', 'Status', 'Status', 'Estado')}: ${_humanizeCode(recebimento.status)}',
                    ),
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.originalValue', 'Valor original', 'Original amount', 'Valor original')}: ${regionalizacao.formatCurrency(recebimento.valorOriginal)}',
                    ),
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.balance', 'Saldo', 'Balance', 'Saldo')}: ${regionalizacao.formatCurrency(recebimento.valorEmAberto)}',
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: _triple(
            context,
            'sales.query.mobile.returnsSection',
            'Devoluções e trocas',
            'Returns and exchanges',
            'Devoluciones y cambios',
          ),
          emptyMessage: _triple(
            context,
            'sales.query.mobile.returnsEmpty',
            'Esta venda ainda não possui devoluções ou trocas.',
            'This sale has no returns or exchanges yet.',
            'Esta venta aún no tiene devoluciones o cambios.',
          ),
          children: detalhe.devolucoes
              .map(
                (DevolucaoVendaDetalhe devolucao) => _DetailListTile(
                  title: _fallback(
                    devolucao.codigoDevolucao,
                    devolucao.idDevolucao,
                  ),
                  subtitle:
                      '${_formatDateTime(regionalizacao, devolucao.dataHora)} · ${_fallback(devolucao.nomeColaborador, devolucao.idColaborador)}',
                  trailing: regionalizacao.formatCurrency(
                    devolucao.valorTotalDevolvido,
                  ),
                  content: <Widget>[
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.type', 'Tipo', 'Type', 'Tipo')}: ${_humanizeCode(devolucao.tipo)}',
                    ),
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.exchangeValue', 'Troca', 'Exchange', 'Cambio')}: ${regionalizacao.formatCurrency(devolucao.valorTotalTroca)}',
                    ),
                    _DetailBadge(
                      label:
                          '${_triple(context, 'sales.query.mobile.difference', 'Diferença', 'Difference', 'Diferencia')}: ${regionalizacao.formatCurrency(devolucao.saldoFinanceiro)}',
                    ),
                    if (devolucao.itensDevolvidos.isNotEmpty)
                      _DetailBadge(
                        label:
                            '${_triple(context, 'sales.query.mobile.returnItemsCount', 'Itens devolvidos', 'Returned items', 'Artículos devueltos')}: ${devolucao.itensDevolvidos.length}',
                      ),
                    if (devolucao.itensTroca.isNotEmpty)
                      _DetailBadge(
                        label:
                            '${_triple(context, 'sales.query.mobile.exchangeItemsCount', 'Itens de troca', 'Exchange items', 'Artículos de cambio')}: ${devolucao.itensTroca.length}',
                      ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: _triple(
            context,
            'sales.query.mobile.historySection',
            'Histórico',
            'History',
            'Historial',
          ),
          emptyMessage: _triple(
            context,
            'sales.query.mobile.historyEmpty',
            'Nenhum evento adicional encontrado.',
            'No additional events found.',
            'No se encontraron eventos adicionales.',
          ),
          children: detalhe.historico
              .map(
                (EventoVendaDetalhe evento) => _HistoryTile(
                  title: _humanizeCode(evento.tipo),
                  subtitle:
                      '${_formatDateTime(regionalizacao, evento.dataHora)}${evento.referencia.trim().isNotEmpty ? ' · ${evento.referencia}' : ''}',
                  amount:
                      evento.valor.abs() > 0.0001
                          ? regionalizacao.formatCurrency(evento.valor)
                          : null,
                  positive: evento.valor >= 0,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: colors.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(
                color: colors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...children.expand(
              (Widget child) => <Widget>[
                child,
                if (child != children.last) const SizedBox(height: 10),
              ],
            ),
        ],
      ),
    );
  }
}

class _DetailListTile extends StatelessWidget {
  const _DetailListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.content,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final List<Widget> content;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.titleText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              trailing,
              style: TextStyle(
                color: colors.titleText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        if (content.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < content.length; index++) ...<Widget>[
                content[index],
                if (index + 1 < content.length) const SizedBox(height: 4),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors.mutedText.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.positive,
  });

  final String title;
  final String subtitle;
  final String? amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final Color amountColor = positive ? const Color(0xFF16A34A) : colors.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: colors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: colors.titleText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
              if ((amount ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  amount!,
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailMetricRow extends StatelessWidget {
  const _DetailMetricRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        border:
            isLast ? null : Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 3,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.titleText,
                fontSize: emphasize ? 15 : 13.5,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _triple(
  BuildContext context,
  String key,
  String pt,
  String en,
  String es,
) {
  final String language = Localizations.localeOf(context).languageCode;
  final String fallback = switch (language) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
  return context.t(key, fallback: fallback);
}

String _fallback(String? value, String fallback) {
  final String text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _formatDateTime(LocaleSettingsProvider regionalizacao, DateTime? value) {
  if (value == null) return '-';
  final String date = regionalizacao.formatDate(value);
  final String time = regionalizacao.formatTime(value);
  return '$date $time';
}

String _formatQuantity(double value) {
  if ((value - value.round()).abs() < 0.0001) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

double? _parseNumero(String text) {
  final String normalized = text.trim();
  if (normalized.isEmpty) return null;
  if (normalized.contains(',') && normalized.contains('.')) {
    return double.tryParse(normalized.replaceAll('.', '').replaceAll(',', '.'));
  }
  if (normalized.contains(',')) {
    return double.tryParse(normalized.replaceAll(',', '.'));
  }
  return double.tryParse(normalized);
}

String _mensagemErro(Object error) {
  if (error is ConsultaVendasApiException) return error.mensagem;
  final String text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Não foi possível consultar as vendas.' : text;
}

String _humanizeCode(String value) {
  final String normalized = value.trim();
  if (normalized.isEmpty) return '-';
  final String lower = normalized.replaceAll('_', ' ').toLowerCase();
  return lower
      .split(' ')
      .where((String part) => part.isNotEmpty)
      .map(
        (String part) =>
            '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

Color _financialStatusColor(String value) {
  switch (value) {
    case 'QUITADA':
      return const Color(0xFF16A34A);
    case 'PARCIAL':
      return const Color(0xFFF59E0B);
    case 'CANCELADA':
      return const Color(0xFFEF4444);
    case 'EM_ABERTO':
    default:
      return const Color(0xFF2563EB);
  }
}

Color _returnStatusColor(String value) {
  switch (value) {
    case 'TOTAL':
      return const Color(0xFFEF4444);
    case 'PARCIAL':
      return const Color(0xFFF59E0B);
    case 'SEM_DEVOLUCAO':
    default:
      return SixMobilePalette.secondary;
  }
}

String _financialStatusLabel(BuildContext context, String value) {
  switch (value) {
    case 'QUITADA':
      return _triple(
        context,
        'sales.query.financial.paid',
        'Quitada',
        'Paid',
        'Pagada',
      );
    case 'PARCIAL':
      return _triple(
        context,
        'sales.query.financial.partial',
        'Parcial',
        'Partial',
        'Parcial',
      );
    case 'EM_ABERTO':
      return _triple(
        context,
        'sales.query.financial.open',
        'Em aberto',
        'Open',
        'Abierta',
      );
    case 'CANCELADA':
      return _triple(
        context,
        'sales.query.financial.cancelled',
        'Cancelada',
        'Cancelled',
        'Cancelada',
      );
    default:
      return _humanizeCode(value);
  }
}

String _returnStatusLabel(BuildContext context, String value) {
  switch (value) {
    case 'SEM_DEVOLUCAO':
      return _triple(
        context,
        'sales.query.return.none',
        'Sem devolução',
        'No return',
        'Sin devolución',
      );
    case 'PARCIAL':
      return _triple(
        context,
        'sales.query.return.partial',
        'Parcial',
        'Partial',
        'Parcial',
      );
    case 'TOTAL':
      return _triple(
        context,
        'sales.query.return.total',
        'Total',
        'Full',
        'Total',
      );
    default:
      return _humanizeCode(value);
  }
}
