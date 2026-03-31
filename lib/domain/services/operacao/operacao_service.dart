
import '../../../data/models/operacao_models.dart';
import '../../../data/services/operacao/operacao_api_client.dart';
import '../../../mappers/operacao_mapper.dart';

class OperacaoService {
  OperacaoService({
    required OperacaoApiClient apiClient,
    required OperacaoRequestMapper mapper,
  })  : _apiClient = apiClient,
        _mapper = mapper;

  final OperacaoApiClient _apiClient;
  final OperacaoRequestMapper _mapper;

  Future<OperacaoInserirResponse> finalizarVenda(
    OperacaoVendaInput input,
  ) async {
    final request = _mapper.toRequest(input);

    return _apiClient.inserirOperacao(
      request: request,
    );
  }
}
