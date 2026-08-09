import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/operational_procedures/procedure_execution_rules.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_demo_badge.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_execution_item.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_execution_progress.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_execution_summary.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_trigger_metadata.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';

class OperationalProcedurePreviewMobileScreen extends StatefulWidget {
  const OperationalProcedurePreviewMobileScreen({
    super.key,
    required this.procedure,
    this.configuration = const ProcedureExecutionConfiguration(),
  });

  final OperationalProcedure procedure;
  final ProcedureExecutionConfiguration configuration;

  @override
  State<OperationalProcedurePreviewMobileScreen> createState() =>
      _OperationalProcedurePreviewMobileScreenState();
}

class _OperationalProcedurePreviewMobileScreenState
    extends State<OperationalProcedurePreviewMobileScreen> {
  late ProcedureExecutionDraft _execution;
  final ProcedureExecutionRules _executionRules = ProcedureExecutionRules();
  final Set<String> _pendingItemIds = <String>{};
  bool _showSummary = false;
  ProcedureTrigger? _selectedTrigger;

  @override
  void initState() {
    super.initState();
    _execution = ProcedureExecutionDraft(
      procedureId: widget.procedure.id,
      currentStageIndex: 0,
      responses: const <String, ProcedureItemResponse>{},
      startedAt: DateTime.now(),
    );
    final List<ProcedureTrigger> enabledTriggers =
        widget.procedure.triggers
            .where((ProcedureTrigger trigger) => trigger.enabled)
            .toList();
    _selectedTrigger = enabledTriggers.isEmpty ? null : enabledTriggers.first;
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final bool hasResponses = _execution.responses.isNotEmpty;
    final bool canPop =
        widget.configuration.isOperational ? false : !hasResponses;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) return;
        if (widget.configuration.isOperational) {
          await _handleOperationalExit();
          return;
        }
        if (!hasResponses) return;
        if (await _confirmDiscardResponses()) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: SixMobilePageShell(
        title: context.t(
          widget.configuration.isOperational
              ? 'procedimentos.operationalExecutionTitle'
              : 'procedimentos.previewTitle',
          fallback:
              widget.configuration.isOperational
                  ? 'Antes de iniciar a venda'
                  : 'Pré-visualização',
        ),
        backgroundColor: SixMobilePalette.background,
        primaryColor: SixMobilePalette.primary,
        secondaryColor: SixMobilePalette.secondary,
        accentColor: SixMobilePalette.accent,
        enableAnimatedBackground: !reduceMotion,
        bodyBuilder: (
          BuildContext context,
          ScrollController scrollController,
          double topInset,
        ) {
          return SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
              children: <Widget>[
                _PreviewHeader(
                  procedure: widget.procedure,
                  configuration: widget.configuration,
                ),
                SizedBox(height: 14),
                _TriggerSimulationPanel(
                  triggers: widget.procedure.triggers,
                  selectedTrigger: _selectedTrigger,
                  onSelected: (ProcedureTrigger trigger) {
                    setState(() => _selectedTrigger = trigger);
                  },
                ),
                SizedBox(height: 14),
                AnimatedSwitcher(
                  duration:
                      reduceMotion
                          ? Duration.zero
                          : Duration(milliseconds: 220),
                  child:
                      _showSummary
                          ? OperationalProcedureExecutionSummary(
                            key: ValueKey<String>('summary'),
                            completed: _completedCount,
                            total: _totalItems,
                            optionalPending: _optionalPendingCount,
                            onReview: () {
                              setState(() => _showSummary = false);
                            },
                            onClose: _closeCompleted,
                            title:
                                widget.configuration.isOperational
                                    ? context.t(
                                      'procedimentos.operationalSummaryTitle',
                                      fallback: 'Procedimento concluído',
                                    )
                                    : null,
                            message:
                                widget.configuration.isOperational
                                    ? context.t(
                                      'procedimentos.operationalNoDataSaved',
                                      fallback:
                                          'Nenhuma resposta foi salva nesta integração local experimental.',
                                    )
                                    : null,
                            closeLabel:
                                widget.configuration.isOperational
                                    ? context.t(
                                      'procedimentos.completeAndStartSale',
                                      fallback: 'Concluir e iniciar venda',
                                    )
                                    : null,
                            badgeLabel:
                                widget.configuration.isOperational
                                    ? context.t(
                                      'procedimentos.experimentalIntegration',
                                      fallback: 'Integração experimental',
                                    )
                                    : null,
                          )
                          : _buildExecution(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExecution() {
    if (widget.procedure.stages.isEmpty) {
      return _PreviewCard(
        child: Text(
          context.t(
            'procedimentos.previewIncompleteProcedure',
            fallback:
                'Este procedimento ainda não possui etapas para demonstrar.',
          ),
          style: TextStyle(color: SixMobilePalette.mutedText, height: 1.35),
        ),
      );
    }

    final ProcedureStage stage =
        widget.procedure.stages[_execution.currentStageIndex];
    final ProcedureExecutionValidation validation = _procedureValidation;
    final String stageProgress = OperationalProcedureI18n.stageProgress(
      context,
      _execution.currentStageIndex + 1,
      widget.procedure.stages.length,
    );

    return _PreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          OperationalProcedureExecutionProgress(
            completedActions: validation.answeredItems,
            totalActions: validation.totalItems,
            label: OperationalProcedureI18n.actionsCompleted(
              context,
              validation.answeredItems,
              validation.totalItems,
            ),
          ),
          SizedBox(height: 16),
          Text(
            stageProgress,
            style: TextStyle(
              color: SixMobilePalette.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            stage.title,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (stage.description.trim().isNotEmpty) ...<Widget>[
            SizedBox(height: 6),
            Text(
              stage.description,
              style: TextStyle(color: SixMobilePalette.mutedText, height: 1.35),
            ),
          ],
          if (_pendingItemIds.isNotEmpty) ...<Widget>[
            SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                context.t(
                  'procedimentos.previewPendingMessage',
                  fallback: 'Existem ações obrigatórias pendentes nesta etapa.',
                ),
                style: TextStyle(
                  color: SixMobilePalette.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          SizedBox(height: 14),
          ...stage.items.map((ProcedureItem item) {
            return OperationalProcedureExecutionItem(
              item: item,
              response: _execution.responses[item.id],
              pending: _pendingItemIds.contains(item.id),
              onChanged: _updateResponse,
            );
          }),
          SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _execution.currentStageIndex == 0
                          ? null
                          : () => setState(() {
                            _pendingItemIds.clear();
                            _execution = _execution.copyWith(
                              currentStageIndex:
                                  _execution.currentStageIndex - 1,
                            );
                          }),
                  icon: Icon(Icons.arrow_back_rounded),
                  label: Text(context.t('common.back', fallback: 'Voltar')),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _goNext,
                  icon: Icon(
                    _isLastStage
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    _isLastStage
                        ? context.t(
                          'procedimentos.previewFinishDemo',
                          fallback: 'Finalizar',
                        )
                        : context.t(
                          'procedimentos.previewNextStage',
                          fallback: 'Próxima etapa',
                        ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.configuration.isOperational &&
              _executionRules.canSkip(
                widget.configuration.enforcementMode,
              )) ...<Widget>[
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _skipOperationalProcedure,
                child: Text(_skipLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateResponse(ProcedureItemResponse response) {
    setState(() {
      final Map<String, ProcedureItemResponse> responses =
          Map<String, ProcedureItemResponse>.of(_execution.responses);
      responses[response.itemId] = response;
      _pendingItemIds.remove(response.itemId);
      _execution = _execution.copyWith(responses: responses);
    });
  }

  void _goNext() {
    final ProcedureStage stage =
        widget.procedure.stages[_execution.currentStageIndex];
    final ProcedureExecutionValidation validation = _executionRules
        .validateStage(
          stage: stage,
          responses: _execution.responses,
          enforcementMode: widget.configuration.enforcementMode,
        );
    if (!validation.canComplete) {
      setState(
        () =>
            _pendingItemIds
              ..clear()
              ..addAll(validation.pendingItemIds),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'procedimentos.previewPendingMessage',
              fallback: 'Existem ações obrigatórias pendentes nesta etapa.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _pendingItemIds.clear();
      if (_isLastStage) {
        _execution = _execution.copyWith(completedAt: DateTime.now());
        _showSummary = true;
      } else {
        _execution = _execution.copyWith(
          currentStageIndex: _execution.currentStageIndex + 1,
        );
      }
    });
  }

  void _closeCompleted() {
    if (!widget.configuration.isOperational) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(
      ProcedureFlowResult.continueOperation(
        completedProcedureIds: <String>[widget.procedure.id],
      ),
    );
  }

  String get _skipLabel {
    if (widget.configuration.enforcementMode ==
        ProcedureEnforcementMode.informative) {
      return context.t(
        'procedimentos.continueToStartSale',
        fallback: 'Continuar para a venda',
      );
    }
    return context.t(
      'procedimentos.continueWithoutCompleting',
      fallback: 'Continuar sem concluir',
    );
  }

  Future<void> _skipOperationalProcedure() async {
    if (widget.configuration.enforcementMode ==
        ProcedureEnforcementMode.recommended) {
      final bool confirmed = await _confirmRecommendedSkip();
      if (!confirmed || !mounted) return;
      Navigator.of(context).pop(
        ProcedureFlowResult.skipped(
          skippedProcedureIds: <String>[widget.procedure.id],
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      ProcedureFlowResult.continueOperation(
        completedProcedureIds: <String>[widget.procedure.id],
      ),
    );
  }

  Future<void> _handleOperationalExit() async {
    if (widget.configuration.enforcementMode ==
        ProcedureEnforcementMode.required) {
      final bool cancelSale = await _confirmRequiredCancellation();
      if (!cancelSale || !mounted) return;
      Navigator.of(context).pop(ProcedureFlowResult.cancelled());
      return;
    }

    if (widget.configuration.enforcementMode ==
        ProcedureEnforcementMode.recommended) {
      final bool confirmed = await _confirmRecommendedSkip();
      if (!confirmed || !mounted) return;
      Navigator.of(context).pop(
        ProcedureFlowResult.skipped(
          skippedProcedureIds: <String>[widget.procedure.id],
        ),
      );
      return;
    }

    Navigator.of(context).pop(ProcedureFlowResult.continueOperation());
  }

  Future<bool> _confirmRecommendedSkip() async {
    return await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder:
              (_) => _DiscardPreviewSheet(
                title: context.t(
                  'procedimentos.continueWithoutCompletingTitle',
                  fallback: 'Continuar sem concluir?',
                ),
                message: context.t(
                  'procedimentos.continueWithoutCompletingMessage',
                  fallback:
                      'Este procedimento é recomendado antes de iniciar a venda.',
                ),
                confirmLabel: context.t(
                  'procedimentos.continueAnyway',
                  fallback: 'Continuar mesmo assim',
                ),
                cancelLabel: context.t(
                  'procedimentos.returnToProcedure',
                  fallback: 'Voltar ao procedimento',
                ),
              ),
        ) ??
        false;
  }

  Future<bool> _confirmRequiredCancellation() async {
    return await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder:
              (_) => _DiscardPreviewSheet(
                title: context.t(
                  'procedimentos.cancelSaleStartTitle',
                  fallback: 'Cancelar início da venda?',
                ),
                message: context.t(
                  'procedimentos.cancelSaleStartMessage',
                  fallback:
                      'Este procedimento é obrigatório. Ao sair, a nova venda não será iniciada.',
                ),
                confirmLabel: context.t(
                  'procedimentos.cancelSale',
                  fallback: 'Cancelar venda',
                ),
                cancelLabel: context.t(
                  'procedimentos.returnToProcedure',
                  fallback: 'Continuar procedimento',
                ),
              ),
        ) ??
        false;
  }

  ProcedureExecutionValidation get _procedureValidation {
    return _executionRules.validateProcedure(
      procedure: widget.procedure,
      execution: _execution,
      enforcementMode: widget.configuration.enforcementMode,
    );
  }

  int get _totalItems => _procedureValidation.totalItems;

  int get _completedCount => _procedureValidation.answeredItems;

  int get _optionalPendingCount {
    return widget.procedure.stages.fold<int>(0, (
      int total,
      ProcedureStage stage,
    ) {
      return total +
          stage.items.where((ProcedureItem item) {
            return !item.required &&
                !_executionRules.isItemAnswered(
                  item: item,
                  response: _execution.responses[item.id],
                );
          }).length;
    });
  }

  bool get _isLastStage {
    return _execution.currentStageIndex >= widget.procedure.stages.length - 1;
  }

  Future<bool> _confirmDiscardResponses() async {
    return await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder:
              (_) => _DiscardPreviewSheet(
                title: context.t(
                  'procedimentos.previewDiscardTitle',
                  fallback: 'Descartar respostas?',
                ),
                message: context.t(
                  'procedimentos.previewDiscardMessage',
                  fallback:
                      'As respostas desta demonstração serão descartadas ao sair.',
                ),
              ),
        ) ??
        false;
  }
}

class _TriggerSimulationPanel extends StatelessWidget {
  const _TriggerSimulationPanel({
    required this.triggers,
    required this.selectedTrigger,
    required this.onSelected,
  });

  final List<ProcedureTrigger> triggers;
  final ProcedureTrigger? selectedTrigger;
  final ValueChanged<ProcedureTrigger> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<ProcedureTrigger> enabled =
        triggers.where((ProcedureTrigger trigger) => trigger.enabled).toList();
    final ProcedureTrigger? current =
        selectedTrigger ?? (enabled.isNotEmpty ? enabled.first : null);

    return _PreviewCard(
      child: Semantics(
        container: true,
        label: context.t(
          'procedimentos.executionConfiguration',
          fallback: 'Configuração de execução',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.t(
                'procedimentos.executionConfiguration',
                fallback: 'Configuração de execução',
              ),
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            if (current == null)
              Text(
                context.t(
                  'procedimentos.manualDemoExecution',
                  fallback: 'Execução manual de demonstração.',
                ),
                style: TextStyle(
                  color: SixMobilePalette.titleText,
                  fontWeight: FontWeight.w800,
                ),
              )
            else ...<Widget>[
              _TriggerPreviewLine(trigger: current),
              if (enabled.length > 1) ...<Widget>[
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      enabled.map((ProcedureTrigger trigger) {
                        final bool selected = trigger.id == current.id;
                        return ChoiceChip(
                          label: Text(
                            '${operationTypeLabel(context, trigger.operationType)} • '
                            '${triggerMomentLabel(context, trigger.triggerMoment)}',
                          ),
                          selected: selected,
                          onSelected: (_) => onSelected(trigger),
                        );
                      }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TriggerPreviewLine extends StatelessWidget {
  const _TriggerPreviewLine({required this.trigger});

  final ProcedureTrigger trigger;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: triggerSemanticsLabel(context, trigger),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            operationTypeLabel(context, trigger.operationType),
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            triggerMomentLabel(context, trigger.triggerMoment),
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 3),
          Text(
            '${activationModeLabel(context, trigger.activationMode)} • '
            '${enforcementModeLabel(context, trigger.enforcementMode)} • '
            '${triggerStatusLabel(context, trigger.enabled)}',
            style: TextStyle(
              color: SixMobilePalette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.procedure, required this.configuration});

  final OperationalProcedure procedure;
  final ProcedureExecutionConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: procedure.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          OperationalProcedureDemoBadge(
            label: context.t(
              configuration.isOperational
                  ? 'procedimentos.experimentalIntegration'
                  : 'procedimentos.demoData',
              fallback:
                  configuration.isOperational
                      ? 'Integração experimental'
                      : 'Dados demonstrativos',
            ),
          ),
          if (configuration.isOperational) ...<Widget>[
            SizedBox(height: 8),
            Text(
              OperationalProcedureI18n.procedureSequence(
                context,
                configuration.procedureIndex,
                configuration.totalProcedures,
              ),
              style: TextStyle(
                color: SixMobilePalette.heroSupportingText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          SizedBox(height: 10),
          Text(
            procedure.name.trim().isEmpty
                ? context.t(
                  'procedimentos.previewUntitledProcedure',
                  fallback: 'Procedimento sem nome',
                )
                : procedure.name,
            style: TextStyle(
              color: SixMobilePalette.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          if (procedure.description.trim().isNotEmpty) ...<Widget>[
            SizedBox(height: 8),
            Text(
              procedure.description,
              style: TextStyle(
                color: SixMobilePalette.heroSupportingText,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DiscardPreviewSheet extends StatelessWidget {
  const _DiscardPreviewSheet({
    required this.title,
    required this.message,
    this.cancelLabel,
    this.confirmLabel,
  });

  final String title;
  final String message;
  final String? cancelLabel;
  final String? confirmLabel;

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
            title,
            style: TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: SixMobilePalette.mutedText, height: 1.35),
          ),
          SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelLabel ??
                        context.t(
                          'procedimentos.keepEditing',
                          fallback: 'Continuar editando',
                        ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    confirmLabel ??
                        context.t(
                          'procedimentos.discard',
                          fallback: 'Descartar',
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
}
