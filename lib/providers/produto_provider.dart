import 'package:appplanilha/data/models/produto_model.dart';
import 'package:flutter/material.dart';

import '../core/services/produto_service.dart';

class ProdutoProvider with ChangeNotifier {
  final ProdutoService _service = ProdutoService();

  List<ProdutoModel> _produtos = [];
  bool _isLoading = false;

  List<ProdutoModel> get produtos => _produtos;

  bool get isLoading => _isLoading;

  Future<void> carregarProdutos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        'idUsuario': '2ea5e611cab0439a917229e44e9301a8',
        'idColaborador': '2ea5e611cab0439a917229e44e9301a8',
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
