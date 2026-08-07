import 'package:flutter/material.dart';

import '../navigation/mobile_navigation_controller.dart';
import 'gestao_mobile_screen.dart';
import 'home_page_mobile_screen.dart';
import 'atendimento_mobile_screen.dart';

class MobileMainShell extends StatefulWidget {
  const MobileMainShell({super.key, this.initialIndex = 1})
    : assert(initialIndex >= 0 && initialIndex <= 2);

  final int initialIndex;

  @override
  State<MobileMainShell> createState() => _MobileMainShellState();
}

class _MobileMainShellState extends State<MobileMainShell>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 340);
  static const Curve _transitionCurve = Curves.easeOutQuart;
  static const double _slideDistance = 12;

  late final MobileNavigationController _navigationController;
  late final AnimationController _transitionController;
  late final Animation<double> _entryAnimation;
  late final List<Widget?> _pages;
  late int _selectedIndex;
  int _transitionDirection = 0;

  @override
  void initState() {
    super.initState();

    _navigationController = MobileNavigationController(
      initialIndex: widget.initialIndex,
    );
    _transitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      value: 1,
    );
    _entryAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: _transitionCurve,
    );
    _pages = List<Widget?>.filled(3, null);
    _pages[widget.initialIndex] = _createPage(widget.initialIndex);
    _selectedIndex = widget.initialIndex;

    _navigationController.addListener(_onNavigationChanged);
  }

  @override
  void dispose() {
    _navigationController.removeListener(_onNavigationChanged);
    _navigationController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _onNavigationChanged() {
    final int index = _navigationController.value;
    if (index == _selectedIndex) return;

    _pages[index] ??= _createPage(index);

    if (!mounted) return;

    _selectPage(index);
  }

  void _selectPage(int index) {
    setState(() {
      _transitionDirection = (index - _selectedIndex).sign;
      _selectedIndex = index;
    });
    _transitionController.forward(from: 0);
  }

  Widget _createPage(int index) {
    switch (index) {
      case 0:
        return const GestaoMobileScreen();
      case 1:
        return const HomePageMobile(title: 'Início');
      case 2:
        return const AtendimentoMobileScreen();
      default:
        throw ArgumentError.value(
          index,
          'index',
          'Índice de navegação inválido',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;

    return MobileNavigationScope(
      controller: _navigationController,
      child:
          reduceMotion
              ? _buildIndexedPages()
              : AnimatedBuilder(
                animation: _entryAnimation,
                child: _buildIndexedPages(),
                builder: (BuildContext context, Widget? child) {
                  final double progress = _entryAnimation.value;
                  final double dx =
                      (1 - progress) * _slideDistance * _transitionDirection;

                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
              ),
    );
  }

  Widget _buildIndexedPages() {
    return IndexedStack(
      index: _selectedIndex,
      children: List<Widget>.generate(
        _pages.length,
        (int index) => _pages[index] ?? const SizedBox.shrink(),
      ),
    );
  }
}
