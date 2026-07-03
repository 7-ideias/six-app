import '../../../data/models/regionalizacao_models.dart';
import '../../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../../mappers/configuracao_regionalizacao_mapper.dart';
import '../../models/regionalizacao_models.dart';

class RegionalizacaoService {
  RegionalizacaoService({
    required RegionalizacaoApiClient apiClient,
  }) : _apiClient = apiClient;

  final RegionalizacaoApiClient _apiClient;

  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() {
    return _apiClient.buscarRegionalizacao();
  }

  ConfiguracaoRegionalizacaoSistema converterResponseParaDominio(
    ConfiguracaoRegionalizacaoResponse response,
  ) {
    return ConfiguracaoRegionalizacaoMapper.fromResponse(response);
  }

  Future<ConfiguracaoRegionalizacaoSistema> salvarRegionalizacao(
    ConfiguracaoRegionalizacaoSistema dominio,
  ) async {
    final request = ConfiguracaoRegionalizacaoMapper.toRequest(dominio);
    final response = await _apiClient.salvarRegionalizacao(request);
    return ConfiguracaoRegionalizacaoMapper.fromResponse(response);
  }
}
