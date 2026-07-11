import '../../../data/models/ai_assistant_models.dart';
import '../../../data/services/ia/ai_assistant_api_client.dart';

class AiAssistantService {
  AiAssistantService({AiAssistantApiClient? apiClient})
    : _apiClient = apiClient ?? AiAssistantApiClient();

  final AiAssistantApiClient _apiClient;

  Future<AiAssistantResponseModel> perguntar(AiAssistantRequestModel request) {
    return _apiClient.perguntar(request);
  }

  Future<void> enviarFeedback(AiAssistantFeedbackRequestModel request) {
    return _apiClient.enviarFeedback(request);
  }

  Future<void> enviarSugestao(AiAssistantSuggestionRequestModel request) {
    return _apiClient.enviarSugestao(request);
  }
}
