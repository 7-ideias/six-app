import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/models/produto_imagem_model.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/services/categoria_catalogo/categoria_catalogo_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/categorias_produtos_servicos_mobile_screen.dart';

class CadastroProdutoMobileScreen extends StatefulWidget {
  const CadastroProdutoMobileScreen({
    super.key,
    this.produtoParaEdicao,
    this.tipoInicial = 'PRODUTO',
  });

  final ProdutoModel? produtoParaEdicao;
  final String tipoInicial;

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
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;
  static const Color _surfaceColor = SixMobilePalette.surface;
  static const Color _mutedTextColor = SixMobilePalette.mutedText;
  static const Color _titleTextColor = SixMobilePalette.titleText;
  static const Color _borderColor = SixMobilePalette.border;
  static const Color _softAccentColor = SixMobilePalette.softAccentSurface;
  static const Color _softNeutralColor = SixMobilePalette.softNeutralSurface;

  static const int _maxImageSlots = 5;

  final _formKey = GlobalKey<FormState>();
  final ProdutoService _produtoService = ProdutoService();
  final CategoriaCatalogoApiClient _categoriaApiClient =
      HttpCategoriaCatalogoApiClient();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _slotsScrollController = ScrollController();

  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();
  final _modeloController = TextEditingController(text: 'UNIDADE');
  final _grupoController = TextEditingController();
  final _precoVendaController = TextEditingController();
  final _estoqueMinController = TextEditingController(text: '1');
  final _estoqueMaxController = TextEditingController(text: '1000');
  final _tempoGarantiaController = TextEditingController();
  final _valorComissaoController = TextEditingController(text: '0');
  final _quantidadeEntradaController = TextEditingController(text: '1');
  final _valorCustoController = TextEditingController(text: '0');
  final _valorVendaEntradaController = TextEditingController(text: '0');

  late String _tipoSelecionado;
  String? _produtoEmEdicaoId;
  List<CategoriaCatalogoModel> _categoriasCatalogo =
      const <CategoriaCatalogoModel>[];
  bool _carregandoCategorias = false;
  String? _erroCategorias;
  String? _categoriaSelecionadaId;
  String? _categoriaSelecionadaNome;

  bool _ativo = true;
  bool _podeAlterarValorNaHora = false;
  bool _produtoTemComissaoEspecial = false;
  bool _isLoading = false;
  bool _slotsHintPlayed = false;

  final List<_ProdutoImagemSlot> _imagemSlots =
      List<_ProdutoImagemSlot>.generate(
        _maxImageSlots,
        (_) => _ProdutoImagemSlot(),
        growable: false,
      );

  int _slotSelecionadoIndex = 0;

  bool get _isModoEdicao => widget.produtoParaEdicao != null;

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  String _tipoLabel(String tipo) {
    return _normalizarTipo(tipo) == 'SERVICO'
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
    super.dispose();
  }

  String _normalizarTipo(String value) {
    final tipo = value.trim().toUpperCase();
    if (tipo == 'SERVICO' || tipo == 'SERVIÇO') {
      return 'SERVICO';
    }
    return 'PRODUTO';
  }

  void _preencherCamposSeModoEdicao() {
    final produto = widget.produtoParaEdicao;
    if (produto == null) {
      return;
    }

    _produtoEmEdicaoId = produto.id;
    _ativo = produto.ativo;
    _codigoController.text = produto.codigoDeBarras;
    _nomeController.text = produto.nomeProduto;
    _tipoSelecionado = _normalizarTipo(produto.tipoProduto);
    _categoriaSelecionadaId = produto.objCategoria?.idCategoria;
    _categoriaSelecionadaNome = produto.objCategoria?.nomeCategoria;
    _modeloController.text =
        produto.modeloProduto.trim().isEmpty
            ? 'UNIDADE'
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

    final imagens = produto.imagens ?? const <ProdutoImagemModel>[];
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
    final String? id = _categoriaSelecionadaId;
    if (id == null || id.trim().isEmpty) return null;

    for (final CategoriaCatalogoModel categoria in _categoriasCatalogo) {
      if (categoria.id == id) return categoria;
    }

    return null;
  }

