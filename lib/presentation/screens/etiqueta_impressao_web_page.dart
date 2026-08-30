import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/utils/pdf_download.dart';
import 'package:sixpos/data/models/etiqueta_models.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/services/etiqueta/etiqueta_api_client.dart';
import 'package:sixpos/presentation/components/web/six_web_label_pdf_generate_dialog.dart';
import 'package:sixpos/domain/services/etiqueta/etiqueta_service.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

import 'etiqueta_web_i18n.dart';

class EtiquetaImpressaoWebPage extends StatefulWidget {
  const EtiquetaImpressaoWebPage({
    super.key,
    required this.modelos,
    required this.service,
    this.initialTemplateId,
    this.onClose,
  });

  final List<EtiquetaModelo> modelos;
  final EtiquetaService service;
  final String? initialTemplateId;
  final VoidCallback? onClose;

  @override
  State<EtiquetaImpressaoWebPage> createState() =>
      _EtiquetaImpressaoWebPageState();
}

class _EtiquetaImpressaoWebPageState extends State<EtiquetaImpressaoWebPage> {
  late String? _templateId;
  final Map<String, _SelectedProduct> _selected = <String, _SelectedProduct>{};
  bool _generating = false;
  String? _error;
  EtiquetaPdfResponse? _lastPdf;

  @override
  void initState() {
    super.initState();
    final bool initialExists = widget.modelos.any(
      (EtiquetaModelo model) => model.id == widget.initialTemplateId,
    );
    _templateId =
        initialExists
            ? widget.initialTemplateId
            : widget.modelos.firstOrNull?.id;
  }

  EtiquetaModelo? get _selectedTemplate {
    final String? id = _templateId;
    if (id == null) return null;
    for (final EtiquetaModelo model in widget.modelos) {
      if (model.id == id) return model;
    }
    return null;
  }

  int get _totalLabels => _selected.values.fold<int>(
    0,
    (int total, _SelectedProduct item) => total + item.quantity,
  );

