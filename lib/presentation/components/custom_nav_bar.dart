import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sixpos/presentation/screens/gestao_mobile_screen.dart';
import 'package:sixpos/presentation/screens/home_page_mobile_screen.dart';
import 'package:sixpos/presentation/screens/operacao_mobile_screen.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int initialIndex;

  const CustomBottomNavBar({super.key, this.initialIndex = 1}); // 1 = Início

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedColor = Color(0xFF64748B);
  static const Color _activeSurfaceColor = Color(0xFFEFF6FF);

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    Widget page;

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
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 140),
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.72)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1A0B1F3A),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
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
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _onNavItemTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 52,
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 10 : 6,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isActive ? _activeSurfaceColor : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFDCEBFF)
                    : Colors.transparent,
              ),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: isActive ? 1 : 0.94,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    isActive ? activeIcon : icon,
                    size: isActive ? 22 : 21,
                    color: isActive ? _accentColor : _mutedColor,
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: isActive ? _primaryColor : _mutedColor,
                      fontSize: isActive ? 11 : 10.5,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
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
