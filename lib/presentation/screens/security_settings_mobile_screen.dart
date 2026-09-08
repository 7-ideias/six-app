import 'package:flutter/material.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/biometric_auth_service.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';

class SecuritySettingsMobileScreen extends StatefulWidget {
  const SecuritySettingsMobileScreen({super.key});

  @override
  State<SecuritySettingsMobileScreen> createState() =>
      _SecuritySettingsMobileScreenState();
}

class _SecuritySettingsMobileScreenState
    extends State<SecuritySettingsMobileScreen> {
  final AuthService _authService = AuthService();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();

  bool _loading = true;
  bool _updating = false;
  bool _enabled = false;
  String? _userId;
  MobileBiometricAvailability _availability =
      const MobileBiometricAvailability.unavailable();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _localized({
    required String pt,
    required String en,
    required String es,
  }) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => en,
      'es' => es,
      _ => pt,
    };
  }

  String _biometricName() {
    return switch (_availability.kind) {
      MobileBiometricKind.faceId => 'Face ID',
      MobileBiometricKind.touchId => 'Touch ID',
      MobileBiometricKind.face => _localized(
          pt: 'reconhecimento facial',
          en: 'face recognition',
          es: 'reconocimiento facial',
        ),
      MobileBiometricKind.fingerprint => _localized(
          pt: 'impressão digital',
          en: 'fingerprint',
          es: 'huella digital',
        ),
      MobileBiometricKind.generic => _localized(
          pt: 'biometria',
          en: 'biometrics',
          es: 'biometría',
        ),
    };
  }

  IconData _biometricIcon() {
    return switch (_availability.kind) {
      MobileBiometricKind.fingerprint || MobileBiometricKind.touchId =>
        Icons.fingerprint_rounded,
      MobileBiometricKind.faceId || MobileBiometricKind.face =>
        Icons.face_retouching_natural_rounded,
      MobileBiometricKind.generic => Icons.shield_outlined,
    };
  }

  Future<void> _load() async {
    final String? userId = await _authService.getUserId();
    final MobileBiometricAvailability availability =
        await _biometricAuthService.availability();
    await _biometricAuthService.reconcileAuthenticatedUser(userId);
    final bool enabled = await _biometricAuthService.isEnabled();

    if (!mounted) return;
    setState(() {
      _userId = userId;
      _availability = availability;
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (_updating || _loading) return;

    if (!value) {
      setState(() => _updating = true);
      try {
        await _biometricAuthService.disable();
        if (!mounted) return;
        setState(() => _enabled = false);
        _showMessage(
          _localized(
            pt: 'Acesso biométrico desativado neste aparelho.',
            en: 'Biometric access disabled on this device.',
            es: 'Acceso biométrico desactivado en este dispositivo.',
          ),
        );
      } finally {
        if (mounted) setState(() => _updating = false);
      }
      return;
    }

    if (!_availability.canAuthenticate) {
      _showMessage(
        _localized(
          pt: 'Configure uma biometria nas opções de segurança do aparelho e tente novamente.',
          en: 'Set up biometrics in your device security settings and try again.',
          es: 'Configura la biometría en los ajustes de seguridad del dispositivo e inténtalo de nuevo.',
        ),
      );
      return;
    }

    final String userId = _userId?.trim() ?? '';
    if (userId.isEmpty) {
      _showMessage(
        _localized(
          pt: 'Não foi possível identificar o usuário desta sessão.',
          en: 'We could not identify the user for this session.',
          es: 'No pudimos identificar al usuario de esta sesión.',
        ),
      );
      return;
    }

    setState(() => _updating = true);
    try {
      final bool enabled = await _biometricAuthService.enableForUser(
        userId: userId,
        localizedReason: _localized(
          pt: 'Confirme sua identidade para ativar o acesso biométrico ao SixoApp.',
          en: 'Confirm your identity to enable biometric access to SixoApp.',
          es: 'Confirma tu identidad para activar el acceso biométrico a SixoApp.',
        ),
      );
      if (!mounted) return;

      setState(() => _enabled = enabled);
      _showMessage(
        enabled
            ? _localized(
              pt: '${_biometricName()} ativado neste aparelho.',
              en: '${_biometricName()} enabled on this device.',
              es: '${_biometricName()} activado en este dispositivo.',
            )
            : _localized(
              pt: 'A ativação não foi concluída.',
              en: 'Biometric activation was not completed.',
              es: 'La activación biométrica no se completó.',
            ),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final String biometricName = _biometricName();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.titleText,
        elevation: 0,
        title: Text(
          context.t(
            'account.security.title',
            fallback: _localized(
              pt: 'Segurança',
              en: 'Security',
              es: 'Seguridad',
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child:
            _loading
                ? Center(
                  child: CircularProgressIndicator(color: colors.accent),
                )
                : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: colors.softAccentSurface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _biometricIcon(),
                                  color: colors.accent,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _availability.canAuthenticate
                                          ? biometricName
                                          : _localized(
                                            pt: 'Acesso biométrico',
                                            en: 'Biometric access',
                                            es: 'Acceso biométrico',
                                          ),
                                      style: TextStyle(
                                        color: colors.titleText,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _enabled
                                          ? _localized(
                                            pt: 'Ativo neste aparelho',
                                            en: 'Enabled on this device',
                                            es: 'Activo en este dispositivo',
                                          )
                                          : _availability.canAuthenticate
                                          ? _localized(
                                            pt: 'Disponível para ativação',
                                            en: 'Available to enable',
                                            es: 'Disponible para activar',
                                          )
                                          : _localized(
                                            pt: 'Não configurado no aparelho',
                                            en: 'Not configured on this device',
                                            es: 'No configurado en este dispositivo',
                                          ),
                                      style: TextStyle(
                                        color: colors.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _enabled,
                                onChanged:
                                    _updating ? null : _toggleBiometrics,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _localized(
                              pt: 'Quando ativado, o SixoApp pede $biometricName antes de restaurar sua sessão em uma nova abertura do app.',
                              en: 'When enabled, SixoApp requests $biometricName before restoring your session on a new app launch.',
                              es: 'Cuando está activo, SixoApp solicita $biometricName antes de restaurar tu sesión al abrir de nuevo la app.',
                            ),
                            style: TextStyle(
                              color: colors.mutedText,
                              height: 1.45,
                            ),
                          ),
                          if (_updating) ...<Widget>[
                            const SizedBox(height: 16),
                            LinearProgressIndicator(color: colors.accent),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.verified_user_outlined,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _localized(
                                    pt: 'Sua biometria não sai do aparelho',
                                    en: 'Your biometrics never leave the device',
                                    es: 'Tu biometría nunca sale del dispositivo',
                                  ),
                                  style: TextStyle(
                                    color: colors.titleText,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _localized(
                                    pt: 'Face ID, Touch ID, rosto ou impressão digital são validados pelo sistema operacional. O SixoApp recebe apenas o resultado da autenticação. O refresh token da sessão fica protegido no Keychain/Keystore.',
                                    en: 'Face ID, Touch ID, face or fingerprint are validated by the operating system. SixoApp receives only the authentication result. The session refresh token is protected in Keychain/Keystore.',
                                    es: 'Face ID, Touch ID, rostro o huella se validan en el sistema operativo. SixoApp recibe solo el resultado de la autenticación. El refresh token de la sesión queda protegido en Keychain/Keystore.',
                                  ),
                                  style: TextStyle(
                                    color: colors.mutedText,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
