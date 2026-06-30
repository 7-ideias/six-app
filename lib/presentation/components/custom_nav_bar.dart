import 'package:flutter/material.dart';
import 'package:sixpos/presentation/screens/gestao_mobile_screen.dart';
import 'package:sixpos/presentation/screens/home_page_mobile_screen.dart';
import 'package:sixpos/presentation/screens/operacao_mobile_screen.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int initialIndex;

  const CustomBottomNavBar({super.key, this.initialIndex = 1}); // 1 = Início

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedColor = Color(0xFF64748B);

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
        transitionDuration: const Duration(milliseconds: 120),
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: _primaryColor,
          unselectedItemColor: _mutedColor,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: _onNavItemTapped,
          items: [
            _buildNavItem(
              icon: Icons.manage_accounts_outlined,
              activeIcon: Icons.manage_accounts_rounded,
              label: 'Gestão',
            ),
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Início',
            ),
            _buildNavItem(
              icon: Icons.support_agent_outlined,
              activeIcon: Icons.support_agent_rounded,
              label: 'Atendimento',
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      activeIcon: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double scale, Widget? child) {
          return Transform.scale(
            scale: scale,
            child: Transform.translate(
              offset: const Offset(0, -2),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(activeIcon, color: _accentColor, size: 24),
        ),
      ),
      label: label,
    );
  }
}
