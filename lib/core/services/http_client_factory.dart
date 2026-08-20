import 'package:http/http.dart' as http;
import 'http_client_factory_stub.dart'
if (dart.library.html) 'http_client_factory_web.dart';
import 'session_refreshing_http_client.dart';

UnauthorizedTokenRefreshHandler? _unauthorizedTokenRefreshHandler;

void registerUnauthorizedTokenRefreshHandler(
  UnauthorizedTokenRefreshHandler handler,
) {
  _unauthorizedTokenRefreshHandler = handler;
}

http.Client createHttpClient() {
  return SessionRefreshingHttpClient(
    inner: createPlatformHttpClient(),
    refreshHandler: () => _unauthorizedTokenRefreshHandler,
  );
}
