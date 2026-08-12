import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Web header actions theme isolation', () {
    test('acoes globais do header nao dependem visualmente de _pdvTheme', () {
      final String source =
          File('lib/pagina_principal_web.dart').readAsStringSync();

      for (final String methodName in <String>[
        '_buildIndicadorComunicacaoBackend',
        '_buildIAAssistente',
        '_buildUserMenuButton',
        '_buildNotificationBellButton',
      ]) {
        expect(
          _methodSource(source, methodName),
          isNot(contains('_pdvTheme')),
          reason: methodName,
        );
      }
    });

    test('status backend usa tokens semanticos Web', () {
      final String source =
          File('lib/pagina_principal_web.dart').readAsStringSync();
      final String method = _methodSource(source, '_corStatusBackend');

      expect(method, contains('tokens.success'));
      expect(method, contains('tokens.warning'));
      expect(method, contains('tokens.danger'));
    });
  });
}

String _methodSource(String source, String methodName) {
  final int start = source.indexOf(methodName);
  if (start == -1) {
    fail('Metodo nao encontrado: $methodName');
  }

  int braceIndex = source.indexOf('{', start);
  if (braceIndex == -1) {
    fail('Corpo nao encontrado: $methodName');
  }

  int depth = 0;
  for (int index = braceIndex; index < source.length; index++) {
    final String character = source[index];
    if (character == '{') depth++;
    if (character == '}') depth--;
    if (depth == 0) {
      return source.substring(start, index + 1);
    }
  }

  fail('Fim do corpo nao encontrado: $methodName');
}
