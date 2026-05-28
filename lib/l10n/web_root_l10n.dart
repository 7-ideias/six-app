import 'package:flutter/material.dart';

/// Strings localizadas para a landing page (web_root).
///
/// Suporta PT-BR, EN-US e ES-ES. Lê o locale do widget tree via
/// [Localizations.localeOf]. Chamado em [StatelessWidget.build] ou
/// [State.build] após o [MaterialApp] ter aplicado o locale.
class WebRootL10n {
  const WebRootL10n._(this._code);

  final String _code;

  /// Resolve o locale do [context] e retorna o conjunto de strings correto.
  static WebRootL10n of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return WebRootL10n._(code);
  }

  String _t({required String pt, required String en, required String es}) {
    switch (_code) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  // ── Desktop header ────────────────────────────────────────────────────────
  String get navHome => _t(pt: 'Início', en: 'Home', es: 'Inicio');

  String get navFeatures => _t(pt: 'Recursos', en: 'Features', es: 'Recursos');

  String get navPricing => _t(pt: 'Planos', en: 'Pricing', es: 'Planes');

  String get navAbout => _t(pt: 'Sobre', en: 'About', es: 'Sobre');

  String get navLogin => _t(pt: 'Entrar', en: 'Log in', es: 'Entrar');

  String get navSignup =>
      _t(pt: 'Começar agora', en: 'Get started', es: 'Comenzar');

  // ── Mobile header ─────────────────────────────────────────────────────────
  String get mobileDownloadCta =>
      _t(pt: 'Baixar app', en: 'Download', es: 'Descargar');

  // ── Hero section ──────────────────────────────────────────────────────────
  String get heroEyebrowDesktop => _t(
    pt: 'Gestão inteligente para pequenos e médios negócios',
    en: 'Smart management for small and medium businesses',
    es: 'Gestión inteligente para pequeñas y medianas empresas',
  );

  String get heroEyebrowMobile => _t(
    pt: 'Gestão inteligente',
    en: 'Smart management',
    es: 'Gestión inteligente',
  );

  String get heroTitlePrefix => _t(
    pt: 'Uma única plataforma para',
    en: 'One platform for',
    es: 'Una sola plataforma para',
  );

  List<String> get heroWords =>
      _code == 'en'
          ? [
            'point of sale',
            'inventory management',
            'financial control',
            'work orders',
          ]
          : _code == 'es'
          ? [
            'punto de venta',
            'gestión de inventario',
            'control financiero',
            'órdenes de servicio',
          ]
          : [
            'frente de caixa',
            'gestão estoque',
            'controle financeiro',
            'ordens de serviço',
          ];

  String get heroLeadDesktop => _t(
    pt:
        'Implante seu sistema de PDV, Financeiro e CRM sem esperar meses. '
        'Use IA para cadastro automático de produtos, previsão de caixa '
        'e recomendações comerciais.',
    en:
        'Deploy your POS, Finance and CRM without waiting months. '
        'Use AI for automatic product registration, cash flow forecasting '
        'and commercial recommendations.',
    es:
        'Implante su sistema de PDV, Finanzas y CRM sin esperar meses. '
        'Use IA para registro automático de productos, previsión de caja '
        'y recomendaciones comerciales.',
  );

  String get heroLeadMobile => _t(
    pt:
        'PDV, Financeiro e CRM em um só app. Use IA para cadastrar '
        'produtos, prever caixa e receber recomendações comerciais.',
    en:
        'POS, Finance and CRM in one app. Use AI to register products, '
        'predict cash flow and get commercial recommendations.',
    es:
        'PDV, Finanzas y CRM en una app. Use IA para registrar productos, '
        'prever caja y recibir recomendaciones.',
  );

  String get heroCtaPrimary =>
      _t(pt: 'Começar agora', en: 'Get started', es: 'Comenzar ahora');

  String get heroCtaSecondary =>
      _t(pt: 'Ver demonstração', en: 'See demo', es: 'Ver demo');

  String get trustFree =>
      _t(pt: '7 dias grátis', en: '7 days free', es: '7 días gratis');

  String get trustNoCard =>
      _t(pt: 'Sem cartão', en: 'No credit card', es: 'Sin tarjeta');

  String get trustSupport =>
      _t(pt: 'Suporte 24/7', en: 'Support 24/7', es: 'Soporte 24/7');

  String get trustRating => _t(pt: '4,9', en: '4.9', es: '4,9');

  String get trustReviews => _t(
    pt: '· 2.348 avaliações',
    en: '· 2,348 reviews',
    es: '· 2.348 reseñas',
  );

  String get phoneScreenTitle => _t(
    pt: 'Gerencie suas vendas em tempo real',
    en: 'Manage your sales in real time',
    es: 'Gestiona tus ventas en tiempo real',
  );

  String get phoneScreenBody => _t(
    pt: 'Use IA para cadastrar produtos, recomendar preços e prever caixa.',
    en: 'Use AI to register products, recommend prices and predict cash flow.',
    es: 'Use IA para registrar productos, recomendar precios y prever caja.',
  );

  String get chipIaLabel =>
      _t(pt: 'IA CADASTROU', en: 'AI ADDED', es: 'IA REGISTRÓ');

  String get chipIaValue =>
      _t(pt: '12 produtos', en: '12 products', es: '12 productos');

  String get chipRatingStore =>
      _t(pt: 'APP STORE', en: 'APP STORE', es: 'APP STORE');

  String get chipRatingValue => _t(
    pt: '4,9 ★ · top finanças',
    en: '4.9 ★ · top finance',
    es: '4,9 ★ · top finanzas',
  );

  // ── Features section ──────────────────────────────────────────────────────
  String get featuresEyebrow =>
      _t(pt: 'Recursos', en: 'Features', es: 'Recursos');

  String get featuresSectionTitle => _t(
    pt: 'Módulos integrados para toda a sua operação.',
    en: 'Integrated modules for your entire operation.',
    es: 'Módulos integrados para toda su operación.',
  );

  String get featuresSectionLeadDesktop => _t(
    pt:
        'Acompanhe todas as movimentações de caixa, previsualize fluxo de caixa por período,'
        'receba alertas de vencimento e tenha relatórios executivos diários.',
    en:
        'Pet shop, stationery, tech repair, clothing store — Six handles '
        'the same day-to-day you already live, just organized.',
    es:
        'Pet shop, papelería, asistencia técnica, tienda de ropa — Six atiende '
        'el mismo día a día que ya vives, pero organizado.',
  );

  String get featuresSectionLeadMobile => _t(
    pt:
        'Pet shop, papelaria, assistência técnica, loja de roupas — '
        'o Six atende o seu dia-a-dia, organizado.',
    en:
        'Pet shop, stationery, tech repair, clothing store — '
        'Six organized.',
    es: 'Pet shop, papelería, asistencia técnica — Six organizado.',
  );

  /// Feature cards in order: (title, body). Mirrors _features in features_section.
  List<(String, String)> get featureCards =>
      _code == 'en'
          ? [
            (
              'Real-time checkout',
              'Sell in seconds at the counter, reader or phone. Stock syncs instantly.',
            ),
            (
              'Full service orders',
              'Control the tech queue, SLA, parts and customer communication without a spreadsheet.',
            ),
            (
              'Predictive finance',
              'Cash flow forecasting, risk alerts and AI-powered executive dashboard.',
            ),
            (
              'Strategic cockpit',
              'Combines cash, margin, sales and service in a single panel.',
            ),
            (
              'AI product registration',
              'Take a photo — AI registers the product with a suggested price and category.',
            ),
            ('Human support', 'Real-time support — no bot, no canned FAQ.'),
          ]
          : _code == 'es'
          ? [
            (
              'Caja en tiempo real',
              'Vende en segundos en el mostrador, lector o celular. Sincroniza el stock al instante.',
            ),
            (
              'Órdenes de servicio completas',
              'Controla la cola técnica, SLA, piezas y comunicación sin planilla.',
            ),
            (
              'Finanzas predictivas',
              'Previsión de flujo de caja, alertas de riesgo y panel ejecutivo con IA.',
            ),
            (
              'Cockpit estratégico',
              'Combina caja, margen, ventas y atención en un solo panel.',
            ),
            (
              'Registro con IA',
              'Toma una foto — la IA lo registra con precio sugerido y categoría.',
            ),
            (
              'Soporte humano en español',
              'Atención inmediata — sin bot, sin FAQ enlatado.',
            ),
          ]
          : [
            (
              'Frente de caixa em tempo real',
              'Venda em segundos no balcão, leitor ou celular. Sincroniza estoque na hora.',
            ),
            (
              'Ordens de serviço completas',
              'Controle fila técnica, SLA, peças e comunicação com o cliente sem planilha.',
            ),
            (
              'Financeiro preditivo',
              'Previsão de fluxo de caixa, alertas de risco e painel executivo com IA.',
            ),
            (
              'Cockpit estratégico',
              'Cruza caixa, margem, vendas e atendimento em um único painel.',
            ),
            (
              'Cadastro com IA',
              'Tire foto do produto — a IA cadastra com preço sugerido e categoria.',
            ),
            (
              'Suporte humano em português',
              'Atendimento na hora — não bot, não FAQ enlatado.',
            ),
          ];

  // ── Pricing section ───────────────────────────────────────────────────────
  String get pricingEyebrow => _t(pt: 'Preços', en: 'Pricing', es: 'Precios');

  String get pricingSectionTitle => _t(
    pt: 'Simples, transparente, sem surpresa.',
    en: 'Simple, transparent, no surprises.',
    es: 'Simple, transparente, sin sorpresas.',
  );

  String get pricingSectionLeadDesktop => _t(
    pt:
        'Não tem taxa de instalação, não tem contrato de fidelidade. '
        'Cancele quando quiser — sua loja é sua.',
    en:
        'No setup fee, no lock-in contract. '
        'Cancel anytime — your store is yours.',
    es:
        'Sin tarifa de instalación, sin contrato de fidelidad. '
        'Cancela cuando quieras — tu tienda es tuya.',
  );

  String get pricingSectionLeadMobile => _t(
    pt: 'Sem taxa de instalação, sem contrato. Cancele quando quiser.',
    en: 'No setup fee, no contract. Cancel anytime.',
    es: 'Sin tarifa de instalación, sin contrato. Cancela cuando quieras.',
  );

  /// Planos de preço — retorna lista de records com os campos de cada plano.
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
  get plans =>
      _code == 'en'
          ? [
            (
              name: 'Starter',
              price: '\$0',
              cadence: 'forever',
              pitch: 'Start selling today, no sign-up required.',
              features: [
                'Checkout',
                'Up to 50 products',
                'Basic reports',
                'Email support',
              ],
              cta: 'Start free',
              featured: false,
            ),
            (
              name: 'Professional',
              price: '\$99',
              cadence: 'per year',
              pitch: 'For most stores that live by the counter and messaging.',
              features: [
                'Everything in Starter',
                'Inventory + AI registration',
                'Service orders',
                'Predictive finance',
                '24/7 support',
              ],
              cta: 'Subscribe',
              featured: true,
            ),
            (
              name: 'Cockpit',
              price: '\$199',
              cadence: 'per year',
              pitch: 'For businesses that need an executive dashboard.',
              features: [
                'Everything in Professional',
                'Strategic cockpit',
                'Multiple branches',
                'Team access',
                'Dedicated support',
              ],
              cta: 'Talk to sales',
              featured: false,
            ),
          ]
          : _code == 'es'
          ? [
            (
              name: 'Starter',
              price: '\$0',
              cadence: 'para siempre',
              pitch: 'Empieza a vender hoy, sin necesidad de registro.',
              features: [
                'Punto de venta',
                'Hasta 50 productos',
                'Reportes básicos',
                'Soporte por correo',
              ],
              cta: 'Comenzar gratis',
              featured: false,
            ),
            (
              name: 'Professional',
              price: '\$99',
              cadence: 'por año',
              pitch: 'Para tiendas que viven del mostrador y la mensajería.',
              features: [
                'Todo lo de Starter',
                'Inventario + registro con IA',
                'Órdenes de servicio',
                'Finanzas predictivas',
                'Soporte 24/7',
              ],
              cta: 'Suscribirse',
              featured: true,
            ),
            (
              name: 'Cockpit',
              price: '\$199',
              cadence: 'por año',
              pitch: 'Para empresas que necesitan un panel ejecutivo.',
              features: [
                'Todo lo de Professional',
                'Cockpit estratégico',
                'Múltiples sucursales',
                'Acceso para equipos',
                'Soporte dedicado',
              ],
              cta: 'Hablar con ventas',
              featured: false,
            ),
          ]
          : [
            (
              name: 'Starter',
              price: 'R\$0',
              cadence: 'para sempre',
              pitch: 'Comece a vender hoje, sem necessidade de cadastro.',
              features: [
                'Frente de caixa',
                'Até 50 produtos',
                'Relatórios básicos',
                'Suporte por e-mail',
              ],
              cta: 'Começar grátis',
              featured: false,
            ),
            (
              name: 'Professional',
              price: 'R\$499',
              cadence: 'por ano',
              pitch: 'Para lojas que vivem do balcão e do atendimento.',
              features: [
                'Tudo do Starter',
                'Estoque + cadastro com IA',
                'Ordens de serviço',
                'Financeiro preditivo',
                'Suporte 24/7',
              ],
              cta: 'Assinar',
              featured: true,
            ),
            (
              name: 'Cockpit',
              price: 'R\$799',
              cadence: 'por ano',
              pitch: 'Para empresas que precisam de um painel executivo.',
              features: [
                'Tudo do Professional',
                'Cockpit estratégico',
                'Múltiplas filiais',
                'Acesso para equipes',
                'Suporte dedicado',
              ],
              cta: 'Falar com vendas',
              featured: false,
            ),
          ];

  // ── CTA section ───────────────────────────────────────────────────────────
  String get ctaDesktopTitle => _t(
    pt: 'Está em dúvida? Faça um teste.',
    en: 'Not sure? Give it a try.',
    es: '¿Tienes dudas? Pruébalo.',
  );

  String get ctaDesktopSub => _t(
    pt: '14 dias grátis, sem cartão. Um especialista te ajuda a configurar.',
    en: '14 days free, no credit card. A specialist helps you get set up.',
    es: '14 días gratis, sin tarjeta. Un especialista te ayuda a configurar.',
  );

  String get ctaDesktopButton => _t(
    pt: 'Fale com um especialista',
    en: 'Talk to an expert',
    es: 'Habla con un experto',
  );

  String get ctaMobileTitle => _t(
    pt: 'Baixe o Six e comece hoje.',
    en: 'Download Six and start today.',
    es: 'Descarga Six y empieza hoy.',
  );

  String get ctaMobileSub => _t(
    pt: '14 dias grátis, sem cartão. Disponível para iPhone e Android.',
    en: '14 days free, no credit card. Available for iPhone and Android.',
    es: '14 días gratis, sin tarjeta. Disponible para iPhone y Android.',
  );

  // ── Footer ────────────────────────────────────────────────────────────────
  List<(String colTitle, List<String> items)> get footerColumns =>
      _code == 'en'
          ? [
            ('Product', ['Features', 'Pricing', 'Cockpit', 'AI registration']),
            (
              'Segments',
              ['Pet shop', 'Tech repair', 'Clothing store', 'Stationery'],
            ),
            ('Company', ['About', 'Careers', 'Press', 'Contact']),
            ('Support', ['Help center', 'Status', 'Terms', 'Privacy']),
          ]
          : _code == 'es'
          ? [
            ('Producto', ['Recursos', 'Planes', 'Cockpit', 'IA registro']),
            (
              'Segmentos',
              ['Pet shop', 'Asistencia técnica', 'Tienda de ropa', 'Papelería'],
            ),
            ('Empresa', ['Sobre', 'Empleos', 'Prensa', 'Contacto']),
            (
              'Soporte',
              ['Centro de ayuda', 'Estado', 'Términos', 'Privacidad'],
            ),
          ]
          : [
            ('Produto', ['Recursos', 'Planos', 'Cockpit', 'IA cadastro']),
            (
              'Segmentos',
              [
                'Pet shop',
                'Assistência técnica',
                'Loja de roupas',
                'Papelaria',
              ],
            ),
            ('Empresa', ['Sobre', 'Carreiras', 'Imprensa', 'Contato']),
            (
              'Suporte',
              ['Central de ajuda', 'Status', 'Termos', 'Privacidade'],
            ),
          ];

  String get footerTagline => _t(
    pt: 'PDV inteligente para o pequeno negócio brasileiro.',
    en: 'Smart POS for small businesses.',
    es: 'PDV inteligente para el pequeño negocio.',
  );

  String get footerRights => _t(
    pt: '© 2026 Sete Ideias Software House. Todos os direitos reservados.',
    en: '© 2026 Sete Ideias Software House. All rights reserved.',
    es: '© 2026 Sete Ideias Software House. Todos los derechos reservados.',
  );

  String get footerMadeBr => _t(
    pt: 'Feito no Brasil 🇧🇷',
    en: 'Made in Brazil 🇧🇷',
    es: 'Hecho en Brasil 🇧🇷',
  );

  // ── Auth screens (login / register / forgot-password) ─────────────────────

  String get authBack => _t(pt: 'Voltar', en: 'Back', es: 'Volver');

  // Login
  String get authLoginTitle =>
      _t(pt: 'Entrar na sua conta', en: 'Sign in to your account', es: 'Iniciar sesión');

  String get authLoginSubtitle => _t(
    pt: 'Informe seu e-mail e senha para acessar o painel.',
    en: 'Enter your email and password to access the panel.',
    es: 'Ingresa tu correo y contraseña para acceder al panel.',
  );

  String get authEmailHint => _t(pt: 'seu@email.com', en: 'your@email.com', es: 'tu@email.com');

  String get authEmailLabel => _t(pt: 'E-mail', en: 'Email', es: 'Correo');

  String get authPasswordHint =>
      _t(pt: 'Sua senha', en: 'Your password', es: 'Tu contraseña');

  String get authPasswordLabel =>
      _t(pt: 'Senha', en: 'Password', es: 'Contraseña');

  String get authForgotPassword =>
      _t(pt: 'Esqueceu a senha?', en: 'Forgot password?', es: '¿Olvidaste tu contraseña?');

  String get authSignInButton => _t(pt: 'Entrar', en: 'Sign in', es: 'Entrar');

  String get authOrContinueWith =>
      _t(pt: 'ou continue com', en: 'or continue with', es: 'o continúa con');

  String get authNoAccount =>
      _t(pt: 'Ainda não tem uma conta? ', en: "Don't have an account? ", es: '¿No tienes una cuenta? ');

  String get authCreateAccountLink =>
      _t(pt: 'Criar conta', en: 'Sign up', es: 'Crear cuenta');

  // Snackbars — login
  String get authErrFillEmailPassword =>
      _t(pt: 'Preencha o e-mail e a senha', en: 'Fill in your email and password', es: 'Completa el correo y la contraseña');

  String get authErrGoogleLogin =>
      _t(pt: 'Não foi possível concluir o login com Google.', en: 'Could not complete Google sign-in.', es: 'No se pudo completar el inicio de sesión con Google.');

  // Register
  String get authRegisterTitle =>
      _t(pt: 'Crie sua conta Six', en: 'Create your Six account', es: 'Crea tu cuenta Six');

  String get authRegisterSubtitle => _t(
    pt: 'Você terá sete dias de avaliação gratuita.',
    en: 'You will have seven days of free trial.',
    es: 'Tendrás siete días de prueba gratuita.',
  );

  String get authPasswordMinHint =>
      _t(pt: 'Mínimo 8 caracteres', en: 'Minimum 8 characters', es: 'Mínimo 8 caracteres');

  String get authConfirmPasswordHint =>
      _t(pt: 'Repita sua senha', en: 'Repeat your password', es: 'Repite tu contraseña');

  String get authConfirmPasswordLabel =>
      _t(pt: 'Confirme a senha', en: 'Confirm password', es: 'Confirma la contraseña');

  String get authPasswordMismatch =>
      _t(pt: 'As senhas não coincidem.', en: 'Passwords do not match.', es: 'Las contraseñas no coinciden.');

  String get authAgreeWith => _t(pt: 'Concordo com os ', en: 'I agree with the ', es: 'Acepto los ');

  String get authTermsAndConditions =>
      _t(pt: 'Termos e Condições', en: 'Terms and Conditions', es: 'Términos y Condiciones');

  String get authCreateAccountButton =>
      _t(pt: 'Criar conta', en: 'Create account', es: 'Crear cuenta');

  String get authOrSignUpWith =>
      _t(pt: 'ou cadastre-se com', en: 'or sign up with', es: 'o regístrate con');

  // Snackbars — register
  String get authErrAcceptTerms =>
      _t(pt: 'Aceite os Termos e Condições para continuar', en: 'Accept the Terms and Conditions to continue', es: 'Acepta los Términos y Condiciones para continuar');

  String get authErrFillAllFields =>
      _t(pt: 'Preencha e-mail, senha e confirmação de senha', en: 'Fill in email, password and confirmation', es: 'Completa correo, contraseña y confirmación');

  String get authErrPasswordTooShort =>
      _t(pt: 'A senha precisa ter ao menos 8 caracteres', en: 'Password must be at least 8 characters', es: 'La contraseña debe tener al menos 8 caracteres');

  String get authErrPasswordsNotEqual =>
      _t(pt: 'As senhas informadas não são iguais. Verifique e tente novamente.', en: 'The passwords entered do not match. Please check and try again.', es: 'Las contraseñas ingresadas no son iguales. Verifica e intenta de nuevo.');

  String get authErrGoogleRegister =>
      _t(pt: 'Não foi possível concluir o cadastro com Google.', en: 'Could not complete Google sign-up.', es: 'No se pudo completar el registro con Google.');

  String get authErrSendCode =>
      _t(pt: 'Não foi possível enviar o código. Tente novamente.', en: 'Could not send the code. Please try again.', es: 'No se pudo enviar el código. Inténtalo de nuevo.');

  // Forgot password
  String get authForgotTitle =>
      _t(pt: 'Esqueceu a senha?', en: 'Forgot your password?', es: '¿Olvidaste tu contraseña?');

  String get authForgotSubtitle => _t(
    pt: 'Informe seu e-mail e enviaremos um código para redefinir sua senha.',
    en: 'Enter your email and we\'ll send a code to reset your password.',
    es: 'Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.',
  );

  String get authSendVerificationCode =>
      _t(pt: 'Enviar código de verificação', en: 'Send verification code', es: 'Enviar código de verificación');

  String get authErrEnterEmail =>
      _t(pt: 'Informe seu e-mail', en: 'Please enter your email', es: 'Ingresa tu correo');

  String get authAlreadyHaveAccount =>
      _t(pt: 'Já tem uma conta? ', en: 'Already have an account? ', es: '¿Ya tienes una cuenta? ');

  String get authSignInLink => _t(pt: 'Entrar', en: 'Sign in', es: 'Entrar');
}
