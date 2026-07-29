import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/presentation/screens/login_mobile.dart';
import 'package:sixpos/providers/usuario_provider.dart';

import '../screens/meu_perfil_mobile_screen.dart';
import '../screens/preferencias_mobile_screen.dart';

class CoresDoMobile extends StatelessWidget {
  const CoresDoMobile({
    super.key,
    required this.image,
    required this.onPickImage,
  });

  final File? image;
  final void Function(ImageSource source) onPickImage;

  static const Color _surface = SixMobilePalette.surface;
  static const Color _border = SixMobilePalette.border;
  static const Color _title = SixMobilePalette.titleText;
  static const Color _accent = SixMobilePalette.accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color panelColor = colorScheme.surface;

    return SafeArea(
      left: false,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(24),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.22),
                blurRadius: 34,
                spreadRadius: 1,
                offset: const Offset(-12, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(24),
            ),
            child: Column(
              children: <Widget>[
                _buildHeader(context),
                Expanded(
                  child: ColoredBox(
                    color: colorScheme.surfaceContainerLowest,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      children: <Widget>[
                        _buildSectionLabel(context, 'Conta'),
                        _buildItem(
                          context,
                          icon: Icons.person_outline_rounded,
                          title: 'Meu perfil',
                          subtitle: 'Dados pessoais e acesso',
                          onTap:
                              () => _openScreen(
                                context,
                                const MeuPerfilMobileScreen(),
                              ),
                        ),
                        _buildItem(
                          context,
                          icon: Icons.tune_rounded,
                          title: 'Preferências',
                          subtitle: 'Ajustes individuais do app',
                          onTap:
                              () => _openScreen(
                                context,
                                PreferencesMobileScreen(),
                              ),
                        ),
                        _buildItem(
                          context,
                          icon: Icons.shield_outlined,
                          title: 'Gerenciar meus dados',
                          subtitle: 'Dados e privacidade',
                          onTap:
                              () => _openScreen(
                                context,
                                PreferencesMobileScreen(),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 22,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.65,
                          ),
                        ),
                        _buildLogoutItem(context),
                      ],
                    ),
                  ),
                ),
                _buildVersionFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final UsuarioProvider usuarioProvider = UsuarioProvider();

    return FutureBuilder<void>(
      future: _loadUserIfNeeded(usuarioProvider),
      builder: (BuildContext context, AsyncSnapshot<void> _) {
        return ListenableBuilder(
          listenable: usuarioProvider,
          builder: (BuildContext context, Widget? _) {
            final UsuarioModel? usuario = usuarioProvider.usuario;

            return Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  _buildAvatar(context),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _userName(usuario),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail(usuario),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _showImagePickerOptions(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: image != null ? FileImage(image!) : null,
            child:
                image == null
                    ? Icon(
                      Icons.person_outline_rounded,
                      size: 30,
                      color: colorScheme.primary,
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
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 14,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          hoverColor: colorScheme.primary.withValues(alpha: 0.06),
          focusColor: colorScheme.primary.withValues(alpha: 0.08),
          splashColor: colorScheme.primary.withValues(alpha: 0.08),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 21),
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
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color errorColor = colorScheme.error;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: errorColor.withValues(alpha: 0.06),
        focusColor: errorColor.withValues(alpha: 0.08),
        splashColor: errorColor.withValues(alpha: 0.08),
        onTap: () => _logout(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: errorColor.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: errorColor,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: errorColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionFooter(BuildContext context) {
    final String version = AppConfig.appVersion.trim();
    final String buildNumber = AppConfig.appBuildNumber.trim();
    final String versionLabel =
        version.isEmpty ? 'versão não informada' : 'versão $version';
    final String tooltip =
        buildNumber.isEmpty
            ? 'Versão atual: ${version.isEmpty ? '-' : version}'
            : 'Versão atual: ${version.isEmpty ? '-' : version} • build $buildNumber';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      child: Tooltip(
        message: tooltip,
        child: Text(
          versionLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _loadUserIfNeeded(UsuarioProvider provider) async {
    if (provider.usuario != null) return;

    try {
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
    } catch (_) {
      // O painel continua funcional mesmo sem os dados do usuário.
    }
  }

  String _userName(UsuarioModel? usuario) {
    final String nomeDeGuerra = usuario?.nomeDeGuerra.trim() ?? '';
    if (nomeDeGuerra.isNotEmpty) return nomeDeGuerra;

    final String nomeCompleto = <String>[
      usuario?.nome.trim() ?? '',
      usuario?.sobrenome.trim() ?? '',
    ].where((String parte) => parte.isNotEmpty).join(' ');

    return nomeCompleto.isEmpty ? 'Usuário' : nomeCompleto;
  }

  String _userEmail(UsuarioModel? usuario) {
    final String email = usuario?.email.trim() ?? '';
    return email.isEmpty ? 'E-mail não informado' : email;
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPageMobile()),
      (Route<dynamic> route) => false,
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                    color: _title,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
      color: SixMobilePalette.softNeutralSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).pop();
          onPickImage(source);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: _accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _title,
                    fontWeight: FontWeight.w700,
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
