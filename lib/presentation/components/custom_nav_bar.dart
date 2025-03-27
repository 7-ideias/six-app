import 'package:appplanilha/presentation/screens/gestao_mobile_screen.dart';
import 'package:appplanilha/presentation/screens/home_page_mobile_screen.dart';
import 'package:appplanilha/presentation/screens/operacao_mobile_screen.dart';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int initialIndex;

  const CustomBottomNavBar({super.key, this.initialIndex = 1}); // 1 = Home

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
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
        page = GestaoMobileScreen();
        break;
      case 1:
        page = HomePageMobile(title: 'home');
        break;
      case 2:
        page = OperacaoMobileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black87,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      onTap: _onNavItemTapped,
      items: [
        _buildNavItem(Icons.chat, "Gestão"), // index 0
        _buildNavItem(Icons.radio_button_checked, "Home"), // index 1
        _buildNavItem(Icons.person, "Operação"), // index 2
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      activeIcon: Column(
        children: [
          Icon(icon, size: 28),
          Container(
            height: 3,
            width: 20,
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
      label: label,
    );
  }
}
