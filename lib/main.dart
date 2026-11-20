import 'presentation/screens/admin_push_campaigns_web_page.dart';
import 'dart:async';

import 'presentation/navigation/web_app_router.dart';
import 'presentation/navigation/web_destination_routes.dart';

import 'core/services/auth_service.dart';
import 'core/services/billing_http_client.dart';
import 'core/services/billing_return_service.dart';
import 'core/services/agenda_email_link_service.dart';
import 'presentation/screens/billing_access_web_page.dart';
import 'presentation/screens/billing_access_mobile_screen.dart';

import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/pagina_principal_web.dart';
import 'package:sixpos/presentation/screens/admin_portal_web_page.dart';
import 'package:sixpos/presentation/screens/admin_novas_ideias_web_page.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/presentation/screens/admin_usuarios_ativos_web_page.dart';
import 'package:sixpos/presentation/screens/admin_visual_assets_web_page.dart';
import 'package:sixpos/presentation/screens/login_page_web.dart';
import 'package:sixpos/presentation/screens/register_page_web.dart';
import 'package:sixpos/presentation/screens/esqueceu_senha_web.dart';
import 'package:sixpos/presentation/screens/cliente_auto_cadastro_publico_page.dart';
import 'package:sixpos/presentation/screens/colaborador_convite_publico_web_page.dart';
import 'package:sixpos/presentation/screens/colaborador_convite_mobile_page.dart';
import 'package:sixpos/presentation/screens/login_mobile.dart';
import 'package:sixpos/data/models/convite_link.dart';
import 'package:sixpos/presentation/screens/ordem_servico_publica_page.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_assinatura_publica_page.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_status_publico_page.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_lista_web_page.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_web_page.dart';
import 'package:sixpos/presentation/screens/status_atendimento_tecnico_config_web_page.dart';
import 'package:sixpos/presentation/screens/web_auth_gate.dart';
import 'package:sixpos/presentation/pages/web_root/web_root_page.dart';
import 'package:sixpos/presentation/components/six_web_splash_scene.dart';
import 'package:sixpos/presentation/screens/web_checkout_page.dart';
import 'package:sixpos/presentation/screens/web_trial_onboarding_page.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_theme_transition_overlay.dart';
import 'package:sixpos/presentation/navigation/web_auth_route_utils.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';
import 'package:sixpos/providers/empresa_provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/onboarding_inicial_provider.dart';
import 'package:sixpos/providers/produtos_list_provider.dart';
import 'package:sixpos/providers/streak_provider.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:sixpos/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixpos/core/services/firebase_push_notification_service.dart';

import 'core/services/notificacao_service.dart';
import 'core/services/produto_service.dart';
import 'core/services/push_navigation_service.dart';
import 'core/utils/browser_location.dart';
import 'core/ui/app_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    BillingReturnService.instance.initialize();
    AgendaEmailLinkService.instance.initialize();
  }
  if (kIsWeb) usePathUrlStrategy();
  final SharedPreferences? prefs = await _loadSharedPreferences();
  final ThemeProvider themeProvider = await ThemeProvider.load(
    enableLocalPersistence: !kIsWeb,
    storage: prefs == null
        ? null
        : SharedPreferencesThemePreferenceStorage(prefs),
  );

  if (!kIsWeb) {
    await NotificacaoService().initialize();
    await FirebasePushNotificationService.initializeBeforeRunApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(
          create: (_) => ProdutosListProvider<ProdutoModel>(
            fetchFunction: ProdutoService().produtosList,
          ),
        ),
        ChangeNotifierProvider(create: (_) => EmpresaProvider()),
        ChangeNotifierProvider(
          create: (_) => ColaboradorAutorizacoesProvider(),
        ),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingInicialProvider()),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: HttpRegionalizacaoApiClient(),
            ),
          )..initialize(),
        ),
      ],
      child: const MyApp(),
    ),
  );

  if (!kIsWeb) {
    unawaited(FirebasePushNotificationService.initializeOnAppStart());
  }
}

