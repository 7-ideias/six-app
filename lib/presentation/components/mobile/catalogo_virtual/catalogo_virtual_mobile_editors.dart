import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/data/models/catalogo_publico_configuracao_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';

const List<String> _catalogAccentColors = <String>[
  '#126BFF',
  '#0F766E',
  '#7C3AED',
  '#C2410C',
  '#BE185D',
  '#334155',
];

Future<CatalogoPublicoPersonalizacaoModel?>
showCatalogoVirtualPresentationMobileEditor({
  required BuildContext context,
  required CatalogoPublicoPersonalizacaoModel current,
}) {
  return showModalBottomSheet<CatalogoPublicoPersonalizacaoModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder: (_) => _PresentationEditorSheet(current: current),
  );
}

Future<CatalogoPublicoPersonalizacaoModel?>
showCatalogoVirtualAppearanceMobileEditor({
  required BuildContext context,
  required CatalogoPublicoPersonalizacaoModel current,
}) {
  return showModalBottomSheet<CatalogoPublicoPersonalizacaoModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder: (_) => _AppearanceEditorSheet(current: current),
  );
}

Future<CatalogoPublicoPersonalizacaoModel?>
showCatalogoVirtualContentMobileEditor({
  required BuildContext context,
  required CatalogoPublicoPersonalizacaoModel current,
}) {
  return showModalBottomSheet<CatalogoPublicoPersonalizacaoModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder: (_) => _ContentEditorSheet(current: current),
  );
}

