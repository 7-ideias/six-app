import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_response_type_metadata.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_simulated_evidence.dart';

class OperationalProcedureExecutionItem extends StatelessWidget {
  const OperationalProcedureExecutionItem({
    super.key,
    required this.item,
    required this.response,
    required this.pending,
    required this.onChanged,
  });

  final ProcedureItem item;
  final ProcedureItemResponse? response;
  final bool pending;
  final ValueChanged<ProcedureItemResponse> onChanged;

  @override
  Widget build(BuildContext context) {
    final String typeLabel = responseTypeLabel(context, item.responseType);
    final String requiredLabel =
        item.required
            ? context.t('common.required', fallback: 'Obrigatório')
            : context.t('common.optional', fallback: 'Opcional');
    return Semantics(
      container: true,
      label: OperationalProcedureI18n.executionItemSemantics(
        context,
        requiredLabel: requiredLabel,
        title: item.title,
        type: typeLabel,
      ),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              pending
                  ? SixMobilePalette.softAccentSurface
                  : SixMobilePalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                pending
                    ? SixMobilePalette.errorBorder
                    : SixMobilePalette.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  responseTypeIcon(item.responseType),
                  color: SixMobilePalette.secondary,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        OperationalProcedureI18n.executionItemStatus(
                          context,
                          type: typeLabel,
                          requiredLabel: requiredLabel,
                        ),
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.guidance.trim().isNotEmpty) ...<Widget>[
              SizedBox(height: 10),
              Text(
                item.guidance,
                style: TextStyle(
                  color: SixMobilePalette.mutedText,
                  height: 1.35,
                ),
              ),
            ],
            if (pending) ...<Widget>[
              SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(
                  context.t(
                    'procedimentos.previewRequiredPending',
                    fallback: 'Responda esta ação obrigatória para continuar.',
                  ),
                  style: TextStyle(
                    color: SixMobilePalette.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            SizedBox(height: 12),
            _buildControl(context),
            if (isSimulatedResponseType(item.responseType)) ...<Widget>[
              SizedBox(height: 10),
              Text(
                context.t(
                  'procedimentos.simulatedResourceNotice',
                  fallback:
                      'Recurso demonstrativo. Nenhum dado real será capturado.',
                ),
                style: TextStyle(
                  color: SixMobilePalette.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControl(BuildContext context) {
    return switch (item.responseType) {
      ProcedureResponseType.instruction => _InstructionControl(
        completed: response?.completed ?? false,
        onChanged: (bool value) => _emit(completed: value),
      ),
      ProcedureResponseType.confirmation => CheckboxListTile(
        value: response?.completed ?? false,
        contentPadding: EdgeInsets.zero,
        title: Text(
          context.t(
            'procedimentos.previewConfirmAction',
            fallback: 'Confirmar ação',
          ),
        ),
        onChanged: (bool? value) => _emit(completed: value ?? false),
      ),
      ProcedureResponseType.yesNo => _YesNoControl(
        value: response?.boolValue,
        requiresTextWhenNo: item.configuration.requireTextWhenNo,
        negativeTextValue: response?.textValue ?? '',
        negativeTextPlaceholder:
            item.configuration.hasNegativeTextPlaceholder
                ? item.configuration.negativeTextPlaceholder
                : context.t(
                  'procedimentos.previewNegativeTextHint',
                  fallback: 'Digite o que faltou',
                ),
        onChanged: (bool value) {
          _emit(
            completed: true,
            boolValue: value,
            textValue: value ? '' : response?.textValue,
            clearNumberValue: true,
            clearDateValue: true,
            clearEvidence: true,
          );
        },
        onNegativeTextChanged:
            (String value) => _emit(
              completed: true,
              boolValue: false,
              textValue: value,
              clearNumberValue: true,
              clearDateValue: true,
              clearEvidence: true,
            ),
      ),
      ProcedureResponseType.freeText => TextFormField(
        initialValue: response?.textValue ?? '',
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          hintText:
              item.configuration.hasPlaceholder
                  ? item.configuration.placeholder
                  : context.t(
                    'procedimentos.previewTextHint',
                    fallback: 'Digite a resposta',
                  ),
        ),
        onChanged:
            (String value) =>
                _emit(completed: value.trim().isNotEmpty, textValue: value),
      ),
      ProcedureResponseType.number => TextFormField(
        initialValue:
            response?.numberValue == null
                ? ''
                : OperationalProcedureI18n.formatNumber(
                  context,
                  response!.numberValue!,
                ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText:
              item.configuration.hasPlaceholder
                  ? item.configuration.placeholder
                  : context.t(
                    'procedimentos.previewNumberHint',
                    fallback: 'Digite um número',
                  ),
          suffixText:
              item.configuration.hasUnit ? item.configuration.unit : null,
        ),
        onChanged: (String value) {
          final num? parsed = OperationalProcedureI18n.parseNumber(
            context,
            value,
          );
          _emit(completed: parsed != null, numberValue: parsed);
        },
      ),
      ProcedureResponseType.date => _DateControl(
        value: response?.dateValue,
        onChanged: (DateTime value) => _emit(completed: true, dateValue: value),
      ),
      ProcedureResponseType.singleChoice => _SingleChoiceControl(
        options: item.options,
        selected:
            (response?.selectedOptions.isNotEmpty ?? false)
                ? response!.selectedOptions.first
                : null,
        onChanged:
            (String value) =>
                _emit(completed: true, selectedOptions: <String>[value]),
      ),
      ProcedureResponseType.multipleChoice => _MultipleChoiceControl(
        options: item.options,
        selected: response?.selectedOptions ?? <String>[],
        onChanged:
            (List<String> value) =>
                _emit(completed: value.isNotEmpty, selectedOptions: value),
      ),
      ProcedureResponseType.imei => _ImeiControl(
        value: response?.textValue ?? '',
        onChanged:
            (String value) =>
                _emit(completed: value.trim().isNotEmpty, textValue: value),
        onDemo: () => _emit(completed: true, textValue: '359881234567890'),
      ),
      ProcedureResponseType.photo ||
      ProcedureResponseType.signature ||
      ProcedureResponseType.location ||
      ProcedureResponseType.barcode ||
      ProcedureResponseType.document ||
      ProcedureResponseType.audio => _SimulatedControl(
        type: item.responseType,
        evidence: response?.evidence,
        onSimulate:
            () => _emit(
              completed: true,
              evidence: _simulatedEvidence(context, item.responseType),
            ),
        onRemove: () => _emit(completed: false, clearEvidence: true),
      ),
    };
  }

  void _emit({
    bool? completed,
    bool? boolValue,
    String? textValue,
    num? numberValue,
    DateTime? dateValue,
    List<String>? selectedOptions,
    ProcedureSimulatedEvidence? evidence,
    bool clearNumberValue = false,
    bool clearDateValue = false,
    bool clearEvidence = false,
  }) {
    final ProcedureItemResponse current =
        response ??
        ProcedureItemResponse(
          itemId: item.id,
          responseType: item.responseType,
          updatedAt: DateTime.now(),
        );
    onChanged(
      current.copyWith(
        completed: completed,
        boolValue: boolValue,
        textValue: textValue,
        numberValue: numberValue,
        dateValue: dateValue,
        selectedOptions: selectedOptions,
        evidence: evidence,
        clearNumberValue: clearNumberValue,
        clearDateValue: clearDateValue,
        clearEvidence: clearEvidence,
      ),
    );
  }

  ProcedureSimulatedEvidence _simulatedEvidence(
    BuildContext context,
    ProcedureResponseType type,
  ) {
    return switch (type) {
      ProcedureResponseType.photo => ProcedureSimulatedEvidence(
        label: context.t(
          'procedimentos.previewPhotoAdded',
          fallback: 'Foto adicionada',
        ),
        detail: 'foto-demonstrativa.jpg',
        iconKey: 'photo',
      ),
      ProcedureResponseType.signature => ProcedureSimulatedEvidence(
        label: context.t(
          'procedimentos.previewSignatureAdded',
          fallback: 'Assinatura adicionada',
        ),
        detail: context.t(
          'procedimentos.previewSignatureDemoDetail',
          fallback: 'Traço demonstrativo registrado',
        ),
        iconKey: 'signature',
      ),
      ProcedureResponseType.location => ProcedureSimulatedEvidence(
        label: context.t(
          'procedimentos.previewLocationAdded',
          fallback: 'Localização de demonstração capturada',
        ),
        detail: '-23.5505, -46.6333',
        iconKey: 'location',
      ),
      ProcedureResponseType.barcode => ProcedureSimulatedEvidence(
        label: context.t(
          'procedimentos.previewBarcodeAdded',
          fallback: 'Código lido',
        ),
        detail: '7891234567895',
        iconKey: 'barcode',
      ),
      ProcedureResponseType.document => ProcedureSimulatedEvidence(
        label: context.t(
          'procedimentos.previewDocumentAdded',
          fallback: 'Documento anexado',
        ),
        detail: 'termo-demonstrativo.pdf • 184 KB',
        iconKey: 'document',
      ),
      ProcedureResponseType.audio => ProcedureSimulatedEvidence(
        label: context.t(
          'procedimentos.previewAudioAdded',
          fallback: 'Áudio gravado',
        ),
        detail: '00:12',
        iconKey: 'audio',
      ),
      _ => ProcedureSimulatedEvidence(
        label: OperationalProcedureI18n.demonstration(context),
        detail: '',
        iconKey: 'demo',
      ),
    };
  }
}

class _InstructionControl extends StatelessWidget {
  const _InstructionControl({required this.completed, required this.onChanged});

  final bool completed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onChanged(!completed),
      icon: Icon(
        completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      ),
      label: Text(
        completed
            ? context.t(
              'procedimentos.previewUnderstoodDone',
              fallback: 'Entendido',
            )
            : context.t(
              'procedimentos.previewUnderstood',
              fallback: 'Marcar como entendido',
            ),
      ),
    );
  }
}

class _YesNoControl extends StatelessWidget {
  const _YesNoControl({
    required this.value,
    required this.requiresTextWhenNo,
    required this.negativeTextValue,
    required this.negativeTextPlaceholder,
    required this.onChanged,
    required this.onNegativeTextChanged,
  });

  final bool? value;
  final bool requiresTextWhenNo;
  final String negativeTextValue;
  final String negativeTextPlaceholder;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onNegativeTextChanged;

  @override
  Widget build(BuildContext context) {
    final bool showNegativeText = value == false && requiresTextWhenNo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<bool>(
          segments: <ButtonSegment<bool>>[
            ButtonSegment<bool>(
              value: true,
              label: Text(context.t('common.yes', fallback: 'Sim')),
              icon: Icon(Icons.thumb_up_alt_outlined),
            ),
            ButtonSegment<bool>(
              value: false,
              label: Text(context.t('common.no', fallback: 'Não')),
              icon: Icon(Icons.thumb_down_alt_outlined),
            ),
          ],
          selected: value == null ? <bool>{} : <bool>{value!},
          emptySelectionAllowed: true,
          onSelectionChanged: (Set<bool> selected) {
            if (selected.isNotEmpty) onChanged(selected.first);
          },
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 180),
          child:
              showNegativeText
                  ? Padding(
                    key: ValueKey<String>('negative-text'),
                    padding: EdgeInsets.only(top: 12),
                    child: TextFormField(
                      initialValue: negativeTextValue,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: context.t(
                          'procedimentos.previewNegativeTextLabel',
                          fallback: 'O que faltou?',
                        ),
                        hintText: negativeTextPlaceholder,
                      ),
                      onChanged: onNegativeTextChanged,
                    ),
                  )
                  : SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DateControl extends StatelessWidget {
  const _DateControl({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final String label =
        value == null
            ? context.t(
              'procedimentos.previewSelectDate',
              fallback: 'Selecionar data',
            )
            : OperationalProcedureI18n.formatDate(context, value!);
    return OutlinedButton.icon(
      onPressed: () async {
        final DateTime now = DateTime.now();
        final DateTime? selected = await showModalBottomSheet<DateTime>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder:
              (_) => _DateSheet(
                dates: <DateTime>[
                  now,
                  now.add(Duration(days: 1)),
                  now.add(Duration(days: 7)),
                ],
              ),
        );
        if (selected != null) onChanged(selected);
      },
      icon: Icon(Icons.calendar_today_rounded),
      label: Text(label),
    );
  }
}

class _SingleChoiceControl extends StatelessWidget {
  const _SingleChoiceControl({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          options.map((String option) {
            final bool checked = option == selected;
            return Semantics(
              button: true,
              selected: checked,
              label: option,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(option),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        checked
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color:
                            checked
                                ? SixMobilePalette.accent
                                : SixMobilePalette.mutedText,
                      ),
                      SizedBox(width: 10),
                      Expanded(child: Text(option)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _MultipleChoiceControl extends StatelessWidget {
  const _MultipleChoiceControl({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          options.map((String option) {
            final bool checked = selected.contains(option);
            return CheckboxListTile(
              value: checked,
              contentPadding: EdgeInsets.zero,
              title: Text(option),
              onChanged: (bool? value) {
                final List<String> next = <String>[...selected];
                if (value == true && !next.contains(option)) {
                  next.add(option);
                } else if (value != true) {
                  next.remove(option);
                }
                onChanged(next);
              },
            );
          }).toList(),
    );
  }
}

class _ImeiControl extends StatelessWidget {
  const _ImeiControl({
    required this.value,
    required this.onChanged,
    required this.onDemo,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: context.t(
              'procedimentos.previewImeiHint',
              fallback: 'Digite o IMEI',
            ),
          ),
          onChanged: onChanged,
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onDemo,
          icon: Icon(Icons.science_outlined),
          label: Text(
            context.t(
              'procedimentos.previewUseDemoImei',
              fallback: 'Usar IMEI demonstrativo',
            ),
          ),
        ),
      ],
    );
  }
}

class _SimulatedControl extends StatelessWidget {
  const _SimulatedControl({
    required this.type,
    required this.evidence,
    required this.onSimulate,
    required this.onRemove,
  });

  final ProcedureResponseType type;
  final ProcedureSimulatedEvidence? evidence;
  final VoidCallback onSimulate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (evidence != null) {
      return OperationalProcedureSimulatedEvidence(
        icon: responseTypeIcon(type),
        label: evidence!.label,
        detail: evidence!.detail,
        onRemove: onRemove,
        removeLabel: context.t(
          'procedimentos.previewRemoveEvidence',
          fallback: 'Remover evidência',
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onSimulate,
      icon: Icon(responseTypeIcon(type)),
      label: Text(_simulateActionLabel(context, type)),
    );
  }

  String _simulateActionLabel(
    BuildContext context,
    ProcedureResponseType type,
  ) {
    return switch (type) {
      ProcedureResponseType.photo => context.t(
        'procedimentos.previewTakePhoto',
        fallback: 'Tirar foto',
      ),
      ProcedureResponseType.signature => context.t(
        'procedimentos.previewSimulateSignature',
        fallback: 'Simular assinatura',
      ),
      ProcedureResponseType.location => context.t(
        'procedimentos.previewCaptureLocation',
        fallback: 'Capturar localização',
      ),
      ProcedureResponseType.barcode => context.t(
        'procedimentos.previewSimulateBarcode',
        fallback: 'Simular leitura',
      ),
      ProcedureResponseType.document => context.t(
        'procedimentos.previewSimulateDocument',
        fallback: 'Simular anexo',
      ),
      ProcedureResponseType.audio => context.t(
        'procedimentos.previewSimulateAudio',
        fallback: 'Simular gravação',
      ),
      _ => OperationalProcedureI18n.demonstration(context),
    };
  }
}

class _DateSheet extends StatelessWidget {
  const _DateSheet({required this.dates});

  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 18),
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
          SizedBox(height: 14),
          Text(
            context.t(
              'procedimentos.previewSelectDate',
              fallback: 'Selecionar data',
            ),
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          ...dates.map((DateTime date) {
            final String label = OperationalProcedureI18n.formatDate(
              context,
              date,
            );
            return ListTile(
              leading: Icon(Icons.calendar_today_rounded),
              title: Text(label),
              onTap: () => Navigator.of(context).pop(date),
            );
          }),
        ],
      ),
    );
  }
}
