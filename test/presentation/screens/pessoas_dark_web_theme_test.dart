import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pessoas Dark Web', () {
    late String clientesSource;
    late String clienteCadastroSource;
    late String clienteAutoCadastroSource;
    late String clienteSubPainelSource;
    late String colaboradoresSource;
    late String colaboradorConviteSource;
    late String desempenhoSource;

    setUpAll(() {
      clientesSource =
          File(
            'lib/presentation/screens/clientes_usuario_list_page.dart',
          ).readAsStringSync();
      clienteCadastroSource =
          File(
            'lib/presentation/screens/cliente_usuario_cadastro_web_dialog.dart',
          ).readAsStringSync();
      clienteAutoCadastroSource =
          File(
            'lib/presentation/screens/cliente_auto_cadastro_link_section.dart',
          ).readAsStringSync();
      clienteSubPainelSource =
          File('lib/sub_painel_cadastro_cliente.dart').readAsStringSync();
      colaboradoresSource =
          File(
            'lib/presentation/screens/colaboradores_usuario_web_page.dart',
          ).readAsStringSync();
      colaboradorConviteSource =
          File(
            'lib/presentation/screens/colaborador_convite_web_body.dart',
          ).readAsStringSync();
      desempenhoSource =
          File(
            'lib/presentation/screens/desempenho_colaborador_web_page.dart',
          ).readAsStringSync();
    });

    test(
      'Clientes usa WebThemeTokens em superficies, busca, status e modais',
      () {
        expect(clientesSource, contains('web_theme_tokens.dart'));
        expect(clienteCadastroSource, contains('web_theme_tokens.dart'));
        expect(clienteAutoCadastroSource, contains('web_theme_tokens.dart'));
        expect(clienteSubPainelSource, contains('web_theme_tokens.dart'));

        expect(clientesSource, contains('tokens.workspaceBackground'));
        expect(clientesSource, contains('tokens.cardBackground'));
        expect(clientesSource, contains('tokens.inputBackground'));
        expect(clientesSource, contains('tokens.success'));
        expect(clientesSource, contains('tokens.statusNeutral'));
        expect(clientesSource, contains('tokens.danger'));

        expect(clienteCadastroSource, contains('tokens.surfaceMuted'));
        expect(clienteCadastroSource, contains('tokens.inputBackground'));
        expect(clienteCadastroSource, contains('tokens.selectedBackground'));
        expect(clienteSubPainelSource, contains('tokens.surfaceElevated'));
        expect(clienteSubPainelSource, contains('tokens.workspaceBackground'));
        expect(clienteAutoCadastroSource, contains('tokens.surfaceElevated'));
        expect(
          clienteAutoCadastroSource,
          contains('tokens.selectedBackground'),
        );

        expect(clientesSource, isNot(contains('Colors.green.shade700')));
      },
    );

    test(
      'Colaboradores usa WebThemeTokens em lista, permissoes, disabled e dialogs',
      () {
        expect(colaboradoresSource, contains('web_theme_tokens.dart'));
        expect(colaboradorConviteSource, contains('web_theme_tokens.dart'));

        expect(colaboradoresSource, contains('tokens.workspaceBackground'));
        expect(colaboradoresSource, contains('tokens.cardBackground'));
        expect(colaboradoresSource, contains('tokens.inputBackground'));
        expect(colaboradoresSource, contains('tokens.selectedBackground'));
        expect(colaboradoresSource, contains('tokens.success'));
        expect(colaboradoresSource, contains('tokens.statusNeutral'));
        expect(colaboradoresSource, contains('tokens.surfaceElevated'));

        expect(colaboradorConviteSource, contains('tokens.inputBackground'));
        expect(colaboradorConviteSource, contains('tokens.selectedBackground'));
        expect(colaboradorConviteSource, contains('tokens.disabledBackground'));
        expect(colaboradorConviteSource, contains('tokens.disabledForeground'));

        expect(colaboradoresSource, isNot(contains('Colors.green.shade700')));
      },
    );

    test('Desempenho usa tokens em KPIs, filtros, status e dialogs', () {
      expect(desempenhoSource, contains('web_theme_tokens.dart'));
      expect(desempenhoSource, contains('tokens.workspaceBackground'));
      expect(desempenhoSource, contains('tokens.surfaceMuted'));
      expect(desempenhoSource, contains('tokens.cardBackground'));
      expect(desempenhoSource, contains('tokens.inputBackground'));
      expect(desempenhoSource, contains('tokens.selectedBackground'));
      expect(desempenhoSource, contains('tokens.surfaceElevated'));
      expect(desempenhoSource, contains('tokens.cardBorder'));

      expect(
        desempenhoSource,
        contains('Color _statusColor(String status, WebThemeTokens tokens)'),
      );
      expect(desempenhoSource, contains('return tokens.success'));
      expect(desempenhoSource, contains('return tokens.info'));
      expect(desempenhoSource, contains('return tokens.warning'));
      expect(desempenhoSource, contains('return tokens.danger'));
      expect(desempenhoSource, contains('return tokens.statusNeutral'));
      expect(
        desempenhoSource,
        contains('barrierColor: pageTokens.workspaceBackground'),
      );
    });
  });
}
