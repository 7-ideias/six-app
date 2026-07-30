import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_response_type_metadata.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_type_picker.dart';

class OperationalProcedureItemEditorSheet extends StatefulWidget {
  const OperationalProcedureItemEditorSheet({super.key, this.item});

  final ProcedureItem? item;

  @override
  State<OperationalProcedureItemEditorSheet> createState() =>
      _OperationalProcedureItemEditorSheetState();
}

class _OperationalProcedureItemEditorSheetState
    extends State<OperationalProcedureItemEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _guidanceController;
  late final TextEditingController _placeholderController;
  late final TextEditingController _unitController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late ProcedureResponseType _responseType;
  late bool _required;
  late List<String> _options;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    final ProcedureItem? item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _guidanceController = TextEditingController(text: item?.guidance ?? '');
    _placeholderController = TextEditingController(
      text: item?.configuration.placeholder ?? '',
    );
    _unitController = TextEditingController(
      text: item?.configuration.unit ?? '',
    );
    _responseType = item?.responseType ?? ProcedureResponseType.instruction;
    _required = item?.required ?? false;
    _options = <String>[...?item?.options];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _guidanceController.dispose();
    _placeholderController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProcedureResponseTypeMetadata metadata = metadataForResponseType(
      _responseType,
    );
    return _SheetSurface(
      title:
          widget.item == null
              ? context.t('procedimentos.addItem', fallback: 'Adicionar item')
              : context.t('procedimentos.editItem', fallback: 'Editar item'),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.t(
                  'procedimentos.itemTitleField',
                  fallback: 'Título ou instrução',
                ),
              ),
              validator: (String? value) {
                if ((value ?? '').trim().isEmpty) {
                  return context.t(
                    'procedimentos.validationItemTitle',
                    fallback: 'Informe o título do item.',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _guidanceController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.t(
                  'procedimentos.itemGuidanceField',
                  fallback: 'Texto de apoio',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SelectorTile(
              label: context.t(
                'procedimentos.itemType',
                fallback: 'Tipo de item',
              ),
              value: responseTypeLabel(context, _responseType),
              icon: responseTypeIcon(_responseType),
              onTap: _selectResponseType,
            ),
            AnimatedSwitcher(
              duration:
                  MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
              child: _TypeSpecificFields(
                key: ValueKey<ProcedureResponseType>(_responseType),
                metadata: metadata,
                placeholderController: _placeholderController,
                unitController: _unitController,
                options: _options,
                optionsError: _optionsError,
                onOptionsChanged: (List<String> options) {
                  setState(() {
                    _options = options;
                    _optionsError = null;
                  });
                },
              ),
            ),
            SwitchListTile.adaptive(
              value: _required,
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.t('common.required', fallback: 'Obrigatório'),
              ),
              subtitle: Text(
                context.t(
                  'procedimentos.itemRequiredHelp',
                  fallback:
                      'A lógica final da obrigatoriedade será definida na integração operacional.',
                ),
              ),
              onChanged:
                  metadata.allowsRequired
                      ? (bool value) => setState(() => _required = value)
                      : null,
            ),
            const SizedBox(height: 16),
            _SheetActions(
              saveLabel: context.t(
                'procedimentos.saveItem',
                fallback: 'Salvar item',
              ),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectResponseType() async {
    final ProcedureResponseType? selected =
        await OperationalProcedureTypePicker.show(
          context,
          selected: _responseType,
        );
    if (selected == null || selected == _responseType) return;
    if (isChoiceResponseType(_responseType) &&
        !isChoiceResponseType(selected) &&
        _options.any((String option) => option.trim().isNotEmpty)) {
      final bool discard = await _confirmTypeChange();
      if (!discard || !mounted) return;
    }
    setState(() {
      _responseType = selected;
      _optionsError = null;
      if (!isChoiceResponseType(selected)) {
        _options = <String>[];
      }
      if (!metadataForResponseType(selected).acceptsPlaceholder) {
        _placeholderController.clear();
      }
      if (!metadataForResponseType(selected).acceptsUnit) {
        _unitController.clear();
      }
    });
  }

  Future<bool> _confirmTypeChange() async {
    return await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder:
              (_) => _ConfirmSheet(
                title: context.t(
                  'procedimentos.changeTypeTitle',
                  fallback: 'Trocar tipo de item?',
                ),
                message: context.t(
                  'procedimentos.changeTypeMessage',
                  fallback:
                      'As opções configuradas serão removidas para este tipo.',
                ),
              ),
        ) ??
        false;
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final bool validForm = _formKey.currentState?.validate() ?? false;
    final List<String> normalizedOptions = _options
        .map((String option) => option.trim())
        .where((String option) => option.isNotEmpty)
        .toList(growable: false);
    if (isChoiceResponseType(_responseType) && normalizedOptions.length < 2) {
      setState(() {
        _optionsError = context.t(
          'procedimentos.validationChoiceOptions',
          fallback: 'Informe pelo menos duas opções.',
        );
      });
    }
    if (!validForm || _optionsError != null) return;

    Navigator.of(context).pop(
      ProcedureItem(
        id: widget.item?.id ?? '',
        title: _titleController.text.trim(),
        guidance: _guidanceController.text.trim(),
        responseType: _responseType,
        required: _required,
        order: widget.item?.order ?? 0,
        options: normalizedOptions,
        configuration: ProcedureItemConfiguration(
          placeholder: _placeholderController.text.trim(),
          unit: _unitController.text.trim(),
        ),
      ),
    );
  }
}

class _TypeSpecificFields extends StatelessWidget {
  const _TypeSpecificFields({
    super.key,
    required this.metadata,
    required this.placeholderController,
    required this.unitController,
    required this.options,
    required this.optionsError,
    required this.onOptionsChanged,
  });

  final ProcedureResponseTypeMetadata metadata;
  final TextEditingController placeholderController;
  final TextEditingController unitController;
  final List<String> options;
  final String? optionsError;
  final ValueChanged<List<String>> onOptionsChanged;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    if (metadata.acceptsPlaceholder) {
      children.addAll(<Widget>[
        const SizedBox(height: 12),
        TextFormField(
          controller: placeholderController,
          decoration: InputDecoration(
            labelText: context.t(
              'procedimentos.placeholderField',
              fallback: 'Placeholder',
            ),
          ),
        ),
      ]);
    }
    if (metadata.acceptsUnit) {
      children.addAll(<Widget>[
        const SizedBox(height: 12),
        TextFormField(
          controller: unitController,
          decoration: InputDecoration(
            labelText: context.t(
              'procedimentos.unitField',
              fallback: 'Unidade',
            ),
          ),
        ),
      ]);
    }
    if (metadata.acceptsOptions) {
      children.addAll(<Widget>[
        const SizedBox(height: 12),
        _ChoiceOptionsEditor(
          options: options,
          errorText: optionsError,
          onChanged: onOptionsChanged,
        ),
      ]);
    }
    if (metadata.simulated) {
      children.addAll(<Widget>[
        const SizedBox(height: 12),
        _SimulationNotice(
          text: context.t(
            'procedimentos.simulatedTypeEditorHelp',
            fallback:
                'No modo demonstração, esta captura será simulada sem usar recursos do dispositivo.',
          ),
        ),
      ]);
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(children: children);
  }
}

class _ChoiceOptionsEditor extends StatefulWidget {
  const _ChoiceOptionsEditor({
    required this.options,
    required this.errorText,
    required this.onChanged,
  });

  final List<String> options;
  final String? errorText;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_ChoiceOptionsEditor> createState() => _ChoiceOptionsEditorState();
}

class _ChoiceOptionsEditorState extends State<_ChoiceOptionsEditor> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _buildControllers(widget.options);
    if (_controllers.length < 2) {
      _controllers.addAll(
        <TextEditingController>[
          TextEditingController(),
          TextEditingController(),
        ].take(2 - _controllers.length),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _ChoiceOptionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options &&
        widget.options.length != _controllers.length) {
      for (final TextEditingController controller in _controllers) {
        controller.dispose();
      }
      _controllers = _buildControllers(widget.options);
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> _buildControllers(List<String> options) {
    return options
        .map((String option) => TextEditingController(text: option))
        .toList();
  }

  void _emit() {
    widget.onChanged(
      _controllers
          .map((TextEditingController controller) => controller.text)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.t(
        'procedimentos.choiceOptions',
        fallback: 'Opções de escolha',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t(
                    'procedimentos.choiceOptions',
                    fallback: 'Opções de escolha',
                  ),
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _controllers.add(TextEditingController()));
                  _emit();
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  context.t(
                    'procedimentos.addOption',
                    fallback: 'Adicionar opção',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._controllers.asMap().entries.map((
            MapEntry<int, TextEditingController> entry,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: OperationalProcedureI18n.optionNumber(
                          context,
                          entry.key + 1,
                        ),
                      ),
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  IconButton(
                    tooltip: context.t(
                      'procedimentos.removeOption',
                      fallback: 'Remover opção',
                    ),
                    onPressed:
                        _controllers.length <= 2
                            ? null
                            : () {
                              setState(() {
                                final TextEditingController removed =
                                    _controllers.removeAt(entry.key);
                                removed.dispose();
                              });
                              _emit();
                            },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                ],
              ),
            );
          }),
          if (widget.errorText != null)
            Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText!,
                style: const TextStyle(
                  color: SixMobilePalette.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: text,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SixMobilePalette.softAccentSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SixMobilePalette.highlightedBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.science_outlined,
              color: SixMobilePalette.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: SixMobilePalette.titleText,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: SixMobilePalette.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: SixMobilePalette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: SixMobilePalette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({required this.saveLabel, required this.onSave});

  final String saveLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('common.cancel', fallback: 'Cancelar')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(onPressed: onSave, child: Text(saveLabel)),
        ),
      ],
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(context.t('common.cancel', fallback: 'Cancelar')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    context.t('common.continue', fallback: 'Continuar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
