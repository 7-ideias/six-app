import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/app_modal_side_sheet.dart';
import 'package:sixpos/presentation/components/user_profile_avatar_image.dart';
import 'package:sixpos/presentation/screens/login_settings_mobile.dart';

class SixMobileAccountPanelAction extends StatelessWidget {
  const SixMobileAccountPanelAction({
    super.key,
    required this.profileImage,
    required this.onPickImage,
    this.size = 40,
    this.borderColor,
    this.backgroundColor,
    this.iconColor,
    this.isUpdatingImage = false,
  });

  final String? profileImage;
  final Future<void> Function(ImageSource source) onPickImage;
  final double size;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isUpdatingImage;

  static Future<void> open(
    BuildContext context, {
    required String? profileImage,
    required Future<void> Function(ImageSource source) onPickImage,
    required bool isUpdatingImage,
  }) {
    return showAppModalSideSheet<void>(
      context: context,
      barrierLabel: context.t(
        'account.settings.close',
        fallback: 'Fechar configurações',
      ),
      child: LoginSettingsMobile(
        profileImage: profileImage,
        onPickImage: onPickImage,
        isUpdatingImage: isUpdatingImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String accessibilityLabel = context.t(
      'account.settings.open',
      fallback: 'Abrir configurações da conta',
    );

    return Semantics(
      button: true,
      label: accessibilityLabel,
      child: Tooltip(
        message: accessibilityLabel,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap:
                () => open(
                  context,
                  profileImage: profileImage,
                  onPickImage: onPickImage,
                  isUpdatingImage: isUpdatingImage,
                ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    backgroundColor ??
                    theme.colorScheme.surface.withValues(alpha: 0.14),
                border: Border.all(
                  color:
                      borderColor ??
                      theme.colorScheme.onSurface.withValues(alpha: 0.18),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  isUpdatingImage
                      ? SizedBox(
                        width: size * 0.42,
                        height: size * 0.42,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor ?? theme.colorScheme.onSurface,
                        ),
                      )
                      : UserProfileAvatarImage(
                        imageValue: profileImage,
                        fallbackIcon: Icons.person_rounded,
                        fallbackColor: iconColor ?? theme.colorScheme.onSurface,
                        size: size,
                        fallbackIconSize: size * 0.54,
                        circle: true,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
