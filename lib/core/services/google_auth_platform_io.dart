import 'dart:io';

class GoogleAuthPlatformConfig {
  const GoogleAuthPlatformConfig({this.clientId});

  final String? clientId;
}

GoogleAuthPlatformConfig resolveGoogleAuthPlatformConfig() {
  const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  if (Platform.isIOS || Platform.isMacOS) {
    return GoogleAuthPlatformConfig(
      clientId: iosClientId.isEmpty ? null : iosClientId,
    );
  }

  if (Platform.isAndroid) {
    // google_sign_in_android 6.x não usa o OAuth Android client id como
    // `clientId`. No Android, a identidade do app é validada pelo package name
    // + certificado SHA cadastrados no Google/Firebase. O OAuth Web usado para
    // emitir idToken para o backend é informado separadamente em
    // `serverClientId` pelo GoogleAuthService.
    return const GoogleAuthPlatformConfig();
  }

  return const GoogleAuthPlatformConfig();
}

bool isGoogleAuthNetworkError(Object error) => error is SocketException;
