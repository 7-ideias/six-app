import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';
import 'package:sixpos/data/services/catalog_health/catalog_health_api_client.dart';
import 'package:sixpos/providers/catalog_health_provider.dart';

void main() {
  test('usa a visualização configurada sem duplicar o cliente de dados', () async {
    final _RecordingCatalogHealthApiClient api =
        _RecordingCatalogHealthApiClient();
    final CatalogHealthProvider provider = CatalogHealthProvider(
      apiClient: api,
      visualizacao: 'WEB',
    );

    await provider.load();

    expect(api.visualizacao, 'WEB');
    expect(provider.summary, isNotNull);
    expect(provider.hasError, isFalse);
  });
}

class _RecordingCatalogHealthApiClient implements CatalogHealthApiClient {
  String? visualizacao;

  @override
  Future<CatalogHealthSummary> buscarSaudeCatalogo({
    String visualizacao = 'MOBILE',
  }) async {
    this.visualizacao = visualizacao;
    return CatalogHealthSummary.empty();
  }
}
