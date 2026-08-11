import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/pdf_download.dart';
import 'package:sixpos/core/utils/produto_helper.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
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
    this.tipoInicial = 'PRODUTO',
  });

  final bool isSelecao;
  final bool modoEdicao;
  final bool permitirSelecaoMultipla;
  final String tipoInicial;

  @override
  Widget build(BuildContext context) {
    return ProdutoListaBody(
      isSelecao: isSelecao,
      modoEdicao: modoEdicao,
      permitirSelecaoMultipla: permitirSelecaoMultipla,
      tipoInicial: tipoInicial,
    );
  }
}

class ProdutoListaBody extends StatefulWidget {
  const ProdutoListaBody({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
    this.permitirSelecaoMultipla = false,
    this.tipoInicial = 'PRODUTO',
  });

  final bool isSelecao;
  final bool modoEdicao;
  final bool permitirSelecaoMultipla;
  final String tipoInicial;

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
  final Map<String, _ProdutoSelecionadoWeb> _produtosSelecionados =
      <String, _ProdutoSelecionadoWeb>{};

  String termoBusca = '';
  String ordenacao = 'nome';
  String tipoSelecionado = 'PRODUTO';
  bool _isGerandoRelatorio = false;
  bool _salvandoPreferencia = false;

  ModoDeExibicaoUsuario get _modoDeExibicaoProdutos =>
      _usuarioProvider
          .usuario
          ?.preferenciasIndividuaisDoUsuario
          .modoDeExibicaoProdutos ??
      ModoDeExibicaoUsuario.vertical;

  bool get _exibicaoHorizontal =>
      _modoDeExibicaoProdutos == ModoDeExibicaoUsuario.horizontal;

  bool get _isProdutoSelecionado => tipoSelecionado == 'PRODUTO';

  bool get _usarTokensSelecaoWeb => widget.isSelecao;

  int get _quantidadeSelecionadaTotal => _produtosSelecionados.values.fold<int>(
    0,
    (int total, _ProdutoSelecionadoWeb item) => total + item.quantidade,
  );

  double get _totalSelecionado => _produtosSelecionados.values.fold<double>(
    0,
    (double total, _ProdutoSelecionadoWeb item) => total + item.total,
  );

