bool isAuthenticatedWebAppRoute(Uri uri) {
  return uri.path == '/app' || uri.path.startsWith('/app/');
}

bool _hasUnsafeAuthenticatedWebPath(Uri uri) {
  return uri.pathSegments.any(
    (String segment) => segment == '.' || segment == '..',
  );
}

String normalizeAuthenticatedWebLocation(String? rawLocation) {
  final String raw = (rawLocation ?? '').trim();
  if (raw.isEmpty) {
    return '/app';
  }

  if (raw.contains('\\')) {
    return '/app';
  }

  final Uri? uri = Uri.tryParse(raw);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return '/app';
  }

  if (!isAuthenticatedWebAppRoute(uri) || _hasUnsafeAuthenticatedWebPath(uri)) {
    return '/app';
  }

  final String query = uri.hasQuery ? '?${uri.query}' : '';
  final String fragment = uri.hasFragment ? '#${uri.fragment}' : '';
  return '${uri.path}$query$fragment';
}

String? sanitizeAuthenticatedWebRedirect(String? redirect) {
  final String raw = (redirect ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }

  final String decoded;
  try {
    decoded = Uri.decodeComponent(raw).trim();
  } on FormatException {
    return null;
  }
  if (decoded.contains('\\')) {
    return null;
  }

  final Uri? uri = Uri.tryParse(decoded);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return null;
  }

  if (!isAuthenticatedWebAppRoute(uri) || _hasUnsafeAuthenticatedWebPath(uri)) {
    return null;
  }

  final String query = uri.hasQuery ? '?${uri.query}' : '';
  final String fragment = uri.hasFragment ? '#${uri.fragment}' : '';
  return '${uri.path}$query$fragment';
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
