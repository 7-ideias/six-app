// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const bool _disableBrowserHandoff = bool.fromEnvironment(
  'SIXAPP_DISABLE_WEB_BROWSER_HANDOFF',
  defaultValue: false,
);

bool assignBrowserLocationImpl(String url) {
  if (_disableBrowserHandoff) {
    return false;
  }
  html.window.location.assign(url);
  return true;
}

bool replaceBrowserLocationImpl(String url) {
  if (_disableBrowserHandoff) {
    return false;
  }
  html.window.location.replace(url);
  return true;
}
