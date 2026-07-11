import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/admin/admin_dashboard_metrics.dart';

void main() {
  group('AdminCompaniesMetrics', () {
    test('calcula inativas e percentual ativo com valores validos', () {
      final metrics = AdminCompaniesMetrics.fromValues(total: 10, active: 7);

      expect(metrics.total, 10);
      expect(metrics.active, 7);
      expect(metrics.inactive, 3);
      expect(metrics.activePercent, 70);
      expect(metrics.hasCompanies, isTrue);
    });

    test('trata total zero sem divisao por zero', () {
      final metrics = AdminCompaniesMetrics.fromValues(total: 0, active: 0);

      expect(metrics.total, 0);
      expect(metrics.active, 0);
      expect(metrics.inactive, 0);
      expect(metrics.activePercent, 0);
      expect(metrics.hasCompanies, isFalse);
    });

    test('nao gera inativas negativas quando ativos excedem o total', () {
      final metrics = AdminCompaniesMetrics.fromValues(total: 4, active: 9);

      expect(metrics.total, 4);
      expect(metrics.active, 9);
      expect(metrics.inactive, 0);
      expect(metrics.activePercent, 100);
    });

    test('normaliza valores negativos para os calculos derivados', () {
      final metrics = AdminCompaniesMetrics.fromValues(total: -2, active: -5);

      expect(metrics.total, 0);
      expect(metrics.active, 0);
      expect(metrics.inactive, 0);
      expect(metrics.activePercent, 0);
    });
  });
}
