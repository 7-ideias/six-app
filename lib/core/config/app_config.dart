class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'https://931c-2804-14c-ccec-8001-50b2-faa3-abe4-8605.ngrok-free.app',
    // 'API_BASE_URL',
    defaultValue: 'https://931c-2804-14c-ccec-8001-50b2-faa3-abe4-8605.ngrok-free.app',
    // defaultValue: 'http://localhost:8082',
  );
}
