import 'browser_location_stub.dart'
    if (dart.library.html) 'browser_location_web.dart';

bool assignBrowserLocation(String url) => assignBrowserLocationImpl(url);
bool replaceBrowserLocation(String url) => replaceBrowserLocationImpl(url);
