import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/perfil_negocio_change_service.dart';
import '../../core/services/perfil_negocio_service.dart';
import '../../core/services/visual_asset_sync_service.dart';
import '../../data/models/vendas_mobile_assets_model.dart';
import '../../providers/empresa_provider.dart';

class VendasMobileAssetsContextController extends ChangeNotifier {
  VendasMobileAssetsContextController({
    PerfilNegocioService? perfilNegocioService,
    EmpresaProvider? empresaProvider,
    VisualAssetSyncService? visualAssetSyncService,
  }) : _service = perfilNegocioService ?? PerfilNegocioService(),
       _company = empresaProvider ?? EmpresaProvider(),
       _sync = visualAssetSyncService ?? VisualAssetSyncService.instance;

  final PerfilNegocioService _service;
  final EmpresaProvider _company;
  final VisualAssetSyncService _sync;
  StreamSubscription<void>? _versions;
  StreamSubscription<String>? _profiles;
  VendasMobileAssetsModel? _assets;
  VendasMobileAssetsModel? get assets => _assets;
  bool _loading = !kIsWeb;
  bool get loading => _loading;
  bool _disposed = false;
  bool _initialized = false;
  int _generation = 0;
  String? _companyId;

  void initialize() {
    if (_disposed || _initialized || kIsWeb) return;
    _initialized = true;
    _company.addListener(_companyChanged);
    _versions = _sync.changes.listen((_) => unawaited(refresh()));
    _profiles = PerfilNegocioChangeService.instance.changes.listen((id) {
      if (id == _companyId) unawaited(refresh());
    });
    scheduleMicrotask(() async {
      await _sync.initialize();
      if (!_disposed && _generation == 0) await refresh();
    });
  }

  Future<void> refresh() async {
    if (_disposed || kIsWeb) return;
    final generation = ++_generation;
    _assets = null;
    _loading = true;
    notifyListeners();
    try {
      final companyId = await _service.empresaAtual();
      final resolved = await _service.vendasMobileAssets(companyId);
      if (_disposed || generation != _generation) return;
      final version = _sync.version;
      _companyId = companyId;
      _assets = VendasMobileAssetsModel(
        perfilNegocio: resolved.perfilNegocio,
        assets: resolved.assets
            .map((item) {
              final uri = Uri.parse(item.imagemUrl);
              return VendasMobileAssetModel(
                id: item.id,
                slot: item.slot,
                modoExibicao: item.modoExibicao,
                imagemFallback: item.imagemFallback,
                imagemUrl:
                    version == null
                        ? item.imagemUrl
                        : uri
                            .replace(
                              queryParameters: {
                                ...uri.queryParameters,
                                'v': version,
                              },
                            )
                            .toString(),
              );
            })
            .toList(growable: false),
      );
    } catch (error) {
      if (_disposed || generation != _generation) return;
      debugPrint('[VendasMobile] falha ao carregar imagens: $error');
    }
    if (_disposed || generation != _generation) return;
    _loading = false;
    notifyListeners();
  }

  void _companyChanged() {
    if (_disposed) return;
    ++_generation;
    _companyId = null;
    _assets = null;
    _loading = _company.empresa != null;
    notifyListeners();
    if (_loading) scheduleMicrotask(refresh);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    if (_initialized) _company.removeListener(_companyChanged);
    _versions?.cancel();
    _profiles?.cancel();
    _service.dispose();
    super.dispose();
  }
}
