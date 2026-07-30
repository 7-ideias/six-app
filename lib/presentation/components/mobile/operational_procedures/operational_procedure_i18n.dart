import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:sixpos/l10n/six_i18n.dart';

class OperationalProcedureI18n {
  const OperationalProcedureI18n._();

  static String stageProgress(BuildContext context, int current, int total) {
    return AppLocalizations.of(
          context,
        )?.procedimentosStageProgress(current, total) ??
        _template(
          context,
          'procedimentos.stageProgress',
          'Etapa {current} de {total}',
          <String, Object>{'current': current, 'total': total},
        );
  }

  static String procedureSequence(
    BuildContext context,
    int current,
    int total,
  ) {
    return AppLocalizations.of(
          context,
        )?.procedimentosProcedureSequence(current, total) ??
        _template(
          context,
          'procedimentos.procedureSequence',
          'Procedimento {current} de {total}',
          <String, Object>{'current': current, 'total': total},
        );
  }

  static String actionsCompleted(
    BuildContext context,
    int answered,
    int total,
  ) {
    return AppLocalizations.of(
          context,
        )?.procedimentosActionsCompleted(answered, total) ??
        _pluralTemplate(
          context,
          keyPrefix: 'procedimentos.actionsCompleted',
          count: answered,
          zero: '0 de {total} ações concluídas',
          one: '1 de {total} ação concluída',
          other: '{count} de {total} ações concluídas',
          values: <String, Object>{'total': total},
        );
  }

  static String answeredActionsSummary(
    BuildContext context,
    int answered,
    int total,
  ) {
    return AppLocalizations.of(
          context,
        )?.procedimentosAnsweredActionsSummary(answered, total) ??
        _pluralTemplate(
          context,
          keyPrefix: 'procedimentos.answeredActionsSummary',
          count: answered,
          zero: '0 de {total} ações respondidas.',
          one: '1 de {total} ação respondida.',
          other: '{count} de {total} ações respondidas.',
          values: <String, Object>{'total': total},
        );
  }

  static String optionalPendingSummary(BuildContext context, int count) {
    return AppLocalizations.of(
          context,
        )?.procedimentosOptionalPendingSummary(count) ??
        _pluralTemplate(
          context,
          keyPrefix: 'procedimentos.optionalPendingSummary',
          count: count,
          zero: 'Nenhum item opcional pendente.',
          one: '1 item opcional pendente.',
          other: '{count} itens opcionais pendentes.',
        );
  }

  static String requiredPendingSummary(BuildContext context, int count) {
    return AppLocalizations.of(
          context,
        )?.procedimentosRequiredPendingSummary(count) ??
        _pluralTemplate(
          context,
          keyPrefix: 'procedimentos.requiredPendingSummary',
          count: count,
          zero: 'Nenhum item obrigatório pendente.',
          one: '1 item obrigatório pendente.',
          other: '{count} itens obrigatórios pendentes.',
        );
  }

  static String itemCount(BuildContext context, int count) {
    return AppLocalizations.of(context)?.procedimentosItemCount(count) ??
        _pluralTemplate(
          context,
          keyPrefix: 'procedimentos.itemCount',
          count: count,
          zero: '0 itens',
          one: '1 item',
          other: '{count} itens',
        );
  }

  static String stageCount(BuildContext context, int count) {
    return AppLocalizations.of(context)?.procedimentosStageCount(count) ??
        _pluralTemplate(
          context,
          keyPrefix: 'procedimentos.stageCount',
          count: count,
          zero: '0 etapas',
          one: '1 etapa',
          other: '{count} etapas',
        );
  }

  static String structureSummary(
    BuildContext context, {
    required int stages,
    required int items,
  }) {
    return AppLocalizations.of(
          context,
        )?.procedimentosStructureSummary(stages, items) ??
        '${stageCount(context, stages)} • ${itemCount(context, items)}';
  }

  static String stageSemantics(
    BuildContext context, {
    required int order,
    required String title,
    required int itemCount,
  }) {
    return AppLocalizations.of(
          context,
        )?.procedimentosStageSemantics(order, title, itemCount) ??
        _template(
          context,
          'procedimentos.stageSemantics',
          'Etapa {order}: {title}. {itemCountLabel}.',
          <String, Object>{
            'order': order,
            'title': title,
            'itemCountLabel': OperationalProcedureI18n.itemCount(
              context,
              itemCount,
            ),
          },
        );
  }

  static String executionItemSemantics(
    BuildContext context, {
    required String requiredLabel,
    required String title,
    required String type,
  }) {
    return AppLocalizations.of(
          context,
        )?.procedimentosExecutionItemSemantics(requiredLabel, title, type) ??
        _template(
          context,
          'procedimentos.executionItemSemantics',
          '{requiredLabel}: {title}. {type}.',
          <String, Object>{
            'requiredLabel': requiredLabel,
            'title': title,
            'type': type,
          },
        );
  }

