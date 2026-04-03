class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // 'API_BASE_URL',
    // defaultValue: 'http://10.0.2.2:8082',
    // defaultValue: 'http://localhost:8082',
    // defaultValue: 'https://931c-2804-14c-ccec-8001-50b2-faa3-abe4-8605.ngrok-free.app',
  );
}
