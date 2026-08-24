// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/services/http_client_factory.dart';
import 'package:sixpos/core/utils/produto_cadastro_form_utils.dart';
import 'package:sixpos/data/models/imagem_sugestao_model.dart';
import 'package:sixpos/data/models/produto_imagem_model.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/services/imagem_sugestao/imagem_sugestao_api_client.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/domain/services/produto/produto_quick_update_service.dart';
import 'package:sixpos/presentation/components/imagem_sugestoes_section.dart';
import 'package:sixpos/presentation/components/produto_web_image.dart';
import 'package:sixpos/presentation/components/six_top_notice.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'l10n/six_i18n.dart';

class SubPainelCadastroProduto extends StatelessWidget {
  const SubPainelCadastroProduto({
    super.key,
    required this.body,
    required this.textoDaAppBar,
  });

  final Widget body;
  final String textoDaAppBar;

  void _fecharSubPainel(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ColorScheme modalColorScheme = theme.colorScheme.copyWith(
      primary: tokens.info,
      secondary: tokens.info,
      surface: tokens.surfaceElevated,
      surfaceContainer: tokens.surface,
      surfaceContainerHigh: tokens.cardBackground,
      surfaceContainerHighest: tokens.surfaceMuted,
      onSurface: tokens.primaryText,
      onSurfaceVariant: tokens.secondaryText,
      outline: tokens.cardBorder,
      outlineVariant: tokens.cardBorder,
      error: tokens.danger,
    );
    final ThemeData modalTheme = theme.copyWith(
      colorScheme: modalColorScheme,
      scaffoldBackgroundColor: tokens.surfaceElevated,
      canvasColor: tokens.surfaceElevated,
      cardColor: tokens.cardBackground,
      dialogTheme: theme.dialogTheme.copyWith(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: tokens.inputBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.info, width: 1.4),
        ),
      ),
    );
    final Size size = MediaQuery.of(context).size;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _fecharSubPainel(context),
      },
      child: Focus(
        autofocus: true,
        child: Center(
          child: Container(
            width: size.width * 0.9,
            height: size.height * 0.9,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: tokens.cardBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Theme(
              data: modalTheme,
              child: Material(color: tokens.surfaceElevated, child: body),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> showSubPainelCadastroProduto(
  BuildContext context,
  String textoDaAppBar, {
  ProdutoModel? produtoParaEdicao,
  bool modoEdicao = false,
}) {
  final WebThemeTokens tokens = WebThemeTokens.of(context);
  final double barrierAlpha = Theme.of(context).brightness == Brightness.dark
      ? 0.70
      : 0.42;
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: tokens.workspaceBackground.withValues(alpha: barrierAlpha),
    builder: (BuildContext dialogContext) {
      return SubPainelCadastroProduto(
        textoDaAppBar: textoDaAppBar,
        body: CadastroProdutoWebBody(
          produtoParaEdicao: produtoParaEdicao,
          modoEdicao: modoEdicao,
        ),
      );
    },
  );
}

class CadastroProdutoWebBody extends StatefulWidget {
  const CadastroProdutoWebBody({
    super.key,
    this.produtoParaEdicao,
    this.modoEdicao = false,
    this.produtoService,
    this.imagemSugestaoApiClient,
    this.categoriaApiClient,
  });

  final ProdutoModel? produtoParaEdicao;
  final bool modoEdicao;
  final ProdutoService? produtoService;
  final ImagemSugestaoApiClient? imagemSugestaoApiClient;
  final CategoriaCatalogoApiClient? categoriaApiClient;

  @override
  State<CadastroProdutoWebBody> createState() => _CadastroProdutoWebBodyState();
}

class _ProdutoImagemSlot {
  _ProdutoImagemSlot();

  ProdutoImagemModel? image;
  Uint8List? previewBytes;
  bool isLoading = false;

  void reset() {
    image = null;
    previewBytes = null;
    isLoading = false;
  }
}

class _CadastroProdutoWebBodyState extends State<CadastroProdutoWebBody> {
  static const String _categoriaSemCategoriaMenuId = '__sem_categoria__';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final ProdutoService _produtoService =
      widget.produtoService ?? ProdutoService();
  late final ProdutoQuickUpdateService _produtoQuickUpdateService =
      ProdutoQuickUpdateService(produtoService: _produtoService);
  late final ImagemSugestaoApiClient _imagemSugestaoApiClient =
      widget.imagemSugestaoApiClient ?? HttpImagemSugestaoApiClient();
  late final CategoriaCatalogoApiClient _categoriaApiClient =
      widget.categoriaApiClient ?? HttpCategoriaCatalogoApiClient();

  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _nomeProdutoController = TextEditingController();
  final TextEditingController _grupoProdutoController = TextEditingController();
  final TextEditingController _tempoGarantiaController =
      TextEditingController();
  final TextEditingController _modeloProdutoController = TextEditingController(
    text: ProdutoCadastroFormUtils.modeloPadrao,
  );
  final TextEditingController _estoqueMaximoController = TextEditingController(
    text: '1000',
  );
  final TextEditingController _estoqueMinimoController = TextEditingController(
    text: '1',
  );
  final TextEditingController _precoVendaController = TextEditingController();
  final TextEditingController _valorComissaoController = TextEditingController(
    text: '0',
  );
  final TextEditingController _quantidadeEntradaController =
      TextEditingController(text: '1');
  final TextEditingController _valorCustoController = TextEditingController(
    text: '0',
  );
  final TextEditingController _valorVendaEntradaController =
      TextEditingController(text: '0');
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _codigoInternoController =
      TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _fabricanteController = TextEditingController();
  final TextEditingController _unidadeMedidaController = TextEditingController(
    text: 'UN',
  );
  final TextEditingController _quantidadeMinimaVendaController =
      TextEditingController();
  final TextEditingController _ncmController = TextEditingController();
  final TextEditingController _cestController = TextEditingController();
  final TextEditingController _cfopController = TextEditingController();
  final TextEditingController _origemMercadoriaController =
      TextEditingController();
  final TextEditingController _cstIcmsController = TextEditingController();
  final TextEditingController _csosnController = TextEditingController();
  final TextEditingController _cstPisController = TextEditingController();
  final TextEditingController _cstCofinsController = TextEditingController();

  bool _ativo = true;
  bool _favorito = false;
  bool _disponivelParaCatalogo = false;
  bool _favoritoAtualizando = false;
  bool _catalogoAtualizando = false;
  bool _podeAlterarValorNaHora = false;
  bool _produtoTemComissaoEspecial = false;
  bool _isLoading = false;
  String _tipoCadastro = 'RESUMIDO';
  int _etapaAtual = 0;
  String _categoriaUnidadeMedida = 'UNIDADE';
  bool _controlaEstoque = true;
  bool _permiteVendaFracionada = false;
  bool _permiteEstoqueNegativo = false;
  String _tipoSelecionado = ProdutoCadastroFormUtils.tipoProduto;
  List<CategoriaCatalogoModel> _categoriasCatalogo =
      const <CategoriaCatalogoModel>[];
  bool _carregandoCategorias = false;
  String? _erroCategorias;
  String? _categoriaSelecionadaId;
  String? _categoriaSelecionadaNome;

  static const int _maxImageSlots = 5;
  final List<_ProdutoImagemSlot> _imagemSlots =
      List<_ProdutoImagemSlot>.generate(
        _maxImageSlots,
        (_) => _ProdutoImagemSlot(),
        growable: false,
      );

  bool _isSugestoesLoading = false;
  bool _jaBuscouSugestoes = false;
  String? _erroSugestoes;
  List<ImagemSugestao> _imagensSugeridas = const <ImagemSugestao>[];
  Timer? _debounceSugestoesTimer;
  http.Client? _sugestoesHttpClient;
  int _sugestoesRequestId = 0;
  String? _produtoEmEdicaoId;
  int _slotSelecionadoIndex = 0;

  int get _totalImagensSelecionadas =>
      _imagemSlots.where((slot) => slot.image != null).length;

  List<ProdutoImagemModel> get _imagensParaEnvio => _imagemSlots
      .map((slot) => slot.image)
      .whereType<ProdutoImagemModel>()
      .toList(growable: false);

  Set<int> get _sugestoesAplicadasIds => _imagemSlots
      .map((slot) => slot.image?.sugestaoId)
      .whereType<int>()
      .toSet();

  int get _indicePrimeiroSlotLivre =>
      _imagemSlots.indexWhere((slot) => slot.image == null);

  bool get _temSlotLivre => _indicePrimeiroSlotLivre != -1;

  _ProdutoImagemSlot get _slotSelecionado =>
      _imagemSlots[_slotSelecionadoIndex];

  bool get _isModoEdicao =>
      widget.modoEdicao && widget.produtoParaEdicao != null;

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  ProdutoCadastroNumberFormat _numberFormat() {
    final localeSettings = context.read<LocaleSettingsProvider>();
    return ProdutoCadastroNumberFormat(
      decimalSeparator: localeSettings.decimalSeparator,
      thousandSeparator: localeSettings.thousandSeparator,
    );
  }

  String _decimalInputHint({int decimalPlaces = 2}) {
    final decimalSeparator = context
        .read<LocaleSettingsProvider>()
        .decimalSeparator;
    return '0$decimalSeparator${'0' * decimalPlaces}';
  }

  String _tipoLabel(String tipo) {
    return ProdutoCadastroFormUtils.normalizarTipo(tipo) ==
            ProdutoCadastroFormUtils.tipoServico
        ? _t('produto.web.typeService', 'Serviço')
        : _t('produto.web.typeProduct', 'Produto');
  }

  String _categoriaDisplayName(CategoriaCatalogoModel categoria) {
    if (categoria.ativo) return categoria.nome;
    return '${categoria.nome} (${_t('common.inactive', 'Inativa')})';
  }

  @override
  void initState() {
    super.initState();
    _preencherCamposSeModoEdicao();
    _carregarCategoriasCatalogo();
    _nomeProdutoController.addListener(_onCamposSugestoesAlterados);
    _grupoProdutoController.addListener(_onCamposSugestoesAlterados);
    _tempoGarantiaController.addListener(_onCamposSugestoesAlterados);
    if (_camposMinimosParaSugestao) {
      _onCamposSugestoesAlterados();
    }
  }

  @override
  void dispose() {
    _debounceSugestoesTimer?.cancel();
    _sugestoesHttpClient?.close();
    _nomeProdutoController.removeListener(_onCamposSugestoesAlterados);
    _grupoProdutoController.removeListener(_onCamposSugestoesAlterados);
    _tempoGarantiaController.removeListener(_onCamposSugestoesAlterados);
    _codigoBarrasController.dispose();
    _nomeProdutoController.dispose();
    _grupoProdutoController.dispose();
    _tempoGarantiaController.dispose();
    _modeloProdutoController.dispose();
    _estoqueMaximoController.dispose();
    _estoqueMinimoController.dispose();
    _precoVendaController.dispose();
    _valorComissaoController.dispose();
    _quantidadeEntradaController.dispose();
    _valorCustoController.dispose();
    _valorVendaEntradaController.dispose();
    _descricaoController.dispose();
    _codigoInternoController.dispose();
    _marcaController.dispose();
    _fabricanteController.dispose();
    _unidadeMedidaController.dispose();
    _quantidadeMinimaVendaController.dispose();
    _ncmController.dispose();
    _cestController.dispose();
    _cfopController.dispose();
    _origemMercadoriaController.dispose();
    _cstIcmsController.dispose();
    _csosnController.dispose();
    _cstPisController.dispose();
    _cstCofinsController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(context, label, hintText: hintText),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return _t('common.required', 'Campo obrigatório');
              }
              return null;
            }
          : null,
    );
  }

  bool get _camposMinimosParaSugestao {
    return _nomeProdutoController.text.trim().isNotEmpty &&
        (_tipoSelecionado == ProdutoCadastroFormUtils.tipoProduto ||
            _tipoSelecionado == ProdutoCadastroFormUtils.tipoServico);
  }

  void _onCamposSugestoesAlterados() {
    _debounceSugestoesTimer?.cancel();

    if (!_camposMinimosParaSugestao) {
      _sugestoesRequestId++;
      _sugestoesHttpClient?.close();
      _sugestoesHttpClient = null;
      setState(() {
        _isSugestoesLoading = false;
        _jaBuscouSugestoes = false;
        _erroSugestoes = null;
        _imagensSugeridas = const <ImagemSugestao>[];
      });
      return;
    }

    _debounceSugestoesTimer = Timer(
      const Duration(milliseconds: 600),
      () => _buscarSugestoesImagem(),
    );
  }

  ImagemSugestaoRequest? _montarRequisicaoSugestao() {
    if (!_camposMinimosParaSugestao) {
      return null;
    }

    final String descricao = <String>[
      _tempoGarantiaController.text.trim(),
      _modeloProdutoController.text.trim(),
      _grupoProdutoController.text.trim(),
    ].where((String value) => value.isNotEmpty).join(' | ');

    return ImagemSugestaoRequest(
      titulo: _nomeProdutoController.text.trim(),
      descricao: descricao,
      categoria:
          _categoriaSelecionadaNome ?? _grupoProdutoController.text.trim(),
      tipo: _tipoSelecionado == ProdutoCadastroFormUtils.tipoServico
          ? 'servico'
          : 'produto',
      quantidade: 6,
    );
  }

  Future<void> _buscarSugestoesImagem({bool manual = false}) async {
    final ImagemSugestaoRequest? request = _montarRequisicaoSugestao();
    if (request == null) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preencha título e tipo para gerar sugestões.'),
          ),
        );
      }
      return;
    }

    final int requestId = ++_sugestoesRequestId;

    _sugestoesHttpClient?.close();
    final http.Client currentClient = createHttpClient();
    _sugestoesHttpClient = currentClient;

    setState(() {
      _isSugestoesLoading = true;
      _jaBuscouSugestoes = true;
      _erroSugestoes = null;
    });

    try {
      final ImagemSugestaoResponse response = await _imagemSugestaoApiClient
          .buscarSugestoes(request, httpClient: currentClient);

      if (!mounted || requestId != _sugestoesRequestId) {
        return;
      }

      setState(() {
        _imagensSugeridas = response.imagens;
        _isSugestoesLoading = false;
      });
    } on ImagemSugestaoApiException catch (e) {
      if (!mounted || requestId != _sugestoesRequestId) {
        return;
      }
      setState(() {
        _isSugestoesLoading = false;
        _imagensSugeridas = const <ImagemSugestao>[];
        _erroSugestoes =
            'Não foi possível gerar sugestões no momento (HTTP ${e.statusCode}).';
      });
    } catch (_) {
      if (!mounted || requestId != _sugestoesRequestId) {
        return;
      }
      setState(() {
        _isSugestoesLoading = false;
        _imagensSugeridas = const <ImagemSugestao>[];
        _erroSugestoes = 'Falha ao gerar sugestões. Tente novamente.';
      });
    } finally {
      if (_sugestoesHttpClient == currentClient) {
        _sugestoesHttpClient = null;
      }
      currentClient.close();
    }
  }

  void _aplicarSugestaoEmSlot(ImagemSugestao sugestao) {
    if (!_temSlotLivre && _slotSelecionado.image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você já atingiu o limite de 5 imagens. Remova uma para adicionar outra.',
          ),
        ),
      );
      return;
    }

    final bool slotAtivoLivre = _slotSelecionado.image == null;
    final int slotIndex = slotAtivoLivre
        ? _slotSelecionadoIndex
        : _indicePrimeiroSlotLivre;
    setState(() {
      final slot = _imagemSlots[slotIndex];
      slot.image = ProdutoImagemModel(
        origem: 'SUGESTAO',
        nomeArquivo: 'Sugestão por IA',
        url: sugestao.urlAlta,
        urlMiniatura: sugestao.urlMiniatura,
        sugestaoId: sugestao.id,
      );
      slot.previewBytes = null;
      _slotSelecionadoIndex = slotIndex;
    });
  }

  void _preencherCamposSeModoEdicao() {
    if (!_isModoEdicao) {
      return;
    }

    final ProdutoModel produto = widget.produtoParaEdicao!;
    _produtoEmEdicaoId = produto.id;
    _codigoBarrasController.text = produto.codigoDeBarras;
    _nomeProdutoController.text = produto.nomeProduto;
    _tipoSelecionado = ProdutoCadastroFormUtils.normalizarTipo(
      produto.tipoProduto,
    );
    _grupoProdutoController.text = produto.objAgrupamento?.grupoDoProduto ?? '';
    _categoriaSelecionadaId = produto.objCategoria?.idCategoria;
    _categoriaSelecionadaNome = produto.objCategoria?.nomeCategoria;
    _modeloProdutoController.text = produto.modeloProduto.trim().isEmpty
        ? ProdutoCadastroFormUtils.modeloPadrao
        : produto.modeloProduto;
    _estoqueMaximoController.text = produto.estoqueMaximo.toString();
    _estoqueMinimoController.text = produto.estoqueMinimo.toString();
    _precoVendaController.text = produto.precoVenda.toString();
    _valorComissaoController.text = produto
        .objComissao
        .valorFixoDeComissaoParaEsseProduto
        .toString();
    _produtoTemComissaoEspecial =
        produto.objComissao.produtoTemComissaoEspecial;
    _ativo = produto.ativo;
    _favorito = produto.favorito;
    _disponivelParaCatalogo = produto.disponivelParaCatalogo;
    _tipoCadastro = produto.tipoCadastro.toUpperCase() == 'COMPLETO'
        ? 'COMPLETO'
        : 'RESUMIDO';

    if (produto.objetoServico != null) {
      _tempoGarantiaController.text = produto.objetoServico!.tempoDaGarantia;
      _podeAlterarValorNaHora = produto.objetoServico!.podeAlterarOValorNaHora;
    }

    if (produto.objEntradaSaidaProduto != null &&
        produto.objEntradaSaidaProduto!.isNotEmpty) {
      final ObjEntradaSaidaProduto entrada =
          produto.objEntradaSaidaProduto!.first;
      _quantidadeEntradaController.text = entrada.quantidade.toString();
      _valorCustoController.text = entrada.valorCusto.toString();
      _valorVendaEntradaController.text = entrada.valorDaVenda.toString();
    }

    final ProdutoDetalhesModel? detalhes = produto.detalhes;
    _descricaoController.text = detalhes?.descricao ?? '';
    _codigoInternoController.text = detalhes?.codigoInterno ?? '';
    _marcaController.text = detalhes?.marca ?? '';
    _fabricanteController.text = detalhes?.fabricante ?? '';

    final ProdutoRegrasOperacionaisModel? regras = produto.regrasOperacionais;
    _categoriaUnidadeMedida = regras?.categoriaUnidadeMedida ?? 'UNIDADE';
    _unidadeMedidaController.text = regras?.unidadeMedida ?? 'UN';
    _controlaEstoque = regras?.controlaEstoque ?? true;
    _permiteVendaFracionada = regras?.permiteVendaFracionada ?? false;
    _permiteEstoqueNegativo = regras?.permiteEstoqueNegativo ?? false;
    _quantidadeMinimaVendaController.text =
        regras == null || regras.quantidadeMinimaVenda == 0
        ? ''
        : regras.quantidadeMinimaVenda.toString();

    final ProdutoDadosFiscaisModel? fiscais = produto.dadosFiscais;
    _ncmController.text = fiscais?.ncm ?? '';
    _cestController.text = fiscais?.cest ?? '';
    _cfopController.text = fiscais?.cfop ?? '';
    _origemMercadoriaController.text = fiscais?.origemMercadoria ?? '';
    _cstIcmsController.text = fiscais?.cstIcms ?? '';
    _csosnController.text = fiscais?.csosn ?? '';
    _cstPisController.text = fiscais?.cstPis ?? '';
    _cstCofinsController.text = fiscais?.cstCofins ?? '';

    for (final slot in _imagemSlots) {
      slot.reset();
    }

    final List<ProdutoImagemModel> imagensDoProduto =
        produto.imagens ?? const <ProdutoImagemModel>[];

    for (
      int i = 0;
      i < imagensDoProduto.length && i < _imagemSlots.length;
      i++
    ) {
      _imagemSlots[i].image = imagensDoProduto[i];
    }
  }

  Future<void> _carregarCategoriasCatalogo() async {
    setState(() {
      _carregandoCategorias = true;
      _erroCategorias = null;
    });

    try {
      final CategoriaCatalogoListResponse response = await _categoriaApiClient
          .listarCategorias();

      if (!mounted) return;

      setState(() {
        _categoriasCatalogo = response.categorias;
        _carregandoCategorias = false;
        _validarCategoriaSelecionadaComTipoAtual();
        _sincronizarNomeCategoriaSelecionada();
      });
    } on CategoriaCatalogoApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _carregandoCategorias = false;
        _erroCategorias =
            '${_t('produto.web.categoryLoadHttpError', 'Erro ao carregar categorias')} '
            '(HTTP ${error.statusCode}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoCategorias = false;
        _erroCategorias = _t(
          'produto.web.categoryLoadError',
          'Não foi possível carregar categorias.',
        );
      });
    }
  }

  void _sincronizarNomeCategoriaSelecionada() {
    final CategoriaCatalogoModel? categoria = _categoriaSelecionadaEncontrada;
    if (categoria != null) {
      _categoriaSelecionadaNome = categoria.nome;
    }
  }

  CategoriaCatalogoModel? get _categoriaSelecionadaEncontrada {
    return ProdutoCadastroFormUtils.encontrarCategoriaPorId(
      _categoriasCatalogo,
      _categoriaSelecionadaId,
    );
  }

  List<CategoriaCatalogoModel> get _categoriasCompativeis {
    return _categoriasCatalogo
        .where(
          (CategoriaCatalogoModel categoria) =>
              categoria.ativo || categoria.id == _categoriaSelecionadaId,
        )
        .where(_categoriaCompativelComTipoAtual)
        .toList(growable: false);
  }

  bool _categoriaCompativelComTipoAtual(CategoriaCatalogoModel categoria) {
    return ProdutoCadastroFormUtils.categoriaCompativelComTipo(
      categoria,
      _tipoSelecionado,
    );
  }

  void _validarCategoriaSelecionadaComTipoAtual() {
    final String? id = _categoriaSelecionadaId;
    if (id == null || id.trim().isEmpty) {
      return;
    }

    final CategoriaCatalogoModel? categoria = _categoriaSelecionadaEncontrada;
    if (categoria == null && _categoriasCatalogo.isNotEmpty) {
      _categoriaSelecionadaId = null;
      _categoriaSelecionadaNome = null;
      return;
    }

    if (categoria != null && !_categoriaCompativelComTipoAtual(categoria)) {
      _categoriaSelecionadaId = null;
      _categoriaSelecionadaNome = null;
    }
  }

  Widget _buildTipoDropdown(BuildContext context, double width) {
    final String label = _t('produto.web.typeLabel', 'Tipo');

    return SizedBox(
      width: width,
      child: _SixWebDropdownField(
        label: label,
        value: _tipoSelecionado,
        icon: Icons.inventory_2_outlined,
        tooltip: '${_t('common.select', 'Selecionar')} $label',
        options: <_SixWebDropdownOption>[
          _SixWebDropdownOption(
            value: ProdutoCadastroFormUtils.tipoProduto,
            label: _t('produto.web.typeProduct', 'Produto'),
            icon: Icons.inventory_2_outlined,
          ),
          _SixWebDropdownOption(
            value: ProdutoCadastroFormUtils.tipoServico,
            label: _t('produto.web.typeService', 'Serviço'),
            icon: Icons.handyman_outlined,
          ),
        ],
        onSelected: (String value) {
          setState(() {
            _tipoSelecionado = ProdutoCadastroFormUtils.normalizarTipo(value);
            _validarCategoriaSelecionadaComTipoAtual();
          });
          _onCamposSugestoesAlterados();
        },
      ),
    );
  }

  Widget _buildCategoriaDropdown(BuildContext context, double width) {
    final List<CategoriaCatalogoModel> categorias = _categoriasCompativeis;
    final bool categoriaSelecionadaExiste = categorias.any(
      (CategoriaCatalogoModel categoria) =>
          categoria.id == _categoriaSelecionadaId,
    );
    final String? valor = categoriaSelecionadaExiste
        ? _categoriaSelecionadaId
        : null;
    final String label = _t('produto.web.categoryLabel', 'Categoria');

    return SizedBox(
      width: width,
      child: _SixWebDropdownField(
        label: label,
        value: valor ?? _categoriaSemCategoriaMenuId,
        icon: Icons.category_outlined,
        enabled: !_carregandoCategorias,
        placeholder: _carregandoCategorias
            ? _t('common.loading', 'Carregando...')
            : _t('produto.web.categoryHint', 'Selecione uma categoria'),
        showPlaceholder: _carregandoCategorias,
        errorText: _carregandoCategorias ? null : _erroCategorias,
        tooltip: '${_t('common.select', 'Selecionar')} $label',
        options: <_SixWebDropdownOption>[
          _SixWebDropdownOption(
            value: _categoriaSemCategoriaMenuId,
            label: _t('produto.web.categoryNone', 'Sem categoria'),
            icon: Icons.remove_circle_outline_rounded,
          ),
          ...categorias.map(
            (CategoriaCatalogoModel categoria) => _SixWebDropdownOption(
              value: categoria.id,
              label: _categoriaDisplayName(categoria),
              icon: categoria.ativo
                  ? Icons.label_outline_rounded
                  : Icons.visibility_off_outlined,
            ),
          ),
        ],
        onSelected: (String selectedValue) {
          final String? value = selectedValue == _categoriaSemCategoriaMenuId
              ? null
              : selectedValue;
          setState(() {
            _categoriaSelecionadaId = value;
            final CategoriaCatalogoModel? categoria =
                _categoriaSelecionadaEncontrada;
            _categoriaSelecionadaNome = categoria?.nome;
          });
          _onCamposSugestoesAlterados();
        },
      ),
    );
  }

  ProdutoModel _montarProduto() {
    return ProdutoCadastroFormUtils.montarProduto(
      ProdutoCadastroFormData(
        id: _produtoEmEdicaoId,
        ativo: _ativo,
        favorito: _favorito,
        disponivelParaCatalogo: _disponivelParaCatalogo,
        codigoDeBarras: _codigoBarrasController.text,
        nomeProduto: _nomeProdutoController.text,
        tipoProduto: _tipoSelecionado,
        categoriaSelecionadaId: _categoriaSelecionadaId,
        categoriaSelecionadaNome: _categoriaSelecionadaNome,
        categoriaSelecionada: _categoriaSelecionadaEncontrada,
        grupoProduto: _grupoProdutoController.text,
        tempoGarantia: _tempoGarantiaController.text,
        podeAlterarValorNaHora: _podeAlterarValorNaHora,
        modeloProduto: _modeloProdutoController.text,
        estoqueMaximo: _estoqueMaximoController.text,
        estoqueMinimo: _estoqueMinimoController.text,
        precoVenda: _precoVendaController.text,
        produtoTemComissaoEspecial: _produtoTemComissaoEspecial,
        valorComissao: _valorComissaoController.text,
        quantidadeEntrada: _quantidadeEntradaController.text,
        valorCusto: _valorCustoController.text,
        valorVendaEntrada: _valorVendaEntradaController.text,
        imagens: _imagensParaEnvio,
        numberFormat: _numberFormat(),
        tipoCadastro: _tipoCadastro,
        descricao: _descricaoController.text,
        codigoInterno: _codigoInternoController.text,
        marca: _marcaController.text,
        fabricante: _fabricanteController.text,
        categoriaUnidadeMedida: _categoriaUnidadeMedida,
        unidadeMedida: _unidadeMedidaController.text,
        controlaEstoque: _controlaEstoque,
        permiteVendaFracionada: _permiteVendaFracionada,
        permiteEstoqueNegativo: _permiteEstoqueNegativo,
        quantidadeMinimaVenda: _quantidadeMinimaVendaController.text,
        ncm: _ncmController.text,
        cest: _cestController.text,
        cfop: _cfopController.text,
        origemMercadoria: _origemMercadoriaController.text,
        cstIcms: _cstIcmsController.text,
        csosn: _csosnController.text,
        cstPis: _cstPisController.text,
        cstCofins: _cstCofinsController.text,
      ),
    );
  }

  Future<void> _selecionarFotoParaSlot(int slotIndex) async {
    if (_isLoading || slotIndex < 0 || slotIndex >= _maxImageSlots) {
      return;
    }

    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;

    final html.File? file = input.files?.isNotEmpty == true
        ? input.files!.first
        : null;
    if (file == null) return;

    final reader = html.FileReader();
    final completer = Completer<void>();

    reader.onLoad.listen((_) => completer.complete());
    reader.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(reader.error ?? 'Erro ao ler arquivo');
      }
    });

    reader.readAsArrayBuffer(file);

    setState(() {
      _imagemSlots[slotIndex].isLoading = true;
    });

    try {
      await completer.future;
      final result = reader.result;
      if (!mounted) {
        return;
      }

      if (result is ByteBuffer) {
        final Uint8List bytes = Uint8List.view(result);
        final ProdutoImagemModel imageModel = ProdutoImagemModel(
          origem: 'UPLOAD',
          nomeArquivo: file.name,
          imagemBase64: base64Encode(bytes),
        );

        setState(() {
          final slot = _imagemSlots[slotIndex];
          slot.previewBytes = bytes;
          slot.image = imageModel;
          slot.isLoading = false;
        });
      } else {
        setState(() {
          _imagemSlots[slotIndex].isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _imagemSlots[slotIndex].isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar a imagem.')),
      );
    }
  }

  void _removerImagemDoSlot(int slotIndex) {
    if (_isLoading || slotIndex < 0 || slotIndex >= _maxImageSlots) {
      return;
    }

    setState(() {
      _imagemSlots[slotIndex].reset();
      if (_slotSelecionadoIndex >= _maxImageSlots) {
        _slotSelecionadoIndex = 0;
      }
    });
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final produto = _montarProduto();
      if (_isModoEdicao) {
        await _produtoService.atualizarProduto(produto);
      } else {
        await _produtoService.cadastrarProduto(produto);
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(_t('common.success', 'Sucesso')),
            content: Text(
              _isModoEdicao
                  ? _t(
                      'produto.web.updateSuccess',
                      'Produto atualizado com sucesso!',
                    )
                  : _t(
                      'produto.web.createSuccess',
                      'Produto cadastrado com sucesso!',
                    ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_t('common.close', 'Fechar')),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              _isModoEdicao
                  ? _t('produto.web.updateErrorTitle', 'Erro ao atualizar')
                  : _t('produto.web.createErrorTitle', 'Erro ao cadastrar'),
            ),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_t('common.close', 'Fechar')),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _alternarFavorito() async {
    if (_isLoading || _favoritoAtualizando) return;

    final bool novoValor = !_favorito;
    if (!_isModoEdicao || _produtoEmEdicaoId == null) {
      setState(() {
        _favorito = novoValor;
      });
      _mostrarFeedbackFavorito(novoValor);
      return;
    }

    setState(() {
      _favoritoAtualizando = true;
    });

    try {
      await _produtoQuickUpdateService.atualizarFavorito(
        produtoId: _produtoEmEdicaoId!,
        ativo: _ativo,
        favorito: novoValor,
      );
      if (!mounted) return;
      setState(() {
        _favorito = novoValor;
      });
      _mostrarFeedbackFavorito(novoValor);
    } catch (_) {
      if (!mounted) return;
      SixTopNotice.show(
        context,
        message: _t(
          'produto.favorite.updateError',
          'Não foi possível atualizar o favorito do produto.',
        ),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoritoAtualizando = false;
        });
      }
    }
  }

  Future<void> _alternarDisponivelParaCatalogo() async {
    if (_isLoading || _catalogoAtualizando) return;

    final bool novoValor = !_disponivelParaCatalogo;
    if (!_isModoEdicao || _produtoEmEdicaoId == null) {
      setState(() {
        _disponivelParaCatalogo = novoValor;
      });
      _mostrarFeedbackCatalogo(novoValor);
      return;
    }

    setState(() {
      _catalogoAtualizando = true;
    });

    try {
      await _produtoQuickUpdateService.atualizarDisponivelParaCatalogo(
        produtoId: _produtoEmEdicaoId!,
        ativo: _ativo,
        disponivelParaCatalogo: novoValor,
      );
      if (!mounted) return;
      setState(() {
        _disponivelParaCatalogo = novoValor;
      });
      _mostrarFeedbackCatalogo(novoValor);
    } catch (_) {
      if (!mounted) return;
      SixTopNotice.show(
        context,
        message: _t(
          'produto.catalog.updateError',
          'Não foi possível atualizar a disponibilidade no catálogo.',
        ),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _catalogoAtualizando = false;
        });
      }
    }
  }

  void _mostrarFeedbackFavorito(bool favorito) {
    SixTopNotice.show(
      context,
      message: favorito
          ? _t('produto.favorite.enabledFeedback', 'Favorito ativado')
          : _t('produto.favorite.disabledFeedback', 'Favorito desativado'),
      icon: favorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    );
  }

  void _mostrarFeedbackCatalogo(bool disponivelParaCatalogo) {
    SixTopNotice.show(
      context,
      message: disponivelParaCatalogo
          ? _t(
              'produto.catalog.enabledFeedback',
              'Disponível para catálogo ativado',
            )
          : _t(
              'produto.catalog.disabledFeedback',
              'Disponível para catálogo desativado',
            ),
      icon: disponivelParaCatalogo
          ? Icons.storefront_rounded
          : Icons.storefront_outlined,
    );
  }

  Widget _buildHeaderToggleButton(
    BuildContext context, {
    required bool active,
    required VoidCallback? onPressed,
    required String tooltip,
    required IconData icon,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: active
              ? tokens.info.withValues(alpha: 0.18)
              : tokens.surface,
          foregroundColor: active ? tokens.info : tokens.secondaryText,
          disabledBackgroundColor: tokens.disabledBackground,
          disabledForegroundColor: tokens.disabledForeground,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String statusText = _isLoading
        ? (_isModoEdicao
              ? _t('produto.web.savingUpdate', 'Salvando alteração...')
              : _t('produto.web.saving', 'Salvando...'))
        : (_isModoEdicao
              ? _t('produto.web.readyToEdit', 'Pronto para editar')
              : _t('produto.web.readyToSubmit', 'Pronto para envio'));

    Widget headerIcon() {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: tokens.info.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          _isModoEdicao ? Icons.edit_note_rounded : Icons.add_box_outlined,
          color: tokens.info,
          size: 28,
        ),
      );
    }

    Widget titleBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _isModoEdicao
                ? _t('produto.web.editProductTitle', 'Edição de produto')
                : _t('produtos.cadastroDeProdutos', 'Cadastro de produtos'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isModoEdicao
                ? _t(
                    'produto.web.editProductSubtitle',
                    'Revise os dados cadastrados e salve as alterações.',
                  )
                : _t(
                    'produto.web.createProductSubtitle',
                    'Informe dados comerciais, estoque, preço e imagens do catálogo.',
                  ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.secondaryText,
              height: 1.35,
            ),
          ),
        ],
      );
    }

    Widget statusChip() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 16,
              height: 16,
              child: _isLoading
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.info,
                    )
                  : Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: tokens.info,
                    ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    Widget closeButton() {
      return IconButton.filledTonal(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        tooltip: _t('common.close', 'Fechar'),
        icon: const Icon(Icons.close_rounded),
        style: IconButton.styleFrom(
          backgroundColor: tokens.surfaceMuted,
          foregroundColor: tokens.info,
          disabledBackgroundColor: tokens.disabledBackground,
          disabledForegroundColor: tokens.disabledForeground,
        ),
      );
    }

    final Widget favoritoAction = _buildHeaderToggleButton(
      context,
      active: _favorito,
      onPressed: (_isLoading || _favoritoAtualizando)
          ? null
          : () {
              _alternarFavorito();
            },
      tooltip: _favorito
          ? _t('produto.favorite.removeTooltip', 'Remover dos favoritos')
          : _t('produto.favorite.addTooltip', 'Marcar como favorito'),
      icon: _favorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    );

    final Widget catalogoAction = _buildHeaderToggleButton(
      context,
      active: _disponivelParaCatalogo,
      onPressed: (_isLoading || _catalogoAtualizando)
          ? null
          : () {
              _alternarDisponivelParaCatalogo();
            },
      tooltip: _disponivelParaCatalogo
          ? _t(
              'produto.catalog.disableTooltip',
              'Retirar da disponibilidade para catálogo',
            )
          : _t('produto.catalog.enableTooltip', 'Disponibilizar para catálogo'),
      icon: _disponivelParaCatalogo
          ? Icons.storefront_rounded
          : Icons.storefront_outlined,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border(bottom: BorderSide(color: tokens.cardBorder)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    headerIcon(),
                    const SizedBox(width: 14),
                    Expanded(child: titleBlock()),
                    const SizedBox(width: 10),
                    closeButton(),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    statusChip(),
                    favoritoAction,
                    catalogoAction,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: <Widget>[
              headerIcon(),
              const SizedBox(width: 16),
              Expanded(child: titleBlock()),
              const SizedBox(width: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  statusChip(),
                  favoritoAction,
                  catalogoAction,
                  closeButton(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: animatedChild,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 22),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? colorScheme.primary.withValues(alpha: 0.045)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? colorScheme.primary.withValues(alpha: 0.28)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildFotoCard(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _ProdutoImagemSlot slotAtivo = _slotSelecionado;

    return _buildSectionCard(
      context: context,
      title: _t('produto.web.productPhotosTitle', 'Fotos do produto'),
      subtitle: _t(
        'produto.web.productPhotosSubtitle',
        'Selecione um slot e adicione a imagem principal do catálogo.',
      ),
      icon: Icons.photo_camera_back_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _buildMetaChip(
                context: context,
                icon: Icons.photo_library_outlined,
                label:
                    '${_t('produto.web.selectedImagesLabel', 'Selecionadas')}: '
                    '$_totalImagensSelecionadas / $_maxImageSlots',
              ),
              _buildMetaChip(
                context: context,
                icon: Icons.adjust_rounded,
                label:
                    '${_t('produto.web.activeSlotLabel', 'Slot ativo')}: '
                    '${_slotSelecionadoIndex + 1}',
                highlighted: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildImagemAtiva(context, slotAtivo),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _isLoading || slotAtivo.isLoading
                    ? null
                    : () => _selecionarFotoParaSlot(_slotSelecionadoIndex),
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  slotAtivo.image == null
                      ? _t(
                          'produto.web.addActiveSlotImage',
                          'Adicionar no slot ativo',
                        )
                      : _t('produto.web.changeImage', 'Trocar imagem'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isLoading || slotAtivo.image == null
                    ? null
                    : () => _removerImagemDoSlot(_slotSelecionadoIndex),
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  _t(
                    'produto.web.removeActiveSlotImage',
                    'Remover do slot ativo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _t('produto.web.slotsLabel', 'Slots'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: tokens.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List<Widget>.generate(
                _maxImageSlots,
                (int index) => Padding(
                  padding: EdgeInsets.only(
                    right: index == _maxImageSlots - 1 ? 0 : 10,
                  ),
                  child: _buildMiniaturaSlot(context, index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _temSlotLivre
                ? _t(
                    'produto.web.applyAiSuggestionHint',
                    'Você pode aplicar sugestões de IA no slot ativo ou no próximo slot livre.',
                  )
                : _t(
                    'produto.web.imageLimitReachedHint',
                    'Limite de imagens atingido. Remova uma miniatura para continuar.',
                  ),
            style: TextStyle(
              fontSize: 12,
              color: tokens.secondaryText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    bool highlighted = false,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? tokens.selectedBackground : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? tokens.selectedBorder : tokens.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 15,
            color: highlighted ? tokens.info : tokens.secondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: highlighted ? tokens.info : tokens.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagemAtiva(BuildContext context, _ProdutoImagemSlot slotAtivo) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool hasImage = slotAtivo.image != null;
    final bool isSugestao = slotAtivo.image?.origem == 'SUGESTAO';

    final Widget imageContent = hasImage
        ? _buildImageContent(
            context,
            slotAtivo,
            fit: BoxFit.cover,
            brokenIconSize: 34,
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.photo_camera_back_outlined,
                size: 38,
                color: tokens.info,
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhuma imagem no slot ${_slotSelecionadoIndex + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: tokens.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use o botão de upload ou escolha uma sugestão por IA.',
                style: TextStyle(fontSize: 12, color: tokens.secondaryText),
              ),
            ],
          );

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSugestao ? tokens.selectedBorder : tokens.cardBorder,
          width: isSugestao ? 2 : 1,
        ),
        color: tokens.surfaceMuted,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: imageContent),
          if (slotAtivo.isLoading)
            Positioned.fill(
              child: Container(
                color: tokens.workspaceBackground.withValues(alpha: 0.48),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (hasImage)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tokens.workspaceBackground.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: tokens.cardBorder.withValues(alpha: 0.72),
                  ),
                ),
                child: Text(
                  isSugestao ? 'Origem: IA' : 'Origem: Upload',
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniaturaSlot(BuildContext context, int index) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final _ProdutoImagemSlot slot = _imagemSlots[index];
    final bool hasImage = slot.image != null;
    final bool isAtivo = index == _slotSelecionadoIndex;

    final Widget thumb = hasImage
        ? _buildImageContent(
            context,
            slot,
            fit: BoxFit.cover,
            brokenIconSize: 20,
            loadingSize: 18,
            preferThumbnail: true,
          )
        : Icon(Icons.add_photo_alternate_outlined, color: tokens.mutedText);

    return InkWell(
      onTap: () => setState(() => _slotSelecionadoIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAtivo ? tokens.selectedBorder : tokens.cardBorder,
            width: isAtivo ? 2 : 1,
          ),
          color: isAtivo ? tokens.selectedBackground : tokens.cardBackground,
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 78,
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: tokens.surfaceMuted,
              ),
              clipBehavior: Clip.antiAlias,
              child: slot.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Center(child: thumb),
            ),
            const SizedBox(height: 6),
            Text(
              'Slot ${index + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tokens.primaryText,
              ),
            ),
            Text(
              hasImage ? 'OK' : 'Vazio',
              style: TextStyle(fontSize: 10, color: tokens.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(
    BuildContext context,
    _ProdutoImagemSlot slot, {
    required BoxFit fit,
    double brokenIconSize = 24,
    double loadingSize = 24,
    bool preferThumbnail = false,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return ProdutoWebImage(
      image: slot.image,
      previewBytes: slot.previewBytes,
      fit: fit,
      loadingSize: loadingSize,
      preferThumbnail: preferThumbnail,
      fallback: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: tokens.mutedText,
          size: brokenIconSize,
        ),
      ),
    );
  }

  Widget _buildResumoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localeSettings = context.watch<LocaleSettingsProvider>();

    final double precoVenda = ProdutoCadastroFormUtils.parseDecimal(
      _precoVendaController.text,
      numberFormat: ProdutoCadastroNumberFormat(
        decimalSeparator: localeSettings.decimalSeparator,
        thousandSeparator: localeSettings.thousandSeparator,
      ),
    );
    final String preco = localeSettings.formatCurrency(precoVenda);

    return _buildSectionCard(
      context: context,
      title: _t('produto.web.quickSummaryTitle', 'Resumo rápido'),
      subtitle: _t(
        'produto.web.quickSummarySubtitle',
        'Leitura objetiva para conferir antes de salvar.',
      ),
      icon: Icons.summarize_outlined,
      child: Column(
        children: <Widget>[
          _buildInfoRow(
            context,
            _t('produto.web.nameLabel', 'Nome'),
            _nomeProdutoController.text.trim().isEmpty
                ? '-'
                : _nomeProdutoController.text.trim(),
          ),
          _buildInfoRow(
            context,
            _t('produto.web.typeLabel', 'Tipo'),
            _tipoLabel(_tipoSelecionado),
          ),
          _buildInfoRow(
            context,
            _t('produto.web.categoryLabel', 'Categoria'),
            _categoriaSelecionadaNome == null ||
                    _categoriaSelecionadaNome!.trim().isEmpty
                ? '-'
                : _categoriaSelecionadaNome!,
          ),
          _buildInfoRow(
            context,
            _t('produto.web.modelLabel', 'Modelo'),
            _modeloProdutoController.text.trim().isEmpty
                ? '-'
                : _modeloProdutoController.text.trim(),
          ),
          _buildInfoRow(context, _t('produto.web.priceLabel', 'Preço'), preco),
          _buildInfoRow(
            context,
            _t('produto.web.groupLabel', 'Grupo'),
            _grupoProdutoController.text.trim().isEmpty
                ? '-'
                : _grupoProdutoController.text.trim(),
          ),
          _buildInfoRow(
            context,
            _t('produto.web.statusLabel', 'Status'),
            _ativo
                ? _t('common.active', 'Ativo')
                : _t('common.inactive', 'Inativo'),
            isLast: true,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _tipoSelecionado == ProdutoCadastroFormUtils.tipoServico
                  ? _t(
                      'produto.web.serviceModeSummary',
                      'Modo serviço ligado: destaque maior para garantia e alteração de valor.',
                    )
                  : _t(
                      'produto.web.productModeSummary',
                      'Modo produto ligado: foco em estoque, custo e preço de venda.',
                    ),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.74),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugestoesImagemCard(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Sugestões por IA',
      subtitle: 'Sugestões automáticas com base no título e tipo do cadastro.',
      icon: Icons.auto_awesome_outlined,
      child: ImagemSugestoesSection(
        isLoading: _isSugestoesLoading,
        hasSearched: _jaBuscouSugestoes,
        canGenerate: _camposMinimosParaSugestao && !_isLoading,
        sugestoes: _imagensSugeridas,
        errorMessage: _erroSugestoes,
        usedSuggestionIds: _sugestoesAplicadasIds,
        onGerarSugestoes: () => _buscarSugestoesImagem(manual: true),
        onSelecionarSugestao: _aplicarSugestaoEmSlot,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isLast = false,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: tokens.cardBorder.withValues(alpha: 0.72),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 86,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: tokens.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _cadastroCompleto => _tipoCadastro == 'COMPLETO';

  int get _totalEtapas => _cadastroCompleto ? 5 : 3;

  List<String> get _rotulosEtapas => _cadastroCompleto
      ? <String>[
          _t('produto.journey.identification', 'Identificação'),
          _t('produto.journey.commercial', 'Comercial'),
          _t('produto.journey.operation', 'Operação'),
          _t('produto.journey.fiscal', 'Fiscal'),
          _t('produto.journey.review', 'Revisão'),
        ]
      : <String>[
          _t('produto.journey.identification', 'Identificação'),
          _t('produto.journey.commercial', 'Comercial'),
          _t('produto.journey.review', 'Revisão'),
        ];

  void _selecionarTipoCadastro(String tipo) {
    if (_isLoading || tipo == _tipoCadastro) return;
    setState(() {
      _tipoCadastro = tipo;
      _etapaAtual = 0;
    });
  }

  Widget _buildTipoCadastroSelector(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: _t('produto.journey.modeTitle', 'Escolha o nível do cadastro'),
      subtitle: _t(
        'produto.journey.modeSubtitle',
        'Comece simples ou registre detalhes operacionais e fiscais.',
      ),
      icon: Icons.route_outlined,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compacto = constraints.maxWidth < 720;
          final Widget resumido = _CadastroModeOptionWeb(
            icon: Icons.bolt_outlined,
            title: _t('produto.journey.summaryTitle', 'Cadastro resumido'),
            subtitle: _t(
              'produto.journey.summarySubtitle',
              'Para colocar o item em operação rapidamente.',
            ),
            selected: !_cadastroCompleto,
            onTap: () => _selecionarTipoCadastro('RESUMIDO'),
          );
          final Widget completo = _CadastroModeOptionWeb(
            icon: Icons.fact_check_outlined,
            title: _t('produto.journey.completeTitle', 'Cadastro completo'),
            subtitle: _t(
              'produto.journey.completeSubtitle',
              'Inclui regras operacionais e dados fiscais opcionais.',
            ),
            selected: _cadastroCompleto,
            onTap: () => _selecionarTipoCadastro('COMPLETO'),
          );
          return compacto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    resumido,
                    const SizedBox(height: 12),
                    completo,
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(child: resumido),
                    const SizedBox(width: 14),
                    Expanded(child: completo),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildJourneyProgress(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<String> rotulos = _rotulosEtapas;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compacto = constraints.maxWidth < 700;
          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${_t('produto.journey.step', 'Etapa')} ${_etapaAtual + 1} '
                  '${_t('produto.journey.of', 'de')} $_totalEtapas · ${rotulos[_etapaAtual]}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_etapaAtual + 1) / _totalEtapas,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            );
          }

          return Row(
            children: List<Widget>.generate(rotulos.length, (int index) {
              final bool ativa = index == _etapaAtual;
              final bool concluida = index < _etapaAtual;
              return Expanded(
                child: Row(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ativa || concluida
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: concluida
                          ? Icon(
                              Icons.check_rounded,
                              size: 17,
                              color: colorScheme.onPrimary,
                            )
                          : Text(
                              '${index + 1}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: ativa
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rotulos[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: ativa
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontWeight: ativa ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (index < rotulos.length - 1)
                      Container(
                        width: 22,
                        height: 1,
                        color: colorScheme.outlineVariant,
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildDetalhesComplementares(
    BuildContext context, {
    required bool telaGrande,
    required bool telaMedia,
  }) {
    return _buildSectionCard(
      context: context,
      title: _t('produto.journey.detailsTitle', 'Detalhes complementares'),
      subtitle: _t(
        'produto.journey.detailsSubtitle',
        'Informações opcionais para busca, catálogo e organização.',
      ),
      icon: Icons.notes_outlined,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: _buildTextField(
              context: context,
              controller: _descricaoController,
              label: _t('produto.fields.description', 'Descrição'),
              maxLines: 3,
            ),
          ),
          SizedBox(
            width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
            child: _buildTextField(
              context: context,
              controller: _codigoInternoController,
              label: _t('produto.fields.internalCode', 'Código interno'),
            ),
          ),
          SizedBox(
            width: telaGrande ? 260 : (telaMedia ? 240 : double.infinity),
            child: _buildTextField(
              context: context,
              controller: _marcaController,
              label: _t('produto.fields.brand', 'Marca'),
            ),
          ),
          SizedBox(
            width: telaGrande ? 300 : (telaMedia ? 280 : double.infinity),
            child: _buildTextField(
              context: context,
              controller: _fabricanteController,
              label: _t('produto.fields.manufacturer', 'Fabricante'),
            ),
          ),
        ],
      ),
    );
  }

  String _categoriaUnidadeLabel(String codigo) {
    const Map<String, String> fallbacks = <String, String>{
      'UNIDADE': 'Unidade',
      'AREA': 'Área',
      'DISTANCIA': 'Distância',
      'VOLUME': 'Volume',
      'TEMPO': 'Tempo',
      'PESO': 'Peso',
      'MOEDA': 'Moeda',
    };
    return _t(
      'produto.unitCategory.${codigo.toLowerCase()}',
      fallbacks[codigo] ?? codigo,
    );
  }

  Widget _buildRegrasOperacionais(
    BuildContext context, {
    required bool telaGrande,
    required bool telaMedia,
  }) {
    const List<String> categorias = <String>[
      'UNIDADE',
      'AREA',
      'DISTANCIA',
      'VOLUME',
      'TEMPO',
      'PESO',
      'MOEDA',
    ];
    return _buildSectionCard(
      context: context,
      title: _t('produto.journey.operationalRulesTitle', 'Regras operacionais'),
      subtitle: _t(
        'produto.journey.operationalRulesSubtitle',
        'Defina como este item será medido, vendido e controlado.',
      ),
      icon: Icons.tune_outlined,
      child: Column(
        children: <Widget>[
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 280 : (telaMedia ? 260 : double.infinity),
                child: _SixWebDropdownField(
                  label: _t(
                    'produto.fields.unitCategory',
                    'Categoria da unidade',
                  ),
                  value: _categoriaUnidadeMedida,
                  icon: Icons.straighten_outlined,
                  options: categorias
                      .map(
                        (String codigo) => _SixWebDropdownOption(
                          value: codigo,
                          label: _categoriaUnidadeLabel(codigo),
                          icon: Icons.straighten_outlined,
                        ),
                      )
                      .toList(growable: false),
                  onSelected: (String value) =>
                      setState(() => _categoriaUnidadeMedida = value),
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _unidadeMedidaController,
                  label: _t('produto.fields.unitCode', 'Unidade de medida'),
                  hintText: _t('produto.fields.unitCodeHint', 'Ex.: UN, KG, M'),
                ),
              ),
              SizedBox(
                width: telaGrande ? 230 : (telaMedia ? 230 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _quantidadeMinimaVendaController,
                  label: _t(
                    'produto.fields.minimumSaleQuantity',
                    'Quantidade mínima',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: _t('produto.fields.trackStock', 'Controlar estoque'),
                  subtitle: _t(
                    'produto.fields.trackStockHelp',
                    'Movimenta saldo nas entradas e vendas.',
                  ),
                  value: _controlaEstoque,
                  onChanged: (bool value) =>
                      setState(() => _controlaEstoque = value),
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: _t(
                    'produto.fields.allowFractionalSale',
                    'Permitir venda fracionada',
                  ),
                  subtitle: _t(
                    'produto.fields.allowFractionalSaleHelp',
                    'Aceita quantidades decimais para peso, área ou volume.',
                  ),
                  value: _permiteVendaFracionada,
                  onChanged: (bool value) =>
                      setState(() => _permiteVendaFracionada = value),
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: _t(
                    'produto.fields.allowNegativeStock',
                    'Permitir estoque negativo',
                  ),
                  subtitle: _t(
                    'produto.fields.allowNegativeStockHelp',
                    'Mantém a venda disponível mesmo sem saldo suficiente.',
                  ),
                  value: _permiteEstoqueNegativo,
                  onChanged: (bool value) =>
                      setState(() => _permiteEstoqueNegativo = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDadosFiscais(
    BuildContext context, {
    required bool telaGrande,
    required bool telaMedia,
  }) {
    final double largura = telaGrande
        ? 240
        : (telaMedia ? 220 : double.infinity);
    Widget campo(TextEditingController controller, String label) {
      return SizedBox(
        width: largura,
        child: _buildTextField(
          context: context,
          controller: controller,
          label: label,
        ),
      );
    }

    return _buildSectionCard(
      context: context,
      title: _t('produto.journey.fiscalTitle', 'Dados fiscais e contábeis'),
      subtitle: _t(
        'produto.journey.fiscalSubtitle',
        'Preencha somente o que sua operação ou contador exigir.',
      ),
      icon: Icons.receipt_long_outlined,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          campo(_ncmController, _t('produto.fields.ncm', 'NCM')),
          campo(_cestController, _t('produto.fields.cest', 'CEST')),
          campo(_cfopController, _t('produto.fields.cfop', 'CFOP')),
          campo(
            _origemMercadoriaController,
            _t('produto.fields.goodsOrigin', 'Origem da mercadoria'),
          ),
          campo(_cstIcmsController, _t('produto.fields.cstIcms', 'CST ICMS')),
          campo(_csosnController, _t('produto.fields.csosn', 'CSOSN')),
          campo(_cstPisController, _t('produto.fields.cstPis', 'CST PIS')),
          campo(
            _cstCofinsController,
            _t('produto.fields.cstCofins', 'CST COFINS'),
          ),
        ],
      ),
    );
  }

  void _avancarEtapa() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    if (_etapaAtual < _totalEtapas - 1) {
      setState(() => _etapaAtual++);
    }
  }

  void _voltarEtapa() {
    FocusScope.of(context).unfocus();
    if (_etapaAtual > 0) {
      setState(() => _etapaAtual--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildActionsBar(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tokens.workspaceBackground.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          Text(
            '${_t('produto.journey.step', 'Etapa')} ${_etapaAtual + 1} '
            '${_t('produto.journey.of', 'de')} $_totalEtapas · ${_rotulosEtapas[_etapaAtual]}',
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton(
                onPressed: _isLoading ? null : _voltarEtapa,
                child: Text(
                  _etapaAtual == 0
                      ? _t('common.cancel', 'Cancelar')
                      : _t('common.back', 'Voltar'),
                ),
              ),
              FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : (_etapaAtual == _totalEtapas - 1
                          ? _salvarProduto
                          : _avancarEtapa),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _etapaAtual == _totalEtapas - 1
                            ? Icons.save_outlined
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  _isLoading
                      ? (_isModoEdicao
                            ? _t(
                                'produto.web.savingUpdate',
                                'Salvando alteração...',
                              )
                            : _t('produto.web.saving', 'Salvando...'))
                      : (_etapaAtual < _totalEtapas - 1
                            ? _t('common.continue', 'Continuar')
                            : (_isModoEdicao
                                  ? _t(
                                      'produto.web.saveUpdate',
                                      'Salvar alteração',
                                    )
                                  : _t(
                                      'produto.web.saveProduct',
                                      'Salvar produto',
                                    ))),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool telaGrande = constraints.maxWidth >= 1080;
        final bool telaMedia = constraints.maxWidth >= 760;

        final Widget dadosPrincipais = _buildSectionCard(
          context: context,
          title: _t('produto.web.mainDataTitle', 'Dados principais'),
          subtitle: _t(
            'produto.web.mainDataSubtitle',
            'Identificação comercial e classificação do item.',
          ),
          icon: Icons.badge_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _codigoBarrasController,
                  label: _t('produto.web.skuLabel', 'Código de barras'),
                  hintText: _t('produto.web.skuHint', 'Ex.: 789000000001'),
                ),
              ),
              SizedBox(
                width: telaGrande ? 390 : (telaMedia ? 320 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _nomeProdutoController,
                  label: _t('produto.web.productNameLabel', 'Nome do produto'),
                  hintText: _t(
                    'produto.web.productNameHint',
                    'Descreva seu produto aqui',
                  ),
                  requiredField: true,
                ),
              ),
              _buildTipoDropdown(
                context,
                telaGrande ? 190 : (telaMedia ? 180 : double.infinity),
              ),
              _buildCategoriaDropdown(
                context,
                telaGrande ? 280 : (telaMedia ? 260 : double.infinity),
              ),
              SizedBox(
                width: telaGrande ? 180 : (telaMedia ? 160 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _modeloProdutoController,
                  label: _t('produto.web.modelLabel', 'Modelo'),
                  hintText: ProdutoCadastroFormUtils.modeloPadrao,
                ),
              ),
              SizedBox(
                width: telaGrande ? 250 : (telaMedia ? 240 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _grupoProdutoController,
                  label: _t('produto.web.groupLabel', 'Grupo'),
                  hintText: _t('produto.web.groupHint', 'Ex.: Acessórios'),
                ),
              ),
            ],
          ),
        );

        final Widget estoquePreco = _buildSectionCard(
          context: context,
          title: _t('produto.web.stockPriceTitle', 'Estoque e preço'),
          subtitle: _t(
            'produto.web.stockPriceSubtitle',
            'Controle de limites, custo e preço comercial.',
          ),
          icon: Icons.sell_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 180 : (telaMedia ? 180 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _estoqueMaximoController,
                  label: _t('produto.web.maxStockLabel', 'Estoque máximo'),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: telaGrande ? 180 : (telaMedia ? 180 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _estoqueMinimoController,
                  label: _t('produto.web.minStockLabel', 'Estoque mínimo'),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _precoVendaController,
                  label: _t('produto.web.salePriceLabel', 'Preço de venda'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: _decimalInputHint(),
                ),
              ),
            ],
          ),
        );

        final Widget servicoComissao = _buildSectionCard(
          context: context,
          title: _t(
            'produto.web.serviceCommissionRulesTitle',
            'Serviço, comissão e regras',
          ),
          subtitle: _t(
            'produto.web.serviceCommissionRulesSubtitle',
            'Campos que ajudam a deixar a operação mais flexível.',
          ),
          icon: Icons.settings_suggest_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: telaGrande
                        ? 250
                        : (telaMedia ? 240 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _tempoGarantiaController,
                      label: _t(
                        'produto.web.warrantyLabel',
                        'Tempo da garantia',
                      ),
                      hintText: _t('produto.web.warrantyHint', 'Ex.: 90 dias'),
                    ),
                  ),
                  SizedBox(
                    width: telaGrande
                        ? 220
                        : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _valorComissaoController,
                      label: _t(
                        'produto.web.commissionValueLabel',
                        'Valor fixo da comissão',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: _decimalInputHint(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: _t(
                        'produto.web.activeProductTitle',
                        'Produto ativo',
                      ),
                      subtitle: _t(
                        'produto.web.activeProductSubtitle',
                        'Disponível para venda e listagens.',
                      ),
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: _t(
                        'produto.web.changePriceAtSaleTitle',
                        'Alterar valor na hora',
                      ),
                      subtitle: _t(
                        'produto.web.changePriceAtSaleSubtitle',
                        'Permite ajustar o valor durante o atendimento.',
                      ),
                      value: _podeAlterarValorNaHora,
                      onChanged: (value) =>
                          setState(() => _podeAlterarValorNaHora = value),
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: _t(
                        'produto.web.specialCommissionTitle',
                        'Comissão especial',
                      ),
                      subtitle: _t(
                        'produto.web.specialCommissionSubtitle',
                        'Aplica comissão específica para este item.',
                      ),
                      value: _produtoTemComissaoEspecial,
                      onChanged: (value) =>
                          setState(() => _produtoTemComissaoEspecial = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final Widget movimentacao = _buildSectionCard(
          context: context,
          title: _t('produto.web.entryExitTitle', 'Entrada e saída do produto'),
          subtitle: _t(
            'produto.web.entryExitSubtitle',
            'Dados iniciais de movimentação e precificação.',
          ),
          icon: Icons.swap_horiz_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 180 : (telaMedia ? 180 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _quantidadeEntradaController,
                  label: _t('produto.web.entryQuantityLabel', 'Quantidade'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              SizedBox(
                width: telaGrande ? 200 : (telaMedia ? 200 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _valorCustoController,
                  label: _t('produto.web.costValueLabel', 'Valor de custo'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: _decimalInputHint(),
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _valorVendaEntradaController,
                  label: _t(
                    'produto.web.entrySaleValueLabel',
                    'Valor da venda',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: _decimalInputHint(),
                ),
              ),
            ],
          ),
        );

        late final Widget conteudoEtapa;
        if (_etapaAtual == 0) {
          conteudoEtapa = Column(
            children: <Widget>[
              _buildTipoCadastroSelector(context),
              const SizedBox(height: 20),
              dadosPrincipais,
              if (_cadastroCompleto) ...<Widget>[
                const SizedBox(height: 20),
                _buildDetalhesComplementares(
                  context,
                  telaGrande: telaGrande,
                  telaMedia: telaMedia,
                ),
              ],
            ],
          );
        } else if (_etapaAtual == 1) {
          conteudoEtapa = Column(
            children: <Widget>[
              estoquePreco,
              const SizedBox(height: 20),
              servicoComissao,
              const SizedBox(height: 20),
              movimentacao,
            ],
          );
        } else if (_cadastroCompleto && _etapaAtual == 2) {
          conteudoEtapa = _buildRegrasOperacionais(
            context,
            telaGrande: telaGrande,
            telaMedia: telaMedia,
          );
        } else if (_cadastroCompleto && _etapaAtual == 3) {
          conteudoEtapa = _buildDadosFiscais(
            context,
            telaGrande: telaGrande,
            telaMedia: telaMedia,
          );
        } else {
          final Widget imagens = Column(
            children: <Widget>[
              _buildFotoCard(context),
              const SizedBox(height: 20),
              _buildSugestoesImagemCard(context),
            ],
          );
          conteudoEtapa = telaGrande
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 7, child: imagens),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: _buildResumoCard(context)),
                  ],
                )
              : Column(
                  children: <Widget>[
                    _buildResumoCard(context),
                    const SizedBox(height: 20),
                    imagens,
                  ],
                );
        }

        return Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Column(
                        children: <Widget>[
                          _buildJourneyProgress(context),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: KeyedSubtree(
                              key: ValueKey<String>(
                                '$_tipoCadastro-$_etapaAtual',
                              ),
                              child: conteudoEtapa,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: _buildActionsBar(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CadastroModeOptionWeb extends StatelessWidget {
  const _CadastroModeOptionWeb({
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.06)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.50)
                    : colorScheme.outlineVariant,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SixWebDropdownOption {
  const _SixWebDropdownOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class _SixWebDropdownField extends StatefulWidget {
  const _SixWebDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.icon,
    required this.onSelected,
    this.enabled = true,
    this.placeholder,
    this.errorText,
    this.tooltip,
    this.showPlaceholder = false,
  });

  final String label;
  final String value;
  final List<_SixWebDropdownOption> options;
  final IconData icon;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final String? placeholder;
  final String? errorText;
  final String? tooltip;
  final bool showPlaceholder;

  @override
  State<_SixWebDropdownField> createState() => _SixWebDropdownFieldState();
}

class _SixWebDropdownFieldState extends State<_SixWebDropdownField> {
  bool _open = false;
  bool _hover = false;

  _SixWebDropdownOption? get _selectedOption {
    for (final _SixWebDropdownOption option in widget.options) {
      if (option.value == widget.value) {
        return option;
      }
    }
    return null;
  }

  String get _displayLabel {
    if (widget.showPlaceholder && widget.placeholder != null) {
      return widget.placeholder!;
    }

    final _SixWebDropdownOption? selectedOption = _selectedOption;
    if (selectedOption != null) {
      return selectedOption.label;
    }

    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return widget.options.isEmpty ? '' : widget.options.first.label;
  }

  String get _effectiveValue {
    final _SixWebDropdownOption? selectedOption = _selectedOption;
    if (selectedOption != null) {
      return selectedOption.value;
    }

    return widget.options.isEmpty ? widget.value : widget.options.first.value;
  }

  Future<void> _showMenu() async {
    if (!widget.enabled || widget.options.isEmpty) {
      return;
    }

    setState(() => _open = true);

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero, ancestor: overlay);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String effectiveValue = _effectiveValue;

    final String? selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          position.dx,
          position.dy + box.size.height + 8,
          box.size.width,
          box.size.height,
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 12,
      color: colorScheme.surface,
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
        maxHeight: 360,
      ),
      items: widget.options
          .map(
            (_SixWebDropdownOption option) => PopupMenuItem<String>(
              value: option.value,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: _SixWebDropdownMenuItem(
                option: option,
                selected: option.value == effectiveValue,
                colorScheme: colorScheme,
              ),
            ),
          )
          .toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool active = widget.enabled && (_open || _hover);
    final bool hasError =
        widget.errorText != null && widget.errorText!.trim().isNotEmpty;
    final Color borderColor = hasError
        ? colorScheme.error
        : active
        ? colorScheme.primary.withValues(alpha: 0.42)
        : colorScheme.outline.withValues(alpha: 0.22);
    final Color backgroundColor = widget.enabled
        ? (active
              ? colorScheme.primary.withValues(alpha: 0.05)
              : colorScheme.surface)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.34);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: '${widget.label}: $_displayLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Tooltip(
            message: widget.tooltip ?? widget.label,
            waitDuration: const Duration(milliseconds: 450),
            child: MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.enabled ? _showMenu : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: 58,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: active
                          ? <BoxShadow>[
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          widget.icon,
                          size: 20,
                          color: widget.enabled
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _displayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: widget.showPlaceholder
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: active
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasError) ...<Widget>[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                widget.errorText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SixWebDropdownMenuItem extends StatelessWidget {
  const _SixWebDropdownMenuItem({
    required this.option,
    required this.selected,
    required this.colorScheme,
  });

  final _SixWebDropdownOption option;
  final bool selected;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            selected ? Icons.check_circle_rounded : option.icon,
            color: selected
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.78),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
