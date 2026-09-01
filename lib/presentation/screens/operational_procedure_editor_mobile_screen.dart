import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_item_editor.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_card.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_demo_badge.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_response_type_metadata.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_state_views.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_card.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_editor.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_metadata.dart'
    as trigger_meta;
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/screens/operational_procedure_preview_mobile_screen.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/operational_procedure_provider.dart';

InputDecoration _operationalProcedureFieldDecoration(
  BuildContext context, {
  required String labelText,
}) {
  final SixMobileColorScheme colors = context.sixMobileColors;
  final OutlineInputBorder enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: colors.border),
  );

  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: colors.softSurface,
    labelStyle: TextStyle(color: colors.mutedText, fontWeight: FontWeight.w700),
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: enabledBorder,
    enabledBorder: enabledBorder,
    disabledBorder: enabledBorder,
    focusedBorder: enabledBorder.copyWith(
      borderSide: BorderSide(color: colors.accent, width: 1.4),
    ),
    errorBorder: enabledBorder.copyWith(
      borderSide: BorderSide(color: colors.errorBorder),
    ),
    focusedErrorBorder: enabledBorder.copyWith(
      borderSide: BorderSide(color: colors.error, width: 1.4),
    ),
  );
}

ThemeData _operationalProcedureEditorTheme(BuildContext context) {
  final ThemeData baseTheme = Theme.of(context);
  final SixMobileColorScheme colors = context.sixMobileColors;

  return baseTheme.copyWith(
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return colors.onAccent;
        }
        return colors.titleText;
      }),
      trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return colors.accent.withValues(alpha: 0.48);
        }
        return colors.softSurface;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return colors.accent;
        }
        return colors.strongBorder;
      }),
      trackOutlineWidth: const WidgetStatePropertyAll<double>(1.2),
      overlayColor: WidgetStatePropertyAll<Color>(
        colors.accent.withValues(alpha: 0.12),
      ),
    ),
    dividerColor: colors.border,
  );
}

