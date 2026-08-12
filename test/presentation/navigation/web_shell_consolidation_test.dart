import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebShell consolidado', () {
    test('PaginaPrincipalWeb nao possui fallback OLD/NEW de navegacao', () {
      final File paginaPrincipal = File('lib/pagina_principal_web.dart');
      final String source = paginaPrincipal.readAsStringSync();

      expect(source, contains('AuthenticatedWebShell('));
      expect(source, isNot(contains('_useWebShellNavigation')));
      expect(source, isNot(contains('TopNavigationBarWeb')));
      expect(source, isNot(contains('top_navigation_bar_web.dart')));
    });

    test('TopNavigationBarWeb foi removido da arvore de codigo', () {
      expect(File('lib/top_navigation_bar_web.dart').existsSync(), isFalse);
    });
  });
}
