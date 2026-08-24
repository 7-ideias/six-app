import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/produto_helper.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/produto/produto_quick_update_service.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/produto_cadastrar_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

class ProdutolistMobileScreen extends StatefulWidget {
  const ProdutolistMobileScreen({
    super.key,
    this.isSelecao = false,
    this.permitirSelecaoMultipla = false,
    this.tipoInicial = 'PRODUTO',
    this.apenasAtivosNoBackend = false,
    this.produtoService,
  });

  final bool isSelecao;
  final bool permitirSelecaoMultipla;
  final String tipoInicial;
  final bool apenasAtivosNoBackend;
  final ProdutoService? produtoService;

  @override
  State<ProdutolistMobileScreen> createState() =>
      _ProdutolistMobileScreenState();
}

enum _ProdutoStatusFiltroMobile { todos, ativos, inativos }

enum _ProdutoEstoqueFiltroMobile {
  todos,
  emEstoque,
  estoqueBaixo,
  semEstoque,
  estoqueNegativo,
}

enum _ProdutoSituacaoEstoqueMobile {
  naoAplicavel,
  emEstoque,
  estoqueBaixo,
  semEstoque,
  estoqueNegativo,
}

class _CategoriaFiltroMobile {
  const _CategoriaFiltroMobile({required this.id, required this.nome});

  final String id;
  final String nome;
}

class _ProdutoMobileFilterSelection {
  const _ProdutoMobileFilterSelection({
    required this.categoriaId,
    required this.statusFiltro,
    required this.estoqueFiltro,
    required this.ordenacao,
  });

  final String? categoriaId;
  final _ProdutoStatusFiltroMobile statusFiltro;
  final _ProdutoEstoqueFiltroMobile estoqueFiltro;
  final String ordenacao;
}

