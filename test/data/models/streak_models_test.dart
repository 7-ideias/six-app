import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/streak_models.dart';

void main() {
  group('UserStreaksModel', () {
    test('parseia resposta completa da API', () {
      final model = UserStreaksModel.fromJson(const <String, dynamic>{
        'mobile': <String, dynamic>{
          'currentDays': 5,
          'longestDays': 18,
          'activeToday': true,
          'lastActivityDay': '2026-08-09',
        },
        'web': <String, dynamic>{
          'currentDays': 2,
          'longestDays': 9,
          'activeToday': false,
          'lastActivityDay': '2026-08-08',
        },
        'shared': <String, dynamic>{
          'currentDays': 12,
          'longestDays': 31,
          'activeToday': true,
          'lastActivityDay': '2026-08-09',
        },
      });

      expect(model.mobile.currentDays, 5);
      expect(model.mobile.longestDays, 18);
      expect(model.mobile.activeToday, isTrue);
      expect(model.mobile.lastActivityDay, DateTime(2026, 8, 9));
      expect(model.web.currentDays, 2);
      expect(model.shared.currentDays, 12);
    });

    test('usa zeros seguros quando a API estiver temporariamente ausente', () {
      final model = UserStreaksModel.fromJson(const <String, dynamic>{});

      expect(model.mobile.currentDays, 0);
      expect(model.web.currentDays, 0);
      expect(model.shared.currentDays, 0);
      expect(model.shared.activeToday, isFalse);
    });
  });

  test('request envia apenas plataforma e timezone', () {
    final request = StreakActivityRequest(
      platform: StreakPlatform.mobile,
      timezone: 'America/Sao_Paulo',
    );

    expect(request.toJson(), <String, dynamic>{
      'platform': 'MOBILE',
      'timezone': 'America/Sao_Paulo',
    });
    expect(request.toJson().containsKey('userId'), isFalse);
    expect(request.toJson().containsKey('day'), isFalse);
    expect(request.toJson().containsValue('SHARED'), isFalse);
  });
}
