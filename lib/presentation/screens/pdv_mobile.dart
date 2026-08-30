import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/di/operacao_module.dart';
import '../../core/di/caixa_module.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/produto_helper.dart';
import '../../data/models/caixa_models.dart';
import '../../data/models/operacao_models.dart';
import '../../data/models/produto_imagem_model.dart';
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
import '../components/mobile/six_mobile_recebimento_bottom_sheet.dart';
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

  late final OperacaoService _operacaoService;
  late final CaixaService _caixaService;
  late final VendaNaoLiquidadaApiClient _vendaNaoLiquidadaApiClient;
  final List<_VendaItemMobile> _itens = <_VendaItemMobile>[];

  bool _enviando = false;
  bool _buscandoCodigo = false;
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
                      apenasAtivosNoBackend: true,
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
    final String? imagemProduto = _resolverImagemPrincipal(produto.imagens);
    final index = _itens.indexWhere((item) => item.idProduto == idProduto);

    if (index >= 0) {
      _itens[index] = _itens[index].copyWith(
        quantidade: _itens[index].quantidade + 1,
        imagemProduto: _itens[index].imagemProduto ?? imagemProduto,
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
        imagemProduto: imagemProduto,
      ),
    );
  }

  String? _resolverImagemPrincipal(List<ProdutoImagemModel>? imagens) {
    if (imagens == null || imagens.isEmpty) return null;
    for (final ProdutoImagemModel imagem in imagens) {
      final String miniatura = (imagem.urlMiniatura ?? '').trim();
      if (miniatura.isNotEmpty) return miniatura;
      final String url = (imagem.url ?? '').trim();
      if (url.isNotEmpty) return url;
    }
    return null;
  }

  Future<void> _finalizarVenda() async {
    if (!await _garantirCaixaAbertoParaVenda()) {
      return;
    }

    if (_itens.isEmpty) {
      _mostrarSnack('Inclua pelo menos um item para finalizar.');
      return;
    }

    final SixMobileRecebimentoResultado? resultado =
        await _abrirRecebimentoBottomSheet();
    if (resultado == null) {
      return;
    }

    if (_editandoVendaNaoLiquidada) {
      await _liquidarVendaNaoLiquidada(resultado);
      return;
    }

    await _enviarVenda(
      receberDepois: resultado.parcial,
      formasPagamento: _mapearFormasPagamento(resultado.recebimentos),
      mensagemSucesso:
          resultado.parcial
              ? 'Venda registrada com recebimento parcial.'
              : 'Venda finalizada com sucesso.',
    );
  }

  Future<SixMobileRecebimentoResultado?> _abrirRecebimentoBottomSheet() {
    final VendaNaoLiquidadaModel? venda = widget.vendaNaoLiquidada;
    return SixMobileRecebimentoBottomSheet.show(
      context,
      titulo:
          _editandoVendaNaoLiquidada
              ? _txt(
                'vendasNaoLiquidadas.receberTitulo',
                'Receber venda em aberto',
              )
              : _txt('pdv.mobile.receiveSaleTitle', 'Receber venda'),
      descricao:
          _editandoVendaNaoLiquidada &&
                  venda != null &&
                  venda.descricao.trim().isNotEmpty
              ? venda.descricao
              : _txt(
                'pdv.mobile.counterSaleReceiptDescription',
                'Venda do balcão pronta para recebimento',
              ),
      contato:
          _editandoVendaNaoLiquidada &&
                  venda != null &&
                  venda.nomeCliente.trim().isNotEmpty
              ? venda.nomeCliente.trim()
              : null,
      valorOriginal: _total,
      valorJaRecebido: 0,
      valorAberto: _total,
      codigoTipoInicial: venda?.codigoTipoRecebimento,
      permitirParcial: true,
      observacaoInicial:
          _editandoVendaNaoLiquidada
              ? 'Recebimento realizado pelo PDV mobile.'
              : 'Recebimento realizado no balcão de venda.',
    );
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
        mensagemSucesso: 'Venda registrada para receber depois.',
      );
    }
  }

  Future<void> _enviarVenda({
    required bool receberDepois,
    required List<FormaPagamentoSelecionada> formasPagamento,
    required String mensagemSucesso,
  }) async {
    if (!await _garantirCaixaAbertoParaVenda()) {
      return;
    }

    setState(() => _enviando = true);
    try {
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
                ? (formasPagamento.isEmpty
                    ? 'Venda mobile para receber depois ${dataOperacao.toIso8601String()}'
                    : 'Venda mobile com recebimento parcial ${dataOperacao.toIso8601String()}')
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
      _mostrarSnack(mensagemSucesso);
    } catch (e) {
      if (mounted) _mostrarSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _liquidarVendaNaoLiquidada(
    SixMobileRecebimentoResultado resultado,
  ) async {
    final venda = widget.vendaNaoLiquidada!;
    setState(() => _enviando = true);
    try {
      await _vendaNaoLiquidadaApiClient.liquidar(
        idRecebimento: venda.idRecebimento,
        input: LiquidarVendaNaoLiquidadaInput(
          codigoTipoRecebimento: resultado.codigoTipoRecebimento,
          valorRecebido: resultado.valor,
          recebimentos: resultado.recebimentos,
          itens: _itens
              .map((item) => item.toVendaNaoLiquidadaItem())
              .toList(growable: false),
          observacao: resultado.observacao ?? 'Recebido pelo PDV mobile',
          idSessaoCaixa: _idSessaoCaixaAtual,
        ),
      );

      if (!mounted) return;
      _mostrarSnack(
        resultado.parcial
            ? 'Recebimento parcial registrado com sucesso.'
            : 'Venda recebida com sucesso.',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _mostrarSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  List<FormaPagamentoSelecionada> _mapearFormasPagamento(
    List<RecebimentoFormaInput> recebimentos,
  ) {
    return recebimentos
        .map(
          (RecebimentoFormaInput recebimento) => FormaPagamentoSelecionada(
            codigo: recebimento.codigo.trim().toUpperCase(),
            valor: recebimento.valor,
          ),
        )
        .toList(growable: false);
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
    final bottomPadding = temItens ? 16.0 : 28.0;

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
          tooltip: 'Adicionar produto',
          onPressed:
              _enviando || !_caixaAbertoParaVenda ? null : _abrirSelecaoProduto,
          icon: Icon(Icons.add_rounded),
        ),
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
                              : 'Revise os itens e finalize'),
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
    final bool podeEditarItem = !_enviando && _caixaAbertoParaVenda;

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
          _buildItemLeading(item),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: SixMobilePalette.titleText,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    _buildItemRemoveButton(
                      onTap:
                          podeEditarItem
                              ? () => _definirQuantidade(item, 0)
                              : null,
                    ),
                  ],
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
                          podeEditarItem
                              ? () => _alterarQuantidade(item, -1)
                              : null,
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
                      child: _QuantidadeValorButton(
                        key: ValueKey<String>(
                          '${item.idProduto}-${item.quantidade}',
                        ),
                        quantidade: item.quantidade,
                        label: _txt(
                          'pdv.mobile.editQuantity',
                          'Editar quantidade',
                        ),
                        onTap:
                            podeEditarItem
                                ? () => _editarQuantidade(item)
                                : null,
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add_rounded,
                      label: 'Aumentar quantidade',
                      onTap:
                          podeEditarItem
                              ? () => _alterarQuantidade(item, 1)
                              : null,
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

  Widget _buildItemRemoveButton({required VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: _txt('pdv.mobile.removeItem', 'Remover item'),
      enabled: onTap != null,
      child: Material(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color:
                  onTap == null
                      ? SixMobilePalette.mutedText
                      : SixMobilePalette.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemLeading(_VendaItemMobile item) {
    final BoxDecoration decoration = BoxDecoration(
      color: SixMobilePalette.softAccentSurface,
      borderRadius: BorderRadius.circular(14),
    );
    final String? imagemProduto = item.imagemProduto?.trim();
    if (imagemProduto == null || imagemProduto.isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: decoration,
        child: Icon(
          item.ehServico
              ? Icons.handyman_outlined
              : Icons.shopping_bag_outlined,
          color: SixMobilePalette.accent,
          size: 21,
        ),
      );
    }

    final Uint8List? imageBytes = _decodeDataUrl(imagemProduto);
    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: decoration,
      child:
          imageBytes != null
              ? Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildItemLeadingFallback(item),
              )
              : Image.network(
                imagemProduto,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildItemLeadingFallback(item),
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SixMobilePalette.accent,
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildItemLeadingFallback(_VendaItemMobile item) {
    return Center(
      child: Icon(
        item.ehServico ? Icons.handyman_outlined : Icons.shopping_bag_outlined,
        color: SixMobilePalette.accent,
        size: 21,
      ),
    );
  }

  Uint8List? _decodeDataUrl(String value) {
    final String trimmed = value.trim();
    if (!trimmed.startsWith('data:image')) return null;
    final int commaIndex = trimmed.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= trimmed.length - 1) return null;
    try {
      return base64Decode(trimmed.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
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
    final index = _itens.indexWhere(
      (element) => element.idProduto == item.idProduto,
    );
    if (index < 0) return;
    _definirQuantidade(_itens[index], _itens[index].quantidade + delta);
  }

  void _definirQuantidade(_VendaItemMobile item, int quantidade) {
    setState(() {
      final index = _itens.indexWhere(
        (element) => element.idProduto == item.idProduto,
      );
      if (index < 0) return;
      if (quantidade <= 0) {
        _itens.removeAt(index);
      } else {
        _itens[index] = _itens[index].copyWith(quantidade: quantidade);
      }
    });
  }

  Future<void> _editarQuantidade(_VendaItemMobile item) async {
    final TextEditingController controller = TextEditingController(
      text: item.quantidade.toString(),
    );
    final FocusNode focusNode = FocusNode();

    try {
      final int? novaQuantidade = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (BuildContext modalContext) {
          String? validationError;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!focusNode.canRequestFocus) return;
            focusNode.requestFocus();
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          });

          int? parseQuantity() {
            final int? parsed = int.tryParse(controller.text.trim());
            if (parsed == null || parsed <= 0) {
              return null;
            }
            return parsed;
          }

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              void confirmar() {
                final int? quantidade = parseQuantity();
                if (quantidade == null) {
                  setModalState(() {
                    validationError = _txt(
                      'pdv.mobile.invalidQuantity',
                      'Informe uma quantidade inteira maior que zero.',
                    );
                  });
                  return;
                }

                Navigator.of(context).pop<int>(quantidade);
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Material(
                  color: SixMobilePalette.surface,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: SixMobilePalette.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: SixMobilePalette.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: SixMobilePalette.navigationShadow,
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: SixMobilePalette.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          _txt(
                            'pdv.mobile.editQuantityTitle',
                            'Editar quantidade',
                          ),
                          style: TextStyle(
                            color: SixMobilePalette.titleText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          item.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            if (validationError == null) return;
                            setModalState(() => validationError = null);
                          },
                          onSubmitted: (_) => confirmar(),
                          style: TextStyle(
                            color: SixMobilePalette.titleText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            labelText: _txt(
                              'pdv.mobile.quantityFieldLabel',
                              'Quantidade',
                            ),
                            hintText: _txt(
                              'pdv.mobile.quantityFieldHint',
                              'Digite a quantidade desejada',
                            ),
                            errorText: validationError,
                            prefixIcon: Icon(
                              Icons.tag_rounded,
                              color: SixMobilePalette.accent,
                            ),
                            filled: true,
                            fillColor: SixMobilePalette.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: SixMobilePalette.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: SixMobilePalette.accent,
                                width: 1.4,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: SixMobilePalette.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: SixMobilePalette.error,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: SixMobilePalette.softAccentSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: SixMobilePalette.border),
                          ),
                          child: Text(
                            _txt(
                              'pdv.mobile.quantityEditorHint',
                              'Use os botões laterais para ajuste fino e a digitação para volumes maiores.',
                            ),
                            style: TextStyle(
                              color: SixMobilePalette.mutedText,
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: SixMobilePalette.border,
                                  ),
                                ),
                                child: Text(
                                  _txt('common.cancel', 'Cancelar'),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: confirmar,
                                style: FilledButton.styleFrom(
                                  minimumSize: Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _txt(
                                    'pdv.mobile.applyQuantity',
                                    'Aplicar quantidade',
                                  ),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
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
        },
      );

      if (!mounted || novaQuantidade == null) return;
      _definirQuantidade(item, novaQuantidade);
    } finally {
      focusNode.dispose();
      controller.dispose();
    }
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

class _QuantidadeValorButton extends StatelessWidget {
  const _QuantidadeValorButton({
    super.key,
    required this.quantidade,
    required this.label,
    required this.onTap,
  });

  final int quantidade;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      value: quantidade.toString(),
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: BoxConstraints(minWidth: 58),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: SixMobilePalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    '$quantidade',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SixMobilePalette.titleText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color:
                      onTap == null
                          ? SixMobilePalette.mutedText
                          : SixMobilePalette.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VendaItemMobile {
  const _VendaItemMobile({
    required this.idProduto,
    required this.nome,
    required this.valorUnitario,
    required this.quantidade,
    required this.ehServico,
    this.imagemProduto,
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
      imagemProduto: null,
    );
  }

  final String idProduto;
  final String nome;
  final double valorUnitario;
  final int quantidade;
  final bool ehServico;
  final String? imagemProduto;

  double get subtotal => valorUnitario * quantidade;

  _VendaItemMobile copyWith({int? quantidade, String? imagemProduto}) {
    return _VendaItemMobile(
      idProduto: idProduto,
      nome: nome,
      valorUnitario: valorUnitario,
      quantidade: quantidade ?? this.quantidade,
      ehServico: ehServico,
      imagemProduto: imagemProduto ?? this.imagemProduto,
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
