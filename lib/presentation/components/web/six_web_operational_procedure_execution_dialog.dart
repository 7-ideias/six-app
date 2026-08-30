import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/data/models/operational_procedure_flow_models.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_response_type_metadata.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

typedef SixWebOperationalProcedureSubmit =
    Future<ProcedureFlowResult> Function(
      OperationalProcedureExecutionSubmission submission,
    );

class OperationalProcedureExecutionSubmission {
  const OperationalProcedureExecutionSubmission({
    required this.execution,
    required this.status,
  });

  final ProcedureExecutionDraft execution;
  final String status;
}

Future<ProcedureFlowResult?> showSixWebOperationalProcedureExecutionDialog({
  required BuildContext context,
  required OperationalProcedure procedure,
  required ProcedureExecutionConfiguration configuration,
  required SixWebOperationalProcedureSubmit onSubmit,
}) {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return showGeneralDialog<ProcedureFlowResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _OperationalProcedureRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: SixWebOperationalProcedureExecutionDialog(
          procedure: procedure,
          configuration: configuration,
          onSubmit: onSubmit,
        ),
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => child,
  );
}

class SixWebOperationalProcedureExecutionDialog extends StatefulWidget {
  const SixWebOperationalProcedureExecutionDialog({
    super.key,
    required this.procedure,
    required this.configuration,
    required this.onSubmit,
  });

  final OperationalProcedure procedure;
  final ProcedureExecutionConfiguration configuration;
  final SixWebOperationalProcedureSubmit onSubmit;

  @override
  State<SixWebOperationalProcedureExecutionDialog> createState() =>
      _SixWebOperationalProcedureExecutionDialogState();
}

enum _OperationalProcedureDialogState { review, processing, success, error }

enum _SubmissionAction { complete, skip, cancel }

