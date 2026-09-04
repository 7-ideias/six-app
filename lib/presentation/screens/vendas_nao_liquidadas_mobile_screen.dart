import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/agenda_financeira_acoes_financeiras.dart';
import '../../data/models/agenda_financeira_lancamento_model.dart';
import '../../data/models/caixa_models.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/venda_nao_liquidada_models.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../data/services/caixa/venda_nao_liquidada_api_client.dart';
import '../../data/services/desempenho_colaborador/desempenho_colaborador_api_client.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile/six_mobile_recebimento_bottom_sheet.dart';
import '../components/mobile/six_mobile_selection_sheet.dart';
import '../components/mobile/sixoapp_mobile_loading_scene.dart';
import '../components/mobile_motion.dart';

class VendasNaoLiquidadasMobileScreen extends StatefulWidget {
  const VendasNaoLiquidadasMobileScreen({
    super.key,
    this.apiClient,
    this.acoesFinanceiras,
    this.caixaApiClient,
    this.vendedoresLoader,
    this.habilitarPersistenciaPreferencias = true,
  });

  final VendaNaoLiquidadaApiClient? apiClient;
  final AgendaFinanceiraAcoesFinanceiras? acoesFinanceiras;
  final CaixaApiClient? caixaApiClient;
  final Future<List<ColaboradorUsuarioResumo>> Function()? vendedoresLoader;
  final bool habilitarPersistenciaPreferencias;

  @override
  State<VendasNaoLiquidadasMobileScreen> createState() =>
      _VendasNaoLiquidadasMobileScreenState();
}

