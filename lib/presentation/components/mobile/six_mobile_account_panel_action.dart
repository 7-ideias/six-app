import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/app_modal_side_sheet.dart';
import 'package:sixpos/presentation/screens/login_settings_mobile.dart';

class SixMobileAccountPanelAction extends StatelessWidget {
  const SixMobileAccountPanelAction({
    super.key,
    required this.image,
    required this.onPickImage,
    this.size = 40,
    this.borderColor,
    this.backgroundColor,
    this.iconColor,
  });

  final File? image;
  final void Function(ImageSource source) onPickImage;
  final double size;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? iconColor;

  static Future<void> open(
    BuildContext context, {
    required File? image,
    required void Function(ImageSource source) onPickImage,
  }) {
    return showAppModalSideSheet<void>(
      context: context,
      barrierLabel: context.t(
        'account.settings.close',
        fallback: 'Fechar configurações',
      ),
      child: LoginSettingsMobile(image: image, onPickImage: onPickImage),
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
            onTap: () => open(context, image: image, onPickImage: onPickImage),
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
                  image == null
                      ? Icon(
                        Icons.person_rounded,
                        size: size * 0.54,
                        color: iconColor ?? theme.colorScheme.onSurface,
                      )
                      : Image.file(
                        image!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
