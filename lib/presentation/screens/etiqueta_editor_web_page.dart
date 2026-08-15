import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/etiqueta_models.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

import 'etiqueta_web_i18n.dart';

class EtiquetaEditorWebPage extends StatefulWidget {
  const EtiquetaEditorWebPage({
    super.key,
    this.initialModel,
    required this.onSave,
    this.onClose,
  });

  final EtiquetaModelo? initialModel;
  final Future<EtiquetaModelo> Function(EtiquetaModelo model) onSave;
  final VoidCallback? onClose;

  @override
  State<EtiquetaEditorWebPage> createState() => _EtiquetaEditorWebPageState();
}

class _EtiquetaEditorWebPageState extends State<EtiquetaEditorWebPage> {
  late EtiquetaModelo _model;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _selectedElementId;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _model = widget.initialModel ?? _newModel();
    _nameController = TextEditingController(text: _model.nome);
    _descriptionController = TextEditingController(text: _model.descricao);
    if (_model.elementos.isNotEmpty) {
      _selectedElementId = _model.elementos.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  EtiquetaModelo _newModel() {
    return EtiquetaModelo(
      nome: '',
      descricao: '',
      papel: const EtiquetaPapel(preset: 'A4', larguraMm: 210, alturaMm: 297),
      grade: const EtiquetaGrade(
        colunas: 3,
        linhas: 8,
        margemSuperiorMm: 11,
        margemInferiorMm: 11,
        margemEsquerdaMm: 10,
        margemDireitaMm: 10,
        espacamentoHorizontalMm: 5,
        espacamentoVerticalMm: 5,
      ),
      etiqueta: const EtiquetaTamanho(larguraMm: 60, alturaMm: 30),
      elementos: _defaultElementsForNewModel(),
    );
  }

  List<EtiquetaElemento> _defaultElementsForNewModel() {
    return const <EtiquetaElemento>[
      EtiquetaElemento(
        id: 'default-company-name',
        tipo: 'TEXT',
        bindingKey: 'COMPANY_NAME',
        xMm: 3,
        yMm: 2,
        larguraMm: 54,
        alturaMm: 4.5,
        zIndex: 1,
        propriedades: <String, dynamic>{
          'fontSize': 7,
          'bold': false,
          'align': 'CENTER',
        },
      ),
      EtiquetaElemento(
        id: 'default-product-name',
        tipo: 'TEXT',
        bindingKey: 'PRODUCT_NAME',
        xMm: 3,
        yMm: 7,
        larguraMm: 54,
        alturaMm: 6.5,
        zIndex: 2,
        propriedades: <String, dynamic>{
          'fontSize': 10,
          'bold': true,
          'align': 'CENTER',
        },
      ),
      EtiquetaElemento(
        id: 'default-product-price',
        tipo: 'TEXT',
        bindingKey: 'PRODUCT_PRICE',
        xMm: 3,
        yMm: 14,
        larguraMm: 54,
        alturaMm: 4.5,
        zIndex: 3,
        propriedades: <String, dynamic>{
          'fontSize': 11,
          'bold': true,
          'align': 'CENTER',
        },
      ),
      EtiquetaElemento(
        id: 'default-product-barcode',
        tipo: 'BARCODE',
        bindingKey: 'PRODUCT_BARCODE',
        xMm: 4,
        yMm: 20,
        larguraMm: 52,
        alturaMm: 8,
        zIndex: 4,
        propriedades: <String, dynamic>{
          'barcodeType': 'CODE128',
          'showText': true,
        },
      ),
    ];
  }

  EtiquetaElemento? get _selectedElement {
    final String? id = _selectedElementId;
    if (id == null) return null;
    for (final EtiquetaElemento element in _model.elementos) {
      if (element.id == id) return element;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleSettingsProvider>();
    context.watch<EmpresaProvider>();
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String? geometryError = _geometryError();

    return Material(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          SixWebDashboardHeader(
            icon: Icons.local_offer_outlined,
            title:
                widget.initialModel == null
                    ? _tr(
                      'labels.editor.newTitle',
                      'Novo modelo de etiqueta',
                      'New label template',
                      'Nueva plantilla de etiqueta',
                    )
                    : _tr(
                      'labels.editor.editTitle',
                      'Editar modelo de etiqueta',
                      'Edit label template',
                      'Editar plantilla de etiqueta',
                    ),
            subtitle: _tr(
              'labels.editor.subtitle',
              'Configure medidas físicas, conteúdo e posicionamento. Tudo é salvo em milímetros.',
              'Configure physical dimensions, content and positioning. Everything is stored in millimeters.',
              'Configure medidas físicas, contenido y posición. Todo se guarda en milímetros.',
            ),
            onBack: widget.onClose,
            actions: <Widget>[
              FilledButton.icon(
                onPressed: _saving || geometryError != null ? null : _save,
                icon:
                    _saving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? _tr(
                        'labels.editor.saving',
                        'Salvando...',
                        'Saving...',
                        'Guardando...',
                      )
                      : _tr(
                        'labels.editor.save',
                        'Salvar modelo',
                        'Save template',
                        'Guardar plantilla',
                      ),
                ),
              ),
            ],
          ),
          if (geometryError != null || _saveError != null)
            _ErrorBanner(message: _saveError ?? geometryError!),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 1120;
                if (compact) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _settingsPanel(),
                        const SizedBox(height: 16),
                        SizedBox(height: 560, child: _canvasPanel()),
                        const SizedBox(height: 16),
                        _propertiesPanel(),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(width: 310, child: _settingsPanel()),
                      const SizedBox(width: 16),
                      Expanded(child: _canvasPanel()),
                      const SizedBox(width: 16),
                      SizedBox(width: 310, child: _propertiesPanel()),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsPanel() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: tokens.cardBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _tr('labels.editor.model', 'Modelo', 'Template', 'Plantilla'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration(
                _tr(
                  'labels.editor.name',
                  'Nome do modelo',
                  'Template name',
                  'Nombre de la plantilla',
                ),
                Icons.edit_outlined,
              ),
              onChanged: (_) => setState(() => _saveError = null),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              minLines: 1,
              maxLines: 2,
              decoration: _inputDecoration(
                _tr(
                  'labels.editor.description',
                  'Descrição (opcional)',
                  'Description (optional)',
                  'Descripción (opcional)',
                ),
                Icons.notes_outlined,
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle(
              _tr('labels.editor.paper', 'Papel', 'Paper', 'Papel'),
              Icons.description_outlined,
            ),
            const SizedBox(height: 10),
            _MenuField(
              icon: Icons.description_outlined,
              label: _tr(
                'labels.editor.format',
                'Formato',
                'Format',
                'Formato',
              ),
              value: _paperLabel(_model.papel.preset),
              values: const <String>[
                'A4',
                'LETTER',
                'THERMAL_40X30',
                'THERMAL_50X30',
                'THERMAL_60X40',
                'THERMAL_100X50',
                'CUSTOM',
              ],
              valueLabel: _paperLabel,
              onSelected: _applyPaperPreset,
            ),
            const SizedBox(height: 10),
            _MenuField(
              icon: Icons.crop_rotate_rounded,
              label: _tr(
                'labels.editor.orientation',
                'Orientação',
                'Orientation',
                'Orientación',
              ),
              value: _orientationLabel(_model.papel.orientacao),
              values: const <String>['PORTRAIT', 'LANDSCAPE'],
              valueLabel: _orientationLabel,
              onSelected: _changeOrientation,
            ),
            const SizedBox(height: 10),
            _twoNumbers(
              first: _numberField(
                keyName: 'paper-width',
                label: _tr('labels.editor.width', 'Largura', 'Width', 'Ancho'),
                value: _model.papel.larguraMm,
                enabled: _model.papel.preset == 'CUSTOM',
                onChanged:
                    (double value) =>
                        _setPaper(_model.papel.copyWith(larguraMm: value)),
              ),
              second: _numberField(
                keyName: 'paper-height',
                label: _tr('labels.editor.height', 'Altura', 'Height', 'Alto'),
                value: _model.papel.alturaMm,
                enabled: _model.papel.preset == 'CUSTOM',
                onChanged:
                    (double value) =>
                        _setPaper(_model.papel.copyWith(alturaMm: value)),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle(
              _tr(
                'labels.editor.grid',
                'Grade de etiquetas',
                'Label grid',
                'Cuadrícula de etiquetas',
              ),
              Icons.grid_view_outlined,
            ),
            const SizedBox(height: 10),
            _twoNumbers(
              first: _intField(
                keyName: 'columns',
                label: _tr(
                  'labels.editor.columns',
                  'Colunas',
                  'Columns',
                  'Columnas',
                ),
                value: _model.grade.colunas,
                onChanged:
                    (int value) =>
                        _setGrade(_model.grade.copyWith(colunas: value)),
              ),
              second: _intField(
                keyName: 'rows',
                label: _tr('labels.editor.rows', 'Linhas', 'Rows', 'Filas'),
                value: _model.grade.linhas,
                onChanged:
                    (int value) =>
                        _setGrade(_model.grade.copyWith(linhas: value)),
              ),
            ),
            const SizedBox(height: 10),
            _twoNumbers(
              first: _numberField(
                keyName: 'label-width',
                label: _tr(
                  'labels.editor.labelWidth',
                  'Etiqueta L',
                  'Label W',
                  'Etiqueta A',
                ),
                value: _model.etiqueta.larguraMm,
                onChanged:
                    (double value) => _setLabelSize(
                      _model.etiqueta.copyWith(larguraMm: value),
                    ),
              ),
              second: _numberField(
                keyName: 'label-height',
                label: _tr(
                  'labels.editor.labelHeight',
                  'Etiqueta A',
                  'Label H',
                  'Etiqueta H',
                ),
                value: _model.etiqueta.alturaMm,
                onChanged:
                    (double value) => _setLabelSize(
                      _model.etiqueta.copyWith(alturaMm: value),
                    ),
              ),
            ),
            const SizedBox(height: 10),
            _twoNumbers(
              first: _numberField(
                keyName: 'gap-h',
                label: _tr(
                  'labels.editor.horizontalGap',
                  'Gap H',
                  'H gap',
                  'Espacio H',
                ),
                value: _model.grade.espacamentoHorizontalMm,
                onChanged:
                    (double value) => _setGrade(
                      _model.grade.copyWith(espacamentoHorizontalMm: value),
                    ),
              ),
              second: _numberField(
                keyName: 'gap-v',
                label: _tr(
                  'labels.editor.verticalGap',
                  'Gap V',
                  'V gap',
                  'Espacio V',
                ),
                value: _model.grade.espacamentoVerticalMm,
                onChanged:
                    (double value) => _setGrade(
                      _model.grade.copyWith(espacamentoVerticalMm: value),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _tr(
                'labels.editor.margins',
                'Margens (mm)',
                'Margins (mm)',
                'Márgenes (mm)',
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _twoNumbers(
              first: _numberField(
                keyName: 'margin-left',
                label: _tr(
                  'labels.editor.left',
                  'Esquerda',
                  'Left',
                  'Izquierda',
                ),
                value: _model.grade.margemEsquerdaMm,
                onChanged:
                    (double value) => _setGrade(
                      _model.grade.copyWith(margemEsquerdaMm: value),
                    ),
              ),
              second: _numberField(
                keyName: 'margin-right',
                label: _tr(
                  'labels.editor.right',
                  'Direita',
                  'Right',
                  'Derecha',
                ),
                value: _model.grade.margemDireitaMm,
                onChanged:
                    (double value) => _setGrade(
                      _model.grade.copyWith(margemDireitaMm: value),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            _twoNumbers(
              first: _numberField(
                keyName: 'margin-top',
                label: _tr('labels.editor.top', 'Superior', 'Top', 'Superior'),
                value: _model.grade.margemSuperiorMm,
                onChanged:
                    (double value) => _setGrade(
                      _model.grade.copyWith(margemSuperiorMm: value),
                    ),
              ),
              second: _numberField(
                keyName: 'margin-bottom',
                label: _tr(
                  'labels.editor.bottom',
                  'Inferior',
                  'Bottom',
                  'Inferior',
                ),
                value: _model.grade.margemInferiorMm,
                onChanged:
                    (double value) => _setGrade(
                      _model.grade.copyWith(margemInferiorMm: value),
                    ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle(
              _tr(
                'labels.editor.sheetPreview',
                'Preview da folha',
                'Sheet preview',
                'Vista previa de la hoja',
              ),
              Icons.picture_as_pdf_outlined,
            ),
            const SizedBox(height: 10),
            SizedBox(height: 190, child: _SheetPreview(model: _model)),
          ],
        ),
      ),
    );
  }

  Widget _canvasPanel() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: tokens.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _tr(
                          'labels.editor.labelCanvas',
                          'Etiqueta',
                          'Label canvas',
                          'Etiqueta',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${_fmt(_model.etiqueta.larguraMm)} × ${_fmt(_model.etiqueta.alturaMm)} mm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_ElementPreset>(
                  tooltip: _tr(
                    'labels.editor.addElement',
                    'Adicionar elemento',
                    'Add element',
                    'Agregar elemento',
                  ),
                  onSelected: _addElement,
                  itemBuilder:
                      (BuildContext context) => _elementPresets
                          .map(
                            (_ElementPreset preset) =>
                                PopupMenuItem<_ElementPreset>(
                                  value: preset,
                                  child: Row(
                                    children: <Widget>[
                                      Icon(preset.icon, size: 18),
                                      const SizedBox(width: 10),
                                      Text(_elementPresetLabel(preset.key)),
                                    ],
                                  ),
                                ),
                          )
                          .toList(growable: false),
                  child: _addElementButton(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double availableWidth =
                      math.max(180.0, constraints.maxWidth - 50).toDouble();
                  final double availableHeight =
                      math.max(150.0, constraints.maxHeight - 45).toDouble();
                  final double scale =
                      math
                          .min(
                            availableWidth /
                                math.max(1, _model.etiqueta.larguraMm),
                            availableHeight /
                                math.max(1, _model.etiqueta.alturaMm),
                          )
                          .clamp(1.0, 16.0)
                          .toDouble();
                  final double width = _model.etiqueta.larguraMm * scale;
                  final double height = _model.etiqueta.alturaMm * scale;

                  return Container(
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '1 mm = ${scale.toStringAsFixed(2)} px',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: width,
                            height: height,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: tokens.selectedBorder),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                for (final EtiquetaElemento element
                                    in _model.elementos)
                                  _EditableElement(
                                    key: ValueKey<String>(element.id),
                                    element: element,
                                    scale: scale,
                                    selected: element.id == _selectedElementId,
                                    previewText: _previewText(element),
                                    onSelect:
                                        () => setState(
                                          () => _selectedElementId = element.id,
                                        ),
                                    onMove:
                                        (Offset delta) =>
                                            _moveElement(element, delta, scale),
                                    onResize:
                                        (Offset delta) => _resizeElement(
                                          element,
                                          delta,
                                          scale,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertiesPanel() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final EtiquetaElemento? element = _selectedElement;
    return Card(
      margin: EdgeInsets.zero,
      color: tokens.cardBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            element == null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      _tr(
                        'labels.editor.elements',
                        'Elementos',
                        'Elements',
                        'Elementos',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_model.elementos.isEmpty)
                      Text(
                        _tr(
                          'labels.editor.noElements',
                          'Adicione nome, preço, código de barras, QR Code ou texto livre.',
                          'Add product name, price, barcode, QR Code or free text.',
                          'Agregue nombre, precio, código de barras, QR o texto libre.',
                        ),
                        style: TextStyle(color: tokens.secondaryText),
                      )
                    else
                      for (final EtiquetaElemento item in _model.elementos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton.icon(
                            onPressed:
                                () => setState(
                                  () => _selectedElementId = item.id,
                                ),
                            icon: Icon(_iconForElement(item), size: 18),
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _bindingLabel(item.bindingKey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                  ],
                )
                : _elementProperties(element),
      ),
    );
  }

  Widget _elementProperties(EtiquetaElemento element) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool isText = element.tipo == 'TEXT';
    final bool isBarcode = element.tipo == 'BARCODE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _bindingLabel(element.bindingKey),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: _tr(
                'labels.editor.deleteElement',
                'Excluir elemento',
                'Delete element',
                'Eliminar elemento',
              ),
              onPressed: () => _deleteElement(element.id),
              icon: Icon(Icons.delete_outline_rounded, color: tokens.danger),
            ),
          ],
        ),
        Text(
          element.tipo,
          style: theme.textTheme.labelSmall?.copyWith(
            color: tokens.secondaryText,
          ),
        ),
        const SizedBox(height: 18),
        _sectionTitle(
          _tr(
            'labels.editor.positionSize',
            'Posição e tamanho',
            'Position and size',
            'Posición y tamaño',
          ),
          Icons.open_with_rounded,
        ),
        const SizedBox(height: 10),
        _twoNumbers(
          first: _numberField(
            keyName: 'element-x-${element.id}',
            label: 'X',
            value: element.xMm,
            onChanged:
                (double value) => _updateElement(element.copyWith(xMm: value)),
          ),
          second: _numberField(
            keyName: 'element-y-${element.id}',
            label: 'Y',
            value: element.yMm,
            onChanged:
                (double value) => _updateElement(element.copyWith(yMm: value)),
          ),
        ),
        const SizedBox(height: 8),
        _twoNumbers(
          first: _numberField(
            keyName: 'element-w-${element.id}',
            label: _tr('labels.editor.width', 'Largura', 'Width', 'Ancho'),
            value: element.larguraMm,
            onChanged:
                (double value) =>
                    _updateElement(element.copyWith(larguraMm: value)),
          ),
          second: _numberField(
            keyName: 'element-h-${element.id}',
            label: _tr('labels.editor.height', 'Altura', 'Height', 'Alto'),
            value: element.alturaMm,
            onChanged:
                (double value) =>
                    _updateElement(element.copyWith(alturaMm: value)),
          ),
        ),
        if (isText) ...<Widget>[
          const SizedBox(height: 18),
          _sectionTitle(
            _tr('labels.editor.textStyle', 'Texto', 'Text', 'Texto'),
            Icons.text_fields_rounded,
          ),
          const SizedBox(height: 10),
          if (element.bindingKey == 'FREE_TEXT')
            TextField(
              key: ValueKey<String>(
                'free-text-${element.id}-${element.propriedades['text']}',
              ),
              controller: TextEditingController(
                text: element.propriedades['text']?.toString() ?? '',
              ),
              decoration: _inputDecoration(
                _tr(
                  'labels.editor.freeText',
                  'Texto livre',
                  'Free text',
                  'Texto libre',
                ),
                Icons.short_text_rounded,
              ),
              onChanged:
                  (String value) => _updateProperties(
                    element,
                    <String, dynamic>{'text': value},
                  ),
            ),
          if (element.bindingKey == 'FREE_TEXT') const SizedBox(height: 10),
          _numberField(
            keyName: 'font-size-${element.id}',
            label: _tr(
              'labels.editor.fontSize',
              'Tamanho da fonte (pt)',
              'Font size (pt)',
              'Tamaño de fuente (pt)',
            ),
            value: _propertyDouble(element, 'fontSize', 10),
            suffix: 'pt',
            onChanged:
                (double value) => _updateProperties(element, <String, dynamic>{
                  'fontSize': value,
                }),
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _tr('labels.editor.bold', 'Negrito', 'Bold', 'Negrita'),
            ),
            value: _propertyBool(element, 'bold', false),
            onChanged:
                (bool value) => _updateProperties(element, <String, dynamic>{
                  'bold': value,
                }),
          ),
          _MenuField(
            icon: Icons.format_align_left_rounded,
            label: _tr(
              'labels.editor.alignment',
              'Alinhamento',
              'Alignment',
              'Alineación',
            ),
            value: _alignLabel(
              element.propriedades['align']?.toString() ?? 'LEFT',
            ),
            values: const <String>['LEFT', 'CENTER', 'RIGHT'],
            valueLabel: _alignLabel,
            onSelected:
                (String value) => _updateProperties(element, <String, dynamic>{
                  'align': value,
                }),
          ),
        ],
        if (isBarcode) ...<Widget>[
          const SizedBox(height: 18),
          _sectionTitle(
            _tr(
              'labels.editor.barcode',
              'Código de barras',
              'Barcode',
              'Código de barras',
            ),
            Icons.view_week_outlined,
          ),
          const SizedBox(height: 10),
          _MenuField(
            icon: Icons.view_week_outlined,
            label: _tr(
              'labels.editor.symbology',
              'Simbologia',
              'Symbology',
              'Simbología',
            ),
            value: element.propriedades['barcodeType']?.toString() ?? 'CODE128',
            values: const <String>[
              'CODE128',
              'CODE39',
              'EAN13',
              'EAN8',
              'UPCA',
              'ITF',
            ],
            valueLabel: (String value) => value,
            onSelected:
                (String value) => _updateProperties(element, <String, dynamic>{
                  'barcodeType': value,
                }),
          ),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _tr(
                'labels.editor.showCode',
                'Exibir código abaixo das barras',
                'Show value below bars',
                'Mostrar valor bajo las barras',
              ),
            ),
            value: _propertyBool(element, 'showText', true),
            onChanged:
                (bool value) => _updateProperties(element, <String, dynamic>{
                  'showText': value,
                }),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Text(
            _tr(
              'labels.editor.bindingHint',
              'O modelo salva a referência do campo, não o valor exibido no preview.',
              'The template stores the field reference, not the preview value.',
              'La plantilla guarda la referencia del campo, no el valor de la vista previa.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(
        () =>
            _saveError = _tr(
              'labels.editor.nameRequired',
              'Informe um nome para o modelo.',
              'Enter a name for the template.',
              'Ingrese un nombre para la plantilla.',
            ),
      );
      return;
    }
    if (_model.elementos.isEmpty) {
      setState(
        () =>
            _saveError = _tr(
              'labels.editor.atLeastOneElement',
              'Adicione ao menos um elemento antes de salvar o modelo.',
              'Add at least one element before saving the template.',
              'Agregue al menos un elemento antes de guardar la plantilla.',
            ),
      );
      return;
    }
    final String? geometry = _geometryError();
    if (geometry != null) {
      setState(() => _saveError = geometry);
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final EtiquetaModelo saved = await widget.onSave(
        _model.copyWith(
          nome: name,
          descricao: _descriptionController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop<EtiquetaModelo>(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = _tr(
          'labels.editor.saveError',
          'Não foi possível salvar o modelo. Verifique os dados e tente novamente.',
          'Could not save the template. Check the data and try again.',
          'No se pudo guardar la plantilla. Revise los datos e inténtelo nuevamente.',
        );
      });
    }
  }

  String? _geometryError() {
    if (_model.papel.larguraMm <= 0 ||
        _model.papel.alturaMm <= 0 ||
        _model.etiqueta.larguraMm <= 0 ||
        _model.etiqueta.alturaMm <= 0 ||
        _model.grade.colunas <= 0 ||
        _model.grade.linhas <= 0) {
      return _tr(
        'labels.editor.invalidDimensions',
        'As dimensões, linhas e colunas precisam ser maiores que zero.',
        'Dimensions, rows and columns must be greater than zero.',
        'Las dimensiones, filas y columnas deben ser mayores que cero.',
      );
    }
    final double requiredWidth =
        _model.grade.margemEsquerdaMm +
        _model.grade.margemDireitaMm +
        _model.grade.colunas * _model.etiqueta.larguraMm +
        math.max(0, _model.grade.colunas - 1) *
            _model.grade.espacamentoHorizontalMm;
    final double requiredHeight =
        _model.grade.margemSuperiorMm +
        _model.grade.margemInferiorMm +
        _model.grade.linhas * _model.etiqueta.alturaMm +
        math.max(0, _model.grade.linhas - 1) *
            _model.grade.espacamentoVerticalMm;
    if (requiredWidth > _model.papel.larguraMm + 0.001 ||
        requiredHeight > _model.papel.alturaMm + 0.001) {
      return _tr(
        'labels.editor.gridDoesNotFit',
        'A grade configurada não cabe no papel. Ajuste etiquetas, margens, gaps, linhas ou colunas.',
        'The configured grid does not fit on the paper. Adjust labels, margins, gaps, rows or columns.',
        'La cuadrícula configurada no cabe en el papel. Ajuste etiquetas, márgenes, espacios, filas o columnas.',
      );
    }
    for (final EtiquetaElemento element in _model.elementos) {
      if (element.xMm < 0 ||
          element.yMm < 0 ||
          element.larguraMm <= 0 ||
          element.alturaMm <= 0 ||
          element.xMm + element.larguraMm > _model.etiqueta.larguraMm + 0.001 ||
          element.yMm + element.alturaMm > _model.etiqueta.alturaMm + 0.001) {
        return _tr(
          'labels.editor.elementOutOfBounds',
          'Há um elemento fora dos limites da etiqueta.',
          'An element is outside the label bounds.',
          'Hay un elemento fuera de los límites de la etiqueta.',
        );
      }
    }
    return null;
  }

  void _applyPaperPreset(String preset) {
    final EtiquetaModelo next = switch (preset) {
      'A4' => _model.copyWith(
        papel: const EtiquetaPapel(preset: 'A4', larguraMm: 210, alturaMm: 297),
        grade: const EtiquetaGrade(
          colunas: 3,
          linhas: 8,
          margemSuperiorMm: 11,
          margemInferiorMm: 11,
          margemEsquerdaMm: 10,
          margemDireitaMm: 10,
          espacamentoHorizontalMm: 5,
          espacamentoVerticalMm: 5,
        ),
        etiqueta: const EtiquetaTamanho(larguraMm: 60, alturaMm: 30),
      ),
      'LETTER' => _model.copyWith(
        papel: const EtiquetaPapel(
          preset: 'LETTER',
          larguraMm: 215.9,
          alturaMm: 279.4,
        ),
        grade: const EtiquetaGrade(
          colunas: 3,
          linhas: 7,
          margemSuperiorMm: 10,
          margemInferiorMm: 10,
          margemEsquerdaMm: 10,
          margemDireitaMm: 10,
          espacamentoHorizontalMm: 5,
          espacamentoVerticalMm: 5,
        ),
        etiqueta: const EtiquetaTamanho(larguraMm: 60, alturaMm: 32),
      ),
      'THERMAL_40X30' => _thermalPreset(preset, 40, 30),
      'THERMAL_50X30' => _thermalPreset(preset, 50, 30),
      'THERMAL_60X40' => _thermalPreset(preset, 60, 40),
      'THERMAL_100X50' => _thermalPreset(preset, 100, 50),
      _ => _model.copyWith(papel: _model.papel.copyWith(preset: 'CUSTOM')),
    };
    setState(() {
      _model = _clampElements(next);
      _saveError = null;
    });
  }

  EtiquetaModelo _thermalPreset(String preset, double width, double height) {
    return _model.copyWith(
      papel: EtiquetaPapel(preset: preset, larguraMm: width, alturaMm: height),
      grade: const EtiquetaGrade(colunas: 1, linhas: 1),
      etiqueta: EtiquetaTamanho(larguraMm: width, alturaMm: height),
    );
  }

  void _changeOrientation(String orientation) {
    if (_model.papel.orientacao == orientation) return;
    setState(() {
      _model = _model.copyWith(
        papel: _model.papel.copyWith(
          orientacao: orientation,
          larguraMm: _model.papel.alturaMm,
          alturaMm: _model.papel.larguraMm,
        ),
      );
      _saveError = null;
    });
  }

  void _addElement(_ElementPreset preset) {
    final int index = _model.elementos.length + 1;
    final double maxWidth =
        math.max(4.0, _model.etiqueta.larguraMm - 6).toDouble();
    final double maxHeight =
        math.max(4.0, _model.etiqueta.alturaMm - 6).toDouble();
    final EtiquetaElemento element = EtiquetaElemento(
      id: '${preset.key.toLowerCase()}-${DateTime.now().microsecondsSinceEpoch}',
      tipo: preset.type,
      bindingKey: preset.binding,
      xMm: 3,
      yMm:
          math
              .min(
                3.0 + ((index - 1) * 2.0),
                math.max(0.0, _model.etiqueta.alturaMm - 8),
              )
              .toDouble(),
      larguraMm: math.min(preset.widthMm, maxWidth).toDouble(),
      alturaMm: math.min(preset.heightMm, maxHeight).toDouble(),
      zIndex: index,
      propriedades: Map<String, dynamic>.from(preset.properties),
    );
    setState(() {
      _model = _model.copyWith(
        elementos: <EtiquetaElemento>[..._model.elementos, element],
      );
      _selectedElementId = element.id;
      _saveError = null;
    });
  }

  void _deleteElement(String id) {
    setState(() {
      _model = _model.copyWith(
        elementos: _model.elementos
            .where((EtiquetaElemento item) => item.id != id)
            .toList(growable: false),
      );
      _selectedElementId =
          _model.elementos.isEmpty ? null : _model.elementos.first.id;
    });
  }

  void _moveElement(EtiquetaElemento element, Offset deltaPx, double scale) {
    final double maxX =
        math.max(0, _model.etiqueta.larguraMm - element.larguraMm).toDouble();
    final double maxY =
        math.max(0, _model.etiqueta.alturaMm - element.alturaMm).toDouble();
    _updateElement(
      element.copyWith(
        xMm: (element.xMm + deltaPx.dx / scale).clamp(0.0, maxX).toDouble(),
        yMm: (element.yMm + deltaPx.dy / scale).clamp(0.0, maxY).toDouble(),
      ),
    );
  }

  void _resizeElement(EtiquetaElemento element, Offset deltaPx, double scale) {
    final double maxWidth =
        math.max(2.0, _model.etiqueta.larguraMm - element.xMm).toDouble();
    final double maxHeight =
        math.max(2.0, _model.etiqueta.alturaMm - element.yMm).toDouble();
    _updateElement(
      element.copyWith(
        larguraMm:
            (element.larguraMm + deltaPx.dx / scale)
                .clamp(2.0, maxWidth)
                .toDouble(),
        alturaMm:
            (element.alturaMm + deltaPx.dy / scale)
                .clamp(2.0, maxHeight)
                .toDouble(),
      ),
    );
  }

  void _updateElement(EtiquetaElemento updated) {
    setState(() {
      _model = _model.copyWith(
        elementos: <EtiquetaElemento>[
          for (final EtiquetaElemento element in _model.elementos)
            if (element.id == updated.id) updated else element,
        ],
      );
      _saveError = null;
    });
  }

  void _updateProperties(
    EtiquetaElemento element,
    Map<String, dynamic> changes,
  ) {
    _updateElement(
      element.copyWith(
        propriedades: <String, dynamic>{...element.propriedades, ...changes},
      ),
    );
  }

  void _setPaper(EtiquetaPapel paper) =>
      setState(() => _model = _model.copyWith(papel: paper));
  void _setGrade(EtiquetaGrade grade) =>
      setState(() => _model = _model.copyWith(grade: grade));
  void _setLabelSize(EtiquetaTamanho size) =>
      setState(() => _model = _clampElements(_model.copyWith(etiqueta: size)));

  EtiquetaModelo _clampElements(EtiquetaModelo model) {
    return model.copyWith(
      elementos: model.elementos
          .map((EtiquetaElemento element) {
            final double width =
                element.larguraMm
                    .clamp(2.0, math.max(2.0, model.etiqueta.larguraMm))
                    .toDouble();
            final double height =
                element.alturaMm
                    .clamp(2.0, math.max(2.0, model.etiqueta.alturaMm))
                    .toDouble();
            return element.copyWith(
              larguraMm: width,
              alturaMm: height,
              xMm:
                  element.xMm
                      .clamp(
                        0.0,
                        math.max(0.0, model.etiqueta.larguraMm - width),
                      )
                      .toDouble(),
              yMm:
                  element.yMm
                      .clamp(
                        0.0,
                        math.max(0.0, model.etiqueta.alturaMm - height),
                      )
                      .toDouble(),
            );
          })
          .toList(growable: false),
    );
  }

  String _previewText(EtiquetaElemento element) {
    switch (element.bindingKey) {
      case 'PRODUCT_NAME':
        return _tr(
          'labels.preview.product',
          'Produto exemplo',
          'Sample product',
          'Producto de ejemplo',
        );
      case 'PRODUCT_PRICE':
        return context.read<LocaleSettingsProvider>().formatCurrency(129.90);
      case 'PRODUCT_BARCODE':
        return '7891234567895';
      case 'PRODUCT_INTERNAL_CODE':
        return 'ABC123';
      case 'COMPANY_NAME':
        return _currentCompanyPreviewName();
      case 'FREE_TEXT':
        return element.propriedades['text']?.toString() ??
            _tr(
              'labels.preview.freeText',
              'Texto livre',
              'Free text',
              'Texto libre',
            );
      default:
        return element.bindingKey;
    }
  }

  String _currentCompanyPreviewName() {
    final String nomeFantasia =
        context.read<EmpresaProvider>().empresa?.nomeFantasia.trim() ?? '';
    if (nomeFantasia.isNotEmpty) return nomeFantasia;
    return _tr(
      'labels.preview.company',
      'Nome do comércio',
      'Business name',
      'Nombre del comercio',
    );
  }

  IconData _iconForElement(EtiquetaElemento element) => switch (element.tipo) {
    'BARCODE' => Icons.view_week_outlined,
    'QRCODE' => Icons.qr_code_2_rounded,
    _ => Icons.text_fields_rounded,
  };

  double _propertyDouble(
    EtiquetaElemento element,
    String key,
    double fallback,
  ) {
    final dynamic value = element.propriedades[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _propertyBool(EtiquetaElemento element, String key, bool fallback) {
    final dynamic value = element.propriedades[key];
    return value is bool ? value : fallback;
  }

  Widget _sectionTitle(String label, IconData icon) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _addElementButton() {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.selectedBackground.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.selectedBorder.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.add_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            _tr('labels.editor.add', 'Adicionar', 'Add', 'Agregar'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _twoNumbers({required Widget first, required Widget second}) {
    return Row(
      children: <Widget>[
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
      ],
    );
  }

  Widget _numberField({
    required String keyName,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    bool enabled = true,
    String suffix = 'mm',
  }) {
    return _LiveNumberField(
      key: ValueKey<String>('number-$keyName'),
      value: value,
      enabled: enabled,
      decoration: _inputDecoration(label, null, suffixText: suffix),
      formatter: _fmt,
      onChanged: onChanged,
    );
  }

  Widget _intField({
    required String keyName,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return _LiveIntField(
      key: ValueKey<String>('int-$keyName'),
      value: value,
      decoration: _inputDecoration(label, null),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData? icon, {
    String? suffixText,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 19),
      suffixText: suffixText,
      isDense: true,
      filled: true,
      fillColor: tokens.inputBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.selectedBorder, width: 1.3),
      ),
    );
  }

  String _paperLabel(String value) => switch (value) {
    'A4' => 'A4 · 210 × 297 mm',
    'LETTER' => _tr(
      'labels.paper.letter',
      'Carta · 215,9 × 279,4 mm',
      'Letter · 215.9 × 279.4 mm',
      'Carta · 215,9 × 279,4 mm',
    ),
    'THERMAL_40X30' => '40 × 30 mm',
    'THERMAL_50X30' => '50 × 30 mm',
    'THERMAL_60X40' => '60 × 40 mm',
    'THERMAL_100X50' => '100 × 50 mm',
    _ => _tr('labels.paper.custom', 'Personalizado', 'Custom', 'Personalizado'),
  };

  String _orientationLabel(String value) =>
      value == 'LANDSCAPE'
          ? _tr(
            'labels.orientation.landscape',
            'Paisagem',
            'Landscape',
            'Horizontal',
          )
          : _tr(
            'labels.orientation.portrait',
            'Retrato',
            'Portrait',
            'Vertical',
          );

  String _alignLabel(String value) => switch (value) {
    'CENTER' => _tr('labels.align.center', 'Centro', 'Center', 'Centro'),
    'RIGHT' => _tr('labels.align.right', 'Direita', 'Right', 'Derecha'),
    _ => _tr('labels.align.left', 'Esquerda', 'Left', 'Izquierda'),
  };

  String _bindingLabel(String value) => switch (value) {
    'PRODUCT_NAME' => _tr(
      'labels.binding.productName',
      'Nome do produto',
      'Product name',
      'Nombre del producto',
    ),
    'PRODUCT_PRICE' => _tr(
      'labels.binding.productPrice',
      'Preço do produto',
      'Product price',
      'Precio del producto',
    ),
    'PRODUCT_BARCODE' => _tr(
      'labels.binding.productBarcode',
      'Código de barras do produto',
      'Product barcode',
      'Código de barras del producto',
    ),
    'PRODUCT_INTERNAL_CODE' => _tr(
      'labels.binding.internalCode',
      'Código interno',
      'Internal code',
      'Código interno',
    ),
    'COMPANY_NAME' => _tr(
      'labels.binding.companyName',
      'Nome do comércio',
      'Business name',
      'Nombre del comercio',
    ),
    'FREE_TEXT' => _tr(
      'labels.binding.freeText',
      'Texto livre',
      'Free text',
      'Texto libre',
    ),
    _ => value,
  };

  String _elementPresetLabel(String key) => switch (key) {
    'PRODUCT_NAME' => _bindingLabel('PRODUCT_NAME'),
    'PRODUCT_PRICE' => _bindingLabel('PRODUCT_PRICE'),
    'BARCODE' => _tr(
      'labels.element.barcode',
      'Código de barras',
      'Barcode',
      'Código de barras',
    ),
    'QRCODE' => 'QR Code',
    'PRODUCT_INTERNAL_CODE' => _bindingLabel('PRODUCT_INTERNAL_CODE'),
    'COMPANY_NAME' => _bindingLabel('COMPANY_NAME'),
    _ => _bindingLabel('FREE_TEXT'),
  };

  String _fmt(double value) {
    if ((value - value.round()).abs() < 0.0001) return value.round().toString();
    return value
        .toStringAsFixed(value.abs() < 10 ? 2 : 1)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _tr(String key, String pt, String en, String es) =>
      etiquetaTr(context, key, pt: pt, en: en, es: es);
}

class _EditableElement extends StatelessWidget {
  const _EditableElement({
    super.key,
    required this.element,
    required this.scale,
    required this.selected,
    required this.previewText,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });

  final EtiquetaElemento element;
  final double scale;
  final bool selected;
  final String previewText;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Positioned(
      left: element.xMm * scale,
      top: element.yMm * scale,
      width: element.larguraMm * scale,
      height: element.alturaMm * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSelect,
                onPanStart: (_) => onSelect(),
                onPanUpdate:
                    (DragUpdateDetails details) => onMove(details.delta),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 110),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? colors.primaryContainer.withValues(alpha: 0.32)
                            : colors.surfaceContainerHighest.withValues(
                              alpha: 0.35,
                            ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected ? colors.primary : colors.outlineVariant,
                      width: selected ? 1.4 : 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: _ElementPreview(
                      element: element,
                      previewText: previewText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              right: -6,
              bottom: -6,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate:
                      (DragUpdateDetails details) => onResize(details.delta),
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.onPrimary, width: 1.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ElementPreview extends StatelessWidget {
  const _ElementPreview({required this.element, required this.previewText});

  final EtiquetaElemento element;
  final String previewText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (element.tipo == 'BARCODE') {
      return Padding(
        padding: const EdgeInsets.all(3),
        child: CustomPaint(
          painter: _BarcodePreviewPainter(color: colors.onSurface),
          child: const SizedBox.expand(),
        ),
      );
    }
    if (element.tipo == 'QRCODE') {
      return Padding(
        padding: const EdgeInsets.all(3),
        child: CustomPaint(
          painter: _QrPreviewPainter(color: colors.onSurface),
          child: const SizedBox.expand(),
        ),
      );
    }
    final bool bold = element.propriedades['bold'] == true;
    final String align = element.propriedades['align']?.toString() ?? 'LEFT';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Align(
        alignment: switch (align) {
          'CENTER' => Alignment.center,
          'RIGHT' => Alignment.centerRight,
          _ => Alignment.centerLeft,
        },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            previewText,
            maxLines: 2,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetPreview extends StatelessWidget {
  const _SheetPreview({required this.model});
  final EtiquetaModelo model;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double scale =
            math
                .min(
                  (constraints.maxWidth - 20) /
                      math.max(1, model.papel.larguraMm),
                  (constraints.maxHeight - 20) /
                      math.max(1, model.papel.alturaMm),
                )
                .clamp(0.1, 5.0)
                .toDouble();
        return Center(
          child: Container(
            width: model.papel.larguraMm * scale,
            height: model.papel.alturaMm * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: tokens.cardBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                for (int row = 0; row < model.grade.linhas; row++)
                  for (int column = 0; column < model.grade.colunas; column++)
                    Positioned(
                      left:
                          (model.grade.margemEsquerdaMm +
                              column *
                                  (model.etiqueta.larguraMm +
                                      model.grade.espacamentoHorizontalMm)) *
                          scale,
                      top:
                          (model.grade.margemSuperiorMm +
                              row *
                                  (model.etiqueta.alturaMm +
                                      model.grade.espacamentoVerticalMm)) *
                          scale,
                      width: model.etiqueta.larguraMm * scale,
                      height: model.etiqueta.alturaMm * scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.selectedBackground.withValues(
                            alpha: 0.45,
                          ),
                          border: Border.all(
                            color: tokens.selectedBorder,
                            width: 0.7,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuField extends StatefulWidget {
  const _MenuField({
    required this.icon,
    required this.label,
    required this.value,
    required this.values,
    required this.valueLabel,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<String> values;
  final String Function(String value) valueLabel;
  final ValueChanged<String> onSelected;

  @override
  State<_MenuField> createState() => _MenuFieldState();
}

class _MenuFieldState extends State<_MenuField> {
  bool _open = false;

  String get _safeValue {
    if (widget.values.contains(widget.value)) {
      return widget.value;
    }
    return widget.values.isEmpty ? '' : widget.values.first;
  }

  Future<void> _showOptions() async {
    if (widget.values.isEmpty) return;
    setState(() => _open = true);

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero, ancestor: overlay);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String safeValue = _safeValue;

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
      color: tokens.menuBackground,
      constraints: BoxConstraints.tightFor(width: box.size.width),
      items: widget.values
          .map(
            (String item) => PopupMenuItem<String>(
              value: item,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: _MenuFieldMenuItem(
                label: widget.valueLabel(item),
                selected: item == safeValue,
              ),
            ),
          )
          .toList(growable: false),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MenuFieldTrigger(
      label: widget.label,
      value: widget.valueLabel(_safeValue),
      icon: widget.icon,
      open: _open,
      onTap: _showOptions,
    );
  }
}

class _MenuFieldTrigger extends StatefulWidget {
  const _MenuFieldTrigger({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.open = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool open;

  @override
  State<_MenuFieldTrigger> createState() => _MenuFieldTriggerState();
}

class _MenuFieldTriggerState extends State<_MenuFieldTrigger> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool enabled = widget.onTap != null;
    final bool active = enabled && (widget.open || _hover);
    final Color borderColor =
        active ? tokens.selectedBorder : tokens.cardBorder;
    final Color backgroundColor =
        active ? tokens.selectedBackground : tokens.inputBackground;

    return Semantics(
      button: true,
      enabled: enabled,
      label: '${widget.label}: ${widget.value}',
      child: Tooltip(
        message: 'Selecionar ${widget.label}',
        waitDuration: const Duration(milliseconds: 450),
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: enabled ? widget.onTap : null,
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
                  boxShadow:
                      active
                          ? <BoxShadow>[
                            BoxShadow(
                              color: tokens.info.withValues(alpha: 0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.secondaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: widget.open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: active ? tokens.info : tokens.mutedText,
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
    );
  }
}

class _MenuFieldMenuItem extends StatelessWidget {
  const _MenuFieldMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? tokens.selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            selected ? Icons.check_circle_rounded : Icons.arrow_right_rounded,
            color: selected ? tokens.info : tokens.mutedText,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveNumberField extends StatefulWidget {
  const _LiveNumberField({
    super.key,
    required this.value,
    required this.decoration,
    required this.formatter,
    required this.onChanged,
    this.enabled = true,
  });

  final double value;
  final InputDecoration decoration;
  final String Function(double value) formatter;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  State<_LiveNumberField> createState() => _LiveNumberFieldState();
}

class _LiveNumberFieldState extends State<_LiveNumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.formatter(widget.value));
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _LiveNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final String formatted = widget.formatter(widget.value);
      if (_controller.text != formatted) {
        _controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) return;
    final String formatted = widget.formatter(widget.value);
    if (_controller.text == formatted) return;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: widget.decoration,
      onChanged: (String text) {
        final double? parsed = double.tryParse(text.replaceAll(',', '.'));
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}

class _LiveIntField extends StatefulWidget {
  const _LiveIntField({
    super.key,
    required this.value,
    required this.decoration,
    required this.onChanged,
  });

  final int value;
  final InputDecoration decoration;
  final ValueChanged<int> onChanged;

  @override
  State<_LiveIntField> createState() => _LiveIntFieldState();
}

class _LiveIntFieldState extends State<_LiveIntField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _LiveIntField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final String formatted = widget.value.toString();
      if (_controller.text != formatted) {
        _controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) return;
    final String formatted = widget.value.toString();
    if (_controller.text == formatted) return;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      decoration: widget.decoration,
      onChanged: (String text) {
        final int? parsed = int.tryParse(text);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}

class _ElementPreset {
  const _ElementPreset({
    required this.key,
    required this.type,
    required this.binding,
    required this.icon,
    required this.widthMm,
    required this.heightMm,
    this.properties = const <String, dynamic>{},
  });

  final String key;
  final String type;
  final String binding;
  final IconData icon;
  final double widthMm;
  final double heightMm;
  final Map<String, dynamic> properties;
}

const List<_ElementPreset> _elementPresets = <_ElementPreset>[
  _ElementPreset(
    key: 'PRODUCT_NAME',
    type: 'TEXT',
    binding: 'PRODUCT_NAME',
    icon: Icons.title_rounded,
    widthMm: 44,
    heightMm: 6,
    properties: <String, dynamic>{
      'fontSize': 10,
      'bold': true,
      'align': 'LEFT',
    },
  ),
  _ElementPreset(
    key: 'PRODUCT_PRICE',
    type: 'TEXT',
    binding: 'PRODUCT_PRICE',
    icon: Icons.payments_outlined,
    widthMm: 25,
    heightMm: 7,
    properties: <String, dynamic>{
      'fontSize': 14,
      'bold': true,
      'align': 'LEFT',
    },
  ),
  _ElementPreset(
    key: 'BARCODE',
    type: 'BARCODE',
    binding: 'PRODUCT_BARCODE',
    icon: Icons.view_week_outlined,
    widthMm: 44,
    heightMm: 10,
    properties: <String, dynamic>{'barcodeType': 'CODE128', 'showText': true},
  ),
  _ElementPreset(
    key: 'QRCODE',
    type: 'QRCODE',
    binding: 'PRODUCT_BARCODE',
    icon: Icons.qr_code_2_rounded,
    widthMm: 15,
    heightMm: 15,
  ),
  _ElementPreset(
    key: 'PRODUCT_INTERNAL_CODE',
    type: 'TEXT',
    binding: 'PRODUCT_INTERNAL_CODE',
    icon: Icons.tag_rounded,
    widthMm: 28,
    heightMm: 5,
    properties: <String, dynamic>{
      'fontSize': 8,
      'bold': false,
      'align': 'LEFT',
    },
  ),
  _ElementPreset(
    key: 'COMPANY_NAME',
    type: 'TEXT',
    binding: 'COMPANY_NAME',
    icon: Icons.storefront_outlined,
    widthMm: 40,
    heightMm: 5,
    properties: <String, dynamic>{
      'fontSize': 8,
      'bold': false,
      'align': 'LEFT',
    },
  ),
  _ElementPreset(
    key: 'FREE_TEXT',
    type: 'TEXT',
    binding: 'FREE_TEXT',
    icon: Icons.short_text_rounded,
    widthMm: 30,
    heightMm: 5,
    properties: <String, dynamic>{
      'text': 'Texto',
      'fontSize': 9,
      'bold': false,
      'align': 'LEFT',
    },
  ),
];

class _BarcodePreviewPainter extends CustomPainter {
  const _BarcodePreviewPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double unit = math.max(1.0, size.width / 100).toDouble();
    double x = 0;
    int index = 0;
    while (x < size.width) {
      final double width =
          unit *
          (index % 5 == 0
              ? 3
              : index % 3 == 0
              ? 2
              : 1);
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          0,
          math.min(width, size.width - x).toDouble(),
          size.height,
        ),
        paint,
      );
      x += width + unit;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePreviewPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _QrPreviewPainter extends CustomPainter {
  const _QrPreviewPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    const int count = 17;
    final double cell = math.min(size.width, size.height) / count;
    for (int y = 0; y < count; y++) {
      for (int x = 0; x < count; x++) {
        final bool finder =
            (x < 5 && y < 5) ||
            (x >= count - 5 && y < 5) ||
            (x < 5 && y >= count - 5);
        final bool random = ((x * 3 + y * 5 + x * y) % 7) < 3;
        if (finder || random) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPreviewPainter oldDelegate) =>
      oldDelegate.color != color;
}
