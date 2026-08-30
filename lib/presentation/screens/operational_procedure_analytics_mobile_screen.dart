import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/operational_procedure_persistence_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/operational_procedures/operational_procedure_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class OperationalProcedureAnalyticsMobileScreen extends StatefulWidget {
  const OperationalProcedureAnalyticsMobileScreen({super.key});

  @override
  State<OperationalProcedureAnalyticsMobileScreen> createState() =>
      _OperationalProcedureAnalyticsMobileScreenState();
}

class _OperationalProcedureAnalyticsMobileScreenState
    extends State<OperationalProcedureAnalyticsMobileScreen> {
  OperationalProcedureAnalytics? _analytics;
  Object? _error;
  bool _loading = true;
  int _days = 30;

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
      final String locale = Localizations.localeOf(context).toLanguageTag();
      final OperationalProcedureAnalytics result =
          await OperationalProcedureService(
            localeTag: locale,
          ).fetchAnalytics(days: _days);
      if (mounted) setState(() => _analytics = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: context.t(
        'procedimentos.analyticsTitle',
        fallback: 'Análise de resultados',
      ),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      actions: <Widget>[
        IconButton(
          tooltip: context.t('common.refresh', fallback: 'Atualizar'),
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bodyBuilder: (context, controller, topInset) {
        return ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
          children: <Widget>[
            _PeriodSelector(
              days: _days,
              onChanged: (int value) {
                setState(() => _days = value);
                _load();
              },
            ),
            const SizedBox(height: 14),
            if (_loading)
              const _AnalyticsLoading()
            else if (_error != null)
              _AnalyticsError(onRetry: _load)
            else if (_analytics != null)
              _AnalyticsContent(analytics: _analytics!),
          ],
        );
      },
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.analytics});

  final OperationalProcedureAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider locale =
        context.read<LocaleSettingsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: <Widget>[
            _KpiCard(
              label: context.t(
                'procedimentos.analyticsExecutions',
                fallback: 'Execuções',
              ),
              value: locale.formatInteger(analytics.totalExecutions),
              icon: Icons.fact_check_outlined,
            ),
            _KpiCard(
              label: context.t(
                'procedimentos.analyticsCompletion',
                fallback: 'Conclusão',
              ),
              value: locale.formatPercent(analytics.completionRate),
              icon: Icons.task_alt_rounded,
            ),
            _KpiCard(
              label: context.t(
                'procedimentos.analyticsNegative',
                fallback: 'Respostas negativas',
              ),
              value: locale.formatInteger(analytics.negativeResponses),
              icon: Icons.warning_amber_rounded,
            ),
            _KpiCard(
              label: context.t(
                'procedimentos.analyticsAverageTime',
                fallback: 'Tempo médio',
              ),
              value:
                  '${locale.formatInteger(analytics.averageDurationSeconds)}s',
              icon: Icons.timer_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: context.t(
            'procedimentos.analyticsByQuestion',
            fallback: 'Resultados por pergunta',
          ),
          child:
              analytics.byQuestion.isEmpty
                  ? _empty(context)
                  : Column(
                    children: analytics.byQuestion
                        .map((item) => _QuestionMetric(metric: item))
                        .toList(growable: false),
                  ),
        ),
        const SizedBox(height: 14),
        _Section(
          title: context.t(
            'procedimentos.analyticsRecent',
            fallback: 'Execuções recentes',
          ),
          child:
              analytics.recentExecutions.isEmpty
                  ? _empty(context)
                  : Column(
                    children: analytics.recentExecutions
                        .take(20)
                        .map(
                          (item) =>
                              _ExecutionRow(execution: item, locale: locale),
                        )
                        .toList(growable: false),
                  ),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Text(
      context.t(
        'procedimentos.analyticsEmpty',
        fallback: 'Ainda não há execuções neste período.',
      ),
      style: TextStyle(color: SixMobilePalette.mutedText),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: <int>[7, 30, 90]
          .map((int value) {
            return ChoiceChip(
              label: Text(
                '$value ${context.t('common.days', fallback: 'dias')}',
              ),
              selected: days == value,
              onSelected: (_) => onChanged(value),
            );
          })
          .toList(growable: false),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(icon, color: SixMobilePalette.primary),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionMetric extends StatelessWidget {
  const _QuestionMetric({required this.metric});

  final OperationalProcedureQuestionMetric metric;

  @override
  Widget build(BuildContext context) {
    final double negativeRatio =
        metric.totalAnswers == 0
            ? 0
            : metric.negativeAnswers / metric.totalAnswers;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            metric.question,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: negativeRatio,
              minHeight: 8,
              color: SixMobilePalette.error,
              backgroundColor: const Color(0xFF16A34A).withValues(alpha: .2),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${metric.negativeAnswers} ${context.t('procedimentos.analyticsNegativeShort', fallback: 'negativas')} • ${metric.totalAnswers} ${context.t('procedimentos.analyticsAnswers', fallback: 'respostas')}',
            style: TextStyle(color: SixMobilePalette.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ExecutionRow extends StatelessWidget {
  const _ExecutionRow({required this.execution, required this.locale});

  final OperationalProcedureExecutionResult execution;
  final LocaleSettingsProvider locale;

  @override
  Widget build(BuildContext context) {
    const Color successColor = Color(0xFF16A34A);
    final DateTime date = execution.startedAt.toLocal();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            execution.negativeResponses > 0
                ? SixMobilePalette.error.withValues(alpha: .12)
                : successColor.withValues(alpha: .12),
        child: Icon(
          execution.negativeResponses > 0
              ? Icons.priority_high_rounded
              : Icons.check_rounded,
          color:
              execution.negativeResponses > 0
                  ? SixMobilePalette.error
                  : successColor,
        ),
      ),
      title: Text(
        execution.procedureName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${locale.formatDate(date)} ${locale.formatTime(date)}'
        '${execution.saleId == null ? '' : ' • Venda ${execution.saleId}'}',
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: context.t('common.error', fallback: 'Erro'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.t(
              'procedimentos.analyticsLoadError',
              fallback: 'Não foi possível carregar a análise.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              context.t('common.retry', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}