  bool _categoriaCompativelComTipoAtual(CategoriaCatalogoModel categoria) {
    return categoria.tipo == 'AMBOS' || categoria.tipo == _tipoSelecionado;
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

  ObjCategoria? _montarObjCategoria() {
    final String? id = _categoriaSelecionadaId;
    if (id == null || id.trim().isEmpty) return null;

    final CategoriaCatalogoModel? categoria = _categoriaSelecionadaEncontrada;
    return ObjCategoria(
      idCategoria: id.trim(),
      nomeCategoria: categoria?.nome ?? _categoriaSelecionadaNome ?? '',
    );
  }

  Future<void> _abrirGestaoCategorias() async {
    final bool? alterouCategorias = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const CategoriasProdutosServicosMobileScreen(),
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
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOutCubic,
    );

    if (!mounted || !_slotsScrollController.hasClients) {
      return;
    }

    await _slotsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  double _toDouble(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.').trim()) ?? 0.0;
  }

  int _toInt(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  ProdutoModel _montarProduto() {
    final valorVendaEntrada =
        _valorVendaEntradaController.text.trim().isEmpty
            ? _toDouble(_precoVendaController)
            : _toDouble(_valorVendaEntradaController);
    final ObjCategoria? objCategoria = _montarObjCategoria();

    return ProdutoModel(
      id: _produtoEmEdicaoId,
      ativo: _ativo,
      codigoDeBarras: _codigoController.text.trim(),
      nomeProduto: _nomeController.text.trim(),
      tipoProduto: _tipoSelecionado,
      objCategoria: objCategoria,
      objAgrupamento: ObjAgrupamento(
        grupoDoProduto:
            _grupoController.text.trim().isEmpty
                ? 'Sem grupo'
                : _grupoController.text.trim(),
      ),
      objetoServico: ObjetoServico(
        tempoDaGarantia:
            _tempoGarantiaController.text.trim().isEmpty
                ? 'Sem garantia'
                : _tempoGarantiaController.text.trim(),
        podeAlterarOValorNaHora: _podeAlterarValorNaHora,
      ),
      modeloProduto:
          _modeloController.text.trim().isEmpty
              ? 'UNIDADE'
              : _modeloController.text.trim(),
      estoqueMaximo: _toInt(_estoqueMaxController),
      estoqueMinimo: _toInt(_estoqueMinController),
      precoVenda: _toDouble(_precoVendaController),
      objComissao: ObjComissao(
        produtoTemComissaoEspecial: _produtoTemComissaoEspecial,
        valorFixoDeComissaoParaEsseProduto: _toDouble(_valorComissaoController),
      ),
      objEntradaSaidaProduto: <ObjEntradaSaidaProduto>[
        ObjEntradaSaidaProduto(
          quantidade: _toDouble(_quantidadeEntradaController),
          valorCusto: _toDouble(_valorCustoController),
          valorDaVenda: valorVendaEntrada,
        ),
      ],
      imagens: _imagensParaEnvio,
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
      barrierColor: const Color(0x47000000),
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
                const SizedBox(height: 16),
                Text(
                  _t('produto.mobile.imageSheetTitle', 'Imagem do produto'),
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
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
      hintStyle: const TextStyle(color: _mutedTextColor),
      labelStyle: const TextStyle(color: _mutedTextColor),
      floatingLabelStyle: const TextStyle(
        color: _accentColor,
        fontWeight: FontWeight.w800,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accentColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SixMobilePalette.errorBorder),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SixMobilePalette.error, width: 1.4),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
          _tipoSelecionado == 'SERVICO'
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
      barrierColor: const Color(0x47000000),
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
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: <Widget>[
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t(
                      'produto.mobile.loadingCategories',
                      'Buscando categorias...',
                    ),
                    style: const TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_erroCategorias != null && !_carregandoCategorias)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  _erroCategorias!,
                  style: const TextStyle(
                    color: SixMobilePalette.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _carregarCategoriasCatalogo,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(_t('common.tryAgain', 'Tentar novamente')),
                ),
              ],
            ),
          ),
        if (!_carregandoCategorias &&
            _erroCategorias == null &&
            categorias.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
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
                  style: const TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: _isLoading ? null : _abrirGestaoCategorias,
                  icon: const Icon(Icons.category_outlined, size: 18),
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
      barrierColor: const Color(0x47000000),
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.46,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return _MobileBottomSheetFrame(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
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
                  _tipoSelecionado == 'SERVICO'
                      ? Icons.design_services_outlined
                      : Icons.inventory_2_outlined,
                  color: SixMobilePalette.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
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
                      style: const TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                      style: const TextStyle(
                        color: SixMobilePalette.heroSupportingText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StatusPill(ativo: _ativo),
        ],
      ),
    );
  }

