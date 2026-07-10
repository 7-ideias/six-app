import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/presentation/screens/desempenho_colaborador_page.dart';
import 'package:sixpos/presentation/screens/login_mobile.dart';
import 'package:sixpos/providers/usuario_provider.dart';

import '../screens/meu_perfil_mobile_screen.dart';
import '../screens/preferencias_mobile_screen.dart';

class AppDrawerDoMobile extends StatelessWidget {
  const AppDrawerDoMobile({
    super.key,
    required this.image,
    required this.onPickImage,
  });

  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _surfaceColor = Colors.white;
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _softBlueColor = Color(0xFFEFF6FF);

  final File? image;
  final void Function(ImageSource source) onPickImage;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _backgroundColor,
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                children: <Widget>[
                  _buildSectionLabel('Conta'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Meu perfil',
                    subtitle: 'Dados pessoais e acesso',
                    onTap: () => _openScreen(context, const MeuPerfilMobileScreen()),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Preferências',
                    subtitle: 'Ajustes individuais do app',
                    onTap: () => _openScreen(context, PreferencesMobileScreen()),
                  ),
                  const SizedBox(height: 14),
                  _buildSectionLabel('Gestão'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.trending_up_rounded,
                    title: 'Desempenho',
                    subtitle: 'Metas e resultado por período',
                    highlighted: true,
                    onTap: () => _openScreen(context, const DesempenhoColaboradorPage()),
                  ),
                  const SizedBox(height: 14),
                  _buildSectionLabel('Suporte e segurança'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.chat_outlined,
                    title: 'Preciso de ajuda',
                    subtitle: 'Atendimento e suporte',
                    onTap: () => _showFeatureInProgress(context),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Termos de Uso',
                    subtitle: 'Condições de uso do Six',
                    onTap: () => _showFeatureInProgress(context),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.security_outlined,
                    title: 'Política de Privacidade',
                    subtitle: 'Como seus dados são protegidos',
                    onTap: () => _showFeatureInProgress(context),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Gerenciar meus dados',
                    subtitle: 'Preferências de dados e privacidade',
                    onTap: () => _openScreen(context, PreferencesMobileScreen()),
                  ),
                  const SizedBox(height: 12),
                  _buildLogoutItem(context),
                ],
              ),
            ),
            _buildVersionFooter(),
          ],
        ),
      ),
    );
  }

  Future<void> _carregarUsuarioSeNecessario() async {
    final UsuarioProvider provider = UsuarioProvider();

    if (provider.usuario != null) {
      return;
    }

    try {
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
    } catch (_) {
      // O drawer deve continuar abrindo mesmo se os dados do usuário não carregarem.
    }
  }

  String _nomeDoUsuario(UsuarioModel? usuario) {
    final String nomeDeGuerra = usuario?.nomeDeGuerra.trim() ?? '';

    if (nomeDeGuerra.isNotEmpty) {
      return nomeDeGuerra;
    }

    final String nomeCompleto = <String>[
      usuario?.nome.trim() ?? '',
      usuario?.sobrenome.trim() ?? '',
    ].where((String parte) => parte.isNotEmpty).join(' ').trim();

    if (nomeCompleto.isNotEmpty) {
      return nomeCompleto;
    }

    return 'Usuário';
  }

  String _emailDoUsuario(UsuarioModel? usuario) {
    final String email = usuario?.email.trim() ?? '';

    if (email.isNotEmpty) {
      return email;
    }

    return 'E-mail não informado';
  }

  Widget _buildHeader(BuildContext context) {
    final UsuarioProvider usuarioProvider = UsuarioProvider();

    return FutureBuilder<void>(
      future: _carregarUsuarioSeNecessario(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        return ListenableBuilder(
          listenable: usuarioProvider,
          builder: (BuildContext context, Widget? child) {
            final UsuarioModel? usuario = usuarioProvider.usuario;

            return Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                18,
                MediaQuery.of(context).padding.top + 18,
                18,
                18,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[_primaryColor, _secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _buildAvatar(context),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _nomeDoUsuario(usuario),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _emailDoUsuario(usuario),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFDCEBFF),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gestão rápida do seu comércio',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _showImagePickerOptions(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            backgroundImage: image != null ? FileImage(image!) : null,
            child: image == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: Colors.white,
                  )
                : null,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.12)),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: _primaryColor,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: _mutedTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: highlighted ? const Color(0xFFBFDBFE) : _borderColor,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: highlighted ? _softBlueColor : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: highlighted ? const Color(0xFFBFDBFE) : _borderColor,
                    ),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontSize: 14,
                          fontWeight: highlighted ? FontWeight.w900 : FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: const Color(0xFFFFFBFB),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _logout(context),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFB91C1C),
                      size: 21,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sair da conta',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionFooter() {
    final String version = AppConfig.appVersion.trim();
    final String buildNumber = AppConfig.appBuildNumber.trim();
    final String versionLabel =
        version.isEmpty ? 'versão não informada' : 'versão $version';
    final String tooltip = buildNumber.isEmpty
        ? 'Versão atual: ${version.isEmpty ? '-' : version}'
        : 'Versão atual: ${version.isEmpty ? '-' : version} • build $buildNumber';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Tooltip(
        message: tooltip,
        child: Text(
          versionLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: _mutedTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPageMobile()),
      (Route<dynamic> route) => false,
    );
  }

  void _showFeatureInProgress(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recurso em preparação.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Foto do perfil',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _buildImageOption(
                  bottomSheetContext,
                  icon: Icons.photo_camera_outlined,
                  title: 'Tirar foto',
                  source: ImageSource.camera,
                ),
                const SizedBox(height: 8),
                _buildImageOption(
                  bottomSheetContext,
                  icon: Icons.photo_library_outlined,
                  title: 'Escolher da galeria',
                  source: ImageSource.gallery,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required ImageSource source,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).pop();
          onPickImage(source);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: _primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
