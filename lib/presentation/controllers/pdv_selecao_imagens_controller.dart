import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/perfil_negocio_change_service.dart';
import '../../core/services/perfil_negocio_service.dart';
import '../../core/services/visual_asset_manifest_cache_service.dart';
import '../../core/services/visual_asset_sync_service.dart';
import '../../data/models/pdv_selecao_assets.dart';
import '../../data/models/empresa_model.dart';
import '../../providers/empresa_provider.dart';

/// Mantém somente a composição visual, independente do catálogo e da seleção.
class PdvSelecaoImagensController extends ChangeNotifier {
  PdvSelecaoImagensController({
    PerfilNegocioService? service,
    VisualAssetSyncService? sync,
    VisualAssetManifestCacheService? cache,
  }) : _service = service ?? PerfilNegocioService(),
       _sync = sync ?? VisualAssetSyncService.instance,
       _cache = cache ?? VisualAssetManifestCacheService.instance;

  final PerfilNegocioService _service;
  final VisualAssetSyncService _sync;
  final VisualAssetManifestCacheService _cache;
  static const _kind = 'pdv_selecao_mobile';
  Map<String, String> _urls = const {};
  String? _company;
  String? _environment;
  EmpresaModel? _empresa;
  int _generation = 0;
  bool _disposed = false;
  bool _syncStarted = false;
  StreamSubscription<void>? _versions;
  StreamSubscription<String>? _profiles;

  String? url(String tipo) => _urls[tipo];

  void initialize() {
    if (_versions != null || _disposed) return;
    _versions = _sync.changes.listen((_) => unawaited(_load()));
    _profiles = PerfilNegocioChangeService.instance.changes.listen((company) {
      if (company == _company) unawaited(_load());
    });
    _empresa = EmpresaProvider().empresa;
    EmpresaProvider().addListener(_onContextChanged);
    scheduleMicrotask(() => _load(restore: true));
  }

  void _onContextChanged() {
    final empresa = EmpresaProvider().empresa;
    if (_disposed || identical(_empresa, empresa) && empresa != null) return;
    _empresa = empresa;
    ++_generation;
    _company = null;
    _setUrls(const {});
    if (empresa != null) unawaited(_load());
  }

  Future<void> _load({bool restore = false}) async {
    if (_disposed) return;
    final generation = ++_generation;
    bool current() => !_disposed && generation == _generation;
    try {
      final company = await _service.empresaAtual();
      if (!current()) return;
      await _sync.restoreLocalState();
      if (!current()) return;
      final env = _sync.environment;
      final version = _sync.version;
      if (_company != company || _environment != env) _setUrls(const {});
      _company = company;
      _environment = env;
      if (!_syncStarted) {
        _syncStarted = true;
        unawaited(_sync.initialize());
      }
      if (restore && env != null && version != null) {
        try {
          final saved = await _cache.load(
            kind: _kind,
            companyId: company,
            environment: env,
            assetsVersion: version,
          );
          if (!current()) return;
          if (saved != null) _setUrls(pdvSelecaoUrls(saved));
        } catch (error) {
          debugPrint('[PDV] Cache de imagens indisponível: $error');
        }
        if (!current()) return;
      }
      final urls = await _service.imagensSelecaoPdv(company);
      if (!current()) return;
      _setUrls(urls);
      if (env != null && version != null) {
        await _cache.prefetchAndSave(
          kind: _kind,
          companyId: company,
          environment: env,
          assetsVersion: version,
          payload: urls,
          imageUrls: urls.values,
          stillCurrent: current,
        );
      }
    } catch (error) {
      if (current()) {
        debugPrint('[PDV] Falha ao carregar imagens do seletor: $error');
      }
    }
  }

  void _setUrls(Map<String, String> urls) {
    if (mapEquals(_urls, urls)) return;
    _urls = urls;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    EmpresaProvider().removeListener(_onContextChanged);
    _profiles?.cancel();
    _versions?.cancel();
    _service.dispose();
    super.dispose();
  }
}
