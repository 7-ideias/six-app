import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/data/services/workspace_home/workspace_home_api_client.dart';

abstract class WorkspaceHomeService {
  Future<WorkspaceHomeModel> buscarHome();
}

class DefaultWorkspaceHomeService implements WorkspaceHomeService {
  DefaultWorkspaceHomeService({WorkspaceHomeApiClient? apiClient})
    : _apiClient = apiClient ?? HttpWorkspaceHomeApiClient();

  final WorkspaceHomeApiClient _apiClient;

  @override
  Future<WorkspaceHomeModel> buscarHome() {
    return _apiClient.buscarHome();
  }
}
