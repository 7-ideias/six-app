import 'package:sixpos/data/services/catalog_health/catalog_health_api_client.dart';

class CatalogHealthModule {
  CatalogHealthModule._();

  static final CatalogHealthApiClient catalogHealthApiClient =
      HttpCatalogHealthApiClient();
}
