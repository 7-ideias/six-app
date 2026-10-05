import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/admin_visual_assets_service.dart';
import 'package:sixpos/data/models/web_hero_appearance.dart';
import 'package:sixpos/presentation/admin/admin_web_hero_appearance_card.dart';
import 'package:sixpos/presentation/components/web/six_web_hero_gradient.dart';

class _Service extends AdminVisualAssetsService {
  WebHeroAppearance value = const WebHeroAppearance();
  int saves = 0;
  @override
  Future<WebHeroAppearance> appearance() async => value;
  @override
  Future<WebHeroAppearance> saveAppearance(WebHeroAppearance next) async {
    saves++;
    return value = next;
  }
}

void main() {
  testWidgets(
    'edits themes independently, persists and restores after reopening',
    (tester) async {
      final service = _Service();
      addTearDown(service.dispose);
      await tester.binding.setSurfaceSize(const Size(1024, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Widget page(Key key) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminWebHeroAppearanceCard(key: key, service: service),
          ),
        ),
      );
      await tester.pumpWidget(page(const ValueKey(1)));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNWidgets(4));
      tester.widget<Slider>(find.byType(Slider).at(0)).onChanged!(.3);
      await tester.pump();
      tester.widget<Slider>(find.byType(Slider).at(3)).onChanged!(.7);
      await tester.pump();
      await tester.ensureVisible(find.text('Save fade settings'));
      await tester.tap(find.text('Save fade settings'));
      await tester.pumpAndSettle();
      expect(service.saves, 1);
      expect(service.value.light.intensity, .3);
      expect(service.value.light.extent, .42);
      expect(service.value.dark.intensity, 1);
      expect(service.value.dark.extent, .7);
      await tester.pumpWidget(page(const ValueKey(2)));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider).at(0)).value, .3);
      expect(tester.widget<Slider>(find.byType(Slider).at(3)).value, .7);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'zero intensity removes gradient in both layouts and defaults preserve original',
    () {
      for (final compact in [true, false]) {
        final gradient = sixWebHeroGradient(
          Colors.white,
          const WebHeroFade(intensity: 0),
          compact: compact,
        );
        expect(gradient.colors.every((color) => color.a == 0), isTrue);
      }
      final defaultGradient = sixWebHeroGradient(
        Colors.white,
        const WebHeroFade(),
        compact: false,
      );
      expect(defaultGradient.stops, [0, .42, 1]);
      expect(defaultGradient.colors.last.a, closeTo(.12, .001));
    },
  );
}
