import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/locale_settings_provider.dart';

/// Textos de domínio do perfil. Códigos persistidos nunca são traduzidos.
String perfilNegocioText(BuildContext context, String key) {
  final String language =
      context.read<LocaleSettingsProvider>().currentLocale.languageCode;
  final int index = language == 'en' ? 1 : language == 'es' ? 2 : 0;
  return (_texts[key] ?? _texts['unknown']!)[index];
}

const Map<String, List<String>> _texts = <String, List<String>>{
  'profile': <String>['Perfil do negócio', 'Business profile', 'Perfil del negocio'],
  'description': <String>[
    'Uma experiência com a cara da sua empresa.',
    'An experience that fits your business.',
    'Una experiencia para tu negocio.'
  ],
  'notice': <String>[
    'Estas respostas personalizam a Home. Não alteram permissões nem habilitam funcionalidades.',
    'These answers personalize Home. They do not change permissions or enable features.',
    'Estas respuestas personalizan el inicio. No cambian permisos ni habilitan funciones.'
  ],
  'segmentTitle': <String>[
    'Qual é o ramo do seu negócio?',
    'What is your business sector?',
    '¿Cuál es el sector de tu negocio?'
  ],
  'segmentSubtitle': <String>[
    'Escolha o principal. As atividades podem ser variadas.',
    'Choose the main sector. Your activities can be varied.',
    'Elige el principal. Tus actividades pueden ser variadas.'
  ],
  'subsegment': <String>['Especialidade (opcional)', 'Specialty (optional)', 'Especialidad (opcional)'],
  'noSpecialty': <String>['Sem especialidade definida', 'No specific specialty', 'Sin especialidad definida'],
  'otherDescription': <String>[
    'Descreva seu negócio (opcional)',
    'Describe your business (optional)',
    'Describe tu negocio (opcional)'
  ],
  'activityTitle': <String>[
    'O que sua empresa faz?',
    'What does your business do?',
    '¿Qué hace tu negocio?'
  ],
  'activitySubtitle': <String>[
    'Marque todas as atividades que fazem parte do seu dia a dia.',
    'Select all activities that are part of your day.',
    'Selecciona todas las actividades de tu día a día.'
  ],
  'goalTitle': <String>[
    'Por onde você quer começar?',
    'Where would you like to start?',
    '¿Por dónde quieres empezar?'
  ],
  'goalSubtitle': <String>[
    'Escolha sua prioridade. Você poderá mudar depois.',
    'Choose your priority. You can change it later.',
    'Elige tu prioridad. Puedes cambiarla después.'
  ],
  'configure': <String>['Personalizar meu negócio', 'Personalize my business', 'Personalizar mi negocio'],
  'edit': <String>['Editar perfil', 'Edit profile', 'Editar perfil'],
  'homeTitle': <String>['Para o seu negócio', 'For your business', 'Para tu negocio'],
  'invite': <String>[
    'Conte um pouco sobre sua empresa para personalizar este espaço.',
    'Tell us about your business to personalize this space.',
    'Cuéntanos sobre tu negocio para personalizar este espacio.'
  ],
  'continue': <String>['Continuar', 'Continue', 'Continuar'],
  'back': <String>['Voltar', 'Back', 'Volver'],
  'cancel': <String>['Cancelar', 'Cancel', 'Cancelar'],
  'save': <String>['Salvar perfil', 'Save profile', 'Guardar perfil'],
  'use': <String>['Usar este perfil', 'Use this profile', 'Usar este perfil'],
  'retry': <String>['Tentar novamente', 'Try again', 'Intentar de nuevo'],
  'reload': <String>['Recarregar perfil', 'Reload profile', 'Recargar perfil'],
  'saving': <String>['Salvando…', 'Saving…', 'Guardando…'],
  'loading': <String>['Carregando seu perfil…', 'Loading your profile…', 'Cargando tu perfil…'],
  'ready': <String>[
    'Perfil selecionado. Confirme para concluir a configuração.',
    'Profile selected. Confirm to finish setup.',
    'Perfil seleccionado. Confirma para terminar la configuración.'
  ],
  'confirmTitle': <String>['Salvar alterações?', 'Save changes?', '¿Guardar cambios?'],
  'confirmBody': <String>[
    'As imagens e sugestões da Home desta empresa serão atualizadas. Seus registros e permissões serão mantidos.',
    'Home images and suggestions for this business will be updated. Your records and permissions will be preserved.',
    'Se actualizarán las imágenes y sugerencias de inicio de este negocio. Se conservarán tus registros y permisos.'
  ],
  'segmentRequired': <String>['Escolha um ramo de negócio.', 'Choose a business sector.', 'Elige un sector.'],
  'descriptionTooLong': <String>['Use até 120 caracteres.', 'Use up to 120 characters.', 'Usa hasta 120 caracteres.'],
  'activityRequired': <String>[
    'Selecione venda de produtos ou prestação de serviços.',
    'Select product sales or services.',
    'Selecciona venta de productos o prestación de servicios.'
  ],
  'goalRequired': <String>['Escolha uma prioridade.', 'Choose a priority.', 'Elige una prioridad.'],
  'review': <String>[
    'Revise o ramo, as atividades e a prioridade.',
    'Review the sector, activities and priority.',
    'Revisa el sector, las actividades y la prioridad.'
  ],
  'forbidden': <String>[
    'Você não tem permissão para editar o perfil desta empresa.',
    'You do not have permission to edit this business profile.',
    'No tienes permiso para editar el perfil de este negocio.'
  ],
  'companyChanged': <String>[
    'A empresa selecionada mudou. Feche esta tela e abra o perfil da empresa atual.',
    'The selected business changed. Close this screen and open the current business profile.',
    'Cambió el negocio seleccionado. Cierra esta pantalla y abre el perfil actual.'
  ],
  'conflict': <String>[
    'O perfil foi alterado em outro acesso. Recarregue antes de salvar novamente.',
    'The profile changed in another session. Reload before saving again.',
    'El perfil cambió en otra sesión. Recarga antes de guardar de nuevo.'
  ],
  'loadError': <String>[
    'Não foi possível concluir. Verifique sua conexão e tente novamente.',
    'Unable to complete. Check your connection and try again.',
    'No se pudo completar. Revisa tu conexión e inténtalo de nuevo.'
  ],
  'unknown': <String>['Outro', 'Other', 'Otro'],
  'segment.ELETRONICOS': <String>['Eletrônicos e acessórios', 'Electronics and accessories', 'Electrónica y accesorios'],
  'segment.INFORMATICA': <String>['Informática', 'Computers and IT', 'Informática'],
  'segment.MODA': <String>['Roupas, moda e costura', 'Clothing, fashion and tailoring', 'Ropa, moda y costura'],
  'segment.AUTOMOTIVO': <String>['Automotivo', 'Automotive', 'Automoción'],
  'segment.CASA_CONSTRUCAO': <String>['Casa e construção', 'Home and construction', 'Hogar y construcción'],
  'segment.BELEZA_ESTETICA': <String>['Beleza e estética', 'Beauty and aesthetics', 'Belleza y estética'],
  'segment.LIMPEZA': <String>['Produtos e serviços de limpeza', 'Cleaning products and services', 'Productos y servicios de limpieza'],
  'segment.ALIMENTACAO': <String>['Alimentação', 'Food', 'Alimentación'],
  'segment.SERVICOS_PROFISSIONAIS': <String>['Serviços profissionais', 'Professional services', 'Servicios profesionales'],
  'segment.OUTRO': <String>['Outro tipo de negócio', 'Another type of business', 'Otro tipo de negocio'],
  'sub.CELULARES': <String>['Celulares', 'Mobile phones', 'Teléfonos móviles'],
  'sub.TV_AUDIO': <String>['TV e áudio', 'TV and audio', 'TV y audio'],
  'sub.ELETRODOMESTICOS': <String>['Eletrodomésticos', 'Home appliances', 'Electrodomésticos'],
  'sub.ACESSORIOS': <String>['Acessórios', 'Accessories', 'Accesorios'],
  'sub.COMPUTADORES': <String>['Computadores', 'Computers', 'Computadoras'],
  'sub.IMPRESSORAS': <String>['Impressoras', 'Printers', 'Impresoras'],
  'sub.REDES': <String>['Redes', 'Networks', 'Redes'],
  'sub.ROUPAS': <String>['Roupas', 'Clothing', 'Ropa'],
  'sub.CALCADOS': <String>['Calçados', 'Footwear', 'Calzado'],
  'sub.COSTURA_AJUSTES': <String>['Costura e ajustes', 'Tailoring and alterations', 'Costura y arreglos'],
  'sub.CARROS': <String>['Carros', 'Cars', 'Coches'],
  'sub.MOTOS': <String>['Motos', 'Motorcycles', 'Motos'],
  'sub.PECAS': <String>['Peças e acessórios', 'Parts and accessories', 'Piezas y accesorios'],
  'sub.MATERIAIS': <String>['Materiais de construção', 'Building materials', 'Materiales de construcción'],
  'sub.MOVEIS': <String>['Móveis', 'Furniture', 'Muebles'],
  'sub.MANUTENCAO_PREDIAL': <String>['Manutenção predial', 'Building maintenance', 'Mantenimiento de edificios'],
  'sub.SALAO': <String>['Salão', 'Salon', 'Salón'],
  'sub.ESTETICA': <String>['Estética', 'Aesthetics', 'Estética'],
  'sub.COSMETICOS': <String>['Cosméticos', 'Cosmetics', 'Cosméticos'],
  'sub.PRODUTOS_LIMPEZA': <String>['Produtos de limpeza', 'Cleaning products', 'Productos de limpieza'],
  'sub.SERVICOS_LIMPEZA': <String>['Serviços de limpeza', 'Cleaning services', 'Servicios de limpieza'],
  'activity.VENDA_PRODUTOS': <String>['Vende produtos', 'Sells products', 'Vende productos'],
  'activity.PRESTACAO_SERVICOS': <String>['Presta serviços', 'Provides services', 'Presta servicios'],
  'activity.REPAROS_MANUTENCAO': <String>['Faz reparos ou manutenção', 'Provides repairs or maintenance', 'Realiza reparaciones o mantenimiento'],
  'activity.ORCAMENTOS': <String>['Faz orçamentos', 'Prepares quotes', 'Prepara presupuestos'],
  'activity.ORDEM_SERVICO': <String>['Trabalha com ordens de serviço', 'Uses work orders', 'Trabaja con órdenes de servicio'],
  'activity.AGENDAMENTO': <String>['Atende com agendamento', 'Works by appointment', 'Atiende con cita previa'],
  'activity.ESTOQUE': <String>['Controla estoque', 'Manages inventory', 'Controla existencias'],
  'goal.VENDAS': <String>['Controlar vendas', 'Manage sales', 'Gestionar ventas'],
  'goal.SERVICOS': <String>['Organizar serviços e reparos', 'Organize services and repairs', 'Organizar servicios y reparaciones'],
  'goal.FINANCEIRO': <String>['Organizar o financeiro', 'Organize finances', 'Organizar las finanzas'],
  'goal.ESTOQUE': <String>['Controlar estoque', 'Manage inventory', 'Controlar existencias'],
  'goal.CLIENTES': <String>['Organizar clientes', 'Organize customers', 'Organizar clientes'],
  'goal.GERAL': <String>['Conhecer o SixApp', 'Explore SixApp', 'Conocer SixApp'],
  'banner.VENDAS.title': <String>['Vendas organizadas', 'Organized sales', 'Ventas organizadas'],
  'banner.VENDAS.subtitle': <String>['Do balcão ao acompanhamento dos seus clientes.', 'From the counter to customer follow-up.', 'Del mostrador al seguimiento de tus clientes.'],
  'banner.SERVICOS.title': <String>['Cada serviço no seu lugar', 'Every service organized', 'Cada servicio en su lugar'],
  'banner.SERVICOS.subtitle': <String>['Uma visão clara do que sua empresa entrega.', 'A clear view of what your business delivers.', 'Una visión clara de lo que entrega tu negocio.'],
  'banner.REPAROS.title': <String>['Acompanhe cada reparo', 'Track every repair', 'Sigue cada reparación'],
  'banner.REPAROS.subtitle': <String>['Do recebimento à entrega, com organização.', 'Organized from intake to handover.', 'Del ingreso a la entrega, con organización.'],
  'banner.ORCAMENTOS.title': <String>['Orçamentos com clareza', 'Clear quotes', 'Presupuestos claros'],
  'banner.ORCAMENTOS.subtitle': <String>['Apresente produtos e serviços aos seus clientes.', 'Present products and services to customers.', 'Presenta productos y servicios a tus clientes.'],
  'banner.ESTOQUE.title': <String>['Estoque sob controle', 'Inventory under control', 'Existencias bajo control'],
  'banner.ESTOQUE.subtitle': <String>['Organize os produtos que movimentam seu negócio.', 'Organize the products that drive your business.', 'Organiza los productos que mueven tu negocio.'],
  'banner.FINANCEIRO.title': <String>['Mais clareza no financeiro', 'Clearer finances', 'Más claridad financiera'],
  'banner.FINANCEIRO.subtitle': <String>['Acompanhe entradas, saídas e compromissos.', 'Keep track of income, expenses and commitments.', 'Acompaña ingresos, gastos y compromisos.'],
  'banner.CLIENTES.title': <String>['Clientes mais próximos', 'Closer to your customers', 'Clientes más cerca'],
  'banner.CLIENTES.subtitle': <String>['Organize contatos e valorize cada atendimento.', 'Organize contacts and value every interaction.', 'Organiza contactos y valora cada atención.'],
  'banner.COMUNICACAO.title': <String>['Mantenha seu cliente informado', 'Keep customers informed', 'Mantén informado a tu cliente'],
  'banner.COMUNICACAO.subtitle': <String>['A comunicação também faz parte de um bom serviço.', 'Communication is part of good service.', 'La comunicación también forma parte de un buen servicio.'],
};
