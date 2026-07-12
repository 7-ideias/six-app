import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/screens/gestao_mobile_screen.dart';
import 'package:sixpos/presentation/screens/home_page_mobile_screen.dart';
import 'package:sixpos/presentation/screens/operacao_mobile_screen.dart';

class NavBarMobile extends StatefulWidget {
  final int initialIndex;

  const NavBarMobile({super.key, this.initialIndex = 1}); // 1 = Início

  @override
  State<NavBarMobile> createState() => _NavBarMobileState();
}

class _NavBarMobileState extends State<NavBarMobile> {
  static const Duration _itemAnimationDuration = Duration(milliseconds: 240);
  static const Duration _pageTransitionDuration = Duration(milliseconds: 220);

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    HapticFeedback.selectionClick();

    setState(() {
      _selectedIndex = index;
    });

    final Widget page;

    switch (index) {
      case 0:
        page = const GestaoMobileScreen();
        break;
      case 1:
        page = const HomePageMobile(title: 'Início');
        break;
      case 2:
        page = const OperacaoMobileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: _pageTransitionDuration,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final Animation<double> curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(
                curvedAnimation,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 70,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: SixMobilePalette.surface.withOpacity(0.94),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: SixMobilePalette.surface.withOpacity(0.82),
                ),
              ),
              child: Row(
                children: <Widget>[
                  _buildNavItem(
                    index: 0,
                    icon: Icons.manage_accounts_outlined,
                    activeIcon: Icons.manage_accounts_rounded,
                    label: 'Gestão',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Início',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.support_agent_outlined,
                    activeIcon: Icons.support_agent_rounded,
                    label: 'Atendimento',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = _selectedIndex == index;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Semantics(
          button: true,
          selected: isActive,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _onNavItemTapped(index),
            child: AnimatedContainer(
              duration: _itemAnimationDuration,
              curve: Curves.easeOutCubic,
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? SixMobilePalette.softAccentSurface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? SixMobilePalette.activeBorder
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedScale(
                    duration: _itemAnimationDuration,
                    curve: isActive ? Curves.easeOutBack : Curves.easeOutCubic,
                    scale: isActive ? 1.12 : 1,
                    child: AnimatedContainer(
                      duration: _itemAnimationDuration,
                      curve: Curves.easeOutCubic,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  SixMobilePalette.secondary,
                                  SixMobilePalette.accent,
                                ],
                              )
                            : null,
                        boxShadow: isActive
                            ? const <BoxShadow>[
                                BoxShadow(
                                  color: SixMobilePalette.heroShadow,
                                  blurRadius: 9,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : const <BoxShadow>[],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.72, end: 1).animate(
                                animation,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          isActive ? activeIcon : icon,
                          key: ValueKey<bool>(isActive),
                          size: 19,
                          color: isActive
                              ? SixMobilePalette.onPrimary
                              : SixMobilePalette.mutedText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: _itemAnimationDuration,
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: isActive
                          ? SixMobilePalette.primary
                          : SixMobilePalette.mutedText,
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: -0.1,
                      height: 1,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
