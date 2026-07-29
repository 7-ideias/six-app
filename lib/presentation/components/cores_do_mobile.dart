import 'dart:io';
import 'dart:ui';

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
  static const Color _muted = SixMobilePalette.mutedText;
  static const Color _accent = SixMobilePalette.accent;
  static const Color _background = SixMobilePalette.background;
  static const Color _softSurface = SixMobilePalette.softNeutralSurface;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SafeArea(
      left: false,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    _surface.withValues(alpha: 0.94),
                    _softSurface.withValues(alpha: 0.91),
                    _background.withValues(alpha: 0.88),
                  ],
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(28),
                ),
                border: Border(
                  left: BorderSide(
                    color: SixMobilePalette.onPrimary.withValues(alpha: 0.56),
                    width: 0.8,
                  ),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: SixMobilePalette.heroShadow.withValues(alpha: 0.38),
                    blurRadius: 34,
                    spreadRadius: 1,
                    offset: const Offset(-12, 0),
                  ),
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(-4, 8),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  _buildHeader(context),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      children: <Widget>[
                        _buildSectionLabel(context, 'Conta'),
                        _buildItem(
                          context,
                          icon: Icons.person_outline_rounded,
                          title: 'Meu perfil',
                          subtitle: 'Dados pessoais e acesso',
                          semanticsLabel: 'Abrir meu perfil',
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
                          semanticsLabel: 'Abrir preferências',
                          onTap:
                              () => _openScreen(
                                context,
                                PreferencesMobileScreen(),
                              ),
                        ),
                        _buildItem(
                          context,
                          icon: Icons.privacy_tip_outlined,
                          title: 'Gerenciar meus dados',
                          subtitle: 'Dados e privacidade',
                          semanticsLabel: 'Abrir gerenciamento dos meus dados',
                          onTap:
                              () => _openScreen(
                                context,
                                PreferencesMobileScreen(),
                              ),
                        ),
                        const SizedBox(height: 10),
                        _buildLogoutItem(context),
                      ],
                    ),
                  ),
                  _buildVersionFooter(context),
                ],
              ),
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
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    SixMobilePalette.primary.withValues(alpha: 0.08),
                    SixMobilePalette.accent.withValues(alpha: 0.05),
                    _surface.withValues(alpha: 0.35),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: SixMobilePalette.onPrimary.withValues(alpha: 0.48),
                    width: 0.6,
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
                            color: _title,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail(usuario),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Fechar configurações',
                    icon: const Icon(Icons.close_rounded),
                    color: _title,
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
    return Semantics(
      button: true,
      label: 'Alterar foto do perfil',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showImagePickerOptions(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    SixMobilePalette.primary.withValues(alpha: 0.10),
                    SixMobilePalette.accent.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(
                  color: SixMobilePalette.onPrimary.withValues(alpha: 0.72),
                  width: 2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: SixMobilePalette.heroShadow.withValues(alpha: 0.42),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: _softSurface,
                backgroundImage: image != null ? FileImage(image!) : null,
                child:
                    image == null
                        ? const Icon(
                          Icons.person_outline_rounded,
                          size: 30,
                          color: _accent,
                        )
                        : null,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SixMobilePalette.highlightedBorder,
                    width: 1.2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: SixMobilePalette.navigationShadow.withValues(
                        alpha: 0.7,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 14,
                  color: _accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: _muted,
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
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: _surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            hoverColor: SixMobilePalette.accent.withValues(alpha: 0.06),
            focusColor: SixMobilePalette.accent.withValues(alpha: 0.08),
            splashColor: SixMobilePalette.accent.withValues(alpha: 0.08),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: SixMobilePalette.onPrimary.withValues(alpha: 0.62),
                  width: 0.8,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: SixMobilePalette.navigationShadow.withValues(
                      alpha: 0.45,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.softAccentSurface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: SixMobilePalette.highlightedBorder.withValues(
                          alpha: 0.42,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(icon, color: _accent, size: 21),
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
                          style: const TextStyle(
                            color: _title,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _muted.withValues(alpha: 0.82),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Sair da conta',
      child: Material(
        color: SixMobilePalette.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          hoverColor: SixMobilePalette.error.withValues(alpha: 0.06),
          focusColor: SixMobilePalette.error.withValues(alpha: 0.08),
          splashColor: SixMobilePalette.error.withValues(alpha: 0.08),
          onTap: () => _logout(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: SixMobilePalette.errorBorder.withValues(alpha: 0.62),
                width: 0.8,
              ),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: SixMobilePalette.errorBorder.withValues(
                        alpha: 0.16,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(13)),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: SixMobilePalette.error,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sair da conta',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SixMobilePalette.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

  Widget _buildVersionFooter(BuildContext context) {
    final String version = AppConfig.appVersion.trim();
    final String buildNumber = AppConfig.appBuildNumber.trim();
    final String versionLabel =
        version.isEmpty ? 'versão não informada' : 'versão $version';
    final String tooltip =
        buildNumber.isEmpty
            ? 'Versão atual: ${version.isEmpty ? '-' : version}'
            : 'Versão atual: ${version.isEmpty ? '-' : version} • build $buildNumber';

    return SafeArea(
      top: false,
      left: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Tooltip(
          message: tooltip,
          child: Text(
            versionLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
