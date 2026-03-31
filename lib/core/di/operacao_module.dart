
import '../../data/services/operacao/operacao_api_client.dart';
import '../../domain/services/operacao/operacao_service.dart';
import '../../mappers/operacao_mapper.dart';

class OperacaoModule {
  OperacaoModule._();

  static final OperacaoService operacaoService = OperacaoService(
    apiClient: HttpOperacaoApiClient(),
    mapper: OperacaoRequestMapper(),
  );
}
