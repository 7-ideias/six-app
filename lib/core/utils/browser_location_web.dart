// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool assignBrowserLocationImpl(String url) {
  html.window.location.assign(url);
  return true;
}

bool replaceBrowserLocationImpl(String url) {
  html.window.location.replace(url);
  return true;
}
