import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_auth_route_utils.dart';

void main() {
  group('web public register handoff', () {
    test('/register no Flutter redireciona para HTML via browser', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/register'"));
      expect(mainSource, contains('replaceBrowserLocation(widget.location)'));
      expect(mainSource, contains("fallbackRoute: '/register/flutter'"));
    });

    test('/register/flutter preserva RegisterPageWeb no Flutter', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/register/flutter'"));
      expect(mainSource, contains('page: const RegisterPageWeb()'));
    });

    test('login Flutter Web prefere cadastro publico HTML', () {
      final String loginSource =
          File(
            'lib/presentation/screens/login_page_web.dart',
          ).readAsStringSync();

      expect(loginSource, contains("assignBrowserLocation('/register')"));
      expect(
        loginSource,
        contains("Navigator.pushNamed(context, '/register/flutter')"),
      );
      expect(
        loginSource,
        isNot(contains('builder: (_) => const RegisterPageWeb()')),
      );
    });

    test('/app continua protegido pelo WebAuthGate', () {
      expect(isAuthenticatedWebAppRoute(Uri.parse('/app')), isTrue);
      expect(isAuthenticatedWebAppRoute(Uri.parse('/app/clientes')), isTrue);
    });

    test('/admin continua fora do WebAuthGate e servido pelo Flutter', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(isAuthenticatedWebAppRoute(Uri.parse('/admin')), isFalse);
      expect(mainSource, contains("routeUri.path == '/admin'"));
      expect(mainSource, contains('builder: (_) => const LoginPageWeb()'));
      expect(mainSource, contains("routeUri.path == '/admin/dashboard'"));
    });
  });
}
