import 'package:flutter/widgets.dart';

import 'web_google_sign_in_button_stub.dart'
    if (dart.library.html) 'web_google_sign_in_button_web.dart';

/// Renders the official Google Identity Services button on Flutter web.
/// On other platforms this returns an empty widget; callers should present
/// their own button and call `AuthService.loginWithGoogle()` instead.
class WebGoogleSignInButton extends StatelessWidget {
  const WebGoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: renderWebGoogleSignInButton(),
    );
  }
}
