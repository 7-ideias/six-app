import 'external_link_launcher_stub.dart'
    if (dart.library.html) 'external_link_launcher_web.dart';

Future<bool> launchExternalUri(Uri uri) => launchExternalUriImpl(uri);