  static String executionItemStatus(
    BuildContext context, {
    required String type,
    required String requiredLabel,
  }) {
    return AppLocalizations.of(
          context,
        )?.procedimentosExecutionItemStatus(type, requiredLabel) ??
        _template(
          context,
          'procedimentos.executionItemStatus',
          '{type} • {requiredLabel}',
          <String, Object>{'type': type, 'requiredLabel': requiredLabel},
        );
  }

  static String demonstration(BuildContext context) {
    return AppLocalizations.of(context)?.procedimentosDemonstration ??
        context.t('procedimentos.demonstration', fallback: 'Demonstração');
  }

  static String responseTypeSemantics(
    BuildContext context, {
    required String label,
    required String description,
    required bool simulated,
  }) {
    if (simulated) {
      final String demoLabel = demonstration(context);
      return AppLocalizations.of(
            context,
          )?.procedimentosResponseTypeSimulatedSemantics(
            label,
            description,
            demoLabel,
          ) ??
          _template(
            context,
            'procedimentos.responseTypeSimulatedSemantics',
            '{label}. {description}. {demoLabel}.',
            <String, Object>{
              'label': label,
              'description': description,
              'demoLabel': demoLabel,
            },
          );
    }

    return AppLocalizations.of(
          context,
        )?.procedimentosResponseTypeSemantics(label, description) ??
        _template(
          context,
          'procedimentos.responseTypeSemantics',
          '{label}. {description}.',
          <String, Object>{'label': label, 'description': description},
        );
  }

  static String triggerSemantics(
    BuildContext context, {
    required String operation,
    required String moment,
    required String activation,
    required String enforcement,
    required String status,
  }) {
    return AppLocalizations.of(context)?.procedimentosTriggerSemantics(
          operation,
          moment,
          activation,
          enforcement,
          status,
        ) ??
        _template(
          context,
          'procedimentos.triggerSemantics',
          '{operation}, {moment}, {activation}, {enforcement}, {status}',
          <String, Object>{
            'operation': operation,
            'moment': moment,
            'activation': activation,
            'enforcement': enforcement,
            'status': status,
          },
        );
  }

  static String triggerSummarySingle(
    BuildContext context, {
    required String operation,
    required String moment,
  }) {
    return AppLocalizations.of(
          context,
        )?.procedimentosTriggerSummarySingle(operation, moment) ??
        _template(
          context,
          'procedimentos.triggerSummarySingle',
          '{operation}, {moment}',
          <String, Object>{'operation': operation, 'moment': moment},
        );
  }

  static String triggerSummaryMultiple(
    BuildContext context, {
    required String first,
    required int remaining,
  }) {
    return AppLocalizations.of(
          context,
        )?.procedimentosTriggerSummaryMultiple(first, remaining) ??
        _template(
          context,
          'procedimentos.triggerSummaryMultiple',
          '{first} • +{remaining}',
          <String, Object>{'first': first, 'remaining': remaining},
        );
  }

  static String optionNumber(BuildContext context, int index) {
    return AppLocalizations.of(context)?.procedimentosOptionNumber(index) ??
        _template(
          context,
          'procedimentos.optionNumber',
          'Opção {index}',
          <String, Object>{'index': index},
        );
  }

  static String formatDate(BuildContext context, DateTime value) {
    return DateFormat.yMd(_localeName(context)).format(value);
  }

  static String formatNumber(BuildContext context, num value) {
    return NumberFormat.decimalPattern(_localeName(context)).format(value);
  }

  static num? parseNumber(BuildContext context, String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    try {
      return NumberFormat.decimalPattern(_localeName(context)).parse(trimmed);
    } catch (_) {
      final String fallback = _normalizeNumberFallback(context, trimmed);
      if (fallback.isEmpty) return null;
      return num.tryParse(fallback);
    }
  }

  static String formatPercent(BuildContext context, double value) {
    final NumberFormat formatter = NumberFormat.percentPattern(
      _localeName(context),
    )..maximumFractionDigits = 0;
    return formatter.format(value);
  }

  static String _localeName(BuildContext context) {
    try {
      return Localizations.localeOf(context).toLanguageTag();
    } catch (_) {
      return 'pt-BR';
    }
  }

  static String _normalizeNumberFallback(BuildContext context, String value) {
    final String locale = _localeName(context).toLowerCase();
    String normalized = value.replaceAll(RegExp(r'\s'), '');
    if (locale.startsWith('pt') || locale.startsWith('es')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '');
    }
    return normalized;
  }

  static String _pluralTemplate(
    BuildContext context, {
    required String keyPrefix,
    required int count,
    required String zero,
    required String one,
    required String other,
    Map<String, Object> values = const <String, Object>{},
  }) {
    final String key =
        count == 0
            ? '$keyPrefix.zero'
            : count == 1
            ? '$keyPrefix.one'
            : '$keyPrefix.other';
    final String fallback =
        count == 0
            ? zero
            : count == 1
            ? one
            : other;
    return _template(context, key, fallback, <String, Object>{
      'count': count,
      ...values,
    });
  }

  static String _template(
    BuildContext context,
    String key,
    String fallback,
    Map<String, Object> values,
  ) {
    String text = context.t(key, fallback: fallback);
    for (final MapEntry<String, Object> entry in values.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return text;
  }
}
