import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_auth_route_utils.dart';

void main() {
  group('web public onboarding handoff', () {
    test('/onboarding no Flutter redireciona para HTML via browser', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/onboarding'"));
      expect(mainSource, contains('replaceBrowserLocation(widget.location)'));
      expect(mainSource, contains("fallbackRoute: '/onboarding/flutter'"));
    });

    test('/onboarding/flutter preserva WebTrialOnboardingPage no Flutter', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/onboarding/flutter'"));
      expect(
        mainSource,
        contains(
          'builder: (_) => WebTrialOnboardingPage(initialUri: routeUri)',
        ),
      );
    });

    test('/onboarding fica fora do WebAuthGate', () {
      expect(isAuthenticatedWebAppRoute(Uri.parse('/onboarding')), isFalse);
      expect(
        isAuthenticatedWebAppRoute(Uri.parse('/onboarding/flutter')),
        isFalse,
      );
    });

    test('vercel serve HTML e preserva fallback Flutter', () {
      final String vercelSource = File('vercel.json').readAsStringSync();

      expect(vercelSource, contains('"source": "/onboarding"'));
      expect(vercelSource, contains('"destination": "/onboarding.html"'));
      expect(vercelSource, contains('"source": "/onboarding/flutter"'));
      expect(vercelSource, contains('"destination": "/flutter.html"'));
    });

    test('rotas publicas e autenticadas principais continuam corretas', () {
      final String vercelSource = File('vercel.json').readAsStringSync();

      expect(vercelSource, contains('"source": "/login/flutter"'));
      expect(vercelSource, contains('"source": "/register/flutter"'));
      expect(vercelSource, contains('"source": "/forgot-password/flutter"'));
      expect(vercelSource, contains('"source": "/checkout"'));
      expect(vercelSource, contains('"source": "/app"'));
      expect(vercelSource, contains('"source": "/app/:path*"'));
      expect(vercelSource, contains('"source": "/admin"'));
      expect(vercelSource, contains('"source": "/admin/:path*"'));
      expect(isAuthenticatedWebAppRoute(Uri.parse('/app')), isTrue);
      expect(isAuthenticatedWebAppRoute(Uri.parse('/app/clientes')), isTrue);
      expect(isAuthenticatedWebAppRoute(Uri.parse('/admin')), isFalse);
    });
  });
}
