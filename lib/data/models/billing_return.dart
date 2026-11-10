/// A return link is navigation only, never proof that a payment was made.
class BillingReturn {
  const BillingReturn(this.company, this.outcome);
  final String company, outcome;

  static bool isReturnLocation(Uri uri) {
    final trustedHttps =
        uri.scheme == 'https' &&
        uri.host == 'www.sixoapp.com' &&
        uri.path == '/mobile/billing-return' &&
        !uri.hasPort &&
        uri.userInfo.isEmpty;
    final native =
        uri.scheme == 'com.sixoapp.billing' &&
        uri.host == 'return' &&
        uri.path.isEmpty &&
        !uri.hasPort &&
        uri.userInfo.isEmpty;
    // Flutter's built-in deep-link handler can deliver only the path.
    final platformPath =
        !uri.hasScheme &&
        !uri.hasAuthority &&
        uri.path == '/mobile/billing-return';
    return !uri.hasFragment && (trustedHttps || native || platformPath);
  }

  static BillingReturn? parse(Uri uri) {
    if (!isReturnLocation(uri)) return null;
    final company = uri.queryParameters['company'] ?? '';
    final outcome = uri.queryParameters['retorno'] ?? '';
    if (company.isEmpty ||
        company.length > 128 ||
        !{'stripe', 'cancelado', 'portal'}.contains(outcome))
      return null;
    return BillingReturn(company, outcome);
  }
}
