import '../../../data/models/streak_models.dart';
import '../../../data/services/streak/streak_api_client.dart';

class StreakService {
  StreakService({StreakApiClient? apiClient})
    : _apiClient = apiClient ?? HttpStreakApiClient();

  final StreakApiClient _apiClient;

  Future<UserStreaksModel> getStreaks({String? timezone}) {
    return _apiClient.getStreaks(timezone: timezone);
  }

  Future<UserStreaksModel> registerActivity({
    required StreakPlatform platform,
    String? timezone,
  }) {
    return _apiClient.registerActivity(
      StreakActivityRequest(platform: platform, timezone: timezone),
    );
  }
}
