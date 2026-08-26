import 'package:flutter/widgets.dart';

import '../../data/models/streak_models.dart';
import '../../l10n/six_i18n.dart';

String streakDaysLabel(BuildContext context, int days) {
  if (days == 1) {
    return context.t('streak.oneDay', fallback: '1 dia');
  }
  return context
      .t('streak.days', fallback: '{count} dias')
      .replaceAll('{count}', days.toString());
}

String streakCurrentMessage(BuildContext context, UserStreakScopeModel scope) {
  if (scope.currentDays <= 0) {
    return context.t(
      'streak.keepUsing',
      fallback: 'Use o SixoApp todos os dias para manter sua ofensiva.',
    );
  }
  if (scope.activeToday && scope.currentDays == 1) {
    return context.t(
      'streak.startedToday',
      fallback: 'Sua ofensiva começou hoje.',
    );
  }
  return context
      .t('streak.daysOfStreak', fallback: '{count} dias de ofensiva')
      .replaceAll('{count}', scope.currentDays.toString());
}
