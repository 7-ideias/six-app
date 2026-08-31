(function () {
  'use strict';

  var localeStorageKey = 'sixapp.public.locale';
  var dictionary = {
    pt: {
      title: 'Gestão que age, avisa e conecta | SixoApp',
      description: 'Checklist de tarefas, alertas push, agenda financeira, jornadas web para clientes, assinaturas e uma operação integrada no app e na web.',
      ogTitle: 'Nada escapa. Tudo avança. | SixoApp',
      ogDescription: 'Seu negócio não precisa de mais um sistema. Precisa de uma operação que age, avisa e conecta.',
      twitterTitle: 'Nada escapa. Tudo avança. | SixoApp',
      twitterDescription: 'O básico registra. A operação certa faz o próximo passo acontecer.',
      'access.skip': 'Ir para o conteúdo principal',
      'nav.aria': 'Navegação principal',
      'nav.menu': 'Menu',
      'nav.resources': 'Diferenciais',
      'nav.how': 'A jornada',
      'nav.plans': 'Planos',
      'nav.faq': 'FAQ',
      'nav.login': 'Entrar',
      'nav.signup': 'Começar grátis',
      'language.aria': 'Selecionar idioma',
      'hero.eyebrow': 'Gestão que age, avisa e conecta',
      'hero.lineOne': 'Seu negócio não precisa',
      'hero.lineTwo': 'de mais um sistema.',
      'hero.lineThree': 'Precisa fazer o próximo passo acontecer.',
      'hero.lead': 'O básico registra. Aqui, tarefas viram ações, alertas chegam antes, clientes acompanham o serviço e o financeiro mostra o que vem pela frente — no app e na web.',
      'hero.primary': 'Começar grátis',
      'hero.secondary': 'Ver a operação em movimento',
      'hero.proof.aria': 'Diferenciais principais',
      'hero.proof.platforms': 'App + web no mesmo fluxo',
      'hero.proof.links': 'Links web para o cliente',
      'hero.proof.push': 'Controle que chega por push',
      'hero.image.alt': 'Profissional em uma assistência técnica conectado ao cliente e à operação',
      'hero.signal.alert.label': 'Alerta de controle',
      'hero.signal.alert.value': 'Enviado no momento certo',
      'hero.signal.budget.label': 'Orçamento web',
      'hero.signal.budget.value': 'Cliente visualizando',
      'hero.signal.signature.label': 'Documento',
      'hero.signal.signature.value': 'Assinatura concluída',
      'manifest.aria': 'Manifesto da operação',
      'manifest.one': 'Nada fora do radar.',
      'manifest.two': 'Nenhum cliente no escuro.',
      'manifest.three': 'Toda etapa deixando prova.',
      'contrast.kicker': 'A ruptura',
      'contrast.title': 'Registrar é o mínimo. Fazer avançar é o diferencial.',
      'contrast.lead': 'Cadastro, estoque, vendas e relatórios são o ponto de partida. A diferença aparece antes do atraso, durante o serviço e depois da entrega.',
      'contrast.remember.title': 'Lembra',
      'contrast.remember.body': 'O próximo passo deixa de depender da memória.',
      'contrast.warn.title': 'Avisa',
      'contrast.warn.body': 'O controle chega antes que a pendência vire urgência.',
      'contrast.connect.title': 'Conecta',
      'contrast.connect.body': 'O cliente acompanha sem interromper a equipe.',
      'contrast.prove.title': 'Comprova',
      'contrast.prove.body': 'Etiquetas, documentos e feedback fecham o ciclo.',
      'journey.kicker': 'Uma única jornada',
      'journey.title': 'Uma ação movimenta a próxima.',
      'journey.lead': 'Não são ferramentas soltas. É o mesmo atendimento avançando do primeiro contato ao financeiro.',
      'journey.aria': 'Jornada conectada da operação',
      'journey.quote': 'Orçamento web',
      'journey.signature': 'Aceite e assinatura',
      'journey.label': 'Etiqueta e entrada',
      'journey.checklist': 'Checklist e execução',
      'journey.status': 'Push e status',
      'journey.feedback': 'Entrega e feedback',
      'journey.finance': 'Agenda financeira',
      'features.kicker': 'O que muda na prática',
      'features.title': 'Diferenciais que trabalham juntos.',
      'features.lead': 'Explore cinco capítulos de uma operação que lembra, antecipa, conecta, comprova e continua em qualquer tela.',
      'carousel.controls.aria': 'Controles do carrossel',
      'carousel.prev': 'Diferencial anterior',
      'carousel.next': 'Próximo diferencial',
      'carousel.aria': 'Diferenciais do sistema',
      'carousel.tabs.aria': 'Capítulos dos diferenciais',
      'feature.control.tab': 'Controle',
      'feature.control.title': 'Nada importante depende da memória.',
      'feature.control.body': 'Checklists deixam o próximo passo claro. Notificações push levam pendências e acontecimentos relevantes até quem precisa agir.',
      'feature.control.itemOne': 'Checklist de tarefas',
      'feature.control.itemTwo': 'Notificações push de controle',
      'feature.control.alt': 'Bancada técnica organizada por uma sequência de tarefas',
      'feature.control.overlay.label': 'Controle ativo',
      'feature.control.overlay.value': 'Próxima ação sinalizada',
      'feature.finance.tab': 'Antecipação',
      'feature.finance.title': 'O caixa de amanhã aparece hoje.',
      'feature.finance.body': 'Vencimentos, entradas, saídas e compromissos ganham leitura de agenda para você decidir antes, não correr depois.',
      'feature.finance.itemOne': 'Agenda financeira visual',
      'feature.finance.itemTwo': 'Compromissos no tempo certo',
      'feature.finance.alt': 'Agenda financeira visual organizada sobre uma mesa',
      'feature.finance.overlay.label': 'Próximos compromissos',
      'feature.finance.overlay.value': 'Antes da surpresa',
      'feature.client.tab': 'Cliente',
      'feature.client.title': 'Seu cliente não precisa perguntar. Ele acompanha.',
      'feature.client.body': 'O orçamento abre pela web, o status fica disponível on-line e o feedback chega na mesma jornada — sem exigir aplicativo do cliente.',
      'feature.client.itemOne': 'Orçamentos com link web',
      'feature.client.itemTwo': 'Status on-line e feedback web',
      'feature.client.alt': 'Cliente acompanhando pelo celular um serviço realizado na loja',
      'feature.client.overlay.label': 'Link público',
      'feature.client.overlay.value': 'Cliente acompanhando',
      'feature.evidence.tab': 'Evidência',
      'feature.evidence.title': 'Identifique. Formalize. Comprove.',
      'feature.evidence.body': 'Etiquetas levam organização até o item físico. A assinatura registra o combinado e mantém a conclusão dentro do fluxo.',
      'feature.evidence.itemOne': 'Gerador de etiquetas',
      'feature.evidence.itemTwo': 'Assinaturas digitais de documentos',
      'feature.evidence.alt': 'Etiqueta sendo impressa enquanto um documento é assinado em um tablet',
      'feature.evidence.overlay.label': 'Registrado',
      'feature.evidence.overlay.value': 'Etapa comprovada',
      'feature.integration.tab': 'Continuidade',
      'feature.integration.title': 'Uma operação. Toda tela. Nenhuma ruptura.',
      'feature.integration.body': 'Comece no balcão, acompanhe no celular e continue no computador sem transformar cada dispositivo em um sistema diferente.',
      'feature.integration.itemOne': 'App e web integrados',
      'feature.integration.itemTwo': 'Informações sincronizadas',
      'feature.integration.alt': 'Pessoas trabalhando no celular, tablet e computador com a mesma operação',
      'feature.integration.web': 'WEB',
      'feature.integration.app': 'APP',
      'feature.integration.synced': 'CONECTADO',
      'results.kicker': 'O resultado percebido',
      'results.title': 'Mais controle para o dono. Mais clareza para a equipe. Mais confiança para o cliente.',
      'results.owner.kicker': 'Para quem administra',
      'results.owner.title': 'O problema aparece antes de virar urgência.',
      'results.owner.body': 'Alertas, tarefas e agenda financeira mantêm o que importa visível.',
      'results.team.kicker': 'Para quem executa',
      'results.team.title': 'O próximo passo fica claro.',
      'results.team.body': 'Menos improviso, menos retrabalho e uma rotina que conduz a entrega.',
      'results.client.kicker': 'Para quem é atendido',
      'results.client.title': 'A confiança cresce durante o serviço.',
      'results.client.body': 'O cliente consulta, acompanha, assina e responde pela web.',
      'plans.kicker': 'Planos',
      'plans.title': 'Comece simples. Evolua sem trocar de operação.',
      'plans.lead': 'Escolha o ponto de partida e avance conforme novos controles fizerem sentido para o seu negócio.',
      'faq.kicker': 'Sem letras miúdas',
      'faq.title': 'Perguntas antes do próximo passo.',
      'faq.lead': 'Respostas diretas sobre como essa operação chega à equipe e ao cliente.',
      'faq.one.question': 'O cliente precisa instalar o aplicativo?',
      'faq.one.answer': 'Não para as jornadas públicas. Orçamento, acompanhamento, assinatura e feedback podem abrir diretamente no navegador.',
      'faq.two.question': 'App e web usam as mesmas informações?',
      'faq.two.answer': 'Sim. A operação permanece conectada, com experiências próprias para celular e computador.',
      'faq.three.question': 'O sistema funciona sem internet?',
      'faq.three.answer': 'Não. O SixoApp é on-line para manter informações, equipe e jornadas públicas sincronizadas.',
      'faq.four.question': 'Serve apenas para assistência de celular?',
      'faq.four.answer': 'Não. Foi pensado para comércios que vendem produtos, fazem orçamentos e prestam diferentes tipos de serviço técnico.',
      'faq.five.question': 'A assinatura digital substitui o papel?',
      'faq.five.answer': 'Ela formaliza o aceite e mantém o registro vinculado ao documento. A adequação jurídica depende do tipo de documento e das regras do país onde a operação acontece.',
      'final.kicker': 'Nada escapa. Tudo avança.',
      'final.title': 'Você pode continuar juntando ferramentas. Ou fazer toda a operação trabalhar como uma só.',
      'final.body': 'Do primeiro orçamento ao último feedback. Da tarefa interna ao acompanhamento do cliente.',
      'final.primary': 'Quero uma operação que avança',
      'final.secondary': 'Já tenho uma conta',
      'footer.aria': 'Navegação do rodapé',
      'footer.resources': 'Diferenciais',
      'footer.how': 'A jornada',
      'footer.plans': 'Planos',
      'footer.faq': 'FAQ',
      'footer.rights': 'Todos os direitos reservados.'
    },
    en: {
      title: 'Management that acts, alerts, and connects | SixoApp',
      description: 'Task checklists, push alerts, a financial agenda, customer web journeys, signatures, and one connected operation across app and web.',
      ogTitle: 'Nothing slips through. Everything moves forward. | SixoApp',
      ogDescription: 'Your business does not need another system. It needs an operation that acts, alerts, and connects.',
      twitterTitle: 'Nothing slips through. Everything moves forward. | SixoApp',
      twitterDescription: 'The basics record. The right operation makes the next step happen.',
      'access.skip': 'Skip to main content',
      'nav.aria': 'Main navigation',
      'nav.menu': 'Menu',
      'nav.resources': 'Differentiators',
      'nav.how': 'The journey',
      'nav.plans': 'Plans',
      'nav.faq': 'FAQ',
      'nav.login': 'Sign in',
      'nav.signup': 'Start free',
      'language.aria': 'Select language',
      'hero.eyebrow': 'Management that acts, alerts, and connects',
      'hero.lineOne': 'Your business does not need',
      'hero.lineTwo': 'another system.',
      'hero.lineThree': 'It needs to make the next step happen.',
      'hero.lead': 'The basics record. Here, tasks become actions, alerts arrive early, customers follow the service, and finance shows what is ahead — across app and web.',
      'hero.primary': 'Start free',
      'hero.secondary': 'See the operation in motion',
      'hero.proof.aria': 'Key differentiators',
      'hero.proof.platforms': 'App + web in the same flow',
      'hero.proof.links': 'Web links for customers',
      'hero.proof.push': 'Control delivered by push',
      'hero.image.alt': 'Professional at a technical service shop connected to the customer and the operation',
      'hero.signal.alert.label': 'Control alert',
      'hero.signal.alert.value': 'Sent at the right time',
      'hero.signal.budget.label': 'Web quote',
      'hero.signal.budget.value': 'Customer viewing',
      'hero.signal.signature.label': 'Document',
      'hero.signal.signature.value': 'Signature completed',
      'manifest.aria': 'Operational manifesto',
      'manifest.one': 'Nothing off the radar.',
      'manifest.two': 'No customer left in the dark.',
      'manifest.three': 'Every step leaving proof.',
      'contrast.kicker': 'The break',
      'contrast.title': 'Recording is the minimum. Moving forward is the difference.',
      'contrast.lead': 'Records, inventory, sales, and reports are the starting point. The difference appears before a delay, during the service, and after delivery.',
      'contrast.remember.title': 'Remembers',
      'contrast.remember.body': 'The next step no longer depends on memory.',
      'contrast.warn.title': 'Alerts',
      'contrast.warn.body': 'Control arrives before pending work becomes urgent.',
      'contrast.connect.title': 'Connects',
      'contrast.connect.body': 'Customers follow along without interrupting the team.',
      'contrast.prove.title': 'Proves',
      'contrast.prove.body': 'Labels, documents, and feedback close the loop.',
      'journey.kicker': 'One connected journey',
      'journey.title': 'One action moves the next.',
      'journey.lead': 'These are not loose tools. It is the same service moving from first contact to finance.',
      'journey.aria': 'Connected operational journey',
      'journey.quote': 'Web quote',
      'journey.signature': 'Approval and signature',
      'journey.label': 'Label and intake',
      'journey.checklist': 'Checklist and execution',
      'journey.status': 'Push and status',
      'journey.feedback': 'Delivery and feedback',
      'journey.finance': 'Financial agenda',
      'features.kicker': 'What changes in practice',
      'features.title': 'Differentiators that work together.',
      'features.lead': 'Explore five chapters of an operation that remembers, anticipates, connects, proves, and continues on every screen.',
      'carousel.controls.aria': 'Carousel controls',
      'carousel.prev': 'Previous differentiator',
      'carousel.next': 'Next differentiator',
      'carousel.aria': 'System differentiators',
      'carousel.tabs.aria': 'Differentiator chapters',
      'feature.control.tab': 'Control',
      'feature.control.title': 'Nothing important depends on memory.',
      'feature.control.body': 'Checklists make the next step clear. Push notifications take pending work and relevant events to the person who needs to act.',
      'feature.control.itemOne': 'Task checklists',
      'feature.control.itemTwo': 'Push control alerts',
      'feature.control.alt': 'Technical workbench organized as a sequence of tasks',
      'feature.control.overlay.label': 'Active control',
      'feature.control.overlay.value': 'Next action highlighted',
      'feature.finance.tab': 'Foresight',
      'feature.finance.title': 'Tomorrow’s cash position shows up today.',
      'feature.finance.body': 'Due dates, inflows, outflows, and commitments become a visual agenda so you decide early instead of rushing later.',
      'feature.finance.itemOne': 'Visual financial agenda',
      'feature.finance.itemTwo': 'Commitments at the right time',
      'feature.finance.alt': 'Visual financial agenda organized on a desk',
      'feature.finance.overlay.label': 'Upcoming commitments',
      'feature.finance.overlay.value': 'Before the surprise',
      'feature.client.tab': 'Customer',
      'feature.client.title': 'Your customer does not have to ask. They can follow along.',
      'feature.client.body': 'The quote opens on the web, service status stays available online, and feedback arrives in the same journey — no customer app required.',
      'feature.client.itemOne': 'Quotes with a web link',
      'feature.client.itemTwo': 'Online status and web feedback',
      'feature.client.alt': 'Customer tracking on a phone a service performed at the shop',
      'feature.client.overlay.label': 'Public link',
      'feature.client.overlay.value': 'Customer tracking',
      'feature.evidence.tab': 'Proof',
      'feature.evidence.title': 'Identify. Formalize. Prove.',
      'feature.evidence.body': 'Labels carry organization to the physical item. The signature records the agreement and keeps completion in the same flow.',
      'feature.evidence.itemOne': 'Label generator',
      'feature.evidence.itemTwo': 'Digital document signatures',
      'feature.evidence.alt': 'Label printing while a document is signed on a tablet',
      'feature.evidence.overlay.label': 'Recorded',
      'feature.evidence.overlay.value': 'Step verified',
      'feature.integration.tab': 'Continuity',
      'feature.integration.title': 'One operation. Every screen. No disruption.',
      'feature.integration.body': 'Start at the counter, follow on mobile, and continue on desktop without turning every device into a different system.',
      'feature.integration.itemOne': 'Integrated app and web',
      'feature.integration.itemTwo': 'Synchronized information',
      'feature.integration.alt': 'People working on mobile, tablet, and desktop in the same operation',
      'feature.integration.web': 'WEB',
      'feature.integration.app': 'APP',
      'feature.integration.synced': 'CONNECTED',
      'results.kicker': 'The perceived result',
      'results.title': 'More control for the owner. More clarity for the team. More trust for the customer.',
      'results.owner.kicker': 'For the owner',
      'results.owner.title': 'The problem appears before it becomes urgent.',
      'results.owner.body': 'Alerts, tasks, and the financial agenda keep what matters visible.',
      'results.team.kicker': 'For the team',
      'results.team.title': 'The next step is clear.',
      'results.team.body': 'Less improvisation, less rework, and a routine that guides delivery.',
      'results.client.kicker': 'For the customer',
      'results.client.title': 'Trust grows during the service.',
      'results.client.body': 'The customer reviews, tracks, signs, and responds on the web.',
      'plans.kicker': 'Plans',
      'plans.title': 'Start simple. Grow without changing operations.',
      'plans.lead': 'Choose your starting point and advance as new controls make sense for your business.',
      'faq.kicker': 'No fine print',
      'faq.title': 'Questions before the next step.',
      'faq.lead': 'Straight answers about how this operation reaches the team and the customer.',
      'faq.one.question': 'Does the customer need to install the app?',
      'faq.one.answer': 'Not for public journeys. Quotes, tracking, signatures, and feedback can open directly in the browser.',
      'faq.two.question': 'Do app and web use the same information?',
      'faq.two.answer': 'Yes. The operation stays connected, with experiences designed for mobile and desktop.',
      'faq.three.question': 'Does the system work offline?',
      'faq.three.answer': 'No. SixoApp is online to keep information, the team, and public journeys synchronized.',
      'faq.four.question': 'Is it only for phone repair shops?',
      'faq.four.answer': 'No. It is designed for businesses that sell products, create quotes, and deliver different kinds of technical services.',
      'faq.five.question': 'Does the digital signature replace paper?',
      'faq.five.answer': 'It formalizes acceptance and keeps the record linked to the document. Legal suitability depends on the document type and the rules of the country where the operation takes place.',
      'final.kicker': 'Nothing slips through. Everything moves forward.',
      'final.title': 'You can keep stitching tools together. Or make the entire operation work as one.',
      'final.body': 'From the first quote to the final feedback. From the internal task to customer tracking.',
      'final.primary': 'I want an operation that moves forward',
      'final.secondary': 'I already have an account',
      'footer.aria': 'Footer navigation',
      'footer.resources': 'Differentiators',
      'footer.how': 'The journey',
      'footer.plans': 'Plans',
      'footer.faq': 'FAQ',
      'footer.rights': 'All rights reserved.'
    },
    es: {
      title: 'Gestión que actúa, avisa y conecta | SixoApp',
      description: 'Listas de tareas, alertas push, agenda financiera, experiencias web para clientes, firmas y una operación integrada en la app y la web.',
      ogTitle: 'Nada se pierde. Todo avanza. | SixoApp',
      ogDescription: 'Tu negocio no necesita otro sistema. Necesita una operación que actúe, avise y conecte.',
      twitterTitle: 'Nada se pierde. Todo avanza. | SixoApp',
      twitterDescription: 'Lo básico registra. La operación correcta hace que el siguiente paso suceda.',
      'access.skip': 'Ir al contenido principal',
      'nav.aria': 'Navegación principal',
      'nav.menu': 'Menú',
      'nav.resources': 'Diferenciales',
      'nav.how': 'El recorrido',
      'nav.plans': 'Planes',
      'nav.faq': 'FAQ',
      'nav.login': 'Ingresar',
      'nav.signup': 'Empezar gratis',
      'language.aria': 'Seleccionar idioma',
      'hero.eyebrow': 'Gestión que actúa, avisa y conecta',
      'hero.lineOne': 'Tu negocio no necesita',
      'hero.lineTwo': 'otro sistema.',
      'hero.lineThree': 'Necesita hacer que el siguiente paso suceda.',
      'hero.lead': 'Lo básico registra. Aquí, las tareas se convierten en acciones, las alertas llegan antes, los clientes siguen el servicio y las finanzas muestran lo que viene — en la app y en la web.',
      'hero.primary': 'Empezar gratis',
      'hero.secondary': 'Ver la operación en movimiento',
      'hero.proof.aria': 'Diferenciales principales',
      'hero.proof.platforms': 'App + web en el mismo flujo',
      'hero.proof.links': 'Enlaces web para el cliente',
      'hero.proof.push': 'Control que llega por push',
      'hero.image.alt': 'Profesional en un servicio técnico conectado con el cliente y la operación',
      'hero.signal.alert.label': 'Alerta de control',
      'hero.signal.alert.value': 'Enviada en el momento correcto',
      'hero.signal.budget.label': 'Presupuesto web',
      'hero.signal.budget.value': 'Cliente visualizando',
      'hero.signal.signature.label': 'Documento',
      'hero.signal.signature.value': 'Firma completada',
      'manifest.aria': 'Manifiesto de la operación',
      'manifest.one': 'Nada fuera del radar.',
      'manifest.two': 'Ningún cliente a oscuras.',
      'manifest.three': 'Cada etapa dejando evidencia.',
      'contrast.kicker': 'La ruptura',
      'contrast.title': 'Registrar es lo mínimo. Hacer avanzar es la diferencia.',
      'contrast.lead': 'Registros, inventario, ventas e informes son el punto de partida. La diferencia aparece antes del retraso, durante el servicio y después de la entrega.',
      'contrast.remember.title': 'Recuerda',
      'contrast.remember.body': 'El siguiente paso deja de depender de la memoria.',
      'contrast.warn.title': 'Avisa',
      'contrast.warn.body': 'El control llega antes de que lo pendiente sea urgente.',
      'contrast.connect.title': 'Conecta',
      'contrast.connect.body': 'El cliente sigue todo sin interrumpir al equipo.',
      'contrast.prove.title': 'Comprueba',
      'contrast.prove.body': 'Etiquetas, documentos y feedback cierran el ciclo.',
      'journey.kicker': 'Un único recorrido',
      'journey.title': 'Una acción mueve la siguiente.',
      'journey.lead': 'No son herramientas sueltas. Es el mismo servicio avanzando desde el primer contacto hasta las finanzas.',
      'journey.aria': 'Recorrido conectado de la operación',
      'journey.quote': 'Presupuesto web',
      'journey.signature': 'Aceptación y firma',
      'journey.label': 'Etiqueta y recepción',
      'journey.checklist': 'Lista y ejecución',
      'journey.status': 'Push y estado',
      'journey.feedback': 'Entrega y feedback',
      'journey.finance': 'Agenda financiera',
      'features.kicker': 'Lo que cambia en la práctica',
      'features.title': 'Diferenciales que trabajan juntos.',
      'features.lead': 'Explora cinco capítulos de una operación que recuerda, anticipa, conecta, comprueba y continúa en cada pantalla.',
      'carousel.controls.aria': 'Controles del carrusel',
      'carousel.prev': 'Diferencial anterior',
      'carousel.next': 'Siguiente diferencial',
      'carousel.aria': 'Diferenciales del sistema',
      'carousel.tabs.aria': 'Capítulos de los diferenciales',
      'feature.control.tab': 'Control',
      'feature.control.title': 'Nada importante depende de la memoria.',
      'feature.control.body': 'Las listas dejan claro el siguiente paso. Las notificaciones push llevan pendientes y eventos relevantes a quien necesita actuar.',
      'feature.control.itemOne': 'Listas de tareas',
      'feature.control.itemTwo': 'Notificaciones push de control',
      'feature.control.alt': 'Mesa técnica organizada como una secuencia de tareas',
      'feature.control.overlay.label': 'Control activo',
      'feature.control.overlay.value': 'Siguiente acción destacada',
      'feature.finance.tab': 'Anticipación',
      'feature.finance.title': 'El flujo de caja de mañana aparece hoy.',
      'feature.finance.body': 'Vencimientos, entradas, salidas y compromisos se convierten en una agenda visual para decidir antes y no correr después.',
      'feature.finance.itemOne': 'Agenda financiera visual',
      'feature.finance.itemTwo': 'Compromisos en el momento correcto',
      'feature.finance.alt': 'Agenda financiera visual organizada sobre una mesa',
      'feature.finance.overlay.label': 'Próximos compromisos',
      'feature.finance.overlay.value': 'Antes de la sorpresa',
      'feature.client.tab': 'Cliente',
      'feature.client.title': 'Tu cliente no tiene que preguntar. Puede seguir todo.',
      'feature.client.body': 'El presupuesto abre en la web, el estado permanece disponible online y el feedback llega en el mismo recorrido — sin exigir una app al cliente.',
      'feature.client.itemOne': 'Presupuestos con enlace web',
      'feature.client.itemTwo': 'Estado online y feedback web',
      'feature.client.alt': 'Cliente siguiendo desde el celular un servicio realizado en la tienda',
      'feature.client.overlay.label': 'Enlace público',
      'feature.client.overlay.value': 'Cliente siguiendo',
      'feature.evidence.tab': 'Evidencia',
      'feature.evidence.title': 'Identifica. Formaliza. Comprueba.',
      'feature.evidence.body': 'Las etiquetas llevan la organización al artículo físico. La firma registra lo acordado y mantiene el cierre dentro del mismo flujo.',
      'feature.evidence.itemOne': 'Generador de etiquetas',
      'feature.evidence.itemTwo': 'Firmas digitales de documentos',
      'feature.evidence.alt': 'Etiqueta imprimiéndose mientras se firma un documento en una tablet',
      'feature.evidence.overlay.label': 'Registrado',
      'feature.evidence.overlay.value': 'Etapa comprobada',
      'feature.integration.tab': 'Continuidad',
      'feature.integration.title': 'Una operación. Cada pantalla. Sin interrupciones.',
      'feature.integration.body': 'Empieza en el mostrador, sigue en el celular y continúa en la computadora sin convertir cada dispositivo en un sistema diferente.',
      'feature.integration.itemOne': 'App y web integradas',
      'feature.integration.itemTwo': 'Información sincronizada',
      'feature.integration.alt': 'Personas trabajando en celular, tablet y computadora con la misma operación',
      'feature.integration.web': 'WEB',
      'feature.integration.app': 'APP',
      'feature.integration.synced': 'CONECTADO',
      'results.kicker': 'El resultado percibido',
      'results.title': 'Más control para el dueño. Más claridad para el equipo. Más confianza para el cliente.',
      'results.owner.kicker': 'Para quien administra',
      'results.owner.title': 'El problema aparece antes de ser urgente.',
      'results.owner.body': 'Alertas, tareas y agenda financiera mantienen visible lo importante.',
      'results.team.kicker': 'Para quien ejecuta',
      'results.team.title': 'El siguiente paso queda claro.',
      'results.team.body': 'Menos improvisación, menos retrabajo y una rutina que guía la entrega.',
      'results.client.kicker': 'Para quien recibe el servicio',
      'results.client.title': 'La confianza crece durante el servicio.',
      'results.client.body': 'El cliente consulta, sigue, firma y responde por la web.',
      'plans.kicker': 'Planes',
      'plans.title': 'Empieza simple. Evoluciona sin cambiar de operación.',
      'plans.lead': 'Elige el punto de partida y avanza cuando nuevos controles tengan sentido para tu negocio.',
      'faq.kicker': 'Sin letra pequeña',
      'faq.title': 'Preguntas antes del siguiente paso.',
      'faq.lead': 'Respuestas directas sobre cómo esta operación llega al equipo y al cliente.',
      'faq.one.question': '¿El cliente necesita instalar la aplicación?',
      'faq.one.answer': 'No para los recorridos públicos. Presupuestos, seguimiento, firmas y feedback pueden abrir directamente en el navegador.',
      'faq.two.question': '¿La app y la web usan la misma información?',
      'faq.two.answer': 'Sí. La operación permanece conectada, con experiencias diseñadas para celular y computadora.',
      'faq.three.question': '¿El sistema funciona sin internet?',
      'faq.three.answer': 'No. SixoApp es online para mantener sincronizados la información, el equipo y los recorridos públicos.',
      'faq.four.question': '¿Sirve solo para reparación de celulares?',
      'faq.four.answer': 'No. Está pensado para comercios que venden productos, hacen presupuestos y prestan diferentes tipos de servicio técnico.',
      'faq.five.question': '¿La firma digital reemplaza el papel?',
      'faq.five.answer': 'Formaliza la aceptación y mantiene el registro vinculado al documento. Su validez jurídica depende del tipo de documento y de las normas del país donde opera el negocio.',
      'final.kicker': 'Nada se pierde. Todo avanza.',
      'final.title': 'Puedes seguir acumulando herramientas. O hacer que toda la operación trabaje como una sola.',
      'final.body': 'Desde el primer presupuesto hasta el último feedback. Desde la tarea interna hasta el seguimiento del cliente.',
      'final.primary': 'Quiero una operación que avance',
      'final.secondary': 'Ya tengo una cuenta',
      'footer.aria': 'Navegación del pie',
      'footer.resources': 'Diferenciales',
      'footer.how': 'El recorrido',
      'footer.plans': 'Planes',
      'footer.faq': 'FAQ',
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
      if (Object.prototype.hasOwnProperty.call(copy, key)) node.textContent = copy[key];
    });
    document.querySelectorAll('[data-i18n-aria]').forEach(function (node) {
      var key = node.getAttribute('data-i18n-aria');
      if (Object.prototype.hasOwnProperty.call(copy, key)) node.setAttribute('aria-label', copy[key]);
    });
    document.querySelectorAll('[data-i18n-alt]').forEach(function (node) {
      var key = node.getAttribute('data-i18n-alt');
      if (Object.prototype.hasOwnProperty.call(copy, key)) node.setAttribute('alt', copy[key]);
    });
    document.querySelectorAll('[data-lang-option]').forEach(function (button) {
      button.setAttribute('aria-pressed', button.getAttribute('data-lang-option') === normalized ? 'true' : 'false');
    });

    storeLocale(normalized);
    if (window.sixappImpactCarousel) window.sixappImpactCarousel.refresh();
    window.dispatchEvent(new CustomEvent('sixapp:locale-changed', {
      detail: { language: normalized }
    }));
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

    function closeMenu(restoreFocus) {
      var wasOpen = panel.classList.contains('is-open');
      panel.classList.remove('is-open');
      toggle.setAttribute('aria-expanded', 'false');
      if (restoreFocus && wasOpen) toggle.focus();
    }

    toggle.addEventListener('click', function () {
      var open = panel.classList.toggle('is-open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    panel.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () { closeMenu(false); });
    });
    document.addEventListener('keydown', function (event) {
      if (event.key !== 'Escape' || !panel.classList.contains('is-open')) return;
      event.preventDefault();
      closeMenu(true);
    });
    window.addEventListener('resize', function () {
      if (window.innerWidth > 900) closeMenu(false);
    });
  }

  function setupHeader() {
    var header = document.querySelector('[data-header]');
    if (!header) return;
    var update = function () {
      header.classList.toggle('is-scrolled', window.scrollY > 18);
    };
    update();
    window.addEventListener('scroll', update, { passive: true });
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
      } else {
        window.setTimeout(function () { show(node); }, 50 + (index * 90));
      }
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
    }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });
    observedNodes.forEach(function (node, index) {
      node.style.transitionDelay = String(Math.min((index % 3) * 55, 110)) + 'ms';
      observer.observe(node);
    });
  }

  function setupCarousel() {
    var root = document.querySelector('[data-impact-carousel]');
    if (!root) return;
    var tabs = Array.prototype.slice.call(root.querySelectorAll('[data-carousel-tab]'));
    var slides = Array.prototype.slice.call(root.querySelectorAll('[data-carousel-slide]'));
    var previous = document.querySelector('[data-carousel-prev]');
    var next = document.querySelector('[data-carousel-next]');
    var current = document.querySelector('[data-carousel-current]');
    var live = root.querySelector('[data-carousel-live]');
    var viewport = root.querySelector('[data-carousel-viewport]');
    var tabList = root.querySelector('[role="tablist"]');
    var index = 0;
    var touchStartX = null;
    var reduceMotion = window.matchMedia &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function wrap(value) {
      return (value + slides.length) % slides.length;
    }

    function announce() {
      if (!live) return;
      var heading = slides[index].querySelector('h3');
      live.textContent = String(index + 1) + ' / ' + String(slides.length) + ' — ' +
        (heading ? heading.textContent : '');
    }

    function scrollActiveTab() {
      if (!tabList || !tabs[index]) return;
      var target = tabs[index];
      var left = target.offsetLeft - ((tabList.clientWidth - target.offsetWidth) / 2);
      tabList.scrollTo({
        left: Math.max(0, left),
        behavior: reduceMotion ? 'auto' : 'smooth'
      });
    }

    function activate(nextIndex, options) {
      options = options || {};
      index = wrap(nextIndex);
      tabs.forEach(function (tab, tabIndex) {
        var active = tabIndex === index;
        tab.classList.toggle('is-active', active);
        tab.setAttribute('aria-selected', active ? 'true' : 'false');
        tab.setAttribute('tabindex', active ? '0' : '-1');
      });
      slides.forEach(function (slide, slideIndex) {
        var active = slideIndex === index;
        slide.classList.toggle('is-active', active);
        slide.hidden = !active;
        slide.setAttribute('aria-hidden', active ? 'false' : 'true');
        if ('inert' in slide) slide.inert = !active;
      });
      if (current) current.textContent = String(index + 1).padStart(2, '0');
      if (options.focusTab) tabs[index].focus();
      if (options.scrollTab !== false) scrollActiveTab();
      if (options.announce !== false) announce();
    }

    tabs.forEach(function (tab, tabIndex) {
      tab.addEventListener('click', function () {
        activate(tabIndex);
      });
      tab.addEventListener('keydown', function (event) {
        var target = null;
        if (event.key === 'ArrowRight') target = index + 1;
        if (event.key === 'ArrowLeft') target = index - 1;
        if (event.key === 'Home') target = 0;
        if (event.key === 'End') target = slides.length - 1;
        if (target === null) return;
        event.preventDefault();
        activate(target, { focusTab: true });
      });
    });
    if (previous) previous.addEventListener('click', function () { activate(index - 1); });
    if (next) next.addEventListener('click', function () { activate(index + 1); });
    if (viewport) {
      viewport.addEventListener('touchstart', function (event) {
        touchStartX = event.changedTouches[0].clientX;
      }, { passive: true });
      viewport.addEventListener('touchend', function (event) {
        if (touchStartX === null) return;
        var distance = event.changedTouches[0].clientX - touchStartX;
        touchStartX = null;
        if (Math.abs(distance) < 54) return;
        activate(index + (distance < 0 ? 1 : -1));
      }, { passive: true });
    }

    window.sixappImpactCarousel = {
      refresh: function () { announce(); }
    };
    activate(0, { announce: false, scrollTab: false });
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
  setupHeader();
  setupReveal();
  setupCarousel();
  setupLanguageSwitcher();
  applyLanguage(selectedLanguage());
  cleanupLegacyFlutterWorker();
})();
