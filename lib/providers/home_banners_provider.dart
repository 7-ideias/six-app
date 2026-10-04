import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/perfil_negocio_change_service.dart';
import '../core/services/perfil_negocio_service.dart';
import '../core/services/visual_asset_manifest_cache_service.dart';
import '../core/services/visual_asset_sync_service.dart';
import '../data/models/perfil_negocio_model.dart';

class HomeBannersProvider extends ChangeNotifier {
  HomeBannersProvider({
    PerfilNegocioService? service,
    VisualAssetSyncService? assetSyncService,
    VisualAssetManifestCacheService? manifestCacheService,
  }) : _service = service ?? PerfilNegocioService(),
       _assetSyncService =
           assetSyncService ?? VisualAssetSyncService.instance,
       _manifestCacheService =
           manifestCacheService ?? VisualAssetManifestCacheService.instance {
    _assetSubscription = _assetSyncService.changes.listen((_) {
      if (_disposed) return;
      unawaited(_reloadWithShimmer());
    });
    _profileSubscription =
        PerfilNegocioChangeService.instance.changes.listen((String companyId) {
      if (_disposed) return;
      unawaited(_onProfileChanged(companyId));
    });
  }

  final PerfilNegocioService _service;
  final VisualAssetSyncService _assetSyncService;
  final VisualAssetManifestCacheService _manifestCacheService;
  StreamSubscription<void>? _assetSubscription;
  StreamSubscription<String>? _profileSubscription;
  HomeBannersModel? _dados;
  String? _empresaId;
  bool _carregando = false;
  String? _erro;
  int _geracao = 0;
  bool _disposed = false;

  HomeBannersModel? get dados => _dados;
  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<void> _onProfileChanged(String companyId) async {
    final String current = await _service.empresaAtual();
    if (_disposed || current != companyId) return;

    ++_geracao;
    _empresaId = companyId;
    _dados = null;
    _erro = null;
    _carregando = true;
    _notify();
    await _manifestCacheService.remove(
      kind: 'home_mobile',
      companyId: companyId,
    );
    await carregar(force: true);
  }

  Future<void> _reloadWithShimmer() async {
    if (_disposed) return;
    final String companyId = await _service.empresaAtual();
    _dados = null;
    _erro = null;
    _carregando = true;
    _notify();
    await carregar(force: true);
  }

  Future<void> carregar({bool force = false}) async {
    final int geracao = ++_geracao;
    bool iniciouLoading = false;

    try {
      final String empresaId = await _service.empresaAtual();
      if (_disposed || geracao != _geracao) return;

      bool restored = false;
      if (!force && _dados == null) {
        await _assetSyncService.restoreLocalState();
        final String? environment = _assetSyncService.environment;
        if (environment != null) {
          final Map<String, dynamic>? cached =
              await _manifestCacheService.load(
            kind: 'home_mobile',
            companyId: empresaId,
            environment: environment,
          );
          if (cached != null && !_disposed && geracao == _geracao) {
            try {
              _empresaId = empresaId;
              _dados = HomeBannersModel.fromJson(cached);
              restored = true;
              _notify();
            } catch (error) {
              debugPrint('[HomeBanners] manifesto local inválido: $error');
            }
          }
        }
      }

      final bool versionChanged = await _assetSyncService.initialize();
      if (!force && restored && !versionChanged) {
        return;
      }
      if (!force && _empresaId == empresaId && _dados != null &&
          !versionChanged) {
        return;
      }

      _carregando = _dados == null;
      _erro = null;
      iniciouLoading = true;
      _notify();

      final HomeBannersModel dados = await _service.banners(empresaId);
      if (_disposed || geracao != _geracao) return;

      final String environment = _assetSyncService.environment ?? 'LIVE';
      final String version = _assetSyncService.version ?? '000000000000';
      final bool cached = await _manifestCacheService.prefetchAndSave(
        kind: 'home_mobile',
        companyId: empresaId,
        environment: environment,
        assetsVersion: version,
        payload: dados.toJson(),
        imageUrls: dados.banners.expand(
          (BannerHomeModel item) => <String>[
            if (item.imagemUrl800 != null) item.imagemUrl800!,
            if (item.imagemUrl1200 != null) item.imagemUrl1200!,
          ],
        ),
      );
      if (_disposed || geracao != _geracao) return;
      if (!cached && _dados != null) return;

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
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _service.dispose();
    super.dispose();
  }
}
