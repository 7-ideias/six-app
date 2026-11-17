import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_app_router.dart';
import 'package:sixpos/presentation/navigation/web_destination_routes.dart';
import 'package:sixpos/presentation/navigation/web_navigation_item.dart';

void main() {
  testWidgets('module URLs, Back and Forward retain the live shell', (
    tester,
  ) async {
    final provider = _HistoryProvider('/app/produtos?filter=active');
    final key = GlobalKey<NavigatorState>();
    late WebAppRouter delegate;
    delegate = WebAppRouter(
      navigatorKey: key,
      routeFactory:
          (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder:
                (_) => _Shell(
                  initialDestination:
                      webDestinationForUri(Uri.parse(settings.name!))!,
                ),
          ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (_, __) => Router<Uri>(
              routerDelegate: delegate,
              routeInformationParser: const WebAppRouteParser(),
              routeInformationProvider: provider,
            ),
      ),
    );
    await tester.pumpAndSettle();
    final initialState = tester.state(find.byType(_Shell));
    expect(find.text('catalogProducts'), findsOneWidget);
    expect(
      delegate.currentConfiguration.toString(),
      '/app/produtos?filter=active',
    );

    await tester.tap(find.text('Open stock'));
    await tester.pumpAndSettle();
    expect(provider.reported.last.path, '/app/estoque');
    expect(find.text('catalogStock'), findsOneWidget);

    final count = provider.entries.length;
    provider.browserNavigate('/app/produtos?filter=active');
    await tester.pumpAndSettle();
    expect(find.text('catalogProducts'), findsOneWidget);
    expect(identical(initialState, tester.state(find.byType(_Shell))), isTrue);
    expect(delegate.currentConfiguration.query, 'filter=active');
    // A browser traversal must not create a duplicate history entry.
    expect(provider.entries.length, count);

    provider.browserNavigate('/app/estoque');
    await tester.pumpAndSettle();
    expect(find.text('catalogStock'), findsOneWidget);
    expect(identical(initialState, tester.state(find.byType(_Shell))), isTrue);
    await tester.pumpWidget(const SizedBox());
    delegate.dispose();
    provider.dispose();
  });

  testWidgets('dialogs keep module URL and standalone routes restore it', (
    tester,
  ) async {
    final provider = _HistoryProvider('/app/produtos');
    final key = GlobalKey<NavigatorState>();
    final delegate = WebAppRouter(
      navigatorKey: key,
      routeFactory:
          (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder:
                (_) =>
                    settings.name == '/app/assinatura'
                        ? const Scaffold(body: Text('Checkout'))
                        : const _Shell(
                          initialDestination:
                              WebNavigationDestination.catalogProducts,
                        ),
          ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (_, __) => Router<Uri>(
              routerDelegate: delegate,
              routeInformationParser: const WebAppRouteParser(),
              routeInformationProvider: provider,
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open stock'));
    await tester.pumpAndSettle();
    final shellContext = tester.element(find.byType(_Shell));
    showDialog<void>(
      context: shellContext,
      builder: (_) => const AlertDialog(content: Text('Dialog')),
    );
    await tester.pumpAndSettle();
    expect(delegate.currentConfiguration.path, '/app/estoque');
    key.currentState!.pop();
    await tester.pumpAndSettle();
    key.currentState!.pushNamed('/app/assinatura');
    await tester.pumpAndSettle();
    expect(provider.reported.last.path, '/app/assinatura');
    provider.browserNavigate('/app/estoque');
    await tester.pumpAndSettle();
    expect(find.text('Checkout'), findsNothing);
    expect(find.text('catalogStock'), findsOneWidget);
    provider.browserNavigate('/app/assinatura');
    await tester.pumpAndSettle();
    expect(find.text('Checkout'), findsOneWidget);
    expect(delegate.currentConfiguration.path, '/app/assinatura');
    await tester.pumpWidget(const SizedBox());
    delegate.dispose();
    provider.dispose();
  });
}

class _HistoryProvider extends RouteInformationProvider with ChangeNotifier {
  _HistoryProvider(String path)
    : _value = RouteInformation(uri: Uri.parse(path));
  RouteInformation _value;
  final reported = <Uri>[];
  final entries = <Uri>[];
  @override
  RouteInformation get value => _value;
  void browserNavigate(String path) {
    _value = RouteInformation(uri: Uri.parse(path));
    notifyListeners();
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation information, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    if (type == RouteInformationReportingType.navigate ||
        (type == RouteInformationReportingType.none &&
            _value.uri != information.uri)) {
      entries.add(information.uri);
    }
    _value = information;
    reported.add(information.uri);
  }
}

class _Shell extends StatefulWidget {
  const _Shell({required this.initialDestination});
  final WebNavigationDestination initialDestination;
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  late var destination = widget.initialDestination;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WebAppRouter.maybeOf(context)!.registerShell(ModalRoute.of(context)!, (
      next,
    ) async {
      setState(() => destination = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WebAppRouter.maybeOf(
          context,
        )!.reportDestination(ModalRoute.of(context)!, destination);
      }
    });
    return Scaffold(
      body: Column(
        children: [
          Text(destination.name),
          TextButton(
            onPressed:
                () => setState(
                  () => destination = WebNavigationDestination.catalogStock,
                ),
            child: const Text('Open stock'),
          ),
        ],
      ),
    );
  }
}
