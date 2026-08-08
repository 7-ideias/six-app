import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_account_panel_action.dart';
import 'package:sixpos/presentation/utils/profile_image_payload.dart';
import 'package:sixpos/providers/usuario_provider.dart';

class SixMobileAppBarProfileAction extends StatefulWidget {
  const SixMobileAppBarProfileAction({
    super.key,
    this.size = 34,
    this.padding = const EdgeInsets.only(left: 10, right: 6),
  });

  final double size;
  final EdgeInsetsGeometry padding;

  @override
  State<SixMobileAppBarProfileAction> createState() =>
      _SixMobileAppBarProfileActionState();
}

class _SixMobileAppBarProfileActionState
    extends State<SixMobileAppBarProfileAction> {
  final ImagePicker _picker = ImagePicker();
  final UsuarioProvider _usuarioProvider = UsuarioProvider();
  final UsuarioService _usuarioService = UsuarioService();

  bool _isSavingImage = false;
  bool _isSyncingProfile = false;
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _profileImage = _resolveProfileImage();
    _usuarioProvider.addListener(_onUsuarioChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncProfileIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _usuarioProvider.removeListener(_onUsuarioChanged);
    super.dispose();
  }

  void _onUsuarioChanged() {
    if (!mounted) return;
    setState(() => _profileImage = _resolveProfileImage());
  }

  String? _resolveProfileImage() {
    final String image = _usuarioProvider.usuario?.foto.trim() ?? '';
    return image.isEmpty ? null : image;
  }

  Future<void> _syncProfileIfNeeded() async {
    if (_isSyncingProfile || _usuarioProvider.usuario != null) {
      return;
    }

    _isSyncingProfile = true;
    try {
      await _usuarioService.buscarDadosDoUsuario_atualizaProviders();
    } catch (error) {
      debugPrint(
        '[SixMobileAppBarProfileAction] Falha ao sincronizar perfil: $error',
      );
    } finally {
      _isSyncingProfile = false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isSavingImage) {
      return;
    }

    final XFile? selected = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (selected == null) {
      return;
    }

    if (mounted) {
      setState(() => _isSavingImage = true);
    } else {
      _isSavingImage = true;
    }

    try {
      final String imageDataUrl = await buildProfileImageDataUrl(selected);
      await _usuarioService.atualizarFotoDoUsuario(imageDataUrl);
      if (mounted) {
        setState(() => _profileImage = imageDataUrl);
      } else {
        _profileImage = imageDataUrl;
      }
    } catch (error) {
      debugPrint(
        '[SixMobileAppBarProfileAction] Falha ao atualizar foto: $error',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'perfil.mobile.photoSaveError',
              fallback:
                  'Não foi possível atualizar a foto do perfil. Tente novamente.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingImage = false);
      } else {
        _isSavingImage = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final Color foregroundColor =
        IconTheme.of(context).color ?? SixMobilePalette.onPrimary;
    final bool hasLightForeground =
        ThemeData.estimateBrightnessForColor(foregroundColor) ==
        Brightness.light;

    return Padding(
      padding: widget.padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SixMobileAccountPanelAction(
          profileImage: _profileImage,
          onPickImage: _pickImage,
          isUpdatingImage: _isSavingImage,
          size: widget.size,
          borderColor:
              hasLightForeground
                  ? foregroundColor.withValues(alpha: 0.28)
                  : colors.border.withValues(alpha: 0.85),
          backgroundColor:
              hasLightForeground
                  ? foregroundColor.withValues(alpha: 0.12)
                  : colors.surface.withValues(alpha: 0.96),
          iconColor: foregroundColor,
        ),
      ),
    );
  }
}
