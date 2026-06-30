import '../../../data/models/cliente_usuario_model.dart';
import '../../../data/services/cliente_usuario/cliente_usuario_api_client.dart';

class ClienteUsuarioService {
  ClienteUsuarioService({required ClienteUsuarioApiClient apiClient})
    : _apiClient = apiClient;

  final ClienteUsuarioApiClient _apiClient;

  Future<ClienteUsuarioListResponse> listarClientesUsuario() {
    return _apiClient.listarClientesUsuario();
  }

  Future<List<ClienteUsuario>> listarClientesAtivos() async {
    final ClienteUsuarioListResponse response = await listarClientesUsuario();
    return somenteClientesAtivos(response.clientes);
  }

  Future<ClienteUsuario> cadastrarClienteUsuario(
    ClienteUsuarioRequest request,
  ) {
    return _apiClient.cadastrarClienteUsuario(request);
  }

  Future<ClienteUsuario> atualizarClienteUsuario(
    String idCliente,
    ClienteUsuarioRequest request,
  ) {
    return _apiClient.atualizarClienteUsuario(idCliente, request);
  }

  List<ClienteUsuario> somenteClientesAtivos(List<ClienteUsuario> clientes) {
    return clientes
        .where((ClienteUsuario cliente) => cliente.ativo)
        .toList(growable: false);
  }

  List<ClienteUsuario> filtrarClientes(
    List<ClienteUsuario> clientes,
    String filtro,
  ) {
    final String termo = _normalizar(filtro);
    if (termo.isEmpty) {
      return clientes;
    }

    return clientes.where((ClienteUsuario cliente) {
      return _normalizar(cliente.nome).contains(termo) ||
          _normalizar(cliente.documento).contains(termo) ||
          _normalizar(cliente.email).contains(termo) ||
          _normalizar(cliente.telefone).contains(termo);
    }).toList(growable: false);
  }

  String _normalizar(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