class _VendasNaoLiquidadasMobileScreenState
    extends State<VendasNaoLiquidadasMobileScreen> {
  static const Duration _stateTransitionDuration = Duration(milliseconds: 240);
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
    'EM_ABERTO',
    'PARCIAL',
  ];
  static const List<String> _ordenacoes = <String>[
    'MAIS_RECENTES',
    'MAIS_ANTIGAS',
    'MAIOR_VALOR',
    'MENOR_VALOR',
  ];

  late final VendaNaoLiquidadaApiClient _api;
  late final AgendaFinanceiraAcoesFinanceiras _acoesFinanceiras;
  late final CaixaApiClient _caixaApiClient;
  late final Future<List<ColaboradorUsuarioResumo>> Function()
  _vendedoresLoader;
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final TextEditingController _buscaController = TextEditingController();

  SixMobileColorScheme get _colors => context.sixMobileColors;
  Color get _backgroundColor => _colors.background;
  Color get _primaryColor => _colors.primary;
  Color get _secondaryColor => _colors.secondary;
  Color get _accentColor => _colors.accent;
  Color get _surfaceColor => _colors.surface;
  Color get _mutedTextColor => _colors.mutedText;
  Color get _titleTextColor => _colors.titleText;
  Color get _softAccentSurface => _colors.softAccentSurface;
  Color get _softSurface => _colors.softSurface;
  Color get _borderColor => _colors.border;
  Color get _heroShadow => _colors.heroShadow;

  bool _loading = true;
  bool _cancelando = false;
  String? _erro;
  List<VendaNaoLiquidadaModel> _vendas = <VendaNaoLiquidadaModel>[];
  List<ColaboradorUsuarioResumo> _vendedores =
      const <ColaboradorUsuarioResumo>[];
  late DateTime _dataInicial;
  late DateTime _dataFinal;
  late DateTime _dataInicioPersonalizada;
  late DateTime _dataFimPersonalizada;
  String _periodoSelecionado = _periodoUltimos30Dias;
  String? _statusFinanceiroSelecionado;
  Set<String> _idsVendedoresSelecionados = <String>{};
  String _ordenacaoSelecionada = 'MAIS_RECENTES';
  String _valorMinimoTexto = '';
  String _valorMaximoTexto = '';
  Timer? _salvarFiltrosDebounce;
  bool _aplicandoPreferencias = false;
  bool _usuarioAlterouFiltros = false;
  bool _carregandoVendedores = true;
  bool _falhaAoCarregarVendedores = false;

  static Color _withAlpha(Color color, double opacity) {
    return color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? VendaNaoLiquidadaApiClient();
    _acoesFinanceiras =
        widget.acoesFinanceiras ?? AgendaFinanceiraAcoesFinanceiras();
    _caixaApiClient = widget.caixaApiClient ?? HttpCaixaApiClient();
    _vendedoresLoader =
        widget.vendedoresLoader ??
        () => HttpDesempenhoColaboradorApiClient().listarParticipantes(
          incluirNaoAtivos: false,
        );
    final DateTime hoje = _hojeNormalizado();
    _dataFinal = hoje;
    _dataInicial = hoje.subtract(const Duration(days: 29));
    _dataInicioPersonalizada = _dataInicial;
    _dataFimPersonalizada = _dataFinal;
    _buscaController.addListener(_onBuscaChanged);
    unawaited(_carregarVendedores());
    unawaited(_carregar());
    if (widget.habilitarPersistenciaPreferencias) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _restaurarPreferenciasVendasNaoLiquidadasMobile();
        if (!mounted) return;
        unawaited(_restaurarPreferenciasVendasNaoLiquidadasMobileBackend());
      });
    }
  }

  @override
  void dispose() {
    _salvarFiltrosDebounce?.cancel();
    _buscaController.removeListener(_onBuscaChanged);
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarVendedores() async {
    try {
      final List<ColaboradorUsuarioResumo> resultado =
          await _vendedoresLoader();
      final Map<String, ColaboradorUsuarioResumo> vendedoresPorId =
          <String, ColaboradorUsuarioResumo>{};
      for (final ColaboradorUsuarioResumo vendedor in resultado) {
        final String id = vendedor.idUnicoPessoal.trim();
        if (id.isNotEmpty && vendedor.ativo) {
          vendedoresPorId[id] = vendedor;
        }
      }
      final List<ColaboradorUsuarioResumo> vendedores =
          vendedoresPorId.values.toList(growable: false)..sort(
            (ColaboradorUsuarioResumo first, ColaboradorUsuarioResumo second) =>
                _nomeVendedor(
                  first,
                ).toLowerCase().compareTo(_nomeVendedor(second).toLowerCase()),
          );
      if (!mounted) return;
      setState(() {
        _vendedores = vendedores;
        _falhaAoCarregarVendedores = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao carregar vendedores das vendas a receber mobile: '
        '$error\n$stackTrace',
      );
      if (mounted) {
        setState(() => _falhaAoCarregarVendedores = true);
      }
    } finally {
      if (mounted) {
        setState(() => _carregandoVendedores = false);
      }
    }
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

  Future<void> _receberVenda(VendaNaoLiquidadaModel venda) async {
    if (_cancelando) return;

    final SixMobileRecebimentoResultado? resultado =
        await SixMobileRecebimentoBottomSheet.show(
          context,
          titulo: _txt(
            'vendasNaoLiquidadas.receberTitulo',
            'Receber venda em aberto',
          ),
          descricao: venda.descricao,
          contato: venda.nomeCliente.trim().isEmpty
              ? null
              : venda.nomeCliente.trim(),
          valorOriginal: venda.valorOriginal,
          valorJaRecebido: _valorJaRecebido(venda),
          valorAberto: venda.valorAberto,
          codigoTipoInicial: venda.codigoTipoRecebimento,
          permitirParcial: true,
          observacaoInicial: 'Recebimento realizado no PDV mobile.',
          caixaApiClient: _caixaApiClient,
        );

    if (resultado == null) return;

    setState(() => _cancelando = true);
    try {
      final String? idSessaoCaixa = await _buscarIdSessaoCaixaAberta();
      if (resultado.total) {
        await _api.liquidar(
          idRecebimento: venda.idRecebimento,
          input: LiquidarVendaNaoLiquidadaInput(
            codigoTipoRecebimento: resultado.codigoTipoRecebimento,
            valorRecebido: resultado.valor,
            itens: venda.itens,
            recebimentos: resultado.recebimentos,
            observacao:
                resultado.observacao ??
                'Recebimento total realizado no PDV mobile.',
            referencia: venda.idOperacaoApp.isNotEmpty
                ? venda.idOperacaoApp
                : venda.idOperacaoFinanceira,
            idSessaoCaixa: idSessaoCaixa,
          ),
        );
        if (mounted) {
          _snack(
            _txt(
              'vendasNaoLiquidadas.recebidaSucesso',
              'Venda recebida com sucesso.',
            ),
          );
        }
      } else {
        await _acoesFinanceiras.executarAbatimento(
          idLancamento: venda.idOperacaoFinanceira,
          request: AgendaFinanceiraParcialRequest(
            tipoLiquidacao: 'PARCIAL',
            dataLiquidacao: DateTime.now(),
            valorLiquidado: resultado.valor,
            formaPagamentoRealizada: resultado.formaPagamentoBackend,
            recebimentos: resultado.recebimentos,
            observacoes:
                resultado.observacao ??
                'Recebimento parcial realizado no PDV mobile.',
            idSessaoCaixa: idSessaoCaixa,
          ),
        );
        if (mounted) {
          _snack(
            _txt(
              'vendasNaoLiquidadas.parcialSucesso',
              'Parcial recebida com sucesso.',
            ),
          );
        }
      }
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  Future<String?> _buscarIdSessaoCaixaAberta() async {
    final CaixaSessao? sessao = await _caixaApiClient.getSessaoAtual();
    final String? idSessaoCaixa = sessao?.idSessaoCaixa.trim();
    return idSessaoCaixa == null || idSessaoCaixa.isEmpty
        ? null
        : idSessaoCaixa;
  }

  Future<void> _confirmarCancelamentoVenda(VendaNaoLiquidadaModel venda) async {
    final bool? confirmou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext bottomSheetContext) {
        final ThemeData theme = Theme.of(bottomSheetContext);
        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _icon(
                      Icons.delete_outline_rounded,
                      bg: _withAlpha(SixMobilePalette.error, 0.10),
                      fg: SixMobilePalette.error,
                      size: 44,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            bottomSheetContext.t(
                              'vendasNaoLiquidadas.cancelarTitulo',
                              fallback: 'Cancelar venda em aberto?',
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: _titleTextColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            bottomSheetContext.t(
                              'vendasNaoLiquidadas.cancelarDescricao',
                              fallback:
                                  'Esta ação apaga a operação e devolve os produtos ao estoque quando aplicável.',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _mutedTextColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                _cancelamentoResumo(venda),
                SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    bottomSheetContext.t(
                      'common.confirm',
                      fallback: 'Confirmar',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: SixMobilePalette.error,
                    foregroundColor: SixMobilePalette.onError,
                    minimumSize: Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  icon: Icon(Icons.arrow_back_rounded),
                  label: Text(
                    bottomSheetContext.t('common.back', fallback: 'Voltar'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _titleTextColor,
                    minimumSize: Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmou == true) await _cancelarVendaNaoLiquidada(venda);
  }

  Future<void> _cancelarVendaNaoLiquidada(VendaNaoLiquidadaModel venda) async {
    if (_cancelando) return;
    setState(() => _cancelando = true);
    try {
      await _api.cancelar(idRecebimento: venda.idRecebimento);
      if (!mounted) return;
      _snack(
        _txt(
          'vendasNaoLiquidadas.canceladaSucesso',
          'Venda em aberto cancelada.',
        ),
      );
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  String _formatarValor(num valor) {
    return context.read<LocaleSettingsProvider>().formatCurrency(valor);
  }

  double _valorJaRecebido(VendaNaoLiquidadaModel venda) {
    final double recebido = venda.valorOriginal - venda.valorAberto;
    return recebido > 0 ? recebido : 0;
  }

  String _formatarData(DateTime? data, {bool incluirHora = true}) {
    if (data == null) {
      return _txt('vendasNaoLiquidadas.semData', 'Sem data');
    }
    final LocaleSettingsProvider localeSettings = context
        .read<LocaleSettingsProvider>();
    final String dataFormatada = localeSettings.formatDate(data);
    if (!incluirHora) return dataFormatada;
    return '$dataFormatada ${localeSettings.formatTime(data)}';
  }

  String _formatarQuantidadeVendas(int quantidade) {
    if (quantidade == 1) {
      return _txt(
        'vendasNaoLiquidadas.umaVendaAguardando',
        '1 venda aguardando liquidação',
      );
    }
    return '$quantidade ${_txt('vendasNaoLiquidadas.vendasAguardando', 'vendas aguardando liquidação')}';
  }

  String _formatarQuantidadeItens(int quantidade) {
    final String label = quantidade == 1
        ? _txt('vendasNaoLiquidadas.itemSingular', 'item')
        : _txt('vendasNaoLiquidadas.itemPlural', 'itens');
    return '$quantidade $label';
  }

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
        return DateTimeRange(start: DateTime(hoje.year, hoje.month), end: hoje);
      case _periodoMesPassado:
        final DateTime inicioMesAtual = DateTime(hoje.year, hoje.month);
        final DateTime fimMesPassado = inicioMesAtual.subtract(
          const Duration(days: 1),
        );
        return DateTimeRange(
          start: DateTime(fimMesPassado.year, fimMesPassado.month),
          end: fimMesPassado,
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

  List<String> _idsVendedoresOrdenados() {
    final List<String> ids = _idsVendedoresSelecionados
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    ids.sort();
    return ids;
  }

  String _nomeVendedor(ColaboradorUsuarioResumo vendedor) {
    for (final String value in <String>[
      vendedor.nomeDeGuerra,
      vendedor.nome,
      vendedor.email,
      vendedor.idUnicoPessoal,
    ]) {
      final String normalizado = value.trim();
      if (normalizado.isNotEmpty) return normalizado;
    }
    return vendedor.idUnicoPessoal;
  }

  ColaboradorUsuarioResumo? _vendedorPorId(String id) {
    for (final ColaboradorUsuarioResumo vendedor in _vendedores) {
      if (vendedor.idUnicoPessoal.trim() == id.trim()) return vendedor;
    }
    return null;
  }

  String _valorFiltroVendedores(Set<String> ids) {
    if (ids.isEmpty) {
      return _txt('sales.query.allSellers', 'Todos os vendedores');
    }
    if (ids.length == 1) {
      final ColaboradorUsuarioResumo? vendedor = _vendedorPorId(ids.first);
      if (vendedor != null) return _nomeVendedor(vendedor);
      for (final VendaNaoLiquidadaModel venda in _vendas) {
        if (venda.idColaboradorCriacao.trim() == ids.first.trim() &&
            venda.nomeColaboradorCriacao.trim().isNotEmpty) {
          return venda.nomeColaboradorCriacao.trim();
        }
      }
    }
    final String label = _txt(
      'sales.query.sellersSelected',
      '{count} vendedores',
    );
    return label.replaceAll('{count}', ids.length.toString());
  }

  List<SixMobileSelectionOption<String>> _opcoesVendedoresMobile() {
    final Map<String, SixMobileSelectionOption<String>> opcoes =
        <String, SixMobileSelectionOption<String>>{};
    for (final ColaboradorUsuarioResumo vendedor in _vendedores) {
      final String id = vendedor.idUnicoPessoal.trim();
      if (id.isEmpty) continue;
      final String nome = _nomeVendedor(vendedor);
      final String email = vendedor.email.trim();
      opcoes[id] = SixMobileSelectionOption<String>(
        value: id,
        title: nome,
        subtitle: email.isNotEmpty && email != nome ? email : null,
        icon: Icons.person_outline_rounded,
      );
    }
    for (final VendaNaoLiquidadaModel venda in _vendas) {
      final String id = venda.idColaboradorCriacao.trim();
      if (id.isEmpty || opcoes.containsKey(id)) continue;
      final String nome = venda.nomeColaboradorCriacao.trim();
      opcoes[id] = SixMobileSelectionOption<String>(
        value: id,
        title: nome.isEmpty ? id : nome,
        icon: Icons.person_outline_rounded,
      );
    }
    for (final String id in _idsVendedoresOrdenados()) {
      opcoes.putIfAbsent(
        id,
        () => SixMobileSelectionOption<String>(
          value: id,
          title: id,
          icon: Icons.person_outline_rounded,
        ),
      );
    }
    final List<SixMobileSelectionOption<String>> resultado =
        opcoes.values.toList(growable: false)..sort(
          (
            SixMobileSelectionOption<String> first,
            SixMobileSelectionOption<String> second,
          ) => first.title.toLowerCase().compareTo(second.title.toLowerCase()),
        );
    return resultado;
  }

  double? _parseValor(String texto) {
    String normalizado = texto.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (normalizado.isEmpty) return null;
    final int ultimaVirgula = normalizado.lastIndexOf(',');
    final int ultimoPonto = normalizado.lastIndexOf('.');
    if (ultimaVirgula > ultimoPonto) {
      normalizado = normalizado.replaceAll('.', '').replaceAll(',', '.');
    } else if (ultimoPonto > ultimaVirgula && ultimaVirgula >= 0) {
      normalizado = normalizado.replaceAll(',', '');
    } else if (ultimaVirgula >= 0) {
      normalizado = normalizado.replaceAll(',', '.');
    }
    return double.tryParse(normalizado);
  }

  String _statusFinanceiroDaVenda(VendaNaoLiquidadaModel venda) {
    final String status = venda.status.trim().toUpperCase();
    return status.contains('PARCIAL') || _valorJaRecebido(venda) > 0
        ? 'PARCIAL'
        : 'EM_ABERTO';
  }

  String _textoBuscaVenda(VendaNaoLiquidadaModel venda) {
    return <String>[
      venda.idRecebimento,
      venda.idOperacaoFinanceira,
      venda.idOperacaoApp,
      venda.descricao,
      venda.idCliente,
      venda.nomeCliente,
      venda.idColaboradorCriacao,
      venda.nomeColaboradorCriacao,
      ...venda.itens.expand(
        (VendaNaoLiquidadaItemModel item) => <String>[
          item.idProduto,
          item.nome,
        ],
      ),
    ].join(' ').toLowerCase();
  }

  List<VendaNaoLiquidadaModel> get _vendasFiltradas {
    final String busca = _buscaController.text.trim().toLowerCase();
    final double? valorMinimo = _parseValor(_valorMinimoTexto);
    final double? valorMaximo = _parseValor(_valorMaximoTexto);
    final List<VendaNaoLiquidadaModel> resultado = _vendas
        .where((venda) {
          if (busca.isNotEmpty && !_textoBuscaVenda(venda).contains(busca)) {
            return false;
          }
          if (_idsVendedoresSelecionados.isNotEmpty &&
              !_idsVendedoresSelecionados.contains(
                venda.idColaboradorCriacao.trim(),
              )) {
            return false;
          }
          final DateTime? dataCompetencia = venda.dataCompetencia;
          if (dataCompetencia == null) return false;
          final DateTime data = _normalizarData(dataCompetencia);
          if (data.isBefore(_dataInicial) || data.isAfter(_dataFinal)) {
            return false;
          }
          if (_statusFinanceiroSelecionado != null &&
              _statusFinanceiroDaVenda(venda) != _statusFinanceiroSelecionado) {
            return false;
          }
          if (valorMinimo != null && venda.valorAberto < valorMinimo)
            return false;
          return valorMaximo == null || venda.valorAberto <= valorMaximo;
        })
        .toList(growable: false);

    int compararData(
      VendaNaoLiquidadaModel first,
      VendaNaoLiquidadaModel second,
    ) {
      final DateTime firstDate = first.dataCompetencia ?? DateTime(1970);
      final DateTime secondDate = second.dataCompetencia ?? DateTime(1970);
      return firstDate.compareTo(secondDate);
    }

    switch (_ordenacaoSelecionada) {
      case 'MAIS_ANTIGAS':
        resultado.sort(compararData);
        break;
      case 'MAIOR_VALOR':
        resultado.sort(
          (VendaNaoLiquidadaModel first, VendaNaoLiquidadaModel second) =>
              second.valorAberto.compareTo(first.valorAberto),
        );
        break;
      case 'MENOR_VALOR':
        resultado.sort(
          (VendaNaoLiquidadaModel first, VendaNaoLiquidadaModel second) =>
              first.valorAberto.compareTo(second.valorAberto),
        );
        break;
      case 'MAIS_RECENTES':
      default:
        resultado.sort(
          (VendaNaoLiquidadaModel first, VendaNaoLiquidadaModel second) =>
              compararData(second, first),
        );
        break;
    }
    return resultado;
  }

  bool get _temFiltrosAtivos =>
      _buscaController.text.trim().isNotEmpty ||
      _idsVendedoresSelecionados.isNotEmpty ||
      _periodoSelecionado != _periodoUltimos30Dias ||
      _statusFinanceiroSelecionado != null ||
      _valorMinimoTexto.trim().isNotEmpty ||
      _valorMaximoTexto.trim().isNotEmpty ||
      _ordenacaoSelecionada != 'MAIS_RECENTES';

  int get _quantidadeFiltrosAtivos {
    int quantidade = 0;
    if (_idsVendedoresSelecionados.isNotEmpty) quantidade++;
    if (_periodoSelecionado != _periodoUltimos30Dias) quantidade++;
    if (_statusFinanceiroSelecionado != null) quantidade++;
    if (_valorMinimoTexto.trim().isNotEmpty) quantidade++;
    if (_valorMaximoTexto.trim().isNotEmpty) quantidade++;
    if (_ordenacaoSelecionada != 'MAIS_RECENTES') quantidade++;
    return quantidade;
  }

  void _onBuscaChanged() {
    if (mounted) setState(() {});
    if (_aplicandoPreferencias) return;
    _usuarioAlterouFiltros = true;
    _agendarSalvarPreferencias();
  }

  void _agendarSalvarPreferencias() {
    if (!widget.habilitarPersistenciaPreferencias) return;
    _salvarFiltrosDebounce?.cancel();
    _salvarFiltrosDebounce = Timer(
      const Duration(milliseconds: 450),
      _salvarPreferencias,
    );
  }

  void _salvarPreferencias() {
    if (!widget.habilitarPersistenciaPreferencias) return;
    _salvarFiltrosDebounce?.cancel();
    final ConsultaVendasFiltrosWebPreferencia filtros = _preferenciaAtual();
    unawaited(
      _usuarioService
          .atualizarPreferenciasIndividuais(
            vendasNaoLiquidadasFiltrosMobile: filtros.toJson(),
          )
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint(
              'Erro ao salvar filtros mobile das vendas a receber: '
              '$error\n$stackTrace',
            );
          }),
    );
  }

  ConsultaVendasFiltrosWebPreferencia _preferenciaAtual() {
    return ConsultaVendasFiltrosWebPreferencia(
      busca: _buscaController.text,
      periodo:
          ConsultaVendasPeriodoWebPreferenciaApi.tryFromCodigo(
            _periodoSelecionado,
          ) ??
          ConsultaVendasPeriodoWebPreferencia.ultimos30Dias,
      dataInicio: _periodoSelecionado == _periodoPersonalizado
          ? _dataInicioPersonalizada
          : null,
      dataFim: _periodoSelecionado == _periodoPersonalizado
          ? _dataFimPersonalizada
          : null,
      statusFinanceiro: _statusFinanceiroSelecionado,
      idsVendedores: _idsVendedoresOrdenados(),
      valorMinimo: _valorMinimoTexto,
      valorMaximo: _valorMaximoTexto,
      ordenacao: _ordenacaoSelecionada,
    );
  }

  Future<void> _restaurarPreferenciasVendasNaoLiquidadasMobile() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (!mounted || preferencias == null || _usuarioAlterouFiltros) return;
    _aplicarPreferencias(preferencias.vendasNaoLiquidadasFiltrosMobile);
  }

  Future<void> _restaurarPreferenciasVendasNaoLiquidadasMobileBackend() async {
    try {
      if (_usuarioProvider.usuario == null) {
        await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      }
      final PreferenciasIndividuaisDoUsuarioModel? preferencias =
          _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
      if (!mounted || preferencias == null || _usuarioAlterouFiltros) return;
      _aplicarPreferencias(preferencias.vendasNaoLiquidadasFiltrosMobile);
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao restaurar filtros mobile das vendas a receber: '
        '$error\n$stackTrace',
      );
    }
  }

  void _aplicarPreferencias(ConsultaVendasFiltrosWebPreferencia filtros) {
    _aplicandoPreferencias = true;
    _buscaController.text = filtros.busca;
    setState(() {
      _periodoSelecionado = filtros.periodo.codigo;
      _idsVendedoresSelecionados = filtros.idsVendedores.toSet();
      _statusFinanceiroSelecionado = filtros.statusFinanceiro;
      _ordenacaoSelecionada = filtros.ordenacao;
      _valorMinimoTexto = filtros.valorMinimo;
      _valorMaximoTexto = filtros.valorMaximo;
      if (filtros.periodo ==
          ConsultaVendasPeriodoWebPreferencia.personalizado) {
        if (filtros.dataInicio != null) {
          _dataInicioPersonalizada = filtros.dataInicio!;
        }
        if (filtros.dataFim != null) {
          _dataFimPersonalizada = filtros.dataFim!;
        }
        if (_dataFimPersonalizada.isBefore(_dataInicioPersonalizada)) {
          _dataFimPersonalizada = _dataInicioPersonalizada;
        }
      }
      _sincronizarPeriodoComDatas();
    });
    _aplicandoPreferencias = false;
  }

  Future<void> _abrirFiltros() async {
    final LocaleSettingsProvider regionalizacao = context
        .read<LocaleSettingsProvider>();
    final _VendasNaoLiquidadasFilterDraft? draft =
        await showModalBottomSheet<_VendasNaoLiquidadasFilterDraft>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: _withAlpha(Colors.black, 0.42),
          builder: (BuildContext context) {
            return _VendasNaoLiquidadasFilterSheet(
              initialDraft: _VendasNaoLiquidadasFilterDraft(
                periodo: _periodoSelecionado,
                dataInicio: _dataInicioPersonalizada,
                dataFim: _dataFimPersonalizada,
                idsVendedores: _idsVendedoresSelecionados,
                statusFinanceiro: _statusFinanceiroSelecionado,
                ordenacao: _ordenacaoSelecionada,
                valorMinimo: _valorMinimoTexto,
                valorMaximo: _valorMaximoTexto,
              ),
              sellerOptions: _opcoesVendedoresMobile(),
              sellersLoading: _carregandoVendedores,
              sellersLoadFailed: _falhaAoCarregarVendedores,
              sellerSelectionLabelBuilder: _valorFiltroVendedores,
              formatDate: regionalizacao.formatDate,
              periodLabelBuilder: _periodoLabel,
              financialStatusLabelBuilder: _statusFinanceiroLabel,
              orderLabelBuilder: _ordenacaoLabel,
              showDateSheet: _showDatePickerSheet,
            );
          },
        );
    if (draft == null || !mounted) return;

    setState(() {
      _periodoSelecionado = draft.periodo;
      _dataInicioPersonalizada = draft.dataInicio;
      _dataFimPersonalizada = draft.dataFim.isBefore(draft.dataInicio)
          ? draft.dataInicio
          : draft.dataFim;
      _idsVendedoresSelecionados = Set<String>.from(draft.idsVendedores);
      _statusFinanceiroSelecionado = draft.statusFinanceiro;
      _ordenacaoSelecionada = draft.ordenacao;
      _valorMinimoTexto = draft.valorMinimo;
      _valorMaximoTexto = draft.valorMaximo;
      _sincronizarPeriodoComDatas();
    });
    _usuarioAlterouFiltros = true;
    _salvarPreferencias();
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
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (BuildContext context) {
        return _VendasNaoLiquidadasDateSheet(
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
    _aplicandoPreferencias = true;
    _buscaController.clear();
    setState(() {
      _periodoSelecionado = _periodoUltimos30Dias;
      _dataFinal = hoje;
      _dataInicial = hoje.subtract(const Duration(days: 29));
      _dataInicioPersonalizada = _dataInicial;
      _dataFimPersonalizada = _dataFinal;
      _idsVendedoresSelecionados = <String>{};
      _statusFinanceiroSelecionado = null;
      _ordenacaoSelecionada = 'MAIS_RECENTES';
      _valorMinimoTexto = '';
      _valorMaximoTexto = '';
    });
    _aplicandoPreferencias = false;
    _usuarioAlterouFiltros = true;
    _salvarPreferencias();
  }

  String _periodoLabel(String value) {
    switch (value) {
      case _periodoHoje:
        return _txt('sales.query.period.today', 'Hoje');
      case _periodoUltimos7Dias:
        return _txt('sales.query.period.last7Days', 'Últimos 7 dias');
      case _periodoEsteMes:
        return _txt('sales.query.period.thisMonth', 'Este mês');
      case _periodoMesPassado:
        return _txt('sales.query.period.lastMonth', 'Mês passado');
      case _periodoPersonalizado:
        return _txt('sales.query.period.custom', 'Personalizado');
      case _periodoUltimos30Dias:
      default:
        return _txt('sales.query.period.last30Days', 'Últimos 30 dias');
    }
  }

  String _statusFinanceiroLabel(String value) {
    switch (value) {
      case 'PARCIAL':
        return _txt('sales.query.financial.partial', 'Parcial');
      case 'EM_ABERTO':
      default:
        return _txt('sales.query.financial.open', 'Em aberto');
    }
  }

  String _ordenacaoLabel(String value) {
    switch (value) {
      case 'MAIS_ANTIGAS':
        return _txt('sales.query.order.oldest', 'Mais antigas');
      case 'MAIOR_VALOR':
        return _txt('sales.query.order.highestValue', 'Maior valor');
      case 'MENOR_VALOR':
        return _txt('sales.query.order.lowestValue', 'Menor valor');
      case 'MAIS_RECENTES':
      default:
        return _txt('sales.query.order.newest', 'Mais recentes');
    }
  }

  int _quantidadeItensDaVenda(VendaNaoLiquidadaModel venda) {
    return venda.itens.fold<int>(0, (soma, item) => soma + item.quantidade);
  }

  double get _totalAberto => _vendasFiltradas.fold<double>(
    0,
    (double soma, VendaNaoLiquidadaModel venda) => soma + venda.valorAberto,
  );

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}|${provider.timeFormat}',
    );

    return SixoAppMobileLoadingOverlay(
      isLoading: _cancelando,
      message: _txt('vendasNaoLiquidadas.processando', 'Processando ação...'),
      child: SixMobilePageShell(
        title: _txt('vendasNaoLiquidadas.title', 'Vendas a receber'),
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
          tooltip: _txt('common.back', 'Voltar'),
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: _txt('sales.query.mobile.manageFilters', 'Abrir filtros'),
            onPressed: _loading || _cancelando ? null : _abrirFiltros,
            icon: Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: _txt('common.refresh', 'Atualizar'),
            onPressed: _loading || _cancelando ? null : _carregar,
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
        bodyBuilder: _buildContent,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
          children: <Widget>[
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : _stateTransitionDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildState(reduceMotion: reduceMotion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildState({required bool reduceMotion}) {
    if (_loading) {
      return _loadingState(
        key: ValueKey<String>('vendas-nao-liquidadas-loading'),
      );
    }

    if (_erro != null) {
      return _estado(
        key: ValueKey<String>('vendas-nao-liquidadas-error'),
        icon: Icons.error_outline_rounded,
        titulo: _txt(
          'vendasNaoLiquidadas.erroTitulo',
          'Não foi possível carregar',
        ),
        mensagem: _erro!,
      );
    }

    return _successState(
      key: ValueKey<String>(
        'vendas-nao-liquidadas-success-${_vendas.length}-${_totalAberto.toStringAsFixed(2)}',
      ),
      reduceMotion: reduceMotion,
    );
  }

  Widget _successState({Key? key, required bool reduceMotion}) {
    final List<VendaNaoLiquidadaModel> vendas = _vendasFiltradas;
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _entry(_header(reduceMotion: reduceMotion), reduceMotion: reduceMotion),
        SizedBox(height: 14),
        _entry(
          _filtersCard(),
          delay: Duration(milliseconds: 55),
          reduceMotion: reduceMotion,
        ),
        if (_temFiltrosAtivos) ...<Widget>[
          SizedBox(height: 10),
          _activeFilters(),
        ],
        SizedBox(height: 18),
        _entry(
          _section(
            _txt('vendasNaoLiquidadas.secaoAbertas', 'Vendas em aberto'),
          ),
          delay: Duration(milliseconds: 70),
          reduceMotion: reduceMotion,
        ),
        SizedBox(height: 12),
        if (vendas.isEmpty)
          _entry(
            _empty(filtrada: _vendas.isNotEmpty),
            delay: Duration(milliseconds: 110),
            reduceMotion: reduceMotion,
          )
        else
          ...vendas.asMap().entries.map((
            MapEntry<int, VendaNaoLiquidadaModel> entry,
          ) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _entry(
                _vendaCard(entry.value),
                delay: Duration(milliseconds: 110 + entry.key * 40),
                reduceMotion: reduceMotion,
              ),
            );
          }),
      ],
    );
  }

  Widget _entry(
    Widget child, {
    Duration delay = Duration.zero,
    required bool reduceMotion,
  }) {
    if (reduceMotion) return child;
    return SixStaggeredEntry(delay: delay, child: child);
  }

  Widget _header({required bool reduceMotion}) {
    final int quantidadeFiltrada = _vendasFiltradas.length;
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(color: _heroShadow, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(
                Icons.point_of_sale_outlined,
                bg: _withAlpha(SixMobilePalette.onPrimary, 0.12),
                fg: SixMobilePalette.onPrimary,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'vendasNaoLiquidadas.dashboardTitulo',
                        'Recebimentos pendentes',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatarQuantidadeVendas(quantidadeFiltrada),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.heroSupportingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _withAlpha(SixMobilePalette.onPrimary, 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _withAlpha(SixMobilePalette.onPrimary, 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _txt('vendasNaoLiquidadas.totalEmAberto', 'Total em aberto'),
                  style: TextStyle(
                    color: SixMobilePalette.heroLabelText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                _AnimatedMetricValue(
                  key: ValueKey<String>(
                    'header-total-${_totalAberto.toStringAsFixed(2)}',
                  ),
                  value: _totalAberto,
                  formatter: _formatarValor,
                  reduceMotion: reduceMotion,
                  style: TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 24,
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

  Widget _filtersCard() {
    final int quantidade = _quantidadeFiltrosAtivos;
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _colors.navigationShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            key: ValueKey<String>('vendas-a-receber-busca'),
            controller: _buscaController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _txt(
                'vendasNaoLiquidadas.buscaHint',
                'Venda, cliente, vendedor ou produto',
              ),
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _buscaController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: _txt('common.clear', 'Limpar'),
                      onPressed: _buscaController.clear,
                      icon: Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: _softSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _borderColor),
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  key: ValueKey<String>('vendas-a-receber-abrir-filtros'),
                  onPressed: _abrirFiltros,
                  icon: Icon(Icons.tune_rounded, size: 19),
                  label: Text(
                    quantidade == 0
                        ? _txt('common.filters', 'Filtros')
                        : '${_txt('common.filters', 'Filtros')} ($quantidade)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentColor,
                    backgroundColor: _softAccentSurface,
                    side: BorderSide(color: _borderColor),
                    minimumSize: Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              if (_temFiltrosAtivos) ...<Widget>[
                SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: _txt('common.clearFilters', 'Limpar filtros'),
                  onPressed: _limparFiltros,
                  style: IconButton.styleFrom(
                    foregroundColor: _mutedTextColor,
                    backgroundColor: _softSurface,
                    side: BorderSide(color: _borderColor),
                    minimumSize: Size(46, 46),
                  ),
                  icon: Icon(Icons.filter_alt_off_rounded, size: 20),
                ),
              ],
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(Icons.date_range_rounded, size: 15, color: _mutedTextColor),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  _periodoLabel(_periodoSelecionado),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.people_alt_outlined, size: 15, color: _mutedTextColor),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  _valorFiltroVendedores(_idsVendedoresSelecionados),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeFilters() {
    final List<Widget> chips = <Widget>[];
    if (_periodoSelecionado != _periodoUltimos30Dias) {
      chips.add(_pill(_periodoLabel(_periodoSelecionado)));
    }
    if (_idsVendedoresSelecionados.isNotEmpty) {
      chips.add(_pill(_valorFiltroVendedores(_idsVendedoresSelecionados)));
    }
    if (_statusFinanceiroSelecionado != null) {
      chips.add(_pill(_statusFinanceiroLabel(_statusFinanceiroSelecionado!)));
    }
    if (_valorMinimoTexto.trim().isNotEmpty) {
      chips.add(
        _pill(
          '${_txt('sales.query.minimumValue', 'Valor mínimo')}: '
          '${_valorMinimoTexto.trim()}',
        ),
      );
    }
    if (_valorMaximoTexto.trim().isNotEmpty) {
      chips.add(
        _pill(
          '${_txt('sales.query.maximumValue', 'Valor máximo')}: '
          '${_valorMaximoTexto.trim()}',
        ),
      );
    }
    if (_ordenacaoSelecionada != 'MAIS_RECENTES') {
      chips.add(_pill(_ordenacaoLabel(_ordenacaoSelecionada)));
    }
    if (chips.isEmpty) return SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _vendaCard(VendaNaoLiquidadaModel venda) {
    final int quantidadeItens = _quantidadeItensDaVenda(venda);
    final String colaborador = venda.nomeColaboradorCriacao.trim().isEmpty
        ? _txt('vendasNaoLiquidadas.colaboradorPadrao', 'colaborador')
        : venda.nomeColaboradorCriacao.trim();
    final String cliente = venda.nomeCliente.trim().isEmpty
        ? _txt(
            'vendasNaoLiquidadas.clienteNaoInformado',
            'Cliente não informado',
          )
        : venda.nomeCliente.trim();
    final Widget detailsButton = _cardDetailsButton(venda);

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _cancelando ? null : () => _abrirDetalhesVenda(venda),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _colors.navigationShadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _icon(
                    Icons.receipt_long_outlined,
                    bg: _softAccentSurface,
                    fg: _accentColor,
                    size: 48,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          venda.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          cliente,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${_txt('vendasNaoLiquidadas.criadaPor', 'Criada por')} $colaborador',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  detailsButton,
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _pill(_formatarData(venda.dataCompetencia)),
                  _pill(_formatarQuantidadeItens(quantidadeItens)),
                  if (venda.status.trim().isNotEmpty)
                    _pill(
                      venda.status,
                      fg: _accentColor,
                      bg: _softAccentSurface,
                    ),
                  if (venda.dataVencimento != null)
                    _pill(
                      '${_txt('vendasNaoLiquidadas.venceEm', 'Vence em')} '
                      '${_formatarData(venda.dataVencimento, incluirHora: false)}',
                    ),
                ],
              ),
              SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _txt(
                            'vendasNaoLiquidadas.valorAberto',
                            'Valor em aberto',
                          ),
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatarValor(venda.valorAberto),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  _pill(
                    _txt('vendasNaoLiquidadas.verDetalhes', 'Ver detalhes'),
                    fg: _accentColor,
                    bg: _softAccentSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardDetailsButton(VendaNaoLiquidadaModel venda) {
    return Semantics(
      button: true,
      label: _txt(
        'vendasNaoLiquidadas.verDetalhesVenda',
        'Ver detalhes da venda',
      ),
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: _softAccentSurface,
          foregroundColor: _accentColor,
          fixedSize: Size(40, 40),
          minimumSize: Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        tooltip: _txt(
          'vendasNaoLiquidadas.verDetalhesVenda',
          'Ver detalhes da venda',
        ),
        onPressed: _cancelando ? null : () => _abrirDetalhesVenda(venda),
        icon: Icon(Icons.add_rounded, size: 22),
      ),
    );
  }

  Future<void> _abrirDetalhesVenda(VendaNaoLiquidadaModel venda) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.46,
          maxChildSize: 0.94,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return _vendaDetalhesSheet(
              sheetContext: sheetContext,
              scrollController: scrollController,
              venda: venda,
            );
          },
        );
      },
    );
  }

  Widget _vendaDetalhesSheet({
    required BuildContext sheetContext,
    required ScrollController scrollController,
    required VendaNaoLiquidadaModel venda,
  }) {
    final int quantidadeItens = _quantidadeItensDaVenda(venda);
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(sheetContext) ||
        MediaQuery.accessibleNavigationOf(sheetContext);
    final double valorJaRecebido = _valorJaRecebido(venda);
    final String colaborador = venda.nomeColaboradorCriacao.trim().isEmpty
        ? _txt('vendasNaoLiquidadas.colaboradorPadrao', 'colaborador')
        : venda.nomeColaboradorCriacao.trim();
    final bool podeReceber = !_cancelando && venda.valorAberto > 0;
    final bool podeCancelar = !_cancelando;

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _icon(
                  Icons.receipt_long_outlined,
                  bg: _softAccentSurface,
                  fg: _accentColor,
                  size: 42,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        venda.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_txt('vendasNaoLiquidadas.criadaPor', 'Criada por')} $colaborador',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _txt('common.close', 'Fechar'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: Icon(Icons.close_rounded),
                ),
              ],
            ),
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _pill(_formatarData(venda.dataCompetencia)),
                _pill(_formatarQuantidadeItens(quantidadeItens)),
                _pill(venda.status),
                if (venda.dataVencimento != null)
                  _pill(
                    '${_txt('vendasNaoLiquidadas.venceEm', 'Vence em')} '
                    '${_formatarData(venda.dataVencimento, incluirHora: false)}',
                  ),
              ],
            ),
            SizedBox(height: 16),
            _vendaDetailActions(
              sheetContext: sheetContext,
              venda: venda,
              podeReceber: podeReceber,
              podeCancelar: podeCancelar,
            ),
            SizedBox(height: 18),
            _detailSection(
              title: _txt('vendasNaoLiquidadas.resumoVenda', 'Resumo da venda'),
              icon: Icons.assignment_outlined,
              children: <Widget>[
                _detailLine(
                  _txt('vendasNaoLiquidadas.descricao', 'Descrição'),
                  venda.descricao,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.cliente', 'Cliente'),
                  venda.nomeCliente,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.colaborador', 'Colaborador'),
                  colaborador,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.status', 'Status'),
                  venda.status,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.criacao', 'Criação'),
                  _formatarData(venda.dataCompetencia),
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.vencimento', 'Vencimento'),
                  _formatarData(venda.dataVencimento, incluirHora: false),
                ),
              ],
            ),
            SizedBox(height: 14),
            _detailSection(
              title: _txt('vendasNaoLiquidadas.valores', 'Valores'),
              icon: Icons.payments_outlined,
              children: <Widget>[
                _detailMoneyLine(
                  _txt('vendasNaoLiquidadas.valorOriginal', 'Valor original'),
                  venda.valorOriginal,
                  reduceMotion: reduceMotion,
                ),
                _detailMoneyLine(
                  _txt(
                    'vendasNaoLiquidadas.valorJaRecebido',
                    'Valor já recebido',
                  ),
                  -valorJaRecebido,
                  reduceMotion: reduceMotion,
                  valueColor: valorJaRecebido > 0
                      ? SixMobilePalette.error
                      : _mutedTextColor,
                ),
                _detailMoneyLine(
                  _txt('vendasNaoLiquidadas.valorAberto', 'Valor em aberto'),
                  venda.valorAberto,
                  reduceMotion: reduceMotion,
                  valueColor: venda.valorAberto > 0 ? _accentColor : null,
                ),
                _detailLine(
                  _txt('vendasNaoLiquidadas.itens', 'Itens'),
                  _formatarQuantidadeItens(quantidadeItens),
                ),
              ],
            ),
            SizedBox(height: 14),
            _recebimentosVendaSection(venda),
            SizedBox(height: 14),
            _itensVendaSection(venda),
          ],
        ),
      ),
    );
  }

  Widget _vendaDetailActions({
    required BuildContext sheetContext,
    required VendaNaoLiquidadaModel venda,
    required bool podeReceber,
    required bool podeCancelar,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double itemWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SizedBox(
              width: itemWidth,
              child: _sheetActionButton(
                label: _txt('vendasNaoLiquidadas.receber', 'Receber'),
                icon: Icons.payments_outlined,
                filled: true,
                onPressed: podeReceber
                    ? () => _runAfterClosingSheet(
                        sheetContext,
                        () => _receberVenda(venda),
                      )
                    : null,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _sheetActionButton(
                label: _txt(
                  'vendasNaoLiquidadas.cancelarVenda',
                  'Cancelar venda',
                ),
                icon: Icons.delete_outline_rounded,
                onPressed: podeCancelar
                    ? () => _runAfterClosingSheet(
                        sheetContext,
                        () => _confirmarCancelamentoVenda(venda),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheetActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final ButtonStyle style = filled
        ? FilledButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: SixMobilePalette.onAccent,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: _titleTextColor,
            side: BorderSide(color: _borderColor),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          );
    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17),
        SizedBox(width: 7),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return filled
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }

  void _runAfterClosingSheet(BuildContext sheetContext, VoidCallback action) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  Widget _detailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(icon, bg: _softAccentSurface, fg: _accentColor, size: 38),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailLine(String label, String? value, {Color? valueColor}) {
    final String display = _blankAsDash(value);
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                color: valueColor ?? _titleTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailMoneyLine(
    String label,
    num value, {
    required bool reduceMotion,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _AnimatedMetricValue(
              value: value,
              formatter: _formatarValor,
              reduceMotion: reduceMotion,
              style: TextStyle(
                color: valueColor ?? _titleTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recebimentosVendaSection(VendaNaoLiquidadaModel venda) {
    return _detailSection(
      title: _txt('vendasNaoLiquidadas.recebimentos', 'Recebimentos'),
      icon: Icons.receipt_long_outlined,
      children: <Widget>[
        if (venda.recebimentos.isEmpty)
          Text(
            _txt(
              'vendasNaoLiquidadas.semRecebimentos',
              'Nenhum recebimento lançado.',
            ),
            style: TextStyle(color: _mutedTextColor),
          )
        else
          ...venda.recebimentos.reversed.map((
            VendaNaoLiquidadaRecebimentoModel item,
          ) {
            final String observacoes = item.observacoes?.trim() ?? '';
            final String referencia = item.referencia?.trim() ?? '';
            final String? tipoLiquidacao = _tipoLiquidacaoLabel(
              item.tipoLiquidacao,
            );
            return _detailListTile(
              icon: Icons.payments_outlined,
              title: _descricaoRecebimento(item),
              subtitle: <String>[
                _formatarDataRecebimento(item),
                if (tipoLiquidacao != null) tipoLiquidacao,
                if (referencia.isNotEmpty)
                  '${_txt('vendasNaoLiquidadas.referencia', 'Referência')}: '
                      '$referencia',
                if (observacoes.isNotEmpty) observacoes,
              ].join(' • '),
              trailing: _formatarValor(item.valorLiquidado),
            );
          }),
      ],
    );
  }

  String _descricaoRecebimento(VendaNaoLiquidadaRecebimentoModel item) {
    final String descricao = item.descricaoTipoRecebimento.trim();
    if (descricao.isNotEmpty) return descricao;
    final String forma = item.formaPagamentoRealizada.trim();
    if (forma.isNotEmpty) return forma;
    final String codigo = item.codigoTipoRecebimento.trim();
    if (codigo.isNotEmpty) return codigo;
    return _txt('vendasNaoLiquidadas.recebimento', 'Recebimento');
  }

  String _formatarDataRecebimento(VendaNaoLiquidadaRecebimentoModel item) {
    if (item.registradoEm != null) return _formatarData(item.registradoEm);

    final DateTime? dataLiquidacao = item.dataLiquidacao;
    if (dataLiquidacao == null) return _formatarData(null);

    final bool possuiHora =
        dataLiquidacao.hour != 0 ||
        dataLiquidacao.minute != 0 ||
        dataLiquidacao.second != 0 ||
        dataLiquidacao.millisecond != 0 ||
        dataLiquidacao.microsecond != 0;
    return _formatarData(dataLiquidacao, incluirHora: possuiHora);
  }

  String? _tipoLiquidacaoLabel(String tipoLiquidacao) {
    switch (tipoLiquidacao.trim().toUpperCase()) {
      case 'TOTAL':
        return _txt('vendasNaoLiquidadas.recebimentoTotal', 'Total');
      case 'PARCIAL':
        return _txt('vendasNaoLiquidadas.recebimentoParcial', 'Parcial');
      default:
        return null;
    }
  }

  Widget _itensVendaSection(VendaNaoLiquidadaModel venda) {
    return _detailSection(
      title: _txt('vendasNaoLiquidadas.itensVenda', 'Itens da venda'),
      icon: Icons.inventory_2_outlined,
      children: <Widget>[
        if (venda.itens.isEmpty)
          Text(
            _txt('vendasNaoLiquidadas.semItens', 'Nenhum item vinculado.'),
            style: TextStyle(color: _mutedTextColor),
          )
        else
          ...venda.itens.map((VendaNaoLiquidadaItemModel item) {
            final double total = item.quantidade * item.valorUnitario;
            return _detailListTile(
              icon: item.ehServico
                  ? Icons.handyman_outlined
                  : Icons.inventory_2_outlined,
              title: item.nome,
              subtitle:
                  '${item.quantidade} x ${_formatarValor(item.valorUnitario)}',
              trailing: _formatarValor(total),
            );
          }),
      ],
    );
  }

  Widget _detailListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _icon(icon, bg: _softSurface, fg: _primaryColor, size: 34),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _blankAsDash(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  _blankAsDash(subtitle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            SizedBox(width: 10),
            Text(
              trailing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _blankAsDash(String? value) {
    final String text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  Widget _empty({bool filtrada = false}) {
    return _baseCard(
      child: Column(
        children: <Widget>[
          _icon(
            Icons.check_circle_outline_rounded,
            bg: _softAccentSurface,
            fg: _accentColor,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            filtrada
                ? _txt(
                    'vendasNaoLiquidadas.filtrosSemResultadoTitulo',
                    'Nenhuma venda encontrada',
                  )
                : _txt(
                    'vendasNaoLiquidadas.vazioTitulo',
                    'Nenhuma venda em aberto',
                  ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            filtrada
                ? _txt(
                    'vendasNaoLiquidadas.filtrosSemResultadoDescricao',
                    'Revise ou limpe os filtros para ver outras vendas em aberto.',
                  )
                : _txt(
                    'vendasNaoLiquidadas.vazioDescricao',
                    'Quando uma venda for marcada para receber depois, ela aparecerá aqui.',
                  ),
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.4),
          ),
          if (filtrada) ...<Widget>[
            SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _limparFiltros,
              icon: Icon(Icons.filter_alt_off_rounded),
              label: Text(_txt('common.clearFilters', 'Limpar filtros')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estado({
    Key? key,
    required IconData icon,
    required String titulo,
    required String mensagem,
  }) {
    return Padding(
      key: key,
      padding: EdgeInsets.only(top: 24),
      child: _baseCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _icon(
              icon,
              bg: _withAlpha(_accentColor, 0.10),
              fg: _accentColor,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _titleTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedTextColor, height: 1.4),
            ),
            SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _carregar,
              icon: Icon(Icons.refresh_rounded),
              label: Text(_txt('common.refresh', 'Atualizar')),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState({Key? key}) {
    return Semantics(
      key: key,
      container: true,
      liveRegion: true,
      label: _txt(
        'vendasNaoLiquidadas.carregando',
        'Carregando vendas a receber',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _loadingHeader(),
          SizedBox(height: 14),
          _loadingFiltersCard(),
          SizedBox(height: 18),
          _section(
            _txt('vendasNaoLiquidadas.secaoAbertas', 'Vendas em aberto'),
          ),
          SizedBox(height: 12),
          ...List<Widget>.generate(
            3,
            (int index) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _loadingVendaCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingHeader() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(color: _heroShadow, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(
                Icons.point_of_sale_outlined,
                bg: _withAlpha(SixMobilePalette.onPrimary, 0.12),
                fg: SixMobilePalette.onPrimary,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonLine(width: 190, colorOnDark: true),
                    SizedBox(height: 8),
                    _skeletonLine(width: 150, height: 12, colorOnDark: true),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _withAlpha(SixMobilePalette.onPrimary, 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _withAlpha(SixMobilePalette.onPrimary, 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _skeletonLine(width: 98, height: 12, colorOnDark: true),
                SizedBox(height: 8),
                _skeletonLine(width: 150, height: 24, colorOnDark: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingVendaCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(
                Icons.receipt_long_outlined,
                bg: _softAccentSurface,
                fg: _accentColor,
                size: 48,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonLine(width: double.infinity, height: 16),
                    SizedBox(height: 8),
                    _skeletonLine(width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _skeletonLine(width: 220, height: 28),
          SizedBox(height: 14),
          _skeletonLine(width: 145, height: 20),
          SizedBox(height: 10),
          _skeletonLine(width: double.infinity, height: 42),
        ],
      ),
    );
  }

  Widget _loadingFiltersCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _skeletonLine(width: double.infinity, height: 52),
          SizedBox(height: 12),
          _skeletonLine(width: 150, height: 42),
          SizedBox(height: 10),
          _skeletonLine(width: 230, height: 12),
        ],
      ),
    );
  }

  Widget _cancelamentoResumo(VendaNaoLiquidadaModel venda) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  venda.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatarData(venda.dataCompetencia),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              _formatarValor(venda.valorAberto),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: _titleTextColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _colors.navigationShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _icon(
    IconData icon, {
    required Color bg,
    required Color fg,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size >= 48 ? 18 : 14),
      ),
      child: Icon(icon, color: fg, size: size >= 48 ? 24 : 20),
    );
  }

  Widget _pill(String label, {Color? fg, Color? bg}) {
    final Color foreground = fg ?? _mutedTextColor;
    final Color background = bg ?? _softSurface;

    return Container(
      constraints: BoxConstraints(maxWidth: 260),
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _skeletonLine({
    required double width,
    double height = 14,
    bool colorOnDark = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorOnDark
            ? _withAlpha(SixMobilePalette.onPrimary, 0.18)
            : _withAlpha(_borderColor, 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _titleTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _VendasNaoLiquidadasFilterDraft {
  const _VendasNaoLiquidadasFilterDraft({
    required this.periodo,
    required this.dataInicio,
    required this.dataFim,
    required this.idsVendedores,
    required this.statusFinanceiro,
    required this.ordenacao,
    required this.valorMinimo,
    required this.valorMaximo,
  });

  final String periodo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final Set<String> idsVendedores;
  final String? statusFinanceiro;
  final String ordenacao;
  final String valorMinimo;
  final String valorMaximo;

  _VendasNaoLiquidadasFilterDraft copyWith({
    String? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    Set<String>? idsVendedores,
    String? statusFinanceiro,
    String? ordenacao,
    String? valorMinimo,
    String? valorMaximo,
    bool limparStatusFinanceiro = false,
  }) {
    return _VendasNaoLiquidadasFilterDraft(
      periodo: periodo ?? this.periodo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      idsVendedores: Set<String>.from(idsVendedores ?? this.idsVendedores),
      statusFinanceiro: limparStatusFinanceiro
          ? null
          : statusFinanceiro ?? this.statusFinanceiro,
      ordenacao: ordenacao ?? this.ordenacao,
      valorMinimo: valorMinimo ?? this.valorMinimo,
      valorMaximo: valorMaximo ?? this.valorMaximo,
    );
  }
}

class _VendasNaoLiquidadasFilterSheet extends StatefulWidget {
  const _VendasNaoLiquidadasFilterSheet({
    required this.initialDraft,
    required this.sellerOptions,
    required this.sellersLoading,
    required this.sellersLoadFailed,
    required this.sellerSelectionLabelBuilder,
    required this.formatDate,
    required this.periodLabelBuilder,
    required this.financialStatusLabelBuilder,
    required this.orderLabelBuilder,
    required this.showDateSheet,
  });

  final _VendasNaoLiquidadasFilterDraft initialDraft;
  final List<SixMobileSelectionOption<String>> sellerOptions;
  final bool sellersLoading;
  final bool sellersLoadFailed;
  final String Function(Set<String> values) sellerSelectionLabelBuilder;
  final String Function(DateTime value) formatDate;
  final String Function(String value) periodLabelBuilder;
  final String Function(String value) financialStatusLabelBuilder;
  final String Function(String value) orderLabelBuilder;
  final Future<DateTime?> Function({
    required DateTime initialDate,
    required DateTime minimumDate,
    required String title,
  })
  showDateSheet;

  @override
  State<_VendasNaoLiquidadasFilterSheet> createState() =>
      _VendasNaoLiquidadasFilterSheetState();
}

class _VendasNaoLiquidadasFilterSheetState
    extends State<_VendasNaoLiquidadasFilterSheet> {
  late _VendasNaoLiquidadasFilterDraft _draft;
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
      title: context.t('sales.query.period', fallback: 'Período'),
      subtitle: context.t(
        'sales.query.mobile.periodSubtitle',
        fallback: 'Defina o período das vendas em aberto.',
      ),
      options: _VendasNaoLiquidadasMobileScreenState._periodos
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

  Future<void> _pickVendedores() async {
    final Set<String>?
    selected = await showSixMobileMultiSelectionSheet<String>(
      context: context,
      title: context.t('sales.query.sellers', fallback: 'Vendedores'),
      subtitle: context.t(
        'sales.query.mobile.sellersSubtitle',
        fallback:
            'Selecione um ou mais vendedores. Sem seleção, todos serão considerados.',
      ),
      options: widget.sellerOptions,
      selectedValues: _draft.idsVendedores,
      allLabel: context.t(
        'sales.query.allSellers',
        fallback: 'Todos os vendedores',
      ),
      searchHint: context.t(
        'sales.query.searchSeller',
        fallback: 'Buscar vendedor',
      ),
      emptyTitle: context.t(
        widget.sellersLoadFailed
            ? 'sales.query.sellersLoadError'
            : 'sales.query.noSellers',
        fallback: widget.sellersLoadFailed
            ? 'Não foi possível carregar os vendedores.'
            : 'Nenhum vendedor encontrado.',
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _draft = _draft.copyWith(idsVendedores: selected));
  }

  Future<void> _pickStatusFinanceiro() async {
    const String todos = 'TODOS';
    final String? selected = await showSixMobileSelectionSheet<String>(
      context: context,
      title: context.t(
        'sales.query.financialStatus',
        fallback: 'Situação financeira',
      ),
      options: <SixMobileSelectionOption<String>>[
        SixMobileSelectionOption<String>(
          value: todos,
          title: context.t('common.all', fallback: 'Todas'),
          icon: Icons.filter_alt_outlined,
        ),
        ..._VendasNaoLiquidadasMobileScreenState._statusFinanceiros.map(
          (String value) => SixMobileSelectionOption<String>(
            value: value,
            title: widget.financialStatusLabelBuilder(value),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
      selectedValue: _draft.statusFinanceiro ?? todos,
      emptyTitle: context.t('common.noResults', fallback: 'Nenhum resultado'),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _draft = _draft.copyWith(
        statusFinanceiro: selected == todos ? null : selected,
        limparStatusFinanceiro: selected == todos,
      );
    });
  }

  Future<void> _pickOrdenacao() async {
    final String? selected = await showSixMobileSelectionSheet<String>(
      context: context,
      title: context.t('sales.query.order', fallback: 'Ordenar por'),
      options: _VendasNaoLiquidadasMobileScreenState._ordenacoes
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
    final DateTime? selected = await widget.showDateSheet(
      initialDate: initial,
      minimumDate: minimum,
      title: inicio
          ? context.t('sales.query.startDate', fallback: 'Data inicial')
          : context.t('sales.query.endDate', fallback: 'Data final'),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (inicio) {
        _draft = _draft.copyWith(dataInicio: selected);
        if (_draft.dataFim.isBefore(selected)) {
          _draft = _draft.copyWith(dataFim: selected);
        }
      } else {
        _draft = _draft.copyWith(dataFim: selected);
      }
    });
  }

  void _clear() {
    final DateTime hoje = DateTime.now();
    setState(() {
      _draft = _draft.copyWith(
        periodo: _VendasNaoLiquidadasMobileScreenState._periodoUltimos30Dias,
        dataInicio: hoje.subtract(const Duration(days: 29)),
        dataFim: hoje,
        idsVendedores: <String>{},
        statusFinanceiro: null,
        ordenacao: 'MAIS_RECENTES',
        valorMinimo: '',
        valorMaximo: '',
        limparStatusFinanceiro: true,
      );
      _valorMinimoController.clear();
      _valorMaximoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool sellerEnabled =
        !widget.sellersLoading ||
        widget.sellerOptions.isNotEmpty ||
        _draft.idsVendedores.isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
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
                  SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.strongBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 16, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                context.t(
                                  'vendasNaoLiquidadas.filtrosTitulo',
                                  fallback: 'Filtros das vendas a receber',
                                ),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: colors.titleText,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                context.t(
                                  'vendasNaoLiquidadas.filtrosDescricao',
                                  fallback:
                                      'Ajuste período, vendedores, situação e valores.',
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
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
                      children: <Widget>[
                        SixMobileSelectionField(
                          label: context.t(
                            'sales.query.period',
                            fallback: 'Período',
                          ),
                          value: widget.periodLabelBuilder(_draft.periodo),
                          icon: Icons.date_range_rounded,
                          onTap: _pickPeriodo,
                        ),
                        if (_draft.periodo ==
                            _VendasNaoLiquidadasMobileScreenState
                                ._periodoPersonalizado) ...<Widget>[
                          SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: SixMobileSelectionField(
                                  label: context.t(
                                    'sales.query.startDate',
                                    fallback: 'Data inicial',
                                  ),
                                  value: widget.formatDate(_draft.dataInicio),
                                  icon: Icons.event_rounded,
                                  onTap: () => _pickData(inicio: true),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: SixMobileSelectionField(
                                  label: context.t(
                                    'sales.query.endDate',
                                    fallback: 'Data final',
                                  ),
                                  value: widget.formatDate(_draft.dataFim),
                                  icon: Icons.event_available_rounded,
                                  onTap: () => _pickData(inicio: false),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 12),
                        SixMobileSelectionField(
                          label: context.t(
                            'sales.query.sellers',
                            fallback: 'Vendedores',
                          ),
                          value:
                              widget.sellersLoading &&
                                  _draft.idsVendedores.isEmpty &&
                                  widget.sellerOptions.isEmpty
                              ? context.t(
                                  'sales.query.loadingSellers',
                                  fallback: 'Carregando vendedores...',
                                )
                              : widget.sellerSelectionLabelBuilder(
                                  _draft.idsVendedores,
                                ),
                          helperText: widget.sellersLoadFailed
                              ? context.t(
                                  'sales.query.sellersLoadErrorShort',
                                  fallback: 'Lista indisponível no momento',
                                )
                              : null,
                          icon: Icons.people_alt_outlined,
                          enabled: sellerEnabled,
                          onTap: _pickVendedores,
                        ),
                        SizedBox(height: 12),
                        SixMobileSelectionField(
                          label: context.t(
                            'sales.query.financialStatus',
                            fallback: 'Situação financeira',
                          ),
                          value: _draft.statusFinanceiro == null
                              ? context.t('common.all', fallback: 'Todas')
                              : widget.financialStatusLabelBuilder(
                                  _draft.statusFinanceiro!,
                                ),
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: _pickStatusFinanceiro,
                        ),
                        SizedBox(height: 12),
                        SixMobileSelectionField(
                          label: context.t(
                            'sales.query.order',
                            fallback: 'Ordenar por',
                          ),
                          value: widget.orderLabelBuilder(_draft.ordenacao),
                          icon: Icons.swap_vert_rounded,
                          onTap: _pickOrdenacao,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _valorMinimoController,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: context.t(
                                    'sales.query.minimumValue',
                                    fallback: 'Valor mínimo',
                                  ),
                                  filled: true,
                                  fillColor: colors.softSurface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _valorMaximoController,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: context.t(
                                    'sales.query.maximumValue',
                                    fallback: 'Valor máximo',
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
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                        SizedBox(width: 10),
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

class _VendasNaoLiquidadasDateSheet extends StatefulWidget {
  const _VendasNaoLiquidadasDateSheet({
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
  State<_VendasNaoLiquidadasDateSheet> createState() =>
      _VendasNaoLiquidadasDateSheetState();
}

class _VendasNaoLiquidadasDateSheetState
    extends State<_VendasNaoLiquidadasDateSheet> {
  late DateTime _selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                SizedBox(height: 14),
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
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: widget.minimumDate,
                  lastDate: widget.maximumDate,
                  onDateChanged: (DateTime value) {
                    setState(() => _selectedDate = value);
                  },
                ),
                SizedBox(height: 10),
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
                    SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedDate),
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

class _AnimatedMetricValue extends StatelessWidget {
  const _AnimatedMetricValue({
    super.key,
    required this.value,
    required this.formatter,
    required this.reduceMotion,
    required this.style,
  });

  final num value;
  final String Function(num value) formatter;
  final bool reduceMotion;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return _text(formatter(value));
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return _text(formatter(animatedValue));
      },
    );
  }

  Widget _text(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