ButtonStyle _mobileSheetSecondaryButtonStyle(BuildContext context) {
  final SixMobileColorScheme colors = context.sixMobileColors;

  return OutlinedButton.styleFrom(
    backgroundColor: colors.softAccentSurface,
    foregroundColor: colors.accent,
    disabledBackgroundColor: colors.softSurface.withValues(alpha: 0.72),
    disabledForegroundColor: colors.mutedText,
    side: BorderSide(color: colors.accent.withValues(alpha: 0.28)),
    minimumSize: const Size(0, 46),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

ButtonStyle _mobileSheetPrimaryButtonStyle(BuildContext context) {
  final SixMobileColorScheme colors = context.sixMobileColors;

  return FilledButton.styleFrom(
    backgroundColor: colors.accent,
    foregroundColor: colors.onAccent,
    disabledBackgroundColor: colors.softSurface,
    disabledForegroundColor: colors.mutedText,
    elevation: 0,
    minimumSize: const Size(0, 46),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

ButtonStyle _mobileSheetDestructiveButtonStyle(BuildContext context) {
  final SixMobileColorScheme colors = context.sixMobileColors;

  return OutlinedButton.styleFrom(
    backgroundColor: colors.softSurface,
    foregroundColor: colors.error,
    disabledBackgroundColor: colors.softSurface.withValues(alpha: 0.72),
    disabledForegroundColor: colors.mutedText,
    side: BorderSide(color: colors.error.withValues(alpha: 0.28)),
    minimumSize: const Size(0, 46),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

ButtonStyle _mobileInlineTonalButtonStyle(BuildContext context) {
  final SixMobileColorScheme colors = context.sixMobileColors;

  return OutlinedButton.styleFrom(
    foregroundColor: colors.accent,
    backgroundColor: colors.softAccentSurface,
    disabledForegroundColor: colors.mutedText,
    disabledBackgroundColor: colors.softSurface.withValues(alpha: 0.72),
    side: BorderSide(color: colors.accent.withValues(alpha: 0.26)),
    minimumSize: const Size(0, 38),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

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
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;

  late OperationalProcedure _draft;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _dirty = false;
  bool _saving = false;
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool canManageProcedures = _canManageProcedures(context);
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
          IconButton(
            tooltip: context.t(
              'procedimentos.previewAction',
              fallback: 'Pré-visualizar',
            ),
            onPressed: _openPreview,
            icon: Icon(Icons.play_circle_outline_rounded),
          ),
          TextButton(
            onPressed: canManageProcedures && !_saving ? _save : null,
            child: Text(
              context.t('common.save', fallback: 'Salvar'),
              style: TextStyle(
                color: colors.onPrimary,
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
            child: Theme(
              data: _operationalProcedureEditorTheme(context),
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
                  children: <Widget>[
                    _DemoNotice(),
                    if (!canManageProcedures) ...<Widget>[
                      SizedBox(height: 12),
                      _EditorPermissionNotice(),
                    ],
                    SizedBox(height: 14),
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
                            cursorColor: colors.accent,
                            style: TextStyle(
                              color: colors.titleText,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: _operationalProcedureFieldDecoration(
                              context,
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
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 2,
                            maxLines: 4,
                            cursorColor: colors.accent,
                            style: TextStyle(
                              color: colors.titleText,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: _operationalProcedureFieldDecoration(
                              context,
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
                          SizedBox(height: 12),
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
                          SizedBox(height: 10),
                          _SelectorTile(
                            label: context.t(
                              'procedimentos.momentField',
                              fallback: 'Momento',
                            ),
                            value: momentLabel(context, _draft.moment),
                            icon: Icons.schedule_outlined,
                            onTap: _selectMoment,
                          ),
                          SizedBox(height: 8),
                          _buildSwitchTile(
                            title: context.t(
                              'common.active',
                              fallback: 'Ativo',
                            ),
                            value: _draft.isActive,
                            onChanged: (bool value) {
                              _updateDraft(
                                context
                                    .read<OperationalProcedureProvider>()
                                    .setProcedureActive(_draft, value),
                              );
                            },
                          ),
                          _buildSwitchTile(
                            title: context.t(
                              'procedimentos.requireCompletion',
                              fallback: 'Exigir conclusão deste procedimento',
                            ),
                            subtitle: context.t(
                              'procedimentos.requireCompletionHelp',
                              fallback:
                                  'Na integração futura, esse procedimento poderá exigir conclusão antes de continuar a operação.',
                            ),
                            value: _draft.required,
                            onChanged: (bool value) {
                              _updateDraft(_draft.copyWith(required: value));
                            },
                          ),
                          const Divider(height: 24),
                          _buildSwitchTile(
                            title: context.t(
                              'procedimentos.notifyAdmin',
                              fallback: 'Notificar ADMIN por push',
                            ),
                            subtitle: context.t(
                              'procedimentos.notifyAdminHelp',
                              fallback:
                                  'Avisa os administradores ativos quando a condição ocorrer.',
                            ),
                            value: _draft.adminNotification.enabled,
                            onChanged: (bool value) {
                              _updateDraft(
                                _draft.copyWith(
                                  adminNotification: _draft.adminNotification
                                      .copyWith(enabled: value),
                                ),
                              );
                            },
                          ),
                          if (_draft.adminNotification.enabled)
                            _SelectorTile(
                              label: context.t(
                                'procedimentos.notificationCondition',
                                fallback: 'Quando notificar',
                              ),
                              value: _notificationConditionLabel(
                                _draft.adminNotification.condition,
                              ),
                              icon: Icons.notifications_active_outlined,
                              onTap: _selectNotificationCondition,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14),
                    _SectionCard(
                      title: context.t(
                        'procedimentos.whenExecute',
                        fallback: 'Quando executar',
                      ),
                      trailing: OutlinedButton.icon(
                        onPressed: _addTrigger,
                        style: _mobileInlineTonalButtonStyle(context),
                        icon: Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          context.t(
                            'procedimentos.addTrigger',
                            fallback: 'Adicionar gatilho',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      child: _buildTriggersSection(reduceMotion),
                    ),
                    SizedBox(height: 14),
                    _SectionCard(
                      title: context.t(
                        'procedimentos.stages',
                        fallback: 'Etapas',
                      ),
                      trailing: OutlinedButton.icon(
                        onPressed: _addStage,
                        style: _mobileInlineTonalButtonStyle(context),
                        icon: Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          context.t(
                            'procedimentos.addStage',
                            fallback: 'Adicionar etapa',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                                style: TextStyle(
                                  color: colors.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                          AnimatedSwitcher(
                            duration:
                                reduceMotion
                                    ? Duration.zero
                                    : Duration(milliseconds: 180),
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
                                          _draft.stages
                                              .map(_buildStage)
                                              .toList(),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14),
                    if (canManageProcedures) ...<Widget>[
                      OperationalProcedureNewAction(
                        onTap: _save,
                        label: context.t('common.save', fallback: 'Salvar'),
                        icon: Icons.check_rounded,
                      ),
                      SizedBox(height: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: _openPreview,
                      icon: Icon(Icons.play_circle_outline_rounded),
                      label: Text(
                        context.t(
                          'procedimentos.previewAction',
                          fallback: 'Pré-visualizar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return SwitchListTile.adaptive(
      value: value,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: colors.titleText, fontWeight: FontWeight.w800),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle,
                style: TextStyle(
                  color: colors.mutedText,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
      onChanged: onChanged,
    );
  }

  Widget _buildStage(ProcedureStage stage) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final int itemCount = stage.items.length;
    return Semantics(
      container: true,
      label: OperationalProcedureI18n.stageSemantics(
        context,
        order: stage.order,
        title: stage.title,
        itemCount: itemCount,
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
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
              style: TextStyle(
                color: colors.titleText,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              OperationalProcedureI18n.itemCount(context, itemCount),
              style: TextStyle(color: colors.mutedText),
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
                  icon: Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: context.t(
                    'procedimentos.deleteStage',
                    fallback: 'Excluir etapa',
                  ),
                  onPressed: () => _deleteStage(stage),
                  icon: Icon(Icons.delete_outline),
                ),
              ],
            ),
            children: <Widget>[
              if (stage.description.trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stage.description,
                    style: TextStyle(color: colors.mutedText, height: 1.3),
                  ),
                ),
              SizedBox(height: 8),
              ...stage.items.map((ProcedureItem item) {
                return _ItemRow(
                  item: item,
                  onEdit: () => _editItem(stage, item),
                  onDelete: () => _deleteItem(stage, item),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _addItem(stage),
                  style: _mobileInlineTonalButtonStyle(context),
                  icon: Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    context.t(
                      'procedimentos.addItem',
                      fallback: 'Adicionar item',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriggersSection(bool reduceMotion) {
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : Duration(milliseconds: 180),
      child:
          _draft.triggers.isEmpty
              ? _EmptyInline(
                key: ValueKey<String>('triggers-empty'),
                message: context.t(
                  'procedimentos.noTriggers',
                  fallback: 'Nenhum gatilho configurado.',
                ),
                description: context.t(
                  'procedimentos.noTriggersDescription',
                  fallback:
                      'Sem gatilhos, o procedimento ficará disponível apenas para uso e pré-visualização dentro deste módulo.',
                ),
              )
              : Column(
                key: ValueKey<int>(_draft.triggers.length),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.t(
                      'procedimentos.triggerCount',
                      fallback:
                          '${_draft.triggers.length} gatilho(s) configurado(s)',
                    ),
                    style: TextStyle(
                      color: context.sixMobileColors.mutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  ..._draft.triggers.map((ProcedureTrigger trigger) {
                    return OperationalProcedureTriggerCard(
                      trigger: trigger,
                      onTap: () => _editTrigger(trigger),
                      onEdit: () => _editTrigger(trigger),
                      onDelete: () => _deleteTrigger(trigger),
                      onEnabledChanged: (bool enabled) {
                        _updateDraft(
                          _syncProcedureMomentFromTriggers(
                            context
                                .read<OperationalProcedureProvider>()
                                .setTriggerEnabled(_draft, trigger, enabled),
                          ),
                        );
                      },
                    );
                  }),
                ],
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
          options: const <ProcedureOperationType>[
            ProcedureOperationType.sale,
            ProcedureOperationType.technicalService,
            ProcedureOperationType.cashRegister,
          ],
          selected: _draft.operationType,
          labelBuilder:
              (ProcedureOperationType value) =>
                  operationTypeLabel(context, value),
          iconBuilder: (_) => Icons.storefront_outlined,
        );
    if (selected != null) {
      final List<ProcedureMoment> supportedMoments = trigger_meta
          .publishedMobileProcedureMomentsForOperation(
            selected,
            current: _draft.moment,
          );
      final ProcedureMoment nextMoment =
          supportedMoments.contains(_draft.moment)
              ? _draft.moment
              : supportedMoments.first;
      _updateDraft(
        _syncProcedureMomentFromTriggers(
          _draft.copyWith(
            operationType: selected,
            moment: nextMoment,
            triggers: _draft.triggers
                .map(
                  (ProcedureTrigger trigger) => _syncTriggerWithOperationType(
                    trigger,
                    selected,
                    fallbackMoment: nextMoment,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
    }
  }

  Future<void> _selectNotificationCondition() async {
    final ProcedureAdminNotificationCondition? selected =
        await _showOptionSheet<ProcedureAdminNotificationCondition>(
          title: context.t(
            'procedimentos.notificationCondition',
            fallback: 'Quando notificar',
          ),
          options: ProcedureAdminNotificationCondition.values,
          selected: _draft.adminNotification.condition,
          labelBuilder: _notificationConditionLabel,
          iconBuilder: (_) => Icons.notifications_active_outlined,
        );
    if (selected == null) return;
    _updateDraft(
      _draft.copyWith(
        adminNotification: _draft.adminNotification.copyWith(
          condition: selected,
        ),
      ),
    );
  }

  String _notificationConditionLabel(
    ProcedureAdminNotificationCondition condition,
  ) {
    return switch (condition) {
      ProcedureAdminNotificationCondition.always => context.t(
        'procedimentos.notificationAlways',
        fallback: 'Em toda execução',
      ),
      ProcedureAdminNotificationCondition.negativeResponse => context.t(
        'procedimentos.notificationNegative',
        fallback: 'Ao registrar resposta negativa',
      ),
      ProcedureAdminNotificationCondition.procedureSkipped => context.t(
        'procedimentos.notificationSkipped',
        fallback: 'Ao ignorar o procedimento',
      ),
    };
  }

  Future<void> _selectMoment() async {
    final ProcedureMoment? selected = await _showOptionSheet<ProcedureMoment>(
      title: context.t('procedimentos.momentField', fallback: 'Momento'),
      options: trigger_meta.publishedMobileProcedureMomentsForOperation(
        _draft.operationType,
        current: _draft.moment,
      ),
      selected: _draft.moment,
      labelBuilder: (ProcedureMoment value) => momentLabel(context, value),
      iconBuilder: (_) => Icons.schedule_outlined,
    );
    if (selected != null) {
      _updateDraft(
        _syncProcedureMomentFromTriggers(
          _syncProcedureTriggersWithMoment(
            _draft,
            previousMoment: _draft.moment,
            nextMoment: selected,
          ),
        ),
      );
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

  Future<void> _addTrigger() async {
    final ProcedureTrigger? trigger = await _showTriggerSheet();
    if (trigger == null) return;
    if (!mounted) return;
    _updateDraft(
      _syncProcedureMomentFromTriggers(
        context.read<OperationalProcedureProvider>().addTrigger(
          _draft,
          trigger,
        ),
      ),
    );
  }

  Future<void> _editTrigger(ProcedureTrigger trigger) async {
    final ProcedureTrigger? edited = await _showTriggerSheet(trigger: trigger);
    if (edited == null) return;
    if (!mounted) return;
    _updateDraft(
      _syncProcedureMomentFromTriggers(
        context.read<OperationalProcedureProvider>().updateTrigger(
          _draft,
          edited,
        ),
      ),
    );
  }

  Future<ProcedureTrigger?> _showTriggerSheet({ProcedureTrigger? trigger}) {
    return showModalBottomSheet<ProcedureTrigger>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => OperationalProcedureTriggerEditorSheet(
            trigger: trigger,
            existingTriggers: _draft.triggers,
            procedureOperationType: _draft.operationType,
          ),
    );
  }

  Future<void> _deleteTrigger(ProcedureTrigger trigger) async {
    final bool confirmed = await _confirm(
      title: context.t(
        'procedimentos.deleteTriggerTitle',
        fallback: 'Excluir gatilho?',
      ),
      message:
          '${trigger_meta.operationTypeLabel(context, trigger.operationType)} • '
          '${trigger_meta.triggerMomentLabel(context, trigger.triggerMoment)}\n'
          '${context.t('procedimentos.deleteTriggerMessage', fallback: 'O procedimento deixará de ser apresentado neste momento operacional.')}',
    );
    if (!confirmed) return;
    if (!mounted) return;
    _updateDraft(
      _syncProcedureMomentFromTriggers(
        context.read<OperationalProcedureProvider>().removeTrigger(
          _draft,
          trigger.id,
        ),
      ),
    );
  }

  OperationalProcedure _syncProcedureTriggersWithMoment(
    OperationalProcedure procedure, {
    required ProcedureMoment previousMoment,
    required ProcedureMoment nextMoment,
  }) {
    final ProcedureTriggerMoment? previousTriggerMoment =
        procedureTriggerMomentForMoment(previousMoment);
    final ProcedureTriggerMoment? nextTriggerMoment =
        procedureTriggerMomentForMoment(nextMoment);
    if (nextTriggerMoment == null || procedure.triggers.isEmpty) {
      return procedure.copyWith(moment: nextMoment);
    }

    final DateTime now = DateTime.now();
    final List<ProcedureTrigger> synchronized = procedure.triggers
        .map((ProcedureTrigger trigger) {
          final bool shouldSync =
              procedure.triggers.length == 1 ||
              trigger.triggerMoment == previousTriggerMoment;
          if (!shouldSync) return trigger;
          return trigger.copyWith(
            triggerMoment: nextTriggerMoment,
            operationPoint: procedureOperationPointFor(
              trigger.operationType,
              nextTriggerMoment,
            ),
            updatedAt: now,
          );
        })
        .toList(growable: false);

    return procedure.copyWith(moment: nextMoment, triggers: synchronized);
  }

  OperationalProcedure _syncProcedureMomentFromTriggers(
    OperationalProcedure procedure,
  ) {
    ProcedureMoment? derivedMoment;
    for (final ProcedureTrigger trigger in procedure.triggers) {
      if (!trigger.enabled) continue;
      derivedMoment = procedureMomentForTriggerMoment(trigger.triggerMoment);
      if (derivedMoment != null) break;
    }
    if (derivedMoment == null) {
      for (final ProcedureTrigger trigger in procedure.triggers) {
        derivedMoment = procedureMomentForTriggerMoment(trigger.triggerMoment);
        if (derivedMoment != null) break;
      }
    }
    if (derivedMoment == null || derivedMoment == procedure.moment) {
      return procedure;
    }
    return procedure.copyWith(moment: derivedMoment);
  }

  ProcedureTrigger _syncTriggerWithOperationType(
    ProcedureTrigger trigger,
    ProcedureOperationType operationType, {
    required ProcedureMoment fallbackMoment,
  }) {
    final List<ProcedureMoment> validMoments = trigger_meta
        .publishedMobileProcedureMomentsForOperation(
          operationType,
          current: fallbackMoment,
        );
    final ProcedureMoment? derivedMoment = procedureMomentForTriggerMoment(
      trigger.triggerMoment,
    );
    final ProcedureMoment normalizedMoment =
        derivedMoment != null && validMoments.contains(derivedMoment)
            ? derivedMoment
            : fallbackMoment;
    final ProcedureTriggerMoment normalizedTriggerMoment =
        procedureTriggerMomentForMoment(normalizedMoment) ??
        ProcedureTriggerMoment.beforeStart;

    return trigger.copyWith(
      operationType: operationType,
      triggerMoment: normalizedTriggerMoment,
      operationPoint: procedureOperationPointFor(
        operationType,
        normalizedTriggerMoment,
      ),
      updatedAt: DateTime.now(),
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
      builder: (_) => OperationalProcedureItemEditorSheet(item: item),
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

  Future<void> _openPreview() async {
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) => OperationalProcedurePreviewMobileScreen(
              procedure: _draft.copyWith(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
              ),
            ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_canManageProcedures(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'procedimentos.restrictedDescription',
              fallback:
                  'Você pode consultar os procedimentos da empresa, mas apenas administradores podem criar, editar e analisar essas configurações.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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

    setState(() => _saving = true);
    final OperationalProcedure? persisted = await context
        .read<OperationalProcedureProvider>()
        .saveProcedure(
          _draft.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (persisted == null) {
      final OperationalProcedureSaveFailure? failure =
          context.read<OperationalProcedureProvider>().lastSaveFailure;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure == OperationalProcedureSaveFailure.forbidden
                ? context.t(
                  'procedimentos.restrictedDescription',
                  fallback:
                      'Você pode consultar os procedimentos da empresa, mas apenas administradores podem criar, editar e analisar essas configurações.',
                )
                : context.t(
                  'procedimentos.saveError',
                  fallback: 'Não foi possível salvar o procedimento.',
                ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
        if (isChoiceResponseType(item.responseType) &&
            item.options
                    .where((String option) => option.trim().isNotEmpty)
                    .length <
                2) {
          return context.t(
            'procedimentos.validationChoiceOptions',
            fallback: 'Informe pelo menos duas opções nas escolhas.',
          );
        }
      }
    }
    return null;
  }

  bool _canManageProcedures(BuildContext context) {
    final ColaboradorAutorizacoesProvider? permissions =
        Provider.of<ColaboradorAutorizacoesProvider?>(context, listen: false);
    return permissions?.ehAdministrador ?? true;
  }
}

class _DemoNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OperationalProcedureDemoBadge(
          label: context.t(
            'procedimentos.persistedConfiguration',
            fallback: 'Configuração sincronizada',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            context.t(
              'procedimentos.editorPersistenceNotice',
              fallback:
                  'As alterações são salvas para a empresa e respeitam o idioma atual.',
            ),
            style: TextStyle(
              color: colors.heroSupportingText,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorPermissionNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, color: colors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(
                'procedimentos.editorRestrictedNotice',
                fallback:
                    'Consulta liberada. Somente administradores podem salvar alterações neste procedimento.',
              ),
              style: TextStyle(
                color: colors.titleText,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Semantics(
      container: true,
      label: title,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.navigationShadow,
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
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailing != null) Flexible(child: trailing!),
              ],
            ),
            SizedBox(height: 12),
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 58),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  color:
                      isDark ? colors.accent : SixMobilePalette.secondaryLight,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.titleText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.mutedText,
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
    final SixMobileColorScheme colors = context.sixMobileColors;

    return _SheetSurface(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            options.map((T value) {
              final bool isSelected = value == selected;
              final String label = labelBuilder(value);
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Material(
                  color:
                      isSelected
                          ? colors.softAccentSurface
                          : colors.softSurface,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            isSelected
                                ? colors.accent.withValues(alpha: 0.42)
                                : colors.border,
                      ),
                    ),
                    leading: Icon(
                      iconBuilder(value),
                      color: isSelected ? colors.accent : colors.mutedText,
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        color: colors.titleText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle:
                        descriptionBuilder == null
                            ? null
                            : Text(
                              descriptionBuilder!(value),
                              style: TextStyle(
                                color: colors.mutedText,
                                height: 1.25,
                              ),
                            ),
                    trailing:
                        isSelected
                            ? Icon(Icons.check_rounded, color: colors.accent)
                            : null,
                    selected: isSelected,
                    onTap: () => Navigator.of(context).pop(value),
                  ),
                ),
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
    final SixMobileColorScheme colors = context.sixMobileColors;

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
              cursorColor: colors.accent,
              style: TextStyle(
                color: colors.titleText,
                fontWeight: FontWeight.w700,
              ),
              decoration: _operationalProcedureFieldDecoration(
                context,
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
            SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              cursorColor: colors.accent,
              style: TextStyle(
                color: colors.titleText,
                fontWeight: FontWeight.w700,
              ),
              decoration: _operationalProcedureFieldDecoration(
                context,
                labelText: context.t(
                  'procedimentos.descriptionField',
                  fallback: 'Descrição',
                ),
              ),
            ),
            SizedBox(height: 16),
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
                    items: widget.stage?.items ?? <ProcedureItem>[],
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String type = responseTypeLabel(context, item.responseType);
    final String requiredLabel = requiredStateLabel(context, item.required);
    return Semantics(
      container: true,
      label: 'Item: ${item.title}. Tipo $type. $requiredLabel.',
      child: Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              responseTypeIcon(item.responseType),
              color: isDark ? colors.accent : SixMobilePalette.secondaryLight,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.titleText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$type • $requiredLabel',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedText, fontSize: 12),
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
              icon: Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: context.t(
                'procedimentos.deleteItem',
                fallback: 'Excluir item',
              ),
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({super.key, required this.message, this.description});

  final String message;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          message,
          style: TextStyle(
            color: colors.mutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (description != null) ...<Widget>[
          SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(color: colors.mutedText, height: 1.35),
          ),
        ],
      ],
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
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
                  color: colors.strongBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: colors.titleText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 16),
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
            style: _mobileSheetSecondaryButtonStyle(context),
            child: Text(context.t('common.cancel', fallback: 'Cancelar')),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: onSave,
            style: _mobileSheetPrimaryButtonStyle(context),
            child: Text(saveLabel),
          ),
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
    final SixMobileColorScheme colors = context.sixMobileColors;

    return _SheetSurface(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: TextStyle(color: colors.mutedText, height: 1.35),
          ),
          SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: _mobileSheetSecondaryButtonStyle(context),
                  child: Text(
                    context.t(
                      'procedimentos.keepEditing',
                      fallback: 'Continuar editando',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: _mobileSheetDestructiveButtonStyle(context),
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
