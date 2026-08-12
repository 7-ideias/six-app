import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/workspace_home_model.dart';

void main() {
  test('fromJson mapeia blocos disponíveis com valores numéricos', () {
    final model = WorkspaceHomeModel.fromJson(_workspaceHomeJson);

    expect(model.date, DateTime(2026, 8, 10));
    expect(model.timeZone, 'America/Sao_Paulo');
    expect(model.cash.available, isTrue);
    expect(model.cash.open, isTrue);
    expect(model.cash.sessionId, 'sessao-1');
    expect(model.technicalServices.active, 8);
    expect(model.technicalServices.waitingApproval, 5);
    expect(model.financial.receivableToday?.amount, 1240.50);
    expect(model.financial.overduePayable?.count, 3);
    expect(model.stock.belowMinimum, 6);
  });

  test('fromJson preserva indisponibilidade sem transformar em zero', () {
    final model = WorkspaceHomeModel.fromJson(<String, dynamic>{
      'date': '2026-08-10',
      'timeZone': 'America/Sao_Paulo',
      'cash': <String, dynamic>{'available': false},
      'technicalServices': <String, dynamic>{'available': false},
      'financial': <String, dynamic>{'available': false},
      'stock': <String, dynamic>{'available': false},
    });

    expect(model.cash.available, isFalse);
    expect(model.cash.open, isNull);
    expect(model.technicalServices.active, isNull);
    expect(model.financial.receivableToday, isNull);
    expect(model.stock.belowMinimum, isNull);
  });
}

const Map<String, dynamic> _workspaceHomeJson = <String, dynamic>{
  'date': '2026-08-10',
  'timeZone': 'America/Sao_Paulo',
  'cash': <String, dynamic>{
    'available': true,
    'open': true,
    'sessionId': 'sessao-1',
    'openedAt': '2026-08-10T08:12:00',
    'responsibleName': 'Carlos',
  },
  'technicalServices': <String, dynamic>{
    'available': true,
    'active': 8,
    'waitingApproval': 5,
    'late': 3,
    'readyForPickup': 4,
  },
  'financial': <String, dynamic>{
    'available': true,
    'receivableToday': <String, dynamic>{'count': 4, 'amount': 1240.50},
    'payableToday': <String, dynamic>{'count': 2, 'amount': 680},
    'overdueReceivable': <String, dynamic>{'count': 1, 'amount': 230},
    'overduePayable': <String, dynamic>{'count': 3, 'amount': 540},
  },
  'stock': <String, dynamic>{
    'available': true,
    'belowMinimum': 6,
    'withoutStock': 2,
    'negative': 1,
  },
};
