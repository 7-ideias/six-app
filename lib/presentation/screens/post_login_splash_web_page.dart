import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../../domain/services/aparencia/aparencia_service.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../domain/services/telainicial_web/tela_inicial_web_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/six_splash_scene.dart';

class PostLoginSplashWebPage extends StatefulWidget {
  const PostLoginSplashWebPage({super.key, required this.nextRoute});

  final String nextRoute;

  @override
  State<PostLoginSplashWebPage> createState() => _PostLoginSplashWebPageState();
}

class _PostLoginSplashWebPageState extends State<PostLoginSplashWebPage> {
  static const Duration _minimumDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _prepareSessionAndNavigate();
  }

  Future<void> _prepareSessionAndNavigate() async {
    await Future.wait<void>([
      _guardedBootstrap(),
      Future<void>.delayed(_minimumDuration),
    ]);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      widget.nextRoute,
      (route) => false,
    );
  }

  Future<void> _guardedBootstrap() async {
    try {
      await _bootstrapAuthenticatedSession();
    } catch (error, stackTrace) {
      debugPrint('Erro ao preparar sessão pós-login web: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _bootstrapAuthenticatedSession() async {
    final idiomaDePreferencia =
        await UsuarioService().buscarDadosDoUsuario_atualizaProviders();

    if (!mounted) return;
    await context
        .read<ColaboradorAutorizacoesProvider>()
        .carregarAutorizacoesDoUsuarioLogado(force: true);

    try {
      final regionalizacaoService = RegionalizacaoService(
        apiClient: HttpRegionalizacaoApiClient(),
      );
      final regionalizacao = await regionalizacaoService.buscarRegionalizacao();
      if (!mounted) return;
      await context.read<LocaleSettingsProvider>().applyAuthenticatedLocale(
        idiomaDePreferencia: idiomaDePreferencia,
        regionalizacao: regionalizacao,
      );
    } catch (e) {
      debugPrint('Erro ao aplicar idioma/regionalização no login: $e');
    }

    try {
      final aparenciaService = AparenciaService(
        apiClient: HttpAparenciaApiClient(),
      );
      final config = await aparenciaService.buscarAparencia();
      SixThemeResolver().atualizarConfiguracao(config);
    } catch (e) {
      debugPrint('Erro ao carregar aparência no login: $e');
    }

    await TelaInicialWebService().atualizaProviders();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SixSplashScene(),
    );
  }
}
