import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('admin route decision', () {
    test('mantem admin fora do WebAuthGate e preserva dashboard pos-login', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();
      final String loginSource =
          File(
            'lib/presentation/screens/login_page_web.dart',
          ).readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/admin'"));
      expect(mainSource, contains('builder: (_) => const LoginPageWeb()'));
      expect(mainSource, contains("routeUri.path == '/login/flutter'"));
      expect(mainSource, contains("routeUri.path == '/admin/dashboard'"));
      expect(mainSource, contains("routeUri.path == '/admin/planos'"));
      expect(
        mainSource,
        contains('builder: (_) => const AdminPortalWebPage()'),
      );
      expect(
        mainSource,
        contains('builder: (_) => const AdminPlanosWebPage()'),
      );
      expect(loginSource, contains("if (uri.path == '/admin')"));
      expect(loginSource, contains("return '/admin/dashboard';"));
      expect(loginSource, contains('sanitizeAuthenticatedWebRedirect'));
    });
  });
}
