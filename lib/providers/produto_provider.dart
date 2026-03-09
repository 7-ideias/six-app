import 'package:appplanilha/data/models/produto_model.dart';
import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import '../core/services/produto_service.dart';

class ProdutoProvider with ChangeNotifier {
  final ProdutoService _service = ProdutoService();
  final AuthService _authService = AuthService();

  List<ProdutoModel> _produtos = [];
  bool _isLoading = false;

  List<ProdutoModel> get produtos => _produtos;

  bool get isLoading => _isLoading;

  Future<void> carregarProdutos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final empresaId = await _authService.getEmpresaId();
      final headers = {
        'Content-Type': 'application/json',
        'idUnicoDaEmpresa': empresaId ?? '',
        'Authorization': 'Bearer ${await _authService.getAccessToken()}',
      };
      _produtos = await _service.ProdutosList(headers);
    } catch (e) {
      // Tratar erro (pode adicionar um estado de erro aqui também)
      _produtos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
