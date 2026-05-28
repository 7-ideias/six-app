import 'package:sixpos/core/services/desconto_service.dart';
import 'package:sixpos/data/models/desconto_model.dart';
import 'package:flutter/material.dart';

class DescontoProvider with ChangeNotifier {
  final DescontoService _service = DescontoService();

  List<DescontoModel> _descontos = [];
  bool _isLoading = false;

  List<DescontoModel> get descontos => _descontos;

  bool get isLoading => _isLoading;

  Future<void> carregarDescontos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        'idUsuario': '2ea5e611cab0439a917229e44e9301a8',
        'idColaborador': '2ea5e611cab0439a917229e44e9301a8',
      };
      _descontos = await _service.DescontosList(headers);
    } catch (e) {
      // Tratar erro (pode adicionar um estado de erro aqui também)
      _descontos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
