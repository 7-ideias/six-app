import 'package:flutter/foundation.dart';
import 'package:sixpos/data/datasources/catalog_health_mock_data_source.dart';
import 'package:sixpos/data/models/catalog_health_model.dart';

class CatalogHealthProvider extends ChangeNotifier {
  CatalogHealthProvider({required CatalogHealthMockDataSource dataSource})
    : _dataSource = dataSource;

  final CatalogHealthMockDataSource _dataSource;

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
      _summary = await _dataSource.fetchSummary();
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
