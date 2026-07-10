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
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

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
            'Erro ao carregar categorias (HTTP ${error.statusCode}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoCategorias = false;
        _erroCategorias = 'Não foi possível carregar categorias.';
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
                ? 'Produto atualizado com sucesso!'
                : 'Produto cadastrado com sucesso!',
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
                ? 'Erro ao atualizar produto: $mensagem'
                : 'Erro ao cadastrar produto: $mensagem',
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
        const SnackBar(
          content: Text('Não foi possível carregar a imagem.'),
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
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Imagem do produto',
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ImageActionTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Tirar foto',
                  subtitle: 'Usar a câmera do dispositivo.',
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
                  title: 'Enviar da galeria',
                  subtitle: 'Escolher uma imagem salva no aparelho.',
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
                    title: 'Remover imagem',
                    subtitle: 'Limpar o slot selecionado.',
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accentColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
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
                  return 'Campo obrigatório';
                }
                return null;
              }
              : null,
    );
  }

  Widget _buildCategoriaField() {
    final List<CategoriaCatalogoModel> categorias = _categoriasCompativeis;
    final bool categoriaSelecionadaExiste = categorias.any(
      (CategoriaCatalogoModel categoria) =>
          categoria.id == _categoriaSelecionadaId,
    );
    final String? valor =
        categoriaSelecionadaExiste ? _categoriaSelecionadaId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String?>(
          value: valor,
          decoration: _inputDecoration(
            'Categoria',
            hintText:
                _carregandoCategorias
                    ? 'Carregando categorias...'
                    : 'Selecione uma categoria',
          ),
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sem categoria'),
            ),
            ...categorias.map(
              (CategoriaCatalogoModel categoria) => DropdownMenuItem<String?>(
                value: categoria.id,
                child: Text(
                  categoria.ativo
                      ? categoria.nome
                      : '${categoria.nome} (Inativa)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged:
              _isLoading || _carregandoCategorias
                  ? null
                  : (String? value) {
                    setState(() {
                      _categoriaSelecionadaId = value;
                      final CategoriaCatalogoModel? categoria =
                          _categoriaSelecionadaEncontrada;
                      _categoriaSelecionadaNome = categoria?.nome;
                    });
                  },
        ),
        if (_carregandoCategorias)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Buscando categorias...',
                    style: TextStyle(color: _mutedTextColor, fontSize: 12),
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
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _carregarCategoriasCatalogo,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tentar novamente'),
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
                const Text(
                  'Nenhuma categoria disponível para este tipo.',
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: _isLoading ? null : _abrirGestaoCategorias,
                  icon: const Icon(Icons.category_outlined, size: 18),
                  label: const Text('Gerenciar categorias'),
                ),
              ],
            ),
          ),
      ],
    );
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
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Icon(
              _tipoSelecionado == 'SERVICO'
                  ? Icons.design_services_outlined
                  : Icons.inventory_2_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isModoEdicao ? 'Editar produto' : 'Novo produto',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isModoEdicao
                      ? 'Atualize os dados, fotos e status do cadastro.'
                      : 'Cadastre dados comerciais, estoque e até 5 imagens.',
                  style: const TextStyle(
                    color: Color(0xFFD7E3F5),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(ativo: _ativo),
        ],
      ),
    );
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
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
                  color: const Color(0xFFEFF6FF),
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
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
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
      title: 'Fotos do produto',
      subtitle: 'Use câmera ou upload. O backend receberá até 5 imagens.',
      icon: Icons.photo_camera_back_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallInfoPill(
                icon: Icons.collections_outlined,
                label: '$_totalImagensSelecionadas / $_maxImageSlots imagens',
              ),
              const SizedBox(width: 8),
              _SmallInfoPill(
                icon: Icons.ads_click_outlined,
                label: 'Slot ${_slotSelecionadoIndex + 1}',
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
                label: const Text('Tirar foto'),
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
                label: Text(slot.image == null ? 'Upload' : 'Trocar'),
              ),
              if (slot.image != null)
                TextButton.icon(
                  onPressed:
                      _isLoading || slot.isLoading
                          ? null
                          : () => _removerImagemDoSlot(_slotSelecionadoIndex),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
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

    return InkWell(
      onTap: _isLoading ? null : _abrirOpcoesImagem,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 210,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasImage ? _accentColor : const Color(0xFFE2E8F0),
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
                        ? 'Upload mobile'
                        : 'Imagem salva',
                    style: const TextStyle(
                      color: Colors.white,
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
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_photo_alternate_outlined, size: 42, color: _accentColor),
        SizedBox(height: 10),
        Text(
          'Nenhuma imagem neste slot',
          style: TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 4),
        Text(
          'Toque para tirar foto ou fazer upload',
          style: TextStyle(color: _mutedTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMiniaturaSlot(int index) {
    final slot = _imagemSlots[index];
    final bool selected = index == _slotSelecionadoIndex;
    final bool hasImage = slot.image != null;

    return InkWell(
      onTap: () => setState(() => _slotSelecionadoIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 82,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _accentColor : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    slot.isLoading
                        ? const Center(
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
      title: 'Dados principais',
      subtitle: 'Identificação comercial e classificação.',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _nomeController,
            label: 'Nome do produto',
            hintText: 'Ex.: Tela iPhone 13',
            requiredField: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _codigoController,
            label: 'Código de barras / SKU',
            hintText: 'Ex.: 789000000001',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipoSelecionado,
            decoration: _inputDecoration('Tipo'),
            items: const [
              DropdownMenuItem(value: 'PRODUTO', child: Text('Produto')),
              DropdownMenuItem(value: 'SERVICO', child: Text('Serviço')),
            ],
            onChanged:
                _isLoading
                    ? null
                    : (value) {
                      if (value == null) return;
                      setState(() {
                        _tipoSelecionado = value;
                        _validarCategoriaSelecionadaComTipoAtual();
                      });
                    },
          ),
          const SizedBox(height: 12),
          _buildCategoriaField(),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _modeloController,
            label: 'Modelo',
            hintText: 'UNIDADE',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _grupoController,
            label: 'Grupo',
            hintText: 'Ex.: Peças, acessórios, mão de obra',
          ),
        ],
      ),
    );
  }

  Widget _buildEstoquePrecoCard() {
    return _buildSectionCard(
      title: 'Preço e estoque',
      subtitle: 'Valores comerciais e limites de controle.',
      icon: Icons.sell_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _precoVendaController,
            label: 'Preço de venda',
            hintText: '0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _estoqueMinController,
                  label: 'Estoque mín.',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _estoqueMaxController,
                  label: 'Estoque máx.',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _quantidadeEntradaController,
                  label: 'Entrada',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _valorCustoController,
                  label: 'Custo',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valorVendaEntradaController,
            label: 'Valor da venda na movimentação',
            hintText: 'Usa o preço de venda se ficar vazio',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildRegrasCard() {
    return _buildSectionCard(
      title: 'Regras e status',
      subtitle: 'Configurações rápidas para operação no balcão.',
      icon: Icons.settings_suggest_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _tempoGarantiaController,
            label: 'Tempo da garantia',
            hintText: 'Ex.: 90 dias',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valorComissaoController,
            label: 'Valor fixo da comissão',
            hintText: '0,00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          _SwitchCard(
            title: 'Produto ativo',
            subtitle: 'Disponível para venda e listagens.',
            value: _ativo,
            onChanged:
                _isLoading ? null : (value) => setState(() => _ativo = value),
          ),
          const SizedBox(height: 10),
          _SwitchCard(
            title: 'Alterar valor na hora',
            subtitle: 'Permite ajustar o valor durante o atendimento.',
            value: _podeAlterarValorNaHora,
            onChanged:
                _isLoading
                    ? null
                    : (value) =>
                        setState(() => _podeAlterarValorNaHora = value),
          ),
          const SizedBox(height: 10),
          _SwitchCard(
            title: 'Comissão especial',
            subtitle: 'Aplica comissão específica para este item.',
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _isModoEdicao ? 'Editar produto' : 'Cadastrar produto',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildFotoCard(),
              const SizedBox(height: 16),
              _buildDadosPrincipaisCard(),
              const SizedBox(height: 16),
              _buildEstoquePrecoCard(),
              const SizedBox(height: 16),
              _buildRegrasCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
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
                      _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
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
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.save_outlined),
                  label: Text(
                    _isLoading
                        ? 'Salvando...'
                        : (_isModoEdicao ? 'Salvar edição' : 'Salvar produto'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ativo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(
          color: ativo ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
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
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: _CadastroProdutoMobileScreenState._accentColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _CadastroProdutoMobileScreenState._accentColor,
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
        isDanger ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    final background =
        isDanger ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      style: TextStyle(
                        color:
                            isDanger
                                ? const Color(0xFFB91C1C)
                                : _CadastroProdutoMobileScreenState
                                    ._titleTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:
                            _CadastroProdutoMobileScreenState._mutedTextColor,
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _CadastroProdutoMobileScreenState._titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _CadastroProdutoMobileScreenState._mutedTextColor,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
