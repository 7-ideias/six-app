import 'dart:convert';

import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/produto_helper.dart';
import 'package:sixpos/design_system/components/web/sub_painel_web_general.dart';
import 'package:sixpos/sub_painel_cadastro_produto.dart';
import 'package:flutter/foundation.dart';

import 'package:sixpos/core/utils/pdf_download.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class SubPainelWebProdutoLista extends SubPainelWebGeneral {
  SubPainelWebProdutoLista({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
  }) : super(
          body: ProdutoListaBody(
            isSelecao: isSelecao,
            modoEdicao: modoEdicao,
          ),
          textoDaAppBar: 'Lista de Produtos',
        );

  final bool isSelecao;
  final bool modoEdicao;
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
  final ScrollController _listaProdutosScrollController = ScrollController();
  final ProdutoService _produtoService = ProdutoService();

  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];

  String termoBusca = '';
  String tipoSelecionado = 'PRODUTO';
  String ordenacao = 'nome';
  bool _isGerandoRelatorio = false;

  void _logInfo(String message) {
    debugPrint('[SubPainelWebProdutoLista][INFO] $message');
  }

  void _logError(
    String errorContext,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[SubPainelWebProdutoLista][ERROR] $errorContext');
    debugPrint('[SubPainelWebProdutoLista][ERROR] $error');
    debugPrint('[SubPainelWebProdutoLista][STACK] $stackTrace');

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'produto_lista_sub_painel_web',
        context: ErrorDescription(errorContext),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _logInfo('Widget iniciado. isSelecao=${widget.isSelecao}');
    Future.microtask(_recarregar);
  }

  @override
  void dispose() {
    _controllerBusca.dispose();
    _listaProdutosScrollController.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    try {
      _logInfo(
        'Recarregando produtos. tipoSelecionado=$tipoSelecionado ordenacao=$ordenacao termoBusca="$termoBusca"',
      );

      await ProdutoHelper.retornarProdutosList(
        context,
        tipo: tipoSelecionado,
        onSucesso: atualizarListaComProvider,
      );
    } catch (error, stackTrace) {
      _logError('Erro ao recarregar produtos', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao recarregar produtos. Veja os logs.'),
          ),
        );
      }
    }
  }

  void atualizarListaComProvider(List<ProdutoModel> items) {
    try {
      _logInfo('Produtos recebidos do helper/provider: ${items.length}');
      if (items.isNotEmpty) {
        final primeiro = items.first;
        _logInfo(
          'Primeiro produto: nome=${primeiro.nomeProduto}, codigo=${primeiro.codigoDeBarras}, preco=${primeiro.precoVenda}',
        );
      }

      if (!mounted) return;

      setState(() {
        todosProdutos = items;
        _aplicarFiltroOrdenacaoSemSetState();
      });

      _logInfo(
        'Após atualizarListaComProvider: todosProdutos=${todosProdutos.length}, produtosFiltrados=${produtosFiltrados.length}',
      );
    } catch (error, stackTrace) {
      _logError('Erro em atualizarListaComProvider', error, stackTrace);
    }
  }

  void aplicarFiltroOrdenacao() {
    try {
      setState(_aplicarFiltroOrdenacaoSemSetState);
      _logInfo(
        'Filtro aplicado: termo="$termoBusca", ordenacao=$ordenacao, tipo=$tipoSelecionado, resultado=${produtosFiltrados.length}',
      );
    } catch (error, stackTrace) {
      _logError('Erro ao aplicar filtro e ordenação', error, stackTrace);
    }
  }

  void _aplicarFiltroOrdenacaoSemSetState() {
    final listaBase = ProdutoHelper.filtrarEOrdenarProdutos(
      produtos: todosProdutos,
      termoBusca: termoBusca,
      ordenacao: ordenacao,
    );

    produtosFiltrados = listaBase
        .where((produto) => _matchesTipoSelecionado(produto, tipoSelecionado))
        .toList();
  }

  bool _matchesTipoSelecionado(ProdutoModel produto, String tipo) {
    try {
      final dynamic p = produto;

      final dynamic valor = p.tipoProduto ??
          p.tipoPoduto ??
          p.tipoCadastro ??
          p.tipo ??
          p.categoria;

      if (valor == null) {
        return tipo == 'PRODUTO';
      }

      return valor.toString().toUpperCase() == tipo.toUpperCase();
    } catch (error, stackTrace) {
      _logError('Erro ao validar tipo selecionado', error, stackTrace);
      return tipo == 'PRODUTO';
    }
  }

  void _selecionarProduto(ProdutoModel produto) {
    try {
      _logInfo(
        'Produto clicado. isSelecao=${widget.isSelecao} nome=${produto.nomeProduto} codigo=${produto.codigoDeBarras} preco=${produto.precoVenda}',
      );

      if (widget.isSelecao) {
        _logInfo('Fechando subpainel e retornando produto via Navigator.pop');
        Navigator.pop(context, produto);
      } else {
        if (widget.modoEdicao) {
          _abrirCadastroParaEdicao(produto);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clicou em ${produto.nomeProduto}')),
        );
      }
    } catch (error, stackTrace) {
      _logError('Erro ao selecionar produto', error, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar produto. Veja os logs.'),
        ),
      );
    }
  }

  void _abrirCadastroParaEdicao(ProdutoModel produto) {
    showSubPainelCadastroProduto(
      context,
      'Editar Produto',
      produtoParaEdicao: produto,
      modoEdicao: true,
    );
  }

  Future<void> _imprimirRelatorioProdutos() async {
    if (_isGerandoRelatorio) {
      return;
    }

    setState(() {
      _isGerandoRelatorio = true;
    });

    try {
      final RelatorioProdutoPdfResponse response =
          await _produtoService.gerarRelatorioListagemPdf();

      if (response.arquivoBase64.trim().isEmpty) {
        throw Exception('O backend retornou o PDF vazio.');
      }

      final Uint8List bytes = base64Decode(response.arquivoBase64);
      final bool downloadIniciado = iniciarDownloadPdf(
        bytes: bytes,
        nomeArquivo: response.nomeArquivo,
        mimeType: response.mimeType,
      );

      if (!mounted) {
        return;
      }

      if (!downloadIniciado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Download de PDF disponível apenas na versão web.',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Relatório salvo: ${response.nomeArquivo}')),
      );
    } catch (error, stackTrace) {
      _logError('Erro ao imprimir relatório de produtos', error, stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível gerar o PDF: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGerandoRelatorio = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      final provider = context.watch<ProdutosListProvider<ProdutoModel>>();

      final itensDaLista = produtosFiltrados.isNotEmpty ||
              termoBusca.isNotEmpty ||
              todosProdutos.isNotEmpty
          ? produtosFiltrados
          : provider.listaDeProdutos;

      _logInfo(
        'Build: provider.isLoading=${provider.isLoading}, provider.listaDeProdutos=${provider.listaDeProdutos.length}, todosProdutos=${todosProdutos.length}, produtosFiltrados=${produtosFiltrados.length}, itensDaLista=${itensDaLista.length}',
      );

      return Container(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompact = constraints.maxWidth < 840;
            final EdgeInsets pagePadding = isCompact
                ? const EdgeInsets.fromLTRB(16, 16, 16, 12)
                : const EdgeInsets.fromLTRB(28, 22, 28, 16);

            return Column(
              children: [
                Padding(
                  padding: pagePadding.copyWith(bottom: 0),
                  child: _buildTopSection(
                    context: context,
                    totalItens: itensDaLista.length,
                    isCompact: isCompact,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      pagePadding.left,
                      18,
                      pagePadding.right,
                      0,
                    ),
                    child: _buildListaArea(
                      context: context,
                      provider: provider,
                      itensDaLista: itensDaLista,
                    ),
                  ),
                ),
                Padding(
                  padding: pagePadding.copyWith(top: 14),
                  child: _buildBottomBar(context, itensDaLista.length, isCompact),
                ),
              ],
            );
          },
        ),
      );
    } catch (error, stackTrace) {
      _logError('Erro geral no build do subpainel', error, stackTrace);
      return const Center(
        child: Text('Erro ao montar a lista de produtos. Veja os logs.'),
      );
    }
  }

  Widget _buildTopSection({
    required BuildContext context,
    required int totalItens,
    required bool isCompact,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.72),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.modoEdicao ? 'Editar produtos' : 'Produtos',
                        style: TextStyle(
                          fontSize: isCompact ? 22 : 26,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.modoEdicao
                            ? 'Clique em um item para revisar dados, preço, estoque e imagens.'
                            : 'Catálogo organizado para consulta rápida e operação de balcão.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.62),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildResumoChip(
                context,
                icon: Icons.format_list_bulleted_rounded,
                label: '$totalItens itens',
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (widget.modoEdicao && !widget.isSelecao) ...[
            _buildInfoBanner(context),
            const SizedBox(height: 16),
          ],
          _buildSearchAndOrderBar(context, isCompact),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modo edição ativo: os produtos abrem direto no cadastro para alteração.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withOpacity(0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndOrderBar(BuildContext context, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;

    final searchField = TextField(
      controller: _controllerBusca,
      decoration: InputDecoration(
        hintText: 'Buscar por nome, código ou grupo...',
        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
        suffixIcon: termoBusca.isNotEmpty
            ? IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  try {
                    _controllerBusca.clear();
                    termoBusca = '';
                    aplicarFiltroOrdenacao();
                  } catch (error, stackTrace) {
                    _logError('Erro ao limpar busca', error, stackTrace);
                  }
                },
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.35),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      onChanged: (value) {
        try {
          termoBusca = value;
          aplicarFiltroOrdenacao();
        } catch (error, stackTrace) {
          _logError('Erro no onChanged da busca', error, stackTrace);
        }
      },
    );

    final orderField = Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ordenacao,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: const [
            DropdownMenuItem(
              value: 'nome',
              child: Text('Ordenar por nome'),
            ),
            DropdownMenuItem(
              value: 'preco',
              child: Text('Ordenar por preço'),
            ),
          ],
          onChanged: (value) {
            try {
              if (value != null) {
                ordenacao = value;
                aplicarFiltroOrdenacao();
              }
            } catch (error, stackTrace) {
              _logError('Erro ao trocar ordenação', error, stackTrace);
            }
          },
        ),
      ),
    );

    if (isCompact) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 12),
          orderField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 14),
        SizedBox(width: 240, child: orderField),
      ],
    );
  }

  Widget _buildListaArea({
    required BuildContext context,
    required ProdutosListProvider<ProdutoModel> provider,
    required List<ProdutoModel> itensDaLista,
  }) {
    if (provider.isLoading) {
      return _buildLoadingList(context);
    }

    if (itensDaLista.isEmpty) {
      return _buildEmptyState(context);
    }

    return Scrollbar(
      controller: _listaProdutosScrollController,
      thumbVisibility: true,
      thickness: 7,
      radius: const Radius.circular(999),
      scrollbarOrientation: ScrollbarOrientation.right,
      child: ListView.separated(
        controller: _listaProdutosScrollController,
        primary: false,
        padding: const EdgeInsets.fromLTRB(0, 0, 12, 8),
        itemCount: itensDaLista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          try {
            final produto = itensDaLista[index];
            return _buildProdutoCard(produto, index);
          } catch (error, stackTrace) {
            _logError(
              'Erro ao renderizar item da lista no subpainel',
              error,
              stackTrace,
            );
            return const Card(
              child: ListTile(
                title: Text('Erro ao renderizar produto'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 8),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 96,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajuste a busca ou atualize a listagem para consultar novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int totalItens, bool isCompact) {
    final colorScheme = Theme.of(context).colorScheme;

    final countChip = _buildResumoChip(
      context,
      icon: Icons.inventory_2_outlined,
      label: '$totalItens itens encontrados',
    );

    final actionButtons = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _recarregar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        FilledButton.icon(
          onPressed: _isGerandoRelatorio ? null : _imprimirRelatorioProdutos,
          icon: _isGerandoRelatorio
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: Text(_isGerandoRelatorio ? 'Gerando PDF...' : 'Imprimir PDF'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                countChip,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: actionButtons),
              ],
            )
          : Row(
              children: [
                countChip,
                const Spacer(),
                actionButtons,
              ],
            ),
    );
  }

  Widget _buildResumoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.surfaceVariant.withOpacity(0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight
              ? colorScheme.primary.withOpacity(0.18)
              : colorScheme.outline.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: highlight ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutoCard(ProdutoModel produto, int index) {
    try {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final Duration duration = Duration(milliseconds: 220 + (index % 8) * 32);

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _selecionarProduto(produto),
            child: Ink(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.045),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isCompact = constraints.maxWidth < 680;
                    final content = _buildProdutoCardContent(
                      context,
                      produto,
                      isCompact,
                    );

                    if (isCompact) {
                      return content;
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 104),
                      child: content,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logError('Erro ao montar card de produto', error, stackTrace);
      return const Card(
        child: ListTile(
          title: Text('Erro ao montar card do produto'),
        ),
      );
    }
  }

  Widget _buildProdutoCardContent(
    BuildContext context,
    ProdutoModel produto,
    bool isCompact,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final thumbnail = _buildProdutoThumbnail(context, produto);
    final details = _buildProdutoDetails(context, produto);
    final action = _buildProdutoAction(context, produto);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumbnail,
              const SizedBox(width: 14),
              Expanded(child: details),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colorScheme.outline.withOpacity(0.10)),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      );
    }

    return Row(
      children: [
        thumbnail,
        const SizedBox(width: 16),
        Expanded(child: details),
        const SizedBox(width: 16),
        action,
      ],
    );
  }

  Widget _buildProdutoThumbnail(BuildContext context, ProdutoModel produto) {
    final colorScheme = Theme.of(context).colorScheme;
    final String? imageUrl = _primeiraImagemUrl(produto);

    Widget content;
    if (imageUrl != null) {
      content = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Icon(
          Icons.inventory_2_outlined,
          color: colorScheme.primary,
        ),
      );
    } else {
      content = Icon(
        _iconePorTipo(produto),
        color: colorScheme.primary,
        size: 28,
      );
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: imageUrl == null
            ? LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.12),
                  colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: imageUrl == null ? null : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: content),
    );
  }

  Widget _buildProdutoDetails(BuildContext context, ProdutoModel produto) {
    final colorScheme = Theme.of(context).colorScheme;
    final String codigo = _codigoLabel(produto);
    final String grupo = _grupoLabel(produto);
    final String tipo = _tipoLabel(produto);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                produto.nomeProduto.isEmpty ? 'Produto sem nome' : produto.nomeProduto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildStatusPill(context, produto.ativo ? 'Ativo' : 'Inativo', produto.ativo),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMetaPill(context, Icons.qr_code_2_rounded, codigo),
            _buildMetaPill(context, Icons.category_outlined, tipo),
            if (grupo.isNotEmpty) _buildMetaPill(context, Icons.folder_outlined, grupo),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildValorPill(
              context,
              label: 'Venda',
              value: _precoFormatado(produto.precoVenda),
              icon: Icons.sell_outlined,
            ),
            _buildValorPill(
              context,
              label: 'Mín.',
              value: produto.estoqueMinimo.toString(),
              icon: Icons.low_priority_rounded,
            ),
            _buildValorPill(
              context,
              label: 'Máx.',
              value: produto.estoqueMaximo.toString(),
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProdutoAction(BuildContext context, ProdutoModel produto) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isSelecao) {
      return FilledButton.icon(
        onPressed: () => _selecionarProduto(produto),
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
        label: const Text('Adicionar'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }

    if (widget.modoEdicao) {
      return FilledButton.icon(
        onPressed: () => _abrirCadastroParaEdicao(produto),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text('Editar'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.16)),
      ),
      child: Text(
        _precoFormatado(produto.precoVenda),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMetaPill(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValorPill(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.58),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, String label, bool active) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color color = active ? Colors.green.shade700 : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  String? _primeiraImagemUrl(ProdutoModel produto) {
    final imagens = produto.imagens;
    if (imagens == null || imagens.isEmpty) {
      return null;
    }

    for (final imagem in imagens) {
      final String? url = imagem.url?.trim();
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    return null;
  }

  IconData _iconePorTipo(ProdutoModel produto) {
    return produto.tipoProduto.toUpperCase() == 'SERVICO'
        ? Icons.handyman_outlined
        : Icons.shopping_bag_outlined;
  }

  String _tipoLabel(ProdutoModel produto) {
    final tipo = produto.tipoProduto.trim().toUpperCase();
    if (tipo == 'SERVICO') {
      return 'Serviço';
    }
    return 'Produto';
  }

  String _grupoLabel(ProdutoModel produto) {
    final grupo = produto.objAgrupamento?.grupoDoProduto.trim() ?? '';
    if (grupo.isEmpty || grupo.toLowerCase() == 'sem grupo') {
      return '';
    }
    return grupo;
  }

  String _codigoLabel(ProdutoModel produto) {
    final codigo = produto.codigoDeBarras.trim();
    if (codigo.isEmpty) {
      return 'Sem código';
    }
    return codigo;
  }

  String _precoFormatado(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}
