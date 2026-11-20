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

  List<T> itensDaResposta(dynamic response) {
    if (response is List<T>) return response;
    if (response != null && response.produtosList is List<T>)
      return response.produtosList as List<T>;
    return [];
  }

  Future<List<T>> consultar(Map<String, String> headers) async =>
      itensDaResposta(await fetchFunction(headers));

  Future<void> carregar({Map<String, String>? headers}) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final response = await fetchFunction(headers);
      _fullResponse = response;
      _items = itensDaResposta(response);
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
