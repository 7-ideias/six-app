import 'browser_device_stub.dart'
    if (dart.library.html) 'browser_device_web.dart';

bool isPhoneBrowser() => isPhoneBrowserImpl();
