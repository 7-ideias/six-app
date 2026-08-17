// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

final RegExp _mobilePhoneUserAgentPattern = RegExp(
  r'(iphone|ipod|windows phone|iemobile|opera mini|blackberry|bb10|webos|android.+mobile|mobile safari)',
  caseSensitive: false,
);

bool isPhoneBrowserImpl() {
  final String userAgent = html.window.navigator.userAgent;
  return _mobilePhoneUserAgentPattern.hasMatch(userAgent);
}
