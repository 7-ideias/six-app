import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_auth_route_utils.dart';

void main() {
  group('web public checkout handoff', () {
    test('/checkout no Flutter redireciona para HTML via browser', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/checkout'"));
      expect(mainSource, contains('replaceBrowserLocation(widget.location)'));
      expect(mainSource, contains("fallbackRoute: '/checkout/flutter'"));
    });

    test('/checkout/flutter preserva WebCheckoutPage no Flutter', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/checkout/flutter'"));
      expect(
        mainSource,
        contains('builder: (_) => WebCheckoutPage(initialUri: routeUri)'),
      );
    });

    test('antiga Home Flutter prefere checkout publico HTML', () {
      final String source =
          File(
            'lib/presentation/pages/web_root/web_root_page.dart',
          ).readAsStringSync();

      expect(source, contains("path: '/checkout'"));
      expect(source, contains('assignBrowserLocation(htmlLocation)'));
      expect(source, contains("path: '/checkout/flutter'"));
    });

    test('onboarding Flutter fallback prefere checkout publico HTML', () {
      final String source =
          File(
            'lib/presentation/screens/web_trial_onboarding_page.dart',
          ).readAsStringSync();

      expect(source, contains("assignBrowserLocation('/checkout')"));
      expect(
        source,
        contains("Navigator.pushNamed(context, '/checkout/flutter')"),
      );
      expect(
        source,
        isNot(contains("Navigator.pushNamed(context, '/checkout')")),
      );
    });

    test('/checkout fica fora do WebAuthGate', () {
      expect(isAuthenticatedWebAppRoute(Uri.parse('/checkout')), isFalse);
      expect(
        isAuthenticatedWebAppRoute(Uri.parse('/checkout/flutter')),
        isFalse,
      );
    });

    test('vercel serve HTML e preserva fallback Flutter', () {
      final String vercelSource = File('vercel.json').readAsStringSync();

      expect(vercelSource, contains('"source": "/checkout"'));
      expect(vercelSource, contains('"destination": "/checkout.html"'));
      expect(vercelSource, contains('"source": "/checkout/flutter"'));
      expect(vercelSource, contains('"destination": "/flutter.html"'));
    });

    test('rotas publicas e autenticadas principais continuam corretas', () {
      final String vercelSource = File('vercel.json').readAsStringSync();

      for (final route in <String>[
        '/login/flutter',
        '/register/flutter',
        '/forgot-password/flutter',
        '/onboarding/flutter',
        '/checkout/flutter',
        '/app',
        '/app/:path*',
        '/admin',
        '/admin/:path*',
      ]) {
        expect(vercelSource, contains('"source": "$route"'));
      }

      expect(isAuthenticatedWebAppRoute(Uri.parse('/app')), isTrue);
      expect(isAuthenticatedWebAppRoute(Uri.parse('/app/clientes')), isTrue);
      expect(isAuthenticatedWebAppRoute(Uri.parse('/admin')), isFalse);
    });
  });
}
