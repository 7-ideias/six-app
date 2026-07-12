class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.sixappback.com',
  );

  static const String autoCustomerBaseUrl = String.fromEnvironment(
    'PUBLIC_FRONTEND_URL',
    defaultValue: 'https://six-app-iota.vercel.app/cliente/auto-cadastro',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.47.0',
  );

  static const String appBuildNumber = String.fromEnvironment(
    'APP_BUILD_NUMBER',
    defaultValue: '48',
  );
}
