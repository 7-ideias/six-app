import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Devolucoes Produtos Web Theme', () {
    late String source;

    setUpAll(() {
      source =
          File(
            'lib/presentation/screens/devolucoes_produtos_jornada.dart',
          ).readAsStringSync();
    });

    test('aplica WebThemeTokens no fluxo web e evita feedback hardcoded', () {
      expect(source, contains('AnimatedTheme('));
      expect(source, contains('WebThemeTokens.applyTo(baseTheme)'));
      expect(source, contains('workspaceBackground'));
      expect(source, contains('cardBorder'));
      expect(source, contains('inputBackground'));
      expect(source, contains('surfaceMuted'));
      expect(source, contains('selectedBackground'));
      expect(source, contains('selectedBorder'));
      expect(source, contains('primaryText'));
      expect(source, contains('secondaryText'));
      expect(source, contains('success'));
      expect(source, contains('danger'));
      expect(source, contains('info'));

      expect(source, isNot(contains('const Color(0xFF10B981)')));
      expect(source, isNot(contains('const Color(0xFF047857)')));
    });
  });
}
