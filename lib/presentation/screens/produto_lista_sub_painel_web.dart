import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/pdf_download.dart';
import 'package:sixpos/core/utils/produto_helper.dart';
import 'package:sixpos/sub_painel_cadastro_produto.dart';

import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class SubPainelWebProdutoLista extends StatelessWidget {
  const SubPainelWebProdutoLista({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
  });

  final bool isSelecao;
  final bool modoEdicao;

  @override
  Widget build(BuildContext context) {
    return ProdutoListaBody(
      isSelecao: isSelecao,
      modoEdicao: modoEdicao,
    );
  }
}

class ProdutoListaBody extends StatefulWidget {
  const ProdutoListaBody({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
  });

  final bool isSelecao;
  final bool modoEdicao;

  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {
  final TextEditingController _controllerBusca = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ProdutoService _produtoService = ProdutoService();

  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];

  String termoBusca = '';
  String ordenacao = 'nome';
  bool _isGerandoRelatorio = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_recarregar);
  }

  @override
  void dispose() {
    _controllerBusca.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _selecionarProduto(ProdutoModel produto) {
    if (widget.isSelecao) {
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
    debugPrint('[SubPainelWebProdutoLista][STACK] $stackTrace');
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
            children: [
              _buildHeader(context, itensDaLista.length, isCompact),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 10),
                child: _buildSearchAndOrder(context, isCompact),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 14),
                  child: _buildList(context, provider, itensDaLista),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int totalItens, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.modoEdicao ? 'Editar produtos' : 'Produtos';
    final subtitle = widget.modoEdicao
        ? 'Lista compacta para revisar cadastro, estoque, preço e imagens.'
        : 'Consulta rápida do catálogo com ações de balcão.';

    final titleBlock = Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.inventory_2_outlined, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
      children: [
        _headerButton(context, Icons.refresh_rounded, 'Atualizar', _recarregar),
        _headerButton(context, Icons.add_rounded, 'Novo produto', _abrirNovoProduto, filled: true),
        _headerButton(
          context,
          Icons.picture_as_pdf_outlined,
          _isGerandoRelatorio ? 'Gerando...' : 'Imprimir PDF',
          _isGerandoRelatorio ? null : _imprimirRelatorioProdutos,
        ),
        _closeButton(context),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 28,
        isCompact ? 16 : 22,
        isCompact ? 16 : 28,
        isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.14))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          isCompact
              ? Column(
                  children: [
                    titleBlock,
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 16),
                    actions,
                  ],
                ),
          if (widget.modoEdicao && !widget.isSelecao) ...[
            const SizedBox(height: 12),
            _editBanner(context, totalItens),
          ],
        ],
      ),
    );
  }

  Widget _headerButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onPressed, {
    bool filled = false,
  }) {
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
        children: [
          Icon(Icons.edit_note_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo edição ativo - $totalItens itens encontrados - clique em um produto para alterar.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withOpacity(0.74),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndOrder(BuildContext context, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;

    final search = TextField(
      controller: _controllerBusca,
      decoration: InputDecoration(
        hintText: 'Buscar por nome, código ou grupo...',
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
          items: const [
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
      return Column(children: [search, const SizedBox(height: 10), order]);
    }

    return Row(children: [Expanded(child: search), const SizedBox(width: 12), SizedBox(width: 240, child: order)]);
  }

  Widget _buildList(
    BuildContext context,
    ProdutosListProvider<ProdutoModel> provider,
    List<ProdutoModel> itens,
  ) {
    if (provider.isLoading && itens.isEmpty) return _loadingList(context);
    if (itens.isEmpty) return _emptyState(context);

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 7,
      radius: const Radius.circular(999),
      child: ListView.separated(
        controller: _scrollController,
        primary: false,
        padding: const EdgeInsets.fromLTRB(0, 0, 12, 2),
        itemCount: itens.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _productCard(context, itens[index], index),
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
        height: 74,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.55),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 360,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.40),
                      borderRadius: BorderRadius.circular(999),
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
          children: [
            Icon(Icons.inventory_2_outlined, color: colorScheme.primary, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nenhum produto encontrado',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text('Ajuste a busca ou atualize a listagem.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.62))),
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
    final duration = Duration(milliseconds: 140 + (index % 8) * 20);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 8 * (1 - value)), child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _selecionarProduto(produto),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 5)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
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

  Widget _productWide(BuildContext context, ProdutoModel produto) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _thumbnail(context, produto),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                children: [
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
      children: [
        Row(
          children: [
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
          children: [
            Expanded(
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
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

  Widget _thumbnail(BuildContext context, ProdutoModel produto) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = _primeiraImagemUrl(produto);
    final child = imageUrl == null
        ? Icon(_iconePorTipo(produto), color: colorScheme.primary, size: 24)
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(_iconePorTipo(produto), color: colorScheme.primary, size: 24),
          );

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }

  Widget _actionButton(BuildContext context, ProdutoModel produto) {
    if (widget.isSelecao) {
      return FilledButton.icon(
        onPressed: () => _selecionarProduto(produto),
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
        label: const Text('Adicionar'),
      );
    }

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
        children: [
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
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
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
    return produto.tipoProduto.toUpperCase() == 'SERVICO'
        ? Icons.handyman_outlined
        : Icons.shopping_bag_outlined;
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

  String _precoFormatado(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}
