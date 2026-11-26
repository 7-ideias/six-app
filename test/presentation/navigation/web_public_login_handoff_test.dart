import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/utils/browser_location.dart';

void main() {
  group('web public login handoff', () {
    test('/login/flutter preserva LoginPageWeb no Flutter', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();
      final String loginSource =
          File('lib/presentation/screens/login_page_web.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/login/flutter'"));
      expect(mainSource, contains('builder: (_) => const LoginPageWeb()'));
      expect(loginSource, contains('isPhoneBrowser()'));
      expect(loginSource, contains("replaceBrowserLocation('/login')"));
    });

    test('/login no Flutter redireciona para HTML via browser', () {
      final String mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains("routeUri.path == '/login'"));
      expect(mainSource, contains('replaceBrowserLocation(widget.location)'));
      expect(mainSource, contains("fallbackRoute: '/login/flutter'"));
    });

    test('menu e bloqueio de cobrança usam o mesmo logout público', () {
      final shell = File('lib/pagina_principal_web.dart').readAsStringSync();
      final main = File('lib/main.dart').readAsStringSync();
      final logout =
          File(
            'lib/presentation/navigation/web_logout.dart',
          ).readAsStringSync();

      expect(shell, contains('confirmWebLogout(context)'));
      expect(main, contains('onExit: () => _exitWebBilling(context, company)'));
      expect(main, contains('await confirmWebLogout('));
      expect(logout, contains('await showSixWebLogoutDialog('));
      expect(logout, contains("replaceBrowserLocation('/login')"));
      expect(logout, isNot(contains('LoginPageWeb')));
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
