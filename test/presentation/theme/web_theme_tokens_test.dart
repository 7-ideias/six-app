import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/presentation/theme/six_web_action_styles.dart';
import 'package:sixpos/presentation/layouts/six_web_page_shell.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/providers/theme_provider.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'CTAs acompanham Aparência e troca de paleta em ${dark ? "dark" : "light"}',
      (tester) async {
        final resolver = SixThemeResolver();
        final previous = ConfiguracaoAparenciaSistema(
          tema: resolver.tema,
          paleta: resolver.paleta,
        );
        final provider = ThemeProvider(enableLocalPersistence: false);
        addTearDown(() {
          provider.dispose();
          resolver.atualizarConfiguracao(previous);
        });
        for (final color in [
          const Color(0xFF7425AA),
          const Color(0xFFFFDC45),
        ]) {
          final base = PaletaSistema.defaultPalette();
          resolver.atualizarConfiguracao(
            ConfiguracaoAparenciaSistema(
              tema: dark ? TemaSistema.escuro : TemaSistema.claro,
              paleta: PaletaSistema(
                primaria: color,
                secundaria: base.secundaria,
                destaque: base.destaque,
                alerta: base.alerta,
                fundo: base.fundo,
                superficie: base.superficie,
                textoPrimario: base.textoPrimario,
                textoSecundario: base.textoSecundario,
              ),
            ),
          );
          await tester.pumpWidget(
            AnimatedBuilder(
              animation: provider,
              builder:
                  (_, __) => MaterialApp(
                    theme: provider.lightTheme,
                    darkTheme: provider.darkTheme,
                    themeMode: provider.themeMode,
                    home: Scaffold(
                      body: SixWebPageShell(
                        child: Builder(
                          builder:
                              (context) => Wrap(
                                children: [
                                  FilledButton(
                                    onPressed: () {},
                                    child: const Text('inherited'),
                                  ),
                                  FilledButton(
                                    style: SixWebActionStyles.primary(context),
                                    onPressed: () {},
                                    child: const Text('explicit'),
                                  ),
                                  FilledButton(
                                    style: SixWebActionStyles.primary(context),
                                    onPressed: null,
                                    child: const Text('disabled'),
                                  ),
                                  FilledButton(
                                    style: SixWebActionStyles.danger(context),
                                    onPressed: () {},
                                    child: const Text('danger'),
                                  ),
                                  OutlinedButton(
                                    style: SixWebActionStyles.secondary(
                                      context,
                                    ),
                                    onPressed: () {},
                                    child: const Text('refresh'),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
            ),
          );
          await tester.pumpAndSettle();
          for (final label in ['inherited', 'explicit']) {
            final material = tester.widget<Material>(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(Material),
                  )
                  .first,
            );
            expect(material.color, color);
            final foreground =
                DefaultTextStyle.of(
                  tester.element(find.text(label)),
                ).style.color!;
            expect(
              _contrastRatio(color, foreground),
              greaterThanOrEqualTo(4.5),
            );
          }
          final dangerMaterial = tester.widget<Material>(
            find
                .ancestor(
                  of: find.text('danger'),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(dangerMaterial.color, base.alerta);
          final context = tester.element(find.text('refresh'));
          final style = SixWebActionStyles.secondary(context);
          expect(style.backgroundColor!.resolve({}), Colors.transparent);
          expect(style.overlayColor!.resolve({WidgetState.hovered}), isNotNull);
          expect(
            style.foregroundColor!.resolve({WidgetState.disabled}),
            isNot(style.foregroundColor!.resolve({})),
          );
          final disabled = tester.widget<Material>(
            find
                .ancestor(
                  of: find.text('disabled'),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(disabled.color, isNot(color));
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  group('WebThemeTokens', () {
    test('define hierarquia clara de superficies em Light e Dark', () {
      final WebThemeTokens light = WebThemeTokens.resolve(
        ThemeData.light(useMaterial3: true),
      );
      final WebThemeTokens dark = WebThemeTokens.resolve(
        ThemeData.dark(useMaterial3: true),
      );

      expect(light.workspaceBackground, isNot(light.cardBackground));
      expect(dark.workspaceBackground, isNot(dark.sidebarBackground));
      expect(dark.sidebarBackground, isNot(dark.surface));
      expect(dark.surface, isNot(dark.cardBorder));
      expect(dark.surface, isNot(dark.surfaceElevated));
      expect(dark.hoverBackground, isNot(dark.selectedBackground));
      expect(
        dark.workspaceBackground.computeLuminance(),
        lessThan(dark.surface.computeLuminance()),
      );
      expect(
        dark.surface.computeLuminance(),
        lessThan(dark.surfaceElevated.computeLuminance()),
      );
    });

    test('mantem texto principal com contraste adequado no Dark', () {
      final WebThemeTokens dark = WebThemeTokens.resolve(
        ThemeData.dark(useMaterial3: true),
      );

      expect(
        _contrastRatio(dark.primaryText, dark.workspaceBackground),
        greaterThan(7),
      );
      expect(
        _contrastRatio(dark.secondaryText, dark.sidebarBackground),
        greaterThan(4.5),
      );
    });

    test('define selected e cores semanticas distintas', () {
      final WebThemeTokens dark = WebThemeTokens.resolve(
        ThemeData.dark(useMaterial3: true),
      );

      expect(dark.selectedBackground, isNot(dark.hoverBackground));
      expect(dark.selectedBorder, isNot(dark.selectedBackground));
      expect(<Color>{
        dark.success,
        dark.warning,
        dark.danger,
        dark.info,
      }, hasLength(4));
      expect(<Color>{
        dark.financialPositive,
        dark.financialNegative,
      }, hasLength(2));
      expect(<Color>{dark.stockCritical, dark.stockWarning}, hasLength(2));
    });

    test('instala ThemeExtension sem substituir extensoes externas', () {
      final ThemeData baseTheme = ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        extensions: const <ThemeExtension<dynamic>>[_ProbeExtension('keep')],
      );

      final ThemeData webTheme = WebThemeTokens.applyTo(baseTheme);

      expect(webTheme.extension<WebThemeTokens>(), isNotNull);
      expect(webTheme.extension<_ProbeExtension>()?.value, 'keep');
      expect(
        webTheme.popupMenuTheme.color,
        webTheme.extension<WebThemeTokens>()!.menuBackground,
      );
    });

    test('nao e referenciado por arquivos Mobile', () {
      final List<String> forbiddenReferences =
          Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((File file) => file.path.endsWith('.dart'))
              .where(
                (File file) =>
                    file.readAsStringSync().contains('WebThemeTokens'),
              )
              .map((File file) => file.path.replaceAll('\\', '/'))
              .where(_isForbiddenMobilePath)
              .toList();

      expect(forbiddenReferences, isEmpty);
    });
  });
}

double _contrastRatio(Color a, Color b) {
  final double lighter =
      a.computeLuminance() > b.computeLuminance()
          ? a.computeLuminance()
          : b.computeLuminance();
  final double darker =
      a.computeLuminance() > b.computeLuminance()
          ? b.computeLuminance()
          : a.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

bool _isForbiddenMobilePath(String path) {
  final String normalized = path.toLowerCase();
  return normalized.endsWith('_mobile_screen.dart') ||
      normalized.contains('/mobile/') ||
      normalized.contains('mobile_main_shell') ||
      normalized.contains('navbar_mobile') ||
      normalized.contains('mobile_navigation_controller') ||
      normalized.contains('six_mobile_');
}

@immutable
class _ProbeExtension extends ThemeExtension<_ProbeExtension> {
  const _ProbeExtension(this.value);

  final String value;

  @override
  _ProbeExtension copyWith({String? value}) {
    return _ProbeExtension(value ?? this.value);
  }

  @override
  _ProbeExtension lerp(ThemeExtension<_ProbeExtension>? other, double t) {
    return this;
  }
}
