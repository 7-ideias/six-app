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
  static const Duration _itemAnimationDuration = Duration(milliseconds: 320);
  static const Duration _pageTransitionDuration = Duration(milliseconds: 260);

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
              scale: Tween<double>(begin: 0.975, end: 1).animate(
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
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow,
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 78,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
              decoration: BoxDecoration(
                color: SixMobilePalette.surface.withOpacity(0.91),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: SixMobilePalette.surface.withOpacity(0.84),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _onNavItemTapped(index),
            child: AnimatedScale(
              duration: _itemAnimationDuration,
              curve: isActive ? Curves.easeOutBack : Curves.easeOutCubic,
              scale: isActive ? 1.075 : 0.94,
              child: AnimatedSlide(
                duration: _itemAnimationDuration,
                curve: Curves.easeOutCubic,
                offset: isActive ? const Offset(0, -0.035) : Offset.zero,
                child: AnimatedContainer(
                  duration: _itemAnimationDuration,
                  curve: Curves.easeOutCubic,
                  height: isActive ? 62 : 56,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              SixMobilePalette.surface,
                              SixMobilePalette.softAccentSurface,
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isActive
                          ? SixMobilePalette.highlightedBorder
                          : Colors.transparent,
                    ),
                    boxShadow: isActive
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: SixMobilePalette.navigationShadow,
                              blurRadius: 16,
                              offset: Offset(0, 7),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: _itemAnimationDuration,
                        curve: Curves.easeOutBack,
                        width: isActive ? 36 : 30,
                        height: isActive ? 36 : 30,
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
                                    blurRadius: 12,
                                    offset: Offset(0, 5),
                                  ),
                                ]
                              : const <BoxShadow>[],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.55, end: 1).animate(
                                  animation,
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            isActive ? activeIcon : icon,
                            key: ValueKey<bool>(isActive),
                            size: isActive ? 21 : 20,
                            color: isActive
                                ? SixMobilePalette.onPrimary
                                : SixMobilePalette.mutedText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          color: isActive
                              ? SixMobilePalette.primary
                              : SixMobilePalette.mutedText,
                          fontSize: isActive ? 10.8 : 10.2,
                          fontWeight:
                              isActive ? FontWeight.w900 : FontWeight.w700,
                          letterSpacing: -0.15,
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
        ),
      ),
    );
  }
}
