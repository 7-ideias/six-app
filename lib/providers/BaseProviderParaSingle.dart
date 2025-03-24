// lib/core/providers/single_provider.dart
import 'package:flutter/material.dart';

class BaseProviderParaSingle<T> with ChangeNotifier {
  final Future<T> Function(Map<String, String>? headers) fetchFunction;

  BaseProviderParaSingle({required this.fetchFunction});

  T? _item;
  bool _isLoading = false;
  String? _erro;

  T? get item => _item;

  bool get isLoading => _isLoading;

  String? get erro => _erro;

  Future<void> carregar(Map<String, String>? headers) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _item = await fetchFunction(headers);
    } catch (e) {
      _erro = e.toString();
      _item = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
