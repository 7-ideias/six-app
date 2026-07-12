import 'package:flutter/foundation.dart';

/// Centraliza o estado de comunicação do mobile com o backend.
///
/// O contador permite que chamadas concorrentes não encerrem a animação antes
/// de todas as operações acompanhadas terminarem.
class LoadingDoMobileComunicandoComBackendController {
  const LoadingDoMobileComunicandoComBackendController._();

  static final ValueNotifier<int> _activeOperations = ValueNotifier<int>(0);

  static ValueListenable<int> get activeOperations => _activeOperations;

  static Future<T> track<T>(Future<T> Function() operation) async {
    _activeOperations.value += 1;
    try {
      return await operation();
    } finally {
      final int nextValue = _activeOperations.value - 1;
      _activeOperations.value = nextValue < 0 ? 0 : nextValue;
    }
  }
}
