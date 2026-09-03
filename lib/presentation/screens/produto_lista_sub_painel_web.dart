import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/pdf_download.dart';
import 'package:sixpos/core/utils/produto_helper.dart';
import 'package:sixpos/data/models/produto_imagem_model.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/presentation/components/produto_web_image.dart';
import 'package:sixpos/presentation/components/web/six_web_animated_dialog.dart';
import 'package:sixpos/presentation/components/web/six_web_pdv_quantity_dialog.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/usuario_provider.dart';
import 'package:sixpos/sub_painel_cadastro_produto.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

enum _ProdutoResumoRapidoFiltro {
  todos,
  produtos,
  servicos,
  comImagem,
  estoqueBaixo,
}

enum _ProdutoStatusFiltro { todos, ativos, inativos }

enum _ProdutoEstoqueFiltro {
  todos,
  emEstoque,
  estoqueBaixo,
  semEstoque,
  estoqueNegativo,
}

enum _ProdutoMarcacaoFiltro { todos, favoritos, catalogo, favoritosECatalogo }

enum _ProdutoSituacaoEstoque {
  naoAplicavel,
  emEstoque,
  estoqueBaixo,
  semEstoque,
  estoqueNegativo,
}

class _ProdutoCatalogoEdicaoSnapshot {
  const _ProdutoCatalogoEdicaoSnapshot({
    required this.baseItens,
    required this.itensFiltrados,
    required this.itensPaginados,
    required this.contagensResumo,
    required this.paginaAtual,
    required this.totalPaginas,
    required this.indiceInicial,
    required this.indiceFinal,
  });

  final List<ProdutoModel> baseItens;
  final List<ProdutoModel> itensFiltrados;
  final List<ProdutoModel> itensPaginados;
  final Map<_ProdutoResumoRapidoFiltro, int> contagensResumo;
  final int paginaAtual;
  final int totalPaginas;
  final int indiceInicial;
  final int indiceFinal;
}

class _CategoriaFiltro {
  const _CategoriaFiltro({required this.id, required this.nome});

  final String id;
  final String nome;
}

class _ProdutoFiltroMenuOpcao<T> {
  const _ProdutoFiltroMenuOpcao({required this.value, required this.label});

  final T value;
  final String label;
}