  @override
  void initState() {
    super.initState();
    tipoSelecionado = _normalizarTipoProduto(widget.tipoInicial);
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
        tipo: tipoSelecionado,
        onSucesso: atualizarListaComProvider,
      );
    } catch (error, stackTrace) {
      _logError('Erro ao recarregar produtos', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao recarregar itens. Veja os logs.'),
        ),
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
    final List<ProdutoModel> listaFiltrada =
        ProdutoHelper.filtrarEOrdenarProdutos(
          produtos: todosProdutos,
          termoBusca: termoBusca,
          ordenacao: ordenacao,
        );

    produtosFiltrados =
        listaFiltrada
            .where(
              (ProdutoModel produto) =>
                  _matchesTipoSelecionado(produto, tipoSelecionado),
            )
            .toList();
  }

  void _selectTipo(String tipo) {
    final String normalizado = _normalizarTipoProduto(tipo);
    if (tipoSelecionado == normalizado) return;

    setState(() {
      tipoSelecionado = normalizado;
      termoBusca = '';
      _controllerBusca.clear();
      produtosFiltrados = <ProdutoModel>[];
      todosProdutos = <ProdutoModel>[];
    });

    _recarregar();
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
      _logError(
        'Erro ao salvar preferencia de exibicao de produtos',
        error,
        stackTrace,
      );
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Clicou em ${produto.nomeProduto}')));
  }

  void _alternarSelecaoProduto(ProdutoModel produto) {
    final String chave = _chaveProduto(produto);
    setState(() {
      if (_produtosSelecionados.containsKey(chave)) {
        _produtosSelecionados.remove(chave);
      } else {
        _produtosSelecionados[chave] = _ProdutoSelecionadoWeb(
          produto: produto,
          quantidade: 1,
        );
      }
    });
  }

  void _alterarQuantidadeSelecionada(ProdutoModel produto, int delta) {
    final String chave = _chaveProduto(produto);
    final _ProdutoSelecionadoWeb? selecionado = _produtosSelecionados[chave];
    if (selecionado == null) return;

    setState(() {
      final int novaQuantidade = selecionado.quantidade + delta;
      if (novaQuantidade <= 0) {
        _produtosSelecionados.remove(chave);
        return;
      }

      _produtosSelecionados[chave] = selecionado.copyWith(
        quantidade: novaQuantidade,
      );
    });
  }

  void _confirmarSelecaoMultipla() {
    if (_produtosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um item.')),
      );
      return;
    }

    final List<ProdutoModel> produtosSelecionados = <ProdutoModel>[];
    for (final _ProdutoSelecionadoWeb item in _produtosSelecionados.values) {
      produtosSelecionados.addAll(
        List<ProdutoModel>.filled(item.quantidade, item.produto),
      );
    }

    Navigator.of(context).pop(produtosSelecionados);
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
        final baseProdutos =
            todosProdutos.isNotEmpty ? todosProdutos : provider.listaDeProdutos;
        final itensDaLista =
            baseProdutos.isEmpty && termoBusca.isEmpty
                ? provider.listaDeProdutos
                : produtosFiltrados;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 920;
            final horizontalPadding = isCompact ? 16.0 : 28.0;
            final tokens = WebThemeTokens.of(context);

            return AnimatedContainer(
              duration: WebThemeTokens.transitionDuration,
              curve: WebThemeTokens.transitionCurve,
              color:
                  widget.isSelecao
                      ? tokens.surfaceElevated
                      : tokens.workspaceBackground,
              child: Column(
                children: <Widget>[
                  _buildHeader(context, itensDaLista.length, isCompact),
                  if (widget.isSelecao)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        0,
                      ),
                      child: _buildTipoSelector(context, isCompact),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      widget.isSelecao ? 10 : 14,
                      horizontalPadding,
                      10,
                    ),
                    child: _buildSearchOrderAndPreference(context, isCompact),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        14,
                      ),
                      child: _buildList(context, provider, itensDaLista),
                    ),
                  ),
                  if (widget.isSelecao && widget.permitirSelecaoMultipla)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        18,
                      ),
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
    final tokens = WebThemeTokens.of(context);
    final bool selectionMode = _usarTokensSelecaoWeb;
    final Color accent = tokens.info;
    final Color titleColor = tokens.primaryText;
    final Color subtitleColor = tokens.secondaryText;
    final title =
        widget.isSelecao
            ? widget.permitirSelecaoMultipla
                ? 'Selecionar itens'
                : 'Selecionar item'
            : widget.modoEdicao
            ? 'Editar produtos'
            : 'Produtos';
    final subtitle =
        widget.isSelecao
            ? widget.permitirSelecaoMultipla
                ? 'Marque produtos e serviços e adicione tudo na venda de uma vez.'
                : 'Busca rápida para incluir produto ou serviço na venda.'
            : widget.modoEdicao
            ? 'Lista compacta para revisar cadastro, estoque, preço e imagens.'
            : 'Consulta rápida do catálogo com ações de balcão.';

    final titleBlock = Row(
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: selectionMode ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            widget.isSelecao
                ? Icons.add_shopping_cart_rounded
                : Icons.inventory_2_outlined,
            color: accent,
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
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subtitleColor),
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
        if (widget.isSelecao &&
            widget.permitirSelecaoMultipla &&
            _produtosSelecionados.isNotEmpty)
          _headerButton(
            context,
            Icons.cleaning_services_outlined,
            'Limpar seleção',
            _limparSelecaoMultipla,
          ),
        if (!widget.isSelecao) ...<Widget>[
          _headerButton(
            context,
            Icons.add_rounded,
            'Novo item',
            _abrirNovoProduto,
            filled: true,
          ),
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
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 28,
        isCompact ? 16 : 22,
        isCompact ? 16 : 28,
        isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border(bottom: BorderSide(color: tokens.cardBorder)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
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

  Widget _headerButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onPressed, {
    bool filled = false,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
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
    final tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.danger.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.close_rounded, color: tokens.danger, size: 26),
        ),
      ),
    );
  }

  Widget _editBanner(BuildContext context, int totalItens) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.info.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.edit_note_rounded, color: tokens.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo edição ativo - $totalItens itens encontrados - clique em um produto para alterar.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: tokens.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoSelector(BuildContext context, bool isCompact) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return Container(
      width: isCompact ? double.infinity : 420,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _tipoButton(
              context,
              label: 'Produtos',
              icon: Icons.inventory_2_outlined,
              selected: _isProdutoSelecionado,
              onTap: () => _selectTipo('PRODUTO'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tipoButton(
              context,
              label: 'Serviços',
              icon: Icons.design_services_outlined,
              selected: tipoSelecionado == 'SERVICO',
              onTap: () => _selectTipo('SERVICO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipoButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;

    return Material(
      color: selected ? tokens.selectedBackground : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 17, color: selected ? accent : accent),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected ? tokens.primaryText : tokens.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOrderAndPreference(BuildContext context, bool isCompact) {
    final tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    final Color inputBackground = tokens.inputBackground;
    final Color inputBorder = tokens.cardBorder;

    final search = TextField(
      controller: _controllerBusca,
      style: TextStyle(color: tokens.primaryText),
      decoration: InputDecoration(
        hintText: 'Buscar por nome ou código...',
        hintStyle: TextStyle(color: tokens.mutedText),
        prefixIcon: Icon(Icons.search_rounded, color: accent),
        suffixIcon:
            termoBusca.isEmpty
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
        fillColor: inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.4),
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
        color: inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ordenacao,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: tokens.menuBackground,
          style: TextStyle(
            color: tokens.primaryText,
            fontWeight: FontWeight.w700,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: tokens.secondaryText,
          ),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'nome',
              child: Text('Ordenar por nome'),
            ),
            DropdownMenuItem<String>(
              value: 'preco',
              child: Text('Ordenar por preço'),
            ),
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
        SizedBox(
          width: 268,
          child: _buildModoExibicaoSelector(context, expand: false),
        ),
      ],
    );
  }

  Widget _buildModoExibicaoSelector(
    BuildContext context, {
    required bool expand,
  }) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _modoButton(
              context,
              label: 'Vertical',
              icon: Icons.view_agenda_outlined,
              selected: !_exibicaoHorizontal,
              onTap:
                  () => _alterarModoExibicaoProdutos(
                    ModoDeExibicaoUsuario.vertical,
                  ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _modoButton(
              context,
              label: 'Horizontal',
              icon: Icons.view_carousel_outlined,
              selected: _exibicaoHorizontal,
              onTap:
                  () => _alterarModoExibicaoProdutos(
                    ModoDeExibicaoUsuario.horizontal,
                  ),
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
    final tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    return Material(
      color: selected ? tokens.selectedBackground : Colors.transparent,
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              else
                Icon(icon, size: 17, color: selected ? accent : accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: selected ? tokens.primaryText : accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ProdutosListProvider<ProdutoModel> provider,
    List<ProdutoModel> itens,
  ) {
    if (provider.isLoading && itens.isEmpty) return _loadingList(context);
    if (itens.isEmpty) return _emptyState(context);

    if (_exibicaoHorizontal) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = _horizontalItemWidth(
            constraints.maxWidth,
            itens.length,
          );

          return Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            thickness: 7,
            radius: const Radius.circular(999),
            child: ListView.separated(
              controller: _horizontalScrollController,
              primary: false,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: itens.length,
              separatorBuilder:
                  (_, __) => const SizedBox(width: _horizontalItemSpacing),
              itemBuilder:
                  (context, index) => SizedBox(
                    width: itemWidth,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _productCard(context, itens[index], index),
                    ),
                  ),
            ),
          );
        },
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
        itemBuilder:
            (context, index) => _productCard(context, itens[index], index),
      ),
    );
  }

  static const double _horizontalItemSpacing = 12;

  double _horizontalItemWidth(double availableWidth, int itemCount) {
    if (itemCount <= 0 || !availableWidth.isFinite || availableWidth <= 0) {
      return widget.isSelecao ? 340 : 430;
    }

    final double minWidth = widget.isSelecao ? 340 : 430;
    final int maxVisibleItems = ((availableWidth + _horizontalItemSpacing) /
            (minWidth + _horizontalItemSpacing))
        .floor()
        .clamp(1, itemCount);
    final double totalSpacing = _horizontalItemSpacing * (maxVisibleItems - 1);
    final double itemWidth = (availableWidth - totalSpacing) / maxVisibleItems;

    return itemWidth < minWidth ? minWidth : itemWidth;
  }

  Widget _buildSelectionFooter(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final int totalSelecionados = _quantidadeSelecionadaTotal;
    final bool possuiSelecionados = totalSelecionados > 0;

    return AnimatedContainer(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: possuiSelecionados ? tokens.selectedBorder : tokens.cardBorder,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.playlist_add_check_rounded, color: tokens.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              !possuiSelecionados
                  ? 'Nenhum item selecionado ainda.'
                  : totalSelecionados == 1
                  ? '1 item selecionado • ${_precoFormatado(_totalSelecionado)}'
                  : '$totalSelecionados itens selecionados • ${_precoFormatado(_totalSelecionado)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    possuiSelecionados
                        ? tokens.primaryText
                        : tokens.secondaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: possuiSelecionados ? _confirmarSelecaoMultipla : null,
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: Text(
              possuiSelecionados
                  ? 'Adicionar $totalSelecionados'
                  : 'Adicionar selecionados',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingList(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 2),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder:
          (_, __) => Container(
            height: widget.isSelecao ? 58 : 74,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.cardBorder),
            ),
          ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.only(top: 36),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              _isProdutoSelecionado
                  ? Icons.inventory_2_outlined
                  : Icons.design_services_outlined,
              color: tokens.info,
              size: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _isProdutoSelecionado
                        ? 'Nenhum produto encontrado'
                        : 'Nenhum serviço encontrado',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: tokens.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ajuste a busca ou atualize a listagem.',
                    style: TextStyle(color: tokens.secondaryText),
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
    final tokens = WebThemeTokens.of(context);
    final duration = Duration(milliseconds: 120 + (index % 8) * 18);
    final bool selecionado =
        widget.isSelecao &&
        widget.permitirSelecaoMultipla &&
        _produtosSelecionados.containsKey(_chaveProduto(produto));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(
                _exibicaoHorizontal ? 10 * (1 - value) : 0,
                8 * (1 - value),
              ),
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
              color:
                  selecionado
                      ? tokens.selectedBackground
                      : tokens.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selecionado ? tokens.selectedBorder : tokens.cardBorder,
                width: selecionado ? 1.4 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha:
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.12
                            : 0.035,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: widget.isSelecao ? 8 : 10,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (widget.isSelecao) {
                    return _productSelection(context, produto, selecionado);
                  }
                  final compact = constraints.maxWidth < 760;
                  return compact
                      ? _productCompact(context, produto)
                      : _productWide(context, produto);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _productSelection(
    BuildContext context,
    ProdutoModel produto,
    bool selecionado,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    final _ProdutoSelecionadoWeb? itemSelecionado =
        _produtosSelecionados[_chaveProduto(produto)];
    final int quantidade = itemSelecionado?.quantidade ?? 0;

    Widget quantidadeButton({
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Material(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 18, color: accent),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            _thumbnail(context, produto, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                      color: tokens.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      Text(
                        _codigoLabel(produto),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.secondaryText,
                        ),
                      ),
                      Text(
                        _precoFormatado(produto.precoVenda),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: tokens.primaryText,
                        ),
                      ),
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
                color:
                    selecionado
                        ? tokens.info.withValues(alpha: 0.18)
                        : accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.24)),
              ),
              child: Icon(
                selecionado ? Icons.check_rounded : Icons.add_rounded,
                color: selecionado ? accent : accent,
              ),
            ),
          ],
        ),
        if (selecionado) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.selectedBorder),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Selecionado',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                quantidadeButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _alterarQuantidadeSelecionada(produto, -1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Text(
                    '$quantidade',
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                quantidadeButton(
                  icon: Icons.add_rounded,
                  onTap: () => _alterarQuantidadeSelecionada(produto, 1),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _productWide(BuildContext context, ProdutoModel produto) {
    final tokens = WebThemeTokens.of(context);
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
                produto.nomeProduto.isEmpty
                    ? 'Item sem nome'
                    : produto.nomeProduto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tokens.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  _pill(
                    context,
                    Icons.qr_code_2_rounded,
                    _codigoLabel(produto),
                  ),
                  _pill(context, Icons.category_outlined, _tipoLabel(produto)),
                  if (_grupoLabel(produto).isNotEmpty)
                    _pill(context, Icons.folder_outlined, _grupoLabel(produto)),
                  _pill(
                    context,
                    Icons.sell_outlined,
                    _precoFormatado(produto.precoVenda),
                    strong: true,
                  ),
                  _pill(
                    context,
                    Icons.low_priority_rounded,
                    'Mín.: ${produto.estoqueMinimo}',
                  ),
                  _pill(
                    context,
                    Icons.trending_up_rounded,
                    'Máx.: ${produto.estoqueMaximo}',
                  ),
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
    final tokens = WebThemeTokens.of(context);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            _thumbnail(context, produto),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                produto.nomeProduto.isEmpty
                    ? 'Item sem nome'
                    : produto.nomeProduto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tokens.primaryText,
                ),
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
                  _pill(
                    context,
                    Icons.qr_code_2_rounded,
                    _codigoLabel(produto),
                  ),
                  _pill(
                    context,
                    Icons.sell_outlined,
                    _precoFormatado(produto.precoVenda),
                    strong: true,
                  ),
                ],
              ),
            ),
            _actionButton(context, produto),
          ],
        ),
      ],
    );
  }

  Widget _thumbnail(
    BuildContext context,
    ProdutoModel produto, {
    double size = 52,
  }) {
    final tokens = WebThemeTokens.of(context);
    final Color accent = tokens.info;
    final imageUrl = _primeiraImagemUrl(produto);
    final child =
        imageUrl == null
            ? Icon(
              _iconePorTipo(produto),
              color: accent,
              size: size <= 46 ? 21 : 24,
            )
            : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
                      Icon(_iconePorTipo(produto), color: accent, size: 24),
            );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(size <= 46 ? 14 : 16),
        border: Border.all(color: tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }

  Widget _actionButton(BuildContext context, ProdutoModel produto) {
    return FilledButton.icon(
      onPressed:
          () =>
              widget.modoEdicao
                  ? _abrirCadastroParaEdicao(produto)
                  : _selecionarProduto(produto),
      icon: Icon(
        widget.modoEdicao ? Icons.edit_rounded : Icons.visibility_outlined,
        size: 17,
      ),
      label: Text(widget.modoEdicao ? 'Editar' : 'Ver'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    IconData icon,
    String label, {
    bool strong = false,
  }) {
    final tokens = WebThemeTokens.of(context);
    final Color accent = strong ? tokens.info : tokens.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color:
            strong ? tokens.info.withValues(alpha: 0.10) : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              color: strong ? tokens.primaryText : tokens.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context, bool active) {
    final tokens = WebThemeTokens.of(context);
    final color = active ? tokens.success : tokens.statusNeutral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
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
    if (imagens == null || imagens.isEmpty) return null;
    for (final imagem in imagens) {
      final url = imagem.url?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  String _normalizarTipoProduto(String tipo) {
    final String normalizado = tipo.trim().toUpperCase();
    if (normalizado == 'SERVICO' || normalizado == 'SERVIÇO') {
      return 'SERVICO';
    }
    return 'PRODUTO';
  }

  bool _isServico(ProdutoModel produto) {
    return _normalizarTipoProduto(produto.tipoProduto) == 'SERVICO';
  }

  bool _matchesTipoSelecionado(ProdutoModel produto, String tipo) {
    return _normalizarTipoProduto(produto.tipoProduto) ==
        _normalizarTipoProduto(tipo);
  }

  IconData _iconePorTipo(ProdutoModel produto) {
    return _isServico(produto)
        ? Icons.design_services_outlined
        : Icons.shopping_bag_outlined;
  }

  String _tipoLabel(ProdutoModel produto) {
    return _isServico(produto) ? 'Serviço' : 'Produto';
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
    final String tipo = _normalizarTipoProduto(produto.tipoProduto);
    final String? id = produto.id;
    if (id != null && id.trim().isNotEmpty) return '$tipo:id:${id.trim()}';

    final String codigo = produto.codigoDeBarras.trim();
    if (codigo.isNotEmpty) return '$tipo:codigo:$codigo';

    final String nome = produto.nomeProduto.trim().toLowerCase();
    return '$tipo:nome:$nome|preco:${produto.precoVenda.toStringAsFixed(4)}';
  }

  String _precoFormatado(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}

class _ProdutoSelecionadoWeb {
  const _ProdutoSelecionadoWeb({
    required this.produto,
    required this.quantidade,
  });

  final ProdutoModel produto;
  final int quantidade;

  double get total => produto.precoVenda * quantidade;

  _ProdutoSelecionadoWeb copyWith({int? quantidade}) {
    return _ProdutoSelecionadoWeb(
      produto: produto,
      quantidade: quantidade ?? this.quantidade,
    );
  }
}
