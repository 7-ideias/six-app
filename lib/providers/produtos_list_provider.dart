import 'package:flutter/material.dart';

class ProdutosListProvider<T> with ChangeNotifier {
  final Future<dynamic> Function(Map<String, String>? headers) fetchFunction;

  ProdutosListProvider({required this.fetchFunction});

  List<T> _items = [];
  dynamic _fullResponse;
  bool _isLoading = false;
  String? _erro;

  List<T> get listaDeProdutos => _items;
  dynamic get fullResponse => _fullResponse;

  bool get isLoading => _isLoading;

  String? get erro => _erro;

  Future<void> carregar({Map<String, String>? headers}) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final response = await fetchFunction(headers);
      _fullResponse = response;
      if (response is List<T>) {
        _items = response;
      } else if (response != null && response.produtosList is List<T>) {
        _items = response.produtosList;
      } else {
        _items = [];
      }
    } catch (e) {
      _erro = e.toString();
      _items = [];
      _fullResponse = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
