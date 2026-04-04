import '../../../mappers/configuracao_regionalizacao_mapper.dart';
import '../../models/regionalizacao_models.dart';
import '../../../data/services/regionalizacao/regionalizacao_api_client.dart';

class RegionalizacaoService {
  RegionalizacaoService({
    required RegionalizacaoApiClient apiClient,
  }) : _apiClient = apiClient;

  final RegionalizacaoApiClient _apiClient;

  Future<ConfiguracaoRegionalizacaoSistema> buscarRegionalizacao() async {
    try {
      final response = await _apiClient.getRegionalizacao();
      if (response == null) {
        return ConfiguracaoRegionalizacaoSistema.defaultConfiguration();
      }
      return ConfiguracaoRegionalizacaoMapper.fromResponse(response);
    } catch (_) {
      return ConfiguracaoRegionalizacaoSistema.defaultConfiguration();
    }
  }

  Future<void> salvarRegionalizacao(
    ConfiguracaoRegionalizacaoSistema dominio,
  ) async {
    final request = ConfiguracaoRegionalizacaoMapper.toRequest(dominio);
    return _apiClient.salvarRegionalizacao(request);
  }
}
