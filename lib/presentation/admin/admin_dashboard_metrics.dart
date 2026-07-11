import '../../core/services/admin_portal_service.dart';

class AdminCompaniesMetrics {
  const AdminCompaniesMetrics({
    required this.total,
    required this.active,
    required this.inactive,
    required this.activePercent,
  });

  final int total;
  final int active;
  final int inactive;
  final double activePercent;

  bool get hasCompanies => total > 0;

  factory AdminCompaniesMetrics.fromResumo(AdminPortalResumo resumo) {
    return AdminCompaniesMetrics.fromValues(
      total: resumo.totalEmpresasCadastradas,
      active: resumo.totalEmpresasAtivas,
    );
  }

  factory AdminCompaniesMetrics.fromValues({
    required int total,
    required int active,
  }) {
    final int safeTotal = total < 0 ? 0 : total;
    final int safeActive = active < 0 ? 0 : active;
    final int activeForPercentage = safeActive > safeTotal ? safeTotal : safeActive;
    final int inactive = safeTotal - activeForPercentage;
    final double activePercent = safeTotal == 0 ? 0 : (activeForPercentage / safeTotal) * 100;

    return AdminCompaniesMetrics(
      total: safeTotal,
      active: safeActive,
      inactive: inactive,
      activePercent: activePercent,
    );
  }
}
