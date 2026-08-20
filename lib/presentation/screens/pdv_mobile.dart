import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/di/operacao_module.dart';
import '../../core/di/caixa_module.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/produto_helper.dart';
import '../../data/models/caixa_models.dart';
import '../../data/models/operacao_models.dart';
import '../../data/models/produto_model.dart';
import '../../data/models/recebimento_forma_input.dart';
import '../../data/models/venda_nao_liquidada_models.dart';
import '../../data/services/caixa/venda_nao_liquidada_api_client.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../../domain/services/operacao/operacao_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/usuario_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import 'operacoes_caixa_mobile_screen.dart';
import 'produto_list_mobile_screen.dart';

typedef PdvMobileProductSelectionLauncher = Future<dynamic> Function();
typedef PdvMobileBarcodeScannerLauncher = Future<String?> Function();
typedef PdvMobileBarcodeProductLoader =
    Future<List<ProdutoModel>> Function(BuildContext context, String tipo);
typedef PdvMobileCashOperationsLauncher = Future<void> Function();
typedef PdvMobileCurrentUserIdProvider = Future<String?> Function();
typedef PdvMobileCurrentUserNameProvider = String Function();
typedef PdvMobileNowProvider = DateTime Function();

class PdvMobileScreen extends StatefulWidget {
  const PdvMobileScreen({
    super.key,
    this.vendaNaoLiquidada,
    this.operacaoService,
    this.caixaService,
    this.vendaNaoLiquidadaApiClient,
    this.productSelectionLauncher,
    this.barcodeScannerLauncher,
    this.barcodeProductLoader,
    this.cashOperationsLauncher,
    this.currentUserIdProvider,
    this.currentUserNameProvider,
    this.nowProvider,
  });

  final VendaNaoLiquidadaModel? vendaNaoLiquidada;
  final OperacaoService? operacaoService;
  final CaixaService? caixaService;
  final VendaNaoLiquidadaApiClient? vendaNaoLiquidadaApiClient;
  final PdvMobileProductSelectionLauncher? productSelectionLauncher;
  final PdvMobileBarcodeScannerLauncher? barcodeScannerLauncher;
  final PdvMobileBarcodeProductLoader? barcodeProductLoader;
  final PdvMobileCashOperationsLauncher? cashOperationsLauncher;
  final PdvMobileCurrentUserIdProvider? currentUserIdProvider;
  final PdvMobileCurrentUserNameProvider? currentUserNameProvider;
  final PdvMobileNowProvider? nowProvider;

  @override
  State<PdvMobileScreen> createState() => _PdvMobileScreenState();
}

class _PdvMobileScreenState extends State<PdvMobileScreen> {
  static const double _cardRadius = 22;
  static const double _initialHeroRadius = 30;
  static const double _initialActionsRadius = 26;
  static const double _initialButtonRadius = 20;
  static const double _initialIllustrationSize = 72;
  static const double _initialIllustrationInnerSize = 52;
  static const Duration _entryDuration = Duration(milliseconds: 340);
  static const Duration _stateTransitionDuration = Duration(milliseconds: 340);
  static const Duration _pressDuration = Duration(milliseconds: 100);

  static const List<_FormaPagamentoMobile>
  _formasPagamentoFallback = <_FormaPagamentoMobile>[
    _FormaPagamentoMobile('TIPO1', 'Dinheiro', Icons.payments_outlined),
    _FormaPagamentoMobile('TIPO2', 'Pix', Icons.qr_code_2_outlined),
    _FormaPagamentoMobile(
      'TIPO3',
      'Cartão crédito',
      Icons.credit_card_outlined,
    ),
    _FormaPagamentoMobile(
      'TIPO4',
      'Cartão débito',
      Icons.point_of_sale_outlined,
    ),
    _FormaPagamentoMobile('TIPO5', 'Boleto', Icons.receipt_long_outlined),
    _FormaPagamentoMobile('TIPO6', 'Fiado', Icons.history_toggle_off_outlined),
    _FormaPagamentoMobile('TIPO7', 'Crediário', Icons.event_note_outlined),
    _FormaPagamentoMobile('TIPO8', 'Convênio', Icons.people_outline),
    _FormaPagamentoMobile('TIPO9', 'Vale', Icons.confirmation_number_outlined),
    _FormaPagamentoMobile('TIPO10', 'Outros', Icons.more_horiz_outlined),
  ];

  late final OperacaoService _operacaoService;
  late final CaixaService _caixaService;
  late final VendaNaoLiquidadaApiClient _vendaNaoLiquidadaApiClient;
  final List<_VendaItemMobile> _itens = <_VendaItemMobile>[];
  final Set<String> _formasSelecionadas = <String>{};
  final Map<String, TextEditingController> _valorPorForma =
      <String, TextEditingController>{};
  final GlobalKey _pagamentoKey = GlobalKey();

  List<_FormaPagamentoMobile> _formasPagamento =
      List<_FormaPagamentoMobile>.from(_formasPagamentoFallback);

  bool _enviando = false;
  bool _buscandoCodigo = false;
  bool _destacarPagamento = false;
  bool _carregandoSessaoCaixa = false;
  bool _erroSessaoCaixa = false;
  CaixaSessao? _sessaoCaixa;

  bool get _editandoVendaNaoLiquidada => widget.vendaNaoLiquidada != null;
  double get _total => _itens.fold<double>(0, (s, item) => s + item.subtotal);
  int get _quantidadeItens =>
      _itens.fold<int>(0, (s, item) => s + item.quantidade);
  bool get _busyOrLoadingSession =>
      _enviando || _buscandoCodigo || _carregandoSessaoCaixa;

  static Color _withAlpha(Color color, double opacity) {
    return color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
  }

