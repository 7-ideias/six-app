import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/perfil_negocio_service.dart';
import '../../core/services/visual_asset_manifest_cache_service.dart';
import '../../core/services/visual_asset_sync_service.dart';
import '../../data/models/gestao_mobile_assets_model.dart';
import '../../providers/empresa_provider.dart';

class GestaoMobileAssetsContextController extends ChangeNotifier {
  GestaoMobileAssetsContextController({
    PerfilNegocioService? perfilNegocioService,
    EmpresaProvider? empresaProvider,
    VisualAssetSyncService? visualAssetSyncService,
    VisualAssetManifestCacheService? manifestCacheService,
  }) : _perfilNegocioService = perfilNegocioService ?? PerfilNegocioService(),
       _empresaProvider = empresaProvider ?? EmpresaProvider(),
       _visualAssetSyncService =
           visualAssetSyncService ?? VisualAssetSyncService.instance,
       _manifestCacheService =
           manifestCacheService ?? VisualAssetManifestCacheService.instance;

  final PerfilNegocioService _perfilNegocioService;
  final EmpresaProvider _empresaProvider;
  final VisualAssetSyncService _visualAssetSyncService;
  final VisualAssetManifestCacheService _manifestCacheService;

  StreamSubscription<void>? _assetSyncSubscription;

  GestaoMobileAssetsModel? _assets;
  String? _empresaId;
  int _generation = 0;
  bool _initialized = false;
  bool _disposed = false;

  GestaoMobileAssetsModel? get assets => _assets;

  void initialize() {
    if (_initialized || _disposed || kIsWeb) return;
    _initialized = true;
    _empresaProvider.addListener(_onEmpresaChanged);
    _assetSyncSubscription = _visualAssetSyncService.changes.listen((_) {
      if (_disposed || kIsWeb) return;
      unawaited(refresh());
    });
    scheduleMicrotask(_initializeFromLocalManifest);
  }

  Future<void> _initializeFromLocalManifest() async {
    if (_disposed || kIsWeb) return;
    final String empresaId = await _perfilNegocioService.empresaAtual();
    await _visualAssetSyncService.restoreLocalState();

    bool restored = false;
    final String? environment = _visualAssetSyncService.environment;
    if (environment != null) {
      final Map<String, dynamic>? cached =
          await _manifestCacheService.load(
        kind: 'gestao_mobile',
        companyId: empresaId,
        environment: environment,
      );
      if (cached != null && !_disposed) {
        try {
          _empresaId = empresaId;
          _assets = GestaoMobileAssetsModel.fromJson(cached);
          restored = true;
          notifyListeners();
        } catch (error) {
          debugPrint('[GestaoMobile] manifesto local inválido: $error');
        }
      }
    }

    final bool versionChanged =
        await _visualAssetSyncService.initialize();
    if (!restored || versionChanged) {
      await refresh();
    }
  }

  Future<void> refresh() async {
    if (_disposed || kIsWeb) return;

    final int generation = ++_generation;
    try {
      final String empresaId = await _perfilNegocioService.empresaAtual();
      final GestaoMobileAssetsModel resolved = await _perfilNegocioService
          .gestaoMobileAssets(empresaId);

      if (_disposed || generation != _generation) return;

      final int fallbacks =
          resolved.assets.where((item) => item.imagemFallback).length;
      debugPrint(
        '[GestaoMobile] assets backend empresa=$empresaId '
        'segmento=${resolved.perfilNegocio.perfil.segmentoPrincipal} '
        'subsegmento=${resolved.perfilNegocio.perfil.subsegmento} '
        'fallbacks=$fallbacks/${resolved.assets.length}',
      );

      final String environment =
          _visualAssetSyncService.environment ?? 'LIVE';
      final String version =
          _visualAssetSyncService.version ?? '000000000000';
      final bool cached = await _manifestCacheService.prefetchAndSave(
        kind: 'gestao_mobile',
        companyId: empresaId,
        environment: environment,
        assetsVersion: version,
        payload: resolved.toJson(),
        imageUrls: resolved.assets.map(
          (GestaoMobileAssetModel item) => item.imagemUrl,
        ),
      );
      if (_disposed || generation != _generation) return;
      if (!cached && _assets != null) return;

      _empresaId = empresaId;
      _assets = resolved;
      notifyListeners();
    } catch (error) {
      if (_disposed || generation != _generation) return;
      debugPrint('[GestaoMobile] falha ao carregar assets do backend: $error');

      if (_assets == null && _empresaId == null) return;
      _empresaId = null;
      _assets = null;
      notifyListeners();
    }
  }

  void _onEmpresaChanged() {
    if (_disposed || kIsWeb) return;
    ++_generation;
    _empresaId = null;

    if (_empresaProvider.empresa == null) {
      if (_assets != null) {
        _assets = null;
        notifyListeners();
      }
      return;
    }

    scheduleMicrotask(_initializeFromLocalManifest);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    if (_initialized && !kIsWeb) {
      _empresaProvider.removeListener(_onEmpresaChanged);
    }
    _assetSyncSubscription?.cancel();
    _assetSyncSubscription = null;
    _perfilNegocioService.dispose();
    super.dispose();
  }
}
