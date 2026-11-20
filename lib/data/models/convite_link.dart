class ConviteLink {
  const ConviteLink(this.codigo, this.login, this.email);
  final String codigo;
  final bool login;
  final String email;

  static ConviteLink? parse(String? location) {
    final uri = Uri.tryParse(location ?? '');
    if (uri == null) return null;
    if (uri.hasScheme &&
        (uri.scheme != 'com.sixoapp.app' || uri.host != 'colaborador')) {
      return null;
    }
    final parts = [...uri.pathSegments];
    if (!uri.hasScheme && parts.isNotEmpty && parts.first == 'colaborador') {
      parts.removeAt(0);
    }
    if (parts.length != 2 ||
        parts.first != 'convites' ||
        !RegExp(r'^[a-zA-Z0-9_-]{16,128}$').hasMatch(parts.last)) {
      return null;
    }
    return ConviteLink(
      parts.last,
      uri.queryParameters['login'] == '1',
      uri.queryParameters['email'] ?? '',
    );
  }
}
