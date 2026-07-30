import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_metadata.dart';

class OperationalProcedureTriggerEditorSheet extends StatefulWidget {
  const OperationalProcedureTriggerEditorSheet({
    super.key,
    this.trigger,
    required this.existingTriggers,
  });

  final ProcedureTrigger? trigger;
  final List<ProcedureTrigger> existingTriggers;

  @override
  State<OperationalProcedureTriggerEditorSheet> createState() =>
      _OperationalProcedureTriggerEditorSheetState();
}

class _OperationalProcedureTriggerEditorSheetState
    extends State<OperationalProcedureTriggerEditorSheet> {
  ProcedureOperationType? _operationType;
  ProcedureTriggerMoment? _moment;
  late ProcedureTriggerActivationMode _activationMode;
  late ProcedureEnforcementMode _enforcementMode;
  late bool _enabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ProcedureTrigger? trigger = widget.trigger;
    _operationType = trigger?.operationType;
    _moment = trigger?.triggerMoment;
    _activationMode =
        trigger?.activationMode ?? ProcedureTriggerActivationMode.automatic;
    _enforcementMode =
        trigger?.enforcementMode ?? ProcedureEnforcementMode.recommended;
    _enabled = trigger?.enabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      title:
          widget.trigger == null
              ? context.t(
                'procedimentos.addTrigger',
                fallback: 'Adicionar gatilho',
              )
              : context.t(
                'procedimentos.editTrigger',
                fallback: 'Editar gatilho',
              ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_error != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: const TextStyle(
                  color: SixMobilePalette.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _SelectorTile(
            label: context.t(
              'procedimentos.operationContext',
              fallback: 'Contexto operacional',
            ),
            value:
                _operationType == null
                    ? context.t(
                      'procedimentos.selectOperationContext',
                      fallback: 'Selecionar contexto',
                    )
                    : operationTypeLabel(context, _operationType!),
            icon:
                _operationType == null
                    ? Icons.storefront_outlined
                    : operationTypeIcon(_operationType!),
            onTap: _selectOperation,
          ),
          const SizedBox(height: 6),
          Text(
            context.t(
              'procedimentos.mobilePointAvailable',
              fallback: 'Disponível no aplicativo mobile.',
            ),
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _SelectorTile(
            label: context.t('procedimentos.momentField', fallback: 'Momento'),
            value:
                _moment == null
                    ? context.t(
                      'procedimentos.selectTriggerMoment',
                      fallback: 'Selecionar momento',
                    )
                    : triggerMomentLabel(context, _moment!),
            icon: Icons.schedule_outlined,
            onTap: _operationType == null ? null : _selectMoment,
          ),
          const SizedBox(height: 14),
          _ChoiceSection<ProcedureTriggerActivationMode>(
            title: context.t(
              'procedimentos.activationMode',
              fallback: 'Modo de ativação',
            ),
            values: ProcedureTriggerActivationMode.values,
            selected: _activationMode,
            labelBuilder: activationModeLabel,
            descriptionBuilder: activationModeDescription,
            iconBuilder: activationModeIcon,
            onChanged:
                (ProcedureTriggerActivationMode value) =>
                    setState(() => _activationMode = value),
          ),
          const SizedBox(height: 14),
          _ChoiceSection<ProcedureEnforcementMode>(
            title: context.t(
              'procedimentos.enforcementMode',
              fallback: 'Nível de exigência',
            ),
            values: ProcedureEnforcementMode.values,
            selected: _enforcementMode,
            labelBuilder: enforcementModeLabel,
            descriptionBuilder: enforcementModeDescription,
            iconBuilder: enforcementModeIcon,
            onChanged:
                (ProcedureEnforcementMode value) =>
                    setState(() => _enforcementMode = value),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: _enabled,
            contentPadding: EdgeInsets.zero,
            title: Text(context.t('common.active', fallback: 'Ativo')),
            subtitle: Text(
              context.t(
                'procedimentos.triggerEnabledHelp',
                fallback:
                    'Gatilhos inativos ficam salvos, mas não aparecem na simulação operacional.',
              ),
            ),
            onChanged: (bool value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.t('common.cancel', fallback: 'Cancelar')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: Text(
                    context.t(
                      'procedimentos.saveTrigger',
                      fallback: 'Salvar gatilho',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectOperation() async {
    final ProcedureOperationType? selected =
        await _showOptions<ProcedureOperationType>(
          title: context.t(
            'procedimentos.operationContext',
            fallback: 'Contexto operacional',
          ),
          values: publishedMobileOperationTypes(current: _operationType),
          selected: _operationType,
          labelBuilder: operationTypeLabel,
          iconBuilder: operationTypeIcon,
        );
    if (selected == null) return;
    setState(() {
      _operationType = selected;
      if (_moment != null && !isTriggerMomentValid(selected, _moment!)) {
        _moment = null;
        _error = context.t(
          'procedimentos.triggerMomentCleared',
          fallback: 'Escolha um novo momento compatível com o contexto.',
        );
      } else {
        _error = null;
      }
    });
  }

  Future<void> _selectMoment() async {
    final ProcedureOperationType? operation = _operationType;
    if (operation == null) return;
    final ProcedureTriggerMoment? selected =
        await _showOptions<ProcedureTriggerMoment>(
          title: context.t('procedimentos.momentField', fallback: 'Momento'),
          values: publishedMobileMomentsForOperation(
            operation,
            current: _moment,
          ),
          selected: _moment,
          labelBuilder: triggerMomentLabel,
          iconBuilder: (_) => Icons.schedule_outlined,
        );
    if (selected != null) {
      setState(() {
        _moment = selected;
        _error = null;
      });
    }
  }

  Future<T?> _showOptions<T>({
    required String title,
    required List<T> values,
    required T? selected,
    required String Function(BuildContext context, T value) labelBuilder,
    required IconData Function(T value) iconBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SheetSurface(
          title: title,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                values.map((T value) {
                  final bool isSelected = value == selected;
                  return ListTile(
                    leading: Icon(iconBuilder(value)),
                    title: Text(labelBuilder(context, value)),
                    trailing:
                        isSelected ? const Icon(Icons.check_rounded) : null,
                    selected: isSelected,
                    onTap: () => Navigator.of(context).pop(value),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _save() {
    final ProcedureOperationType? operation = _operationType;
    final ProcedureTriggerMoment? moment = _moment;
    if (operation == null) {
      setState(() {
        _error = context.t(
          'procedimentos.validationTriggerOperation',
          fallback: 'Selecione o contexto operacional.',
        );
      });
      return;
    }
    if (moment == null) {
      setState(() {
        _error = context.t(
          'procedimentos.validationTriggerMoment',
          fallback: 'Selecione o momento de execução.',
        );
      });
      return;
    }
    final ProcedureOperationPoint? operationPoint = procedureOperationPointFor(
      operation,
      moment,
    );
    if (!isTriggerMomentValid(operation, moment) || operationPoint == null) {
      setState(() {
        _error = context.t(
          'procedimentos.validationTriggerMomentInvalid',
          fallback: 'O momento selecionado não é compatível com o contexto.',
        );
      });
      return;
    }

    final DateTime now = DateTime.now();
    final ProcedureTrigger trigger = ProcedureTrigger(
      id: widget.trigger?.id ?? '',
      operationPoint: operationPoint,
      operationType: operation,
      triggerMoment: moment,
      activationMode: _activationMode,
      enforcementMode: _enforcementMode,
      enabled: _enabled,
      order: widget.trigger?.order ?? 0,
      createdAt: widget.trigger?.createdAt ?? now,
      updatedAt: now,
    );
    if (hasDuplicateTrigger(
      widget.existingTriggers,
      trigger,
      ignoringId: widget.trigger?.id,
    )) {
      setState(() {
        _error = context.t(
          'procedimentos.validationDuplicateTrigger',
          fallback:
              'Já existe um gatilho com este contexto, momento e ativação.',
        );
      });
      return;
    }

    Navigator.of(context).pop(trigger);
  }
}

class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.descriptionBuilder,
    required this.iconBuilder,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(BuildContext context, T value) labelBuilder;
  final String Function(BuildContext context, T value) descriptionBuilder;
  final IconData Function(T value) iconBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...values.map((T value) {
            final bool isSelected = value == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                button: true,
                selected: isSelected,
                label:
                    '${labelBuilder(context, value)}. ${descriptionBuilder(context, value)}',
                child: Material(
                  color:
                      isSelected
                          ? SixMobilePalette.softAccentSurface
                          : SixMobilePalette.softNeutralSurface,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => onChanged(value),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              isSelected
                                  ? SixMobilePalette.highlightedBorder
                                  : SixMobilePalette.border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(iconBuilder(value)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  labelBuilder(context, value),
                                  style: const TextStyle(
                                    color: SixMobilePalette.titleText,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  descriptionBuilder(context, value),
                                  style: const TextStyle(
                                    color: SixMobilePalette.mutedText,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              color: SixMobilePalette.accent,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
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
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
