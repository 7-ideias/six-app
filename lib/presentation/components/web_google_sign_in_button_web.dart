import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

Widget renderWebGoogleSignInButton() {
  return web_only.renderButton(
    configuration: web_only.GSIButtonConfiguration(
      type: web_only.GSIButtonType.standard,
      theme: web_only.GSIButtonTheme.outline,
      size: web_only.GSIButtonSize.large,
      text: web_only.GSIButtonText.continueWith,
      shape: web_only.GSIButtonShape.rectangular,
      logoAlignment: web_only.GSIButtonLogoAlignment.left,
      minimumWidth: 360,
    ),
  );
}
