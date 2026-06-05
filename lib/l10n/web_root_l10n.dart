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

  /// String para [key] com fallback local **por idioma** ([_checkoutDefaults]),
  /// usado enquanto o backend ainda não serve a chave. Mantém o padrão "backend
  /// é a fonte" — se a mensagem chegar do servidor ela prevalece — mas garante
  /// que telas em migração (ex.: checkout) renderizem 100% no idioma corrente.
  /// Ver `web_checkout_page.dart`.
  String _sd(String key) {
    final value = WebI18nStore.instance.string(_code, key);
    if (value != null && value.isNotEmpty) return value;
    return _checkoutDefaults[_code]?[key] ??
        _checkoutDefaults['pt']![key] ??
        '';
  }

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

  // ── Checkout ──────────────────────────────────────────────────────────────
  // Conteúdo do checkout redesenhado (Claude Design / Six Design System). Cada
  // getter lê do backend e cai num default local **no idioma corrente**
  // ([_checkoutDefaults]) quando a chave ainda não foi servida — assim a tela
  // renderiza inteira no mesmo idioma antes do backend ser atualizado.

  // Topbar
  String get checkoutCancel => _sd('checkoutCancel');
  String get checkoutHelp => _sd('checkoutHelp');
  String get checkoutHelpLink => _sd('checkoutHelpLink');

  // Seção: planos
  String get checkoutChoosePlan => _sd('checkoutChoosePlan');
  String get checkoutPopularBadge => _sd('checkoutPopularBadge');

  // Seção: pagamento
  String get checkoutPayment => _sd('checkoutPayment');
  String get checkoutCard => _sd('checkoutCard');
  String get checkoutPix => _sd('checkoutPix');
  String get checkoutBoleto => _sd('checkoutBoleto');

  // Formulário de cartão
  String get checkoutCardNumberLabel => _sd('checkoutCardNumberLabel');
  String get checkoutCardExpiryLabel => _sd('checkoutCardExpiryLabel');
  String get checkoutCardCvvLabel => _sd('checkoutCardCvvLabel');
  String get checkoutCardNameLabel => _sd('checkoutCardNameLabel');
  String get checkoutCardNameHint => _sd('checkoutCardNameHint');
  String get checkoutCardCountryLabel => _sd('checkoutCardCountryLabel');
  String get checkoutCardCountryValue => _sd('checkoutCardCountryValue');
  String get checkoutCardFinePrint => _sd('checkoutCardFinePrint');

  // Painel Pix
  String get checkoutPixTitle => _sd('checkoutPixTitle');
  String get checkoutPixBody => _sd('checkoutPixBody');

  // Painel Boleto
  String get checkoutBoletoTitle => _sd('checkoutBoletoTitle');
  String get checkoutBoletoBody => _sd('checkoutBoletoBody');

  // Texto legal + CTA. `{terms}` é substituído pelo link [checkoutTermsLink].
  String get checkoutLegal => _sd('checkoutLegal');
  String get checkoutTermsLink => _sd('checkoutTermsLink');
  String get checkoutSubmit => _sd('checkoutSubmit');

  // Coluna direita: detalhes do plano
  String get checkoutPlanDetails => _sd('checkoutPlanDetails');
  String get checkoutSubscriptionName => _sd('checkoutSubscriptionName');
  String get checkoutRenewPrefix => _sd('checkoutRenewPrefix');
  String get checkoutTotalToday => _sd('checkoutTotalToday');
  String get checkoutSecure => _sd('checkoutSecure');

  // Feedback / simulação
  String get checkoutRequired => _sd('checkoutRequired');
  String get checkoutSimulatedTitle => _sd('checkoutSimulatedTitle');

  /// Defaults locais do checkout por idioma (pt/en/es). Usados só enquanto o
  /// backend não serve a chave; o valor do servidor sempre prevalece. Mantê-los
  /// por idioma evita tela "misturada" quando parte das chaves já vem do backend
  /// num locale e o resto cai no fallback.
  static const Map<String, Map<String, String>> _checkoutDefaults = {
    'pt': {
      'checkoutCancel': 'Cancelar',
      'checkoutHelp': 'Está em dúvida?',
      'checkoutHelpLink': 'Fale com a gente',
      'checkoutChoosePlan': 'Escolha seu plano',
      'checkoutPopularBadge': 'Mais popular',
      'checkoutPayment': 'Pagar com',
      'checkoutCard': 'Cartão de crédito',
      'checkoutPix': 'Pix',
      'checkoutBoleto': 'Boleto',
      'checkoutCardNumberLabel': 'Número do cartão',
      'checkoutCardExpiryLabel': 'Validade',
      'checkoutCardCvvLabel': 'CVV',
      'checkoutCardNameLabel': 'Nome no cartão',
      'checkoutCardNameHint': 'Como aparece no cartão',
      'checkoutCardCountryLabel': 'País',
      'checkoutCardCountryValue': 'Brasil',
      'checkoutCardFinePrint':
          'Ao informar os dados do cartão, você autoriza a Six POS Ltda. a '
              'cobrar pagamentos futuros de acordo com os termos do plano.',
      'checkoutPixTitle': 'Pague em segundos com Pix',
      'checkoutPixBody':
          'Ao confirmar, geramos um QR Code e o código copia e cola. A '
              'liberação do acesso é imediata após a aprovação.',
      'checkoutBoletoTitle': 'Boleto bancário',
      'checkoutBoletoBody':
          'O boleto vence em 3 dias úteis. A confirmação do pagamento pode '
              'levar até 2 dias úteis para liberar o acesso.',
      'checkoutLegal':
          'Cancele quando quiser nas configurações da conta, ao menos um dia '
              'antes de cada renovação. O plano é renovado automaticamente até '
              'o cancelamento. Ao clicar em "Confirmar e assinar" você concorda '
              'com os {terms} e autoriza esta cobrança recorrente.',
      'checkoutTermsLink': 'Termos de Uso',
      'checkoutSubmit': 'Confirmar e assinar',
      'checkoutPlanDetails': 'Detalhes do plano',
      'checkoutSubscriptionName': 'Assinatura Six POS',
      'checkoutRenewPrefix': 'Renova em',
      'checkoutTotalToday': 'Total a pagar hoje (BRL)',
      'checkoutSecure': 'Pagamento seguro e criptografado',
      'checkoutRequired': 'Preencha os dados do cartão.',
      'checkoutSimulatedTitle': 'Checkout simulado',
    },
    'en': {
      'checkoutCancel': 'Cancel',
      'checkoutHelp': 'Have questions?',
      'checkoutHelpLink': 'Talk to us',
      'checkoutChoosePlan': 'Choose your plan',
      'checkoutPopularBadge': 'Most popular',
      'checkoutPayment': 'Pay with',
      'checkoutCard': 'Credit card',
      'checkoutPix': 'Pix',
      'checkoutBoleto': 'Boleto',
      'checkoutCardNumberLabel': 'Card number',
      'checkoutCardExpiryLabel': 'Expiry',
      'checkoutCardCvvLabel': 'CVV',
      'checkoutCardNameLabel': 'Name on card',
      'checkoutCardNameHint': 'As shown on the card',
      'checkoutCardCountryLabel': 'Country',
      'checkoutCardCountryValue': 'Brazil',
      'checkoutCardFinePrint':
          'By entering your card details, you authorize Six POS Ltda. to '
              'charge future payments according to the plan terms.',
      'checkoutPixTitle': 'Pay in seconds with Pix',
      'checkoutPixBody':
          'On confirmation, we generate a QR Code and a copy-and-paste code. '
              'Access is released immediately after approval.',
      'checkoutBoletoTitle': 'Bank slip (Boleto)',
      'checkoutBoletoBody':
          'The boleto is due in 3 business days. Payment confirmation can take '
              'up to 2 business days to release access.',
      'checkoutLegal':
          'Cancel anytime in your account settings, at least one day before '
              'each renewal. The plan renews automatically until canceled. By '
              'clicking "Confirm and subscribe" you agree to the {terms} and '
              'authorize this recurring charge.',
      'checkoutTermsLink': 'Terms of Use',
      'checkoutSubmit': 'Confirm and subscribe',
      'checkoutPlanDetails': 'Plan details',
      'checkoutSubscriptionName': 'Six POS subscription',
      'checkoutRenewPrefix': 'Renews on',
      'checkoutTotalToday': 'Total due today (BRL)',
      'checkoutSecure': 'Secure, encrypted payment',
      'checkoutRequired': 'Please fill in the card details.',
      'checkoutSimulatedTitle': 'Simulated checkout',
    },
    'es': {
      'checkoutCancel': 'Cancelar',
      'checkoutHelp': '¿Tienes dudas?',
      'checkoutHelpLink': 'Habla con nosotros',
      'checkoutChoosePlan': 'Elige tu plan',
      'checkoutPopularBadge': 'Más popular',
      'checkoutPayment': 'Pagar con',
      'checkoutCard': 'Tarjeta de crédito',
      'checkoutPix': 'Pix',
      'checkoutBoleto': 'Boleto',
      'checkoutCardNumberLabel': 'Número de la tarjeta',
      'checkoutCardExpiryLabel': 'Vencimiento',
      'checkoutCardCvvLabel': 'CVV',
      'checkoutCardNameLabel': 'Nombre en la tarjeta',
      'checkoutCardNameHint': 'Como aparece en la tarjeta',
      'checkoutCardCountryLabel': 'País',
      'checkoutCardCountryValue': 'Brasil',
      'checkoutCardFinePrint':
          'Al introducir los datos de la tarjeta, autorizas a Six POS Ltda. a '
              'cobrar pagos futuros de acuerdo con los términos del plan.',
      'checkoutPixTitle': 'Paga en segundos con Pix',
      'checkoutPixBody':
          'Al confirmar, generamos un código QR y el código de copiar y pegar. '
              'El acceso se libera de inmediato tras la aprobación.',
      'checkoutBoletoTitle': 'Boleto bancario',
      'checkoutBoletoBody':
          'El boleto vence en 3 días hábiles. La confirmación del pago puede '
              'tardar hasta 2 días hábiles en liberar el acceso.',
      'checkoutLegal':
          'Cancela cuando quieras en la configuración de la cuenta, al menos un '
              'día antes de cada renovación. El plan se renueva automáticamente '
              'hasta su cancelación. Al hacer clic en "Confirmar y suscribir" '
              'aceptas los {terms} y autorizas este cobro recurrente.',
      'checkoutTermsLink': 'Términos de Uso',
      'checkoutSubmit': 'Confirmar y suscribir',
      'checkoutPlanDetails': 'Detalles del plan',
      'checkoutSubscriptionName': 'Suscripción Six POS',
      'checkoutRenewPrefix': 'Se renueva el',
      'checkoutTotalToday': 'Total a pagar hoy (BRL)',
      'checkoutSecure': 'Pago seguro y cifrado',
      'checkoutRequired': 'Completa los datos de la tarjeta.',
      'checkoutSimulatedTitle': 'Checkout simulado',
    },
  };
}
