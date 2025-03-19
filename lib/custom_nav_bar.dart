import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 2; // Índice inicial (ícone do meio)

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black87, // Fundo escuro como na imagem
      selectedItemColor: Colors.white, // Ícone selecionado branco
      unselectedItemColor: Colors.grey, // Ícones não selecionados em cinza
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed, // Evita comportamento estranho com 5 itens
      onTap: _onNavItemTapped,
      items: [
        _buildNavItem(Icons.chat, "Chat"),
        _buildNavItem(Icons.search, "Buscar"),
        _buildNavItem(Icons.radio_button_checked, "Home"), // Ícone do meio com destaque
        _buildNavItem(Icons.notifications, "Notificações"),
        _buildNavItem(Icons.person, "Perfil"),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      activeIcon: Column(
        children: [
          Icon(icon, size: 28), // Ícone maior quando ativo
          Container(
            height: 3,
            width: 20,
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.blue, // Indicador azul como na imagem
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
      label: label,
    );
  }
}
