import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/perfil_negocio_change_service.dart';
import '../../core/services/perfil_negocio_service.dart';
import '../../core/services/visual_asset_sync_service.dart';
import '../../data/models/web_header_assets_model.dart';
import '../../providers/empresa_provider.dart';

class WebHeaderAssetsContextController extends ChangeNotifier {
  WebHeaderAssetsContextController({
    PerfilNegocioService? perfilNegocioService,
    EmpresaProvider? empresaProvider,
    VisualAssetSyncService? visualAssetSyncService,
  }) : _perfilNegocioService = perfilNegocioService ?? PerfilNegocioService(),
       _empresaProvider = empresaProvider ?? EmpresaProvider(),
       _visualAssetSyncService =
           visualAssetSyncService ?? VisualAssetSyncService.instance;

  final PerfilNegocioService _perfilNegocioService;
  final EmpresaProvider _empresaProvider;
  final VisualAssetSyncService _visualAssetSyncService;

  StreamSubscription<void>? _assetSyncSubscription;
  StreamSubscription<String>? _profileSubscription;

  WebHeaderAssetsModel? _assets;
  String? _empresaId;
  int _generation = 0;
  bool _initialized = false;
  bool _disposed = false;
  bool _isLoading = kIsWeb;

  WebHeaderAssetsModel? get assets => _assets;
  bool get isLoading => _isLoading;
  String? get assetsVersion => _visualAssetSyncService.version;

  void initialize() {
    if (_initialized || _disposed || !kIsWeb) return;
    _initialized = true;
    _empresaProvider.addListener(_onEmpresaChanged);
    _profileSubscription = PerfilNegocioChangeService.instance.changes.listen((
      companyId,
    ) {
      if (_disposed || (_empresaId != null && companyId != _empresaId)) return;
      unawaited(refresh());
    });
    _assetSyncSubscription = _visualAssetSyncService.changes.listen((_) {
      if (_disposed || !kIsWeb) return;
      unawaited(refresh());
    });
    scheduleMicrotask(() async {
      await _visualAssetSyncService.initialize();
      if (!_disposed && _generation == 0) await refresh();
    });
  }

  Future<void> refresh() async {
    if (_disposed || !kIsWeb) return;

    final int generation = ++_generation;
    _assets = null;
    _isLoading = true;
    notifyListeners();
    try {
      final String empresaId = await _perfilNegocioService.empresaAtual();
      final WebHeaderAssetsModel resolved = await _perfilNegocioService
          .webHeaderAssets(empresaId);
      if (_disposed || generation != _generation) return;

      debugPrint(
        '[WebHeaderAssets] empresa=$empresaId '
        'segmento=${resolved.perfilNegocio.perfil.segmentoPrincipal} '
        'subsegmento=${resolved.perfilNegocio.perfil.subsegmento} '
        'assets=${resolved.assets.length}',
      );

      _empresaId = empresaId;
      _assets = resolved;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      if (_disposed || generation != _generation) return;
      debugPrint('[WebHeaderAssets] falha ao carregar: $error');
      _empresaId = null;
      _assets = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onEmpresaChanged() {
    if (_disposed || !kIsWeb) return;
    ++_generation;
    _empresaId = null;
    _assets = null;
    _isLoading = _empresaProvider.empresa != null;
    notifyListeners();

    if (_empresaProvider.empresa == null) {
      return;
    }

    unawaited(_visualAssetSyncService.synchronize());
    scheduleMicrotask(refresh);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    if (_initialized && kIsWeb) {
      _empresaProvider.removeListener(_onEmpresaChanged);
    }
    _assetSyncSubscription?.cancel();
    _assetSyncSubscription = null;
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _perfilNegocioService.dispose();
    super.dispose();
  }
}