  Color get _warningColor =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF59E0B)
          : const Color(0xFF92400E);

  Color get _successColor =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF34D399)
          : const Color(0xFF047857);

  @override
  void initState() {
    super.initState();
    _operacaoService = widget.operacaoService ?? OperacaoModule.operacaoService;
    _caixaService = widget.caixaService ?? CaixaModule.caixaService;
    _vendaNaoLiquidadaApiClient =
        widget.vendaNaoLiquidadaApiClient ?? VendaNaoLiquidadaApiClient();
    final venda = widget.vendaNaoLiquidada;
    if (venda != null) {
      _itens.addAll(
        venda.itens.map(_VendaItemMobile.fromVendaNaoLiquidadaItem),
      );
    }
    _carregarSessaoCaixa();
    _carregarTiposPagamentoConfigurados();
  }

  @override
  void dispose() {
    for (final controller in _valorPorForma.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarTiposPagamentoConfigurados() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaService.buscarInformacoesBasicasDoCaixa();
      final List<_FormaPagamentoMobile> formas =
          _montarFormasPagamentoConfiguradas(informacoes.tiposRecebimento);
      if (!mounted || formas.isEmpty) return;
      setState(() {
        _formasPagamento = formas;
        _removerFormasSelecionadasInativas();
      });
    } catch (_) {
      // Mantém o fallback local para não bloquear o PDV se o backend falhar.
    }
  }

  Future<void> _carregarSessaoCaixa() async {
    if (_carregandoSessaoCaixa) {
      return;
    }

    setState(() {
      _carregandoSessaoCaixa = true;
      _erroSessaoCaixa = false;
    });

    try {
      final CaixaSessao? sessao = await _caixaService.buscarSessaoAtual();
      if (!mounted) {
        return;
      }

      setState(() {
        _sessaoCaixa = sessao;
        _erroSessaoCaixa = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sessaoCaixa = null;
        _erroSessaoCaixa = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregandoSessaoCaixa = false;
        });
      }
    }
  }

  bool get _caixaAbertoParaVenda {
    final CaixaSessao? sessao = _sessaoCaixa;
    return sessao != null && _sessaoCaixaAberta(sessao);
  }

  Future<bool> _garantirCaixaAbertoParaVenda() async {
    if (_caixaAbertoParaVenda) {
      return true;
    }

    if (!_carregandoSessaoCaixa) {
      await _carregarSessaoCaixa();
      if (_caixaAbertoParaVenda) {
        return true;
      }
    }

    if (!mounted) {
      return false;
    }

    _mostrarSnack(
      _txt(
        'pdv.cashSessionRequiredMessage',
        'Abra uma sessão de caixa antes de lançar vendas no PDV.',
      ),
    );
    return false;
  }

  Future<void> _abrirOperacoesCaixaMobile() async {
    final PdvMobileCashOperationsLauncher? cashOperationsLauncher =
        widget.cashOperationsLauncher;
    if (cashOperationsLauncher != null) {
      await cashOperationsLauncher();
    } else {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => OperacoesCaixaMobileScreen()),
      );
    }

    if (!mounted) return;
    await _carregarSessaoCaixa();
    await _carregarTiposPagamentoConfigurados();
  }

  List<_FormaPagamentoMobile> _montarFormasPagamentoConfiguradas(
    List<TiposRecebimento> tipos,
  ) {
    final List<TiposRecebimento> ativos =
        tipos.where((TiposRecebimento tipo) => tipo.ativo).toList()..sort(
          (TiposRecebimento a, TiposRecebimento b) =>
              a.ordemExibicao.compareTo(b.ordemExibicao),
        );

    final Set<String> codigosAdicionados = <String>{};
    final List<_FormaPagamentoMobile> formas = <_FormaPagamentoMobile>[];
    for (final TiposRecebimento tipo in ativos) {
      final String codigo = tipo.codigoTipo.trim().toUpperCase();
      if (!_codigoTipoValido(codigo) || codigosAdicionados.contains(codigo)) {
        continue;
      }
      final String descricao =
          tipo.descricaoExibicao.trim().isNotEmpty
              ? tipo.descricaoExibicao.trim()
              : _descricaoPadraoPorCodigoTipo(codigo);
      formas.add(
        _FormaPagamentoMobile(codigo, descricao, _iconePorCodigoTipo(codigo)),
      );
      codigosAdicionados.add(codigo);
    }
    return formas;
  }

  bool _codigoTipoValido(String codigo) {
    return RegExp(r'^TIPO(10|[1-9])$').hasMatch(codigo);
  }

  void _removerFormasSelecionadasInativas() {
    final Set<String> codigosAtivos =
        _formasPagamento.map((forma) => forma.codigo).toSet();
    for (final String codigo in List<String>.from(_formasSelecionadas)) {
      if (codigosAtivos.contains(codigo)) continue;
      _formasSelecionadas.remove(codigo);
      _valorPorForma[codigo]?.clear();
    }
  }

  String _descricaoPadraoPorCodigoTipo(String codigo) {
    switch (codigo) {
      case 'TIPO1':
        return 'Dinheiro';
      case 'TIPO2':
        return 'Pix';
      case 'TIPO3':
        return 'Cartão crédito';
      case 'TIPO4':
        return 'Cartão débito';
      case 'TIPO5':
        return 'Boleto';
      case 'TIPO6':
        return 'Fiado';
      case 'TIPO7':
        return 'Crediário';
      case 'TIPO8':
        return 'Convênio';
      case 'TIPO9':
        return 'Vale';
      case 'TIPO10':
        return 'Outros';
      default:
        return codigo;
    }
  }

  IconData _iconePorCodigoTipo(String codigo) {
    switch (codigo) {
      case 'TIPO1':
        return Icons.payments_outlined;
      case 'TIPO2':
        return Icons.qr_code_2_outlined;
      case 'TIPO3':
        return Icons.credit_card_outlined;
      case 'TIPO4':
        return Icons.point_of_sale_outlined;
      case 'TIPO5':
        return Icons.receipt_long_outlined;
      case 'TIPO6':
        return Icons.history_toggle_off_outlined;
      case 'TIPO7':
        return Icons.event_note_outlined;
      case 'TIPO8':
        return Icons.people_outline;
      case 'TIPO9':
        return Icons.confirmation_number_outlined;
      default:
        return Icons.more_horiz_outlined;
    }
  }

  Future<void> _abrirSelecaoProduto() async {
    final PdvMobileProductSelectionLauncher? productSelectionLauncher =
        widget.productSelectionLauncher;
    final NavigatorState navigator = Navigator.of(context);

    if (!await _garantirCaixaAbertoParaVenda()) {
      return;
    }
    if (!mounted) {
      return;
    }

    final dynamic result =
        productSelectionLauncher != null
            ? await productSelectionLauncher()
            : await navigator.push<dynamic>(
              MaterialPageRoute<dynamic>(
                builder:
                    (_) => ProdutolistMobileScreen(
                      isSelecao: true,
                      permitirSelecaoMultipla: true,
                    ),
              ),
            );

    if (!mounted || result == null) return;

    if (result is ProdutoModel) {
      _adicionarProdutoSelecionado(result);
      return;
    }

    if (result is List) {
      final produtos = result.whereType<ProdutoModel>().toList(growable: false);
      if (produtos.isNotEmpty) _adicionarProdutosSelecionados(produtos);
    }
  }

  Future<void> _abrirScannerCodigoBarras() async {
    if (_enviando || _buscandoCodigo) return;
    final PdvMobileBarcodeScannerLauncher? barcodeScannerLauncher =
        widget.barcodeScannerLauncher;
    final NavigatorState navigator = Navigator.of(context);

    if (!await _garantirCaixaAbertoParaVenda()) {
      return;
    }
    if (!mounted) {
      return;
    }

    final String? codigo =
        barcodeScannerLauncher != null
            ? await barcodeScannerLauncher()
            : await navigator.push<String>(
              MaterialPageRoute<String>(
                builder: (_) => const _BarcodeScannerMobileScreen(),
              ),
            );

    if (codigo == null || codigo.trim().isEmpty) return;
    await _buscarEAdicionarProdutoPorCodigo(codigo.trim());
  }

  Future<void> _buscarEAdicionarProdutoPorCodigo(String codigo) async {
    if (_buscandoCodigo) return;

    setState(() => _buscandoCodigo = true);
    try {
      final List<ProdutoModel> produtos =
          await _carregarProdutosParaCodigoBarras();

      final codigoNormalizado = codigo.toLowerCase();
      ProdutoModel? encontrado;
      for (final produto in produtos) {
        if (produto.codigoDeBarras.trim().toLowerCase() == codigoNormalizado) {
          encontrado = produto;
          break;
        }
      }

      if (!mounted) return;
      if (encontrado == null) {
        _mostrarSnack('Produto não encontrado para o código $codigo.');
        return;
      }

      _adicionarProdutoSelecionado(encontrado);
      _mostrarSnack('${encontrado.nomeProduto} adicionado à venda.');
    } catch (_) {
      if (mounted) {
        _mostrarSnack('Não foi possível buscar o produto pelo código.');
      }
    } finally {
      if (mounted) setState(() => _buscandoCodigo = false);
    }
  }

  Future<List<ProdutoModel>> _carregarProdutosParaCodigoBarras() async {
    final PdvMobileBarcodeProductLoader? barcodeProductLoader =
        widget.barcodeProductLoader;
    if (barcodeProductLoader != null) {
      return barcodeProductLoader(context, 'PRODUTO');
    }

    List<ProdutoModel> produtos = <ProdutoModel>[];
    await ProdutoHelper.retornarProdutosList(
      context,
      tipo: 'PRODUTO',
      produtosAtivos: true,
      onSucesso: (lista) => produtos = lista,
    );
    return produtos;
  }

  void _adicionarProdutoSelecionado(ProdutoModel produto) {
    setState(() => _adicionarProdutoNaListaSemSetState(produto));
  }

  void _adicionarProdutosSelecionados(List<ProdutoModel> produtos) {
    if (produtos.isEmpty) return;
    setState(() {
      for (final produto in produtos) {
        _adicionarProdutoNaListaSemSetState(produto);
      }
    });
  }

  void _adicionarProdutoNaListaSemSetState(ProdutoModel produto) {
    final idProduto = produto.id ?? produto.codigoDeBarras;
    final tipoNormalizado = produto.tipoProduto.toUpperCase();
    final ehServico =
        tipoNormalizado == 'SERVICO' || tipoNormalizado == 'SERVIÇO';
    final index = _itens.indexWhere((item) => item.idProduto == idProduto);

    if (index >= 0) {
      _itens[index] = _itens[index].copyWith(
        quantidade: _itens[index].quantidade + 1,
      );
      return;
    }

    _itens.add(
      _VendaItemMobile(
        idProduto: idProduto,
        nome: produto.nomeProduto,
        valorUnitario: produto.precoVenda,
        quantidade: 1,
        ehServico: ehServico,
      ),
    );
  }

  Future<void> _finalizarVenda() async {
    if (!await _garantirCaixaAbertoParaVenda()) {
      return;
    }

    if (_itens.isEmpty) {
      _mostrarSnack('Inclua pelo menos um item para finalizar.');
      return;
    }
    if (_formasSelecionadas.isEmpty) {
      await _avisarPagamentoObrigatorio();
      return;
    }
    final formas = _montarFormasPagamento();
    final totalPago = formas.fold<double>(
      0,
      (soma, forma) => soma + forma.valor,
    );
    if ((totalPago - _total).abs() > 0.009) {
      _mostrarSnack('A soma dos pagamentos precisa fechar o total da venda.');
      return;
    }

    await _enviarVenda(receberDepois: false, formasPagamento: formas);
  }

  Future<void> _avisarPagamentoObrigatorio() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (!_destacarPagamento && mounted) {
      setState(() => _destacarPagamento = true);
    }

    await Future<void>.delayed(Duration(milliseconds: 40));
    final pagamentoContext = _pagamentoKey.currentContext;
    if (pagamentoContext != null && pagamentoContext.mounted) {
      await Scrollable.ensureVisible(
        pagamentoContext,
        duration: Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        alignment: 0.10,
      );
    }

    // _mostrarSnack('Selecione uma forma de pagamento ou use Receber depois.');
    await Future<void>.delayed(Duration(milliseconds: 1100));
    if (mounted) setState(() => _destacarPagamento = false);
  }

  Future<void> _receberDepois() async {
    if (_editandoVendaNaoLiquidada) {
      Navigator.of(context).pop(false);
      return;
    }
    if (!await _garantirCaixaAbertoParaVenda()) {
      return;
    }
    if (!mounted) {
      return;
    }
    if (_itens.isEmpty) {
      _mostrarSnack('Inclua pelo menos um item para registrar a venda.');
      return;
    }

    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _withAlpha(Colors.black, 0.42),
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
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
                  children: <Widget>[
                    _modalIcon(Icons.schedule_send_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Receber depois',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'A venda ficará em aberto para liquidação no caixa.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: SixMobilePalette.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                _buildResumoReceberDepois(),
                SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(true),
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('Registrar para receber depois'),
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(false),
                  icon: Icon(Icons.close_rounded),
                  label: Text('Voltar'),
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
      },
    );

    if (confirmou == true) {
      await _enviarVenda(
        receberDepois: true,
        formasPagamento: <FormaPagamentoSelecionada>[],
      );
    }
  }

  Future<void> _enviarVenda({
    required bool receberDepois,
    required List<FormaPagamentoSelecionada> formasPagamento,
  }) async {
    if (!await _garantirCaixaAbertoParaVenda()) {
      return;
    }

    setState(() => _enviando = true);
    try {
      if (_editandoVendaNaoLiquidada && !receberDepois) {
        await _liquidarVendaNaoLiquidada(formasPagamento);
        return;
      }

      final PdvMobileCurrentUserIdProvider? currentUserIdProvider =
          widget.currentUserIdProvider;
      final PdvMobileCurrentUserNameProvider? currentUserNameProvider =
          widget.currentUserNameProvider;
      final PdvMobileNowProvider? nowProvider = widget.nowProvider;
      final idColaborador =
          await (currentUserIdProvider?.call() ?? AuthService().getUserId()) ??
          '';
      final nomeColaborador =
          currentUserNameProvider?.call() ?? _nomeColaboradorAtual();
      final dataOperacao = nowProvider?.call() ?? DateTime.now();
      final input = OperacaoVendaInput(
        descricao:
            receberDepois
                ? 'Venda mobile para receber depois ${dataOperacao.toIso8601String()}'
                : 'Venda mobile ${dataOperacao.toIso8601String()}',
        idColaborador: idColaborador,
        nomeColaborador: nomeColaborador,
        itens: _itens.map((item) => item.toInput()).toList(growable: false),
        formasPagamento: formasPagamento,
        dataOperacao: dataOperacao,
        receberDepois: receberDepois,
      );

      await _operacaoService.finalizarVenda(input);
      if (!mounted) return;
      _limparVenda();
      _mostrarSnack(
        receberDepois
            ? 'Venda registrada para receber depois.'
            : 'Venda finalizada com sucesso.',
      );
    } catch (e) {
      if (mounted) _mostrarSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _liquidarVendaNaoLiquidada(
    List<FormaPagamentoSelecionada> formasPagamento,
  ) async {
    final venda = widget.vendaNaoLiquidada!;
    final FormaPagamentoSelecionada primeiraForma = formasPagamento.first;
    final List<RecebimentoFormaInput> recebimentos = formasPagamento
        .map(
          (FormaPagamentoSelecionada forma) => RecebimentoFormaInput(
            codigo: forma.codigo.toLowerCase(),
            descricao: _descricaoFormaPagamentoSelecionada(forma.codigo),
            valor: forma.valor,
          ),
        )
        .toList(growable: false);
    final double valorRecebido = recebimentos.fold<double>(
      0,
      (double total, RecebimentoFormaInput forma) => total + forma.valor,
    );
    await _vendaNaoLiquidadaApiClient.liquidar(
      idRecebimento: venda.idRecebimento,
      input: LiquidarVendaNaoLiquidadaInput(
        codigoTipoRecebimento: primeiraForma.codigo.toLowerCase(),
        valorRecebido: valorRecebido,
        recebimentos: recebimentos,
        itens: _itens
            .map((item) => item.toVendaNaoLiquidadaItem())
            .toList(growable: false),
        observacao: 'Recebido pelo PDV mobile',
        idSessaoCaixa: _idSessaoCaixaAtual,
      ),
    );

    if (!mounted) return;
    _mostrarSnack('Venda recebida com sucesso.');
    Navigator.of(context).pop(true);
  }

  String _descricaoFormaPagamentoSelecionada(String codigo) {
    for (final _FormaPagamentoMobile forma in _formasPagamento) {
      if (forma.codigo == codigo) return forma.titulo;
    }
    return _descricaoPadraoPorCodigoTipo(codigo);
  }

  String? get _idSessaoCaixaAtual {
    final String? idSessaoCaixa = _sessaoCaixa?.idSessaoCaixa.trim();
    return idSessaoCaixa == null || idSessaoCaixa.isEmpty
        ? null
        : idSessaoCaixa;
  }

  void _limparVenda() {
    setState(() {
      _itens.clear();
      _formasSelecionadas.clear();
      _destacarPagamento = false;
      for (final controller in _valorPorForma.values) {
        controller.clear();
      }
    });
  }

  void _cancelarVenda() {
    if (_editandoVendaNaoLiquidada) {
      Navigator.of(context).pop(false);
      return;
    }
    _limparVenda();
    _mostrarSnack('Venda cancelada.');
  }

  Widget _modalIcon(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: SixMobilePalette.accent),
    );
  }

  Widget _buildResumoReceberDepois() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SixMobilePalette.highlightedBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Valor em aberto',
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            _formatarValor(_total),
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  List<FormaPagamentoSelecionada> _montarFormasPagamento() {
    if (_formasSelecionadas.length == 1) {
      final codigo = _formasSelecionadas.first;
      final valorDigitado = _valorDigitadoForma(codigo);
      return <FormaPagamentoSelecionada>[
        FormaPagamentoSelecionada(
          codigo: codigo,
          valor: valorDigitado > 0 ? valorDigitado : _total,
        ),
      ];
    }
    return _formasSelecionadas
        .map(
          (codigo) => FormaPagamentoSelecionada(
            codigo: codigo,
            valor: _valorDigitadoForma(codigo),
          ),
        )
        .toList(growable: false);
  }

  double _valorDigitadoForma(String codigoForma) {
    final raw = _valorPorForma[codigoForma]?.text ?? '';
    final localeSettings = context.read<LocaleSettingsProvider>();
    final normalizado =
        localeSettings.stripCurrencyMarkers(raw).replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0.0;
  }

  double _valorSelecionadoTotal() {
    if (_formasSelecionadas.isEmpty) return 0.0;
    return _montarFormasPagamento().fold<double>(
      0.0,
      (soma, forma) => soma + forma.valor,
    );
  }

  double _valorRestante() => _total - _valorSelecionadoTotal();

  void _preencherValorRestante(String codigoForma) {
    _valorPorForma.putIfAbsent(codigoForma, () => TextEditingController());
    final controller = _valorPorForma[codigoForma]!;
    final atual = _valorDigitadoForma(codigoForma);
    final restante = _valorRestante();
    final novoValor = (atual + restante).clamp(0.0, _total).toDouble();

    setState(() {
      controller.text = novoValor.toStringAsFixed(2);
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      _formasSelecionadas.add(codigoForma);
      _destacarPagamento = false;
    });
  }

  String _nomeColaboradorAtual() {
    final usuario = UsuarioProvider().usuario;
    if (usuario == null) return 'Colaborador';
    if (usuario.nomeDeGuerra.trim().isNotEmpty) {
      return usuario.nomeDeGuerra.trim();
    }
    final nomeCompleto = '${usuario.nome} ${usuario.sobrenome}'.trim();
    return nomeCompleto.isEmpty ? 'Colaborador' : nomeCompleto;
  }

  String _formatarValor(double valor) {
    return context.read<LocaleSettingsProvider>().formatCurrency(valor);
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temItens = _itens.isNotEmpty;
    final bottomPadding = temItens ? 178.0 : 28.0;

    return SixMobilePageShell(
      title:
          _editandoVendaNaoLiquidada
              ? 'Receber venda'
              : (temItens ? 'Balcão de venda' : 'Nova venda'),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 4,
      scrollEffectOffset: 24,
      scrolledSurfaceOpacity: 0.66,
      actions: <Widget>[
        IconButton(
          tooltip: 'Ler código',
          onPressed:
              _enviando || _buscandoCodigo || !_caixaAbertoParaVenda
                  ? null
                  : _abrirScannerCodigoBarras,
          icon: Icon(Icons.qr_code_scanner_rounded),
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topInset, 16, bottomPadding),
            children: <Widget>[
              SixStaggeredEntry(
                duration: _entryDuration,
                beginOffset: Offset(0, 0.035),
                child: AnimatedSwitcher(
                  duration: _stateTransitionDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    );
                  },
                  child: _buildHeader(),
                ),
              ),
              SizedBox(height: temItens ? 12 : 10),
              if (!_caixaAbertoParaVenda) ...<Widget>[
                SixStaggeredEntry(
                  delay: Duration(milliseconds: 40),
                  duration: _entryDuration,
                  beginOffset: Offset(0, 0.035),
                  child: _buildCaixaObrigatorioNotice(),
                ),
                SizedBox(height: 10),
              ],
              SixStaggeredEntry(
                delay: Duration(milliseconds: 70),
                duration: _entryDuration,
                beginOffset: Offset(0, 0.035),
                child: _buildQuickActionsCard(vendaIniciada: temItens),
              ),
              if (temItens) ...<Widget>[
                SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Column(
                    key: ValueKey<String>('pdv-content'),
                    children: <Widget>[
                      SixStaggeredEntry(
                        delay: Duration(milliseconds: 120),
                        duration: _entryDuration,
                        beginOffset: Offset(0, 0.035),
                        child: _buildItensCard(),
                      ),
                      SizedBox(height: 12),
                      SixStaggeredEntry(
                        delay: Duration(milliseconds: 170),
                        duration: _entryDuration,
                        beginOffset: Offset(0, 0.035),
                        child: _buildPagamentoCard(),
                      ),
                    ],
                  ),
                ),
              ] else ...<Widget>[
                SizedBox(height: _initialBottomBreathingSpace(context)),
              ],
            ],
          ),
        );
      },
      bottomNavigationBar: _itens.isEmpty ? null : _buildBottomActions(),
    );
  }

  double _initialBottomBreathingSpace(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;
    if (height < 680) return 20;
    if (height < 780) return 52;
    return 84;
  }

  Widget _buildCaixaObrigatorioNotice() {
    final Color color =
        _erroSessaoCaixa ? SixMobilePalette.error : _warningColor;
    final String title =
        _carregandoSessaoCaixa
            ? _txt(
              'pdv.cashSessionCheckingTitle',
              'Verificando sessão do caixa',
            )
            : _erroSessaoCaixa
            ? _txt(
              'pdv.cashSessionUnavailableTitle',
              'Não foi possível validar o caixa',
            )
            : _txt('pdv.cashSessionRequiredTitle', 'Abra o caixa para vender');
    final String message =
        _carregandoSessaoCaixa
            ? _txt(
              'pdv.cashSessionCheckingMessage',
              'Aguarde a sincronização antes de lançar uma nova venda.',
            )
            : _erroSessaoCaixa
            ? _txt(
              'pdv.cashSessionUnavailableMessage',
              'Atualize a sessão ou acesse operações de caixa para conferir a situação.',
            )
            : _txt(
              'pdv.cashSessionRequiredMessage',
              'Abra uma sessão de caixa antes de lançar vendas no PDV.',
            );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _withAlpha(color, 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _withAlpha(color, 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                _carregandoSessaoCaixa
                    ? Icons.sync_rounded
                    : Icons.lock_open_rounded,
                color: color,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.mutedText,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _carregandoSessaoCaixa ? null : _carregarSessaoCaixa,
                  icon: Icon(Icons.refresh_rounded),
                  label: Text(_txt('common.refresh', 'Atualizar')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _busyOrLoadingSession ? null : _abrirOperacoesCaixaMobile,
                  icon: Icon(Icons.point_of_sale_rounded),
                  label: Text(
                    _txt('pdv.openCashOperations', 'Operações de caixa'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(44),
                    backgroundColor: SixMobilePalette.accent,
                    foregroundColor: SixMobilePalette.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard({required bool vendaIniciada}) {
    return Material(
      color: SixMobilePalette.surface,
      borderRadius: BorderRadius.circular(
        vendaIniciada ? _cardRadius : _initialActionsRadius,
      ),
      child: Container(
        padding: EdgeInsets.all(vendaIniciada ? 12 : 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            vendaIniciada ? _cardRadius : _initialActionsRadius,
          ),
          border: Border.all(
            color:
                vendaIniciada
                    ? SixMobilePalette.border
                    : SixMobilePalette.activeBorder,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color:
                  vendaIniciada
                      ? SixMobilePalette.navigationShadow
                      : _withAlpha(SixMobilePalette.primary, 0.06),
              blurRadius: vendaIniciada ? 16 : 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child:
            vendaIniciada
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildQuickActionButton(
                            label: 'Adicionar produto',
                            helper: 'Produtos e serviços',
                            icon: Icons.add_shopping_cart_rounded,
                            onTap:
                                _enviando || !_caixaAbertoParaVenda
                                    ? null
                                    : _abrirSelecaoProduto,
                            compact: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickActionButton(
                            label:
                                _buscandoCodigo
                                    ? 'Buscando...'
                                    : 'Ler código de barras',
                            helper: 'Scanner',
                            icon: Icons.qr_code_scanner_rounded,
                            onTap:
                                _enviando ||
                                        _buscandoCodigo ||
                                        !_caixaAbertoParaVenda
                                    ? null
                                    : _abrirScannerCodigoBarras,
                            loading: _buscandoCodigo,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SixStaggeredEntry(
                      delay: Duration(milliseconds: 70),
                      duration: _entryDuration,
                      beginOffset: Offset(0, 0.035),
                      child: _buildQuickActionButton(
                        label: 'Adicionar produto',
                        helper: 'Escolher no catálogo',
                        icon: Icons.add_shopping_cart_rounded,
                        onTap:
                            _enviando || !_caixaAbertoParaVenda
                                ? null
                                : _abrirSelecaoProduto,
                      ),
                    ),
                    SizedBox(height: 8),
                    SixStaggeredEntry(
                      delay: Duration(milliseconds: 140),
                      duration: _entryDuration,
                      beginOffset: Offset(0, 0.035),
                      child: _buildQuickActionButton(
                        label:
                            _buscandoCodigo
                                ? 'Buscando...'
                                : 'Ler código de barras',
                        helper: 'Usar a câmera do aparelho',
                        icon: Icons.qr_code_scanner_rounded,
                        onTap:
                            _enviando ||
                                    _buscandoCodigo ||
                                    !_caixaAbertoParaVenda
                                ? null
                                : _abrirScannerCodigoBarras,
                        loading: _buscandoCodigo,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required String helper,
    required IconData icon,
    required VoidCallback? onTap,
    bool loading = false,
    bool primary = false,
    bool compact = false,
  }) {
    return _PdvActionButton(
      label: label,
      helper: helper,
      icon: icon,
      onTap: onTap,
      loading: loading,
      primary: primary,
      compact: compact,
      radius: _initialButtonRadius,
      pressDuration: _pressDuration,
    );
  }

  Widget _buildHeader() {
    if (_itens.isEmpty) {
      return _buildInitialSaleHero();
    }

    return Container(
      key: ValueKey<String>('pdv-active-hero'),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[SixMobilePalette.primary, SixMobilePalette.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _withAlpha(SixMobilePalette.onPrimary, 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _withAlpha(SixMobilePalette.onPrimary, 0.10),
                  ),
                ),
                child: Icon(
                  _editandoVendaNaoLiquidada
                      ? Icons.receipt_long_outlined
                      : Icons.shopping_bag_outlined,
                  color: SixMobilePalette.onPrimary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _editandoVendaNaoLiquidada
                          ? 'Venda em aberto'
                          : 'Venda no balcão',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      !_caixaAbertoParaVenda
                          ? _txt(
                            'pdv.cashSessionBlockedSubtitle',
                            'Caixa fechado: venda bloqueada',
                          )
                          : (_itens.isEmpty
                              ? 'Pronta para incluir itens'
                              : 'Revise itens e pagamento'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.heroSupportingText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildSessaoCaixaMobileChip(),
          SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Total da venda',
                      style: TextStyle(
                        color: SixMobilePalette.heroLabelText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    _buildAnimatedCurrencyText(
                      _total,
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _withAlpha(SixMobilePalette.onPrimary, 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Itens',
                      style: TextStyle(
                        color: SixMobilePalette.heroLabelText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SixAnimatedNumberText(
                      key: ValueKey<String>('pdv-items-$_quantidadeItens'),
                      value: _quantidadeItens.toString(),
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialSaleHero() {
    return Container(
      key: ValueKey<String>('pdv-initial-hero'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(_initialHeroRadius),
        border: Border.all(color: SixMobilePalette.activeBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _withAlpha(SixMobilePalette.primary, 0.055),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 4),
          _buildMinimalShoppingIllustration(),
          SizedBox(height: 16),
          Text(
            _editandoVendaNaoLiquidada ? 'Venda em aberto' : 'Nova venda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _editandoVendaNaoLiquidada
                ? 'Revise os itens antes de receber.'
                : (_caixaAbertoParaVenda
                    ? 'Seu caixa está pronto.'
                    : _txt(
                      'pdv.cashSessionOpenToSellHint',
                      'Abra o caixa para vender.',
                    )),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _editandoVendaNaoLiquidada
                ? 'Escolha uma opção abaixo para continuar.'
                : 'Escolha uma opção abaixo para começar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSessaoCaixaMobileChip({bool alignLeft = true}) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final _SessaoCaixaMobileView view = _sessaoCaixaMobileView(l10n);

    final Widget badge = Container(
      constraints: BoxConstraints(maxWidth: double.infinity),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: view.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: view.borderColor),
      ),
      child: Text(
        view.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: view.foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (!alignLeft) {
      return badge;
    }

    return Align(alignment: Alignment.centerLeft, child: badge);
  }

  Widget _buildSessaoAtivaOverlayBadge() {
    if (!_caixaAbertoParaVenda) {
      return SizedBox.shrink();
    }

    return _buildSessaoCaixaMobileChip(alignLeft: false);
  }

  Widget _buildSessionBadgeIcon({
    required IconData icon,
    required Color iconColor,
    required Color surfaceColor,
    required BorderRadius borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    double size = 46,
    double iconSize = 24,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: borderRadius,
              border: border,
              boxShadow: boxShadow,
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
          Positioned(
            top: -8,
            right: -76,
            child: _buildSessaoAtivaOverlayBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialSessionBadgeIcon() {
    return _buildSessionBadgeIcon(
      icon: Icons.shopping_bag_outlined,
      iconColor: SixMobilePalette.accent,
      iconSize: 26,
      size: _initialIllustrationInnerSize,
      surfaceColor: SixMobilePalette.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SixMobilePalette.activeBorder),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: SixMobilePalette.navigationShadow,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildInitialIllustrationDecoration() {
    return Container(
      width: _initialIllustrationSize,
      height: _initialIllustrationSize,
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: 20,
            right: 22,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: SixMobilePalette.softAccentSurface,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _withAlpha(SixMobilePalette.accent, 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          _buildInitialSessionBadgeIcon(),
        ],
      ),
    );
  }

  _SessaoCaixaMobileView _sessaoCaixaMobileView(AppLocalizations? l10n) {
    if (_carregandoSessaoCaixa) {
      return _SessaoCaixaMobileView(
        label: l10n?.pdvCashSessionChecking ?? 'Verificando sessão do caixa',
        foregroundColor: SixMobilePalette.primary,
        backgroundColor: _withAlpha(SixMobilePalette.primary, 0.09),
        borderColor: _withAlpha(SixMobilePalette.primary, 0.14),
      );
    }

    if (_erroSessaoCaixa) {
      return _SessaoCaixaMobileView(
        label: l10n?.pdvCashSessionUnavailable ?? 'Sessão indisponível',
        foregroundColor: SixMobilePalette.error,
        backgroundColor: _withAlpha(SixMobilePalette.error, 0.08),
        borderColor: _withAlpha(SixMobilePalette.error, 0.16),
      );
    }

    final CaixaSessao? sessao = _sessaoCaixa;
    if (sessao == null) {
      final Color warningColor = _warningColor;
      return _SessaoCaixaMobileView(
        label: l10n?.pdvCashSessionNotOpen ?? 'Sem sessão aberta',
        foregroundColor: warningColor,
        backgroundColor: _withAlpha(warningColor, 0.10),
        borderColor: _withAlpha(warningColor, 0.18),
      );
    }

    final bool aberta = _sessaoCaixaAberta(sessao);
    final Color successColor = _successColor;
    final Color warningColor = _warningColor;
    final Color foreground = aberta ? successColor : warningColor;

    return _SessaoCaixaMobileView(
      label: _labelSessaoCaixa(sessao, l10n),
      foregroundColor: foreground,
      backgroundColor: _withAlpha(foreground, aberta ? 0.11 : 0.10),
      borderColor: _withAlpha(foreground, aberta ? 0.16 : 0.18),
    );
  }

  bool _sessaoCaixaAberta(CaixaSessao sessao) {
    final String status = sessao.status.trim().toLowerCase();
    return status == 'aberta' ||
        status == 'open' ||
        status == 'active' ||
        status == 'ativa' ||
        status == 'true';
  }

  String _labelSessaoCaixa(CaixaSessao sessao, AppLocalizations? l10n) {
    return _sessaoCaixaAberta(sessao)
        ? (l10n?.pdvWebSessionActive ?? 'Sessão ativa')
        : (l10n?.pdvCashSessionClosed ?? 'Sessão fechada');
  }

  Widget _buildMinimalShoppingIllustration() {
    return Semantics(
      label: 'Ilustração de compra',
      image: true,
      child: _buildInitialIllustrationDecoration(),
    );
  }

  Widget _buildAnimatedCurrencyText(double value, {TextStyle? style}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('pdv-currency-${value.toStringAsFixed(2)}'),
      tween: Tween<double>(begin: 0, end: value),
      duration: Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return Text(
          _formatarValor(animatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }

  Widget _buildStaticCurrencyText(double value, {TextStyle? style}) {
    return Text(
      _formatarValor(value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Widget _buildItensCard() {
    return _buildSectionCard(
      titulo: 'Itens da venda',
      icone: Icons.inventory_2_outlined,
      child: Column(
        children: _itens.map(_buildItemTile).toList(growable: false),
      ),
    );
  }

  Widget _buildPagamentoCard() {
    return _buildSectionCard(
      sectionKey: _pagamentoKey,
      destacar: _destacarPagamento,
      titulo: 'Pagamento',
      icone: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildFormasPagamentoAdaptativas(),
          if (_formasSelecionadas.isEmpty) ...<Widget>[
            SizedBox(height: 14),
            _buildPagamentoHint(),
          ] else ...<Widget>[
            SizedBox(height: 12),
            ..._formasSelecionadas.map(_buildValorFormaField),
          ],
        ],
      ),
    );
  }

  Widget _buildFormasPagamentoAdaptativas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final linhas = _montarLinhasPagamento(constraints.maxWidth);
        return Column(
          children: linhas
              .map((linha) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: linha
                        .asMap()
                        .entries
                        .map((entry) {
                          final forma = entry.value;
                          return Expanded(
                            flex: _flexFormaPagamento(forma),
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: entry.key == 0 ? 0 : 8,
                              ),
                              child: _buildPillPagamento(forma),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  List<List<_FormaPagamentoMobile>> _montarLinhasPagamento(double largura) {
    final int itensPorLinha = largura < 340 ? 2 : (largura < 430 ? 3 : 4);
    final List<List<_FormaPagamentoMobile>> linhas =
        <List<_FormaPagamentoMobile>>[];
    for (
      int index = 0;
      index < _formasPagamento.length;
      index += itensPorLinha
    ) {
      final int proximo = index + itensPorLinha;
      final int fim =
          proximo > _formasPagamento.length ? _formasPagamento.length : proximo;
      linhas.add(_formasPagamento.sublist(index, fim));
    }
    return linhas;
  }

  int _flexFormaPagamento(_FormaPagamentoMobile forma) {
    final tamanho = forma.titulo.length;
    if (tamanho >= 17) return 18;
    if (tamanho >= 12) return 14;
    if (tamanho <= 4) return 8;
    return 10;
  }

  Widget _buildPillPagamento(_FormaPagamentoMobile forma) {
    final selecionado = _formasSelecionadas.contains(forma.codigo);
    return AnimatedScale(
      duration: Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      scale: selecionado ? 1.025 : 1,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        constraints: BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color:
              selecionado
                  ? SixMobilePalette.accent
                  : SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selecionado
                    ? SixMobilePalette.accent
                    : SixMobilePalette.activeBorder,
          ),
          boxShadow:
              selecionado
                  ? <BoxShadow>[
                    BoxShadow(
                      color: _withAlpha(SixMobilePalette.accent, 0.18),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                  : <BoxShadow>[],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap:
              _enviando || !_caixaAbertoParaVenda
                  ? null
                  : () => _alternarFormaPagamento(forma),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  forma.icone,
                  size: 14,
                  color:
                      selecionado
                          ? SixMobilePalette.onPrimary
                          : SixMobilePalette.accent,
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    forma.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color:
                          selecionado
                              ? SixMobilePalette.onPrimary
                              : SixMobilePalette.titleText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _alternarFormaPagamento(_FormaPagamentoMobile forma) {
    final selecionado = _formasSelecionadas.contains(forma.codigo);
    setState(() {
      if (selecionado) {
        _formasSelecionadas.remove(forma.codigo);
        _valorPorForma[forma.codigo]?.clear();
        return;
      }
      _formasSelecionadas.add(forma.codigo);
      _valorPorForma.putIfAbsent(forma.codigo, () => TextEditingController());
      _destacarPagamento = false;
    });

    if (_editandoVendaNaoLiquidada && !selecionado) {
      _preencherValorRestante(forma.codigo);
    }
  }

  Widget _buildPagamentoHint() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 220),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            _destacarPagamento
                ? SixMobilePalette.softAccentSurface
                : SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _destacarPagamento
                  ? SixMobilePalette.highlightedBorder
                  : SixMobilePalette.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.touch_app_outlined, color: SixMobilePalette.accent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _editandoVendaNaoLiquidada
                  ? 'Revise itens, quantidades e escolha uma ou mais formas para receber esta venda.'
                  : 'Toque em uma forma para receber agora ou use Receber depois para deixar a venda em aberto.',
              style: TextStyle(
                color: SixMobilePalette.mutedText,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    Key? sectionKey,
    required String titulo,
    required IconData icone,
    required Widget child,
    bool destacar = false,
  }) {
    return AnimatedScale(
      key: sectionKey,
      scale: destacar ? 1.015 : 1,
      duration: Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color:
                destacar
                    ? SixMobilePalette.highlightedBorder
                    : SixMobilePalette.border,
            width: destacar ? 1.6 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color:
                  destacar
                      ? _withAlpha(SixMobilePalette.accent, 0.18)
                      : SixMobilePalette.navigationShadow,
              blurRadius: destacar ? 18 : 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.softAccentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: SixMobilePalette.accent, size: 19),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.titleText,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(_VendaItemMobile item) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SixMobilePalette.softAccentSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.ehServico
                  ? Icons.handyman_outlined
                  : Icons.shopping_bag_outlined,
              color: SixMobilePalette.accent,
              size: 21,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: SixMobilePalette.titleText,
                  ),
                ),
                SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _buildItemMetaChip(
                      item.ehServico ? 'Serviço' : 'Produto',
                      item.ehServico
                          ? Icons.handyman_outlined
                          : Icons.inventory_2_outlined,
                    ),
                    Text(
                      '${_formatarValor(item.valorUnitario)} un.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildStaticCurrencyText(
                        item.subtotal,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.remove_rounded,
                      label: 'Diminuir quantidade',
                      onTap:
                          _enviando || !_caixaAbertoParaVenda
                              ? null
                              : () => _alterarQuantidade(item, -1),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 180),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        key: ValueKey<String>(
                          '${item.idProduto}-${item.quantidade}',
                        ),
                        width: 34,
                        child: Text(
                          '${item.quantidade}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: SixMobilePalette.titleText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add_rounded,
                      label: 'Aumentar quantidade',
                      onTap:
                          _enviando || !_caixaAbertoParaVenda
                              ? null
                              : () => _alterarQuantidade(item, 1),
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

  Widget _buildItemMetaChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: SixMobilePalette.mutedText),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: Material(
        color: SixMobilePalette.surface,
        shape: CircleBorder(side: BorderSide(color: SixMobilePalette.border)),
        child: InkWell(
          customBorder: CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 19,
              color:
                  onTap == null
                      ? SixMobilePalette.mutedText
                      : SixMobilePalette.accent,
            ),
          ),
        ),
      ),
    );
  }

  void _alterarQuantidade(_VendaItemMobile item, int delta) {
    setState(() {
      final index = _itens.indexWhere(
        (element) => element.idProduto == item.idProduto,
      );
      if (index < 0) return;
      final novaQuantidade = _itens[index].quantidade + delta;
      if (novaQuantidade <= 0) {
        _itens.removeAt(index);
      } else {
        _itens[index] = _itens[index].copyWith(quantidade: novaQuantidade);
      }
    });

    if (_editandoVendaNaoLiquidada && _formasSelecionadas.length == 1) {
      _preencherValorRestante(_formasSelecionadas.first);
    }
  }

  Widget _buildValorFormaField(String codigo) {
    final String currencySymbol =
        context.read<LocaleSettingsProvider>().currencySymbol;
    final forma = _formasPagamento.firstWhere(
      (item) => item.codigo == codigo,
      orElse:
          () => _FormaPagamentoMobile(
            codigo,
            _descricaoPadraoPorCodigoTipo(codigo),
            _iconePorCodigoTipo(codigo),
          ),
    );
    _valorPorForma.putIfAbsent(codigo, () => TextEditingController());
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(forma.icone, size: 19, color: SixMobilePalette.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    forma.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.titleText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _enviando || !_caixaAbertoParaVenda
                          ? null
                          : () => _preencherValorRestante(codigo),
                  child: Text('Completar'),
                ),
              ],
            ),
            SizedBox(height: 8),
            TextField(
              controller: _valorPorForma[codigo],
              enabled: !_enviando && _caixaAbertoParaVenda,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Valor recebido',
                prefixText: '$currencySymbol ',
                helperText:
                    _formasSelecionadas.length == 1
                        ? 'Se ficar vazio, o total da venda será usado.'
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          border: Border(top: BorderSide(color: SixMobilePalette.border)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Total',
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _buildAnimatedCurrencyText(
                        _total,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: SixMobilePalette.softNeutralSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SixMobilePalette.border),
                  ),
                  child: Text(
                    '$_quantidadeItens item(ns)',
                    style: TextStyle(
                      color: SixMobilePalette.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            FilledButton.icon(
              onPressed:
                  _enviando || !_caixaAbertoParaVenda ? null : _finalizarVenda,
              icon:
                  _enviando
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        _editandoVendaNaoLiquidada
                            ? Icons.point_of_sale_outlined
                            : Icons.fact_check_outlined,
                      ),
              label: Text(
                _enviando
                    ? 'Enviando...'
                    : (_editandoVendaNaoLiquidada
                        ? 'Receber venda'
                        : 'Finalizar venda'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: SixMobilePalette.accent,
                foregroundColor: SixMobilePalette.onPrimary,
                minimumSize: Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _enviando ||
                                (!_editandoVendaNaoLiquidada &&
                                    !_caixaAbertoParaVenda)
                            ? null
                            : _receberDepois,
                    icon: Icon(
                      _editandoVendaNaoLiquidada
                          ? Icons.arrow_back_rounded
                          : Icons.schedule_send_outlined,
                    ),
                    label: Text(
                      _editandoVendaNaoLiquidada ? 'Voltar' : 'Receber depois',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SixMobilePalette.primary,
                      side: BorderSide(color: SixMobilePalette.border),
                      minimumSize: Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _enviando ? null : _cancelarVenda,
                    icon: Icon(Icons.close_rounded),
                    label: Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SixMobilePalette.error,
                      side: BorderSide(color: SixMobilePalette.errorBorder),
                      minimumSize: Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
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
    );
  }
}

class _PdvActionButton extends StatefulWidget {
  const _PdvActionButton({
    required this.label,
    required this.helper,
    required this.icon,
    required this.onTap,
    required this.pressDuration,
    this.loading = false,
    this.primary = false,
    this.compact = false,
    this.radius = 20,
  });

  final String label;
  final String helper;
  final IconData icon;
  final VoidCallback? onTap;
  final Duration pressDuration;
  final bool loading;
  final bool primary;
  final bool compact;
  final double radius;

  @override
  State<_PdvActionButton> createState() => _PdvActionButtonState();
}

class _PdvActionButtonState extends State<_PdvActionButton> {
  bool _pressed = false;

  bool get _disabled => widget.onTap == null;

  void _setPressed(bool value) {
    if (_disabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);
    final double scale = !disableAnimations && _pressed ? 0.98 : 1.0;
    final Color foreground =
        widget.primary
            ? SixMobilePalette.onPrimary
            : SixMobilePalette.titleText;
    final Color supporting =
        widget.primary
            ? SixMobilePalette.heroSupportingText
            : SixMobilePalette.mutedText;
    final Color iconColor =
        _disabled
            ? SixMobilePalette.mutedText
            : (widget.primary
                ? SixMobilePalette.onPrimary
                : SixMobilePalette.accent);

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      child: AnimatedScale(
        scale: scale,
        duration: disableAnimations ? Duration.zero : widget.pressDuration,
        curve: Curves.easeOut,
        child: Material(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(widget.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.radius),
            onTap: _disabled ? null : widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Container(
              constraints: BoxConstraints(minHeight: widget.compact ? 64 : 66),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 12,
                vertical: widget.compact ? 10 : 11,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          widget.primary
                              ? _PdvMobileScreenState._withAlpha(
                                SixMobilePalette.onPrimary,
                                0.13,
                              )
                              : SixMobilePalette.surface,
                      borderRadius: BorderRadius.circular(13),
                      border:
                          widget.primary
                              ? null
                              : Border.all(color: SixMobilePalette.border),
                    ),
                    child: Center(
                      child:
                          widget.loading
                              ? SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      widget.primary
                                          ? SixMobilePalette.onPrimary
                                          : SixMobilePalette.accent,
                                ),
                              )
                              : Icon(widget.icon, color: iconColor, size: 19),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                _disabled
                                    ? SixMobilePalette.mutedText
                                    : foreground,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          widget.helper,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: supporting,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Color get _backgroundColor {
    if (_disabled) return SixMobilePalette.softNeutralSurface;
    if (widget.primary) return SixMobilePalette.primary;
    return SixMobilePalette.softNeutralSurface;
  }

  Color get _borderColor {
    if (_disabled) return SixMobilePalette.border;
    if (widget.primary) return SixMobilePalette.primary;
    return SixMobilePalette.activeBorder;
  }
}

class _VendaItemMobile {
  const _VendaItemMobile({
    required this.idProduto,
    required this.nome,
    required this.valorUnitario,
    required this.quantidade,
    required this.ehServico,
  });

  factory _VendaItemMobile.fromVendaNaoLiquidadaItem(
    VendaNaoLiquidadaItemModel item,
  ) {
    return _VendaItemMobile(
      idProduto: item.idProduto,
      nome: item.nome,
      valorUnitario: item.valorUnitario,
      quantidade: item.quantidade,
      ehServico: item.ehServico,
    );
  }

  final String idProduto;
  final String nome;
  final double valorUnitario;
  final int quantidade;
  final bool ehServico;

  double get subtotal => valorUnitario * quantidade;

  _VendaItemMobile copyWith({int? quantidade}) {
    return _VendaItemMobile(
      idProduto: idProduto,
      nome: nome,
      valorUnitario: valorUnitario,
      quantidade: quantidade ?? this.quantidade,
      ehServico: ehServico,
    );
  }

  ItemVendaAtual toInput() {
    return ItemVendaAtual(
      idProduto: idProduto,
      nome: nome,
      quantidade: quantidade,
      valorUnitario: valorUnitario,
      ehServico: ehServico,
    );
  }

  VendaNaoLiquidadaItemModel toVendaNaoLiquidadaItem() {
    return VendaNaoLiquidadaItemModel(
      idProduto: idProduto,
      nome: nome,
      quantidade: quantidade,
      valorUnitario: valorUnitario,
      ehServico: ehServico,
    );
  }
}

class _FormaPagamentoMobile {
  const _FormaPagamentoMobile(this.codigo, this.titulo, this.icone);

  final String codigo;
  final String titulo;
  final IconData icone;
}

class _SessaoCaixaMobileView {
  const _SessaoCaixaMobileView({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
}

class _BarcodeScannerMobileScreen extends StatefulWidget {
  const _BarcodeScannerMobileScreen();

  @override
  State<_BarcodeScannerMobileScreen> createState() =>
      _BarcodeScannerMobileScreenState();
}

class _BarcodeScannerMobileScreenState
    extends State<_BarcodeScannerMobileScreen> {
  late final MobileScannerController _controller;
  bool _codigoLido = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Ler código de barras'),
      ),
      body: Stack(
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_codigoLido) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final codigo = barcodes.first.rawValue;
              if (codigo == null || codigo.trim().isEmpty) return;
              _codigoLido = true;
              Navigator.of(context).pop(codigo.trim());
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _PdvMobileScreenState._withAlpha(Colors.black, 0.58),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Aponte a câmera para o código do produto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
