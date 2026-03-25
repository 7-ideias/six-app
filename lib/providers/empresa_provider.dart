import 'package:flutter/material.dart';
import '../data/models/empresa_model.dart';

class EmpresaProvider with ChangeNotifier {
  static EmpresaProvider? _instance;
  factory EmpresaProvider() {
    _instance ??= EmpresaProvider._internal();
    return _instance!;
  }
  EmpresaProvider._internal();

  EmpresaModel? _empresa;
  bool _isLoading = false;
  String? _erro;

  EmpresaModel? get empresa => _empresa;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  void setEmpresa(EmpresaModel empresa) {
    _empresa = empresa;
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
    _empresa = null;
    _erro = null;
    _isLoading = false;
    notifyListeners();
  }
}
