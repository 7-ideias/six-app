import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/perfil_negocio_service.dart';
import '../core/services/visual_asset_sync_service.dart';
import '../data/models/perfil_negocio_model.dart';

class HomeBannersProvider extends ChangeNotifier {
  HomeBannersProvider({
    PerfilNegocioService? service,
    VisualAssetSyncService? assetSyncService,
  }) : _service = service ?? PerfilNegocioService(),
       _assetSyncService =
           assetSyncService ?? VisualAssetSyncService.instance {
    _assetSubscription = _assetSyncService.changes.listen((_) {
      if (_disposed) return;
      unawaited(carregar(force: true));
    });
    unawaited(_assetSyncService.initialize());
  }

  final PerfilNegocioService _service;
  final VisualAssetSyncService _assetSyncService;
  StreamSubscription<void>? _assetSubscription;
  HomeBannersModel? _dados;
  String? _empresaId;
  bool _carregando = false;
  String? _erro;
  int _geracao = 0;
  bool _disposed = false;

  HomeBannersModel? get dados => _dados;
  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<void> carregar({bool force = false}) async {
    final int geracao = ++_geracao;
    bool iniciouLoading = false;

    try {
      final String empresaId = await _service.empresaAtual();
      if (_disposed || geracao != _geracao) return;

      if (!force && _empresaId == empresaId && _dados != null) {
        return;
      }

      _carregando = true;
      _erro = null;
      iniciouLoading = true;
      _notify();

      final HomeBannersModel dados = await _service.banners(empresaId);
      if (_disposed || geracao != _geracao) return;

      _empresaId = empresaId;
      _dados = dados;
    } catch (error) {
      if (_disposed || geracao != _geracao) return;
      _erro = _erroKey(error);
      if (force) _dados = null;
      _notify();
    } finally {
      if (!_disposed && geracao == _geracao && iniciouLoading) {
        _carregando = false;
        _notify();
      }
    }
  }

  void invalidar() {
    ++_geracao;
    _empresaId = null;
    _dados = null;
    _erro = null;
    _carregando = false;
    _notify();
  }

  String _erroKey(Object error) {
    if (error is PerfilNegocioException &&
        error.code == 'CONTEXTO_EMPRESA_ALTERADO') {
      return 'companyChanged';
    }
    return 'loadError';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_geracao;
    _assetSubscription?.cancel();
    _assetSubscription = null;
    _service.dispose();
    super.dispose();
  }
}
