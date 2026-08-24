import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/consulta_vendas_models.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/vendas/consulta_vendas_api_client.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/six_backend_loading.dart';
import '../components/web/six_web_select_field.dart';
import '../theme/web_theme_tokens.dart';

class ConsultaVendasWebPage extends StatefulWidget {
  const ConsultaVendasWebPage({
    super.key,
    this.onNovaVenda,
    this.onAbrirDevolucoes,
    this.apiClient,
  });

  final VoidCallback? onNovaVenda;
  final ValueChanged<String>? onAbrirDevolucoes;
  final ConsultaVendasApiClient? apiClient;

  @override
  State<ConsultaVendasWebPage> createState() => _ConsultaVendasWebPageState();
}

Future<void> showVendaDetalheWebDialog({
  required BuildContext context,
  required String identificador,
  ConsultaVendasApiClient? apiClient,
  ValueChanged<String>? onAbrirDevolucoes,
}) async {
  final ConsultaVendasApiClient api =
      apiClient ?? HttpConsultaVendasApiClient();
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Future<void> abrirDevolucoes(String idOperacao) async {
    final ValueChanged<String>? callback = onAbrirDevolucoes;
    if (callback != null) {
      callback(idOperacao);
      return;
    }

    await Clipboard.setData(ClipboardData(text: idOperacao));
    if (!context.mounted) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          _text(
            context,
            'sales.query.returnCopied',
            pt:
                'Código da venda copiado. Abra Devoluções e trocas para continuar.',
            en: 'Sale code copied. Open Returns and exchanges to continue.',
            es:
                'Código de venta copiado. Abra Devoluciones y cambios para continuar.',
          ),
        ),
      ),
    );
  }

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
    pageBuilder:
        (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) => _VendaDetalheRouteSurface(
          animation: animation,
          child: _VendaDetalheDialog(
            api: api,
            identificador: identificador,
            onAbrirDevolucoes: abrirDevolucoes,
          ),
        ),
    transitionBuilder:
        (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => child,
  );
}

class _ConsultaVendasWebPageState extends State<ConsultaVendasWebPage> {
  static const String _periodoHoje = 'Hoje';
  static const String _periodoUltimos7Dias = 'Últimos 7 dias';
  static const String _periodoUltimos30Dias = 'Últimos 30 dias';
  static const String _periodoEsteMes = 'Este mês';
  static const String _periodoMesPassado = 'Mês passado';
  static const String _periodoIntervaloPersonalizado =
      'Intervalo personalizado';
  static const List<String> _periodosFiltroData = <String>[
    _periodoHoje,
    _periodoUltimos7Dias,
    _periodoUltimos30Dias,
    _periodoEsteMes,
    _periodoMesPassado,
    _periodoIntervaloPersonalizado,
  ];

  late final ConsultaVendasApiClient _api;
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _valorMinimoController = TextEditingController();
  final TextEditingController _valorMaximoController = TextEditingController();

  late DateTime _dataInicial;
  late DateTime _dataFinal;
  late DateTime _dataInicioPersonalizada;
  late DateTime _dataFimPersonalizada;
  String? _statusFinanceiro;
  String? _statusDevolucao;
  String _periodoSelecionado = _periodoUltimos30Dias;
  String _ordenacao = 'MAIS_RECENTES';
  int _tamanhoPagina = 25;
  Timer? _salvarFiltrosDebounce;