class _ProdutolistMobileScreenState extends State<ProdutolistMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _onAccentColor => SixMobilePalette.onAccent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _surfaceElevatedColor => SixMobilePalette.surfaceElevated;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _softNeutralColor => SixMobilePalette.softNeutralSurface;
  static Color get _borderColor => SixMobilePalette.border;
  static Color get _activeAccentSurface =>
      SixMobilePalette.accent.withValues(alpha: 0.16);
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;

  final TextEditingController _controllerBusca = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusBusca = FocusNode();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  late final ProdutoService _produtoService =
      widget.produtoService ?? ProdutoService();
  late final ProdutoQuickUpdateService _produtoQuickUpdateService =
      ProdutoQuickUpdateService(produtoService: _produtoService);

  Timer? _timerOcultarBusca;
  bool _exibirCampoBusca = false;
  final Map<String, _ProdutoSelecionadoMobile> _selecionados =
      <String, _ProdutoSelecionadoMobile>{};
  final Set<String> _favoritosAtualizando = <String>{};
  final Set<String> _catalogoAtualizando = <String>{};
  final Map<String, int> _indiceImagemHorizontal = <String, int>{};

  static const double _horizontalViewportFraction = 0.94;

  final PageController _horizontalProdutosController = PageController(
    viewportFraction: _horizontalViewportFraction,
  );

  List<ProdutoModel> todosProdutos = <ProdutoModel>[];
  List<ProdutoModel> produtosFiltrados = <ProdutoModel>[];

  String termoBusca = '';
  String tipoSelecionado = 'PRODUTO';
  String ordenacao = 'nome';
  String? _categoriaSelecionadaId;
  _ProdutoStatusFiltroMobile _statusFiltro = _ProdutoStatusFiltroMobile.todos;
  _ProdutoEstoqueFiltroMobile _estoqueFiltro =
      _ProdutoEstoqueFiltroMobile.todos;
  bool _salvandoPreferencia = false;
  bool _fixarHeaderLista = false;

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  Future<T?> _openSubSheetOnNextFrame<T>(
    Future<T?> Function() openSheet,
  ) async {
    final Completer<T?> completer = Completer<T?>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      try {
        final T? result = await openSheet();
        if (!completer.isCompleted) completer.complete(result);
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    });

    return completer.future;
  }

  bool get _isProdutoSelecionado => tipoSelecionado == 'PRODUTO';

  bool get _selecaoMultiplaAtiva =>
      widget.isSelecao && widget.permitirSelecaoMultipla;

  int get _quantidadeSelecionadaTotal => _selecionados.values.fold<int>(
    0,
    (int total, _ProdutoSelecionadoMobile item) => total + item.quantidade,
  );

  double get _totalSelecionado => _selecionados.values.fold<double>(
    0,
    (double total, _ProdutoSelecionadoMobile item) => total + item.total,
  );

  ModoDeExibicaoUsuario get _modoDeExibicaoProdutos =>
      _usuarioProvider
          .usuario
          ?.preferenciasIndividuaisDoUsuario
          .modoDeExibicaoProdutos ??
      ModoDeExibicaoUsuario.vertical;

  bool get _exibicaoHorizontal =>
      _modoDeExibicaoProdutos == ModoDeExibicaoUsuario.horizontal;

  @override
  void initState() {
    super.initState();
    tipoSelecionado = _normalizarTipoProduto(widget.tipoInicial);
    _scrollController.addListener(_atualizarHeaderListaFixo);
    Future.microtask(_carregarPreferenciasDoUsuario);
    Future.microtask(_recarregar);
  }

  @override
  void dispose() {
    _timerOcultarBusca?.cancel();
    _scrollController.dispose();
    _horizontalProdutosController.dispose();
    _focusBusca.dispose();
    _controllerBusca.dispose();
    super.dispose();
  }

  Future<void> _carregarPreferenciasDoUsuario() async {
    if (_usuarioProvider.usuario != null) return;
    try {
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
      if (mounted) setState(() {});
    } catch (_) {
      // Mantem a visualizacao vertical quando as preferencias ainda nao carregaram.
    }
  }

  Future<void> _recarregar() async {
    await ProdutoHelper.retornarProdutosList(
      context,
      tipo: tipoSelecionado,
      produtosAtivos: widget.apenasAtivosNoBackend ? true : null,
      onSucesso: atualizarListaComProvider,
    );
  }

  void atualizarListaComProvider(List<ProdutoModel> listaDeProdutos) {
    todosProdutos = listaDeProdutos;
    _sincronizarCategoriaSelecionada();
    aplicarFiltroOrdenacao();
  }

  void aplicarFiltroOrdenacao() {
    final List<ProdutoModel> listaBase = _ordenarProdutos(
      _aplicarFiltrosEstruturais(todosProdutos),
    );

    if (!mounted) return;

    setState(() {
      produtosFiltrados =
          listaBase
              .where(
                (ProdutoModel produto) =>
                    _matchesTipoSelecionado(produto, tipoSelecionado),
              )
              .toList();
    });
  }

  bool _matchesTipoSelecionado(ProdutoModel produto, String tipo) {
    return _normalizarTipoProduto(produto.tipoProduto) ==
        _normalizarTipoProduto(tipo);
  }

  bool get _temFiltrosEstruturaisAtivos =>
      (_categoriaSelecionadaId != null &&
          _categoriaSelecionadaId!.isNotEmpty) ||
      _statusFiltro != _ProdutoStatusFiltroMobile.todos ||
      _estoqueFiltro != _ProdutoEstoqueFiltroMobile.todos ||
      ordenacao != 'nome';

  String _normalizarTipoProduto(String tipo) {
    final String normalizado = tipo.trim().toUpperCase();
    if (normalizado.isEmpty) return 'PRODUTO';
    if (normalizado == 'SERVIÇO') return 'SERVICO';
    return normalizado;
  }

  List<ProdutoModel> _aplicarFiltrosEstruturais(List<ProdutoModel> itens) {
    Iterable<ProdutoModel> resultado = itens;
    final String termoNormalizado = termoBusca.trim().toLowerCase();

    if (termoNormalizado.isNotEmpty) {
      resultado = resultado.where(
        (ProdutoModel produto) =>
            produto.nomeProduto.toLowerCase().contains(termoNormalizado) ||
            produto.codigoDeBarras.toLowerCase().contains(termoNormalizado),
      );
    }

    if (_categoriaSelecionadaId != null &&
        _categoriaSelecionadaId!.isNotEmpty) {
      resultado = resultado.where(
        (ProdutoModel produto) =>
            produto.objCategoria?.idCategoria == _categoriaSelecionadaId,
      );
    }

    switch (_statusFiltro) {
      case _ProdutoStatusFiltroMobile.todos:
        break;
      case _ProdutoStatusFiltroMobile.ativos:
        resultado = resultado.where((ProdutoModel produto) => produto.ativo);
      case _ProdutoStatusFiltroMobile.inativos:
        resultado = resultado.where((ProdutoModel produto) => !produto.ativo);
    }

    switch (_estoqueFiltro) {
      case _ProdutoEstoqueFiltroMobile.todos:
        break;
      case _ProdutoEstoqueFiltroMobile.emEstoque:
        resultado = resultado.where(
          (ProdutoModel produto) =>
              _situacaoEstoque(produto) ==
              _ProdutoSituacaoEstoqueMobile.emEstoque,
        );
      case _ProdutoEstoqueFiltroMobile.estoqueBaixo:
        resultado = resultado.where(
          (ProdutoModel produto) =>
              _situacaoEstoque(produto) ==
              _ProdutoSituacaoEstoqueMobile.estoqueBaixo,
        );
      case _ProdutoEstoqueFiltroMobile.semEstoque:
        resultado = resultado.where(
          (ProdutoModel produto) =>
              _situacaoEstoque(produto) ==
              _ProdutoSituacaoEstoqueMobile.semEstoque,
        );
      case _ProdutoEstoqueFiltroMobile.estoqueNegativo:
        resultado = resultado.where(
          (ProdutoModel produto) =>
              _situacaoEstoque(produto) ==
              _ProdutoSituacaoEstoqueMobile.estoqueNegativo,
        );
    }

    return resultado.toList(growable: false);
  }

  List<ProdutoModel> _ordenarProdutos(List<ProdutoModel> itens) {
    final List<ProdutoModel> ordenados = <ProdutoModel>[...itens];
    switch (ordenacao) {
      case 'precoAsc':
        ordenados.sort((a, b) => a.precoVenda.compareTo(b.precoVenda));
      case 'precoDesc':
        ordenados.sort((a, b) => b.precoVenda.compareTo(a.precoVenda));
      case 'nome':
      default:
        ordenados.sort(
          (a, b) => a.nomeProduto.toLowerCase().compareTo(
            b.nomeProduto.toLowerCase(),
          ),
        );
    }
    return ordenados;
  }

  List<_CategoriaFiltroMobile> _categoriasDisponiveis() {
    final Map<String, _CategoriaFiltroMobile> categorias =
        <String, _CategoriaFiltroMobile>{};

    for (final ProdutoModel produto in todosProdutos) {
      final ObjCategoria? categoria = produto.objCategoria;
      if (categoria == null) continue;

      final String id = categoria.idCategoria.trim();
      final String nome = categoria.nomeCategoria.trim();
      if (id.isEmpty || nome.isEmpty) continue;

      categorias[id] = _CategoriaFiltroMobile(id: id, nome: nome);
    }

    final List<_CategoriaFiltroMobile> resultado = categorias.values.toList();
    resultado.sort(
      (_CategoriaFiltroMobile a, _CategoriaFiltroMobile b) =>
          a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
    );
    return resultado;
  }

  void _sincronizarCategoriaSelecionada() {
    final String? categoriaId = _categoriaSelecionadaId;
    if (categoriaId == null || categoriaId.isEmpty) return;

    final bool categoriaAindaDisponivel = _categoriasDisponiveis().any(
      (_CategoriaFiltroMobile categoria) => categoria.id == categoriaId,
    );

    if (!categoriaAindaDisponivel) {
      _categoriaSelecionadaId = null;
    }
  }

  double _quantidadeEstoque(ProdutoModel produto) {
    if (!_matchesTipoSelecionado(produto, 'PRODUTO')) return 0;

    final List<ObjEntradaSaidaProduto>? movimentacoes =
        produto.objEntradaSaidaProduto;
    if (movimentacoes == null || movimentacoes.isEmpty) return 0;

    return movimentacoes.fold<double>(
      0,
      (double total, ObjEntradaSaidaProduto item) => total + item.quantidade,
    );
  }

  _ProdutoSituacaoEstoqueMobile _situacaoEstoque(ProdutoModel produto) {
    if (!_matchesTipoSelecionado(produto, 'PRODUTO')) {
      return _ProdutoSituacaoEstoqueMobile.naoAplicavel;
    }

    final double quantidade = _quantidadeEstoque(produto);
    if (quantidade < 0) return _ProdutoSituacaoEstoqueMobile.estoqueNegativo;
    if (quantidade == 0) return _ProdutoSituacaoEstoqueMobile.semEstoque;
    if (produto.estoqueMinimo > 0 &&
        quantidade <= produto.estoqueMinimo.toDouble()) {
      return _ProdutoSituacaoEstoqueMobile.estoqueBaixo;
    }
    return _ProdutoSituacaoEstoqueMobile.emEstoque;
  }

  Future<void> _alternarModoExibicaoProdutos() async {
    await _alterarModoExibicaoProdutos(
      _exibicaoHorizontal
          ? ModoDeExibicaoUsuario.vertical
          : ModoDeExibicaoUsuario.horizontal,
    );
  }

  Future<void> _alterarModoExibicaoProdutos(
    ModoDeExibicaoUsuario novoModo,
  ) async {
    if (_salvandoPreferencia || novoModo == _modoDeExibicaoProdutos) return;

    UsuarioModel? usuarioAtual = _usuarioProvider.usuario;
    if (usuarioAtual == null) {
      await _carregarPreferenciasDoUsuario();
      usuarioAtual = _usuarioProvider.usuario;
    }

    if (usuarioAtual == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar suas preferências.')),
      );
      return;
    }

    final PreferenciasIndividuaisDoUsuarioModel preferenciasAtualizadas =
        usuarioAtual.preferenciasIndividuaisDoUsuario.copyWith(
          modoDeExibicaoProdutos: novoModo,
        );

    final UsuarioModel usuarioAtualizado = UsuarioModel(
      nome: usuarioAtual.nome,
      sobrenome: usuarioAtual.sobrenome,
      cpf: usuarioAtual.cpf,
      registroProfissional: usuarioAtual.registroProfissional,
      email: usuarioAtual.email,
      foto: usuarioAtual.foto,
      nomeDeGuerra: usuarioAtual.nomeDeGuerra,
      celular: usuarioAtual.celular,
      senha: usuarioAtual.senha,
      salt: usuarioAtual.salt,
      rg: usuarioAtual.rg,
      dataNascimento: usuarioAtual.dataNascimento,
      objEndereco: usuarioAtual.objEndereco,
      preferenciasIndividuaisDoUsuario: preferenciasAtualizadas,
      enviarPreferenciasIndividuaisDoUsuario: true,
    );

    setState(() => _salvandoPreferencia = true);
    try {
      await UsuarioService().atualizarDadosDoUsuario(usuarioAtualizado);
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar a preferência de visualização.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvandoPreferencia = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _usuarioProvider,
      builder: (BuildContext context, _) {
        final ProdutosListProvider<ProdutoModel> provider =
            context.watch<ProdutosListProvider<ProdutoModel>>();
        final List<ProdutoModel> itensDaLista =
            produtosFiltrados.isNotEmpty ||
                    termoBusca.isNotEmpty ||
                    todosProdutos.isNotEmpty
                ? produtosFiltrados
                : todosProdutos;
        final bool isSelecao = widget.isSelecao;
        final double bottomPadding = _selecaoMultiplaAtiva ? 170 : 96;

        return SixMobilePageShell(
          title:
              isSelecao
                  ? _t('produto.mobile.selectItem', 'Selecionar item')
                  : (_isProdutoSelecionado
                      ? _t('produto.mobile.typeProduct', 'Produtos')
                      : _t('produto.mobile.typeService', 'Serviços')),
          backgroundColor: _backgroundColor,
          primaryColor: SixMobilePalette.primary,
          secondaryColor: SixMobilePalette.secondary,
          accentColor: SixMobilePalette.accent,
          scrollController: _scrollController,
          enableAnimatedBackground: false,
          toolbarHeight: 48,
          initialContentSpacing: 4,
          scrollEffectOffset: 24,
          scrolledSurfaceOpacity: 0.66,
          actions:
              !isSelecao
                  ? <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: IconButton(
                        tooltip: _t(
                          'produto.mobile.newProduct',
                          'Novo produto',
                        ),
                        onPressed: _criarProduto,
                        icon: Icon(Icons.add_rounded, size: 22),
                      ),
                    ),
                  ]
                  : <Widget>[],
          bodyBuilder: (
            BuildContext context,
            ScrollController scrollController,
            double topInset,
          ) {
            return SafeArea(
              top: false,
              child: Stack(
                children: <Widget>[
                  RefreshIndicator(
                    onRefresh: _recarregar,
                    child: ListView(
                      controller: scrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        topInset + 8,
                        16,
                        bottomPadding,
                      ),
                      children: <Widget>[
                        if (isSelecao)
                          SixStaggeredEntry(
                            delay: Duration(milliseconds: 70),
                            child: _buildTabs(compact: isSelecao),
                          ),
                        if (_exibirCampoBusca &&
                            !_deveExibirHeaderListaFixo(isSelecao)) ...<Widget>[
                          SizedBox(height: 12),
                          SixStaggeredEntry(
                            delay: Duration(milliseconds: 120),
                            child: _buildSearchField(),
                          ),
                        ],
                        SizedBox(
                          height:
                              isSelecao &&
                                      _exibirCampoBusca &&
                                      !_deveExibirHeaderListaFixo(isSelecao)
                                  ? (isSelecao ? 14 : 18)
                                  : (isSelecao ? 14 : 8),
                        ),
                        if (!_deveExibirHeaderListaFixo(isSelecao)) ...<Widget>[
                          _buildListHeader(
                            itensDaLista.length,
                            provider.isLoading,
                          ),
                          SizedBox(height: 10),
                        ],
                        ..._buildListContent(provider, itensDaLista, isSelecao),
                      ],
                    ),
                  ),
                  if (_deveExibirHeaderListaFixo(isSelecao))
                    Positioned(
                      top: topInset,
                      left: 0,
                      right: 0,
                      child: _buildHeaderListaFixo(
                        itensDaLista.length,
                        provider.isLoading,
                      ),
                    ),
                ],
              ),
            );
          },
          bottomNavigationBar:
              _selecaoMultiplaAtiva ? _buildBarraSelecaoMultipla() : null,
        );
      },
    );
  }

  void _atualizarHeaderListaFixo() {
    const double offsetParaFixarHeader = 180;

    final bool deveFixar =
        _scrollController.hasClients &&
        _scrollController.offset >= offsetParaFixarHeader;

    if (deveFixar == _fixarHeaderLista) return;

    setState(() => _fixarHeaderLista = deveFixar);
  }

  bool _deveExibirHeaderListaFixo(bool isSelecao) {
    return !isSelecao && !_exibicaoHorizontal && _fixarHeaderLista;
  }

  Widget _buildHeaderListaFixo(int count, bool isLoading) {
    return Material(
      color: _backgroundColor,
      elevation: 8,
      shadowColor: SixMobilePalette.navigationShadow,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildListHeader(count, isLoading),
            if (_exibirCampoBusca) ...<Widget>[
              SizedBox(height: 10),
              _buildSearchField(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListContent(
    ProdutosListProvider<ProdutoModel> provider,
    List<ProdutoModel> itensDaLista,
    bool isSelecao,
  ) {
    if (provider.isLoading && todosProdutos.isEmpty) {
      return <Widget>[_LoadingState()];
    }

    if (provider.erro != null && todosProdutos.isEmpty) {
      return <Widget>[_ErrorState(onRetry: _recarregar)];
    }

    if (itensDaLista.isEmpty) {
      return <Widget>[_EmptyState()];
    }

    if (_exibicaoHorizontal) {
      return <Widget>[
        SizedBox(
          height: _calcularAlturaCatalogoHorizontal(itensDaLista, isSelecao),
          child: PageView.builder(
            controller: _horizontalProdutosController,
            clipBehavior: Clip.none,
            padEnds: true,
            itemCount: itensDaLista.length,
            itemBuilder: (BuildContext context, int index) {
              final int itemDelay = 190 + ((index * 28).clamp(0, 180)).toInt();
              return Padding(
                padding: EdgeInsets.fromLTRB(6, 14, 6, 6),
                child: SixStaggeredEntry(
                  delay: Duration(milliseconds: itemDelay),
                  child: _buildProdutoCard(itensDaLista[index]),
                ),
              );
            },
          ),
        ),
      ];
    }

    return itensDaLista.asMap().entries.map((
      MapEntry<int, ProdutoModel> entry,
    ) {
      final int itemDelay = 190 + ((entry.key * 28).clamp(0, 180)).toInt();
      return SixStaggeredEntry(
        delay: Duration(milliseconds: itemDelay),
        child: _buildProdutoCard(entry.value),
      );
    }).toList();
  }

  Widget _buildTabs({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SegmentButton(
              label: _t('produto.mobile.typeProduct', 'Produtos'),
              icon: Icons.inventory_2_outlined,
              selected: _isProdutoSelecionado,
              compact: compact,
              onTap: () => _selectTipo('PRODUTO'),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: _t('produto.mobile.typeService', 'Serviços'),
              icon: Icons.design_services_outlined,
              selected: tipoSelecionado == 'SERVICO',
              compact: compact,
              onTap: () => _selectTipo('SERVICO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _controllerBusca,
        focusNode: _focusBusca,
        cursorColor: _accentColor,
        style: TextStyle(color: _titleTextColor, fontWeight: FontWeight.w600),
        onTap: _reiniciarTimerOcultarBusca,
        onChanged: (String value) {
          termoBusca = value;
          aplicarFiltroOrdenacao();
          _reiniciarTimerOcultarBusca();
        },
        decoration: InputDecoration(
          hintText:
              _isProdutoSelecionado
                  ? _t(
                    'produto.mobile.searchProductHint',
                    'Buscar produto ou código',
                  )
                  : _t('produto.mobile.searchServiceHint', 'Buscar serviço'),
          hintStyle: TextStyle(color: _mutedTextColor),
          prefixIcon: Icon(Icons.search_rounded, color: _accentColor),
          suffixIcon:
              _controllerBusca.text.isEmpty
                  ? IconButton(
                    icon: Icon(Icons.tune_rounded, color: _titleTextColor),
                    tooltip: _t(
                      'produto.mobile.filtersTooltip',
                      'Filtros e ordenação',
                    ),
                    onPressed: _showFilterOptions,
                  )
                  : IconButton(
                    onPressed: () {
                      _controllerBusca.clear();
                      termoBusca = '';
                      aplicarFiltroOrdenacao();
                      _reiniciarTimerOcultarBusca();
                    },
                    icon: Icon(Icons.close_rounded, color: _mutedTextColor),
                  ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  void _abrirCampoBusca() {
    _timerOcultarBusca?.cancel();

    if (!_exibirCampoBusca) {
      setState(() => _exibirCampoBusca = true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusBusca.requestFocus();
    });

    _reiniciarTimerOcultarBusca();
  }

  void _reiniciarTimerOcultarBusca() {
    _timerOcultarBusca?.cancel();
    _timerOcultarBusca = Timer(
      Duration(seconds: 10),
      _ocultarCampoBuscaPorInatividade,
    );
  }

  void _ocultarCampoBuscaPorInatividade() {
    if (!mounted) return;

    final bool temBusca =
        termoBusca.trim().isNotEmpty || _controllerBusca.text.trim().isNotEmpty;

    FocusManager.instance.primaryFocus?.unfocus();

    if (temBusca) return;

    setState(() => _exibirCampoBusca = false);
  }

  Widget _buildBuscaListHeaderButton() {
    return Tooltip(
      message:
          _isProdutoSelecionado
              ? _t('produto.mobile.searchProducts', 'Buscar produtos')
              : _t('produto.mobile.searchServices', 'Buscar serviços'),
      child: InkWell(
        onTap: _abrirCampoBusca,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _exibirCampoBusca ? _activeAccentSurface : _softAccentColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(Icons.search_rounded, color: _accentColor, size: 18),
        ),
      ),
    );
  }

  Widget _buildFiltroListHeaderButton() {
    final bool filtrosAtivos = _temFiltrosEstruturaisAtivos;

    return Tooltip(
      message: _t('produto.mobile.filtersTooltip', 'Filtros e ordenação'),
      child: InkWell(
        onTap: _showFilterOptions,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: filtrosAtivos ? _activeAccentSurface : _softAccentColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: filtrosAtivos ? _secondaryColor : _accentColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  bool _produtoFavoritoVisual(ProdutoModel produto) {
    return produto.favorito;
  }

  Future<void> _alternarFavoritoVisual(ProdutoModel produto) async {
    final String chave = _chaveProduto(produto);
    if (_favoritosAtualizando.contains(chave) ||
        (produto.id?.isEmpty ?? true)) {
      return;
    }

    setState(() {
      _favoritosAtualizando.add(chave);
    });

    try {
      final ProdutoModel atualizado = await _produtoQuickUpdateService
          .alternarFavorito(produto);
      if (!mounted) return;
      _substituirProdutoNaLista(atualizado);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'produto.favorite.updateError',
              'Não foi possível atualizar o favorito do produto.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoritosAtualizando.remove(chave);
        });
      }
    }
  }

  Future<void> _alternarDisponivelParaCatalogoVisual(
    ProdutoModel produto,
  ) async {
    final String chave = _chaveProduto(produto);
    if (_catalogoAtualizando.contains(chave) || (produto.id?.isEmpty ?? true)) {
      return;
    }

    setState(() {
      _catalogoAtualizando.add(chave);
    });

    try {
      final ProdutoModel atualizado = await _produtoQuickUpdateService
          .alternarDisponivelParaCatalogo(produto);
      if (!mounted) return;
      _substituirProdutoNaLista(atualizado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            atualizado.disponivelParaCatalogo
                ? _t(
                  'produto.catalog.enabledFeedback',
                  'Disponível para catálogo ativado',
                )
                : _t(
                  'produto.catalog.disabledFeedback',
                  'Disponível para catálogo desativado',
                ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'produto.catalog.updateError',
              'Não foi possível atualizar a disponibilidade no catálogo.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _catalogoAtualizando.remove(chave);
        });
      }
    }
  }

  void _substituirProdutoNaLista(ProdutoModel atualizado) {
    setState(() {
      todosProdutos = todosProdutos
          .map(
            (ProdutoModel item) => item.id == atualizado.id ? atualizado : item,
          )
          .toList(growable: false);
      produtosFiltrados = _ordenarProdutos(
            _aplicarFiltrosEstruturais(todosProdutos),
          )
          .where(
            (ProdutoModel produto) =>
                _matchesTipoSelecionado(produto, tipoSelecionado),
          )
          .toList(growable: false);
    });
  }

  Widget _buildFavoritoVisualButton(
    ProdutoModel produto, {
    bool sobreImagem = false,
    double size = 34,
    double iconSize = 19,
  }) {
    final bool favorito = _produtoFavoritoVisual(produto);
    final bool atualizando = _favoritosAtualizando.contains(
      _chaveProduto(produto),
    );

    return Tooltip(
      message:
          favorito
              ? _t('produto.favorite.removeTooltip', 'Remover dos favoritos')
              : _t('produto.favorite.addTooltip', 'Marcar como favorito'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: atualizando ? null : () => _alternarFavoritoVisual(produto),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color:
                  favorito
                      ? Color(0xFFEF4444)
                      : sobreImagem
                      ? Color(0xD9FFFFFF)
                      : _surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: favorito ? Color(0xFFEF4444) : Color(0xFFFCA5A5),
              ),
              boxShadow:
                  sobreImagem
                      ? <BoxShadow>[
                        BoxShadow(
                          color: SixMobilePalette.navigationShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                      : <BoxShadow>[],
            ),
            child:
                atualizando
                    ? Padding(
                      padding: EdgeInsets.all(size <= 30 ? 7 : 8),
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: favorito ? Colors.white : Color(0xFFEF4444),
                        ),
                      ),
                    )
                    : Icon(
                      favorito
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: favorito ? Colors.white : Color(0xFFEF4444),
                      size: iconSize,
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogoVisualButton(
    ProdutoModel produto, {
    bool sobreImagem = false,
    double size = 34,
    double iconSize = 19,
  }) {
    final bool disponivelParaCatalogo = produto.disponivelParaCatalogo;
    final bool atualizando = _catalogoAtualizando.contains(
      _chaveProduto(produto),
    );

    return Tooltip(
      message:
          disponivelParaCatalogo
              ? _t(
                'produto.catalog.disableTooltip',
                'Retirar da disponibilidade para catálogo',
              )
              : _t(
                'produto.catalog.enableTooltip',
                'Disponibilizar para catálogo',
              ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              atualizando
                  ? null
                  : () => _alternarDisponivelParaCatalogoVisual(produto),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color:
                  disponivelParaCatalogo
                      ? _accentColor
                      : sobreImagem
                      ? Color(0xD9FFFFFF)
                      : _surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: disponivelParaCatalogo ? _accentColor : _borderColor,
              ),
              boxShadow:
                  sobreImagem
                      ? <BoxShadow>[
                        BoxShadow(
                          color: SixMobilePalette.navigationShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                      : <BoxShadow>[],
            ),
            child:
                atualizando
                    ? Padding(
                      padding: EdgeInsets.all(size <= 30 ? 7 : 8),
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              disponivelParaCatalogo
                                  ? _onAccentColor
                                  : _accentColor,
                        ),
                      ),
                    )
                    : Icon(
                      disponivelParaCatalogo
                          ? Icons.storefront_rounded
                          : Icons.storefront_outlined,
                      color:
                          disponivelParaCatalogo
                              ? _onAccentColor
                              : _accentColor,
                      size: iconSize,
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildModoExibicaoListHeaderButton() {
    return Tooltip(
      message:
          _exibicaoHorizontal
              ? _t('produto.mobile.verticalView', 'Usar visualização vertical')
              : _t(
                'produto.mobile.horizontalView',
                'Usar visualização horizontal',
              ),
      child: InkWell(
        onTap: _salvandoPreferencia ? null : _alternarModoExibicaoProdutos,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _softAccentColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child:
              _salvandoPreferencia
                  ? Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : Icon(
                    _exibicaoHorizontal
                        ? Icons.view_agenda_outlined
                        : Icons.view_carousel_outlined,
                    color: _accentColor,
                    size: 18,
                  ),
        ),
      ),
    );
  }

  Widget _buildListHeader(int count, bool isLoading) {
    final String titulo =
        widget.isSelecao
            ? (_selecaoMultiplaAtiva
                ? _t(
                  'produto.mobile.selectManyItems',
                  'Selecione um ou mais itens',
                )
                : (_isProdutoSelecionado
                    ? _t(
                      'produto.mobile.tapProductToAdd',
                      'Toque no produto para adicionar',
                    )
                    : _t(
                      'produto.mobile.tapServiceToAdd',
                      'Toque no serviço para adicionar',
                    )))
            : (_isProdutoSelecionado
                ? _t('produto.mobile.typeProduct', 'Produtos')
                : _t('produto.mobile.typeService', 'Serviços'));

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isLoading) ...<Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
        ],
        _buildBuscaListHeaderButton(),
        SizedBox(width: 8),
        _buildFiltroListHeaderButton(),
        SizedBox(width: 8),
        _buildModoExibicaoListHeaderButton(),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _softAccentColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count ${count == 1 ? _t('produto.mobile.itemSingular', 'item') : _t('produto.mobile.itemPlural', 'itens')}',
            style: TextStyle(
              color: _accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProdutoCard(ProdutoModel produto) {
    if (widget.isSelecao) return _buildProdutoSelectionCard(produto);

    if (_exibicaoHorizontal) {
      return _buildProdutoHorizontalComFotoCard(produto);
    }

    final bool ativo = produto.ativo == true;
    final bool isProduto = _matchesTipoSelecionado(produto, 'PRODUTO');
    final String titulo =
        produto.nomeProduto.isEmpty
            ? _t('produto.webList.itemWithoutName', 'Item sem nome')
            : produto.nomeProduto;
    final String subtitulo = _resumoProdutoVertical(produto, ativo);

    return _SwipeRevealTile(
      key: ValueKey<String>('produto-vertical-${_chaveProduto(produto)}'),
      backgroundColor: _softNeutralColor,
      dividerColor: _borderColor,
      onTap: () => _editarProduto(produto),
      actions: <_SwipeRevealAction>[
        _SwipeRevealAction(
          semanticLabel:
              produto.disponivelParaCatalogo
                  ? _t(
                    'produto.catalog.disableTooltip',
                    'Retirar da disponibilidade para catálogo',
                  )
                  : _t(
                    'produto.catalog.enableTooltip',
                    'Disponibilizar para catálogo',
                  ),
          icon:
              produto.disponivelParaCatalogo
                  ? Icons.storefront_rounded
                  : Icons.storefront_outlined,
          foregroundColor:
              produto.disponivelParaCatalogo ? _onAccentColor : _accentColor,
          backgroundColor:
              produto.disponivelParaCatalogo ? _accentColor : _surfaceColor,
          borderColor:
              produto.disponivelParaCatalogo ? _accentColor : _borderColor,
          isLoading: _catalogoAtualizando.contains(_chaveProduto(produto)),
          onTap: () => _alternarDisponivelParaCatalogoVisual(produto),
        ),
        _SwipeRevealAction(
          semanticLabel:
              produto.favorito
                  ? _t(
                    'produto.favorite.removeTooltip',
                    'Remover dos favoritos',
                  )
                  : _t('produto.favorite.addTooltip', 'Marcar como favorito'),
          icon:
              produto.favorito
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
          foregroundColor: produto.favorito ? Colors.white : Color(0xFFEF4444),
          backgroundColor: produto.favorito ? Color(0xFFEF4444) : _surfaceColor,
          borderColor: Color(0xFFFCA5A5),
          isLoading: _favoritosAtualizando.contains(_chaveProduto(produto)),
          onTap: () => _alternarFavoritoVisual(produto),
        ),
      ],
      child: Container(
        color: _surfaceColor,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            _buildThumbnail(produto, isProduto, size: 44),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: _titleTextColor,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: _mutedTextColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: _mutedTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  double _calcularAlturaCatalogoHorizontal(
    List<ProdutoModel> itensDaLista,
    bool isSelecao,
  ) {
    if (isSelecao) return _selecaoMultiplaAtiva ? 376 : 118;

    const double alturaMinima = 688;

    final MediaQueryData media = MediaQuery.of(context);
    const double alturaReservadaPeloFab = 96;
    const double espacamentoAteCatalogo = 152;

    final double alturaDisponivel =
        media.size.height -
        media.padding.top -
        media.padding.bottom -
        kToolbarHeight -
        alturaReservadaPeloFab -
        espacamentoAteCatalogo;

    return alturaDisponivel < alturaMinima ? alturaMinima : alturaDisponivel;
  }

  List<dynamic> _imagensValidasProduto(ProdutoModel produto) {
    final List<dynamic> imagens = List<dynamic>.from(
      produto.imagens ?? <dynamic>[],
    );

    return imagens.where((dynamic imagem) {
      final String imagemBase64 = (imagem.imagemBase64 ?? '').toString().trim();
      final String url = (imagem.url ?? '').toString().trim();

      return imagemBase64.isNotEmpty || url.isNotEmpty;
    }).toList();
  }

  Widget _buildProdutoHorizontalComFotoCard(ProdutoModel produto) {
    final bool ativo = produto.ativo == true;
    final bool isProduto = _matchesTipoSelecionado(produto, 'PRODUTO');
    final String codigo = produto.codigoDeBarras.trim();
    final int imagensCount = produto.imagens?.length ?? 0;
    final String grupo = _grupoProdutoLabel(produto);
    final String estoque = _estoqueProdutoLabel(produto);
    final String resumo = _resumoProdutoHorizontal(produto);

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _editarProduto(produto),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.navigationShadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 278,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: _buildProdutoHorizontalImagem(produto, isProduto),
                    ),
                    Positioned(
                      top: 9,
                      left: 9,
                      child: _StatusChip(ativo: ativo),
                    ),
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Column(
                        children: <Widget>[
                          _buildFavoritoVisualButton(
                            produto,
                            sobreImagem: true,
                          ),
                          SizedBox(height: 8),
                          _buildCatalogoVisualButton(
                            produto,
                            sobreImagem: true,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 9,
                      bottom: 9,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceElevatedColor,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: SixMobilePalette.navigationShadow,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _formatCurrency(produto.precoVenda),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _titleTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        produto.nomeProduto.isEmpty
                            ? _t(
                              'produto.webList.itemWithoutName',
                              'Item sem nome',
                            )
                            : produto.nomeProduto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: _titleTextColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildProdutoInfoSection(
                        title: _t(
                          'produto.mobile.generalInfoTitle',
                          'Informações gerais',
                        ),
                        children: <Widget>[
                          _buildProdutoInfoRow(
                            label: _t('common.status', 'Status'),
                            valueWidget: _StatusChip(ativo: ativo),
                          ),
                          _buildProdutoInfoRow(
                            label: _t(
                              'produto.catalog.statusLabel',
                              'Catálogo',
                            ),
                            valueWidget: _CatalogStatusChip(
                              disponivelParaCatalogo:
                                  produto.disponivelParaCatalogo,
                            ),
                          ),
                          _buildProdutoInfoRow(
                            label: _t('produto.mobile.groupLabel', 'Grupo'),
                            value:
                                grupo.isEmpty
                                    ? _t(
                                      'produto.webList.filter.categoryAll',
                                      'Sem grupo',
                                    )
                                    : grupo,
                          ),
                          _buildProdutoInfoRow(
                            label: _t('produto.webList.table.code', 'Código'),
                            value:
                                codigo.isEmpty
                                    ? _t(
                                      'produto.webList.codeUnavailable',
                                      'Sem código',
                                    )
                                    : codigo,
                          ),
                          _buildProdutoInfoRow(
                            label: _t(
                              'produto.webList.stockQuantity',
                              'Estoque',
                            ),
                            value:
                                estoque.isEmpty
                                    ? _t(
                                      'produto.webList.stockNotApplicable',
                                      'Sem controle',
                                    )
                                    : estoque,
                            valueColor: _corEstoqueProduto(produto),
                          ),
                          _buildProdutoInfoRow(
                            label: _t('produto.mobile.photosLabel', 'Fotos'),
                            value:
                                '$imagensCount ${_t('produto.mobile.photosLabel', imagensCount == 1 ? 'foto' : 'fotos')}',
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 2, bottom: 2),
                            child: Divider(
                              height: 14,
                              thickness: 1,
                              color: _borderColor,
                            ),
                          ),
                          Text(
                            _t(
                              'produto.mobile.aboutProductTitle',
                              'Sobre o produto',
                            ),
                            style: TextStyle(
                              color: _titleTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            resumo.isEmpty
                                ? _t(
                                  'produto.mobile.aboutProductEmpty',
                                  'Sem detalhes adicionais informados.',
                                )
                                : resumo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _mutedTextColor,
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _softAccentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: _accentColor,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProdutoHorizontalImagem(ProdutoModel produto, bool isProduto) {
    final List<dynamic> imagens = _imagensValidasProduto(produto);
    final String chave = _chaveProduto(produto);

    if (imagens.isEmpty) {
      return _buildProdutoHorizontalImagemContainer(
        _buildHeroPlaceholder(isProduto),
      );
    }

    final int indiceAtual = (_indiceImagemHorizontal[chave] ?? 0).clamp(
      0,
      imagens.length - 1,
    );

    return _buildProdutoHorizontalImagemContainer(
      Stack(
        children: <Widget>[
          Positioned.fill(
            child:
                imagens.length == 1
                    ? _buildImagemProdutoContent(imagens.first, isProduto)
                    : PageView.builder(
                      key: PageStorageKey<String>(
                        'produto-horizontal-imagens-$chave',
                      ),
                      itemCount: imagens.length,
                      onPageChanged: (int index) {
                        if (_indiceImagemHorizontal[chave] == index) return;
                        setState(() => _indiceImagemHorizontal[chave] = index);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return _buildImagemProdutoContent(
                          imagens[index],
                          isProduto,
                        );
                      },
                    ),
          ),
          if (imagens.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(imagens.length, (int index) {
                  final bool ativo = index == indiceAtual;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    width: ativo ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ativo ? Colors.white : Color(0x99FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProdutoHorizontalImagemContainer(Widget child) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _softAccentColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  Widget _buildImagemProdutoContent(dynamic imagem, bool isProduto) {
    final Uint8List? bytes =
        _decodeBase64Image(imagem?.imagemBase64) ?? _decodeDataUrl(imagem?.url);

    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final String url = (imagem?.url ?? '').toString().trim();
    if (url.isEmpty) return _buildHeroPlaceholder(isProduto);

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? loadingProgress,
      ) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _buildHeroPlaceholder(isProduto),
    );
  }

  Widget _buildProdutoSelectionCard(ProdutoModel produto) {
    if (_selecaoMultiplaAtiva && _exibicaoHorizontal) {
      return _buildProdutoSelectionExpandedCard(produto);
    }

    return _buildProdutoSelectionCompactCard(produto);
  }

  Widget _buildProdutoSelectionCompactCard(ProdutoModel produto) {
    final bool isProduto = _matchesTipoSelecionado(produto, 'PRODUTO');
    final String codigo = produto.codigoDeBarras.trim();
    final String chave = _chaveProduto(produto);
    final _ProdutoSelecionadoMobile? selecionado = _selecionados[chave];
    final bool estaSelecionado = selecionado != null;
    final int quantidade = selecionado?.quantidade ?? 0;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap:
            () =>
                _selecaoMultiplaAtiva
                    ? _alternarProdutoSelecionado(produto)
                    : Navigator.pop(context, produto),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            minHeight:
                _selecaoMultiplaAtiva ? (estaSelecionado ? 126 : 68) : 74,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: _selecaoMultiplaAtiva && !estaSelecionado ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: estaSelecionado ? _softAccentColor : _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: estaSelecionado ? _accentColor : _borderColor,
              width: estaSelecionado ? 1.4 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.navigationShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _buildThumbnail(produto, isProduto, size: 42),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          produto.nomeProduto.isEmpty
                              ? 'Item sem nome'
                              : produto.nomeProduto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _titleTextColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                codigo.isEmpty ? 'Sem código' : codigo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _mutedTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              _formatCurrency(produto.precoVenda),
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: estaSelecionado ? _accentColor : _softAccentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      estaSelecionado ? Icons.check_rounded : Icons.add_rounded,
                      color: estaSelecionado ? _onAccentColor : _accentColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (_selecaoMultiplaAtiva && estaSelecionado) ...<Widget>[
                SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceElevatedColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Text(
                        'Selecionado',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Spacer(),
                    _QuantidadeButton(
                      icon: Icons.remove_rounded,
                      onTap: () => _alterarQuantidadeSelecionada(produto, -1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantidade',
                        style: TextStyle(
                          color: _titleTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _QuantidadeButton(
                      icon: Icons.add_rounded,
                      onTap: () => _alterarQuantidadeSelecionada(produto, 1),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProdutoSelectionExpandedCard(ProdutoModel produto) {
    final bool isProduto = _matchesTipoSelecionado(produto, 'PRODUTO');
    final String codigo = produto.codigoDeBarras.trim();
    final String chave = _chaveProduto(produto);
    final _ProdutoSelecionadoMobile? selecionado = _selecionados[chave];
    final bool estaSelecionado = selecionado != null;
    final int quantidade = selecionado?.quantidade ?? 0;

    return AnimatedContainer(
      duration: Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: estaSelecionado ? _accentColor : Colors.transparent,
          width: estaSelecionado ? 1.6 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:
                estaSelecionado
                    ? _accentColor.withValues(alpha: 0.18)
                    : SixMobilePalette.navigationShadow,
            blurRadius: estaSelecionado ? 22 : 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => _alternarProdutoSelecionado(produto),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 190),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: estaSelecionado ? _softAccentColor : _surfaceColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    _buildProdutoHeroImage(produto, isProduto),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 180),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              estaSelecionado
                                  ? _accentColor
                                  : _surfaceElevatedColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                estaSelecionado ? _accentColor : _borderColor,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: SixMobilePalette.navigationShadow,
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          estaSelecionado
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          color:
                              estaSelecionado ? _onAccentColor : _accentColor,
                          size: 24,
                        ),
                      ),
                    ),
                    if (estaSelecionado)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: _accentColor.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.check_circle_rounded,
                                color: _onAccentColor,
                                size: 15,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Selecionado',
                                style: TextStyle(
                                  color: _onAccentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            produto.nomeProduto.isEmpty
                                ? 'Item sem nome'
                                : produto.nomeProduto,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _titleTextColor,
                              fontSize: 17,
                              height: 1.16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.qr_code_2_rounded,
                                color: _mutedTextColor,
                                size: 15,
                              ),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  codigo.isEmpty ? 'Sem código' : codigo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _mutedTextColor,
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
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _softAccentColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _formatCurrency(produto.precoVenda),
                        style: TextStyle(
                          color: _titleTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (estaSelecionado) ...<Widget>[
                  SizedBox(height: 14),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _surfaceElevatedColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Quantidade',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _QuantidadeButton(
                          icon: Icons.remove_rounded,
                          onTap:
                              () => _alterarQuantidadeSelecionada(produto, -1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$quantidade',
                            style: TextStyle(
                              color: _titleTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _QuantidadeButton(
                          icon: Icons.add_rounded,
                          onTap:
                              () => _alterarQuantidadeSelecionada(produto, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProdutoHeroImage(ProdutoModel produto, bool isProduto) {
    final dynamic imagem =
        produto.imagens?.isNotEmpty == true ? produto.imagens!.first : null;
    final Uint8List? bytes =
        _decodeBase64Image(imagem?.imagemBase64) ?? _decodeDataUrl(imagem?.url);

    Widget content;
    if (bytes != null) {
      content = Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
    } else if (imagem?.url != null && imagem!.url!.trim().isNotEmpty) {
      content = Image.network(
        imagem.url!,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildHeroPlaceholder(isProduto),
      );
    } else {
      content = _buildHeroPlaceholder(isProduto);
    }

    return AspectRatio(
      aspectRatio: 16 / 8.6,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _softAccentColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _borderColor),
        ),
        child: content,
      ),
    );
  }

  Widget _buildHeroPlaceholder(bool isProduto) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_softAccentColor, _softNeutralColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: _surfaceElevatedColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderColor),
          ),
          child: Icon(
            isProduto
                ? Icons.inventory_2_outlined
                : Icons.design_services_outlined,
            color: _accentColor,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildBarraSelecaoMultipla() {
    final bool possuiSelecionados = _quantidadeSelecionadaTotal > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          border: Border(top: BorderSide(color: _borderColor)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$_quantidadeSelecionadaTotal item(ns) selecionado(s)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  _formatCurrency(_totalSelecionado),
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            FilledButton.icon(
              onPressed: possuiSelecionados ? _confirmarSelecaoMultipla : null,
              icon: Icon(Icons.add_shopping_cart_rounded),
              label: Text('Adicionar selecionados'),
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(48),
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

  void _alternarProdutoSelecionado(ProdutoModel produto) {
    final String chave = _chaveProduto(produto);
    setState(() {
      if (_selecionados.containsKey(chave)) {
        _selecionados.remove(chave);
        return;
      }

      _selecionados[chave] = _ProdutoSelecionadoMobile(
        produto: produto,
        quantidade: 1,
      );
    });
  }

  void _alterarQuantidadeSelecionada(ProdutoModel produto, int delta) {
    final String chave = _chaveProduto(produto);
    final _ProdutoSelecionadoMobile? selecionado = _selecionados[chave];
    if (selecionado == null) return;

    setState(() {
      final int novaQuantidade = selecionado.quantidade + delta;
      if (novaQuantidade <= 0) {
        _selecionados.remove(chave);
        return;
      }

      _selecionados[chave] = selecionado.copyWith(quantidade: novaQuantidade);
    });
  }

  void _confirmarSelecaoMultipla() {
    final List<ProdutoModel> produtosSelecionados = <ProdutoModel>[];
    for (final _ProdutoSelecionadoMobile item in _selecionados.values) {
      produtosSelecionados.addAll(
        List<ProdutoModel>.filled(item.quantidade, item.produto),
      );
    }

    Navigator.of(context).pop<List<ProdutoModel>>(produtosSelecionados);
  }

  String _chaveProduto(ProdutoModel produto) {
    final String tipo = _normalizarTipoProduto(produto.tipoProduto);
    final String prefixo = 'tipo:$tipo';
    final String? id = produto.id;
    if (id != null && id.trim().isNotEmpty) return '$prefixo|id:${id.trim()}';

    final String codigo = produto.codigoDeBarras.trim();
    if (codigo.isNotEmpty) return '$prefixo|codigo:$codigo';

    final String nome = produto.nomeProduto.trim().toLowerCase();
    return '$prefixo|nome:$nome|preco:${produto.precoVenda}';
  }

  Widget _buildThumbnail(
    ProdutoModel produto,
    bool isProduto, {
    required double size,
  }) {
    final dynamic imagem =
        produto.imagens?.isNotEmpty == true ? produto.imagens!.first : null;
    final Uint8List? bytes =
        _decodeBase64Image(imagem?.imagemBase64) ?? _decodeDataUrl(imagem?.url);

    Widget content;
    if (bytes != null) {
      content = Image.memory(bytes, fit: BoxFit.cover);
    } else if (imagem?.url != null && imagem!.url!.trim().isNotEmpty) {
      content = Image.network(
        imagem.url!,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined),
      );
    } else {
      content = Icon(
        isProduto ? Icons.inventory_2_outlined : Icons.design_services_outlined,
        color: _accentColor,
        size: size <= 44 ? 21 : 24,
      );
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _softAccentColor,
        borderRadius: BorderRadius.circular(size <= 44 ? 14 : 17),
        border: Border.all(color: _borderColor),
      ),
      child: Center(child: content),
    );
  }

  Uint8List? _decodeDataUrl(String? value) {
    if (value == null || !value.startsWith('data:image')) return null;
    return _decodeBase64Image(value);
  }

  Uint8List? _decodeBase64Image(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final String payload =
          value.contains(',') ? value.split(',').last : value;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  void _selectTipo(String tipo) {
    if (tipoSelecionado == tipo) return;

    setState(() {
      tipoSelecionado = tipo;
      termoBusca = '';
      _controllerBusca.clear();
      produtosFiltrados = <ProdutoModel>[];
      todosProdutos = <ProdutoModel>[];
    });
    _recarregar();
  }

  Future<void> _criarProduto() async {
    await _abrirCadastro(tipoInicial: tipoSelecionado);
  }

  Future<void> _editarProduto(ProdutoModel produto) async {
    await _abrirCadastro(
      produto: produto,
      tipoInicial:
          produto.tipoProduto.trim().isEmpty
              ? tipoSelecionado
              : produto.tipoProduto,
    );
  }

  Future<void> _abrirCadastro({
    ProdutoModel? produto,
    required String tipoInicial,
  }) async {
    final bool? atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder:
            (_) => CadastroProdutoMobileScreen(
              produtoParaEdicao: produto,
              tipoInicial: tipoInicial,
            ),
      ),
    );

    if (atualizado == true && mounted) await _recarregar();
  }

  Future<void> _showFilterOptions() async {
    final _ProdutoMobileFilterSelection?
    selection = await showModalBottomSheet<_ProdutoMobileFilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      builder: (BuildContext context) {
        final BuildContext sheetContext = context;
        String? categoriaSelecionadaTemp = _categoriaSelecionadaId;
        _ProdutoStatusFiltroMobile statusFiltroTemp = _statusFiltro;
        _ProdutoEstoqueFiltroMobile estoqueFiltroTemp = _estoqueFiltro;
        String ordenacaoTemp = ordenacao;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            Future<void> selecionarCategoria() async {
              final String? categoriaId =
                  await _openSubSheetOnNextFrame<String>(
                    () => _showCategoryFilterSelector(
                      sheetContext,
                      categoriaSelecionadaTemp,
                    ),
                  );
              if (categoriaId == null) return;
              modalSetState(() {
                categoriaSelecionadaTemp =
                    categoriaId.isEmpty ? null : categoriaId;
              });
            }

            Future<void> selecionarStatus() async {
              final _ProdutoStatusFiltroMobile? status =
                  await _openSubSheetOnNextFrame<_ProdutoStatusFiltroMobile>(
                    () => _showStatusFilterSelector(
                      sheetContext,
                      statusFiltroTemp,
                    ),
                  );
              if (status == null) return;
              modalSetState(() => statusFiltroTemp = status);
            }

            Future<void> selecionarEstoque() async {
              final _ProdutoEstoqueFiltroMobile? estoque =
                  await _openSubSheetOnNextFrame<_ProdutoEstoqueFiltroMobile>(
                    () => _showStockFilterSelector(
                      sheetContext,
                      estoqueFiltroTemp,
                    ),
                  );
              if (estoque == null) return;
              modalSetState(() => estoqueFiltroTemp = estoque);
            }

            Future<void> selecionarOrdenacao() async {
              final String? novaOrdenacao =
                  await _openSubSheetOnNextFrame<String>(
                    () => _showSortSelector(sheetContext, ordenacaoTemp),
                  );
              if (novaOrdenacao == null) return;
              modalSetState(() => ordenacaoTemp = novaOrdenacao);
            }

            final bool temFiltros =
                (categoriaSelecionadaTemp != null &&
                    categoriaSelecionadaTemp!.isNotEmpty) ||
                statusFiltroTemp != _ProdutoStatusFiltroMobile.todos ||
                estoqueFiltroTemp != _ProdutoEstoqueFiltroMobile.todos ||
                ordenacaoTemp != 'nome';

            return SafeArea(
              top: false,
              child: Container(
                margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.74,
                ),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: SixMobilePalette.navigationShadow,
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _borderColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _softAccentColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _accentColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _t(
                                    'produto.mobile.filtersTitle',
                                    'Filtrar catálogo',
                                  ),
                                  style: TextStyle(
                                    color: _titleTextColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _t(
                                    'produto.mobile.filtersSubtitle',
                                    'Ajuste categoria, status, estoque e ordenação.',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _mutedTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _FilterSelectorTile(
                        icon: Icons.category_outlined,
                        label: _t(
                          'produto.webList.filter.category',
                          'Categoria',
                        ),
                        value: _categoriaSelecionadaLabel(
                          categoriaSelecionadaTemp,
                        ),
                        onTap: selecionarCategoria,
                      ),
                      SizedBox(height: 10),
                      _FilterSelectorTile(
                        icon: Icons.toggle_on_outlined,
                        label: _t('atendimentoTecnico.status', 'Status'),
                        value: _statusFiltroLabel(statusFiltroTemp),
                        onTap: selecionarStatus,
                      ),
                      SizedBox(height: 10),
                      _FilterSelectorTile(
                        icon: Icons.inventory_2_outlined,
                        label: _t('workspaceHome.stock.title', 'Estoque'),
                        value: _estoqueFiltroLabel(estoqueFiltroTemp),
                        onTap: selecionarEstoque,
                      ),
                      SizedBox(height: 10),
                      _FilterSelectorTile(
                        icon: Icons.swap_vert_rounded,
                        label: _t('produto.webList.sort.label', 'Ordenação'),
                        value: _ordenacaoLabel(ordenacaoTemp),
                        onTap: selecionarOrdenacao,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  temFiltros
                                      ? () {
                                        modalSetState(() {
                                          categoriaSelecionadaTemp = null;
                                          statusFiltroTemp =
                                              _ProdutoStatusFiltroMobile.todos;
                                          estoqueFiltroTemp =
                                              _ProdutoEstoqueFiltroMobile.todos;
                                          ordenacaoTemp = 'nome';
                                        });
                                      }
                                      : null,
                              child: Text(_t('common.clear', 'Limpar')),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop(
                                  _ProdutoMobileFilterSelection(
                                    categoriaId: categoriaSelecionadaTemp,
                                    statusFiltro: statusFiltroTemp,
                                    estoqueFiltro: estoqueFiltroTemp,
                                    ordenacao: ordenacaoTemp,
                                  ),
                                );
                              },
                              child: Text(_t('common.confirm', 'Confirmar')),
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

    if (selection == null || !mounted) return;

    setState(() {
      _categoriaSelecionadaId = selection.categoriaId;
      _statusFiltro = selection.statusFiltro;
      _estoqueFiltro = selection.estoqueFiltro;
      ordenacao = selection.ordenacao;
    });
    aplicarFiltroOrdenacao();
  }

  Future<String?> _showCategoryFilterSelector(
    BuildContext launcherContext,
    String? categoriaSelecionada,
  ) async {
    String termo = '';

    final String? result = await showModalBottomSheet<String>(
      context: launcherContext,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            final List<_CategoriaFiltroMobile> categoriasFiltradas =
                _categoriasDisponiveis()
                    .where((_CategoriaFiltroMobile categoria) {
                      if (termo.trim().isEmpty) return true;
                      return categoria.nome.toLowerCase().contains(
                        termo.trim().toLowerCase(),
                      );
                    })
                    .toList(growable: false);
            final List<Widget> categoriaOptions = <Widget>[
              _SortOptionTile(
                icon: Icons.layers_clear_outlined,
                title: _t(
                  'produto.webList.filter.categoryAll',
                  'Todas categorias',
                ),
                subtitle: _t(
                  'produto.mobile.allCategoriesSubtitle',
                  'Mostra qualquer categoria disponível.',
                ),
                selected:
                    categoriaSelecionada == null ||
                    categoriaSelecionada.isEmpty,
                onTap: () => Navigator.of(context).pop(''),
              ),
              ...categoriasFiltradas.map(
                (_CategoriaFiltroMobile categoria) => Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: _SortOptionTile(
                    icon: Icons.category_outlined,
                    title: categoria.nome,
                    subtitle: _t(
                      'produto.mobile.categoryOptionSubtitle',
                      'Filtra a lista por esta categoria.',
                    ),
                    selected: categoriaSelecionada == categoria.id,
                    onTap: () => Navigator.of(context).pop(categoria.id),
                  ),
                ),
              ),
            ];
            final bool exibirListaCompacta = categoriaOptions.length <= 4;

            Widget buildHeader() {
              return Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _borderColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _t('produto.webList.filter.category', 'Categoria'),
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _softNeutralColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _borderColor),
                      ),
                      child: TextField(
                        cursorColor: _accentColor,
                        onChanged:
                            (String value) =>
                                modalSetState(() => termo = value),
                        decoration: InputDecoration(
                          hintText: _t('common.search', 'Buscar'),
                          hintStyle: TextStyle(color: _mutedTextColor),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _accentColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            BoxDecoration decoration = BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.navigationShadow,
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            );

            if (categoriasFiltradas.isEmpty || exibirListaCompacta) {
              return SafeArea(
                top: false,
                child: Container(
                  margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                  ),
                  decoration: decoration,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        buildHeader(),
                        if (categoriasFiltradas.isEmpty)
                          Padding(
                            padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
                            child: Text(
                              _t(
                                'common.noResults',
                                'Nenhum resultado encontrado',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(children: categoriaOptions),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.82,
                minChildSize: 0.60,
                maxChildSize: 0.96,
                builder: (
                  BuildContext context,
                  ScrollController scrollController,
                ) {
                  return Container(
                    margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: decoration,
                    child: Column(
                      children: <Widget>[
                        buildHeader(),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: categoriaOptions,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    return result;
  }

  Future<_ProdutoStatusFiltroMobile?> _showStatusFilterSelector(
    BuildContext launcherContext,
    _ProdutoStatusFiltroMobile selected,
  ) {
    return _showFilterOptionSelector<_ProdutoStatusFiltroMobile>(
      launcherContext: launcherContext,
      title: _t('atendimentoTecnico.status', 'Status'),
      options: <_FilterOption<_ProdutoStatusFiltroMobile>>[
        _FilterOption<_ProdutoStatusFiltroMobile>(
          value: _ProdutoStatusFiltroMobile.todos,
          icon: Icons.apps_rounded,
          title: _t('produto.webList.filter.statusAll', 'Todos'),
          subtitle: _t(
            'produto.mobile.statusAllSubtitle',
            'Exibe itens ativos e inativos.',
          ),
        ),
        _FilterOption<_ProdutoStatusFiltroMobile>(
          value: _ProdutoStatusFiltroMobile.ativos,
          icon: Icons.check_circle_outline_rounded,
          title: _t('common.active', 'Ativo'),
          subtitle: _t(
            'produto.mobile.statusActiveSubtitle',
            'Mostra apenas itens ativos.',
          ),
        ),
        _FilterOption<_ProdutoStatusFiltroMobile>(
          value: _ProdutoStatusFiltroMobile.inativos,
          icon: Icons.pause_circle_outline_rounded,
          title: _t('common.inactive', 'Inativo'),
          subtitle: _t(
            'produto.mobile.statusInactiveSubtitle',
            'Mostra apenas itens inativos.',
          ),
        ),
      ],
      selected: selected,
    );
  }

  Future<_ProdutoEstoqueFiltroMobile?> _showStockFilterSelector(
    BuildContext launcherContext,
    _ProdutoEstoqueFiltroMobile selected,
  ) {
    return _showFilterOptionSelector<_ProdutoEstoqueFiltroMobile>(
      launcherContext: launcherContext,
      title: _t('workspaceHome.stock.title', 'Estoque'),
      options: <_FilterOption<_ProdutoEstoqueFiltroMobile>>[
        _FilterOption<_ProdutoEstoqueFiltroMobile>(
          value: _ProdutoEstoqueFiltroMobile.todos,
          icon: Icons.apps_rounded,
          title: _t('produto.webList.filter.stockAll', 'Todos'),
          subtitle: _t(
            'produto.mobile.stockAllSubtitle',
            'Não restringe a situação de estoque.',
          ),
        ),
        _FilterOption<_ProdutoEstoqueFiltroMobile>(
          value: _ProdutoEstoqueFiltroMobile.emEstoque,
          icon: Icons.inventory_2_outlined,
          title: _t('produto.webList.filter.stockAvailable', 'Em estoque'),
          subtitle: _t(
            'produto.mobile.stockAvailableSubtitle',
            'Mostra itens com saldo disponível.',
          ),
        ),
        _FilterOption<_ProdutoEstoqueFiltroMobile>(
          value: _ProdutoEstoqueFiltroMobile.estoqueBaixo,
          icon: Icons.warning_amber_rounded,
          title: _t('produto.webList.stockLow', 'Estoque baixo'),
          subtitle: _t(
            'produto.mobile.stockLowSubtitle',
            'Mostra itens no mínimo configurado.',
          ),
        ),
        _FilterOption<_ProdutoEstoqueFiltroMobile>(
          value: _ProdutoEstoqueFiltroMobile.semEstoque,
          icon: Icons.remove_shopping_cart_outlined,
          title: _t('produto.webList.stockOut', 'Sem estoque'),
          subtitle: _t(
            'produto.mobile.stockOutSubtitle',
            'Mostra itens sem saldo no catálogo.',
          ),
        ),
        _FilterOption<_ProdutoEstoqueFiltroMobile>(
          value: _ProdutoEstoqueFiltroMobile.estoqueNegativo,
          icon: Icons.trending_down_rounded,
          title: _t('produto.webList.stockNegative', 'Estoque negativo'),
          subtitle: _t(
            'produto.mobile.stockNegativeSubtitle',
            'Mostra itens com saldo negativo.',
          ),
        ),
      ],
      selected: selected,
    );
  }

  Future<String?> _showSortSelector(
    BuildContext launcherContext,
    String selected,
  ) {
    return _showFilterOptionSelector<String>(
      launcherContext: launcherContext,
      title: _t('produto.webList.sort.label', 'Ordenação'),
      options: <_FilterOption<String>>[
        _FilterOption<String>(
          value: 'nome',
          icon: Icons.sort_by_alpha_rounded,
          title: _t('produto.mobile.sortName', 'Nome'),
          subtitle: _t('produto.mobile.sortNameSubtitle', 'Ordem alfabética.'),
        ),
        _FilterOption<String>(
          value: 'precoAsc',
          icon: Icons.south_west_rounded,
          title: _t('produto.mobile.sortLowestPrice', 'Menor preço'),
          subtitle: _t(
            'produto.mobile.sortLowestPriceSubtitle',
            'Do mais barato ao mais caro.',
          ),
        ),
        _FilterOption<String>(
          value: 'precoDesc',
          icon: Icons.north_east_rounded,
          title: _t('produto.mobile.sortHighestPrice', 'Maior preço'),
          subtitle: _t(
            'produto.mobile.sortHighestPriceSubtitle',
            'Do mais caro ao mais barato.',
          ),
        ),
      ],
      selected: selected,
    );
  }

  Future<T?> _showFilterOptionSelector<T>({
    required BuildContext launcherContext,
    required String title,
    required List<_FilterOption<T>> options,
    required T selected,
  }) {
    return showModalBottomSheet<T>(
      context: launcherContext,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      builder: (BuildContext context) {
        final List<Widget> optionTiles = options
            .asMap()
            .entries
            .map((MapEntry<int, _FilterOption<T>> entry) {
              final _FilterOption<T> option = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == options.length - 1 ? 0 : 8,
                ),
                child: _SortOptionTile(
                  icon: option.icon,
                  title: option.title,
                  subtitle: option.subtitle,
                  selected: option.value == selected,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
              );
            })
            .toList(growable: false);
        final bool exibirListaCompacta = optionTiles.length <= 4;

        return SafeArea(
          top: false,
          child: Container(
            margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.74,
            ),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.navigationShadow,
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _borderColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 16),
                  Flexible(
                    child:
                        exibirListaCompacta
                            ? SingleChildScrollView(
                              child: Column(children: optionTiles),
                            )
                            : ListView(shrinkWrap: true, children: optionTiles),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double value) {
    return context.read<LocaleSettingsProvider>().formatCurrency(value);
  }

  String _formatDecimal(num value) {
    return context.read<LocaleSettingsProvider>().formatDecimal(value);
  }

  String _categoriaProdutoLabel(ProdutoModel produto) {
    return produto.objCategoria?.nomeCategoria.trim() ?? '';
  }

  String _grupoProdutoLabel(ProdutoModel produto) {
    return produto.objAgrupamento?.grupoDoProduto.trim() ?? '';
  }

  String _estoqueProdutoLabel(ProdutoModel produto) {
    if (!_matchesTipoSelecionado(produto, 'PRODUTO')) return '';

    final double quantidade = _quantidadeEstoque(produto);
    final _ProdutoSituacaoEstoqueMobile situacao = _situacaoEstoque(produto);

    switch (situacao) {
      case _ProdutoSituacaoEstoqueMobile.naoAplicavel:
        return '';
      case _ProdutoSituacaoEstoqueMobile.emEstoque:
        return _t(
          'produto.webList.stockQuantity',
          'Qtd {value}',
        ).replaceAll('{value}', _formatDecimal(quantidade));
      case _ProdutoSituacaoEstoqueMobile.estoqueBaixo:
        return _t('produto.webList.stockLow', 'Estoque baixo');
      case _ProdutoSituacaoEstoqueMobile.semEstoque:
        return _t('produto.webList.stockOut', 'Sem estoque');
      case _ProdutoSituacaoEstoqueMobile.estoqueNegativo:
        return _t('produto.webList.stockNegative', 'Estoque negativo');
    }
  }

  String _garantiaProdutoLabel(ProdutoModel produto) {
    final String garantia = produto.objetoServico?.tempoDaGarantia.trim() ?? '';
    if (garantia.isEmpty) return '';

    return '${_t('produto.mobile.warrantyLabel', 'Tempo da garantia')}: $garantia';
  }

  Color _corEstoqueProduto(ProdutoModel produto) {
    final _ProdutoSituacaoEstoqueMobile situacao = _situacaoEstoque(produto);

    switch (situacao) {
      case _ProdutoSituacaoEstoqueMobile.estoqueNegativo:
      case _ProdutoSituacaoEstoqueMobile.semEstoque:
        return const Color(0xFFDC2626);
      case _ProdutoSituacaoEstoqueMobile.estoqueBaixo:
        return const Color(0xFFF97316);
      case _ProdutoSituacaoEstoqueMobile.emEstoque:
      case _ProdutoSituacaoEstoqueMobile.naoAplicavel:
        return _titleTextColor;
    }
  }

  String _resumoProdutoHorizontal(ProdutoModel produto) {
    final List<String> partes = <String>[];

    final String categoria = _categoriaProdutoLabel(produto);
    if (categoria.isNotEmpty) {
      partes.add(
        '${_t('produto.mobile.categoryLabel', 'Categoria')} $categoria',
      );
    }

    final String modelo = produto.modeloProduto.trim();
    if (modelo.isNotEmpty && modelo.toUpperCase() != 'UNIDADE') {
      partes.add('${_t('produto.mobile.modelLabel', 'Modelo')} $modelo');
    }

    final String garantia = _garantiaProdutoLabel(produto);
    if (garantia.isNotEmpty) {
      partes.add(garantia);
    }

    return partes.join('. ');
  }

  String _resumoProdutoVertical(ProdutoModel produto, bool ativo) {
    final List<String> partes = <String>[_formatCurrency(produto.precoVenda)];
    final String codigo = produto.codigoDeBarras.trim();
    final String categoria = _categoriaProdutoLabel(produto);
    final String grupo = _grupoProdutoLabel(produto);
    final String alertaEstoque = _alertaEstoqueProdutoVertical(produto);

    if (codigo.isNotEmpty) {
      partes.add(codigo);
    } else if (categoria.isNotEmpty) {
      partes.add(categoria);
    } else if (grupo.isNotEmpty) {
      partes.add(grupo);
    } else {
      partes.add(
        _matchesTipoSelecionado(produto, 'PRODUTO')
            ? _t('produto.mobile.typeProduct', 'Produto')
            : _t('produto.mobile.typeService', 'Serviço'),
      );
    }

    if (!ativo) {
      partes.add(_t('common.inactive', 'Inativo'));
    } else if (alertaEstoque.isNotEmpty) {
      partes.add(alertaEstoque);
    }

    return partes.join(' • ');
  }

  String _alertaEstoqueProdutoVertical(ProdutoModel produto) {
    switch (_situacaoEstoque(produto)) {
      case _ProdutoSituacaoEstoqueMobile.estoqueBaixo:
        return _t('produto.webList.stockLow', 'Estoque baixo');
      case _ProdutoSituacaoEstoqueMobile.semEstoque:
        return _t('produto.webList.stockOut', 'Sem estoque');
      case _ProdutoSituacaoEstoqueMobile.estoqueNegativo:
        return _t('produto.webList.stockNegative', 'Estoque negativo');
      case _ProdutoSituacaoEstoqueMobile.emEstoque:
      case _ProdutoSituacaoEstoqueMobile.naoAplicavel:
        return '';
    }
  }

  Widget _buildProdutoInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceElevatedColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProdutoInfoRow({
    required String label,
    String? value,
    Widget? valueWidget,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12),
          if (valueWidget != null)
            valueWidget
          else
            Flexible(
              child: Text(
                value ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: valueColor ?? _titleTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _categoriaSelecionadaLabel(String? categoriaId) {
    if (categoriaId == null || categoriaId.isEmpty) {
      return _t('produto.webList.filter.categoryAll', 'Todas categorias');
    }

    for (final _CategoriaFiltroMobile categoria in _categoriasDisponiveis()) {
      if (categoria.id == categoriaId) return categoria.nome;
    }

    return _t('produto.webList.filter.categoryAll', 'Todas categorias');
  }

  String _statusFiltroLabel(_ProdutoStatusFiltroMobile statusFiltro) {
    switch (statusFiltro) {
      case _ProdutoStatusFiltroMobile.todos:
        return _t('produto.webList.filter.statusAll', 'Todos');
      case _ProdutoStatusFiltroMobile.ativos:
        return _t('common.active', 'Ativo');
      case _ProdutoStatusFiltroMobile.inativos:
        return _t('common.inactive', 'Inativo');
    }
  }

  String _estoqueFiltroLabel(_ProdutoEstoqueFiltroMobile estoqueFiltro) {
    switch (estoqueFiltro) {
      case _ProdutoEstoqueFiltroMobile.todos:
        return _t('produto.webList.filter.stockAll', 'Todos');
      case _ProdutoEstoqueFiltroMobile.emEstoque:
        return _t('produto.webList.filter.stockAvailable', 'Em estoque');
      case _ProdutoEstoqueFiltroMobile.estoqueBaixo:
        return _t('produto.webList.stockLow', 'Estoque baixo');
      case _ProdutoEstoqueFiltroMobile.semEstoque:
        return _t('produto.webList.stockOut', 'Sem estoque');
      case _ProdutoEstoqueFiltroMobile.estoqueNegativo:
        return _t('produto.webList.stockNegative', 'Estoque negativo');
    }
  }

  String _ordenacaoLabel(String ordenacaoAtual) {
    switch (ordenacaoAtual) {
      case 'precoAsc':
        return _t('produto.mobile.sortLowestPrice', 'Menor preço');
      case 'precoDesc':
        return _t('produto.mobile.sortHighestPrice', 'Maior preço');
      case 'nome':
      default:
        return _t('produto.webList.sort.name', 'Ordenar por nome');
    }
  }
}

class _ProdutoSelecionadoMobile {
  const _ProdutoSelecionadoMobile({
    required this.produto,
    required this.quantidade,
  });

  final ProdutoModel produto;
  final int quantidade;

  double get total => produto.precoVenda * quantidade;

  _ProdutoSelecionadoMobile copyWith({int? quantidade}) {
    return _ProdutoSelecionadoMobile(
      produto: produto,
      quantidade: quantidade ?? this.quantidade,
    );
  }
}

class _SwipeRevealAction {
  const _SwipeRevealAction({
    required this.semanticLabel,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    this.isLoading = false,
  });

  final String semanticLabel;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final FutureOr<void> Function() onTap;
  final bool isLoading;
}

class _SwipeRevealTile extends StatefulWidget {
  const _SwipeRevealTile({
    super.key,
    required this.child,
    required this.actions,
    required this.onTap,
    required this.backgroundColor,
    required this.dividerColor,
  });

  final Widget child;
  final List<_SwipeRevealAction> actions;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color dividerColor;

  @override
  State<_SwipeRevealTile> createState() => _SwipeRevealTileState();
}

class _SwipeRevealTileState extends State<_SwipeRevealTile> {
  static const double _actionWidth = 54;
  static const double _tileHeight = 64;
  static const double _dividerLeadingInset = 68;
  static const double _dividerTrailingInset = 12;
  double _dragOffset = 0;

  double get _maxReveal => widget.actions.length * _actionWidth;

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final double nextOffset = _dragOffset + details.primaryDelta!;
    setState(() {
      _dragOffset = nextOffset.clamp(-_maxReveal, 0.0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    final bool shouldOpen =
        velocity < -240 || _dragOffset.abs() > (_maxReveal * 0.42);

    setState(() {
      _dragOffset = shouldOpen ? -_maxReveal : 0;
    });
  }

  Future<void> _handleAction(_SwipeRevealAction action) async {
    setState(() => _dragOffset = 0);
    await action.onTap();
  }

  void _handleTap() {
    if (_dragOffset != 0) {
      setState(() => _dragOffset = 0);
      return;
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tileHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(color: widget.backgroundColor),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _maxReveal,
                child: Row(
                  children: widget.actions
                      .map((_SwipeRevealAction action) {
                        return Expanded(
                          child: Semantics(
                            button: true,
                            label: action.semanticLabel,
                            child: Material(
                              color: action.backgroundColor,
                              child: InkWell(
                                onTap:
                                    action.isLoading
                                        ? null
                                        : () => _handleAction(action),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: action.borderColor,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child:
                                        action.isLoading
                                            ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: action.foregroundColor,
                                              ),
                                            )
                                            : Icon(
                                              action.icon,
                                              color: action.foregroundColor,
                                              size: 19,
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                onHorizontalDragEnd: _handleHorizontalDragEnd,
                child: widget.child,
              ),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: _dividerLeadingInset,
                  right: _dividerTrailingInset,
                ),
                child: Container(height: 1, color: widget.dividerColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantidadeButton extends StatelessWidget {
  const _QuantidadeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SixMobilePalette.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SixMobilePalette.border),
          ),
          child: Icon(icon, color: SixMobilePalette.accent, size: 18),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        color: selected ? SixMobilePalette.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 9 : 11,
              horizontal: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color:
                      selected
                          ? SixMobilePalette.onAccent
                          : SixMobilePalette.mutedText,
                ),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color:
                          selected
                              ? SixMobilePalette.onAccent
                              : SixMobilePalette.mutedText,
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        ativo
            ? (isDark ? const Color(0xFF052E1A) : const Color(0xFFEAF8EE))
            : (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2));
    final Color foregroundColor =
        ativo
            ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A))
            : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo
            ? context.t('common.active', fallback: 'Ativo')
            : context.t('common.inactive', fallback: 'Inativo'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _CatalogStatusChip extends StatelessWidget {
  const _CatalogStatusChip({required this.disponivelParaCatalogo});

  final bool disponivelParaCatalogo;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        disponivelParaCatalogo
            ? (isDark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE))
            : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFF4F4F5));
    final Color foregroundColor =
        disponivelParaCatalogo
            ? (isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1))
            : (isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        disponivelParaCatalogo
            ? context.t(
              'produto.catalog.availableStatus',
              fallback: 'Disponível',
            )
            : context.t(
              'produto.catalog.unavailableStatus',
              fallback: 'Indisponível',
            ),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _FilterSelectorTile extends StatelessWidget {
  const _FilterSelectorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SixMobilePalette.softNeutralSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SixMobilePalette.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: SixMobilePalette.softAccentSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: SixMobilePalette.accent, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: SixMobilePalette.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption<T> {
  const _FilterOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final T value;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color:
              selected
                  ? SixMobilePalette.softAccentSurface
                  : SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? SixMobilePalette.accent : SixMobilePalette.border,
            width: selected ? 1.3 : 1,
          ),
          boxShadow:
              selected
                  ? <BoxShadow>[
                    BoxShadow(
                      color: SixMobilePalette.accent.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                  : <BoxShadow>[],
        ),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                    selected
                        ? SixMobilePalette.accent
                        : SixMobilePalette.surfaceElevated,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color:
                      selected
                          ? SixMobilePalette.accent
                          : SixMobilePalette.border,
                ),
              ),
              child: Icon(
                icon,
                color:
                    selected
                        ? SixMobilePalette.onAccent
                        : SixMobilePalette.mutedText,
                size: 18,
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          selected
                              ? SixMobilePalette.accent
                              : SixMobilePalette.titleText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              duration: Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              scale: selected ? 1 : 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: SixMobilePalette.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: SixMobilePalette.onAccent,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: SixMobilePalette.accent,
          backgroundColor: SixMobilePalette.activeBorder,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.wifi_off_outlined, color: Color(0xFFDC2626), size: 34),
          SizedBox(height: 10),
          Text(
            context.t(
              'produto.mobile.catalogLoadError',
              fallback: 'Não foi possível carregar o catálogo.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onRetry(),
            icon: Icon(Icons.refresh_rounded),
            label: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.inventory_2_outlined,
            color: SixMobilePalette.accent,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            context.t(
              'produto.mobile.emptyTitle',
              fallback: 'Nenhum item encontrado.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            context.t(
              'produto.mobile.emptyDescription',
              fallback: 'Ajuste a busca ou atualize a listagem.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: SixMobilePalette.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
