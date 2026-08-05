import 'package:flutter/material.dart';
import 'package:sixpos/data/mock/dashboard_inicio_mock.dart';
import 'package:sixpos/data/models/dashboard_inicio_model.dart';

/// Estado da dashboard inicial.
///
/// Gerencia o período selecionado e o modelo de dados resultante.
/// O mock é carregado com um atraso simulado para exercitar os estados
/// de loading/success sem precisar de infraestrutura de rede.
///
/// Ponto de substituição futura: troque [DashboardInicioMock.forPeriod]
/// por uma chamada a um repository real. Os widgets consumidores
/// não precisarão mudar.
class DashboardInicioProvider extends ChangeNotifier {
  DashboardInicioProvider({
    DashboardPeriod initialPeriod = DashboardPeriod.currentMonth,
  }) : _period = initialPeriod {
    _data = DashboardInicioMock.forPeriod(_period);
  }

  DashboardPeriod _period;
  late DashboardInicioModel _data;
  bool _isLoading = false;
  String? _error;

  DashboardPeriod get period => _period;
  DashboardInicioModel get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Altera o período e recarrega os dados.
  void setPeriod(DashboardPeriod period) {
    if (_period == period) return;
    _period = period;
    _reload();
  }

  /// Força recarga dos dados (simula ação de atualizar).
  Future<void> reload() => _reload();

  Future<void> _reload() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final DashboardPeriod capturedPeriod = _period;
    await Future<void>.delayed(const Duration(milliseconds: 380));

    // Descarta resultado se o período mudou durante o delay.
    if (_period != capturedPeriod) return;
    _data = DashboardInicioMock.forPeriod(_period);
    _isLoading = false;
    notifyListeners();
  }
}
