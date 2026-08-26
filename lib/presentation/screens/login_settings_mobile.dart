import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_maturity_badge.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_theme_toggle.dart';
import 'package:sixpos/presentation/components/user_profile_avatar_image.dart';
import 'package:sixpos/presentation/screens/login_mobile.dart';
import 'package:sixpos/providers/theme_provider.dart';
import 'package:sixpos/providers/usuario_provider.dart';

import 'meu_perfil_mobile_screen.dart';

class _AccountPanelColors {
  const _AccountPanelColors({
    required this.panelStart,
    required this.panelMiddle,
    required this.panelEnd,
    required this.headerStart,
    required this.headerMiddle,
    required this.headerEnd,
    required this.surface,
    required this.softSurface,
    required this.iconSurface,
    required this.border,
    required this.cardBorder,
    required this.panelBorder,
    required this.headerBorder,
    required this.title,
    required this.muted,
    required this.accent,
    required this.error,
    required this.shadow,
    required this.secondaryShadow,
  });

  final Color panelStart;
  final Color panelMiddle;
  final Color panelEnd;
  final Color headerStart;
  final Color headerMiddle;
  final Color headerEnd;
  final Color surface;
  final Color softSurface;
  final Color iconSurface;
  final Color border;
  final Color cardBorder;
  final Color panelBorder;
  final Color headerBorder;
  final Color title;
  final Color muted;
  final Color accent;
  final Color error;
  final Color shadow;
  final Color secondaryShadow;

