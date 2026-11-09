import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/storage_plan.dart';
import 'package:sixpos/data/models/storage_usage.dart';

void main() {
  test('legacy response does not invent quotas or a plan', () {
    final usage = StorageUsage.fromJson({
      'companyId': 'a',
      'status': 'PENDENTE',
    });
    expect(usage.plan.planId, isNull);
    expect(usage.plan.limits.fileLimitBytes, isNull);
    expect(storageQuotaStatus(100, null), 'quotaNotConfigured');
    expect(storageQuotaStatus(null, 100), 'noMeasurement');
  });
  test('warning boundaries and overage retain actual percentage', () {
    expect(storageQuotaStatus(79, 100), 'quotaWithin');
    expect(storageQuotaStatus(80, 100), 'quotaNear');
    expect(storageQuotaStatus(100, 100), 'quotaReached');
    expect(storageQuotaStatus(101, 100), 'quotaExceeded');
  });
  test('MB conversion is exact and honors configured decimal separator', () {
    expect(storageMegabytesToBytes('1,000001', ','), 1000001);
    expect(storageMegabytesToBytes('0.000001', '.'), 1);
    expect(storageBytesToMegabytes(1000001, ','), '1,000001');
    expect(storageMegabytesToBytes('', ','), isNull);
    for (final invalid in ['0', '-1', '1.000', '1,1234567', '1000000001']) {
      expect(
        () => storageMegabytesToBytes(invalid, ','),
        throwsFormatException,
      );
    }
  });
  test(
    'plan name respects locale and assignment carries optimistic version',
    () {
      final plan = StorageEffectivePlan.fromJson({
        'planId': 'pro',
        'code': 'PRO',
        'names': {'pt-BR': 'Profissional', 'en-US': 'Professional'},
        'assignmentVersion': 3,
        'limits': {'fileLimitBytes': 1000000000, 'version': 2},
      });
      expect(plan.name('pt-PT'), 'Profissional');
      expect(plan.name('es-ES'), 'PRO');
      expect(plan.assignmentRequest(null), {
        'planId': null,
        'expectedVersion': 3,
      });
      expect(plan.limits.toRequest()['expectedVersion'], 2);
    },
  );
  test('invalid limits are not interpreted as unlimited', () {
    for (final value in [0, -1, 1.5, '100']) {
      expect(
        () => StorageLimits.fromJson({'fileLimitBytes': value}),
        throwsFormatException,
      );
    }
  });
}
