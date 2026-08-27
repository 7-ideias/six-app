import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/loading_do_mobile_comunicando_com_backend_controller.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/sixoapp_mobile_loading_scene.dart';
import '../navigation/mobile_navigation_controller.dart';
import 'mobile_main_shell.dart';

class PostLoginSplashMobilePage extends StatefulWidget {
  const PostLoginSplashMobilePage({super.key});

  @override
  State<PostLoginSplashMobilePage> createState() =>
      _PostLoginSplashMobilePageState();
}

class _PostLoginSplashMobilePageState extends State<PostLoginSplashMobilePage> {
  @override
  void initState() {
    super.initState();
    _prepareSessionAndNavigate();
  }

  Future<void> _prepareSessionAndNavigate() async {
    await LoadingDoMobileComunicandoComBackendController.track<void>(() async {
      await _guardedBootstrap();
    });

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const MobileMainShell(
          initialIndex: MobileNavigationController.dashIndex,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _guardedBootstrap() async {
    try {
      await _bootstrapAuthenticatedSession();
    } catch (error, stackTrace) {
      debugPrint('Erro ao preparar sessao pos-login mobile: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _bootstrapAuthenticatedSession() async {
    final idiomaDePreferencia = await UsuarioService()
        .buscarDadosDoUsuario_atualizaProviders();

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
    } catch (error) {
      debugPrint(
        'Erro ao aplicar idioma/regionalizacao no login mobile: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SixoAppMobileLoadingScene(
        message: context.t(
          'splash.syncingAccount',
          fallback: 'Sincronizando seus dados...',
        ),
      ),
    );
  }
}
