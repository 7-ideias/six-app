import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_text_styles_android.dart';
import 'app_text_styles_ios.dart';
import 'app_text_styles_web.dart';

class AppTextStyles {
  static TextStyle get heading {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppTextStylesAndroid.heading;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppTextStylesIOS.heading;
    } else {
      return AppTextStylesWeb.heading;
    }
  }

  static TextStyle get body {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppTextStylesAndroid.body;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppTextStylesIOS.body;
    } else {
      return AppTextStylesWeb.body;
    }
  }
}
