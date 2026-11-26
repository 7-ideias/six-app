import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/browser_location.dart';
import '../components/web/six_web_logout_dialog.dart';
import '../services/web_authenticated_bootstrap_service.dart';

/// Returns true when the browser is leaving the current Flutter document.
Future<bool> confirmWebLogout(
  BuildContext context, {
  NavigatorState? loginNavigator,
}) async {
  final navigator = loginNavigator ?? Navigator.of(context);
  final confirmed = await showSixWebLogoutDialog(
    context: context,
    onConfirm: () async {
      await AuthService().logout();
      WebAuthenticatedBootstrapService().clearInMemorySession(
        context.mounted ? context : null,
      );
    },
  );
  if (!confirmed) return false;
  if (replaceBrowserLocation('/login')) return true;
  if (navigator.mounted) {
    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }
  return false;
}