  int get _estimatedPages {
    final EtiquetaModelo? model = _selectedTemplate;
    if (model == null || _totalLabels == 0) return 0;
    final int perPage = model.grade.colunas * model.grade.linhas;
    if (perPage <= 0) return 0;
    return (_totalLabels / perPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool compact = MediaQuery.sizeOf(context).width < 860;
    return PopScope(
      canPop: !_generating,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (DismissIntent intent) {
                if (_generating) return null;
                widget.onClose?.call();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Semantics(
              namesRoute: true,
              label: _tr(
                'labels.print.title',
                'Imprimir etiquetas',
                'Print labels',
                'Imprimir etiquetas',
              ),
              child: Material(
                color: tokens.workspaceBackground,
                child: Column(
                  children: <Widget>[
                    SixWebDashboardHeader(
                      icon: Icons.print_outlined,
                      title: _tr(
                        'labels.print.title',
                        'Imprimir etiquetas',
                        'Print labels',
                        'Imprimir etiquetas',
                      ),
                      subtitle: _tr(
                        'labels.print.subtitle',
                        'Escolha o modelo, selecione os produtos e informe quantas etiquetas deseja para cada item.',
                        'Choose a template, select products and set how many labels you need for each item.',
                        'Elija la plantilla, seleccione productos e indique cuántas etiquetas necesita de cada artículo.',
                      ),
                      onBack: _generating ? null : widget.onClose,
                      actions: <Widget>[_generateButton()],
                    ),
                    if (_error != null) _errorBanner(_error!),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(compact ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _configurationCard(compact),
                            const SizedBox(height: 16),
                            _productsCard(compact),
                            const SizedBox(height: 16),
                            _summaryBar(compact),
                          ],
                        ),
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

  Widget _configurationCard(bool compact) {
    final EtiquetaModelo? selected = _selectedTemplate;
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return SixWebSectionCard(
      title: _tr(
        'labels.print.templateSection',
        'Modelo de impressão',
        'Print template',
        'Plantilla de impresión',
      ),
      subtitle: _tr(
        'labels.print.templateSectionHint',
        'O PDF usa exatamente as medidas físicas salvas no modelo.',
        'The PDF uses the exact physical dimensions saved in the template.',
        'El PDF utiliza exactamente las medidas físicas guardadas en la plantilla.',
      ),
      icon: Icons.local_offer_outlined,
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: compact ? double.infinity : 420,
            child: PopupMenuButton<String>(
              enabled: widget.modelos.isNotEmpty,
              onSelected:
                  (String value) => setState(() {
                    _templateId = value;
                    _error = null;
                    _lastPdf = null;
                  }),
              itemBuilder:
                  (BuildContext context) => widget.modelos
                      .where((EtiquetaModelo model) => model.id != null)
                      .map(
                        (EtiquetaModelo model) => PopupMenuItem<String>(
                          value: model.id!,
                          child: Row(
                            children: <Widget>[
                              if (model.id == _templateId) ...<Widget>[
                                const Icon(Icons.check_rounded, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Expanded(child: Text(model.nome)),
                              const SizedBox(width: 10),
                              Text(
                                '${_fmt(model.etiqueta.larguraMm)}×${_fmt(model.etiqueta.alturaMm)} mm',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: tokens.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: tokens.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.description_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _tr(
                              'labels.print.selectedTemplate',
                              'Modelo selecionado',
                              'Selected template',
                              'Plantilla seleccionada',
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selected?.nome ??
                                _tr(
                                  'labels.print.noTemplate',
                                  'Nenhum modelo',
                                  'No template',
                                  'Ninguna plantilla',
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded),
                  ],
                ),
              ),
            ),
          ),
          if (selected != null) ...<Widget>[
            _metadataChip(
              Icons.straighten_rounded,
              '${_fmt(selected.etiqueta.larguraMm)} × ${_fmt(selected.etiqueta.alturaMm)} mm',
            ),
            _metadataChip(
              Icons.grid_view_outlined,
              '${selected.grade.colunas} × ${selected.grade.linhas}',
            ),
            _metadataChip(Icons.description_outlined, selected.papel.preset),
          ],
        ],
      ),
    );
  }

  Widget _productsCard(bool compact) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return SixWebSectionCard(
      title: _tr('labels.print.products', 'Produtos', 'Products', 'Productos'),
      subtitle: _tr(
        'labels.print.productsHint',
        'A quantidade ao lado de cada produto é a quantidade de etiquetas que será impressa.',
        'The quantity beside each product is the number of labels that will be printed.',
        'La cantidad junto a cada producto es la cantidad de etiquetas que se imprimirá.',
      ),
      icon: Icons.inventory_2_outlined,
      trailing: FilledButton.tonalIcon(
        onPressed: _selectProducts,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: Text(
          _selected.isEmpty
              ? _tr(
                'labels.print.selectProducts',
                'Selecionar produtos',
                'Select products',
                'Seleccionar productos',
              )
              : _tr(
                'labels.print.changeProducts',
                'Alterar seleção',
                'Change selection',
                'Cambiar selección',
              ),
        ),
      ),
      child:
          _selected.isEmpty
              ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 34,
                      color: tokens.secondaryText,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _tr(
                        'labels.print.emptyProducts',
                        'Nenhum produto selecionado.',
                        'No products selected.',
                        'No hay productos seleccionados.',
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tr(
                        'labels.print.emptyProductsHint',
                        'Abra o catálogo, marque um ou mais produtos e ajuste as quantidades.',
                        'Open the catalog, select one or more products and adjust quantities.',
                        'Abra el catálogo, seleccione uno o más productos y ajuste las cantidades.',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: <Widget>[
                  for (final _SelectedProduct item
                      in _selected.values) ...<Widget>[
                    _productRow(item, compact),
                    if (item != _selected.values.last)
                      Divider(height: 1, color: tokens.divider),
                  ],
                ],
              ),
    );
  }

  Widget _productRow(_SelectedProduct item, bool compact) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final LocaleSettingsProvider locale =
        context.watch<LocaleSettingsProvider>();
    final ProdutoModel product = item.product;
    final Widget quantity = _quantityControl(item);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _productIdentity(product, theme, tokens, locale),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      quantity,
                      const Spacer(),
                      _removeButton(item),
                    ],
                  ),
                ],
              )
              : Row(
                children: <Widget>[
                  Expanded(
                    child: _productIdentity(product, theme, tokens, locale),
                  ),
                  const SizedBox(width: 16),
                  quantity,
                  const SizedBox(width: 10),
                  _removeButton(item),
                ],
              ),
    );
  }

  Widget _productIdentity(
    ProdutoModel product,
    ThemeData theme,
    WebThemeTokens tokens,
    LocaleSettingsProvider locale,
  ) {
    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: const Icon(Icons.inventory_2_outlined, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                product.nomeProduto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 10,
                runSpacing: 3,
                children: <Widget>[
                  Text(
                    locale.formatCurrency(product.precoVenda),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.codigoDeBarras.trim().isNotEmpty)
                    Text(
                      product.codigoDeBarras,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quantityControl(_SelectedProduct item) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: _tr(
              'labels.print.decrease',
              'Diminuir',
              'Decrease',
              'Disminuir',
            ),
            onPressed:
                item.quantity <= 1
                    ? null
                    : () => _setQuantity(item, item.quantity - 1),
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          SizedBox(
            width: 46,
            child: Text(
              item.quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: _tr(
              'labels.print.increase',
              'Aumentar',
              'Increase',
              'Aumentar',
            ),
            onPressed:
                item.quantity >= 1000
                    ? null
                    : () => _setQuantity(item, item.quantity + 1),
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _removeButton(_SelectedProduct item) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return IconButton(
      tooltip: _tr('labels.print.remove', 'Remover', 'Remove', 'Eliminar'),
      onPressed:
          () => setState(() {
            _selected.remove(item.product.id);
            _lastPdf = null;
          }),
      icon: Icon(Icons.close_rounded, color: tokens.danger),
    );
  }

  Widget _summaryBar(bool compact) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<Widget> metrics = <Widget>[
      _summaryMetric(
        _tr(
          'labels.print.selectedProducts',
          'Produtos',
          'Products',
          'Productos',
        ),
        _selected.length.toString(),
      ),
      _summaryMetric(
        _tr('labels.print.totalLabels', 'Etiquetas', 'Labels', 'Etiquetas'),
        _totalLabels.toString(),
      ),
      _summaryMetric(
        _tr(
          'labels.print.estimatedPages',
          'Páginas estimadas',
          'Estimated pages',
          'Páginas estimadas',
        ),
        _estimatedPages.toString(),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Wrap(spacing: 20, runSpacing: 12, children: metrics),
                  const SizedBox(height: 14),
                  _generateButton(stretched: true),
                ],
              )
              : Row(
                children: <Widget>[
                  Expanded(
                    child: Wrap(spacing: 32, runSpacing: 10, children: metrics),
                  ),
                  if (_lastPdf != null) ...<Widget>[
                    Text(
                      _tr(
                        'labels.print.pdfReady',
                        'PDF gerado',
                        'PDF generated',
                        'PDF generado',
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  _generateButton(),
                ],
              ),
    );
  }

  Widget _generateButton({bool stretched = false}) {
    final Widget button = FilledButton.icon(
      onPressed:
          _generating || _selected.isEmpty || _selectedTemplate == null
              ? null
              : _generatePdf,
      icon:
          _generating
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(
        _generating
            ? _tr(
              'labels.print.generating',
              'Gerando...',
              'Generating...',
              'Generando...',
            )
            : _tr(
              'labels.print.generatePdf',
              'Gerar PDF',
              'Generate PDF',
              'Generar PDF',
            ),
      ),
    );
    return stretched ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _summaryMetric(String label, String value) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: tokens.secondaryText),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Future<void> _selectProducts() async {
    final List<ProdutoModel>? result = await showDialog<List<ProdutoModel>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          backgroundColor: WebThemeTokens.of(dialogContext).cardBackground,
          surfaceTintColor: Colors.transparent,
          child: SizedBox(
            width: mathMin(size.width * 0.94, 1380),
            height: mathMin(size.height * 0.90, 900),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: WebThemeTokens.of(dialogContext).divider,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.inventory_2_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          etiquetaTr(
                            dialogContext,
                            'labels.print.productSelectorTitle',
                            pt: 'Selecione os produtos e as quantidades',
                            en: 'Select products and quantities',
                            es: 'Seleccione productos y cantidades',
                          ),
                          style: Theme.of(dialogContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip:
                            MaterialLocalizations.of(
                              dialogContext,
                            ).closeButtonTooltip,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: SubPainelWebProdutoLista(
                    isSelecao: true,
                    permitirSelecaoMultipla: true,
                    tipoInicial: 'PRODUTO',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null || !mounted) return;

    final Map<String, _SelectedProduct> next = <String, _SelectedProduct>{};
    bool missingId = false;
    for (final ProdutoModel product in result) {
      final String id = product.id?.trim() ?? '';
      if (id.isEmpty) {
        missingId = true;
        continue;
      }
      final _SelectedProduct? current = next[id];
      next[id] = _SelectedProduct(
        product: product,
        quantity: (current?.quantity ?? 0) + 1,
      );
    }
    setState(() {
      _selected
        ..clear()
        ..addAll(next);
      _lastPdf = null;
      _error =
          missingId
              ? _tr(
                'labels.print.productWithoutId',
                'Um item sem identificador foi ignorado na seleção.',
                'An item without an identifier was ignored.',
                'Se ignoró un artículo sin identificador.',
              )
              : null;
    });
  }

  void _setQuantity(_SelectedProduct item, int quantity) {
    final String id = item.product.id!;
    setState(() {
      _selected[id] = _SelectedProduct(
        product: item.product,
        quantity: quantity.clamp(1, 1000),
      );
      _lastPdf = null;
    });
  }

  Future<void> _generatePdf() async {
    final EtiquetaModelo? model = _selectedTemplate;
    if (model == null ||
        model.id?.trim().isEmpty != false ||
        _selected.isEmpty) {
      return;
    }
    await showSixWebLabelPdfGenerateDialog(
      context: context,
      templateName: model.nome,
      productCount: _selected.length,
      totalLabels: _totalLabels,
      estimatedPages: _estimatedPages,
      onConfirm: _executePdfGeneration,
    );
  }

  Future<void> _executePdfGeneration() async {
    final EtiquetaModelo? model = _selectedTemplate;
    final String templateId = model?.id ?? '';
    if (templateId.isEmpty || _selected.isEmpty) return;
    final List<EtiquetaImpressaoItem> items = _selected.values
        .map(
          (_SelectedProduct item) => EtiquetaImpressaoItem(
            sourceId: item.product.id!,
            quantidade: item.quantity,
          ),
        )
        .toList(growable: false);
    setState(() {
      _generating = true;
      _error = null;
    });
    debugPrint(
      '[EtiquetaImpressaoWebPage] Iniciando geração do PDF '
      'templateId=$templateId templateNome="${model?.nome ?? '-'}" '
      'produtos=${items.length} totalEtiquetas=$_totalLabels '
      'amostraIds=${items.take(5).map((EtiquetaImpressaoItem item) => item.sourceId).join(',')}',
    );
    try {
      final EtiquetaPdfResponse pdf = await widget.service.gerarPdf(
        templateId: templateId,
        items: items,
      );
      if (pdf.arquivoBase64.trim().isEmpty) {
        throw StateError('PDF_EMPTY');
      }
      final List<int> bytes = base64Decode(pdf.arquivoBase64);
      debugPrint(
        '[EtiquetaImpressaoWebPage] PDF recebido '
        'arquivo=${pdf.nomeArquivo} mimeType=${pdf.mimeType} '
        'paginas=${pdf.totalPaginas} etiquetas=${pdf.totalEtiquetas} '
        'bytes=${bytes.length}',
      );
      final bool downloaded = iniciarDownloadPdf(
        bytes: Uint8List.fromList(bytes),
        nomeArquivo: pdf.nomeArquivo,
        mimeType: pdf.mimeType,
      );
      if (!downloaded) throw StateError('DOWNLOAD_UNAVAILABLE');
      if (!mounted) return;
      setState(() => _lastPdf = pdf);
    } catch (error, stackTrace) {
      _logPdfGenerationFailure(
        error: error,
        stackTrace: stackTrace,
        templateId: templateId,
        templateName: model?.nome,
        items: items,
      );
      if (mounted) setState(() => _error = null);
      throw Exception(_pdfErrorMessage(error));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _pdfErrorMessage(Object error) {
    final String raw = error.toString();
    if (raw.contains('PDF_EMPTY')) {
      return _tr(
        'labels.print.emptyPdf',
        'O backend respondeu à geração, mas retornou um PDF vazio.',
        'The backend answered the generation request but returned an empty PDF.',
        'El backend respondió a la generación, pero devolvió un PDF vacío.',
      );
    }
    if (raw.contains('RESPOSTA_INVALIDA')) {
      return _tr(
        'labels.print.invalidPdfResponse',
        'A geração retornou uma resposta inválida. Verifique os logs técnicos e tente novamente.',
        'The generation returned an invalid response. Check the technical logs and try again.',
        'La generación devolvió una respuesta inválida. Revise los registros técnicos e inténtelo de nuevo.',
      );
    }
    if (raw.contains('ETIQUETA_VALOR_CODIGO_VAZIO')) {
      return _tr(
        'labels.print.missingBarcode',
        'Um dos produtos não possui código de barras, mas o modelo exige esse campo.',
        'One of the products has no barcode, but the template requires it.',
        'Uno de los productos no tiene código de barras, pero la plantilla lo requiere.',
      );
    }
    if (raw.contains('CHECKSUM_INVALIDO') ||
        raw.contains('EAN13_INVALIDO') ||
        raw.contains('EAN8_INVALIDO') ||
        raw.contains('UPCA_INVALIDO')) {
      return _tr(
        'labels.print.invalidBarcode',
        'Há um código de barras incompatível com a simbologia escolhida no modelo.',
        'A barcode is incompatible with the symbology selected in the template.',
        'Hay un código de barras incompatible con la simbología elegida en la plantilla.',
      );
    }
    if (raw.contains('DOWNLOAD_UNAVAILABLE')) {
      return _tr(
        'labels.print.downloadUnavailable',
        'O PDF foi gerado, mas o download não pôde ser iniciado.',
        'The PDF was generated, but the download could not be started.',
        'El PDF fue generado, pero no se pudo iniciar la descarga.',
      );
    }
    return _tr(
      'labels.print.genericError',
      'Não foi possível gerar o PDF de etiquetas. Revise o modelo e tente novamente.',
      'Could not generate the label PDF. Review the template and try again.',
      'No se pudo generar el PDF de etiquetas. Revise la plantilla e inténtelo de nuevo.',
    );
  }

  void _logPdfGenerationFailure({
    required Object error,
    required StackTrace stackTrace,
    required String templateId,
    required String? templateName,
    required List<EtiquetaImpressaoItem> items,
  }) {
    final int totalEtiquetas = items.fold<int>(
      0,
      (int total, EtiquetaImpressaoItem item) => total + item.quantidade,
    );
    debugPrint(
      '[EtiquetaImpressaoWebPage] Falha ao gerar PDF '
      'templateId=$templateId templateNome="${templateName ?? '-'}" '
      'produtos=${items.length} totalEtiquetas=$totalEtiquetas '
      'amostraIds=${items.take(5).map((EtiquetaImpressaoItem item) => item.sourceId).join(',')} '
      'erro=$error',
    );
    if (error is EtiquetaApiException) {
      debugPrint(
        '[EtiquetaImpressaoWebPage] Detalhes da API '
        'status=${error.statusCode} code=${error.code} '
        'message=${error.message ?? '-'} detail=${error.detail ?? '-'} '
        'path=${error.path ?? '-'}',
      );
    }
    debugPrint('[EtiquetaImpressaoWebPage] Stack trace: $stackTrace');
  }

  Widget _metadataChip(IconData icon, String label) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: tokens.danger.withValues(alpha: 0.10),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger, size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          IconButton(
            onPressed: () => setState(() => _error = null),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) =>
      value == value.roundToDouble()
          ? value.round().toString()
          : value.toStringAsFixed(1);

  String _tr(String key, String pt, String en, String es) =>
      etiquetaTr(context, key, pt: pt, en: en, es: es);
}

class _SelectedProduct {
  const _SelectedProduct({required this.product, required this.quantity});
  final ProdutoModel product;
  final int quantity;
}

double mathMin(double a, double b) => a < b ? a : b;
