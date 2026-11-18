import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/admin_ideas_service.dart';
import 'package:sixpos/presentation/screens/admin_novas_ideias_web_page.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

class _IdeasService implements AdminIdeasService {
  @override
  Future<List<AdminIdeaModel>> listar() async => const [
    AdminIdeaModel(
      id: '1',
      empresaId: 'empresa',
      usuarioId: 'usuario',
      descricao: 'Sugestão de teste',
      modulo: 'geral',
      telaAtual: 'assistente',
      plataforma: 'web',
      idioma: 'pt-BR',
      status: 'RECEBIDA',
      criadaEm: null,
    ),
  ];
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Novas ideias aplica a paleta web em ${brightness.name}', (
      tester,
    ) async {
      final theme = ThemeData(brightness: brightness);
      final tokens = WebThemeTokens.resolve(theme);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: AdminNovasIdeiasWebPage(
              embeddedInMainShell: true,
              service: _IdeasService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.style?.color, tokens.primaryText);
      expect(field.decoration?.fillColor, tokens.inputBackground);
      expect(field.decoration?.hintStyle?.color, tokens.mutedText);
      expect(
        field.decoration?.focusedBorder?.borderSide.color,
        tokens.selectedBorder,
      );

      final idea = find.text('Sugestão de teste');
      expect(tester.widget<Text>(idea).style?.color, tokens.primaryText);
      final backgrounds = tester
          .widgetList<Container>(
            find.ancestor(of: idea, matching: find.byType(Container)),
          )
          .map((card) => card.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.color);
      expect(backgrounds, contains(tokens.cardBackground));
    });
  }
}
