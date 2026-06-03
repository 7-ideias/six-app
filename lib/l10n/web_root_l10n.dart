import 'package:flutter/material.dart';

import 'web_i18n_store.dart';

/// Acessor tipado das traduções de UI (landing page + telas web de auth).
///
/// **O backend é a única fonte de conteúdo.** Esta classe não contém nenhuma
/// string traduzida — ela apenas lê as mensagens já carregadas em memória pelo
/// [WebI18nStore] (populado pelo `LocaleSettingsProvider` a partir do endpoint
/// `GET /public/api/i18n/{locale}`).
///
/// Os widgets que usam estes getters só devem ser construídos depois que as
/// mensagens do locale corrente estiverem disponíveis — isso é garantido pelo
/// `WebI18nGate`, que exibe carregamento/erro até o store estar pronto. Por
/// isso, na ausência de uma chave, os getters retornam vazio (`''` / `[]`) em
/// vez de cair em qualquer texto embutido.
///
/// As chaves usadas aqui são exatamente as servidas pelo backend em
/// `src/main/resources/i18n/{locale}.json`.
class WebRootL10n {
  const WebRootL10n._(this._code);

  final String _code;

  /// Resolve o locale do [context] e retorna o acessor correto.
  static WebRootL10n of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return WebRootL10n._(code);
  }

  /// String simples para [key] (vazio se ainda não carregada).
  String _s(String key) => WebI18nStore.instance.string(_code, key) ?? '';

  /// Lista de strings para [key] (vazia se ausente).
  List<String> _list(String key) =>
      WebI18nStore.instance.stringList(_code, key) ?? const <String>[];

  /// Lista de objetos para [key] (vazia se ausente).
  List<Map<String, dynamic>> _objects(String key) =>
      WebI18nStore.instance.objectList(_code, key) ?? const <Map<String, dynamic>>[];

  // ── Desktop header ────────────────────────────────────────────────────────
  String get navHome => _s('navHome');
  String get navFeatures => _s('navFeatures');
  String get navPricing => _s('navPricing');
  String get navAbout => _s('navAbout');
  String get navLogin => _s('navLogin');
  String get navSignup => _s('navSignup');

  // ── Mobile header ─────────────────────────────────────────────────────────
  String get mobileDownloadCta => _s('mobileDownloadCta');

  // ── Hero section ──────────────────────────────────────────────────────────
  String get heroEyebrowDesktop => _s('heroEyebrowDesktop');
  String get heroEyebrowMobile => _s('heroEyebrowMobile');
  String get heroTitlePrefix => _s('heroTitlePrefix');

  List<String> get heroWords => _list('heroWords');

  String get heroLeadDesktop => _s('heroLeadDesktop');
  String get heroLeadMobile => _s('heroLeadMobile');
  String get heroCtaPrimary => _s('heroCtaPrimary');
  String get heroCtaSecondary => _s('heroCtaSecondary');

  String get trustFree => _s('trustFree');
  String get trustNoCard => _s('trustNoCard');
  String get trustSupport => _s('trustSupport');
  String get trustRating => _s('trustRating');
  String get trustReviews => _s('trustReviews');

  String get phoneScreenTitle => _s('phoneScreenTitle');
  String get phoneScreenBody => _s('phoneScreenBody');

  String get chipIaLabel => _s('chipIaLabel');
  String get chipIaValue => _s('chipIaValue');
  String get chipRatingStore => _s('chipRatingStore');
  String get chipRatingValue => _s('chipRatingValue');

  // ── Features section ──────────────────────────────────────────────────────
  String get featuresEyebrow => _s('featuresEyebrow');
  String get featuresSectionTitle => _s('featuresSectionTitle');
  String get featuresSectionLeadDesktop => _s('featuresSectionLeadDesktop');
  String get featuresSectionLeadMobile => _s('featuresSectionLeadMobile');

  /// Feature cards em ordem: (title, body).
  List<(String, String)> get featureCards {
    final result = <(String, String)>[];
    for (final item in _objects('featureCards')) {
      final title = item['title'];
      final body = item['body'];
      if (title is String && body is String) {
        result.add((title, body));
      }
    }
    return result;
  }

  // ── Pricing section ───────────────────────────────────────────────────────
  String get pricingEyebrow => _s('pricingEyebrow');
  String get pricingSectionTitle => _s('pricingSectionTitle');
  String get pricingSectionLeadDesktop => _s('pricingSectionLeadDesktop');
  String get pricingSectionLeadMobile => _s('pricingSectionLeadMobile');

  /// Planos de preço — lista de records com os campos de cada plano.
  List<
    ({
      String name,
      String price,
      String cadence,
      String pitch,
      List<String> features,
      String cta,
      bool featured,
    })
  >
  get plans {
    final result =
        <({
          String name,
          String price,
          String cadence,
          String pitch,
          List<String> features,
          String cta,
          bool featured,
        })>[];
    for (final item in _objects('plans')) {
      final name = item['name'];
      final price = item['price'];
      final cadence = item['cadence'];
      final pitch = item['pitch'];
      final features = item['features'];
      final cta = item['cta'];
      final featured = item['featured'];
      if (name is String &&
          price is String &&
          cadence is String &&
          pitch is String &&
          features is List &&
          cta is String &&
          featured is bool) {
        result.add((
          name: name,
          price: price,
          cadence: cadence,
          pitch: pitch,
          features: features.map((e) => e.toString()).toList(),
          cta: cta,
          featured: featured,
        ));
      }
    }
    return result;
  }

  // ── CTA section ───────────────────────────────────────────────────────────
  String get ctaDesktopTitle => _s('ctaDesktopTitle');
  String get ctaDesktopSub => _s('ctaDesktopSub');
  String get ctaDesktopButton => _s('ctaDesktopButton');
  String get ctaMobileTitle => _s('ctaMobileTitle');
  String get ctaMobileSub => _s('ctaMobileSub');

  // ── Footer ────────────────────────────────────────────────────────────────
  List<(String colTitle, List<String> items)> get footerColumns {
    final result = <(String, List<String>)>[];
    for (final item in _objects('footerColumns')) {
      final title = item['title'];
      final items = item['items'];
      if (title is String && items is List) {
        result.add((title, items.map((e) => e.toString()).toList()));
      }
    }
    return result;
  }

  String get footerTagline => _s('footerTagline');
  String get footerRights => _s('footerRights');
  String get footerMadeBr => _s('footerMadeBr');

  // ── Auth screens (login / register / forgot-password) ─────────────────────
  String get authBack => _s('authBack');

  // Login
  String get authLoginTitle => _s('authLoginTitle');
  String get authLoginSubtitle => _s('authLoginSubtitle');
  String get authEmailHint => _s('authEmailHint');
  String get authEmailLabel => _s('authEmailLabel');
  String get authPasswordHint => _s('authPasswordHint');
  String get authPasswordLabel => _s('authPasswordLabel');
  String get authForgotPassword => _s('authForgotPassword');
  String get authSignInButton => _s('authSignInButton');
  String get authOrContinueWith => _s('authOrContinueWith');
  String get authNoAccount => _s('authNoAccount');
  String get authCreateAccountLink => _s('authCreateAccountLink');
  String get authErrFillEmailPassword => _s('authErrFillEmailPassword');
  String get authErrGoogleLogin => _s('authErrGoogleLogin');

  // Register
  String get authRegisterTitle => _s('authRegisterTitle');
  String get authRegisterSubtitle => _s('authRegisterSubtitle');
  String get authPasswordMinHint => _s('authPasswordMinHint');
  String get authConfirmPasswordHint => _s('authConfirmPasswordHint');
  String get authConfirmPasswordLabel => _s('authConfirmPasswordLabel');
  String get authPasswordMismatch => _s('authPasswordMismatch');
  String get authAgreeWith => _s('authAgreeWith');
  String get authTermsAndConditions => _s('authTermsAndConditions');
  String get authCreateAccountButton => _s('authCreateAccountButton');
  String get authOrSignUpWith => _s('authOrSignUpWith');
  String get authErrAcceptTerms => _s('authErrAcceptTerms');
  String get authErrFillAllFields => _s('authErrFillAllFields');
  String get authErrPasswordTooShort => _s('authErrPasswordTooShort');
  String get authErrPasswordsNotEqual => _s('authErrPasswordsNotEqual');
  String get authErrGoogleRegister => _s('authErrGoogleRegister');
  String get authErrSendCode => _s('authErrSendCode');

  // Forgot password
  String get authForgotTitle => _s('authForgotTitle');
  String get authForgotSubtitle => _s('authForgotSubtitle');
  String get authSendVerificationCode => _s('authSendVerificationCode');
  String get authErrEnterEmail => _s('authErrEnterEmail');
  String get authAlreadyHaveAccount => _s('authAlreadyHaveAccount');
  String get authSignInLink => _s('authSignInLink');
}
