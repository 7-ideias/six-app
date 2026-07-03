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
  const ProdutolistMobileScreen({super.key, this.isSelecao = false});

  final bool isSelecao;

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
  final UsuarioProvider _usuarioProvider = UsuarioProvider();

  List<ProdutoModel> todosProdutos = <ProdutoModel>[];
  List<ProdutoModel> produtosFiltrados = <ProdutoModel>[];

  String termoBusca = '';
  String tipoSelecionado = 'PRODUTO';
  String ordenacao = 'nome';
  bool _salvandoPreferencia = false;

  bool get _isProdutoSelecionado => tipoSelecionado == 'PRODUTO';

  ModoDeExibicaoUsuario get _modoDeExibicaoProdutos => _usuarioProvider
          .usuario?.preferenciasIndividuaisDoUsuario.modoDeExibicaoProdutos ??
      ModoDeExibicaoUsuario.vertical;

  bool get _exibicaoHorizontal =>
      _modoDeExibicaoProdutos == ModoDeExibicaoUsuario.horizontal;

  @override
  void initState() {
    super.initState();
    Future.microtask(_carregarPreferenciasDoUsuario);
    Future.microtask(_recarregar);
  }

  @override
  void dispose() {
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
      produtosFiltrados = listaBase
          .where((ProdutoModel produto) =>
              _matchesTipoSelecionado(produto, tipoSelecionado))
          .toList();
    });
  }

  bool _matchesTipoSelecionado(ProdutoModel produto, String tipo) {
    final String valor = produto.tipoProduto.trim();
    if (valor.isEmpty) return tipo == 'PRODUTO';

    final String normalizado = valor.toUpperCase();
    return normalizado == tipo.toUpperCase() ||
        (tipo == 'SERVICO' && normalizado == 'SERVIÇO');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoModo == ModoDeExibicaoUsuario.horizontal
                ? 'Produtos agora em visualização horizontal.'
                : 'Produtos agora em visualização vertical.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a preferência de visualização.'),
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
        final List<ProdutoModel> itensDaLista = produtosFiltrados.isNotEmpty ||
                termoBusca.isNotEmpty ||
                todosProdutos.isNotEmpty
            ? produtosFiltrados
            : todosProdutos;
        final bool isSelecao = widget.isSelecao;

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            title: Text(
              isSelecao ? 'Selecionar item' : 'Produtos e serviços',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            actions: <Widget>[
              IconButton(
                tooltip: _exibicaoHorizontal
                    ? 'Usar visualização vertical'
                    : 'Usar visualização horizontal',
                icon: _salvandoPreferencia
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _exibicaoHorizontal
                            ? Icons.view_agenda_outlined
                            : Icons.view_carousel_outlined,
                      ),
                onPressed:
                    _salvandoPreferencia ? null : _alternarModoExibicaoProdutos,
              ),
              IconButton(
                tooltip: 'Ordenar',
                icon: const Icon(Icons.swap_vert_rounded),
                onPressed: _showSortOptions,
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, isSelecao ? 12 : 14, 16, 96),
                children: <Widget>[
                  if (!isSelecao) ...<Widget>[
                    SixStaggeredEntry(child: _buildHeaderCard()),
                    const SizedBox(height: 16),
                  ],
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 70),
                    child: _buildTabs(compact: isSelecao),
                  ),
                  const SizedBox(height: 12),
                  SixStaggeredEntry(
                    delay: const Duration(milliseconds: 120),
                    child: _buildSearchField(),
                  ),
                  if (!isSelecao) ...<Widget>[
                    const SizedBox(height: 14),
                    SixStaggeredEntry(
                      delay: const Duration(milliseconds: 155),
                      child: _buildSummarySection(),
                    ),
                  ],
                  SizedBox(height: isSelecao ? 14 : 18),
                  _buildListHeader(itensDaLista.length, provider.isLoading),
                  const SizedBox(height: 10),
                  ..._buildListContent(provider, itensDaLista, isSelecao),
                ],
              ),
            ),
          ),
          floatingActionButton: isSelecao
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  onPressed: _criarProduto,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(_isProdutoSelecionado ? 'Novo produto' : 'Novo serviço'),
                ),
        );
      },
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
          height: isSelecao ? 108 : 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 8),
            itemCount: itensDaLista.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final int itemDelay = 190 + ((index * 28).clamp(0, 180)).toInt();
              return SizedBox(
                width: isSelecao ? 292 : 336,
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

    return itensDaLista.asMap().entries.map((MapEntry<int, ProdutoModel> entry) {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Icon(
              _isProdutoSelecionado
                  ? Icons.inventory_2_outlined
                  : Icons.design_services_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _isProdutoSelecionado
                      ? 'Catálogo de produtos'
                      : 'Catálogo de serviços',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isProdutoSelecionado
                      ? 'Crie, edite e mantenha fotos, preços e estoque.'
                      : 'Crie e edite serviços com visual adequado ao mobile.',
                  style: const TextStyle(color: Color(0xFFD7E3F5), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
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
        onChanged: (String value) {
          termoBusca = value;
          aplicarFiltroOrdenacao();
        },
        decoration: InputDecoration(
          hintText: _isProdutoSelecionado ? 'Buscar produto ou código' : 'Buscar serviço',
          hintStyle: const TextStyle(color: _mutedTextColor),
          prefixIcon: const Icon(Icons.search_rounded, color: _accentColor),
          suffixIcon: _controllerBusca.text.isEmpty
              ? IconButton(
                  icon: const Icon(Icons.tune_rounded, color: _titleTextColor),
                  onPressed: _showSortOptions,
                )
              : IconButton(
                  onPressed: () {
                    _controllerBusca.clear();
                    termoBusca = '';
                    aplicarFiltroOrdenacao();
                  },
                  icon: const Icon(Icons.close_rounded, color: _mutedTextColor),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Consumer<ProdutosListProvider<ProdutoModel>>(
      builder: (BuildContext context, ProdutosListProvider<ProdutoModel> provider, _) {
        final Object? response = provider.fullResponse;
        if (response is! ProdutoResponseModel) return const SizedBox.shrink();

        return Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: 'Itens',
                value: response.skusTotaisNoEstoque.toString(),
                icon: Icons.widgets_outlined,
              ),
            ),
            if (_isProdutoSelecionado) ...<Widget>[
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'Sem estoque',
                  value: _formatNumber(response.qtSemEstoque),
                  icon: Icons.inventory_outlined,
                ),
              ),
            ],
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Valor',
                value: _formatCurrency(response.vlEstoqueEmGrana),
                icon: Icons.payments_outlined,
                compact: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListHeader(int count, bool isLoading) {
    final String titulo = widget.isSelecao
        ? (_isProdutoSelecionado ? 'Toque no produto para adicionar' : 'Toque no serviço para adicionar')
        : (_isProdutoSelecionado ? 'Produtos cadastrados' : 'Serviços cadastrados');

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
                          label: produto.codigoDeBarras.isEmpty
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
                          label: '$imagensCount foto${imagensCount == 1 ? '' : 's'}',
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

  Widget _buildProdutoSelectionCard(ProdutoModel produto) {
    final bool isProduto = _matchesTipoSelecionado(produto, 'PRODUTO');
    final String codigo = produto.codigoDeBarras.trim();

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pop(context, produto),
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              _buildThumbnail(produto, isProduto, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      produto.nomeProduto.isEmpty ? 'Item sem nome' : produto.nomeProduto,
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: _accentColor, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ProdutoModel produto, bool isProduto, {required double size}) {
    final dynamic imagem = produto.imagens?.isNotEmpty == true ? produto.imagens!.first : null;
    final Uint8List? bytes =
        _decodeBase64Image(imagem?.imagemBase64) ?? _decodeDataUrl(imagem?.url);

    Widget content;
    if (bytes != null) {
      content = Image.memory(bytes, fit: BoxFit.cover);
    } else if (imagem?.url != null && imagem!.url!.trim().isNotEmpty) {
      content = Image.network(
        imagem.url!,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
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
      final String payload = value.contains(',') ? value.split(',').last : value;
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
      tipoInicial: produto.tipoProduto.trim().isEmpty ? tipoSelecionado : produto.tipoProduto,
    );
  }

  Future<void> _abrirCadastro({
    ProdutoModel? produto,
    required String tipoInicial,
  }) async {
    final bool? atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CadastroProdutoMobileScreen(
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

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
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
            padding: EdgeInsets.symmetric(vertical: compact ? 9 : 11, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 18, color: selected ? Colors.white : _mutedTextColor),
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
    required this.icon,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final int? numericValue = int.tryParse(value);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accentColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _mutedTextColor,
            ),
          ),
          const SizedBox(height: 4),
          if (numericValue == null)
            Text(
              value,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w900,
                color: _titleTextColor,
              ),
            )
          else
            SixAnimatedNumberText(
              value: value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _titleTextColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = ativo ? const Color(0xFFEAF8EE) : const Color(0xFFFEF2F2);
    final Color foregroundColor = ativo ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(999)),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: foregroundColor),
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
              color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected) const Icon(Icons.check_rounded, color: Color(0xFF2563EB)),
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
          const Icon(Icons.wifi_off_outlined, color: Color(0xFFDC2626), size: 34),
          const SizedBox(height: 10),
          const Text(
            'Não foi possível carregar o catálogo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
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
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
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
