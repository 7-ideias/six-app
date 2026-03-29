import 'package:flutter/material.dart';
import '../data/models/usuario_model.dart';

class UsuarioProvider with ChangeNotifier {
  static UsuarioProvider? _instance;
  factory UsuarioProvider() {
    _instance ??= UsuarioProvider._internal();
    return _instance!;
  }
  UsuarioProvider._internal();

  UsuarioModel? _usuario;
  bool _isLoading = false;
  String? _erro;

  UsuarioModel? get usuario => _usuario;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  void setUsuario(UsuarioModel usuario) {
    _usuario = usuario;
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
    _usuario = null;
    _erro = null;
    _isLoading = false;
    notifyListeners();
  }
}
