import 'dart:io';

import 'package:appplanilha/core/services/auth_service.dart';
import 'package:appplanilha/presentation/screens/configuracoes_mobile_screen.dart';
import 'package:appplanilha/presentation/screens/login_mobile.dart';
import 'package:appplanilha/presentation/screens/perfil_do_meu_negocio_mobile_screen.dart';
import 'package:appplanilha/presentation/screens/precos_e_planos_mobile_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/meu_perfil_mobile_screen.dart';
import '../screens/preferencias_mobile_screen.dart';

class AppDrawerDoMobile extends StatelessWidget {
  final File? image;
  final void Function(ImageSource source) onPickImage;

  const AppDrawerDoMobile({Key? key, required this.image, required this.onPickImage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // UserAccountsDrawerHeader(
          //   accountName: Text("Nome do Usuário"),
          //   accountEmail: Text("email@exemplo.com"),
          //   currentAccountPicture: CircleAvatar(
          //     backgroundImage: image != null ? FileImage(image!) : null,
          //     child: image == null ? Icon(Icons.camera_alt, size: 24.0) : null,
          //   ),
          //   decoration: BoxDecoration(color: Colors.white),
          // ),
          UserAccountsDrawerHeader(
            accountName: Text(
              "Nome do Usuário",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            accountEmail: Text(
              "email@exemplo.com",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 36,
              backgroundImage: image != null ? FileImage(image!) : null,
              child: image == null
                  ? Icon(
                  Icons.camera_alt, size: 28.0, color: Theme.of(context).colorScheme.onPrimary)
                  : null,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            otherAccountsPictures: const [
              CircleAvatar(
                backgroundImage: AssetImage(
                    'assets/images/avatar_placeholder.png'), // ou outro ícone
              ),
            ],
            onDetailsPressed: () {
              // Pode usar para abrir um menu suspenso ou dropdown no futuro
            },
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
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
            'Perfil do meu negócio', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PerfilDoMeuNegocioMobileScreen(),
              ),
            );
          }),
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
              MaterialPageRoute(
                  builder: (context) => PreferencesMobileScreen()),
            );
          }),
          Divider(),
          _buildItem(context, Icons.logout, 'Sair da conta', () async {
            await AuthService().logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPageMobile()),
              (route) => false,
            );
          }),
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Center(
              child: Text(
                'versão 1.0.1',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: theme.colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }
}
