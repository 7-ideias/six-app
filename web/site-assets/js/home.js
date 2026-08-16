(function () {
  'use strict';

  var localeStorageKey = 'sixapp.public.locale';

  var dictionary = {
    pt: {
      title: 'SixApp - Gestão em Web, Android e iOS',
      description: 'SixApp organiza vendas, orçamentos, atendimentos técnicos, clientes, equipe e financeiro em uma plataforma para usar na Web, Android e iOS.',
      ogTitle: 'SixApp',
      ogDescription: 'Gestão completa para quem vende produtos e presta serviços técnicos na Web, Android e iOS.',
      twitterTitle: 'SixApp',
      twitterDescription: 'Vendas, orçamentos, atendimentos, equipe e financeiro na Web, Android e iOS.',
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
      'hero.slide.one.eyebrow': 'Gestão simples para comércio e serviços',
      'hero.slide.one.title': 'Venda, atenda e acompanhe em um só lugar',
      'hero.slide.one.lead': 'Produtos, serviços técnicos, clientes e financeiro com clareza e rapidez.',
      'hero.slide.two.eyebrow': 'Web + Android + iOS',
      'hero.slide.two.title': 'Use no computador, no Android e no iPhone',
      'hero.slide.two.lead': 'Venda, atenda, acompanhe clientes e organize a operação também no celular, com experiência pensada para uso real.',
      'hero.slide.three.eyebrow': 'Equipe e crescimento',
      'hero.slide.three.title': 'Mais controle para a equipe. Mais clareza para crescer.',
      'hero.slide.three.lead': 'Defina acessos, acompanhe atividades e tome decisões com informações organizadas.',
      'hero.chips.aria': 'Rotinas principais',
      'hero.chip.sales': 'Vendas',
      'hero.chip.service': 'Serviços técnicos',
      'hero.chip.customers': 'Clientes',
      'hero.chip.finance': 'Financeiro',
      'hero.chip.permissions': 'Permissões',
      'hero.chip.activities': 'Atividades',
      'hero.chip.decisions': 'Decisões',
      'hero.platforms.aria': 'Plataformas do SixApp',
      'hero.management.aria': 'Apoios de gestão',
      'hero.carousel.aria': 'Slides da Home',
      'hero.tabs.aria': 'Destaques do SixApp',
      'hero.prev': 'Slide anterior',
      'hero.next': 'Próximo slide',
      'hero.tab.one': 'Organize a operação',
      'hero.tab.two': 'Use no computador, Android e iOS',
      'hero.tab.three': 'Controle para crescer',
      'preview.aria': 'Prévia Web e mobile do SixApp',
      'preview.workspace': 'Visão geral',
      'preview.status': 'Online',
      'preview.kpi.sales': 'Vendas',
      'preview.kpi.sales.value': 'Hoje',
      'preview.kpi.service': 'Atendimentos',
      'preview.kpi.service.value': 'Fila organizada',
      'preview.kpi.finance': 'Financeiro',
      'preview.kpi.finance.value': 'Visão clara',
      'preview.flow.one.label': 'Orçamento',
      'preview.flow.one.title': 'Aprovado',
      'preview.flow.two.label': 'Serviço',
      'preview.flow.two.title': 'Em execução',
      'preview.flow.three.label': 'Entrega',
      'preview.flow.three.title': 'Comprovante pronto',
      'preview.mobile.title': 'Visão geral',
      'preview.mobile.sales': 'Vendas hoje',
      'preview.mobile.sales.value': 'Em uso',
      'preview.mobile.service': 'Atendimentos',
      'preview.mobile.service.value': '24',
      'preview.mobile.activity.one': 'Orçamento aprovado',
      'preview.mobile.activity.two': 'Serviço em execução',
      'preview.mobile.activity.three': 'Venda realizada',
      'trust.aria': 'Diferenciais do SixApp',
      'trust.allInOne': 'Tudo em um só lugar',
      'trust.allInOne.body': 'Vendas, serviços, clientes e financeiro integrados e organizados.',
      'trust.platforms': 'Web, Android e iOS',
      'trust.platforms.body': 'Use o sistema no computador e também no celular, com experiência pensada para operação real.',
      'trust.team': 'Equipe alinhada',
      'trust.team.body': 'Acesso certo para cada pessoa, com tarefas e responsabilidades.',
      'trust.growth': 'Crescimento com clareza',
      'trust.growth.body': 'Mais controle hoje para construir resultados amanhã.',
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
      'platforms.title': 'Web, Android e iOS de verdade.',
      'platforms.lead': 'A mesma plataforma para operar no navegador e também no celular, com rotinas pensadas para uso real no Android e no iPhone.',
      'platforms.aria': 'Plataformas',
      'platforms.web.body': 'Operação no computador',
      'platforms.android.body': 'Gestão também no celular',
      'platforms.ios.body': 'Continuidade no iPhone',
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
      'faq.four.answer': 'Sim. A experiência contempla Web, Android e iOS, com rotinas para operação real também no mobile.',
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
      'footer.note': 'Produto digital para gestão comercial e operacional.',
      'nav.solutions': 'Dores e soluções',
      'hero.editorial.eyebrow': 'Gestão simples para comércio e serviços',
      'hero.editorial.lineOne': 'Todo o seu negócio',
      'hero.editorial.lineTwo': 'em um sistema',
      'hero.editorial.emphasis': 'simples.',
      'hero.editorial.lead': 'Vendas, produtos, serviços técnicos, clientes e financeiro em uma experiência leve para usar no computador e no celular.',
      'hero.editorial.primary': 'Criar conta',
      'hero.editorial.secondary': 'Ver funcionalidades',
      'hero.proof.aria': 'Diferenciais principais',
      'hero.proof.online': 'Sistema online',
      'hero.proof.multiBusiness': 'Multiempresa',
      'hero.proof.languages': 'Vários idiomas',
      'hero.image.alt': 'Comércio organizado com computador e celular',
      'hero.platform.card.aria': 'Disponível na Web, Android e iOS',
      'hero.platform.card.body': 'A operação completa também no celular',
      'hero.status.label': 'Atendimento',
      'hero.status.value': 'Tudo organizado',
      'marquee.aria': 'Áreas do SixApp',
      'marquee.sales': 'Vendas',
      'marquee.products': 'Produtos',
      'marquee.service': 'Serviços técnicos',
      'marquee.customers': 'Clientes',
      'marquee.finance': 'Financeiro',
      'marquee.reports': 'Relatórios',
      'marquee.mobile': 'Mobile',
      'resources.editorial.title': 'Tudo o que a sua operação precisa.',
      'resources.editorial.lead': 'Recursos conectados, sem excesso de telas e com uma navegação feita para ser entendida rapidamente.',
      'showcase.aria': 'SixApp na rotina',
      'showcase.service.kicker': 'Serviços técnicos',
      'showcase.service.title': 'Cada atendimento com contexto e continuidade.',
      'showcase.service.body': 'Registre informações, evidências e mudanças de status em um fluxo que acompanha o serviço do recebimento à entrega.',
      'showcase.service.pointOne': 'Histórico reunido por cliente e atendimento',
      'showcase.service.pointTwo': 'Status claros para a equipe',
      'showcase.service.pointThree': 'Documentos prontos para compartilhar',
      'showcase.service.stepOne': 'Recebido',
      'showcase.service.stepTwo': 'Em atendimento',
      'showcase.service.stepThree': 'Pronto para entrega',
      'showcase.operation.kicker': 'Operação integrada',
      'showcase.operation.title': 'Produtos, pessoas e financeiro na mesma rotina.',
      'showcase.operation.body': 'O dado cadastrado deixa de ficar isolado e passa a apoiar vendas, serviços, estoque, recebimentos e decisões.',
      'showcase.operation.pointOne': 'Produtos e serviços prontos para uso',
      'showcase.operation.pointTwo': 'Clientes, colaboradores e fornecedores organizados',
      'showcase.operation.pointThree': 'Movimentações com visão financeira',
      'showcase.operation.cardOne': 'Operação do dia',
      'showcase.operation.cardOneValue': 'Visão geral',
      'showcase.operation.cardTwo': 'Estoque',
      'showcase.operation.cardTwoValue': 'Atualizado',
      'showcase.operation.cardThree': 'Equipe',
      'showcase.operation.cardThreeValue': 'Acessos definidos',
      'showcase.platform.kicker': 'Web + Android + iOS',
      'showcase.platform.title': 'O SixApp inteiro acompanha você.',
      'showcase.platform.body': 'Não é apenas um aplicativo de apoio: as rotinas do negócio também podem ser utilizadas no celular, com experiência própria para cada tela.',
      'showcase.platform.pointOne': 'Gestão completa no navegador',
      'showcase.platform.pointTwo': 'Operação prática no Android e no iPhone',
      'showcase.platform.pointThree': 'Informações sincronizadas pela internet',
      'solutions.kicker': 'Dores e soluções',
      'solutions.title': 'Problemas reais da operação, tratados de forma direta.',
      'solutions.lead': 'O SixApp reduz a fragmentação do dia a dia conectando informações que normalmente ficam espalhadas.',
      'solutions.pain.label': 'A dor',
      'solutions.answer.label': 'A solução SixApp',
      'solutions.one.painTitle': 'Informações do atendimento espalhadas',
      'solutions.one.painBody': 'Status, observações e evidências ficam em lugares diferentes, tornando a consulta lenta e aumentando o risco de desencontro.',
      'solutions.one.answerTitle': 'Histórico e status centralizados',
      'solutions.one.answerBody': 'O atendimento mantém contexto, etapas e registros reunidos para facilitar a continuidade do trabalho.',
      'solutions.two.painTitle': 'Equipe sem clareza sobre acessos',
      'solutions.two.painBody': 'Quando todos enxergam ou executam as mesmas ações, responsabilidades e informações sensíveis ficam difíceis de controlar.',
      'solutions.two.answerTitle': 'Permissões por colaborador',
      'solutions.two.answerBody': 'O administrador organiza os acessos de acordo com o papel de cada pessoa e de cada comércio.',
      'solutions.three.painTitle': 'Cadastros que não conversam com a operação',
      'solutions.three.painBody': 'Produtos, serviços e pessoas registrados de forma isolada geram repetição de trabalho durante vendas e atendimentos.',
      'solutions.three.answerTitle': 'Uma base conectada ao uso diário',
      'solutions.three.answerBody': 'Os cadastros apoiam as movimentações e preservam o contexto necessário em cada jornada.',
      'solutions.four.painTitle': 'Decisões financeiras sem visão suficiente',
      'solutions.four.painBody': 'Caixa, recebimentos, compromissos e pendências separados dificultam a leitura do momento do negócio.',
      'solutions.four.answerTitle': 'Financeiro organizado para acompanhar',
      'solutions.four.answerBody': 'Informações importantes ficam reunidas para apoiar conferência, planejamento e tomada de decisão.',
      'solutions.cta.title': 'Organize primeiro. Cresça com clareza.',
      'solutions.cta.body': 'Conheça a experiência do SixApp e veja como ela se encaixa na sua operação.',
      'solutions.cta.button': 'Criar conta',
      'steps.kicker': 'Como funciona',
      'steps.title': 'Começar é simples.',
      'steps.lead': 'A conta evolui junto com a estrutura do seu negócio, da primeira configuração à operação da equipe.',
      'steps.one.title': 'Crie a conta',
      'steps.one.body': 'O administrador inicia o acesso e registra as informações principais.',
      'steps.two.title': 'Organize o comércio',
      'steps.two.body': 'Cadastre produtos, serviços, pessoas e configure os acessos da equipe.',
      'steps.three.title': 'Use onde estiver',
      'steps.three.body': 'Opere pela Web, Android ou iOS com as informações sincronizadas.',
      'plans.editorial.title': 'Um caminho para cada momento do negócio.',
      'plans.editorial.lead': 'Comece pela conta, conheça as opções disponíveis e evolua conforme a sua operação ganhar novas necessidades.',
      'plans.start.kicker': 'Começar',
      'plans.start.title': 'Crie sua conta',
      'plans.start.body': 'Inicie o cadastro e prepare a primeira estrutura do seu comércio.',
      'plans.start.button': 'Criar conta',
      'plans.options.kicker': 'Conhecer opções',
      'plans.options.title': 'Veja os planos disponíveis',
      'plans.options.body': 'Compare as opções do SixApp em uma etapa própria e segura.',
      'plans.options.button': 'Conhecer planos',
      'plans.grow.kicker': 'Evoluir',
      'plans.grow.title': 'Amplie quando precisar',
      'plans.grow.body': 'Adicione organização, pessoas e recursos conforme a operação crescer.',
      'plans.grow.button': 'Rever recursos',
      'final.editorial.title': 'Comece a organizar o seu negócio com o SixApp.',
      'final.editorial.body': 'Crie uma conta ou entre para continuar de onde parou.',
      'footer.solutions': 'Soluções',
      'footer.rights': 'Todos os direitos reservados.'
    },
    en: {
      title: 'SixApp - Management on Web, Android and iOS',
      description: 'SixApp organizes sales, quotes, technical service, customers, teams and finance in a platform for Web, Android and iOS.',
      ogTitle: 'SixApp',
      ogDescription: 'Complete management for businesses that sell products and provide technical services on Web, Android and iOS.',
      twitterTitle: 'SixApp',
      twitterDescription: 'Sales, quotes, service, teams and finance on Web, Android and iOS.',
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
      'hero.slide.one.eyebrow': 'Simple management for commerce and services',
      'hero.slide.one.title': 'Sell, serve and track in one place',
      'hero.slide.one.lead': 'Products, technical services, customers and finance with clarity and speed.',
      'hero.slide.two.eyebrow': 'Web + Android + iOS',
      'hero.slide.two.title': 'Use it on desktop, Android and iPhone',
      'hero.slide.two.lead': 'Sell, serve, track customers and organize operations on mobile too, with an experience designed for real use.',
      'hero.slide.three.eyebrow': 'Team and growth',
      'hero.slide.three.title': 'More control for the team. More clarity to grow.',
      'hero.slide.three.lead': 'Define access, track activities and make decisions with organized information.',
      'hero.chips.aria': 'Main routines',
      'hero.chip.sales': 'Sales',
      'hero.chip.service': 'Technical services',
      'hero.chip.customers': 'Customers',
      'hero.chip.finance': 'Finance',
      'hero.chip.permissions': 'Permissions',
      'hero.chip.activities': 'Activities',
      'hero.chip.decisions': 'Decisions',
      'hero.platforms.aria': 'SixApp platforms',
      'hero.management.aria': 'Management support',
      'hero.carousel.aria': 'Home slides',
      'hero.tabs.aria': 'SixApp highlights',
      'hero.prev': 'Previous slide',
      'hero.next': 'Next slide',
      'hero.tab.one': 'Organize the operation',
      'hero.tab.two': 'Use it on desktop, Android and iOS',
      'hero.tab.three': 'Control to grow',
      'preview.aria': 'SixApp Web and mobile preview',
      'preview.workspace': 'Overview',
      'preview.status': 'Online',
      'preview.kpi.sales': 'Sales',
      'preview.kpi.sales.value': 'Today',
      'preview.kpi.service': 'Service',
      'preview.kpi.service.value': 'Organized queue',
      'preview.kpi.finance': 'Finance',
      'preview.kpi.finance.value': 'Clear view',
      'preview.flow.one.label': 'Quote',
      'preview.flow.one.title': 'Approved',
      'preview.flow.two.label': 'Service',
      'preview.flow.two.title': 'In progress',
      'preview.flow.three.label': 'Delivery',
      'preview.flow.three.title': 'Receipt ready',
      'preview.mobile.title': 'Overview',
      'preview.mobile.sales': 'Sales today',
      'preview.mobile.sales.value': 'In use',
      'preview.mobile.service': 'Service',
      'preview.mobile.service.value': '24',
      'preview.mobile.activity.one': 'Quote approved',
      'preview.mobile.activity.two': 'Service in progress',
      'preview.mobile.activity.three': 'Sale completed',
      'trust.aria': 'SixApp advantages',
      'trust.allInOne': 'Everything in one place',
      'trust.allInOne.body': 'Sales, services, customers and finance integrated and organized.',
      'trust.platforms': 'Web, Android and iOS',
      'trust.platforms.body': 'Use SixApp on desktop and mobile, with an experience designed for real operations.',
      'trust.team': 'Aligned team',
      'trust.team.body': 'The right access for each person, with tasks and responsibilities.',
      'trust.growth': 'Growth with clarity',
      'trust.growth.body': 'More control today to build tomorrow results.',
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
      'platforms.title': 'Web, Android and iOS for real.',
      'platforms.lead': 'The same platform for operating in the browser and on mobile, with routines designed for real use on Android and iPhone.',
      'platforms.aria': 'Platforms',
      'platforms.web.body': 'Desktop operation',
      'platforms.android.body': 'Management on mobile too',
      'platforms.ios.body': 'Continuity on iPhone',
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
      'faq.four.answer': 'Yes. SixApp includes Web, Android and iOS, with routines for real operations on mobile too.',
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
      'footer.note': 'Digital product for commercial and operational management.',
      'nav.solutions': 'Problems and solutions',
      'hero.editorial.eyebrow': 'Simple management for commerce and services',
      'hero.editorial.lineOne': 'Your entire business',
      'hero.editorial.lineTwo': 'in one',
      'hero.editorial.emphasis': 'simple system.',
      'hero.editorial.lead': 'Sales, products, technical services, customers and finance in a lightweight experience for desktop and mobile.',
      'hero.editorial.primary': 'Create account',
      'hero.editorial.secondary': 'Explore features',
      'hero.proof.aria': 'Main advantages',
      'hero.proof.online': 'Online system',
      'hero.proof.multiBusiness': 'Multiple businesses',
      'hero.proof.languages': 'Multiple languages',
      'hero.image.alt': 'Organized business with a desktop computer and mobile phone',
      'hero.platform.card.aria': 'Available on Web, Android and iOS',
      'hero.platform.card.body': 'Complete operations on mobile too',
      'hero.status.label': 'Service',
      'hero.status.value': 'Everything organized',
      'marquee.aria': 'SixApp areas',
      'marquee.sales': 'Sales',
      'marquee.products': 'Products',
      'marquee.service': 'Technical services',
      'marquee.customers': 'Customers',
      'marquee.finance': 'Finance',
      'marquee.reports': 'Reports',
      'marquee.mobile': 'Mobile',
      'resources.editorial.title': 'Everything your operation needs.',
      'resources.editorial.lead': 'Connected features, without excessive screens and with navigation designed to be understood quickly.',
      'showcase.aria': 'SixApp in daily operations',
      'showcase.service.kicker': 'Technical services',
      'showcase.service.title': 'Every service with context and continuity.',
      'showcase.service.body': 'Record information, evidence and status changes in a flow that follows service from intake to delivery.',
      'showcase.service.pointOne': 'History grouped by customer and service',
      'showcase.service.pointTwo': 'Clear statuses for the team',
      'showcase.service.pointThree': 'Documents ready to share',
      'showcase.service.stepOne': 'Received',
      'showcase.service.stepTwo': 'In service',
      'showcase.service.stepThree': 'Ready for delivery',
      'showcase.operation.kicker': 'Integrated operation',
      'showcase.operation.title': 'Products, people and finance in the same routine.',
      'showcase.operation.body': 'Registered data no longer stays isolated and starts supporting sales, services, inventory, receivables and decisions.',
      'showcase.operation.pointOne': 'Products and services ready for use',
      'showcase.operation.pointTwo': 'Customers, collaborators and suppliers organized',
      'showcase.operation.pointThree': 'Transactions with a financial view',
      'showcase.operation.cardOne': 'Daily operation',
      'showcase.operation.cardOneValue': 'Overview',
      'showcase.operation.cardTwo': 'Inventory',
      'showcase.operation.cardTwoValue': 'Updated',
      'showcase.operation.cardThree': 'Team',
      'showcase.operation.cardThreeValue': 'Access defined',
      'showcase.platform.kicker': 'Web + Android + iOS',
      'showcase.platform.title': 'The entire SixApp goes with you.',
      'showcase.platform.body': 'It is more than a support app: business routines can also be used on mobile, with an experience designed for each screen.',
      'showcase.platform.pointOne': 'Complete management in the browser',
      'showcase.platform.pointTwo': 'Practical operations on Android and iPhone',
      'showcase.platform.pointThree': 'Information synchronized over the internet',
      'solutions.kicker': 'Problems and solutions',
      'solutions.title': 'Real operational problems, addressed directly.',
      'solutions.lead': 'SixApp reduces daily fragmentation by connecting information that normally remains scattered.',
      'solutions.pain.label': 'The problem',
      'solutions.answer.label': 'The SixApp solution',
      'solutions.one.painTitle': 'Service information scattered across places',
      'solutions.one.painBody': 'Statuses, notes and evidence stay in different places, slowing searches and increasing the risk of mismatched information.',
      'solutions.one.answerTitle': 'Centralized history and statuses',
      'solutions.one.answerBody': 'Service keeps context, stages and records together to make work continuity easier.',
      'solutions.two.painTitle': 'A team without clarity about access',
      'solutions.two.painBody': 'When everyone sees or performs the same actions, responsibilities and sensitive information become difficult to control.',
      'solutions.two.answerTitle': 'Permissions by collaborator',
      'solutions.two.answerBody': 'The administrator organizes access according to each person role and each business.',
      'solutions.three.painTitle': 'Records disconnected from operations',
      'solutions.three.painBody': 'Products, services and people registered separately create repeated work during sales and service.',
      'solutions.three.answerTitle': 'A base connected to daily use',
      'solutions.three.answerBody': 'Records support transactions and preserve the context required in each journey.',
      'solutions.four.painTitle': 'Financial decisions without enough visibility',
      'solutions.four.painBody': 'Cash, receivables, commitments and pending items kept apart make the business moment harder to understand.',
      'solutions.four.answerTitle': 'Organized finance for follow-up',
      'solutions.four.answerBody': 'Important information is brought together to support review, planning and decision-making.',
      'solutions.cta.title': 'Organize first. Grow with clarity.',
      'solutions.cta.body': 'Explore the SixApp experience and see how it fits your operation.',
      'solutions.cta.button': 'Create account',
      'steps.kicker': 'How it works',
      'steps.title': 'Getting started is simple.',
      'steps.lead': 'The account evolves with your business structure, from the first setup to team operations.',
      'steps.one.title': 'Create the account',
      'steps.one.body': 'The administrator starts access and registers the main information.',
      'steps.two.title': 'Organize the business',
      'steps.two.body': 'Register products, services and people, then configure team access.',
      'steps.three.title': 'Use it wherever you are',
      'steps.three.body': 'Operate on Web, Android or iOS with synchronized information.',
      'plans.editorial.title': 'A path for every stage of the business.',
      'plans.editorial.lead': 'Start with an account, explore the available options and evolve as your operation gains new needs.',
      'plans.start.kicker': 'Start',
      'plans.start.title': 'Create your account',
      'plans.start.body': 'Begin registration and prepare the first structure of your business.',
      'plans.start.button': 'Create account',
      'plans.options.kicker': 'Explore options',
      'plans.options.title': 'See available plans',
      'plans.options.body': 'Compare SixApp options in a dedicated, secure step.',
      'plans.options.button': 'Explore plans',
      'plans.grow.kicker': 'Evolve',
      'plans.grow.title': 'Expand when you need to',
      'plans.grow.body': 'Add organization, people and features as your operation grows.',
      'plans.grow.button': 'Review features',
      'final.editorial.title': 'Start organizing your business with SixApp.',
      'final.editorial.body': 'Create an account or sign in to continue where you left off.',
      'footer.solutions': 'Solutions',
      'footer.rights': 'All rights reserved.'
    },
    es: {
      title: 'SixApp - Gestión en Web, Android e iOS',
      description: 'SixApp organiza ventas, presupuestos, atención técnica, clientes, equipo y finanzas en una plataforma para usar en Web, Android e iOS.',
      ogTitle: 'SixApp',
      ogDescription: 'Gestión completa para quienes venden productos y prestan servicios técnicos en Web, Android e iOS.',
      twitterTitle: 'SixApp',
      twitterDescription: 'Ventas, presupuestos, atención, equipo y finanzas en Web, Android e iOS.',
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
      'hero.slide.one.eyebrow': 'Gestión simple para comercio y servicios',
      'hero.slide.one.title': 'Vende, atiende y acompaña en un solo lugar',
      'hero.slide.one.lead': 'Productos, servicios técnicos, clientes y finanzas con claridad y rapidez.',
      'hero.slide.two.eyebrow': 'Web + Android + iOS',
      'hero.slide.two.title': 'Úsalo en la computadora, Android y iPhone',
      'hero.slide.two.lead': 'Vende, atiende, acompaña clientes y organiza la operación también en el celular, con una experiencia pensada para uso real.',
      'hero.slide.three.eyebrow': 'Equipo y crecimiento',
      'hero.slide.three.title': 'Más control para el equipo. Más claridad para crecer.',
      'hero.slide.three.lead': 'Define accesos, acompaña actividades y toma decisiones con información organizada.',
      'hero.chips.aria': 'Rutinas principales',
      'hero.chip.sales': 'Ventas',
      'hero.chip.service': 'Servicios técnicos',
      'hero.chip.customers': 'Clientes',
      'hero.chip.finance': 'Finanzas',
      'hero.chip.permissions': 'Permisos',
      'hero.chip.activities': 'Actividades',
      'hero.chip.decisions': 'Decisiones',
      'hero.platforms.aria': 'Plataformas de SixApp',
      'hero.management.aria': 'Apoyos de gestión',
      'hero.carousel.aria': 'Slides de la Home',
      'hero.tabs.aria': 'Aspectos destacados de SixApp',
      'hero.prev': 'Slide anterior',
      'hero.next': 'Siguiente slide',
      'hero.tab.one': 'Organiza la operación',
      'hero.tab.two': 'Úsalo en computadora, Android e iOS',
      'hero.tab.three': 'Control para crecer',
      'preview.aria': 'Vista Web y mobile de SixApp',
      'preview.workspace': 'Visión general',
      'preview.status': 'Online',
      'preview.kpi.sales': 'Ventas',
      'preview.kpi.sales.value': 'Hoy',
      'preview.kpi.service': 'Atenciones',
      'preview.kpi.service.value': 'Fila organizada',
      'preview.kpi.finance': 'Finanzas',
      'preview.kpi.finance.value': 'Visión clara',
      'preview.flow.one.label': 'Presupuesto',
      'preview.flow.one.title': 'Aprobado',
      'preview.flow.two.label': 'Servicio',
      'preview.flow.two.title': 'En ejecución',
      'preview.flow.three.label': 'Entrega',
      'preview.flow.three.title': 'Comprobante listo',
      'preview.mobile.title': 'Visión general',
      'preview.mobile.sales': 'Ventas hoy',
      'preview.mobile.sales.value': 'En uso',
      'preview.mobile.service': 'Atenciones',
      'preview.mobile.service.value': '24',
      'preview.mobile.activity.one': 'Presupuesto aprobado',
      'preview.mobile.activity.two': 'Servicio en ejecución',
      'preview.mobile.activity.three': 'Venta realizada',
      'trust.aria': 'Diferenciales de SixApp',
      'trust.allInOne': 'Todo en un solo lugar',
      'trust.allInOne.body': 'Ventas, servicios, clientes y finanzas integrados y organizados.',
      'trust.platforms': 'Web, Android e iOS',
      'trust.platforms.body': 'Usa SixApp en la computadora y también en el celular, con experiencia pensada para operación real.',
      'trust.team': 'Equipo alineado',
      'trust.team.body': 'Acceso correcto para cada persona, con tareas y responsabilidades.',
      'trust.growth': 'Crecimiento con claridad',
      'trust.growth.body': 'Más control hoy para construir resultados mañana.',
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
      'platforms.title': 'Web, Android e iOS de verdad.',
      'platforms.lead': 'La misma plataforma para operar en el navegador y también en el celular, con rutinas pensadas para uso real en Android y iPhone.',
      'platforms.aria': 'Plataformas',
      'platforms.web.body': 'Operación en la computadora',
      'platforms.android.body': 'Gestión también en el celular',
      'platforms.ios.body': 'Continuidad en iPhone',
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
      'faq.four.answer': 'Sí. SixApp contempla Web, Android e iOS, con rutinas para operación real también en mobile.',
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
      'footer.note': 'Producto digital para gestión comercial y operativa.',
      'nav.solutions': 'Problemas y soluciones',
      'hero.editorial.eyebrow': 'Gestión simple para comercios y servicios',
      'hero.editorial.lineOne': 'Todo tu negocio',
      'hero.editorial.lineTwo': 'en un sistema',
      'hero.editorial.emphasis': 'simple.',
      'hero.editorial.lead': 'Ventas, productos, servicios técnicos, clientes y finanzas en una experiencia ligera para usar en la computadora y en el celular.',
      'hero.editorial.primary': 'Crear cuenta',
      'hero.editorial.secondary': 'Ver funcionalidades',
      'hero.proof.aria': 'Diferenciales principales',
      'hero.proof.online': 'Sistema online',
      'hero.proof.multiBusiness': 'Multiempresa',
      'hero.proof.languages': 'Varios idiomas',
      'hero.image.alt': 'Comercio organizado con computadora y celular',
      'hero.platform.card.aria': 'Disponible en Web, Android e iOS',
      'hero.platform.card.body': 'La operación completa también en el celular',
      'hero.status.label': 'Atención',
      'hero.status.value': 'Todo organizado',
      'marquee.aria': 'Áreas de SixApp',
      'marquee.sales': 'Ventas',
      'marquee.products': 'Productos',
      'marquee.service': 'Servicios técnicos',
      'marquee.customers': 'Clientes',
      'marquee.finance': 'Finanzas',
      'marquee.reports': 'Informes',
      'marquee.mobile': 'Mobile',
      'resources.editorial.title': 'Todo lo que tu operación necesita.',
      'resources.editorial.lead': 'Recursos conectados, sin exceso de pantallas y con una navegación pensada para entenderse rápidamente.',
      'showcase.aria': 'SixApp en la rutina',
      'showcase.service.kicker': 'Servicios técnicos',
      'showcase.service.title': 'Cada atención con contexto y continuidad.',
      'showcase.service.body': 'Registra información, evidencias y cambios de estado en un flujo que acompaña el servicio desde la recepción hasta la entrega.',
      'showcase.service.pointOne': 'Historial reunido por cliente y atención',
      'showcase.service.pointTwo': 'Estados claros para el equipo',
      'showcase.service.pointThree': 'Documentos listos para compartir',
      'showcase.service.stepOne': 'Recibido',
      'showcase.service.stepTwo': 'En atención',
      'showcase.service.stepThree': 'Listo para entregar',
      'showcase.operation.kicker': 'Gestión integrada',
      'showcase.operation.title': 'Productos, personas y finanzas en la misma rutina.',
      'showcase.operation.body': 'El dato registrado deja de estar aislado y pasa a apoyar ventas, servicios, inventario, cobros y decisiones.',
      'showcase.operation.pointOne': 'Productos y servicios listos para usar',
      'showcase.operation.pointTwo': 'Clientes, colaboradores y proveedores organizados',
      'showcase.operation.pointThree': 'Movimientos con visión financiera',
      'showcase.operation.cardOne': 'Operación del día',
      'showcase.operation.cardOneValue': 'Visión general',
      'showcase.operation.cardTwo': 'Inventario',
      'showcase.operation.cardTwoValue': 'Actualizado',
      'showcase.operation.cardThree': 'Equipo',
      'showcase.operation.cardThreeValue': 'Accesos definidos',
      'showcase.platform.kicker': 'Web, Android e iOS',
      'showcase.platform.title': 'El SixApp completo te acompaña.',
      'showcase.platform.body': 'No es solo una aplicación de apoyo: las rutinas del negocio también pueden utilizarse en el celular, con una experiencia propia para cada pantalla.',
      'showcase.platform.pointOne': 'Gestión completa en el navegador',
      'showcase.platform.pointTwo': 'Operación práctica en Android y iPhone',
      'showcase.platform.pointThree': 'Sincronización online de la información',
      'solutions.kicker': 'Problemas y soluciones',
      'solutions.title': 'Problemas reales de la operación, tratados de forma directa.',
      'solutions.lead': 'SixApp reduce la fragmentación diaria conectando información que normalmente queda dispersa.',
      'solutions.pain.label': 'El problema',
      'solutions.answer.label': 'La solución SixApp',
      'solutions.one.painTitle': 'Información de la atención dispersa',
      'solutions.one.painBody': 'Estados, observaciones y evidencias quedan en lugares diferentes, haciendo más lenta la consulta y aumentando el riesgo de descoordinación.',
      'solutions.one.answerTitle': 'Historial y estados centralizados',
      'solutions.one.answerBody': 'La atención mantiene contexto, etapas y registros reunidos para facilitar la continuidad del trabajo.',
      'solutions.two.painTitle': 'Equipo sin claridad sobre los accesos',
      'solutions.two.painBody': 'Cuando todos ven o ejecutan las mismas acciones, las responsabilidades y la información sensible se vuelven difíciles de controlar.',
      'solutions.two.answerTitle': 'Permisos por colaborador',
      'solutions.two.answerBody': 'El administrador organiza los accesos de acuerdo con el rol de cada persona y de cada comercio.',
      'solutions.three.painTitle': 'Registros que no conversan con la operación',
      'solutions.three.painBody': 'Productos, servicios y personas registrados de forma aislada generan repetición de trabajo durante ventas y atenciones.',
      'solutions.three.answerTitle': 'Una base conectada al uso diario',
      'solutions.three.answerBody': 'Los registros apoyan los movimientos y preservan el contexto necesario en cada recorrido.',
      'solutions.four.painTitle': 'Decisiones financieras sin visión suficiente',
      'solutions.four.painBody': 'Caja, cobros, compromisos y pendientes separados dificultan la lectura del momento del negocio.',
      'solutions.four.answerTitle': 'Finanzas organizadas para acompañar',
      'solutions.four.answerBody': 'La información importante queda reunida para apoyar la revisión, la planificación y la toma de decisiones.',
      'solutions.cta.title': 'Organiza primero. Crece con claridad.',
      'solutions.cta.body': 'Conoce la experiencia de SixApp y descubre cómo se adapta a tu operación.',
      'solutions.cta.button': 'Crear cuenta',
      'steps.kicker': 'Cómo funciona',
      'steps.title': 'Comenzar es simple.',
      'steps.lead': 'La cuenta evoluciona junto con la estructura de tu negocio, desde la primera configuración hasta la operación del equipo.',
      'steps.one.title': 'Crea la cuenta',
      'steps.one.body': 'El administrador inicia el acceso y registra la información principal.',
      'steps.two.title': 'Organiza el comercio',
      'steps.two.body': 'Registra productos, servicios y personas, y configura los accesos del equipo.',
      'steps.three.title': 'Úsalo donde estés',
      'steps.three.body': 'Opera desde la Web, Android o iOS con la información sincronizada.',
      'plans.editorial.title': 'Un camino para cada momento del negocio.',
      'plans.editorial.lead': 'Comienza por la cuenta, conoce las opciones disponibles y evoluciona cuando tu operación tenga nuevas necesidades.',
      'plans.start.kicker': 'Comenzar',
      'plans.start.title': 'Crea tu cuenta',
      'plans.start.body': 'Inicia el registro y prepara la primera estructura de tu comercio.',
      'plans.start.button': 'Crear cuenta',
      'plans.options.kicker': 'Conocer opciones',
      'plans.options.title': 'Mira los planes disponibles',
      'plans.options.body': 'Compara las opciones de SixApp en una etapa propia y segura.',
      'plans.options.button': 'Conocer planes',
      'plans.grow.kicker': 'Evolucionar',
      'plans.grow.title': 'Amplía cuando lo necesites',
      'plans.grow.body': 'Agrega organización, personas y recursos a medida que crezca la operación.',
      'plans.grow.button': 'Revisar recursos',
      'final.editorial.title': 'Comienza a organizar tu negocio con SixApp.',
      'final.editorial.body': 'Crea una cuenta o entra para continuar desde donde lo dejaste.',
      'footer.solutions': 'Problemas y soluciones',
      'footer.rights': 'Todos los derechos reservados.'
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

  function setupReveal() {
    var nodes = Array.prototype.slice.call(document.querySelectorAll('[data-reveal]'));
    if (!nodes.length) return;

    var reduceMotion = window.matchMedia &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function show(node) {
      node.classList.add('is-visible');
    }

    var immediateNodes = nodes.filter(function (node) {
      var value = node.getAttribute('data-reveal');
      return value === 'hero' || value === 'hero-visual';
    });

    immediateNodes.forEach(function (node, index) {
      if (reduceMotion) {
        show(node);
        return;
      }

      window.setTimeout(function () { show(node); }, 40 + (index * 80));
    });

    var observedNodes = nodes.filter(function (node) {
      return immediateNodes.indexOf(node) === -1;
    });

    if (reduceMotion || !('IntersectionObserver' in window)) {
      observedNodes.forEach(show);
      return;
    }

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        show(entry.target);
        observer.unobserve(entry.target);
      });
    }, {
      threshold: 0.12,
      rootMargin: '0px 0px -6% 0px'
    });

    observedNodes.forEach(function (node, index) {
      node.style.transitionDelay = String(Math.min((index % 3) * 55, 110)) + 'ms';
      observer.observe(node);
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
  setupReveal();
  setupLanguageSwitcher();
  applyLanguage(selectedLanguage());
  cleanupLegacyFlutterWorker();
})();