Future<T?> showProdutoListaSelecaoWebDialog<T>({
  required BuildContext context,
  bool permitirSelecaoMultipla = false,
  String tipoInicial = 'PRODUTO',
  bool apenasAtivosNoBackend = false,
  double widthFactor = 0.88,
  double heightFactor = 0.86,
  double? maxWidth,
  double? maxHeight,
  EdgeInsets padding = const EdgeInsets.all(24),
}) {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  return showSixWebAnimatedDialog<T>(
    context: context,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    overlayColor: const Color(0x8A0B1324),
    overlayBlurSigma: 12,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 320),
    padding: padding,
    builder: (BuildContext dialogContext) {
      final ThemeData themedDialog = WebThemeTokens.applyTo(
        Theme.of(dialogContext),
      );
      final WebThemeTokens tokens = WebThemeTokens.of(dialogContext);
      final Size size = MediaQuery.sizeOf(dialogContext);
      double dialogWidth = size.width * widthFactor;
      double dialogHeight = size.height * heightFactor;

      if (maxWidth != null) {
        dialogWidth = math.min(dialogWidth, maxWidth);
      }
      if (maxHeight != null) {
        dialogHeight = math.min(dialogHeight, maxHeight);
      }

      return Theme(
        data: themedDialog,
        child: Dialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: tokens.cardBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF020617).withValues(alpha: 0.18),
                  blurRadius: 42,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: SubPainelWebProdutoLista(
                isSelecao: true,
                permitirSelecaoMultipla: permitirSelecaoMultipla,
                tipoInicial: tipoInicial,
                apenasAtivosNoBackend: apenasAtivosNoBackend,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class SubPainelWebProdutoLista extends StatelessWidget {
  const SubPainelWebProdutoLista({
    super.key,
    this.isSelecao = false,
    this.modoEdicao = false,
    this.permitirSelecaoMultipla = false,
    this.tipoInicial = 'PRODUTO',
    this.apenasAtivosNoBackend = false,
    this.exibirInformacoesEstoque = false,
  });

  final bool isSelecao;
  final bool modoEdicao;
  final bool permitirSelecaoMultipla;
  final String tipoInicial;
  final bool apenasAtivosNoBackend;
  final bool exibirInformacoesEstoque;

  @override
  Widget build(BuildContext context) {
    return ProdutoListaBody(
      isSelecao: isSelecao,
      modoEdicao: modoEdicao,
      permitirSelecaoMultipla: permitirSelecaoMultipla,
      tipoInicial: tipoInicial,
      apenasAtivosNoBackend: apenasAtivosNoBackend,
      exibirInformacoesEstoque: exibirInformacoesEstoque,
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
    this.apenasAtivosNoBackend = false,
    this.exibirInformacoesEstoque = false,
  });

  final bool isSelecao;
  final bool modoEdicao;
  final bool permitirSelecaoMultipla;
  final String tipoInicial;
  final bool apenasAtivosNoBackend;
  final bool exibirInformacoesEstoque;

  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {
  static const List<int> _opcoesItensPorPagina = <int>[12, 24, 48];

  final TextEditingController _controllerBusca = TextEditingController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ProdutoService _produtoService = ProdutoService();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final UsuarioService _usuarioService = UsuarioService();

  List<ProdutoModel> todosProdutos = <ProdutoModel>[];
  List<ProdutoModel> produtosFiltrados = <ProdutoModel>[];
  final Map<String, _ProdutoSelecionadoWeb> _produtosSelecionados =
      <String, _ProdutoSelecionadoWeb>{};

  String termoBusca = '';
  String ordenacao = 'nomeAsc';
  String tipoSelecionado = 'PRODUTO';
  bool _isGerandoRelatorio = false;
  bool _carregandoCatalogoEdicao = false;
  bool _salvandoPreferencia = false;
  bool _aplicandoPreferenciasEstoque = false;
  bool _usuarioAlterouFiltrosEstoque = false;
  bool _salvandoFiltrosEstoque = false;
  bool _salvamentoFiltrosEstoquePendente = false;
  Timer? _debouncePreferenciasEstoque;
  String? _ultimaAssinaturaPreferenciasEstoque;
  String? _erroCatalogoEdicao;
  String? _categoriaSelecionadaId;
  _ProdutoResumoRapidoFiltro _resumoRapidoSelecionado =
      _ProdutoResumoRapidoFiltro.produtos;
  _ProdutoStatusFiltro _statusFiltro = _ProdutoStatusFiltro.todos;
  _ProdutoEstoqueFiltro _estoqueFiltro = _ProdutoEstoqueFiltro.todos;
  _ProdutoMarcacaoFiltro _marcacaoFiltro = _ProdutoMarcacaoFiltro.todos;
  int _paginaAtual = 0;
  int _itensPorPagina = _opcoesItensPorPagina.first;

  ModoDeExibicaoUsuario get _modoDeExibicaoProdutosPersistido =>
      _usuarioProvider
          .usuario
          ?.preferenciasIndividuaisDoUsuario
          .modoDeExibicaoProdutos ??
      ModoDeExibicaoUsuario.vertical;

  ModoDeExibicaoUsuario get _modoDeExibicaoProdutosWeb {
    switch (_modoDeExibicaoProdutosPersistido) {
      case ModoDeExibicaoUsuario.horizontal:
      case ModoDeExibicaoUsuario.grade:
        return ModoDeExibicaoUsuario.grade;
      case ModoDeExibicaoUsuario.vertical:
      case ModoDeExibicaoUsuario.lista:
        return ModoDeExibicaoUsuario.lista;
    }
  }

  bool get _usarGrade =>
      _modoDeExibicaoProdutosWeb == ModoDeExibicaoUsuario.grade;

  bool get _isProdutoSelecionado => tipoSelecionado == 'PRODUTO';

  bool get _usarTokensSelecaoWeb => widget.isSelecao;

  bool get _exibirInformacoesEstoque =>
      widget.exibirInformacoesEstoque || widget.isSelecao;

  bool get _usarPreferenciasEstoqueWeb =>
      widget.exibirInformacoesEstoque && !widget.isSelecao;

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
    _resumoRapidoSelecionado =
        tipoSelecionado == 'SERVICO'
            ? _ProdutoResumoRapidoFiltro.servicos
            : _ProdutoResumoRapidoFiltro.produtos;
    Future.microtask(_inicializarTela);
  }

  @override
  void dispose() {
    final bool temSalvamentoPendente =
        _debouncePreferenciasEstoque?.isActive ?? false;
    _debouncePreferenciasEstoque?.cancel();
    if (temSalvamentoPendente) {
      unawaited(_salvarPreferenciasEstoqueWeb());
    }
    _controllerBusca.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _inicializarTela() async {
    if (_usarPreferenciasEstoqueWeb) {
      await _restaurarPreferenciasEstoqueWebDoCache();
    }
    if (!mounted) return;

    await _recarregar();
    if (!mounted) return;

    if (_usarPreferenciasEstoqueWeb) {
      unawaited(_restaurarPreferenciasEstoqueWebDoBackend());
    } else {
      unawaited(_carregarPreferenciasDoUsuario());
    }
  }

  Future<void> _restaurarPreferenciasEstoqueWebDoCache() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (!mounted || preferencias == null || _usuarioAlterouFiltrosEstoque) {
      return;
    }
    _aplicarPreferenciasEstoqueWeb(preferencias.estoqueFiltrosWeb);
  }

  Future<void> _restaurarPreferenciasEstoqueWebDoBackend() async {
    try {
      if (_usuarioProvider.usuario == null) {
        await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      }
      final PreferenciasIndividuaisDoUsuarioModel? preferencias =
          _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
      if (!mounted || preferencias == null || _usuarioAlterouFiltrosEstoque) {
        return;
      }
      _aplicarPreferenciasEstoqueWeb(preferencias.estoqueFiltrosWeb);
    } catch (error, stackTrace) {
      _logError(
        'Erro ao restaurar preferencias web do estoque',
        error,
        stackTrace,
      );
    }
  }

  void _aplicarPreferenciasEstoqueWeb(EstoqueFiltrosPreferencia filtros) {
    String? categoriaId = filtros.categoriaId;
    if (categoriaId != null &&
        todosProdutos.isNotEmpty &&
        !todosProdutos.any(
          (ProdutoModel produto) =>
              produto.objCategoria?.idCategoria == categoriaId,
        )) {
      categoriaId = null;
    }

    _aplicandoPreferenciasEstoque = true;
    setState(() {
      termoBusca = filtros.busca;
      _controllerBusca.text = filtros.busca;
      _categoriaSelecionadaId = categoriaId;
      _statusFiltro = _statusEstoqueWebDaPreferencia(filtros.status);
      _estoqueFiltro = _situacaoEstoqueWebDaPreferencia(
        filtros.situacaoEstoque,
      );
      _marcacaoFiltro = _marcacaoEstoqueWebDaPreferencia(filtros.marcacao);
      ordenacao = _ordenacaoEstoqueWebDaPreferencia(filtros.ordenacao);
      _resumoRapidoSelecionado = _resumoEstoqueWebDaPreferencia(
        filtros.resumoRapido,
      );
      _itensPorPagina = filtros.itensPorPagina;
      _resetarPaginacao();
    });
    _aplicandoPreferenciasEstoque = false;
    _ultimaAssinaturaPreferenciasEstoque = _assinaturaPreferenciasEstoqueWeb();
  }

  void _agendarSalvamentoPreferenciasEstoqueWeb() {
    if (!_usarPreferenciasEstoqueWeb || _aplicandoPreferenciasEstoque) return;

    _debouncePreferenciasEstoque?.cancel();
    if (_assinaturaPreferenciasEstoqueWeb() ==
        _ultimaAssinaturaPreferenciasEstoque) {
      return;
    }
    _usuarioAlterouFiltrosEstoque = true;

    _debouncePreferenciasEstoque = Timer(
      const Duration(milliseconds: 450),
      _salvarPreferenciasEstoqueWeb,
    );
  }

  Future<void> _salvarPreferenciasEstoqueWeb() async {
    if (_salvandoFiltrosEstoque) {
      _salvamentoFiltrosEstoquePendente = true;
      return;
    }

    _salvandoFiltrosEstoque = true;
    try {
      while (true) {
        _salvamentoFiltrosEstoquePendente = false;
        final String assinatura = _assinaturaPreferenciasEstoqueWeb();
        if (assinatura == _ultimaAssinaturaPreferenciasEstoque) break;

        final EstoqueFiltrosPreferencia filtros =
            _preferenciasEstoqueWebAtuais();
        try {
          await _usuarioService.atualizarPreferenciasIndividuais(
            estoqueFiltrosWeb: filtros.toJson(),
          );
          _ultimaAssinaturaPreferenciasEstoque = assinatura;
        } catch (error, stackTrace) {
          _logError(
            'Erro ao salvar preferencias web do estoque',
            error,
            stackTrace,
          );
          break;
        }

        if (!_salvamentoFiltrosEstoquePendente &&
            _assinaturaPreferenciasEstoqueWeb() ==
                _ultimaAssinaturaPreferenciasEstoque) {
          break;
        }
      }
    } finally {
      _salvandoFiltrosEstoque = false;
    }
  }

  EstoqueFiltrosPreferencia _preferenciasEstoqueWebAtuais() {
    return EstoqueFiltrosPreferencia(
      busca: termoBusca,
      categoriaId: _categoriaSelecionadaId,
      status: _statusPreferenciaEstoqueWeb(_statusFiltro),
      situacaoEstoque: _situacaoPreferenciaEstoqueWeb(_estoqueFiltro),
      marcacao: _marcacaoPreferenciaEstoqueWeb(_marcacaoFiltro),
      ordenacao: _ordenacaoPreferenciaEstoqueWeb(ordenacao),
      resumoRapido: _resumoPreferenciaEstoqueWeb(_resumoRapidoSelecionado),
      itensPorPagina: _itensPorPagina,
    );
  }

  String _assinaturaPreferenciasEstoqueWeb() {
    final EstoqueFiltrosPreferencia filtros = _preferenciasEstoqueWebAtuais();
    return <Object?>[
      filtros.busca,
      filtros.categoriaId,
      filtros.status,
      filtros.situacaoEstoque,
      filtros.marcacao,
      filtros.ordenacao,
      filtros.resumoRapido,
      filtros.itensPorPagina,
    ].join('|');
  }

  _ProdutoStatusFiltro _statusEstoqueWebDaPreferencia(String codigo) {
    switch (codigo) {
      case 'ATIVOS':
        return _ProdutoStatusFiltro.ativos;
      case 'INATIVOS':
        return _ProdutoStatusFiltro.inativos;
      default:
        return _ProdutoStatusFiltro.todos;
    }
  }

  String _statusPreferenciaEstoqueWeb(_ProdutoStatusFiltro filtro) {
    switch (filtro) {
      case _ProdutoStatusFiltro.todos:
        return 'TODOS';
      case _ProdutoStatusFiltro.ativos:
        return 'ATIVOS';
      case _ProdutoStatusFiltro.inativos:
        return 'INATIVOS';
    }
  }

  _ProdutoEstoqueFiltro _situacaoEstoqueWebDaPreferencia(String codigo) {
    switch (codigo) {
      case 'EM_ESTOQUE':
        return _ProdutoEstoqueFiltro.emEstoque;
      case 'ESTOQUE_BAIXO':
        return _ProdutoEstoqueFiltro.estoqueBaixo;
      case 'SEM_ESTOQUE':
        return _ProdutoEstoqueFiltro.semEstoque;
      case 'ESTOQUE_NEGATIVO':
        return _ProdutoEstoqueFiltro.estoqueNegativo;
      default:
        return _ProdutoEstoqueFiltro.todos;
    }
  }

  String _situacaoPreferenciaEstoqueWeb(_ProdutoEstoqueFiltro filtro) {
    switch (filtro) {
      case _ProdutoEstoqueFiltro.todos:
        return 'TODOS';
      case _ProdutoEstoqueFiltro.emEstoque:
        return 'EM_ESTOQUE';
      case _ProdutoEstoqueFiltro.estoqueBaixo:
        return 'ESTOQUE_BAIXO';
      case _ProdutoEstoqueFiltro.semEstoque:
        return 'SEM_ESTOQUE';
      case _ProdutoEstoqueFiltro.estoqueNegativo:
        return 'ESTOQUE_NEGATIVO';
    }
  }

  _ProdutoMarcacaoFiltro _marcacaoEstoqueWebDaPreferencia(String codigo) {
    switch (codigo) {
      case 'FAVORITOS':
        return _ProdutoMarcacaoFiltro.favoritos;
      case 'CATALOGO':
        return _ProdutoMarcacaoFiltro.catalogo;
      case 'FAVORITOS_E_CATALOGO':
        return _ProdutoMarcacaoFiltro.favoritosECatalogo;
      default:
        return _ProdutoMarcacaoFiltro.todos;
    }
  }

  String _marcacaoPreferenciaEstoqueWeb(_ProdutoMarcacaoFiltro filtro) {
    switch (filtro) {
      case _ProdutoMarcacaoFiltro.todos:
        return 'TODOS';
      case _ProdutoMarcacaoFiltro.favoritos:
        return 'FAVORITOS';
      case _ProdutoMarcacaoFiltro.catalogo:
        return 'CATALOGO';
      case _ProdutoMarcacaoFiltro.favoritosECatalogo:
        return 'FAVORITOS_E_CATALOGO';
    }
  }

  String _ordenacaoEstoqueWebDaPreferencia(String codigo) {
    switch (codigo) {
      case 'PRECO_ASC':
        return 'precoAsc';
      case 'PRECO_DESC':
        return 'precoDesc';
      default:
        return 'nomeAsc';
    }
  }

  String _ordenacaoPreferenciaEstoqueWeb(String valor) {
    switch (valor) {
      case 'precoAsc':
        return 'PRECO_ASC';
      case 'precoDesc':
        return 'PRECO_DESC';
      default:
        return 'NOME_ASC';
    }
  }

  _ProdutoResumoRapidoFiltro _resumoEstoqueWebDaPreferencia(String codigo) {
    switch (codigo) {
      case 'TODOS':
        return _ProdutoResumoRapidoFiltro.todos;
      case 'SERVICOS':
        return _ProdutoResumoRapidoFiltro.servicos;
      case 'COM_IMAGEM':
        return _ProdutoResumoRapidoFiltro.comImagem;
      case 'ESTOQUE_BAIXO':
        return _ProdutoResumoRapidoFiltro.estoqueBaixo;
      default:
        return _ProdutoResumoRapidoFiltro.produtos;
    }
  }

  String _resumoPreferenciaEstoqueWeb(_ProdutoResumoRapidoFiltro filtro) {
    switch (filtro) {
      case _ProdutoResumoRapidoFiltro.todos:
        return 'TODOS';
      case _ProdutoResumoRapidoFiltro.produtos:
        return 'PRODUTOS';
      case _ProdutoResumoRapidoFiltro.servicos:
        return 'SERVICOS';
      case _ProdutoResumoRapidoFiltro.comImagem:
        return 'COM_IMAGEM';
      case _ProdutoResumoRapidoFiltro.estoqueBaixo:
        return 'ESTOQUE_BAIXO';
    }
  }

  Future<void> _carregarPreferenciasDoUsuario() async {
    if (_usuarioProvider.usuario != null) return;
    try {
      await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
      if (mounted) setState(() {});
    } catch (error, stackTrace) {
      _logError('Erro ao carregar preferencias do usuario', error, stackTrace);
    }
  }

  Future<void> _recarregar() async {
    if (!widget.isSelecao) {
      await _recarregarCatalogoEdicao();
      return;
    }

    try {
      await ProdutoHelper.retornarProdutosList(
        context,
        tipo: tipoSelecionado,
        produtosAtivos: widget.apenasAtivosNoBackend ? true : null,
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

  Future<void> _recarregarCatalogoEdicao() async {
    if (!mounted) return;

    setState(() {
      _carregandoCatalogoEdicao = true;
      _erroCatalogoEdicao = null;
    });

    final List<ProdutoModel> produtos = <ProdutoModel>[];
    final List<ProdutoModel> servicos = <ProdutoModel>[];
    Object? erroProdutos;
    Object? erroServicos;

    try {
      await ProdutoHelper.retornarProdutosList(
        context,
        tipo: 'PRODUTO',
        onSucesso: (List<ProdutoModel> items) => produtos.addAll(items),
      );
    } catch (error, stackTrace) {
      erroProdutos = error;
      _logError(
        'Erro ao recarregar produtos do catalogo web',
        error,
        stackTrace,
      );
    }

    if (!mounted) return;

    try {
      await ProdutoHelper.retornarProdutosList(
        context,
        tipo: 'SERVICO',
        onSucesso: (List<ProdutoModel> items) => servicos.addAll(items),
      );
    } catch (error, stackTrace) {
      erroServicos = error;
      _logError(
        'Erro ao recarregar servicos do catalogo web',
        error,
        stackTrace,
      );
    }

    if (!mounted) return;

    final List<ProdutoModel> itensCarregados = <ProdutoModel>[
      ...produtos,
      ...servicos,
    ];
    setState(() {
      todosProdutos = itensCarregados;
      final String? categoriaId = _categoriaSelecionadaId;
      if (categoriaId != null &&
          !itensCarregados.any(
            (ProdutoModel produto) =>
                produto.objCategoria?.idCategoria == categoriaId,
          )) {
        _categoriaSelecionadaId = null;
      }
      produtosFiltrados = const <ProdutoModel>[];
      _carregandoCatalogoEdicao = false;
      _resetarPaginacao();
      _erroCatalogoEdicao =
          produtos.isEmpty && servicos.isEmpty
              ? (erroProdutos ?? erroServicos)?.toString()
              : null;
    });
    if (_usarPreferenciasEstoqueWeb && !_usuarioAlterouFiltrosEstoque) {
      _ultimaAssinaturaPreferenciasEstoque =
          _assinaturaPreferenciasEstoqueWeb();
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
                  _matchesTipoSelecionado(produto, tipoSelecionado) &&
                  _matchesMarcacaoFiltro(produto),
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

  void _atualizarCatalogo(VoidCallback update, {bool resetPagination = true}) {
    setState(() {
      update();
      if (resetPagination) {
        _resetarPaginacao();
      }
    });
    _agendarSalvamentoPreferenciasEstoqueWeb();
  }

  void _resetarPaginacao() {
    _paginaAtual = 0;
  }

  Future<void> _alterarModoExibicaoProdutos(
    ModoDeExibicaoUsuario novoModo,
  ) async {
    if (_salvandoPreferencia || novoModo == _modoDeExibicaoProdutosWeb) return;

    setState(() => _salvandoPreferencia = true);
    try {
      await _usuarioService.atualizarPreferenciasIndividuais(
        modoDeExibicaoProdutosWeb: novoModo.codigo,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'produto.webList.preferenceSaved',
              fallback: 'Preferência de visualização atualizada.',
            ),
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

  Future<void> _abrirEditorQuantidadeSelecionada(ProdutoModel produto) async {
    final String chave = _chaveProduto(produto);
    final _ProdutoSelecionadoWeb? selecionado = _produtosSelecionados[chave];
    if (selecionado == null) return;

    await showSixWebPdvQuantityDialog(
      context: context,
      productName: produto.nomeProduto.trim(),
      productCode: produto.codigoDeBarras.trim(),
      currentQuantity: selecionado.quantidade,
      onConfirm: (int novaQuantidade) async {
        if (!mounted) return;
        setState(() {
          _produtosSelecionados[chave] = selecionado.copyWith(
            quantidade: novaQuantidade,
          );
        });
      },
    );
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

  Future<void> _abrirCadastroParaEdicao(ProdutoModel produto) async {
    final bool? atualizado = await showSubPainelCadastroProduto(
      context,
      'Editar Produto',
      produtoParaEdicao: produto,
      modoEdicao: true,
    );
    if (atualizado == true && mounted) {
      await _recarregar();
    }
  }

  Future<void> _abrirNovoProduto() async {
    final bool? atualizado = await showSubPainelCadastroProduto(
      context,
      'Cadastro de Produtos',
    );
    if (atualizado == true && mounted) {
      await _recarregar();
    }
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
        ProdutosListProvider<ProdutoModel>? provider;
        List<ProdutoModel> itensDaLista = const <ProdutoModel>[];
        _ProdutoCatalogoEdicaoSnapshot? snapshot;

        if (widget.isSelecao) {
          provider = context.watch<ProdutosListProvider<ProdutoModel>>();
          final List<ProdutoModel> baseProdutos =
              todosProdutos.isNotEmpty
                  ? todosProdutos
                  : provider.listaDeProdutos;
          itensDaLista =
              baseProdutos.isEmpty && termoBusca.isEmpty
                  ? provider.listaDeProdutos
                  : produtosFiltrados;
        } else {
          snapshot = _criarCatalogoEdicaoSnapshot();
          itensDaLista = snapshot.itensFiltrados;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 920;
            final horizontalPadding = isCompact ? 16.0 : 28.0;
            final tokens = WebThemeTokens.of(context);
            final bool paginacaoCompactaNoConteudo =
                !widget.isSelecao && isCompact;

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
                  if (widget.isSelecao)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        10,
                        horizontalPadding,
                        10,
                      ),
                      child: _buildSearchOrderAndPreference(context, isCompact),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        12,
                      ),
                      child: _buildCatalogControls(
                        context,
                        isCompact,
                        snapshot!,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        14,
                      ),
                      child:
                          widget.isSelecao
                              ? _buildList(context, provider!, itensDaLista)
                              : paginacaoCompactaNoConteudo
                              ? Column(
                                children: <Widget>[
                                  Expanded(
                                    child: _buildCatalogContent(
                                      context,
                                      snapshot!,
                                      constraints.maxWidth,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCatalogPagination(
                                    context,
                                    snapshot,
                                    true,
                                  ),
                                ],
                              )
                              : _buildCatalogContent(
                                context,
                                snapshot!,
                                constraints.maxWidth,
                              ),
                    ),
                  ),
                  if (!widget.isSelecao && !paginacaoCompactaNoConteudo)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        18,
                      ),
                      child: _buildCatalogPagination(
                        context,
                        snapshot!,
                        isCompact,
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
    final String title =
        widget.isSelecao
            ? widget.permitirSelecaoMultipla
                ? context.t(
                  'produto.webList.selection.titleMany',
                  fallback: 'Selecionar itens',
                )
                : context.t(
                  'produto.webList.selection.titleOne',
                  fallback: 'Selecionar item',
                )
            : widget.modoEdicao
            ? context.t(
              'produto.webList.edit.title',
              fallback: 'Editar produtos',
            )
            : context.t(
              'web.navigation.catalog.products',
              fallback: 'Produtos',
            );
    final String subtitle =
        widget.isSelecao
            ? widget.permitirSelecaoMultipla
                ? context.t(
                  'produto.webList.selection.subtitleMany',
                  fallback:
                      'Marque produtos e serviços e adicione tudo na venda de uma vez.',
                )
                : context.t(
                  'produto.webList.selection.subtitleOne',
                  fallback:
                      'Busca rápida para incluir produto ou serviço na venda.',
                )
            : widget.modoEdicao
            ? _exibirInformacoesEstoque
                ? context.t(
                  'produto.webList.edit.subtitle',
                  fallback:
                      'Gerencie seu catálogo de produtos, estoque, preços e imagens.',
                )
                : context.t(
                  'catalogHub.list.subtitle',
                  fallback:
                      'Gerencie produtos, serviços, preços, imagens e organização.',
                )
            : context.t(
              'produto.webList.default.subtitle',
              fallback: 'Consulta rápida do catálogo com ações de balcão.',
            );

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
        _headerButton(
          context,
          Icons.refresh_rounded,
          context.t('common.refresh', fallback: 'Atualizar'),
          _recarregar,
        ),
        if (widget.isSelecao &&
            widget.permitirSelecaoMultipla &&
            _produtosSelecionados.isNotEmpty)
          _headerButton(
            context,
            Icons.cleaning_services_outlined,
            context.t('common.clear', fallback: 'Limpar'),
            _limparSelecaoMultipla,
          ),
        if (!widget.isSelecao) ...<Widget>[
          _headerButton(
            context,
            Icons.add_rounded,
            context.t('produto.webList.newItem', fallback: 'Novo item'),
            _abrirNovoProduto,
            filled: true,
          ),
          _headerButton(
            context,
            Icons.picture_as_pdf_outlined,
            _isGerandoRelatorio
                ? context.t('common.generating', fallback: 'Gerando...')
                : context.t(
                  'produto.webList.printPdf',
                  fallback: 'Imprimir PDF',
                ),
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
        style: _catalogFilledButtonStyle(
          context,
          padding: padding,
          shape: shape,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: _catalogOutlinedButtonStyle(
        context,
        padding: padding,
        shape: shape,
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    final OutlinedBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close_rounded, size: 18),
      label: Text(context.t('common.close', fallback: 'Fechar')),
      style: _catalogOutlinedButtonStyle(
        context,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: shape,
      ),
    );
  }

  ButtonStyle _catalogOutlinedButtonStyle(
    BuildContext context, {
    required EdgeInsetsGeometry padding,
    required OutlinedBorder shape,
    bool emphasis = false,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return OutlinedButton.styleFrom(
      padding: padding,
      shape: shape,
      foregroundColor: tokens.info,
      disabledForegroundColor: tokens.disabledForeground,
      backgroundColor:
          emphasis
              ? tokens.info.withValues(alpha: 0.07)
              : tokens.inputBackground,
      disabledBackgroundColor: tokens.disabledBackground.withValues(
        alpha: 0.48,
      ),
      side: BorderSide(
        color:
            emphasis ? tokens.info.withValues(alpha: 0.22) : tokens.cardBorder,
      ),
    ).copyWith(overlayColor: _catalogButtonOverlay(tokens));
  }

  ButtonStyle _catalogFilledButtonStyle(
    BuildContext context, {
    required EdgeInsetsGeometry padding,
    required OutlinedBorder shape,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return FilledButton.styleFrom(
      padding: padding,
      shape: shape,
      backgroundColor: tokens.info,
      foregroundColor: tokens.onInfo,
      disabledBackgroundColor: tokens.disabledBackground,
      disabledForegroundColor: tokens.disabledForeground,
    ).copyWith(overlayColor: _catalogFilledButtonOverlay(tokens));
  }

  WidgetStateProperty<Color?> _catalogButtonOverlay(WebThemeTokens tokens) {
    return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return tokens.info.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return tokens.info.withValues(alpha: 0.10);
      }
      return null;
    });
  }

  WidgetStateProperty<Color?> _catalogFilledButtonOverlay(
    WebThemeTokens tokens,
  ) {
    return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return tokens.workspaceBackground.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return tokens.workspaceBackground.withValues(alpha: 0.10);
      }
      return null;
    });
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
              context
                  .t(
                    'produto.webList.edit.banner',
                    fallback:
                        'Modo edição ativo • {count} itens encontrados • clique em um produto para alterar.',
                  )
                  .replaceAll('{count}', totalItens.toString()),
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

    final search = TextField(
      controller: _controllerBusca,
      style: TextStyle(color: tokens.primaryText),
      decoration: InputDecoration(
        hintText: context.t(
          'produto.webList.searchHint',
          fallback: 'Buscar por nome, código ou SKU...',
        ),
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
        fillColor: tokens.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.cardBorder),
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

    final Widget marcacaoFilter = _buildMenuFiltro<_ProdutoMarcacaoFiltro>(
      context: context,
      icon: Icons.auto_awesome_outlined,
      label: context.t('produto.webList.filter.flags', fallback: 'Marcadores'),
      value: _marcacaoFiltroLabel(context),
      selectedValue: _marcacaoFiltro,
      minWidth: 184,
      items: <_ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>>[
        _ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>(
          value: _ProdutoMarcacaoFiltro.todos,
          label: context.t(
            'produto.webList.filter.flagsAll',
            fallback: 'Todos itens',
          ),
        ),
        _ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>(
          value: _ProdutoMarcacaoFiltro.favoritos,
          label: context.t(
            'produto.webList.filter.flagsFavorites',
            fallback: 'Favoritos',
          ),
        ),
        _ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>(
          value: _ProdutoMarcacaoFiltro.catalogo,
          label: context.t(
            'produto.webList.filter.flagsCatalog',
            fallback: 'No catálogo',
          ),
        ),
        _ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>(
          value: _ProdutoMarcacaoFiltro.favoritosECatalogo,
          label: context.t(
            'produto.webList.filter.flagsFavoritesCatalog',
            fallback: 'Favoritos e catálogo',
          ),
        ),
      ],
      onSelected: (_ProdutoMarcacaoFiltro value) {
        _atualizarCatalogo(() {
          _marcacaoFiltro = value;
        });
        aplicarFiltroOrdenacao();
      },
    );

    final Widget order = _buildMenuFiltro<String>(
      context: context,
      icon: Icons.swap_vert_rounded,
      label: context.t('produto.webList.sort.label', fallback: 'Ordenação'),
      value: _ordenacaoLabel(context),
      selectedValue: ordenacao,
      minWidth: 184,
      items: <_ProdutoFiltroMenuOpcao<String>>[
        _ProdutoFiltroMenuOpcao<String>(
          value: 'nomeAsc',
          label: context.t(
            'produto.webList.sort.name',
            fallback: 'Ordenar por nome',
          ),
        ),
        _ProdutoFiltroMenuOpcao<String>(
          value: 'precoAsc',
          label: context.t(
            'produto.webList.sort.priceAsc',
            fallback: 'Menor preço',
          ),
        ),
        _ProdutoFiltroMenuOpcao<String>(
          value: 'precoDesc',
          label: context.t(
            'produto.webList.sort.priceDesc',
            fallback: 'Maior preço',
          ),
        ),
      ],
      onSelected: (String value) {
        _atualizarCatalogo(() {
          ordenacao = value;
        });
        aplicarFiltroOrdenacao();
      },
    );

    final Widget filters = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[marcacaoFilter, order],
    );

    if (isCompact) {
      return Column(
        children: <Widget>[
          search,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: filters),
          const SizedBox(height: 10),
          _buildModoExibicaoSelector(context, expand: true),
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wrapBelow = constraints.maxWidth < 1320;
        if (wrapBelow) {
          return Column(
            children: <Widget>[
              search,
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  SizedBox(width: 196, child: marcacaoFilter),
                  SizedBox(width: 196, child: order),
                  SizedBox(
                    width: 268,
                    child: _buildModoExibicaoSelector(context, expand: false),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 196, child: marcacaoFilter),
            const SizedBox(width: 12),
            SizedBox(width: 196, child: order),
            const SizedBox(width: 12),
            SizedBox(
              width: 268,
              child: _buildModoExibicaoSelector(context, expand: false),
            ),
          ],
        );
      },
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
              label:
                  widget.isSelecao
                      ? context.t(
                        'produto.webList.view.vertical',
                        fallback: 'Vertical',
                      )
                      : context.t(
                        'produto.webList.view.list',
                        fallback: 'Lista',
                      ),
              icon: Icons.view_agenda_outlined,
              selected: !_usarGrade,
              onTap:
                  () =>
                      _alterarModoExibicaoProdutos(ModoDeExibicaoUsuario.lista),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _modoButton(
              context,
              label:
                  widget.isSelecao
                      ? context.t(
                        'produto.webList.view.horizontal',
                        fallback: 'Horizontal',
                      )
                      : context.t(
                        'produto.webList.view.grid',
                        fallback: 'Grade',
                      ),
              icon: Icons.view_carousel_outlined,
              selected: _usarGrade,
              onTap:
                  () =>
                      _alterarModoExibicaoProdutos(ModoDeExibicaoUsuario.grade),
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

  _ProdutoCatalogoEdicaoSnapshot _criarCatalogoEdicaoSnapshot() {
    final List<ProdutoModel> baseItens = _aplicarFiltrosEstruturais(
      todosProdutos,
      incluirResumoRapido: false,
    );
    final Map<_ProdutoResumoRapidoFiltro, int> contagensResumo =
        <_ProdutoResumoRapidoFiltro, int>{
          _ProdutoResumoRapidoFiltro.todos: baseItens.length,
          _ProdutoResumoRapidoFiltro.produtos:
              baseItens.where((ProdutoModel item) => !_isServico(item)).length,
          _ProdutoResumoRapidoFiltro.servicos:
              baseItens.where(_isServico).length,
          _ProdutoResumoRapidoFiltro.comImagem:
              baseItens
                  .where((ProdutoModel item) => _primeiraImagem(item) != null)
                  .length,
          _ProdutoResumoRapidoFiltro.estoqueBaixo:
              baseItens
                  .where(
                    (ProdutoModel item) =>
                        _situacaoEstoque(item) ==
                        _ProdutoSituacaoEstoque.estoqueBaixo,
                  )
                  .length,
        };
    final List<ProdutoModel> itensFiltrados = _ordenarProdutos(
      _aplicarFiltrosEstruturais(todosProdutos),
    );

    final int totalPaginas =
        itensFiltrados.isEmpty
            ? 1
            : ((itensFiltrados.length - 1) ~/ _itensPorPagina) + 1;
    final int paginaAtualNormalizada =
        totalPaginas <= 1 ? 0 : _paginaAtual.clamp(0, totalPaginas - 1);
    final int inicio =
        itensFiltrados.isEmpty ? 0 : paginaAtualNormalizada * _itensPorPagina;
    final int fim =
        itensFiltrados.isEmpty
            ? 0
            : (inicio + _itensPorPagina).clamp(0, itensFiltrados.length);

    return _ProdutoCatalogoEdicaoSnapshot(
      baseItens: baseItens,
      itensFiltrados: itensFiltrados,
      itensPaginados:
          itensFiltrados.isEmpty
              ? const <ProdutoModel>[]
              : itensFiltrados.sublist(inicio, fim),
      contagensResumo: contagensResumo,
      paginaAtual: paginaAtualNormalizada,
      totalPaginas: totalPaginas,
      indiceInicial: itensFiltrados.isEmpty ? 0 : inicio + 1,
      indiceFinal: fim,
    );
  }

  List<ProdutoModel> _aplicarFiltrosEstruturais(
    List<ProdutoModel> itens, {
    bool incluirResumoRapido = true,
  }) {
    Iterable<ProdutoModel> resultado = itens;
    final String termoNormalizado = termoBusca.trim().toLowerCase();

    if (termoNormalizado.isNotEmpty) {
      resultado = resultado.where(
        (ProdutoModel produto) => _matchesBusca(produto, termoNormalizado),
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
      case _ProdutoStatusFiltro.todos:
        break;
      case _ProdutoStatusFiltro.ativos:
        resultado = resultado.where((ProdutoModel produto) => produto.ativo);
      case _ProdutoStatusFiltro.inativos:
        resultado = resultado.where((ProdutoModel produto) => !produto.ativo);
    }

    if (_exibirInformacoesEstoque) {
      switch (_estoqueFiltro) {
        case _ProdutoEstoqueFiltro.todos:
          break;
        case _ProdutoEstoqueFiltro.emEstoque:
          resultado = resultado.where(
            (ProdutoModel produto) =>
                _situacaoEstoque(produto) == _ProdutoSituacaoEstoque.emEstoque,
          );
        case _ProdutoEstoqueFiltro.estoqueBaixo:
          resultado = resultado.where(
            (ProdutoModel produto) =>
                _situacaoEstoque(produto) ==
                _ProdutoSituacaoEstoque.estoqueBaixo,
          );
        case _ProdutoEstoqueFiltro.semEstoque:
          resultado = resultado.where(
            (ProdutoModel produto) =>
                _situacaoEstoque(produto) == _ProdutoSituacaoEstoque.semEstoque,
          );
        case _ProdutoEstoqueFiltro.estoqueNegativo:
          resultado = resultado.where(
            (ProdutoModel produto) =>
                _situacaoEstoque(produto) ==
                _ProdutoSituacaoEstoque.estoqueNegativo,
          );
      }
    }

    switch (_marcacaoFiltro) {
      case _ProdutoMarcacaoFiltro.todos:
        break;
      case _ProdutoMarcacaoFiltro.favoritos:
        resultado = resultado.where((ProdutoModel produto) => produto.favorito);
      case _ProdutoMarcacaoFiltro.catalogo:
        resultado = resultado.where(
          (ProdutoModel produto) => produto.disponivelParaCatalogo,
        );
      case _ProdutoMarcacaoFiltro.favoritosECatalogo:
        resultado = resultado.where(
          (ProdutoModel produto) =>
              produto.favorito && produto.disponivelParaCatalogo,
        );
    }

    if (!incluirResumoRapido) {
      return resultado.toList(growable: false);
    }

    switch (_resumoRapidoSelecionado) {
      case _ProdutoResumoRapidoFiltro.todos:
        return resultado.toList(growable: false);
      case _ProdutoResumoRapidoFiltro.produtos:
        return resultado
            .where((ProdutoModel item) => !_isServico(item))
            .toList(growable: false);
      case _ProdutoResumoRapidoFiltro.servicos:
        return resultado.where(_isServico).toList(growable: false);
      case _ProdutoResumoRapidoFiltro.comImagem:
        return resultado
            .where((ProdutoModel item) => _primeiraImagem(item) != null)
            .toList(growable: false);
      case _ProdutoResumoRapidoFiltro.estoqueBaixo:
        return resultado
            .where(
              (ProdutoModel item) =>
                  _situacaoEstoque(item) ==
                  _ProdutoSituacaoEstoque.estoqueBaixo,
            )
            .toList(growable: false);
    }
  }

  bool _matchesBusca(ProdutoModel produto, String termoNormalizado) {
    return produto.nomeProduto.toLowerCase().contains(termoNormalizado) ||
        produto.codigoDeBarras.toLowerCase().contains(termoNormalizado);
  }

  List<ProdutoModel> _ordenarProdutos(List<ProdutoModel> itens) {
    final List<ProdutoModel> ordenados = <ProdutoModel>[...itens];
    switch (ordenacao) {
      case 'precoAsc':
        ordenados.sort((a, b) => a.precoVenda.compareTo(b.precoVenda));
      case 'precoDesc':
        ordenados.sort((a, b) => b.precoVenda.compareTo(a.precoVenda));
      case 'nomeAsc':
      default:
        ordenados.sort(
          (a, b) => a.nomeProduto.toLowerCase().compareTo(
            b.nomeProduto.toLowerCase(),
          ),
        );
    }
    return ordenados;
  }

  Widget _buildCatalogControls(
    BuildContext context,
    bool isCompact,
    _ProdutoCatalogoEdicaoSnapshot snapshot,
  ) {
    return Column(
      children: <Widget>[
        _buildCatalogSearchAndFilters(context, isCompact),
        const SizedBox(height: 10),
        _buildResumoRapidoBar(context, snapshot),
      ],
    );
  }

  Widget _buildCatalogSearchAndFilters(BuildContext context, bool isCompact) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    final Widget searchField = TextField(
      key: const ValueKey<String>('produto-web-search-field'),
      controller: _controllerBusca,
      style: TextStyle(color: tokens.primaryText),
      decoration: InputDecoration(
        hintText: context.t(
          'produto.webList.searchHint',
          fallback: 'Buscar por nome, código ou SKU...',
        ),
        hintStyle: TextStyle(color: tokens.mutedText),
        prefixIcon: Icon(Icons.search_rounded, color: tokens.info),
        suffixIcon:
            termoBusca.isEmpty
                ? null
                : IconButton(
                  tooltip: context.t('common.clear', fallback: 'Limpar'),
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _controllerBusca.clear();
                    _atualizarCatalogo(() {
                      termoBusca = '';
                    });
                  },
                ),
        filled: true,
        fillColor: tokens.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.info, width: 1.4),
        ),
      ),
      onChanged: (String value) {
        _atualizarCatalogo(() {
          termoBusca = value;
        });
      },
    );

    final Widget filters = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _buildMenuFiltro<String?>(
          context: context,
          icon: Icons.category_outlined,
          label: context.t(
            'produto.webList.filter.category',
            fallback: 'Categoria',
          ),
          value: _categoriaSelecionadaLabel(context),
          selectedValue: _categoriaSelecionadaId,
          minWidth: 190,
          items: <_ProdutoFiltroMenuOpcao<String?>>[
            _ProdutoFiltroMenuOpcao<String?>(
              value: null,
              label: context.t(
                'produto.webList.filter.categoryAll',
                fallback: 'Todas categorias',
              ),
            ),
            ..._categoriasDisponiveis().map(
              (_CategoriaFiltro categoria) => _ProdutoFiltroMenuOpcao<String?>(
                value: categoria.id,
                label: categoria.nome,
              ),
            ),
          ],
          onSelected: (String? value) {
            _atualizarCatalogo(() {
              _categoriaSelecionadaId = value;
            });
          },
        ),
        _buildMenuFiltro<_ProdutoStatusFiltro>(
          context: context,
          icon: Icons.toggle_on_outlined,
          label: context.t('atendimentoTecnico.status', fallback: 'Status'),
          value: _statusFiltroLabel(context),
          selectedValue: _statusFiltro,
          minWidth: 156,
          items: <_ProdutoFiltroMenuOpcao<_ProdutoStatusFiltro>>[
            _ProdutoFiltroMenuOpcao<_ProdutoStatusFiltro>(
              value: _ProdutoStatusFiltro.todos,
              label: context.t(
                'produto.webList.filter.statusAll',
                fallback: 'Todos',
              ),
            ),
            _ProdutoFiltroMenuOpcao<_ProdutoStatusFiltro>(
              value: _ProdutoStatusFiltro.ativos,
              label: context.t('common.active', fallback: 'Ativo'),
            ),
            _ProdutoFiltroMenuOpcao<_ProdutoStatusFiltro>(
              value: _ProdutoStatusFiltro.inativos,
              label: context.t('common.inactive', fallback: 'Inativo'),
            ),
          ],
          onSelected: (_ProdutoStatusFiltro value) {
            _atualizarCatalogo(() {
              _statusFiltro = value;
            });
          },
        ),
        if (_exibirInformacoesEstoque)
          _buildMenuFiltro<_ProdutoEstoqueFiltro>(
            context: context,
            icon: Icons.inventory_2_outlined,
            label: context.t('workspaceHome.stock.title', fallback: 'Estoque'),
            value: _estoqueFiltroLabel(context),
            selectedValue: _estoqueFiltro,
            minWidth: 170,
            items: <_ProdutoFiltroMenuOpcao<_ProdutoEstoqueFiltro>>[
              _ProdutoFiltroMenuOpcao<_ProdutoEstoqueFiltro>(
                value: _ProdutoEstoqueFiltro.todos,
                label: context.t(
                  'produto.webList.filter.stockAll',
                  fallback: 'Todos',
                ),
              ),
              _ProdutoFiltroMenuOpcao<_ProdutoEstoqueFiltro>(
                value: _ProdutoEstoqueFiltro.emEstoque,
                label: context.t(
                  'produto.webList.filter.stockAvailable',
                  fallback: 'Em estoque',
                ),
              ),
              _ProdutoFiltroMenuOpcao<_ProdutoEstoqueFiltro>(
                value: _ProdutoEstoqueFiltro.estoqueBaixo,
                label: context.t(
                  'produto.webList.filter.stockLow',
                  fallback: 'Estoque baixo',
                ),
              ),
              _ProdutoFiltroMenuOpcao<_ProdutoEstoqueFiltro>(
                value: _ProdutoEstoqueFiltro.semEstoque,
                label: context.t(
                  'produto.webList.filter.stockOut',
                  fallback: 'Sem estoque',
                ),
              ),
              _ProdutoFiltroMenuOpcao<_ProdutoEstoqueFiltro>(
                value: _ProdutoEstoqueFiltro.estoqueNegativo,
                label: context.t(
                  'produto.webList.filter.stockNegative',
                  fallback: 'Estoque negativo',
                ),
              ),
            ],
            onSelected: (_ProdutoEstoqueFiltro value) {
              _atualizarCatalogo(() {
                _estoqueFiltro = value;
              });
            },
          ),
        _buildMenuFiltro<_ProdutoMarcacaoFiltro>(
          context: context,
          icon: Icons.auto_awesome_outlined,
          label: context.t(
            'produto.webList.filter.flags',
            fallback: 'Marcadores',
          ),
          value: _marcacaoFiltroLabel(context),
          selectedValue: _marcacaoFiltro,
          minWidth: 184,
          items: <_ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>>[
            _ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>(
              value: _ProdutoMarcacaoFiltro.todos,
              label: context.t(
                'produto.webList.filter.flagsAll',
                fallback: 'Todos itens',
              ),
            ),
            _ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>(
              value: _ProdutoMarcacaoFiltro.favoritos,
              label: context.t(
                'produto.webList.filter.flagsFavorites',
                fallback: 'Favoritos',
              ),
            ),
            _ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>(
              value: _ProdutoMarcacaoFiltro.catalogo,
              label: context.t(
                'produto.webList.filter.flagsCatalog',
                fallback: 'No catálogo',
              ),
            ),
            _ProdutoFiltroMenuOpcao<_ProdutoMarcacaoFiltro>(
              value: _ProdutoMarcacaoFiltro.favoritosECatalogo,
              label: context.t(
                'produto.webList.filter.flagsFavoritesCatalog',
                fallback: 'Favoritos e catálogo',
              ),
            ),
          ],
          onSelected: (_ProdutoMarcacaoFiltro value) {
            _atualizarCatalogo(() {
              _marcacaoFiltro = value;
            });
          },
        ),
        _buildMenuFiltro<String>(
          context: context,
          icon: Icons.swap_vert_rounded,
          label: context.t('produto.webList.sort.label', fallback: 'Ordenação'),
          value: _ordenacaoLabel(context),
          selectedValue: ordenacao,
          minWidth: 170,
          items: <_ProdutoFiltroMenuOpcao<String>>[
            _ProdutoFiltroMenuOpcao<String>(
              value: 'nomeAsc',
              label: context.t(
                'produto.webList.sort.name',
                fallback: 'Ordenar por nome',
              ),
            ),
            _ProdutoFiltroMenuOpcao<String>(
              value: 'precoAsc',
              label: context.t(
                'produto.webList.sort.priceAsc',
                fallback: 'Menor preço',
              ),
            ),
            _ProdutoFiltroMenuOpcao<String>(
              value: 'precoDesc',
              label: context.t(
                'produto.webList.sort.priceDesc',
                fallback: 'Maior preço',
              ),
            ),
          ],
          onSelected: (String value) {
            _atualizarCatalogo(() {
              ordenacao = value;
            });
          },
        ),
        SizedBox(
          width: isCompact ? double.infinity : 220,
          child: _buildModoExibicaoSelector(context, expand: true),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child:
          isCompact
              ? Column(
                children: <Widget>[
                  searchField,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerLeft, child: filters),
                ],
              )
              : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool wrapBelow = constraints.maxWidth < 1320;
                  if (wrapBelow) {
                    return Column(
                      children: <Widget>[
                        searchField,
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerLeft, child: filters),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 11, child: searchField),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 13,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: filters,
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildMenuFiltro<T>({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required T selectedValue,
    required List<_ProdutoFiltroMenuOpcao<T>> items,
    required ValueChanged<T> onSelected,
    double minWidth = 150,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: 240),
      child: _ProdutoFiltroMenu<T>(
        tooltip: label,
        icon: icon,
        label: label,
        value: value,
        selectedValue: selectedValue,
        items: items,
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildResumoRapidoBar(
    BuildContext context,
    _ProdutoCatalogoEdicaoSnapshot snapshot,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<_ProdutoResumoRapidoFiltro> filtros =
        <_ProdutoResumoRapidoFiltro>[
          _ProdutoResumoRapidoFiltro.todos,
          _ProdutoResumoRapidoFiltro.produtos,
          _ProdutoResumoRapidoFiltro.servicos,
          _ProdutoResumoRapidoFiltro.comImagem,
          if (_exibirInformacoesEstoque)
            _ProdutoResumoRapidoFiltro.estoqueBaixo,
        ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: filtros
            .map((_ProdutoResumoRapidoFiltro filtro) {
              final bool selected = _resumoRapidoSelecionado == filtro;
              final int count = snapshot.contagensResumo[filtro] ?? 0;
              return Material(
                key: ValueKey<String>('produto-web-quick-${filtro.name}'),
                color:
                    selected ? tokens.selectedBackground : tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap:
                      () => _atualizarCatalogo(() {
                        _resumoRapidoSelecionado = filtro;
                      }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            selected
                                ? tokens.selectedBorder
                                : tokens.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _resumoRapidoLabel(context, filtro),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                selected
                                    ? tokens.primaryText
                                    : tokens.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? tokens.info.withValues(alpha: 0.12)
                                    : tokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color:
                                  selected ? tokens.info : tokens.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildCatalogContent(
    BuildContext context,
    _ProdutoCatalogoEdicaoSnapshot snapshot,
    double availableWidth,
  ) {
    if (_carregandoCatalogoEdicao) {
      return _buildCatalogLoading(context, availableWidth);
    }

    if (_erroCatalogoEdicao != null && todosProdutos.isEmpty) {
      return _buildCatalogError(context);
    }

    if (snapshot.itensFiltrados.isEmpty) {
      return _emptyState(context);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child:
          _usarGrade
              ? _buildCatalogGrid(
                context: context,
                key: const ValueKey<String>('produto-web-grid'),
                itens: snapshot.itensPaginados,
                availableWidth: availableWidth,
              )
              : _buildCatalogListView(
                context: context,
                key: const ValueKey<String>('produto-web-list'),
                itens: snapshot.itensPaginados,
                availableWidth: availableWidth,
              ),
    );
  }

  Widget _buildCatalogLoading(BuildContext context, double availableWidth) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final int columns = _columnsForWidth(availableWidth);
    final double spacing = 14;
    final double itemWidth =
        columns <= 1
            ? availableWidth
            : (availableWidth - (spacing * (columns - 1))) / columns;

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      thickness: 7,
      radius: const Radius.circular(999),
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List<Widget>.generate(8, (int index) {
            return Container(
              width: itemWidth,
              height: 182,
              decoration: BoxDecoration(
                color: tokens.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tokens.cardBorder),
              ),
            );
          }, growable: false),
        ),
      ),
    );
  }

  Widget _buildCatalogError(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: tokens.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: tokens.danger, size: 36),
            const SizedBox(height: 12),
            Text(
              context.t(
                'produto.webList.errorTitle',
                fallback: 'Não foi possível carregar o catálogo.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: tokens.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _erroCatalogoEdicao ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.secondaryText),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _recarregar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                context.t('common.tryAgain', fallback: 'Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogGrid({
    required BuildContext context,
    required Key key,
    required List<ProdutoModel> itens,
    required double availableWidth,
  }) {
    final int columns = _columnsForWidth(availableWidth);
    final double spacing = 14;
    final double itemWidth =
        columns <= 1
            ? availableWidth
            : (availableWidth - (spacing * (columns - 1))) / columns;

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      thickness: 7,
      radius: const Radius.circular(999),
      child: SingleChildScrollView(
        key: key,
        controller: _verticalScrollController,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: itens
              .asMap()
              .entries
              .map(
                (MapEntry<int, ProdutoModel> entry) => SizedBox(
                  width: itemWidth,
                  child: _buildCatalogGridCard(context, entry.value, entry.key),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildCatalogGridCard(
    BuildContext context,
    ProdutoModel produto,
    int index,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _ProdutoSituacaoEstoque situacaoEstoque = _situacaoEstoque(produto);
    final String codigo = produto.codigoDeBarras.trim();
    final String categoria = _categoriaOuTipoLabel(context, produto);

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('catalog-grid-${_chaveProduto(produto)}-$index'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 120 + (index % 8) * 16),
      curve: Curves.easeOutCubic,
      builder:
          (BuildContext context, double value, Widget? child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: child,
            ),
          ),
      child: _ProdutoHoverableCardSurface(
        borderRadius: 18,
        baseColor: tokens.cardBackground,
        baseBorderColor: tokens.cardBorder,
        hoverColor: tokens.surfaceMuted,
        hoverBorderColor: tokens.info.withValues(alpha: 0.22),
        onTap: () => _abrirCadastroParaEdicao(produto),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _thumbnail(context, produto, size: 60),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          produto.nomeProduto.isEmpty
                              ? context.t(
                                'produto.webList.itemWithoutName',
                                fallback: 'Item sem nome',
                              )
                              : produto.nomeProduto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: tokens.primaryText,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          categoria,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _statusPill(context, produto.ativo),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _precoFormatado(produto.precoVenda),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: tokens.primaryText,
                      ),
                    ),
                  ),
                  if (_exibirInformacoesEstoque) ...<Widget>[
                    const SizedBox(width: 12),
                    _buildQuantidadeEstoqueInfo(context, produto),
                  ],
                ],
              ),
              if (_exibirInformacoesEstoque &&
                  situacaoEstoque != _ProdutoSituacaoEstoque.emEstoque &&
                  situacaoEstoque !=
                      _ProdutoSituacaoEstoque.naoAplicavel) ...<Widget>[
                const SizedBox(height: 10),
                _buildEstoqueChip(context, situacaoEstoque),
              ],
              if (codigo.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.qr_code_2_rounded,
                        size: 16,
                        color: tokens.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          codigo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tokens.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: _actionButton(context, produto, compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogListView({
    required BuildContext context,
    required Key key,
    required List<ProdutoModel> itens,
    required double availableWidth,
  }) {
    final bool showWideColumns = availableWidth >= 1060;

    return Column(
      key: key,
      children: <Widget>[
        if (showWideColumns) _buildCatalogListHeader(context),
        Expanded(
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            thickness: 7,
            radius: const Radius.circular(999),
            child: ListView.separated(
              controller: _verticalScrollController,
              padding: EdgeInsets.fromLTRB(0, showWideColumns ? 10 : 0, 12, 2),
              itemCount: itens.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder:
                  (BuildContext context, int index) =>
                      showWideColumns
                          ? _buildCatalogListRow(context, itens[index], index)
                          : _buildCatalogGridCard(context, itens[index], index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogListHeader(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: tokens.secondaryText,
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 72),
            Expanded(
              flex: 4,
              child: Text(
                context.t('produto.webList.table.product', fallback: 'Produto'),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                context.t(
                  'produto.webList.table.category',
                  fallback: 'Categoria',
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                context.t('produto.webList.table.code', fallback: 'Código'),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                context.t('produto.webList.table.price', fallback: 'Preço'),
                textAlign: TextAlign.end,
              ),
            ),
            if (_exibirInformacoesEstoque)
              Expanded(
                flex: 2,
                child: Text(
                  context.t('workspaceHome.stock.title', fallback: 'Estoque'),
                  textAlign: TextAlign.end,
                ),
              ),
            Expanded(
              flex: 2,
              child: Text(
                context.t('atendimentoTecnico.status', fallback: 'Status'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 104),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogListRow(
    BuildContext context,
    ProdutoModel produto,
    int index,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _ProdutoSituacaoEstoque situacaoEstoque = _situacaoEstoque(produto);

    return _ProdutoHoverableCardSurface(
      borderRadius: 18,
      baseColor: tokens.cardBackground,
      baseBorderColor: tokens.cardBorder,
      hoverColor: tokens.surfaceMuted,
      hoverBorderColor: tokens.info.withValues(alpha: 0.22),
      onTap: () => _abrirCadastroParaEdicao(produto),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _thumbnail(context, produto, size: 58),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    produto.nomeProduto.isEmpty
                        ? context.t(
                          'produto.webList.itemWithoutName',
                          fallback: 'Item sem nome',
                        )
                        : produto.nomeProduto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: tokens.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tipoLabel(produto),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: tokens.secondaryText),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _categoriaOuTipoLabel(context, produto),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.secondaryText),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                produto.codigoDeBarras.trim().isEmpty
                    ? context.t('common.notInformed', fallback: 'Não informado')
                    : produto.codigoDeBarras.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _precoFormatado(produto.precoVenda),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (_exibirInformacoesEstoque)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _quantidadeEstoqueLabel(produto),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (situacaoEstoque != _ProdutoSituacaoEstoque.emEstoque &&
                        situacaoEstoque != _ProdutoSituacaoEstoque.naoAplicavel)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildEstoqueChip(
                          context,
                          situacaoEstoque,
                          compact: true,
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: _statusPill(context, produto.ativo),
              ),
            ),
            const SizedBox(width: 12),
            _actionButton(context, produto, compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogPagination(
    BuildContext context,
    _ProdutoCatalogoEdicaoSnapshot snapshot,
    bool isCompact,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<Object> pages = _pageItems(
      snapshot.paginaAtual,
      snapshot.totalPaginas,
    );
    final Widget paginationControls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _paginationArrow(
          context,
          icon: Icons.chevron_left_rounded,
          enabled: snapshot.paginaAtual > 0,
          onTap:
              () => _atualizarCatalogo(() {
                _paginaAtual = snapshot.paginaAtual - 1;
              }, resetPagination: false),
        ),
        ...pages.map(
          (Object item) => _buildPageMarker(context, item, snapshot),
        ),
        _paginationArrow(
          context,
          icon: Icons.chevron_right_rounded,
          enabled: snapshot.paginaAtual < snapshot.totalPaginas - 1,
          onTap:
              () => _atualizarCatalogo(() {
                _paginaAtual = snapshot.paginaAtual + 1;
              }, resetPagination: false),
        ),
        _buildItensPorPaginaMenu(context),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useCompactLayout =
              isCompact || constraints.maxWidth < 1220;
          if (useCompactLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _paginationSummary(context, snapshot),
                  style: TextStyle(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                paginationControls,
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _paginationSummary(context, snapshot),
                  style: TextStyle(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: paginationControls,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageMarker(
    BuildContext context,
    Object item,
    _ProdutoCatalogoEdicaoSnapshot snapshot,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    if (item is String) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          item,
          style: TextStyle(
            color: tokens.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final int page = item as int;
    final bool selected = page == snapshot.paginaAtual;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        key: ValueKey<String>('produto-web-page-${page + 1}'),
        borderRadius: BorderRadius.circular(12),
        onTap:
            selected
                ? null
                : () => _atualizarCatalogo(() {
                  _paginaAtual = page;
                }, resetPagination: false),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tokens.selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? tokens.selectedBorder : tokens.cardBorder,
            ),
          ),
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? tokens.primaryText : tokens.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _paginationArrow(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? tokens.surfaceElevated : tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? tokens.primaryText : tokens.mutedText,
        ),
      ),
    );
  }

  Widget _buildItensPorPaginaMenu(BuildContext context) {
    return _buildMenuFiltro<int>(
      context: context,
      icon: Icons.format_list_numbered_rounded,
      label: context.t(
        'produto.webList.itemsPerPageLabel',
        fallback: 'Itens por página',
      ),
      value: _itensPorPagina.toString(),
      selectedValue: _itensPorPagina,
      minWidth: 142,
      items: _opcoesItensPorPagina
          .map(
            (int value) => _ProdutoFiltroMenuOpcao<int>(
              value: value,
              label: value.toString(),
            ),
          )
          .toList(growable: false),
      onSelected: (int value) {
        _atualizarCatalogo(() {
          _itensPorPagina = value;
        });
      },
    );
  }

  List<Object> _pageItems(int paginaAtual, int totalPaginas) {
    if (totalPaginas <= 1) {
      return const <Object>[0];
    }

    if (totalPaginas <= 7) {
      return List<Object>.generate(totalPaginas, (int index) => index);
    }

    final Set<int> paginas = <int>{0, totalPaginas - 1, paginaAtual};
    if (paginaAtual - 1 > 0) paginas.add(paginaAtual - 1);
    if (paginaAtual + 1 < totalPaginas - 1) paginas.add(paginaAtual + 1);

    final List<int> ordenadas = paginas.toList()..sort();
    final List<Object> resultado = <Object>[];
    for (int index = 0; index < ordenadas.length; index++) {
      final int pagina = ordenadas[index];
      if (index > 0 && pagina - ordenadas[index - 1] > 1) {
        resultado.add('...');
      }
      resultado.add(pagina);
    }
    return resultado;
  }

  String _paginationSummary(
    BuildContext context,
    _ProdutoCatalogoEdicaoSnapshot snapshot,
  ) {
    return context
        .t(
          'produto.webList.pagination.summary',
          fallback: 'Exibindo {start} a {end} de {total} itens',
        )
        .replaceAll('{start}', snapshot.indiceInicial.toString())
        .replaceAll('{end}', snapshot.indiceFinal.toString())
        .replaceAll('{total}', snapshot.itensFiltrados.length.toString());
  }

  int _columnsForWidth(double width) {
    if (width >= 1360) return 4;
    if (width >= 1040) return 3;
    if (width >= 680) return 2;
    return 1;
  }

  List<_CategoriaFiltro> _categoriasDisponiveis() {
    final Map<String, _CategoriaFiltro> categorias =
        <String, _CategoriaFiltro>{};
    for (final ProdutoModel produto in todosProdutos) {
      final ObjCategoria? categoria = produto.objCategoria;
      if (categoria == null) continue;
      final String id = categoria.idCategoria.trim();
      final String nome = categoria.nomeCategoria.trim();
      if (id.isEmpty || nome.isEmpty) continue;
      categorias[id] = _CategoriaFiltro(id: id, nome: nome);
    }

    final List<_CategoriaFiltro> resultado = categorias.values.toList();
    resultado.sort(
      (_CategoriaFiltro a, _CategoriaFiltro b) =>
          a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
    );
    return resultado;
  }

  String _categoriaSelecionadaLabel(BuildContext context) {
    if (_categoriaSelecionadaId == null || _categoriaSelecionadaId!.isEmpty) {
      return context.t(
        'produto.webList.filter.categoryAll',
        fallback: 'Todas categorias',
      );
    }

    for (final _CategoriaFiltro categoria in _categoriasDisponiveis()) {
      if (categoria.id == _categoriaSelecionadaId) return categoria.nome;
    }

    return context.t(
      'produto.webList.filter.categoryAll',
      fallback: 'Todas categorias',
    );
  }

  String _statusFiltroLabel(BuildContext context) {
    switch (_statusFiltro) {
      case _ProdutoStatusFiltro.todos:
        return context.t('produto.webList.filter.statusAll', fallback: 'Todos');
      case _ProdutoStatusFiltro.ativos:
        return context.t('common.active', fallback: 'Ativo');
      case _ProdutoStatusFiltro.inativos:
        return context.t('common.inactive', fallback: 'Inativo');
    }
  }

  String _estoqueFiltroLabel(BuildContext context) {
    switch (_estoqueFiltro) {
      case _ProdutoEstoqueFiltro.todos:
        return context.t('produto.webList.filter.stockAll', fallback: 'Todos');
      case _ProdutoEstoqueFiltro.emEstoque:
        return context.t(
          'produto.webList.filter.stockAvailable',
          fallback: 'Em estoque',
        );
      case _ProdutoEstoqueFiltro.estoqueBaixo:
        return context.t(
          'produto.webList.filter.stockLow',
          fallback: 'Estoque baixo',
        );
      case _ProdutoEstoqueFiltro.semEstoque:
        return context.t(
          'produto.webList.filter.stockOut',
          fallback: 'Sem estoque',
        );
      case _ProdutoEstoqueFiltro.estoqueNegativo:
        return context.t(
          'produto.webList.filter.stockNegative',
          fallback: 'Estoque negativo',
        );
    }
  }

  String _marcacaoFiltroLabel(BuildContext context) {
    switch (_marcacaoFiltro) {
      case _ProdutoMarcacaoFiltro.todos:
        return context.t(
          'produto.webList.filter.flagsAll',
          fallback: 'Todos itens',
        );
      case _ProdutoMarcacaoFiltro.favoritos:
        return context.t(
          'produto.webList.filter.flagsFavorites',
          fallback: 'Favoritos',
        );
      case _ProdutoMarcacaoFiltro.catalogo:
        return context.t(
          'produto.webList.filter.flagsCatalog',
          fallback: 'No catálogo',
        );
      case _ProdutoMarcacaoFiltro.favoritosECatalogo:
        return context.t(
          'produto.webList.filter.flagsFavoritesCatalog',
          fallback: 'Favoritos e catálogo',
        );
    }
  }

  String _ordenacaoLabel(BuildContext context) {
    switch (ordenacao) {
      case 'precoAsc':
        return context.t(
          'produto.webList.sort.priceAsc',
          fallback: 'Menor preço',
        );
      case 'precoDesc':
        return context.t(
          'produto.webList.sort.priceDesc',
          fallback: 'Maior preço',
        );
      case 'nomeAsc':
      default:
        return context.t(
          'produto.webList.sort.name',
          fallback: 'Ordenar por nome',
        );
    }
  }

  String _resumoRapidoLabel(
    BuildContext context,
    _ProdutoResumoRapidoFiltro filtro,
  ) {
    switch (filtro) {
      case _ProdutoResumoRapidoFiltro.todos:
        return context.t('common.all', fallback: 'Todos');
      case _ProdutoResumoRapidoFiltro.produtos:
        return context.t(
          'web.navigation.catalog.products',
          fallback: 'Produtos',
        );
      case _ProdutoResumoRapidoFiltro.servicos:
        return context.t(
          'web.navigation.catalog.services',
          fallback: 'Serviços',
        );
      case _ProdutoResumoRapidoFiltro.comImagem:
        return context.t(
          'produto.webList.quick.withImage',
          fallback: 'Com imagem',
        );
      case _ProdutoResumoRapidoFiltro.estoqueBaixo:
        return context.t(
          'produto.webList.quick.lowStock',
          fallback: 'Estoque baixo',
        );
    }
  }

  String _categoriaOuTipoLabel(BuildContext context, ProdutoModel produto) {
    final String categoria = produto.objCategoria?.nomeCategoria.trim() ?? '';
    if (categoria.isNotEmpty) return categoria;
    return _tipoLabel(produto);
  }

  double _quantidadeEstoque(ProdutoModel produto) {
    if (_isServico(produto)) return 0;
    final List<ObjEntradaSaidaProduto>? movimentacoes =
        produto.objEntradaSaidaProduto;
    if (movimentacoes == null || movimentacoes.isEmpty) return 0;
    return movimentacoes.fold<double>(
      0,
      (double total, ObjEntradaSaidaProduto item) => total + item.quantidade,
    );
  }

  _ProdutoSituacaoEstoque _situacaoEstoque(ProdutoModel produto) {
    if (_isServico(produto)) {
      return _ProdutoSituacaoEstoque.naoAplicavel;
    }

    final double quantidade = _quantidadeEstoque(produto);
    if (quantidade < 0) return _ProdutoSituacaoEstoque.estoqueNegativo;
    if (quantidade == 0) return _ProdutoSituacaoEstoque.semEstoque;
    if (produto.estoqueMinimo > 0 &&
        quantidade <= produto.estoqueMinimo.toDouble()) {
      return _ProdutoSituacaoEstoque.estoqueBaixo;
    }
    return _ProdutoSituacaoEstoque.emEstoque;
  }

  Widget _buildQuantidadeEstoqueInfo(
    BuildContext context,
    ProdutoModel produto,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Text(
      _quantidadeEstoqueLabel(produto),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: tokens.secondaryText,
      ),
    );
  }

  String _quantidadeEstoqueLabel(ProdutoModel produto) {
    if (_isServico(produto)) {
      return context.t(
        'produto.webList.stockNotApplicable',
        fallback: 'Sem controle',
      );
    }
    return context
        .t('produto.webList.stockQuantity', fallback: 'Qtd {value}')
        .replaceAll(
          '{value}',
          _formatarQuantidade(_quantidadeEstoque(produto)),
        );
  }

  Widget _buildEstoqueChip(
    BuildContext context,
    _ProdutoSituacaoEstoque situacao, {
    bool compact = false,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color color = switch (situacao) {
      _ProdutoSituacaoEstoque.estoqueBaixo => tokens.stockWarning,
      _ProdutoSituacaoEstoque.semEstoque => tokens.warning,
      _ProdutoSituacaoEstoque.estoqueNegativo => tokens.stockCritical,
      _ => tokens.secondaryText,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        _situacaoEstoqueLabel(context, situacao),
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  String _situacaoEstoqueLabel(
    BuildContext context,
    _ProdutoSituacaoEstoque situacao,
  ) {
    switch (situacao) {
      case _ProdutoSituacaoEstoque.estoqueBaixo:
        return context.t('produto.webList.stockLow', fallback: 'Estoque baixo');
      case _ProdutoSituacaoEstoque.semEstoque:
        return context.t('produto.webList.stockOut', fallback: 'Sem estoque');
      case _ProdutoSituacaoEstoque.estoqueNegativo:
        return context.t(
          'produto.webList.stockNegative',
          fallback: 'Estoque negativo',
        );
      case _ProdutoSituacaoEstoque.emEstoque:
        return context.t(
          'produto.webList.filter.stockAvailable',
          fallback: 'Em estoque',
        );
      case _ProdutoSituacaoEstoque.naoAplicavel:
        return context.t(
          'produto.webList.stockNotApplicable',
          fallback: 'Sem controle',
        );
    }
  }

  String _formatarQuantidade(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return context.read<LocaleSettingsProvider>().formatDecimal(value);
  }

  Widget _buildList(
    BuildContext context,
    ProdutosListProvider<ProdutoModel> provider,
    List<ProdutoModel> itens,
  ) {
    if (provider.isLoading && itens.isEmpty) return _loadingList(context);
    if (itens.isEmpty) return _emptyState(context);

    if (_usarGrade) {
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
                _usarGrade ? 10 * (1 - value) : 0,
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
    final String editarQuantidadeTooltip = context.t(
      'pdv.quantityEditor.tooltip',
      fallback: 'Editar quantidade',
    );

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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Tooltip(
                    message: editarQuantidadeTooltip,
                    child: Semantics(
                      button: true,
                      label: '$editarQuantidadeTooltip: $quantidade',
                      child: Material(
                        color: tokens.surfaceElevated,
                        borderRadius: BorderRadius.circular(11),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap:
                              () => _abrirEditorQuantidadeSelecionada(produto),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 54),
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: tokens.selectedBorder.withValues(
                                  alpha: 0.92,
                                ),
                              ),
                            ),
                            child: Text(
                              '$quantidade',
                              style: TextStyle(
                                color: tokens.primaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
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
                  if (_exibirInformacoesEstoque) ...<Widget>[
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
    final ProdutoImagemModel? image = _primeiraImagem(produto);
    final Widget child =
        image == null
            ? Icon(
              _iconePorTipo(produto),
              color: accent,
              size: size <= 46 ? 21 : 24,
            )
            : _thumbnailImageContent(
              produto: produto,
              image: image,
              size: size,
              accent: accent,
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

  Widget _thumbnailImageContent({
    required ProdutoModel produto,
    required ProdutoImagemModel image,
    required double size,
    required Color accent,
  }) {
    final Widget fallback = Icon(
      _iconePorTipo(produto),
      color: accent,
      size: size <= 46 ? 21 : 24,
    );

    return ProdutoWebImage(
      image: image,
      fit: BoxFit.cover,
      preferThumbnail: true,
      loadingSize: size <= 46 ? 16 : 18,
      fallback: fallback,
    );
  }

  Widget _actionButton(
    BuildContext context,
    ProdutoModel produto, {
    bool compact = false,
  }) {
    final OutlinedBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return OutlinedButton.icon(
      onPressed:
          () =>
              widget.modoEdicao
                  ? _abrirCadastroParaEdicao(produto)
                  : _selecionarProduto(produto),
      icon: Icon(
        widget.modoEdicao ? Icons.edit_rounded : Icons.visibility_outlined,
        size: 17,
      ),
      label: Text(
        widget.modoEdicao
            ? context.t('common.edit', fallback: 'Editar')
            : context.t('produto.webList.viewAction', fallback: 'Ver'),
      ),
      style: _catalogOutlinedButtonStyle(
        context,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 11 : 13,
        ),
        shape: shape,
        emphasis: true,
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

  ProdutoImagemModel? _primeiraImagem(ProdutoModel produto) {
    final imagens = produto.imagens;
    if (imagens == null || imagens.isEmpty) return null;

    for (final ProdutoImagemModel imagem in imagens) {
      if (ProdutoWebImageResolver.hasLocalDataSource(imagem)) return imagem;
    }

    for (final ProdutoImagemModel imagem in imagens) {
      if (_hasImageContent(imagem)) return imagem;
    }
    return null;
  }

  bool _hasImageContent(ProdutoImagemModel image) {
    return ProdutoWebImageResolver.hasRenderableSource(
      image,
      preferThumbnail: true,
    );
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

  bool _matchesMarcacaoFiltro(ProdutoModel produto) {
    switch (_marcacaoFiltro) {
      case _ProdutoMarcacaoFiltro.todos:
        return true;
      case _ProdutoMarcacaoFiltro.favoritos:
        return produto.favorito;
      case _ProdutoMarcacaoFiltro.catalogo:
        return produto.disponivelParaCatalogo;
      case _ProdutoMarcacaoFiltro.favoritosECatalogo:
        return produto.favorito && produto.disponivelParaCatalogo;
    }
  }

  IconData _iconePorTipo(ProdutoModel produto) {
    return _isServico(produto)
        ? Icons.design_services_outlined
        : Icons.shopping_bag_outlined;
  }

  String _tipoLabel(ProdutoModel produto) {
    return _isServico(produto)
        ? context.t('web.navigation.catalog.services', fallback: 'Serviço')
        : context.t('web.navigation.catalog.products', fallback: 'Produto');
  }

  String _grupoLabel(ProdutoModel produto) {
    final grupo = produto.objAgrupamento?.grupoDoProduto.trim() ?? '';
    if (grupo.isEmpty || grupo.toLowerCase() == 'sem grupo') return '';
    return grupo;
  }

  String _codigoLabel(ProdutoModel produto) {
    final codigo = produto.codigoDeBarras.trim();
    return codigo.isEmpty
        ? context.t('produto.webList.codeUnavailable', fallback: 'Sem código')
        : codigo;
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
    return context.read<LocaleSettingsProvider>().formatCurrency(valor);
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

class _ProdutoFiltroMenu<T> extends StatefulWidget {
  const _ProdutoFiltroMenu({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final String value;
  final T selectedValue;
  final List<_ProdutoFiltroMenuOpcao<T>> items;
  final ValueChanged<T> onSelected;

  @override
  State<_ProdutoFiltroMenu<T>> createState() => _ProdutoFiltroMenuState<T>();
}

class _ProdutoFiltroMenuState<T> extends State<_ProdutoFiltroMenu<T>> {
  bool _hovered = false;
  bool _open = false;

  Future<void> _openMenu() async {
    if (widget.items.isEmpty) return;

    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size fieldSize = fieldBox.size;
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    setState(() => _open = true);
    final T? selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        fieldOffset.dx,
        fieldOffset.dy + fieldSize.height + 6,
        overlayBox.size.width - fieldOffset.dx - fieldSize.width,
        0,
      ),
      color: tokens.menuBackground,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      items: widget.items
          .map((_ProdutoFiltroMenuOpcao<T> option) {
            final bool selected = option.value == widget.selectedValue;
            final ThemeData theme = Theme.of(context);

            return PopupMenuItem<T>(
              value: option.value,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: selected ? tokens.info : tokens.mutedText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.primaryText,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.selectedValue) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = _hovered || _open;

    return Semantics(
      button: true,
      label: widget.label,
      value: widget.value,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _openMenu,
              child: AnimatedContainer(
                duration: WebThemeTokens.transitionDuration,
                curve: WebThemeTokens.transitionCurve,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: active ? tokens.surfaceMuted : tokens.inputBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active ? tokens.selectedBorder : tokens.cardBorder,
                    width: active ? 1.4 : 1,
                  ),
                  boxShadow:
                      active
                          ? <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(widget.icon, size: 18, color: tokens.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: tokens.secondaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: WebThemeTokens.transitionDuration,
                      curve: WebThemeTokens.transitionCurve,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: active ? tokens.info : tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProdutoHoverableCardSurface extends StatefulWidget {
  const _ProdutoHoverableCardSurface({
    required this.child,
    required this.onTap,
    required this.baseColor,
    required this.baseBorderColor,
    required this.hoverColor,
    required this.hoverBorderColor,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color baseColor;
  final Color baseBorderColor;
  final Color hoverColor;
  final Color hoverBorderColor;
  final double borderRadius;

  @override
  State<_ProdutoHoverableCardSurface> createState() =>
      _ProdutoHoverableCardSurfaceState();
}

class _ProdutoHoverableCardSurfaceState
    extends State<_ProdutoHoverableCardSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onTap: widget.onTap,
        onHover: (bool value) {
          if (_hovered == value) return;
          setState(() => _hovered = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : widget.baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color:
                  _hovered ? widget.hoverBorderColor : widget.baseBorderColor,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.14 : 0.04),
                blurRadius: _hovered ? 16 : 12,
                offset: Offset(0, _hovered ? 7 : 5),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