Future<SharedPreferences?> _loadSharedPreferences() async {
  try {
    return SharedPreferences.getInstance();
  } catch (error, stackTrace) {
    debugPrint('Erro ao inicializar SharedPreferences: $error\n$stackTrace');
    return null;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final WebAppRouter _webRouter = WebAppRouter(
    navigatorKey: PushNavigationService.navigatorKey,
    routeFactory: _onGenerateWebRoute,
  );
  final _webBackButtonDispatcher = RootBackButtonDispatcher();
  late final _webRouteInformationProvider = PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(uri: Uri.base),
  );

  @override
  void dispose() {
    if (kIsWeb) {
      _webRouter.dispose();
      _webRouteInformationProvider.dispose();
    }
    super.dispose();
  }

  Route<dynamic> _onGenerateWebRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '/';
    final Uri routeUri = Uri.parse(routeName);
    final destination = webDestinationForUri(routeUri);
    if (destination != null) {
      return _authenticatedWebRoute(
        settings: settings,
        page: PaginaPrincipalWeb(initialDestination: destination),
      );
    }

    if (routeUri.path == '/' || routeUri.path == '/home') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const WebAuthGate(
          requestedLocation: '/app',
          unauthenticatedChild: WebRootPage(),
          child: _BrowserLocationRedirectPage(
            location: '/app',
            fallbackRoute: '/app',
          ),
        ),
      );
    }
    if (routeUri.path == '/login') {
      return _browserLocationRoute(
        settings: settings,
        location: _formatWebLocation(routeUri),
        fallbackRoute: '/login/flutter',
      );
    }
    if (routeUri.path == '/login/flutter') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginPageWeb(),
      );
    }
    if (routeUri.path == '/admin') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginPageWeb(),
      );
    }
    if (routeUri.path == '/admin/dashboard') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AdminPortalWebPage(),
      );
    }
    if (routeUri.path == '/app/painel-super') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const PaginaPrincipalWeb(
          initialDestination: WebNavigationDestination.superPanel,
        ),
      );
    }
    if (routeUri.path == '/app/campanhas-push') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const PaginaPrincipalWeb(
          initialDestination: WebNavigationDestination.pushCampaigns,
        ),
      );
    }
    if (routeUri.path == '/admin/campanhas-push') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AdminPushCampaignsWebPage(),
      );
    }
    if (routeUri.path == '/admin/usuarios') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AdminUsuariosAtivosWebPage(),
      );
    }
    if (routeUri.path == '/admin/novas-ideias') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AdminNovasIdeiasWebPage(),
      );
    }
    if (routeUri.path == '/admin/planos' ||
        routeUri.path == '/app/admin/planos') {
      return _authenticatedWebRoute(
        settings: const RouteSettings(name: '/app/admin/planos'),
        page: const PaginaPrincipalWeb(
          initialDestination: WebNavigationDestination.adminPlans,
        ),
      );
    }
    if (routeUri.path == '/admin/imagens-contextuais') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AdminVisualAssetsWebPage(),
      );
    }
    if (routeUri.path == '/register') {
      return _browserLocationRoute(
        settings: settings,
        location: _formatWebLocation(routeUri),
        fallbackRoute: '/register/flutter',
      );
    }
    if (routeUri.path == '/register/flutter') {
      return _slidePageRoute(settings: settings, page: const RegisterPageWeb());
    }
    if (routeUri.path == '/forgot-password') {
      return _browserLocationRoute(
        settings: settings,
        location: _formatWebLocation(routeUri),
        fallbackRoute: '/forgot-password/flutter',
      );
    }
    if (routeUri.path == '/forgot-password/flutter') {
      return _slidePageRoute(
        settings: settings,
        page: const EsqueceuSenhaWeb(),
      );
    }
    if (routeUri.path == '/app') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const PaginaPrincipalWeb(),
      );
    }
    if (routeUri.path == '/app/atendimentos-tecnicos') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const AtendimentosTecnicosWebPage(),
      );
    }
    if (routeUri.path == '/app/atendimentos-tecnicos/criados') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const AtendimentosTecnicosListaWebPage(),
      );
    }
    if (routeUri.path == '/app/configuracoes/status-atendimento-tecnico') {
      return _authenticatedWebRoute(
        settings: settings,
        page: const StatusAtendimentoTecnicoConfigWebPage(),
      );
    }
    if (routeUri.path == '/atendimento/assinatura') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            AtendimentoTecnicoAssinaturaPublicaPage(initialUri: routeUri),
      );
    }
    if (routeUri.path == '/atendimento/status') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            AtendimentoTecnicoStatusPublicoPage(initialUri: routeUri),
      );
    }
    if (routeUri.path == '/onboarding') {
      return _browserLocationRoute(
        settings: settings,
        location: _formatWebLocation(routeUri),
        fallbackRoute: '/onboarding/flutter',
      );
    }
    if (routeUri.path == '/onboarding/flutter') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => WebTrialOnboardingPage(initialUri: routeUri),
      );
    }
    if (routeUri.path == '/checkout') {
      return _browserLocationRoute(
        settings: settings,
        location: _formatWebLocation(routeUri),
        fallbackRoute: '/checkout/flutter',
      );
    }
    if (routeUri.path == '/checkout/flutter' ||
        routeUri.path == '/app/assinatura') {
      return _authenticatedWebRoute(
        settings: RouteSettings(
          name: Uri(
            path: '/app/assinatura',
            queryParameters: routeUri.queryParameters.isEmpty
                ? null
                : routeUri.queryParameters,
          ).toString(),
        ),
        page: WebCheckoutPage(initialUri: routeUri),
      );
    }

    final bool isPublicOsRoute =
        routeUri.pathSegments.isNotEmpty &&
        routeUri.pathSegments.first == 'ordem-servico';
    final bool isPublicClienteAutoCadastroRoute =
        routeUri.pathSegments.length == 2 &&
        routeUri.pathSegments[0] == 'cliente' &&
        routeUri.pathSegments[1] == 'auto-cadastro';
    final bool isFlutterClienteAutoCadastroRoute =
        routeUri.pathSegments.length == 3 &&
        routeUri.pathSegments[0] == 'cliente' &&
        routeUri.pathSegments[1] == 'auto-cadastro' &&
        routeUri.pathSegments[2] == 'flutter';
    final bool isPublicColaboradorConviteRoute =
        routeUri.pathSegments.length == 3 &&
        routeUri.pathSegments[0] == 'colaborador' &&
        routeUri.pathSegments[1] == 'convites' &&
        routeUri.pathSegments[2] != 'flutter';
    final bool isFlutterColaboradorConviteRoute =
        routeUri.pathSegments.length == 4 &&
        routeUri.pathSegments[0] == 'colaborador' &&
        routeUri.pathSegments[1] == 'convites' &&
        routeUri.pathSegments[2] == 'flutter';

    if (isPublicColaboradorConviteRoute) {
      return _browserLocationRoute(
        settings: settings,
        location: _formatWebLocation(routeUri),
        fallbackRoute:
            '/colaborador/convites/flutter/${routeUri.pathSegments[2]}',
      );
    }
    if (isFlutterColaboradorConviteRoute) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ColaboradorConvitePublicoWebPage(
          codigo: routeUri.pathSegments[3],
        ),
      );
    }
    if (isPublicClienteAutoCadastroRoute) {
      return _browserLocationRoute(
        settings: settings,
        location: _formatWebLocation(routeUri),
        fallbackRoute: '/cliente/auto-cadastro/flutter',
      );
    }
    if (isFlutterClienteAutoCadastroRoute) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ClienteAutoCadastroPublicoPage(initialUri: routeUri),
      );
    }
    if (isPublicOsRoute) {
      final String ordemId = routeUri.pathSegments.length > 1
          ? routeUri.pathSegments[1]
          : 'os-sem-id';
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            OrdemServicoPublicaPage(ordemId: ordemId, initialUri: routeUri),
      );
    }

    if (isAuthenticatedWebAppRoute(routeUri)) {
      return _authenticatedWebRoute(
        settings: settings,
        page: const PaginaPrincipalWeb(),
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const WebRootPage(),
    );
  }

  String _formatWebLocation(Uri uri) {
    final String query = uri.hasQuery ? '?${uri.query}' : '';
    final String fragment = uri.hasFragment ? '#${uri.fragment}' : '';
    return '${uri.path}$query$fragment';
  }

  MaterialPageRoute<void> _browserLocationRoute({
    required RouteSettings settings,
    required String location,
    required String fallbackRoute,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _BrowserLocationRedirectPage(
        location: location,
        fallbackRoute: fallbackRoute,
      ),
    );
  }

  MaterialPageRoute<void> _authenticatedWebRoute({
    required RouteSettings settings,
    required Widget page,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) =>
          WebAuthGate(requestedLocation: settings.name, child: page),
    );
  }

  PageRouteBuilder<void> _slidePageRoute({
    required RouteSettings settings,
    required Widget page,
  }) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final slide =
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            );
        final fade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  Widget _destinoDoConvite(ConviteLink convite) =>
      convite.login
          ? LoginPageMobile(emailInicial: convite.email)
          : ColaboradorConviteMobilePage(codigo: convite.codigo);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleSettingsProvider>();

    return MaterialApp(
      navigatorKey: kIsWeb ? null : PushNavigationService.navigatorKey,
      scaffoldMessengerKey: AppFeedback.scaffoldMessengerKey,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'SixoApp',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeAnimationDuration: kIsWeb
          ? kThemeAnimationDuration
          : const Duration(milliseconds: 320),
      themeAnimationCurve: kIsWeb ? Curves.linear : Curves.easeOutCubic,
      builder: (BuildContext context, Widget? child) {
        final Widget resolvedChild = kIsWeb
            ? Router<Uri>(
                routerDelegate: _webRouter,
                routeInformationProvider: _webRouteInformationProvider,
                routeInformationParser: const WebAppRouteParser(),
                backButtonDispatcher: _webBackButtonDispatcher,
              )
            : child ?? const SizedBox.shrink();
        return ValueListenableBuilder<String?>(
          valueListenable: paymentRequiredCompany,
          builder: (context, company, _) => Stack(
            children: [
              ExcludeSemantics(
                excluding: company != null,
                child: FocusScope(
                  descendantsAreFocusable: company == null,
                  child: IgnorePointer(
                    ignoring: company != null,
                    child: kIsWeb
                        ? resolvedChild
                        : SixMobileThemeTransitionOverlay(child: resolvedChild),
                  ),
                ),
              ),
              if (company != null)
                Positioned.fill(
                  child: kIsWeb
                      ? BillingAccessWebPage(
                          key: ValueKey('$company:$paymentRequiredCampaignId'),
                          campaignId: paymentRequiredCampaignId,
                          companyId: company,
                          onExit: _exitBilling,
                        )
                      : BillingAccessMobileScreen(
                          key: ValueKey('$company:$paymentRequiredCampaignId'),
                          campaignId: paymentRequiredCampaignId,
                          companyId: company,
                          onExit: _exitBilling,
                        ),
                ),
            ],
          ),
        );
      },
      locale: localeProvider.currentLocale,
      supportedLocales: LocaleSettingsProvider.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateInitialRoutes: kIsWeb ? null : (name) {
        final link = ConviteLink.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName)
            ?? ConviteLink.parse(name);
        // Agenda links continue from the splash screen after authentication.
        return [MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/'),
          builder: (_) => link == null ? const SplashScreen() : _destinoDoConvite(link),
        )];
      },
      onGenerateRoute: kIsWeb ? null : (settings) {
        final link = ConviteLink.parse(settings.name);
        if (link == null) return null;
        return MaterialPageRoute<void>(settings: settings, builder: (_) => _destinoDoConvite(link));
      },
      routes: kIsWeb ? const {} : {'/': (_) => const SplashScreen()},
      initialRoute: kIsWeb ? null : '/',
    );
  }
}

class _BrowserLocationRedirectPage extends StatefulWidget {
  const _BrowserLocationRedirectPage({
    required this.location,
    required this.fallbackRoute,
  });

  final String location;
  final String fallbackRoute;

  @override
  State<_BrowserLocationRedirectPage> createState() =>
      _BrowserLocationRedirectPageState();
}

class _BrowserLocationRedirectPageState
    extends State<_BrowserLocationRedirectPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (replaceBrowserLocation(widget.location)) {
        return;
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(widget.fallbackRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SixWebSplashScene());
  }
}

class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appTitle = l10n?.appTitle ?? 'SixoApp';

    return Scaffold(
      appBar: AppBar(title: Text('$appTitle - $slug')),
      body: Center(child: Text('Catálogo: $slug')),
    );
  }
}

Future<void> _exitBilling() async {
  await AuthService().logout();
  PushNavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => kIsWeb ? const LoginPageWeb() : const SplashScreen(),
    ),
    (_) => false,
  );
}
