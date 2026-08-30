import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';

class OperationalProcedureExecutionWebDialog extends StatefulWidget {
  const OperationalProcedureExecutionWebDialog({
    super.key,
    required this.procedure,
    required this.configuration,
  });

  final OperationalProcedure procedure;
  final ProcedureExecutionConfiguration configuration;

  @override
  State<OperationalProcedureExecutionWebDialog> createState() =>
      _OperationalProcedureExecutionWebDialogState();
}

class _OperationalProcedureExecutionWebDialogState
    extends State<OperationalProcedureExecutionWebDialog> {
  late ProcedureExecutionDraft _execution;
  int _stageIndex = 0;
  bool _saving = false;
  final Set<String> _pending = <String>{};

  @override
  void initState() {
    super.initState();
    _execution = ProcedureExecutionDraft(
      procedureId: widget.procedure.id,
      currentStageIndex: 0,
      responses: const <String, ProcedureItemResponse>{},
      startedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProcedureStage stage = widget.procedure.stages[_stageIndex];
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
          child: Column(
            children: <Widget>[
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${context.t('procedimentos.stage', fallback: 'Etapa')} ${_stageIndex + 1} ${context.t('common.of', fallback: 'de')} ${widget.procedure.stages.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stage.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (stage.description.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(stage.description),
                      ],
                      const SizedBox(height: 20),
                      ...stage.items.map(_item),
                    ],
                  ),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 22, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: .45),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'procedimentos.operationalBadge',
                    fallback: 'Procedimento operacional',
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.procedure.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (widget.procedure.description.trim().isNotEmpty)
                  Text(widget.procedure.description),
              ],
            ),
          ),
          IconButton(
            tooltip: context.t('common.close', fallback: 'Fechar'),
            onPressed: _saving ? null : _exit,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _item(ProcedureItem item) {
    final ProcedureItemResponse? response = _execution.responses[item.id];
    final bool pending = _pending.contains(item.id);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pending
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (item.guidance.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(item.guidance),
          ],
          const SizedBox(height: 12),
          _input(item, response),
          if (pending) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              context.t(
                'procedimentos.requiredAnswer',
                fallback: 'Resposta obrigatória.',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _input(ProcedureItem item, ProcedureItemResponse? response) {
    if (item.responseType == ProcedureResponseType.yesNo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: true,
                label: Text(context.t('common.yes', fallback: 'Sim')),
                icon: const Icon(Icons.check_rounded),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text(context.t('common.no', fallback: 'Não')),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
            selected: response?.boolValue == null
                ? <bool>{}
                : <bool>{response!.boolValue!},
            emptySelectionAllowed: true,
            onSelectionChanged: (Set<bool> values) {
              if (values.isEmpty) return;
              _update(
                item,
                (response ?? _emptyResponse(item)).copyWith(
                  completed: true,
                  boolValue: values.first,
                ),
              );
            },
          ),
          if (response?.boolValue == false &&
              item.configuration.requireTextWhenNo) ...<Widget>[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: response?.textValue,
              decoration: InputDecoration(
                labelText: context.t(
                  'procedimentos.negativeReason',
                  fallback: 'O que faltou?',
                ),
              ),
              onChanged: (String value) {
                _update(item, response!.copyWith(textValue: value));
              },
            ),
          ],
        ],
      );
    }
    if (item.responseType == ProcedureResponseType.freeText ||
        item.responseType == ProcedureResponseType.barcode ||
        item.responseType == ProcedureResponseType.imei) {
      return TextFormField(
        initialValue: response?.textValue,
        decoration: InputDecoration(
          hintText: item.configuration.placeholder,
          border: const OutlineInputBorder(),
        ),
        onChanged: (String value) {
          _update(
            item,
            (response ?? _emptyResponse(item)).copyWith(
              textValue: value,
              completed: value.trim().isNotEmpty,
            ),
          );
        },
      );
    }
    if (item.responseType == ProcedureResponseType.number) {
      return TextFormField(
        initialValue: response?.numberValue?.toString(),
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onChanged: (String value) {
          final num? parsed = num.tryParse(value.replaceAll(',', '.'));
          _update(
            item,
            (response ?? _emptyResponse(item)).copyWith(
              numberValue: parsed,
              completed: parsed != null,
              clearNumberValue: parsed == null,
            ),
          );
        },
      );
    }
    if (item.responseType == ProcedureResponseType.singleChoice ||
        item.responseType == ProcedureResponseType.multipleChoice) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: item.options
            .map((String option) {
              final bool selected =
                  response?.selectedOptions.contains(option) ?? false;
              return FilterChip(
                label: Text(option),
                selected: selected,
                onSelected: (bool value) {
                  final List<String> selectedOptions = List<String>.of(
                    response?.selectedOptions ?? const [],
                  );
                  if (item.responseType == ProcedureResponseType.singleChoice) {
                    selectedOptions
                      ..clear()
                      ..add(option);
                  } else if (value) {
                    selectedOptions.add(option);
                  } else {
                    selectedOptions.remove(option);
                  }
                  _update(
                    item,
                    (response ?? _emptyResponse(item)).copyWith(
                      selectedOptions: selectedOptions,
                      completed: selectedOptions.isNotEmpty,
                    ),
                  );
                },
              );
            })
            .toList(growable: false),
      );
    }
    return CheckboxListTile(
      value: response?.completed ?? false,
      contentPadding: EdgeInsets.zero,
      title: Text(
        context.t(
          'procedimentos.confirmAction',
          fallback: 'Confirmar ação realizada',
        ),
      ),
      onChanged: (bool? value) {
        _update(
          item,
          (response ?? _emptyResponse(item)).copyWith(completed: value == true),
        );
      },
    );
  }

  Widget _footer() {
    final bool last = _stageIndex == widget.procedure.stages.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 22),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: <Widget>[
          if (widget.configuration.allowSkip)
            TextButton(
              onPressed: _saving ? null : _skip,
              child: Text(
                context.t(
                  'procedimentos.continueWithoutCompleting',
                  fallback: 'Continuar sem concluir',
                ),
              ),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: _saving || _stageIndex == 0
                ? null
                : () => setState(() => _stageIndex--),
            child: Text(context.t('common.back', fallback: 'Voltar')),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _saving ? null : _next,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  ),
            label: Text(
              last
                  ? context.t('common.finish', fallback: 'Concluir')
                  : context.t('common.continueLabel', fallback: 'Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  ProcedureItemResponse _emptyResponse(ProcedureItem item) {
    return ProcedureItemResponse(
      itemId: item.id,
      responseType: item.responseType,
      updatedAt: DateTime.now(),
    );
  }

  void _update(ProcedureItem item, ProcedureItemResponse response) {
    setState(() {
      final Map<String, ProcedureItemResponse> responses =
          Map<String, ProcedureItemResponse>.of(_execution.responses);
      responses[item.id] = response;
      _execution = _execution.copyWith(responses: responses);
      _pending.remove(item.id);
    });
  }

  Future<void> _next() async {
    final ProcedureStage stage = widget.procedure.stages[_stageIndex];
    final Set<String> pending = stage.items
        .where((ProcedureItem item) {
          if (!item.required) return false;
          final ProcedureItemResponse? response = _execution.responses[item.id];
          if (response == null || !response.completed) return true;
          return item.responseType == ProcedureResponseType.yesNo &&
              item.configuration.requireTextWhenNo &&
              response.boolValue == false &&
              response.textValue.trim().isEmpty;
        })
        .map((ProcedureItem item) => item.id)
        .toSet();
    if (pending.isNotEmpty) {
      setState(() => _pending.addAll(pending));
      return;
    }
    if (_stageIndex < widget.procedure.stages.length - 1) {
      setState(() => _stageIndex++);
      return;
    }
    await _persist('CONCLUIDO', (String id) {
      return ProcedureFlowResult.continueOperation(
        completedProcedureIds: <String>[widget.procedure.id],
        executionIds: <String>[id],
      );
    });
  }

  Future<void> _skip() async {
    await _persist('IGNORADO', (String id) {
      return ProcedureFlowResult.skipped(
        skippedProcedureIds: <String>[widget.procedure.id],
        executionIds: <String>[id],
      );
    });
  }

  Future<void> _exit() async {
    if (widget.configuration.enforcementMode ==
        ProcedureEnforcementMode.required) {
      await _persist('CANCELADO', (_) => const ProcedureFlowResult.cancelled());
      return;
    }
    await _skip();
  }

  Future<void> _persist(
    String status,
    ProcedureFlowResult Function(String id) resultBuilder,
  ) async {
    setState(() => _saving = true);
    try {
      final result =
          await OperationalProcedureService(
            localeTag: Localizations.localeOf(context).toLanguageTag(),
          ).persistExecution(
            procedure: widget.procedure,
            execution: _execution.copyWith(completedAt: DateTime.now()),
            configuration: widget.configuration,
            status: status,
            platform: ProcedurePlatform.web,
          );
      if (mounted) Navigator.of(context).pop(resultBuilder(result.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'procedimentos.executionSaveError',
              fallback:
                  'Não foi possível salvar as respostas. Tente novamente.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
