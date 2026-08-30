import 'package:flutter/foundation.dart';

import '../core/services/onboarding_inicial_service.dart';
import '../data/models/onboarding_inicial_model.dart';

class OnboardingInicialProvider extends ChangeNotifier {
  OnboardingInicialProvider({OnboardingInicialService? service})
    : _service = service ?? OnboardingInicialService();

  final OnboardingInicialService _service;

  OnboardingInicialModel? _estado;
  bool _carregando = false;
  bool _salvando = false;
  Object? _erro;

  OnboardingInicialModel? get estado => _estado;
  bool get carregando => _carregando;
  bool get salvando => _salvando;
  Object? get erro => _erro;
  bool get precisaFazerOnboarding =>
      _estado != null && !_estado!.fezOnboardingInicial;

  Future<OnboardingInicialModel> carregar({bool force = false}) async {
    if (!force && _estado != null) return _estado!;
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final OnboardingInicialModel estado = await _service.buscar();
      _estado = estado;
      return estado;
    } catch (error) {
      _erro = error;
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<OnboardingInicialModel> concluir(
    ConcluirOnboardingInicialRequest request,
  ) async {
    if (_salvando) {
      return _estado ?? (throw StateError('Onboarding ainda não carregado.'));
    }
    _salvando = true;
    _erro = null;
    notifyListeners();
    try {
      final OnboardingInicialModel estado = await _service.concluir(request);
      _estado = estado;
      return estado;
    } catch (error) {
      _erro = error;
      rethrow;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  void limpar() {
    _estado = null;
    _carregando = false;
    _salvando = false;
    _erro = null;
    notifyListeners();
  }
}
