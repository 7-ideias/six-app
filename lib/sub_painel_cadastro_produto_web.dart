import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:appplanilha/core/services/produto_service.dart';
import 'package:appplanilha/data/models/imagem_sugestao_model.dart';
import 'package:appplanilha/data/models/produto_imagem_model.dart';
import 'package:appplanilha/data/models/produto_model.dart';
import 'package:appplanilha/data/services/imagem_sugestao/imagem_sugestao_api_client.dart';
import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:appplanilha/presentation/components/imagem_sugestoes_section.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SubPainelCadastroProduto extends SubPainelWebGeneral {
  const SubPainelCadastroProduto({
    super.key,
    required super.body,
    required super.textoDaAppBar,
  });
}

void showSubPainelCadastroProduto(
  BuildContext context,
  String textoDaAppBar, {
  ProdutoModel? produtoParaEdicao,
  bool modoEdicao = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
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
  });

  final ProdutoModel? produtoParaEdicao;
  final bool modoEdicao;

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProdutoService _produtoService = ProdutoService();
  final ImagemSugestaoApiClient _imagemSugestaoApiClient =
      HttpImagemSugestaoApiClient();

  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _nomeProdutoController = TextEditingController();
  final TextEditingController _grupoProdutoController = TextEditingController();
  final TextEditingController _tempoGarantiaController =
      TextEditingController();
  final TextEditingController _modeloProdutoController = TextEditingController(
    text: 'UNIDADE',
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

  bool _ativo = true;
  bool _podeAlterarValorNaHora = false;
  bool _produtoTemComissaoEspecial = false;
  bool _isLoading = false;
  String _tipoSelecionado = 'PRODUTO';

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

  List<ProdutoImagemModel> get _imagensParaEnvio =>
      _imagemSlots
          .map((slot) => slot.image)
          .whereType<ProdutoImagemModel>()
          .toList(growable: false);

  Set<int> get _sugestoesAplicadasIds =>
      _imagemSlots
          .map((slot) => slot.image?.sugestaoId)
          .whereType<int>()
          .toSet();

  int get _indicePrimeiroSlotLivre =>
      _imagemSlots.indexWhere((slot) => slot.image == null);

  bool get _temSlotLivre => _indicePrimeiroSlotLivre != -1;

  _ProdutoImagemSlot get _slotSelecionado => _imagemSlots[_slotSelecionadoIndex];

  bool get _isModoEdicao =>
      widget.modoEdicao && widget.produtoParaEdicao != null;

  @override
  void initState() {
    super.initState();
    _preencherCamposSeModoEdicao();
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

  double _toDouble(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.').trim()) ?? 0.0;
  }

  int _toInt(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  bool get _camposMinimosParaSugestao {
    return _nomeProdutoController.text.trim().isNotEmpty &&
        (_tipoSelecionado == 'PRODUTO' || _tipoSelecionado == 'SERVICO');
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
      categoria: _grupoProdutoController.text.trim(),
      tipo: _tipoSelecionado == 'SERVICO' ? 'servico' : 'produto',
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
    final http.Client currentClient = http.Client();
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
              'Você já atingiu o limite de 5 imagens. Remova uma para adicionar outra.'),
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
    _tipoSelecionado =
        produto.tipoProduto.isEmpty ? 'PRODUTO' : produto.tipoProduto;
    _grupoProdutoController.text = produto.objAgrupamento?.grupoDoProduto ?? '';
    _modeloProdutoController.text = produto.modeloProduto;
    _estoqueMaximoController.text = produto.estoqueMaximo.toString();
    _estoqueMinimoController.text = produto.estoqueMinimo.toString();
    _precoVendaController.text = produto.precoVenda.toString();
    _valorComissaoController.text =
        produto.objComissao.valorFixoDeComissaoParaEsseProduto.toString();
    _produtoTemComissaoEspecial =
        produto.objComissao.produtoTemComissaoEspecial;
    _ativo = produto.ativo;

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

    for (final slot in _imagemSlots) {
      slot.reset();
    }

    final List<ProdutoImagemModel> imagensDoProduto =
        produto.imagens ?? const <ProdutoImagemModel>[];

    for (int i = 0;
        i < imagensDoProduto.length && i < _imagemSlots.length;
        i++) {
      _imagemSlots[i].image = imagensDoProduto[i];
    }
  }

  ProdutoModel _montarProduto() {
    return ProdutoModel(
      id: _produtoEmEdicaoId,
      ativo: _ativo,
      codigoDeBarras: _codigoBarrasController.text.trim(),
      nomeProduto: _nomeProdutoController.text.trim(),
      tipoProduto: _tipoSelecionado,
      objAgrupamento: ObjAgrupamento(
        grupoDoProduto:
            _grupoProdutoController.text.trim().isEmpty
                ? 'Sem grupo'
                : _grupoProdutoController.text.trim(),
      ),
      objetoServico: ObjetoServico(
        tempoDaGarantia:
            _tempoGarantiaController.text.trim().isEmpty
                ? 'Sem garantia'
                : _tempoGarantiaController.text.trim(),
        podeAlterarOValorNaHora: _podeAlterarValorNaHora,
      ),
      modeloProduto:
          _modeloProdutoController.text.trim().isEmpty
              ? 'UNIDADE'
              : _modeloProdutoController.text.trim(),
      estoqueMaximo: _toInt(_estoqueMaximoController),
      estoqueMinimo: _toInt(_estoqueMinimoController),
      precoVenda: _toDouble(_precoVendaController),
      objComissao: ObjComissao(
        produtoTemComissaoEspecial: _produtoTemComissaoEspecial,
        valorFixoDeComissaoParaEsseProduto: _toDouble(_valorComissaoController),
      ),
      objEntradaSaidaProduto: <ObjEntradaSaidaProduto>[
        ObjEntradaSaidaProduto(
          quantidade: _toDouble(_quantidadeEntradaController),
          valorCusto: _toDouble(_valorCustoController),
          valorDaVenda: _toDouble(_valorVendaEntradaController),
        ),
      ],
      imagens: _imagensParaEnvio,
    );
  }

  Future<void> _selecionarFotoParaSlot(int slotIndex) async {
    if (_isLoading || slotIndex < 0 || slotIndex >= _maxImageSlots) {
      return;
    }

    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;

    final html.File? file =
        input.files?.isNotEmpty == true ? input.files!.first : null;
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
            title: const Text('Sucesso'),
            content: Text(
              _isModoEdicao
                  ? 'Produto atualizado com sucesso!'
                  : 'Produto cadastrado com sucesso!',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              _isModoEdicao ? 'Erro ao atualizar' : 'Erro ao cadastrar',
            ),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
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

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _isModoEdicao ? 'Edição de produto' : 'Cadastro de produto',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    _isModoEdicao
                        ? 'Modo edição: revise os dados já cadastrados e salve as alterações.'
                        : 'Visual mais alinhado ao SixApp, com destaque para foto e ações principais.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.wifi_tethering, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isLoading
                      ? (_isModoEdicao
                          ? 'Salvando alteração...'
                          : 'Salvando...')
                      : (_isModoEdicao
                          ? 'Pronto para editar'
                          : 'Pronto para envio'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
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
                  color: colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.65),
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
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.16)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.62),
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
    final colorScheme = Theme.of(context).colorScheme;
    final _ProdutoImagemSlot slotAtivo = _slotSelecionado;

    return _buildSectionCard(
      context: context,
      title: 'Fotos do produto',
      subtitle:
          'Fluxo de galeria: selecione um slot e adicione a imagem.',
      icon: Icons.photo_camera_back_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Selecionadas: $_totalImagensSelecionadas / $_maxImageSlots',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Slot ativo: ${_slotSelecionadoIndex + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildImagemAtiva(context, slotAtivo),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: _isLoading || slotAtivo.isLoading
                    ? null
                    : () => _selecionarFotoParaSlot(_slotSelecionadoIndex),
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  slotAtivo.image == null ? 'Adicionar no slot ativo' : 'Trocar imagem',
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _isLoading || slotAtivo.image == null
                    ? null
                    : () => _removerImagemDoSlot(_slotSelecionadoIndex),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover do slot ativo'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Slots',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List<Widget>.generate(
                _maxImageSlots,
                (int index) => Padding(
                  padding: EdgeInsets.only(right: index == _maxImageSlots - 1 ? 0 : 10),
                  child: _buildMiniaturaSlot(context, index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _temSlotLivre
                ? 'Você pode aplicar sugestões de IA no slot ativo (se estiver vazio) ou no próximo slot livre.'
                : 'Limite de imagens atingido. Remova uma miniatura para continuar.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagemAtiva(BuildContext context, _ProdutoImagemSlot slotAtivo) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool hasImage = slotAtivo.image != null;
    final bool isSugestao = slotAtivo.image?.origem == 'SUGESTAO';

    Widget imageContent;
    if (slotAtivo.previewBytes != null) {
      imageContent = Image.memory(slotAtivo.previewBytes!, fit: BoxFit.cover);
    } else if (slotAtivo.image?.url != null) {
      imageContent = Image.network(
        slotAtivo.image!.url!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined),
        ),
      );
    } else {
      imageContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.photo_camera_back_outlined,
            size: 38,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhuma imagem no slot ${_slotSelecionadoIndex + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use o botão de upload ou escolha uma sugestão por IA.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.58),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSugestao ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
          width: isSugestao ? 2 : 1,
        ),
        color: colorScheme.surfaceVariant,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: imageContent),
          if (slotAtivo.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.28),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSugestao ? 'Origem: IA' : 'Origem: Upload',
                  style: const TextStyle(
                    color: Colors.white,
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final _ProdutoImagemSlot slot = _imagemSlots[index];
    final bool hasImage = slot.image != null;
    final bool isAtivo = index == _slotSelecionadoIndex;

    Widget thumb;
    if (slot.previewBytes != null) {
      thumb = Image.memory(slot.previewBytes!, fit: BoxFit.cover);
    } else if (slot.image?.url != null) {
      thumb = Image.network(
        slot.image!.url!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      );
    } else {
      thumb = Icon(
        Icons.add_photo_alternate_outlined,
        color: colorScheme.onSurface.withOpacity(0.46),
      );
    }

    return InkWell(
      onTap: () => setState(() => _slotSelecionadoIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAtivo ? colorScheme.primary : colorScheme.outline.withOpacity(0.24),
            width: isAtivo ? 2 : 1,
          ),
          color: isAtivo ? colorScheme.primary.withOpacity(0.05) : colorScheme.surface,
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 78,
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: colorScheme.surfaceVariant,
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            Text(
              hasImage ? 'OK' : 'Vazio',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final String preco =
        _precoVendaController.text.trim().isEmpty
            ? 'R\$ 0,00'
            : 'R\$ ${_precoVendaController.text.trim()}';

    return _buildSectionCard(
      context: context,
      title: 'Resumo rápido',
      subtitle: 'Leitura objetiva para o usuário conferir antes de salvar.',
      icon: Icons.summarize_outlined,
      child: Column(
        children: <Widget>[
          _buildInfoRow(
            'Nome',
            _nomeProdutoController.text.trim().isEmpty
                ? '-'
                : _nomeProdutoController.text.trim(),
          ),
          _buildInfoRow('Tipo', _tipoSelecionado),
          _buildInfoRow(
            'Modelo',
            _modeloProdutoController.text.trim().isEmpty
                ? '-'
                : _modeloProdutoController.text.trim(),
          ),
          _buildInfoRow('Preço', preco),
          _buildInfoRow(
            'Grupo',
            _grupoProdutoController.text.trim().isEmpty
                ? '-'
                : _grupoProdutoController.text.trim(),
          ),
          _buildInfoRow('Status', _ativo ? 'Ativo' : 'Inativo', isLast: true),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _tipoSelecionado == 'SERVICO'
                  ? 'Modo serviço ligado: destaque maior para garantia e alteração de valor.'
                  : 'Modo produto ligado: foco em estoque, custo e preço de venda.',
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

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 12),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
                ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.54),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            _isModoEdicao
                ? 'Revise os dados e conclua a alteração.'
                : 'Revise os dados e conclua o cadastro.',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: _isLoading ? null : _salvarProduto,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: Text(
                  _isLoading
                      ? (_isModoEdicao
                          ? 'Salvando alteração...'
                          : 'Salvando...')
                      : (_isModoEdicao ? 'Salvar alteração' : 'Salvar produto'),
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
          title: 'Dados principais',
          subtitle: 'Identificação comercial e classificação do item.',
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
                  label: 'Código de barras',
                  hintText: 'Ex.: 789000000001',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 390 : (telaMedia ? 320 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _nomeProdutoController,
                  label: 'Nome do produto',
                  hintText: 'descreva seu produto aqui',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 190 : (telaMedia ? 180 : double.infinity),
                child: DropdownButtonFormField<String>(
                  value: _tipoSelecionado,
                  decoration: _inputDecoration(context, 'Tipo'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'PRODUTO', child: Text('PRODUTO')),
                    DropdownMenuItem(value: 'SERVICO', child: Text('SERVIÇO')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _tipoSelecionado = value;
                    });
                    _onCamposSugestoesAlterados();
                  },
                ),
              ),
              SizedBox(
                width: telaGrande ? 180 : (telaMedia ? 160 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _modeloProdutoController,
                  label: 'Modelo',
                  hintText: 'UNIDADE',
                  requiredField: true,
                ),
              ),
            ],
          ),
        );

        final Widget estoquePreco = _buildSectionCard(
          context: context,
          title: 'Estoque e preço',
          subtitle: 'Controle de limites, custo e preço comercial.',
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
                  label: 'Estoque máximo',
                  keyboardType: TextInputType.number,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 180 : (telaMedia ? 180 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _estoqueMinimoController,
                  label: 'Estoque mínimo',
                  keyboardType: TextInputType.number,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _precoVendaController,
                  label: 'Preço de venda',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: '0,00',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 250 : (telaMedia ? 240 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _grupoProdutoController,
                  label: 'Grupo do produto',
                  hintText: 'Ex.: Acessórios',
                  requiredField: true,
                ),
              ),
            ],
          ),
        );

        final Widget servicoComissao = _buildSectionCard(
          context: context,
          title: 'Serviço, comissão e regras',
          subtitle: 'Campos que ajudam a deixar a operação mais flexível.',
          icon: Icons.settings_suggest_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width:
                        telaGrande ? 250 : (telaMedia ? 240 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _tempoGarantiaController,
                      label: 'Tempo da garantia',
                      hintText: 'Ex.: 90 dias',
                      requiredField: true,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _valorComissaoController,
                      label: 'Valor fixo da comissão',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: '0,00',
                      requiredField: true,
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
                      title: 'Produto ativo',
                      subtitle: 'Disponível para venda e listagens.',
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Alterar valor na hora',
                      subtitle:
                          'Permite ajustar o valor durante o atendimento.',
                      value: _podeAlterarValorNaHora,
                      onChanged:
                          (value) =>
                              setState(() => _podeAlterarValorNaHora = value),
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Comissão especial',
                      subtitle: 'Aplica comissão específica para este item.',
                      value: _produtoTemComissaoEspecial,
                      onChanged:
                          (value) => setState(
                            () => _produtoTemComissaoEspecial = value,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final Widget movimentacao = _buildSectionCard(
          context: context,
          title: 'Entrada e saída do produto',
          subtitle: 'Dados iniciais de movimentação e precificação.',
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
                  label: 'Quantidade',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 200 : (telaMedia ? 200 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _valorCustoController,
                  label: 'Valor de custo',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _valorVendaEntradaController,
                  label: 'Valor da venda',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  requiredField: true,
                ),
              ),
            ],
          ),
        );

        final Widget conteudoEsquerdo = Column(
          children: <Widget>[
            dadosPrincipais,
            const SizedBox(height: 20),
            estoquePreco,
            const SizedBox(height: 20),
            servicoComissao,
            const SizedBox(height: 20),
            movimentacao,
          ],
        );

        final Widget conteudoDireito = Column(
          children: <Widget>[
            _buildFotoCard(context),
            const SizedBox(height: 20),
            _buildSugestoesImagemCard(context),
            const SizedBox(height: 20),
            _buildResumoCard(context),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    if (telaGrande)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 7, child: conteudoEsquerdo),
                          const SizedBox(width: 24),
                          Expanded(flex: 4, child: conteudoDireito),
                        ],
                      )
                    else ...<Widget>[
                      _buildFotoCard(context),
                      const SizedBox(height: 20),
                      _buildSugestoesImagemCard(context),
                      const SizedBox(height: 20),
                      _buildResumoCard(context),
                      const SizedBox(height: 20),
                      conteudoEsquerdo,
                    ],
                    const SizedBox(height: 24),
                    _buildActionsBar(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
