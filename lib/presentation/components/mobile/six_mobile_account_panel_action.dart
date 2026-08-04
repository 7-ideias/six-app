import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/presentation/components/app_modal_side_sheet.dart';
import 'package:sixpos/presentation/screens/login_settings_mobile.dart';

class SixMobileAccountPanelAction extends StatelessWidget {
  const SixMobileAccountPanelAction({
    super.key,
    required this.image,
    required this.onPickImage,
  });

  final File? image;
  final void Function(ImageSource source) onPickImage;

  static Future<void> open(
    BuildContext context, {
    required File? image,
    required void Function(ImageSource source) onPickImage,
  }) {
    return showAppModalSideSheet<void>(
      context: context,
      barrierLabel: 'Fechar configurações',
      child: LoginSettingsMobile(image: image, onPickImage: onPickImage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir configurações da conta',
      child: IconButton(
        tooltip: 'Abrir configurações da conta',
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => open(context, image: image, onPickImage: onPickImage),
      ),
    );
  }
}
