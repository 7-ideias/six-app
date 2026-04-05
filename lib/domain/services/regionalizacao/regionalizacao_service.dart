import '../../../data/models/regionalizacao_models.dart';
import '../../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../../mappers/configuracao_regionalizacao_mapper.dart';
import '../../models/regionalizacao_models.dart';

class RegionalizacaoService {
  RegionalizacaoService({
    required RegionalizacaoApiClient apiClient,
  }) : _apiClient = apiClient;

  final RegionalizacaoApiClient _apiClient;

  ConfiguracaoRegionalizacaoSistema converterResponseParaDominio(
      ConfiguracaoRegionalizacaoResponse response,
      ) {
    return ConfiguracaoRegionalizacaoMapper.fromResponse(response);
  }

  Future<void> salvarRegionalizacao(
      ConfiguracaoRegionalizacaoSistema dominio,
      ) async {
    final request = ConfiguracaoRegionalizacaoMapper.toRequest(dominio);
    return _apiClient.salvarRegionalizacao(request);
  }
}
