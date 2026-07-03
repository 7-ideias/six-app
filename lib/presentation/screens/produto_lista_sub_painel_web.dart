import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/pdf_download.dart';
import 'package:sixpos/core/utils/produto_helper.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/providers/usuario_provider.dart';
import 'package:sixpos/sub_painel_cadastro_produto.dart';

import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class SubPainelWebProdutoLista extends StatelessWidget {
  const SubPainelWebProdutoLista({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
    this.permitirSelecaoMultipla = false,
  });

  final bool isSelecao;
  final bool modoEdicao;
  final bool permitirSelecaoMultipla;

  @override
  Widget build(BuildContext context) {
    return ProdutoListaBody(
      isSelecao: isSelecao,
      modoEdicao: modoEdicao,
      permitirSelecaoMultipla: permitirSelecaoMultipla,
    );
  }
}

class ProdutoListaBody extends StatefulWidget {
  const ProdutoListaBody({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
    this.permitirSelecaoMultipla = false,
  });

  final bool isSelecao;
  final bool modoEdicao;
  final bool permitirSelecaoMultipla;

  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {
  final TextEditingController _controllerBusca = TextEditingController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ProdutoService _produtoService = ProdutoService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();

  List<ProdutoModel> todosProdutos = <ProdutoModel>[];
  List<ProdutoModel> produtosFiltrados = <ProdutoModel>[];
  final Map<String, ProdutoModel> _produtosSelecionados = <String, ProdutoModel>{};

  String termoBusca = '';
  String ordenacao = 'nome';
  bool _isGerandoRelatorio = false;
  bool _salvandoPreferencia = false;

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
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarPreferenciasDoUsuario() async {
    if (_usuarioProvider.usuario != null) return;
    try {
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
      if (mounted) setState(() {});
    } catch (error, stackTrace) {
      _logError('Erro ao carregar preferencias do usuario', error, stackTrace);
    }
  }

  Future<void> _recarregar() async {
    try {
      await ProdutoHelper.retornarProdutosList(
        context,
        tipo: 'PRODUTO',
        onSucesso: atualizarListaComProvider,
      );
    } catch (error, stackTrace) {
      _logError('Erro ao recarregar produtos', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao recarregar produtos. Veja os logs.')),
      );
    }
  }

  void atualizarListaComProvider(List<ProdutoModel> items) {
    if (!mounted) return;
    setState(() {
      todosProdutos = items;
      _aplicarFiltroOrdenacaoSemSetState();
    });
  }

  void aplicarFiltroOrdenacao() {
    setState(_aplicarFiltroOrdenacaoSemSetState);
  }

  void _aplicarFiltroOrdenacaoSemSetState() {
    produtosFiltrados = ProdutoHelper.filtrarEOrdenarProdutos(
      produtos: todosProdutos,
      termoBusca: termoBusca,
      ordenacao: ordenacao,
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
        const SnackBar(content: Text('Não foi possível carregar suas preferências.')),
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
    } catch (error, stackTrace) {
      _logError('Erro ao salvar preferencia de exibicao de produtos', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a preferência de visualização.')),
      );
    } finally {
      if (mounted) setState(() => _salvandoPreferencia = false);
    }
  }

  void _selecionarProduto(ProdutoModel produto) {
    if (widget.isSelecao) {
      if (widget.permitirSelecaoMultipla) {
        _alternarSelecaoProduto(produto);
        return;
      }
      Navigator.pop(context, produto);
      return;
    }

    if (widget.modoEdicao) {
      _abrirCadastroParaEdicao(produto);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Clicou em ${produto.nomeProduto}')),
    );
  }

  void _alternarSelecaoProduto(ProdutoModel produto) {
    final String chave = _chaveProduto(produto);
    setState(() {
      if (_produtosSelecionados.containsKey(chave)) {
        _produtosSelecionados.remove(chave);
      } else {
        _produtosSelecionados[chave] = produto;
      }
    });
  }

  void _confirmarSelecaoMultipla() {
    if (_produtosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um produto.')),
      );
      return;
    }
    Navigator.of(context).pop(_produtosSelecionados.values.toList(growable: false));
  }

  void _limparSelecaoMultipla() {
    if (_produtosSelecionados.isEmpty) return;
    setState(_produtosSelecionados.clear);
  }

  void _abrirCadastroParaEdicao(ProdutoModel produto) {
    showSubPainelCadastroProduto(
      context,
      'Editar Produto',
      produtoParaEdicao: produto,
      modoEdicao: true,
    );
  }

  void _abrirNovoProduto() {
    showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
  }

