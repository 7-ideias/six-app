import '../../../data/services/aparencia/aparencia_api_client.dart';
import '../../../mappers/configuracao_aparencia_mapper.dart';
import '../../models/aparencia_models.dart';

class AparenciaService {
  AparenciaService({
    required AparenciaApiClient apiClient,
  }) : _apiClient = apiClient;

  final AparenciaApiClient _apiClient;

  Future<ConfiguracaoAparenciaSistema> buscarAparencia() async {
    try {
      final response = await _apiClient.getAparencia();
      if (response == null) {
        return _retornarPadrao();
      }
      return ConfiguracaoAparenciaMapper.fromResponse(response);
    } catch (e) {
      // Log do erro e retorno de padrão conforme solicitado
      return _retornarPadrao();
    }
  }

  ConfiguracaoAparenciaSistema _retornarPadrao() {
    return ConfiguracaoAparenciaSistema(
      tema: TemaSistema.claro,
      paleta: PaletaSistema.defaultPalette(),
    );
  }

  Future<void> salvarAparencia(ConfiguracaoAparenciaSistema dominio) async {
    final request = ConfiguracaoAparenciaMapper.toRequest(dominio);
    return _apiClient.salvarAparencia(request);
  }
}
