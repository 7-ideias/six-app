import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/utils/produto_helper.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/produto_cadastrar_mobile_screen.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

class ProdutolistMobileScreen extends StatefulWidget {
  const ProdutolistMobileScreen({
    super.key,
    this.isSelecao = false,
    this.permitirSelecaoMultipla = false,
  });

  final bool isSelecao;
  final bool permitirSelecaoMultipla;

  @override
  State<ProdutolistMobileScreen> createState() =>
      _ProdutolistMobileScreenState();
}

class _ProdutolistMobileScreenState extends State<ProdutolistMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  final TextEditingController _controllerBusca = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusBusca = FocusNode();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();

  Timer? _timerOcultarBusca;
  bool _exibirCampoBusca = false;
  final Map<String, _ProdutoSelecionadoMobile> _selecionados =
      <String, _ProdutoSelecionadoMobile>{};
  final Set<String> _favoritosVisuais = <String>{};
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
  bool _salvandoPreferencia = false;
  bool _fixarHeaderLista = false;
  bool _exibirValores = true;

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
      onSucesso: atualizarListaComProvider,
    );
  }

  void atualizarListaComProvider(List<ProdutoModel> listaDeProdutos) {
    todosProdutos = listaDeProdutos;
    aplicarFiltroOrdenacao();
  }

  void aplicarFiltroOrdenacao() {
    final List<ProdutoModel> listaBase = ProdutoHelper.filtrarEOrdenarProdutos(
      produtos: todosProdutos,
      termoBusca: termoBusca,
      ordenacao: ordenacao,
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

  String _normalizarTipoProduto(String tipo) {
    final String normalizado = tipo.trim().toUpperCase();
    if (normalizado.isEmpty) return 'PRODUTO';
    if (normalizado == 'SERVIÇO') return 'SERVICO';
    return normalizado;
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
        const SnackBar(
          content: Text('Não foi possível carregar suas preferências.'),
        ),
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
        const SnackBar(
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

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            title:
                isSelecao
                    ? const Text(
                      'Selecionar item',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    )
                    : null,
            actions: const <Widget>[],
          ),
          body: SafeArea(
            child: Stack(
              children: <Widget>[
                RefreshIndicator(
                  onRefresh: _recarregar,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      isSelecao ? 12 : 14,
                      16,
                      bottomPadding,
                    ),
                    children: <Widget>[
                      if (!isSelecao) ...<Widget>[
                        SixStaggeredEntry(child: _buildHeaderCard()),
                        const SizedBox(height: 16),
                      ],
                      SixStaggeredEntry(
                        delay: const Duration(milliseconds: 70),
                        child: _buildTabs(compact: isSelecao),
                      ),
                      if (_exibirCampoBusca &&
                          !_deveExibirHeaderListaFixo(isSelecao)) ...<Widget>[
                        const SizedBox(height: 12),
                        SixStaggeredEntry(
                          delay: const Duration(milliseconds: 120),
                          child: _buildSearchField(),
                        ),
                      ],
                      SizedBox(
                        height:
                            _exibirCampoBusca &&
                                    !_deveExibirHeaderListaFixo(isSelecao)
                                ? (isSelecao ? 14 : 18)
                                : 14,
                      ),
                      if (!_deveExibirHeaderListaFixo(isSelecao)) ...<Widget>[
                        _buildListHeader(
                          itensDaLista.length,
                          provider.isLoading,
                        ),
                        const SizedBox(height: 10),
                      ],
                      ..._buildListContent(provider, itensDaLista, isSelecao),
                    ],
                  ),
                ),
                if (_deveExibirHeaderListaFixo(isSelecao))
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildHeaderListaFixo(
                      itensDaLista.length,
                      provider.isLoading,
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton:
              isSelecao
                  ? null
                  : FloatingActionButton.extended(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    onPressed: _criarProduto,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      _isProdutoSelecionado ? 'Novo produto' : 'Novo serviço',
                    ),
                  ),
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
      shadowColor: const Color(0x1A000000),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildListHeader(count, isLoading),
            if (_exibirCampoBusca) ...<Widget>[
              const SizedBox(height: 10),
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
      return const <Widget>[_LoadingState()];
    }

    if (provider.erro != null && todosProdutos.isEmpty) {
      return <Widget>[_ErrorState(onRetry: _recarregar)];
    }

    if (itensDaLista.isEmpty) {
      return const <Widget>[_EmptyState()];
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
      return Padding(
        padding: EdgeInsets.only(bottom: isSelecao ? 8 : 12),
        child: SixStaggeredEntry(
          delay: Duration(milliseconds: itemDelay),
          child: _buildProdutoCard(entry.value),
        ),
      );
    }).toList();
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x220B1F3A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: _buildSummarySection(),
    );
  }

  Widget _buildTabs({required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SegmentButton(
              label: 'Produtos',
              icon: Icons.inventory_2_outlined,
              selected: _isProdutoSelecionado,
              compact: compact,
              onTap: () => _selectTipo('PRODUTO'),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Serviços',
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

  void _alternarExibicaoValores() {
    setState(() => _exibirValores = !_exibirValores);
  }

  Widget _buildExibirValoresHeaderButton() {
    return Tooltip(
      message: _exibirValores ? 'Esconder resumo' : 'Revelar resumo',
      child: InkWell(
        onTap: _alternarExibicaoValores,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
                _exibirValores
                    ? const Color(0x26FFFFFF)
                    : const Color(0x14FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x3DFFFFFF)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Icon(
              _exibirValores
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              key: ValueKey<bool>(_exibirValores),
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _controllerBusca,
        focusNode: _focusBusca,
        onTap: _reiniciarTimerOcultarBusca,
        onChanged: (String value) {
          termoBusca = value;
          aplicarFiltroOrdenacao();
          _reiniciarTimerOcultarBusca();
        },
        decoration: InputDecoration(
          hintText:
              _isProdutoSelecionado
                  ? 'Buscar produto ou código'
                  : 'Buscar serviço',
          hintStyle: const TextStyle(color: _mutedTextColor),
          prefixIcon: const Icon(Icons.search_rounded, color: _accentColor),
          suffixIcon:
              _controllerBusca.text.isEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: _titleTextColor,
                    ),
                    onPressed: _showSortOptions,
                  )
                  : IconButton(
                    onPressed: () {
                      _controllerBusca.clear();
                      termoBusca = '';
                      aplicarFiltroOrdenacao();
                      _reiniciarTimerOcultarBusca();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _mutedTextColor,
                    ),
                  ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Consumer<ProdutosListProvider<ProdutoModel>>(
      builder: (
        BuildContext context,
        ProdutosListProvider<ProdutoModel> provider,
        _,
      ) {
        final Object? response = provider.fullResponse;
        if (response is! ProdutoResponseModel) return const SizedBox.shrink();

        final String itensResumo = _formatResumoValorVisivel(
          response.skusTotaisNoEstoque.toString(),
        );
        final String semEstoqueResumo = _formatResumoValorVisivel(
          _isProdutoSelecionado ? _formatNumber(response.qtSemEstoque) : '-',
        );
        final String valorResumo = _formatResumoValorVisivel(
          _formatCurrency(response.vlEstoqueEmGrana),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 44),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _SummaryCard(label: 'Itens', value: itensResumo),
                  _SummaryCard(label: 'Sem estoque', value: semEstoqueResumo),
                  _SummaryCard(
                    label: 'Valor',
                    value: valorResumo,
                    compact: true,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _buildExibirValoresHeaderButton(),
            ),
          ],
        );
      },
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
      const Duration(seconds: 10),
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
      message: _isProdutoSelecionado ? 'Buscar produtos' : 'Buscar serviços',
      child: InkWell(
        onTap: _abrirCampoBusca,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
                _exibirCampoBusca
                    ? const Color(0xFFDDEBFF)
                    : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            Icons.search_rounded,
            color: _accentColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroListHeaderButton() {
    final bool ordenacaoAlterada = ordenacao != 'nome';

    return Tooltip(
      message: 'Ordenar catálogo',
      child: InkWell(
        onTap: _showSortOptions,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
                ordenacaoAlterada
                    ? const Color(0xFFDDEBFF)
                    : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: ordenacaoAlterada ? _secondaryColor : _accentColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  bool _produtoFavoritoVisual(ProdutoModel produto) {
    return _favoritosVisuais.contains(_chaveProduto(produto));
  }

  void _alternarFavoritoVisual(ProdutoModel produto) {
    final String chave = _chaveProduto(produto);

    setState(() {
      if (_favoritosVisuais.contains(chave)) {
        _favoritosVisuais.remove(chave);
        return;
      }

      _favoritosVisuais.add(chave);
    });
  }

  Widget _buildFavoritoVisualButton(
    ProdutoModel produto, {
    bool sobreImagem = false,
  }) {
    final bool favorito = _produtoFavoritoVisual(produto);

    return Tooltip(
      message: favorito ? 'Remover dos favoritos' : 'Marcar como favorito',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _alternarFavoritoVisual(produto),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  favorito
                      ? const Color(0xFFEF4444)
                      : sobreImagem
                      ? const Color(0xD9FFFFFF)
                      : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    favorito
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFFCA5A5),
              ),
              boxShadow:
                  sobreImagem
                      ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                      : const <BoxShadow>[],
            ),
            child: Icon(
              favorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorito ? Colors.white : const Color(0xFFEF4444),
              size: 19,
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
              ? 'Usar visualização vertical'
              : 'Usar visualização horizontal',
      child: InkWell(
        onTap: _salvandoPreferencia ? null : _alternarModoExibicaoProdutos,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child:
              _salvandoPreferencia
                  ? const Center(
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
                ? 'Selecione um ou mais itens'
                : (_isProdutoSelecionado
                    ? 'Toque no produto para adicionar'
                    : 'Toque no serviço para adicionar'))
            : (_isProdutoSelecionado ? 'Produtos' : 'Serviços');

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isLoading) ...<Widget>[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ],
        _buildBuscaListHeaderButton(),
        const SizedBox(width: 8),
        _buildFiltroListHeaderButton(),
        const SizedBox(width: 8),
        _buildModoExibicaoListHeaderButton(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count ${count == 1 ? 'item' : 'itens'}',
            style: const TextStyle(
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
    final int imagensCount = produto.imagens?.length ?? 0;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _editarProduto(produto),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildThumbnail(produto, isProduto, size: 54),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            produto.nomeProduto,
                            maxLines: _exibicaoHorizontal ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              color: _titleTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildFavoritoVisualButton(produto),
                        const SizedBox(width: 8),
                        _StatusChip(ativo: ativo),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _InfoChip(
                          icon: Icons.qr_code_2_rounded,
                          label:
                              produto.codigoDeBarras.isEmpty
                                  ? 'Sem código'
                                  : 'Código ${produto.codigoDeBarras}',
                        ),
                        if (produto.modeloProduto.isNotEmpty)
                          _InfoChip(
                            icon: Icons.straighten_rounded,
                            label: produto.modeloProduto,
                          ),
                        _InfoChip(
                          icon: Icons.photo_library_outlined,
                          label:
                              '$imagensCount foto${imagensCount == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _formatCurrency(produto.precoVenda),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _titleTextColor,
                            ),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
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
            ],
          ),
        ),
      ),
    );
  }

  double _calcularAlturaCatalogoHorizontal(
    List<ProdutoModel> itensDaLista,
    bool isSelecao,
  ) {
    if (isSelecao) return _selecaoMultiplaAtiva ? 376 : 118;

    const double alturaMinima = 390;

    final MediaQueryData media = MediaQuery.of(context);
    const double alturaReservadaPeloFab = 96;
    const double espacamentoAteCatalogo = 230;

    final double alturaDisponivel =
        media.size.height -
        media.padding.top -
        media.padding.bottom -
        kToolbarHeight -
        alturaReservadaPeloFab -
        espacamentoAteCatalogo;

    return alturaDisponivel < alturaMinima ? alturaMinima : alturaDisponivel;
  }

  bool _produtoTemImagem(ProdutoModel produto) {
    return _imagensValidasProduto(produto).isNotEmpty;
  }

  List<dynamic> _imagensValidasProduto(ProdutoModel produto) {
    final List<dynamic> imagens = List<dynamic>.from(
      produto.imagens ?? const <dynamic>[],
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

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _editarProduto(produto),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
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
                      child: _buildFavoritoVisualButton(
                        produto,
                        sobreImagem: true,
                      ),
                    ),
                    Positioned(
                      right: 9,
                      bottom: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _formatCurrency(produto.precoVenda),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
              const SizedBox(height: 10),
              Text(
                produto.nomeProduto.isEmpty
                    ? 'Item sem nome'
                    : produto.nomeProduto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: _titleTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.qr_code_2_rounded,
                      label: codigo.isEmpty ? 'Sem código' : 'Código $codigo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.photo_library_outlined,
                    label: '$imagensCount foto${imagensCount == 1 ? '' : 's'}',
                  ),
                ],
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
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: ativo ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ativo ? Colors.white : const Color(0x99FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const <BoxShadow>[
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
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
        return const Center(
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
          duration: const Duration(milliseconds: 180),
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
            color: estaSelecionado ? const Color(0xFFEFF6FF) : _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: estaSelecionado ? _accentColor : const Color(0xFFE2E8F0),
              width: estaSelecionado ? 1.4 : 1,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A000000),
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
                  const SizedBox(width: 12),
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _titleTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                codigo.isEmpty ? 'Sem código' : codigo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _mutedTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatCurrency(produto.precoVenda),
                              style: const TextStyle(
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
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          estaSelecionado
                              ? _accentColor
                              : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      estaSelecionado ? Icons.check_rounded : Icons.add_rounded,
                      color: estaSelecionado ? Colors.white : _accentColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (_selecaoMultiplaAtiva && estaSelecionado) ...<Widget>[
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
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
                    const Spacer(),
                    _QuantidadeButton(
                      icon: Icons.remove_rounded,
                      onTap: () => _alterarQuantidadeSelecionada(produto, -1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantidade',
                        style: const TextStyle(
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
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(2),
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
                    ? const Color(0x292563EB)
                    : const Color(0x12000000),
            blurRadius: estaSelecionado ? 22 : 16,
            offset: const Offset(0, 8),
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
            duration: const Duration(milliseconds: 190),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: estaSelecionado ? const Color(0xFFF8FBFF) : _surfaceColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                        duration: const Duration(milliseconds: 180),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: estaSelecionado ? _accentColor : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                estaSelecionado
                                    ? _accentColor
                                    : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x24000000),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          estaSelecionado
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          color: estaSelecionado ? Colors.white : _accentColor,
                          size: 24,
                        ),
                      ),
                    ),
                    if (estaSelecionado)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x302563EB),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Selecionado',
                                style: TextStyle(
                                  color: Colors.white,
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
                const SizedBox(height: 14),
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
                            style: const TextStyle(
                              color: _titleTextColor,
                              fontSize: 17,
                              height: 1.16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.qr_code_2_rounded,
                                color: _mutedTextColor,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  codigo.isEmpty ? 'Sem código' : codigo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
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
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _formatCurrency(produto.precoVenda),
                        style: const TextStyle(
                          color: _titleTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (estaSelecionado) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$quantidade',
                            style: const TextStyle(
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
          return const Center(
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
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: content,
      ),
    );
  }

  Widget _buildHeroPlaceholder(bool isProduto) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDEBFF)),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x14000000),
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
                    style: const TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatCurrency(_totalSelecionado),
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: possuiSelecionados ? _confirmarSelecaoMultipla : null,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Adicionar selecionados'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
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
          return const Center(
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
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
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(size <= 44 ? 14 : 17),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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

  void _showSortOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Ordenar catálogo',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _SortOptionTile(
                  title: 'Nome',
                  selected: ordenacao == 'nome',
                  onTap: () => _changeSort('nome'),
                ),
                const SizedBox(height: 10),
                _SortOptionTile(
                  title: 'Menor preço',
                  selected: ordenacao == 'precoAsc',
                  onTap: () => _changeSort('precoAsc'),
                ),
                const SizedBox(height: 10),
                _SortOptionTile(
                  title: 'Maior preço',
                  selected: ordenacao == 'precoDesc',
                  onTap: () => _changeSort('precoDesc'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeSort(String value) {
    Navigator.pop(context);
    ordenacao = value;
    aplicarFiltroOrdenacao();
  }

  String _formatResumoValorVisivel(String value) {
    if (_exibirValores) return value;
    return '••••';
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
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

class _QuantidadeButton extends StatelessWidget {
  const _QuantidadeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
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

  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        color: selected ? _accentColor : Colors.transparent,
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
                  color: selected ? Colors.white : _mutedTextColor,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : _mutedTextColor,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = TextStyle(
      fontSize: compact ? 10.5 : 12,
      height: 1,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    );

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Color(0xFFD7E3F5),
            ),
          ),
          const SizedBox(height: 3),
          _ResumoAnimatedValue(value: value, style: valueStyle),
        ],
      ),
    );
  }
}

class _ResumoAnimatedValue extends StatelessWidget {
  const _ResumoAnimatedValue({required this.value, required this.style});

  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final _ResumoNumberValue? parsed = _ResumoNumberValue.tryParse(value);

    if (parsed == null) {
      return Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: parsed.number),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        return Text(
          parsed.format(animatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

class _ResumoNumberValue {
  const _ResumoNumberValue({
    required this.number,
    required this.isCurrency,
    required this.hasDecimal,
  });

  final double number;
  final bool isCurrency;
  final bool hasDecimal;

  static _ResumoNumberValue? tryParse(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty || trimmed.contains('•') || trimmed == '-') {
      return null;
    }

    final bool isCurrency = trimmed.startsWith('R\$');
    final bool hasDecimal = trimmed.contains(',');

    final String numericText =
        trimmed
            .replaceAll('R\$', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'[^0-9\.-]'), '')
            .trim();

    if (numericText.isEmpty) return null;

    final double? number = double.tryParse(numericText);
    if (number == null) return null;

    return _ResumoNumberValue(
      number: number,
      isCurrency: isCurrency,
      hasDecimal: hasDecimal,
    );
  }

  String format(double value) {
    if (isCurrency) {
      return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
    }

    if (hasDecimal) {
      return value.toStringAsFixed(1).replaceAll('.', ',');
    }

    return value.round().toString();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        ativo ? const Color(0xFFEAF8EE) : const Color(0xFFFEF2F2);
    final Color foregroundColor =
        ativo ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEFF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color:
                        selected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded, color: Color(0xFF2563EB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.wifi_off_outlined,
            color: Color(0xFFDC2626),
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            'Não foi possível carregar o catálogo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 34),
          SizedBox(height: 10),
          Text(
            'Nenhum item encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ajuste a busca ou atualize a listagem.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
