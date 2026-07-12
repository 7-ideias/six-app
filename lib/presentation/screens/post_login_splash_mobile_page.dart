import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/loading_do_mobile_comunicando_com_backend_controller.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/six_lottie_action_overlay.dart';
import '../components/web_auth_logout_splash_scene.dart';
import 'home_page_mobile_screen.dart';

class PostLoginSplashMobilePage extends StatefulWidget {
  const PostLoginSplashMobilePage({super.key});

  @override
  State<PostLoginSplashMobilePage> createState() =>
      _PostLoginSplashMobilePageState();
}

class _PostLoginSplashMobilePageState extends State<PostLoginSplashMobilePage> {
  static const Duration _minimumDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _prepareSessionAndNavigate();
  }

  Future<void> _prepareSessionAndNavigate() async {
    await LoadingDoMobileComunicandoComBackendController.track<void>(() async {
      await Future.wait<void>([
        _guardedBootstrap(),
        Future<void>.delayed(_minimumDuration),
      ]);
    });

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomePageMobile(title: 'Home'),
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
    } catch (error) {
      debugPrint('Erro ao aplicar idioma/regionalizacao no login mobile: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable:
          LoadingDoMobileComunicandoComBackendController.activeOperations,
      child: const Scaffold(body: WebAuthLogoutSplashScene()),
      builder: (BuildContext context, int activeOperations, Widget? child) {
        return SixLottieActionOverlay(
          isLoading: activeOperations > 0,
          title: 'Preparando seu acesso',
          subtitle: 'Sincronizando seus dados, permissões e preferências.',
          child: child!,
        );
      },
    );
  }
}