  ConsultaVendasResponse? _resultado;
  bool _carregando = false;
  bool _aplicandoPreferencias = false;
  bool _usuarioAlterouFiltros = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpConsultaVendasApiClient();
    final DateTime hoje = _hojeNormalizado();
    _dataFinal = hoje;
    _dataInicial = hoje.subtract(const Duration(days: 29));
    _dataInicioPersonalizada = _dataInicial;
    _dataFimPersonalizada = _dataFinal;
    _buscaController.addListener(_onTextoFiltrosChanged);
    _valorMinimoController.addListener(_onTextoFiltrosChanged);
    _valorMaximoController.addListener(_onTextoFiltrosChanged);
    Future<void>.microtask(() async {
      await _restaurarPreferenciasConsultaVendas();
      await _carregar(pagina: 0);
      unawaited(
        _restaurarPreferenciasConsultaVendasBackend(recarregarSeAlterou: true),
      );
    });
  }

  @override
  void dispose() {
    _salvarFiltrosDebounce?.cancel();
    _buscaController.removeListener(_onTextoFiltrosChanged);
    _valorMinimoController.removeListener(_onTextoFiltrosChanged);
    _valorMaximoController.removeListener(_onTextoFiltrosChanged);
    _buscaController.dispose();
    _valorMinimoController.dispose();
    _valorMaximoController.dispose();
    super.dispose();
  }

  Future<void> _carregar({int? pagina}) async {
    if (_carregando) return;
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
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  ConsultaVendasFiltro _filtro({required int pagina}) {
    return ConsultaVendasFiltro(
      dataInicial: _dataInicial,
      dataFinal: _dataFinal,
      busca: _buscaController.text,
      statusFinanceiro: _statusFinanceiro,
      statusDevolucao: _statusDevolucao,
      valorMinimo: _parseNumero(_valorMinimoController.text),
      valorMaximo: _parseNumero(_valorMaximoController.text),
      ordenacao: _ordenacao,
      pagina: pagina,
      tamanho: _tamanhoPagina,
    );
  }

  bool get _usaPeriodoPersonalizado =>
      _periodoSelecionado == _periodoIntervaloPersonalizado;

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
      case _periodoIntervaloPersonalizado:
        final DateTime inicio = _normalizarData(_dataInicioPersonalizada);
        final DateTime fim = _normalizarData(_dataFimPersonalizada);
        return DateTimeRange(
          start: inicio.isAfter(fim) ? fim : inicio,
          end: fim.isBefore(inicio) ? inicio : fim,
        );
      case _periodoUltimos30Dias:
      default:
        return DateTimeRange(
          start: hoje.subtract(const Duration(days: 29)),
          end: hoje,
        );
    }
  }

  void _sincronizarPeriodoComDatas() {
    final DateTimeRange periodo = _resolverPeriodoSelecionado();
    _dataInicial = periodo.start;
    _dataFinal = periodo.end;
  }

  void _ajustarPeriodoPersonalizadoSeguro() {
    final DateTime inicio = _normalizarData(_dataInicioPersonalizada);
    final DateTime fim = _normalizarData(_dataFimPersonalizada);
    if (fim.isBefore(inicio)) {
      _dataFimPersonalizada = inicio;
    }
  }

  Future<void> _selecionarDataPersonalizada({required bool inicial}) async {
    final DateTime atual =
        inicial ? _dataInicioPersonalizada : _dataFimPersonalizada;
    final DateTime firstDate =
        inicial ? DateTime(2020) : _dataInicioPersonalizada;
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: _text(
        context,
        inicial ? 'sales.query.customStartDate' : 'sales.query.customEndDate',
        pt: inicial ? 'Selecionar data inicial' : 'Selecionar data final',
        en: inicial ? 'Select start date' : 'Select end date',
        es: inicial ? 'Seleccionar fecha inicial' : 'Seleccionar fecha final',
      ),
    );
    if (selecionada == null || !mounted) return;

    setState(() {
      final DateTime normalizada = _normalizarData(selecionada);
      if (inicial) {
        _dataInicioPersonalizada = normalizada;
        _ajustarPeriodoPersonalizadoSeguro();
      } else {
        _dataFimPersonalizada = normalizada;
      }
      _sincronizarPeriodoComDatas();
    });
    _onFiltroAlterado(salvarImediatamente: true);
  }

  Future<void> _limparFiltros() async {
    final DateTime hoje = _hojeNormalizado();
    _aplicandoPreferencias = true;
    setState(() {
      _periodoSelecionado = _periodoUltimos30Dias;
      _dataFinal = hoje;
      _dataInicial = _dataFinal.subtract(const Duration(days: 29));
      _dataInicioPersonalizada = _dataInicial;
      _dataFimPersonalizada = _dataFinal;
      _buscaController.clear();
      _valorMinimoController.clear();
      _valorMaximoController.clear();
      _statusFinanceiro = null;
      _statusDevolucao = null;
      _ordenacao = 'MAIS_RECENTES';
      _tamanhoPagina = 25;
    });
    _aplicandoPreferencias = false;
    _onFiltroAlterado(salvarImediatamente: true);
    await _carregar(pagina: 0);
  }

  Future<void> _restaurarPreferenciasConsultaVendas() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
      return;
    }
    _aplicarPreferenciasConsultaVendas(preferencias.consultaVendasFiltrosWeb);
  }

  Future<void> _restaurarPreferenciasConsultaVendasBackend({
    bool recarregarSeAlterou = false,
  }) async {
    try {
      if (_usuarioProvider.usuario == null) {
        await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      }
      final PreferenciasIndividuaisDoUsuarioModel? preferencias =
          _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
      if (!mounted || preferencias == null || _usuarioAlterouFiltros) {
        return;
      }
      final bool alterou = _aplicarPreferenciasConsultaVendas(
        preferencias.consultaVendasFiltrosWeb,
      );
      if (alterou && recarregarSeAlterou && mounted) {
        await _carregar(pagina: 0);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao restaurar preferencias da consulta de vendas: '
        '$error\n$stackTrace',
      );
    }
  }

  bool _aplicarPreferenciasConsultaVendas(
    ConsultaVendasFiltrosWebPreferencia filtros,
  ) {
    final String assinaturaAnterior = _assinaturaFiltrosAtual();
    _aplicandoPreferencias = true;
    if (_buscaController.text != filtros.busca) {
      _buscaController.text = filtros.busca;
    }
    if (_valorMinimoController.text != filtros.valorMinimo) {
      _valorMinimoController.text = filtros.valorMinimo;
    }
    if (_valorMaximoController.text != filtros.valorMaximo) {
      _valorMaximoController.text = filtros.valorMaximo;
    }
    setState(() {
      _statusFinanceiro = filtros.statusFinanceiro;
      _statusDevolucao = filtros.statusDevolucao;
      _ordenacao = filtros.ordenacao;
      _tamanhoPagina = filtros.tamanhoPagina > 0 ? filtros.tamanhoPagina : 25;
      _periodoSelecionado = _periodoLabelPreferencia(filtros.periodo);
      if (filtros.periodo ==
          ConsultaVendasPeriodoWebPreferencia.personalizado) {
        if (filtros.dataInicio != null) {
          _dataInicioPersonalizada = filtros.dataInicio!;
        }
        if (filtros.dataFim != null) {
          _dataFimPersonalizada = filtros.dataFim!;
        }
        _ajustarPeriodoPersonalizadoSeguro();
      }
      _sincronizarPeriodoComDatas();
    });
    _aplicandoPreferencias = false;
    return assinaturaAnterior != _assinaturaFiltrosAtual();
  }

  void _onTextoFiltrosChanged() {
    if (mounted) {
      setState(() {});
    }
    if (_aplicandoPreferencias) {
      return;
    }
    _onFiltroAlterado();
  }

  void _onFiltroAlterado({bool salvarImediatamente = false}) {
    _usuarioAlterouFiltros = true;
    if (salvarImediatamente) {
      _salvarPreferenciasConsultaVendas();
      return;
    }
    _agendarSalvarPreferenciasConsultaVendas();
  }

  void _agendarSalvarPreferenciasConsultaVendas() {
    _salvarFiltrosDebounce?.cancel();
    _salvarFiltrosDebounce = Timer(
      const Duration(milliseconds: 450),
      _salvarPreferenciasConsultaVendas,
    );
  }

  void _salvarPreferenciasConsultaVendas() {
    _salvarFiltrosDebounce?.cancel();
    final ConsultaVendasFiltrosWebPreferencia filtros =
        _preferenciaConsultaVendasAtual();

    unawaited(
      _usuarioService
          .atualizarPreferenciasIndividuais(
            consultaVendasFiltrosWeb: filtros.toJson(),
          )
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint(
              'Erro ao salvar preferencias da consulta de vendas: '
              '$error\n$stackTrace',
            );
          }),
    );
  }

  ConsultaVendasFiltrosWebPreferencia _preferenciaConsultaVendasAtual() {
    return ConsultaVendasFiltrosWebPreferencia(
      busca: _buscaController.text,
      periodo: _periodoPreferenciaAtual(_periodoSelecionado),
      dataInicio: _usaPeriodoPersonalizado ? _dataInicioPersonalizada : null,
      dataFim: _usaPeriodoPersonalizado ? _dataFimPersonalizada : null,
      statusFinanceiro: _statusFinanceiro,
      statusDevolucao: _statusDevolucao,
      valorMinimo: _valorMinimoController.text,
      valorMaximo: _valorMaximoController.text,
      ordenacao: _ordenacao,
      tamanhoPagina: _tamanhoPagina,
    );
  }

  String _assinaturaFiltrosAtual() {
    final ConsultaVendasFiltrosWebPreferencia filtros =
        _preferenciaConsultaVendasAtual();
    return <String>[
      filtros.busca.trim(),
      filtros.periodo.codigo,
      filtros.dataInicio?.toIso8601String() ?? '',
      filtros.dataFim?.toIso8601String() ?? '',
      filtros.statusFinanceiro ?? '',
      filtros.statusDevolucao ?? '',
      filtros.valorMinimo.trim(),
      filtros.valorMaximo.trim(),
      filtros.ordenacao,
      filtros.tamanhoPagina.toString(),
    ].join('|');
  }

  bool get _temFiltrosAtivos =>
      _buscaController.text.trim().isNotEmpty ||
      _periodoSelecionado != _periodoUltimos30Dias ||
      _statusFinanceiro != null ||
      _statusDevolucao != null ||
      _valorMinimoController.text.trim().isNotEmpty ||
      _valorMaximoController.text.trim().isNotEmpty ||
      _ordenacao != 'MAIS_RECENTES';

  void _selecionarPeriodoFiltro(String selected) {
    if (!_periodosFiltroData.contains(selected) ||
        _periodoSelecionado == selected) {
      return;
    }
    setState(() {
      _periodoSelecionado = selected;
      if (_usaPeriodoPersonalizado) {
        _ajustarPeriodoPersonalizadoSeguro();
      }
      _sincronizarPeriodoComDatas();
    });
    _onFiltroAlterado(salvarImediatamente: true);
  }

  Future<void> _abrirDetalhe(VendaConsultaResumo venda) async {
    await showVendaDetalheWebDialog(
      context: context,
      identificador: venda.idOperacao,
      apiClient: _api,
      onAbrirDevolucoes: widget.onAbrirDevolucoes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = Theme.of(context);
    final ThemeData webTheme = WebThemeTokens.applyTo(baseTheme);
    final WebThemeTokens tokens = WebThemeTokens.resolve(baseTheme);
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();

    return AnimatedTheme(
      data: webTheme,
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      child: Container(
        key: const Key('consulta-vendas-web-root'),
        color: tokens.workspaceBackground,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compacto = constraints.maxWidth < 980;
            final double padding = compacto ? 14 : 22;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 18, padding, 26),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildCabecalho(context, tokens, compacto),
                      const SizedBox(height: 16),
                      _buildResumo(context, tokens, regionalizacao),
                      const SizedBox(height: 16),
                      _buildFiltros(context, tokens, regionalizacao, compacto),
                      const SizedBox(height: 16),
                      _buildResultados(
                        context,
                        tokens,
                        regionalizacao,
                        compacto,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCabecalho(
    BuildContext context,
    WebThemeTokens tokens,
    bool compacto,
  ) {
    final ThemeData theme = Theme.of(context);
    final Widget titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _text(
            context,
            'sales.query.title',
            pt: 'Vendas',
            en: 'Sales',
            es: 'Ventas',
          ),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _text(
            context,
            'sales.query.subtitle',
            pt:
                'Consulte, filtre e acompanhe todo o ciclo das vendas deste comércio.',
            en:
                'Search, filter and follow the complete sales lifecycle for this business.',
            es:
                'Consulte, filtre y acompañe todo el ciclo de ventas de este comercio.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final Widget acoes = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.info,
            backgroundColor: tokens.surfaceMuted.withValues(alpha: 0.35),
            side: BorderSide(color: tokens.selectedBorder),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _carregando ? null : () => _carregar(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            _text(
              context,
              'common.refresh',
              pt: 'Atualizar',
              en: 'Refresh',
              es: 'Actualizar',
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: widget.onNovaVenda,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: Text(
            _text(
              context,
              'sales.query.newSale',
              pt: 'Nova venda',
              en: 'New sale',
              es: 'Nueva venta',
            ),
          ),
        ),
      ],
    );

    return _SurfaceCard(
      tokens: tokens,
      padding: const EdgeInsets.all(18),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[titulo, const SizedBox(height: 16), acoes],
              )
              : Row(
                children: <Widget>[
                  Expanded(child: titulo),
                  const SizedBox(width: 20),
                  acoes,
                ],
              ),
    );
  }

  Widget _buildResumo(
    BuildContext context,
    WebThemeTokens tokens,
    LocaleSettingsProvider regionalizacao,
  ) {
    final ResumoConsultaVendas resumo =
        _resultado?.resumo ??
        const ResumoConsultaVendas(
          quantidadeVendas: 0,
          valorTotalVendido: 0,
          valorTotalRecebido: 0,
          valorTotalEmAberto: 0,
          valorTotalDevolvido: 0,
        );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _KpiCard(
          tokens: tokens,
          icon: Icons.receipt_long_outlined,
          label: _text(
            context,
            'sales.query.kpi.count',
            pt: 'Vendas',
            en: 'Sales',
            es: 'Ventas',
          ),
          value: resumo.quantidadeVendas.toString(),
          accent: tokens.info,
        ),
        _KpiCard(
          tokens: tokens,
          icon: Icons.trending_up_rounded,
          label: _text(
            context,
            'sales.query.kpi.sold',
            pt: 'Valor vendido',
            en: 'Sold amount',
            es: 'Valor vendido',
          ),
          value: regionalizacao.formatCurrency(resumo.valorTotalVendido),
          accent: tokens.financialPositive,
        ),
        _KpiCard(
          tokens: tokens,
          icon: Icons.payments_outlined,
          label: _text(
            context,
            'sales.query.kpi.received',
            pt: 'Valor recebido',
            en: 'Received amount',
            es: 'Valor recibido',
          ),
          value: regionalizacao.formatCurrency(resumo.valorTotalRecebido),
          accent: tokens.success,
        ),
        _KpiCard(
          tokens: tokens,
          icon: Icons.schedule_outlined,
          label: _text(
            context,
            'sales.query.kpi.open',
            pt: 'Saldo em aberto',
            en: 'Open balance',
            es: 'Saldo abierto',
          ),
          value: regionalizacao.formatCurrency(resumo.valorTotalEmAberto),
          accent: tokens.warning,
        ),
        _KpiCard(
          tokens: tokens,
          icon: Icons.assignment_return_outlined,
          label: _text(
            context,
            'sales.query.kpi.returned',
            pt: 'Valor devolvido',
            en: 'Returned amount',
            es: 'Valor devuelto',
          ),
          value: regionalizacao.formatCurrency(resumo.valorTotalDevolvido),
          accent: tokens.danger,
        ),
        _KpiCard(
          tokens: tokens,
          icon: Icons.analytics_outlined,
          label: _text(
            context,
            'sales.query.kpi.average',
            pt: 'Ticket médio',
            en: 'Average ticket',
            es: 'Ticket promedio',
          ),
          value: regionalizacao.formatCurrency(resumo.ticketMedio),
          accent: tokens.secondaryText,
        ),
      ],
    );
  }

  Widget _buildFiltros(
    BuildContext context,
    WebThemeTokens tokens,
    LocaleSettingsProvider regionalizacao,
    bool compacto,
  ) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color inputFillColor =
        dark
            ? tokens.surfaceElevated.withValues(alpha: 0.94)
            : tokens.inputBackground;
    final InputDecoration decoration = InputDecoration(
      filled: true,
      fillColor: inputFillColor,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: tokens.secondaryText,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: theme.textTheme.labelMedium?.copyWith(
        color: tokens.info,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: tokens.mutedText,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: tokens.info,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );

    return _SurfaceCard(
      tokens: tokens,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool larguraCompacta = compacto || constraints.maxWidth < 1040;
          final double campoBuscaLargura =
              larguraCompacta ? constraints.maxWidth : 360;
          final double campoMedioLargura =
              larguraCompacta ? constraints.maxWidth : 220;
          final double campoPequenoLargura =
              larguraCompacta ? constraints.maxWidth : 170;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.filter_alt_outlined, color: tokens.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _text(
                        context,
                        'sales.query.filters',
                        pt: 'Filtros',
                        en: 'Filters',
                        es: 'Filtros',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (_temFiltrosAtivos)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Text(
                        _text(
                          context,
                          'sales.query.filtersActive',
                          pt: 'Filtros ativos',
                          en: 'Active filters',
                          es: 'Filtros activos',
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: tokens.secondaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: <Widget>[
                  SizedBox(
                    width: campoBuscaLargura,
                    child: TextField(
                      controller: _buscaController,
                      decoration: decoration.copyWith(
                        labelText: _text(
                          context,
                          'sales.query.search',
                          pt: 'Venda, cliente, documento ou produto',
                          en: 'Sale, customer, document or product',
                          es: 'Venta, cliente, documento o producto',
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _carregar(pagina: 0),
                    ),
                  ),
                  SixWebSelectField(
                    width: campoMedioLargura,
                    label: _text(
                      context,
                      'sales.query.period',
                      pt: 'Período',
                      en: 'Period',
                      es: 'Período',
                    ),
                    value: _periodoFiltroLabel(
                      context,
                      regionalizacao,
                      _periodoSelecionado,
                      _dataInicial,
                      _dataFinal,
                    ),
                    items: <String>[
                      for (final String value in _periodosFiltroData)
                        _periodoFiltroItemLabel(context, value),
                    ],
                    icon: Icons.date_range_rounded,
                    onSelected: (String selected) {
                      _selecionarPeriodoFiltro(
                        _periodoValueFromLabel(context, selected),
                      );
                    },
                  ),
                  SixWebSelectField(
                    width: campoMedioLargura,
                    label: _text(
                      context,
                      'sales.query.financialStatus',
                      pt: 'Situação financeira',
                      en: 'Financial status',
                      es: 'Situación financiera',
                    ),
                    value:
                        _statusFinanceiro == null
                            ? _allLabel(context)
                            : _statusFinanceiroLabel(
                              context,
                              _statusFinanceiro!,
                            ),
                    items: <String>[
                      _allLabel(context),
                      for (final String value in const <String>[
                        'QUITADA',
                        'PARCIAL',
                        'EM_ABERTO',
                        'CANCELADA',
                      ])
                        _statusFinanceiroLabel(context, value),
                    ],
                    icon: Icons.account_balance_wallet_outlined,
                    onSelected: (String selected) {
                      setState(() {
                        _statusFinanceiro = _financialStatusValueFromLabel(
                          context,
                          selected,
                        );
                      });
                      _onFiltroAlterado(salvarImediatamente: true);
                    },
                  ),
                  SixWebSelectField(
                    width: campoMedioLargura,
                    label: _text(
                      context,
                      'sales.query.returnStatus',
                      pt: 'Situação da devolução',
                      en: 'Return status',
                      es: 'Situación de devolución',
                    ),
                    value:
                        _statusDevolucao == null
                            ? _allLabel(context)
                            : _statusDevolucaoLabel(context, _statusDevolucao!),
                    items: <String>[
                      _allLabel(context),
                      for (final String value in const <String>[
                        'SEM_DEVOLUCAO',
                        'PARCIAL',
                        'TOTAL',
                      ])
                        _statusDevolucaoLabel(context, value),
                    ],
                    icon: Icons.assignment_return_outlined,
                    onSelected: (String selected) {
                      setState(() {
                        _statusDevolucao = _returnStatusValueFromLabel(
                          context,
                          selected,
                        );
                      });
                      _onFiltroAlterado(salvarImediatamente: true);
                    },
                  ),
                ],
              ),
              if (_usaPeriodoPersonalizado) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _DateFilterButton(
                      tokens: tokens,
                      width: campoMedioLargura,
                      label: _text(
                        context,
                        'sales.query.startDate',
                        pt: 'Data inicial',
                        en: 'Start date',
                        es: 'Fecha inicial',
                      ),
                      value: regionalizacao.formatDate(
                        _dataInicioPersonalizada,
                      ),
                      onPressed:
                          () => _selecionarDataPersonalizada(inicial: true),
                    ),
                    _DateFilterButton(
                      tokens: tokens,
                      width: campoMedioLargura,
                      label: _text(
                        context,
                        'sales.query.endDate',
                        pt: 'Data final',
                        en: 'End date',
                        es: 'Fecha final',
                      ),
                      value: regionalizacao.formatDate(_dataFimPersonalizada),
                      onPressed:
                          () => _selecionarDataPersonalizada(inicial: false),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: <Widget>[
                  SizedBox(
                    width: campoPequenoLargura,
                    child: TextField(
                      controller: _valorMinimoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: decoration.copyWith(
                        labelText: _text(
                          context,
                          'sales.query.minimumValue',
                          pt: 'Valor mínimo',
                          en: 'Minimum value',
                          es: 'Valor mínimo',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: campoPequenoLargura,
                    child: TextField(
                      controller: _valorMaximoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: decoration.copyWith(
                        labelText: _text(
                          context,
                          'sales.query.maximumValue',
                          pt: 'Valor máximo',
                          en: 'Maximum value',
                          es: 'Valor máximo',
                        ),
                      ),
                    ),
                  ),
                  SixWebSelectField(
                    width: campoMedioLargura,
                    label: _text(
                      context,
                      'sales.query.order',
                      pt: 'Ordenar por',
                      en: 'Sort by',
                      es: 'Ordenar por',
                    ),
                    value: _ordenacaoLabel(context, _ordenacao),
                    items: <String>[
                      for (final String value in const <String>[
                        'MAIS_RECENTES',
                        'MAIS_ANTIGAS',
                        'MAIOR_VALOR',
                        'MENOR_VALOR',
                      ])
                        _ordenacaoLabel(context, value),
                    ],
                    icon: Icons.swap_vert_rounded,
                    onSelected: (String selected) {
                      setState(() {
                        _ordenacao = _orderValueFromLabel(context, selected);
                      });
                      _onFiltroAlterado(salvarImediatamente: true);
                    },
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      if (_temFiltrosAtivos)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tokens.info,
                            backgroundColor: tokens.surfaceMuted.withValues(
                              alpha: 0.35,
                            ),
                            side: BorderSide(color: tokens.selectedBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _carregando ? null : _limparFiltros,
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: Text(
                            _text(
                              context,
                              'common.clear',
                              pt: 'Limpar',
                              en: 'Clear',
                              es: 'Limpiar',
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed:
                            _carregando ? null : () => _carregar(pagina: 0),
                        icon: const Icon(Icons.search_rounded),
                        label: Text(
                          _text(
                            context,
                            'sales.query.applyFilters',
                            pt: 'Aplicar filtros',
                            en: 'Apply filters',
                            es: 'Aplicar filtros',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultados(
    BuildContext context,
    WebThemeTokens tokens,
    LocaleSettingsProvider regionalizacao,
    bool compacto,
  ) {
    final ConsultaVendasResponse? resultado = _resultado;
    final ThemeData theme = Theme.of(context);

    return _SurfaceCard(
      tokens: tokens,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _text(
                          context,
                          'sales.query.results',
                          pt: 'Vendas encontradas',
                          en: 'Sales found',
                          es: 'Ventas encontradas',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _text(
                          context,
                          'sales.query.resultsHint',
                          pt:
                              'Selecione uma venda para visualizar itens, recebimentos, devoluções e histórico.',
                          en:
                              'Select a sale to view items, receipts, returns and history.',
                          es:
                              'Seleccione una venta para ver artículos, cobros, devoluciones e historial.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (resultado != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: Text(
                      '${resultado.totalElementos} ${_text(context, 'sales.query.records', pt: 'registros', en: 'records', es: 'registros')}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.secondaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.divider),
          if (_carregando && resultado != null)
            LinearProgressIndicator(
              minHeight: 2,
              color: tokens.info,
              backgroundColor: tokens.surfaceMuted,
            ),
          if (_carregando && resultado == null)
            Padding(
              padding: const EdgeInsets.all(18),
              child: SixBackendLoading(
                title: _text(
                  context,
                  'sales.query.loadingTitle',
                  pt: 'Carregando vendas',
                  en: 'Loading sales',
                  es: 'Cargando ventas',
                ),
                subtitle: _text(
                  context,
                  'sales.query.loadingSubtitle',
                  pt: 'Buscando os dados operacionais desta empresa.',
                  en: 'Fetching operational data for this business.',
                  es: 'Buscando los datos operativos de este comercio.',
                ),
                leadingIcon: Icons.receipt_long_outlined,
                animation: SixBackendLoadingAnimation.skeletonPulse,
                backgroundColor: tokens.cardBackground,
                borderColor: tokens.cardBorder,
              ),
            )
          else if (_erro != null && resultado == null)
            _ErroConsulta(tokens: tokens, mensagem: _erro!, onRetry: _carregar)
          else if (resultado == null || resultado.vendas.isEmpty)
            _EstadoVazioVendas(tokens: tokens)
          else if (compacto)
            _VendasCompactList(
              vendas: resultado.vendas,
              tokens: tokens,
              regionalizacao: regionalizacao,
              onTap: _abrirDetalhe,
            )
          else
            _VendasWideTable(
              vendas: resultado.vendas,
              tokens: tokens,
              regionalizacao: regionalizacao,
              onTap: _abrirDetalhe,
            ),
          if (_erro != null && resultado != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: _InlineError(tokens: tokens, mensagem: _erro!),
            ),
          if (resultado != null)
            _PaginationFooter(
              tokens: tokens,
              resultado: resultado,
              tamanhoPagina: _tamanhoPagina,
              carregando: _carregando,
              onPrevious:
                  resultado.paginaAtual > 0
                      ? () => _carregar(pagina: resultado.paginaAtual - 1)
                      : null,
              onNext:
                  resultado.paginaAtual + 1 < resultado.totalPaginas
                      ? () => _carregar(pagina: resultado.paginaAtual + 1)
                      : null,
              onPageSizeChanged: (int value) {
                setState(() => _tamanhoPagina = value);
                _onFiltroAlterado(salvarImediatamente: true);
                _carregar(pagina: 0);
              },
            ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.tokens,
    required this.child,
    required this.padding,
  });

  final WebThemeTokens tokens;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: child,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final WebThemeTokens tokens;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 212,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.12),
                tokens.surfaceMuted,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
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

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.tokens,
    required this.width,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final WebThemeTokens tokens;
  final double width;
  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          side: BorderSide(color: tokens.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            Icon(Icons.calendar_today_outlined, size: 18, color: tokens.info),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendasWideTable extends StatelessWidget {
  const _VendasWideTable({
    required this.vendas,
    required this.tokens,
    required this.regionalizacao,
    required this.onTap,
  });

  final List<VendaConsultaResumo> vendas;
  final WebThemeTokens tokens;
  final LocaleSettingsProvider regionalizacao;
  final ValueChanged<VendaConsultaResumo> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          color: tokens.surfaceMuted,
          child: Row(
            children: <Widget>[
              _TableHeaderCell(
                label: _t(context, 'Venda', 'Sale', 'Venta'),
                flex: 2,
              ),
              _TableHeaderCell(
                label: _t(context, 'Data', 'Date', 'Fecha'),
                flex: 2,
              ),
              _TableHeaderCell(
                label: _t(context, 'Cliente', 'Customer', 'Cliente'),
                flex: 4,
              ),
              _TableHeaderCell(
                label: _t(context, 'Vendedor', 'Seller', 'Vendedor'),
                flex: 3,
              ),
              _TableHeaderCell(
                label: _t(context, 'Financeiro', 'Financial', 'Financiero'),
                flex: 2,
              ),
              _TableHeaderCell(
                label: _t(context, 'Devolução', 'Return', 'Devolución'),
                flex: 2,
              ),
              _TableHeaderCell(
                label: _t(context, 'Total', 'Total', 'Total'),
                flex: 2,
                alignEnd: true,
              ),
              const SizedBox(width: 38),
            ],
          ),
        ),
        for (int index = 0; index < vendas.length; index++) ...<Widget>[
          _VendaWideRow(
            venda: vendas[index],
            tokens: tokens,
            regionalizacao: regionalizacao,
            onTap: () => onTap(vendas[index]),
          ),
          if (index + 1 < vendas.length)
            Divider(height: 1, color: tokens.divider),
        ],
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({
    required this.label,
    required this.flex,
    this.alignEnd = false,
  });

  final String label;
  final int flex;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: tokens.mutedText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _VendaWideRow extends StatelessWidget {
  const _VendaWideRow({
    required this.venda,
    required this.tokens,
    required this.regionalizacao,
    required this.onTap,
  });

  final VendaConsultaResumo venda;
  final WebThemeTokens tokens;
  final LocaleSettingsProvider regionalizacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: tokens.hoverBackground,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      venda.identificadorPreferencial,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${venda.quantidadeLinhas} ${_t(context, 'linhas', 'lines', 'líneas')} · ${_formatQuantity(venda.quantidadeItens)} ${_t(context, 'itens', 'items', 'artículos')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatDateTime(regionalizacao, venda.dataOperacao),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _fallback(
                        venda.nomeCliente,
                        _t(
                          context,
                          'Cliente não identificado',
                          'Unidentified customer',
                          'Cliente no identificado',
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (venda.documentoCliente.trim().isNotEmpty)
                      Text(
                        venda.documentoCliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.mutedText,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _fallback(
                    venda.nomeColaborador,
                    _t(context, 'Sistema', 'System', 'Sistema'),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusChip(
                    label: _statusFinanceiroLabel(
                      context,
                      venda.statusFinanceiro,
                    ),
                    color: _financialStatusColor(
                      tokens,
                      venda.statusFinanceiro,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusChip(
                    label: _statusDevolucaoLabel(
                      context,
                      venda.statusDevolucao,
                    ),
                    color: _returnStatusColor(tokens, venda.statusDevolucao),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    regionalizacao.formatCurrency(venda.valorTotal),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 38,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendasCompactList extends StatelessWidget {
  const _VendasCompactList({
    required this.vendas,
    required this.tokens,
    required this.regionalizacao,
    required this.onTap,
  });

  final List<VendaConsultaResumo> vendas;
  final WebThemeTokens tokens;
  final LocaleSettingsProvider regionalizacao;
  final ValueChanged<VendaConsultaResumo> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vendas.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: tokens.divider),
      itemBuilder: (BuildContext context, int index) {
        final VendaConsultaResumo venda = vendas[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(venda),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          venda.identificadorPreferencial,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: tokens.primaryText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        regionalizacao.formatCurrency(venda.valorTotal),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _fallback(
                      venda.nomeCliente,
                      _t(
                        context,
                        'Cliente não identificado',
                        'Unidentified customer',
                        'Cliente no identificado',
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 7,
                    children: <Widget>[
                      _MetaChip(
                        icon: Icons.schedule_outlined,
                        label: _formatDateTime(
                          regionalizacao,
                          venda.dataOperacao,
                        ),
                        tokens: tokens,
                      ),
                      _MetaChip(
                        icon: Icons.person_outline,
                        label: _fallback(
                          venda.nomeColaborador,
                          _t(context, 'Sistema', 'System', 'Sistema'),
                        ),
                        tokens: tokens,
                      ),
                      _StatusChip(
                        label: _statusFinanceiroLabel(
                          context,
                          venda.statusFinanceiro,
                        ),
                        color: _financialStatusColor(
                          tokens,
                          venda.statusFinanceiro,
                        ),
                      ),
                      _StatusChip(
                        label: _statusDevolucaoLabel(
                          context,
                          venda.statusDevolucao,
                        ),
                        color: _returnStatusColor(
                          tokens,
                          venda.statusDevolucao,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: tokens.mutedText),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.tokens,
    required this.resultado,
    required this.tamanhoPagina,
    required this.carregando,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSizeChanged,
  });

  final WebThemeTokens tokens;
  final ConsultaVendasResponse resultado;
  final int tamanhoPagina;
  final bool carregando;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            '${_t(context, 'Página', 'Page', 'Página')} ${resultado.paginaAtual + 1} ${_t(context, 'de', 'of', 'de')} ${resultado.totalPaginas == 0 ? 1 : resultado.totalPaginas}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tokens.secondaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _t(context, 'Por página', 'Per page', 'Por página'),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: tokens.secondaryText),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: tamanhoPagina,
                underline: const SizedBox.shrink(),
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(value: 25, child: Text('25')),
                  DropdownMenuItem<int>(value: 50, child: Text('50')),
                  DropdownMenuItem<int>(value: 100, child: Text('100')),
                ],
                onChanged:
                    carregando
                        ? null
                        : (int? value) {
                          if (value != null) onPageSizeChanged(value);
                        },
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _t(
                  context,
                  'Página anterior',
                  'Previous page',
                  'Página anterior',
                ),
                onPressed: carregando ? null : onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: _t(
                  context,
                  'Próxima página',
                  'Next page',
                  'Página siguiente',
                ),
                onPressed: carregando ? null : onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoVazioVendas extends StatelessWidget {
  const _EstadoVazioVendas({required this.tokens});

  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: tokens.mutedText,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _t(
              context,
              'Nenhuma venda encontrada',
              'No sales found',
              'No se encontraron ventas',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _t(
              context,
              'Ajuste o período ou remova alguns filtros para ampliar a consulta.',
              'Adjust the period or remove some filters to broaden the search.',
              'Ajuste el período o elimine algunos filtros para ampliar la consulta.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _ErroConsulta extends StatelessWidget {
  const _ErroConsulta({
    required this.tokens,
    required this.mensagem,
    required this.onRetry,
  });

  final WebThemeTokens tokens;
  final String mensagem;
  final Future<void> Function({int? pagina}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger, size: 38),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              _t(context, 'Tentar novamente', 'Try again', 'Intentar de nuevo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.tokens, required this.mensagem});

  final WebThemeTokens tokens;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              mensagem,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendaDetalheDialog extends StatefulWidget {
  const _VendaDetalheDialog({
    required this.api,
    required this.identificador,
    required this.onAbrirDevolucoes,
  });

  final ConsultaVendasApiClient api;
  final String identificador;
  final ValueChanged<String> onAbrirDevolucoes;

  @override
  State<_VendaDetalheDialog> createState() => _VendaDetalheDialogState();
}

class _VendaDetalheDialogState extends State<_VendaDetalheDialog> {
  VendaDetalheResponse? _detalhe;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _detalhe = null;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Size size = MediaQuery.sizeOf(context);
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (DismissIntent intent) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Semantics(
            namesRoute: true,
            label: _t(
              context,
              'Detalhes da venda',
              'Sale details',
              'Detalles de la venta',
            ),
            child: Dialog(
              insetPadding: const EdgeInsets.all(24),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1120,
                  maxHeight: size.height * 0.90,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: tokens.cardBorder.withValues(alpha: 0.85),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.38),
                        blurRadius: 42,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: tokens.surfaceElevated,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Theme.of(context).colorScheme.secondary,
                                  tokens.info.withValues(alpha: 0.92),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 22, 18, 18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: tokens.selectedBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: tokens.selectedBorder,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    color: tokens.info,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _t(
                                          context,
                                          'Detalhes da venda',
                                          'Sale details',
                                          'Detalles de la venta',
                                        ),
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: tokens.primaryText,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.identificador,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: tokens.mutedText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: tokens.surfaceMuted,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: tokens.cardBorder,
                                    ),
                                  ),
                                  child: IconButton(
                                    tooltip: _t(
                                      context,
                                      'Fechar',
                                      'Close',
                                      'Cerrar',
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).maybePop(),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: tokens.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: tokens.divider),
                          Expanded(child: _buildConteudo(context, tokens)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo(BuildContext context, WebThemeTokens tokens) {
    final VendaDetalheResponse? detalhe = _detalhe;
    if (_erro != null) {
      return Center(
        child: _ErroConsulta(
          tokens: tokens,
          mensagem: _erro!,
          onRetry: ({int? pagina}) => _carregar(),
        ),
      );
    }
    if (detalhe == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SixBackendLoading(
          title: _t(
            context,
            'Carregando detalhes',
            'Loading details',
            'Cargando detalles',
          ),
          subtitle: _t(
            context,
            'Reunindo itens, recebimentos, devoluções e histórico.',
            'Gathering items, receipts, returns and history.',
            'Reuniendo artículos, cobros, devoluciones e historial.',
          ),
          leadingIcon: Icons.manage_search_rounded,
          backgroundColor: tokens.cardBackground,
          borderColor: tokens.cardBorder,
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          _DetalheResumoHeader(
            detalhe: detalhe,
            tokens: tokens,
            onAbrirDevolucoes:
                detalhe.resumo.permiteDevolucao
                    ? () {
                      Navigator.of(context).pop();
                      widget.onAbrirDevolucoes(detalhe.resumo.idOperacao);
                    }
                    : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: tokens.primaryText,
                  unselectedLabelColor: tokens.secondaryText,
                  labelStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                  unselectedLabelStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  splashFactory: NoSplash.splashFactory,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  indicator: BoxDecoration(
                    color: tokens.selectedBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.selectedBorder),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  tabs: <Widget>[
                    Tab(text: _t(context, 'Itens', 'Items', 'Artículos')),
                    Tab(
                      text: _t(context, 'Recebimentos', 'Receipts', 'Cobros'),
                    ),
                    Tab(
                      text: _t(
                        context,
                        'Devoluções e trocas',
                        'Returns and exchanges',
                        'Devoluciones y cambios',
                      ),
                    ),
                    Tab(text: _t(context, 'Histórico', 'History', 'Historial')),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _ItensDetalheTab(detalhe: detalhe, tokens: tokens),
                _RecebimentosDetalheTab(detalhe: detalhe, tokens: tokens),
                _DevolucoesDetalheTab(detalhe: detalhe, tokens: tokens),
                _HistoricoDetalheTab(detalhe: detalhe, tokens: tokens),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VendaDetalheRouteSurface extends StatelessWidget {
  const _VendaDetalheRouteSurface({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (BuildContext context, Widget? dialogChild) {
          final double progress = curved.value;
          final Color tint =
              Color.lerp(
                Colors.transparent,
                const Color(0xC40A1324),
                progress,
              )!;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: 12 * progress,
                      sigmaY: 12 * progress,
                    ),
                    child: ColoredBox(color: tint),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, (1 - progress) * 24),
                        child: Transform.scale(
                          scale: 0.96 + (0.04 * progress),
                          child: dialogChild,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetalheResumoHeader extends StatelessWidget {
  const _DetalheResumoHeader({
    required this.detalhe,
    required this.tokens,
    required this.onAbrirDevolucoes,
  });

  final VendaDetalheResponse detalhe;
  final WebThemeTokens tokens;
  final VoidCallback? onAbrirDevolucoes;

  Future<void> _copiarNumeroDaVenda(BuildContext context, String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!context.mounted) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          _t(
            context,
            'Número da venda copiado.',
            'Sale number copied.',
            'Número de venta copiado.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    final VendaConsultaResumo venda = detalhe.resumo;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 900;
            final double metricsWidth =
                compact
                    ? constraints.maxWidth
                    : constraints.maxWidth -
                        (onAbrirDevolucoes != null ? 210 : 0);
            final double blockWidth =
                metricsWidth > 980
                    ? (metricsWidth - 36) / 4
                    : metricsWidth > 700
                    ? (metricsWidth - 24) / 3
                    : metricsWidth > 420
                    ? (metricsWidth - 12) / 2
                    : metricsWidth;

            final Widget metricsSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _t(
                            context,
                            'Número da venda',
                            'Sale number',
                            'Número de venta',
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: tokens.secondaryText,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    compact ? constraints.maxWidth - 96 : 320,
                              ),
                              child: Text(
                                venda.identificadorPreferencial,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: tokens.primaryText,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: _t(
                                context,
                                'Copiar número da venda',
                                'Copy sale number',
                                'Copiar número de venta',
                              ),
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                splashRadius: 18,
                                onPressed:
                                    () => _copiarNumeroDaVenda(
                                      context,
                                      venda.identificadorPreferencial,
                                    ),
                                icon: Icon(
                                  Icons.content_copy_rounded,
                                  size: 18,
                                  color: tokens.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _StatusChip(
                      label: _statusFinanceiroLabel(
                        context,
                        venda.statusFinanceiro,
                      ),
                      color: _financialStatusColor(
                        tokens,
                        venda.statusFinanceiro,
                      ),
                    ),
                    _StatusChip(
                      label: _statusDevolucaoLabel(
                        context,
                        venda.statusDevolucao,
                      ),
                      color: _returnStatusColor(tokens, venda.statusDevolucao),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _fallback(
                    detalhe.descricao,
                    _t(
                      context,
                      'Venda registrada no sistema',
                      'Sale recorded in the system',
                      'Venta registrada en el sistema',
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: <Widget>[
                    _DetailInfoLine(
                      width: blockWidth,
                      label: _t(context, 'Data', 'Date', 'Fecha'),
                      value: _formatDateTime(
                        regionalizacao,
                        venda.dataOperacao,
                      ),
                    ),
                    _DetailInfoLine(
                      width: blockWidth,
                      label: _t(context, 'Cliente', 'Customer', 'Cliente'),
                      value: _fallback(
                        venda.nomeCliente,
                        _t(
                          context,
                          'Não identificado',
                          'Unidentified',
                          'No identificado',
                        ),
                      ),
                    ),
                    _DetailInfoLine(
                      width: blockWidth,
                      label: _t(context, 'Vendedor', 'Seller', 'Vendedor'),
                      value: _fallback(
                        venda.nomeColaborador,
                        _t(context, 'Sistema', 'System', 'Sistema'),
                      ),
                    ),
                    _DetailInfoLine(
                      width: blockWidth,
                      label: _t(context, 'Total', 'Total', 'Total'),
                      numericValue: venda.valorTotal,
                      valueFormatter: regionalizacao.formatCurrency,
                      emphasize: true,
                    ),
                    _DetailInfoLine(
                      width: blockWidth,
                      label: _t(context, 'Recebido', 'Received', 'Recibido'),
                      numericValue: venda.valorRecebido,
                      valueFormatter: regionalizacao.formatCurrency,
                    ),
                    _DetailInfoLine(
                      width: blockWidth,
                      label: _t(context, 'Em aberto', 'Open', 'Abierto'),
                      numericValue: venda.valorEmAberto,
                      valueFormatter: regionalizacao.formatCurrency,
                    ),
                    _DetailInfoLine(
                      width: blockWidth,
                      label: _t(context, 'Devolvido', 'Returned', 'Devuelto'),
                      numericValue: venda.valorDevolvido,
                      valueFormatter: regionalizacao.formatCurrency,
                    ),
                  ],
                ),
              ],
            );

            if (onAbrirDevolucoes == null) {
              return metricsSection;
            }

            final Widget actionButton = FilledButton.icon(
              onPressed: onAbrirDevolucoes,
              icon: const Icon(Icons.assignment_return_outlined, size: 18),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              label: Text(
                _t(
                  context,
                  'Devolver ou trocar',
                  'Return or exchange',
                  'Devolver o cambiar',
                ),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  metricsSection,
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerRight, child: actionButton),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: metricsSection),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: actionButton,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailInfoLine extends StatelessWidget {
  const _DetailInfoLine({
    required this.width,
    required this.label,
    this.value,
    this.numericValue,
    this.valueFormatter,
    this.emphasize = false,
  }) : assert(
         value != null || (numericValue != null && valueFormatter != null),
         'Provide value or numericValue + valueFormatter.',
       );

  final double width;
  final String label;
  final String? value;
  final double? numericValue;
  final String Function(num value)? valueFormatter;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            DefaultTextStyle(
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
                    fontSize: emphasize ? 17 : 14,
                    height: 1.2,
                  ) ??
                  const TextStyle(),
              child:
                  numericValue != null && valueFormatter != null
                      ? _AnimatedNumericDetailValue(
                        key: ValueKey<String>('$label-$numericValue'),
                        value: numericValue!,
                        formatter: valueFormatter!,
                      )
                      : Text(
                        value!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNumericDetailValue extends StatelessWidget {
  const _AnimatedNumericDetailValue({
    super.key,
    required this.value,
    required this.formatter,
  });

  final double value;
  final String Function(num value) formatter;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: Duration(milliseconds: reduceMotion ? 1 : 700),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return Text(
          formatter(animatedValue),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _ItensDetalheTab extends StatelessWidget {
  const _ItensDetalheTab({required this.detalhe, required this.tokens});

  final VendaDetalheResponse detalhe;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    if (detalhe.itens.isEmpty) {
      return _EmptyDetailTab(
        tokens: tokens,
        message: _t(
          context,
          'Nenhum item encontrado nesta venda.',
          'No items found for this sale.',
          'No se encontraron artículos en esta venta.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: detalhe.itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final ItemVendaDetalhe item = detalhe.itens[index];
        return _DetailListCard(
          tokens: tokens,
          title: _fallback(item.nomeProduto, item.idProduto),
          subtitle: item.codigoProduto,
          trailing: regionalizacao.formatCurrency(item.valorTotal),
          children: <Widget>[
            _DetailMiniMetric(
              label: _t(context, 'Quantidade', 'Quantity', 'Cantidad'),
              value: _formatQuantity(item.quantidade),
            ),
            _DetailMiniMetric(
              label: _t(
                context,
                'Valor unitário',
                'Unit price',
                'Valor unitario',
              ),
              value: regionalizacao.formatCurrency(item.valorUnitario),
            ),
            _DetailMiniMetric(
              label: _t(
                context,
                'Já devolvida',
                'Already returned',
                'Ya devuelta',
              ),
              value: _formatQuantity(item.quantidadeDevolvida),
            ),
            _DetailMiniMetric(
              label: _t(
                context,
                'Ainda devolvível',
                'Still returnable',
                'Aún devolvible',
              ),
              value: _formatQuantity(item.quantidadeDisponivel),
            ),
          ],
        );
      },
    );
  }
}

class _RecebimentosDetalheTab extends StatelessWidget {
  const _RecebimentosDetalheTab({required this.detalhe, required this.tokens});

  final VendaDetalheResponse detalhe;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    if (detalhe.recebimentos.isEmpty) {
      return _EmptyDetailTab(
        tokens: tokens,
        message: _t(
          context,
          'Nenhum recebimento registrado.',
          'No receipts recorded.',
          'No hay cobros registrados.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: detalhe.recebimentos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final RecebimentoVendaDetalhe recebimento = detalhe.recebimentos[index];
        return _DetailListCard(
          tokens: tokens,
          title: _fallback(
            recebimento.descricaoTipoRecebimento,
            recebimento.codigoTipoRecebimento,
          ),
          subtitle: _formatDateTime(regionalizacao, recebimento.dataHora),
          trailing: regionalizacao.formatCurrency(recebimento.valorRecebido),
          children: <Widget>[
            _DetailMiniMetric(
              label: _t(context, 'Origem', 'Source', 'Origen'),
              value: recebimento.origem,
              color: tokens.info,
            ),
            _DetailMiniMetric(
              label: _t(context, 'Status', 'Status', 'Estado'),
              value: recebimento.status,
              color: _recebimentoStatusColor(tokens, recebimento.status),
            ),
            _DetailMiniMetric(
              label: _t(
                context,
                'Valor original',
                'Original amount',
                'Valor original',
              ),
              value: regionalizacao.formatCurrency(recebimento.valorOriginal),
              color: tokens.warning,
            ),
            _DetailMiniMetric(
              label: _t(context, 'Saldo', 'Balance', 'Saldo'),
              value: regionalizacao.formatCurrency(recebimento.valorEmAberto),
              color: _recebimentoSaldoColor(tokens, recebimento.valorEmAberto),
            ),
            _DetailMiniMetric(
              label: _t(context, 'Colaborador', 'Employee', 'Colaborador'),
              value: _fallback(
                recebimento.nomeColaborador,
                recebimento.idColaborador,
              ),
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        );
      },
    );
  }
}

class _DevolucoesDetalheTab extends StatelessWidget {
  const _DevolucoesDetalheTab({required this.detalhe, required this.tokens});

  final VendaDetalheResponse detalhe;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    if (detalhe.devolucoes.isEmpty) {
      return _EmptyDetailTab(
        tokens: tokens,
        message: _t(
          context,
          'Esta venda ainda não possui devoluções ou trocas.',
          'This sale has no returns or exchanges yet.',
          'Esta venta aún no tiene devoluciones o cambios.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: detalhe.devolucoes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final DevolucaoVendaDetalhe devolucao = detalhe.devolucoes[index];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: tokens.cardBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _fallback(
                        devolucao.codigoDevolucao,
                        devolucao.idDevolucao,
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusChip(label: devolucao.tipo, color: tokens.info),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${_formatDateTime(regionalizacao, devolucao.dataHora)} · ${_fallback(devolucao.nomeColaborador, devolucao.idColaborador)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: <Widget>[
                  _DetailMiniMetric(
                    label: _t(
                      context,
                      'Total devolvido',
                      'Returned total',
                      'Total devuelto',
                    ),
                    value: regionalizacao.formatCurrency(
                      devolucao.valorTotalDevolvido,
                    ),
                  ),
                  _DetailMiniMetric(
                    label: _t(
                      context,
                      'Total da troca',
                      'Exchange total',
                      'Total del cambio',
                    ),
                    value: regionalizacao.formatCurrency(
                      devolucao.valorTotalTroca,
                    ),
                  ),
                  _DetailMiniMetric(
                    label: _t(context, 'Diferença', 'Difference', 'Diferencia'),
                    value: regionalizacao.formatCurrency(
                      devolucao.saldoFinanceiro,
                    ),
                  ),
                ],
              ),
              if (devolucao.itensDevolvidos.isNotEmpty) ...<Widget>[
                const SizedBox(height: 13),
                Text(
                  _t(
                    context,
                    'Produtos devolvidos',
                    'Returned products',
                    'Productos devueltos',
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                for (final ItemDevolucaoDetalhe item
                    in devolucao.itensDevolvidos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '• ${item.nomeProduto} · ${_formatQuantity(item.quantidade)} · ${item.condicao}${item.retornouAoEstoque ? ' · ${_t(context, 'retornou ao estoque', 'returned to stock', 'volvió al stock')}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ),
              ],
              if (devolucao.itensTroca.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _t(
                    context,
                    'Produtos entregues na troca',
                    'Products delivered in exchange',
                    'Productos entregados en el cambio',
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                for (final ItemTrocaDetalhe item in devolucao.itensTroca)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '• ${item.nomeProduto} · ${_formatQuantity(item.quantidade)} · ${regionalizacao.formatCurrency(item.valorTotal)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HistoricoDetalheTab extends StatelessWidget {
  const _HistoricoDetalheTab({required this.detalhe, required this.tokens});

  final VendaDetalheResponse detalhe;
  final WebThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    if (detalhe.historico.isEmpty) {
      return _EmptyDetailTab(
        tokens: tokens,
        message: _t(
          context,
          'Nenhum evento adicional encontrado.',
          'No additional events found.',
          'No se encontraron eventos adicionales.',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: detalhe.historico.length,
      itemBuilder: (BuildContext context, int index) {
        final EventoVendaDetalhe evento = detalhe.historico[index];
        final bool last = index == detalhe.historico.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 28,
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: tokens.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!last)
                      Expanded(
                        child: Container(width: 2, color: tokens.divider),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        evento.tipo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatDateTime(regionalizacao, evento.dataHora)}${evento.referencia.trim().isNotEmpty ? ' · ${evento.referencia}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.secondaryText,
                        ),
                      ),
                      if (evento.valor.abs() > 0.0001)
                        Text(
                          regionalizacao.formatCurrency(evento.valor),
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(
                            color:
                                evento.valor < 0
                                    ? tokens.financialNegative
                                    : tokens.financialPositive,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailListCard extends StatelessWidget {
  const _DetailListCard({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.children,
  });

  final WebThemeTokens tokens;
  final String title;
  final String subtitle;
  final String trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
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
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                trailing,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(spacing: 10, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _DetailMiniMetric extends StatelessWidget {
  const _DetailMiniMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = color ?? tokens.cardBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            color == null
                ? tokens.surfaceMuted
                : Color.alphaBlend(
                  accent.withValues(alpha: 0.12),
                  tokens.surfaceMuted,
                ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              color == null
                  ? tokens.cardBorder
                  : accent.withValues(alpha: 0.38),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color == null ? tokens.secondaryText : accent,
            fontWeight: FontWeight.w700,
          ),
          children: <InlineSpan>[
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetailTab extends StatelessWidget {
  const _EmptyDetailTab({required this.tokens, required this.message});

  final WebThemeTokens tokens;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _text(
  BuildContext context,
  String key, {
  required String pt,
  String? en,
  String? es,
}) {
  final String language = Localizations.localeOf(context).languageCode;
  final String fallback = switch (language) {
    'en' => en ?? pt,
    'es' => es ?? pt,
    _ => pt,
  };
  return context.t(key, fallback: fallback);
}

String _t(BuildContext context, String pt, String en, String es) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
}

String _periodoFiltroItemLabel(BuildContext context, String periodo) {
  switch (periodo) {
    case _ConsultaVendasWebPageState._periodoHoje:
      return _t(context, 'Hoje', 'Today', 'Hoy');
    case _ConsultaVendasWebPageState._periodoUltimos7Dias:
      return _t(context, 'Últimos 7 dias', 'Last 7 days', 'Últimos 7 días');
    case _ConsultaVendasWebPageState._periodoEsteMes:
      return _t(context, 'Este mês', 'This month', 'Este mes');
    case _ConsultaVendasWebPageState._periodoMesPassado:
      return _t(context, 'Mês passado', 'Last month', 'Mes pasado');
    case _ConsultaVendasWebPageState._periodoIntervaloPersonalizado:
      return _t(
        context,
        'Intervalo personalizado',
        'Custom range',
        'Intervalo personalizado',
      );
    case _ConsultaVendasWebPageState._periodoUltimos30Dias:
    default:
      return _t(context, 'Últimos 30 dias', 'Last 30 days', 'Últimos 30 días');
  }
}

String _periodoFiltroLabel(
  BuildContext context,
  LocaleSettingsProvider regionalizacao,
  String periodoSelecionado,
  DateTime dataInicial,
  DateTime dataFinal,
) {
  if (periodoSelecionado ==
      _ConsultaVendasWebPageState._periodoIntervaloPersonalizado) {
    return '${regionalizacao.formatDate(dataInicial)} - ${regionalizacao.formatDate(dataFinal)}';
  }
  return _periodoFiltroItemLabel(context, periodoSelecionado);
}

String _periodoValueFromLabel(BuildContext context, String label) {
  for (final String value in _ConsultaVendasWebPageState._periodosFiltroData) {
    if (_periodoFiltroItemLabel(context, value) == label) {
      return value;
    }
  }
  return _ConsultaVendasWebPageState._periodoUltimos30Dias;
}

String _periodoLabelPreferencia(ConsultaVendasPeriodoWebPreferencia periodo) {
  switch (periodo) {
    case ConsultaVendasPeriodoWebPreferencia.hoje:
      return _ConsultaVendasWebPageState._periodoHoje;
    case ConsultaVendasPeriodoWebPreferencia.ultimos7Dias:
      return _ConsultaVendasWebPageState._periodoUltimos7Dias;
    case ConsultaVendasPeriodoWebPreferencia.esteMes:
      return _ConsultaVendasWebPageState._periodoEsteMes;
    case ConsultaVendasPeriodoWebPreferencia.mesPassado:
      return _ConsultaVendasWebPageState._periodoMesPassado;
    case ConsultaVendasPeriodoWebPreferencia.personalizado:
      return _ConsultaVendasWebPageState._periodoIntervaloPersonalizado;
    case ConsultaVendasPeriodoWebPreferencia.ultimos30Dias:
      return _ConsultaVendasWebPageState._periodoUltimos30Dias;
  }
}

ConsultaVendasPeriodoWebPreferencia _periodoPreferenciaAtual(String periodo) {
  switch (periodo) {
    case _ConsultaVendasWebPageState._periodoHoje:
      return ConsultaVendasPeriodoWebPreferencia.hoje;
    case _ConsultaVendasWebPageState._periodoUltimos7Dias:
      return ConsultaVendasPeriodoWebPreferencia.ultimos7Dias;
    case _ConsultaVendasWebPageState._periodoEsteMes:
      return ConsultaVendasPeriodoWebPreferencia.esteMes;
    case _ConsultaVendasWebPageState._periodoMesPassado:
      return ConsultaVendasPeriodoWebPreferencia.mesPassado;
    case _ConsultaVendasWebPageState._periodoIntervaloPersonalizado:
      return ConsultaVendasPeriodoWebPreferencia.personalizado;
    case _ConsultaVendasWebPageState._periodoUltimos30Dias:
    default:
      return ConsultaVendasPeriodoWebPreferencia.ultimos30Dias;
  }
}

String _allLabel(BuildContext context) {
  return _text(context, 'common.all', pt: 'Todas', en: 'All', es: 'Todas');
}

String _statusFinanceiroLabel(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'QUITADA' => _t(context, 'Quitada', 'Paid', 'Pagada'),
    'PARCIAL' => _t(context, 'Parcial', 'Partial', 'Parcial'),
    'EM_ABERTO' => _t(context, 'Em aberto', 'Open', 'Abierta'),
    'CANCELADA' => _t(context, 'Cancelada', 'Cancelled', 'Cancelada'),
    _ => _t(context, 'Não informada', 'Not informed', 'No informada'),
  };
}

String? _financialStatusValueFromLabel(BuildContext context, String label) {
  if (label == _allLabel(context)) {
    return null;
  }
  for (final String value in const <String>[
    'QUITADA',
    'PARCIAL',
    'EM_ABERTO',
    'CANCELADA',
  ]) {
    if (_statusFinanceiroLabel(context, value) == label) {
      return value;
    }
  }
  return null;
}

String _statusDevolucaoLabel(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'SEM_DEVOLUCAO' => _t(
      context,
      'Sem devolução',
      'No return',
      'Sin devolución',
    ),
    'PARCIAL' => _t(
      context,
      'Devolução parcial',
      'Partial return',
      'Devolución parcial',
    ),
    'TOTAL' => _t(
      context,
      'Totalmente devolvida',
      'Fully returned',
      'Totalmente devuelta',
    ),
    _ => _t(context, 'Não informada', 'Not informed', 'No informada'),
  };
}

String? _returnStatusValueFromLabel(BuildContext context, String label) {
  if (label == _allLabel(context)) {
    return null;
  }
  for (final String value in const <String>[
    'SEM_DEVOLUCAO',
    'PARCIAL',
    'TOTAL',
  ]) {
    if (_statusDevolucaoLabel(context, value) == label) {
      return value;
    }
  }
  return null;
}

String _ordenacaoLabel(BuildContext context, String value) {
  return switch (value) {
    'MAIS_ANTIGAS' => _t(
      context,
      'Mais antigas',
      'Oldest first',
      'Más antiguas',
    ),
    'MAIOR_VALOR' => _t(
      context,
      'Maior valor',
      'Highest amount',
      'Mayor valor',
    ),
    'MENOR_VALOR' => _t(context, 'Menor valor', 'Lowest amount', 'Menor valor'),
    _ => _t(context, 'Mais recentes', 'Most recent', 'Más recientes'),
  };
}

String _orderValueFromLabel(BuildContext context, String label) {
  for (final String value in const <String>[
    'MAIS_RECENTES',
    'MAIS_ANTIGAS',
    'MAIOR_VALOR',
    'MENOR_VALOR',
  ]) {
    if (_ordenacaoLabel(context, value) == label) {
      return value;
    }
  }
  return 'MAIS_RECENTES';
}

Color _recebimentoStatusColor(WebThemeTokens tokens, String status) {
  return switch (status.trim().toUpperCase()) {
    'CONCLUIDA' || 'CONCLUÍDA' || 'RECEBIDO' || 'PAGO' => tokens.success,
    'PENDENTE' || 'EM_ABERTO' || 'ABERTO' => tokens.warning,
    'CANCELADA' || 'FALHOU' || 'RECUSADO' => tokens.danger,
    _ => tokens.info,
  };
}

Color _recebimentoSaldoColor(WebThemeTokens tokens, num saldo) {
  if (saldo.abs() < 0.0001) {
    return tokens.success;
  }
  return saldo > 0 ? tokens.warning : tokens.info;
}

Color _financialStatusColor(WebThemeTokens tokens, String status) {
  return switch (status.trim().toUpperCase()) {
    'QUITADA' => tokens.success,
    'PARCIAL' => tokens.warning,
    'EM_ABERTO' => tokens.info,
    'CANCELADA' => tokens.danger,
    _ => tokens.statusNeutral,
  };
}

Color _returnStatusColor(WebThemeTokens tokens, String status) {
  return switch (status.trim().toUpperCase()) {
    'PARCIAL' => tokens.warning,
    'TOTAL' => tokens.danger,
    _ => tokens.statusNeutral,
  };
}

String _formatDateTime(LocaleSettingsProvider regionalizacao, DateTime? value) {
  if (value == null) return '-';
  return '${regionalizacao.formatDate(value)} ${regionalizacao.formatTime(value)}';
}

String _formatQuantity(double value) {
  if ((value - value.roundToDouble()).abs() < 0.000001) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

String _fallback(String value, String fallback) {
  return value.trim().isEmpty ? fallback : value.trim();
}

double? _parseNumero(String value) {
  String normalized = value.trim();
  if (normalized.isEmpty) return null;
  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else {
    normalized = normalized.replaceAll(',', '.');
  }
  return double.tryParse(normalized);
}

String _mensagemErro(Object error) {
  if (error is ConsultaVendasApiException) return error.mensagem;
  return error.toString().replaceFirst('Exception: ', '');
}
