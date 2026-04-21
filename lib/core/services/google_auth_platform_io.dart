import 'dart:io';

class GoogleAuthPlatformConfig {
  const GoogleAuthPlatformConfig({this.clientId});

  final String? clientId;
}

GoogleAuthPlatformConfig resolveGoogleAuthPlatformConfig() {
  const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  const androidClientId = String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');

  if (Platform.isIOS || Platform.isMacOS) {
    return GoogleAuthPlatformConfig(
      clientId: iosClientId.isEmpty ? null : iosClientId,
    );
  }
  if (Platform.isAndroid) {
    return GoogleAuthPlatformConfig(
      clientId: androidClientId.isEmpty ? null : androidClientId,
    );
  }
  return const GoogleAuthPlatformConfig();
}

bool isGoogleAuthNetworkError(Object error) => error is SocketException;
