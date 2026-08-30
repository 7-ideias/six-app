import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/loading_do_mobile_comunicando_com_backend_controller.dart';
import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../../providers/onboarding_inicial_provider.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../components/mobile/sixoapp_mobile_loading_scene.dart';
import '../navigation/mobile_navigation_controller.dart';
import 'mobile_main_shell.dart';
import 'onboarding_inicial_mobile_screen.dart';

class PostLoginSplashMobilePage extends StatefulWidget {
  const PostLoginSplashMobilePage({super.key});

  @override
  State<PostLoginSplashMobilePage> createState() =>
      _PostLoginSplashMobilePageState();
}

class _PostLoginSplashMobilePageState extends State<PostLoginSplashMobilePage> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepareSessionAndNavigate();
  }

  Future<void> _prepareSessionAndNavigate() async {
    if (mounted) setState(() => _failed = false);
    try {
      await LoadingDoMobileComunicandoComBackendController.track<void>(() async {
        await _bootstrapAuthenticatedSession();
      });
    } catch (error, stackTrace) {
      debugPrint('Erro ao preparar sessao pos-login mobile: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _failed = true);
      return;
    }

    if (!mounted) return;

    if (context.read<OnboardingInicialProvider>().precisaFazerOnboarding) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => OnboardingInicialMobileScreen(
            onCompleted: _replaceWithHome,
          ),
        ),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const MobileMainShell(
          initialIndex: MobileNavigationController.dashIndex,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _bootstrapAuthenticatedSession() async {
    final idiomaDePreferencia = await UsuarioService()
        .buscarDadosDoUsuario_atualizaProviders();

    if (!mounted) return;
    await context
        .read<ColaboradorAutorizacoesProvider>()
        .carregarAutorizacoesDoUsuarioLogado(force: true);
    await context.read<OnboardingInicialProvider>().carregar(force: true);

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
    if (_failed) {
      final SixMobileColorScheme colors = context.sixMobileColors;
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.cloud_off_rounded, color: colors.error, size: 38),
                  const SizedBox(height: 14),
                  Text(
                    context.t(
                      'initialOnboarding.loadErrorTitle',
                      fallback: 'Não foi possível preparar sua conta',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.titleText,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t(
                      'initialOnboarding.loadErrorMessage',
                      fallback:
                          'Sua sessão foi preservada. Verifique a conexão e tente novamente.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.mutedText, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _prepareSessionAndNavigate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      context.t('common.tryAgain', fallback: 'Tentar novamente'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SixoAppMobileLoadingScene(
        message: context.t(
          'splash.syncingAccount',
          fallback: 'Sincronizando seus dados...',
        ),
      ),
    );
  }

  void _replaceWithHome(BuildContext onboardingContext) {
    Navigator.of(onboardingContext).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MobileMainShell(
          initialIndex: MobileNavigationController.dashIndex,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }
}
