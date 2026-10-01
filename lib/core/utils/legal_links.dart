import 'package:sixpos/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLinks {
  const LegalLinks._();

  static Uri get termsOfServiceUri {
    final String origin = AppConfig.publicFrontendOrigin.trim();
    final String base = origin.isEmpty ? 'https://sixoapp.com' : origin;
    return Uri.parse('$base/termos-de-servico');
  }

  static Future<bool> openTermsOfService() {
    return launchUrl(termsOfServiceUri, mode: LaunchMode.externalApplication);
  }
}
