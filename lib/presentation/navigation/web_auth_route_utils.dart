bool isAuthenticatedWebAppRoute(Uri uri) {
  return uri.path == '/app' || uri.path.startsWith('/app/');
}

String normalizeAuthenticatedWebLocation(String? rawLocation) {
  final String raw = (rawLocation ?? '').trim();
  if (raw.isEmpty) {
    return '/app';
  }

  final Uri? uri = Uri.tryParse(raw);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return '/app';
  }

  if (!isAuthenticatedWebAppRoute(uri)) {
    return '/app';
  }

  final String query = uri.hasQuery ? '?${uri.query}' : '';
  return '${uri.path}$query';
}

String? sanitizeAuthenticatedWebRedirect(String? redirect) {
  final String raw = (redirect ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }

  final String decoded = Uri.decodeComponent(raw).trim();
  final Uri? uri = Uri.tryParse(decoded);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return null;
  }

  if (!isAuthenticatedWebAppRoute(uri)) {
    return null;
  }

  final String query = uri.hasQuery ? '?${uri.query}' : '';
  return '${uri.path}$query';
}

String buildLoginRouteForAuthenticatedWebRedirect(String requestedLocation) {
  final String safeLocation = normalizeAuthenticatedWebLocation(
    requestedLocation,
  );
  return Uri(
    path: '/login',
    queryParameters: <String, String>{'redirect': safeLocation},
  ).toString();
}
