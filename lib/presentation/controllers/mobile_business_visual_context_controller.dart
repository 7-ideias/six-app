import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/perfil_negocio_service.dart';
import '../../providers/empresa_provider.dart';
import '../models/mobile_business_visual_assets.dart';

class MobileBusinessVisualContextController extends ChangeNotifier {
  MobileBusinessVisualContextController({
    PerfilNegocioService? perfilNegocioService,
    EmpresaProvider? empresaProvider,
    this.debugLabel = 'MobileBusinessVisuals',
  }) : _perfilNegocioService = perfilNegocioService ?? PerfilNegocioService(),
       _empresaProvider = empresaProvider ?? EmpresaProvider();

  final PerfilNegocioService _perfilNegocioService;
  final EmpresaProvider _empresaProvider;
  final String debugLabel;

  MobileBusinessVisualAssets? _assets;
  String? _empresaId;
  int _generation = 0;
  bool _initialized = false;
  bool _disposed = false;

  MobileBusinessVisualAssets? get assets => _assets;

  void initialize() {
    if (_initialized || _disposed || kIsWeb) return;
    _initialized = true;
    _empresaProvider.addListener(_onEmpresaChanged);

    scheduleMicrotask(refresh);
  }

  Future<void> refresh() async {
    if (_disposed || kIsWeb) return;

    final int generation = ++_generation;
    try {
      final String empresaId = await _perfilNegocioService.empresaAtual();
      final perfilEmpresa = await _perfilNegocioService.buscar(empresaId);
      if (_disposed || generation != _generation) return;

      final MobileBusinessVisualAssets? resolved =
          perfilEmpresa.configurado
              ? MobileBusinessVisualAssets.fromPerfil(perfilEmpresa.perfil)
              : null;

      debugPrint(
        '[$debugLabel] '
        'segmento=${perfilEmpresa.perfil.segmentoPrincipal} '
        'subsegmento=${perfilEmpresa.perfil.subsegmento} '
        'assets=${resolved?.profileFolder ?? 'fallback-local'}',
      );

      if (_empresaId == empresaId &&
          _assets?.profileFolder == resolved?.profileFolder) {
        return;
      }

      _empresaId = empresaId;
      _assets = resolved;
      notifyListeners();
    } catch (error) {
      if (_disposed || generation != _generation) return;
      debugPrint('[$debugLabel] falha ao resolver assets: $error');
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

    scheduleMicrotask(refresh);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    if (_initialized && !kIsWeb) {
      _empresaProvider.removeListener(_onEmpresaChanged);
    }
    _perfilNegocioService.dispose();
    super.dispose();
  }
}
