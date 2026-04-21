class GoogleAuthPlatformConfig {
  const GoogleAuthPlatformConfig({this.clientId});

  final String? clientId;
}

GoogleAuthPlatformConfig resolveGoogleAuthPlatformConfig() =>
    const GoogleAuthPlatformConfig();

bool isGoogleAuthNetworkError(Object error) => false;
