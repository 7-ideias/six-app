import 'dart:io';

import 'package:appplanilha/presentation/pages/configuracoes_mobile_screen.dart';
import 'package:appplanilha/presentation/pages/precos_e_planos_mobile_screen.dart';
import 'package:appplanilha/presentation/pages/protecao_de_dados_mobile_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../pages/meu_perfil_mobile_screen.dart';
import '../pages/preferencias_mobile_screen.dart';

class AppDrawer extends StatelessWidget {
  final File? image;
  final void Function(ImageSource source) onPickImage;

  const AppDrawer({Key? key, required this.image, required this.onPickImage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("Nome do Usuário"),
            accountEmail: Text("email@exemplo.com"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: image != null ? FileImage(image!) : null,
              child: image == null ? Icon(Icons.camera_alt, size: 24.0) : null,
            ),
            decoration: BoxDecoration(color: Colors.white),
          ),
          _buildItem(context, Icons.person_outline, 'Meu perfil', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MeuPerfilMobileScreen()),
            );
          }),
          _buildItem(
            context,
            Icons.work_outline,
            'Perfil do meu negócio',
            () {},
          ),
          _buildItem(context, Icons.edit, 'Preferências', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreferencesMobileScreen(),
              ),
            );
          }),
          _buildItem(
            context,
            Icons.emoji_events_outlined,
            'Preços e planos',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanosCarrosselScreen(),
                ),
              );
            },
            bold: true,
          ),
          _buildItem(context, Icons.chat_outlined, 'Preciso de ajuda', () {}),
          _buildItem(context, Icons.settings_outlined, 'Configurações', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfiguracoesMobileScreen(),
              ),
            );
          }),
          Divider(),
          _buildItem(
            context,
            Icons.description_outlined,
            'Termos de Uso',
            () {},
          ),
          _buildItem(
            context,
            Icons.security_outlined,
            'Política de Privacidade',
            () {},
          ),
          _buildItem(context, Icons.lock_outline, 'Gerenciar meus dados', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProtecaoDeDadosScreen()),
            );
          }),
          Divider(),
          _buildItem(context, Icons.logout, 'Sair da conta', () {}),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool bold = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}