Future<bool> showCatalogoVirtualUnpublishMobileConfirmation({
  required BuildContext context,
}) async {
  final bool? confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.56),
    builder: (BuildContext sheetContext) {
      final SixMobileColorScheme colors = sheetContext.sixMobileColors;
      final double minHeight = MediaQuery.sizeOf(sheetContext).height * 0.42;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(child: _SheetHandle(color: colors.strongBorder)),
                    const SizedBox(height: 22),
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(
                        Icons.visibility_off_outlined,
                        color: colors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      sheetContext.t(
                        'catalog.publicPage.unpublish.title',
                        fallback: 'Despublicar catálogo?',
                      ),
                      style: Theme.of(
                        sheetContext,
                      ).textTheme.titleLarge?.copyWith(
                        color: colors.titleText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sheetContext.t(
                        'catalog.publicPage.unpublish.body',
                        fallback:
                            'O link será preservado, mas os clientes não conseguirão acessar o catálogo até uma nova publicação.',
                      ),
                      style: TextStyle(color: colors.mutedText, height: 1.4),
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Text(
                              sheetContext.t(
                                'common.cancel',
                                fallback: 'Cancelar',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.error,
                              foregroundColor: SixMobilePalette.onError,
                            ),
                            onPressed:
                                () => Navigator.of(sheetContext).pop(true),
                            icon: const Icon(Icons.visibility_off_outlined),
                            label: Text(
                              sheetContext.t(
                                'catalog.publicPage.unpublish.action',
                                fallback: 'Despublicar',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  return confirmed == true;
}

class _PresentationEditorSheet extends StatefulWidget {
  const _PresentationEditorSheet({required this.current});

  final CatalogoPublicoPersonalizacaoModel current;

  @override
  State<_PresentationEditorSheet> createState() =>
      _PresentationEditorSheetState();
}

class _PresentationEditorSheetState extends State<_PresentationEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.current.titulo);
    _descriptionController = TextEditingController(
      text: widget.current.descricao,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _apply() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      widget.current.copyWith(
        titulo: _titleController.text,
        descricao: _descriptionController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return _MobileEditorSheetFrame(
      title: context.t(
        'catalog.publicPage.editor.content',
        fallback: 'Apresentação',
      ),
      subtitle: context.t(
        'catalog.publicPage.editor.contentHelp',
        fallback: 'Defina a mensagem que abre sua vitrine.',
      ),
      icon: Icons.text_fields_rounded,
      onApply: _apply,
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              key: const ValueKey<String>('catalog-virtual-mobile-title-field'),
              controller: _titleController,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: colors.titleText),
              decoration: _inputDecoration(
                context,
                label: context.t(
                  'catalog.publicPage.editor.titleLabel',
                  fallback: 'Título da vitrine',
                ),
                hint: context.t(
                  'catalog.publicPage.editor.titleHint',
                  fallback: 'Ex.: Encontre o que precisa',
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 6,
              maxLength: 240,
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: colors.titleText),
              decoration: _inputDecoration(
                context,
                label: context.t(
                  'catalog.publicPage.editor.descriptionLabel',
                  fallback: 'Descrição curta',
                ),
                hint: context.t(
                  'catalog.publicPage.editor.descriptionHint',
                  fallback: 'Explique em uma frase o que o cliente encontrará.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceEditorSheet extends StatefulWidget {
  const _AppearanceEditorSheet({required this.current});

  final CatalogoPublicoPersonalizacaoModel current;

  @override
  State<_AppearanceEditorSheet> createState() => _AppearanceEditorSheetState();
}

class _AppearanceEditorSheetState extends State<_AppearanceEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late CatalogoPublicoEstilo _style;
  late String _accentColor;
  late final TextEditingController _colorController;

  @override
  void initState() {
    super.initState();
    _style = widget.current.estilo;
    _accentColor = widget.current.corPrincipal.toUpperCase();
    _colorController = TextEditingController(text: _accentColor);
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  void _selectColor(String value) {
    setState(() {
      _accentColor = value;
      _colorController.text = value;
    });
  }

  void _apply() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(
      context,
    ).pop(widget.current.copyWith(estilo: _style, corPrincipal: _accentColor));
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return _MobileEditorSheetFrame(
      title: context.t(
        'catalog.publicPage.editor.appearance',
        fallback: 'Aparência',
      ),
      subtitle: context.t(
        'catalog.publicPage.editor.appearanceHelp',
        fallback: 'Escolha o clima visual e a cor de destaque.',
      ),
      icon: Icons.palette_outlined,
      onApply: _apply,
      initialChildSize: 0.92,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final CatalogoPublicoEstilo style
                in CatalogoPublicoEstilo.values) ...<Widget>[
              _CatalogStyleOption(
                style: style,
                selected: _style == style,
                onTap: () => setState(() => _style = style),
              ),
              if (style != CatalogoPublicoEstilo.values.last)
                const SizedBox(height: 9),
            ],
            const SizedBox(height: 22),
            Text(
              context.t(
                'catalog.publicPage.editor.accentColor',
                fallback: 'Cor de destaque',
              ),
              style: TextStyle(
                color: colors.titleText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final String color in _catalogAccentColors)
                  _CatalogColorSwatch(
                    value: color,
                    selected: _accentColor == color,
                    onTap: () => _selectColor(color),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _colorController,
              maxLength: 7,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f#]')),
              ],
              style: TextStyle(color: colors.titleText),
              decoration: _inputDecoration(
                context,
                label: context.t(
                  'catalog.publicPage.editor.customColor',
                  fallback: 'Cor personalizada',
                ),
                hint: '#126BFF',
              ).copyWith(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _tryParseColor(_accentColor) ?? colors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                  ),
                ),
              ),
              validator: (String? value) {
                if (!_hasMinimumWhiteContrast(value ?? '')) {
                  return context.t(
                    'catalog.publicPage.editor.invalidColor',
                    fallback:
                        'Use uma cor hexadecimal com bom contraste, como #126BFF.',
                  );
                }
                return null;
              },
              onChanged: (String value) {
                final String normalized = value.toUpperCase();
                if (_hasMinimumWhiteContrast(normalized)) {
                  setState(() => _accentColor = normalized);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentEditorSheet extends StatefulWidget {
  const _ContentEditorSheet({required this.current});

  final CatalogoPublicoPersonalizacaoModel current;

  @override
  State<_ContentEditorSheet> createState() => _ContentEditorSheetState();
}

class _ContentEditorSheetState extends State<_ContentEditorSheet> {
  late CatalogoPublicoDensidade _density;
  late bool _showPrices;
  late bool _showContact;
  late bool _showAddress;

  @override
  void initState() {
    super.initState();
    _density = widget.current.densidade;
    _showPrices = widget.current.exibirPrecos;
    _showContact = widget.current.exibirContato;
    _showAddress = widget.current.exibirEndereco;
  }

  void _apply() {
    Navigator.of(context).pop(
      widget.current.copyWith(
        densidade: _density,
        exibirPrecos: _showPrices,
        exibirContato: _showContact,
        exibirEndereco: _showAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MobileEditorSheetFrame(
      title: context.t(
        'catalog.publicPage.editor.layout',
        fallback: 'Conteúdo e layout',
      ),
      subtitle: context.t(
        'catalog.publicPage.editor.layoutHelp',
        fallback: 'Controle a densidade e as informações visíveis.',
      ),
      icon: Icons.view_quilt_outlined,
      onApply: _apply,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _DensityOption(
                  icon: Icons.grid_view_rounded,
                  title: context.t(
                    'catalog.publicPage.editor.comfortable',
                    fallback: 'Confortável',
                  ),
                  selected: _density == CatalogoPublicoDensidade.confortavel,
                  onTap:
                      () => setState(
                        () => _density = CatalogoPublicoDensidade.confortavel,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DensityOption(
                  icon: Icons.apps_rounded,
                  title: context.t(
                    'catalog.publicPage.editor.compact',
                    fallback: 'Compacto',
                  ),
                  selected: _density == CatalogoPublicoDensidade.compacta,
                  onTap:
                      () => setState(
                        () => _density = CatalogoPublicoDensidade.compacta,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _EditorSwitchRow(
            icon: Icons.sell_outlined,
            title: context.t(
              'catalog.publicPage.editor.showPrices',
              fallback: 'Exibir preços',
            ),
            value: _showPrices,
            onChanged: (bool value) => setState(() => _showPrices = value),
          ),
          const SizedBox(height: 10),
          _EditorSwitchRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: context.t(
              'catalog.publicPage.editor.showContact',
              fallback: 'Exibir contatos',
            ),
            value: _showContact,
            onChanged: (bool value) => setState(() => _showContact = value),
          ),
          const SizedBox(height: 10),
          _EditorSwitchRow(
            icon: Icons.location_on_outlined,
            title: context.t(
              'catalog.publicPage.editor.showAddress',
              fallback: 'Exibir endereço',
            ),
            value: _showAddress,
            onChanged: (bool value) => setState(() => _showAddress = value),
          ),
        ],
      ),
    );
  }
}

class _MobileEditorSheetFrame extends StatelessWidget {
  const _MobileEditorSheetFrame({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.onApply,
    this.initialChildSize = 0.82,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final VoidCallback onApply;
  final double initialChildSize;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(10, 0, 10, viewInsets.bottom + 10),
        child: DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: 0.58,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Material(
              key: const ValueKey<String>(
                'catalog-virtual-mobile-editor-sheet',
              ),
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  _SheetHandle(color: colors.strongBorder),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.softAccentSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border),
                          ),
                          child: Icon(icon, color: colors.accent, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: colors.titleText,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: colors.mutedText,
                                  height: 1.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.t(
                            'common.close',
                            fallback: 'Fechar',
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.border),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                      child: child,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      border: Border(top: BorderSide(color: colors.border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  context.t(
                                    'common.cancel',
                                    fallback: 'Cancelar',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.accent,
                                  foregroundColor: colors.onAccent,
                                ),
                                onPressed: onApply,
                                icon: const Icon(Icons.check_rounded),
                                label: Text(
                                  context.t(
                                    'common.apply',
                                    fallback: 'Aplicar',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CatalogStyleOption extends StatelessWidget {
  const _CatalogStyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final CatalogoPublicoEstilo style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final (String, String, IconData) data = switch (style) {
      CatalogoPublicoEstilo.classico => (
        context.t('catalog.publicPage.style.classic', fallback: 'Clássico'),
        context.t(
          'catalog.publicPage.style.classicHelp',
          fallback: 'Profissional, equilibrado e familiar.',
        ),
        Icons.business_center_outlined,
      ),
      CatalogoPublicoEstilo.minimalista => (
        context.t('catalog.publicPage.style.minimal', fallback: 'Minimalista'),
        context.t(
          'catalog.publicPage.style.minimalHelp',
          fallback: 'Mais espaço, menos elementos visuais.',
        ),
        Icons.crop_free_rounded,
      ),
      CatalogoPublicoEstilo.expressivo => (
        context.t(
          'catalog.publicPage.style.expressive',
          fallback: 'Expressivo',
        ),
        context.t(
          'catalog.publicPage.style.expressiveHelp',
          fallback: 'Cor e contraste para destacar a marca.',
        ),
        Icons.auto_awesome_outlined,
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '${data.$1}. ${data.$2}',
      child: Material(
        color: selected ? colors.softAccentSurface : colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.iconSurface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    data.$3,
                    color: selected ? colors.accent : colors.mutedText,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        data.$1,
                        style: TextStyle(
                          color: colors.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.$2,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? colors.accent : colors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogColorSwatch extends StatelessWidget {
  const _CatalogColorSwatch({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final Color color = _tryParseColor(value) ?? colors.accent;

    return Semantics(
      button: true,
      selected: selected,
      label: value,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.titleText : colors.border,
              width: selected ? 3 : 1,
            ),
            boxShadow:
                selected
                    ? <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.34),
                        blurRadius: 12,
                      ),
                    ]
                    : const <BoxShadow>[],
          ),
          child:
              selected
                  ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 21,
                  )
                  : null,
        ),
      ),
    );
  }
}

class _DensityOption extends StatelessWidget {
  const _DensityOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected ? colors.softAccentSurface : colors.softSurface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  color: selected ? colors.accent : colors.mutedText,
                  size: 25,
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorSwitchRow extends StatelessWidget {
  const _EditorSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.iconSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.accent, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.titleText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required String hint,
}) {
  final SixMobileColorScheme colors = context.sixMobileColors;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: true,
    filled: true,
    fillColor: colors.softSurface,
    labelStyle: TextStyle(color: colors.mutedText),
    hintStyle: TextStyle(color: colors.mutedText),
    counterStyle: TextStyle(color: colors.mutedText),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.error, width: 1.5),
    ),
  );
}

Color? _tryParseColor(String value) {
  final RegExpMatch? match = RegExp(
    r'^#([0-9A-Fa-f]{6})$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  return Color(int.parse('FF${match.group(1)}', radix: 16));
}

bool _hasMinimumWhiteContrast(String value) {
  final RegExpMatch? match = RegExp(
    r'^#([0-9A-Fa-f]{6})$',
  ).firstMatch(value.trim());
  if (match == null) return false;
  final int raw = int.parse(match.group(1)!, radix: 16);

  double channel(int value) {
    final double normalized = value / 255;
    return normalized <= 0.04045
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  final double luminance =
      (0.2126 * channel(raw >> 16)) +
      (0.7152 * channel((raw >> 8) & 0xFF)) +
      (0.0722 * channel(raw & 0xFF));
  return 1.05 / (luminance + 0.05) >= 3;
}
