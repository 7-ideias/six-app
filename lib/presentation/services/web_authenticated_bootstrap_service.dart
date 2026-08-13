import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../../domain/services/aparencia/aparencia_service.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../domain/services/telainicial_web/tela_inicial_web_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/empresa_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/telainicial_web_provider.dart';
import '../../providers/usuario_provider.dart';

class WebAuthenticatedBootstrapService {
  static final WebAuthenticatedBootstrapService _instance =
      WebAuthenticatedBootstrapService._internal();

  factory WebAuthenticatedBootstrapService() => _instance;

  WebAuthenticatedBootstrapService._internal();

  Future<void>? _bootstrapFuture;
  String? _bootstrappedSessionKey;
  int _generation = 0;

  Future<void> bootstrap(BuildContext context, {bool force = false}) async {
    final ColaboradorAutorizacoesProvider autorizacoesProvider =
        context.read<ColaboradorAutorizacoesProvider>();
    final LocaleSettingsProvider localeProvider =
        context.read<LocaleSettingsProvider>();

    final String sessionKey = await _currentSessionKey();
    if (!force &&
        _bootstrapFuture == null &&
        _bootstrappedSessionKey == sessionKey) {
      return;
    }

    final Future<void>? current = _bootstrapFuture;
    if (current != null) {
      return current;
    }

    final int generation = _generation;
    final Future<void> bootstrapFuture = _bootstrapInternal(
      autorizacoesProvider: autorizacoesProvider,
      localeProvider: localeProvider,
    );
    _bootstrapFuture = bootstrapFuture;

    try {
      await bootstrapFuture;
      if (generation == _generation) {
        _bootstrappedSessionKey = sessionKey;
      }
    } finally {
      if (identical(_bootstrapFuture, bootstrapFuture)) {
        _bootstrapFuture = null;
      }
    }
  }

  void reset() {
    _generation += 1;
    _bootstrappedSessionKey = null;
    _bootstrapFuture = null;
  }

  void clearInMemorySession([BuildContext? context]) {
    reset();
    if (context != null) {
      context.read<ColaboradorAutorizacoesProvider>().limpar();
    }
    UsuarioProvider().clear();
    EmpresaProvider().clear();
    TelaInicialWebProvider().clear();
  }

  Future<void> _bootstrapInternal({
    required ColaboradorAutorizacoesProvider autorizacoesProvider,
    required LocaleSettingsProvider localeProvider,
  }) async {
    final String? idiomaDePreferencia =
        await UsuarioService().buscarDadosDoUsuario_atualizaProviders();

    await autorizacoesProvider.carregarAutorizacoesDoUsuarioLogado(force: true);

    try {
      final RegionalizacaoService regionalizacaoService = RegionalizacaoService(
        apiClient: HttpRegionalizacaoApiClient(),
      );
      final regionalizacao = await regionalizacaoService.buscarRegionalizacao();
      await localeProvider.applyAuthenticatedLocale(
        idiomaDePreferencia: idiomaDePreferencia,
        regionalizacao: regionalizacao,
      );
    } catch (e) {
      debugPrint('Erro ao aplicar idioma/regionalização no login web: $e');
    }

    try {
      final AparenciaService aparenciaService = AparenciaService(
        apiClient: HttpAparenciaApiClient(),
      );
      final config = await aparenciaService.buscarAparencia();
      SixThemeResolver().atualizarConfiguracao(config);
    } catch (e) {
      debugPrint('Erro ao carregar aparência no login web: $e');
    }

    await TelaInicialWebService().atualizaProviders();
  }

  Future<String> _currentSessionKey() async {
    final AuthService authService = AuthService();
    final String userId = (await authService.getUserId())?.trim() ?? '';
    final String empresaId = (await authService.getEmpresaId())?.trim() ?? '';
    return '$userId|$empresaId';
  }
}
