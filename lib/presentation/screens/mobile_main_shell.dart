import 'package:flutter/material.dart';

import '../navigation/mobile_navigation_controller.dart';
import 'gestao_mobile_screen.dart';
import 'home_page_mobile_screen.dart';
import 'operacao_mobile_screen.dart';

class MobileMainShell extends StatefulWidget {
  const MobileMainShell({super.key, this.initialIndex = 1})
      : assert(initialIndex >= 0 && initialIndex <= 2);

  final int initialIndex;

  @override
  State<MobileMainShell> createState() => _MobileMainShellState();
}

class _MobileMainShellState extends State<MobileMainShell> {
  late final MobileNavigationController _navigationController;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();

    _navigationController = MobileNavigationController(
      initialIndex: widget.initialIndex,
    );
    _pages = List<Widget?>.filled(3, null);
    _pages[widget.initialIndex] = _createPage(widget.initialIndex);

    _navigationController.addListener(_onNavigationChanged);
  }

  @override
  void dispose() {
    _navigationController.removeListener(_onNavigationChanged);
    _navigationController.dispose();
    super.dispose();
  }

  void _onNavigationChanged() {
    final int index = _navigationController.value;
    _pages[index] ??= _createPage(index);

    if (mounted) {
      setState(() {});
    }
  }

  Widget _createPage(int index) {
    switch (index) {
      case 0:
        return const GestaoMobileScreen();
      case 1:
        return const HomePageMobile(title: 'Início');
      case 2:
        return const OperacaoMobileScreen();
      default:
        throw ArgumentError.value(index, 'index', 'Índice de navegação inválido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileNavigationScope(
      controller: _navigationController,
      child: IndexedStack(
        index: _navigationController.value,
        children: List<Widget>.generate(
          _pages.length,
          (int index) => _pages[index] ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
