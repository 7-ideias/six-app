import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../services/cliente_usuario_service.dart';

class ClienteUsuarioModule {
  ClienteUsuarioModule._();

  static final ClienteUsuarioService clienteUsuarioService =
      ClienteUsuarioService(apiClient: HttpClienteUsuarioApiClient());
}
