import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_maturity_badge.dart';
import 'package:sixpos/presentation/components/user_profile_avatar_image.dart';
import 'package:sixpos/presentation/screens/login_mobile.dart';
import 'package:sixpos/providers/usuario_provider.dart';

import 'meu_perfil_mobile_screen.dart';

class LoginSettingsMobile extends StatelessWidget {
  const LoginSettingsMobile({
    super.key,
    required this.profileImage,
    required this.onPickImage,
    required this.isUpdatingImage,
  });

  final String? profileImage;
  final Future<void> Function(ImageSource source) onPickImage;
  final bool isUpdatingImage;
  static Future<void>? _profileLoadFuture;

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
                        // ── Conta ──
                        _buildSectionLabel(context, 'Conta'),
                        _buildGroupedCard(
                          context,
                          items: <_GroupedItemData>[
                            _GroupedItemData(
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
                            _GroupedItemData(
                              icon: Icons.tune_rounded,
                              title: 'Preferências',
                              subtitle: 'Ajustes individuais do app',
                              semanticsLabel: 'Abrir preferências',
                              comingSoon: true,
                            ),
                            _GroupedItemData(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Gerenciar meus dados',
                              subtitle: 'Dados e privacidade',
                              semanticsLabel:
                                  'Abrir gerenciamento dos meus dados',
                              comingSoon: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Sobre ──
                        _buildSectionLabel(context, 'Sobre'),
                        _buildGroupedCard(
                          context,
                          items: <_GroupedItemData>[
                            _GroupedItemData(
                              icon: Icons.help_outline_rounded,
                              title: 'Ajuda e suporte',
                              subtitle: 'Dúvidas e contato',
                              semanticsLabel: 'Abrir ajuda e suporte',
                              comingSoon: true,
                            ),
                            _GroupedItemData(
                              icon: Icons.description_outlined,
                              title: 'Termos e políticas',
                              subtitle: 'Uso, privacidade e licenças',
                              semanticsLabel: 'Abrir termos e políticas',
                              comingSoon: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
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
      future: _loadUser(),
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
                  _buildAvatar(context, usuario?.foto ?? profileImage),
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

  Widget _buildAvatar(BuildContext context, String? currentProfileImage) {
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
                child:
                    isUpdatingImage
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: _accent,
                          ),
                        )
                        : (currentProfileImage?.trim().isEmpty ?? true)
                        ? const Icon(
                          Icons.person_outline_rounded,
                          size: 30,
                          color: _accent,
                        )
                        : UserProfileAvatarImage(
                          imageValue: currentProfileImage,
                          fallbackIcon: Icons.person_outline_rounded,
                          fallbackColor: _accent,
                          size: 64,
                          fallbackIconSize: 30,
                          circle: true,
                        ),
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
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

  Widget _buildGroupedCard(
    BuildContext context, {
    required List<_GroupedItemData> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SixMobilePalette.onPrimary.withValues(alpha: 0.62),
          width: 0.8,
        ),
      ),
      child: Column(
        children:
            items.asMap().entries.map((MapEntry<int, _GroupedItemData> entry) {
              final int index = entry.key;
              final _GroupedItemData item = entry.value;
              return _buildGroupedTile(
                context,
                item: item,
                isFirst: index == 0,
                isLast: index == items.length - 1,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildGroupedTile(
    BuildContext context, {
    required _GroupedItemData item,
    required bool isFirst,
    required bool isLast,
  }) {
    final bool isEnabled = !item.comingSoon;
    final String comingSoonLabel = context.t(
      'gestao.settings.badge.comingSoon',
      fallback: 'Em breve',
    );

    return Semantics(
      button: isEnabled,
      enabled: isEnabled,
      label: item.semanticsLabel,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isFirst ? 20 : 0),
              bottom: Radius.circular(isLast ? 20 : 0),
            ),
            hoverColor: SixMobilePalette.accent.withValues(alpha: 0.06),
            splashColor: SixMobilePalette.accent.withValues(alpha: 0.08),
            onTap: isEnabled ? item.onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border:
                    isLast
                        ? null
                        : Border(
                          bottom: BorderSide(
                            color: _border.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _softSurface,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.icon, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _title,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (item.comingSoon) ...<Widget>[
                              const SizedBox(width: 8),
                              ManagementSettingsMaturityBadge(
                                maturity: ManagementSettingsMaturity.comingSoon,
                                label: comingSoonLabel,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isEnabled
                        ? Icons.chevron_right_rounded
                        : Icons.lock_outline_rounded,
                    color: _muted.withValues(alpha: 0.7),
                    size: isEnabled ? 22 : 16,
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
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: SixMobilePalette.error.withValues(alpha: 0.06),
          splashColor: SixMobilePalette.error.withValues(alpha: 0.08),
          onTap: () => _confirmLogoutWithSwipe(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.logout_rounded,
                  color: SixMobilePalette.error.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: SixMobilePalette.error.withValues(alpha: 0.8),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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
        version.isEmpty ? 'versão não informada' : 'v$version';
    final String tooltip =
        buildNumber.isEmpty
            ? 'Versão atual: ${version.isEmpty ? '-' : version}'
            : 'Versão atual: ${version.isEmpty ? '-' : version} • build $buildNumber';

    return SafeArea(
      top: false,
      left: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Tooltip(
          message: tooltip,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _softSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: _muted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    versionLabel,
                    style: TextStyle(
                      color: _muted.withValues(alpha: 0.7),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
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

  Future<void> _loadUser() {
    return _profileLoadFuture ??= _reloadUser();
  }

  Future<void> _reloadUser() async {
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

  Future<void> _confirmLogoutWithSwipe(BuildContext context) async {
    final bool confirmed =
        await showModalBottomSheet<bool>(
          context: context,
          showDragHandle: true,
          backgroundColor: _surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext bottomSheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _softSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _border.withValues(alpha: 0.48),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: SixMobilePalette.error.withValues(
                                  alpha: 0.18,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: SixMobilePalette.error.withValues(
                                alpha: 0.82,
                              ),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Sair da conta?',
                                  style: TextStyle(
                                    color: _title,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Confirme para encerrar sua sessão neste aparelho.',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LogoutSwipeConfirmation(
                      onConfirmed:
                          () => Navigator.of(bottomSheetContext).pop(true),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;

    if (!confirmed || !context.mounted) return;
    await _logout(context);
  }

  void _showImagePickerOptions(BuildContext context) {
    final String? currentProfileImage = UsuarioProvider().usuario?.foto.trim();

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
                _buildPhotoPreview(currentProfileImage),
                const SizedBox(height: 14),
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

  Widget _buildPhotoPreview(String? currentProfileImage) {
    final String imageValue = currentProfileImage ?? profileImage ?? '';

    return Center(
      child: Container(
        width: 82,
        height: 82,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _surface,
          border: Border.all(color: SixMobilePalette.highlightedBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: ColoredBox(
            color: _softSurface,
            child: UserProfileAvatarImage(
              imageValue: imageValue,
              fallbackIcon: Icons.person_outline_rounded,
              fallbackColor: _accent,
              size: 76,
              fallbackIconSize: 34,
              circle: true,
            ),
          ),
        ),
      ),
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
        onTap: () async {
          Navigator.of(context).pop();
          await onPickImage(source);
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

class _LogoutSwipeConfirmation extends StatefulWidget {
  const _LogoutSwipeConfirmation({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<_LogoutSwipeConfirmation> createState() =>
      _LogoutSwipeConfirmationState();
}

class _LogoutSwipeConfirmationState extends State<_LogoutSwipeConfirmation> {
  static const double _height = 54;
  static const double _padding = 4;
  static const double _thumbSize = 46;

  double _dragOffset = 0;
  bool _confirmed = false;

  void _updateDrag(double delta, double maxOffset) {
    if (_confirmed) return;
    setState(() {
      _dragOffset = (_dragOffset + delta).clamp(0, maxOffset);
    });
  }

  void _endDrag(double maxOffset) {
    if (_confirmed) return;

    if (_dragOffset >= maxOffset * 0.82) {
      setState(() {
        _confirmed = true;
        _dragOffset = maxOffset;
      });
      HapticFeedback.mediumImpact();
      widget.onConfirmed();
      return;
    }

    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxOffset = (constraints.maxWidth -
                _thumbSize -
                (_padding * 2))
            .clamp(0, double.infinity);
        final double progress = maxOffset == 0 ? 0 : _dragOffset / maxOffset;

        return Semantics(
          button: true,
          enabled: !_confirmed,
          label: 'Deslize para confirmar saída da conta',
          child: GestureDetector(
            onHorizontalDragUpdate:
                (DragUpdateDetails details) =>
                    _updateDrag(details.delta.dx, maxOffset),
            onHorizontalDragEnd: (_) => _endDrag(maxOffset),
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: SixMobilePalette.softNeutralSurface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: SixMobilePalette.border.withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: SixMobilePalette.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 58),
                    child: AnimatedOpacity(
                      opacity: _confirmed ? 0 : (1 - progress).clamp(0.35, 1),
                      duration: const Duration(milliseconds: 120),
                      child: const Text(
                        'Segure e deslize para sair',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration:
                        _confirmed
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: _padding + _dragOffset,
                    top: _padding,
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: SixMobilePalette.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: SixMobilePalette.error.withValues(
                            alpha: _confirmed ? 0.38 : 0.18,
                          ),
                          width: 0.9,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: SixMobilePalette.navigationShadow.withValues(
                              alpha: 0.85,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _confirmed
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: SixMobilePalette.error.withValues(alpha: 0.82),
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupedItemData {
  const _GroupedItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    this.comingSoon = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticsLabel;
  final bool comingSoon;
  final VoidCallback? onTap;
}
