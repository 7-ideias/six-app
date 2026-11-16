import 'workspace_home_model.dart';

/// Presentation-neutral facts shared by the independent web and mobile layouts.
class WorkspaceHomeInsight {
  const WorkspaceHomeInsight(
    this.key,
    this.value, {
    this.money = false,
    this.attention = false,
  });
  final String key;
  final num? value;
  final bool money;
  final bool attention;
}

List<WorkspaceHomeInsight> workspaceHomeInsights(
  WorkspaceHomeSection section,
  WorkspaceHomeModel home,
) {
  return switch (section) {
    WorkspaceHomeSection.financial => [
      WorkspaceHomeInsight(
        'receivableToday',
        home.financial.receivableToday?.amount,
        money: true,
      ),
      WorkspaceHomeInsight(
        'payableToday',
        home.financial.payableToday?.amount,
        money: true,
      ),
      WorkspaceHomeInsight(
        'overdueReceivable',
        home.financial.overdueReceivable?.amount,
        money: true,
        attention: true,
      ),
      WorkspaceHomeInsight(
        'overduePayable',
        home.financial.overduePayable?.amount,
        money: true,
        attention: true,
      ),
    ],
    WorkspaceHomeSection.technicalServices => [
      WorkspaceHomeInsight(
        'late',
        home.technicalServices.late,
        attention: true,
      ),
      WorkspaceHomeInsight(
        'waitingApproval',
        home.technicalServices.waitingApproval,
        attention: true,
      ),
      WorkspaceHomeInsight(
        'readyForPickup',
        home.technicalServices.readyForPickup,
      ),
      WorkspaceHomeInsight('active', home.technicalServices.active),
    ],
    WorkspaceHomeSection.stock => [
      WorkspaceHomeInsight(
        'withoutStock',
        home.stock.withoutStock,
        attention: true,
      ),
      WorkspaceHomeInsight(
        'belowMinimum',
        home.stock.belowMinimum,
        attention: true,
      ),
      WorkspaceHomeInsight('negative', home.stock.negative, attention: true),
    ],
    WorkspaceHomeSection.reservations => [
      WorkspaceHomeInsight(
        'received',
        home.reservations.received,
        attention: true,
      ),
      WorkspaceHomeInsight('inReview', home.reservations.inReview),
    ],
    WorkspaceHomeSection.cash => [],
  };
}
