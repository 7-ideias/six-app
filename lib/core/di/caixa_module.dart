
import '../../data/services/caixa/caixa_api_client.dart';
import '../../domain/services/caixa/caixa_service.dart';

class CaixaModule {
  CaixaModule._();

  static final CaixaService caixaService = CaixaService(
    apiClient: HttpCaixaApiClient(),
  );
}