class _SixWebOperationalProcedureExecutionDialogState
    extends State<SixWebOperationalProcedureExecutionDialog>
    with SingleTickerProviderStateMixin {
  late ProcedureExecutionDraft _execution;
  late final AnimationController _iconController;
  int _stageIndex = 0;
  final Set<String> _pending = <String>{};
  _OperationalProcedureDialogState _state =
      _OperationalProcedureDialogState.review;
  _SubmissionAction _lastAction = _SubmissionAction.complete;

  bool get _isBusy =>
      _state == _OperationalProcedureDialogState.processing ||
      _state == _OperationalProcedureDialogState.success;

  bool get _canDismiss => !_isBusy;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  ProcedureStage get _currentStage => widget.procedure.stages[_stageIndex];

  int get _totalItems => widget.procedure.numberOfItems;

  int get _answeredCount =>
      _execution.responses.values
          .where((ProcedureItemResponse response) => response.completed)
          .length;

  int get _requiredPendingCount =>
      widget.procedure.stages
          .expand((ProcedureStage stage) => stage.items)
          .where((ProcedureItem item) => item.required)
          .where((ProcedureItem item) => _isItemPending(item))
          .length;

  @override
  void initState() {
    super.initState();
    _execution = ProcedureExecutionDraft(
      procedureId: widget.procedure.id,
      currentStageIndex: 0,
      responses: const <String, ProcedureItemResponse>{},
      startedAt: DateTime.now(),
    );
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _iconController.value = 1;
      } else {
        _iconController.forward();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = _accentColor(tokens, theme);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (DismissIntent intent) {
              if (_canDismiss) {
                _dismissFromShortcut();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: PopScope(
            canPop: _canDismiss,
            child: Semantics(
              namesRoute: true,
              label: widget.procedure.name,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 680,
                  maxHeight: 760,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.34),
                        blurRadius: 46,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: tokens.surfaceElevated,
                      surfaceTintColor: Colors.transparent,
                      child: Stack(
                        children: <Widget>[
                          AnimatedSwitcher(
                            duration: Duration(
                              milliseconds: _reduceMotion ? 1 : 240,
                            ),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child:
                                _state ==
                                        _OperationalProcedureDialogState.success
                                    ? _buildSuccess(theme, tokens)
                                    : SizedBox(
                                      key: const ValueKey<String>(
                                        'operational-procedure-review',
                                      ),
                                      width: 680,
                                      height: 760,
                                      child: Column(
                                        children: <Widget>[
                                          _buildHeader(theme, tokens, accent),
                                          Flexible(
                                            child: SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    24,
                                                    20,
                                                    24,
                                                    16,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  _buildExecutionSummary(
                                                    theme,
                                                    tokens,
                                                  ),
                                                  const SizedBox(height: 18),
                                                  _buildStageSection(
                                                    theme,
                                                    tokens,
                                                  ),
                                                  if (_state ==
                                                      _OperationalProcedureDialogState
                                                          .error) ...<Widget>[
                                                    const SizedBox(height: 16),
                                                    _buildErrorBanner(
                                                      theme,
                                                      tokens,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                          _buildFooter(theme, tokens),
                                        ],
                                      ),
                                    ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, WebThemeTokens tokens, Color accent) {
    final String sequenceLabel = OperationalProcedureI18n.procedureSequence(
      context,
      widget.configuration.procedureIndex,
      widget.configuration.totalProcedures,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 22),
      decoration: BoxDecoration(
        color: tokens.selectedBackground.withValues(alpha: 0.86),
        border: Border(bottom: BorderSide(color: tokens.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _OperationalProcedureImpactIcon(
                animation: _iconController,
                accent: accent,
                surfaceColor: tokens.surfaceElevated,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'procedimentos.operationalBadge',
                        'Procedimento operacional',
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.procedure.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.procedure.description.trim().isNotEmpty
                          ? widget.procedure.description
                          : _txt(
                            'procedimentos.executionWillBeSaved',
                            'As respostas e o horário serão salvos ao concluir.',
                          ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _txt('common.close', 'Fechar'),
                onPressed: _canDismiss ? _exit : null,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _SummaryPill(
                icon: Icons.layers_outlined,
                label: _txt(
                  'procedimentos.sequenceProgressPrefix',
                  'Procedimento',
                ),
                value: sequenceLabel,
                variant: _SummaryPillVariant.info,
              ),
              _SummaryPill(
                icon: Icons.list_alt_rounded,
                label: _txt('procedimentos.stages', 'Etapas'),
                value: OperationalProcedureI18n.stageProgress(
                  context,
                  _stageIndex + 1,
                  widget.procedure.stages.length,
                ),
                variant: _SummaryPillVariant.neutral,
              ),
              _SummaryPill(
                icon: Icons.playlist_add_check_circle_outlined,
                label: _txt('procedimentos.items', 'Itens'),
                value: OperationalProcedureI18n.actionsCompleted(
                  context,
                  _answeredCount,
                  _totalItems,
                ),
                variant: _SummaryPillVariant.highlight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionSummary(ThemeData theme, WebThemeTokens tokens) {
    final List<_OperationalSummaryItem> items = <_OperationalSummaryItem>[
      _OperationalSummaryItem(
        icon: Icons.pending_actions_rounded,
        label: _txt('procedimentos.items', 'Itens'),
        value: OperationalProcedureI18n.answeredActionsSummary(
          context,
          _answeredCount,
          _totalItems,
        ),
      ),
      _OperationalSummaryItem(
        icon: Icons.report_gmailerrorred_rounded,
        label: _txt('common.required', 'Obrigatório'),
        value: OperationalProcedureI18n.requiredPendingSummary(
          context,
          _requiredPendingCount,
        ),
      ),
      _OperationalSummaryItem(
        icon: Icons.schedule_rounded,
        label: _txt(
          'procedimentos.executionConfiguration',
          'Configuração de execução',
        ),
        value: _txt(
          'procedimentos.executionWillBeSaved',
          'As respostas e o horário serão salvos ao concluir.',
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 660;
          if (compact) {
            return Column(
              children: <Widget>[
                for (int index = 0; index < items.length; index++) ...<Widget>[
                  _buildSummaryItem(theme, tokens, items[index]),
                  if (index < items.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: tokens.divider),
                    ),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < items.length; index++) ...<Widget>[
                Expanded(child: _buildSummaryItem(theme, tokens, items[index])),
                if (index < items.length - 1)
                  Container(
                    width: 1,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: tokens.divider,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    WebThemeTokens tokens,
    _OperationalSummaryItem item,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: tokens.info, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStageSection(ThemeData theme, WebThemeTokens tokens) {
    final ProcedureStage stage = _currentStage;
    final String stageLabel = OperationalProcedureI18n.stageProgress(
      context,
      _stageIndex + 1,
      widget.procedure.stages.length,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            stageLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stage.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (stage.description.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              stage.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.secondaryText,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...stage.items.map(
            (ProcedureItem item) => _buildItemCard(theme, tokens, item),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    ThemeData theme,
    WebThemeTokens tokens,
    ProcedureItem item,
  ) {
    final ProcedureItemResponse? response = _execution.responses[item.id];
    final bool pending = _pending.contains(item.id);
    final String requiredLabel =
        item.required
            ? _txt('common.required', 'Obrigatório')
            : _txt('common.optional', 'Opcional');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            pending
                ? tokens.danger.withValues(alpha: 0.06)
                : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              pending
                  ? tokens.danger.withValues(alpha: 0.40)
                  : tokens.cardBorder,
        ),
      ),
      child: Semantics(
        label: OperationalProcedureI18n.executionItemSemantics(
          context,
          requiredLabel: requiredLabel,
          title: item.title,
          type: responseTypeLabel(context, item.responseType),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _chip(
                  theme: theme,
                  tokens: tokens,
                  icon: responseTypeIcon(item.responseType),
                  label: responseTypeLabel(context, item.responseType),
                  background: tokens.surface,
                  foreground: tokens.info,
                ),
                _chip(
                  theme: theme,
                  tokens: tokens,
                  icon:
                      item.required
                          ? Icons.error_outline_rounded
                          : Icons.low_priority_rounded,
                  label: requiredLabel,
                  background:
                      item.required
                          ? tokens.warning.withValues(alpha: 0.12)
                          : tokens.surface,
                  foreground:
                      item.required ? tokens.warning : tokens.secondaryText,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (item.guidance.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                item.guidance,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _buildInput(item, response, theme, tokens),
            if (pending) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _txt('procedimentos.requiredAnswer', 'Resposta obrigatória.'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required ThemeData theme,
    required WebThemeTokens tokens,
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    ProcedureItem item,
    ProcedureItemResponse? response,
    ThemeData theme,
    WebThemeTokens tokens,
  ) {
    if (item.responseType == ProcedureResponseType.yesNo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: true,
                label: Text(_txt('common.yes', 'Sim')),
                icon: const Icon(Icons.check_rounded),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text(_txt('common.no', 'Não')),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
            selected:
                response?.boolValue == null
                    ? <bool>{}
                    : <bool>{response!.boolValue!},
            emptySelectionAllowed: true,
            onSelectionChanged: (Set<bool> values) {
              if (values.isEmpty || _isBusy) return;
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
              enabled: !_isBusy,
              decoration: InputDecoration(
                labelText: _txt(
                  'procedimentos.negativeReason',
                  'O que faltou?',
                ),
                filled: true,
                fillColor: tokens.surface,
                border: const OutlineInputBorder(),
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
        enabled: !_isBusy,
        decoration: InputDecoration(
          hintText: item.configuration.placeholder,
          filled: true,
          fillColor: tokens.surface,
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
        enabled: !_isBusy,
        decoration: InputDecoration(
          filled: true,
          fillColor: tokens.surface,
          border: const OutlineInputBorder(),
        ),
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
                onSelected:
                    _isBusy
                        ? null
                        : (bool value) {
                          final List<String> selectedOptions = List<String>.of(
                            response?.selectedOptions ?? const <String>[],
                          );
                          if (item.responseType ==
                              ProcedureResponseType.singleChoice) {
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
        _txt('procedimentos.confirmAction', 'Confirmar ação realizada'),
      ),
      onChanged:
          _isBusy
              ? null
              : (bool? value) {
                _update(
                  item,
                  (response ?? _emptyResponse(item)).copyWith(
                    completed: value == true,
                  ),
                );
              },
    );
  }

  Widget _buildErrorBanner(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded, color: tokens.danger),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _txt(
                'procedimentos.executionSaveError',
                'Não foi possível salvar as respostas. Tente novamente.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, WebThemeTokens tokens) {
    final bool last = _stageIndex == widget.procedure.stages.length - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 660;
          final List<Widget> secondaryActions = <Widget>[
            if (widget.configuration.allowSkip)
              TextButton(
                onPressed: _isBusy ? null : _skip,
                child: Text(
                  _txt(
                    'procedimentos.continueWithoutCompleting',
                    'Continuar sem concluir',
                  ),
                ),
              ),
            if (widget.configuration.allowSkip) const SizedBox(width: 12),
            OutlinedButton(
              onPressed:
                  _isBusy || _stageIndex == 0
                      ? null
                      : () => _setStage(_stageIndex - 1),
              child: Text(_txt('common.back', 'Voltar')),
            ),
          ];
          final Widget primaryAction = FilledButton.icon(
            onPressed: _isBusy ? null : _next,
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: _reduceMotion ? 1 : 160),
              child:
                  _state == _OperationalProcedureDialogState.processing
                      ? const SizedBox(
                        key: ValueKey<String>('operational-procedure-progress'),
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(
                        last
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        key: ValueKey<bool>(last),
                      ),
            ),
            label: AnimatedSwitcher(
              duration: Duration(milliseconds: _reduceMotion ? 1 : 160),
              child: Text(
                _state == _OperationalProcedureDialogState.processing
                    ? _processingLabel()
                    : last
                    ? _txt('common.finish', 'Concluir')
                    : _txt('common.continueLabel', 'Continuar'),
                key: ValueKey<String>(
                  _state == _OperationalProcedureDialogState.processing
                      ? _processingLabel()
                      : last
                      ? 'finish'
                      : 'continue',
                ),
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: secondaryActions,
                ),
                const SizedBox(height: 14),
                primaryAction,
              ],
            );
          }

          return Row(
            children: <Widget>[
              ...secondaryActions,
              const Spacer(),
              primaryAction,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme, WebThemeTokens tokens) {
    return Padding(
      key: const ValueKey<String>('operational-procedure-success'),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: _reduceMotion ? 1 : 360),
            curve: Curves.easeOutBack,
            tween: Tween<double>(begin: 0.72, end: 1),
            builder:
                (BuildContext context, double scale, Widget? child) =>
                    Transform.scale(scale: scale, child: child),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: tokens.success.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: tokens.success, size: 42),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _successTitle(),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _successMessage(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  void _update(ProcedureItem item, ProcedureItemResponse response) {
    setState(() {
      final Map<String, ProcedureItemResponse> responses =
          Map<String, ProcedureItemResponse>.of(_execution.responses);
      responses[item.id] = response;
      _execution = _execution.copyWith(
        responses: responses,
        currentStageIndex: _stageIndex,
      );
      _pending.remove(item.id);
      if (_state == _OperationalProcedureDialogState.error) {
        _state = _OperationalProcedureDialogState.review;
      }
    });
  }

  void _setStage(int index) {
    setState(() {
      _stageIndex = index;
      _execution = _execution.copyWith(currentStageIndex: index);
      _pending.clear();
      if (_state == _OperationalProcedureDialogState.error) {
        _state = _OperationalProcedureDialogState.review;
      }
    });
  }

  ProcedureItemResponse _emptyResponse(ProcedureItem item) {
    return ProcedureItemResponse(
      itemId: item.id,
      responseType: item.responseType,
      updatedAt: DateTime.now(),
    );
  }

  bool _isItemPending(ProcedureItem item) {
    final ProcedureItemResponse? response = _execution.responses[item.id];
    if (response == null || !response.completed) {
      return true;
    }
    return item.responseType == ProcedureResponseType.yesNo &&
        item.configuration.requireTextWhenNo &&
        response.boolValue == false &&
        response.textValue.trim().isEmpty;
  }

  Future<void> _next() async {
    if (_isBusy) return;
    final Set<String> pending =
        _currentStage.items
            .where(
              (ProcedureItem item) => item.required && _isItemPending(item),
            )
            .map((ProcedureItem item) => item.id)
            .toSet();
    if (pending.isNotEmpty) {
      setState(() => _pending.addAll(pending));
      return;
    }
    if (_stageIndex < widget.procedure.stages.length - 1) {
      _setStage(_stageIndex + 1);
      return;
    }
    await _submit(_SubmissionAction.complete, 'CONCLUIDO');
  }

  Future<void> _skip() async {
    if (_isBusy) return;
    await _submit(_SubmissionAction.skip, 'IGNORADO');
  }

  Future<void> _exit() async {
    if (_isBusy) return;
    if (widget.configuration.enforcementMode ==
        ProcedureEnforcementMode.required) {
      await _submit(_SubmissionAction.cancel, 'CANCELADO');
      return;
    }
    await _skip();
  }

  void _dismissFromShortcut() {
    if (widget.configuration.enforcementMode ==
        ProcedureEnforcementMode.required) {
      _exit();
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _submit(_SubmissionAction action, String status) async {
    if (_isBusy) return;
    setState(() {
      _lastAction = action;
      _state = _OperationalProcedureDialogState.processing;
    });

    try {
      final ProcedureFlowResult result = await widget.onSubmit(
        OperationalProcedureExecutionSubmission(
          execution: _execution.copyWith(
            currentStageIndex: _stageIndex,
            completedAt: DateTime.now(),
          ),
          status: status,
        ),
      );
      if (!mounted) return;
      setState(() => _state = _OperationalProcedureDialogState.success);
      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 300 : 780),
      );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _OperationalProcedureDialogState.error);
    }
  }

  String _processingLabel() {
    return switch (_lastAction) {
      _SubmissionAction.complete => _txt('common.saving', 'Salvando...'),
      _SubmissionAction.skip => _txt(
        'procedimentos.processingSkip',
        'Continuando...',
      ),
      _SubmissionAction.cancel => _txt(
        'procedimentos.processingCancel',
        'Cancelando...',
      ),
    };
  }

  String _successTitle() {
    return switch (_lastAction) {
      _SubmissionAction.complete => _txt(
        'procedimentos.operationalSummaryTitle',
        'Procedimento concluído',
      ),
      _SubmissionAction.skip => _txt(
        'procedimentos.skipSuccessTitle',
        'Procedimento ignorado',
      ),
      _SubmissionAction.cancel => _txt(
        'procedimentos.cancelSuccessTitle',
        'Operação cancelada',
      ),
    };
  }

  String _successMessage() {
    return switch (_lastAction) {
      _SubmissionAction.complete => _txt(
        'procedimentos.completeSuccessMessage',
        'As respostas foram registradas e a operação pode continuar.',
      ),
      _SubmissionAction.skip => _txt(
        'procedimentos.skipSuccessMessage',
        'O procedimento foi ignorado e a operação seguirá conforme a configuração.',
      ),
      _SubmissionAction.cancel => _txt(
        'procedimentos.cancelSuccessMessage',
        'A operação foi encerrada antes de seguir para a próxima etapa.',
      ),
    };
  }

  Color _accentColor(WebThemeTokens tokens, ThemeData theme) {
    return switch (_state) {
      _OperationalProcedureDialogState.review ||
      _OperationalProcedureDialogState.processing =>
        theme.brightness == Brightness.dark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFF59E0B),
      _OperationalProcedureDialogState.success => tokens.success,
      _OperationalProcedureDialogState.error => tokens.danger,
    };
  }
}

class _OperationalProcedureRouteSurface extends StatelessWidget {
  const _OperationalProcedureRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? dialogChild) {
        final double progress =
            reduceMotion ? 1 : Curves.easeOutCubic.transform(animation.value);
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 12 * progress,
                  sigmaY: 12 * progress,
                ),
                child: ColoredBox(
                  color: const Color(
                    0xFF0B1324,
                  ).withValues(alpha: 0.72 * progress),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - progress)),
                        child: Transform.scale(
                          scale: 0.96 + (0.04 * progress),
                          child: dialogChild,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OperationalProcedureImpactIcon extends StatelessWidget {
  const _OperationalProcedureImpactIcon({
    required this.animation,
    required this.accent,
    required this.surfaceColor,
  });

  final Animation<double> animation;
  final Color accent;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double pulse = Curves.easeOutCubic.transform(
          const Interval(0, 0.74).transform(animation.value),
        );
        final double badgeScale = Curves.easeOutBack.transform(
          const Interval(0.36, 1).transform(animation.value),
        );
        return SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Opacity(
                opacity: (1 - pulse) * 0.30,
                child: Transform.scale(
                  scale: 0.86 + (pulse * 0.52),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                    ),
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.fact_check_rounded, color: accent, size: 29),
              ),
              Positioned(
                right: 0,
                bottom: 1,
                child: Transform.scale(
                  scale: badgeScale,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _SummaryPillVariant { info, neutral, highlight }

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.variant,
  });

  final IconData icon;
  final String label;
  final String value;
  final _SummaryPillVariant variant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ({Color background, Color foreground, Color border}) palette =
        switch (variant) {
          _SummaryPillVariant.info => (
            background: tokens.info.withValues(alpha: 0.10),
            foreground: tokens.info,
            border: tokens.info.withValues(alpha: 0.20),
          ),
          _SummaryPillVariant.neutral => (
            background: tokens.surface.withValues(alpha: 0.82),
            foreground: tokens.secondaryText,
            border: tokens.cardBorder,
          ),
          _SummaryPillVariant.highlight => (
            background: tokens.success.withValues(alpha: 0.12),
            foreground: tokens.success,
            border: tokens.success.withValues(alpha: 0.18),
          ),
        };

    return Container(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: palette.foreground),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WebThemeTokens.of(context).primaryText,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalSummaryItem {
  const _OperationalSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
