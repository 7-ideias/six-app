import 'package:appplanilha/data/models/tela_inicial_models.dart';
import 'package:flutter/material.dart';

class TelaInicialWebProvider with ChangeNotifier {
  static TelaInicialWebProvider? _instance;
  factory TelaInicialWebProvider() {
    _instance ??= TelaInicialWebProvider._internal();
    return _instance!;
  }
  TelaInicialWebProvider._internal();

  TelaInicialModel? _telaInicial;
  bool _isLoading = false;
  String? _erro;

  TelaInicialModel? get telaInicialWeb => _telaInicial;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  void setTelaInicial(TelaInicialModel telaInicialWeb) {
    _telaInicial = telaInicialWeb;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setErro(String? erro) {
    _erro = erro;
    notifyListeners();
  }

  void clear() {
    _telaInicial = null;
    _erro = null;
    _isLoading = false;
    notifyListeners();
  }
}
