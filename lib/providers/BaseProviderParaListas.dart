// lib/core/providers/base_provider.dart
import 'package:flutter/material.dart';

class BaseProviderParaListas<T> with ChangeNotifier {
  final Future<List<T>> Function(Map<String, String>? headers) fetchFunction;

  BaseProviderParaListas({required this.fetchFunction});

  List<T> _items = [];
  bool _isLoading = false;
  String? _erro;

  List<T> get items => _items;

  bool get isLoading => _isLoading;

  String? get erro => _erro;

  Future<void> carregar({Map<String, String>? headers}) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _items = await fetchFunction(headers);
    } catch (e) {
      _erro = e.toString();
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
