import 'package:flutter/foundation.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';
import 'package:sixpos/data/services/catalog_health/catalog_health_api_client.dart';

class CatalogHealthProvider extends ChangeNotifier {
  CatalogHealthProvider({required CatalogHealthApiClient apiClient})
    : _apiClient = apiClient;

  final CatalogHealthApiClient _apiClient;

  CatalogHealthSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  CatalogHealthSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && !hasError && (_summary?.isEmpty ?? true);

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _apiClient.buscarSaudeCatalogo();
    } catch (_) {
      _summary = null;
      _errorMessage = 'Não foi possível carregar a saúde do catálogo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();
}