  Future<void> _imprimirRelatorioProdutos() async {
    if (_isGerandoRelatorio) return;
    setState(() => _isGerandoRelatorio = true);

    try {
      final response = await _produtoService.gerarRelatorioListagemPdf();
      if (response.arquivoBase64.trim().isEmpty) {
        throw Exception('O backend retornou o PDF vazio.');
      }

      final bytes = base64Decode(response.arquivoBase64);
      final downloadIniciado = iniciarDownloadPdf(
        bytes: bytes,
        nomeArquivo: response.nomeArquivo,
        mimeType: response.mimeType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            downloadIniciado
                ? 'Relatório salvo: ${response.nomeArquivo}'
                : 'Download de PDF disponível apenas na versão web.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logError('Erro ao imprimir relatório de produtos', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $error')),
      );
    } finally {
      if (mounted) setState(() => _isGerandoRelatorio = false);
    }
  }

  void _logError(String context, Object error, StackTrace stackTrace) {
    debugPrint('[SubPainelWebProdutoLista][ERROR] $context');
    debugPrint('[SubPainelWebProdutoLista][ERROR] $error');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'produto_lista_sub_painel_web',
        context: ErrorDescription(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _usuarioProvider,
      builder: (BuildContext context, _) {
        final provider = context.watch<ProdutosListProvider<ProdutoModel>>();
        final baseProdutos = todosProdutos.isNotEmpty ? todosProdutos : provider.listaDeProdutos;
        final itensDaLista = baseProdutos.isEmpty && termoBusca.isEmpty
            ? provider.listaDeProdutos
            : produtosFiltrados;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 920;
            final horizontalPadding = isCompact ? 16.0 : 28.0;

            return Container(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.16),
              child: Column(
                children: <Widget>[
                  _buildHeader(context, itensDaLista.length, isCompact),
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 10),
                    child: _buildSearchOrderAndPreference(context, isCompact),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 14),
                      child: _buildList(context, provider, itensDaLista),
                    ),
                  ),
                  if (widget.isSelecao && widget.permitirSelecaoMultipla)
                    Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 18),
                      child: _buildSelectionFooter(context),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int totalItens, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.isSelecao
        ? widget.permitirSelecaoMultipla
            ? 'Selecionar produtos'
            : 'Selecionar produto'
        : widget.modoEdicao
            ? 'Editar produtos'
            : 'Produtos';
    final subtitle = widget.isSelecao
        ? widget.permitirSelecaoMultipla
            ? 'Marque um ou mais itens e adicione tudo na venda de uma vez.'
            : 'Busca rápida para incluir item na venda.'
        : widget.modoEdicao
            ? 'Lista compacta para revisar cadastro, estoque, preço e imagens.'
            : 'Consulta rápida do catálogo com ações de balcão.';

    final titleBlock = Row(
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            widget.isSelecao ? Icons.add_shopping_cart_rounded : Icons.inventory_2_outlined,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 21 : 24,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.66)),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: <Widget>[
        _headerButton(context, Icons.refresh_rounded, 'Atualizar', _recarregar),
        if (widget.isSelecao && widget.permitirSelecaoMultipla && _produtosSelecionados.isNotEmpty)
          _headerButton(context, Icons.cleaning_services_outlined, 'Limpar seleção', _limparSelecaoMultipla),
        if (!widget.isSelecao) ...<Widget>[
          _headerButton(context, Icons.add_rounded, 'Novo produto', _abrirNovoProduto, filled: true),
          _headerButton(
            context,
            Icons.picture_as_pdf_outlined,
            _isGerandoRelatorio ? 'Gerando...' : 'Imprimir PDF',
            _isGerandoRelatorio ? null : _imprimirRelatorioProdutos,
          ),
        ],
        _closeButton(context),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isCompact ? 16 : 28, isCompact ? 16 : 22, isCompact ? 16 : 28, isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.14))),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: <Widget>[
          isCompact
              ? Column(
                  children: <Widget>[
                    titleBlock,
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(child: titleBlock),
                    const SizedBox(width: 16),
                    actions,
                  ],
                ),
          if (widget.modoEdicao && !widget.isSelecao) ...<Widget>[
            const SizedBox(height: 12),
            _editBanner(context, totalItens),
          ],
        ],
      ),
    );
  }

  Widget _headerButton(BuildContext context, IconData icon, String label, VoidCallback? onPressed, {bool filled = false}) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 15);

    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(padding: padding, shape: shape),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(padding: padding, shape: shape),
    );
  }

  Widget _closeButton(BuildContext context) {
    return Material(
      color: const Color(0xFFE53935),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => Navigator.of(context).pop(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _editBanner(BuildContext context, int totalItens) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.edit_note_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo edição ativo - $totalItens itens encontrados - clique em um produto para alterar.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface.withOpacity(0.74)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOrderAndPreference(BuildContext context, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;

    final search = TextField(
      controller: _controllerBusca,
      decoration: InputDecoration(
        hintText: 'Buscar por nome ou código...',
        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
        suffixIcon: termoBusca.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _controllerBusca.clear();
                  termoBusca = '';
                  aplicarFiltroOrdenacao();
                },
              ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      onChanged: (value) {
        termoBusca = value;
        aplicarFiltroOrdenacao();
      },
    );

    final order = Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ordenacao,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: 'nome', child: Text('Ordenar por nome')),
            DropdownMenuItem(value: 'preco', child: Text('Ordenar por preço')),
          ],
          onChanged: (value) {
            if (value == null) return;
            ordenacao = value;
            aplicarFiltroOrdenacao();
          },
        ),
      ),
    );

    if (isCompact) {
      return Column(
        children: <Widget>[
          search,
          const SizedBox(height: 10),
          order,
          const SizedBox(height: 10),
          _buildModoExibicaoSelector(context, expand: true),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(child: search),
        const SizedBox(width: 12),
        SizedBox(width: 240, child: order),
        const SizedBox(width: 12),
        SizedBox(width: 268, child: _buildModoExibicaoSelector(context, expand: false)),
      ],
    );
  }

  Widget _buildModoExibicaoSelector(BuildContext context, {required bool expand}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _modoButton(
              context,
              label: 'Vertical',
              icon: Icons.view_agenda_outlined,
              selected: !_exibicaoHorizontal,
              onTap: () => _alterarModoExibicaoProdutos(ModoDeExibicaoUsuario.vertical),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _modoButton(
              context,
              label: 'Horizontal',
              icon: Icons.view_carousel_outlined,
              selected: _exibicaoHorizontal,
              onTap: () => _alterarModoExibicaoProdutos(ModoDeExibicaoUsuario.horizontal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modoButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _salvandoPreferencia ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_salvandoPreferencia && selected)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                )
              else
                Icon(icon, size: 17, color: selected ? colorScheme.onPrimary : colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: selected ? colorScheme.onPrimary : colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ProdutosListProvider<ProdutoModel> provider, List<ProdutoModel> itens) {
    if (provider.isLoading && itens.isEmpty) return _loadingList(context);
    if (itens.isEmpty) return _emptyState(context);

    if (_exibicaoHorizontal) {
      return Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        thickness: 7,
        radius: const Radius.circular(999),
        child: ListView.separated(
          controller: _horizontalScrollController,
          primary: false,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(0, 0, 4, 12),
          itemCount: itens.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: widget.isSelecao ? 340 : 430,
            child: Align(
              alignment: Alignment.topCenter,
              child: _productCard(context, itens[index], index),
            ),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      thickness: 7,
      radius: const Radius.circular(999),
      child: ListView.separated(
        controller: _verticalScrollController,
        primary: false,
        padding: const EdgeInsets.fromLTRB(0, 0, 12, 2),
        itemCount: itens.length,
        separatorBuilder: (_, __) => SizedBox(height: widget.isSelecao ? 7 : 8),
        itemBuilder: (context, index) => _productCard(context, itens[index], index),
      ),
    );
  }

  Widget _buildSelectionFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int totalSelecionados = _produtosSelecionados.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: totalSelecionados > 0 ? colorScheme.primary.withOpacity(0.22) : colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.playlist_add_check_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              totalSelecionados == 0
                  ? 'Nenhum produto selecionado ainda.'
                  : totalSelecionados == 1
                      ? '1 produto selecionado para a venda.'
                      : '$totalSelecionados produtos selecionados para a venda.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: totalSelecionados == 0 ? null : _confirmarSelecaoMultipla,
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: Text(totalSelecionados == 0 ? 'Adicionar selecionados' : 'Adicionar $totalSelecionados'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 2),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: widget.isSelecao ? 58 : 74,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.only(top: 36),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.inventory_2_outlined, color: colorScheme.primary, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Nenhum produto encontrado',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ajuste a busca ou atualize a listagem.',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.62)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(BuildContext context, ProdutoModel produto, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = Duration(milliseconds: 120 + (index % 8) * 18);
    final bool selecionado = widget.isSelecao &&
        widget.permitirSelecaoMultipla &&
        _produtosSelecionados.containsKey(_chaveProduto(produto));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(_exibicaoHorizontal ? 10 * (1 - value) : 0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _selecionarProduto(produto),
          child: Ink(
            decoration: BoxDecoration(
              color: selecionado ? colorScheme.primary.withOpacity(0.06) : colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selecionado ? colorScheme.primary.withOpacity(0.36) : colorScheme.outline.withOpacity(0.10),
                width: selecionado ? 1.4 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 5)),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: widget.isSelecao ? 8 : 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (widget.isSelecao) {
                    return _productSelection(context, produto, selecionado);
                  }
                  final compact = constraints.maxWidth < 760;
                  return compact ? _productCompact(context, produto) : _productWide(context, produto);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _productSelection(BuildContext context, ProdutoModel produto, bool selecionado) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        _thumbnail(context, produto, size: 44),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                produto.nomeProduto.isEmpty ? 'Produto sem nome' : produto.nomeProduto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  Text(_codigoLabel(produto), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant)),
                  Text(_precoFormatado(produto.precoVenda), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selecionado ? colorScheme.primary : colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.16)),
          ),
          child: Icon(
            selecionado ? Icons.check_rounded : Icons.add_rounded,
            color: selecionado ? colorScheme.onPrimary : colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _productWide(BuildContext context, ProdutoModel produto) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        _thumbnail(context, produto),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                produto.nomeProduto.isEmpty ? 'Produto sem nome' : produto.nomeProduto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  _pill(context, Icons.qr_code_2_rounded, _codigoLabel(produto)),
                  _pill(context, Icons.category_outlined, _tipoLabel(produto)),
                  if (_grupoLabel(produto).isNotEmpty) _pill(context, Icons.folder_outlined, _grupoLabel(produto)),
                  _pill(context, Icons.sell_outlined, _precoFormatado(produto.precoVenda), strong: true),
                  _pill(context, Icons.low_priority_rounded, 'Mín.: ${produto.estoqueMinimo}'),
                  _pill(context, Icons.trending_up_rounded, 'Máx.: ${produto.estoqueMaximo}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _statusPill(context, produto.ativo),
        const SizedBox(width: 12),
        _actionButton(context, produto),
      ],
    );
  }

  Widget _productCompact(BuildContext context, ProdutoModel produto) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            _thumbnail(context, produto),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                produto.nomeProduto.isEmpty ? 'Produto sem nome' : produto.nomeProduto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
              ),
            ),
            _statusPill(context, produto.ativo),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  _pill(context, Icons.qr_code_2_rounded, _codigoLabel(produto)),
                  _pill(context, Icons.sell_outlined, _precoFormatado(produto.precoVenda), strong: true),
                ],
              ),
            ),
            _actionButton(context, produto),
          ],
        ),
      ],
    );
  }

  Widget _thumbnail(BuildContext context, ProdutoModel produto, {double size = 52}) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = _primeiraImagemUrl(produto);
    final child = imageUrl == null
        ? Icon(_iconePorTipo(produto), color: colorScheme.primary, size: size <= 46 ? 21 : 24)
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(_iconePorTipo(produto), color: colorScheme.primary, size: 24),
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(size <= 46 ? 14 : 16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }

  Widget _actionButton(BuildContext context, ProdutoModel produto) {
    return FilledButton.icon(
      onPressed: () => widget.modoEdicao ? _abrirCadastroParaEdicao(produto) : _selecionarProduto(produto),
      icon: Icon(widget.modoEdicao ? Icons.edit_rounded : Icons.visibility_outlined, size: 17),
      label: Text(widget.modoEdicao ? 'Editar' : 'Ver'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label, {bool strong = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: strong ? colorScheme.primary.withOpacity(0.07) : colorScheme.surfaceVariant.withOpacity(0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: strong ? colorScheme.primary : colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(strong ? 0.88 : 0.68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context, bool active) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active ? Colors.green.shade700 : colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(active ? 'Ativo' : 'Inativo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }

  String? _primeiraImagemUrl(ProdutoModel produto) {
    final imagens = produto.imagens;
    if (imagens == null || imagens.isEmpty) return null;
    for (final imagem in imagens) {
      final url = imagem.url?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  IconData _iconePorTipo(ProdutoModel produto) {
    return produto.tipoProduto.toUpperCase() == 'SERVICO' ? Icons.handyman_outlined : Icons.shopping_bag_outlined;
  }

  String _tipoLabel(ProdutoModel produto) {
    return produto.tipoProduto.toUpperCase() == 'SERVICO' ? 'Serviço' : 'Produto';
  }

  String _grupoLabel(ProdutoModel produto) {
    final grupo = produto.objAgrupamento?.grupoDoProduto.trim() ?? '';
    if (grupo.isEmpty || grupo.toLowerCase() == 'sem grupo') return '';
    return grupo;
  }

  String _codigoLabel(ProdutoModel produto) {
    final codigo = produto.codigoDeBarras.trim();
    return codigo.isEmpty ? 'Sem código' : codigo;
  }

  String _chaveProduto(ProdutoModel produto) {
    final codigo = produto.codigoDeBarras.trim();
    if (codigo.isNotEmpty) return 'codigo:$codigo';
    final nome = produto.nomeProduto.trim().toLowerCase();
    return 'nome:$nome|preco:${produto.precoVenda.toStringAsFixed(4)}';
  }

  String _precoFormatado(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}
