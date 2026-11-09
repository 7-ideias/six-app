import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/storage_usage.dart';

void main() {
  test('pending measurement is unknown rather than zero', () {
    final usage = StorageUsage.fromJson({
      'companyId': 'A',
      'status': 'PENDENTE',
    });
    expect(usage.pending, isTrue);
    expect(usage.databaseBytes, isNull);
    expect(usage.fileBytes, isNull);
  });

  test('zero measured bytes and UTC timestamp are preserved', () {
    final usage = StorageUsage.fromJson({
      'companyId': 'A',
      'status': 'ATUALIZADO',
      'databaseBytes': 0,
      'fileBytes': 1024,
      'fileCount': 1,
      'measuredAt': '2026-11-09T12:00:00Z',
    });
    expect(usage.pending, isFalse);
    expect(usage.databaseBytes, 0);
    expect(usage.fileBytes, 1024);
    expect(usage.measuredAt!.isUtc, isTrue);
  });

  test('malformed and negative counters are rejected', () {
    for (final value in [-1, 0.5, '1024']) {
      expect(
        () => StorageUsage.fromJson({
          'companyId': 'A',
          'status': 'ATUALIZADO',
          'fileBytes': value,
        }),
        throwsFormatException,
      );
    }
  });
}
