import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/mobile/management/management_parallax_card_data.dart';
import 'package:sixpos/presentation/components/mobile/management/management_parallax_carousel.dart';

void main() {
  String selectedTitle(WidgetTester tester) {
    final Text selected = tester.widget<Text>(
      find.byKey(const ValueKey<String>('selected-title')),
    );
    return selected.data ?? '';
  }

  List<ManagementParallaxCardData> buildCards() {
    return const <ManagementParallaxCardData>[
      ManagementParallaxCardData(
        id: 'catalog',
        title: 'Catálogo',
        subtitle: 'Produtos, categorias e estoque sempre à mão.',
        icon: Icons.inventory_2_outlined,
        imageAssetPath:
            'assets/images/management/parallax/management_catalog.webp',
        fallbackGradient: LinearGradient(
          colors: <Color>[Color(0xFF0E7490), Color(0xFF1D4ED8)],
        ),
      ),
      ManagementParallaxCardData(
        id: 'people',
        title: 'Pessoas',
        subtitle: 'Clientes, equipe e parceiros do comércio.',
        icon: Icons.groups_2_outlined,
        imageAssetPath:
            'assets/images/management/parallax/management_people.webp',
        fallbackGradient: LinearGradient(
          colors: <Color>[Color(0xFF0F766E), Color(0xFF2563EB)],
        ),
      ),
      ManagementParallaxCardData(
        id: 'finance',
        title: 'Financeiro',
        subtitle: 'Contas, agenda e formas de recebimento.',
        icon: Icons.account_balance_wallet_outlined,
        imageAssetPath:
            'assets/images/management/parallax/management_finance.webp',
        fallbackGradient: LinearGradient(
          colors: <Color>[Color(0xFF166534), Color(0xFF0C4A6E)],
        ),
      ),
      ManagementParallaxCardData(
        id: 'settings',
        title: 'Configurações',
        subtitle: 'Empresa, idioma, notificações e integrações.',
        icon: Icons.settings_outlined,
        imageAssetPath:
            'assets/images/management/parallax/management_settings.webp',
        fallbackGradient: LinearGradient(
          colors: <Color>[Color(0xFF1E293B), Color(0xFF334155)],
        ),
      ),
    ];
  }

  Future<void> pumpCarousel(
    WidgetTester tester, {
    List<ManagementParallaxCardData>? cards,
    Size? size,
  }) async {
    await tester.binding.setSurfaceSize(size ?? const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: (size ?? const Size(390, 844)).width,
              child: _ManagementParallaxCarouselHarness(
                cards: cards ?? buildCards(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('exibe quatro cards e mantém ordem ao navegar', (
    WidgetTester tester,
  ) async {
    await pumpCarousel(tester);

    final List<String> visitedTitles = <String>[selectedTitle(tester)];

    await tester.drag(
      find.byType(PageView),
      const Offset(-260, 0),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    visitedTitles.add(selectedTitle(tester));

    await tester.drag(
      find.byType(PageView),
      const Offset(-260, 0),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    visitedTitles.add(selectedTitle(tester));

    await tester.drag(
      find.byType(PageView),
      const Offset(-260, 0),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    visitedTitles.add(selectedTitle(tester));

    expect(visitedTitles, <String>[
      'Catálogo',
      'Pessoas',
      'Financeiro',
      'Configurações',
    ]);
  });

  testWidgets('renderiza fallback quando assets não existem', (
    WidgetTester tester,
  ) async {
    final List<ManagementParallaxCardData> cards = buildCards()
        .map(
          (ManagementParallaxCardData card) => ManagementParallaxCardData(
            id: card.id,
            title: card.title,
            subtitle: card.subtitle,
            icon: card.icon,
            imageAssetPath: 'assets/images/management/parallax/missing.webp',
            fallbackGradient: card.fallbackGradient,
          ),
        )
        .toList(growable: false);

    await pumpCarousel(tester, cards: cards);
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(
        const ValueKey<String>('management-parallax-fallback-catalog'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('altera página ao arrastar o carrossel', (
    WidgetTester tester,
  ) async {
    await pumpCarousel(tester);

    expect(selectedTitle(tester), 'Catálogo');

    await tester.fling(find.byType(PageView), const Offset(-420, 0), 1200);
    await tester.pumpAndSettle();

    expect(selectedTitle(tester), isNot('Catálogo'));
  });

  testWidgets('não gera overflow em largura compacta', (
    WidgetTester tester,
  ) async {
    await pumpCarousel(tester, size: const Size(320, 640));
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(PageView),
      const Offset(-220, 0),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _ManagementParallaxCarouselHarness extends StatefulWidget {
  const _ManagementParallaxCarouselHarness({required this.cards});

  final List<ManagementParallaxCardData> cards;

  @override
  State<_ManagementParallaxCarouselHarness> createState() =>
      _ManagementParallaxCarouselHarnessState();
}

class _ManagementParallaxCarouselHarnessState
    extends State<_ManagementParallaxCarouselHarness> {
  late final PageController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ManagementParallaxCarousel(
          controller: _controller,
          cards: widget.cards,
          selectedIndex: _selectedIndex,
          onPageChanged: (int index) {
            if (!mounted) return;
            setState(() => _selectedIndex = index);
          },
        ),
        const SizedBox(height: 12),
        Text(
          widget.cards[_selectedIndex].title,
          key: const ValueKey<String>('selected-title'),
        ),
      ],
    );
  }
}
