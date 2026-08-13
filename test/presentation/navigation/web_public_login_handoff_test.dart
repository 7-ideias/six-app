import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/utils/browser_location.dart';

void main() {
  group('web public login handoff', () {
    test('/login/flutter preserva LoginPageWeb no Flutter', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/login/flutter'"));
      expect(mainSource, contains('builder: (_) => const LoginPageWeb()'));
    });

    test('/login no Flutter redireciona para HTML via browser', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/login'"));
      expect(mainSource, contains('replaceBrowserLocation(widget.location)'));
      expect(mainSource, contains("fallbackRoute: '/login/flutter'"));
    });

    test('logout Web usa navegacao completa para login publico', () {
      final String source = File('lib/pagina_principal_web.dart').readAsStringSync();

      expect(source, contains("replaceBrowserLocation('/login')"));
      expect(
        source,
        isNot(
          contains('MaterialPageRoute<void>(builder: (_) => const LoginPageWeb())'),
        ),
      );
    });

    test('sessao invalida no WebAuthGate usa navegacao completa', () {
      final String source =
          File('lib/presentation/screens/web_auth_gate.dart').readAsStringSync();

      expect(
        source,
        contains('replaceBrowserLocation(_activeController.loginRoute)'),
      );
    });

    test('admin continua no Flutter', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/admin'"));
      expect(mainSource, contains('builder: (_) => const LoginPageWeb()'));
      expect(mainSource, contains("routeUri.path == '/admin/dashboard'"));
    });

    test('stub nao Web nao usa navegacao de browser', () {
      expect(assignBrowserLocation('/login'), isFalse);
      expect(replaceBrowserLocation('/login'), isFalse);
    });
  });
}
