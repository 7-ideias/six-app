import 'package:flutter/widgets.dart';

class WebMarketingLocalizer {
  WebMarketingLocalizer._(this.languageCode);

  final String languageCode;

  static const String demoYoutubeUrl =
      'https://www.youtube.com/watch?v=REPLACE_WITH_OFFICIAL_DEMO';

  static WebMarketingLocalizer of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final code =
        _strings.containsKey(locale.languageCode)
            ? locale.languageCode
            : _fallbackLanguage;
    return WebMarketingLocalizer._(code);
  }

  static const String _fallbackLanguage = 'en';

  String t(String key) {
    return _strings[languageCode]?[key] ??
        _strings[_fallbackLanguage]?[key] ??
        key;
  }

  List<String> list(String key) {
    final localized = _lists[languageCode]?[key];
    if (localized != null) {
      return List<String>.from(localized);
    }

    final fallback = _lists[_fallbackLanguage]?[key];
    if (fallback != null) {
      return List<String>.from(fallback);
    }

    return const [];
  }

  static const Map<String, Map<String, String>> _strings = {
    'pt': {
      'nav.aiErp': 'Six ERP IA',
      'nav.subtitle': 'Gestao inteligente para empresas de alta performance',
      'nav.login': 'Entrar',
      'nav.testNow': 'Experimente agora',
      'nav.buy': 'Comprar licenca',
      'hero.badge': 'ERP inteligente com IA aplicada em toda a operacao',
      'hero.title':
          'A plataforma que transforma vendas, servicos e financeiro em escala.',
      'hero.subtitle':
          'Configure em minutos e use IA para cadastrar produtos, recomendar precos, prever caixa e gerar relatorios com contexto real do seu negocio.',
      'hero.ctaTrial': 'Experimente agora',
      'hero.ctaLogin': 'Ja uso o sistema',
      'hero.ctaPlans': 'Ver planos e comprar',
      'hero.kpi1Label': 'implantacao',
      'hero.kpi1Value': 'em minutos',
      'hero.kpi2Label': 'modulos integrados',
      'hero.kpi2Value': 'vendas + OS + financeiro',
      'hero.kpi3Label': 'assistente IA',
      'hero.kpi3Value': 'em cadastros e analises',
      'features.title':
          'Feito para operacoes reais: do balcao ao servico tecnico',
      'features.subtitle':
          'Fluxos conectados entre vendas, orcamentos, ordens de servico, estoque e cobranca. A IA aprende com seus dados para acelerar decisoes.',
      'demo.title': 'Demo no YouTube e app nas lojas',
      'demo.subtitle':
          'Mostre para sua equipe em 5 minutos como o Six acelera atendimento, conversao e gestao com IA.',
      'demo.watch': 'Copiar link do video demo',
      'demo.opened': 'Link do YouTube copiado para area de transferencia.',
      'demo.warning':
          'Baixe somente pelas lojas oficiais. Evite APKs de origem desconhecida para proteger seus dados.',
      'download.android': 'Disponivel no Google Play',
      'download.ios': 'Disponivel na App Store',
      'pricing.title': 'Planos desenhados para converter e escalar',
      'pricing.subtitle':
          'Comece com teste guiado e evolua para assinatura com checkout pronto para Stripe.',
      'pricing.cardStarter': 'Starter IA',
      'pricing.cardPro': 'Pro IA',
      'pricing.cardEnterprise': 'Enterprise IA',
      'pricing.buyNow': 'Comprar agora',
      'pricing.testNow': 'Testar antes',
      'pricing.month': '/mes',
      'pricing.contact': 'fale com vendas',
      'checkout.badge': 'Checkout preparado para Stripe e gateways similares',
      'footer.cta':
          'Ative seu ambiente de teste e personalize o ERP com IA para o seu segmento.',
      'footer.ctaButton': 'Iniciar onboarding inteligente',
      'footer.loginButton': 'Ir para login',
      'common.language': 'Idioma',
      'language.pt': 'Portugues',
      'language.en': 'English',
      'language.es': 'Espanol',
      'onboarding.title': 'Onboarding inteligente para montar seu ERP ideal',
      'onboarding.subtitle':
          'Responda algumas escolhas e deixe a IA sugerir modulos, indicadores e automacoes para o seu negocio.',
      'onboarding.stepBusiness': 'Como sua operacao vende hoje?',
      'onboarding.stepSegments': 'Quais segmentos representam seu negocio?',
      'onboarding.stepChannels': 'Quais canais de venda voce utiliza?',
      'onboarding.stepModules': 'Quais modulos quer ativar no piloto?',
      'onboarding.stepAi': 'Onde a IA deve priorizar ganhos?',
      'onboarding.stepTeam': 'Quantas pessoas usam o sistema?',
      'onboarding.teamLabel': 'usuarios estimados',
      'onboarding.businessName': 'Nome do negocio (opcional)',
      'onboarding.aiPreview': 'Plano recomendado com IA',
      'onboarding.aiPreviewSubtitle':
          'Com base nas suas escolhas, o assistente vai iniciar com estas configuracoes:',
      'onboarding.finish': 'Concluir configuracao e ir para login',
      'onboarding.saved':
          'Perfil salvo. Continue no login para iniciar o teste.',
      'checkout.title': 'Comprar licenca e ativar ambiente',
      'checkout.subtitle':
          'Interface pronta para conectar com Stripe, Pix, boleto ou outro provedor.',
      'checkout.company': 'Empresa',
      'checkout.name': 'Responsavel',
      'checkout.email': 'Email comercial',
      'checkout.coupon': 'Cupom (opcional)',
      'checkout.billingCycle': 'Cobranca',
      'checkout.monthly': 'Mensal',
      'checkout.yearly': 'Anual (economia)',
      'checkout.payment': 'Forma de pagamento',
      'checkout.card': 'Cartao',
      'checkout.pix': 'Pix',
      'checkout.invoice': 'Boleto',
      'checkout.summary': 'Resumo da assinatura',
      'checkout.integrate': 'Integrar gateway e finalizar compra',
      'checkout.nextStep':
          'Proxima etapa: conectar endpoint de checkout no backend (ex.: Stripe Checkout Session).',
      'checkout.required':
          'Preencha empresa, responsavel e email para continuar.',
      'checkout.simulated': 'Payload de compra pronto para integracao:',
    },
    'en': {
      'nav.aiErp': 'Six AI ERP',
      'nav.subtitle': 'Smart management for high-performance companies',
      'nav.login': 'Login',
      'nav.testNow': 'Try now',
      'nav.buy': 'Buy license',
      'hero.badge': 'AI-native ERP across your entire operation',
      'hero.title':
          'The platform that scales sales, service operations and finance.',
      'hero.subtitle':
          'Go live in minutes and use AI to create products, recommend pricing, forecast cash flow and generate business-aware reports.',
      'hero.ctaTrial': 'Try now',
      'hero.ctaLogin': 'I already use Six',
      'hero.ctaPlans': 'See plans and buy',
      'hero.kpi1Label': 'go-live',
      'hero.kpi1Value': 'in minutes',
      'hero.kpi2Label': 'connected modules',
      'hero.kpi2Value': 'sales + service + finance',
      'hero.kpi3Label': 'AI copilot',
      'hero.kpi3Value': 'for records and insights',
      'features.title':
          'Built for real operations: from counter sales to field service',
      'features.subtitle':
          'Connected workflows across sales, quotations, service orders, inventory and billing. AI learns from your data to accelerate decisions.',
      'demo.title': 'YouTube demo and app stores',
      'demo.subtitle':
          'Show your team in 5 minutes how Six increases speed, conversion and control with AI.',
      'demo.watch': 'Copy demo video link',
      'demo.opened': 'YouTube link copied to clipboard.',
      'demo.warning':
          'Download only from official stores. Avoid unknown APKs to protect your data.',
      'download.android': 'Available on Google Play',
      'download.ios': 'Available on App Store',
      'pricing.title': 'Plans designed for conversion and scale',
      'pricing.subtitle':
          'Start with guided trial and grow into subscription with Stripe-ready checkout.',
      'pricing.cardStarter': 'AI Starter',
      'pricing.cardPro': 'AI Pro',
      'pricing.cardEnterprise': 'AI Enterprise',
      'pricing.buyNow': 'Buy now',
      'pricing.testNow': 'Test first',
      'pricing.month': '/month',
      'pricing.contact': 'contact sales',
      'checkout.badge': 'Checkout prepared for Stripe and similar gateways',
      'footer.cta': 'Start your trial workspace and personalize ERP with AI.',
      'footer.ctaButton': 'Start smart onboarding',
      'footer.loginButton': 'Go to login',
      'common.language': 'Language',
      'language.pt': 'Portuguese',
      'language.en': 'English',
      'language.es': 'Spanish',
      'onboarding.title': 'Smart onboarding to assemble your ideal ERP',
      'onboarding.subtitle':
          'Answer a few choices and let AI suggest modules, KPIs and automations for your business.',
      'onboarding.stepBusiness': 'How does your operation sell today?',
      'onboarding.stepSegments': 'Which segments represent your business?',
      'onboarding.stepChannels': 'Which sales channels do you use?',
      'onboarding.stepModules': 'Which modules do you want in the pilot?',
      'onboarding.stepAi': 'Where should AI prioritize gains?',
      'onboarding.stepTeam': 'How many users will access the system?',
      'onboarding.teamLabel': 'estimated users',
      'onboarding.businessName': 'Business name (optional)',
      'onboarding.aiPreview': 'AI recommended setup',
      'onboarding.aiPreviewSubtitle':
          'Based on your choices, the assistant will start with these configurations:',
      'onboarding.finish': 'Finish setup and go to login',
      'onboarding.saved':
          'Profile saved. Continue through login to start your trial.',
      'checkout.title': 'Buy license and activate workspace',
      'checkout.subtitle':
          'UI ready to integrate Stripe, Pix, invoice, or another provider.',
      'checkout.company': 'Company',
      'checkout.name': 'Owner',
      'checkout.email': 'Business email',
      'checkout.coupon': 'Coupon (optional)',
      'checkout.billingCycle': 'Billing',
      'checkout.monthly': 'Monthly',
      'checkout.yearly': 'Yearly (save more)',
      'checkout.payment': 'Payment method',
      'checkout.card': 'Card',
      'checkout.pix': 'Pix',
      'checkout.invoice': 'Invoice',
      'checkout.summary': 'Subscription summary',
      'checkout.integrate': 'Integrate gateway and complete purchase',
      'checkout.nextStep':
          'Next step: connect backend checkout endpoint (e.g. Stripe Checkout Session).',
      'checkout.required': 'Fill company, owner and email to continue.',
      'checkout.simulated': 'Purchase payload ready to integrate:',
    },
    'es': {
      'nav.aiErp': 'Six ERP IA',
      'nav.subtitle': 'Gestion inteligente para empresas de alto rendimiento',
      'nav.login': 'Ingresar',
      'nav.testNow': 'Probar ahora',
      'nav.buy': 'Comprar licencia',
      'hero.badge': 'ERP con IA en toda la operacion',
      'hero.title': 'La plataforma que escala ventas, servicios y finanzas.',
      'hero.subtitle':
          'Configure en minutos y use IA para crear productos, sugerir precios, prever caja y generar reportes de negocio.',
      'hero.ctaTrial': 'Probar ahora',
      'hero.ctaLogin': 'Ya uso Six',
      'hero.ctaPlans': 'Ver planes y comprar',
      'hero.kpi1Label': 'implementacion',
      'hero.kpi1Value': 'en minutos',
      'hero.kpi2Label': 'modulos conectados',
      'hero.kpi2Value': 'ventas + servicio + finanzas',
      'hero.kpi3Label': 'copiloto IA',
      'hero.kpi3Value': 'en registros y analisis',
      'features.title':
          'Hecho para operaciones reales: del mostrador al servicio',
      'features.subtitle':
          'Flujos conectados entre ventas, presupuestos, ordenes de servicio, inventario y cobro. La IA aprende de tus datos.',
      'demo.title': 'Demo en YouTube y apps en tiendas',
      'demo.subtitle':
          'Muestra en 5 minutos como Six acelera atencion, conversion y gestion con IA.',
      'demo.watch': 'Copiar enlace del video demo',
      'demo.opened': 'Enlace de YouTube copiado al portapapeles.',
      'demo.warning':
          'Descarga solo desde tiendas oficiales. Evita APKs desconocidos para proteger tus datos.',
      'download.android': 'Disponible en Google Play',
      'download.ios': 'Disponible en App Store',
      'pricing.title': 'Planes para convertir y escalar',
      'pricing.subtitle':
          'Empieza con prueba guiada y evoluciona con checkout listo para Stripe.',
      'pricing.cardStarter': 'Starter IA',
      'pricing.cardPro': 'Pro IA',
      'pricing.cardEnterprise': 'Enterprise IA',
      'pricing.buyNow': 'Comprar ahora',
      'pricing.testNow': 'Probar primero',
      'pricing.month': '/mes',
      'pricing.contact': 'contactar ventas',
      'checkout.badge': 'Checkout preparado para Stripe y gateways similares',
      'footer.cta':
          'Activa tu ambiente de prueba y personaliza el ERP con IA para tu segmento.',
      'footer.ctaButton': 'Iniciar onboarding inteligente',
      'footer.loginButton': 'Ir al login',
      'common.language': 'Idioma',
      'language.pt': 'Portugues',
      'language.en': 'Ingles',
      'language.es': 'Espanol',
      'onboarding.title': 'Onboarding inteligente para armar tu ERP ideal',
      'onboarding.subtitle':
          'Responde algunas opciones y deja que la IA sugiera modulos, KPIs y automatizaciones.',
      'onboarding.stepBusiness': 'Como vende tu operacion hoy?',
      'onboarding.stepSegments': 'Que segmentos representan tu negocio?',
      'onboarding.stepChannels': 'Que canales de venta usas?',
      'onboarding.stepModules': 'Que modulos quieres activar?',
      'onboarding.stepAi': 'Donde la IA debe priorizar ganancias?',
      'onboarding.stepTeam': 'Cuantas personas usaran el sistema?',
      'onboarding.teamLabel': 'usuarios estimados',
      'onboarding.businessName': 'Nombre del negocio (opcional)',
      'onboarding.aiPreview': 'Plan recomendado con IA',
      'onboarding.aiPreviewSubtitle':
          'Segun tus elecciones, el asistente iniciara con estas configuraciones:',
      'onboarding.finish': 'Finalizar configuracion e ir al login',
      'onboarding.saved':
          'Perfil guardado. Continua por login para iniciar la prueba.',
      'checkout.title': 'Comprar licencia y activar ambiente',
      'checkout.subtitle':
          'Interfaz lista para conectar Stripe, Pix, boleto u otro proveedor.',
      'checkout.company': 'Empresa',
      'checkout.name': 'Responsable',
      'checkout.email': 'Email comercial',
      'checkout.coupon': 'Cupon (opcional)',
      'checkout.billingCycle': 'Cobranza',
      'checkout.monthly': 'Mensual',
      'checkout.yearly': 'Anual (ahorro)',
      'checkout.payment': 'Metodo de pago',
      'checkout.card': 'Tarjeta',
      'checkout.pix': 'Pix',
      'checkout.invoice': 'Boleto',
      'checkout.summary': 'Resumen de suscripcion',
      'checkout.integrate': 'Integrar gateway y finalizar compra',
      'checkout.nextStep':
          'Siguiente paso: conectar endpoint de checkout en backend (ej.: Stripe Checkout Session).',
      'checkout.required':
          'Completa empresa, responsable y email para continuar.',
      'checkout.simulated': 'Payload de compra listo para integracion:',
    },
  };

  static const Map<String, Map<String, List<String>>> _lists = {
    'pt': {
      'featureTitles': [
        'Vendas e PDV com IA',
        'Orcamentos inteligentes',
        'Ordens de servico completas',
        'Financeiro preditivo',
      ],
      'featureDescriptions': [
        'Sugestoes de combos, margem e reposicao com base no seu historico.',
        'Monte propostas com precificacao assistida e conversao em pedido em 1 clique.',
        'Controle fila tecnica, SLA, pecas e comunicacao com cliente em tempo real.',
        'Previsao de fluxo de caixa, alertas de risco e painel executivo com IA.',
      ],
      'planStarterFeatures': [
        'PDV e vendas de balcao',
        'Cadastro assistido por IA',
        'Relatorios essenciais',
      ],
      'planProFeatures': [
        'Tudo do Starter',
        'Orcamentos e catalogos',
        'Ordens de servico e agenda tecnica',
        'Insights de margem por IA',
      ],
      'planEnterpriseFeatures': [
        'Tudo do Pro',
        'Automacoes e regras avancadas',
        'Integracoes dedicadas',
        'Squad de sucesso e IA customizada',
      ],
      'demoSteps': [
        '1. Assista ao video de demonstracao no YouTube.',
        '2. Baixe o app nas lojas oficiais para teste em campo.',
        '3. Inicie o onboarding e personalize modulos com IA.',
      ],
      'businessModels': [
        'Vendas de balcao',
        'Catalogo digital de vendas',
        'Vestuario',
        'Alimentacao',
        'Ordens de servico',
        'Operacao hibrida',
      ],
      'segments': [
        'Moda',
        'Food service',
        'Eletronicos',
        'Autopecas',
        'Assistencia tecnica',
        'Casa e decoracao',
      ],
      'channels': [
        'Loja fisica',
        'WhatsApp',
        'E-commerce proprio',
        'Marketplace',
        'Equipe externa',
      ],
      'modules': [
        'PDV e vendas',
        'Orcamentos',
        'Ordens de servico',
        'Estoque e compras',
        'Financeiro',
        'CRM e pos-venda',
      ],
      'aiFocus': [
        'Cadastro inteligente de produtos e clientes',
        'Sugestao de precificacao e margem',
        'Relatorios executivos automaticos',
        'Previsao de demanda e caixa',
        'Automacao de follow-up comercial',
      ],
      'aiRecommendationsBase': [
        'Habilitar assistente IA no cadastro para reduzir tempo operacional.',
        'Criar painel executivo com indicadores diarios de vendas e margem.',
      ],
    },
    'en': {
      'featureTitles': [
        'AI sales and POS',
        'Smart quotations',
        'Full service orders',
        'Predictive finance',
      ],
      'featureDescriptions': [
        'Suggest combos, margin targets and replenishment based on history.',
        'Build proposals with AI-assisted pricing and convert in one click.',
        'Manage technician queue, SLA, parts and customer communication.',
        'Cash-flow forecast, risk alerts and executive dashboard powered by AI.',
      ],
      'planStarterFeatures': [
        'Counter sales and POS',
        'AI-assisted product setup',
        'Core reports',
      ],
      'planProFeatures': [
        'Everything in Starter',
        'Quotations and catalogs',
        'Service orders and schedule',
        'AI margin insights',
      ],
      'planEnterpriseFeatures': [
        'Everything in Pro',
        'Advanced automations and rules',
        'Dedicated integrations',
        'Success squad and custom AI',
      ],
      'demoSteps': [
        '1. Watch the YouTube demo.',
        '2. Download the app from official stores for field validation.',
        '3. Start onboarding and personalize modules with AI.',
      ],
      'businessModels': [
        'Counter sales',
        'Digital sales catalog',
        'Fashion retail',
        'Food operation',
        'Service orders',
        'Hybrid operation',
      ],
      'segments': [
        'Fashion',
        'Food service',
        'Electronics',
        'Auto parts',
        'Technical assistance',
        'Home and decor',
      ],
      'channels': [
        'Physical store',
        'WhatsApp',
        'Own e-commerce',
        'Marketplace',
        'Field team',
      ],
      'modules': [
        'POS and sales',
        'Quotations',
        'Service orders',
        'Inventory and purchasing',
        'Finance',
        'CRM and retention',
      ],
      'aiFocus': [
        'Smart product and customer setup',
        'Pricing and margin suggestions',
        'Automatic executive reports',
        'Demand and cash forecast',
        'Sales follow-up automation',
      ],
      'aiRecommendationsBase': [
        'Enable AI assistant in records to reduce operational time.',
        'Create executive dashboard with daily sales and margin indicators.',
      ],
    },
    'es': {
      'featureTitles': [
        'Ventas y POS con IA',
        'Presupuestos inteligentes',
        'Ordenes de servicio completas',
        'Finanzas predictivas',
      ],
      'featureDescriptions': [
        'Sugerencias de combos, margen y reposicion basadas en historial.',
        'Crea propuestas con precios asistidos por IA y convierte en un clic.',
        'Gestiona cola tecnica, SLA, repuestos y comunicacion con clientes.',
        'Prevision de caja, alertas de riesgo y dashboard ejecutivo con IA.',
      ],
      'planStarterFeatures': [
        'POS y ventas de mostrador',
        'Registro asistido por IA',
        'Reportes esenciales',
      ],
      'planProFeatures': [
        'Todo lo de Starter',
        'Presupuestos y catalogos',
        'Ordenes de servicio y agenda tecnica',
        'Insights de margen con IA',
      ],
      'planEnterpriseFeatures': [
        'Todo lo de Pro',
        'Automatizaciones y reglas avanzadas',
        'Integraciones dedicadas',
        'Equipo de exito e IA personalizada',
      ],
      'demoSteps': [
        '1. Mira el video demo en YouTube.',
        '2. Descarga la app desde tiendas oficiales para validar en campo.',
        '3. Inicia onboarding y personaliza modulos con IA.',
      ],
      'businessModels': [
        'Ventas de mostrador',
        'Catalogo digital de ventas',
        'Moda',
        'Alimentacion',
        'Ordenes de servicio',
        'Operacion hibrida',
      ],
      'segments': [
        'Moda',
        'Food service',
        'Electronica',
        'Autopartes',
        'Asistencia tecnica',
        'Casa y decoracion',
      ],
      'channels': [
        'Tienda fisica',
        'WhatsApp',
        'E-commerce propio',
        'Marketplace',
        'Equipo externo',
      ],
      'modules': [
        'POS y ventas',
        'Presupuestos',
        'Ordenes de servicio',
        'Inventario y compras',
        'Finanzas',
        'CRM y postventa',
      ],
      'aiFocus': [
        'Registro inteligente de productos y clientes',
        'Sugerencias de precios y margen',
        'Reportes ejecutivos automaticos',
        'Prevision de demanda y caja',
        'Automatizacion de seguimiento comercial',
      ],
      'aiRecommendationsBase': [
        'Activar asistente IA en registros para reducir tiempo operativo.',
        'Crear dashboard ejecutivo con indicadores diarios de ventas y margen.',
      ],
    },
  };
}
