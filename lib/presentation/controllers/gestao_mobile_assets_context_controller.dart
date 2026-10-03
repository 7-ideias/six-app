import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/perfil_negocio_service.dart';
import '../../data/models/gestao_mobile_assets_model.dart';
import '../../providers/empresa_provider.dart';

class GestaoMobileAssetsContextController extends ChangeNotifier {
  GestaoMobileAssetsContextController({
    PerfilNegocioService? perfilNegocioService,
    EmpresaProvider? empresaProvider,
  }) : _perfilNegocioService = perfilNegocioService ?? PerfilNegocioService(),
       _empresaProvider = empresaProvider ?? EmpresaProvider();

  final PerfilNegocioService _perfilNegocioService;
  final EmpresaProvider _empresaProvider;

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
    scheduleMicrotask(refresh);
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
