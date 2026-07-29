import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_card.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_demo_badge.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_state_views.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/providers/operational_procedure_provider.dart';

class OperationalProcedureEditorMobileScreen extends StatefulWidget {
  const OperationalProcedureEditorMobileScreen({
    super.key,
    required this.initialProcedure,
    required this.isCreating,
  });

  final OperationalProcedure initialProcedure;
  final bool isCreating;

  @override
  State<OperationalProcedureEditorMobileScreen> createState() =>
      _OperationalProcedureEditorMobileScreenState();
}

class _OperationalProcedureEditorMobileScreenState
    extends State<OperationalProcedureEditorMobileScreen> {
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;

  late OperationalProcedure _draft;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _dirty = false;
  String? _structureError;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialProcedure;
    _nameController = TextEditingController(text: _draft.name);
    _descriptionController = TextEditingController(text: _draft.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop || !_dirty) return;
        if (await _confirmDiscard()) {
          if (context.mounted) Navigator.of(context).pop(false);
        }
      },
      child: SixMobilePageShell(
        title:
            widget.isCreating
                ? context.t(
                  'procedimentos.editorNewTitle',
                  fallback: 'Novo procedimento',
                )
                : context.t(
                  'procedimentos.editorEditTitle',
                  fallback: 'Editar procedimento',
                ),
        backgroundColor: _backgroundColor,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        accentColor: _accentColor,
        enableAnimatedBackground: !reduceMotion,
        actions: <Widget>[
          TextButton(
            onPressed: _save,
            child: Text(
              context.t('common.save', fallback: 'Salvar'),
              style: const TextStyle(
                color: SixMobilePalette.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
                children: <Widget>[
                  _DemoNotice(),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: context.t(
                      'procedimentos.generalInfo',
                      fallback: 'Informações gerais',
                    ),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.t(
                              'procedimentos.nameField',
                              fallback: 'Nome',
                            ),
                          ),
                          validator: (String? value) {
                            if ((value ?? '').trim().isEmpty) {
                              return context.t(
                                'procedimentos.validationName',
                                fallback: 'Informe o nome do procedimento.',
                              );
                            }
                            return null;
                          },
                          onChanged: (String value) {
                            _updateDraft(_draft.copyWith(name: value.trim()));
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: context.t(
                              'procedimentos.descriptionField',
                              fallback: 'Descrição',
                            ),
                          ),
                          onChanged: (String value) {
                            _updateDraft(
                              _draft.copyWith(description: value.trim()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _SelectorTile(
                          label: context.t(
                            'procedimentos.operationContext',
                            fallback: 'Contexto operacional',
                          ),
                          value: operationTypeLabel(
                            context,
                            _draft.operationType,
                          ),
                          icon: Icons.storefront_outlined,
                          onTap: _selectOperationType,
                        ),
                        const SizedBox(height: 10),
                        _SelectorTile(
                          label: context.t(
                            'procedimentos.momentField',
                            fallback: 'Momento',
                          ),
                          value: momentLabel(context, _draft.moment),
                          icon: Icons.schedule_outlined,
                          onTap: _selectMoment,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          value: _draft.isActive,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.t('common.active', fallback: 'Ativo'),
                          ),
                          onChanged: (bool value) {
                            _updateDraft(
                              context
                                  .read<OperationalProcedureProvider>()
                                  .setProcedureActive(_draft, value),
                            );
                          },
                        ),
                        SwitchListTile.adaptive(
                          value: _draft.required,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.t(
                              'procedimentos.requireCompletion',
                              fallback: 'Exigir conclusão deste procedimento',
                            ),
                          ),
                          subtitle: Text(
                            context.t(
                              'procedimentos.requireCompletionHelp',
                              fallback:
                                  'Na integração futura, esse procedimento poderá exigir conclusão antes de continuar a operação.',
                            ),
                          ),
                          onChanged: (bool value) {
                            _updateDraft(_draft.copyWith(required: value));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: context.t(
                      'procedimentos.stages',
                      fallback: 'Etapas',
                    ),
                    trailing: TextButton.icon(
                      onPressed: _addStage,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        context.t(
                          'procedimentos.addStage',
                          fallback: 'Adicionar etapa',
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_structureError != null) ...<Widget>[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _structureError!,
                              style: const TextStyle(
                                color: SixMobilePalette.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        AnimatedSwitcher(
                          duration:
                              reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                          child:
                              _draft.stages.isEmpty
                                  ? _EmptyInline(
                                    message: context.t(
                                      'procedimentos.noStages',
                                      fallback:
                                          'Adicione pelo menos uma etapa.',
                                    ),
                                  )
                                  : Column(
                                    key: ValueKey<int>(_draft.stages.length),
                                    children:
                                        _draft.stages.map(_buildStage).toList(),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OperationalProcedureNewAction(
                    onTap: _save,
                    label: context.t('common.save', fallback: 'Salvar'),
                    icon: Icons.check_rounded,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStage(ProcedureStage stage) {
    final int itemCount = stage.items.length;
    return Semantics(
      container: true,
      label:
          'Etapa ${stage.order}: ${stage.title}. $itemCount ${context.t('procedimentos.itemPlural', fallback: 'itens')}.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: true,
            title: Text(
              '${stage.order}. ${stage.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              itemCount == 1
                  ? '1 ${context.t('procedimentos.itemSingular', fallback: 'item')}'
                  : '$itemCount ${context.t('procedimentos.itemPlural', fallback: 'itens')}',
              style: const TextStyle(color: SixMobilePalette.mutedText),
            ),
            trailing: Wrap(
              spacing: 2,
              children: <Widget>[
                IconButton(
                  tooltip: context.t(
                    'procedimentos.editStage',
                    fallback: 'Editar etapa',
                  ),
                  onPressed: () => _editStage(stage),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: context.t(
                    'procedimentos.deleteStage',
                    fallback: 'Excluir etapa',
                  ),
                  onPressed: () => _deleteStage(stage),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            children: <Widget>[
              if (stage.description.trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stage.description,
                    style: const TextStyle(
                      color: SixMobilePalette.mutedText,
                      height: 1.3,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ...stage.items.map((ProcedureItem item) {
                return _ItemRow(
                  item: item,
                  onEdit: () => _editItem(stage, item),
                  onDelete: () => _deleteItem(stage, item),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addItem(stage),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    context.t(
                      'procedimentos.addItem',
                      fallback: 'Adicionar item',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateDraft(OperationalProcedure next) {
    setState(() {
      _draft = next;
      _dirty = true;
      _structureError = null;
    });
  }

  Future<void> _selectOperationType() async {
    final ProcedureOperationType? selected =
        await _showOptionSheet<ProcedureOperationType>(
          title: context.t(
            'procedimentos.operationContext',
            fallback: 'Contexto operacional',
          ),
          options: ProcedureOperationType.values,
          selected: _draft.operationType,
          labelBuilder:
              (ProcedureOperationType value) =>
                  operationTypeLabel(context, value),
          iconBuilder: (_) => Icons.storefront_outlined,
        );
    if (selected != null) {
      _updateDraft(_draft.copyWith(operationType: selected));
    }
  }

  Future<void> _selectMoment() async {
    final ProcedureMoment? selected = await _showOptionSheet<ProcedureMoment>(
      title: context.t('procedimentos.momentField', fallback: 'Momento'),
      options: ProcedureMoment.values,
      selected: _draft.moment,
      labelBuilder: (ProcedureMoment value) => momentLabel(context, value),
      iconBuilder: (_) => Icons.schedule_outlined,
    );
    if (selected != null) {
      _updateDraft(_draft.copyWith(moment: selected));
    }
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T value) labelBuilder,
    required IconData Function(T value) iconBuilder,
    String Function(T value)? descriptionBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _OptionSheet<T>(
          title: title,
          options: options,
          selected: selected,
          labelBuilder: labelBuilder,
          iconBuilder: iconBuilder,
          descriptionBuilder: descriptionBuilder,
        );
      },
    );
  }

  Future<void> _addStage() async {
    final ProcedureStage? stage = await _showStageSheet();
    if (stage == null) return;
    if (!mounted) return;
    _updateDraft(
      context.read<OperationalProcedureProvider>().addStage(_draft, stage),
    );
  }

  Future<void> _editStage(ProcedureStage stage) async {
    final ProcedureStage? edited = await _showStageSheet(stage: stage);
    if (edited == null) return;
    if (!mounted) return;
    _updateDraft(
      context.read<OperationalProcedureProvider>().updateStage(_draft, edited),
    );
  }

  Future<ProcedureStage?> _showStageSheet({ProcedureStage? stage}) {
    return showModalBottomSheet<ProcedureStage>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StageEditorSheet(stage: stage),
    );
  }

  Future<void> _deleteStage(ProcedureStage stage) async {
    final bool confirmed = await _confirm(
      title: context.t(
        'procedimentos.confirmDeleteStageTitle',
        fallback: 'Excluir etapa?',
      ),
      message: context.t(
        'procedimentos.confirmDeleteStageMessage',
        fallback: 'Os itens desta etapa também serão removidos.',
      ),
    );
    if (!confirmed) return;
    if (!mounted) return;
    _updateDraft(
      context.read<OperationalProcedureProvider>().removeStage(
        _draft,
        stage.id,
      ),
    );
  }

  Future<void> _addItem(ProcedureStage stage) async {
    final ProcedureItem? item = await _showItemSheet();
    if (item == null) return;
    if (!mounted) return;
    final ProcedureStage updated = context
        .read<OperationalProcedureProvider>()
        .addItem(stage, item);
    _updateDraft(
      context.read<OperationalProcedureProvider>().updateStage(_draft, updated),
    );
  }

  Future<void> _editItem(ProcedureStage stage, ProcedureItem item) async {
    final ProcedureItem? edited = await _showItemSheet(item: item);
    if (edited == null) return;
    if (!mounted) return;
    final ProcedureStage updated = context
        .read<OperationalProcedureProvider>()
        .updateItem(stage, edited);
    _updateDraft(
      context.read<OperationalProcedureProvider>().updateStage(_draft, updated),
    );
  }

  Future<ProcedureItem?> _showItemSheet({ProcedureItem? item}) {
    return showModalBottomSheet<ProcedureItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemEditorSheet(item: item),
    );
  }

  Future<void> _deleteItem(ProcedureStage stage, ProcedureItem item) async {
    final bool confirmed = await _confirm(
      title: context.t(
        'procedimentos.confirmDeleteItemTitle',
        fallback: 'Excluir item?',
      ),
      message: context.t(
        'procedimentos.confirmDeleteItemMessage',
        fallback: 'Este item será removido da etapa.',
      ),
    );
    if (!confirmed) return;
    if (!mounted) return;
    final ProcedureStage updated = context
        .read<OperationalProcedureProvider>()
        .removeItem(stage, item.id);
    _updateDraft(
      context.read<OperationalProcedureProvider>().updateStage(_draft, updated),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ConfirmSheet(title: title, message: message),
        ) ??
        false;
  }

  Future<bool> _confirmDiscard() {
    return _confirm(
      title: context.t(
        'procedimentos.discardChangesTitle',
        fallback: 'Descartar alterações?',
      ),
      message: context.t(
        'procedimentos.discardChangesMessage',
        fallback:
            'As alterações feitas neste procedimento ainda não foram salvas.',
      ),
    );
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final bool validForm = _formKey.currentState?.validate() ?? false;
    final String? structureError = _validateStructure();
    if (!validForm || structureError != null) {
      setState(() => _structureError = structureError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            structureError ??
                context.t(
                  'procedimentos.validationReviewFields',
                  fallback: 'Revise os campos obrigatórios.',
                ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<OperationalProcedureProvider>().saveProcedure(
      _draft.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
    _dirty = false;
    Navigator.of(context).pop(true);
  }

  String? _validateStructure() {
    if (_draft.stages.isEmpty) {
      return context.t(
        'procedimentos.validationAtLeastOneStage',
        fallback: 'Adicione pelo menos uma etapa.',
      );
    }
    for (final ProcedureStage stage in _draft.stages) {
      if (stage.title.trim().isEmpty) {
        return context.t(
          'procedimentos.validationStageTitle',
          fallback: 'Informe o título da etapa.',
        );
      }
      if (stage.items.isEmpty) {
        return context.t(
          'procedimentos.validationStageItem',
          fallback: 'Cada etapa precisa ter pelo menos um item.',
        );
      }
      for (final ProcedureItem item in stage.items) {
        if (item.title.trim().isEmpty) {
          return context.t(
            'procedimentos.validationItemTitle',
            fallback: 'Informe o título do item.',
          );
        }
      }
    }
    return null;
  }
}

class _DemoNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OperationalProcedureDemoBadge(
          label: context.t(
            'procedimentos.demoData',
            fallback: 'Dados demonstrativos',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.t(
              'procedimentos.editorDemoNotice',
              fallback:
                  'As alterações serão mantidas apenas durante esta sessão.',
            ),
            style: const TextStyle(
              color: SixMobilePalette.heroSupportingText,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SixMobilePalette.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: SixMobilePalette.titleText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailing != null) Flexible(child: trailing!),
              ],
            ),
            const SizedBox(height: 12),
            child,
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

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.iconBuilder,
    this.descriptionBuilder,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T value) labelBuilder;
  final IconData Function(T value) iconBuilder;
  final String Function(T value)? descriptionBuilder;

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            options.map((T value) {
              final bool isSelected = value == selected;
              final String label = labelBuilder(value);
              return ListTile(
                leading: Icon(iconBuilder(value)),
                title: Text(label),
                subtitle:
                    descriptionBuilder == null
                        ? null
                        : Text(descriptionBuilder!(value)),
                trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                selected: isSelected,
                onTap: () => Navigator.of(context).pop(value),
              );
            }).toList(),
      ),
    );
  }
}

class _StageEditorSheet extends StatefulWidget {
  const _StageEditorSheet({this.stage});

  final ProcedureStage? stage;

  @override
  State<_StageEditorSheet> createState() => _StageEditorSheetState();
}

class _StageEditorSheetState extends State<_StageEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.stage?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.stage?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      title:
          widget.stage == null
              ? context.t('procedimentos.addStage', fallback: 'Adicionar etapa')
              : context.t('procedimentos.editStage', fallback: 'Editar etapa'),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.t(
                  'procedimentos.stageTitleField',
                  fallback: 'Título da etapa',
                ),
              ),
              validator: (String? value) {
                if ((value ?? '').trim().isEmpty) {
                  return context.t(
                    'procedimentos.validationStageTitle',
                    fallback: 'Informe o título da etapa.',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.t(
                  'procedimentos.descriptionField',
                  fallback: 'Descrição',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SheetActions(
              saveLabel: context.t(
                'procedimentos.saveStage',
                fallback: 'Salvar etapa',
              ),
              onSave: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop(
                  ProcedureStage(
                    id: widget.stage?.id ?? '',
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    order: widget.stage?.order ?? 0,
                    items: widget.stage?.items ?? const <ProcedureItem>[],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditorSheet extends StatefulWidget {
  const _ItemEditorSheet({this.item});

  final ProcedureItem? item;

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _guidanceController;
  late ProcedureResponseType _responseType;
  late bool _required;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _guidanceController = TextEditingController(
      text: widget.item?.guidance ?? '',
    );
    _responseType =
        widget.item?.responseType ?? ProcedureResponseType.instruction;
    _required = widget.item?.required ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _guidanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (bool value) => setState(() => _required = value),
            ),
            const SizedBox(height: 16),
            _SheetActions(
              saveLabel: context.t(
                'procedimentos.saveItem',
                fallback: 'Salvar item',
              ),
              onSave: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop(
                  ProcedureItem(
                    id: widget.item?.id ?? '',
                    title: _titleController.text.trim(),
                    guidance: _guidanceController.text.trim(),
                    responseType: _responseType,
                    required: _required,
                    order: widget.item?.order ?? 0,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectResponseType() async {
    final ProcedureResponseType? selected =
        await showModalBottomSheet<ProcedureResponseType>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return _OptionSheet<ProcedureResponseType>(
              title: context.t(
                'procedimentos.itemType',
                fallback: 'Tipo de item',
              ),
              options: ProcedureResponseType.values,
              selected: _responseType,
              labelBuilder:
                  (ProcedureResponseType value) =>
                      responseTypeLabel(context, value),
              iconBuilder: responseTypeIcon,
              descriptionBuilder:
                  (ProcedureResponseType value) =>
                      responseTypeDescription(context, value),
            );
          },
        );
    if (selected != null) setState(() => _responseType = selected);
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ProcedureItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String type = responseTypeLabel(context, item.responseType);
    final String requiredLabel = requiredStateLabel(context, item.required);
    return Semantics(
      container: true,
      label: 'Item: ${item.title}. Tipo $type. $requiredLabel.',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              responseTypeIcon(item.responseType),
              color: SixMobilePalette.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$type • $requiredLabel',
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
            IconButton(
              tooltip: context.t(
                'procedimentos.editItem',
                fallback: 'Editar item',
              ),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: context.t(
                'procedimentos.deleteItem',
                fallback: 'Excluir item',
              ),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: SixMobilePalette.mutedText,
        fontWeight: FontWeight.w700,
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
                  child: Text(
                    context.t(
                      'procedimentos.keepEditing',
                      fallback: 'Continuar editando',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    context.t('procedimentos.discard', fallback: 'Descartar'),
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

String responseTypeLabel(BuildContext context, ProcedureResponseType type) {
  return switch (type) {
    ProcedureResponseType.instruction => context.t(
      'procedimentos.responseInstruction',
      fallback: 'Orientação',
    ),
    ProcedureResponseType.confirmation => context.t(
      'procedimentos.responseConfirmation',
      fallback: 'Confirmação',
    ),
    ProcedureResponseType.yesNo => context.t(
      'procedimentos.responseYesNo',
      fallback: 'Sim ou não',
    ),
  };
}

String responseTypeDescription(
  BuildContext context,
  ProcedureResponseType type,
) {
  return switch (type) {
    ProcedureResponseType.instruction => context.t(
      'procedimentos.responseInstructionDescription',
      fallback: 'Apresenta uma instrução ao colaborador.',
    ),
    ProcedureResponseType.confirmation => context.t(
      'procedimentos.responseConfirmationDescription',
      fallback: 'Exige que o colaborador confirme uma ação.',
    ),
    ProcedureResponseType.yesNo => context.t(
      'procedimentos.responseYesNoDescription',
      fallback: 'Apresenta uma pergunta objetiva.',
    ),
  };
}

IconData responseTypeIcon(ProcedureResponseType type) {
  return switch (type) {
    ProcedureResponseType.instruction => Icons.info_outline_rounded,
    ProcedureResponseType.confirmation => Icons.task_alt_rounded,
    ProcedureResponseType.yesNo => Icons.help_outline_rounded,
  };
}
