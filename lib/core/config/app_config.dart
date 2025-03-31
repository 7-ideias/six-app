class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8082',
    // defaultValue: 'http://localhost:8082',
  );
}
