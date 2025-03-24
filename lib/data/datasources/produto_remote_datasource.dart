import '../../core/services/api_client.dart';
import '../models/produto_model.dart';

class ProdutoRemoteDataSource {
  final ApiClient apiClient;

  ProdutoRemoteDataSource({required this.apiClient});

  Future<List<ProdutoModel>> buscarProdutos() async {
    final response = await apiClient.get(
      '/produtos',
    ); // só muda o endpoint aqui
    return (response as List)
        .map((json) => ProdutoModel.fromJson(json))
        .toList();
  }
}
