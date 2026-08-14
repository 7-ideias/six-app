(function () {
  'use strict';

  var localeStorageKey = 'sixapp.public.locale';

  var dictionary = {
    pt: {
      title: 'SixApp - Gestão para produtos e serviços técnicos',
      description: 'SixApp organiza vendas, orçamentos, atendimentos técnicos, clientes, equipe e financeiro em uma plataforma online para comércios de produtos e serviços.',
      ogTitle: 'SixApp',
      ogDescription: 'Gestão completa para quem vende produtos e presta serviços técnicos.',
      twitterTitle: 'SixApp',
      twitterDescription: 'Vendas, orçamentos, atendimentos, equipe e financeiro em um só lugar.',
      'access.skip': 'Ir para o conteúdo principal',
      'nav.aria': 'Navegação principal',
      'nav.menu': 'Menu',
      'nav.resources': 'Recursos',
      'nav.segments': 'Segmentos',
      'nav.how': 'Como funciona',
      'nav.plans': 'Planos',
      'nav.faq': 'FAQ',
      'nav.login': 'Entrar',
      'nav.signup': 'Criar conta',
      'language.aria': 'Selecionar idioma',
      'hero.eyebrow': 'Gestão online para comércio e serviços',
      'hero.title': 'Gestão completa para quem vende produtos e presta serviços técnicos.',
      'hero.lead': 'O SixApp conecta vendas, orçamentos, atendimentos, clientes, equipe e financeiro em um só lugar, com clareza para operar hoje e acompanhar o crescimento amanhã.',
      'hero.primary': 'Começar agora',
      'hero.secondary': 'Entrar',
      'hero.tertiary': 'Conhecer recursos',
      'hero.onboarding': 'Experimentar',
      'preview.aria': 'Prévia simplificada do SixApp',
      'preview.workspace': 'Operação de hoje',
      'preview.status': 'Online',
      'preview.kpi.sales': 'Vendas',
      'preview.kpi.sales.value': 'Em acompanhamento',
      'preview.kpi.service': 'Atendimentos',
      'preview.kpi.service.value': 'Fila organizada',
      'preview.kpi.finance': 'Financeiro',
      'preview.kpi.finance.value': 'Visão clara',
      'preview.flow.one.label': 'Orçamento',
      'preview.flow.one.title': 'Aguardando aprovação',
      'preview.flow.two.label': 'Serviço',
      'preview.flow.two.title': 'Em execução',
      'preview.flow.three.label': 'Entrega',
      'preview.flow.three.title': 'Comprovante pronto',
      'trust.aria': 'Diferenciais do SixApp',
      'trust.platforms': 'Web, Android e iOS',
      'trust.platforms.body': 'Acesse no computador e no celular.',
      'trust.languages': 'Vários idiomas',
      'trust.languages.body': 'Português, inglês e espanhol na Home pública.',
      'trust.multiBusiness': 'Mais de um comércio',
      'trust.multiBusiness.body': 'Organização para contas com múltiplas operações.',
      'trust.permissions': 'Permissões por colaborador',
      'trust.permissions.body': 'Acesso alinhado ao papel de cada pessoa.',
      'trust.online': 'Informações sincronizadas',
      'trust.online.body': 'Dados online para acompanhar a rotina.',
      'resources.kicker': 'Recursos principais',
      'resources.title': 'Uma base organizada para vender, atender e acompanhar.',
      'resources.lead': 'O SixApp reúne módulos essenciais para comércios que combinam produtos, serviços, clientes e gestão diária.',
      'feature.sales.title': 'Vendas e orçamentos',
      'feature.sales.body': 'Registre pedidos, acompanhe propostas e avance do orçamento ao atendimento com menos retrabalho.',
      'feature.service.title': 'Atendimento técnico',
      'feature.service.body': 'Organize solicitações, status, evidências, execução e entrega sem perder o histórico do cliente.',
      'feature.catalog.title': 'Produtos e serviços',
      'feature.catalog.body': 'Mantenha catálogo, estoque e serviços cadastrados em uma rotina centralizada.',
      'feature.people.title': 'Clientes, colaboradores e fornecedores',
      'feature.people.body': 'Tenha cadastros mais claros para relacionamento, operação e acompanhamento interno.',
      'feature.finance.title': 'Financeiro',
      'feature.finance.body': 'Acompanhe caixa, recebimentos, pendências e compromissos com leitura operacional.',
      'feature.pdf.title': 'Relatórios e comprovantes em PDF',
      'feature.pdf.body': 'Gere documentos e registros para apoiar atendimento, entrega e conferência.',
      'feature.communication.title': 'Comunicação e notificações',
      'feature.communication.body': 'Acompanhe eventos relevantes da operação e mantenha o cliente informado quando o fluxo permitir.',
      'feature.permissions.title': 'Equipe e permissões',
      'feature.permissions.body': 'Separe responsabilidades e reduza acesso indevido a ações sensíveis.',
      'journey.kicker': 'Jornada do atendimento técnico',
      'journey.title': 'Do primeiro contato ao comprovante final.',
      'journey.lead': 'A jornada foi pensada para serviços técnicos especializados, sem limitar o processo a um único tipo de equipamento.',
      'journey.one.title': 'Receba o item ou a solicitação',
      'journey.one.body': 'Comece pelo atendimento e registre o contexto do cliente.',
      'journey.two.title': 'Registre informações e evidências',
      'journey.two.body': 'Organize dados, observações e histórico do atendimento.',
      'journey.three.title': 'Prepare o orçamento',
      'journey.three.body': 'Formalize produtos, serviços e condições antes da execução.',
      'journey.four.title': 'Acompanhe aprovação e execução',
      'journey.four.body': 'Mantenha status claros para equipe e gestão.',
      'journey.five.title': 'Notifique o cliente',
      'journey.five.body': 'Use o fluxo para apoiar comunicação sobre andamento e próximos passos.',
      'journey.six.title': 'Entregue e gere o comprovante',
      'journey.six.body': 'Finalize com registro organizado para consulta e conferência.',
      'segments.kicker': 'Segmentos atendidos',
      'segments.title': 'Para negócios que precisam unir balcão, serviço e gestão.',
      'segments.lead': 'O SixApp atende rotinas de comércio e prestação de serviço técnico com processos, pessoas e financeiro no mesmo ambiente.',
      'segments.aria': 'Exemplos de segmentos',
      'segment.one': 'Assistência técnica',
      'segment.two': 'Informática',
      'segment.three': 'Eletrônica',
      'segment.four': 'Manutenção',
      'segment.five': 'Climatização',
      'segment.six': 'Eletrodomésticos',
      'segment.workshops': 'Oficinas e equipamentos',
      'segment.eight': 'Serviços técnicos especializados',
      'segments.note': 'E muitos outros negócios que combinam produtos e serviços.',
      'management.preview.aria': 'Prévia gerencial simplificada',
      'management.preview.cash': 'Caixa',
      'management.preview.cash.value': 'Resumo do dia',
      'management.preview.team': 'Equipe',
      'management.preview.team.value': 'Permissões ativas',
      'management.preview.tag.one': 'Vendas',
      'management.preview.tag.two': 'Pendências',
      'management.preview.tag.three': 'Comércios',
      'management.kicker': 'Gestão além do atendimento',
      'management.title': 'Visão gerencial sem reproduzir o dashboard inteiro na Home.',
      'management.lead': 'Acompanhe indicadores, equipe, caixas, vendas, pendências, financeiro e múltiplos comércios com uma leitura preparada para decisão.',
      'management.item.one': 'Indicadores e pendências com leitura rápida.',
      'management.item.two': 'Equipe e permissões alinhadas à operação.',
      'management.item.three': 'Visão para quem administra mais de um comércio.',
      'platforms.kicker': 'Multiplataforma',
      'platforms.title': 'Acesse no computador, Android e iOS.',
      'platforms.lead': 'O SixApp foi pensado para a rotina online do comércio: gestão no navegador e acompanhamento no celular quando a operação pedir mobilidade.',
      'platforms.aria': 'Plataformas',
      'plans.kicker': 'Planos',
      'plans.title': 'Comece de forma simples e evolua conforme o seu negócio.',
      'plans.lead': 'Os planos devem acompanhar o momento da operação sem obrigar você a decidir tudo antes de organizar a rotina.',
      'plans.card.title': 'Conheça as opções do SixApp',
      'plans.card.body': 'A página de checkout continua no fluxo Flutter Web. Caso prefira começar pela conta, o cadastro também está disponível.',
      'plans.primary': 'Conhecer planos',
      'plans.secondary': 'Criar conta',
      'faq.kicker': 'FAQ',
      'faq.title': 'Perguntas frequentes',
      'faq.lead': 'Respostas diretas para entender se o SixApp se encaixa na sua rotina.',
      'faq.one.question': 'Para quais tipos de negócio o SixApp serve?',
      'faq.one.answer': 'Para comércios que vendem produtos, prestam serviços técnicos, fazem orçamentos e precisam acompanhar clientes, equipe e financeiro.',
      'faq.two.question': 'Posso cadastrar mais de um comércio?',
      'faq.two.answer': 'A estrutura do app considera operações com mais de um comércio por conta, mantendo a gestão separada quando necessário.',
      'faq.three.question': 'Posso controlar permissões dos colaboradores?',
      'faq.three.answer': 'Sim. O SixApp considera permissões para limitar ações sensíveis de acordo com o papel do colaborador.',
      'faq.four.question': 'O SixApp funciona no celular e computador?',
      'faq.four.answer': 'Sim. A experiência contempla Web, Android e iOS, com rotinas adequadas para gestão e acompanhamento.',
      'faq.five.question': 'É possível gerar relatórios e comprovantes?',
      'faq.five.answer': 'O app possui fluxos de relatórios e comprovantes em PDF para apoiar conferência, atendimento e entrega.',
      'faq.six.question': 'Meus colaboradores precisam ter acesso a tudo?',
      'faq.six.answer': 'Não. A gestão de permissões ajuda a separar responsabilidades e reduzir acesso indevido a áreas sensíveis.',
      'faq.offline.question': 'O SixApp funciona sem internet?',
      'faq.offline.answer': 'Não. O SixApp é um sistema online e exige conexão com a internet para manter informações sincronizadas.',
      'final.kicker': 'Próximo passo',
      'final.title': 'Organize hoje a operação que você quer escalar amanhã.',
      'final.primary': 'Criar minha conta',
      'final.secondary': 'Entrar',
      'footer.product': 'Gestão online para comércios de produtos e serviços técnicos.',
      'footer.aria': 'Navegação do rodapé',
      'footer.resources': 'Recursos',
      'footer.segments': 'Segmentos',
      'footer.how': 'Como funciona',
      'footer.plans': 'Planos',
      'footer.faq': 'FAQ',
      'footer.access.aria': 'Acesso',
      'footer.login': 'Entrar',
      'footer.signup': 'Criar conta',
      'footer.terms': 'Termos e privacidade em preparação',
      'footer.note': 'Produto digital para gestão comercial e operacional.'
    },
    en: {
      title: 'SixApp - Management for products and technical services',
      description: 'SixApp organizes sales, quotes, technical service, customers, teams and finance in an online platform for product and service businesses.',
      ogTitle: 'SixApp',
      ogDescription: 'Complete management for businesses that sell products and provide technical services.',
      twitterTitle: 'SixApp',
      twitterDescription: 'Sales, quotes, service, teams and finance in one place.',
      'access.skip': 'Skip to main content',
      'nav.aria': 'Main navigation',
      'nav.menu': 'Menu',
      'nav.resources': 'Features',
      'nav.segments': 'Segments',
      'nav.how': 'How it works',
      'nav.plans': 'Plans',
      'nav.faq': 'FAQ',
      'nav.login': 'Sign in',
      'nav.signup': 'Create account',
      'language.aria': 'Select language',
      'hero.eyebrow': 'Online management for commerce and services',
      'hero.title': 'Complete management for businesses that sell products and provide technical services.',
      'hero.lead': 'SixApp connects sales, quotes, service, customers, teams and finance in one place, with clarity to operate today and follow growth tomorrow.',
      'hero.primary': 'Start now',
      'hero.secondary': 'Sign in',
      'hero.tertiary': 'Explore features',
      'hero.onboarding': 'Try it',
      'preview.aria': 'Simplified SixApp preview',
      'preview.workspace': 'Today operation',
      'preview.status': 'Online',
      'preview.kpi.sales': 'Sales',
      'preview.kpi.sales.value': 'Being tracked',
      'preview.kpi.service': 'Service',
      'preview.kpi.service.value': 'Organized queue',
      'preview.kpi.finance': 'Finance',
      'preview.kpi.finance.value': 'Clear view',
      'preview.flow.one.label': 'Quote',
      'preview.flow.one.title': 'Waiting approval',
      'preview.flow.two.label': 'Service',
      'preview.flow.two.title': 'In progress',
      'preview.flow.three.label': 'Delivery',
      'preview.flow.three.title': 'Receipt ready',
      'trust.aria': 'SixApp advantages',
      'trust.platforms': 'Web, Android and iOS',
      'trust.platforms.body': 'Access it on desktop and mobile.',
      'trust.languages': 'Multiple languages',
      'trust.languages.body': 'Portuguese, English and Spanish on the public Home.',
      'trust.multiBusiness': 'More than one business',
      'trust.multiBusiness.body': 'Organization for accounts with multiple operations.',
      'trust.permissions': 'Permissions by collaborator',
      'trust.permissions.body': 'Access aligned with each person role.',
      'trust.online': 'Synchronized information',
      'trust.online.body': 'Online data to follow the routine.',
      'resources.kicker': 'Main features',
      'resources.title': 'An organized base to sell, serve and follow up.',
      'resources.lead': 'SixApp brings essential modules together for businesses that combine products, services, customers and daily management.',
      'feature.sales.title': 'Sales and quotes',
      'feature.sales.body': 'Register orders, follow proposals and move from quote to service with less rework.',
      'feature.service.title': 'Technical service',
      'feature.service.body': 'Organize requests, statuses, evidence, execution and delivery without losing customer history.',
      'feature.catalog.title': 'Products and services',
      'feature.catalog.body': 'Keep catalog, inventory and services registered in a centralized routine.',
      'feature.people.title': 'Customers, collaborators and suppliers',
      'feature.people.body': 'Keep clearer records for relationships, operation and internal tracking.',
      'feature.finance.title': 'Finance',
      'feature.finance.body': 'Track cash, receivables, pending items and commitments with operational reading.',
      'feature.pdf.title': 'PDF reports and receipts',
      'feature.pdf.body': 'Generate documents and records to support service, delivery and review.',
      'feature.communication.title': 'Communication and notifications',
      'feature.communication.body': 'Follow relevant operation events and keep customers informed when the flow allows it.',
      'feature.permissions.title': 'Team and permissions',
      'feature.permissions.body': 'Separate responsibilities and reduce improper access to sensitive actions.',
      'journey.kicker': 'Technical service journey',
      'journey.title': 'From first contact to the final receipt.',
      'journey.lead': 'The journey supports specialized technical services without limiting the process to one type of equipment.',
      'journey.one.title': 'Receive the item or request',
      'journey.one.body': 'Start with service intake and register the customer context.',
      'journey.two.title': 'Record information and evidence',
      'journey.two.body': 'Organize data, notes and service history.',
      'journey.three.title': 'Prepare the quote',
      'journey.three.body': 'Formalize products, services and conditions before execution.',
      'journey.four.title': 'Follow approval and execution',
      'journey.four.body': 'Keep statuses clear for the team and management.',
      'journey.five.title': 'Notify the customer',
      'journey.five.body': 'Use the flow to support communication about progress and next steps.',
      'journey.six.title': 'Deliver and generate the receipt',
      'journey.six.body': 'Close with an organized record for lookup and review.',
      'segments.kicker': 'Business segments',
      'segments.title': 'For businesses that need to connect counter, service and management.',
      'segments.lead': 'SixApp supports commerce and technical service routines with processes, people and finance in the same workspace.',
      'segments.aria': 'Segment examples',
      'segment.one': 'Technical assistance',
      'segment.two': 'IT services',
      'segment.three': 'Electronics',
      'segment.four': 'Maintenance',
      'segment.five': 'HVAC',
      'segment.six': 'Home appliances',
      'segment.workshops': 'Workshops and equipment',
      'segment.eight': 'Specialized technical services',
      'segments.note': 'And many other businesses that combine products and services.',
      'management.preview.aria': 'Simplified management preview',
      'management.preview.cash': 'Cash',
      'management.preview.cash.value': 'Daily summary',
      'management.preview.team': 'Team',
      'management.preview.team.value': 'Active permissions',
      'management.preview.tag.one': 'Sales',
      'management.preview.tag.two': 'Pending items',
      'management.preview.tag.three': 'Businesses',
      'management.kicker': 'Management beyond service',
      'management.title': 'A management view without reproducing the whole dashboard on the Home.',
      'management.lead': 'Follow indicators, teams, cash, sales, pending items, finance and multiple businesses with a view prepared for decisions.',
      'management.item.one': 'Indicators and pending items with quick reading.',
      'management.item.two': 'Team and permissions aligned with the operation.',
      'management.item.three': 'A view for those who manage more than one business.',
      'platforms.kicker': 'Multiplatform',
      'platforms.title': 'Access it on desktop, Android and iOS.',
      'platforms.lead': 'SixApp was designed for the online routine of a business: management in the browser and mobile tracking when the operation needs mobility.',
      'platforms.aria': 'Platforms',
      'plans.kicker': 'Plans',
      'plans.title': 'Start simply and evolve as your business grows.',
      'plans.lead': 'Plans should follow the operation moment without forcing every decision before the routine is organized.',
      'plans.card.title': 'Explore SixApp options',
      'plans.card.body': 'The checkout page remains in the Flutter Web flow. If you prefer to start with an account, registration is also available.',
      'plans.primary': 'Explore plans',
      'plans.secondary': 'Create account',
      'faq.kicker': 'FAQ',
      'faq.title': 'Frequently asked questions',
      'faq.lead': 'Direct answers to understand whether SixApp fits your routine.',
      'faq.one.question': 'What types of business is SixApp for?',
      'faq.one.answer': 'For businesses that sell products, provide technical services, create quotes and need to follow customers, teams and finance.',
      'faq.two.question': 'Can I register more than one business?',
      'faq.two.answer': 'The app structure considers operations with more than one business per account, keeping management separated when needed.',
      'faq.three.question': 'Can I control collaborator permissions?',
      'faq.three.answer': 'Yes. SixApp considers permissions to limit sensitive actions according to each collaborator role.',
      'faq.four.question': 'Does SixApp work on mobile and desktop?',
      'faq.four.answer': 'Yes. The experience includes Web, Android and iOS, with routines suited for management and tracking.',
      'faq.five.question': 'Can I generate reports and receipts?',
      'faq.five.answer': 'The app has report and PDF receipt flows to support review, service and delivery.',
      'faq.six.question': 'Do my collaborators need access to everything?',
      'faq.six.answer': 'No. Permission management helps separate responsibilities and reduce improper access to sensitive areas.',
      'faq.offline.question': 'Does SixApp work without internet?',
      'faq.offline.answer': 'No. SixApp is an online system and requires an internet connection to keep information synchronized.',
      'final.kicker': 'Next step',
      'final.title': 'Organize today the operation you want to scale tomorrow.',
      'final.primary': 'Create my account',
      'final.secondary': 'Sign in',
      'footer.product': 'Online management for product and technical service businesses.',
      'footer.aria': 'Footer navigation',
      'footer.resources': 'Features',
      'footer.segments': 'Segments',
      'footer.how': 'How it works',
      'footer.plans': 'Plans',
      'footer.faq': 'FAQ',
      'footer.access.aria': 'Access',
      'footer.login': 'Sign in',
      'footer.signup': 'Create account',
      'footer.terms': 'Terms and privacy in preparation',
      'footer.note': 'Digital product for commercial and operational management.'
    },
    es: {
      title: 'SixApp - Gestión para productos y servicios técnicos',
      description: 'SixApp organiza ventas, presupuestos, atención técnica, clientes, equipo y finanzas en una plataforma online para comercios de productos y servicios.',
      ogTitle: 'SixApp',
      ogDescription: 'Gestión completa para quienes venden productos y prestan servicios técnicos.',
      twitterTitle: 'SixApp',
      twitterDescription: 'Ventas, presupuestos, atención, equipo y finanzas en un solo lugar.',
      'access.skip': 'Ir al contenido principal',
      'nav.aria': 'Navegación principal',
      'nav.menu': 'Menú',
      'nav.resources': 'Recursos',
      'nav.segments': 'Segmentos',
      'nav.how': 'Cómo funciona',
      'nav.plans': 'Planes',
      'nav.faq': 'FAQ',
      'nav.login': 'Entrar',
      'nav.signup': 'Crear cuenta',
      'language.aria': 'Seleccionar idioma',
      'hero.eyebrow': 'Gestión online para comercio y servicios',
      'hero.title': 'Gestión completa para quienes venden productos y prestan servicios técnicos.',
      'hero.lead': 'SixApp conecta ventas, presupuestos, atención, clientes, equipo y finanzas en un solo lugar, con claridad para operar hoy y acompañar el crecimiento mañana.',
      'hero.primary': 'Comenzar ahora',
      'hero.secondary': 'Entrar',
      'hero.tertiary': 'Conocer recursos',
      'hero.onboarding': 'Probar',
      'preview.aria': 'Vista simplificada de SixApp',
      'preview.workspace': 'Operación de hoy',
      'preview.status': 'Online',
      'preview.kpi.sales': 'Ventas',
      'preview.kpi.sales.value': 'En seguimiento',
      'preview.kpi.service': 'Atenciones',
      'preview.kpi.service.value': 'Fila organizada',
      'preview.kpi.finance': 'Finanzas',
      'preview.kpi.finance.value': 'Visión clara',
      'preview.flow.one.label': 'Presupuesto',
      'preview.flow.one.title': 'Esperando aprobación',
      'preview.flow.two.label': 'Servicio',
      'preview.flow.two.title': 'En ejecución',
      'preview.flow.three.label': 'Entrega',
      'preview.flow.three.title': 'Comprobante listo',
      'trust.aria': 'Diferenciales de SixApp',
      'trust.platforms': 'Web, Android e iOS',
      'trust.platforms.body': 'Accede desde computadora y celular.',
      'trust.languages': 'Varios idiomas',
      'trust.languages.body': 'Portugués, inglés y español en la Home pública.',
      'trust.multiBusiness': 'Más de un comercio',
      'trust.multiBusiness.body': 'Organización para cuentas con múltiples operaciones.',
      'trust.permissions': 'Permisos por colaborador',
      'trust.permissions.body': 'Acceso alineado con el rol de cada persona.',
      'trust.online': 'Información sincronizada',
      'trust.online.body': 'Datos online para acompañar la rutina.',
      'resources.kicker': 'Recursos principales',
      'resources.title': 'Una base organizada para vender, atender y acompañar.',
      'resources.lead': 'SixApp reúne módulos esenciales para comercios que combinan productos, servicios, clientes y gestión diaria.',
      'feature.sales.title': 'Ventas y presupuestos',
      'feature.sales.body': 'Registra pedidos, acompaña propuestas y avanza del presupuesto a la atención con menos retrabajo.',
      'feature.service.title': 'Atención técnica',
      'feature.service.body': 'Organiza solicitudes, estados, evidencias, ejecución y entrega sin perder el historial del cliente.',
      'feature.catalog.title': 'Productos y servicios',
      'feature.catalog.body': 'Mantén catálogo, inventario y servicios registrados en una rutina centralizada.',
      'feature.people.title': 'Clientes, colaboradores y proveedores',
      'feature.people.body': 'Ten registros más claros para relación, operación y seguimiento interno.',
      'feature.finance.title': 'Finanzas',
      'feature.finance.body': 'Acompaña caja, cobros, pendientes y compromisos con lectura operativa.',
      'feature.pdf.title': 'Informes y comprobantes en PDF',
      'feature.pdf.body': 'Genera documentos y registros para apoyar atención, entrega y conferencia.',
      'feature.communication.title': 'Comunicación y notificaciones',
      'feature.communication.body': 'Acompaña eventos relevantes de la operación y mantén al cliente informado cuando el flujo lo permita.',
      'feature.permissions.title': 'Equipo y permisos',
      'feature.permissions.body': 'Separa responsabilidades y reduce accesos indebidos a acciones sensibles.',
      'journey.kicker': 'Jornada de atención técnica',
      'journey.title': 'Del primer contacto al comprobante final.',
      'journey.lead': 'La jornada fue pensada para servicios técnicos especializados, sin limitar el proceso a un único tipo de equipo.',
      'journey.one.title': 'Recibe el item o la solicitud',
      'journey.one.body': 'Comienza por la atención y registra el contexto del cliente.',
      'journey.two.title': 'Registra información y evidencias',
      'journey.two.body': 'Organiza datos, observaciones e historial de la atención.',
      'journey.three.title': 'Prepara el presupuesto',
      'journey.three.body': 'Formaliza productos, servicios y condiciones antes de la ejecución.',
      'journey.four.title': 'Acompaña aprobación y ejecución',
      'journey.four.body': 'Mantén estados claros para el equipo y la gestión.',
      'journey.five.title': 'Notifica al cliente',
      'journey.five.body': 'Usa el flujo para apoyar la comunicación sobre avance y próximos pasos.',
      'journey.six.title': 'Entrega y genera el comprobante',
      'journey.six.body': 'Finaliza con un registro organizado para consulta y conferencia.',
      'segments.kicker': 'Segmentos atendidos',
      'segments.title': 'Para negocios que necesitan unir mostrador, servicio y gestión.',
      'segments.lead': 'SixApp atiende rutinas de comercio y prestación de servicio técnico con procesos, personas y finanzas en el mismo ambiente.',
      'segments.aria': 'Ejemplos de segmentos',
      'segment.one': 'Asistencia técnica',
      'segment.two': 'Informática',
      'segment.three': 'Electrónica',
      'segment.four': 'Mantenimiento',
      'segment.five': 'Climatización',
      'segment.six': 'Electrodomésticos',
      'segment.workshops': 'Talleres y equipos',
      'segment.eight': 'Servicios técnicos especializados',
      'segments.note': 'Y muchos otros negocios que combinan productos y servicios.',
      'management.preview.aria': 'Vista gerencial simplificada',
      'management.preview.cash': 'Caja',
      'management.preview.cash.value': 'Resumen del día',
      'management.preview.team': 'Equipo',
      'management.preview.team.value': 'Permisos activos',
      'management.preview.tag.one': 'Ventas',
      'management.preview.tag.two': 'Pendientes',
      'management.preview.tag.three': 'Comercios',
      'management.kicker': 'Gestión más allá de la atención',
      'management.title': 'Visión gerencial sin reproducir todo el dashboard en la Home.',
      'management.lead': 'Acompaña indicadores, equipo, cajas, ventas, pendientes, finanzas y múltiples comercios con una lectura preparada para decidir.',
      'management.item.one': 'Indicadores y pendientes con lectura rápida.',
      'management.item.two': 'Equipo y permisos alineados con la operación.',
      'management.item.three': 'Visión para quien administra más de un comercio.',
      'platforms.kicker': 'Multiplataforma',
      'platforms.title': 'Accede desde computadora, Android e iOS.',
      'platforms.lead': 'SixApp fue pensado para la rutina online del comercio: gestión en el navegador y seguimiento en el celular cuando la operación pide movilidad.',
      'platforms.aria': 'Plataformas',
      'plans.kicker': 'Planes',
      'plans.title': 'Comienza de forma simple y evoluciona según tu negocio.',
      'plans.lead': 'Los planes deben acompañar el momento de la operación sin obligarte a decidir todo antes de organizar la rutina.',
      'plans.card.title': 'Conoce las opciones de SixApp',
      'plans.card.body': 'La página de checkout continúa en el flujo Flutter Web. Si prefieres comenzar por la cuenta, el registro también está disponible.',
      'plans.primary': 'Conocer planes',
      'plans.secondary': 'Crear cuenta',
      'faq.kicker': 'FAQ',
      'faq.title': 'Preguntas frecuentes',
      'faq.lead': 'Respuestas directas para entender si SixApp encaja en tu rutina.',
      'faq.one.question': '¿Para qué tipos de negocio sirve SixApp?',
      'faq.one.answer': 'Para comercios que venden productos, prestan servicios técnicos, hacen presupuestos y necesitan acompañar clientes, equipo y finanzas.',
      'faq.two.question': '¿Puedo registrar más de un comercio?',
      'faq.two.answer': 'La estructura de la app considera operaciones con más de un comercio por cuenta, manteniendo la gestión separada cuando sea necesario.',
      'faq.three.question': '¿Puedo controlar permisos de colaboradores?',
      'faq.three.answer': 'Sí. SixApp considera permisos para limitar acciones sensibles según el rol del colaborador.',
      'faq.four.question': '¿SixApp funciona en celular y computadora?',
      'faq.four.answer': 'Sí. La experiencia contempla Web, Android e iOS, con rutinas adecuadas para gestión y seguimiento.',
      'faq.five.question': '¿Es posible generar informes y comprobantes?',
      'faq.five.answer': 'La app posee flujos de informes y comprobantes en PDF para apoyar conferencia, atención y entrega.',
      'faq.six.question': '¿Mis colaboradores necesitan acceso a todo?',
      'faq.six.answer': 'No. La gestión de permisos ayuda a separar responsabilidades y reducir acceso indebido a áreas sensibles.',
      'faq.offline.question': '¿SixApp funciona sin internet?',
      'faq.offline.answer': 'No. SixApp es un sistema online y exige conexión a internet para mantener la información sincronizada.',
      'final.kicker': 'Próximo paso',
      'final.title': 'Organiza hoy la operación que quieres escalar mañana.',
      'final.primary': 'Crear mi cuenta',
      'final.secondary': 'Entrar',
      'footer.product': 'Gestión online para comercios de productos y servicios técnicos.',
      'footer.aria': 'Navegación del pie de página',
      'footer.resources': 'Recursos',
      'footer.segments': 'Segmentos',
      'footer.how': 'Cómo funciona',
      'footer.plans': 'Planes',
      'footer.faq': 'FAQ',
      'footer.access.aria': 'Acceso',
      'footer.login': 'Entrar',
      'footer.signup': 'Crear cuenta',
      'footer.terms': 'Términos y privacidad en preparación',
      'footer.note': 'Producto digital para gestión comercial y operativa.'
    }
  };

  function normalizeLanguage(value) {
    var code = String(value || '').toLowerCase();
    if (code.indexOf('en') === 0) return 'en';
    if (code.indexOf('es') === 0) return 'es';
    return 'pt';
  }

  function getStoredLocale() {
    try {
      return window.localStorage.getItem(localeStorageKey);
    } catch (_) {
      return null;
    }
  }

  function storeLocale(language) {
    try {
      window.localStorage.setItem(localeStorageKey, language);
    } catch (_) {}
  }

  function selectedLanguage() {
    var stored = getStoredLocale();
    if (stored) return normalizeLanguage(stored);
    var browser = (navigator.languages && navigator.languages[0]) || navigator.language || 'pt-BR';
    return normalizeLanguage(browser);
  }

  function setMeta(name, content) {
    var node = document.querySelector('meta[name="' + name + '"]');
    if (node) node.setAttribute('content', content);
  }

  function setProperty(property, content) {
    var node = document.querySelector('meta[property="' + property + '"]');
    if (node) node.setAttribute('content', content);
  }

  function applyLanguage(language) {
    var normalized = normalizeLanguage(language);
    var copy = dictionary[normalized] || dictionary.pt;
    document.documentElement.lang = normalized === 'pt' ? 'pt-BR' : normalized;
    document.title = copy.title;
    setMeta('description', copy.description);
    setProperty('og:title', copy.ogTitle);
    setProperty('og:description', copy.ogDescription);
    setMeta('twitter:title', copy.twitterTitle);
    setMeta('twitter:description', copy.twitterDescription);

    document.querySelectorAll('[data-i18n]').forEach(function (node) {
      var key = node.getAttribute('data-i18n');
      if (copy[key]) node.textContent = copy[key];
    });

    document.querySelectorAll('[data-i18n-aria]').forEach(function (node) {
      var key = node.getAttribute('data-i18n-aria');
      if (copy[key]) node.setAttribute('aria-label', copy[key]);
    });

    document.querySelectorAll('[data-i18n-alt]').forEach(function (node) {
      var key = node.getAttribute('data-i18n-alt');
      if (copy[key]) node.setAttribute('alt', copy[key]);
    });

    document.querySelectorAll('[data-lang-option]').forEach(function (button) {
      button.setAttribute('aria-pressed', button.getAttribute('data-lang-option') === normalized ? 'true' : 'false');
    });

    storeLocale(normalized);
  }

  function setupLanguageSwitcher() {
    document.querySelectorAll('[data-lang-option]').forEach(function (button) {
      button.addEventListener('click', function () {
        applyLanguage(button.getAttribute('data-lang-option'));
      });
    });
  }

  function setupMobileMenu() {
    var toggle = document.querySelector('[data-menu-toggle]');
    var panel = document.querySelector('[data-nav-panel]');
    if (!toggle || !panel) return;

    function closeMenu() {
      panel.classList.remove('is-open');
      toggle.setAttribute('aria-expanded', 'false');
    }

    function openMenu() {
      panel.classList.add('is-open');
      toggle.setAttribute('aria-expanded', 'true');
    }

    toggle.addEventListener('click', function () {
      if (panel.classList.contains('is-open')) {
        closeMenu();
      } else {
        openMenu();
      }
    });

    panel.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', closeMenu);
    });

    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') closeMenu();
    });

    window.addEventListener('resize', function () {
      if (window.innerWidth > 900) closeMenu();
    });
  }

  function setupCurrentYear() {
    document.querySelectorAll('[data-current-year]').forEach(function (node) {
      node.textContent = String(new Date().getFullYear());
    });
  }

  function isSixAppFlutterServiceWorker(registration) {
    var worker = registration.active || registration.waiting || registration.installing;
    if (!worker || !worker.scriptURL) return false;
    try {
      var scriptUrl = new URL(worker.scriptURL);
      var scopeUrl = new URL(registration.scope);
      return scriptUrl.origin === window.location.origin &&
        scopeUrl.origin === window.location.origin &&
        scriptUrl.pathname === '/flutter_service_worker.js' &&
        scopeUrl.pathname === '/';
    } catch (_) {
      return false;
    }
  }

  function isSixAppFlutterCacheName(cacheName) {
    return cacheName === 'flutter-app-cache' ||
      cacheName === 'flutter-temp-cache' ||
      cacheName === 'flutter-app-manifest' ||
      cacheName.indexOf('flutter-app-cache-') === 0 ||
      cacheName.indexOf('flutter-temp-cache-') === 0 ||
      cacheName.indexOf('flutter-app-manifest-') === 0;
  }

  function clearSixAppFlutterCaches() {
    if (!('caches' in window)) return Promise.resolve();
    return caches.keys().then(function (cacheNames) {
      return Promise.all(cacheNames
        .filter(isSixAppFlutterCacheName)
        .map(function (cacheName) { return caches.delete(cacheName); }));
    });
  }

  function cleanupLegacyFlutterWorker() {
    if (!('serviceWorker' in navigator)) return;
    navigator.serviceWorker.getRegistrations()
      .then(function (registrations) {
        return Promise.all(registrations
          .filter(isSixAppFlutterServiceWorker)
          .map(function (registration) { return registration.unregister(); }));
      })
      .then(clearSixAppFlutterCaches)
      .catch(function () {});
  }

  document.documentElement.classList.add('has-js');
  setupCurrentYear();
  setupMobileMenu();
  setupLanguageSwitcher();
  applyLanguage(selectedLanguage());
  cleanupLegacyFlutterWorker();
})();
