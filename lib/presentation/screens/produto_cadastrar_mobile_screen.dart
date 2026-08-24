import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/produto_cadastro_form_utils.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/models/produto_imagem_model.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/six_top_notice.dart';
import 'package:sixpos/presentation/screens/categorias_produtos_servicos_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class CadastroProdutoMobileScreen extends StatefulWidget {
  const CadastroProdutoMobileScreen({
    super.key,
    this.produtoParaEdicao,
    this.tipoInicial = ProdutoCadastroFormUtils.tipoProduto,
    this.produtoService,
    this.categoriaApiClient,
  });

  final ProdutoModel? produtoParaEdicao;
  final String tipoInicial;
  final ProdutoService? produtoService;
  final CategoriaCatalogoApiClient? categoriaApiClient;

  @override
  State<CadastroProdutoMobileScreen> createState() =>
      _CadastroProdutoMobileScreenState();
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

class _CadastroProdutoMobileScreenState
    extends State<CadastroProdutoMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.border;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _softNeutralColor => SixMobilePalette.softNeutralSurface;

  static const int _maxImageSlots = 5;

  final _formKey = GlobalKey<FormState>();
  late final ProdutoService _produtoService =
      widget.produtoService ?? ProdutoService();
  late final CategoriaCatalogoApiClient _categoriaApiClient =
      widget.categoriaApiClient ?? HttpCategoriaCatalogoApiClient();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _slotsScrollController = ScrollController();

  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();
  final _modeloController = TextEditingController(
    text: ProdutoCadastroFormUtils.modeloPadrao,
  );
  final _grupoController = TextEditingController();
  final _precoVendaController = TextEditingController();
  final _estoqueMinController = TextEditingController(text: '1');
  final _estoqueMaxController = TextEditingController(text: '1000');
  final _tempoGarantiaController = TextEditingController();
  final _valorComissaoController = TextEditingController(text: '0');
  final _quantidadeEntradaController = TextEditingController(text: '1');
  final _valorCustoController = TextEditingController(text: '0');
  final _valorVendaEntradaController = TextEditingController(text: '0');
  final _descricaoController = TextEditingController();
  final _codigoInternoController = TextEditingController();
  final _marcaController = TextEditingController();
  final _fabricanteController = TextEditingController();
  final _unidadeMedidaController = TextEditingController(text: 'UN');
  final _quantidadeMinimaVendaController = TextEditingController();
  final _ncmController = TextEditingController();
  final _cestController = TextEditingController();
  final _cfopController = TextEditingController();
  final _origemMercadoriaController = TextEditingController();
  final _cstIcmsController = TextEditingController();
  final _csosnController = TextEditingController();
  final _cstPisController = TextEditingController();
  final _cstCofinsController = TextEditingController();

  late String _tipoSelecionado;
  String? _produtoEmEdicaoId;
  List<CategoriaCatalogoModel> _categoriasCatalogo = <CategoriaCatalogoModel>[];
  bool _carregandoCategorias = false;
  String? _erroCategorias;
  String? _categoriaSelecionadaId;
  String? _categoriaSelecionadaNome;

  bool _ativo = true;
  bool _favorito = false;
  bool _disponivelParaCatalogo = false;
  bool _podeAlterarValorNaHora = false;
  bool _produtoTemComissaoEspecial = false;
  bool _isLoading = false;
  bool _slotsHintPlayed = false;
  String _tipoCadastro = 'RESUMIDO';
  int _etapaAtual = 0;
  String _categoriaUnidadeMedida = 'UNIDADE';
  bool _controlaEstoque = true;
  bool _permiteVendaFracionada = false;
  bool _permiteEstoqueNegativo = false;

  final List<_ProdutoImagemSlot> _imagemSlots =
      List<_ProdutoImagemSlot>.generate(
        _maxImageSlots,
        (_) => _ProdutoImagemSlot(),
        growable: false,
      );

  int _slotSelecionadoIndex = 0;

  bool get _isModoEdicao => widget.produtoParaEdicao != null;

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  ProdutoCadastroNumberFormat _numberFormat() {
    final localeSettings = context.read<LocaleSettingsProvider>();
    return ProdutoCadastroNumberFormat(
      decimalSeparator: localeSettings.decimalSeparator,
      thousandSeparator: localeSettings.thousandSeparator,
    );
  }

  String _decimalInputHint({int decimalPlaces = 2}) {
    final decimalSeparator =
        context.read<LocaleSettingsProvider>().decimalSeparator;
    return '0$decimalSeparator${'0' * decimalPlaces}';
  }

  String _tipoLabel(String tipo) {
    return _normalizarTipo(tipo) == ProdutoCadastroFormUtils.tipoServico
        ? _t('produto.mobile.typeService', 'Serviço')
        : _t('produto.mobile.typeProduct', 'Produto');
  }

  String _categoriaDisplayName(CategoriaCatalogoModel categoria) {
    if (categoria.ativo) return categoria.nome;
    return '${categoria.nome} (${_t('common.inactive', 'Inativa')})';
  }

  _ProdutoImagemSlot get _slotSelecionado =>
      _imagemSlots[_slotSelecionadoIndex];

  int get _totalImagensSelecionadas =>
      _imagemSlots.where((slot) => slot.image != null).length;

  List<ProdutoImagemModel> get _imagensParaEnvio => _imagemSlots
      .map((slot) => slot.image)
      .whereType<ProdutoImagemModel>()
      .take(_maxImageSlots)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = _normalizarTipo(widget.tipoInicial);
    _preencherCamposSeModoEdicao();
    _carregarCategoriasCatalogo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playSlotsHint();
    });
  }

  @override
  void dispose() {
    _slotsScrollController.dispose();
    _nomeController.dispose();
    _codigoController.dispose();
    _modeloController.dispose();
    _grupoController.dispose();
    _precoVendaController.dispose();
    _estoqueMinController.dispose();
    _estoqueMaxController.dispose();
    _tempoGarantiaController.dispose();
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

  String _normalizarTipo(String value) {
    return ProdutoCadastroFormUtils.normalizarTipo(value);
  }

  void _preencherCamposSeModoEdicao() {
    final produto = widget.produtoParaEdicao;
    if (produto == null) {
      return;
    }

    _produtoEmEdicaoId = produto.id;
    _ativo = produto.ativo;
    _favorito = produto.favorito;
    _disponivelParaCatalogo = produto.disponivelParaCatalogo;
    _tipoCadastro =
        produto.tipoCadastro.toUpperCase() == 'COMPLETO'
            ? 'COMPLETO'
            : 'RESUMIDO';
    _codigoController.text = produto.codigoDeBarras;
    _nomeController.text = produto.nomeProduto;
    _tipoSelecionado = _normalizarTipo(produto.tipoProduto);
    _categoriaSelecionadaId = produto.objCategoria?.idCategoria;
    _categoriaSelecionadaNome = produto.objCategoria?.nomeCategoria;
    _modeloController.text =
        produto.modeloProduto.trim().isEmpty
            ? ProdutoCadastroFormUtils.modeloPadrao
            : produto.modeloProduto;
    _grupoController.text = produto.objAgrupamento?.grupoDoProduto ?? '';
    _estoqueMaxController.text = produto.estoqueMaximo.toString();
    _estoqueMinController.text = produto.estoqueMinimo.toString();
    _precoVendaController.text = produto.precoVenda.toString();
    _valorComissaoController.text =
        produto.objComissao.valorFixoDeComissaoParaEsseProduto.toString();
    _produtoTemComissaoEspecial =
        produto.objComissao.produtoTemComissaoEspecial;

    if (produto.objetoServico != null) {
      _tempoGarantiaController.text = produto.objetoServico!.tempoDaGarantia;
      _podeAlterarValorNaHora = produto.objetoServico!.podeAlterarOValorNaHora;
    }

    if (produto.objEntradaSaidaProduto != null &&
        produto.objEntradaSaidaProduto!.isNotEmpty) {
      final entrada = produto.objEntradaSaidaProduto!.first;
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

    final imagens = produto.imagens ?? <ProdutoImagemModel>[];
    for (int i = 0; i < imagens.length && i < _imagemSlots.length; i++) {
      _imagemSlots[i].image = imagens[i];
    }
  }

  Future<void> _carregarCategoriasCatalogo() async {
    setState(() {
      _carregandoCategorias = true;
      _erroCategorias = null;
    });

    try {
      final CategoriaCatalogoListResponse response =
          await _categoriaApiClient.listarCategorias();
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
            '${_t('produto.mobile.categoryLoadHttpError', 'Erro ao carregar categorias')} '
            '(HTTP ${error.statusCode}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoCategorias = false;
        _erroCategorias = _t(
          'produto.mobile.categoryLoadError',
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

  bool _categoriaCompativelComTipoAtual(CategoriaCatalogoModel categoria) {
    return ProdutoCadastroFormUtils.categoriaCompativelComTipo(
      categoria,
      _tipoSelecionado,
    );
  }

  void _validarCategoriaSelecionadaComTipoAtual() {
    final String? id = _categoriaSelecionadaId;
    if (id == null || id.trim().isEmpty) return;

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

  List<CategoriaCatalogoModel> get _categoriasCompativeis {
    return _categoriasCatalogo
        .where(
          (CategoriaCatalogoModel categoria) =>
              categoria.ativo || categoria.id == _categoriaSelecionadaId,
        )
        .where(_categoriaCompativelComTipoAtual)
        .toList(growable: false);
  }

  Future<void> _abrirGestaoCategorias() async {
    final bool? alterouCategorias = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CategoriasProdutosServicosMobileScreen(),
      ),
    );

    if (alterouCategorias == true && mounted) {
      await _carregarCategoriasCatalogo();
    }
  }

  Future<void> _playSlotsHint() async {
    if (_slotsHintPlayed || !mounted || !_slotsScrollController.hasClients) {
      return;
    }

    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery?.disableAnimations == true ||
        mediaQuery?.accessibleNavigation == true) {
      return;
    }

    final maxScroll = _slotsScrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      return;
    }

    _slotsHintPlayed = true;
    final hintOffset = math.min(42.0, maxScroll);

    await _slotsScrollController.animateTo(
      hintOffset,
      duration: Duration(milliseconds: 330),
      curve: Curves.easeOutCubic,
    );

    if (!mounted || !_slotsScrollController.hasClients) {
      return;
    }

    await _slotsScrollController.animateTo(
      0,
      duration: Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  ProdutoModel _montarProduto() {
    return ProdutoCadastroFormUtils.montarProduto(
      ProdutoCadastroFormData(
        id: _produtoEmEdicaoId,
        ativo: _ativo,
        favorito: _favorito,
        disponivelParaCatalogo: _disponivelParaCatalogo,
        codigoDeBarras: _codigoController.text,
        nomeProduto: _nomeController.text,
        tipoProduto: _tipoSelecionado,
        categoriaSelecionadaId: _categoriaSelecionadaId,
        categoriaSelecionadaNome: _categoriaSelecionadaNome,
        categoriaSelecionada: _categoriaSelecionadaEncontrada,
        grupoProduto: _grupoController.text,
        tempoGarantia: _tempoGarantiaController.text,
        podeAlterarValorNaHora: _podeAlterarValorNaHora,
        modeloProduto: _modeloController.text,
        estoqueMaximo: _estoqueMaxController.text,
        estoqueMinimo: _estoqueMinController.text,
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
        usarPrecoVendaComoValorEntradaQuandoVazio: true,
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isModoEdicao
                ? _t(
                  'produto.mobile.updateSuccess',
                  'Produto atualizado com sucesso!',
                )
                : _t(
                  'produto.mobile.createSuccess',
                  'Produto cadastrado com sucesso!',
                ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      final mensagem = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isModoEdicao
                ? '${_t('produto.mobile.updateError', 'Erro ao atualizar produto')}: $mensagem'
                : '${_t('produto.mobile.createError', 'Erro ao cadastrar produto')}: $mensagem',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _alternarFavorito() {
    if (_isLoading) return;

    setState(() {
      _favorito = !_favorito;
    });

    SixTopNotice.show(
      context,
      message:
          _favorito
              ? _t('produto.favorite.enabledFeedback', 'Favorito ativado')
              : _t('produto.favorite.disabledFeedback', 'Favorito desativado'),
      icon: _favorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    );
  }

  void _alternarDisponivelParaCatalogo() {
    if (_isLoading) return;

    setState(() {
      _disponivelParaCatalogo = !_disponivelParaCatalogo;
    });

    SixTopNotice.show(
      context,
      message:
          _disponivelParaCatalogo
              ? _t(
                'produto.catalog.enabledFeedback',
                'Disponível para catálogo ativado',
              )
              : _t(
                'produto.catalog.disabledFeedback',
                'Disponível para catálogo desativado',
              ),
      icon:
          _disponivelParaCatalogo
              ? Icons.storefront_rounded
              : Icons.storefront_outlined,
    );
  }

  Widget _buildHeaderAction({
    required bool active,
    required VoidCallback onPressed,
    required String tooltip,
    required IconData icon,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            backgroundColor:
                active
                    ? SixMobilePalette.onPrimary.withValues(alpha: 0.20)
                    : SixMobilePalette.onPrimary.withValues(alpha: 0.08),
            foregroundColor:
                active
                    ? SixMobilePalette.onPrimary
                    : SixMobilePalette.heroSupportingText,
          ),
        ),
      ),
    );
  }

  Future<void> _selecionarImagem(ImageSource source, int slotIndex) async {
    if (_isLoading || slotIndex < 0 || slotIndex >= _maxImageSlots) {
      return;
    }

    setState(() {
      _imagemSlots[slotIndex].isLoading = true;
    });

    try {
      final XFile? arquivo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );

      if (arquivo == null) {
        if (!mounted) return;
        setState(() {
          _imagemSlots[slotIndex].isLoading = false;
        });
        return;
      }

      final bytes = await arquivo.readAsBytes();

      if (!mounted) return;

      if (bytes.isEmpty) {
        throw Exception('Arquivo vazio.');
      }

      final nomeArquivo =
          arquivo.name.trim().isEmpty
              ? 'produto-${DateTime.now().millisecondsSinceEpoch}.jpg'
              : arquivo.name.trim();

      setState(() {
        final slot = _imagemSlots[slotIndex];
        slot.previewBytes = bytes;
        slot.image = ProdutoImagemModel(
          origem: 'UPLOAD',
          nomeArquivo: nomeArquivo,
          imagemBase64: base64Encode(bytes),
        );
        slot.isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _imagemSlots[slotIndex].isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'produto.mobile.imageLoadError',
              'Não foi possível carregar a imagem.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removerImagemDoSlot(int slotIndex) {
    if (_isLoading || slotIndex < 0 || slotIndex >= _maxImageSlots) {
      return;
    }

    setState(() {
      _imagemSlots[slotIndex].reset();
    });
  }

  void _abrirOpcoesImagem() {
    final slot = _slotSelecionado;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x47000000),
      useSafeArea: true,
      builder: (BuildContext context) {
        return _MobileBottomSheetFrame(
          child: Semantics(
            container: true,
            label: _t('produto.mobile.imageSheetTitle', 'Imagem do produto'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MobileSheetHandle(),
                SizedBox(height: 16),
                Text(
                  _t('produto.mobile.imageSheetTitle', 'Imagem do produto'),
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12),
                _ImageActionTile(
                  icon: Icons.photo_camera_outlined,
                  title: _t('produto.mobile.takePhoto', 'Tirar foto'),
                  subtitle: _t(
                    'produto.mobile.takePhotoSubtitle',
                    'Usar a câmera do dispositivo.',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selecionarImagem(
                      ImageSource.camera,
                      _slotSelecionadoIndex,
                    );
                  },
                ),
                SizedBox(height: 10),
                _ImageActionTile(
                  icon: Icons.upload_file_outlined,
                  title: _t(
                    'produto.mobile.uploadFromGallery',
                    'Enviar da galeria',
                  ),
                  subtitle: _t(
                    'produto.mobile.uploadFromGallerySubtitle',
                    'Escolher uma imagem salva no aparelho.',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selecionarImagem(
                      ImageSource.gallery,
                      _slotSelecionadoIndex,
                    );
                  },
                ),
                if (slot.image != null) ...[
                  SizedBox(height: 10),
                  _ImageActionTile(
                    icon: Icons.delete_outline,
                    title: _t('produto.mobile.removeImage', 'Remover imagem'),
                    subtitle: _t(
                      'produto.mobile.removeImageSubtitle',
                      'Limpar o slot selecionado.',
                    ),
                    isDanger: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      _removerImagemDoSlot(_slotSelecionadoIndex);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surfaceColor,
      hintStyle: TextStyle(color: _mutedTextColor),
      labelStyle: TextStyle(color: _mutedTextColor),
      floatingLabelStyle: TextStyle(
        color: _accentColor,
        fontWeight: FontWeight.w800,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _accentColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: SixMobilePalette.errorBorder),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: SixMobilePalette.error, width: 1.4),
      ),
    );
  }

  Widget _buildTextField({
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
      cursorColor: _accentColor,
      style: TextStyle(
        color: _titleTextColor,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(label, hintText: hintText),
      validator:
          requiredField
              ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return _t('common.required', 'Campo obrigatório');
                }
                return null;
              }
              : null,
    );
  }

  Widget _buildTipoField() {
    return _MobileSelectorField(
      label: _t('produto.mobile.typeLabel', 'Tipo'),
      value: _tipoLabel(_tipoSelecionado),
      icon:
          _tipoSelecionado == ProdutoCadastroFormUtils.tipoServico
              ? Icons.design_services_outlined
              : Icons.inventory_2_outlined,
      enabled: !_isLoading,
      onTap: _abrirSeletorTipo,
    );
  }

  Future<void> _abrirSeletorTipo() async {
    if (_isLoading) return;

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x47000000),
      useSafeArea: true,
      builder: (BuildContext context) {
        return _MobileBottomSheetFrame(
          child: _TipoProdutoSelectorSheet(
            title: _t('produto.mobile.typeSheetTitle', 'Tipo do cadastro'),
            subtitle: _t(
              'produto.mobile.typeSheetSubtitle',
              'Escolha se este cadastro será vendido como produto ou serviço.',
            ),
            selectedType: _tipoSelecionado,
            productLabel: _t('produto.mobile.typeProduct', 'Produto'),
            productSubtitle: _t(
              'produto.mobile.typeProductSubtitle',
              'Item com estoque, custo e quantidade.',
            ),
            serviceLabel: _t('produto.mobile.typeService', 'Serviço'),
            serviceSubtitle: _t(
              'produto.mobile.typeServiceSubtitle',
              'Atendimento, mão de obra ou serviço sem estoque físico.',
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == _tipoSelecionado) {
      return;
    }

    setState(() {
      _tipoSelecionado = selected;
      _validarCategoriaSelecionadaComTipoAtual();
    });
  }

  Widget _buildCategoriaField() {
    final List<CategoriaCatalogoModel> categorias = _categoriasCompativeis;
    final bool categoriaSelecionadaExiste = categorias.any(
      (CategoriaCatalogoModel categoria) =>
          categoria.id == _categoriaSelecionadaId,
    );
    final CategoriaCatalogoModel? categoriaSelecionada =
        categoriaSelecionadaExiste ? _categoriaSelecionadaEncontrada : null;
    final String? categoriaLabel =
        categoriaSelecionada != null
            ? _categoriaDisplayName(categoriaSelecionada)
            : _categoriaSelecionadaNome?.trim();
    final String value =
        categoriaLabel != null && categoriaLabel.isNotEmpty
            ? categoriaLabel
            : _t('produto.mobile.categoryNone', 'Sem categoria');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MobileSelectorField(
          label: _t('produto.mobile.categoryLabel', 'Categoria'),
          value: value,
          icon: Icons.category_outlined,
          enabled: !_isLoading && !_carregandoCategorias,
          loading: _carregandoCategorias,
          onTap: _abrirSeletorCategoria,
        ),
        if (_carregandoCategorias)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accentColor,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t(
                      'produto.mobile.loadingCategories',
                      'Buscando categorias...',
                    ),
                    style: TextStyle(color: _mutedTextColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        if (_erroCategorias != null && !_carregandoCategorias)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  _erroCategorias!,
                  style: TextStyle(
                    color: SixMobilePalette.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _carregarCategoriasCatalogo,
                  icon: Icon(Icons.refresh_rounded, size: 18),
                  label: Text(_t('common.tryAgain', 'Tentar novamente')),
                ),
              ],
            ),
          ),
        if (!_carregandoCategorias &&
            _erroCategorias == null &&
            categorias.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  _t(
                    'produto.mobile.noCategoriesForType',
                    'Nenhuma categoria disponível para este tipo.',
                  ),
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: _isLoading ? null : _abrirGestaoCategorias,
                  icon: Icon(Icons.category_outlined, size: 18),
                  label: Text(
                    _t(
                      'produto.mobile.manageCategories',
                      'Gerenciar categorias',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _abrirSeletorCategoria() async {
    if (_isLoading || _carregandoCategorias) return;

    final _CategoriaSelectionResult?
    result = await showModalBottomSheet<_CategoriaSelectionResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x47000000),
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.46,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return _MobileBottomSheetFrame(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _CategoriaSelectorSheet(
                title: _t(
                  'produto.mobile.categorySheetTitle',
                  'Selecionar categoria',
                ),
                subtitle: _t(
                  'produto.mobile.categorySheetSubtitle',
                  'A lista mostra apenas categorias compatíveis com o tipo atual.',
                ),
                searchHint: _t(
                  'produto.mobile.categorySearchHint',
                  'Buscar categoria',
                ),
                noCategoryLabel: _t(
                  'produto.mobile.categoryNone',
                  'Sem categoria',
                ),
                noCategorySubtitle: _t(
                  'produto.mobile.categoryNoneSubtitle',
                  'Salvar este cadastro sem vínculo de categoria.',
                ),
                selectedLabel: _t('common.selected', 'Selecionado'),
                inactiveLabel: _t('common.inactive', 'Inativa'),
                emptyTitle: _t(
                  'produto.mobile.categoryEmptySearchTitle',
                  'Nenhuma categoria encontrada',
                ),
                emptySubtitle: _t(
                  'produto.mobile.categoryEmptySearchSubtitle',
                  'Ajuste a busca ou gerencie as categorias do catálogo.',
                ),
                manageLabel: _t(
                  'produto.mobile.manageCategories',
                  'Gerenciar categorias',
                ),
                categories: _categoriasCompativeis,
                selectedCategoryId: _categoriaSelecionadaId,
                scrollController: scrollController,
                onManageCategories: () {
                  Navigator.of(sheetContext).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _abrirGestaoCategorias();
                    }
                  });
                },
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _categoriaSelecionadaId = result.id;
      final CategoriaCatalogoModel? categoria = _categoriaSelecionadaEncontrada;
      _categoriaSelecionadaNome = categoria?.nome;
    });
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: SixMobilePalette.onPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: SixMobilePalette.onPrimary.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(
                  _tipoSelecionado == ProdutoCadastroFormUtils.tipoServico
                      ? Icons.design_services_outlined
                      : Icons.inventory_2_outlined,
                  color: SixMobilePalette.onPrimary,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isModoEdicao
                          ? _t(
                            'produto.mobile.editProductTitle',
                            'Editar produto',
                          )
                          : _t(
                            'produto.mobile.newProductTitle',
                            'Novo produto',
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _isModoEdicao
                          ? _t(
                            'produto.mobile.editProductSubtitle',
                            'Atualize os dados, fotos e status do cadastro.',
                          )
                          : _t(
                            'produto.mobile.newProductSubtitle',
                            'Cadastre dados comerciais, estoque e até 5 imagens.',
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.heroSupportingText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          _buildJourneyProgress(embeddedInHeader: true),
        ],
      ),
    );
  }

  Widget _buildFieldPair({required Widget first, required Widget second}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: <Widget>[first, SizedBox(height: 12), second],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: first),
            SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildStaggeredEntry({
    required Duration delay,
    required Widget child,
  }) {
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery?.disableAnimations == true ||
        mediaQuery?.accessibleNavigation == true) {
      return child;
    }

    return SixStaggeredEntry(delay: delay, child: child);
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _softAccentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _accentColor, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildFotoCard() {
    final slot = _slotSelecionado;

    return _buildSectionCard(
      title: _t('produto.mobile.photosTitle', 'Fotos do produto'),
      subtitle: _t(
        'produto.mobile.photosSubtitle',
        'Use câmera ou upload. O backend receberá até 5 imagens.',
      ),
      icon: Icons.photo_camera_back_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallInfoPill(
                icon: Icons.collections_outlined,
                label:
                    '$_totalImagensSelecionadas / $_maxImageSlots '
                    '${_t('produto.mobile.imagesCountSuffix', 'imagens')}',
              ),
              SizedBox(width: 8),
              _SmallInfoPill(
                icon: Icons.ads_click_outlined,
                label:
                    '${_t('produto.mobile.imageSlot', 'Slot')} '
                    '${_slotSelecionadoIndex + 1}',
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildImagemAtiva(slot),
          SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed:
                    _isLoading || slot.isLoading
                        ? null
                        : () => _selecionarImagem(
                          ImageSource.camera,
                          _slotSelecionadoIndex,
                        ),
                icon: Icon(Icons.photo_camera_outlined),
                label: Text(_t('produto.mobile.takePhoto', 'Tirar foto')),
              ),
              OutlinedButton.icon(
                onPressed:
                    _isLoading || slot.isLoading
                        ? null
                        : () => _selecionarImagem(
                          ImageSource.gallery,
                          _slotSelecionadoIndex,
                        ),
                icon: Icon(Icons.upload_file_outlined),
                label: Text(
                  slot.image == null
                      ? _t('produto.mobile.uploadShort', 'Upload')
                      : _t('produto.mobile.changeImage', 'Trocar'),
                ),
              ),
              if (slot.image != null)
                TextButton.icon(
                  onPressed:
                      _isLoading || slot.isLoading
                          ? null
                          : () => _removerImagemDoSlot(_slotSelecionadoIndex),
                  icon: Icon(Icons.delete_outline),
                  label: Text(_t('produto.mobile.remove', 'Remover')),
                ),
            ],
          ),
          SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: ListView.separated(
              controller: _slotsScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _maxImageSlots,
              separatorBuilder: (_, __) => SizedBox(width: 10),
              itemBuilder: (context, index) => _buildMiniaturaSlot(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagemAtiva(_ProdutoImagemSlot slot) {
    final bool hasImage = slot.image != null;

    return Semantics(
      button: true,
      label: _t('produto.mobile.imageSlotAction', 'Alterar imagem do produto'),
      child: InkWell(
        onTap: _isLoading ? null : _abrirOpcoesImagem,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 210,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _softAccentColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasImage ? _accentColor : _borderColor,
              width: hasImage ? 1.4 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    hasImage
                        ? _buildImageContent(slot, fit: BoxFit.cover)
                        : _buildImagePlaceholder(),
              ),
              if (slot.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.28),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (hasImage)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      slot.image?.origem == 'UPLOAD'
                          ? _t('produto.mobile.imageUploadTag', 'Upload mobile')
                          : _t('produto.mobile.imageSavedTag', 'Imagem salva'),
                      style: TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 10,
                bottom: 10,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black.withValues(alpha: 0.56),
                  child: Icon(
                    Icons.more_horiz,
                    color: SixMobilePalette.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 42, color: _accentColor),
        SizedBox(height: 10),
        Text(
          _t('produto.mobile.emptyImageSlotTitle', 'Nenhuma imagem neste slot'),
          textAlign: TextAlign.center,
          style: TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 4),
        Text(
          _t(
            'produto.mobile.emptyImageSlotSubtitle',
            'Toque para tirar foto ou fazer upload',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: _mutedTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMiniaturaSlot(int index) {
    final slot = _imagemSlots[index];
    final bool selected = index == _slotSelecionadoIndex;
    final bool hasImage = slot.image != null;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${_t('produto.mobile.imageSlot', 'Slot')} ${index + 1}'
          '${hasImage ? ', ${_t('produto.mobile.withImage', 'com imagem')}' : ''}',
      child: InkWell(
        onTap: () => setState(() => _slotSelecionadoIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 82,
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? _softAccentColor : _surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _accentColor : _borderColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _softNeutralColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      slot.isLoading
                          ? Center(
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _accentColor,
                              ),
                            ),
                          )
                          : hasImage
                          ? _buildImageContent(slot, fit: BoxFit.cover)
                          : Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: _mutedTextColor,
                              size: 20,
                            ),
                          ),
                ),
              ),
              SizedBox(height: 5),
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: selected ? _accentColor : _mutedTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(_ProdutoImagemSlot slot, {required BoxFit fit}) {
    final bytes =
        slot.previewBytes ??
        _decodeBase64Image(slot.image?.imagemBase64) ??
        _decodeDataUrl(slot.image?.url);

    if (bytes != null) {
      return Image.memory(bytes, fit: fit, width: double.infinity);
    }

    final url = slot.image?.url;
    if (url != null && url.trim().isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) {
          return Center(child: Icon(Icons.broken_image_outlined));
        },
      );
    }

    return Center(child: Icon(Icons.broken_image_outlined));
  }

  Uint8List? _decodeDataUrl(String? value) {
    if (value == null || !value.startsWith('data:image')) {
      return null;
    }

    return _decodeBase64Image(value);
  }

  Uint8List? _decodeBase64Image(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final payload = value.contains(',') ? value.split(',').last : value;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  Widget _buildDadosPrincipaisCard() {
    return _buildSectionCard(
      title: _t('produto.mobile.mainDataTitle', 'Dados principais'),
      subtitle: _t(
        'produto.mobile.mainDataSubtitle',
        'Identificação comercial e classificação.',
      ),
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _nomeController,
            label: _t('produto.mobile.productNameLabel', 'Nome do produto'),
            hintText: _t(
              'produto.mobile.productNameHint',
              'Ex.: Tela iPhone 13',
            ),
            requiredField: true,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _codigoController,
            label: _t('produto.mobile.skuLabel', 'Código de barras / SKU'),
            hintText: _t('produto.mobile.skuHint', 'Ex.: 789000000001'),
          ),
          SizedBox(height: 12),
          _buildTipoField(),
          SizedBox(height: 12),
          _buildCategoriaField(),
          SizedBox(height: 12),
          _buildTextField(
            controller: _modeloController,
            label: _t('produto.mobile.modelLabel', 'Modelo'),
            hintText: ProdutoCadastroFormUtils.modeloPadrao,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _grupoController,
            label: _t('produto.mobile.groupLabel', 'Grupo'),
            hintText: _t(
              'produto.mobile.groupHint',
              'Ex.: Peças, acessórios, mão de obra',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstoquePrecoCard() {
    return _buildSectionCard(
      title: _t('produto.mobile.priceStockTitle', 'Preço e estoque'),
      subtitle: _t(
        'produto.mobile.priceStockSubtitle',
        'Valores comerciais e limites de controle.',
      ),
      icon: Icons.sell_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _precoVendaController,
            label: _t('produto.mobile.salePriceLabel', 'Preço de venda'),
            hintText: _decimalInputHint(),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 12),
          _buildFieldPair(
            first: _buildTextField(
              controller: _estoqueMinController,
              label: _t('produto.mobile.minStockLabel', 'Estoque mín.'),
              keyboardType: TextInputType.number,
            ),
            second: _buildTextField(
              controller: _estoqueMaxController,
              label: _t('produto.mobile.maxStockLabel', 'Estoque máx.'),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(height: 12),
          _buildFieldPair(
            first: _buildTextField(
              controller: _quantidadeEntradaController,
              label: _t('produto.mobile.entryQtyLabel', 'Entrada'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            second: _buildTextField(
              controller: _valorCustoController,
              label: _t('produto.mobile.costLabel', 'Custo'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _valorVendaEntradaController,
            label: _t(
              'produto.mobile.entrySaleValueLabel',
              'Valor da venda na movimentação',
            ),
            hintText: _t(
              'produto.mobile.entrySaleValueHint',
              'Usa o preço de venda se ficar vazio',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildRegrasCard() {
    return _buildSectionCard(
      title: _t('produto.mobile.rulesTitle', 'Regras e status'),
      subtitle: _t(
        'produto.mobile.rulesSubtitle',
        'Configurações rápidas para operação no balcão.',
      ),
      icon: Icons.settings_suggest_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _tempoGarantiaController,
            label: _t('produto.mobile.warrantyLabel', 'Tempo da garantia'),
            hintText: _t('produto.mobile.warrantyHint', 'Ex.: 90 dias'),
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _valorComissaoController,
            label: _t(
              'produto.mobile.commissionValueLabel',
              'Valor fixo da comissão',
            ),
            hintText: _decimalInputHint(),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 12),
          _SwitchCard(
            title: _t('produto.mobile.activeProductTitle', 'Produto ativo'),
            subtitle: _t(
              'produto.mobile.activeProductSubtitle',
              'Disponível para venda e listagens.',
            ),
            value: _ativo,
            onChanged:
                _isLoading ? null : (value) => setState(() => _ativo = value),
          ),
          SizedBox(height: 10),
          _SwitchCard(
            title: _t(
              'produto.mobile.changePriceAtSaleTitle',
              'Alterar valor na hora',
            ),
            subtitle: _t(
              'produto.mobile.changePriceAtSaleSubtitle',
              'Permite ajustar o valor durante o atendimento.',
            ),
            value: _podeAlterarValorNaHora,
            onChanged:
                _isLoading
                    ? null
                    : (value) =>
                        setState(() => _podeAlterarValorNaHora = value),
          ),
          SizedBox(height: 10),
          _SwitchCard(
            title: _t(
              'produto.mobile.specialCommissionTitle',
              'Comissão especial',
            ),
            subtitle: _t(
              'produto.mobile.specialCommissionSubtitle',
              'Aplica comissão específica para este item.',
            ),
            value: _produtoTemComissaoEspecial,
            onChanged:
                _isLoading
                    ? null
                    : (value) =>
                        setState(() => _produtoTemComissaoEspecial = value),
          ),
        ],
      ),
    );
  }

  bool get _cadastroCompleto => _tipoCadastro == 'COMPLETO';

  int get _totalEtapas => _cadastroCompleto ? 5 : 3;

  List<String> get _rotulosEtapas =>
      _cadastroCompleto
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

  Widget _buildTipoCadastroSelector() {
    return _buildSectionCard(
      title: _t('produto.journey.modeTitle', 'Escolha o nível do cadastro'),
      subtitle: _t(
        'produto.journey.modeSubtitle',
        'Você pode começar simples e completar as informações depois.',
      ),
      icon: Icons.route_outlined,
      child: Column(
        children: <Widget>[
          _CadastroModeOptionMobile(
            icon: Icons.bolt_outlined,
            title: _t('produto.journey.summaryTitle', 'Cadastro resumido'),
            subtitle: _t(
              'produto.journey.summarySubtitle',
              'Para colocar o item em operação rapidamente.',
            ),
            selected: !_cadastroCompleto,
            onTap: () => _selecionarTipoCadastro('RESUMIDO'),
          ),
          SizedBox(height: 10),
          _CadastroModeOptionMobile(
            icon: Icons.fact_check_outlined,
            title: _t('produto.journey.completeTitle', 'Cadastro completo'),
            subtitle: _t(
              'produto.journey.completeSubtitle',
              'Inclui regras operacionais e dados fiscais opcionais.',
            ),
            selected: _cadastroCompleto,
            onTap: () => _selecionarTipoCadastro('COMPLETO'),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyProgress({bool embeddedInHeader = false}) {
    final List<String> rotulos = _rotulosEtapas;
    return Semantics(
      container: true,
      label:
          '${_t('produto.journey.step', 'Etapa')} ${_etapaAtual + 1} '
          '${_t('produto.journey.of', 'de')} $_totalEtapas',
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              embeddedInHeader
                  ? _surfaceColor.withValues(alpha: 0.98)
                  : _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                embeddedInHeader
                    ? SixMobilePalette.onPrimary.withValues(alpha: 0.10)
                    : _borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${_t('produto.journey.step', 'Etapa')} ${_etapaAtual + 1} '
              '${_t('produto.journey.of', 'de')} $_totalEtapas · ${rotulos[_etapaAtual]}',
              style: TextStyle(
                color: _titleTextColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: List<Widget>.generate(rotulos.length, (int index) {
                final bool concluida = index < _etapaAtual;
                final bool atual = index == _etapaAtual;
                return Expanded(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    height: 5,
                    margin: EdgeInsets.only(
                      right: index == rotulos.length - 1 ? 0 : 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          concluida || atual
                              ? _accentColor
                              : SixMobilePalette.activeBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhesComplementaresCard() {
    return _buildSectionCard(
      title: _t('produto.journey.detailsTitle', 'Detalhes complementares'),
      subtitle: _t(
        'produto.journey.detailsSubtitle',
        'Informações opcionais para busca, catálogo e organização.',
      ),
      icon: Icons.notes_outlined,
      child: Column(
        children: <Widget>[
          _buildTextField(
            controller: _descricaoController,
            label: _t('produto.fields.description', 'Descrição'),
            hintText: _t(
              'produto.fields.descriptionHint',
              'Características ou observações do item',
            ),
            maxLines: 3,
          ),
          SizedBox(height: 12),
          _buildTextField(
            controller: _codigoInternoController,
            label: _t('produto.fields.internalCode', 'Código interno'),
          ),
          SizedBox(height: 12),
          _buildFieldPair(
            first: _buildTextField(
              controller: _marcaController,
              label: _t('produto.fields.brand', 'Marca'),
            ),
            second: _buildTextField(
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

  Future<void> _abrirSeletorCategoriaUnidade() async {
    final String? selecionada = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (BuildContext context) {
        const List<String> categorias = <String>[
          'UNIDADE',
          'AREA',
          'DISTANCIA',
          'VOLUME',
          'TEMPO',
          'PESO',
          'MOEDA',
        ];
        return _MobileBottomSheetFrame(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.78,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _MobileSheetHandle(),
                SizedBox(height: 16),
                _SheetTitleBlock(
                  icon: Icons.straighten_outlined,
                  title: _t(
                    'produto.fields.unitCategory',
                    'Categoria da unidade',
                  ),
                  subtitle: _t(
                    'produto.fields.unitCategoryHelp',
                    'Escolha como o item é medido na operação.',
                  ),
                ),
                SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categorias.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String codigo = categorias[index];
                      return _SelectionOptionTile(
                        icon: Icons.straighten_outlined,
                        title: _categoriaUnidadeLabel(codigo),
                        subtitle: '',
                        selected: codigo == _categoriaUnidadeMedida,
                        onTap: () => Navigator.of(context).pop(codigo),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selecionada == null) return;
    setState(() => _categoriaUnidadeMedida = selecionada);
  }

  Widget _buildRegrasOperacionaisCard() {
    return _buildSectionCard(
      title: _t('produto.journey.operationalRulesTitle', 'Regras operacionais'),
      subtitle: _t(
        'produto.journey.operationalRulesSubtitle',
        'Defina como este item será medido, vendido e controlado.',
      ),
      icon: Icons.tune_outlined,
      child: Column(
        children: <Widget>[
          _MobileSelectorField(
            label: _t('produto.fields.unitCategory', 'Categoria da unidade'),
            value: _categoriaUnidadeLabel(_categoriaUnidadeMedida),
            icon: Icons.straighten_outlined,
            onTap: _abrirSeletorCategoriaUnidade,
          ),
          SizedBox(height: 12),
          _buildFieldPair(
            first: _buildTextField(
              controller: _unidadeMedidaController,
              label: _t('produto.fields.unitCode', 'Unidade de medida'),
              hintText: _t('produto.fields.unitCodeHint', 'Ex.: UN, KG, M'),
            ),
            second: _buildTextField(
              controller: _quantidadeMinimaVendaController,
              label: _t(
                'produto.fields.minimumSaleQuantity',
                'Quantidade mínima',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          SizedBox(height: 12),
          _SwitchCard(
            title: _t('produto.fields.trackStock', 'Controlar estoque'),
            subtitle: _t(
              'produto.fields.trackStockHelp',
              'Movimenta saldo nas entradas e vendas.',
            ),
            value: _controlaEstoque,
            onChanged:
                _isLoading
                    ? null
                    : (bool value) => setState(() => _controlaEstoque = value),
          ),
          SizedBox(height: 10),
          _SwitchCard(
            title: _t(
              'produto.fields.allowFractionalSale',
              'Permitir venda fracionada',
            ),
            subtitle: _t(
              'produto.fields.allowFractionalSaleHelp',
              'Aceita quantidades decimais, como peso, área ou volume.',
            ),
            value: _permiteVendaFracionada,
            onChanged:
                _isLoading
                    ? null
                    : (bool value) =>
                        setState(() => _permiteVendaFracionada = value),
          ),
          SizedBox(height: 10),
          _SwitchCard(
            title: _t(
              'produto.fields.allowNegativeStock',
              'Permitir estoque negativo',
            ),
            subtitle: _t(
              'produto.fields.allowNegativeStockHelp',
              'Mantém a venda disponível mesmo sem saldo suficiente.',
            ),
            value: _permiteEstoqueNegativo,
            onChanged:
                _isLoading
                    ? null
                    : (bool value) =>
                        setState(() => _permiteEstoqueNegativo = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDadosFiscaisCard() {
    return _buildSectionCard(
      title: _t('produto.journey.fiscalTitle', 'Dados fiscais e contábeis'),
      subtitle: _t(
        'produto.journey.fiscalSubtitle',
        'Preencha somente o que sua operação ou contador exigir.',
      ),
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: <Widget>[
          _buildFieldPair(
            first: _buildTextField(
              controller: _ncmController,
              label: _t('produto.fields.ncm', 'NCM'),
            ),
            second: _buildTextField(
              controller: _cestController,
              label: _t('produto.fields.cest', 'CEST'),
            ),
          ),
          SizedBox(height: 12),
          _buildFieldPair(
            first: _buildTextField(
              controller: _cfopController,
              label: _t('produto.fields.cfop', 'CFOP'),
            ),
            second: _buildTextField(
              controller: _origemMercadoriaController,
              label: _t('produto.fields.goodsOrigin', 'Origem da mercadoria'),
            ),
          ),
          SizedBox(height: 12),
          _buildFieldPair(
            first: _buildTextField(
              controller: _cstIcmsController,
              label: _t('produto.fields.cstIcms', 'CST ICMS'),
            ),
            second: _buildTextField(
              controller: _csosnController,
              label: _t('produto.fields.csosn', 'CSOSN'),
            ),
          ),
          SizedBox(height: 12),
          _buildFieldPair(
            first: _buildTextField(
              controller: _cstPisController,
              label: _t('produto.fields.cstPis', 'CST PIS'),
            ),
            second: _buildTextField(
              controller: _cstCofinsController,
              label: _t('produto.fields.cstCofins', 'CST COFINS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    final LocaleSettingsProvider locale =
        context.watch<LocaleSettingsProvider>();
    final double preco = ProdutoCadastroFormUtils.parseDecimal(
      _precoVendaController.text,
      numberFormat: _numberFormat(),
    );
    return _buildSectionCard(
      title: _t('produto.journey.reviewTitle', 'Revise antes de concluir'),
      subtitle: _t(
        'produto.journey.reviewSubtitle',
        'Você ainda poderá editar o produto depois do cadastro.',
      ),
      icon: Icons.checklist_rtl_outlined,
      child: Column(
        children: <Widget>[
          _ProdutoReviewRowMobile(
            label: _t('produto.mobile.productNameLabel', 'Nome do produto'),
            value:
                _nomeController.text.trim().isEmpty
                    ? _t('common.notInformed', 'Não informado')
                    : _nomeController.text.trim(),
          ),
          _ProdutoReviewRowMobile(
            label: _t('produto.mobile.salePriceLabel', 'Preço de venda'),
            value: locale.formatCurrency(preco),
          ),
          _ProdutoReviewRowMobile(
            label: _t('produto.fields.unitCode', 'Unidade de medida'),
            value:
                _unidadeMedidaController.text.trim().isEmpty
                    ? 'UN'
                    : _unidadeMedidaController.text.trim().toUpperCase(),
          ),
          _ProdutoReviewRowMobile(
            label: _t('produto.journey.modeLabel', 'Tipo de cadastro'),
            value:
                _cadastroCompleto
                    ? _t('produto.journey.completeTitle', 'Cadastro completo')
                    : _t('produto.journey.summaryTitle', 'Cadastro resumido'),
            isLast: true,
          ),
        ],
      ),
    );
  }

  List<Widget> _conteudoDaEtapa() {
    if (_etapaAtual == 0) {
      return <Widget>[
        _buildDadosPrincipaisCard(),
        if (_cadastroCompleto) ...<Widget>[
          SizedBox(height: 16),
          _buildDetalhesComplementaresCard(),
        ],
      ];
    }
    if (_etapaAtual == 1) {
      return <Widget>[
        _buildEstoquePrecoCard(),
        SizedBox(height: 16),
        _buildRegrasCard(),
      ];
    }
    if (_cadastroCompleto && _etapaAtual == 2) {
      return <Widget>[_buildRegrasOperacionaisCard()];
    }
    if (_cadastroCompleto && _etapaAtual == 3) {
      return <Widget>[_buildDadosFiscaisCard()];
    }
    return <Widget>[_buildReviewCard(), SizedBox(height: 16), _buildFotoCard()];
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
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title:
          _isModoEdicao
              ? _t('produto.mobile.editProductTitle', 'Editar produto')
              : _t('produto.mobile.createProductTitle', 'Cadastrar produto'),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 4,
      scrollEffectOffset: 24,
      scrolledSurfaceOpacity: 0.66,
      actions: <Widget>[
        _buildHeaderAction(
          active: _favorito,
          onPressed: _alternarFavorito,
          tooltip:
              _favorito
                  ? _t(
                    'produto.favorite.removeTooltip',
                    'Remover dos favoritos',
                  )
                  : _t('produto.favorite.addTooltip', 'Marcar como favorito'),
          icon:
              _favorito
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
        ),
        _buildHeaderAction(
          active: _disponivelParaCatalogo,
          onPressed: _alternarDisponivelParaCatalogo,
          tooltip:
              _disponivelParaCatalogo
                  ? _t(
                    'produto.catalog.disableTooltip',
                    'Retirar da disponibilidade para catálogo',
                  )
                  : _t(
                    'produto.catalog.enableTooltip',
                    'Disponibilizar para catálogo',
                  ),
          icon:
              _disponivelParaCatalogo
                  ? Icons.storefront_rounded
                  : Icons.storefront_outlined,
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 112),
              children: [
                _buildStaggeredEntry(
                  delay: Duration(milliseconds: 60),
                  child: _buildHeaderCard(),
                ),
                SizedBox(height: 16),
                if (_etapaAtual == 0) ...<Widget>[
                  _buildStaggeredEntry(
                    delay: Duration(milliseconds: 110),
                    child: _buildTipoCadastroSelector(),
                  ),
                  SizedBox(height: 16),
                ],
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey<String>('$_tipoCadastro-$_etapaAtual'),
                    children: _conteudoDaEtapa(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildBottomActionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          border: Border(top: BorderSide(color: _borderColor)),
          boxShadow: [
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _voltarEtapa,
                child: Text(
                  _etapaAtual == 0
                      ? _t('common.cancel', 'Cancelar')
                      : _t('common.back', 'Voltar'),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed:
                    _isLoading
                        ? null
                        : (_etapaAtual == _totalEtapas - 1
                            ? _salvar
                            : _avancarEtapa),
                icon:
                    _isLoading
                        ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SixMobilePalette.onPrimary,
                          ),
                        )
                        : Icon(
                          _etapaAtual == _totalEtapas - 1
                              ? Icons.save_outlined
                              : Icons.arrow_forward_rounded,
                        ),
                label: Text(
                  _isLoading
                      ? _t('common.saving', 'Salvando...')
                      : (_etapaAtual < _totalEtapas - 1
                          ? _t('common.continue', 'Continuar')
                          : (_isModoEdicao
                              ? _t('produto.mobile.saveEdit', 'Salvar edição')
                              : _t(
                                'produto.mobile.saveProduct',
                                'Salvar produto',
                              ))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CadastroModeOptionMobile extends StatelessWidget {
  const _CadastroModeOptionMobile({
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
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color:
            selected
                ? SixMobilePalette.softAccentSurface
                : SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 180),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    selected
                        ? SixMobilePalette.highlightedBorder
                        : SixMobilePalette.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.iconSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: SixMobilePalette.accent),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color:
                      selected
                          ? SixMobilePalette.accent
                          : SixMobilePalette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProdutoReviewRowMobile extends StatelessWidget {
  const _ProdutoReviewRowMobile({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(bottom: BorderSide(color: SixMobilePalette.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: SixMobilePalette.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriaSelectionResult {
  const _CategoriaSelectionResult(this.id);

  final String? id;
}

class _MobileBottomSheetFrame extends StatelessWidget {
  const _MobileBottomSheetFrame({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: padding,
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.heroShadow,
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _MobileSheetHandle extends StatelessWidget {
  const _MobileSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: SixMobilePalette.activeBorder,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _MobileSelectorField extends StatelessWidget {
  const _MobileSelectorField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool effectiveEnabled = enabled && !loading;

    return Semantics(
      button: true,
      enabled: effectiveEnabled,
      label: '$label. $value',
      child: Material(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: effectiveEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: BoxConstraints(minHeight: 58),
            padding: EdgeInsets.fromLTRB(14, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    effectiveEnabled
                        ? SixMobilePalette.border
                        : SixMobilePalette.activeBorder,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.softAccentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: SixMobilePalette.accent, size: 19),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              effectiveEnabled
                                  ? SixMobilePalette.titleText
                                  : SixMobilePalette.mutedText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                if (loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SixMobilePalette.accent,
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color:
                        effectiveEnabled
                            ? SixMobilePalette.accent
                            : SixMobilePalette.mutedText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipoProdutoSelectorSheet extends StatelessWidget {
  const _TipoProdutoSelectorSheet({
    required this.title,
    required this.subtitle,
    required this.selectedType,
    required this.productLabel,
    required this.productSubtitle,
    required this.serviceLabel,
    required this.serviceSubtitle,
  });

  final String title;
  final String subtitle;
  final String selectedType;
  final String productLabel;
  final String productSubtitle;
  final String serviceLabel;
  final String serviceSubtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _MobileSheetHandle(),
          SizedBox(height: 16),
          _SheetTitleBlock(
            icon: Icons.tune_rounded,
            title: title,
            subtitle: subtitle,
          ),
          SizedBox(height: 16),
          _SelectionOptionTile(
            icon: Icons.inventory_2_outlined,
            title: productLabel,
            subtitle: productSubtitle,
            selected: selectedType == ProdutoCadastroFormUtils.tipoProduto,
            onTap:
                () => Navigator.of(
                  context,
                ).pop(ProdutoCadastroFormUtils.tipoProduto),
          ),
          SizedBox(height: 10),
          _SelectionOptionTile(
            icon: Icons.design_services_outlined,
            title: serviceLabel,
            subtitle: serviceSubtitle,
            selected: selectedType == ProdutoCadastroFormUtils.tipoServico,
            onTap:
                () => Navigator.of(
                  context,
                ).pop(ProdutoCadastroFormUtils.tipoServico),
          ),
        ],
      ),
    );
  }
}

class _CategoriaSelectorSheet extends StatefulWidget {
  const _CategoriaSelectorSheet({
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.noCategoryLabel,
    required this.noCategorySubtitle,
    required this.selectedLabel,
    required this.inactiveLabel,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.manageLabel,
    required this.categories,
    required this.selectedCategoryId,
    required this.scrollController,
    required this.onManageCategories,
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final String noCategoryLabel;
  final String noCategorySubtitle;
  final String selectedLabel;
  final String inactiveLabel;
  final String emptyTitle;
  final String emptySubtitle;
  final String manageLabel;
  final List<CategoriaCatalogoModel> categories;
  final String? selectedCategoryId;
  final ScrollController scrollController;
  final VoidCallback onManageCategories;

  @override
  State<_CategoriaSelectorSheet> createState() =>
      _CategoriaSelectorSheetState();
}

class _CategoriaSelectorSheetState extends State<_CategoriaSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoriaCatalogoModel> get _filteredCategories {
    final String normalizedQuery = _normalize(_query);
    if (normalizedQuery.isEmpty) return widget.categories;

    return widget.categories
        .where((CategoriaCatalogoModel categoria) {
          return _normalize(
            '${categoria.nome} ${categoria.descricao}',
          ).contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  String _normalize(String value) => value.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final List<CategoriaCatalogoModel> filtered = _filteredCategories;

    return Semantics(
      container: true,
      label: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _MobileSheetHandle(),
          SizedBox(height: 16),
          _SheetTitleBlock(
            icon: Icons.category_outlined,
            title: widget.title,
            subtitle: widget.subtitle,
          ),
          SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (String value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            cursorColor: SixMobilePalette.accent,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: SixMobilePalette.accent,
              ),
              suffixIcon:
                  _query.isEmpty
                      ? null
                      : IconButton(
                        tooltip: widget.searchHint,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: Icon(Icons.close_rounded),
                      ),
              filled: true,
              fillColor: SixMobilePalette.softNeutralSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: <Widget>[
                _SelectionOptionTile(
                  icon: Icons.not_interested_rounded,
                  title: widget.noCategoryLabel,
                  subtitle: widget.noCategorySubtitle,
                  selected: widget.selectedCategoryId == null,
                  trailingLabel:
                      widget.selectedCategoryId == null
                          ? widget.selectedLabel
                          : null,
                  onTap:
                      () => Navigator.of(
                        context,
                      ).pop(const _CategoriaSelectionResult(null)),
                ),
                SizedBox(height: 10),
                ...filtered.map((CategoriaCatalogoModel categoria) {
                  final bool selected =
                      categoria.id == widget.selectedCategoryId;
                  final String subtitle =
                      categoria.descricao.trim().isNotEmpty
                          ? categoria.descricao
                          : (categoria.ativo ? '' : widget.inactiveLabel);

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _SelectionOptionTile(
                      icon: Icons.sell_outlined,
                      title:
                          categoria.ativo
                              ? categoria.nome
                              : '${categoria.nome} (${widget.inactiveLabel})',
                      subtitle: subtitle,
                      selected: selected,
                      trailingLabel: selected ? widget.selectedLabel : null,
                      onTap:
                          () => Navigator.of(
                            context,
                          ).pop(_CategoriaSelectionResult(categoria.id)),
                    ),
                  );
                }),
                if (filtered.isEmpty) ...<Widget>[
                  SizedBox(height: 8),
                  _SelectorEmptyState(
                    title: widget.emptyTitle,
                    subtitle: widget.emptySubtitle,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onManageCategories,
              icon: Icon(Icons.category_outlined),
              label: Text(
                widget.manageLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTitleBlock extends StatelessWidget {
  const _SheetTitleBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SixMobilePalette.titleText,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SixMobilePalette.mutedText,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionOptionTile extends StatelessWidget {
  const _SelectionOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: trailingLabel == null ? title : '$title, $trailingLabel',
      child: Material(
        color:
            selected
                ? SixMobilePalette.softAccentSurface
                : SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    selected
                        ? SixMobilePalette.highlightedBorder
                        : SixMobilePalette.border,
                width: selected ? 1.3 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SixMobilePalette.activeBorder),
                  ),
                  child: Icon(icon, color: SixMobilePalette.accent, size: 21),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8),
                if (trailingLabel != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: SixMobilePalette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trailingLabel!,
                      style: TextStyle(
                        color: SixMobilePalette.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color:
                        selected
                            ? SixMobilePalette.accent
                            : SixMobilePalette.mutedText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorEmptyState extends StatelessWidget {
  const _SelectorEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.search_off_rounded,
            color: SixMobilePalette.mutedText,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoPill extends StatelessWidget {
  const _SmallInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: SixMobilePalette.softAccentSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: SixMobilePalette.accent),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SixMobilePalette.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageActionTile extends StatelessWidget {
  const _ImageActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDanger ? SixMobilePalette.error : SixMobilePalette.accent;
    final background =
        isDanger
            ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF450A0A)
                : const Color(0xFFFEF2F2))
            : SixMobilePalette.softAccentSurface;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: foreground),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              isDanger
                                  ? SixMobilePalette.error
                                  : SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: SixMobilePalette.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
