import 'package:sixpos/data/models/workspace_home_model.dart';
import 'package:sixpos/data/services/workspace_home/workspace_home_api_client.dart';

abstract class WorkspaceHomeService {
  Future<WorkspaceHomeModel> buscarHome();
}

abstract class WorkspaceHomeSectionsService {
  bool get supportsSections;
  Future<String> currentScope();
  Future<WorkspaceHomeModel> buscarSecao(
    WorkspaceHomeSection section,
    String scope,
  );
}

class DefaultWorkspaceHomeService
    implements WorkspaceHomeService, WorkspaceHomeSectionsService {
  DefaultWorkspaceHomeService({WorkspaceHomeApiClient? apiClient})
    : _apiClient = apiClient ?? HttpWorkspaceHomeApiClient();

  final WorkspaceHomeApiClient _apiClient;

  @override
  bool get supportsSections => _apiClient is WorkspaceHomeSectionsApiClient;

  @override
  Future<String> currentScope() =>
      (_apiClient as WorkspaceHomeSectionsApiClient).currentScope();

  @override
  Future<WorkspaceHomeModel> buscarSecao(
    WorkspaceHomeSection section,
    String scope,
  ) => (_apiClient as WorkspaceHomeSectionsApiClient).buscarSecao(
    section,
    scope,
  );

  @override
  Future<WorkspaceHomeModel> buscarHome() {
    return _apiClient.buscarHome();
  }
}