  Widget _buildFieldPair({required Widget first, required Widget second}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: <Widget>[first, const SizedBox(height: 12), second],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: first),
            const SizedBox(width: 12),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: const [
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
          const SizedBox(height: 16),
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
              const SizedBox(width: 8),
              _SmallInfoPill(
                icon: Icons.ads_click_outlined,
                label:
                    '${_t('produto.mobile.imageSlot', 'Slot')} '
                    '${_slotSelecionadoIndex + 1}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildImagemAtiva(slot),
          const SizedBox(height: 12),
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
                icon: const Icon(Icons.photo_camera_outlined),
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
                icon: const Icon(Icons.upload_file_outlined),
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
                  icon: const Icon(Icons.delete_outline),
                  label: Text(_t('produto.mobile.remove', 'Remover')),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: ListView.separated(
              controller: _slotsScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _maxImageSlots,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
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
                      color: Colors.black.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      slot.image?.origem == 'UPLOAD'
                          ? _t('produto.mobile.imageUploadTag', 'Upload mobile')
                          : _t('produto.mobile.imageSavedTag', 'Imagem salva'),
                      style: const TextStyle(
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
                  child: const Icon(
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
        const Icon(
          Icons.add_photo_alternate_outlined,
          size: 42,
          color: _accentColor,
        ),
        const SizedBox(height: 10),
        Text(
          _t('produto.mobile.emptyImageSlotTitle', 'Nenhuma imagem neste slot'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _titleTextColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _t(
            'produto.mobile.emptyImageSlotSubtitle',
            'Toque para tirar foto ou fazer upload',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: _mutedTextColor, fontSize: 12),
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 82,
          padding: const EdgeInsets.all(6),
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
                          ? const Center(
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
                          : const Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: _mutedTextColor,
                              size: 20,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 5),
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
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) {
          return const Center(child: Icon(Icons.broken_image_outlined));
        },
      );
    }

    return const Center(child: Icon(Icons.broken_image_outlined));
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
          const SizedBox(height: 12),
          _buildTextField(
            controller: _codigoController,
            label: _t('produto.mobile.skuLabel', 'Código de barras / SKU'),
            hintText: _t('produto.mobile.skuHint', 'Ex.: 789000000001'),
          ),
          const SizedBox(height: 12),
          _buildTipoField(),
          const SizedBox(height: 12),
          _buildCategoriaField(),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _modeloController,
            label: _t('produto.mobile.modelLabel', 'Modelo'),
            hintText: 'UNIDADE',
          ),
          const SizedBox(height: 12),
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
            hintText: '0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _buildFieldPair(
            first: _buildTextField(
              controller: _quantidadeEntradaController,
              label: _t('produto.mobile.entryQtyLabel', 'Entrada'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            second: _buildTextField(
              controller: _valorCustoController,
              label: _t('produto.mobile.costLabel', 'Custo'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valorComissaoController,
            label: _t(
              'produto.mobile.commissionValueLabel',
              'Valor fixo da comissão',
            ),
            hintText: '0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
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
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 112),
              children: [
                _buildStaggeredEntry(
                  delay: const Duration(milliseconds: 60),
                  child: _buildHeaderCard(),
                ),
                const SizedBox(height: 16),
                _buildStaggeredEntry(
                  delay: const Duration(milliseconds: 110),
                  child: _buildFotoCard(),
                ),
                const SizedBox(height: 16),
                _buildStaggeredEntry(
                  delay: const Duration(milliseconds: 160),
                  child: _buildDadosPrincipaisCard(),
                ),
                const SizedBox(height: 16),
                _buildStaggeredEntry(
                  delay: const Duration(milliseconds: 210),
                  child: _buildEstoquePrecoCard(),
                ),
                const SizedBox(height: 16),
                _buildStaggeredEntry(
                  delay: const Duration(milliseconds: 260),
                  child: _buildRegrasCard(),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
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
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(false),
                child: Text(_t('common.cancel', 'Cancelar')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _salvar,
                icon:
                    _isLoading
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SixMobilePalette.onPrimary,
                          ),
                        )
                        : const Icon(Icons.save_outlined),
                label: Text(
                  _isLoading
                      ? _t('common.saving', 'Salvando...')
                      : (_isModoEdicao
                          ? _t('produto.mobile.saveEdit', 'Salvar edição')
                          : _t('produto.mobile.saveProduct', 'Salvar produto')),
                ),
              ),
            ),
          ],
        ),
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
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: padding,
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
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
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
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
                const SizedBox(width: 8),
                if (loading)
                  const SizedBox(
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
          const SizedBox(height: 16),
          _SheetTitleBlock(
            icon: Icons.tune_rounded,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 16),
          _SelectionOptionTile(
            icon: Icons.inventory_2_outlined,
            title: productLabel,
            subtitle: productSubtitle,
            selected: selectedType == 'PRODUTO',
            onTap: () => Navigator.of(context).pop('PRODUTO'),
          ),
          const SizedBox(height: 10),
          _SelectionOptionTile(
            icon: Icons.design_services_outlined,
            title: serviceLabel,
            subtitle: serviceSubtitle,
            selected: selectedType == 'SERVICO',
            onTap: () => Navigator.of(context).pop('SERVICO'),
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
          const SizedBox(height: 16),
          _SheetTitleBlock(
            icon: Icons.category_outlined,
            title: widget.title,
            subtitle: widget.subtitle,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (String value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(
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
                        icon: const Icon(Icons.close_rounded),
                      ),
              filled: true,
              fillColor: SixMobilePalette.softNeutralSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                const SizedBox(height: 10),
                ...filtered.map((CategoriaCatalogoModel categoria) {
                  final bool selected =
                      categoria.id == widget.selectedCategoryId;
                  final String subtitle =
                      categoria.descricao.trim().isNotEmpty
                          ? categoria.descricao
                          : (categoria.ativo ? '' : widget.inactiveLabel);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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
                  const SizedBox(height: 8),
                  _SelectorEmptyState(
                    title: widget.emptyTitle,
                    subtitle: widget.emptySubtitle,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onManageCategories,
              icon: const Icon(Icons.category_outlined),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SixMobilePalette.titleText,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
            padding: const EdgeInsets.all(14),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (trailingLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: SixMobilePalette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trailingLabel!,
                      style: const TextStyle(
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.search_off_rounded,
            color: SixMobilePalette.mutedText,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final Color background =
        ativo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final Color foreground =
        ativo ? const Color(0xFF15803D) : SixMobilePalette.error;
    final String label =
        ativo
            ? context.t('common.active', fallback: 'Ativo')
            : context.t('common.inactive', fallback: 'Inativo');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: SixMobilePalette.softAccentSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: SixMobilePalette.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
        isDanger ? const Color(0xFFFEF2F2) : SixMobilePalette.softAccentSurface;

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
            padding: const EdgeInsets.all(14),
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
                const SizedBox(width: 12),
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
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
