import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_auth_route_utils.dart';

void main() {
  group('web public forgot password handoff', () {
    test('/forgot-password no Flutter redireciona para HTML via browser', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/forgot-password'"));
      expect(mainSource, contains('replaceBrowserLocation(widget.location)'));
      expect(mainSource, contains("fallbackRoute: '/forgot-password/flutter'"));
    });

    test('/forgot-password/flutter preserva EsqueceuSenhaWeb no Flutter', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(
        mainSource,
        contains("routeUri.path == '/forgot-password/flutter'"),
      );
      expect(mainSource, contains('page: const EsqueceuSenhaWeb()'));
    });

    test('login Flutter Web prefere recuperacao publica HTML', () {
      final String loginSource =
          File(
            'lib/presentation/screens/login_page_web.dart',
          ).readAsStringSync();

      expect(
        loginSource,
        contains("assignBrowserLocation('/forgot-password')"),
      );
      expect(
        loginSource,
        contains("Navigator.pushNamed(context, '/forgot-password/flutter')"),
      );
    });

    test('/forgot-password fica fora do WebAuthGate', () {
      expect(
        isAuthenticatedWebAppRoute(Uri.parse('/forgot-password')),
        isFalse,
      );
      expect(
        isAuthenticatedWebAppRoute(Uri.parse('/forgot-password/flutter')),
        isFalse,
      );
      expect(isAuthenticatedWebAppRoute(Uri.parse('/app')), isTrue);
      expect(isAuthenticatedWebAppRoute(Uri.parse('/app/clientes')), isTrue);
      expect(isAuthenticatedWebAppRoute(Uri.parse('/admin')), isFalse);
    });

    test('vercel serve HTML e preserva fallback Flutter', () {
      final String vercelSource = File('vercel.json').readAsStringSync();

      expect(vercelSource, contains('"source": "/forgot-password"'));
      expect(vercelSource, contains('"destination": "/forgot-password.html"'));
      expect(vercelSource, contains('"source": "/forgot-password/flutter"'));
      expect(vercelSource, contains('"destination": "/flutter.html"'));
      expect(vercelSource, contains('"source": "/login/flutter"'));
      expect(vercelSource, contains('"source": "/register/flutter"'));
      expect(vercelSource, contains('"source": "/onboarding"'));
      expect(vercelSource, contains('"source": "/checkout"'));
      expect(vercelSource, contains('"source": "/app"'));
      expect(vercelSource, contains('"source": "/admin"'));
    });
  });
}
