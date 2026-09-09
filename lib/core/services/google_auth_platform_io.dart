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

  // No Android, o OAuth client nativo é resolvido pelo package name +
  // certificado SHA cadastrados no Google/Firebase. O GoogleAuthService envia
  // separadamente o OAuth Web como serverClientId para emissão do idToken.
  return const GoogleAuthPlatformConfig();
}

bool isGoogleAuthNetworkError(Object error) => error is SocketException;