  static _AccountPanelColors resolve(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (theme.brightness != Brightness.dark) {
      return _AccountPanelColors(
        panelStart: SixMobilePalette.surface.withValues(alpha: 0.94),
        panelMiddle: SixMobilePalette.softNeutralSurface.withValues(
          alpha: 0.91,
        ),
        panelEnd: SixMobilePalette.background.withValues(alpha: 0.88),
        headerStart: SixMobilePalette.primary.withValues(alpha: 0.08),
        headerMiddle: SixMobilePalette.accent.withValues(alpha: 0.05),
        headerEnd: SixMobilePalette.surface.withValues(alpha: 0.35),
        surface: SixMobilePalette.surface,
        softSurface: SixMobilePalette.softNeutralSurface,
        iconSurface: SixMobilePalette.softNeutralSurface,
        border: SixMobilePalette.border,
        cardBorder: SixMobilePalette.onPrimary.withValues(alpha: 0.62),
        panelBorder: SixMobilePalette.onPrimary.withValues(alpha: 0.56),
        headerBorder: SixMobilePalette.onPrimary.withValues(alpha: 0.48),
        title: SixMobilePalette.titleText,
        muted: SixMobilePalette.mutedText,
        accent: SixMobilePalette.accent,
        error: SixMobilePalette.error,
        shadow: SixMobilePalette.heroShadow.withValues(alpha: 0.38),
        secondaryShadow: colorScheme.shadow.withValues(alpha: 0.08),
      );
    }

    final Color baseSurface = colorScheme.surface;
    final Color elevatedSurface = Color.alphaBlend(
      colorScheme.onSurface.withValues(alpha: 0.07),
      baseSurface,
    );
    final Color softSurface = Color.alphaBlend(
      SixMobilePalette.accent.withValues(alpha: 0.09),
      baseSurface,
    );
    final Color iconSurface = Color.alphaBlend(
      SixMobilePalette.accent.withValues(alpha: 0.14),
      baseSurface,
    );

    return _AccountPanelColors(
      panelStart: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.08),
        baseSurface,
      ).withValues(alpha: 0.97),
      panelMiddle: elevatedSurface.withValues(alpha: 0.95),
      panelEnd: Color.alphaBlend(
        SixMobilePalette.accent.withValues(alpha: 0.07),
        baseSurface,
      ).withValues(alpha: 0.92),
      headerStart: colorScheme.primary.withValues(alpha: 0.16),
      headerMiddle: SixMobilePalette.accent.withValues(alpha: 0.11),
      headerEnd: elevatedSurface.withValues(alpha: 0.62),
      surface: elevatedSurface,
      softSurface: softSurface,
      iconSurface: iconSurface,
      border: colorScheme.outlineVariant.withValues(alpha: 0.38),
      cardBorder: colorScheme.outlineVariant.withValues(alpha: 0.34),
      panelBorder: colorScheme.onSurface.withValues(alpha: 0.12),
      headerBorder: colorScheme.onSurface.withValues(alpha: 0.10),
      title: colorScheme.onSurface,
      muted: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
      accent: SixMobilePalette.highlightedBorder,
      error: SixMobilePalette.error,
      shadow: colorScheme.shadow.withValues(alpha: 0.44),
      secondaryShadow: colorScheme.shadow.withValues(alpha: 0.24),
    );
  }

  static _AccountPanelColors lerp(
    _AccountPanelColors begin,
    _AccountPanelColors end,
    double t,
  ) {
    return _AccountPanelColors(
      panelStart: Color.lerp(begin.panelStart, end.panelStart, t)!,
      panelMiddle: Color.lerp(begin.panelMiddle, end.panelMiddle, t)!,
      panelEnd: Color.lerp(begin.panelEnd, end.panelEnd, t)!,
      headerStart: Color.lerp(begin.headerStart, end.headerStart, t)!,
      headerMiddle: Color.lerp(begin.headerMiddle, end.headerMiddle, t)!,
      headerEnd: Color.lerp(begin.headerEnd, end.headerEnd, t)!,
      surface: Color.lerp(begin.surface, end.surface, t)!,
      softSurface: Color.lerp(begin.softSurface, end.softSurface, t)!,
      iconSurface: Color.lerp(begin.iconSurface, end.iconSurface, t)!,
      border: Color.lerp(begin.border, end.border, t)!,
      cardBorder: Color.lerp(begin.cardBorder, end.cardBorder, t)!,
      panelBorder: Color.lerp(begin.panelBorder, end.panelBorder, t)!,
      headerBorder: Color.lerp(begin.headerBorder, end.headerBorder, t)!,
      title: Color.lerp(begin.title, end.title, t)!,
      muted: Color.lerp(begin.muted, end.muted, t)!,
      accent: Color.lerp(begin.accent, end.accent, t)!,
      error: Color.lerp(begin.error, end.error, t)!,
      shadow: Color.lerp(begin.shadow, end.shadow, t)!,
      secondaryShadow:
          Color.lerp(begin.secondaryShadow, end.secondaryShadow, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _AccountPanelColors &&
            other.panelStart == panelStart &&
            other.panelMiddle == panelMiddle &&
            other.panelEnd == panelEnd &&
            other.headerStart == headerStart &&
            other.headerMiddle == headerMiddle &&
            other.headerEnd == headerEnd &&
            other.surface == surface &&
            other.softSurface == softSurface &&
            other.iconSurface == iconSurface &&
            other.border == border &&
            other.cardBorder == cardBorder &&
            other.panelBorder == panelBorder &&
            other.headerBorder == headerBorder &&
            other.title == title &&
            other.muted == muted &&
            other.accent == accent &&
            other.error == error &&
            other.shadow == shadow &&
            other.secondaryShadow == secondaryShadow;
  }

  @override
  int get hashCode => Object.hashAll(<Object>[
    panelStart,
    panelMiddle,
    panelEnd,
    headerStart,
    headerMiddle,
    headerEnd,
    surface,
    softSurface,
    iconSurface,
    border,
    cardBorder,
    panelBorder,
    headerBorder,
    title,
    muted,
    accent,
    error,
    shadow,
    secondaryShadow,
  ]);
}

class _AccountPanelColorsTween extends Tween<_AccountPanelColors> {
  _AccountPanelColorsTween({super.end});

  @override
  _AccountPanelColors lerp(double t) {
    final _AccountPanelColors? begin = this.begin;
    final _AccountPanelColors? end = this.end;

    if (begin == null && end == null) {
      throw StateError('Account panel color tween requires a target value.');
    }
    if (begin == null) return end!;
    if (end == null) return begin;

    return _AccountPanelColors.lerp(begin, end, t);
  }
}

class LoginSettingsMobile extends StatefulWidget {
  const LoginSettingsMobile({
    super.key,
    required this.profileImage,
    required this.onPickImage,
    required this.isUpdatingImage,
  });

  final String? profileImage;
  final Future<void> Function(ImageSource source) onPickImage;
  final bool isUpdatingImage;

  @override
  State<LoginSettingsMobile> createState() => _LoginSettingsMobileState();
}

class _LoginSettingsMobileState extends State<LoginSettingsMobile> {
  static Future<void>? _profileLoadFuture;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final _AccountPanelColors targetColors = _AccountPanelColors.resolve(
      context,
    );
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final String themeTitle = context.t(
      'account.settings.theme.dark.title',
      fallback: 'Tema escuro',
    );
    final String themeSubtitle = context.t(
      isDarkMode
          ? 'account.settings.theme.dark.enabled'
          : 'account.settings.theme.dark.disabled',
      fallback:
          isDarkMode
              ? 'Interface com fundo escuro ativada'
              : 'Reduz o brilho da interface neste aparelho',
    );
    final String themeSemantics = context.t(
      isDarkMode
          ? 'account.settings.theme.dark.disable'
          : 'account.settings.theme.dark.enable',
      fallback: isDarkMode ? 'Desativar tema escuro' : 'Ativar tema escuro',
    );

    return TweenAnimationBuilder<_AccountPanelColors>(
      tween: _AccountPanelColorsTween(end: targetColors),
      duration: reduceMotion ? Duration.zero : Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (
        BuildContext context,
        _AccountPanelColors colors,
        Widget? child,
      ) {
        return SafeArea(
          left: false,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        colors.panelStart,
                        colors.panelMiddle,
                        colors.panelEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(28),
                    ),
                    border: Border(
                      left: BorderSide(color: colors.panelBorder, width: 0.8),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 34,
                        spreadRadius: 1,
                        offset: Offset(-12, 0),
                      ),
                      BoxShadow(
                        color: colors.secondaryShadow,
                        blurRadius: 18,
                        offset: Offset(-4, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      _buildHeader(context, colors),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 18),
                          children: <Widget>[
                            _buildSectionLabel(
                              context,
                              colors,
                              context.t(
                                'account.settings.section.account',
                                fallback: 'Conta',
                              ),
                            ),
                            _buildGroupedCard(
                              context,
                              colors: colors,
                              items: <_GroupedItemData>[
                                _GroupedItemData(
                                  icon: Icons.person_outline_rounded,
                                  title: context.t(
                                    'account.settings.profile.title',
                                    fallback: 'Meu perfil',
                                  ),
                                  subtitle: context.t(
                                    'account.settings.profile.subtitle',
                                    fallback: 'Dados pessoais e acesso',
                                  ),
                                  semanticsLabel: context.t(
                                    'account.settings.profile.open',
                                    fallback: 'Abrir meu perfil',
                                  ),
                                  onTap:
                                      () => _openScreen(
                                        context,
                                        MeuPerfilMobileScreen(),
                                      ),
                                ),
                                _GroupedItemData(
                                  icon:
                                      isDarkMode
                                          ? Icons.nightlight_round
                                          : Icons.wb_sunny_rounded,
                                  title: themeTitle,
                                  subtitle: themeSubtitle,
                                  semanticsLabel: themeSemantics,
                                  onTap:
                                      () => _toggleTheme(context, !isDarkMode),
                                  toggled: isDarkMode,
                                  trailing: ExcludeSemantics(
                                    child: SixMobileThemeToggle(
                                      isDark: isDarkMode,
                                      semanticsLabel: themeSemantics,
                                      onChanged:
                                          (bool value) =>
                                              _toggleTheme(context, value),
                                    ),
                                  ),
                                ),
                                _GroupedItemData(
                                  icon: Icons.tune_rounded,
                                  title: context.t(
                                    'account.settings.preferences.title',
                                    fallback: 'Preferências',
                                  ),
                                  subtitle: context.t(
                                    'account.settings.preferences.subtitle',
                                    fallback: 'Ajustes individuais do app',
                                  ),
                                  semanticsLabel: context.t(
                                    'account.settings.preferences.open',
                                    fallback: 'Abrir preferências',
                                  ),
                                  comingSoon: true,
                                ),
                                _GroupedItemData(
                                  icon: Icons.privacy_tip_outlined,
                                  title: context.t(
                                    'account.settings.privacy.title',
                                    fallback: 'Gerenciar meus dados',
                                  ),
                                  subtitle: context.t(
                                    'account.settings.privacy.subtitle',
                                    fallback: 'Dados e privacidade',
                                  ),
                                  semanticsLabel: context.t(
                                    'account.settings.privacy.open',
                                    fallback:
                                        'Abrir gerenciamento dos meus dados',
                                  ),
                                  comingSoon: true,
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            _buildSectionLabel(
                              context,
                              colors,
                              context.t(
                                'account.settings.section.about',
                                fallback: 'Sobre',
                              ),
                            ),
                            _buildGroupedCard(
                              context,
                              colors: colors,
                              items: <_GroupedItemData>[
                                _GroupedItemData(
                                  icon: Icons.help_outline_rounded,
                                  title: context.t(
                                    'account.settings.support.title',
                                    fallback: 'Ajuda e suporte',
                                  ),
                                  subtitle: context.t(
                                    'account.settings.support.subtitle',
                                    fallback: 'Dúvidas e contato',
                                  ),
                                  semanticsLabel: context.t(
                                    'account.settings.support.open',
                                    fallback: 'Abrir ajuda e suporte',
                                  ),
                                  comingSoon: true,
                                ),
                                _GroupedItemData(
                                  icon: Icons.description_outlined,
                                  title: context.t(
                                    'account.settings.terms.title',
                                    fallback: 'Termos e políticas',
                                  ),
                                  subtitle: context.t(
                                    'account.settings.terms.subtitle',
                                    fallback: 'Uso, privacidade e licenças',
                                  ),
                                  semanticsLabel: context.t(
                                    'account.settings.terms.open',
                                    fallback: 'Abrir termos e políticas',
                                  ),
                                  comingSoon: true,
                                ),
                              ],
                            ),

                            SizedBox(height: 20),
                            _buildLogoutItem(context, colors),
                          ],
                        ),
                      ),
                      _buildVersionFooter(context, colors),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, _AccountPanelColors colors) {
    final UsuarioProvider usuarioProvider = UsuarioProvider();
    final String closeLabel = context.t(
      'account.settings.close',
      fallback: 'Fechar configurações',
    );

    return FutureBuilder<void>(
      future: _loadUser(),
      builder: (BuildContext context, AsyncSnapshot<void> _) {
        return ListenableBuilder(
          listenable: usuarioProvider,
          builder: (BuildContext context, Widget? _) {
            final UsuarioModel? usuario = usuarioProvider.usuario;

            return Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(18, 16, 14, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    colors.headerStart,
                    colors.headerMiddle,
                    colors.headerEnd,
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: colors.headerBorder, width: 0.6),
                ),
              ),
              child: Row(
                children: <Widget>[
                  _buildAvatar(
                    context,
                    colors,
                    usuario?.foto ?? widget.profileImage,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _userName(context, usuario),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.title,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _userEmail(context, usuario),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    tooltip: closeLabel,
                    icon: Icon(Icons.close_rounded),
                    color: colors.title,
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

  Widget _buildAvatar(
    BuildContext context,
    _AccountPanelColors colors,
    String? currentProfileImage,
  ) {
    final String avatarLabel = context.t(
      'account.settings.avatar.change',
      fallback: 'Alterar foto do perfil',
    );

    return Semantics(
      button: true,
      label: avatarLabel,
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
                    colors.accent.withValues(alpha: 0.10),
                    colors.accent.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(
                  color: SixMobilePalette.onPrimary.withValues(alpha: 0.72),
                  width: 2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.42),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: colors.softSurface,
                child:
                    widget.isUpdatingImage
                        ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: colors.accent,
                          ),
                        )
                        : (currentProfileImage?.trim().isEmpty ?? true)
                        ? Icon(
                          Icons.person_outline_rounded,
                          size: 30,
                          color: colors.accent,
                        )
                        : UserProfileAvatarImage(
                          imageValue: currentProfileImage,
                          fallbackIcon: Icons.person_outline_rounded,
                          fallbackColor: colors.accent,
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
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.accent, width: 1.2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors.secondaryShadow.withValues(alpha: 0.7),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 14,
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    BuildContext context,
    _AccountPanelColors colors,
    String label,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(
    BuildContext context, {
    required _AccountPanelColors colors,
    required List<_GroupedItemData> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder, width: 0.8),
      ),
      child: Column(
        children:
            items.asMap().entries.map((MapEntry<int, _GroupedItemData> entry) {
              final int index = entry.key;
              final _GroupedItemData item = entry.value;
              return _buildGroupedTile(
                context,
                colors: colors,
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
    required _AccountPanelColors colors,
    required _GroupedItemData item,
    required bool isFirst,
    required bool isLast,
  }) {
    final bool isEnabled = !item.comingSoon;
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    final bool reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    final String comingSoonLabel = context.t(
      'gestao.settings.badge.comingSoon',
      fallback: 'Em breve',
    );

    return Semantics(
      button: isEnabled,
      enabled: isEnabled,
      toggled: item.toggled,
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
            hoverColor: colors.accent.withValues(alpha: 0.08),
            splashColor: colors.accent.withValues(alpha: 0.10),
            onTap: isEnabled ? item.onTap : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border:
                    isLast
                        ? null
                        : Border(
                          bottom: BorderSide(
                            color: colors.border.withValues(alpha: 0.5),
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
                      color: colors.iconSurface,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: AnimatedSwitcher(
                      duration:
                          reduceMotion
                              ? Duration.zero
                              : Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.76,
                              end: 1,
                            ).animate(animation),
                            child: RotationTransition(
                              turns: Tween<double>(
                                begin: -0.08,
                                end: 0,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Icon(
                        item.icon,
                        key: ValueKey<IconData>(item.icon),
                        color: colors.accent,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
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
                                style: TextStyle(
                                  color: colors.title,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (item.comingSoon) ...<Widget>[
                              SizedBox(width: 8),
                              ManagementSettingsMaturityBadge(
                                maturity: ManagementSettingsMaturity.comingSoon,
                                label: comingSoonLabel,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6),
                  item.trailing ??
                      Icon(
                        isEnabled
                            ? Icons.chevron_right_rounded
                            : Icons.lock_outline_rounded,
                        color: colors.muted.withValues(alpha: 0.7),
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

  Widget _buildLogoutItem(BuildContext context, _AccountPanelColors colors) {
    final String logoutLabel = context.t(
      'account.settings.logout',
      fallback: 'Sair da conta',
    );

    return Semantics(
      button: true,
      label: logoutLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: colors.error.withValues(alpha: 0.06),
          splashColor: colors.error.withValues(alpha: 0.08),
          onTap: () => _confirmLogoutWithSwipe(context),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.logout_rounded,
                  color: colors.error.withValues(alpha: 0.8),
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  logoutLabel,
                  style: TextStyle(
                    color: colors.error.withValues(alpha: 0.8),
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

  Widget _buildVersionFooter(BuildContext context, _AccountPanelColors colors) {
    final String version = AppConfig.appVersion.trim();
    final String buildNumber = AppConfig.appBuildNumber.trim();
    final String versionLabel =
        version.isEmpty
            ? context.t(
              'account.settings.version.unavailable',
              fallback: 'versão não informada',
            )
            : 'v$version';
    final String currentVersionPrefix = context.t(
      'account.settings.version.currentPrefix',
      fallback: 'Versão atual',
    );
    final String buildPrefix = context.t(
      'account.settings.version.buildPrefix',
      fallback: 'compilação',
    );
    final String versionValue = version.isEmpty ? '-' : version;
    final String tooltip =
        buildNumber.isEmpty
            ? '$currentVersionPrefix: $versionValue'
            : '$currentVersionPrefix: $versionValue • $buildPrefix $buildNumber';

    return SafeArea(
      top: false,
      left: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Tooltip(
          message: tooltip,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.softSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: colors.muted.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 6),
                  Text(
                    versionLabel,
                    style: TextStyle(
                      color: colors.muted.withValues(alpha: 0.7),
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

  String _userName(BuildContext context, UsuarioModel? usuario) {
    final String nomeDeGuerra = usuario?.nomeDeGuerra.trim() ?? '';
    if (nomeDeGuerra.isNotEmpty) return nomeDeGuerra;

    final String nomeCompleto = <String>[
      usuario?.nome.trim() ?? '',
      usuario?.sobrenome.trim() ?? '',
    ].where((String parte) => parte.isNotEmpty).join(' ');

    return nomeCompleto.isEmpty
        ? context.t('account.settings.user.fallbackName', fallback: 'Usuário')
        : nomeCompleto;
  }

  String _userEmail(BuildContext context, UsuarioModel? usuario) {
    final String email = usuario?.email.trim() ?? '';
    return email.isEmpty
        ? context.t(
          'account.settings.user.emailUnavailable',
          fallback: 'E-mail não informado',
        )
        : email;
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _toggleTheme(BuildContext context, bool isDarkMode) {
    unawaited(context.read<ThemeProvider>().toggleTheme(isDarkMode));
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginPageMobile()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _confirmLogoutWithSwipe(BuildContext context) async {
    final _AccountPanelColors colors = _AccountPanelColors.resolve(context);
    final String confirmTitle = context.t(
      'account.settings.logout.confirmTitle',
      fallback: 'Sair da conta?',
    );
    final String confirmSubtitle = context.t(
      'account.settings.logout.confirmSubtitle',
      fallback: 'Confirme para encerrar sua sessão neste aparelho.',
    );
    final String cancelLabel = context.t('common.cancel', fallback: 'Cancelar');

    final bool confirmed =
        await showModalBottomSheet<bool>(
          context: context,
          showDragHandle: true,
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext bottomSheetContext) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.48),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: colors.error.withValues(alpha: 0.18),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: colors.error.withValues(alpha: 0.82),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  confirmTitle,
                                  style: TextStyle(
                                    color: colors.title,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  confirmSubtitle,
                                  style: TextStyle(
                                    color: colors.muted,
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
                    SizedBox(height: 14),
                    _LogoutSwipeConfirmation(
                      colors: colors,
                      onConfirmed:
                          () => Navigator.of(bottomSheetContext).pop(true),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      child: Text(cancelLabel),
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
    final _AccountPanelColors colors = _AccountPanelColors.resolve(context);
    final String? currentProfileImage = UsuarioProvider().usuario?.foto.trim();
    final String title = context.t(
      'account.settings.avatar.sheetTitle',
      fallback: 'Foto do perfil',
    );
    final String cameraLabel = context.t(
      'account.settings.avatar.camera',
      fallback: 'Tirar foto',
    );
    final String galleryLabel = context.t(
      'account.settings.avatar.gallery',
      fallback: 'Escolher da galeria',
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12),
                _buildPhotoPreview(context, currentProfileImage),
                SizedBox(height: 14),
                _buildImageOption(
                  bottomSheetContext,
                  icon: Icons.photo_camera_outlined,
                  title: cameraLabel,
                  source: ImageSource.camera,
                ),
                SizedBox(height: 8),
                _buildImageOption(
                  bottomSheetContext,
                  icon: Icons.photo_library_outlined,
                  title: galleryLabel,
                  source: ImageSource.gallery,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoPreview(BuildContext context, String? currentProfileImage) {
    final _AccountPanelColors colors = _AccountPanelColors.resolve(context);
    final String imageValue = currentProfileImage ?? widget.profileImage ?? '';

    return Center(
      child: Container(
        width: 82,
        height: 82,
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface,
          border: Border.all(color: SixMobilePalette.highlightedBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.navigationShadow.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: ColoredBox(
            color: colors.softSurface,
            child: UserProfileAvatarImage(
              imageValue: imageValue,
              fallbackIcon: Icons.person_outline_rounded,
              fallbackColor: colors.accent,
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
    final _AccountPanelColors colors = _AccountPanelColors.resolve(context);

    return Material(
      color: colors.softSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          Navigator.of(context).pop();
          await widget.onPickImage(source);
        },
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: colors.accent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.title,
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
  const _LogoutSwipeConfirmation({
    required this.colors,
    required this.onConfirmed,
  });

  final _AccountPanelColors colors;
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
          label: context.t(
            'account.settings.logout.swipeSemantics',
            fallback: 'Deslize para confirmar saída da conta',
          ),
          child: GestureDetector(
            onHorizontalDragUpdate:
                (DragUpdateDetails details) =>
                    _updateDrag(details.delta.dx, maxOffset),
            onHorizontalDragEnd: (_) => _endDrag(maxOffset),
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: widget.colors.softSurface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: widget.colors.border.withValues(alpha: 0.7),
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
                          color: widget.colors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 58),
                    child: AnimatedOpacity(
                      opacity: _confirmed ? 0 : (1 - progress).clamp(0.35, 1),
                      duration: Duration(milliseconds: 120),
                      child: Text(
                        context.t(
                          'account.settings.logout.swipeHint',
                          fallback: 'Segure e deslize para sair',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.colors.muted,
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
                            : Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: _padding + _dragOffset,
                    top: _padding,
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: widget.colors.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.colors.error.withValues(
                            alpha: _confirmed ? 0.38 : 0.18,
                          ),
                          width: 0.9,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: widget.colors.secondaryShadow.withValues(
                              alpha: 0.85,
                            ),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _confirmed
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: widget.colors.error.withValues(alpha: 0.82),
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
    this.trailing,
    this.toggled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticsLabel;
  final bool comingSoon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool? toggled;
}
