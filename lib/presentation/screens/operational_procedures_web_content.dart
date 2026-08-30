import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/data/models/operational_procedure_persistence_models.dart';
import 'package:sixpos/data/services/operational_procedures/operational_procedure_api_client.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class OperationalProceduresWebContent extends StatefulWidget {
  const OperationalProceduresWebContent({super.key});

  @override
  State<OperationalProceduresWebContent> createState() =>
      _OperationalProceduresWebContentState();
}

class _OperationalProceduresWebContentState
    extends State<OperationalProceduresWebContent> {
  final HttpOperationalProcedureApiClient _api =
      HttpOperationalProcedureApiClient();
  List<OperationalProcedure> _procedures = const <OperationalProcedure>[];
  OperationalProcedureAnalytics? _analytics;
  bool _loading = true;
  bool _saving = false;
  bool _showAnalytics = false;
  Object? _error;

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _api.fetchProcedures(idioma: _locale),
        OperationalProcedureService(
          apiClient: _api,
          localeTag: _locale,
        ).fetchAnalytics(),
      ]);
      if (!mounted) return;
      setState(() {
        _procedures = (results[0] as OperationalProcedureSummary).procedures;
        _analytics = results[1] as OperationalProcedureAnalytics;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(64),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return SixWebSectionCard(
        title: context.t('common.error', fallback: 'Erro'),
        icon: Icons.error_outline_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.t(
                'procedimentos.loadError',
                fallback: 'Não foi possível carregar os procedimentos.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                context.t('common.retry', fallback: 'Tentar novamente'),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SixWebDashboardHeader(
          icon: Icons.fact_check_outlined,
          title: context.t('procedimentos.title', fallback: 'Procedimentos'),
          subtitle: context.t(
            'procedimentos.webSubtitle',
            fallback:
                'Configure orientações operacionais e acompanhe os resultados persistidos.',
          ),
          actions: <Widget>[
            SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(
                    context.t(
                      'procedimentos.configurations',
                      fallback: 'Configurações',
                    ),
                  ),
                ),
                ButtonSegment<bool>(
                  value: true,
                  icon: const Icon(Icons.insights_rounded),
                  label: Text(
                    context.t(
                      'procedimentos.analyticsTitle',
                      fallback: 'Análise',
                    ),
                  ),
                ),
              ],
              selected: <bool>{_showAnalytics},
              onSelectionChanged: (Set<bool> value) {
                setState(() => _showAnalytics = value.first);
              },
            ),
            if (!_showAnalytics)
              FilledButton.icon(
                onPressed: _saving ? null : () => _edit(null),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  context.t(
                    'procedimentos.newProcedure',
                    fallback: 'Novo procedimento',
                  ),
                ),
              ),
            IconButton.filledTonal(
              onPressed: _loading ? null : _load,
              tooltip: context.t('common.refresh', fallback: 'Atualizar'),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_showAnalytics)
          _AnalyticsWeb(analytics: _analytics)
        else
          _ConfigurationsWeb(
            procedures: _procedures,
            saving: _saving,
            onEdit: _edit,
            onToggle: _toggle,
          ),
      ],
    );
  }

  Future<void> _edit(OperationalProcedure? procedure) async {
    final OperationalProcedure? result = await showDialog<OperationalProcedure>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ProcedureWebEditor(procedure: procedure, localeTag: _locale),
    );
    if (result == null || !mounted) return;
    await _save(result, procedure == null);
  }

  Future<void> _toggle(OperationalProcedure procedure, bool enabled) async {
    await _save(
      procedure.copyWith(
        status: enabled ? ProcedureStatus.active : ProcedureStatus.inactive,
      ),
      false,
    );
  }

  Future<void> _save(OperationalProcedure procedure, bool creating) async {
    setState(() => _saving = true);
    try {
      await _api.saveProcedure(
        procedure: procedure,
        idioma: _locale,
        isCreating: creating,
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'procedimentos.saveError',
              fallback: 'Não foi possível salvar o procedimento.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ConfigurationsWeb extends StatelessWidget {
  const _ConfigurationsWeb({
    required this.procedures,
    required this.saving,
    required this.onEdit,
    required this.onToggle,
  });

  final List<OperationalProcedure> procedures;
  final bool saving;
  final ValueChanged<OperationalProcedure> onEdit;
  final void Function(OperationalProcedure procedure, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    return SixWebSectionCard(
      title: context.t(
        'procedimentos.configuredProcedures',
        fallback: 'Procedimentos configurados',
      ),
      subtitle: context.t(
        'procedimentos.availableContextsHelp',
        fallback: 'Contextos disponíveis: Venda, Atendimento técnico e Caixa.',
      ),
      icon: Icons.rule_folder_outlined,
      child: procedures.isEmpty
          ? Text(
              context.t(
                'procedimentos.empty',
                fallback: 'Nenhum procedimento configurado.',
              ),
            )
          : Column(
              children: procedures
                  .map((OperationalProcedure procedure) {
                    return _ProcedureRow(
                      procedure: procedure,
                      saving: saving,
                      onEdit: () => onEdit(procedure),
                      onToggle: (bool value) => onToggle(procedure, value),
                    );
                  })
                  .toList(growable: false),
            ),
    );
  }
}

class _ProcedureRow extends StatelessWidget {
  const _ProcedureRow({
    required this.procedure,
    required this.saving,
    required this.onEdit,
    required this.onToggle,
  });

  final OperationalProcedure procedure;
  final bool saving;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.fact_check_outlined, color: tokens.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  procedure.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_contextLabel(context, procedure.operationType)} • '
                  '${procedure.numberOfStages} ${context.t('procedimentos.stagesLower', fallback: 'etapas')} • '
                  '${procedure.numberOfItems} ${context.t('procedimentos.itemsLower', fallback: 'itens')}',
                  style: TextStyle(color: tokens.secondaryText),
                ),
                if (procedure.adminNotification.enabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      context.t(
                        'procedimentos.adminPushEnabled',
                        fallback: 'Push para ADMIN habilitado',
                      ),
                      style: TextStyle(
                        color: tokens.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: procedure.isActive,
            onChanged: saving ? null : onToggle,
          ),
          IconButton(
            tooltip: context.t('common.edit', fallback: 'Editar'),
            onPressed: saving ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsWeb extends StatelessWidget {
  const _AnalyticsWeb({required this.analytics});

  final OperationalProcedureAnalytics? analytics;

  @override
  Widget build(BuildContext context) {
    final OperationalProcedureAnalytics data =
        analytics ??
        const OperationalProcedureAnalytics(
          periodDays: 30,
          totalExecutions: 0,
          completed: 0,
          skipped: 0,
          completionRate: 0,
          negativeResponses: 0,
          averageDurationSeconds: 0,
          sampleLimited: false,
          byContext: <OperationalProcedureContextMetric>[],
          byProcedure: <OperationalProcedureMetric>[],
          byQuestion: <OperationalProcedureQuestionMetric>[],
          recentExecutions: <OperationalProcedureExecutionResult>[],
        );
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    return Column(
      children: <Widget>[
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          childAspectRatio: 2.25,
          children: <Widget>[
            SixWebKpiCard(
              icon: Icons.fact_check_outlined,
              label: context.t(
                'procedimentos.analyticsExecutions',
                fallback: 'Execuções',
              ),
              value: data.totalExecutions.toDouble(),
              formatter: locale.formatInteger,
            ),
            SixWebKpiCard(
              icon: Icons.task_alt_rounded,
              label: context.t(
                'procedimentos.analyticsCompletion',
                fallback: 'Taxa de conclusão',
              ),
              value: data.completionRate,
              formatter: locale.formatPercent,
              highlight: true,
            ),
            SixWebKpiCard(
              icon: Icons.warning_amber_rounded,
              label: context.t(
                'procedimentos.analyticsNegative',
                fallback: 'Respostas negativas',
              ),
              value: data.negativeResponses.toDouble(),
              formatter: locale.formatInteger,
            ),
            SixWebKpiCard(
              icon: Icons.timer_outlined,
              label: context.t(
                'procedimentos.analyticsAverageTime',
                fallback: 'Tempo médio',
              ),
              value: data.averageDurationSeconds,
              formatter: (double value) => '${locale.formatInteger(value)}s',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SixWebSectionCard(
                title: context.t(
                  'procedimentos.analyticsByQuestion',
                  fallback: 'Resultados por pergunta',
                ),
                icon: Icons.quiz_outlined,
                child: _QuestionTable(items: data.byQuestion),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SixWebSectionCard(
                title: context.t(
                  'procedimentos.analyticsRecent',
                  fallback: 'Execuções recentes',
                ),
                icon: Icons.history_rounded,
                child: _RecentTable(
                  items: data.recentExecutions,
                  locale: locale,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestionTable extends StatelessWidget {
  const _QuestionTable({required this.items});
  final List<OperationalProcedureQuestionMetric> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _emptyAnalytics(context);
    return Column(
      children: items
          .take(10)
          .map((item) {
            final double ratio = item.totalAnswers == 0
                ? 0
                : item.negativeAnswers / item.totalAnswers;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.question,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('${item.negativeAnswers}/${item.totalAnswers}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: ratio, minHeight: 7),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _RecentTable extends StatelessWidget {
  const _RecentTable({required this.items, required this.locale});
  final List<OperationalProcedureExecutionResult> items;
  final LocaleSettingsProvider locale;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _emptyAnalytics(context);
    return Column(
      children: items
          .take(10)
          .map((item) {
            final DateTime date = item.startedAt.toLocal();
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item.negativeResponses > 0
                    ? Icons.priority_high_rounded
                    : Icons.check_rounded,
              ),
              title: Text(
                item.procedureName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${locale.formatDate(date)} ${locale.formatTime(date)}',
              ),
              trailing: Text(item.saleId == null ? '—' : '#${item.saleId}'),
            );
          })
          .toList(growable: false),
    );
  }
}

Widget _emptyAnalytics(BuildContext context) {
  return Text(
    context.t(
      'procedimentos.analyticsEmpty',
      fallback: 'Ainda não há execuções neste período.',
    ),
  );
}

class _ProcedureWebEditor extends StatefulWidget {
  const _ProcedureWebEditor({required this.procedure, required this.localeTag});
  final OperationalProcedure? procedure;
  final String localeTag;

  @override
  State<_ProcedureWebEditor> createState() => _ProcedureWebEditorState();
}

class _ProcedureWebEditorState extends State<_ProcedureWebEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late ProcedureOperationType _context;
  late bool _active;
  late bool _notifyAdmin;
  late ProcedureAdminNotificationCondition _condition;
  late List<TextEditingController> _questions;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final OperationalProcedure? procedure = widget.procedure;
    _name = TextEditingController(text: procedure?.name ?? '');
    _description = TextEditingController(text: procedure?.description ?? '');
    _context = procedure?.operationType ?? ProcedureOperationType.sale;
    _active = procedure?.isActive ?? true;
    _notifyAdmin = procedure?.adminNotification.enabled ?? false;
    _condition =
        procedure?.adminNotification.condition ??
        ProcedureAdminNotificationCondition.negativeResponse;
    final List<ProcedureItem> items =
        procedure?.stages
            .expand((ProcedureStage stage) => stage.items)
            .toList(growable: false) ??
        const <ProcedureItem>[];
    _questions = items.isEmpty
        ? <TextEditingController>[TextEditingController()]
        : items.map((item) => TextEditingController(text: item.title)).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    for (final controller in _questions) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.procedure == null
            ? context.t(
                'procedimentos.newProcedure',
                fallback: 'Novo procedimento',
              )
            : context.t(
                'procedimentos.editProcedure',
                fallback: 'Editar procedimento',
              ),
      ),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'procedimentos.currentLanguageHelp',
                    fallback:
                        'O conteúdo será salvo no idioma atual e usará fallback nos demais idiomas.',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: context.t(
                      'procedimentos.nameField',
                      fallback: 'Nome',
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.t(
                          'procedimentos.validationName',
                          fallback: 'Informe o nome.',
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: context.t(
                      'procedimentos.descriptionField',
                      fallback: 'Descrição',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProcedureOperationType>(
                  initialValue: _context,
                  decoration: InputDecoration(
                    labelText: context.t(
                      'procedimentos.operationContext',
                      fallback: 'Contexto operacional',
                    ),
                  ),
                  items:
                      const <ProcedureOperationType>[
                            ProcedureOperationType.sale,
                            ProcedureOperationType.technicalService,
                            ProcedureOperationType.cashRegister,
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_contextLabel(context, value)),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setState(() => _context = value ?? _context),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: Text(context.t('common.active', fallback: 'Ativo')),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _notifyAdmin,
                  onChanged: (value) => setState(() => _notifyAdmin = value),
                  title: Text(
                    context.t(
                      'procedimentos.notifyAdmin',
                      fallback: 'Notificar ADMIN por push',
                    ),
                  ),
                ),
                if (_notifyAdmin)
                  DropdownButtonFormField<ProcedureAdminNotificationCondition>(
                    initialValue: _condition,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'procedimentos.notificationCondition',
                        fallback: 'Quando notificar',
                      ),
                    ),
                    items: ProcedureAdminNotificationCondition.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_conditionLabel(context, value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _condition = value ?? _condition),
                  ),
                const Divider(height: 30),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.t(
                          'procedimentos.questions',
                          fallback: 'Perguntas (Sim/Não)',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(
                        () => _questions.add(TextEditingController()),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        context.t(
                          'procedimentos.addQuestion',
                          fallback: 'Adicionar pergunta',
                        ),
                      ),
                    ),
                  ],
                ),
                ..._questions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: entry.value,
                            decoration: InputDecoration(
                              labelText:
                                  '${context.t('procedimentos.question', fallback: 'Pergunta')} ${entry.key + 1}',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? context.t(
                                    'procedimentos.validationItemTitle',
                                    fallback: 'Informe a pergunta.',
                                  )
                                : null,
                          ),
                        ),
                        IconButton(
                          onPressed: _questions.length == 1
                              ? null
                              : () {
                                  final controller = _questions.removeAt(
                                    entry.key,
                                  );
                                  controller.dispose();
                                  setState(() {});
                                },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('common.cancel', fallback: 'Cancelar')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.t('common.save', fallback: 'Salvar')),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final DateTime now = DateTime.now();
    final OperationalProcedure? current = widget.procedure;
    final ProcedureOperationPoint point = switch (_context) {
      ProcedureOperationType.technicalService =>
        ProcedureOperationPoint.technicalServiceStartBefore,
      ProcedureOperationType.cashRegister =>
        ProcedureOperationPoint.cashRegisterStartBefore,
      _ => ProcedureOperationPoint.saleStartBefore,
    };
    final Map<String, String> nameTranslations = Map<String, String>.of(
      current?.nameTranslations ?? const {},
    );
    final Map<String, String> descriptionTranslations = Map<String, String>.of(
      current?.descriptionTranslations ?? const {},
    );
    nameTranslations[widget.localeTag] = _name.text.trim();
    descriptionTranslations[widget.localeTag] = _description.text.trim();
    final List<ProcedureItem> currentItems =
        current?.stages.expand((stage) => stage.items).toList() ?? const [];
    final ProcedureStage? firstStage =
        current != null && current.stages.isNotEmpty
        ? current.stages.first
        : null;
    final ProcedureTrigger? firstTrigger =
        current != null && current.triggers.isNotEmpty
        ? current.triggers.first
        : null;
    final List<ProcedureItem> items = _questions
        .asMap()
        .entries
        .map((entry) {
          final ProcedureItem? existing = entry.key < currentItems.length
              ? currentItems[entry.key]
              : null;
          final Map<String, String> translations = Map<String, String>.of(
            existing?.titleTranslations ?? const {},
          );
          translations[widget.localeTag] = entry.value.text.trim();
          return ProcedureItem(
            id: existing?.id ?? 'item-local-${entry.key + 1}',
            title: entry.value.text.trim(),
            guidance: existing?.guidance ?? '',
            responseType: ProcedureResponseType.yesNo,
            required: true,
            order: entry.key + 1,
            titleTranslations: translations,
            configuration:
                existing?.configuration ??
                const ProcedureItemConfiguration(requireTextWhenNo: true),
          );
        })
        .toList(growable: false);
    final ProcedureStage stage = ProcedureStage(
      id: firstStage?.id ?? 'stage-local-1',
      title:
          firstStage?.title ??
          context.t(
            'procedimentos.customerExperience',
            fallback: 'Experiência do cliente',
          ),
      description: firstStage?.description ?? '',
      order: 1,
      items: items,
      titleTranslations:
          firstStage?.titleTranslations ??
          <String, String>{
            widget.localeTag: context.t(
              'procedimentos.customerExperience',
              fallback: 'Experiência do cliente',
            ),
          },
    );
    Navigator.of(context).pop(
      OperationalProcedure(
        id: current?.id ?? 'procedure-local-${now.microsecondsSinceEpoch}',
        name: _name.text.trim(),
        description: _description.text.trim(),
        nameTranslations: nameTranslations,
        descriptionTranslations: descriptionTranslations,
        operationType: _context,
        moment: ProcedureMoment.beforeStart,
        status: _active ? ProcedureStatus.active : ProcedureStatus.inactive,
        required: false,
        triggers: <ProcedureTrigger>[
          ProcedureTrigger(
            id: firstTrigger?.id ?? 'trigger-local-1',
            operationPoint: point,
            operationType: _context,
            triggerMoment: ProcedureTriggerMoment.beforeStart,
            activationMode: ProcedureTriggerActivationMode.automatic,
            enforcementMode: ProcedureEnforcementMode.recommended,
            enabled: true,
            order: 1,
            createdAt: current?.createdAt ?? now,
            updatedAt: now,
          ),
        ],
        stages: <ProcedureStage>[stage],
        adminNotification: ProcedureAdminNotificationConfiguration(
          enabled: _notifyAdmin,
          condition: _condition,
        ),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }
}

String _contextLabel(BuildContext context, ProcedureOperationType type) {
  return switch (type) {
    ProcedureOperationType.sale => context.t(
      'procedimentos.contextSale',
      fallback: 'Venda',
    ),
    ProcedureOperationType.technicalService => context.t(
      'procedimentos.contextTechnicalService',
      fallback: 'Atendimento técnico',
    ),
    ProcedureOperationType.cashRegister => context.t(
      'procedimentos.contextCashRegister',
      fallback: 'Caixa',
    ),
    _ => type.name,
  };
}

String _conditionLabel(
  BuildContext context,
  ProcedureAdminNotificationCondition value,
) {
  return switch (value) {
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
