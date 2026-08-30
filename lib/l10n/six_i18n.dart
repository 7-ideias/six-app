import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'web_i18n_store.dart';

/// Normaliza aliases históricos encontrados em pacotes de tradução antigos.
///
/// A regra atua somente sobre textos de interface já classificados como i18n;
/// identificadores técnicos como `SixBack`, `sixappback.com` e chaves de API
/// permanecem inalterados.
String normalizeSixoAppBranding(String value) {
  String normalized = value;
  final List<RegExp> legacyAliases = <RegExp>[
    RegExp(r'\bAppplanilha\b', caseSensitive: false),
    RegExp(r'\bSix\s+POS\b', caseSensitive: false),
    RegExp(r'\bSix\s+ERP\b', caseSensitive: false),
    RegExp(r'\bSix\s+App\b', caseSensitive: false),
    RegExp(r'\bSixApp\b', caseSensitive: false),
  ];

  for (final RegExp alias in legacyAliases) {
    normalized = normalized.replaceAll(alias, 'SixoApp');
  }
  return normalized.replaceAllMapped(
    RegExp(r'(^|[^A-Za-z0-9_-])Six(?=$|[^A-Za-z0-9_-])'),
    (Match match) => '${match.group(1) ?? ''}SixoApp',
  );
}

extension SixI18nBuildContext on BuildContext {
  /// Resolve textos do SixoApp a partir do pacote de traduções carregado do
  /// backend.
  ///
  /// Uso preferencial em telas web, Android e iOS:
  /// `context.t('common.save')`.
  ///
  /// [fallback] deve ser usado apenas como proteção mínima durante migração ou
  /// quando o endpoint de i18n ainda não trouxe a chave.
  String t(String key, {String? fallback}) {
    final code = _sixCurrentLanguageCode();
    final value = SixI18nStore.instance.string(code, key);
    if (value != null && value.isNotEmpty) {
      return normalizeSixoAppBranding(value);
    }

    final resolvedFallback =
        fallback ?? _fallbacks[code]?[key] ?? _fallbacks['pt']?[key];
    if (resolvedFallback != null && resolvedFallback.isNotEmpty) {
      if (kDebugMode) {
        // debugPrint(
        //   '[i18n] chave ausente: $key para idioma=$code. Usando fallback.',
        // );
      }
      return normalizeSixoAppBranding(resolvedFallback);
    }

    if (kDebugMode) {
      debugPrint('[i18n] chave ausente: $key para idioma=$code.');
    }
    return key;
  }

  String _sixCurrentLanguageCode() {
    try {
      return Localizations.localeOf(this).languageCode;
    } catch (_) {
      return 'pt';
    }
  }
}

const Map<String, Map<String, String>> _fallbacks = {
  'pt': {
    'produto.journey.changeMode': 'Alterar',
    'clientes.journey.title': 'Escolha a jornada de cadastro',
    'clientes.journey.subtitle':
        'Você pode salvar só o essencial ou enriquecer o cadastro agora.',
    'clientes.journey.simpleTitle': 'Cadastro simples',
    'clientes.journey.simpleSubtitle':
        'Nome, documento, telefone e e-mail para cadastrar sem atrito.',
    'clientes.journey.completeTitle': 'Cadastro completo',
    'clientes.journey.completeSubtitle':
        'Endereço, crédito e contexto para uma operação mais preparada.',
    'clientes.journey.stepEssential': 'Essenciais',
    'clientes.journey.stepAddress': 'Endereço',
    'clientes.journey.stepRelationship': 'Crédito e relacionamento',
    'clientes.journey.step': 'Etapa',
    'clientes.journey.of': 'de',
    'clientes.journey.reviewBeforeSave': 'Revise os dados antes de salvar.',
    'clientes.journey.continueHint': 'Avance quando esta etapa estiver pronta.',
    'clientes.quality.title': 'Qualidade do cadastro',
    'clientes.quality.levelInitial': 'Começando agora',
    'clientes.quality.levelEssential': 'Base essencial pronta',
    'clientes.quality.levelDetailed': 'Cadastro bem detalhado',
    'clientes.quality.levelExcellent': 'Cadastro excelente',
    'clientes.quality.actionName': 'informar nome',
    'clientes.quality.actionDocument': 'informar documento',
    'clientes.quality.actionPhone': 'informar telefone',
    'clientes.quality.actionEmail': 'informar e-mail',
    'clientes.quality.actionZip': 'informar CEP',
    'clientes.quality.actionAddress': 'completar endereço',
    'clientes.quality.actionCredit': 'configurar crédito',
    'clientes.quality.actionNotes': 'adicionar contexto',
    'clientes.form.invalidEmail': 'Informe um e-mail válido',
    'produto.quality.title': 'Qualidade do cadastro',
    'produto.quality.levelEssential': 'Essencial',
    'produto.quality.levelReady': 'Pronto para vender',
    'produto.quality.levelPrepared': 'Bem preparado',
    'produto.quality.levelExcellent': 'Excelente',
    'produto.quality.nextActions':
        'Próximas melhorias que aumentam a qualidade:',
    'produto.quality.completeMessage':
        'Cadastro bem preparado para este nível.',
    'produto.quality.actionName': 'Informar nome',
    'produto.quality.actionPrice': 'Adicionar preço',
    'produto.quality.actionCategory': 'Escolher categoria',
    'produto.quality.actionIdentifier': 'Adicionar código',
    'produto.quality.actionOrganization': 'Informar grupo',
    'produto.quality.actionStock': 'Configurar estoque',
    'produto.quality.actionImage': 'Adicionar imagem',
    'produto.quality.actionDetails': 'Completar detalhes',
    'produto.quality.actionRules': 'Revisar regras',
    'produto.quality.actionFiscal': 'Informar dados fiscais',
    'app.title': 'SixoApp',
    'common.save': 'Salvar',
    'common.cancel': 'Cancelar',
    'common.back': 'Voltar',
    'common.close': 'Fechar',
    'common.edit': 'Editar',
    'common.delet\u0065': 'Excluir',
    'common.search': 'Buscar',
    'common.clear': 'Limpar',
    'common.confirm': 'Confirmar',
    'common.apply': 'Aplicar',
    'common.continue': 'Continuar',
    'common.tryAgain': 'Tentar novamente',
    'common.loading': 'Carregando...',
    'common.noResults': 'Nenhum resultado encontrado',
    'common.unexpectedError': 'Erro inesperado',
    'common.unableToLoad': 'Não foi possível carregar.',
    'common.savedSuccessfully': 'Configurações salvas com sucesso.',
    'common.yes': 'Sim',
    'common.no': 'Não',
    'common.active': 'Ativo',
    'common.inactive': 'Inativo',
    'common.online': 'Online',
    'common.offline': 'Offline',
    'common.required': 'Obrigatório',
    'common.optional': 'Opcional',
    'common.soon': 'Em breve',
    'common.refresh': 'Atualizar',
    'common.copy': 'Copiar',
    'common.share': 'Compartilhar',
    'common.number': 'Número',
    'common.all': 'Todos',
    'common.customer': 'Cliente',
    'common.updatedAt': 'Atualizado em',
    'common.lastUpdatedAt': 'Última atualização às',
    'common.notInformed': 'Não informada',
    'pdv.quantityEditor.title': 'Editar quantidade',
    'pdv.quantityEditor.tooltip': 'Editar quantidade',
    'pdv.quantityEditor.subtitle':
        'Revise o item e aplique a nova quantidade. O subtotal e o total da venda serão recalculados imediatamente.',
    'pdv.quantityEditor.codeLabel': 'Código',
    'pdv.quantityEditor.currentLabel': 'Quantidade atual',
    'pdv.quantityEditor.currentHint':
        'Ajuste fino continua disponível nos botões laterais.',
    'pdv.quantityEditor.fieldLabel': 'Nova quantidade',
    'pdv.quantityEditor.hint': 'Digite a quantidade desejada para este item.',
    'pdv.quantityEditor.invalid':
        'Informe uma quantidade inteira maior que zero.',
    'pdv.quantityEditor.effectHint':
        'A alteração atualiza o subtotal do item e o total da venda imediatamente.',
    'pdv.quantityEditor.confirm': 'Aplicar quantidade',
    'pdv.quantityEditor.processing': 'Aplicando quantidade...',
    'pdv.quantityEditor.successTitle': 'Quantidade atualizada',
    'pdv.quantityEditor.successMessage':
        'O item foi recalculado e a venda já reflete a nova quantidade.',
    'pdv.quantityEditor.error':
        'Não foi possível atualizar a quantidade agora. Tente novamente em alguns instantes.',
    'pdv.clearSale.dialogBarrier': 'Confirmar limpeza da venda atual',
    'pdv.clearSale.dialogTitle': 'Limpar venda atual?',
    'pdv.clearSale.dialogSubtitle':
        'Revise o resumo antes de limpar. O atendimento atual será reiniciado para abrir uma nova venda.',
    'pdv.clearSale.summaryItems': 'Itens',
    'pdv.clearSale.summaryTotal': 'Total',
    'pdv.clearSale.summaryCustomer': 'Cliente',
    'pdv.clearSale.confirmAction': 'Limpar venda',
    'pdv.clearSale.impactHint':
        'Itens, cliente identificado e recebimentos temporários serão removidos deste PDV.',
    'pdv.clearSale.processingTitle': 'Limpando venda...',
    'pdv.clearSale.processingMessage':
        'Aguarde enquanto os dados temporários desta venda são removidos.',
    'pdv.clearSale.successTitle': 'Venda limpa com sucesso',
    'pdv.clearSale.successMessage':
        'O PDV está pronto para iniciar uma nova venda.',
    'pdv.clearSale.error':
        'Não foi possível limpar a venda agora. Tente novamente em instantes.',
    'pdv.customerIdentification.title': 'Identificar cliente',
    'pdv.customerIdentification.subtitle':
        'Selecione um cliente cadastrado ou crie um novo sem sair desta etapa.',
    'pdv.customerIdentification.availableCustomers': 'Clientes ativos',
    'pdv.customerIdentification.currentCustomer': 'Cliente atual',
    'pdv.customerIdentification.currentEmpty': 'Nenhum cliente vinculado',
    'pdv.customerIdentification.searchLabel':
        'Buscar cliente por nome, documento, telefone ou e-mail',
    'pdv.customerIdentification.loading': 'Carregando clientes ativos...',
    'pdv.customerIdentification.loadError':
        'Não foi possível carregar os clientes.',
    'pdv.customerIdentification.errorTitle':
        'Não foi possível carregar os clientes',
    'pdv.customerIdentification.newCustomer': 'Cadastrar cliente',
    'pdv.customerIdentification.openingCreate': 'Abrindo cadastro...',
    'pdv.customerIdentification.createError':
        'Não foi possível abrir o cadastro de cliente agora.',
    'pdv.customerIdentification.emptyTitle': 'Nenhum cliente ativo cadastrado',
    'pdv.customerIdentification.emptyMessage':
        'Cadastre o cliente agora para seguir com o atendimento sem sair desta etapa.',
    'pdv.customerIdentification.emptySearchTitle': 'Nenhum cliente encontrado',
    'pdv.customerIdentification.emptySearchMessage':
        'Revise os termos da busca ou cadastre um novo cliente para continuar.',
    'pdv.customerIdentification.removeCustomer': 'Remover cliente atual',
    'pdv.customerIdentification.unnamedCustomer': 'Cliente sem nome',
    'pdv.customerIdentification.personTypeFallback': 'PF',
    'pdv.customerIdentification.noDocument': 'Sem documento',
    'pdv.customerIdentification.creditEnabled': 'Fiado liberado',
    'pdv.customerIdentification.creditBlocked':
        'Fiado bloqueado para novas vendas',
    'pdv.customerIdentification.creditDisabled': 'Cliente sem fiado liberado',
    'pdv.customerIdentification.selected': 'Selecionado',
    'pdv.customerIdentification.select': 'Selecionar',
    'recebimento.valorEmAberto': 'Valor em aberto',
    'recebimento.summaryType': 'Tipo',
    'recebimento.total': 'Total',
    'recebimento.parcial': 'Parcial',
    'recebimento.formasRecebimento': 'Formas de recebimento',
    'recebimento.restante': 'Restante',
    'recebimento.valorForma': 'Valor da forma',
    'recebimento.tipoRecebimento': 'Tipo de recebimento',
    'recebimento.carregandoTipos': 'Carregando tipos de recebimento...',
    'recebimento.adicionarForma': 'Adicionar forma',
    'recebimento.removerForma': 'Remover forma',
    'recebimento.observacao': 'Observação',
    'recebimento.receberTotal': 'Receber total',
    'recebimento.receberParcial': 'Receber parcial',
    'recebimento.erroValoresMaioresQueZero':
        'Informe valores maiores que zero.',
    'recebimento.erroValorMaiorQueZero': 'Informe um valor maior que zero.',
    'recebimento.erroParcialMenorQueAberto':
        'Para parcial, informe um valor menor que o aberto.',
    'recebimento.erroTotalIgualSaldo':
        'Para total, o valor precisa quitar o saldo em aberto.',
    'recebimento.erroFormaDuplicada':
        'Cada forma de recebimento pode ser usada apenas uma vez.',
    'pdv.receipt.type': 'Tipo de recebimento',
    'pdv.receipt.partialReady':
        'Recebimento parcial pronto. O saldo ficará em aberto.',
    'pdv.receipt.partialHint':
        'Informe um valor maior que zero e menor que o total da venda.',
    'pdv.receipt.partialDefined': 'Parcial definido',
    'pdv.receipt.confirmPartial': 'Confirmar parcial',
    'pdv.receipt.confirmPartialMessage': 'Deseja receber',
    'pdv.receipt.keepOpenBalance': 'e manter o saldo restante em aberto',
    'vendasAReceber.openInPdv': 'Abrir no PDV',
    'pdv.openSale.status': 'Venda em aberto',
    'pdv.openSale.readOnlyStatus': 'Somente consulta',
    'pdv.openSale.readOnlyTitle': 'Consulta de venda em aberto',
    'pdv.openSale.readOnlySubtitle':
        'Produtos, quantidades e preços estão bloqueados nesta etapa. Revise os dados e receba o saldo.',
    'pdv.openSale.editStatus': 'Edição de itens',
    'pdv.openSale.editTitle': 'Revise os itens antes de receber',
    'pdv.openSale.editSubtitle':
        'Inclua ou remova produtos e serviços e altere quantidades. Os preços originais são preservados; itens novos usam o preço atual do cadastro. As mudanças serão aplicadas somente ao receber.',
    'pdv.openSale.partialReadOnlySubtitle':
        'Esta venda já possui recebimentos. Para preservar o histórico financeiro, os itens permanecem bloqueados.',
    'pdv.openSale.pendingChanges': 'Alterações pendentes',
    'pdv.openSale.receiveBalance': 'Receber saldo',
    'pdv.openSale.receiveUpdatedSale': 'Receber venda revisada',
    'pdv.openSale.receiveTitle': 'Receber saldo da venda',
    'pdv.openSale.receiptNote': 'Saldo recebido pelo PDV web.',
    'pdv.openSale.updatedReceiptNote':
        'Venda revisada e recebida pelo PDV web.',
    'pdv.openSale.receivedMessage': 'Venda recebida com sucesso.',
    'pdv.openSale.receiptErrorTitle': 'Não foi possível receber a venda',
    'pdv.openSale.originalTotal': 'Total original',
    'pdv.openSale.openBalance': 'Saldo em aberto',
    'pdv.openSale.currentTotal': 'Novo total',
    'pdv.openSale.totalDifference': 'Diferença',
    'pdv.openSale.emptyItemsTitle': 'A venda precisa ter itens',
    'pdv.openSale.emptyItemsMessage':
        'Inclua pelo menos um produto ou serviço antes de receber a venda.',
    'pdv.openSale.invalidItemsTitle': 'Revise os itens da venda',
    'pdv.openSale.invalidItemsMessage':
        'Todos os itens precisam ter nome, quantidade positiva e valor válido.',
    'pdv.openSale.confirmChangesTitle': 'Confirmar itens revisados?',
    'pdv.openSale.confirmChangesMessage':
        'Ao receber, a nova composição de itens será aplicada e o estoque e o financeiro serão conciliados.',
    'pdv.openSale.continueToReceipt': 'Continuar para recebimento',
    'pdv.openSale.outdatedTitle': 'A venda foi alterada',
    'pdv.openSale.outdatedMessage':
        'Outra operação modificou esta venda. Feche a consulta e abra novamente para trabalhar com os dados atuais.',
    'pdv.openSale.exitTitle': 'Sair da consulta?',
    'pdv.openSale.exitMessage':
        'A venda continuará em aberto. Nenhum item, preço ou recebimento será alterado.',
    'pdv.openSale.exitAction': 'Sair da consulta',
    'pdv.openSale.discardTitle': 'Descartar alterações?',
    'pdv.openSale.discardMessage':
        'As alterações feitas no PDV não serão salvas. A venda continuará em aberto com os dados anteriores.',
    'pdv.openSale.discardAction': 'Descartar e sair',
    'pdv.openSale.replaceTitle': 'Substituir a venda atual?',
    'pdv.openSale.replaceMessage':
        'Os dados que estão no PDV serão substituídos pela venda em aberto selecionada.',
    'pdv.openSale.replaceAction': 'Abrir venda',
    'pdv.openSale.loadedMessage':
        'Venda carregada para revisão. Você pode incluir, remover e alterar quantidades antes de receber.',
    'pdv.openSale.loadedReadOnlyMessage':
        'Venda carregada para consulta. Como já existem recebimentos, os itens permanecem bloqueados.',
    'pdv.openSale.loadErrorTitle': 'Não foi possível abrir a venda',
    'pdv.openSale.unavailableTitle': 'Venda não disponível',
    'pdv.openSale.unavailableMessage':
        'A venda pode ter sido recebida ou cancelada por outro usuário.',
    'common.generating': 'Gerando...',
    'common.saving': 'Salvando...',
    'common.rangeTo': 'a',
    'common.weekday.monday': 'Segunda-feira',
    'common.weekday.tuesday': 'Terça-feira',
    'common.weekday.wednesday': 'Quarta-feira',
    'common.weekday.thursday': 'Quinta-feira',
    'common.weekday.friday': 'Sexta-feira',
    'common.weekday.saturday': 'Sábado',
    'common.weekday.sunday': 'Domingo',
    'common.weekdayShort.monday': 'Seg',
    'common.weekdayShort.tuesday': 'Ter',
    'common.weekdayShort.wednesday': 'Qua',
    'common.weekdayShort.thursday': 'Qui',
    'common.weekdayShort.friday': 'Sex',
    'common.weekdayShort.saturday': 'Sáb',
    'common.weekdayShort.sunday': 'Dom',
    'web.navigation.home': 'Início',
    'web.navigation.operations': 'Atendimento',
    'web.navigation.operations.pos': 'Frente de caixa',
    'web.navigation.operations.technicalService': 'Assistências técnicas',
    'web.navigation.operations.purchases': 'Compras',
    'web.navigation.operations.reservations': 'Reservas',
    'web.navigation.catalog': 'Catálogo',
    'web.navigation.catalog.publicPage': 'Página pública',
    'web.navigation.catalog.reservations': 'Reservas',
    'web.navigation.catalog.products': 'Produtos',
    'web.navigation.catalog.services': 'Serviços',
    'web.navigation.catalog.stock': 'Estoque',
    'web.navigation.catalog.categories': 'Categorias',
    'catalog.publicPage.title': 'Página pública do catálogo',
    'catalog.publicPage.subtitle':
        'Personalize, visualize e compartilhe sua vitrine em um só lugar.',
    'catalog.publicPage.open': 'Abrir',
    'catalog.publicPage.copy': 'Copiar link',
    'catalog.publicPage.share': 'Compartilhar',
    'catalog.publicPage.published': 'Publicado',
    'catalog.publicPage.offline': 'Fora do ar',
    'catalog.publicPage.save': 'Salvar alterações',
    'catalog.publicPage.discard': 'Descartar',
    'catalog.publicPage.saveSuccessPublished':
        'Página salva e publicada com sucesso.',
    'catalog.publicPage.saveSuccessDraft':
        'Personalização salva. Publique quando estiver pronta.',
    'catalog.publicPage.saveError':
        'Não foi possível salvar a página do catálogo.',
    'catalog.publicPage.openError':
        'Não foi possível abrir o catálogo em uma nova aba.',
    'catalog.publicPage.linkCopied': 'Link público copiado.',
    'catalog.publicPage.shareSubject': 'Catálogo de {title}',
    'catalog.publicPage.shareFallback':
        'O compartilhamento não está disponível. O link foi copiado.',
    'catalog.publicPage.loadErrorTitle':
        'Não foi possível carregar a página pública',
    'catalog.publicPage.editor.publication': 'Catálogo publicado',
    'catalog.publicPage.editor.publicationOn':
        'Clientes podem acessar pelo link público.',
    'catalog.publicPage.editor.publicationOff':
        'O link fica preservado, mas indisponível.',
    'catalog.publicPage.editor.content': 'Apresentação',
    'catalog.publicPage.editor.contentHelp':
        'Defina a mensagem que abre sua vitrine.',
    'catalog.publicPage.editor.titleLabel': 'Título da vitrine',
    'catalog.publicPage.editor.titleHint': 'Ex.: Encontre o que precisa',
    'catalog.publicPage.editor.descriptionLabel': 'Descrição curta',
    'catalog.publicPage.editor.descriptionHint':
        'Explique em uma frase o que o cliente encontrará.',
    'catalog.publicPage.editor.appearance': 'Aparência',
    'catalog.publicPage.editor.appearanceHelp':
        'Escolha o clima visual e a cor de destaque.',
    'catalog.publicPage.editor.accentColor': 'Cor de destaque',
    'catalog.publicPage.editor.customColor': 'Cor personalizada',
    'catalog.publicPage.editor.invalidColor':
        'Use uma cor hexadecimal com bom contraste, como #126BFF.',
    'catalog.publicPage.editor.layout': 'Conteúdo e layout',
    'catalog.publicPage.editor.layoutHelp':
        'Controle a densidade e as informações visíveis.',
    'catalog.publicPage.editor.comfortable': 'Confortável',
    'catalog.publicPage.editor.compact': 'Compacto',
    'catalog.publicPage.editor.showPrices': 'Exibir preços',
    'catalog.publicPage.editor.showContact': 'Exibir contatos',
    'catalog.publicPage.editor.showAddress': 'Exibir endereço',
    'catalog.publicPage.style.classic': 'Clássico',
    'catalog.publicPage.style.classicHelp':
        'Profissional, equilibrado e familiar.',
    'catalog.publicPage.style.minimal': 'Minimalista',
    'catalog.publicPage.style.minimalHelp':
        'Mais espaço, menos elementos visuais.',
    'catalog.publicPage.style.expressive': 'Expressivo',
    'catalog.publicPage.style.expressiveHelp':
        'Cor e contraste para destacar a marca.',
    'catalog.publicPage.preview.title': 'Prévia ao vivo',
    'catalog.publicPage.preview.unsaved':
        'Visualizando alterações ainda não salvas',
    'catalog.publicPage.preview.saved': 'Aparência salva no catálogo',
    'catalog.publicPage.preview.desktop': 'Desktop',
    'catalog.publicPage.preview.mobile': 'Celular',
    'catalog.publicPage.preview.storeFallback': 'Seu comércio',
    'catalog.publicPage.preview.products': 'Produtos disponíveis',
    'catalog.publicPage.preview.chooseItems': 'Escolha seus itens',
    'catalog.publicPage.preview.empty':
        'Marque produtos como disponíveis para o catálogo.',
    'catalog.publicPage.unpublish.barrier':
        'Confirmar despublicação do catálogo',
    'catalog.publicPage.unpublish.title': 'Despublicar catálogo?',
    'catalog.publicPage.unpublish.body':
        'Clientes com o link deixarão de ver os produtos até uma nova publicação.',
    'catalog.publicPage.unpublish.action': 'Despublicar',
    'catalog.publicPage.unpublish.processing': 'Retirando o catálogo do ar...',
    'catalog.publicPage.unpublish.processingBody':
        'Aguarde enquanto atualizamos o acesso público.',
    'catalog.publicPage.unpublish.success': 'Catálogo despublicado',
    'catalog.publicPage.unpublish.successBody':
        'O link foi preservado e poderá ser reativado depois.',
    'catalog.publicPage.unpublish.error':
        'Não foi possível despublicar. Tente novamente.',
    'produto.dashboard.importSpreadsheetSoon':
        'Importar via planilha (em breve)',
    'web.navigation.people': 'Pessoas',
    'web.navigation.people.customers': 'Clientes',
    'web.navigation.people.collaborators': 'Colaboradores',
    'web.navigation.people.sixoUsers': 'Usuários do Sixo',
    'web.navigation.people.performance': 'Desempenho',
    'web.navigation.cash': 'Caixa',
    'web.navigation.financial': 'Financeiro',
    'web.navigation.financial.agenda': 'Agenda financeira',
    'web.navigation.settings': 'Configurações',
    'web.navigation.reports': 'Relatórios',
    'web.navigation.unavailable': 'Destino indisponível nesta versão.',
    'usuariosSixo.title': 'Usuários do Sixo',
    'usuariosSixo.subtitle':
        'Consulte os usuários cadastrados com acesso exclusivo para o perfil SUPER.',
    'usuariosSixo.summarySemantics':
        'Resumo dos usuários cadastrados no Sixo',
    'usuariosSixo.summaryTitle': 'Base global de usuários',
    'usuariosSixo.summarySubtitle':
        'Consulta protegida pelo perfil SUPER do token.',
    'usuariosSixo.totalLabel': 'usuários',
    'usuariosSixo.totalRegistered': 'Usuários cadastrados',
    'usuariosSixo.searchHint':
        'Buscar por nome, e-mail, celular ou perfil',
    'usuariosSixo.resultsLabel': 'encontrados',
    'usuariosSixo.forbiddenTitle': 'Acesso exclusivo para SUPER',
    'usuariosSixo.forbiddenMessage':
        'Seu perfil não possui permissão para consultar os usuários do Sixo.',
    'usuariosSixo.loading': 'Carregando usuários do Sixo',
    'usuariosSixo.loadErrorTitle':
        'Não foi possível carregar os usuários',
    'usuariosSixo.loadError': 'Verifique sua conexão e tente novamente.',
    'usuariosSixo.emptyTitle': 'Nenhum usuário encontrado',
    'usuariosSixo.emptyMessage':
        'Ajuste a busca para consultar outros usuários.',
    'usuariosSixo.userFallback': 'Usuário do Sixo',
    'usuariosSixo.noEmail': 'E-mail não informado',
    'usuariosSixo.noPhone': 'Celular não informado',
    'usuariosSixo.role.super': 'SUPER',
    'usuariosSixo.role.admin': 'Administrador',
    'usuariosSixo.role.collaborator': 'Colaborador',
    'usuariosSixo.role.customer': 'Cliente',
    'usuariosSixo.role.unknown': 'Não informado',
    'usuariosSixo.detail.title': 'Detalhes do usuário',
    'usuariosSixo.detail.subtitle':
        'Cadastro, preferências, empresas e vínculos salvos no Sixo.',
    'usuariosSixo.detail.loadError':
        'Não foi possível carregar os detalhes.',
    'usuariosSixo.detail.personal': 'Dados pessoais',
    'usuariosSixo.detail.account': 'Conta e permissões',
    'usuariosSixo.detail.preferences': 'Preferências individuais',
    'usuariosSixo.detail.globalPreferences': 'Preferências globais',
    'usuariosSixo.detail.companies': 'Empresas vinculadas',
    'usuariosSixo.detail.links': 'Vínculos e dados contratuais',
    'usuariosSixo.detail.noCompanies': 'Nenhuma empresa vinculada.',
    'usuariosSixo.detail.noLinks': 'Nenhum vínculo cadastrado.',
    'usuariosSixo.detail.imageStored': 'Imagem armazenada',
    'usuariosSixo.onboarding.completed': 'Onboarding concluído',
    'usuariosSixo.onboarding.pending': 'Onboarding pendente',
    'usuariosSixo.onboarding.dialogBarrier':
        'Alterar status do onboarding inicial',
    'usuariosSixo.onboarding.resetTitle': 'Solicitar novo onboarding?',
    'usuariosSixo.onboarding.resetMessage':
        'No próximo acesso, o usuário deverá confirmar novamente seus dados iniciais antes de entrar no sistema.',
    'usuariosSixo.onboarding.resetAction': 'Refazer onboarding',
    'usuariosSixo.onboarding.completeTitle':
        'Marcar onboarding como concluído?',
    'usuariosSixo.onboarding.completeMessage':
        'O usuário deixará de ver o onboarding inicial nos próximos acessos.',
    'usuariosSixo.onboarding.completeAction': 'Marcar como concluído',
    'usuariosSixo.onboarding.processingTitle': 'Atualizando onboarding...',
    'usuariosSixo.onboarding.processingMessage':
        'Aguarde enquanto a nova configuração é salva.',
    'usuariosSixo.onboarding.successTitle': 'Onboarding atualizado',
    'usuariosSixo.onboarding.successMessage':
        'A nova regra já valerá no próximo acesso do usuário.',
    'usuariosSixo.onboarding.errorTitle': 'Não foi possível atualizar',
    'usuariosSixo.onboarding.errorMessage':
        'Tente novamente. Nenhuma outra informação foi alterada.',
    'initialOnboarding.eyebrow': 'Configuração inicial',
    'initialOnboarding.step': 'Etapa',
    'initialOnboarding.of': 'de',
    'initialOnboarding.identityTitle': 'Vamos começar pelo essencial',
    'initialOnboarding.identitySubtitle':
        'Confirme seus dados para personalizarmos sua experiência.',
    'initialOnboarding.businessTitle': 'O que seu negócio faz?',
    'initialOnboarding.businessSubtitle':
        'Isso apenas organiza módulos e atalhos. Você poderá alterar depois.',
    'initialOnboarding.languageQuestion':
        'Em qual idioma deseja continuar?',
    'initialOnboarding.userName': 'Como podemos chamar você?',
    'initialOnboarding.companyName': 'Nome do seu negócio',
    'initialOnboarding.salesTitle': 'Vende produtos',
    'initialOnboarding.salesSubtitle': 'PDV, catálogo, estoque e vendas.',
    'initialOnboarding.servicesTitle': 'Presta serviços técnicos',
    'initialOnboarding.servicesSubtitle':
        'Atendimentos, ordens de serviço e procedimentos.',
    'initialOnboarding.start': 'Começar a usar o SixoApp',
    'initialOnboarding.activityRequired':
        'Selecione vendas, serviços técnicos ou ambos.',
    'initialOnboarding.userNameRequired': 'Informe seu nome para continuar.',
    'initialOnboarding.companyNameRequired':
        'Informe o nome da empresa para continuar.',
    'initialOnboarding.saveError':
        'Não foi possível salvar agora. Tente novamente.',
    'initialOnboarding.loadErrorTitle':
        'Não foi possível iniciar a configuração',
    'initialOnboarding.loadErrorMessage':
        'Verifique sua conexão e tente novamente.',
    'caixa.operacoes.openConfirmTitle': 'Confirmar abertura de caixa?',
    'caixa.operacoes.openConfirmMessage':
        'Deseja abrir {cashDesk} com troco inicial de {amount}?',
    'caixa.operacoes.openConfirmAction': 'Abrir caixa',
    'caixa.operacoes.closeSessionAction': 'Encerrar caixa',
    'caixa.operacoes.closeDialogTitle': 'Encerrar sessão de caixa?',
    'caixa.operacoes.closeDialogSubtitle':
        'Revise o resumo antes de concluir. Esta ação não poderá ser desfeita.',
    'caixa.operacoes.closeDialogCashDesk': 'Caixa',
    'caixa.operacoes.closeDialogMovements': 'Movimentos',
    'caixa.operacoes.closeDialogExpectedBalance': 'Saldo esperado',
    'caixa.operacoes.closeDialogChecklistComplete':
        'Resumo operacional disponível',
    'caixa.operacoes.closeDialogBack': 'Voltar',
    'caixa.operacoes.closeDialogConfirm': 'Encerrar caixa',
    'caixa.operacoes.closeDialogProcessing': 'Encerrando...',
    'caixa.operacoes.closeDialogSuccessTitle': 'Caixa encerrado com sucesso',
    'caixa.operacoes.closeDialogSuccessMessage':
        'A sessão foi finalizada e permanece disponível no histórico.',
    'caixa.operacoes.closeDialogError':
        'Não foi possível encerrar o caixa. Verifique sua conexão e tente novamente.',
    'caixa.operacoes.cancelDialogTitle': 'Cancelar movimentação?',
    'caixa.operacoes.cancelDialogSubtitle':
        'Revise os vínculos desta operação antes de cancelar. Dependendo do histórico financeiro, o lançamento pode precisar permanecer registrado.',
    'caixa.operacoes.cancelDialogOperation': 'Operação',
    'caixa.operacoes.cancelDialogMethod': 'Forma',
    'caixa.operacoes.cancelDialogAmount': 'Valor',
    'caixa.operacoes.cancelDialogChecklist':
        'Se a movimentação estiver vinculada a recebimentos ou lançamentos futuros, o cancelamento poderá ser bloqueado para preservar o histórico.',
    'caixa.operacoes.cancelDialogBack': 'Voltar',
    'caixa.operacoes.cancelDialogConfirm': 'Cancelar operação',
    'caixa.operacoes.cancelDialogProcessing': 'Cancelando...',
    'caixa.operacoes.cancelDialogSuccessTitle': 'Movimentação cancelada',
    'caixa.operacoes.cancelDialogSuccessMessage':
        'O histórico do caixa foi atualizado e a operação não seguirá ativa na sessão atual.',
    'caixa.operacoes.cancelDialogError':
        'Não foi possível cancelar a movimentação agora. Revise os vínculos financeiros e tente novamente.',
    'caixa.operacoes.cancelDialogLinkedRecordsError':
        'Esta movimentação possui vínculo com recebimentos ou lançamentos futuros e precisa permanecer registrada no histórico financeiro.',
    'caixa.operacoes.cancelDialogPermissionError':
        'Você não possui permissão para cancelar esta movimentação.',
    'caixa.operacoes.cancelDialogConnectivityError':
        'Não foi possível falar com o servidor agora. Verifique sua conexão e tente novamente.',
    'caixa.operacoes.cancelDialogLikelyLinkedError':
        'Não foi possível cancelar esta movimentação porque ela pode estar vinculada a outros registros financeiros. Revise os recebimentos relacionados e tente novamente.',
    'caixa.operacoes.addEntryAction': 'Adicionar lançamento',
    'caixa.operacoes.launchDialogTitle': 'Registrar lançamento operacional',
    'caixa.operacoes.launchDialogSubtitle':
        'Preencha os dados da operação e revise antes de registrar no caixa.',
    'caixa.operacoes.launchDialogTypeLabel': 'Tipo da operação',
    'caixa.operacoes.launchDialogSelect': 'Selecione',
    'caixa.operacoes.launchDialogAmountLabel': 'Valor',
    'caixa.operacoes.launchDialogRelatedTypeLabel': 'Forma relacionada',
    'caixa.operacoes.launchDialogReferenceLabel': 'Referência / comprovante',
    'caixa.operacoes.launchDialogReferenceHint': 'Ex.: MOV-001',
    'caixa.operacoes.launchDialogObservationLabel': 'Observação',
    'caixa.operacoes.launchDialogObservationHint':
        'Descreva o motivo da movimentação com clareza.',
    'caixa.operacoes.launchDialogLinkedSaleLabel': 'Possui vínculo com venda',
    'caixa.operacoes.launchDialogLinkedSaleHint':
        'Use em estornos ou situações relacionadas a atendimento anterior.',
    'caixa.operacoes.launchDialogReviewAction': 'Revisar lançamento',
    'caixa.operacoes.launchDialogTypeRequired': 'Selecione o tipo da operação.',
    'caixa.operacoes.launchDialogRelatedTypeRequired':
        'Selecione a forma relacionada.',
    'caixa.operacoes.launchDialogAmountRequired': 'Informe um valor válido.',
    'caixa.operacoes.launchDialogReviewTitle':
        'Confirmar lançamento operacional?',
    'caixa.operacoes.launchDialogReviewSubtitle':
        'Revise os dados abaixo antes de registrar a movimentação no caixa.',
    'caixa.operacoes.launchDialogChecklist': 'Resumo pronto para confirmação.',
    'caixa.operacoes.launchDialogEditAction': 'Editar dados',
    'caixa.operacoes.launchDialogConfirmAction': 'Registrar movimentação',
    'caixa.operacoes.launchDialogProcessing': 'Registrando...',
    'caixa.operacoes.launchDialogError':
        'Não foi possível registrar a movimentação. Verifique os dados e tente novamente.',
    'caixa.operacoes.launchDialogSuccessTitle':
        'Movimentação registrada com sucesso',
    'caixa.operacoes.launchDialogSuccessMessage':
        'O lançamento já aparece no histórico e no resumo do caixa.',
    'caixa.operacoes.launchDialogAvailableMethods': 'Formas ativas',
    'caixa.operacoes.launchDialogLinkedSaleTag': 'Vinculado a venda',
    'caixa.operacoes.historyTodayOnly': 'Somente hoje',
    'caixa.operacoes.historyPeriod': 'Período',
    'caixa.operacoes.historyPeriodToday': 'Hoje',
    'caixa.operacoes.historyPeriodLast7Days': 'Últimos 7 dias',
    'caixa.operacoes.historyPeriodLast30Days': 'Últimos 30 dias',
    'caixa.operacoes.historyPeriodThisMonth': 'Este mês',
    'caixa.operacoes.historyPeriodLastMonth': 'Mês passado',
    'caixa.operacoes.historyPeriodCustomRange': 'Intervalo personalizado',
    'caixa.operacoes.historyNature': 'Natureza',
    'caixa.operacoes.historyStatus': 'Status',
    'caixa.operacoes.historyOperation': 'Operação',
    'caixa.operacoes.historyMethod': 'Forma',
    'caixa.operacoes.historyStartDate': 'Data inicial',
    'caixa.operacoes.historyEndDate': 'Data final',
    'caixa.operacoes.historyStartDateHelp': 'Selecionar data inicial',
    'caixa.operacoes.historyEndDateHelp': 'Selecionar data final',
    'caixa.operacoes.historyClearFilters': 'Limpar filtros',
    'caixa.operacoes.historyNoResultsFiltered':
        'Nenhuma movimentação encontrada com os filtros aplicados.',
    'caixa.operacoes.historyNoResultsToday':
        'Nenhuma movimentação registrada hoje.',
    'web.standalone.quote': 'Orçamento',
    'web.standalone.serviceOrder': 'Ordem de serviço',
    'web.shell.expandSidebar': 'Expandir navegação',
    'web.shell.collapseSidebar': 'Recolher navegação',
    'web.shell.currentCommerce': 'Comércio atual',
    'web.shell.sessionContext': 'Contexto da sessão',
    'web.shell.workspace': 'Workspace operacional',
    'web.shell.version': 'Versão',
    'web.header.profile': 'Perfil',
    'web.header.profileTooltip': 'Meu perfil',
    'web.header.userMenu': 'Usuário',
    'web.header.myProfile': 'Meu perfil',
    'web.header.theme.dark': 'Tema escuro',
    'web.header.theme.dark.enable': 'Ativar tema escuro',
    'web.header.theme.dark.disable': 'Desativar tema escuro',
    'web.header.logout': 'Sair',
    'web.logout.dialog.title': 'Encerrar sessão agora?',
    'web.logout.dialog.subtitle':
        'Revise o contexto antes de sair. Você voltará para a tela pública de login neste navegador.',
    'web.logout.dialog.user': 'Usuário',
    'web.logout.dialog.currentCommerce': 'Comércio atual',
    'web.logout.dialog.nextStep': 'Próximo passo',
    'web.logout.dialog.nextStepValue': 'Tela pública de login',
    'web.logout.dialog.checklist':
        'A sessão atual será encerrada somente neste navegador.',
    'web.logout.dialog.back': 'Continuar conectado',
    'web.logout.dialog.confirm': 'Sair agora',
    'web.logout.dialog.processing': 'Encerrando sessão...',
    'web.logout.dialog.successTitle': 'Sessão encerrada com sucesso',
    'web.logout.dialog.successMessage':
        'Preparando o retorno para a tela pública de login.',
    'web.logout.dialog.error':
        'Não foi possível encerrar a sessão agora. Tente novamente em alguns instantes.',
    'workspaceHome.title': 'Meu dia no SixoApp',
    'workspaceHome.greeting': 'Olá, {name}',
    'workspaceHome.unknownUser': 'usuário',
    'workspaceHome.companyFallback': 'Comércio atual',
    'workspaceHome.operationalDate': 'Hoje: {date}',
    'workspaceHome.refreshTooltip': 'Atualizar resumo do dia',
    'workspaceHome.loading.title': 'Carregando resumo do dia',
    'workspaceHome.loading.subtitle':
        'Buscando a situação atual desta empresa.',
    'workspaceHome.error.title': 'Não foi possível carregar o resumo do dia.',
    'collaboratorHome.title': 'Meu painel',
    'collaboratorHome.subtitle':
        'Acompanhe metas, vendas, serviços e prioridades do seu trabalho.',
    'collaboratorHome.loading': 'Carregando seu painel operacional',
    'collaboratorHome.error.user':
        'Não foi possível identificar seu painel pessoal.',
    'collaboratorHome.attention.title': 'Prioridades do trabalho',
    'collaboratorHome.attention.clear':
        'Tudo em dia nas suas frentes de trabalho.',
    'collaboratorHome.attention.pending': '{count} pontos precisam de atenção.',
    'collaboratorHome.attention.overdueSales': 'Vendas vencidas',
    'collaboratorHome.attention.overdueServices': 'Entregas atrasadas',
    'collaboratorHome.attention.reservations': 'Reservas para analisar',
    'collaboratorHome.sales.title': 'Minhas vendas',
    'collaboratorHome.sales.period': 'Resultados de {start} a {end}',
    'collaboratorHome.sales.count': 'Vendas no mês',
    'collaboratorHome.sales.total': 'Total vendido',
    'collaboratorHome.sales.received': 'Já recebido',
    'collaboratorHome.sales.openMonth': 'Em aberto no mês',
    'collaboratorHome.sales.loadError':
        'Não foi possível carregar o resumo das suas vendas.',
    'collaboratorHome.openSales.title': 'Vendas ainda não liquidadas',
    'collaboratorHome.openSales.subtitle':
        'Somente vendas registradas por você.',
    'collaboratorHome.openSales.loadError':
        'Não foi possível carregar suas vendas em aberto.',
    'collaboratorHome.openSales.empty':
        'Você não possui vendas aguardando liquidação.',
    'collaboratorHome.openSales.more': 'Mais {count} vendas em aberto',
    'collaboratorHome.openSales.customerFallback': 'Cliente não informado',
    'collaboratorHome.openSales.saleFallback': 'Venda',
    'collaboratorHome.openSales.noDueDate': 'Sem vencimento',
    'collaboratorHome.openSales.overdue': 'Vencida',
    'collaboratorHome.services.title': 'Meus serviços por status',
    'collaboratorHome.services.subtitle':
        'Distribuição dos atendimentos em que você é o técnico.',
    'collaboratorHome.services.open': 'Abrir atendimentos',
    'collaboratorHome.services.loadError':
        'Não foi possível carregar seus serviços.',
    'collaboratorHome.services.empty':
        'Nenhum atendimento está atribuído a você.',
    'collaboratorHome.services.total': 'Total atribuído',
    'collaboratorHome.services.inProgress': 'Em andamento',
    'collaboratorHome.services.dueToday': 'Entregas hoje',
    'collaboratorHome.services.overdue': 'Atrasados',
    'collaboratorHome.services.moreStatuses':
        'Mais {count} status com movimentação',
    'collaboratorHome.services.unknownStatus': 'Sem status',
    'collaboratorHome.reservations.title': 'Fila de reservas',
    'collaboratorHome.reservations.subtitle':
        'Pedidos do catálogo que podem virar venda.',
    'collaboratorHome.reservations.open': 'Abrir reservas',
    'collaboratorHome.reservations.loadError':
        'Não foi possível carregar as reservas.',
    'collaboratorHome.reservations.pending': 'Pendentes',
    'collaboratorHome.reservations.received': 'Recebidas',
    'collaboratorHome.reservations.analysis': 'Em análise',
    'collaboratorHome.reservations.confirmed': 'Confirmadas',
    'collaboratorHome.reservations.converted': 'Convertidas',
    'performance.home.title': 'Minhas metas',
    'performance.home.subtitle':
        'Acompanhe suas metas e os resultados atualizados pelo SixoApp.',
    'performance.home.dashboardTitle': 'Meta x resultado',
    'performance.home.period': 'Resultados de {start} a {end}',
    'performance.home.accessibilityLabel': 'Dashboard das minhas metas',
    'performance.home.loading': 'Carregando suas metas',
    'performance.home.loadError': 'Não foi possível atualizar suas metas.',
    'performance.home.emptyTitle': 'Nenhuma meta ativa neste mês',
    'performance.home.emptySubtitle':
        'Quando uma meta for cadastrada para você, o resultado aparecerá aqui.',
    'performance.home.result': 'Resultado',
    'performance.home.target': 'Meta',
    'performance.indicator.salesValue': 'Valor vendido',
    'performance.indicator.salesQuantity': 'Quantidade de vendas',
    'performance.indicator.servicesValue': 'Valor em serviços',
    'performance.indicator.serviceCalls': 'Atendimentos técnicos',
    'performance.indicator.finishedServiceCalls': 'Atendimentos finalizados',
    'performance.indicator.serviceCallsValue': 'Valor em atendimentos',
    'workspaceHome.section.today': 'Situação de hoje',
    'workspaceHome.section.attention': 'Precisa da sua atenção',
    'workspaceHome.section.quickActions': 'Ações rápidas',
    'workspaceHome.empty.today':
        'Nenhum bloco do resumo está disponível para suas permissões.',
    'workspaceHome.empty.attention': 'Nenhuma pendência importante agora.',
    'workspaceHome.empty.quickActions':
        'Nenhuma ação rápida disponível para suas permissões.',
    'dashboardInicio.mobileCompanyFilterTooltip':
        'Filtrar comércios: {comercio}',
    'dashboardInicio.mobileCompanyFilterTitle': 'Filtrar comércios',
    'dashboardInicio.mobileCompanyFilterSubtitle':
        'Escolha um comércio para visualizar a dashboard.',
    'dashboardInicio.mobileCompanyFilterAll': 'Todos',
    'dashboardInicio.mobileGreetingSubtitle':
        'Veja os principais movimentos de {empresa} hoje.',
    'dashboardInicio.mobileCompanyFilterSearchHint': 'Buscar comércio',
    'dashboardInicio.mobileCompanyFilterEmptyTitle':
        'Nenhum comércio disponível',
    'dashboardInicio.mobileCompanyFilterEmptyMessage':
        'Não encontramos vínculos ativos para este usuário.',
    'dashboardInicio.mobileCompanyFilterLoadError':
        'Não foi possível carregar os comércios disponíveis agora.',
    'dashboardInicio.mobileCompanyFilterSwitchError':
        'Não foi possível trocar o comércio agora. Tente novamente.',
    'dashboardInicio.mobileDashboardFilterTitle': 'Filtrar dashboard',
    'dashboardInicio.mobileDashboardFilterSubtitle':
        'Escolha o comércio e, se precisar, refine por colaborador.',
    'dashboardInicio.mobileDashboardFilterCompanyLabel': 'Comércio',
    'dashboardInicio.mobileDashboardFilterCompanyHelper':
        'Define qual comércio alimenta os indicadores exibidos.',
    'dashboardInicio.mobileCollaboratorFilterLabel': 'Colaborador',
    'dashboardInicio.mobileCollaboratorFilterAll': 'Todos os colaboradores',
    'dashboardInicio.mobileCollaboratorFilterHelper':
        'Mostra os indicadores do colaborador selecionado na dashboard.',
    'dashboardInicio.mobileCollaboratorFilterDisabledHelper':
        'Escolha um comércio específico para filtrar colaboradores.',
    'dashboardInicio.mobileCollaboratorFilterLoadingHelper':
        'Carregando colaboradores do comércio atual.',
    'dashboardInicio.mobileCollaboratorFilterTitle': 'Filtrar colaborador',
    'dashboardInicio.mobileCollaboratorFilterSubtitle':
        'Escolha um colaborador para refinar os indicadores.',
    'dashboardInicio.mobileCollaboratorFilterSearchHint': 'Buscar colaborador',
    'dashboardInicio.mobileCollaboratorFilterEmptyTitle':
        'Nenhum colaborador disponível',
    'dashboardInicio.mobileCollaboratorFilterEmptyMessage':
        'Não encontramos colaboradores ativos neste comércio.',
    'dashboardInicio.mobileCollaboratorFilterLoadError':
        'Não foi possível carregar os colaboradores deste comércio agora.',
    'dashboardInicio.mobileCollaboratorFilterSelectedFallback':
        'Colaborador selecionado',
    'dashboardInicio.mobileInfrastructureRequestsTitle': 'Requests do backend',
    'dashboardInicio.mobileInfrastructureRequestsSubtitle':
        'Respostas monitoradas na janela selecionada do backend.',
    'dashboardInicio.mobileInfrastructureRequestsFilterTitle':
        'Filtrar requests do backend',
    'dashboardInicio.mobileInfrastructureRequestsFilterSubtitle':
        'Informe a janela que entra na contagem dos status 200, 400 e 500.',
    'dashboardInicio.mobileInfrastructureRequestsFilterValueLabel':
        'Quantidade',
    'dashboardInicio.mobileInfrastructureRequestsFilterUnitLabel': 'Unidade',
    'dashboardInicio.mobileInfrastructureRequestsFilterMinutes': 'Minutos',
    'dashboardInicio.mobileInfrastructureRequestsFilterHours': 'Horas',
    'dashboardInicio.mobileInfrastructureRequestsFilterApply': 'Aplicar janela',
    'dashboardInicio.mobileInfrastructureRequestsMinuteSingular': 'minuto',
    'dashboardInicio.mobileInfrastructureRequestsMinutePlural': 'minutos',
    'dashboardInicio.mobileInfrastructureRequestsHourSingular': 'hora',
    'dashboardInicio.mobileInfrastructureRequestsHourPlural': 'horas',
    'workspaceHome.cash.title': 'Caixa',
    'workspaceHome.cash.open': 'Aberto',
    'workspaceHome.cash.closed': 'Fechado',
    'workspaceHome.cash.openedAt': 'desde {time}',
    'workspaceHome.cash.openedAtWithDate': 'desde {date} às {time}',
    'workspaceHome.cash.responsible': 'Aberto por {name}',
    'workspaceHome.technical.title': 'Assistências',
    'workspaceHome.technical.active.one': '1 em andamento',
    'workspaceHome.technical.active.other': '{count} em andamento',
    'workspaceHome.financial.receivableToday': 'A receber hoje',
    'workspaceHome.financial.payableToday': 'A pagar hoje',
    'workspaceHome.financial.count.one': '1 conta',
    'workspaceHome.financial.count.other': '{count} contas',
    'workspaceHome.stock.title': 'Estoque',
    'workspaceHome.stock.noCritical': 'Sem alertas críticos',
    'workspaceHome.stock.belowMinimum.one': '1 abaixo do mínimo',
    'workspaceHome.stock.belowMinimum.other': '{count} abaixo do mínimo',
    'workspaceHome.stock.withoutStock.one': '1 sem estoque',
    'workspaceHome.stock.withoutStock.other': '{count} sem estoque',
    'workspaceHome.stock.negative.one': '1 negativo',
    'workspaceHome.stock.negative.other': '{count} negativos',
    'workspaceHome.attention.lateServices.one': '1 serviço atrasado',
    'workspaceHome.attention.lateServices.other': '{count} serviços atrasados',
    'workspaceHome.attention.waitingApproval.one':
        '1 orçamento aguardando aprovação',
    'workspaceHome.attention.waitingApproval.other':
        '{count} orçamentos aguardando aprovação',
    'workspaceHome.attention.readyForPickup.one':
        '1 equipamento pronto para retirada',
    'workspaceHome.attention.readyForPickup.other':
        '{count} equipamentos prontos para retirada',
    'workspaceHome.attention.overdueReceivable.one':
        '1 conta a receber vencida',
    'workspaceHome.attention.overdueReceivable.other':
        '{count} contas a receber vencidas',
    'workspaceHome.attention.overduePayable.one': '1 conta a pagar vencida',
    'workspaceHome.attention.overduePayable.other':
        '{count} contas a pagar vencidas',
    'workspaceHome.attention.stockNegative.one':
        '1 produto com estoque negativo',
    'workspaceHome.attention.stockNegative.other':
        '{count} produtos com estoque negativo',
    'workspaceHome.attention.stockWithout.one': '1 produto sem estoque',
    'workspaceHome.attention.stockWithout.other':
        '{count} produtos sem estoque',
    'workspaceHome.attention.stockBelow.one':
        '1 produto abaixo do estoque mínimo',
    'workspaceHome.attention.stockBelow.other':
        '{count} produtos abaixo do estoque mínimo',
    'workspaceHome.action.openTechnicalServices': 'Abrir assistências',
    'workspaceHome.action.openFinancial': 'Abrir financeiro',
    'workspaceHome.action.openStock': 'Abrir estoque',
    'workspaceHome.quickAction.newSale': 'Nova venda',
    'workspaceHome.quickAction.newTechnicalService': 'Novo atendimento',
    'workspaceHome.quickAction.cash': 'Caixa',
    'workspaceHome.quickAction.financialAgenda': 'Agenda financeira',
    'streak.title': 'Ofensiva',
    'streak.mobile': 'Mobile',
    'streak.web': 'Web',
    'streak.shared': 'Geral',
    'streak.longest': 'Recorde',
    'streak.oneDay': '1 dia',
    'streak.days': '{count} dias',
    'streak.daysOfStreak': '{count} dias de ofensiva',
    'streak.keepUsing': 'Use o SixoApp todos os dias para manter sua ofensiva.',
    'streak.startedToday': 'Sua ofensiva começou hoje.',
    'streak.loading': 'Carregando seus dias de ofensiva.',
    'streak.loadError': 'Não foi possível carregar sua ofensiva.',
    'mobile.nav.dash': 'dash',
    'mobile.nav.home': 'Início',
    'mobile.nav.management': 'Gestão',
    'mobile.nav.service': 'Atendimento',
    'empresa.configuracao.title': 'Empresa',
    'empresa.configuracao.loadError':
        'Não foi possível carregar os dados da empresa.',
    'empresa.configuracao.saveSuccess':
        'Dados da empresa atualizados com sucesso.',
    'empresa.configuracao.saveError':
        'Não foi possível salvar os dados da empresa.',
    'empresa.configuracao.summaryTitle': 'Dados do comércio',
    'empresa.configuracao.summarySubtitle':
        'Atualize as informações usadas nos documentos e no atendimento.',
    'empresa.configuracao.identityTitle': 'Identidade da empresa',
    'empresa.configuracao.identitySubtitle':
        'Revise os dados principais antes de salvar as alterações.',
    'empresa.configuracao.legalName': 'Razão social',
    'empresa.configuracao.legalNameHint': 'Nome legal da empresa',
    'empresa.configuracao.tradeName': 'Nome fantasia',
    'empresa.configuracao.tradeNameHint': 'Nome comercial usado no atendimento',
    'empresa.configuracao.document': 'Documento da empresa',
    'empresa.configuracao.documentHint': 'CNPJ ou documento fiscal equivalente',
    'empresa.configuracao.requiredField': 'Informe este campo.',
    'empresa.configuracao.readyToEdit': 'Dados prontos para edição.',
    'empresa.configuracao.waitingData': 'Aguardando dados da empresa.',
    'empresa.configuracao.statusSubtitle':
        'As informações salvas aparecem nos documentos e comprovantes do comércio.',
    'empresa.configuracao.saveChanges': 'Salvar alterações',
    'empresa.configuracao.logoTitle': 'Logo da empresa',
    'empresa.configuracao.logoSubtitle':
        'Adicione uma imagem nítida, de preferência quadrada.',
    'empresa.configuracao.logoRegistered':
        'Imagem pronta para salvar no cadastro do comércio.',
    'empresa.configuracao.logoSelect': 'Selecionar logo',
    'empresa.configuracao.logoChange': 'Trocar logo',
    'empresa.configuracao.logoRemove': 'Remover',
    'empresa.configuracao.logoSheetTitle': 'Cadastrar logo',
    'empresa.configuracao.logoSheetSubtitle':
        'Escolha uma imagem da galeria ou tire uma foto.',
    'empresa.configuracao.logoFromGallery': 'Escolher da galeria',
    'empresa.configuracao.logoFromCamera': 'Usar câmera',
    'empresa.configuracao.logoLoadError': 'Não foi possível carregar o logo.',
    'empresa.configuracao.logoTooLarge': 'Escolha uma imagem de até 1 MB.',
    'empresa.configuracao.logoSemantics': 'Logo cadastrado da empresa.',
    'empresa.configuracao.logoEmptySemantics': 'Nenhum logo cadastrado.',
    'catalogHealth.mobile.attentionItems': '{count} itens precisam de atenção',
    'catalogHealth.status.critical': 'Crítico',
    'catalogHealth.status.warning': 'Atenção',
    'catalogHealth.status.healthy': 'Saudável',
    'catalogHealth.status.default': 'Saúde',
    'atendimentoTecnico.status': 'Status',
    'atendimentoTecnico.filters.paymentStatus.label': 'Status pagamento',
    'atendimentoTecnico.filters.paymentStatus.tooltip':
        'Filtrar por status do pagamento',
    'atendimentoTecnico.filters.paymentStatus.helper':
        'Filtre atendimentos por saldo em aberto ou liquidado.',
    'atendimentoTecnico.filters.paymentStatus.all': 'Todos os pagamentos',
    'atendimentoTecnico.filters.paymentStatus.open': 'Em aberto',
    'atendimentoTecnico.filters.paymentStatus.paid': 'Liquidado',
    'atendimentoTecnico.filters.multiSelected': '{count} selecionados',
    'atendimentoTecnico.filters.technician.label': 'Técnico responsável',
    'atendimentoTecnico.filters.technician.tooltip':
        'Filtrar por técnico responsável',
    'atendimentoTecnico.filters.technician.all': 'Todos os técnicos',
    'atendimentoTecnico.filters.technician.none': 'Sem técnico responsável',
    'atendimentoTecnico.filters.technician.selectedFallback':
        'Técnico selecionado',
    'atendimentoTecnico.filters.status.tooltip': 'Filtrar por status',
    'atendimentoTecnico.filters.status.all': 'Todos os status',
    'atendimentoTecnico.filters.status.allWithCount':
        'Todos os status ({count})',
    'atendimentoTecnico.filters.status.selectedFallback': 'Status selecionado',
    'atendimentoTecnico.lista.openDetails': 'Ver detalhes',
    'atendimentoTecnico.lista.detailsDialog.title': 'Detalhes do atendimento',
    'atendimentoTecnico.lista.detailsDialog.subtitle':
        'Revise financeiro, andamento e histórico completos antes de seguir para outra ação.',
    'atendimentoTecnico.lista.detailsDialog.barrierLabel':
        'Fechar detalhes do atendimento',
    'atendimentoTecnico.web.dateFilterDialog.barrierLabel':
        'Fechar filtro de data',
    'atendimentoTecnico.web.dateFilterDialog.filterLabel': 'Data',
    'atendimentoTecnico.web.dateFilterDialog.title': 'Filtrar por data',
    'atendimentoTecnico.web.dateFilterDialog.subtitle':
        'Defina o intervalo de atualização dos atendimentos.',
    'atendimentoTecnico.web.dateFilterDialog.fieldLabel': 'Campo',
    'atendimentoTecnico.web.dateFilterDialog.fieldValueUpdatedAt':
        'Atualização',
    'atendimentoTecnico.web.dateFilterDialog.currentRangeLabel': 'Intervalo',
    'atendimentoTecnico.web.dateFilterDialog.allDates': 'Todas as datas',
    'atendimentoTecnico.web.dateFilterDialog.dateFrom': 'A partir de {date}',
    'atendimentoTecnico.web.dateFilterDialog.dateUntil': 'Até {date}',
    'atendimentoTecnico.web.dateFilterDialog.dateRange': '{start} até {end}',
    'atendimentoTecnico.web.dateFilterDialog.startLabel': 'Início',
    'atendimentoTecnico.web.dateFilterDialog.endLabel': 'Fim',
    'atendimentoTecnico.web.dateFilterDialog.dateHint': 'dd/MM/yyyy',
    'atendimentoTecnico.web.dateFilterDialog.quickToday': 'Hoje',
    'atendimentoTecnico.web.dateFilterDialog.quickLast7Days': 'Últimos 7 dias',
    'atendimentoTecnico.web.dateFilterDialog.quickNext7Days': 'Próximos 7 dias',
    'atendimentoTecnico.web.dateFilterDialog.quickOverdue': 'Vencidos',
    'atendimentoTecnico.web.dateFilterDialog.quickLast30Days':
        'Últimos 30 dias',
    'atendimentoTecnico.web.dateFilterDialog.quickThisMonth': 'Este mês',
    'atendimentoTecnico.web.dateFilterDialog.clearAction': 'Limpar',
    'atendimentoTecnico.web.dateFilterDialog.cancelAction': 'Cancelar',
    'atendimentoTecnico.web.dateFilterDialog.applyAction': 'Aplicar',
    'atendimentoTecnico.web.dateFilterDialog.startInvalid':
        'Informe a data inicial em um formato válido.',
    'atendimentoTecnico.web.dateFilterDialog.endInvalid':
        'Informe a data final em um formato válido.',
    'atendimentoTecnico.web.dateFilterDialog.endBeforeStart':
        'A data final não pode ser anterior à inicial.',
    'atendimentoTecnico.customerNotInformed': 'Cliente não informado',
    'atendimentoTecnico.expectedDelivery': 'Entrega prevista',
    'atendimentoTecnico.equipment': 'Equipamento',
    'atendimentoTecnico.reportedIssue': 'Defeito',
    'atendimentoTecnico.publicStatus.title': 'Status do serviço',
    'atendimentoTecnico.publicStatus.subtitle':
        'Acompanhe a etapa atual do atendimento técnico pelo link público.',
    'atendimentoTecnico.publicStatus.progressTitle': 'Progresso do atendimento',
    'atendimentoTecnico.publicStatus.progressShort': 'Progresso do serviço',
    'atendimentoTecnico.publicStatus.serviceData': 'Dados do serviço',
    'atendimentoTecnico.publicStatus.history': 'Histórico de status',
    'atendimentoTecnico.publicStatus.noHistory':
        'Nenhuma mudança de status registrada.',
    'atendimentoTecnico.publicStatus.loading':
        'Carregando status do serviço...',
    'atendimentoTecnico.publicStatus.errorTitle':
        'Não foi possível carregar o status',
    'atendimentoTecnico.publicStatus.invalidLink':
        'Link inválido. Token ou comércio não informado.',
    'atendimentoTecnico.publicStatus.linkTitle': 'Link público de status',
    'atendimentoTecnico.publicStatus.linkCopied':
        'Link copiado para a área de transferência.',
    'atendimentoTecnico.publicStatus.linkCopiedShort':
        'Link de status copiado.',
    'atendimentoTecnico.publicStatus.linkHelp':
        'Envie este link ao cliente para acompanhar o status atual do serviço.',
    'atendimentoTecnico.publicStatus.linkMissing':
        'Link não retornado pelo backend.',
    'atendimentoTecnico.publicStatus.linkError':
        'Não foi possível gerar o link de status',
    'atendimentoTecnico.publicStatus.shareMessage':
        'Acompanhe o status do seu serviço pelo link abaixo:',
    'atendimentoTecnico.publicStatus.shareSubject': 'Status do serviço',
    'atendimentoTecnico.publicStatus.shareFallback':
        'Não foi possível abrir o compartilhamento. O link foi copiado.',
    'atendimentoTecnico.publicStatus.publicUrlMissing':
        'URL pública do aplicativo não configurada.',
    'atendimentoTecnico.publicStatus.action': 'Status público',
    'atendimentoTecnico.publicStatus.actionShort': 'Status',
    'atendimentoTecnico.publicStatus.signaturePendingTitle':
        'Assinatura de aprovação pendente',
    'atendimentoTecnico.publicStatus.signaturePendingDescription':
        'Você pode acompanhar o status normalmente. Para aprovar o serviço, clique no botão e assine na próxima página.',
    'atendimentoTecnico.publicStatus.signatureRenewTitle':
        'Nova assinatura necessária',
    'atendimentoTecnico.publicStatus.signatureRenewDescription':
        'O atendimento foi alterado depois da última aprovação. Você pode acompanhar o status normalmente e assinar a versão atual quando quiser aprovar.',
    'atendimentoTecnico.publicStatus.signatureAction': 'Assinar aprovação',
    'atendimentoTecnico.publicStatus.signatureLinkMissing':
        'Link de assinatura não retornado pelo backend.',
    'atendimentoTecnico.publicStatus.signatureLinkError':
        'Não foi possível abrir a assinatura.',
    'atendimentoTecnico.publicStatus.responsibleUnit': 'Unidade responsável',
    'atendimentoTecnico.publicStatus.officialChannel': 'Canal oficial',
    'atendimentoTecnico.publicStatus.updatedByBusiness':
        'Status atualizado pelo estabelecimento',
    'atendimentoTecnico.publicStatus.companyDataSource':
        'Dados fornecidos pelo estabelecimento.',
    'atendimentoTecnico.publicStatus.officialServiceChannel':
        'Canal oficial de acompanhamento do serviço.',
    'atendimentoTecnico.publicStatus.externalLinkUnavailable':
        'Não foi possível abrir este contato neste dispositivo.',
    'atendimentoTecnico.mobile.loading': 'Carregando atendimentos técnicos',
    'atendimentoTecnico.mobile.dashboardTitle': 'Dashboard técnico',
    'atendimentoTecnico.mobile.dashboardDescription': '',
    'atendimentoTecnico.mobile.emptyTitle': 'Nenhum atendimento encontrado',
    'atendimentoTecnico.mobile.emptyMessage':
        'Tente buscar por cliente, equipamento, status ou número.',
    'atendimentoTecnico.mobile.emptyFilteredMessage':
        'Nenhum atendimento encontrado com os filtros selecionados.',
    'atendimentoTecnico.mobile.errorTitle':
        'Não foi possível carregar os atendimentos',
    'atendimentoTecnico.mobile.recentSection': 'Atendimentos recentes',
    'atendimentoTecnico.mobile.filteredSection': 'Resultado do filtro',
    'atendimentoTecnico.mobile.searchHint':
        'Buscar por cliente, status, equipamento ou número',
    'atendimentoTecnico.mobile.advancedFilters': 'Filtros avançados',
    'atendimentoTecnico.mobile.advancedFiltersActive':
        'Filtros avançados ativos',
    'atendimentoTecnico.mobile.clearFilters': 'Limpar filtros',
    'atendimentoTecnico.mobile.sortRecent': 'Mais recentes',
    'atendimentoTecnico.mobile.resultCountOne': '1 atendimento',
    'atendimentoTecnico.mobile.resultCountMany': '{count} atendimentos',
    'atendimentoTecnico.mobile.periodSummaryTitle': 'Resumo do período',
    'atendimentoTecnico.mobile.summaryServiceOne': 'atendimento',
    'atendimentoTecnico.mobile.summaryServiceMany': 'atendimentos',
    'atendimentoTecnico.mobile.summaryOpenOne': 'em aberto',
    'atendimentoTecnico.mobile.summaryOpenMany': 'em aberto',
    'atendimentoTecnico.mobile.summarySignedOne': 'assinado',
    'atendimentoTecnico.mobile.summarySignedMany': 'assinados',
    'atendimentoTecnico.mobile.summaryOpenValue': '{value} em aberto',
    'atendimentoTecnico.mobile.summaryOpenValueCaption': 'em aberto',
    'atendimentoTecnico.mobile.filterSheetTitle': 'Filtrar atendimentos',
    'atendimentoTecnico.mobile.filterPeriod': 'Período',
    'atendimentoTecnico.mobile.filterPaymentStatus': 'Status do pagamento',
    'atendimentoTecnico.mobile.filterDate': 'Data',
    'atendimentoTecnico.mobile.filterStartDate': 'Início',
    'atendimentoTecnico.mobile.filterEndDate': 'Fim',
    'atendimentoTecnico.mobile.dateToday': 'Hoje',
    'atendimentoTecnico.mobile.dateAll': 'Todas as datas',
    'atendimentoTecnico.mobile.dateRange': '{start} até {end}',
    'atendimentoTecnico.mobile.dateFrom': 'A partir de {date}',
    'atendimentoTecnico.mobile.dateUntil': 'Até {date}',
    'atendimentoTecnico.mobile.dateLast7Days': 'Últimos 7 dias',
    'atendimentoTecnico.mobile.dateNext7Days': 'Próximos 7 dias',
    'atendimentoTecnico.mobile.dateOverdue': 'Vencidos',
    'atendimentoTecnico.mobile.filterTechnician': 'Técnico responsável',
    'atendimentoTecnico.mobile.searchTechnician': 'Buscar técnico',
    'atendimentoTecnico.mobile.allTechnicians': 'Todos os técnicos',
    'atendimentoTecnico.mobile.selectedTechnician': 'Técnico selecionado',
    'atendimentoTecnico.mobile.noTechnicianFound': 'Nenhum técnico encontrado.',
    'atendimentoTecnico.mobile.viewOneService': 'Ver 1 atendimento',
    'atendimentoTecnico.mobile.viewManyServices': 'Ver {count} atendimentos',
    'atendimentoTecnico.mobile.waitingApprovalTitle':
        'Orçamentos aguardando aprovação',
    'atendimentoTecnico.mobile.waitingApprovalDescription':
        'Serviços enviados ao cliente que ainda precisam de aprovação.',
    'atendimentoTecnico.mobile.waitingApprovalEmptyTitle':
        'Nenhum orçamento aguardando aprovação no momento.',
    'atendimentoTecnico.mobile.waitingApprovalEmptyMessage':
        'Quando um orçamento for enviado e estiver aguardando a decisão do cliente, ele aparecerá aqui.',
    'atendimentoTecnico.mobile.waitingApprovalErrorTitle':
        'Não foi possível consultar os orçamentos. Tente novamente.',
    'atendimentoTecnico.mobile.waitingApprovalLoading':
        'Carregando orçamentos aguardando aprovação',
    'atendimentoTecnico.mobile.waitingApprovalSection':
        'Orçamentos aguardando aprovação',
    'atendimentoTecnico.mobile.waitingApprovalFilteredSection':
        'Resultado do filtro',
    'atendimentoTecnico.mobile.currentStatusOption': 'Status atual',
    'atendimentoTecnico.mobile.selectStatusOption': 'Toque para selecionar',
    'technicalService.status.waitingCustomerAproval':
        'Aguardando aprovação do cliente',
    'atendimentoTecnico.mobile.sharePdfTooltip': 'Compartilhar atendimento',
    'atendimentoTecnico.mobile.pdfSectionTitle': 'Documento do atendimento',
    'atendimentoTecnico.mobile.pdfSectionDescription':
        'PDF pronto para enviar ao cliente com os dados do atendimento.',
    'atendimentoTecnico.mobile.pdfSectionGenerating':
        'Preparando o PDF para compartilhamento.',
    'atendimentoTecnico.mobile.sharePdfAction': 'Compartilhar PDF',
    'atendimentoTecnico.mobile.pdfLoadingTitle': 'Gerando PDF do atendimento',
    'atendimentoTecnico.mobile.pdfLoadingSubtitle':
        'Aguarde enquanto o documento é preparado.',
    'atendimentoTecnico.mobile.detailLoadError':
        'Não foi possível carregar os dados atualizados do atendimento.',
    'atendimentoTecnico.mobile.pdfDownloaded': 'PDF baixado com sucesso.',
    'atendimentoTecnico.mobile.pdfPermissionDenied':
        'Você não possui permissão para compartilhar este atendimento.',
    'atendimentoTecnico.mobile.pdfNotFound': 'Atendimento não encontrado.',
    'atendimentoTecnico.mobile.pdfInvalidFile':
        'O arquivo recebido é inválido.',
    'atendimentoTecnico.mobile.pdfShareUnavailable':
        'Não foi possível compartilhar o documento.',
    'atendimentoTecnico.mobile.pdfShareError':
        'Não foi possível compartilhar o documento.',
    'atendimentoTecnico.mobile.pdfGenerationError':
        'Não foi possível gerar o PDF do atendimento.',
    'atendimentoTecnico.mobile.publicStatusDescription':
        'Visível para o cliente no link de acompanhamento.',
    'atendimentoTecnico.publicStatus.shareLinkAction': 'Compartilhar link',
    'atendimentoTecnico.mobile.paymentOpen': 'Financeiro aberto',
    'atendimentoTecnico.mobile.paymentSettled': 'Financeiro liquidado',
    'atendimentoTecnico.mobile.signed': 'Assinado',
    'atendimentoTecnico.mobile.signaturePending': 'Assinatura pendente',
    'atendimentoTecnico.customerNotSigned': 'Cliente não assinou',
    'atendimentoTecnico.mobile.customerNotSigned': 'Cliente não assinou',
    'atendimentoTecnico.mobile.deliveryLate': 'Entrega atrasada',
    'atendimentoTecnico.signatureGate.title': 'Assinatura necessária',
    'atendimentoTecnico.signatureGate.message':
        'Para avançar para {status}, envie o link de assinatura ao cliente, assine neste dispositivo ou registre o bypass.',
    'atendimentoTecnico.signatureGate.sendLink': 'Enviar link ao cliente',
    'atendimentoTecnico.signatureGate.signHere': 'Assinar neste dispositivo',
    'atendimentoTecnico.signatureGate.bypass': 'Avançar sem assinatura',
    'atendimentoTecnico.signatureGate.deviceTitle': 'Coletar assinatura',
    'atendimentoTecnico.signatureGate.deviceMessage':
        'Registre a assinatura para avançar para {status}.',
    'atendimentoTecnico.signatureGate.deviceSigner': 'Nome de quem assina',
    'atendimentoTecnico.signatureGate.deviceDocument': 'Documento opcional',
    'atendimentoTecnico.signatureGate.deviceSignatureField': 'Assinatura',
    'atendimentoTecnico.signatureGate.deviceObservation': 'Observação opcional',
    'atendimentoTecnico.signatureGate.deviceSave': 'Registrar assinatura',
    'atendimentoTecnico.signatureGate.deviceSignerRequired':
        'Informe o nome de quem está assinando.',
    'atendimentoTecnico.signatureGate.deviceSignatureRequired':
        'Faça a assinatura no quadro indicado.',
    'atendimentoTecnico.signatureGate.deviceSignatureSaved':
        'Assinatura registrada e status atualizado.',
    'atendimentoTecnico.signatureGate.deviceSignatureError':
        'Não foi possível registrar a assinatura',
    'atendimentoTecnico.signatureGate.publicUrlMissing':
        'URL pública do aplicativo não configurada.',
    'atendimentoTecnico.signatureGate.linkMissing':
        'Link de assinatura não retornado pelo backend.',
    'atendimentoTecnico.signatureGate.linkCopied':
        'Link de assinatura copiado.',
    'atendimentoTecnico.signatureGate.linkError':
        'Não foi possível gerar o link de assinatura',
    'atendimentoTecnico.signatureGate.shareMessage':
        'Para aprovar o atendimento, assine pelo link abaixo:',
    'atendimentoTecnico.signatureGate.shareSubject':
        'Assinatura do atendimento',
    'atendimentoTecnico.mobile.valorOriginal': 'Valor original',
    'atendimentoTecnico.mobile.valorJaRecebido': 'Valor já recebido',
    'atendimentoTecnico.mobile.valorEmAberto': 'Valor em aberto',
    'atendimentoTecnico.mobile.liquidation': 'Liquidação',
    'atendimentoTecnico.mobile.liquidated': 'Liquidada',
    'atendimentoTecnico.mobile.notLiquidated': 'Não liquidada',
    'atendimentoTecnico.mobile.products': 'Produtos',
    'atendimentoTecnico.mobile.services': 'Serviços',
    'atendimentoTecnico.mobile.changeStatusAction': 'Mudar status',
    'atendimentoTecnico.mobile.createTitle': 'Novo atendimento técnico',
    'atendimentoTecnico.mobile.createHeaderTitle': 'Iniciar assistência',
    'atendimentoTecnico.mobile.createHeaderSubtitle':
        'Cliente, equipamento e defeito em uma tela rápida para balcão.',
    'atendimentoTecnico.mobile.responsible': 'Responsável',
    'atendimentoTecnico.mobile.serviceChip': 'Assistência',
    'atendimentoTecnico.mobile.quoteChip': 'Orçamento',
    'atendimentoTecnico.mobile.noItemsChip': 'Sem itens',
    'atendimentoTecnico.mobile.mainDataSection': 'Dados principais',
    'atendimentoTecnico.mobile.internalDescription': 'Descrição interna',
    'atendimentoTecnico.mobile.internalDescriptionHint':
        'Ex.: Troca de tela iPhone 11',
    'atendimentoTecnico.mobile.equipmentType': 'Tipo de equipamento',
    'atendimentoTecnico.mobile.brand': 'Marca',
    'atendimentoTecnico.mobile.model': 'Modelo',
    'atendimentoTecnico.mobile.serialNumber': 'Nº série',
    'atendimentoTecnico.mobile.imei': 'IMEI',
    'atendimentoTecnico.mobile.accessoriesNotes': 'Acessórios / observações',
    'atendimentoTecnico.mobile.accessoriesNotesHint':
        'Ex.: sem carregador, com capa, tela trincada...',
    'atendimentoTecnico.mobile.technicalReportSection': 'Relato técnico',
    'atendimentoTecnico.mobile.customerIssue': 'Defeito relatado pelo cliente',
    'atendimentoTecnico.mobile.customerIssueHint':
        'Descreva o problema informado no balcão.',
    'atendimentoTecnico.mobile.initialDiagnosis': 'Diagnóstico técnico inicial',
    'atendimentoTecnico.mobile.initialDiagnosisHint':
        'Opcional neste primeiro momento.',
    'atendimentoTecnico.mobile.datesSection': 'Datas',
    'atendimentoTecnico.mobile.validity': 'Validade',
    'atendimentoTecnico.mobile.financialDueDate': 'Vencimento financeiro',
    'atendimentoTecnico.mobile.financialPreviewSection': 'Prévia financeira',
    'atendimentoTecnico.mobile.financialPreviewDescription':
        'O valor fica em aberto até registrar um recebimento.',
    'atendimentoTecnico.mobile.valorConfirmado': 'Confirmado',
    'atendimentoTecnico.mobile.paymentStampNoValue': 'SEM VALOR',
    'atendimentoTecnico.mobile.paymentStampOpen': 'EM ABERTO',
    'atendimentoTecnico.mobile.savingService': 'Iniciando atendimento...',
    'atendimentoTecnico.mobile.startServiceAction':
        'Iniciar atendimento técnico',
    'auth.loginRequiredFields': 'Por favor, preencha o e-mail e a senha',
    'auth.loginTitleMobile': 'Entrar',
    'auth.loginSubtitleMobile':
        'Para entrar em sua conta, informe\nseu e-mail e senha',
    'auth.email': 'E-mail',
    'auth.password': 'Senha',
    'auth.forgotPassword': 'Esqueceu a senha?',
    'auth.continue': 'Continuar',
    'auth.noAccount': 'Ainda não tem uma contaXPTO?',
    'auth.createAccount': 'Criar conta',
    'auth.signInWithApple': 'Entrar com Apple',
    'auth.signInWithGoogle': 'Entrar com Google',
    'auth.googleLoginError': 'Não foi possível concluir o login com Google.',
    'auth.session.validatingTitle': 'Entrando no SixoApp',
    'auth.session.validatingMessage': 'Validando sua sessão com segurança...',
    'splash.preparingWorkspace': 'Preparando seu espaço...',
    'splash.validatingSession': 'Validando sua sessão...',
    'splash.syncingAccount': 'Sincronizando seus dados...',
    'splash.connectedTagline': 'Tudo conectado. Tudo sob controle.',
    'auth.session.temporaryErrorTitle': 'Não foi possível validar sua sessão',
    'auth.session.temporaryErrorMessage':
        'Sua sessão foi preservada. Verifique sua conexão e tente novamente.',
    'webAuthGate.temporaryError.title': 'Não foi possível validar sua sessão',
    'webAuthGate.temporaryError.message':
        'Verifique sua conexão ou aguarde o backend responder e tente novamente.',
    'auth.appleLoginMock': 'Login com Apple (mocked)',
    'auth.termsPrefix':
        'Ao clicar em "Continuar", declaro ter lido e concordo com os ',
    'auth.terms': 'Termos de Uso e Política de Privacidade',
    'auth.mobileEntry.title': 'Seu negócio, conectado.',
    'auth.mobileEntry.subtitle':
        'Vendas, estoque e gestão no mesmo ritmo — onde você estiver.',
    'auth.mobileEntry.sales': 'Vendas',
    'auth.mobileEntry.stock': 'Estoque',
    'auth.mobileEntry.management': 'Gestão',
    'auth.mobileEntry.continueTitle': 'Como deseja continuar?',
    'auth.mobileEntry.loginAction': 'Entrar na minha conta',
    'auth.mobileEntry.createAction': 'Criar minha conta',
    'auth.mobileEntry.securityNote': 'Acesso seguro e dados sempre protegidos.',
    'auth.mobileLogin.title': 'Bem-vindo de volta',
    'auth.mobileLogin.subtitle': 'Entre para continuar de onde parou.',
    'auth.mobileLogin.formTitle': 'Acesse seu espaço',
    'auth.mobileLogin.emailHint': 'voce@empresa.com',
    'auth.mobileLogin.passwordHint': 'Digite sua senha',
    'auth.mobileLogin.showPassword': 'Mostrar senha',
    'auth.mobileLogin.hidePassword': 'Ocultar senha',
    'auth.mobileLogin.submit': 'Entrar',
    'auth.mobileLogin.socialDivider': 'ou continue com',
    'auth.mobileLogin.createPrompt': 'Primeira vez no SixoApp?',
    'auth.mobileCreate.title': 'Crie seu espaço',
    'auth.mobileCreate.subtitle':
        'Comece simples. O SixoApp cresce junto com seu negócio.',
    'auth.mobileCreate.formTitle': 'Sua conta começa aqui',
    'auth.mobileCreate.formNote': 'Leva menos de um minuto.',
    'auth.mobileCreate.loginLabel': 'Login',
    'auth.mobileCreate.loginHint': 'Escolha seu login de acesso',
    'auth.mobileCreate.passwordLabel': 'Senha',
    'auth.mobileCreate.passwordHint': 'Mínimo de 8 caracteres',
    'auth.mobileCreate.confirmPasswordLabel': 'Confirme a senha',
    'auth.mobileCreate.confirmPasswordHint': 'Repita sua senha',
    'auth.mobileCreate.acceptTerms':
        'Concordo com os Termos e a Política de Privacidade.',
    'auth.mobileCreate.submit': 'Criar conta',
    'auth.mobileCreate.loginPrompt': 'Já tem uma conta? Entrar',
    'auth.mobileCreate.acceptTermsError':
        'Aceite os Termos e Condições para continuar.',
    'auth.mobileCreate.requiredFieldsError': 'Preencha todos os campos.',
    'auth.mobileCreate.passwordLengthError':
        'A senha precisa ter ao menos 8 caracteres.',
    'auth.mobileCreate.passwordMismatchInline': 'As senhas não coincidem.',
    'auth.mobileCreate.passwordMismatchError':
        'As senhas informadas não são iguais. Verifique e tente novamente.',
    'auth.entry.title': 'Bem-vindo ao SixoApp',
    'auth.entry.subtitle':
        'Antes de continuar, diga como deseja acessar o app.',
    'auth.entry.hasAccountTitle': 'Já tenho uma conta',
    'auth.entry.hasAccountSubtitle':
        'Entre com seu e-mail e senha para acessar sua empresa.',
    'auth.entry.loginAction': 'Entrar',
    'auth.entry.newAccountTitle': 'Sou novo por aqui',
    'auth.entry.newAccountSubtitle':
        'Veja um resumo rápido e crie sua conta para começar.',
    'auth.entry.newAccountAction': 'Conhecer o SixoApp',
    'auth.onboarding.title': 'Comece pelo essencial',
    'auth.onboarding.subtitle':
        'Veja três pontos rápidos antes de criar sua conta.',
    'auth.onboarding.step1Title': 'Atendimento organizado',
    'auth.onboarding.step1Subtitle':
        'Registre vendas, orçamentos e assistências em um fluxo simples.',
    'auth.onboarding.step2Title': 'Catálogo e estoque no bolso',
    'auth.onboarding.step2Subtitle':
        'Mantenha produtos, serviços e informações essenciais sempre à mão.',
    'auth.onboarding.step3Title': 'Gestão para crescer',
    'auth.onboarding.step3Subtitle':
        'Acompanhe indicadores e prepare sua operação para evoluir com o SixoApp.',
    'auth.onboarding.skip': 'Pular',
    'auth.onboarding.next': 'Avançar',
    'auth.onboarding.createAccountAction': 'Criar minha conta',
    'auth.onboarding.loginAction': 'Já tenho uma conta',
    'configuracoes.regionalizationTitle': 'Regionalização',
    'configuracoes.descRegionalization':
        'Idioma, país, moeda, fuso horário, formatos de data e padronização financeira da empresa.',
    'configuracoes.languageAndRegionalConventions':
        'Idioma e convenções regionais',
    'configuracoes.languageAndRegionalConventionsDesc':
        'Defina a experiência local da empresa, incluindo idioma, fuso e padrões de exibição.',
    'configuracoes.systemLanguage': 'Idioma do sistema',
    'configuracoes.countryRegion': 'País / região',
    'configuracoes.timeZone': 'Fuso horário',
    'configuracoes.dateFormat': 'Formato de data',
    'configuracoes.timeFormat': 'Formato de hora',
    'configuracoes.firstDayOfWeek': 'Primeiro dia da semana',
    'configuracoes.numberFormat': 'Formato numérico',
    'configuracoes.currencyAndFinancialStandard':
        'Moeda e padronização financeira',
    'configuracoes.currencyAndFinancialStandardDesc':
        'Essas definições influenciam dashboards, vendas, ordem de serviço, orçamentos e documentos.',
    'configuracoes.mainCurrency': 'Moeda principal',
    'configuracoes.symbolPosition': 'Posição do símbolo',
    'configuracoes.decimalPlaces': 'Casas decimais',
    'configuracoes.decimalSeparator': 'Separador decimal',
    'configuracoes.thousandSeparator': 'Separador de milhar',
    'configuracoes.allowMultipleCurrencies': 'Permitir múltiplas moedas',
    'configuracoes.allowMultipleCurrenciesDesc':
        'Mantém a base preparada para cenários internacionais e conversão futura.',
    'configuracoes.applyFinancialRounding': 'Aplicar arredondamento financeiro',
    'configuracoes.applyFinancialRoundingDesc':
        'Padroniza cálculos e evita divergências de centavos em documentos e totais.',
    'configuracoes.recebimento.contextTitle':
        'Formas de recebimento configuráveis',
    'configuracoes.recebimento.contextDescription':
        'Personalize como sua empresa recebe pagamentos. Os códigos internos são mantidos pelo sistema, mas o nome e o comportamento podem ser ajustados.',
    'configuracoes.recebimento.metricsTotal': 'Tipos configurados',
    'configuracoes.recebimento.metricsActive': 'Ativos',
    'configuracoes.recebimento.metricsImmediate': 'Natureza imediata',
    'configuracoes.recebimento.metricsFuture': 'Natureza futura',
    'configuracoes.recebimento.loadingTitle':
        'Carregando formas de recebimento',
    'configuracoes.recebimento.loadingSubtitle':
        'Sincronizando as configurações da empresa no backend.',
    'configuracoes.recebimento.errorLoad':
        'Não foi possível carregar as formas de recebimento.',
    'configuracoes.recebimento.errorBadRequest':
        'Dados inválidos para esta operação.',
    'configuracoes.recebimento.errorUnauthorized':
        'Sessão expirada. Faça login novamente.',
    'configuracoes.recebimento.errorForbidden':
        'Você não possui permissão para alterar configurações da empresa.',
    'configuracoes.recebimento.errorNotFound':
        'Configuração de forma de recebimento não encontrada.',
    'configuracoes.recebimento.errorLoadWithStatus':
        'Erro ao carregar formas de recebimento.',
    'configuracoes.recebimento.errorSaveWithStatus':
        'Erro ao salvar forma de recebimento.',
    'configuracoes.recebimento.saveSuccess':
        'Forma de recebimento atualizada com sucesso.',
    'configuracoes.recebimento.errorSave':
        'Não foi possível salvar a forma de recebimento.',
    'configuracoes.recebimento.restoreConfirmTitle': 'Restaurar padrão',
    'configuracoes.recebimento.restoreConfirmBody':
        'Esta ação restaura os 10 tipos de recebimento para a configuração padrão da empresa.',
    'configuracoes.recebimento.restoreAction': 'Restaurar padrão',
    'configuracoes.recebimento.restoreSuccess':
        'Configuração padrão das formas de recebimento restaurada com sucesso.',
    'configuracoes.recebimento.restoreError':
        'Não foi possível restaurar a configuração padrão.',
    'configuracoes.recebimento.countPrefix': 'Tipos carregados',
    'configuracoes.recebimento.activeCount': 'Ativos',
    'configuracoes.recebimento.refreshAction': 'Atualizar',
    'configuracoes.recebimento.unnamed': 'Sem nome definido',
    'configuracoes.recebimento.nature': 'Natureza',
    'configuracoes.recebimento.natureImmediate': 'Imediato',
    'configuracoes.recebimento.natureFuture': 'Futuro',
    'configuracoes.recebimento.natureImmediateDescription':
        'Entra no caixa no momento do recebimento.',
    'configuracoes.recebimento.natureFutureDescription':
        'Gera valor a receber para uma data futura.',
    'configuracoes.recebimento.requiresClient': 'Exige cliente',
    'configuracoes.recebimento.requiresClientDescription':
        'Obrigatório quando esta forma depende de um cliente identificado.',
    'configuracoes.recebimento.installments': 'Aceita parcelamento',
    'configuracoes.recebimento.installmentsDescription':
        'Permite dividir o recebimento em parcelas.',
    'configuracoes.recebimento.displayOrder': 'Ordem de exibição',
    'configuracoes.recebimento.technicalCode': 'Código técnico',
    'configuracoes.recebimento.displayName': 'Nome de exibição',
    'configuracoes.recebimento.validationName': 'Informe o nome de exibição.',
    'configuracoes.recebimento.validationNameLength':
        'Use pelo menos 2 caracteres.',
    'configuracoes.recebimento.validationOrder':
        'Informe uma ordem válida maior ou igual a 1.',
    'configuracoes.recebimento.validationColor':
        'Use um HEX válido no formato #RRGGBB.',
    'configuracoes.recebimento.color': 'Cor (opcional)',
    'configuracoes.recebimento.icon': 'Ícone (opcional)',
    'configuracoes.recebimento.activeDescription':
        'Controla se a forma pode ser utilizada nos fluxos.',
    'configuracoes.recebimento.editDialogTitle': 'Editar forma de recebimento',
    'configuracoes.recebimento.errorStateTitle':
        'Não foi possível carregar as configurações',
    'configuracoes.recebimento.emptyTitle':
        'Nenhuma forma de recebimento encontrada',
    'configuracoes.recebimento.emptyDescription':
        'Atualize a tela para sincronizar os tipos configurados da empresa.',
    'procedimentos.title': 'Procedimentos',
    'procedimentos.subtitle': 'Guias para vendas, atendimentos e entregas',
    'procedimentos.introTitle':
        'Configure orientações para vendas, atendimentos e entregas.',
    'procedimentos.demoData': 'Dados demonstrativos',
    'procedimentos.filtersLabel': 'Filtros de procedimentos',
    'procedimentos.filterAll': 'Todos',
    'procedimentos.filterActive': 'Ativos',
    'procedimentos.filterInactive': 'Inativos',
    'procedimentos.newProcedure': 'Novo procedimento',
    'procedimentos.newProcedureSemantics': 'Novo procedimento',
    'procedimentos.createProcedure': 'Criar procedimento',
    'procedimentos.openAction': 'Abrir',
    'procedimentos.createUnavailable':
        'A criação de procedimentos será disponibilizada na próxima etapa.',
    'procedimentos.editUnavailable':
        'A edição deste procedimento será disponibilizada na próxima etapa.',
    'procedimentos.loading': 'Carregando procedimentos',
    'procedimentos.emptyTitle': 'Nenhum procedimento configurado',
    'procedimentos.emptyDescription':
        'Crie orientações para apoiar a equipe nos momentos importantes da operação.',
    'procedimentos.filteredEmptyTitle': 'Nenhum procedimento neste filtro',
    'procedimentos.filteredEmptyDescription':
        'Altere o filtro para ver outros procedimentos demonstrativos.',
    'procedimentos.errorTitle': 'Não foi possível carregar os procedimentos',
    'procedimentos.errorDescription': 'Tente novamente em instantes.',
    'procedimentos.statusDraft': 'Rascunho',
    'procedimentos.operationSale': 'Venda',
    'procedimentos.operationTechnicalService': 'Atendimento técnico',
    'procedimentos.operationQuote': 'Orçamento',
    'procedimentos.operationDelivery': 'Entrega',
    'procedimentos.momentBeforeStart': 'Antes de iniciar',
    'procedimentos.momentBeforeFinish': 'Antes de finalizar',
    'procedimentos.momentBeforeDelivery': 'Antes da entrega',
    'procedimentos.stageSingular': 'etapa',
    'procedimentos.stagePlural': 'etapas',
    'procedimentos.itemSingular': 'item',
    'procedimentos.itemPlural': 'itens',
    'procedimentos.stageProgress': 'Etapa {current} de {total}',
    'procedimentos.procedureSequence': 'Procedimento {current} de {total}',
    'procedimentos.actionsCompleted.zero': '0 de {total} ações concluídas',
    'procedimentos.actionsCompleted.one': '1 de {total} ação concluída',
    'procedimentos.actionsCompleted.other':
        '{count} de {total} ações concluídas',
    'procedimentos.answeredActionsSummary.zero':
        '0 de {total} ações respondidas.',
    'procedimentos.answeredActionsSummary.one': '1 de {total} ação respondida.',
    'procedimentos.answeredActionsSummary.other':
        '{count} de {total} ações respondidas.',
    'procedimentos.optionalPendingSummary.zero':
        'Nenhum item opcional pendente.',
    'procedimentos.optionalPendingSummary.one': '1 item opcional pendente.',
    'procedimentos.optionalPendingSummary.other':
        '{count} itens opcionais pendentes.',
    'procedimentos.requiredPendingSummary.zero':
        'Nenhum item obrigatório pendente.',
    'procedimentos.requiredPendingSummary.one': '1 item obrigatório pendente.',
    'procedimentos.requiredPendingSummary.other':
        '{count} itens obrigatórios pendentes.',
    'procedimentos.itemCount.zero': '0 itens',
    'procedimentos.itemCount.one': '1 item',
    'procedimentos.itemCount.other': '{count} itens',
    'procedimentos.stageCount.zero': '0 etapas',
    'procedimentos.stageCount.one': '1 etapa',
    'procedimentos.stageCount.other': '{count} etapas',
    'procedimentos.stageSemantics': 'Etapa {order}: {title}. {itemCountLabel}.',
    'procedimentos.executionItemSemantics': '{requiredLabel}: {title}. {type}.',
    'procedimentos.executionItemStatus': '{type} • {requiredLabel}',
    'procedimentos.responseTypeSemantics': '{label}. {description}.',
    'procedimentos.responseTypeSimulatedSemantics':
        '{label}. {description}. {demoLabel}.',
    'procedimentos.triggerSemantics':
        '{operation}, {moment}, {activation}, {enforcement}, {status}',
    'procedimentos.triggerSummarySingle': '{operation}, {moment}',
    'procedimentos.triggerSummaryMultiple': '{first} • +{remaining}',
    'procedimentos.optionNumber': 'Opção {index}',
    'procedimentos.editorNewTitle': 'Novo procedimento',
    'procedimentos.editorEditTitle': 'Editar procedimento',
    'procedimentos.generalInfo': 'Informações gerais',
    'procedimentos.nameField': 'Nome',
    'procedimentos.descriptionField': 'Descrição',
    'procedimentos.operationContext': 'Contexto operacional',
    'procedimentos.momentField': 'Momento',
    'procedimentos.requireCompletion': 'Exigir conclusão deste procedimento',
    'procedimentos.requireCompletionHelp':
        'Na integração futura, esse procedimento poderá exigir conclusão antes de continuar a operação.',
    'procedimentos.stages': 'Etapas',
    'procedimentos.addStage': 'Adicionar etapa',
    'procedimentos.editStage': 'Editar etapa',
    'procedimentos.deleteStage': 'Excluir etapa',
    'procedimentos.items': 'Itens',
    'procedimentos.addItem': 'Adicionar item',
    'procedimentos.editItem': 'Editar item',
    'procedimentos.deleteItem': 'Excluir item',
    'procedimentos.itemType': 'Tipo de item',
    'procedimentos.stageTitleField': 'Título da etapa',
    'procedimentos.itemTitleField': 'Título ou instrução',
    'procedimentos.itemGuidanceField': 'Texto de apoio',
    'procedimentos.saveStage': 'Salvar etapa',
    'procedimentos.saveItem': 'Salvar item',
    'procedimentos.responseInstruction': 'Orientação',
    'procedimentos.responseConfirmation': 'Confirmação',
    'procedimentos.responseYesNo': 'Sim ou não',
    'procedimentos.responseInstructionDescription':
        'Apresenta uma instrução ao colaborador.',
    'procedimentos.responseConfirmationDescription':
        'Exige que o colaborador confirme uma ação.',
    'procedimentos.responseYesNoDescription':
        'Apresenta uma pergunta objetiva.',
    'procedimentos.validationName': 'Informe o nome do procedimento.',
    'procedimentos.validationReviewFields':
        'Revise os campos destacados antes de salvar.',
    'procedimentos.validationAtLeastOneStage':
        'Adicione pelo menos uma etapa ao procedimento.',
    'procedimentos.validationStageTitle': 'Informe o título da etapa.',
    'procedimentos.validationStageItem':
        'Cada etapa precisa ter pelo menos um item.',
    'procedimentos.validationItemTitle': 'Informe o título do item.',
    'procedimentos.createdSuccess': 'Procedimento criado.',
    'procedimentos.updatedSuccess': 'Procedimento atualizado.',
    'procedimentos.discardChangesTitle': 'Descartar alterações?',
    'procedimentos.discardChangesMessage':
        'As alterações feitas neste procedimento ainda não foram salvas.',
    'procedimentos.keepEditing': 'Continuar editando',
    'procedimentos.discard': 'Descartar',
    'procedimentos.confirmDeleteStageTitle': 'Excluir etapa?',
    'procedimentos.confirmDeleteStageMessage':
        'Os itens desta etapa também serão removidos.',
    'procedimentos.confirmDeleteItemTitle': 'Excluir item?',
    'procedimentos.confirmDeleteItemMessage':
        'Este item será removido do procedimento.',
    'procedimentos.editorDemoNotice':
        'As alterações serão mantidas apenas durante esta sessão.',
    'procedimentos.noStages': 'Nenhuma etapa adicionada',
    'procedimentos.itemRequiredHelp':
        'A lógica final de obrigatoriedade será definida na integração operacional.',
    'procedimentos.previewAction': 'Pré-visualizar',
    'procedimentos.demonstration': 'Demonstração',
    'procedimentos.responsePhoto': 'Tirar foto',
    'procedimentos.responseSignature': 'Assinatura',
    'procedimentos.responseLocation': 'Capturar localização',
    'procedimentos.responseBarcode': 'Ler código de barras',
    'procedimentos.responseImei': 'Informar IMEI',
    'procedimentos.responseDocument': 'Anexar documento',
    'procedimentos.responseAudio': 'Gravar áudio',
    'procedimentos.responseFreeText': 'Texto livre',
    'procedimentos.responseNumber': 'Número',
    'procedimentos.responseDate': 'Data',
    'procedimentos.responseSingleChoice': 'Escolha única',
    'procedimentos.responseMultipleChoice': 'Escolha múltipla',
    'procedimentos.responsePhotoDescription':
        'Simula a captura de uma foto como evidência.',
    'procedimentos.responseSignatureDescription':
        'Simula a coleta de uma assinatura.',
    'procedimentos.responseLocationDescription':
        'Simula a captura de uma localização.',
    'procedimentos.responseBarcodeDescription':
        'Simula a leitura de um código de barras.',
    'procedimentos.responseImeiDescription':
        'Permite informar um IMEI manualmente.',
    'procedimentos.responseDocumentDescription':
        'Simula o anexo de um documento.',
    'procedimentos.responseAudioDescription': 'Simula uma gravação de áudio.',
    'procedimentos.responseFreeTextDescription':
        'Permite registrar uma resposta em texto.',
    'procedimentos.responseNumberDescription':
        'Permite registrar um valor numérico.',
    'procedimentos.responseDateDescription': 'Permite selecionar uma data.',
    'procedimentos.responseSingleChoiceDescription':
        'Permite selecionar uma opção.',
    'procedimentos.responseMultipleChoiceDescription':
        'Permite selecionar uma ou mais opções.',
    'procedimentos.typeCategoryGuide': 'Orientar e confirmar',
    'procedimentos.typeCategoryCollect': 'Coletar informação',
    'procedimentos.typeCategoryEvidence': 'Registrar evidência',
    'procedimentos.typeCategoryIdentify': 'Identificar',
    'procedimentos.itemTypePickerHelp':
        'Escolha como o colaborador vai responder ou registrar esta ação.',
    'procedimentos.placeholderField': 'Placeholder',
    'procedimentos.unitField': 'Unidade',
    'procedimentos.choiceOptions': 'Opções de escolha',
    'procedimentos.addOption': 'Adicionar opção',
    'procedimentos.removeOption': 'Remover opção',
    'procedimentos.optionField': 'Opção',
    'procedimentos.validationChoiceOptions': 'Informe pelo menos duas opções.',
    'procedimentos.changeTypeTitle': 'Trocar tipo de item?',
    'procedimentos.changeTypeMessage':
        'As opções configuradas serão removidas para este tipo.',
    'procedimentos.simulatedTypeEditorHelp':
        'No modo demonstração, esta captura será simulada sem usar recursos do dispositivo.',
    'procedimentos.previewTitle': 'Pré-visualização',
    'procedimentos.previewUntitledProcedure': 'Procedimento sem nome',
    'procedimentos.previewIncompleteProcedure':
        'Este procedimento ainda não possui etapas para demonstrar.',
    'procedimentos.previewOf': 'de',
    'procedimentos.previewProgressLabel': 'Ações concluídas',
    'procedimentos.previewPendingMessage':
        'Existem ações obrigatórias pendentes nesta etapa.',
    'procedimentos.previewRequiredPending':
        'Responda esta ação obrigatória para continuar.',
    'procedimentos.previewNextStage': 'Próxima etapa',
    'procedimentos.previewFinishDemo': 'Finalizar',
    'procedimentos.previewReviewStages': 'Revisar etapas',
    'procedimentos.previewSummaryTitle': 'Demonstração concluída',
    'procedimentos.previewSummarySavedMessage': 'Nenhuma resposta foi salva.',
    'procedimentos.previewSummaryAnswered': 'Ações respondidas.',
    'procedimentos.previewSummaryNoOptionalPending':
        'Nenhum item opcional pendente.',
    'procedimentos.previewSummaryOptionalPending': 'Item opcional pendente.',
    'procedimentos.previewDiscardTitle': 'Descartar respostas?',
    'procedimentos.previewDiscardMessage':
        'As respostas desta demonstração serão descartadas ao sair.',
    'procedimentos.previewConfirmAction': 'Confirmar ação',
    'procedimentos.previewUnderstood': 'Marcar como entendido',
    'procedimentos.previewUnderstoodDone': 'Entendido',
    'procedimentos.previewTextHint': 'Digite a resposta',
    'procedimentos.previewNumberHint': 'Digite um número',
    'procedimentos.previewSelectDate': 'Selecionar data',
    'procedimentos.previewImeiHint': 'Digite o IMEI',
    'procedimentos.previewUseDemoImei': 'Usar IMEI demonstrativo',
    'procedimentos.previewTakePhoto': 'Tirar foto',
    'procedimentos.previewSimulateSignature': 'Simular assinatura',
    'procedimentos.previewCaptureLocation': 'Capturar localização',
    'procedimentos.previewSimulateBarcode': 'Simular leitura',
    'procedimentos.previewSimulateDocument': 'Simular anexo',
    'procedimentos.previewSimulateAudio': 'Simular gravação',
    'procedimentos.previewRemoveEvidence': 'Remover evidência',
    'procedimentos.simulatedResourceNotice':
        'Recurso demonstrativo. Nenhum dado real será capturado.',
    'procedimentos.previewPhotoAdded': 'Foto adicionada',
    'procedimentos.previewSignatureAdded': 'Assinatura adicionada',
    'procedimentos.previewSignatureDemoDetail':
        'Traço demonstrativo registrado',
    'procedimentos.previewLocationAdded':
        'Localização de demonstração capturada',
    'procedimentos.previewBarcodeAdded': 'Código lido',
    'procedimentos.previewDocumentAdded': 'Documento anexado',
    'procedimentos.previewAudioAdded': 'Áudio gravado',
    'procedimentos.operationCashRegister': 'Caixa',
    'procedimentos.operationCustomerRegistration': 'Cadastro de cliente',
    'procedimentos.triggerMomentBeforeStart': 'Antes de iniciar',
    'procedimentos.triggerMomentAfterStart': 'Após iniciar',
    'procedimentos.triggerMomentBeforeFinish': 'Antes de concluir',
    'procedimentos.triggerMomentAfterFinish': 'Após concluir',
    'procedimentos.triggerMomentBeforeDelivery': 'Antes da entrega',
    'procedimentos.triggerMomentAfterDelivery': 'Após a entrega',
    'procedimentos.triggerMomentOnDemand': 'Sob demanda',
    'procedimentos.activationManual': 'Manual',
    'procedimentos.activationAutomatic': 'Automático',
    'procedimentos.activationManualDescription':
        'O colaborador poderá iniciar este procedimento quando necessário.',
    'procedimentos.activationAutomaticDescription':
        'Na integração futura, o procedimento será apresentado no momento configurado.',
    'procedimentos.enforcementInformative': 'Informativo',
    'procedimentos.enforcementRecommended': 'Recomendado',
    'procedimentos.enforcementRequired': 'Obrigatório',
    'procedimentos.enforcementInformativeDescription':
        'Apresenta o procedimento sem exigir conclusão.',
    'procedimentos.enforcementRecommendedDescription':
        'Recomenda a conclusão, mas não deve bloquear a operação.',
    'procedimentos.enforcementRequiredDescription':
        'Na integração futura, exigirá conclusão antes de continuar.',
    'procedimentos.whenExecute': 'Quando executar',
    'procedimentos.addTrigger': 'Adicionar gatilho',
    'procedimentos.editTrigger': 'Editar gatilho',
    'procedimentos.deleteTrigger': 'Excluir gatilho',
    'procedimentos.noTriggers': 'Nenhum gatilho configurado.',
    'procedimentos.noTriggersDescription':
        'Sem gatilhos, o procedimento ficará disponível apenas para uso e pré-visualização dentro deste módulo.',
    'procedimentos.triggerCount': 'gatilhos',
    'procedimentos.selectOperationContext': 'Selecionar contexto',
    'procedimentos.selectTriggerMoment': 'Selecionar momento',
    'procedimentos.activationMode': 'Modo de execução',
    'procedimentos.enforcementMode': 'Nível de exigência',
    'procedimentos.triggerEnabledHelp':
        'Controla se este gatilho será considerado na integração futura.',
    'procedimentos.saveTrigger': 'Salvar gatilho',
    'procedimentos.triggerMomentCleared':
        'O momento foi limpo porque não é compatível com o contexto selecionado.',
    'procedimentos.validationTriggerOperation':
        'Escolha o contexto operacional.',
    'procedimentos.validationTriggerMoment': 'Escolha o momento de execução.',
    'procedimentos.validationTriggerMomentInvalid':
        'Escolha um momento compatível com o contexto.',
    'procedimentos.validationDuplicateTrigger':
        'Já existe um gatilho com este contexto, momento e modo de execução.',
    'procedimentos.deleteTriggerTitle': 'Excluir gatilho?',
    'procedimentos.deleteTriggerMessage':
        'O procedimento deixará de ser apresentado neste momento operacional.',
    'procedimentos.triggerSummaryNone': 'Sem gatilhos configurados',
    'procedimentos.triggerSummaryOnlyInactive': 'Gatilhos inativos',
    'procedimentos.executionConfiguration': 'Configuração de execução',
    'procedimentos.triggerSimulationNotice':
        'Simulação de gatilho. Nenhuma operação real será bloqueada.',
    'procedimentos.manualDemoExecution': 'Execução manual de demonstração.',
    'procedimentos.operationPointSaleStartBefore': 'Antes de iniciar uma venda',
    'procedimentos.operationPointSaleStartBeforeDescription':
        'Executado antes de abrir o fluxo de uma nova venda.',
    'procedimentos.mobilePointAvailable': 'Disponível no aplicativo mobile.',
    'procedimentos.operationalExecutionTitle': 'Antes de iniciar a venda',
    'procedimentos.operationalSummaryTitle': 'Procedimento concluído',
    'procedimentos.operationalNoDataSaved':
        'Nenhuma resposta foi salva nesta integração local experimental.',
    'procedimentos.completeAndStartSale': 'Concluir e iniciar venda',
    'procedimentos.experimentalIntegration': 'Integração experimental',
    'procedimentos.continueToStartSale': 'Continuar para a venda',
    'procedimentos.continueWithoutCompleting': 'Continuar sem concluir',
    'procedimentos.continueWithoutCompletingTitle': 'Continuar sem concluir?',
    'procedimentos.continueWithoutCompletingMessage':
        'Este procedimento é recomendado antes de iniciar a venda.',
    'procedimentos.continueAnyway': 'Continuar mesmo assim',
    'procedimentos.returnToProcedure': 'Voltar ao procedimento',
    'procedimentos.cancelSaleStartTitle': 'Cancelar início da venda?',
    'procedimentos.cancelSaleStartMessage':
        'Este procedimento é obrigatório. Ao sair, a nova venda não será iniciada.',
    'procedimentos.cancelSale': 'Cancelar venda',
    'procedimentos.sequenceProgressPrefix': 'Procedimento',
    'procedimentos.previewNegativeTextLabel': 'O que faltou?',
    'procedimentos.previewNegativeTextHint': 'Digite o que faltou',
    'procedimentos.operationalLoadError':
        'Não foi possível carregar os procedimentos.',
    'procedimentos.operationalBadge': 'Procedimento operacional',
    'procedimentos.operationalExecutionTitleReal': 'Procedimento operacional',
    'procedimentos.executionWillBeSaved':
        'As respostas e o horário serão salvos ao concluir.',
    'procedimentos.completeAndContinue': 'Concluir e continuar',
    'procedimentos.continueOperation': 'Continuar operação',
    'procedimentos.processingSkip': 'Continuando...',
    'procedimentos.processingCancel': 'Cancelando...',
    'procedimentos.executionSaveError':
        'Não foi possível salvar as respostas. Tente novamente.',
    'procedimentos.skipSuccessTitle': 'Procedimento ignorado',
    'procedimentos.cancelSuccessTitle': 'Operação cancelada',
    'procedimentos.completeSuccessMessage':
        'As respostas foram registradas e a operação pode continuar.',
    'procedimentos.skipSuccessMessage':
        'O procedimento foi ignorado e a operação seguirá conforme a configuração.',
    'procedimentos.cancelSuccessMessage':
        'A operação foi encerrada antes de seguir para a próxima etapa.',
    'procedimentos.persistedConfiguration': 'Configuração sincronizada',
    'procedimentos.editorPersistenceNotice':
        'As alterações são salvas para a empresa e respeitam o idioma atual.',
    'procedimentos.notifyAdmin': 'Notificar ADMIN por push',
    'procedimentos.notifyAdminHelp':
        'Avisa os administradores ativos quando a condição ocorrer.',
    'procedimentos.notificationCondition': 'Quando notificar',
    'procedimentos.notificationAlways': 'Em toda execução',
    'procedimentos.notificationNegative': 'Ao registrar resposta negativa',
    'procedimentos.notificationSkipped': 'Ao ignorar o procedimento',
    'procedimentos.analyticsTitle': 'Análise de resultados',
    'procedimentos.analyticsExecutions': 'Execuções',
    'procedimentos.analyticsCompletion': 'Taxa de conclusão',
    'procedimentos.analyticsNegative': 'Respostas negativas',
    'procedimentos.analyticsAverageTime': 'Tempo médio',
    'procedimentos.analyticsByQuestion': 'Resultados por pergunta',
    'procedimentos.analyticsRecent': 'Execuções recentes',
    'procedimentos.analyticsEmpty': 'Ainda não há execuções neste período.',
    'procedimentos.contextSale': 'Venda',
    'procedimentos.contextTechnicalService': 'Atendimento técnico',
    'procedimentos.contextCashRegister': 'Caixa',

    // Gestão — seções
    'gestao.title': 'Gestão',
    'gestao.hub.title': 'O que você quer gerenciar?',
    'gestao.hub.subtitle':
        'Acesse cadastros, pessoas, financeiro e preferências.',
    'gestao.hub.terminal.products': 'Gerencie seus produtos e colaboradores',
    'gestao.hub.terminal.finance': 'Gerencie seu financeiro',
    'gestao.hub.terminal.preferences':
        'Ajuste suas preferências e configurações',
    'gestao.catalog.title': 'Catálogo',
    'gestao.catalog.subtitle': 'Produtos, categorias e estoque',
    'gestao.people.title': 'Pessoas',
    'gestao.people.subtitle': 'Clientes, equipe e parceiros',
    'gestao.finance.title': 'Financeiro',
    'gestao.finance.subtitle': 'Contas, agenda e recebimentos',
    'gestao.settings.title': 'Configurações',
    'gestao.settings.selectorTitle': 'Geral',
    'gestao.settings.subtitle': 'Empresa, idioma e integrações',

    // Gestão — itens de Catálogo
    'gestao.catalog.productsServices': 'Produtos e Serviços',
    'gestao.catalog.productsServicesDesc':
        'Saúde, cadastro e revisão do catálogo',
    'gestao.catalog.categories': 'Categorias',
    'gestao.catalog.categoriesDesc': 'Organização do catálogo',
    'gestao.catalog.inventory': 'Estoque',
    'gestao.catalog.inventoryDesc': 'Saldos, entradas e ajustes',

    // Gestão — itens de Pessoas
    'gestao.people.clients': 'Clientes',
    'gestao.people.clientsDesc': 'Base de atendimento e relacionamento',
    'gestao.people.collaborators': 'Colaboradores',
    'gestao.people.collaboratorsDesc': 'Equipe, acessos e responsabilidades',
    'gestao.people.sixoUsers': 'Usuários do Sixo',
    'gestao.people.sixoUsersDesc':
        'Base global protegida pelo perfil SUPER',
    'gestao.people.suppliers': 'Fornecedores',
    'gestao.people.suppliersDesc': 'Parceiros e compras do comércio',
    'gestao.people.performance': 'Desempenho do colaborador',
    'gestao.people.performanceDesc':
        'Metas, vendas, serviços e evolução da equipe',

    // Desempenho do colaborador — mobile
    'performance.mobile.title': 'Desempenho',
    'performance.mobile.heroTitle': 'Desempenho da equipe',
    'performance.mobile.heroSubtitle':
        'Acompanhe metas, vendas, serviços e atendimentos por participante.',
    'performance.mobile.refresh': 'Atualizar desempenho',
    'performance.mobile.newGoal': 'Nova meta',
    'performance.mobile.editGoal': 'Editar meta',
    'performance.mobile.currentMonth': 'Mês atual',
    'performance.mobile.lastThirtyDays': 'Últimos 30 dias',
    'performance.mobile.today': 'Hoje',
    'performance.mobile.period': 'Período',
    'performance.mobile.participant': 'Participante',
    'performance.mobile.selectParticipant': 'Selecionar participante',
    'performance.mobile.searchParticipant': 'Buscar participante',
    'performance.mobile.noParticipant': 'Nenhum participante encontrado',
    'performance.mobile.noParticipantMessage':
        'Ajuste o filtro ou cadastre colaboradores para continuar.',
    'performance.mobile.allActive': 'Todos os ativos',
    'performance.mobile.allInactive': 'Todos os não ativos',
    'performance.mobile.allParticipants': 'Todos os participantes',
    'performance.mobile.active': 'Ativos',
    'performance.mobile.inactive': 'Não ativos',
    'performance.mobile.both': 'Ambos',
    'performance.mobile.score': 'Score médio',
    'performance.mobile.scoreDesc': 'Média ponderada das metas',
    'performance.mobile.goalsReached': 'Metas batidas',
    'performance.mobile.goalsReachedDesc': 'No período selecionado',
    'performance.mobile.sales': 'Vendas',
    'performance.mobile.salesOperations': '{count} operações no período',
    'performance.mobile.serviceCalls': 'Atendimentos',
    'performance.mobile.serviceCallsDesc': 'Assistências técnicas no período',
    'performance.mobile.resultsTab': 'Resultados',
    'performance.mobile.goalsTab': 'Metas',
    'performance.mobile.resultsTitle': 'Meta x realizado',
    'performance.mobile.resultsSubtitle':
        'Evolução calculada para o período selecionado.',
    'performance.mobile.goalsTitle': 'Metas cadastradas',
    'performance.mobile.goalsSubtitle':
        'Toque em uma meta para consultar ou editar.',
    'performance.mobile.noResults': 'Nenhuma meta ativa para exibir',
    'performance.mobile.noResultsDesc':
        'Ajuste os filtros ou cadastre uma nova meta.',
    'performance.mobile.noGoals': 'Sem metas cadastradas',
    'performance.mobile.noGoalsDesc':
        'Crie metas para acompanhar o desempenho da equipe.',
    'performance.mobile.loadError': 'Não foi possível carregar o desempenho.',
    'performance.mobile.loadErrorDesc':
        'Verifique sua conexão e tente novamente.',
    'performance.mobile.tryAgain': 'Tentar novamente',
    'performance.mobile.loading': 'Carregando desempenho da equipe',
    'performance.mobile.goalSaved': 'Meta cadastrada.',
    'performance.mobile.goalUpdated': 'Meta atualizada.',
    'performance.mobile.goalSaveError':
        'Não foi possível salvar a meta. Tente novamente.',
    'performance.mobile.noFilteredParticipant':
        'Não há participantes para o filtro selecionado.',
    'performance.mobile.indicator': 'Indicador',
    'performance.mobile.selectIndicator': 'Selecionar indicador',
    'performance.mobile.targetValue': 'Valor alvo',
    'performance.mobile.weight': 'Peso',
    'performance.mobile.startDate': 'Data inicial',
    'performance.mobile.endDate': 'Data final',
    'performance.mobile.applyDate': 'Aplicar data',
    'performance.mobile.status': 'Situação da meta',
    'performance.mobile.goalActive': 'Ativa',
    'performance.mobile.goalPaused': 'Pausada',
    'performance.mobile.goalClosed': 'Encerrada',
    'performance.mobile.createGoal': 'Cadastrar meta',
    'performance.mobile.saveGoal': 'Salvar meta',
    'performance.mobile.cancel': 'Cancelar',
    'performance.mobile.invalidPositiveNumber':
        'Informe um valor maior que zero',
    'performance.mobile.invalidDateRange':
        'A data final não pode ser anterior à data inicial.',
    'performance.mobile.participantFallback': 'Participante',
    'performance.mobile.noPeriod': 'Sem período',
    'performance.mobile.valueOfTarget': '{value} de {target}',
    'performance.mobile.statusAboveGoal': 'Acima da meta',
    'performance.mobile.statusInProgress': 'Em progresso',
    'performance.mobile.statusAtRisk': 'Em risco',
    'performance.mobile.statusCritical': 'Crítico',
    'performance.mobile.statusUnknown': 'Sem status',
    'performance.mobile.indicator.salesValue': 'Valor vendido',
    'performance.mobile.indicator.salesQuantity': 'Quantidade de vendas',
    'performance.mobile.indicator.servicesValue': 'Valor em serviços',
    'performance.mobile.indicator.serviceCalls': 'Atendimentos técnicos',
    'performance.mobile.indicator.finishedServiceCalls':
        'Atendimentos finalizados',
    'performance.mobile.indicator.serviceCallsValue': 'Valor em atendimentos',

    // Gestão — itens de Financeiro
    'gestao.finance.receivable': 'Contas a receber',
    'gestao.finance.receivableDesc': 'Recebíveis e cobranças em aberto',
    'gestao.finance.payable': 'Contas a pagar',
    'gestao.finance.payableDesc': 'Despesas e compromissos',
    'gestao.finance.schedule': 'Agenda financeira',
    'gestao.finance.scheduleDesc': 'Previsões, fiado e crediário',
    'gestao.finance.paymentMethods': 'Formas de recebimento',
    'gestao.finance.paymentMethodsDesc': 'Dinheiro, cartão, Pix e outros meios',

    // Gestão — grupos de Configurações
    'gestao.settings.group.company': 'Empresa',
    'gestao.settings.group.teamAccess': 'Equipe e acesso',
    'gestao.settings.group.operation': 'Operação',
    'gestao.settings.group.communication': 'Comunicação',
    'gestao.settings.group.docsIntegrations': 'Documentos e integrações',

    // Gestão — itens de Configurações
    'gestao.settings.item.company.title': 'Empresa',
    'gestao.settings.item.company.subtitle':
        'Dados cadastrais e identidade do comércio',
    'gestao.settings.item.regionalization.title': 'Regionalização',
    'gestao.settings.item.regionalization.subtitle':
        'Idioma, moeda, país e formatos locais',
    'gestao.settings.item.users.title': 'Usuários e permissões',
    'gestao.settings.item.users.subtitle':
        'Acessos, perfis e segurança da equipe',
    'gestao.settings.item.procedures.title': 'Procedimentos',
    'gestao.settings.item.procedures.subtitle':
        'Guias para vendas, atendimentos e entregas',
    'gestao.settings.item.notifications.title': 'Notificações',
    'gestao.settings.item.notifications.subtitle':
        'Eventos recebidos e alertas do sistema',
    'gestao.settings.item.pdfTemplates.title': 'Modelos de PDF',
    'gestao.settings.item.pdfTemplates.subtitle':
        'Orçamentos, OS, recibos e documentos',
    'gestao.settings.item.integrations.title': 'Integrações',
    'gestao.settings.item.integrations.subtitle':
        'Serviços externos e automações',

    // Gestão — visão contextual mobile
    'gestao.overview.selectedArea': 'Área selecionada',
    'gestao.overview.generalTitle': 'Visão geral',
    'gestao.overview.valueUnavailable': '--',
    'gestao.overview.mainActions': 'Ações principais',
    'gestao.overview.errorMessage':
        'As ações continuam disponíveis. Tente atualizar os dados em instantes.',
    'gestao.catalog.summaryTitle': 'Resumo do catálogo',
    'gestao.catalog.metric.products': 'Produtos',
    'gestao.catalog.metric.productsServices': 'Produtos e serviços',
    'gestao.catalog.metric.categories': 'Categorias',
    'gestao.catalog.metric.lowStock': 'Estoque baixo',
    'gestao.catalog.lowStockAlertSemantic':
        'Indicador de atenção para estoque baixo',
    'gestao.catalog.loadError':
        'Não foi possível carregar o resumo do catálogo.',
    'gestao.catalog.emptyTitle': 'Catálogo sem dados para exibir',
    'gestao.catalog.emptyMessage':
        'Cadastre produtos, serviços ou categorias para preencher os indicadores.',
    'gestao.catalog.permissionRestrictedTitle':
        'Catálogo restrito para este usuário',
    'gestao.catalog.permissionRestrictedMessage':
        'A ação de produtos e serviços respeita as permissões atuais.',
    'gestao.catalog.webCatalog': 'Catálogo web',
    'gestao.catalog.webCatalogDesc':
        'Experiência completa do catálogo no navegador',
    'gestao.catalog.webCatalogBadge': 'WEB',
    'gestao.catalog.lowStockTitle': 'Estoque precisa de atenção',
    'gestao.catalog.lowStockMessage':
        '{count} item(ns) abaixo do limite configurado no catálogo.',
    'gestao.catalog.lowStockAction': 'Ver itens',
    'gestao.people.summaryTitle': 'Resumo de pessoas',
    'gestao.people.metric.clients': 'Clientes',
    'gestao.people.metric.collaborators': 'Colaboradores',
    'gestao.people.metric.suppliers': 'Fornecedores',
    'gestao.people.suppliersUnavailableSemantic': 'Recurso em breve',
    'gestao.people.loadError': 'Não foi possível carregar o resumo de pessoas.',
    'gestao.people.emptyTitle': 'Nenhum contato carregado',
    'gestao.people.emptyMessage':
        'Clientes e colaboradores aparecerão aqui quando estiverem cadastrados.',
    'gestao.people.suppliersBlockedTitle': 'Fornecedores ainda não disponível',
    'gestao.people.suppliersBlockedMessage':
        'O recurso segue marcado como Em breve e não possui navegação mobile ativa.',
    'gestao.finance.actionGroup': 'Agenda e recursos',
    'gestao.finance.summaryTitle': 'Resumo financeiro',
    'gestao.finance.metric.events': 'Próximos eventos',
    'gestao.finance.metric.receivableEvents': 'A receber',
    'gestao.finance.metric.payableEvents': 'A pagar',
    'gestao.finance.loadError':
        'Não foi possível carregar a agenda financeira.',
    'gestao.finance.emptyTitle': 'Agenda sem lançamentos próximos',
    'gestao.finance.emptyMessage':
        'Abra a agenda financeira para criar previsões e acompanhar vencimentos.',
    'gestao.finance.openSchedule': 'Abrir agenda',
    'gestao.finance.attentionTitle': 'Agenda com vencimentos próximos',
    'gestao.finance.attentionMessage':
        '{count} evento(s) vencido(s) ou vencendo hoje na agenda.',
    'gestao.finance.blockedResourcesTitle': 'Recursos financeiros em evolução',
    'gestao.finance.blockedResourcesMessage':
        'Contas a receber, contas a pagar e formas de recebimento continuam bloqueadas no mobile.',

    // Atendimento mobile
    'atendimento.mobile.title': 'Atendimento',
    'atendimento.mobile.heroTitle': 'O que você deseja fazer?',
    'atendimento.mobile.heroSubtitle':
        'Venda, serviço ou recebimento em poucos passos',
    'atendimento.mobile.introTitle': 'Atendimento ao Cliente',
    'atendimento.mobile.introLineSales': 'vender, receber, consultar',
    'atendimento.mobile.introLineReturns': 'devoluções de produtos',
    'atendimento.mobile.introLineServices': 'serviços, orçamentos etc',
    'atendimento.mobile.chooseOperation': 'Escolha a operação para iniciar.',
    'atendimento.mobile.salesMenuTitle': 'Vendas',
    'atendimento.mobile.newSaleTitle': 'Vendas',
    'atendimento.mobile.newSaleSubtitle': 'Opções',
    'atendimento.mobile.consultSalesTitle': 'Consultar vendas',
    'atendimento.mobile.consultSalesSubtitle': 'Consultar histórico de vendas',
    'atendimento.mobile.newServiceTitle': 'Serviços',
    'atendimento.mobile.newServiceSubtitle': 'Criar ou acompanhar',
    'atendimento.mobile.servicesMenuTitle': 'Serviços',
    'atendimento.mobile.createServiceTitle': 'Novo serviço',
    'atendimento.mobile.createServiceSubtitle':
        'Abrir novo atendimento técnico',
    'atendimento.mobile.consultServicesInProgressTitle':
        'Consultar serviços em andamento',
    'atendimento.mobile.consultServicesInProgressSubtitle':
        'Ver atendimentos técnicos ativos',
    'atendimento.mobile.waitingApprovalBudgetsTitle':
        'Orçamentos aguardando aprovação',
    'atendimento.mobile.waitingApprovalBudgetsSubtitle':
        'Consulte serviços que ainda precisam da aprovação do cliente',
    'atendimento.mobile.receiveTitle': 'Receber',
    'atendimento.mobile.receiveSubtitle': 'Vendas em aberto',
    'atendimento.mobile.followToday': 'Acompanhe hoje',
    'atendimento.mobile.salesToReceiveTitle': 'Vendas a receber',
    'atendimento.mobile.salesToReceiveSubtitle': 'Vendas não liquidadas',
    'atendimento.mobile.servicesInProgressTitle': 'Serviços em andamento',
    'atendimento.mobile.servicesInProgressSubtitle':
        'Atendimentos técnicos ativos',
    'atendimento.mobile.moreOptions': 'Mais opções',
    'atendimento.mobile.cashOperationsTitle': 'Caixa',
    'atendimento.mobile.cashOperationsSubtitle': 'Abrir e movimentar',
    'atendimento.mobile.counterLoadError': 'Não foi possível atualizar agora',
    'atendimento.mobile.servicesToReceiveTitle': 'Serviços a receber',
    'atendimento.mobile.servicesToReceiveSubtitle':
        'Atendimentos técnicos com financeiro aberto',
    'atendimento.mobile.technicalServicesPendingPaymentTitle':
        'Atendimentos técnicos pendentes de pagamento',
    'atendimento.mobile.pendingPaymentsLoadingTitle': 'Carregando atendimentos',
    'atendimento.mobile.pendingPaymentsLoadingSubtitle':
        'Buscando serviços com financeiro em aberto.',
    'atendimento.mobile.pendingPaymentHeaderTitle': 'Financeiro aberto',
    'atendimento.mobile.pendingPaymentTotalOpen': 'Total em aberto',
    'atendimento.mobile.pendingPaymentSection': 'Atendimentos com saldo',
    'atendimento.mobile.pendingPaymentErrorTitle': 'Não foi possível carregar',
    'atendimento.mobile.pendingPaymentErrorMessage':
        'Tente atualizar os atendimentos técnicos em instantes.',
    'atendimento.mobile.pendingPaymentEmptyTitle': 'Nenhum serviço a receber',
    'atendimento.mobile.pendingPaymentEmptyMessage':
        'Os atendimentos técnicos estão sem financeiro em aberto.',
    'atendimento.mobile.onePendingPaymentService':
        '1 atendimento com financeiro aberto',
    'atendimento.mobile.pendingPaymentServices':
        'atendimentos com financeiro aberto',
    'atendimento.mobile.serviceNumber': 'Atendimento',
    'atendimento.mobile.openValue': 'Valor em aberto',
    'atendimento.mobile.totalValue': 'Valor total',
    'atendimento.mobile.dueDate': 'Vence em',
    'atendimento.mobile.noDueDate': 'Sem vencimento',
    'operacao.mobile.returnTitle': 'Devoluções e Trocas',
    'operacao.mobile.returnSubtitle': 'Registrar devolução',
    'operacao.mobile.returnUnavailable': 'Em breve',

    // Devoluções mobile
    'devolucao.mobile.title': 'Devoluções',
    'devolucao.mobile.introTitle': 'Localize a venda',
    'devolucao.mobile.introSubtitle':
        'Use o código do comprovante para iniciar uma devolução ou troca.',
    'devolucao.mobile.saleCodeLabel': 'Código ou ID da venda',
    'devolucao.mobile.saleCodeHint': 'Ex.: VEN-1024',
    'devolucao.mobile.searchSale': 'Buscar venda',
    'devolucao.mobile.searching': 'Buscando...',
    'devolucao.mobile.operationCompleted': 'Operação concluída',
    'devolucao.mobile.saleFound': 'Venda encontrada',
    'devolucao.mobile.changeSale': 'Trocar venda',
    'devolucao.mobile.unidentifiedCustomer': 'Cliente não identificado',
    'devolucao.mobile.productsValue': 'Valor dos produtos',
    'devolucao.mobile.returnBalance': 'Saldo devolvível',
    'devolucao.mobile.hasEligibleItems': 'Possui itens disponíveis',
    'devolucao.mobile.noEligibleBalance': 'Sem itens disponíveis',
    'devolucao.mobile.operationTypeTitle': 'O que será feito?',
    'devolucao.mobile.operationTypeSubtitle':
        'Escolha entre devolver ou trocar produtos.',
    'devolucao.mobile.returnOnly': 'Somente devolução',
    'devolucao.mobile.exchange': 'Troca',
    'devolucao.mobile.itemsTitle': 'Produtos que retornam',
    'devolucao.mobile.itemsSubtitle':
        'Selecione os itens e informe quantidade, condição e motivo.',
    'devolucao.mobile.noItems':
        'Esta venda não possui itens disponíveis para devolução.',
    'devolucao.mobile.soldValue': 'Vendido: {value}',
    'devolucao.mobile.availableValue': 'Disponível: {value}',
    'devolucao.mobile.quantity': 'Quantidade',
    'devolucao.mobile.maximumQuantity': 'Máximo: {value}',
    'devolucao.mobile.condition': 'Condição do produto',
    'devolucao.mobile.reason': 'Motivo da devolução',
    'devolucao.mobile.stockReturn': 'Retornar ao estoque',
    'devolucao.mobile.stockReturnOn':
        'O saldo disponível do produto será recomposto.',
    'devolucao.mobile.stockReturnOff':
        'A devolução será registrada sem recompor o estoque.',
    'devolucao.mobile.exchangeItemsTitle': 'Produtos da troca',
    'devolucao.mobile.exchangeItemsSubtitle':
        'Os novos produtos sairão do estoque pelo preço atual.',
    'devolucao.mobile.addProduct': 'Adicionar produto',
    'devolucao.mobile.exchangeEmpty':
        'Adicione o produto que o cliente receberá.',
    'devolucao.mobile.selectExchangeProduct': 'Escolher produto da troca',
    'devolucao.mobile.searchProduct': 'Buscar produto',
    'devolucao.mobile.noProductsTitle': 'Nenhum produto encontrado',
    'devolucao.mobile.noProductsMessage':
        'Revise a busca ou o cadastro de produtos ativos.',
    'devolucao.mobile.productPrice': 'Preço atual: {value}',
    'devolucao.mobile.perUnit': '{value} por unidade',
    'devolucao.mobile.remove': 'Remover produto',
    'devolucao.mobile.financialTitle': 'Acerto financeiro',
    'devolucao.mobile.returnedProducts': 'Produtos devolvidos',
    'devolucao.mobile.exchangeProducts': 'Produtos da troca',
    'devolucao.mobile.differenceReceive': 'Diferença a receber',
    'devolucao.mobile.refundValue': 'Valor a reembolsar',
    'devolucao.mobile.customerPays': 'O cliente paga a diferença.',
    'devolucao.mobile.companyRefunds': 'A empresa reembolsa o cliente.',
    'devolucao.mobile.noFinancialMovement': 'Não haverá movimento financeiro.',
    'devolucao.mobile.paymentMethod': 'Forma de pagamento ou reembolso',
    'devolucao.mobile.paymentHelper': 'Exige sessão de caixa aberta.',
    'devolucao.mobile.selectPayment': 'Selecionar forma',
    'devolucao.mobile.searchPayment': 'Buscar forma',
    'devolucao.mobile.noPaymentMethods': 'Nenhuma forma disponível',
    'devolucao.mobile.noPaymentMethodsMessage':
        'Configure uma forma de recebimento imediato antes de concluir.',
    'devolucao.mobile.reviewTitle': 'Revisar e concluir',
    'devolucao.mobile.reviewSubtitle':
        'Confirme os dados antes de movimentar estoque e caixa.',
    'devolucao.mobile.notes': 'Observações internas (opcional)',
    'devolucao.mobile.processing': 'Processando...',
    'devolucao.mobile.completeExchange': 'Concluir troca',
    'devolucao.mobile.completeReturn': 'Concluir devolução',
    'devolucao.mobile.confirmationHelper':
        'A confirmação pode movimentar estoque e registrar o acerto no caixa.',
    'devolucao.mobile.recentTitle': 'Operações recentes',
    'devolucao.mobile.recentSubtitle':
        'Últimas devoluções e trocas desta empresa.',
    'devolucao.mobile.loadingRecent': 'Carregando operações recentes',
    'devolucao.mobile.emptyRecent':
        'Nenhuma devolução ou troca concluída recentemente.',
    'devolucao.mobile.successMessage': 'Operação {code} concluída com sucesso.',
    'devolucao.mobile.unexpectedError':
        'Não foi possível concluir a operação. Tente novamente.',
    'devolucao.mobile.validation.saleRequired':
        'Informe o código ou identificador da venda.',
    'devolucao.mobile.validation.invalidQuantity':
        'Informe uma quantidade válida para {product}.',
    'devolucao.mobile.validation.quantityExceeded':
        'A quantidade de {product} supera o saldo devolvível.',
    'devolucao.mobile.validation.reasonRequired':
        'Informe o motivo da devolução de {product}.',
    'devolucao.mobile.validation.selectReturnItem':
        'Selecione pelo menos um produto para devolver.',
    'devolucao.mobile.validation.selectExchangeItem':
        'Adicione pelo menos um produto para a troca.',
    'devolucao.mobile.validation.selectPayment':
        'Selecione a forma usada no acerto da diferença.',
    'devolucao.mobile.condition.sealed': 'Novo / lacrado',
    'devolucao.mobile.condition.opened': 'Aberto',
    'devolucao.mobile.condition.used': 'Usado',
    'devolucao.mobile.condition.defective': 'Com defeito',
    'devolucao.mobile.condition.damaged': 'Avariado',
    'devolucao.mobile.condition.other': 'Outra condição',

    // Vendas não liquidadas mobile
    'vendasNaoLiquidadas.recebimentos': 'Recebimentos',
    'vendasNaoLiquidadas.semRecebimentos': 'Nenhum recebimento lançado.',
    'vendasNaoLiquidadas.referencia': 'Referência',
    'vendasNaoLiquidadas.recebimento': 'Recebimento',
    'vendasNaoLiquidadas.recebimentoTotal': 'Total',
    'vendasNaoLiquidadas.recebimentoParcial': 'Parcial',

    // Gestão — badges e cabeçalho admin
    'gestao.settings.badge.experimental': 'Experimental',
    'gestao.settings.badge.comingSoon': 'Em breve',
    'gestao.settings.adminHeader.title': 'Configurações da empresa',
    'gestao.settings.adminHeader.subtitle':
        'Organize empresa, equipe, operação e comunicação.',
    'gestao.featureInProgress': 'Fluxo mobile em evolução.',
    'produto.webList.selection.titleMany': 'Selecionar itens',
    'produto.webList.selection.titleOne': 'Selecionar item',
    'produto.webList.selection.subtitleMany':
        'Marque produtos e serviços e adicione tudo na venda de uma vez.',
    'produto.webList.selection.subtitleOne':
        'Busca rápida para incluir produto ou serviço na venda.',
    'produto.webList.edit.title': 'Editar produtos',
    'produto.webList.edit.subtitle':
        'Gerencie seu catálogo de produtos, estoque, preços e imagens.',
    'produto.webList.default.subtitle':
        'Consulta rápida do catálogo com ações de balcão.',
    'produto.webList.newItem': 'Novo item',
    'produto.webList.printPdf': 'Imprimir PDF',
    'produto.webList.publicCatalogLink': 'Link do catálogo',
    'produto.webList.publicCatalogPreparing': 'Preparando...',
    'produto.webList.publicCatalogCopied': 'Link público do catálogo copiado.',
    'produto.webList.publicCatalogError':
        'Não foi possível preparar o link do catálogo.',
    'catalogReservations.title': 'Reservas do catálogo',
    'catalogReservations.subtitle':
        'Acompanhe solicitações recebidas pelo catálogo virtual.',
    'catalogReservations.loadingTitle': 'Carregando reservas',
    'catalogReservations.loadingSubtitle':
        'Sincronizando as solicitações deste comércio.',
    'catalogReservations.detailLoading': 'Carregando detalhes',
    'catalogReservations.detailLoadingSubtitle':
        'Buscando os produtos e dados do cliente.',
    'catalogReservations.detailTitle': 'Detalhes da reserva',
    'catalogReservations.empty': 'Nenhuma reserva encontrada.',
    'catalogReservations.error': 'Não foi possível carregar as reservas.',
    'catalogReservations.status': 'Status',
    'catalogReservations.filters.apply': 'Aplicar',
    'catalogReservations.filters.clear': 'Limpar filtros',
    'catalogReservations.filters.status.selectedCount': '{count} selecionados',
    'catalogReservations.filters.period': 'Período',
    'catalogReservations.filters.start': 'Início',
    'catalogReservations.filters.end': 'Fim',
    'catalogReservations.filters.date': 'Data',
    'catalogReservations.filters.date.all': 'Todas as datas',
    'catalogReservations.filters.date.today': 'Hoje',
    'catalogReservations.filters.date.yesterday': 'Ontem',
    'catalogReservations.filters.date.last7Days': 'Ultimos 7 dias',
    'catalogReservations.filters.date.next7Days': 'Proximos 7 dias',
    'catalogReservations.filters.date.thisMonth': 'Este mês',
    'catalogReservations.filters.date.nextMonth': 'Próximo mês',
    'catalogReservations.filters.date.customRange': 'Intervalo personalizado',
    'catalogReservations.filters.date.pick': 'Escolher data',
    'catalogReservations.filters.date.pickRange': 'De dia a tal dia',
    'catalogReservations.filters.date.helpText': 'Selecionar data',
    'catalogReservations.filters.date.startHelpText': 'Selecionar data inicial',
    'catalogReservations.filters.date.endHelpText': 'Selecionar data final',
    'catalogReservations.filters.date.rangeHelpText': 'Selecionar periodo',
    'catalogReservations.status.received': 'Recebida',
    'catalogReservations.status.analysis': 'Em análise',
    'catalogReservations.status.confirmed': 'Confirmada',
    'catalogReservations.status.cancelled': 'Cancelada',
    'catalogReservations.status.converted': 'Convertida em venda',
    'catalogReservations.convert.title': 'Converter em venda',
    'catalogReservations.convert.description':
        'Valida o estoque e cria uma venda a receber com estes produtos.',
    'catalogReservations.convert.action': 'Converter em venda',
    'catalogReservations.convert.processing': 'Convertendo...',
    'catalogReservations.convert.confirmTitle': 'Converter reserva em venda?',
    'catalogReservations.convert.confirmMessage':
        'O estoque será validado e os itens serão enviados para uma venda a receber.',
    'catalogReservations.convert.success':
        'Reserva convertida em venda a receber.',
    'catalogReservations.convert.convertedTitle': 'Venda criada',
    'catalogReservations.convert.saleId': 'Venda',
    'catalogReservations.convert.error.stock':
        'Estoque insuficiente para converter esta reserva.',
    'catalogReservations.convert.error.confirmedOnly':
        'Confirme a reserva antes de convertê-la em venda.',
    'catalogReservations.convert.error.processing':
        'Esta reserva já está sendo convertida. Atualize a tela.',
    'catalogReservations.convert.error.paymentConfig':
        'Configure um tipo de recebimento futuro antes da conversão.',
    'catalogReservations.convert.error.product':
        'Um dos produtos reservados não está mais disponível.',
    'catalogReservations.convert.error.generic':
        'Não foi possível converter a reserva em venda.',
    'catalogReservations.items': 'itens',
    'catalogReservations.products': 'Produtos reservados',
    'catalogReservations.notes': 'Observação',
    'catalogReservations.noNotes': 'Nenhuma observação informada.',
    'catalogReservations.previous': 'Página anterior',
    'catalogReservations.next': 'Próxima página',
    'produto.webList.edit.banner':
        'Modo edição ativo • {count} itens encontrados • clique em um produto para alterar.',
    'produto.webList.searchHint': 'Buscar por nome, código ou SKU...',
    'produto.webList.preferenceSaved':
        'Preferência de visualização atualizada.',
    'produto.webList.view.vertical': 'Vertical',
    'produto.webList.view.horizontal': 'Horizontal',
    'produto.webList.view.list': 'Lista',
    'produto.webList.view.grid': 'Grade',
    'produto.webList.filter.category': 'Categoria',
    'produto.webList.filter.categoryAll': 'Todas categorias',
    'produto.webList.filter.flags': 'Marcadores',
    'produto.webList.filter.flagsAll': 'Todos itens',
    'produto.webList.filter.flagsFavorites': 'Favoritos',
    'produto.webList.filter.flagsCatalog': 'No catálogo',
    'produto.webList.filter.flagsFavoritesCatalog': 'Favoritos e catálogo',
    'produto.webList.filter.statusAll': 'Todos',
    'produto.webList.filter.stockAll': 'Todos',
    'produto.webList.filter.stockAvailable': 'Em estoque',
    'produto.webList.filter.stockLow': 'Estoque baixo',
    'produto.webList.filter.stockOut': 'Sem estoque',
    'produto.webList.filter.stockNegative': 'Estoque negativo',
    'produto.webList.sort.label': 'Ordenação',
    'produto.webList.sort.name': 'Ordenar por nome',
    'produto.webList.sort.priceAsc': 'Menor preço',
    'produto.webList.sort.priceDesc': 'Maior preço',
    'produto.webList.quick.withImage': 'Com imagem',
    'produto.webList.quick.lowStock': 'Estoque baixo',
    'produto.webList.errorTitle': 'Não foi possível carregar o catálogo.',
    'produto.webList.itemWithoutName': 'Item sem nome',
    'produto.webList.table.product': 'Produto',
    'produto.webList.table.category': 'Categoria',
    'produto.webList.table.code': 'Código',
    'produto.webList.table.price': 'Preço',
    'produto.webList.itemsPerPageLabel': 'Itens por página',
    'produto.webList.pagination.summary':
        'Exibindo {start} a {end} de {total} itens',
    'produto.webList.stockNotApplicable': 'Sem controle',
    'produto.webList.stockQuantity': 'Qtd {value}',
    'produto.webList.stockLow': 'Estoque baixo',
    'produto.webList.stockOut': 'Sem estoque',
    'produto.webList.stockNegative': 'Estoque negativo',
    'produto.webList.codeUnavailable': 'Sem código',
    'produto.webList.viewAction': 'Ver',
    'produto.favorite.addTooltip': 'Marcar como favorito',
    'produto.favorite.removeTooltip': 'Remover dos favoritos',
    'produto.favorite.enabledFeedback': 'Favorito ativado',
    'produto.favorite.disabledFeedback': 'Favorito desativado',
    'produto.favorite.updateError':
        'Não foi possível atualizar o favorito do produto.',
    'produto.catalog.enableTooltip': 'Disponibilizar para catálogo',
    'produto.catalog.disableTooltip':
        'Retirar da disponibilidade para catálogo',
    'produto.catalog.enabledFeedback': 'Disponível para catálogo ativado',
    'produto.catalog.disabledFeedback': 'Disponível para catálogo desativado',
    'produto.catalog.updateError':
        'Não foi possível atualizar a disponibilidade no catálogo.',
    'produto.catalog.statusLabel': 'Catálogo',
    'produto.catalog.availableStatus': 'Disponível',
    'produto.catalog.unavailableStatus': 'Indisponível',
  },
  'en': {
    'produto.journey.changeMode': 'Change',
    'clientes.journey.title': 'Choose the registration journey',
    'clientes.journey.subtitle':
        'Save only the essentials or enrich the customer profile now.',
    'clientes.journey.simpleTitle': 'Simple registration',
    'clientes.journey.simpleSubtitle':
        'Name, document, phone and email for a frictionless registration.',
    'clientes.journey.completeTitle': 'Complete registration',
    'clientes.journey.completeSubtitle':
        'Address, credit and context for a better-prepared operation.',
    'clientes.journey.stepEssential': 'Essentials',
    'clientes.journey.stepAddress': 'Address',
    'clientes.journey.stepRelationship': 'Credit and relationship',
    'clientes.journey.step': 'Step',
    'clientes.journey.of': 'of',
    'clientes.journey.reviewBeforeSave': 'Review the data before saving.',
    'clientes.journey.continueHint': 'Continue when this step is ready.',
    'clientes.quality.title': 'Registration quality',
    'clientes.quality.levelInitial': 'Just getting started',
    'clientes.quality.levelEssential': 'Essential profile ready',
    'clientes.quality.levelDetailed': 'Well-detailed profile',
    'clientes.quality.levelExcellent': 'Excellent profile',
    'clientes.quality.actionName': 'add a name',
    'clientes.quality.actionDocument': 'add a document',
    'clientes.quality.actionPhone': 'add a phone',
    'clientes.quality.actionEmail': 'add an email',
    'clientes.quality.actionZip': 'add a postal code',
    'clientes.quality.actionAddress': 'complete the address',
    'clientes.quality.actionCredit': 'configure credit',
    'clientes.quality.actionNotes': 'add context',
    'clientes.form.invalidEmail': 'Enter a valid email',
    'produto.quality.title': 'Registration quality',
    'produto.quality.levelEssential': 'Essential',
    'produto.quality.levelReady': 'Ready to sell',
    'produto.quality.levelPrepared': 'Well prepared',
    'produto.quality.levelExcellent': 'Excellent',
    'produto.quality.nextActions': 'Next improvements that increase quality:',
    'produto.quality.completeMessage':
        'Registration is well prepared for this level.',
    'produto.quality.actionName': 'Enter name',
    'produto.quality.actionPrice': 'Add price',
    'produto.quality.actionCategory': 'Choose category',
    'produto.quality.actionIdentifier': 'Add code',
    'produto.quality.actionOrganization': 'Enter group',
    'produto.quality.actionStock': 'Configure stock',
    'produto.quality.actionImage': 'Add image',
    'produto.quality.actionDetails': 'Complete details',
    'produto.quality.actionRules': 'Review rules',
    'produto.quality.actionFiscal': 'Enter tax data',
    'app.title': 'SixoApp',
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.back': 'Back',
    'common.close': 'Close',
    'common.edit': 'Edit',
    'common.delet\u0065': 'Delete',
    'common.search': 'Search',
    'common.clear': 'Clear',
    'common.confirm': 'Confirm',
    'common.apply': 'Apply',
    'common.continue': 'Continue',
    'common.tryAgain': 'Try again',
    'common.loading': 'Loading...',
    'common.noResults': 'No results found',
    'common.unexpectedError': 'Unexpected error',
    'common.unableToLoad': 'Could not load.',
    'common.savedSuccessfully': 'Settings saved successfully.',
    'common.yes': 'Yes',
    'common.no': 'No',
    'common.active': 'Active',
    'common.inactive': 'Inactive',
    'common.online': 'Online',
    'common.offline': 'Offline',
    'common.required': 'Required',
    'common.optional': 'Optional',
    'common.soon': 'Coming soon',
    'common.refresh': 'Refresh',
    'common.copy': 'Copy',
    'common.share': 'Share',
    'common.number': 'Number',
    'common.all': 'All',
    'common.customer': 'Customer',
    'common.updatedAt': 'Updated at',
    'common.lastUpdatedAt': 'Last updated at',
    'common.notInformed': 'Not informed',
    'pdv.quantityEditor.title': 'Edit quantity',
    'pdv.quantityEditor.tooltip': 'Edit quantity',
    'pdv.quantityEditor.subtitle':
        'Review the item and apply the new quantity. The item subtotal and sale total will be recalculated immediately.',
    'pdv.quantityEditor.codeLabel': 'Code',
    'pdv.quantityEditor.currentLabel': 'Current quantity',
    'pdv.quantityEditor.currentHint':
        'Fine adjustment remains available on the side buttons.',
    'pdv.quantityEditor.fieldLabel': 'New quantity',
    'pdv.quantityEditor.hint': 'Enter the desired quantity for this item.',
    'pdv.quantityEditor.invalid': 'Enter a whole quantity greater than zero.',
    'pdv.quantityEditor.effectHint':
        'The change updates the item subtotal and the sale total immediately.',
    'pdv.quantityEditor.confirm': 'Apply quantity',
    'pdv.customerIdentification.title': 'Identify customer',
    'pdv.customerIdentification.subtitle':
        'Select a registered customer or create a new one without leaving this step.',
    'pdv.customerIdentification.availableCustomers': 'Active customers',
    'pdv.customerIdentification.currentCustomer': 'Current customer',
    'pdv.customerIdentification.currentEmpty': 'No customer linked',
    'pdv.customerIdentification.searchLabel':
        'Search customer by name, document, phone or email',
    'pdv.customerIdentification.loading': 'Loading active customers...',
    'pdv.customerIdentification.loadError': 'Unable to load customers.',
    'pdv.customerIdentification.errorTitle': 'Unable to load customers',
    'pdv.customerIdentification.newCustomer': 'Create customer',
    'pdv.customerIdentification.openingCreate': 'Opening registration...',
    'pdv.customerIdentification.createError':
        'Unable to open customer registration right now.',
    'pdv.customerIdentification.emptyTitle': 'No active customers registered',
    'pdv.customerIdentification.emptyMessage':
        'Create the customer now to continue without leaving this step.',
    'pdv.customerIdentification.emptySearchTitle': 'No customer found',
    'pdv.customerIdentification.emptySearchMessage':
        'Review the search terms or create a new customer to continue.',
    'pdv.customerIdentification.removeCustomer': 'Remove current customer',
    'pdv.customerIdentification.unnamedCustomer': 'Unnamed customer',
    'pdv.customerIdentification.personTypeFallback': 'PF',
    'pdv.customerIdentification.noDocument': 'No document',
    'pdv.customerIdentification.creditEnabled': 'Store credit enabled',
    'pdv.customerIdentification.creditBlocked':
        'Store credit blocked for new sales',
    'pdv.customerIdentification.creditDisabled':
        'Customer without store credit enabled',
    'pdv.customerIdentification.selected': 'Selected',
    'pdv.customerIdentification.select': 'Select',
    'pdv.quantityEditor.processing': 'Applying quantity...',
    'pdv.quantityEditor.successTitle': 'Quantity updated',
    'pdv.quantityEditor.successMessage':
        'The item was recalculated and the sale already reflects the new quantity.',
    'pdv.quantityEditor.error':
        'Could not update the quantity right now. Try again in a moment.',
    'pdv.clearSale.dialogBarrier': 'Confirm clearing the current sale',
    'pdv.clearSale.dialogTitle': 'Clear current sale?',
    'pdv.clearSale.dialogSubtitle':
        'Review the summary before clearing. The current service will be reset so you can start a new sale.',
    'pdv.clearSale.summaryItems': 'Items',
    'pdv.clearSale.summaryTotal': 'Total',
    'pdv.clearSale.summaryCustomer': 'Customer',
    'pdv.clearSale.confirmAction': 'Clear sale',
    'pdv.clearSale.impactHint':
        'Items, identified customer and temporary receipts will be removed from this POS.',
    'pdv.clearSale.processingTitle': 'Clearing sale...',
    'pdv.clearSale.processingMessage':
        'Please wait while the temporary data from this sale is removed.',
    'pdv.clearSale.successTitle': 'Sale cleared successfully',
    'pdv.clearSale.successMessage': 'The POS is ready to start a new sale.',
    'pdv.clearSale.error':
        'Unable to clear the sale right now. Please try again shortly.',
    'recebimento.valorEmAberto': 'Outstanding amount',
    'recebimento.summaryType': 'Type',
    'recebimento.total': 'Full',
    'recebimento.parcial': 'Partial',
    'recebimento.formasRecebimento': 'Payment methods',
    'recebimento.restante': 'Remaining',
    'recebimento.valorForma': 'Method amount',
    'recebimento.tipoRecebimento': 'Payment method',
    'recebimento.carregandoTipos': 'Loading payment methods...',
    'recebimento.adicionarForma': 'Add method',
    'recebimento.removerForma': 'Remove method',
    'recebimento.observacao': 'Notes',
    'recebimento.receberTotal': 'Receive full amount',
    'recebimento.receberParcial': 'Receive partial amount',
    'recebimento.erroValoresMaioresQueZero': 'Enter amounts greater than zero.',
    'recebimento.erroValorMaiorQueZero': 'Enter an amount greater than zero.',
    'recebimento.erroParcialMenorQueAberto':
        'For a partial receipt, enter less than the outstanding amount.',
    'recebimento.erroTotalIgualSaldo':
        'For a full receipt, the amount must settle the outstanding balance.',
    'recebimento.erroFormaDuplicada':
        'Each payment method can be used only once.',
    'pdv.receipt.type': 'Receipt type',
    'pdv.receipt.partialReady':
        'Partial receipt ready. The remaining balance will stay open.',
    'pdv.receipt.partialHint':
        'Enter an amount greater than zero and lower than the sale total.',
    'pdv.receipt.partialDefined': 'Partial defined',
    'pdv.receipt.confirmPartial': 'Confirm partial receipt',
    'pdv.receipt.confirmPartialMessage': 'Do you want to receive',
    'pdv.receipt.keepOpenBalance': 'and keep the remaining balance outstanding',
    'vendasAReceber.openInPdv': 'Open in POS',
    'pdv.openSale.status': 'Open sale',
    'pdv.openSale.readOnlyStatus': 'View only',
    'pdv.openSale.readOnlyTitle': 'Open sale review',
    'pdv.openSale.readOnlySubtitle':
        'Products, quantities, and prices are locked at this stage. Review the data and receive the outstanding balance.',
    'pdv.openSale.editStatus': 'Item editing',
    'pdv.openSale.editTitle': 'Review the items before receiving',
    'pdv.openSale.editSubtitle':
        'Add or remove products and services and change quantities. Original prices are preserved; new items use the current catalog price. Changes are applied only when receiving.',
    'pdv.openSale.partialReadOnlySubtitle':
        'This sale already has receipts. To preserve the financial history, its items remain locked.',
    'pdv.openSale.pendingChanges': 'Pending changes',
    'pdv.openSale.receiveBalance': 'Receive balance',
    'pdv.openSale.receiveUpdatedSale': 'Receive revised sale',
    'pdv.openSale.receiveTitle': 'Receive sale balance',
    'pdv.openSale.receiptNote': 'Balance received through the web POS.',
    'pdv.openSale.updatedReceiptNote':
        'Revised sale received through the web POS.',
    'pdv.openSale.receivedMessage': 'Sale received successfully.',
    'pdv.openSale.receiptErrorTitle': 'Unable to receive the sale',
    'pdv.openSale.originalTotal': 'Original total',
    'pdv.openSale.openBalance': 'Outstanding balance',
    'pdv.openSale.currentTotal': 'New total',
    'pdv.openSale.totalDifference': 'Difference',
    'pdv.openSale.emptyItemsTitle': 'The sale must have items',
    'pdv.openSale.emptyItemsMessage':
        'Add at least one product or service before receiving the sale.',
    'pdv.openSale.invalidItemsTitle': 'Review the sale items',
    'pdv.openSale.invalidItemsMessage':
        'Every item must have a name, a positive quantity, and a valid price.',
    'pdv.openSale.confirmChangesTitle': 'Confirm revised items?',
    'pdv.openSale.confirmChangesMessage':
        'When receiving, the revised item composition will be applied and inventory and finance will be reconciled.',
    'pdv.openSale.continueToReceipt': 'Continue to receipt',
    'pdv.openSale.outdatedTitle': 'The sale has changed',
    'pdv.openSale.outdatedMessage':
        'Another operation changed this sale. Close the review and open it again to use the current data.',
    'pdv.openSale.exitTitle': 'Exit review?',
    'pdv.openSale.exitMessage':
        'The sale will remain open. No item, price, or receipt will be changed.',
    'pdv.openSale.exitAction': 'Exit review',
    'pdv.openSale.discardTitle': 'Discard changes?',
    'pdv.openSale.discardMessage':
        'Changes made in the POS will not be saved. The sale will remain open with its previous data.',
    'pdv.openSale.discardAction': 'Discard and exit',
    'pdv.openSale.replaceTitle': 'Replace the current sale?',
    'pdv.openSale.replaceMessage':
        'The current POS data will be replaced by the selected open sale.',
    'pdv.openSale.replaceAction': 'Open sale',
    'pdv.openSale.loadedMessage':
        'Sale loaded for review. You can add, remove, and change quantities before receiving.',
    'pdv.openSale.loadedReadOnlyMessage':
        'Sale loaded for review. Because it already has receipts, its items remain locked.',
    'pdv.openSale.loadErrorTitle': 'Unable to open the sale',
    'pdv.openSale.unavailableTitle': 'Sale unavailable',
    'pdv.openSale.unavailableMessage':
        'The sale may have been received or canceled by another user.',
    'common.generating': 'Generating...',
    'common.saving': 'Saving...',
    'common.rangeTo': 'to',
    'common.weekday.monday': 'Monday',
    'common.weekday.tuesday': 'Tuesday',
    'common.weekday.wednesday': 'Wednesday',
    'common.weekday.thursday': 'Thursday',
    'common.weekday.friday': 'Friday',
    'common.weekday.saturday': 'Saturday',
    'common.weekday.sunday': 'Sunday',
    'common.weekdayShort.monday': 'Mon',
    'common.weekdayShort.tuesday': 'Tue',
    'common.weekdayShort.wednesday': 'Wed',
    'common.weekdayShort.thursday': 'Thu',
    'common.weekdayShort.friday': 'Fri',
    'common.weekdayShort.saturday': 'Sat',
    'common.weekdayShort.sunday': 'Sun',
    'web.navigation.home': 'Home',
    'web.navigation.operations': 'Operations',
    'web.navigation.operations.pos': 'Point of sale',
    'web.navigation.operations.technicalService': 'Technical services',
    'web.navigation.operations.purchases': 'Purchases',
    'web.navigation.operations.reservations': 'Reservations',
    'web.navigation.catalog': 'Catalog',
    'web.navigation.catalog.publicPage': 'Public page',
    'web.navigation.catalog.reservations': 'Reservations',
    'web.navigation.catalog.products': 'Products',
    'web.navigation.catalog.services': 'Services',
    'web.navigation.catalog.stock': 'Stock',
    'web.navigation.catalog.categories': 'Categories',
    'catalog.publicPage.title': 'Public catalog page',
    'catalog.publicPage.subtitle':
        'Customize, preview, and share your storefront in one place.',
    'catalog.publicPage.open': 'Open',
    'catalog.publicPage.copy': 'Copy link',
    'catalog.publicPage.share': 'Share',
    'catalog.publicPage.published': 'Published',
    'catalog.publicPage.offline': 'Offline',
    'catalog.publicPage.save': 'Save changes',
    'catalog.publicPage.discard': 'Discard',
    'catalog.publicPage.saveSuccessPublished':
        'Page saved and published successfully.',
    'catalog.publicPage.saveSuccessDraft':
        'Customization saved. Publish it when it is ready.',
    'catalog.publicPage.saveError': 'Could not save the catalog page.',
    'catalog.publicPage.openError': 'Could not open the catalog in a new tab.',
    'catalog.publicPage.linkCopied': 'Public link copied.',
    'catalog.publicPage.shareSubject': '{title} catalog',
    'catalog.publicPage.shareFallback':
        'Sharing is unavailable. The public link was copied.',
    'catalog.publicPage.loadErrorTitle': 'Could not load the public page',
    'catalog.publicPage.editor.publication': 'Published catalog',
    'catalog.publicPage.editor.publicationOn':
        'Customers can access it through the public link.',
    'catalog.publicPage.editor.publicationOff':
        'The link is preserved but unavailable.',
    'catalog.publicPage.editor.content': 'Introduction',
    'catalog.publicPage.editor.contentHelp':
        'Set the message that opens your storefront.',
    'catalog.publicPage.editor.titleLabel': 'Storefront title',
    'catalog.publicPage.editor.titleHint': 'Example: Find what you need',
    'catalog.publicPage.editor.descriptionLabel': 'Short description',
    'catalog.publicPage.editor.descriptionHint':
        'Explain in one sentence what customers will find.',
    'catalog.publicPage.editor.appearance': 'Appearance',
    'catalog.publicPage.editor.appearanceHelp':
        'Choose the visual mood and accent color.',
    'catalog.publicPage.editor.accentColor': 'Accent color',
    'catalog.publicPage.editor.customColor': 'Custom color',
    'catalog.publicPage.editor.invalidColor':
        'Use a high-contrast hexadecimal color, such as #126BFF.',
    'catalog.publicPage.editor.layout': 'Content and layout',
    'catalog.publicPage.editor.layoutHelp':
        'Control density and visible information.',
    'catalog.publicPage.editor.comfortable': 'Comfortable',
    'catalog.publicPage.editor.compact': 'Compact',
    'catalog.publicPage.editor.showPrices': 'Show prices',
    'catalog.publicPage.editor.showContact': 'Show contact details',
    'catalog.publicPage.editor.showAddress': 'Show address',
    'catalog.publicPage.style.classic': 'Classic',
    'catalog.publicPage.style.classicHelp':
        'Professional, balanced, and familiar.',
    'catalog.publicPage.style.minimal': 'Minimal',
    'catalog.publicPage.style.minimalHelp':
        'More space and fewer visual elements.',
    'catalog.publicPage.style.expressive': 'Expressive',
    'catalog.publicPage.style.expressiveHelp':
        'Color and contrast to highlight your brand.',
    'catalog.publicPage.preview.title': 'Live preview',
    'catalog.publicPage.preview.unsaved': 'Previewing unsaved changes',
    'catalog.publicPage.preview.saved': 'Appearance saved to the catalog',
    'catalog.publicPage.preview.desktop': 'Desktop',
    'catalog.publicPage.preview.mobile': 'Mobile',
    'catalog.publicPage.preview.storeFallback': 'Your business',
    'catalog.publicPage.preview.products': 'Available products',
    'catalog.publicPage.preview.chooseItems': 'Choose your items',
    'catalog.publicPage.preview.empty':
        'Mark products as available for the catalog.',
    'catalog.publicPage.unpublish.barrier': 'Confirm catalog unpublishing',
    'catalog.publicPage.unpublish.title': 'Unpublish catalog?',
    'catalog.publicPage.unpublish.body':
        'Customers with the link will no longer see products until it is published again.',
    'catalog.publicPage.unpublish.action': 'Unpublish',
    'catalog.publicPage.unpublish.processing': 'Taking the catalog offline...',
    'catalog.publicPage.unpublish.processingBody':
        'Please wait while we update public access.',
    'catalog.publicPage.unpublish.success': 'Catalog unpublished',
    'catalog.publicPage.unpublish.successBody':
        'The link was preserved and can be reactivated later.',
    'catalog.publicPage.unpublish.error':
        'Could not unpublish. Please try again.',
    'produto.dashboard.importSpreadsheetSoon':
        'Import via spreadsheet (coming soon)',
    'web.navigation.people': 'People',
    'web.navigation.people.customers': 'Customers',
    'web.navigation.people.collaborators': 'Team members',
    'web.navigation.people.sixoUsers': 'Sixo users',
    'web.navigation.people.performance': 'Performance',
    'web.navigation.cash': 'Cash register',
    'web.navigation.financial': 'Financial',
    'web.navigation.financial.agenda': 'Financial agenda',
    'web.navigation.settings': 'Settings',
    'web.navigation.reports': 'Reports',
    'web.navigation.unavailable': 'Destination unavailable in this version.',
    'usuariosSixo.title': 'Sixo users',
    'usuariosSixo.subtitle':
        'View all registered users with access restricted to the SUPER role.',
    'usuariosSixo.summarySemantics': 'Registered Sixo users summary',
    'usuariosSixo.summaryTitle': 'Global user base',
    'usuariosSixo.summarySubtitle':
        'Query protected by the SUPER role in the token.',
    'usuariosSixo.totalLabel': 'users',
    'usuariosSixo.totalRegistered': 'Registered users',
    'usuariosSixo.searchHint': 'Search by name, email, phone, or role',
    'usuariosSixo.resultsLabel': 'found',
    'usuariosSixo.forbiddenTitle': 'SUPER-only access',
    'usuariosSixo.forbiddenMessage':
        'Your profile is not allowed to view Sixo users.',
    'usuariosSixo.loading': 'Loading Sixo users',
    'usuariosSixo.loadErrorTitle': 'Unable to load users',
    'usuariosSixo.loadError': 'Check your connection and try again.',
    'usuariosSixo.emptyTitle': 'No users found',
    'usuariosSixo.emptyMessage':
        'Adjust the search to find other users.',
    'usuariosSixo.userFallback': 'Sixo user',
    'usuariosSixo.noEmail': 'Email not provided',
    'usuariosSixo.noPhone': 'Phone not provided',
    'usuariosSixo.role.super': 'SUPER',
    'usuariosSixo.role.admin': 'Administrator',
    'usuariosSixo.role.collaborator': 'Collaborator',
    'usuariosSixo.role.customer': 'Customer',
    'usuariosSixo.role.unknown': 'Not provided',
    'usuariosSixo.detail.title': 'User details',
    'usuariosSixo.detail.subtitle':
        'Registration, preferences, companies, and links saved in Sixo.',
    'usuariosSixo.detail.loadError': 'Unable to load user details.',
    'usuariosSixo.detail.personal': 'Personal data',
    'usuariosSixo.detail.account': 'Account and permissions',
    'usuariosSixo.detail.preferences': 'Individual preferences',
    'usuariosSixo.detail.globalPreferences': 'Global preferences',
    'usuariosSixo.detail.companies': 'Linked companies',
    'usuariosSixo.detail.links': 'Links and contract data',
    'usuariosSixo.detail.noCompanies': 'No linked companies.',
    'usuariosSixo.detail.noLinks': 'No links registered.',
    'usuariosSixo.detail.imageStored': 'Stored image',
    'usuariosSixo.onboarding.completed': 'Onboarding completed',
    'usuariosSixo.onboarding.pending': 'Onboarding pending',
    'usuariosSixo.onboarding.dialogBarrier':
        'Change initial onboarding status',
    'usuariosSixo.onboarding.resetTitle': 'Request onboarding again?',
    'usuariosSixo.onboarding.resetMessage':
        'On the next access, the user will need to confirm their initial data again before entering the system.',
    'usuariosSixo.onboarding.resetAction': 'Redo onboarding',
    'usuariosSixo.onboarding.completeTitle':
        'Mark onboarding as completed?',
    'usuariosSixo.onboarding.completeMessage':
        'The user will no longer see initial onboarding on future access.',
    'usuariosSixo.onboarding.completeAction': 'Mark as completed',
    'usuariosSixo.onboarding.processingTitle': 'Updating onboarding...',
    'usuariosSixo.onboarding.processingMessage':
        'Please wait while the new setting is saved.',
    'usuariosSixo.onboarding.successTitle': 'Onboarding updated',
    'usuariosSixo.onboarding.successMessage':
        'The new rule will apply the next time the user signs in.',
    'usuariosSixo.onboarding.errorTitle': 'Unable to update',
    'usuariosSixo.onboarding.errorMessage':
        'Try again. No other information was changed.',
    'initialOnboarding.eyebrow': 'Initial setup',
    'initialOnboarding.step': 'Step',
    'initialOnboarding.of': 'of',
    'initialOnboarding.identityTitle': 'Let’s start with the essentials',
    'initialOnboarding.identitySubtitle':
        'Confirm your information so we can personalize your experience.',
    'initialOnboarding.businessTitle': 'What does your business do?',
    'initialOnboarding.businessSubtitle':
        'This only organizes modules and shortcuts. You can change it later.',
    'initialOnboarding.languageQuestion':
        'Which language would you like to continue in?',
    'initialOnboarding.userName': 'What should we call you?',
    'initialOnboarding.companyName': 'Business name',
    'initialOnboarding.salesTitle': 'Sells products',
    'initialOnboarding.salesSubtitle':
        'Point of sale, catalog, inventory, and sales.',
    'initialOnboarding.servicesTitle': 'Provides technical services',
    'initialOnboarding.servicesSubtitle':
        'Appointments, service orders, and procedures.',
    'initialOnboarding.start': 'Start using SixoApp',
    'initialOnboarding.activityRequired':
        'Select sales, technical services, or both.',
    'initialOnboarding.userNameRequired':
        'Enter your name to continue.',
    'initialOnboarding.companyNameRequired':
        'Enter the company name to continue.',
    'initialOnboarding.saveError': 'Unable to save now. Please try again.',
    'initialOnboarding.loadErrorTitle': 'Unable to start setup',
    'initialOnboarding.loadErrorMessage':
        'Check your connection and try again.',
    'caixa.operacoes.openConfirmTitle': 'Confirm cash opening?',
    'caixa.operacoes.openConfirmMessage':
        'Do you want to open {cashDesk} with an initial cash amount of {amount}?',
    'caixa.operacoes.openConfirmAction': 'Open cash register',
    'caixa.operacoes.closeSessionAction': 'Close cash register',
    'caixa.operacoes.closeDialogTitle': 'Close cash register session?',
    'caixa.operacoes.closeDialogSubtitle':
        'Review the summary before continuing. This action cannot be undone.',
    'caixa.operacoes.closeDialogCashDesk': 'Cash register',
    'caixa.operacoes.closeDialogMovements': 'Transactions',
    'caixa.operacoes.closeDialogExpectedBalance': 'Expected balance',
    'caixa.operacoes.closeDialogChecklistComplete':
        'Operational summary available',
    'caixa.operacoes.closeDialogBack': 'Back',
    'caixa.operacoes.closeDialogConfirm': 'Close cash register',
    'caixa.operacoes.closeDialogProcessing': 'Closing...',
    'caixa.operacoes.closeDialogSuccessTitle':
        'Cash register closed successfully',
    'caixa.operacoes.closeDialogSuccessMessage':
        'The session has ended and remains available in the history.',
    'caixa.operacoes.closeDialogError':
        'Unable to close the cash register. Check your connection and try again.',
    'caixa.operacoes.cancelDialogTitle': 'Cancel transaction?',
    'caixa.operacoes.cancelDialogSubtitle':
        'Review this transaction linkage before canceling. Depending on the financial history, the entry may need to remain recorded.',
    'caixa.operacoes.cancelDialogOperation': 'Transaction',
    'caixa.operacoes.cancelDialogMethod': 'Method',
    'caixa.operacoes.cancelDialogAmount': 'Amount',
    'caixa.operacoes.cancelDialogChecklist':
        'If the transaction is linked to future receipts or related entries, cancellation may be blocked to preserve the history.',
    'caixa.operacoes.cancelDialogBack': 'Back',
    'caixa.operacoes.cancelDialogConfirm': 'Cancel transaction',
    'caixa.operacoes.cancelDialogProcessing': 'Canceling...',
    'caixa.operacoes.cancelDialogSuccessTitle': 'Transaction canceled',
    'caixa.operacoes.cancelDialogSuccessMessage':
        'The cash history has been updated and this transaction is no longer active in the current session.',
    'caixa.operacoes.cancelDialogError':
        'Unable to cancel this transaction right now. Review related financial links and try again.',
    'caixa.operacoes.cancelDialogLinkedRecordsError':
        'This transaction is linked to future receipts or entries and must remain recorded in the financial history.',
    'caixa.operacoes.cancelDialogPermissionError':
        'You do not have permission to cancel this transaction.',
    'caixa.operacoes.cancelDialogConnectivityError':
        'Unable to reach the server right now. Check your connection and try again.',
    'caixa.operacoes.cancelDialogLikelyLinkedError':
        'Unable to cancel this transaction because it may be linked to other financial records. Review the related receipts and try again.',
    'caixa.operacoes.addEntryAction': 'Add entry',
    'caixa.operacoes.launchDialogTitle': 'Register operational entry',
    'caixa.operacoes.launchDialogSubtitle':
        'Fill in the operation details and review them before posting to the cash register.',
    'caixa.operacoes.launchDialogTypeLabel': 'Operation type',
    'caixa.operacoes.launchDialogSelect': 'Select',
    'caixa.operacoes.launchDialogAmountLabel': 'Amount',
    'caixa.operacoes.launchDialogRelatedTypeLabel': 'Related method',
    'caixa.operacoes.launchDialogReferenceLabel': 'Reference / receipt',
    'caixa.operacoes.launchDialogReferenceHint': 'Example: MOV-001',
    'caixa.operacoes.launchDialogObservationLabel': 'Note',
    'caixa.operacoes.launchDialogObservationHint':
        'Describe the reason for the movement clearly.',
    'caixa.operacoes.launchDialogLinkedSaleLabel': 'Linked to a sale',
    'caixa.operacoes.launchDialogLinkedSaleHint':
        'Use this for reversals or cases related to a previous service.',
    'caixa.operacoes.launchDialogReviewAction': 'Review entry',
    'caixa.operacoes.launchDialogTypeRequired': 'Select the operation type.',
    'caixa.operacoes.launchDialogRelatedTypeRequired':
        'Select the related method.',
    'caixa.operacoes.launchDialogAmountRequired': 'Enter a valid amount.',
    'caixa.operacoes.launchDialogReviewTitle': 'Confirm operational entry?',
    'caixa.operacoes.launchDialogReviewSubtitle':
        'Review the details below before posting the movement to the cash register.',
    'caixa.operacoes.launchDialogChecklist': 'Summary ready for confirmation.',
    'caixa.operacoes.launchDialogEditAction': 'Edit details',
    'caixa.operacoes.launchDialogConfirmAction': 'Register movement',
    'caixa.operacoes.launchDialogProcessing': 'Registering...',
    'caixa.operacoes.launchDialogError':
        'The movement could not be registered. Check the details and try again.',
    'caixa.operacoes.launchDialogSuccessTitle':
        'Movement registered successfully',
    'caixa.operacoes.launchDialogSuccessMessage':
        'The entry is already visible in the history and cash summary.',
    'caixa.operacoes.launchDialogAvailableMethods': 'Active methods',
    'caixa.operacoes.launchDialogLinkedSaleTag': 'Linked to sale',
    'caixa.operacoes.historyTodayOnly': 'Today only',
    'caixa.operacoes.historyPeriod': 'Period',
    'caixa.operacoes.historyPeriodToday': 'Today',
    'caixa.operacoes.historyPeriodLast7Days': 'Last 7 days',
    'caixa.operacoes.historyPeriodLast30Days': 'Last 30 days',
    'caixa.operacoes.historyPeriodThisMonth': 'This month',
    'caixa.operacoes.historyPeriodLastMonth': 'Last month',
    'caixa.operacoes.historyPeriodCustomRange': 'Custom range',
    'caixa.operacoes.historyNature': 'Direction',
    'caixa.operacoes.historyStatus': 'Status',
    'caixa.operacoes.historyOperation': 'Operation',
    'caixa.operacoes.historyMethod': 'Method',
    'caixa.operacoes.historyStartDate': 'Start date',
    'caixa.operacoes.historyEndDate': 'End date',
    'caixa.operacoes.historyStartDateHelp': 'Select start date',
    'caixa.operacoes.historyEndDateHelp': 'Select end date',
    'caixa.operacoes.historyClearFilters': 'Clear filters',
    'caixa.operacoes.historyNoResultsFiltered':
        'No transactions found for the selected filters.',
    'caixa.operacoes.historyNoResultsToday':
        'No transactions registered today.',
    'web.standalone.quote': 'Quote',
    'web.standalone.serviceOrder': 'Service order',
    'web.shell.expandSidebar': 'Expand navigation',
    'web.shell.collapseSidebar': 'Collapse navigation',
    'web.shell.currentCommerce': 'Current business',
    'web.shell.sessionContext': 'Session context',
    'web.shell.workspace': 'Operational workspace',
    'web.shell.version': 'Version',
    'web.header.profile': 'Profile',
    'web.header.profileTooltip': 'My profile',
    'web.header.userMenu': 'User',
    'web.header.myProfile': 'My profile',
    'web.header.theme.dark': 'Dark theme',
    'web.header.theme.dark.enable': 'Enable dark theme',
    'web.header.theme.dark.disable': 'Disable dark theme',
    'web.header.logout': 'Sign out',
    'web.logout.dialog.title': 'End session now?',
    'web.logout.dialog.subtitle':
        'Review the current context before signing out. You will return to the public login screen in this browser.',
    'web.logout.dialog.user': 'User',
    'web.logout.dialog.currentCommerce': 'Current business',
    'web.logout.dialog.nextStep': 'Next step',
    'web.logout.dialog.nextStepValue': 'Public login screen',
    'web.logout.dialog.checklist':
        'The current session will end only in this browser.',
    'web.logout.dialog.back': 'Stay signed in',
    'web.logout.dialog.confirm': 'Sign out now',
    'web.logout.dialog.processing': 'Ending session...',
    'web.logout.dialog.successTitle': 'Session ended successfully',
    'web.logout.dialog.successMessage':
        'Preparing the return to the public login screen.',
    'web.logout.dialog.error':
        'Unable to end the session right now. Please try again in a moment.',
    'workspaceHome.title': 'My day in SixoApp',
    'workspaceHome.greeting': 'Hello, {name}',
    'workspaceHome.unknownUser': 'user',
    'workspaceHome.companyFallback': 'Current business',
    'workspaceHome.operationalDate': 'Today: {date}',
    'workspaceHome.refreshTooltip': 'Refresh day summary',
    'workspaceHome.loading.title': 'Loading day summary',
    'workspaceHome.loading.subtitle':
        'Fetching the current situation for this business.',
    'workspaceHome.error.title': 'Could not load the day summary.',
    'collaboratorHome.title': 'My dashboard',
    'collaboratorHome.subtitle':
        'Track your goals, sales, services, and work priorities.',
    'collaboratorHome.loading': 'Loading your operational dashboard',
    'collaboratorHome.error.user':
        'We could not identify your personal dashboard.',
    'collaboratorHome.attention.title': 'Work priorities',
    'collaboratorHome.attention.clear':
        'Everything is up to date across your work areas.',
    'collaboratorHome.attention.pending': '{count} items need attention.',
    'collaboratorHome.attention.overdueSales': 'Overdue sales',
    'collaboratorHome.attention.overdueServices': 'Late deliveries',
    'collaboratorHome.attention.reservations': 'Reservations to review',
    'collaboratorHome.sales.title': 'My sales',
    'collaboratorHome.sales.period': 'Results from {start} to {end}',
    'collaboratorHome.sales.count': 'Sales this month',
    'collaboratorHome.sales.total': 'Total sold',
    'collaboratorHome.sales.received': 'Already received',
    'collaboratorHome.sales.openMonth': 'Outstanding this month',
    'collaboratorHome.sales.loadError': 'We could not load your sales summary.',
    'collaboratorHome.openSales.title': 'Unsettled sales',
    'collaboratorHome.openSales.subtitle': 'Only sales registered by you.',
    'collaboratorHome.openSales.loadError':
        'We could not load your outstanding sales.',
    'collaboratorHome.openSales.empty':
        'You have no sales awaiting settlement.',
    'collaboratorHome.openSales.more': '{count} more outstanding sales',
    'collaboratorHome.openSales.customerFallback': 'Customer not provided',
    'collaboratorHome.openSales.saleFallback': 'Sale',
    'collaboratorHome.openSales.noDueDate': 'No due date',
    'collaboratorHome.openSales.overdue': 'Overdue',
    'collaboratorHome.services.title': 'My services by status',
    'collaboratorHome.services.subtitle':
        'Distribution of service calls assigned to you.',
    'collaboratorHome.services.open': 'Open service calls',
    'collaboratorHome.services.loadError': 'We could not load your services.',
    'collaboratorHome.services.empty':
        'No service call is currently assigned to you.',
    'collaboratorHome.services.total': 'Total assigned',
    'collaboratorHome.services.inProgress': 'In progress',
    'collaboratorHome.services.dueToday': 'Due today',
    'collaboratorHome.services.overdue': 'Overdue',
    'collaboratorHome.services.moreStatuses':
        '{count} more statuses with activity',
    'collaboratorHome.services.unknownStatus': 'No status',
    'collaboratorHome.reservations.title': 'Reservation queue',
    'collaboratorHome.reservations.subtitle':
        'Catalog requests that can become sales.',
    'collaboratorHome.reservations.open': 'Open reservations',
    'collaboratorHome.reservations.loadError':
        'We could not load reservations.',
    'collaboratorHome.reservations.pending': 'Pending',
    'collaboratorHome.reservations.received': 'Received',
    'collaboratorHome.reservations.analysis': 'Under review',
    'collaboratorHome.reservations.confirmed': 'Confirmed',
    'collaboratorHome.reservations.converted': 'Converted',
    'performance.home.title': 'My goals',
    'performance.home.subtitle':
        'Track your goals and results updated by SixoApp.',
    'performance.home.dashboardTitle': 'Goal vs. result',
    'performance.home.period': 'Results from {start} to {end}',
    'performance.home.accessibilityLabel': 'My goals dashboard',
    'performance.home.loading': 'Loading your goals',
    'performance.home.loadError': 'Could not update your goals.',
    'performance.home.emptyTitle': 'No active goal this month',
    'performance.home.emptySubtitle':
        'When a goal is assigned to you, its result will appear here.',
    'performance.home.result': 'Result',
    'performance.home.target': 'Goal',
    'performance.indicator.salesValue': 'Sales amount',
    'performance.indicator.salesQuantity': 'Number of sales',
    'performance.indicator.servicesValue': 'Services amount',
    'performance.indicator.serviceCalls': 'Technical services',
    'performance.indicator.finishedServiceCalls': 'Completed services',
    'performance.indicator.serviceCallsValue': 'Service calls amount',
    'workspaceHome.section.today': 'Today status',
    'workspaceHome.section.attention': 'Needs your attention',
    'workspaceHome.section.quickActions': 'Quick actions',
    'workspaceHome.empty.today':
        'No summary block is available for your permissions.',
    'dashboardInicio.mobileGreetingSubtitle':
        'See the main activity for {empresa} today.',
    'workspaceHome.empty.attention': 'No important pending items right now.',
    'workspaceHome.empty.quickActions':
        'No quick action is available for your permissions.',
    'workspaceHome.cash.title': 'Cash register',
    'workspaceHome.cash.open': 'Open',
    'workspaceHome.cash.closed': 'Closed',
    'workspaceHome.cash.openedAt': 'since {time}',
    'workspaceHome.cash.openedAtWithDate': 'since {date} at {time}',
    'workspaceHome.cash.responsible': 'Opened by {name}',
    'workspaceHome.technical.title': 'Services',
    'workspaceHome.technical.active.one': '1 in progress',
    'workspaceHome.technical.active.other': '{count} in progress',
    'workspaceHome.financial.receivableToday': 'Receivable today',
    'workspaceHome.financial.payableToday': 'Payable today',
    'workspaceHome.financial.count.one': '1 account',
    'workspaceHome.financial.count.other': '{count} accounts',
    'workspaceHome.stock.title': 'Stock',
    'workspaceHome.stock.noCritical': 'No critical alerts',
    'workspaceHome.stock.belowMinimum.one': '1 below minimum',
    'workspaceHome.stock.belowMinimum.other': '{count} below minimum',
    'workspaceHome.stock.withoutStock.one': '1 out of stock',
    'workspaceHome.stock.withoutStock.other': '{count} out of stock',
    'workspaceHome.stock.negative.one': '1 negative',
    'workspaceHome.stock.negative.other': '{count} negative',
    'workspaceHome.attention.lateServices.one': '1 late service',
    'workspaceHome.attention.lateServices.other': '{count} late services',
    'workspaceHome.attention.waitingApproval.one':
        '1 quote waiting for approval',
    'workspaceHome.attention.waitingApproval.other':
        '{count} quotes waiting for approval',
    'workspaceHome.attention.readyForPickup.one': '1 device ready for pickup',
    'workspaceHome.attention.readyForPickup.other':
        '{count} devices ready for pickup',
    'workspaceHome.attention.overdueReceivable.one': '1 overdue receivable',
    'workspaceHome.attention.overdueReceivable.other':
        '{count} overdue receivables',
    'workspaceHome.attention.overduePayable.one': '1 overdue payable',
    'workspaceHome.attention.overduePayable.other': '{count} overdue payables',
    'workspaceHome.attention.stockNegative.one':
        '1 product with negative stock',
    'workspaceHome.attention.stockNegative.other':
        '{count} products with negative stock',
    'workspaceHome.attention.stockWithout.one': '1 product out of stock',
    'workspaceHome.attention.stockWithout.other':
        '{count} products out of stock',
    'workspaceHome.attention.stockBelow.one': '1 product below minimum stock',
    'workspaceHome.attention.stockBelow.other':
        '{count} products below minimum stock',
    'workspaceHome.action.openTechnicalServices': 'Open services',
    'workspaceHome.action.openFinancial': 'Open financial',
    'workspaceHome.action.openStock': 'Open stock',
    'workspaceHome.quickAction.newSale': 'New sale',
    'workspaceHome.quickAction.newTechnicalService': 'New service',
    'workspaceHome.quickAction.cash': 'Cash register',
    'workspaceHome.quickAction.financialAgenda': 'Financial agenda',
    'streak.title': 'Streak',
    'streak.mobile': 'Mobile',
    'streak.web': 'Web',
    'streak.shared': 'Overall',
    'streak.longest': 'Best',
    'streak.oneDay': '1 day',
    'streak.days': '{count} days',
    'streak.daysOfStreak': '{count} day streak',
    'streak.keepUsing': 'Use SixoApp every day to keep your streak.',
    'streak.startedToday': 'Your streak started today.',
    'streak.loading': 'Loading your streak days.',
    'streak.loadError': 'Could not load your streak.',
    'dashboardInicio.mobileCompanyFilterTooltip':
        'Filter businesses: {comercio}',
    'dashboardInicio.mobileCompanyFilterTitle': 'Filter businesses',
    'dashboardInicio.mobileCompanyFilterSubtitle':
        'Choose a business to view on the dashboard.',
    'dashboardInicio.mobileCompanyFilterAll': 'All',
    'dashboardInicio.mobileCompanyFilterSearchHint': 'Search business',
    'dashboardInicio.mobileCompanyFilterEmptyTitle': 'No business available',
    'dashboardInicio.mobileCompanyFilterEmptyMessage':
        'We could not find active links for this user.',
    'dashboardInicio.mobileCompanyFilterLoadError':
        'Could not load the available businesses right now.',
    'dashboardInicio.mobileCompanyFilterSwitchError':
        'Could not switch the business right now. Try again.',
    'dashboardInicio.mobileDashboardFilterTitle': 'Filter dashboard',
    'dashboardInicio.mobileDashboardFilterSubtitle':
        'Choose the business and, if needed, refine by collaborator.',
    'dashboardInicio.mobileDashboardFilterCompanyLabel': 'Business',
    'dashboardInicio.mobileDashboardFilterCompanyHelper':
        'Defines which business feeds the displayed indicators.',
    'dashboardInicio.mobileCollaboratorFilterLabel': 'Collaborator',
    'dashboardInicio.mobileCollaboratorFilterAll': 'All collaborators',
    'dashboardInicio.mobileCollaboratorFilterHelper':
        'Shows the dashboard indicators for the selected collaborator.',
    'dashboardInicio.mobileCollaboratorFilterDisabledHelper':
        'Choose a specific business before filtering collaborators.',
    'dashboardInicio.mobileCollaboratorFilterLoadingHelper':
        'Loading collaborators for the current business.',
    'dashboardInicio.mobileCollaboratorFilterTitle': 'Filter collaborator',
    'dashboardInicio.mobileCollaboratorFilterSubtitle':
        'Choose a collaborator to refine the indicators.',
    'dashboardInicio.mobileCollaboratorFilterSearchHint': 'Search collaborator',
    'dashboardInicio.mobileCollaboratorFilterEmptyTitle':
        'No collaborator available',
    'dashboardInicio.mobileCollaboratorFilterEmptyMessage':
        'We could not find active collaborators for this business.',
    'dashboardInicio.mobileCollaboratorFilterLoadError':
        'Could not load the collaborators for this business right now.',
    'dashboardInicio.mobileCollaboratorFilterSelectedFallback':
        'Selected collaborator',
    'dashboardInicio.mobileInfrastructureRequestsTitle': 'Backend requests',
    'dashboardInicio.mobileInfrastructureRequestsSubtitle':
        'Responses monitored in the selected backend time window.',
    'dashboardInicio.mobileInfrastructureRequestsFilterTitle':
        'Filter backend requests',
    'dashboardInicio.mobileInfrastructureRequestsFilterSubtitle':
        'Enter the time window used to count status 200, 400 and 500 responses.',
    'dashboardInicio.mobileInfrastructureRequestsFilterValueLabel': 'Amount',
    'dashboardInicio.mobileInfrastructureRequestsFilterUnitLabel': 'Unit',
    'dashboardInicio.mobileInfrastructureRequestsFilterMinutes': 'Minutes',
    'dashboardInicio.mobileInfrastructureRequestsFilterHours': 'Hours',
    'dashboardInicio.mobileInfrastructureRequestsFilterApply': 'Apply window',
    'dashboardInicio.mobileInfrastructureRequestsMinuteSingular': 'minute',
    'dashboardInicio.mobileInfrastructureRequestsMinutePlural': 'minutes',
    'dashboardInicio.mobileInfrastructureRequestsHourSingular': 'hour',
    'dashboardInicio.mobileInfrastructureRequestsHourPlural': 'hours',
    'mobile.nav.dash': 'dash',
    'mobile.nav.home': 'Home',
    'mobile.nav.management': 'Management',
    'mobile.nav.service': 'Service',
    'empresa.configuracao.title': 'Company',
    'empresa.configuracao.loadError': 'Could not load company data.',
    'empresa.configuracao.saveSuccess': 'Company data updated successfully.',
    'empresa.configuracao.saveError': 'Could not save company data.',
    'empresa.configuracao.summaryTitle': 'Business data',
    'empresa.configuracao.summarySubtitle':
        'Update the information used in documents and service.',
    'empresa.configuracao.identityTitle': 'Company identity',
    'empresa.configuracao.identitySubtitle':
        'Review the main data before saving changes.',
    'empresa.configuracao.legalName': 'Legal name',
    'empresa.configuracao.legalNameHint': 'Company legal name',
    'empresa.configuracao.tradeName': 'Trade name',
    'empresa.configuracao.tradeNameHint': 'Commercial name used during service',
    'empresa.configuracao.document': 'Company document',
    'empresa.configuracao.documentHint': 'Tax ID or equivalent fiscal document',
    'empresa.configuracao.requiredField': 'Fill in this field.',
    'empresa.configuracao.readyToEdit': 'Data ready for editing.',
    'empresa.configuracao.waitingData': 'Waiting for company data.',
    'empresa.configuracao.statusSubtitle':
        'Saved information appears in business documents and receipts.',
    'empresa.configuracao.saveChanges': 'Save changes',
    'empresa.configuracao.logoTitle': 'Company logo',
    'empresa.configuracao.logoSubtitle':
        'Add a clear image, preferably square.',
    'empresa.configuracao.logoRegistered':
        'Image ready to save in the business profile.',
    'empresa.configuracao.logoSelect': 'Select logo',
    'empresa.configuracao.logoChange': 'Change logo',
    'empresa.configuracao.logoRemove': 'Remove',
    'empresa.configuracao.logoSheetTitle': 'Add logo',
    'empresa.configuracao.logoSheetSubtitle':
        'Choose an image from the gallery or take a photo.',
    'empresa.configuracao.logoFromGallery': 'Choose from gallery',
    'empresa.configuracao.logoFromCamera': 'Use camera',
    'empresa.configuracao.logoLoadError': 'Could not load the logo.',
    'empresa.configuracao.logoTooLarge': 'Choose an image up to 1 MB.',
    'empresa.configuracao.logoSemantics': 'Company logo registered.',
    'empresa.configuracao.logoEmptySemantics': 'No logo registered.',
    'atendimentoTecnico.status': 'Status',
    'atendimentoTecnico.filters.paymentStatus.label': 'Payment status',
    'atendimentoTecnico.filters.paymentStatus.tooltip':
        'Filter by payment status',
    'atendimentoTecnico.filters.paymentStatus.helper':
        'Filter service records by open balance or paid status.',
    'atendimentoTecnico.filters.paymentStatus.all': 'All payments',
    'atendimentoTecnico.filters.paymentStatus.open': 'Open',
    'atendimentoTecnico.filters.paymentStatus.paid': 'Paid',
    'atendimentoTecnico.filters.multiSelected': '{count} selected',
    'atendimentoTecnico.filters.technician.label': 'Responsible technician',
    'atendimentoTecnico.filters.technician.tooltip': 'Filter by technician',
    'atendimentoTecnico.filters.technician.all': 'All technicians',
    'atendimentoTecnico.filters.technician.none': 'No responsible technician',
    'atendimentoTecnico.filters.technician.selectedFallback':
        'Selected technician',
    'atendimentoTecnico.filters.status.tooltip': 'Filter by status',
    'atendimentoTecnico.filters.status.all': 'All statuses',
    'atendimentoTecnico.filters.status.allWithCount': 'All statuses ({count})',
    'atendimentoTecnico.filters.status.selectedFallback': 'Selected status',
    'atendimentoTecnico.lista.openDetails': 'View details',
    'atendimentoTecnico.lista.detailsDialog.title': 'Service details',
    'atendimentoTecnico.lista.detailsDialog.subtitle':
        'Review the financials, progress, and complete history before moving to another action.',
    'atendimentoTecnico.lista.detailsDialog.barrierLabel':
        'Close service details',
    'atendimentoTecnico.web.dateFilterDialog.barrierLabel': 'Close date filter',
    'atendimentoTecnico.web.dateFilterDialog.filterLabel': 'Date',
    'atendimentoTecnico.web.dateFilterDialog.title': 'Filter by date',
    'atendimentoTecnico.web.dateFilterDialog.subtitle':
        'Set the service update interval.',
    'atendimentoTecnico.web.dateFilterDialog.fieldLabel': 'Field',
    'atendimentoTecnico.web.dateFilterDialog.fieldValueUpdatedAt':
        'Update date',
    'atendimentoTecnico.web.dateFilterDialog.currentRangeLabel': 'Range',
    'atendimentoTecnico.web.dateFilterDialog.allDates': 'All dates',
    'atendimentoTecnico.web.dateFilterDialog.dateFrom': 'From {date}',
    'atendimentoTecnico.web.dateFilterDialog.dateUntil': 'Until {date}',
    'atendimentoTecnico.web.dateFilterDialog.dateRange': '{start} to {end}',
    'atendimentoTecnico.web.dateFilterDialog.startLabel': 'Start',
    'atendimentoTecnico.web.dateFilterDialog.endLabel': 'End',
    'atendimentoTecnico.web.dateFilterDialog.dateHint': 'MM/dd/yyyy',
    'atendimentoTecnico.web.dateFilterDialog.quickToday': 'Today',
    'atendimentoTecnico.web.dateFilterDialog.quickLast7Days': 'Last 7 days',
    'atendimentoTecnico.web.dateFilterDialog.quickNext7Days': 'Next 7 days',
    'atendimentoTecnico.web.dateFilterDialog.quickOverdue': 'Overdue',
    'atendimentoTecnico.web.dateFilterDialog.quickLast30Days': 'Last 30 days',
    'atendimentoTecnico.web.dateFilterDialog.quickThisMonth': 'This month',
    'atendimentoTecnico.web.dateFilterDialog.clearAction': 'Clear',
    'atendimentoTecnico.web.dateFilterDialog.cancelAction': 'Cancel',
    'atendimentoTecnico.web.dateFilterDialog.applyAction': 'Apply',
    'atendimentoTecnico.web.dateFilterDialog.startInvalid':
        'Enter a valid start date.',
    'atendimentoTecnico.web.dateFilterDialog.endInvalid':
        'Enter a valid end date.',
    'atendimentoTecnico.web.dateFilterDialog.endBeforeStart':
        'The end date cannot be before the start date.',
    'atendimentoTecnico.customerNotInformed': 'Customer not informed',
    'atendimentoTecnico.expectedDelivery': 'Expected delivery',
    'atendimentoTecnico.equipment': 'Equipment',
    'atendimentoTecnico.reportedIssue': 'Reported issue',
    'atendimentoTecnico.publicStatus.title': 'Service status',
    'atendimentoTecnico.publicStatus.subtitle':
        'Track the current technical service stage through the public link.',
    'atendimentoTecnico.publicStatus.progressTitle': 'Service progress',
    'atendimentoTecnico.publicStatus.progressShort': 'Service progress',
    'atendimentoTecnico.publicStatus.serviceData': 'Service data',
    'atendimentoTecnico.publicStatus.history': 'Status history',
    'atendimentoTecnico.publicStatus.noHistory': 'No status changes recorded.',
    'atendimentoTecnico.publicStatus.loading': 'Loading service status...',
    'atendimentoTecnico.publicStatus.errorTitle': 'Could not load the status',
    'atendimentoTecnico.publicStatus.invalidLink':
        'Invalid link. Token or business not informed.',
    'atendimentoTecnico.publicStatus.linkTitle': 'Public status link',
    'atendimentoTecnico.publicStatus.linkCopied': 'Link copied to clipboard.',
    'atendimentoTecnico.publicStatus.linkCopiedShort': 'Status link copied.',
    'atendimentoTecnico.publicStatus.linkHelp':
        'Send this link to the customer to track the current service status.',
    'atendimentoTecnico.publicStatus.linkMissing':
        'The backend did not return a link.',
    'atendimentoTecnico.publicStatus.linkError':
        'Could not generate the status link',
    'atendimentoTecnico.publicStatus.shareMessage':
        'Track your service status through the link below:',
    'atendimentoTecnico.publicStatus.shareSubject': 'Service status',
    'atendimentoTecnico.publicStatus.shareFallback':
        'Could not open sharing. The link was copied.',
    'atendimentoTecnico.publicStatus.publicUrlMissing':
        'Public app URL is not configured.',
    'atendimentoTecnico.publicStatus.action': 'Public status',
    'atendimentoTecnico.publicStatus.actionShort': 'Status',
    'atendimentoTecnico.publicStatus.signaturePendingTitle':
        'Approval signature pending',
    'atendimentoTecnico.publicStatus.signaturePendingDescription':
        'You can keep tracking the status normally. To approve the service, tap the button and sign on the next page.',
    'atendimentoTecnico.publicStatus.signatureRenewTitle':
        'New signature required',
    'atendimentoTecnico.publicStatus.signatureRenewDescription':
        'This service was changed after the last approval. You can keep tracking the status normally and sign the current version when you want to approve it.',
    'atendimentoTecnico.publicStatus.signatureAction': 'Sign approval',
    'atendimentoTecnico.publicStatus.signatureLinkMissing':
        'The backend did not return a signature link.',
    'atendimentoTecnico.publicStatus.signatureLinkError':
        'Could not open the signature.',
    'atendimentoTecnico.publicStatus.responsibleUnit': 'Responsible unit',
    'atendimentoTecnico.publicStatus.officialChannel': 'Official channel',
    'atendimentoTecnico.publicStatus.updatedByBusiness':
        'Status updated by the business',
    'atendimentoTecnico.publicStatus.companyDataSource':
        'Data provided by the business.',
    'atendimentoTecnico.publicStatus.officialServiceChannel':
        'Official service tracking channel.',
    'atendimentoTecnico.publicStatus.externalLinkUnavailable':
        'Could not open this contact on this device.',
    'atendimentoTecnico.mobile.loading': 'Loading technical services',
    'atendimentoTecnico.mobile.emptyFilteredMessage':
        'No services found with the selected filters.',
    'atendimentoTecnico.mobile.searchHint':
        'Search by customer, status, equipment, or number',
    'atendimentoTecnico.mobile.advancedFilters': 'Advanced filters',
    'atendimentoTecnico.mobile.advancedFiltersActive':
        'Active advanced filters',
    'atendimentoTecnico.mobile.clearFilters': 'Clear filters',
    'atendimentoTecnico.mobile.sortRecent': 'Most recent',
    'atendimentoTecnico.mobile.resultCountOne': '1 service',
    'atendimentoTecnico.mobile.resultCountMany': '{count} services',
    'atendimentoTecnico.mobile.periodSummaryTitle': 'Period summary',
    'atendimentoTecnico.mobile.summaryServiceOne': 'service',
    'atendimentoTecnico.mobile.summaryServiceMany': 'services',
    'atendimentoTecnico.mobile.summaryOpenOne': 'open',
    'atendimentoTecnico.mobile.summaryOpenMany': 'open',
    'atendimentoTecnico.mobile.summarySignedOne': 'signed',
    'atendimentoTecnico.mobile.summarySignedMany': 'signed',
    'atendimentoTecnico.mobile.summaryOpenValue': '{value} open',
    'atendimentoTecnico.mobile.summaryOpenValueCaption': 'open',
    'atendimentoTecnico.mobile.filterSheetTitle': 'Filter services',
    'atendimentoTecnico.mobile.filterPeriod': 'Period',
    'atendimentoTecnico.mobile.filterPaymentStatus': 'Payment status',
    'atendimentoTecnico.mobile.filterDate': 'Date',
    'atendimentoTecnico.mobile.filterStartDate': 'Start',
    'atendimentoTecnico.mobile.filterEndDate': 'End',
    'atendimentoTecnico.mobile.dateToday': 'Today',
    'atendimentoTecnico.mobile.dateAll': 'All dates',
    'atendimentoTecnico.mobile.dateRange': '{start} to {end}',
    'atendimentoTecnico.mobile.dateFrom': 'From {date}',
    'atendimentoTecnico.mobile.dateUntil': 'Until {date}',
    'atendimentoTecnico.mobile.dateLast7Days': 'Last 7 days',
    'atendimentoTecnico.mobile.dateNext7Days': 'Next 7 days',
    'atendimentoTecnico.mobile.dateOverdue': 'Overdue',
    'atendimentoTecnico.mobile.filterTechnician': 'Responsible technician',
    'atendimentoTecnico.mobile.searchTechnician': 'Search technician',
    'atendimentoTecnico.mobile.allTechnicians': 'All technicians',
    'atendimentoTecnico.mobile.selectedTechnician': 'Selected technician',
    'atendimentoTecnico.mobile.noTechnicianFound': 'No technician found.',
    'atendimentoTecnico.mobile.viewOneService': 'View 1 service',
    'atendimentoTecnico.mobile.viewManyServices': 'View {count} services',
    'atendimentoTecnico.mobile.sharePdfTooltip': 'Share service',
    'atendimentoTecnico.mobile.pdfSectionTitle': 'Service document',
    'atendimentoTecnico.mobile.pdfSectionDescription':
        'PDF ready to send to the customer with the service details.',
    'atendimentoTecnico.mobile.pdfSectionGenerating':
        'Preparing the PDF for sharing.',
    'atendimentoTecnico.mobile.sharePdfAction': 'Share PDF',
    'atendimentoTecnico.mobile.pdfLoadingTitle': 'Generating service PDF',
    'atendimentoTecnico.mobile.pdfLoadingSubtitle':
        'Please wait while the document is prepared.',
    'atendimentoTecnico.mobile.detailLoadError':
        'Could not load the latest service data.',
    'atendimentoTecnico.mobile.pdfDownloaded': 'PDF downloaded successfully.',
    'atendimentoTecnico.mobile.pdfPermissionDenied':
        'You do not have permission to share this service.',
    'atendimentoTecnico.mobile.pdfNotFound': 'Service not found.',
    'atendimentoTecnico.mobile.pdfInvalidFile': 'The received file is invalid.',
    'atendimentoTecnico.mobile.pdfShareUnavailable':
        'Could not share the document.',
    'atendimentoTecnico.mobile.pdfShareError': 'Could not share the document.',
    'atendimentoTecnico.mobile.pdfGenerationError':
        'Could not generate the service PDF.',
    'atendimentoTecnico.mobile.publicStatusDescription':
        'Visible to the customer in the tracking link.',
    'atendimentoTecnico.publicStatus.shareLinkAction': 'Share link',
    'atendimentoTecnico.mobile.paymentOpen': 'Open financial balance',
    'atendimentoTecnico.mobile.paymentSettled': 'Financial balance settled',
    'atendimentoTecnico.mobile.signed': 'Signed',
    'atendimentoTecnico.mobile.signaturePending': 'Signature pending',
    'atendimentoTecnico.customerNotSigned': 'Customer has not signed',
    'atendimentoTecnico.mobile.customerNotSigned': 'Customer has not signed',
    'atendimentoTecnico.mobile.deliveryLate': 'Delivery late',
    'atendimentoTecnico.signatureGate.title': 'Signature required',
    'atendimentoTecnico.signatureGate.message':
        'To move to {status}, send the signature link to the customer, sign on this device, or register the bypass.',
    'atendimentoTecnico.signatureGate.sendLink': 'Send link to customer',
    'atendimentoTecnico.signatureGate.signHere': 'Sign on this device',
    'atendimentoTecnico.signatureGate.bypass': 'Move without signature',
    'atendimentoTecnico.signatureGate.deviceTitle': 'Collect signature',
    'atendimentoTecnico.signatureGate.deviceMessage':
        'Register the signature to move to {status}.',
    'atendimentoTecnico.signatureGate.deviceSigner': 'Signer name',
    'atendimentoTecnico.signatureGate.deviceDocument': 'Optional document',
    'atendimentoTecnico.signatureGate.deviceSignatureField': 'Signature',
    'atendimentoTecnico.signatureGate.deviceObservation': 'Optional note',
    'atendimentoTecnico.signatureGate.deviceSave': 'Register signature',
    'atendimentoTecnico.signatureGate.deviceSignerRequired':
        'Enter the name of the person signing.',
    'atendimentoTecnico.signatureGate.deviceSignatureRequired':
        'Sign in the indicated area.',
    'atendimentoTecnico.signatureGate.deviceSignatureSaved':
        'Signature registered and status updated.',
    'atendimentoTecnico.signatureGate.deviceSignatureError':
        'Could not register the signature',
    'atendimentoTecnico.signatureGate.publicUrlMissing':
        'The public app URL is not configured.',
    'atendimentoTecnico.signatureGate.linkMissing':
        'The backend did not return a signature link.',
    'atendimentoTecnico.signatureGate.linkCopied': 'Signature link copied.',
    'atendimentoTecnico.signatureGate.linkError':
        'Could not generate the signature link',
    'atendimentoTecnico.signatureGate.shareMessage':
        'To approve the service, sign using the link below:',
    'atendimentoTecnico.signatureGate.shareSubject': 'Service signature',
    'atendimentoTecnico.mobile.valorOriginal': 'Original amount',
    'atendimentoTecnico.mobile.valorJaRecebido': 'Amount already received',
    'atendimentoTecnico.mobile.valorEmAberto': 'Open amount',
    'atendimentoTecnico.mobile.liquidation': 'Settlement',
    'atendimentoTecnico.mobile.liquidated': 'Settled',
    'atendimentoTecnico.mobile.notLiquidated': 'Not settled',
    'atendimentoTecnico.mobile.products': 'Products',
    'atendimentoTecnico.mobile.services': 'Services',
    'atendimentoTecnico.mobile.changeStatusAction': 'Change status',
    'atendimentoTecnico.mobile.createTitle': 'New technical service',
    'atendimentoTecnico.mobile.createHeaderTitle': 'Start service',
    'atendimentoTecnico.mobile.createHeaderSubtitle':
        'Customer, equipment and issue in a fast counter screen.',
    'atendimentoTecnico.mobile.responsible': 'Responsible',
    'atendimentoTecnico.mobile.serviceChip': 'Service',
    'atendimentoTecnico.mobile.quoteChip': 'Quote',
    'atendimentoTecnico.mobile.noItemsChip': 'No items',
    'atendimentoTecnico.mobile.mainDataSection': 'Main data',
    'atendimentoTecnico.mobile.internalDescription': 'Internal description',
    'atendimentoTecnico.mobile.internalDescriptionHint':
        'E.g.: iPhone 11 screen replacement',
    'atendimentoTecnico.mobile.equipmentType': 'Equipment type',
    'atendimentoTecnico.mobile.brand': 'Brand',
    'atendimentoTecnico.mobile.model': 'Model',
    'atendimentoTecnico.mobile.serialNumber': 'Serial no.',
    'atendimentoTecnico.mobile.imei': 'IMEI',
    'atendimentoTecnico.mobile.accessoriesNotes': 'Accessories / notes',
    'atendimentoTecnico.mobile.accessoriesNotesHint':
        'E.g.: no charger, with case, cracked screen...',
    'atendimentoTecnico.mobile.technicalReportSection': 'Technical report',
    'atendimentoTecnico.mobile.customerIssue': 'Issue reported by the customer',
    'atendimentoTecnico.mobile.customerIssueHint':
        'Describe the problem reported at the counter.',
    'atendimentoTecnico.mobile.initialDiagnosis': 'Initial technical diagnosis',
    'atendimentoTecnico.mobile.initialDiagnosisHint':
        'Optional at this first moment.',
    'atendimentoTecnico.mobile.datesSection': 'Dates',
    'atendimentoTecnico.mobile.validity': 'Validity',
    'atendimentoTecnico.mobile.financialDueDate': 'Financial due date',
    'atendimentoTecnico.mobile.financialPreviewSection': 'Financial preview',
    'atendimentoTecnico.mobile.financialPreviewDescription':
        'The amount remains open until a receipt is recorded.',
    'atendimentoTecnico.mobile.valorConfirmado': 'Confirmed',
    'atendimentoTecnico.mobile.paymentStampNoValue': 'NO VALUE',
    'atendimentoTecnico.mobile.paymentStampOpen': 'OPEN',
    'atendimentoTecnico.mobile.savingService': 'Starting service...',
    'atendimentoTecnico.mobile.startServiceAction': 'Start technical service',
    'procedimentos.title': 'Procedures',
    'procedimentos.subtitle': 'Guides for sales, service and deliveries',
    'procedimentos.introTitle':
        'Configure guidance for sales, service and deliveries.',
    'procedimentos.demoData': 'Demo data',
    'procedimentos.filtersLabel': 'Procedure filters',
    'procedimentos.filterAll': 'All',
    'procedimentos.filterActive': 'Active',
    'procedimentos.filterInactive': 'Inactive',
    'procedimentos.newProcedure': 'New procedure',
    'procedimentos.newProcedureSemantics': 'New procedure',
    'procedimentos.createProcedure': 'Create procedure',
    'procedimentos.openAction': 'Open',
    'procedimentos.createUnavailable':
        'Procedure creation will be available in the next step.',
    'procedimentos.editUnavailable':
        'Editing this procedure will be available in the next step.',
    'procedimentos.loading': 'Loading procedures',
    'procedimentos.emptyTitle': 'No procedures configured',
    'procedimentos.emptyDescription':
        'Create guidance to support the team at key moments of the operation.',
    'procedimentos.filteredEmptyTitle': 'No procedures in this filter',
    'procedimentos.filteredEmptyDescription':
        'Change the filter to see other demo procedures.',
    'procedimentos.errorTitle': 'Could not load procedures',
    'procedimentos.errorDescription': 'Try again in a moment.',
    'procedimentos.statusDraft': 'Draft',
    'procedimentos.operationSale': 'Sale',
    'procedimentos.operationTechnicalService': 'Technical service',
    'procedimentos.operationQuote': 'Quote',
    'procedimentos.operationDelivery': 'Delivery',
    'procedimentos.momentBeforeStart': 'Before starting',
    'procedimentos.momentBeforeFinish': 'Before finishing',
    'procedimentos.momentBeforeDelivery': 'Before delivery',
    'procedimentos.stageSingular': 'stage',
    'procedimentos.stagePlural': 'stages',
    'procedimentos.itemSingular': 'item',
    'procedimentos.itemPlural': 'items',
    'procedimentos.stageProgress': 'Stage {current} of {total}',
    'procedimentos.procedureSequence': 'Procedure {current} of {total}',
    'procedimentos.actionsCompleted.zero': '0 of {total} actions completed',
    'procedimentos.actionsCompleted.one': '1 of {total} action completed',
    'procedimentos.actionsCompleted.other':
        '{count} of {total} actions completed',
    'procedimentos.answeredActionsSummary.zero':
        '0 of {total} actions answered.',
    'procedimentos.answeredActionsSummary.one': '1 of {total} action answered.',
    'procedimentos.answeredActionsSummary.other':
        '{count} of {total} actions answered.',
    'procedimentos.optionalPendingSummary.zero': 'No optional items pending.',
    'procedimentos.optionalPendingSummary.one': '1 optional item pending.',
    'procedimentos.optionalPendingSummary.other':
        '{count} optional items pending.',
    'procedimentos.requiredPendingSummary.zero': 'No required items pending.',
    'procedimentos.requiredPendingSummary.one': '1 required item pending.',
    'procedimentos.requiredPendingSummary.other':
        '{count} required items pending.',
    'procedimentos.itemCount.zero': '0 items',
    'procedimentos.itemCount.one': '1 item',
    'procedimentos.itemCount.other': '{count} items',
    'procedimentos.stageCount.zero': '0 stages',
    'procedimentos.stageCount.one': '1 stage',
    'procedimentos.stageCount.other': '{count} stages',
    'procedimentos.stageSemantics': 'Stage {order}: {title}. {itemCountLabel}.',
    'procedimentos.executionItemSemantics': '{requiredLabel}: {title}. {type}.',
    'procedimentos.executionItemStatus': '{type} • {requiredLabel}',
    'procedimentos.responseTypeSemantics': '{label}. {description}.',
    'procedimentos.responseTypeSimulatedSemantics':
        '{label}. {description}. {demoLabel}.',
    'procedimentos.triggerSemantics':
        '{operation}, {moment}, {activation}, {enforcement}, {status}',
    'procedimentos.triggerSummarySingle': '{operation}, {moment}',
    'procedimentos.triggerSummaryMultiple': '{first} • +{remaining}',
    'procedimentos.optionNumber': 'Option {index}',
    'procedimentos.editorNewTitle': 'New procedure',
    'procedimentos.editorEditTitle': 'Edit procedure',
    'procedimentos.generalInfo': 'General information',
    'procedimentos.nameField': 'Name',
    'procedimentos.descriptionField': 'Description',
    'procedimentos.operationContext': 'Operational context',
    'procedimentos.momentField': 'Moment',
    'procedimentos.requireCompletion': 'Require procedure completion',
    'procedimentos.requireCompletionHelp':
        'In a future integration, this procedure may require completion before continuing the operation.',
    'procedimentos.stages': 'Stages',
    'procedimentos.addStage': 'Add stage',
    'procedimentos.editStage': 'Edit stage',
    'procedimentos.deleteStage': 'Delete stage',
    'procedimentos.items': 'Items',
    'procedimentos.addItem': 'Add item',
    'procedimentos.editItem': 'Edit item',
    'procedimentos.deleteItem': 'Delete item',
    'procedimentos.itemType': 'Item type',
    'procedimentos.stageTitleField': 'Stage title',
    'procedimentos.itemTitleField': 'Title or instruction',
    'procedimentos.itemGuidanceField': 'Supporting text',
    'procedimentos.saveStage': 'Save stage',
    'procedimentos.saveItem': 'Save item',
    'procedimentos.responseInstruction': 'Instruction',
    'procedimentos.responseConfirmation': 'Confirmation',
    'procedimentos.responseYesNo': 'Yes or no',
    'procedimentos.responseInstructionDescription':
        'Shows an instruction to the staff member.',
    'procedimentos.responseConfirmationDescription':
        'Requires the staff member to confirm an action.',
    'procedimentos.responseYesNoDescription': 'Shows an objective question.',
    'procedimentos.validationName': 'Enter the procedure name.',
    'procedimentos.validationReviewFields':
        'Review the highlighted fields before saving.',
    'procedimentos.validationAtLeastOneStage':
        'Add at least one stage to the procedure.',
    'procedimentos.validationStageTitle': 'Enter the stage title.',
    'procedimentos.validationStageItem': 'Each stage needs at least one item.',
    'procedimentos.validationItemTitle': 'Enter the item title.',
    'procedimentos.createdSuccess': 'Procedure created.',
    'procedimentos.updatedSuccess': 'Procedure updated.',
    'procedimentos.discardChangesTitle': 'Discard changes?',
    'procedimentos.discardChangesMessage':
        'The changes made to this procedure have not been saved yet.',
    'procedimentos.keepEditing': 'Keep editing',
    'procedimentos.discard': 'Discard',
    'procedimentos.confirmDeleteStageTitle': 'Delete stage?',
    'procedimentos.confirmDeleteStageMessage':
        'The items in this stage will also be removed.',
    'procedimentos.confirmDeleteItemTitle': 'Delete item?',
    'procedimentos.confirmDeleteItemMessage':
        'This item will be removed from the procedure.',
    'procedimentos.editorDemoNotice':
        'Changes will be kept only during this session.',
    'procedimentos.noStages': 'No stages added',
    'procedimentos.itemRequiredHelp':
        'The final required behavior will be defined in the operational integration.',
    'procedimentos.previewAction': 'Preview',
    'procedimentos.demonstration': 'Demo',
    'procedimentos.responsePhoto': 'Take photo',
    'procedimentos.responseSignature': 'Signature',
    'procedimentos.responseLocation': 'Capture location',
    'procedimentos.responseBarcode': 'Read barcode',
    'procedimentos.responseImei': 'Enter IMEI',
    'procedimentos.responseDocument': 'Attach document',
    'procedimentos.responseAudio': 'Record audio',
    'procedimentos.responseFreeText': 'Free text',
    'procedimentos.responseNumber': 'Number',
    'procedimentos.responseDate': 'Date',
    'procedimentos.responseSingleChoice': 'Single choice',
    'procedimentos.responseMultipleChoice': 'Multiple choice',
    'procedimentos.responsePhotoDescription':
        'Simulates capturing a photo as evidence.',
    'procedimentos.responseSignatureDescription':
        'Simulates collecting a signature.',
    'procedimentos.responseLocationDescription':
        'Simulates capturing a location.',
    'procedimentos.responseBarcodeDescription': 'Simulates reading a barcode.',
    'procedimentos.responseImeiDescription':
        'Allows entering an IMEI manually.',
    'procedimentos.responseDocumentDescription':
        'Simulates attaching a document.',
    'procedimentos.responseAudioDescription': 'Simulates an audio recording.',
    'procedimentos.responseFreeTextDescription':
        'Allows recording a text response.',
    'procedimentos.responseNumberDescription':
        'Allows recording a numeric value.',
    'procedimentos.responseDateDescription': 'Allows selecting a date.',
    'procedimentos.responseSingleChoiceDescription':
        'Allows selecting one option.',
    'procedimentos.responseMultipleChoiceDescription':
        'Allows selecting one or more options.',
    'procedimentos.typeCategoryGuide': 'Guide and confirm',
    'procedimentos.typeCategoryCollect': 'Collect information',
    'procedimentos.typeCategoryEvidence': 'Record evidence',
    'procedimentos.typeCategoryIdentify': 'Identify',
    'procedimentos.itemTypePickerHelp':
        'Choose how the staff member will respond to or record this action.',
    'procedimentos.placeholderField': 'Placeholder',
    'procedimentos.unitField': 'Unit',
    'procedimentos.choiceOptions': 'Choice options',
    'procedimentos.addOption': 'Add option',
    'procedimentos.removeOption': 'Remove option',
    'procedimentos.optionField': 'Option',
    'procedimentos.validationChoiceOptions': 'Enter at least two options.',
    'procedimentos.changeTypeTitle': 'Change item type?',
    'procedimentos.changeTypeMessage':
        'The configured options will be removed for this type.',
    'procedimentos.simulatedTypeEditorHelp':
        'In demo mode, this capture will be simulated without using device resources.',
    'procedimentos.previewTitle': 'Preview',
    'procedimentos.previewUntitledProcedure': 'Untitled procedure',
    'procedimentos.previewIncompleteProcedure':
        'This procedure does not have stages to demonstrate yet.',
    'procedimentos.previewOf': 'of',
    'procedimentos.previewProgressLabel': 'Completed actions',
    'procedimentos.previewPendingMessage':
        'There are required actions pending in this stage.',
    'procedimentos.previewRequiredPending':
        'Answer this required action to continue.',
    'procedimentos.previewNextStage': 'Next stage',
    'procedimentos.previewFinishDemo': 'Finish',
    'procedimentos.previewReviewStages': 'Review stages',
    'procedimentos.previewSummaryTitle': 'Demo completed',
    'procedimentos.previewSummarySavedMessage': 'No response was saved.',
    'procedimentos.previewSummaryAnswered': 'Answered actions.',
    'procedimentos.previewSummaryNoOptionalPending':
        'No optional items pending.',
    'procedimentos.previewSummaryOptionalPending': 'Optional item pending.',
    'procedimentos.previewDiscardTitle': 'Discard responses?',
    'procedimentos.previewDiscardMessage':
        'The responses from this demo will be discarded when leaving.',
    'procedimentos.previewConfirmAction': 'Confirm action',
    'procedimentos.previewUnderstood': 'Mark as understood',
    'procedimentos.previewUnderstoodDone': 'Understood',
    'procedimentos.previewTextHint': 'Enter the response',
    'procedimentos.previewNumberHint': 'Enter a number',
    'procedimentos.previewSelectDate': 'Select date',
    'procedimentos.previewImeiHint': 'Enter IMEI',
    'procedimentos.previewUseDemoImei': 'Use demo IMEI',
    'procedimentos.previewTakePhoto': 'Take photo',
    'procedimentos.previewSimulateSignature': 'Simulate signature',
    'procedimentos.previewCaptureLocation': 'Capture location',
    'procedimentos.previewSimulateBarcode': 'Simulate reading',
    'procedimentos.previewSimulateDocument': 'Simulate attachment',
    'procedimentos.previewSimulateAudio': 'Simulate recording',
    'procedimentos.previewRemoveEvidence': 'Remove evidence',
    'procedimentos.simulatedResourceNotice':
        'Demo resource. No real data will be captured.',
    'procedimentos.previewPhotoAdded': 'Photo added',
    'procedimentos.previewSignatureAdded': 'Signature added',
    'procedimentos.previewSignatureDemoDetail': 'Demo stroke recorded',
    'procedimentos.previewLocationAdded': 'Demo location captured',
    'procedimentos.previewBarcodeAdded': 'Code read',
    'procedimentos.previewDocumentAdded': 'Document attached',
    'procedimentos.previewAudioAdded': 'Audio recorded',
    'procedimentos.operationCashRegister': 'Cash register',
    'procedimentos.operationCustomerRegistration': 'Customer registration',
    'procedimentos.triggerMomentBeforeStart': 'Before starting',
    'procedimentos.triggerMomentAfterStart': 'After starting',
    'procedimentos.triggerMomentBeforeFinish': 'Before completing',
    'procedimentos.triggerMomentAfterFinish': 'After completing',
    'procedimentos.triggerMomentBeforeDelivery': 'Before delivery',
    'procedimentos.triggerMomentAfterDelivery': 'After delivery',
    'procedimentos.triggerMomentOnDemand': 'On demand',
    'procedimentos.activationManual': 'Manual',
    'procedimentos.activationAutomatic': 'Automatic',
    'procedimentos.activationManualDescription':
        'The staff member can start this procedure when needed.',
    'procedimentos.activationAutomaticDescription':
        'In a future integration, the procedure will be shown at the configured moment.',
    'procedimentos.enforcementInformative': 'Informative',
    'procedimentos.enforcementRecommended': 'Recommended',
    'procedimentos.enforcementRequired': 'Required',
    'procedimentos.enforcementInformativeDescription':
        'Shows the procedure without requiring completion.',
    'procedimentos.enforcementRecommendedDescription':
        'Recommends completion, but should not block the operation.',
    'procedimentos.enforcementRequiredDescription':
        'In a future integration, it will require completion before continuing.',
    'procedimentos.whenExecute': 'When to execute',
    'procedimentos.addTrigger': 'Add trigger',
    'procedimentos.editTrigger': 'Edit trigger',
    'procedimentos.deleteTrigger': 'Delete trigger',
    'procedimentos.noTriggers': 'No triggers configured.',
    'procedimentos.noTriggersDescription':
        'Without triggers, the procedure will only be available for use and preview inside this module.',
    'procedimentos.triggerCount': 'triggers',
    'procedimentos.selectOperationContext': 'Select context',
    'procedimentos.selectTriggerMoment': 'Select moment',
    'procedimentos.activationMode': 'Execution mode',
    'procedimentos.enforcementMode': 'Enforcement level',
    'procedimentos.triggerEnabledHelp':
        'Controls whether this trigger will be considered in a future integration.',
    'procedimentos.saveTrigger': 'Save trigger',
    'procedimentos.triggerMomentCleared':
        'The moment was cleared because it is not compatible with the selected context.',
    'procedimentos.validationTriggerOperation':
        'Choose the operational context.',
    'procedimentos.validationTriggerMoment': 'Choose the execution moment.',
    'procedimentos.validationTriggerMomentInvalid':
        'Choose a moment compatible with the context.',
    'procedimentos.validationDuplicateTrigger':
        'A trigger with this context, moment and execution mode already exists.',
    'procedimentos.deleteTriggerTitle': 'Delete trigger?',
    'procedimentos.deleteTriggerMessage':
        'The procedure will no longer be shown at this operational moment.',
    'procedimentos.triggerSummaryNone': 'No triggers configured',
    'procedimentos.triggerSummaryOnlyInactive': 'Inactive triggers',
    'procedimentos.executionConfiguration': 'Execution configuration',
    'procedimentos.triggerSimulationNotice':
        'Trigger simulation. No real operation will be blocked.',
    'procedimentos.manualDemoExecution': 'Manual demo execution.',
    'procedimentos.operationPointSaleStartBefore': 'Before starting a sale',
    'procedimentos.operationPointSaleStartBeforeDescription':
        'Runs before opening the new sale flow.',
    'procedimentos.mobilePointAvailable': 'Available in the mobile app.',
    'procedimentos.operationalExecutionTitle': 'Before starting the sale',
    'procedimentos.operationalSummaryTitle': 'Procedure completed',
    'procedimentos.operationalNoDataSaved':
        'No response was saved in this local experimental integration.',
    'procedimentos.completeAndStartSale': 'Complete and start sale',
    'procedimentos.experimentalIntegration': 'Experimental integration',
    'procedimentos.continueToStartSale': 'Continue to sale',
    'procedimentos.continueWithoutCompleting': 'Continue without completing',
    'procedimentos.continueWithoutCompletingTitle':
        'Continue without completing?',
    'procedimentos.continueWithoutCompletingMessage':
        'This procedure is recommended before starting the sale.',
    'procedimentos.continueAnyway': 'Continue anyway',
    'procedimentos.returnToProcedure': 'Return to procedure',
    'procedimentos.cancelSaleStartTitle': 'Cancel sale start?',
    'procedimentos.cancelSaleStartMessage':
        'This procedure is required. If you leave, the new sale will not be started.',
    'procedimentos.cancelSale': 'Cancel sale',
    'procedimentos.sequenceProgressPrefix': 'Procedure',
    'procedimentos.previewNegativeTextLabel': 'What was missing?',
    'procedimentos.previewNegativeTextHint': 'Describe what was missing',
    'procedimentos.operationalLoadError': 'Could not load procedures.',
    'procedimentos.operationalBadge': 'Operational procedure',
    'procedimentos.operationalExecutionTitleReal': 'Operational procedure',
    'procedimentos.executionWillBeSaved':
        'Answers and timestamps will be saved when you finish.',
    'procedimentos.completeAndContinue': 'Complete and continue',
    'procedimentos.continueOperation': 'Continue operation',
    'procedimentos.processingSkip': 'Continuing...',
    'procedimentos.processingCancel': 'Cancelling...',
    'procedimentos.executionSaveError':
        'Could not save the answers. Please try again.',
    'procedimentos.skipSuccessTitle': 'Procedure skipped',
    'procedimentos.cancelSuccessTitle': 'Operation cancelled',
    'procedimentos.completeSuccessMessage':
        'The answers were saved and the operation can continue.',
    'procedimentos.skipSuccessMessage':
        'The procedure was skipped and the operation will continue under the current configuration.',
    'procedimentos.cancelSuccessMessage':
        'The operation was closed before moving to the next step.',
    'procedimentos.persistedConfiguration': 'Synced configuration',
    'procedimentos.editorPersistenceNotice':
        'Changes are saved for the company in the current language.',
    'procedimentos.notifyAdmin': 'Send push notification to ADMIN',
    'procedimentos.notifyAdminHelp':
        'Notifies active administrators when the condition occurs.',
    'procedimentos.notificationCondition': 'When to notify',
    'procedimentos.notificationAlways': 'On every execution',
    'procedimentos.notificationNegative': 'When an answer is negative',
    'procedimentos.notificationSkipped': 'When the procedure is skipped',
    'procedimentos.analyticsTitle': 'Results analysis',
    'procedimentos.analyticsExecutions': 'Executions',
    'procedimentos.analyticsCompletion': 'Completion rate',
    'procedimentos.analyticsNegative': 'Negative answers',
    'procedimentos.analyticsAverageTime': 'Average time',
    'procedimentos.analyticsByQuestion': 'Results by question',
    'procedimentos.analyticsRecent': 'Recent executions',
    'procedimentos.analyticsEmpty':
        'There are no executions in this period yet.',
    'procedimentos.contextSale': 'Sale',
    'procedimentos.contextTechnicalService': 'Technical service',
    'procedimentos.contextCashRegister': 'Cash register',
    'auth.loginRequiredFields': 'Please fill in email and password',
    'auth.loginTitleMobile': 'Sign in',
    'auth.loginSubtitleMobile':
        'To access your account, enter\nyour email and password',
    'auth.email': 'Email',
    'auth.password': 'Password',
    'auth.forgotPassword': 'Forgot password?',
    'auth.continue': 'Continue',
    'auth.noAccount': 'Don\'t have an account yet?',
    'auth.createAccount': 'Create account',
    'auth.signInWithApple': 'Sign in with Apple',
    'auth.signInWithGoogle': 'Sign in with Google',
    'auth.googleLoginError': 'Could not complete Google sign-in.',
    'auth.session.validatingTitle': 'Signing in to SixoApp',
    'auth.session.validatingMessage': 'Validating your session securely...',
    'splash.preparingWorkspace': 'Preparing your workspace...',
    'splash.validatingSession': 'Validating your session...',
    'splash.syncingAccount': 'Syncing your data...',
    'splash.connectedTagline': 'Everything connected. Everything in control.',
    'auth.session.temporaryErrorTitle': 'Could not validate your session',
    'auth.session.temporaryErrorMessage':
        'Your session was preserved. Check your connection and try again.',
    'webAuthGate.temporaryError.title': 'Could not validate your session',
    'webAuthGate.temporaryError.message':
        'Check your connection or wait for the backend to respond, then try again.',
    'auth.appleLoginMock': 'Apple sign-in (mocked)',
    'auth.termsPrefix':
        'By clicking "Continue", I confirm that I have read and agree with the ',
    'auth.terms': 'Terms of Use and Privacy Policy',
    'auth.mobileEntry.title': 'Your business, connected.',
    'auth.mobileEntry.subtitle':
        'Sales, inventory and management moving together — wherever you are.',
    'auth.mobileEntry.sales': 'Sales',
    'auth.mobileEntry.stock': 'Inventory',
    'auth.mobileEntry.management': 'Management',
    'auth.mobileEntry.continueTitle': 'How would you like to continue?',
    'auth.mobileEntry.loginAction': 'Sign in to my account',
    'auth.mobileEntry.createAction': 'Create my account',
    'auth.mobileEntry.securityNote':
        'Secure access with your data always protected.',
    'auth.mobileLogin.title': 'Welcome back',
    'auth.mobileLogin.subtitle': 'Sign in to continue where you left off.',
    'auth.mobileLogin.formTitle': 'Access your workspace',
    'auth.mobileLogin.emailHint': 'you@company.com',
    'auth.mobileLogin.passwordHint': 'Enter your password',
    'auth.mobileLogin.showPassword': 'Show password',
    'auth.mobileLogin.hidePassword': 'Hide password',
    'auth.mobileLogin.submit': 'Sign in',
    'auth.mobileLogin.socialDivider': 'or continue with',
    'auth.mobileLogin.createPrompt': 'New to SixoApp?',
    'auth.mobileCreate.title': 'Create your workspace',
    'auth.mobileCreate.subtitle':
        'Start simple. SixoApp grows with your business.',
    'auth.mobileCreate.formTitle': 'Your account starts here',
    'auth.mobileCreate.formNote': 'It takes less than a minute.',
    'auth.mobileCreate.loginLabel': 'Login',
    'auth.mobileCreate.loginHint': 'Choose your access login',
    'auth.mobileCreate.passwordLabel': 'Password',
    'auth.mobileCreate.passwordHint': 'At least 8 characters',
    'auth.mobileCreate.confirmPasswordLabel': 'Confirm password',
    'auth.mobileCreate.confirmPasswordHint': 'Repeat your password',
    'auth.mobileCreate.acceptTerms': 'I agree to the Terms and Privacy Policy.',
    'auth.mobileCreate.submit': 'Create account',
    'auth.mobileCreate.loginPrompt': 'Already have an account? Sign in',
    'auth.mobileCreate.acceptTermsError':
        'Accept the Terms and Conditions to continue.',
    'auth.mobileCreate.requiredFieldsError': 'Fill in all fields.',
    'auth.mobileCreate.passwordLengthError':
        'The password must be at least 8 characters long.',
    'auth.mobileCreate.passwordMismatchInline': 'Passwords do not match.',
    'auth.mobileCreate.passwordMismatchError':
        'The passwords are different. Check them and try again.',
    'auth.entry.title': 'Welcome to SixoApp',
    'auth.entry.subtitle':
        'Before continuing, choose how you want to access the app.',
    'auth.entry.hasAccountTitle': 'I already have an account',
    'auth.entry.hasAccountSubtitle':
        'Sign in with your email and password to access your company.',
    'auth.entry.loginAction': 'Sign in',
    'auth.entry.newAccountTitle': 'I am new here',
    'auth.entry.newAccountSubtitle':
        'See a quick overview and create your account to get started.',
    'auth.entry.newAccountAction': 'Explore SixoApp',
    'auth.onboarding.title': 'Start with the essentials',
    'auth.onboarding.subtitle':
        'See three quick points before creating your account.',
    'auth.onboarding.step1Title': 'Organized service',
    'auth.onboarding.step1Subtitle':
        'Register sales, quotes and service orders in a simple flow.',
    'auth.onboarding.step2Title': 'Catalog and stock in your pocket',
    'auth.onboarding.step2Subtitle':
        'Keep products, services and key information always at hand.',
    'auth.onboarding.step3Title': 'Management to grow',
    'auth.onboarding.step3Subtitle':
        'Track indicators and prepare your operation to evolve with SixoApp.',
    'auth.onboarding.skip': 'Skip',
    'auth.onboarding.next': 'Next',
    'auth.onboarding.createAccountAction': 'Create my account',
    'auth.onboarding.loginAction': 'I already have an account',
    'configuracoes.recebimento.contextTitle': 'Configurable payment methods',
    'configuracoes.recebimento.contextDescription':
        'Customize how your company receives payments. Internal codes stay fixed by the system, while names and behavior can be adjusted.',
    'configuracoes.recebimento.metricsTotal': 'Configured types',
    'configuracoes.recebimento.metricsActive': 'Active',
    'configuracoes.recebimento.metricsImmediate': 'Immediate nature',
    'configuracoes.recebimento.metricsFuture': 'Future nature',
    'configuracoes.recebimento.loadingTitle': 'Loading payment methods',
    'configuracoes.recebimento.loadingSubtitle':
        'Syncing company settings from the backend.',
    'configuracoes.recebimento.errorLoad': 'Could not load payment methods.',
    'configuracoes.recebimento.errorBadRequest':
        'Invalid data for this operation.',
    'configuracoes.recebimento.errorUnauthorized':
        'Session expired. Please sign in again.',
    'configuracoes.recebimento.errorForbidden':
        'You do not have permission to change company settings.',
    'configuracoes.recebimento.errorNotFound':
        'Payment method configuration not found.',
    'configuracoes.recebimento.errorLoadWithStatus':
        'Error loading payment methods.',
    'configuracoes.recebimento.errorSaveWithStatus':
        'Error saving payment method.',
    'configuracoes.recebimento.saveSuccess':
        'Payment method updated successfully.',
    'configuracoes.recebimento.errorSave': 'Could not save payment method.',
    'configuracoes.recebimento.restoreConfirmTitle': 'Restore defaults',
    'configuracoes.recebimento.restoreConfirmBody':
        'This action restores the 10 payment types to the company default setup.',
    'configuracoes.recebimento.restoreAction': 'Restore defaults',
    'configuracoes.recebimento.restoreSuccess':
        'Default payment method setup restored successfully.',
    'configuracoes.recebimento.restoreError':
        'Could not restore default setup.',
    'configuracoes.recebimento.countPrefix': 'Loaded types',
    'configuracoes.recebimento.activeCount': 'Active',
    'configuracoes.recebimento.refreshAction': 'Refresh',
    'configuracoes.recebimento.unnamed': 'Unnamed type',
    'configuracoes.recebimento.nature': 'Nature',
    'configuracoes.recebimento.natureImmediate': 'Immediate',
    'configuracoes.recebimento.natureFuture': 'Future',
    'configuracoes.recebimento.natureImmediateDescription':
        'Enters cash flow at the time of receipt.',
    'configuracoes.recebimento.natureFutureDescription':
        'Creates an amount receivable on a future date.',
    'configuracoes.recebimento.requiresClient': 'Requires customer',
    'configuracoes.recebimento.requiresClientDescription':
        'Required when this method depends on an identified customer.',
    'configuracoes.recebimento.installments': 'Allows installments',
    'configuracoes.recebimento.installmentsDescription':
        'Allows splitting the receipt into installments.',
    'configuracoes.recebimento.displayOrder': 'Display order',
    'configuracoes.recebimento.technicalCode': 'Technical code',
    'configuracoes.recebimento.displayName': 'Display name',
    'configuracoes.recebimento.validationName': 'Enter a display name.',
    'configuracoes.recebimento.validationNameLength':
        'Use at least 2 characters.',
    'configuracoes.recebimento.validationOrder':
        'Enter a valid order greater than or equal to 1.',
    'configuracoes.recebimento.validationColor':
        'Use a valid HEX in #RRGGBB format.',
    'configuracoes.recebimento.color': 'Color (optional)',
    'configuracoes.recebimento.icon': 'Icon (optional)',
    'configuracoes.recebimento.activeDescription':
        'Controls whether the method can be used in workflows.',
    'configuracoes.recebimento.editDialogTitle': 'Edit payment method',
    'configuracoes.recebimento.errorStateTitle': 'Could not load settings',
    'configuracoes.recebimento.emptyTitle': 'No payment methods found',
    'configuracoes.recebimento.emptyDescription':
        'Refresh the screen to sync the configured company types.',

    // Management — sections
    'gestao.title': 'Management',
    'gestao.hub.title': 'What would you like to manage?',
    'gestao.hub.subtitle':
        'Access catalog records, people, finances, and preferences.',
    'gestao.hub.terminal.products': 'Manage your products and collaborators',
    'gestao.hub.terminal.finance': 'Manage your finances',
    'gestao.hub.terminal.preferences': 'Adjust your preferences and settings',
    'gestao.catalog.title': 'Catalog',
    'gestao.catalog.subtitle': 'Products, categories and inventory',
    'gestao.people.title': 'People',
    'gestao.people.subtitle': 'Customers, team and partners',
    'gestao.finance.title': 'Finance',
    'gestao.finance.subtitle': 'Accounts, schedule and receipts',
    'gestao.settings.title': 'Settings',
    'gestao.settings.selectorTitle': 'General',
    'gestao.settings.subtitle': 'Company, language and integrations',

    // Management — Catalog items
    'gestao.catalog.productsServices': 'Products & Services',
    'gestao.catalog.productsServicesDesc': 'Health, records and catalog review',
    'gestao.catalog.categories': 'Categories',
    'gestao.catalog.categoriesDesc': 'Catalog organization',
    'gestao.catalog.inventory': 'Inventory',
    'gestao.catalog.inventoryDesc': 'Balances, entries and adjustments',

    // Management — People items
    'gestao.people.clients': 'Customers',
    'gestao.people.clientsDesc': 'Service and relationship base',
    'gestao.people.collaborators': 'Collaborators',
    'gestao.people.collaboratorsDesc': 'Team, access and responsibilities',
    'gestao.people.sixoUsers': 'Sixo users',
    'gestao.people.sixoUsersDesc':
        'Global base protected by the SUPER role',
    'gestao.people.suppliers': 'Suppliers',
    'gestao.people.suppliersDesc': 'Partners and business purchases',

    // Management — Finance items
    'gestao.finance.receivable': 'Accounts receivable',
    'gestao.finance.receivableDesc': 'Receivables and open billings',
    'gestao.finance.payable': 'Accounts payable',
    'gestao.finance.payableDesc': 'Expenses and commitments',
    'gestao.finance.schedule': 'Financial schedule',
    'gestao.finance.scheduleDesc': 'Forecasts, credit and installments',
    'gestao.finance.paymentMethods': 'Payment methods',
    'gestao.finance.paymentMethodsDesc': 'Cash, card, Pix and other means',

    // Management — Settings groups
    'gestao.settings.group.company': 'Company',
    'gestao.settings.group.teamAccess': 'Team & access',
    'gestao.settings.group.operation': 'Operation',
    'gestao.settings.group.communication': 'Communication',
    'gestao.settings.group.docsIntegrations': 'Documents & integrations',

    // Management — Settings items
    'gestao.settings.item.company.title': 'Company',
    'gestao.settings.item.company.subtitle':
        'Business registration and identity',
    'gestao.settings.item.regionalization.title': 'Regionalization',
    'gestao.settings.item.regionalization.subtitle':
        'Language, currency, country and local formats',
    'gestao.settings.item.users.title': 'Users & permissions',
    'gestao.settings.item.users.subtitle': 'Access, profiles and team security',
    'gestao.settings.item.procedures.title': 'Procedures',
    'gestao.settings.item.procedures.subtitle':
        'Guides for sales, services and deliveries',
    'gestao.settings.item.notifications.title': 'Notifications',
    'gestao.settings.item.notifications.subtitle':
        'Received events and system alerts',
    'gestao.settings.item.pdfTemplates.title': 'PDF templates',
    'gestao.settings.item.pdfTemplates.subtitle':
        'Quotes, work orders, receipts and documents',
    'gestao.settings.item.integrations.title': 'Integrations',
    'gestao.settings.item.integrations.subtitle':
        'External services and automations',

    // Management — contextual mobile overview
    'gestao.overview.selectedArea': 'Selected area',
    'gestao.overview.generalTitle': 'Overview',
    'gestao.overview.valueUnavailable': '--',
    'gestao.overview.mainActions': 'Main actions',
    'gestao.overview.errorMessage':
        'Actions are still available. Try refreshing the data in a moment.',
    'gestao.catalog.summaryTitle': 'Catalog summary',
    'gestao.catalog.metric.products': 'Products',
    'gestao.catalog.metric.productsServices': 'Products and services',
    'gestao.catalog.metric.categories': 'Categories',
    'gestao.catalog.metric.lowStock': 'Low stock',
    'gestao.catalog.lowStockAlertSemantic': 'Attention indicator for low stock',
    'gestao.catalog.loadError': 'Could not load the catalog summary.',
    'gestao.catalog.emptyTitle': 'No catalog data to show',
    'gestao.catalog.emptyMessage':
        'Add products, services or categories to fill the indicators.',
    'gestao.catalog.permissionRestrictedTitle':
        'Catalog restricted for this user',
    'gestao.catalog.permissionRestrictedMessage':
        'The Products & Services action respects current permissions.',
    'gestao.catalog.lowStockTitle': 'Inventory needs attention',
    'gestao.catalog.lowStockMessage':
        '{count} item(s) below the configured catalog threshold.',
    'gestao.catalog.lowStockAction': 'View items',
    'gestao.people.summaryTitle': 'People summary',
    'gestao.people.metric.clients': 'Customers',
    'gestao.people.metric.collaborators': 'Collaborators',
    'gestao.people.metric.suppliers': 'Suppliers',
    'gestao.people.suppliersUnavailableSemantic': 'Coming soon resource',
    'gestao.people.loadError': 'Could not load the people summary.',
    'gestao.people.emptyTitle': 'No contacts loaded',
    'gestao.people.emptyMessage':
        'Customers and collaborators will appear here when registered.',
    'gestao.people.suppliersBlockedTitle': 'Suppliers not available yet',
    'gestao.people.suppliersBlockedMessage':
        'The resource remains marked as Coming soon and has no active mobile navigation.',
    'gestao.finance.actionGroup': 'Schedule and resources',
    'gestao.finance.summaryTitle': 'Financial summary',
    'gestao.finance.metric.events': 'Upcoming events',
    'gestao.finance.metric.receivableEvents': 'Receivable',
    'gestao.finance.metric.payableEvents': 'Payable',
    'gestao.finance.loadError': 'Could not load the financial schedule.',
    'gestao.finance.emptyTitle': 'No upcoming schedule entries',
    'gestao.finance.emptyMessage':
        'Open the financial schedule to create forecasts and track due dates.',
    'gestao.finance.openSchedule': 'Open schedule',
    'gestao.finance.attentionTitle': 'Schedule with upcoming due dates',
    'gestao.finance.attentionMessage':
        '{count} overdue or due-today event(s) in the schedule.',
    'gestao.finance.blockedResourcesTitle': 'Financial resources in progress',
    'gestao.finance.blockedResourcesMessage':
        'Accounts receivable, accounts payable and payment methods remain locked on mobile.',

    // Service mobile
    'atendimento.mobile.title': 'Service',
    'atendimento.mobile.heroTitle': 'What do you want to do?',
    'atendimento.mobile.heroSubtitle':
        'Sale, service or receipt in a few steps',
    'atendimento.mobile.introTitle': 'Customer Service',
    'atendimento.mobile.introLineSales': 'sell, collect, review',
    'atendimento.mobile.introLineReturns': 'product returns',
    'atendimento.mobile.introLineServices': 'services, estimates, and more',
    'atendimento.mobile.chooseOperation': 'Choose the operation to start.',
    'atendimento.mobile.salesMenuTitle': 'Sales',
    'atendimento.mobile.newSaleTitle': 'Sales',
    'atendimento.mobile.newSaleSubtitle': 'Options',
    'atendimento.mobile.consultSalesTitle': 'View sales',
    'atendimento.mobile.consultSalesSubtitle': 'View sales history',
    'atendimento.mobile.newServiceTitle': 'Services',
    'atendimento.mobile.newServiceSubtitle': 'Create or track',
    'atendimento.mobile.servicesMenuTitle': 'Services',
    'atendimento.mobile.createServiceTitle': 'New service',
    'atendimento.mobile.createServiceSubtitle': 'Open new technical service',
    'atendimento.mobile.consultServicesInProgressTitle':
        'View services in progress',
    'atendimento.mobile.consultServicesInProgressSubtitle':
        'See active technical services',
    'atendimento.mobile.receiveTitle': 'Receive',
    'atendimento.mobile.receiveSubtitle': 'Open sales',
    'atendimento.mobile.followToday': 'Track today',
    'atendimento.mobile.salesToReceiveTitle': 'Sales to receive',
    'atendimento.mobile.salesToReceiveSubtitle': 'Unsettled sales',
    'atendimento.mobile.servicesInProgressTitle': 'Services in progress',
    'atendimento.mobile.servicesInProgressSubtitle':
        'Active technical services',
    'atendimento.mobile.moreOptions': 'More options',
    'atendimento.mobile.cashOperationsTitle': 'Cash',
    'atendimento.mobile.cashOperationsSubtitle': 'Open and move',
    'atendimento.mobile.counterLoadError': 'Could not update right now',
    'atendimento.mobile.servicesToReceiveTitle': 'Services to receive',
    'atendimento.mobile.servicesToReceiveSubtitle':
        'Technical services with open financial balance',
    'atendimento.mobile.technicalServicesPendingPaymentTitle':
        'Technical services pending payment',
    'atendimento.mobile.pendingPaymentsLoadingTitle':
        'Loading technical services',
    'atendimento.mobile.pendingPaymentsLoadingSubtitle':
        'Fetching services with open financial balance.',
    'atendimento.mobile.pendingPaymentHeaderTitle': 'Open financial balance',
    'atendimento.mobile.pendingPaymentTotalOpen': 'Total open',
    'atendimento.mobile.pendingPaymentSection': 'Services with balance',
    'atendimento.mobile.pendingPaymentErrorTitle': 'Could not load',
    'atendimento.mobile.pendingPaymentErrorMessage':
        'Try refreshing technical services in a moment.',
    'atendimento.mobile.pendingPaymentEmptyTitle': 'No services to receive',
    'atendimento.mobile.pendingPaymentEmptyMessage':
        'Technical services have no open financial balance.',
    'atendimento.mobile.onePendingPaymentService':
        '1 service with open financial balance',
    'atendimento.mobile.pendingPaymentServices':
        'services with open financial balance',
    'atendimento.mobile.serviceNumber': 'Service',
    'atendimento.mobile.openValue': 'Open amount',
    'atendimento.mobile.totalValue': 'Total amount',
    'atendimento.mobile.dueDate': 'Due on',
    'atendimento.mobile.noDueDate': 'No due date',
    'operacao.mobile.returnTitle': 'Returns and Exchanges',
    'operacao.mobile.returnSubtitle': 'Register return',
    'operacao.mobile.returnUnavailable': 'Coming soon',

    // Mobile returns
    'devolucao.mobile.title': 'Returns',
    'devolucao.mobile.introTitle': 'Find the sale',
    'devolucao.mobile.introSubtitle':
        'Use the receipt code to start a return or exchange.',
    'devolucao.mobile.saleCodeLabel': 'Sale code or ID',
    'devolucao.mobile.saleCodeHint': 'Example: SALE-1024',
    'devolucao.mobile.searchSale': 'Find sale',
    'devolucao.mobile.searching': 'Searching...',
    'devolucao.mobile.operationCompleted': 'Operation completed',
    'devolucao.mobile.saleFound': 'Sale found',
    'devolucao.mobile.changeSale': 'Change sale',
    'devolucao.mobile.unidentifiedCustomer': 'Unidentified customer',
    'devolucao.mobile.productsValue': 'Product value',
    'devolucao.mobile.returnBalance': 'Returnable balance',
    'devolucao.mobile.hasEligibleItems': 'Items are available',
    'devolucao.mobile.noEligibleBalance': 'No items available',
    'devolucao.mobile.operationTypeTitle': 'What will be done?',
    'devolucao.mobile.operationTypeSubtitle':
        'Choose between returning or exchanging products.',
    'devolucao.mobile.returnOnly': 'Return only',
    'devolucao.mobile.exchange': 'Exchange',
    'devolucao.mobile.itemsTitle': 'Products being returned',
    'devolucao.mobile.itemsSubtitle':
        'Select the items and enter quantity, condition and reason.',
    'devolucao.mobile.noItems': 'This sale has no items available for return.',
    'devolucao.mobile.soldValue': 'Sold: {value}',
    'devolucao.mobile.availableValue': 'Available: {value}',
    'devolucao.mobile.quantity': 'Quantity',
    'devolucao.mobile.maximumQuantity': 'Maximum: {value}',
    'devolucao.mobile.condition': 'Product condition',
    'devolucao.mobile.reason': 'Reason for return',
    'devolucao.mobile.stockReturn': 'Return to inventory',
    'devolucao.mobile.stockReturnOn':
        'The available product balance will be restored.',
    'devolucao.mobile.stockReturnOff':
        'The return will be recorded without restoring inventory.',
    'devolucao.mobile.exchangeItemsTitle': 'Exchange products',
    'devolucao.mobile.exchangeItemsSubtitle':
        'New products will leave inventory at the current price.',
    'devolucao.mobile.addProduct': 'Add product',
    'devolucao.mobile.exchangeEmpty':
        'Add the product the customer will receive.',
    'devolucao.mobile.selectExchangeProduct': 'Choose exchange product',
    'devolucao.mobile.searchProduct': 'Search products',
    'devolucao.mobile.noProductsTitle': 'No products found',
    'devolucao.mobile.noProductsMessage':
        'Review the search or the active product catalog.',
    'devolucao.mobile.productPrice': 'Current price: {value}',
    'devolucao.mobile.perUnit': '{value} per unit',
    'devolucao.mobile.remove': 'Remove product',
    'devolucao.mobile.financialTitle': 'Financial settlement',
    'devolucao.mobile.returnedProducts': 'Returned products',
    'devolucao.mobile.exchangeProducts': 'Exchange products',
    'devolucao.mobile.differenceReceive': 'Difference to receive',
    'devolucao.mobile.refundValue': 'Refund amount',
    'devolucao.mobile.customerPays': 'The customer pays the difference.',
    'devolucao.mobile.companyRefunds': 'The company refunds the customer.',
    'devolucao.mobile.noFinancialMovement':
        'There will be no financial movement.',
    'devolucao.mobile.paymentMethod': 'Payment or refund method',
    'devolucao.mobile.paymentHelper': 'Requires an open cash session.',
    'devolucao.mobile.selectPayment': 'Select method',
    'devolucao.mobile.searchPayment': 'Search methods',
    'devolucao.mobile.noPaymentMethods': 'No methods available',
    'devolucao.mobile.noPaymentMethodsMessage':
        'Configure an immediate payment method before completing.',
    'devolucao.mobile.reviewTitle': 'Review and complete',
    'devolucao.mobile.reviewSubtitle':
        'Confirm the data before moving inventory and cash.',
    'devolucao.mobile.notes': 'Internal notes (optional)',
    'devolucao.mobile.processing': 'Processing...',
    'devolucao.mobile.completeExchange': 'Complete exchange',
    'devolucao.mobile.completeReturn': 'Complete return',
    'devolucao.mobile.confirmationHelper':
        'Confirmation may move inventory and record the cash settlement.',
    'devolucao.mobile.recentTitle': 'Recent operations',
    'devolucao.mobile.recentSubtitle':
        'Latest returns and exchanges for this business.',
    'devolucao.mobile.loadingRecent': 'Loading recent operations',
    'devolucao.mobile.emptyRecent':
        'No returns or exchanges were completed recently.',
    'devolucao.mobile.successMessage':
        'Operation {code} completed successfully.',
    'devolucao.mobile.unexpectedError':
        'The operation could not be completed. Please try again.',
    'devolucao.mobile.validation.saleRequired':
        'Enter the sale code or identifier.',
    'devolucao.mobile.validation.invalidQuantity':
        'Enter a valid quantity for {product}.',
    'devolucao.mobile.validation.quantityExceeded':
        'The quantity of {product} exceeds the returnable balance.',
    'devolucao.mobile.validation.reasonRequired':
        'Enter the return reason for {product}.',
    'devolucao.mobile.validation.selectReturnItem':
        'Select at least one product to return.',
    'devolucao.mobile.validation.selectExchangeItem':
        'Add at least one product to the exchange.',
    'devolucao.mobile.validation.selectPayment':
        'Select the method used to settle the difference.',
    'devolucao.mobile.condition.sealed': 'New / sealed',
    'devolucao.mobile.condition.opened': 'Opened',
    'devolucao.mobile.condition.used': 'Used',
    'devolucao.mobile.condition.defective': 'Defective',
    'devolucao.mobile.condition.damaged': 'Damaged',
    'devolucao.mobile.condition.other': 'Other condition',

    // Open sales mobile
    'vendasNaoLiquidadas.recebimentos': 'Receipts',
    'vendasNaoLiquidadas.semRecebimentos': 'No receipt recorded.',
    'vendasNaoLiquidadas.referencia': 'Reference',
    'vendasNaoLiquidadas.recebimento': 'Receipt',
    'vendasNaoLiquidadas.recebimentoTotal': 'Full',
    'vendasNaoLiquidadas.recebimentoParcial': 'Partial',

    // Management — badges and admin header
    'gestao.settings.badge.experimental': 'Experimental',
    'gestao.settings.badge.comingSoon': 'Coming soon',
    'gestao.settings.adminHeader.title': 'Company settings',
    'gestao.settings.adminHeader.subtitle':
        'Organize company, team, operation and communication.',
    'gestao.catalog.webCatalog': 'Web catalog',
    'gestao.catalog.webCatalogDesc': 'Full catalog experience in the browser',
    'gestao.catalog.webCatalogBadge': 'WEB',
    'gestao.featureInProgress': 'Mobile flow in progress.',
    'produto.webList.selection.titleMany': 'Select items',
    'produto.webList.selection.titleOne': 'Select item',
    'produto.webList.selection.subtitleMany':
        'Check products and services and add everything to the sale at once.',
    'produto.webList.selection.subtitleOne':
        'Quick search to add a product or service to the sale.',
    'produto.webList.edit.title': 'Edit products',
    'produto.webList.edit.subtitle':
        'Manage your product catalog, stock, prices and images.',
    'produto.webList.default.subtitle':
        'Quick catalog lookup with counter actions.',
    'produto.webList.newItem': 'New item',
    'produto.webList.printPdf': 'Print PDF',
    'produto.webList.publicCatalogLink': 'Catalog link',
    'produto.webList.publicCatalogPreparing': 'Preparing...',
    'produto.webList.publicCatalogCopied': 'Public catalog link copied.',
    'produto.webList.publicCatalogError': 'Could not prepare the catalog link.',
    'catalogReservations.title': 'Catalog reservations',
    'catalogReservations.subtitle':
        'Track requests received through the virtual catalog.',
    'catalogReservations.loadingTitle': 'Loading reservations',
    'catalogReservations.loadingSubtitle':
        'Syncing requests for this business.',
    'catalogReservations.detailLoading': 'Loading details',
    'catalogReservations.detailLoadingSubtitle':
        'Fetching products and customer information.',
    'catalogReservations.detailTitle': 'Reservation details',
    'catalogReservations.empty': 'No reservations found.',
    'catalogReservations.error': 'Could not load reservations.',
    'catalogReservations.status': 'Status',
    'catalogReservations.filters.apply': 'Apply',
    'catalogReservations.filters.clear': 'Clear filters',
    'catalogReservations.filters.status.selectedCount': '{count} selected',
    'catalogReservations.filters.period': 'Period',
    'catalogReservations.filters.start': 'Start',
    'catalogReservations.filters.end': 'End',
    'catalogReservations.filters.date': 'Date',
    'catalogReservations.filters.date.all': 'All dates',
    'catalogReservations.filters.date.today': 'Today',
    'catalogReservations.filters.date.yesterday': 'Yesterday',
    'catalogReservations.filters.date.last7Days': 'Last 7 days',
    'catalogReservations.filters.date.next7Days': 'Next 7 days',
    'catalogReservations.filters.date.thisMonth': 'This month',
    'catalogReservations.filters.date.nextMonth': 'Next month',
    'catalogReservations.filters.date.customRange': 'Custom range',
    'catalogReservations.filters.date.pick': 'Pick a date',
    'catalogReservations.filters.date.pickRange': 'From day to day',
    'catalogReservations.filters.date.helpText': 'Select date',
    'catalogReservations.filters.date.startHelpText': 'Select start date',
    'catalogReservations.filters.date.endHelpText': 'Select end date',
    'catalogReservations.filters.date.rangeHelpText': 'Select period',
    'catalogReservations.status.received': 'Received',
    'catalogReservations.status.analysis': 'Under review',
    'catalogReservations.status.confirmed': 'Confirmed',
    'catalogReservations.status.cancelled': 'Cancelled',
    'catalogReservations.status.converted': 'Converted to sale',
    'catalogReservations.convert.title': 'Convert to sale',
    'catalogReservations.convert.description':
        'Validates stock and creates an accounts-receivable sale with these products.',
    'catalogReservations.convert.action': 'Convert to sale',
    'catalogReservations.convert.processing': 'Converting...',
    'catalogReservations.convert.confirmTitle': 'Convert reservation to sale?',
    'catalogReservations.convert.confirmMessage':
        'Stock will be validated and the items will be sent to an accounts-receivable sale.',
    'catalogReservations.convert.success':
        'Reservation converted to an accounts-receivable sale.',
    'catalogReservations.convert.convertedTitle': 'Sale created',
    'catalogReservations.convert.saleId': 'Sale',
    'catalogReservations.convert.error.stock':
        'Insufficient stock to convert this reservation.',
    'catalogReservations.convert.error.confirmedOnly':
        'Confirm the reservation before converting it to a sale.',
    'catalogReservations.convert.error.processing':
        'This reservation is already being converted. Refresh the screen.',
    'catalogReservations.convert.error.paymentConfig':
        'Configure a future payment type before conversion.',
    'catalogReservations.convert.error.product':
        'One of the reserved products is no longer available.',
    'catalogReservations.convert.error.generic':
        'The reservation could not be converted to a sale.',
    'catalogReservations.items': 'items',
    'catalogReservations.products': 'Reserved products',
    'catalogReservations.notes': 'Notes',
    'catalogReservations.noNotes': 'No notes provided.',
    'catalogReservations.previous': 'Previous page',
    'catalogReservations.next': 'Next page',
    'produto.webList.edit.banner':
        'Edit mode active • {count} items found • click a product to change it.',
    'produto.webList.searchHint': 'Search by name, code or SKU...',
    'produto.webList.preferenceSaved': 'View preference updated.',
    'produto.webList.view.vertical': 'Vertical',
    'produto.webList.view.horizontal': 'Horizontal',
    'produto.webList.view.list': 'List',
    'produto.webList.view.grid': 'Grid',
    'produto.webList.filter.category': 'Category',
    'produto.webList.filter.categoryAll': 'All categories',
    'produto.webList.filter.flags': 'Flags',
    'produto.webList.filter.flagsAll': 'All items',
    'produto.webList.filter.flagsFavorites': 'Favorites',
    'produto.webList.filter.flagsCatalog': 'In catalog',
    'produto.webList.filter.flagsFavoritesCatalog': 'Favorites and catalog',
    'produto.webList.filter.statusAll': 'All',
    'produto.webList.filter.stockAll': 'All',
    'produto.webList.filter.stockAvailable': 'In stock',
    'produto.webList.filter.stockLow': 'Low stock',
    'produto.webList.filter.stockOut': 'Out of stock',
    'produto.webList.filter.stockNegative': 'Negative stock',
    'produto.webList.sort.label': 'Sort',
    'produto.webList.sort.name': 'Sort by name',
    'produto.webList.sort.priceAsc': 'Lowest price',
    'produto.webList.sort.priceDesc': 'Highest price',
    'produto.webList.quick.withImage': 'With image',
    'produto.webList.quick.lowStock': 'Low stock',
    'produto.webList.errorTitle': 'Could not load the catalog.',
    'produto.webList.itemWithoutName': 'Unnamed item',
    'produto.webList.table.product': 'Product',
    'produto.webList.table.category': 'Category',
    'produto.webList.table.code': 'Code',
    'produto.webList.table.price': 'Price',
    'produto.webList.itemsPerPageLabel': 'Items per page',
    'produto.webList.pagination.summary':
        'Showing {start} to {end} of {total} items',
    'produto.webList.stockNotApplicable': 'No stock control',
    'produto.webList.stockQuantity': 'Qty {value}',
    'produto.webList.stockLow': 'Low stock',
    'produto.webList.stockOut': 'Out of stock',
    'produto.webList.stockNegative': 'Negative stock',
    'produto.webList.codeUnavailable': 'No code',
    'produto.webList.viewAction': 'View',
    'produto.favorite.addTooltip': 'Mark as favorite',
    'produto.favorite.removeTooltip': 'Remove from favorites',
    'produto.favorite.enabledFeedback': 'Favorite enabled',
    'produto.favorite.disabledFeedback': 'Favorite disabled',
    'produto.favorite.updateError':
        'Could not update the product favorite flag.',
    'produto.catalog.enableTooltip': 'Make available for catalog',
    'produto.catalog.disableTooltip': 'Remove from catalog availability',
    'produto.catalog.enabledFeedback': 'Available for catalog enabled',
    'produto.catalog.disabledFeedback': 'Available for catalog disabled',
    'produto.catalog.updateError': 'Could not update catalog availability.',
    'produto.catalog.statusLabel': 'Catalog',
    'produto.catalog.availableStatus': 'Available',
    'produto.catalog.unavailableStatus': 'Unavailable',
  },
  'es': {
    'produto.journey.changeMode': 'Cambiar',
    'clientes.journey.title': 'Elige la jornada de registro',
    'clientes.journey.subtitle':
        'Guarda solo lo esencial o enriquece el perfil del cliente ahora.',
    'clientes.journey.simpleTitle': 'Registro simple',
    'clientes.journey.simpleSubtitle':
        'Nombre, documento, teléfono y correo para registrar sin fricción.',
    'clientes.journey.completeTitle': 'Registro completo',
    'clientes.journey.completeSubtitle':
        'Dirección, crédito y contexto para una operación más preparada.',
    'clientes.journey.stepEssential': 'Esenciales',
    'clientes.journey.stepAddress': 'Dirección',
    'clientes.journey.stepRelationship': 'Crédito y relación',
    'clientes.journey.step': 'Paso',
    'clientes.journey.of': 'de',
    'clientes.journey.reviewBeforeSave': 'Revisa los datos antes de guardar.',
    'clientes.journey.continueHint': 'Avanza cuando este paso esté listo.',
    'clientes.quality.title': 'Calidad del registro',
    'clientes.quality.levelInitial': 'Comenzando ahora',
    'clientes.quality.levelEssential': 'Perfil esencial listo',
    'clientes.quality.levelDetailed': 'Perfil bien detallado',
    'clientes.quality.levelExcellent': 'Perfil excelente',
    'clientes.quality.actionName': 'informar nombre',
    'clientes.quality.actionDocument': 'informar documento',
    'clientes.quality.actionPhone': 'informar teléfono',
    'clientes.quality.actionEmail': 'informar correo',
    'clientes.quality.actionZip': 'informar código postal',
    'clientes.quality.actionAddress': 'completar dirección',
    'clientes.quality.actionCredit': 'configurar crédito',
    'clientes.quality.actionNotes': 'agregar contexto',
    'clientes.form.invalidEmail': 'Ingresa un correo válido',
    'produto.quality.title': 'Calidad del registro',
    'produto.quality.levelEssential': 'Esencial',
    'produto.quality.levelReady': 'Listo para vender',
    'produto.quality.levelPrepared': 'Bien preparado',
    'produto.quality.levelExcellent': 'Excelente',
    'produto.quality.nextActions': 'Próximas mejoras que aumentan la calidad:',
    'produto.quality.completeMessage':
        'Registro bien preparado para este nivel.',
    'produto.quality.actionName': 'Informar nombre',
    'produto.quality.actionPrice': 'Agregar precio',
    'produto.quality.actionCategory': 'Elegir categoría',
    'produto.quality.actionIdentifier': 'Agregar código',
    'produto.quality.actionOrganization': 'Informar grupo',
    'produto.quality.actionStock': 'Configurar stock',
    'produto.quality.actionImage': 'Agregar imagen',
    'produto.quality.actionDetails': 'Completar detalles',
    'produto.quality.actionRules': 'Revisar reglas',
    'produto.quality.actionFiscal': 'Informar datos fiscales',
    'app.title': 'SixoApp',
    'common.save': 'Guardar',
    'common.cancel': 'Cancelar',
    'common.back': 'Volver',
    'common.close': 'Cerrar',
    'common.edit': 'Editar',
    'common.delet\u0065': 'Eliminar',
    'common.search': 'Buscar',
    'common.clear': 'Limpiar',
    'common.confirm': 'Confirmar',
    'common.apply': 'Aplicar',
    'common.continue': 'Continuar',
    'common.tryAgain': 'Intentar de nuevo',
    'common.loading': 'Cargando...',
    'common.noResults': 'No se encontraron resultados',
    'common.unexpectedError': 'Error inesperado',
    'common.unableToLoad': 'No se pudo cargar.',
    'common.savedSuccessfully': 'Configuración guardada correctamente.',
    'common.yes': 'Sí',
    'common.no': 'No',
    'common.active': 'Activo',
    'common.inactive': 'Inactivo',
    'common.online': 'Online',
    'common.offline': 'Offline',
    'common.required': 'Obligatorio',
    'common.optional': 'Opcional',
    'common.soon': 'Próximamente',
    'common.refresh': 'Actualizar',
    'common.copy': 'Copiar',
    'common.share': 'Compartir',
    'common.number': 'Número',
    'common.all': 'Todos',
    'common.customer': 'Cliente',
    'common.updatedAt': 'Actualizado el',
    'common.lastUpdatedAt': 'Última actualización a las',
    'common.notInformed': 'No informado',
    'pdv.quantityEditor.title': 'Editar cantidad',
    'pdv.quantityEditor.tooltip': 'Editar cantidad',
    'pdv.quantityEditor.subtitle':
        'Revisa el artículo y aplica la nueva cantidad. El subtotal del artículo y el total de la venta se recalcularán de inmediato.',
    'pdv.quantityEditor.codeLabel': 'Código',
    'pdv.quantityEditor.currentLabel': 'Cantidad actual',
    'pdv.quantityEditor.currentHint':
        'El ajuste fino sigue disponible en los botones laterales.',
    'pdv.quantityEditor.fieldLabel': 'Nueva cantidad',
    'pdv.quantityEditor.hint':
        'Ingresa la cantidad deseada para este artículo.',
    'pdv.quantityEditor.invalid': 'Ingresa una cantidad entera mayor que cero.',
    'pdv.quantityEditor.effectHint':
        'El cambio actualiza de inmediato el subtotal del artículo y el total de la venta.',
    'pdv.quantityEditor.confirm': 'Aplicar cantidad',
    'pdv.customerIdentification.title': 'Identificar cliente',
    'pdv.customerIdentification.subtitle':
        'Selecciona un cliente registrado o crea uno nuevo sin salir de esta etapa.',
    'pdv.customerIdentification.availableCustomers': 'Clientes activos',
    'pdv.customerIdentification.currentCustomer': 'Cliente actual',
    'pdv.customerIdentification.currentEmpty': 'Ningún cliente vinculado',
    'pdv.customerIdentification.searchLabel':
        'Buscar cliente por nombre, documento, teléfono o correo',
    'pdv.customerIdentification.loading': 'Cargando clientes activos...',
    'pdv.customerIdentification.loadError':
        'No se pudieron cargar los clientes.',
    'pdv.customerIdentification.errorTitle':
        'No se pudieron cargar los clientes',
    'pdv.customerIdentification.newCustomer': 'Registrar cliente',
    'pdv.customerIdentification.openingCreate': 'Abriendo registro...',
    'pdv.customerIdentification.createError':
        'No se pudo abrir el registro del cliente ahora.',
    'pdv.customerIdentification.emptyTitle':
        'No hay clientes activos registrados',
    'pdv.customerIdentification.emptyMessage':
        'Registra al cliente ahora para continuar sin salir de esta etapa.',
    'pdv.customerIdentification.emptySearchTitle':
        'No se encontró ningún cliente',
    'pdv.customerIdentification.emptySearchMessage':
        'Revisa los términos de búsqueda o registra un nuevo cliente para continuar.',
    'pdv.customerIdentification.removeCustomer': 'Quitar cliente actual',
    'pdv.customerIdentification.unnamedCustomer': 'Cliente sin nombre',
    'pdv.customerIdentification.personTypeFallback': 'PF',
    'pdv.customerIdentification.noDocument': 'Sin documento',
    'pdv.customerIdentification.creditEnabled': 'Crédito habilitado',
    'pdv.customerIdentification.creditBlocked':
        'Crédito bloqueado para nuevas ventas',
    'pdv.customerIdentification.creditDisabled':
        'Cliente sin crédito habilitado',
    'pdv.customerIdentification.selected': 'Seleccionado',
    'pdv.customerIdentification.select': 'Seleccionar',
    'pdv.quantityEditor.processing': 'Aplicando cantidad...',
    'pdv.quantityEditor.successTitle': 'Cantidad actualizada',
    'pdv.quantityEditor.successMessage':
        'El artículo fue recalculado y la venta ya refleja la nueva cantidad.',
    'pdv.quantityEditor.error':
        'No fue posible actualizar la cantidad ahora. Inténtalo de nuevo en unos instantes.',
    'pdv.clearSale.dialogBarrier': 'Confirmar limpieza de la venta actual',
    'pdv.clearSale.dialogTitle': '¿Limpiar venta actual?',
    'pdv.clearSale.dialogSubtitle':
        'Revise el resumen antes de limpiar. La atención actual se reiniciará para abrir una nueva venta.',
    'pdv.clearSale.summaryItems': 'Artículos',
    'pdv.clearSale.summaryTotal': 'Total',
    'pdv.clearSale.summaryCustomer': 'Cliente',
    'pdv.clearSale.confirmAction': 'Limpiar venta',
    'pdv.clearSale.impactHint':
        'Los artículos, el cliente identificado y los cobros temporales se eliminarán de este TPV.',
    'pdv.clearSale.processingTitle': 'Limpiando venta...',
    'pdv.clearSale.processingMessage':
        'Espera mientras se eliminan los datos temporales de esta venta.',
    'pdv.clearSale.successTitle': 'Venta limpiada correctamente',
    'pdv.clearSale.successMessage':
        'El TPV está listo para iniciar una nueva venta.',
    'pdv.clearSale.error':
        'No fue posible limpiar la venta ahora. Inténtalo de nuevo en unos instantes.',
    'recebimento.valorEmAberto': 'Valor pendiente',
    'recebimento.summaryType': 'Tipo',
    'recebimento.total': 'Total',
    'recebimento.parcial': 'Parcial',
    'recebimento.formasRecebimento': 'Formas de cobro',
    'recebimento.restante': 'Restante',
    'recebimento.valorForma': 'Valor de la forma',
    'recebimento.tipoRecebimento': 'Forma de cobro',
    'recebimento.carregandoTipos': 'Cargando formas de cobro...',
    'recebimento.adicionarForma': 'Añadir forma',
    'recebimento.removerForma': 'Eliminar forma',
    'recebimento.observacao': 'Observación',
    'recebimento.receberTotal': 'Cobrar total',
    'recebimento.receberParcial': 'Cobrar parcial',
    'recebimento.erroValoresMaioresQueZero':
        'Introduzca valores mayores que cero.',
    'recebimento.erroValorMaiorQueZero': 'Introduzca un valor mayor que cero.',
    'recebimento.erroParcialMenorQueAberto':
        'Para un cobro parcial, introduzca menos que el saldo pendiente.',
    'recebimento.erroTotalIgualSaldo':
        'Para un cobro total, el valor debe liquidar el saldo pendiente.',
    'recebimento.erroFormaDuplicada':
        'Cada forma de cobro puede utilizarse solo una vez.',
    'pdv.receipt.type': 'Tipo de cobro',
    'pdv.receipt.partialReady':
        'Cobro parcial listo. El saldo restante quedará pendiente.',
    'pdv.receipt.partialHint':
        'Introduzca un valor mayor que cero y menor que el total de la venta.',
    'pdv.receipt.partialDefined': 'Parcial definido',
    'pdv.receipt.confirmPartial': 'Confirmar cobro parcial',
    'pdv.receipt.confirmPartialMessage': '¿Desea cobrar',
    'pdv.receipt.keepOpenBalance': 'y mantener pendiente el saldo restante',
    'vendasAReceber.openInPdv': 'Abrir en el TPV',
    'pdv.openSale.status': 'Venta pendiente',
    'pdv.openSale.readOnlyStatus': 'Solo consulta',
    'pdv.openSale.readOnlyTitle': 'Consulta de venta pendiente',
    'pdv.openSale.readOnlySubtitle':
        'Los productos, las cantidades y los precios están bloqueados en esta etapa. Revise los datos y cobre el saldo.',
    'pdv.openSale.editStatus': 'Edición de artículos',
    'pdv.openSale.editTitle': 'Revise los artículos antes de cobrar',
    'pdv.openSale.editSubtitle':
        'Añada o elimine productos y servicios y cambie cantidades. Se conservan los precios originales; los artículos nuevos usan el precio actual del catálogo. Los cambios se aplican solo al cobrar.',
    'pdv.openSale.partialReadOnlySubtitle':
        'Esta venta ya tiene cobros. Para conservar el historial financiero, sus artículos permanecen bloqueados.',
    'pdv.openSale.pendingChanges': 'Cambios pendientes',
    'pdv.openSale.receiveBalance': 'Cobrar saldo',
    'pdv.openSale.receiveUpdatedSale': 'Cobrar venta revisada',
    'pdv.openSale.receiveTitle': 'Cobrar saldo de la venta',
    'pdv.openSale.receiptNote': 'Saldo cobrado desde el TPV web.',
    'pdv.openSale.updatedReceiptNote':
        'Venta revisada y cobrada desde el TPV web.',
    'pdv.openSale.receivedMessage': 'Venta cobrada correctamente.',
    'pdv.openSale.receiptErrorTitle': 'No se pudo cobrar la venta',
    'pdv.openSale.originalTotal': 'Total original',
    'pdv.openSale.openBalance': 'Saldo pendiente',
    'pdv.openSale.currentTotal': 'Nuevo total',
    'pdv.openSale.totalDifference': 'Diferencia',
    'pdv.openSale.emptyItemsTitle': 'La venta debe tener artículos',
    'pdv.openSale.emptyItemsMessage':
        'Añada al menos un producto o servicio antes de cobrar la venta.',
    'pdv.openSale.invalidItemsTitle': 'Revise los artículos de la venta',
    'pdv.openSale.invalidItemsMessage':
        'Todos los artículos deben tener nombre, cantidad positiva y precio válido.',
    'pdv.openSale.confirmChangesTitle': '¿Confirmar artículos revisados?',
    'pdv.openSale.confirmChangesMessage':
        'Al cobrar, se aplicará la nueva composición de artículos y se conciliarán el inventario y las finanzas.',
    'pdv.openSale.continueToReceipt': 'Continuar al cobro',
    'pdv.openSale.outdatedTitle': 'La venta ha cambiado',
    'pdv.openSale.outdatedMessage':
        'Otra operación modificó esta venta. Cierre la consulta y ábrala de nuevo para usar los datos actuales.',
    'pdv.openSale.exitTitle': '¿Salir de la consulta?',
    'pdv.openSale.exitMessage':
        'La venta seguirá pendiente. No se modificará ningún artículo, precio ni cobro.',
    'pdv.openSale.exitAction': 'Salir de la consulta',
    'pdv.openSale.discardTitle': '¿Descartar cambios?',
    'pdv.openSale.discardMessage':
        'Los cambios realizados en el TPV no se guardarán. La venta seguirá pendiente con los datos anteriores.',
    'pdv.openSale.discardAction': 'Descartar y salir',
    'pdv.openSale.replaceTitle': '¿Reemplazar la venta actual?',
    'pdv.openSale.replaceMessage':
        'Los datos actuales del TPV serán reemplazados por la venta pendiente seleccionada.',
    'pdv.openSale.replaceAction': 'Abrir venta',
    'pdv.openSale.loadedMessage':
        'Venta cargada para revisión. Puede añadir, eliminar y cambiar cantidades antes de cobrar.',
    'pdv.openSale.loadedReadOnlyMessage':
        'Venta cargada para consulta. Como ya tiene cobros, sus artículos permanecen bloqueados.',
    'pdv.openSale.loadErrorTitle': 'No se pudo abrir la venta',
    'pdv.openSale.unavailableTitle': 'Venta no disponible',
    'pdv.openSale.unavailableMessage':
        'La venta puede haber sido cobrada o cancelada por otro usuario.',
    'common.generating': 'Generando...',
    'common.saving': 'Guardando...',
    'common.rangeTo': 'a',
    'common.weekday.monday': 'Lunes',
    'common.weekday.tuesday': 'Martes',
    'common.weekday.wednesday': 'Miércoles',
    'common.weekday.thursday': 'Jueves',
    'common.weekday.friday': 'Viernes',
    'common.weekday.saturday': 'Sábado',
    'common.weekday.sunday': 'Domingo',
    'common.weekdayShort.monday': 'Lun',
    'common.weekdayShort.tuesday': 'Mar',
    'common.weekdayShort.wednesday': 'Mié',
    'common.weekdayShort.thursday': 'Jue',
    'common.weekdayShort.friday': 'Vie',
    'common.weekdayShort.saturday': 'Sáb',
    'common.weekdayShort.sunday': 'Dom',
    'web.navigation.home': 'Inicio',
    'web.navigation.operations': 'Operaciones',
    'web.navigation.operations.pos': 'Punto de venta',
    'web.navigation.operations.technicalService': 'Servicios técnicos',
    'web.navigation.operations.purchases': 'Compras',
    'web.navigation.operations.reservations': 'Reservas',
    'web.navigation.catalog': 'Catálogo',
    'web.navigation.catalog.publicPage': 'Página pública',
    'web.navigation.catalog.reservations': 'Reservas',
    'web.navigation.catalog.products': 'Productos',
    'web.navigation.catalog.services': 'Servicios',
    'web.navigation.catalog.stock': 'Inventario',
    'web.navigation.catalog.categories': 'Categorías',
    'catalog.publicPage.title': 'Página pública del catálogo',
    'catalog.publicPage.subtitle':
        'Personaliza, visualiza y comparte tu vitrina en un solo lugar.',
    'catalog.publicPage.open': 'Abrir',
    'catalog.publicPage.copy': 'Copiar enlace',
    'catalog.publicPage.share': 'Compartir',
    'catalog.publicPage.published': 'Publicado',
    'catalog.publicPage.offline': 'Fuera de línea',
    'catalog.publicPage.save': 'Guardar cambios',
    'catalog.publicPage.discard': 'Descartar',
    'catalog.publicPage.saveSuccessPublished':
        'Página guardada y publicada correctamente.',
    'catalog.publicPage.saveSuccessDraft':
        'Personalización guardada. Publícala cuando esté lista.',
    'catalog.publicPage.saveError':
        'No fue posible guardar la página del catálogo.',
    'catalog.publicPage.openError':
        'No fue posible abrir el catálogo en una nueva pestaña.',
    'catalog.publicPage.linkCopied': 'Enlace público copiado.',
    'catalog.publicPage.shareSubject': 'Catálogo de {title}',
    'catalog.publicPage.shareFallback':
        'Compartir no está disponible. Se copió el enlace público.',
    'catalog.publicPage.loadErrorTitle':
        'No fue posible cargar la página pública',
    'catalog.publicPage.editor.publication': 'Catálogo publicado',
    'catalog.publicPage.editor.publicationOn':
        'Los clientes pueden acceder mediante el enlace público.',
    'catalog.publicPage.editor.publicationOff':
        'El enlace se conserva, pero no está disponible.',
    'catalog.publicPage.editor.content': 'Presentación',
    'catalog.publicPage.editor.contentHelp':
        'Define el mensaje que abre tu vitrina.',
    'catalog.publicPage.editor.titleLabel': 'Título de la vitrina',
    'catalog.publicPage.editor.titleHint': 'Ej.: Encuentra lo que necesitas',
    'catalog.publicPage.editor.descriptionLabel': 'Descripción breve',
    'catalog.publicPage.editor.descriptionHint':
        'Explica en una frase qué encontrará el cliente.',
    'catalog.publicPage.editor.appearance': 'Apariencia',
    'catalog.publicPage.editor.appearanceHelp':
        'Elige el estilo visual y el color destacado.',
    'catalog.publicPage.editor.accentColor': 'Color destacado',
    'catalog.publicPage.editor.customColor': 'Color personalizado',
    'catalog.publicPage.editor.invalidColor':
        'Usa un color hexadecimal con buen contraste, como #126BFF.',
    'catalog.publicPage.editor.layout': 'Contenido y diseño',
    'catalog.publicPage.editor.layoutHelp':
        'Controla la densidad y la información visible.',
    'catalog.publicPage.editor.comfortable': 'Cómodo',
    'catalog.publicPage.editor.compact': 'Compacto',
    'catalog.publicPage.editor.showPrices': 'Mostrar precios',
    'catalog.publicPage.editor.showContact': 'Mostrar contactos',
    'catalog.publicPage.editor.showAddress': 'Mostrar dirección',
    'catalog.publicPage.style.classic': 'Clásico',
    'catalog.publicPage.style.classicHelp':
        'Profesional, equilibrado y familiar.',
    'catalog.publicPage.style.minimal': 'Minimalista',
    'catalog.publicPage.style.minimalHelp':
        'Más espacio y menos elementos visuales.',
    'catalog.publicPage.style.expressive': 'Expresivo',
    'catalog.publicPage.style.expressiveHelp':
        'Color y contraste para destacar la marca.',
    'catalog.publicPage.preview.title': 'Vista previa en vivo',
    'catalog.publicPage.preview.unsaved':
        'Visualizando cambios aún no guardados',
    'catalog.publicPage.preview.saved': 'Apariencia guardada en el catálogo',
    'catalog.publicPage.preview.desktop': 'Escritorio',
    'catalog.publicPage.preview.mobile': 'Móvil',
    'catalog.publicPage.preview.storeFallback': 'Tu comercio',
    'catalog.publicPage.preview.products': 'Productos disponibles',
    'catalog.publicPage.preview.chooseItems': 'Elige tus artículos',
    'catalog.publicPage.preview.empty':
        'Marca productos como disponibles para el catálogo.',
    'catalog.publicPage.unpublish.barrier': 'Confirmar retirada del catálogo',
    'catalog.publicPage.unpublish.title': '¿Retirar el catálogo?',
    'catalog.publicPage.unpublish.body':
        'Los clientes con el enlace dejarán de ver los productos hasta una nueva publicación.',
    'catalog.publicPage.unpublish.action': 'Retirar',
    'catalog.publicPage.unpublish.processing':
        'Retirando el catálogo de línea...',
    'catalog.publicPage.unpublish.processingBody':
        'Espera mientras actualizamos el acceso público.',
    'catalog.publicPage.unpublish.success': 'Catálogo retirado',
    'catalog.publicPage.unpublish.successBody':
        'El enlace se conservó y podrá reactivarse después.',
    'catalog.publicPage.unpublish.error':
        'No fue posible retirar el catálogo. Inténtalo de nuevo.',
    'produto.dashboard.importSpreadsheetSoon':
        'Importar por hoja de cálculo (próximamente)',
    'web.navigation.people': 'Personas',
    'web.navigation.people.customers': 'Clientes',
    'web.navigation.people.collaborators': 'Colaboradores',
    'web.navigation.people.sixoUsers': 'Usuarios de Sixo',
    'web.navigation.people.performance': 'Desempeño',
    'web.navigation.cash': 'Caja',
    'web.navigation.financial': 'Financiero',
    'web.navigation.financial.agenda': 'Agenda financiera',
    'web.navigation.settings': 'Configuración',
    'web.navigation.reports': 'Informes',
    'web.navigation.unavailable': 'Destino no disponible en esta versión.',
    'usuariosSixo.title': 'Usuarios de Sixo',
    'usuariosSixo.subtitle':
        'Consulta todos los usuarios registrados con acceso exclusivo para el perfil SUPER.',
    'usuariosSixo.summarySemantics':
        'Resumen de usuarios registrados en Sixo',
    'usuariosSixo.summaryTitle': 'Base global de usuarios',
    'usuariosSixo.summarySubtitle':
        'Consulta protegida por el perfil SUPER del token.',
    'usuariosSixo.totalLabel': 'usuarios',
    'usuariosSixo.totalRegistered': 'Usuarios registrados',
    'usuariosSixo.searchHint':
        'Buscar por nombre, correo, celular o perfil',
    'usuariosSixo.resultsLabel': 'encontrados',
    'usuariosSixo.forbiddenTitle': 'Acceso exclusivo para SUPER',
    'usuariosSixo.forbiddenMessage':
        'Tu perfil no tiene permiso para consultar los usuarios de Sixo.',
    'usuariosSixo.loading': 'Cargando usuarios de Sixo',
    'usuariosSixo.loadErrorTitle':
        'No fue posible cargar los usuarios',
    'usuariosSixo.loadError':
        'Verifica tu conexión e inténtalo de nuevo.',
    'usuariosSixo.emptyTitle': 'No se encontraron usuarios',
    'usuariosSixo.emptyMessage':
        'Ajusta la búsqueda para consultar otros usuarios.',
    'usuariosSixo.userFallback': 'Usuario de Sixo',
    'usuariosSixo.noEmail': 'Correo no informado',
    'usuariosSixo.noPhone': 'Celular no informado',
    'usuariosSixo.role.super': 'SUPER',
    'usuariosSixo.role.admin': 'Administrador',
    'usuariosSixo.role.collaborator': 'Colaborador',
    'usuariosSixo.role.customer': 'Cliente',
    'usuariosSixo.role.unknown': 'No informado',
    'usuariosSixo.detail.title': 'Detalles del usuario',
    'usuariosSixo.detail.subtitle':
        'Registro, preferencias, empresas y vínculos guardados en Sixo.',
    'usuariosSixo.detail.loadError':
        'No fue posible cargar los detalles.',
    'usuariosSixo.detail.personal': 'Datos personales',
    'usuariosSixo.detail.account': 'Cuenta y permisos',
    'usuariosSixo.detail.preferences': 'Preferencias individuales',
    'usuariosSixo.detail.globalPreferences': 'Preferencias globales',
    'usuariosSixo.detail.companies': 'Empresas vinculadas',
    'usuariosSixo.detail.links': 'Vínculos y datos contractuales',
    'usuariosSixo.detail.noCompanies': 'No hay empresas vinculadas.',
    'usuariosSixo.detail.noLinks': 'No hay vínculos registrados.',
    'usuariosSixo.detail.imageStored': 'Imagen almacenada',
    'usuariosSixo.onboarding.completed': 'Onboarding completado',
    'usuariosSixo.onboarding.pending': 'Onboarding pendiente',
    'usuariosSixo.onboarding.dialogBarrier':
        'Cambiar estado del onboarding inicial',
    'usuariosSixo.onboarding.resetTitle': '¿Solicitar nuevamente el onboarding?',
    'usuariosSixo.onboarding.resetMessage':
        'En el próximo acceso, el usuario deberá confirmar nuevamente sus datos iniciales antes de entrar al sistema.',
    'usuariosSixo.onboarding.resetAction': 'Repetir onboarding',
    'usuariosSixo.onboarding.completeTitle':
        '¿Marcar el onboarding como completado?',
    'usuariosSixo.onboarding.completeMessage':
        'El usuario dejará de ver el onboarding inicial en sus próximos accesos.',
    'usuariosSixo.onboarding.completeAction': 'Marcar como completado',
    'usuariosSixo.onboarding.processingTitle': 'Actualizando onboarding...',
    'usuariosSixo.onboarding.processingMessage':
        'Espera mientras se guarda la nueva configuración.',
    'usuariosSixo.onboarding.successTitle': 'Onboarding actualizado',
    'usuariosSixo.onboarding.successMessage':
        'La nueva regla se aplicará en el próximo acceso del usuario.',
    'usuariosSixo.onboarding.errorTitle': 'No fue posible actualizar',
    'usuariosSixo.onboarding.errorMessage':
        'Inténtalo de nuevo. No se modificó ninguna otra información.',
    'initialOnboarding.eyebrow': 'Configuración inicial',
    'initialOnboarding.step': 'Paso',
    'initialOnboarding.of': 'de',
    'initialOnboarding.identityTitle': 'Empecemos por lo esencial',
    'initialOnboarding.identitySubtitle':
        'Confirma tus datos para personalizar tu experiencia.',
    'initialOnboarding.businessTitle': '¿Qué hace tu negocio?',
    'initialOnboarding.businessSubtitle':
        'Esto solo organiza módulos y accesos. Podrás cambiarlo después.',
    'initialOnboarding.languageQuestion':
        '¿En qué idioma deseas continuar?',
    'initialOnboarding.userName': '¿Cómo podemos llamarte?',
    'initialOnboarding.companyName': 'Nombre de tu negocio',
    'initialOnboarding.salesTitle': 'Vende productos',
    'initialOnboarding.salesSubtitle':
        'Punto de venta, catálogo, inventario y ventas.',
    'initialOnboarding.servicesTitle': 'Presta servicios técnicos',
    'initialOnboarding.servicesSubtitle':
        'Atenciones, órdenes de servicio y procedimientos.',
    'initialOnboarding.start': 'Comenzar a usar SixoApp',
    'initialOnboarding.activityRequired':
        'Selecciona ventas, servicios técnicos o ambos.',
    'initialOnboarding.userNameRequired':
        'Ingresa tu nombre para continuar.',
    'initialOnboarding.companyNameRequired':
        'Ingresa el nombre de la empresa para continuar.',
    'initialOnboarding.saveError':
        'No fue posible guardar ahora. Inténtalo de nuevo.',
    'initialOnboarding.loadErrorTitle':
        'No fue posible iniciar la configuración',
    'initialOnboarding.loadErrorMessage':
        'Verifica tu conexión e inténtalo de nuevo.',
    'caixa.operacoes.openConfirmTitle': '¿Confirmar apertura de caja?',
    'caixa.operacoes.openConfirmMessage':
        '¿Deseas abrir {cashDesk} con fondo inicial de {amount}?',
    'caixa.operacoes.openConfirmAction': 'Abrir caja',
    'caixa.operacoes.closeSessionAction': 'Cerrar caja',
    'caixa.operacoes.closeDialogTitle': '¿Cerrar la sesión de caja?',
    'caixa.operacoes.closeDialogSubtitle':
        'Revise el resumen antes de continuar. Esta acción no se puede deshacer.',
    'caixa.operacoes.closeDialogCashDesk': 'Caja',
    'caixa.operacoes.closeDialogMovements': 'Movimientos',
    'caixa.operacoes.closeDialogExpectedBalance': 'Saldo esperado',
    'caixa.operacoes.closeDialogChecklistComplete':
        'Resumen operativo disponible',
    'caixa.operacoes.closeDialogBack': 'Volver',
    'caixa.operacoes.closeDialogConfirm': 'Cerrar caja',
    'caixa.operacoes.closeDialogProcessing': 'Cerrando...',
    'caixa.operacoes.closeDialogSuccessTitle': 'Caja cerrada correctamente',
    'caixa.operacoes.closeDialogSuccessMessage':
        'La sesión ha finalizado y permanece disponible en el historial.',
    'caixa.operacoes.closeDialogError':
        'No se pudo cerrar la caja. Compruebe su conexión e inténtelo de nuevo.',
    'caixa.operacoes.cancelDialogTitle': '¿Cancelar movimiento?',
    'caixa.operacoes.cancelDialogSubtitle':
        'Revise los vínculos de esta operación antes de cancelarla. Según el historial financiero, el registro puede necesitar mantenerse.',
    'caixa.operacoes.cancelDialogOperation': 'Operación',
    'caixa.operacoes.cancelDialogMethod': 'Forma',
    'caixa.operacoes.cancelDialogAmount': 'Importe',
    'caixa.operacoes.cancelDialogChecklist':
        'Si el movimiento está vinculado a cobros o registros futuros, la cancelación puede bloquearse para preservar el historial.',
    'caixa.operacoes.cancelDialogBack': 'Volver',
    'caixa.operacoes.cancelDialogConfirm': 'Cancelar operación',
    'caixa.operacoes.cancelDialogProcessing': 'Cancelando...',
    'caixa.operacoes.cancelDialogSuccessTitle': 'Movimiento cancelado',
    'caixa.operacoes.cancelDialogSuccessMessage':
        'El historial de caja se actualizó y esta operación ya no seguirá activa en la sesión actual.',
    'caixa.operacoes.cancelDialogError':
        'No se pudo cancelar el movimiento ahora. Revise los vínculos financieros e inténtelo nuevamente.',
    'caixa.operacoes.cancelDialogLinkedRecordsError':
        'Este movimiento está vinculado a cobros o registros futuros y debe permanecer registrado en el historial financiero.',
    'caixa.operacoes.cancelDialogPermissionError':
        'No tienes permiso para cancelar este movimiento.',
    'caixa.operacoes.cancelDialogConnectivityError':
        'No fue posible comunicarse con el servidor ahora. Revise su conexión e inténtelo nuevamente.',
    'caixa.operacoes.cancelDialogLikelyLinkedError':
        'No fue posible cancelar este movimiento porque puede estar vinculado a otros registros financieros. Revise los cobros relacionados e inténtelo nuevamente.',
    'caixa.operacoes.addEntryAction': 'Agregar lanzamiento',
    'caixa.operacoes.launchDialogTitle': 'Registrar lanzamiento operativo',
    'caixa.operacoes.launchDialogSubtitle':
        'Complete los datos de la operación y revíselos antes de registrarla en la caja.',
    'caixa.operacoes.launchDialogTypeLabel': 'Tipo de operación',
    'caixa.operacoes.launchDialogSelect': 'Seleccione',
    'caixa.operacoes.launchDialogAmountLabel': 'Importe',
    'caixa.operacoes.launchDialogRelatedTypeLabel': 'Forma relacionada',
    'caixa.operacoes.launchDialogReferenceLabel': 'Referencia / comprobante',
    'caixa.operacoes.launchDialogReferenceHint': 'Ej.: MOV-001',
    'caixa.operacoes.launchDialogObservationLabel': 'Observación',
    'caixa.operacoes.launchDialogObservationHint':
        'Describa con claridad el motivo del movimiento.',
    'caixa.operacoes.launchDialogLinkedSaleLabel':
        'Tiene vínculo con una venta',
    'caixa.operacoes.launchDialogLinkedSaleHint':
        'Úselo en reversiones o situaciones relacionadas con una atención anterior.',
    'caixa.operacoes.launchDialogReviewAction': 'Revisar lanzamiento',
    'caixa.operacoes.launchDialogTypeRequired':
        'Seleccione el tipo de operación.',
    'caixa.operacoes.launchDialogRelatedTypeRequired':
        'Seleccione la forma relacionada.',
    'caixa.operacoes.launchDialogAmountRequired': 'Ingrese un importe válido.',
    'caixa.operacoes.launchDialogReviewTitle':
        '¿Confirmar lanzamiento operativo?',
    'caixa.operacoes.launchDialogReviewSubtitle':
        'Revise los datos a continuación antes de registrar el movimiento en la caja.',
    'caixa.operacoes.launchDialogChecklist': 'Resumen listo para confirmar.',
    'caixa.operacoes.launchDialogEditAction': 'Editar datos',
    'caixa.operacoes.launchDialogConfirmAction': 'Registrar movimiento',
    'caixa.operacoes.launchDialogProcessing': 'Registrando...',
    'caixa.operacoes.launchDialogError':
        'No fue posible registrar el movimiento. Revise los datos e inténtelo nuevamente.',
    'caixa.operacoes.launchDialogSuccessTitle':
        'Movimiento registrado correctamente',
    'caixa.operacoes.launchDialogSuccessMessage':
        'El lanzamiento ya aparece en el historial y en el resumen de caja.',
    'caixa.operacoes.launchDialogAvailableMethods': 'Formas activas',
    'caixa.operacoes.launchDialogLinkedSaleTag': 'Vinculado a venta',
    'caixa.operacoes.historyTodayOnly': 'Solo hoy',
    'caixa.operacoes.historyPeriod': 'Período',
    'caixa.operacoes.historyPeriodToday': 'Hoy',
    'caixa.operacoes.historyPeriodLast7Days': 'Últimos 7 días',
    'caixa.operacoes.historyPeriodLast30Days': 'Últimos 30 días',
    'caixa.operacoes.historyPeriodThisMonth': 'Este mes',
    'caixa.operacoes.historyPeriodLastMonth': 'Mes pasado',
    'caixa.operacoes.historyPeriodCustomRange': 'Intervalo personalizado',
    'caixa.operacoes.historyNature': 'Naturaleza',
    'caixa.operacoes.historyStatus': 'Estado',
    'caixa.operacoes.historyOperation': 'Operación',
    'caixa.operacoes.historyMethod': 'Forma',
    'caixa.operacoes.historyStartDate': 'Fecha inicial',
    'caixa.operacoes.historyEndDate': 'Fecha final',
    'caixa.operacoes.historyStartDateHelp': 'Seleccionar fecha inicial',
    'caixa.operacoes.historyEndDateHelp': 'Seleccionar fecha final',
    'caixa.operacoes.historyClearFilters': 'Limpiar filtros',
    'caixa.operacoes.historyNoResultsFiltered':
        'No se encontraron movimientos con los filtros aplicados.',
    'caixa.operacoes.historyNoResultsToday':
        'No se registraron movimientos hoy.',
    'web.standalone.quote': 'Presupuesto',
    'web.standalone.serviceOrder': 'Orden de servicio',
    'web.shell.expandSidebar': 'Expandir navegación',
    'web.shell.collapseSidebar': 'Contraer navegación',
    'web.shell.currentCommerce': 'Comercio actual',
    'web.shell.sessionContext': 'Contexto de la sesión',
    'web.shell.workspace': 'Workspace operativo',
    'web.shell.version': 'Versión',
    'web.header.profile': 'Perfil',
    'web.header.profileTooltip': 'Mi perfil',
    'web.header.userMenu': 'Usuario',
    'web.header.myProfile': 'Mi perfil',
    'web.header.theme.dark': 'Tema oscuro',
    'web.header.theme.dark.enable': 'Activar tema oscuro',
    'web.header.theme.dark.disable': 'Desactivar tema oscuro',
    'web.header.logout': 'Salir',
    'web.logout.dialog.title': '¿Cerrar la sesión ahora?',
    'web.logout.dialog.subtitle':
        'Revise el contexto antes de salir. Volverá a la pantalla pública de inicio de sesión en este navegador.',
    'web.logout.dialog.user': 'Usuario',
    'web.logout.dialog.currentCommerce': 'Comercio actual',
    'web.logout.dialog.nextStep': 'Siguiente paso',
    'web.logout.dialog.nextStepValue': 'Pantalla pública de inicio de sesión',
    'web.logout.dialog.checklist':
        'La sesión actual se cerrará solo en este navegador.',
    'web.logout.dialog.back': 'Seguir conectado',
    'web.logout.dialog.confirm': 'Salir ahora',
    'web.logout.dialog.processing': 'Cerrando sesión...',
    'web.logout.dialog.successTitle': 'Sesión cerrada correctamente',
    'web.logout.dialog.successMessage':
        'Preparando el regreso a la pantalla pública de inicio de sesión.',
    'web.logout.dialog.error':
        'No fue posible cerrar la sesión ahora. Inténtelo nuevamente en unos instantes.',
    'workspaceHome.title': 'Mi día en SixoApp',
    'workspaceHome.greeting': 'Hola, {name}',
    'workspaceHome.unknownUser': 'usuario',
    'workspaceHome.companyFallback': 'Comercio actual',
    'workspaceHome.operationalDate': 'Hoy: {date}',
    'workspaceHome.refreshTooltip': 'Actualizar resumen del día',
    'workspaceHome.loading.title': 'Cargando resumen del día',
    'workspaceHome.loading.subtitle':
        'Buscando la situación actual de este comercio.',
    'workspaceHome.error.title': 'No fue posible cargar el resumen del día.',
    'collaboratorHome.title': 'Mi panel',
    'collaboratorHome.subtitle':
        'Sigue tus metas, ventas, servicios y prioridades de trabajo.',
    'collaboratorHome.loading': 'Cargando tu panel operativo',
    'collaboratorHome.error.user':
        'No fue posible identificar tu panel personal.',
    'collaboratorHome.attention.title': 'Prioridades del trabajo',
    'collaboratorHome.attention.clear':
        'Todo está al día en tus frentes de trabajo.',
    'collaboratorHome.attention.pending': '{count} puntos necesitan atención.',
    'collaboratorHome.attention.overdueSales': 'Ventas vencidas',
    'collaboratorHome.attention.overdueServices': 'Entregas atrasadas',
    'collaboratorHome.attention.reservations': 'Reservas para revisar',
    'collaboratorHome.sales.title': 'Mis ventas',
    'collaboratorHome.sales.period': 'Resultados de {start} a {end}',
    'collaboratorHome.sales.count': 'Ventas del mes',
    'collaboratorHome.sales.total': 'Total vendido',
    'collaboratorHome.sales.received': 'Ya recibido',
    'collaboratorHome.sales.openMonth': 'Pendiente en el mes',
    'collaboratorHome.sales.loadError':
        'No fue posible cargar el resumen de tus ventas.',
    'collaboratorHome.openSales.title': 'Ventas aún no liquidadas',
    'collaboratorHome.openSales.subtitle': 'Solo ventas registradas por ti.',
    'collaboratorHome.openSales.loadError':
        'No fue posible cargar tus ventas pendientes.',
    'collaboratorHome.openSales.empty':
        'No tienes ventas pendientes de liquidación.',
    'collaboratorHome.openSales.more': 'Hay {count} ventas pendientes más',
    'collaboratorHome.openSales.customerFallback': 'Cliente no informado',
    'collaboratorHome.openSales.saleFallback': 'Venta',
    'collaboratorHome.openSales.noDueDate': 'Sin vencimiento',
    'collaboratorHome.openSales.overdue': 'Vencida',
    'collaboratorHome.services.title': 'Mis servicios por estado',
    'collaboratorHome.services.subtitle':
        'Distribución de las atenciones donde eres el técnico.',
    'collaboratorHome.services.open': 'Abrir atenciones',
    'collaboratorHome.services.loadError':
        'No fue posible cargar tus servicios.',
    'collaboratorHome.services.empty':
        'No tienes atenciones asignadas actualmente.',
    'collaboratorHome.services.total': 'Total asignado',
    'collaboratorHome.services.inProgress': 'En curso',
    'collaboratorHome.services.dueToday': 'Entregas hoy',
    'collaboratorHome.services.overdue': 'Atrasados',
    'collaboratorHome.services.moreStatuses':
        'Hay {count} estados más con actividad',
    'collaboratorHome.services.unknownStatus': 'Sin estado',
    'collaboratorHome.reservations.title': 'Cola de reservas',
    'collaboratorHome.reservations.subtitle':
        'Solicitudes del catálogo que pueden convertirse en ventas.',
    'collaboratorHome.reservations.open': 'Abrir reservas',
    'collaboratorHome.reservations.loadError':
        'No fue posible cargar las reservas.',
    'collaboratorHome.reservations.pending': 'Pendientes',
    'collaboratorHome.reservations.received': 'Recibidas',
    'collaboratorHome.reservations.analysis': 'En análisis',
    'collaboratorHome.reservations.confirmed': 'Confirmadas',
    'collaboratorHome.reservations.converted': 'Convertidas',
    'performance.home.title': 'Mis metas',
    'performance.home.subtitle':
        'Acompaña tus metas y los resultados actualizados por SixoApp.',
    'performance.home.dashboardTitle': 'Meta vs. resultado',
    'performance.home.period': 'Resultados de {start} a {end}',
    'performance.home.accessibilityLabel': 'Dashboard de mis metas',
    'performance.home.loading': 'Cargando tus metas',
    'performance.home.loadError': 'No fue posible actualizar tus metas.',
    'performance.home.emptyTitle': 'Ninguna meta activa este mes',
    'performance.home.emptySubtitle':
        'Cuando se te asigne una meta, su resultado aparecerá aquí.',
    'performance.home.result': 'Resultado',
    'performance.home.target': 'Meta',
    'performance.indicator.salesValue': 'Valor vendido',
    'performance.indicator.salesQuantity': 'Cantidad de ventas',
    'performance.indicator.servicesValue': 'Valor en servicios',
    'performance.indicator.serviceCalls': 'Atenciones técnicas',
    'performance.indicator.finishedServiceCalls': 'Atenciones finalizadas',
    'performance.indicator.serviceCallsValue': 'Valor en atenciones',
    'workspaceHome.section.today': 'Situación de hoy',
    'workspaceHome.section.attention': 'Necesita tu atención',
    'workspaceHome.section.quickActions': 'Acciones rápidas',
    'workspaceHome.empty.today':
        'Ningún bloque del resumen está disponible para tus permisos.',
    'dashboardInicio.mobileGreetingSubtitle':
        'Consulta los principales movimientos de {empresa} hoy.',
    'workspaceHome.empty.attention': 'No hay pendientes importantes por ahora.',
    'workspaceHome.empty.quickActions':
        'No hay acciones rápidas disponibles para tus permisos.',
    'workspaceHome.cash.title': 'Caja',
    'workspaceHome.cash.open': 'Abierta',
    'workspaceHome.cash.closed': 'Cerrada',
    'workspaceHome.cash.openedAt': 'desde {time}',
    'workspaceHome.cash.openedAtWithDate': 'desde {date} a las {time}',
    'workspaceHome.cash.responsible': 'Abierta por {name}',
    'workspaceHome.technical.title': 'Servicios',
    'workspaceHome.technical.active.one': '1 en curso',
    'workspaceHome.technical.active.other': '{count} en curso',
    'workspaceHome.financial.receivableToday': 'Por cobrar hoy',
    'workspaceHome.financial.payableToday': 'Por pagar hoy',
    'workspaceHome.financial.count.one': '1 cuenta',
    'workspaceHome.financial.count.other': '{count} cuentas',
    'workspaceHome.stock.title': 'Stock',
    'workspaceHome.stock.noCritical': 'Sin alertas críticas',
    'workspaceHome.stock.belowMinimum.one': '1 por debajo del mínimo',
    'workspaceHome.stock.belowMinimum.other': '{count} por debajo del mínimo',
    'workspaceHome.stock.withoutStock.one': '1 sin stock',
    'workspaceHome.stock.withoutStock.other': '{count} sin stock',
    'workspaceHome.stock.negative.one': '1 negativo',
    'workspaceHome.stock.negative.other': '{count} negativos',
    'workspaceHome.attention.lateServices.one': '1 servicio atrasado',
    'workspaceHome.attention.lateServices.other': '{count} servicios atrasados',
    'workspaceHome.attention.waitingApproval.one':
        '1 presupuesto esperando aprobación',
    'workspaceHome.attention.waitingApproval.other':
        '{count} presupuestos esperando aprobación',
    'workspaceHome.attention.readyForPickup.one':
        '1 equipo listo para retirada',
    'workspaceHome.attention.readyForPickup.other':
        '{count} equipos listos para retirada',
    'workspaceHome.attention.overdueReceivable.one':
        '1 cuenta por cobrar vencida',
    'workspaceHome.attention.overdueReceivable.other':
        '{count} cuentas por cobrar vencidas',
    'workspaceHome.attention.overduePayable.one': '1 cuenta por pagar vencida',
    'workspaceHome.attention.overduePayable.other':
        '{count} cuentas por pagar vencidas',
    'workspaceHome.attention.stockNegative.one':
        '1 producto con stock negativo',
    'workspaceHome.attention.stockNegative.other':
        '{count} productos con stock negativo',
    'workspaceHome.attention.stockWithout.one': '1 producto sin stock',
    'workspaceHome.attention.stockWithout.other': '{count} productos sin stock',
    'workspaceHome.attention.stockBelow.one':
        '1 producto por debajo del stock mínimo',
    'workspaceHome.attention.stockBelow.other':
        '{count} productos por debajo del stock mínimo',
    'workspaceHome.action.openTechnicalServices': 'Abrir asistencias',
    'workspaceHome.action.openFinancial': 'Abrir financiero',
    'workspaceHome.action.openStock': 'Abrir stock',
    'workspaceHome.quickAction.newSale': 'Nueva venta',
    'workspaceHome.quickAction.newTechnicalService': 'Nuevo servicio',
    'workspaceHome.quickAction.cash': 'Caja',
    'workspaceHome.quickAction.financialAgenda': 'Agenda financiera',
    'streak.title': 'Racha',
    'streak.mobile': 'Mobile',
    'streak.web': 'Web',
    'streak.shared': 'General',
    'streak.longest': 'Récord',
    'streak.oneDay': '1 día',
    'streak.days': '{count} días',
    'streak.daysOfStreak': '{count} días de racha',
    'streak.keepUsing': 'Usa SixoApp todos los días para mantener tu racha.',
    'streak.startedToday': 'Tu racha empezó hoy.',
    'streak.loading': 'Cargando tus días de racha.',
    'streak.loadError': 'No se pudo cargar tu racha.',
    'dashboardInicio.mobileCompanyFilterTooltip':
        'Filtrar comercios: {comercio}',
    'dashboardInicio.mobileCompanyFilterTitle': 'Filtrar comercios',
    'dashboardInicio.mobileCompanyFilterSubtitle':
        'Elige un comercio para ver el dashboard.',
    'dashboardInicio.mobileCompanyFilterAll': 'Todos',
    'dashboardInicio.mobileCompanyFilterSearchHint': 'Buscar comercio',
    'dashboardInicio.mobileCompanyFilterEmptyTitle':
        'Ningún comercio disponible',
    'dashboardInicio.mobileCompanyFilterEmptyMessage':
        'No encontramos vínculos activos para este usuario.',
    'dashboardInicio.mobileCompanyFilterLoadError':
        'No se pudieron cargar los comercios disponibles ahora.',
    'dashboardInicio.mobileCompanyFilterSwitchError':
        'No se pudo cambiar el comercio ahora. Inténtalo de nuevo.',
    'dashboardInicio.mobileDashboardFilterTitle': 'Filtrar dashboard',
    'dashboardInicio.mobileDashboardFilterSubtitle':
        'Elige el comercio y, si hace falta, refina por colaborador.',
    'dashboardInicio.mobileDashboardFilterCompanyLabel': 'Comercio',
    'dashboardInicio.mobileDashboardFilterCompanyHelper':
        'Define qué comercio alimenta los indicadores mostrados.',
    'dashboardInicio.mobileCollaboratorFilterLabel': 'Colaborador',
    'dashboardInicio.mobileCollaboratorFilterAll': 'Todos los colaboradores',
    'dashboardInicio.mobileCollaboratorFilterHelper':
        'Muestra los indicadores del colaborador seleccionado en el dashboard.',
    'dashboardInicio.mobileCollaboratorFilterDisabledHelper':
        'Elige un comercio específico para filtrar colaboradores.',
    'dashboardInicio.mobileCollaboratorFilterLoadingHelper':
        'Cargando colaboradores del comercio actual.',
    'dashboardInicio.mobileCollaboratorFilterTitle': 'Filtrar colaborador',
    'dashboardInicio.mobileCollaboratorFilterSubtitle':
        'Elige un colaborador para refinar los indicadores.',
    'dashboardInicio.mobileCollaboratorFilterSearchHint': 'Buscar colaborador',
    'dashboardInicio.mobileCollaboratorFilterEmptyTitle':
        'Ningún colaborador disponible',
    'dashboardInicio.mobileCollaboratorFilterEmptyMessage':
        'No encontramos colaboradores activos en este comercio.',
    'dashboardInicio.mobileCollaboratorFilterLoadError':
        'No se pudieron cargar los colaboradores de este comercio ahora.',
    'dashboardInicio.mobileCollaboratorFilterSelectedFallback':
        'Colaborador seleccionado',
    'dashboardInicio.mobileInfrastructureRequestsTitle': 'Requests del backend',
    'dashboardInicio.mobileInfrastructureRequestsSubtitle':
        'Respuestas monitoreadas en la ventana seleccionada del backend.',
    'dashboardInicio.mobileInfrastructureRequestsFilterTitle':
        'Filtrar requests del backend',
    'dashboardInicio.mobileInfrastructureRequestsFilterSubtitle':
        'Indica la ventana que entra en el conteo de los estados 200, 400 y 500.',
    'dashboardInicio.mobileInfrastructureRequestsFilterValueLabel': 'Cantidad',
    'dashboardInicio.mobileInfrastructureRequestsFilterUnitLabel': 'Unidad',
    'dashboardInicio.mobileInfrastructureRequestsFilterMinutes': 'Minutos',
    'dashboardInicio.mobileInfrastructureRequestsFilterHours': 'Horas',
    'dashboardInicio.mobileInfrastructureRequestsFilterApply':
        'Aplicar ventana',
    'dashboardInicio.mobileInfrastructureRequestsMinuteSingular': 'minuto',
    'dashboardInicio.mobileInfrastructureRequestsMinutePlural': 'minutos',
    'dashboardInicio.mobileInfrastructureRequestsHourSingular': 'hora',
    'dashboardInicio.mobileInfrastructureRequestsHourPlural': 'horas',
    'mobile.nav.dash': 'dash',
    'mobile.nav.home': 'Inicio',
    'mobile.nav.management': 'Gestión',
    'mobile.nav.service': 'Atención',
    'empresa.configuracao.title': 'Empresa',
    'empresa.configuracao.loadError':
        'No se pudieron cargar los datos de la empresa.',
    'empresa.configuracao.saveSuccess':
        'Datos de la empresa actualizados correctamente.',
    'empresa.configuracao.saveError':
        'No se pudieron guardar los datos de la empresa.',
    'empresa.configuracao.summaryTitle': 'Datos del comercio',
    'empresa.configuracao.summarySubtitle':
        'Actualiza la información usada en documentos y atención.',
    'empresa.configuracao.identityTitle': 'Identidad de la empresa',
    'empresa.configuracao.identitySubtitle':
        'Revisa los datos principales antes de guardar los cambios.',
    'empresa.configuracao.legalName': 'Razón social',
    'empresa.configuracao.legalNameHint': 'Nombre legal de la empresa',
    'empresa.configuracao.tradeName': 'Nombre comercial',
    'empresa.configuracao.tradeNameHint':
        'Nombre comercial usado en la atención',
    'empresa.configuracao.document': 'Documento de la empresa',
    'empresa.configuracao.documentHint':
        'Identificación fiscal o documento equivalente',
    'empresa.configuracao.requiredField': 'Completa este campo.',
    'empresa.configuracao.readyToEdit': 'Datos listos para edición.',
    'empresa.configuracao.waitingData': 'Esperando datos de la empresa.',
    'empresa.configuracao.statusSubtitle':
        'La información guardada aparece en documentos y comprobantes del comercio.',
    'empresa.configuracao.saveChanges': 'Guardar cambios',
    'empresa.configuracao.logoTitle': 'Logo de la empresa',
    'empresa.configuracao.logoSubtitle':
        'Agrega una imagen nítida, preferiblemente cuadrada.',
    'empresa.configuracao.logoRegistered':
        'Imagen lista para guardar en el perfil del comercio.',
    'empresa.configuracao.logoSelect': 'Seleccionar logo',
    'empresa.configuracao.logoChange': 'Cambiar logo',
    'empresa.configuracao.logoRemove': 'Eliminar',
    'empresa.configuracao.logoSheetTitle': 'Registrar logo',
    'empresa.configuracao.logoSheetSubtitle':
        'Elige una imagen de la galería o toma una foto.',
    'empresa.configuracao.logoFromGallery': 'Elegir de la galería',
    'empresa.configuracao.logoFromCamera': 'Usar cámara',
    'empresa.configuracao.logoLoadError': 'No se pudo cargar el logo.',
    'empresa.configuracao.logoTooLarge': 'Elige una imagen de hasta 1 MB.',
    'empresa.configuracao.logoSemantics': 'Logo registrado de la empresa.',
    'empresa.configuracao.logoEmptySemantics': 'Ningún logo registrado.',
    'atendimentoTecnico.status': 'Estado',
    'atendimentoTecnico.filters.paymentStatus.label': 'Estado de pago',
    'atendimentoTecnico.filters.paymentStatus.tooltip':
        'Filtrar por estado de pago',
    'atendimentoTecnico.filters.paymentStatus.helper':
        'Filtre atenciones por saldo abierto o liquidado.',
    'atendimentoTecnico.filters.paymentStatus.all': 'Todos los pagos',
    'atendimentoTecnico.filters.paymentStatus.open': 'Abierto',
    'atendimentoTecnico.filters.paymentStatus.paid': 'Liquidado',
    'atendimentoTecnico.filters.multiSelected': '{count} seleccionados',
    'atendimentoTecnico.filters.technician.label': 'Técnico responsable',
    'atendimentoTecnico.filters.technician.tooltip':
        'Filtrar por técnico responsable',
    'atendimentoTecnico.filters.technician.all': 'Todos los técnicos',
    'atendimentoTecnico.filters.technician.none': 'Sin técnico responsable',
    'atendimentoTecnico.filters.technician.selectedFallback':
        'Técnico seleccionado',
    'atendimentoTecnico.filters.status.tooltip': 'Filtrar por estado',
    'atendimentoTecnico.filters.status.all': 'Todos los estados',
    'atendimentoTecnico.filters.status.allWithCount':
        'Todos los estados ({count})',
    'atendimentoTecnico.filters.status.selectedFallback': 'Estado seleccionado',
    'atendimentoTecnico.lista.openDetails': 'Ver detalles',
    'atendimentoTecnico.lista.detailsDialog.title': 'Detalles del servicio',
    'atendimentoTecnico.lista.detailsDialog.subtitle':
        'Revise finanzas, avance e historial completo antes de continuar con otra acción.',
    'atendimentoTecnico.lista.detailsDialog.barrierLabel':
        'Cerrar detalles del servicio',
    'atendimentoTecnico.web.dateFilterDialog.barrierLabel':
        'Cerrar filtro de fecha',
    'atendimentoTecnico.web.dateFilterDialog.filterLabel': 'Fecha',
    'atendimentoTecnico.web.dateFilterDialog.title': 'Filtrar por fecha',
    'atendimentoTecnico.web.dateFilterDialog.subtitle':
        'Define el intervalo de actualización de las atenciones.',
    'atendimentoTecnico.web.dateFilterDialog.fieldLabel': 'Campo',
    'atendimentoTecnico.web.dateFilterDialog.fieldValueUpdatedAt':
        'Actualización',
    'atendimentoTecnico.web.dateFilterDialog.currentRangeLabel': 'Intervalo',
    'atendimentoTecnico.web.dateFilterDialog.allDates': 'Todas las fechas',
    'atendimentoTecnico.web.dateFilterDialog.dateFrom': 'Desde {date}',
    'atendimentoTecnico.web.dateFilterDialog.dateUntil': 'Hasta {date}',
    'atendimentoTecnico.web.dateFilterDialog.dateRange': '{start} hasta {end}',
    'atendimentoTecnico.web.dateFilterDialog.startLabel': 'Inicio',
    'atendimentoTecnico.web.dateFilterDialog.endLabel': 'Fin',
    'atendimentoTecnico.web.dateFilterDialog.dateHint': 'dd/MM/yyyy',
    'atendimentoTecnico.web.dateFilterDialog.quickToday': 'Hoy',
    'atendimentoTecnico.web.dateFilterDialog.quickLast7Days': 'Últimos 7 días',
    'atendimentoTecnico.web.dateFilterDialog.quickNext7Days': 'Próximos 7 días',
    'atendimentoTecnico.web.dateFilterDialog.quickOverdue': 'Vencidos',
    'atendimentoTecnico.web.dateFilterDialog.quickLast30Days':
        'Últimos 30 días',
    'atendimentoTecnico.web.dateFilterDialog.quickThisMonth': 'Este mes',
    'atendimentoTecnico.web.dateFilterDialog.clearAction': 'Limpiar',
    'atendimentoTecnico.web.dateFilterDialog.cancelAction': 'Cancelar',
    'atendimentoTecnico.web.dateFilterDialog.applyAction': 'Aplicar',
    'atendimentoTecnico.web.dateFilterDialog.startInvalid':
        'Ingresa una fecha inicial válida.',
    'atendimentoTecnico.web.dateFilterDialog.endInvalid':
        'Ingresa una fecha final válida.',
    'atendimentoTecnico.web.dateFilterDialog.endBeforeStart':
        'La fecha final no puede ser anterior a la inicial.',
    'atendimentoTecnico.customerNotInformed': 'Cliente no informado',
    'atendimentoTecnico.expectedDelivery': 'Entrega prevista',
    'atendimentoTecnico.equipment': 'Equipo',
    'atendimentoTecnico.reportedIssue': 'Defecto',
    'atendimentoTecnico.publicStatus.title': 'Estado del servicio',
    'atendimentoTecnico.publicStatus.subtitle':
        'Sigue la etapa actual del servicio técnico por el link público.',
    'atendimentoTecnico.publicStatus.progressTitle': 'Progreso del servicio',
    'atendimentoTecnico.publicStatus.progressShort': 'Progreso del servicio',
    'atendimentoTecnico.publicStatus.serviceData': 'Datos del servicio',
    'atendimentoTecnico.publicStatus.history': 'Historial de estado',
    'atendimentoTecnico.publicStatus.noHistory':
        'No hay cambios de estado registrados.',
    'atendimentoTecnico.publicStatus.loading':
        'Cargando estado del servicio...',
    'atendimentoTecnico.publicStatus.errorTitle': 'No se pudo cargar el estado',
    'atendimentoTecnico.publicStatus.invalidLink':
        'Link inválido. Token o comercio no informado.',
    'atendimentoTecnico.publicStatus.linkTitle': 'Link público de estado',
    'atendimentoTecnico.publicStatus.linkCopied':
        'Link copiado al portapapeles.',
    'atendimentoTecnico.publicStatus.linkCopiedShort':
        'Link de estado copiado.',
    'atendimentoTecnico.publicStatus.linkHelp':
        'Envía este link al cliente para seguir el estado actual del servicio.',
    'atendimentoTecnico.publicStatus.linkMissing':
        'El backend no devolvió un link.',
    'atendimentoTecnico.publicStatus.linkError':
        'No se pudo generar el link de estado',
    'atendimentoTecnico.publicStatus.shareMessage':
        'Sigue el estado de tu servicio en el siguiente link:',
    'atendimentoTecnico.publicStatus.shareSubject': 'Estado del servicio',
    'atendimentoTecnico.publicStatus.shareFallback':
        'No se pudo abrir el compartir. El link fue copiado.',
    'atendimentoTecnico.publicStatus.publicUrlMissing':
        'La URL pública de la aplicación no está configurada.',
    'atendimentoTecnico.publicStatus.action': 'Estado público',
    'atendimentoTecnico.publicStatus.actionShort': 'Estado',
    'atendimentoTecnico.publicStatus.signaturePendingTitle':
        'Firma de aprobación pendiente',
    'atendimentoTecnico.publicStatus.signaturePendingDescription':
        'Puedes seguir el estado normalmente. Para aprobar el servicio, toca el botón y firma en la siguiente página.',
    'atendimentoTecnico.publicStatus.signatureRenewTitle':
        'Nueva firma necesaria',
    'atendimentoTecnico.publicStatus.signatureRenewDescription':
        'El servicio fue modificado después de la última aprobación. Puedes seguir el estado normalmente y firmar la versión actual cuando quieras aprobarla.',
    'atendimentoTecnico.publicStatus.signatureAction': 'Firmar aprobación',
    'atendimentoTecnico.publicStatus.signatureLinkMissing':
        'El backend no devolvió un link de firma.',
    'atendimentoTecnico.publicStatus.signatureLinkError':
        'No se pudo abrir la firma.',
    'atendimentoTecnico.publicStatus.responsibleUnit': 'Unidad responsable',
    'atendimentoTecnico.publicStatus.officialChannel': 'Canal oficial',
    'atendimentoTecnico.publicStatus.updatedByBusiness':
        'Estado actualizado por el comercio',
    'atendimentoTecnico.publicStatus.companyDataSource':
        'Datos proporcionados por el establecimiento.',
    'atendimentoTecnico.publicStatus.officialServiceChannel':
        'Canal oficial de seguimiento del servicio.',
    'atendimentoTecnico.publicStatus.externalLinkUnavailable':
        'No fue posible abrir este contacto en este dispositivo.',
    'atendimentoTecnico.mobile.loading': 'Cargando servicios técnicos',
    'atendimentoTecnico.mobile.emptyFilteredMessage':
        'No se encontraron servicios con los filtros seleccionados.',
    'atendimentoTecnico.mobile.searchHint':
        'Buscar por cliente, estado, equipo o número',
    'atendimentoTecnico.mobile.advancedFilters': 'Filtros avanzados',
    'atendimentoTecnico.mobile.advancedFiltersActive':
        'Filtros avanzados activos',
    'atendimentoTecnico.mobile.clearFilters': 'Limpiar filtros',
    'atendimentoTecnico.mobile.sortRecent': 'Más recientes',
    'atendimentoTecnico.mobile.resultCountOne': '1 servicio',
    'atendimentoTecnico.mobile.resultCountMany': '{count} servicios',
    'atendimentoTecnico.mobile.periodSummaryTitle': 'Resumen del período',
    'atendimentoTecnico.mobile.summaryServiceOne': 'servicio',
    'atendimentoTecnico.mobile.summaryServiceMany': 'servicios',
    'atendimentoTecnico.mobile.summaryOpenOne': 'abierto',
    'atendimentoTecnico.mobile.summaryOpenMany': 'abiertos',
    'atendimentoTecnico.mobile.summarySignedOne': 'firmado',
    'atendimentoTecnico.mobile.summarySignedMany': 'firmados',
    'atendimentoTecnico.mobile.summaryOpenValue': '{value} abierto',
    'atendimentoTecnico.mobile.summaryOpenValueCaption': 'abierto',
    'atendimentoTecnico.mobile.filterSheetTitle': 'Filtrar servicios',
    'atendimentoTecnico.mobile.filterPeriod': 'Período',
    'atendimentoTecnico.mobile.filterPaymentStatus': 'Estado del pago',
    'atendimentoTecnico.mobile.filterDate': 'Fecha',
    'atendimentoTecnico.mobile.filterStartDate': 'Inicio',
    'atendimentoTecnico.mobile.filterEndDate': 'Fin',
    'atendimentoTecnico.mobile.dateToday': 'Hoy',
    'atendimentoTecnico.mobile.dateAll': 'Todas las fechas',
    'atendimentoTecnico.mobile.dateRange': '{start} hasta {end}',
    'atendimentoTecnico.mobile.dateFrom': 'Desde {date}',
    'atendimentoTecnico.mobile.dateUntil': 'Hasta {date}',
    'atendimentoTecnico.mobile.dateLast7Days': 'Últimos 7 días',
    'atendimentoTecnico.mobile.dateNext7Days': 'Próximos 7 días',
    'atendimentoTecnico.mobile.dateOverdue': 'Vencidos',
    'atendimentoTecnico.mobile.filterTechnician': 'Técnico responsable',
    'atendimentoTecnico.mobile.searchTechnician': 'Buscar técnico',
    'atendimentoTecnico.mobile.allTechnicians': 'Todos los técnicos',
    'atendimentoTecnico.mobile.selectedTechnician': 'Técnico seleccionado',
    'atendimentoTecnico.mobile.noTechnicianFound': 'No se encontró técnico.',
    'atendimentoTecnico.mobile.viewOneService': 'Ver 1 servicio',
    'atendimentoTecnico.mobile.viewManyServices': 'Ver {count} servicios',
    'atendimentoTecnico.mobile.sharePdfTooltip': 'Compartir servicio',
    'atendimentoTecnico.mobile.pdfSectionTitle': 'Documento del servicio',
    'atendimentoTecnico.mobile.pdfSectionDescription':
        'PDF listo para enviar al cliente con los datos del servicio.',
    'atendimentoTecnico.mobile.pdfSectionGenerating':
        'Preparando el PDF para compartir.',
    'atendimentoTecnico.mobile.sharePdfAction': 'Compartir PDF',
    'atendimentoTecnico.mobile.pdfLoadingTitle': 'Generando PDF del servicio',
    'atendimentoTecnico.mobile.pdfLoadingSubtitle':
        'Espera mientras se prepara el documento.',
    'atendimentoTecnico.mobile.detailLoadError':
        'No se pudieron cargar los datos actualizados del servicio.',
    'atendimentoTecnico.mobile.pdfDownloaded': 'PDF descargado correctamente.',
    'atendimentoTecnico.mobile.pdfPermissionDenied':
        'No tienes permiso para compartir este servicio.',
    'atendimentoTecnico.mobile.pdfNotFound': 'Servicio no encontrado.',
    'atendimentoTecnico.mobile.pdfInvalidFile':
        'El archivo recibido no es válido.',
    'atendimentoTecnico.mobile.pdfShareUnavailable':
        'No se pudo compartir el documento.',
    'atendimentoTecnico.mobile.pdfShareError':
        'No se pudo compartir el documento.',
    'atendimentoTecnico.mobile.pdfGenerationError':
        'No se pudo generar el PDF del servicio.',
    'atendimentoTecnico.mobile.publicStatusDescription':
        'Visible para el cliente en el link de seguimiento.',
    'atendimentoTecnico.publicStatus.shareLinkAction': 'Compartir link',
    'atendimentoTecnico.mobile.paymentOpen': 'Financiero abierto',
    'atendimentoTecnico.mobile.paymentSettled': 'Financiero liquidado',
    'atendimentoTecnico.mobile.signed': 'Firmado',
    'atendimentoTecnico.mobile.signaturePending': 'Firma pendiente',
    'atendimentoTecnico.customerNotSigned': 'Cliente no firmó',
    'atendimentoTecnico.mobile.customerNotSigned': 'Cliente no firmó',
    'atendimentoTecnico.mobile.deliveryLate': 'Entrega atrasada',
    'atendimentoTecnico.signatureGate.title': 'Firma necesaria',
    'atendimentoTecnico.signatureGate.message':
        'Para avanzar a {status}, envía el link de firma al cliente, firma en este dispositivo o registra el bypass.',
    'atendimentoTecnico.signatureGate.sendLink': 'Enviar link al cliente',
    'atendimentoTecnico.signatureGate.signHere': 'Firmar en este dispositivo',
    'atendimentoTecnico.signatureGate.bypass': 'Avanzar sin firma',
    'atendimentoTecnico.signatureGate.deviceTitle': 'Recoger firma',
    'atendimentoTecnico.signatureGate.deviceMessage':
        'Registra la firma para avanzar a {status}.',
    'atendimentoTecnico.signatureGate.deviceSigner': 'Nombre de quien firma',
    'atendimentoTecnico.signatureGate.deviceDocument': 'Documento opcional',
    'atendimentoTecnico.signatureGate.deviceSignatureField': 'Firma',
    'atendimentoTecnico.signatureGate.deviceObservation':
        'Observación opcional',
    'atendimentoTecnico.signatureGate.deviceSave': 'Registrar firma',
    'atendimentoTecnico.signatureGate.deviceSignerRequired':
        'Informa el nombre de quien firma.',
    'atendimentoTecnico.signatureGate.deviceSignatureRequired':
        'Firma en el cuadro indicado.',
    'atendimentoTecnico.signatureGate.deviceSignatureSaved':
        'Firma registrada y estado actualizado.',
    'atendimentoTecnico.signatureGate.deviceSignatureError':
        'No se pudo registrar la firma',
    'atendimentoTecnico.signatureGate.publicUrlMissing':
        'La URL pública de la aplicación no está configurada.',
    'atendimentoTecnico.signatureGate.linkMissing':
        'El backend no devolvió el link de firma.',
    'atendimentoTecnico.signatureGate.linkCopied': 'Link de firma copiado.',
    'atendimentoTecnico.signatureGate.linkError':
        'No se pudo generar el link de firma',
    'atendimentoTecnico.signatureGate.shareMessage':
        'Para aprobar el servicio, firma por el link abajo:',
    'atendimentoTecnico.signatureGate.shareSubject': 'Firma del servicio',
    'atendimentoTecnico.mobile.valorOriginal': 'Valor original',
    'atendimentoTecnico.mobile.valorJaRecebido': 'Valor ya recibido',
    'atendimentoTecnico.mobile.valorEmAberto': 'Valor abierto',
    'atendimentoTecnico.mobile.liquidation': 'Liquidación',
    'atendimentoTecnico.mobile.liquidated': 'Liquidada',
    'atendimentoTecnico.mobile.notLiquidated': 'No liquidada',
    'atendimentoTecnico.mobile.products': 'Productos',
    'atendimentoTecnico.mobile.services': 'Servicios',
    'atendimentoTecnico.mobile.changeStatusAction': 'Cambiar estado',
    'atendimentoTecnico.mobile.createTitle': 'Nueva atención técnica',
    'atendimentoTecnico.mobile.createHeaderTitle': 'Iniciar asistencia',
    'atendimentoTecnico.mobile.createHeaderSubtitle':
        'Cliente, equipo y defecto en una pantalla rápida para mostrador.',
    'atendimentoTecnico.mobile.responsible': 'Responsable',
    'atendimentoTecnico.mobile.serviceChip': 'Asistencia',
    'atendimentoTecnico.mobile.quoteChip': 'Presupuesto',
    'atendimentoTecnico.mobile.noItemsChip': 'Sin ítems',
    'atendimentoTecnico.mobile.mainDataSection': 'Datos principales',
    'atendimentoTecnico.mobile.internalDescription': 'Descripción interna',
    'atendimentoTecnico.mobile.internalDescriptionHint':
        'Ej.: Cambio de pantalla iPhone 11',
    'atendimentoTecnico.mobile.equipmentType': 'Tipo de equipo',
    'atendimentoTecnico.mobile.brand': 'Marca',
    'atendimentoTecnico.mobile.model': 'Modelo',
    'atendimentoTecnico.mobile.serialNumber': 'Nº de serie',
    'atendimentoTecnico.mobile.imei': 'IMEI',
    'atendimentoTecnico.mobile.accessoriesNotes': 'Accesorios / observaciones',
    'atendimentoTecnico.mobile.accessoriesNotesHint':
        'Ej.: sin cargador, con funda, pantalla rota...',
    'atendimentoTecnico.mobile.technicalReportSection': 'Relato técnico',
    'atendimentoTecnico.mobile.customerIssue':
        'Defecto relatado por el cliente',
    'atendimentoTecnico.mobile.customerIssueHint':
        'Describe el problema informado en el mostrador.',
    'atendimentoTecnico.mobile.initialDiagnosis': 'Diagnóstico técnico inicial',
    'atendimentoTecnico.mobile.initialDiagnosisHint':
        'Opcional en este primer momento.',
    'atendimentoTecnico.mobile.datesSection': 'Fechas',
    'atendimentoTecnico.mobile.validity': 'Validez',
    'atendimentoTecnico.mobile.financialDueDate': 'Vencimiento financiero',
    'atendimentoTecnico.mobile.financialPreviewSection': 'Vista financiera',
    'atendimentoTecnico.mobile.financialPreviewDescription':
        'El valor queda abierto hasta registrar un cobro.',
    'atendimentoTecnico.mobile.valorConfirmado': 'Confirmado',
    'atendimentoTecnico.mobile.paymentStampNoValue': 'SIN VALOR',
    'atendimentoTecnico.mobile.paymentStampOpen': 'ABIERTO',
    'atendimentoTecnico.mobile.savingService': 'Iniciando atención...',
    'atendimentoTecnico.mobile.startServiceAction': 'Iniciar atención técnica',
    'auth.loginRequiredFields':
        'Completa el correo electrónico y la contraseña',
    'auth.loginTitleMobile': 'Entrar',
    'auth.loginSubtitleMobile':
        'Para acceder a tu cuenta, ingresa\ntu correo y contraseña',
    'auth.email': 'Correo electrónico',
    'auth.password': 'Contraseña',
    'auth.forgotPassword': '¿Olvidaste tu contraseña?',
    'auth.continue': 'Continuar',
    'auth.noAccount': '¿Aún no tienes una cuenta?',
    'auth.createAccount': 'Crear cuenta',
    'auth.signInWithApple': 'Entrar con Apple',
    'auth.signInWithGoogle': 'Entrar con Google',
    'auth.googleLoginError':
        'No se pudo completar el inicio de sesión con Google.',
    'auth.session.validatingTitle': 'Entrando a SixoApp',
    'auth.session.validatingMessage': 'Validando tu sesión de forma segura...',
    'splash.preparingWorkspace': 'Preparando tu espacio...',
    'splash.validatingSession': 'Validando tu sesión...',
    'splash.syncingAccount': 'Sincronizando tus datos...',
    'splash.connectedTagline': 'Todo conectado. Todo bajo control.',
    'auth.session.temporaryErrorTitle': 'No se pudo validar tu sesión',
    'auth.session.temporaryErrorMessage':
        'Tu sesión fue preservada. Verifica tu conexión e inténtalo de nuevo.',
    'webAuthGate.temporaryError.title': 'No se pudo validar tu sesión',
    'webAuthGate.temporaryError.message':
        'Verifica tu conexión o espera a que el backend responda y vuelve a intentarlo.',
    'auth.appleLoginMock': 'Inicio de sesión con Apple (mocked)',
    'auth.termsPrefix':
        'Al hacer clic en "Continuar", declaro que leí y acepto los ',
    'auth.terms': 'Términos de Uso y Política de Privacidad',
    'auth.mobileEntry.title': 'Tu negocio, conectado.',
    'auth.mobileEntry.subtitle':
        'Ventas, inventario y gestión al mismo ritmo — estés donde estés.',
    'auth.mobileEntry.sales': 'Ventas',
    'auth.mobileEntry.stock': 'Inventario',
    'auth.mobileEntry.management': 'Gestión',
    'auth.mobileEntry.continueTitle': '¿Cómo quieres continuar?',
    'auth.mobileEntry.loginAction': 'Entrar en mi cuenta',
    'auth.mobileEntry.createAction': 'Crear mi cuenta',
    'auth.mobileEntry.securityNote':
        'Acceso seguro y datos siempre protegidos.',
    'auth.mobileLogin.title': 'Bienvenido de nuevo',
    'auth.mobileLogin.subtitle': 'Entra para continuar donde lo dejaste.',
    'auth.mobileLogin.formTitle': 'Accede a tu espacio',
    'auth.mobileLogin.emailHint': 'tu@empresa.com',
    'auth.mobileLogin.passwordHint': 'Ingresa tu contraseña',
    'auth.mobileLogin.showPassword': 'Mostrar contraseña',
    'auth.mobileLogin.hidePassword': 'Ocultar contraseña',
    'auth.mobileLogin.submit': 'Entrar',
    'auth.mobileLogin.socialDivider': 'o continúa con',
    'auth.mobileLogin.createPrompt': '¿Primera vez en SixoApp?',
    'auth.mobileCreate.title': 'Crea tu espacio',
    'auth.mobileCreate.subtitle':
        'Empieza simple. SixoApp crece junto con tu negocio.',
    'auth.mobileCreate.formTitle': 'Tu cuenta empieza aquí',
    'auth.mobileCreate.formNote': 'Toma menos de un minuto.',
    'auth.mobileCreate.loginLabel': 'Usuario',
    'auth.mobileCreate.loginHint': 'Elige tu usuario de acceso',
    'auth.mobileCreate.passwordLabel': 'Contraseña',
    'auth.mobileCreate.passwordHint': 'Mínimo de 8 caracteres',
    'auth.mobileCreate.confirmPasswordLabel': 'Confirma la contraseña',
    'auth.mobileCreate.confirmPasswordHint': 'Repite tu contraseña',
    'auth.mobileCreate.acceptTerms':
        'Acepto los Términos y la Política de Privacidad.',
    'auth.mobileCreate.submit': 'Crear cuenta',
    'auth.mobileCreate.loginPrompt': '¿Ya tienes una cuenta? Entrar',
    'auth.mobileCreate.acceptTermsError':
        'Acepta los Términos y Condiciones para continuar.',
    'auth.mobileCreate.requiredFieldsError': 'Completa todos los campos.',
    'auth.mobileCreate.passwordLengthError':
        'La contraseña debe tener al menos 8 caracteres.',
    'auth.mobileCreate.passwordMismatchInline': 'Las contraseñas no coinciden.',
    'auth.mobileCreate.passwordMismatchError':
        'Las contraseñas son diferentes. Verifícalas e inténtalo de nuevo.',
    'auth.entry.title': 'Bienvenido a SixoApp',
    'auth.entry.subtitle':
        'Antes de continuar, elige cómo quieres acceder a la app.',
    'auth.entry.hasAccountTitle': 'Ya tengo una cuenta',
    'auth.entry.hasAccountSubtitle':
        'Entra con tu correo y contraseña para acceder a tu empresa.',
    'auth.entry.loginAction': 'Entrar',
    'auth.entry.newAccountTitle': 'Soy nuevo aquí',
    'auth.entry.newAccountSubtitle':
        'Mira un resumen rápido y crea tu cuenta para comenzar.',
    'auth.entry.newAccountAction': 'Conocer SixoApp',
    'auth.onboarding.title': 'Empieza por lo esencial',
    'auth.onboarding.subtitle':
        'Mira tres puntos rápidos antes de crear tu cuenta.',
    'auth.onboarding.step1Title': 'Atención organizada',
    'auth.onboarding.step1Subtitle':
        'Registra ventas, presupuestos y asistencias en un flujo simple.',
    'auth.onboarding.step2Title': 'Catálogo y stock en el bolsillo',
    'auth.onboarding.step2Subtitle':
        'Mantén productos, servicios e información esencial siempre a mano.',
    'auth.onboarding.step3Title': 'Gestión para crecer',
    'auth.onboarding.step3Subtitle':
        'Acompaña indicadores y prepara tu operación para evolucionar con SixoApp.',
    'auth.onboarding.skip': 'Saltar',
    'auth.onboarding.next': 'Avanzar',
    'auth.onboarding.createAccountAction': 'Crear mi cuenta',
    'auth.onboarding.loginAction': 'Ya tengo una cuenta',
    'configuracoes.recebimento.contextTitle': 'Formas de cobro configurables',
    'configuracoes.recebimento.contextDescription':
        'Personaliza cómo tu empresa recibe pagos. Los códigos internos se mantienen fijos por el sistema, pero el nombre y el comportamiento se pueden ajustar.',
    'configuracoes.recebimento.metricsTotal': 'Tipos configurados',
    'configuracoes.recebimento.metricsActive': 'Activos',
    'configuracoes.recebimento.metricsImmediate': 'Naturaleza inmediata',
    'configuracoes.recebimento.metricsFuture': 'Naturaleza futura',
    'configuracoes.recebimento.loadingTitle': 'Cargando formas de cobro',
    'configuracoes.recebimento.loadingSubtitle':
        'Sincronizando la configuración de la empresa desde el backend.',
    'configuracoes.recebimento.errorLoad':
        'No se pudieron cargar las formas de cobro.',
    'configuracoes.recebimento.errorBadRequest':
        'Datos inválidos para esta operación.',
    'configuracoes.recebimento.errorUnauthorized':
        'Sesión expirada. Inicia sesión nuevamente.',
    'configuracoes.recebimento.errorForbidden':
        'No tienes permiso para cambiar la configuración de la empresa.',
    'configuracoes.recebimento.errorNotFound':
        'No se encontró la configuración de la forma de cobro.',
    'configuracoes.recebimento.errorLoadWithStatus':
        'Error al cargar formas de cobro.',
    'configuracoes.recebimento.errorSaveWithStatus':
        'Error al guardar la forma de cobro.',
    'configuracoes.recebimento.saveSuccess':
        'Forma de cobro actualizada correctamente.',
    'configuracoes.recebimento.errorSave':
        'No se pudo guardar la forma de cobro.',
    'configuracoes.recebimento.restoreConfirmTitle':
        'Restaurar valores predeterminados',
    'configuracoes.recebimento.restoreConfirmBody':
        'Esta acción restaura los 10 tipos de cobro a la configuración predeterminada de la empresa.',
    'configuracoes.recebimento.restoreAction':
        'Restaurar valores predeterminados',
    'configuracoes.recebimento.restoreSuccess':
        'La configuración predeterminada de formas de cobro fue restaurada correctamente.',
    'configuracoes.recebimento.restoreError':
        'No se pudo restaurar la configuración predeterminada.',
    'configuracoes.recebimento.countPrefix': 'Tipos cargados',
    'configuracoes.recebimento.activeCount': 'Activos',
    'configuracoes.recebimento.refreshAction': 'Actualizar',
    'configuracoes.recebimento.unnamed': 'Sin nombre definido',
    'configuracoes.recebimento.nature': 'Naturaleza',
    'configuracoes.recebimento.natureImmediate': 'Inmediato',
    'configuracoes.recebimento.natureFuture': 'Futuro',
    'configuracoes.recebimento.natureImmediateDescription':
        'Ingresa en caja en el momento del cobro.',
    'configuracoes.recebimento.natureFutureDescription':
        'Genera un valor por cobrar para una fecha futura.',
    'configuracoes.recebimento.requiresClient': 'Requiere cliente',
    'configuracoes.recebimento.requiresClientDescription':
        'Obligatorio cuando esta forma depende de un cliente identificado.',
    'configuracoes.recebimento.installments': 'Permite cuotas',
    'configuracoes.recebimento.installmentsDescription':
        'Permite dividir el cobro en cuotas.',
    'configuracoes.recebimento.displayOrder': 'Orden de visualización',
    'configuracoes.recebimento.technicalCode': 'Código técnico',
    'configuracoes.recebimento.displayName': 'Nombre para mostrar',
    'configuracoes.recebimento.validationName':
        'Ingresa el nombre para mostrar.',
    'configuracoes.recebimento.validationNameLength':
        'Usa al menos 2 caracteres.',
    'configuracoes.recebimento.validationOrder':
        'Ingresa un orden válido mayor o igual a 1.',
    'configuracoes.recebimento.validationColor':
        'Usa un HEX válido con formato #RRGGBB.',
    'configuracoes.recebimento.color': 'Color (opcional)',
    'configuracoes.recebimento.icon': 'Ícono (opcional)',
    'configuracoes.recebimento.activeDescription':
        'Controla si la forma puede utilizarse en los flujos.',
    'configuracoes.recebimento.editDialogTitle': 'Editar forma de cobro',
    'configuracoes.recebimento.errorStateTitle':
        'No se pudo cargar la configuración',
    'configuracoes.recebimento.emptyTitle': 'No se encontraron formas de cobro',
    'configuracoes.recebimento.emptyDescription':
        'Actualiza la pantalla para sincronizar los tipos configurados de la empresa.',
    'procedimentos.title': 'Procedimientos',
    'procedimentos.subtitle': 'Guías para ventas, atenciones y entregas',
    'procedimentos.introTitle':
        'Configura orientaciones para ventas, atenciones y entregas.',
    'procedimentos.demoData': 'Datos demostrativos',
    'procedimentos.filtersLabel': 'Filtros de procedimientos',
    'procedimentos.filterAll': 'Todos',
    'procedimentos.filterActive': 'Activos',
    'procedimentos.filterInactive': 'Inactivos',
    'procedimentos.newProcedure': 'Nuevo procedimiento',
    'procedimentos.newProcedureSemantics': 'Nuevo procedimiento',
    'procedimentos.createProcedure': 'Crear procedimiento',
    'procedimentos.openAction': 'Abrir',
    'procedimentos.createUnavailable':
        'La creación de procedimientos estará disponible en la próxima etapa.',
    'procedimentos.editUnavailable':
        'La edición de este procedimiento estará disponible en la próxima etapa.',
    'procedimentos.loading': 'Cargando procedimientos',
    'procedimentos.emptyTitle': 'Ningún procedimiento configurado',
    'procedimentos.emptyDescription':
        'Crea orientaciones para apoyar al equipo en los momentos importantes de la operación.',
    'procedimentos.filteredEmptyTitle': 'Ningún procedimiento en este filtro',
    'procedimentos.filteredEmptyDescription':
        'Cambia el filtro para ver otros procedimientos demostrativos.',
    'procedimentos.errorTitle': 'No fue posible cargar los procedimientos',
    'procedimentos.errorDescription': 'Inténtalo nuevamente en unos instantes.',
    'procedimentos.statusDraft': 'Borrador',
    'procedimentos.operationSale': 'Venta',
    'procedimentos.operationTechnicalService': 'Atención técnica',
    'procedimentos.operationQuote': 'Presupuesto',
    'procedimentos.operationDelivery': 'Entrega',
    'procedimentos.momentBeforeStart': 'Antes de iniciar',
    'procedimentos.momentBeforeFinish': 'Antes de finalizar',
    'procedimentos.momentBeforeDelivery': 'Antes de la entrega',
    'procedimentos.stageSingular': 'etapa',
    'procedimentos.stagePlural': 'etapas',
    'procedimentos.itemSingular': 'ítem',
    'procedimentos.itemPlural': 'ítems',
    'procedimentos.stageProgress': 'Etapa {current} de {total}',
    'procedimentos.procedureSequence': 'Procedimiento {current} de {total}',
    'procedimentos.actionsCompleted.zero': '0 de {total} acciones concluidas',
    'procedimentos.actionsCompleted.one': '1 de {total} acción concluida',
    'procedimentos.actionsCompleted.other':
        '{count} de {total} acciones concluidas',
    'procedimentos.answeredActionsSummary.zero':
        '0 de {total} acciones respondidas.',
    'procedimentos.answeredActionsSummary.one':
        '1 de {total} acción respondida.',
    'procedimentos.answeredActionsSummary.other':
        '{count} de {total} acciones respondidas.',
    'procedimentos.optionalPendingSummary.zero':
        'Ningún ítem opcional pendiente.',
    'procedimentos.optionalPendingSummary.one': '1 ítem opcional pendiente.',
    'procedimentos.optionalPendingSummary.other':
        '{count} ítems opcionales pendientes.',
    'procedimentos.requiredPendingSummary.zero':
        'Ningún ítem obligatorio pendiente.',
    'procedimentos.requiredPendingSummary.one': '1 ítem obligatorio pendiente.',
    'procedimentos.requiredPendingSummary.other':
        '{count} ítems obligatorios pendientes.',
    'procedimentos.itemCount.zero': '0 ítems',
    'procedimentos.itemCount.one': '1 ítem',
    'procedimentos.itemCount.other': '{count} ítems',
    'procedimentos.stageCount.zero': '0 etapas',
    'procedimentos.stageCount.one': '1 etapa',
    'procedimentos.stageCount.other': '{count} etapas',
    'procedimentos.stageSemantics': 'Etapa {order}: {title}. {itemCountLabel}.',
    'procedimentos.executionItemSemantics': '{requiredLabel}: {title}. {type}.',
    'procedimentos.executionItemStatus': '{type} • {requiredLabel}',
    'procedimentos.responseTypeSemantics': '{label}. {description}.',
    'procedimentos.responseTypeSimulatedSemantics':
        '{label}. {description}. {demoLabel}.',
    'procedimentos.triggerSemantics':
        '{operation}, {moment}, {activation}, {enforcement}, {status}',
    'procedimentos.triggerSummarySingle': '{operation}, {moment}',
    'procedimentos.triggerSummaryMultiple': '{first} • +{remaining}',
    'procedimentos.optionNumber': 'Opción {index}',
    'procedimentos.editorNewTitle': 'Nuevo procedimiento',
    'procedimentos.editorEditTitle': 'Editar procedimiento',
    'procedimentos.generalInfo': 'Información general',
    'procedimentos.nameField': 'Nombre',
    'procedimentos.descriptionField': 'Descripción',
    'procedimentos.operationContext': 'Contexto operativo',
    'procedimentos.momentField': 'Momento',
    'procedimentos.requireCompletion':
        'Exigir conclusión de este procedimiento',
    'procedimentos.requireCompletionHelp':
        'En una integración futura, este procedimiento podrá exigir conclusión antes de continuar la operación.',
    'procedimentos.stages': 'Etapas',
    'procedimentos.addStage': 'Agregar etapa',
    'procedimentos.editStage': 'Editar etapa',
    'procedimentos.deleteStage': 'Eliminar etapa',
    'procedimentos.items': 'Ítems',
    'procedimentos.addItem': 'Agregar ítem',
    'procedimentos.editItem': 'Editar ítem',
    'procedimentos.deleteItem': 'Eliminar ítem',
    'procedimentos.itemType': 'Tipo de ítem',
    'procedimentos.stageTitleField': 'Título de la etapa',
    'procedimentos.itemTitleField': 'Título o instrucción',
    'procedimentos.itemGuidanceField': 'Texto de apoyo',
    'procedimentos.saveStage': 'Guardar etapa',
    'procedimentos.saveItem': 'Guardar ítem',
    'procedimentos.responseInstruction': 'Orientación',
    'procedimentos.responseConfirmation': 'Confirmación',
    'procedimentos.responseYesNo': 'Sí o no',
    'procedimentos.responseInstructionDescription':
        'Presenta una instrucción al colaborador.',
    'procedimentos.responseConfirmationDescription':
        'Exige que el colaborador confirme una acción.',
    'procedimentos.responseYesNoDescription': 'Presenta una pregunta objetiva.',
    'procedimentos.validationName': 'Ingresa el nombre del procedimiento.',
    'procedimentos.validationReviewFields':
        'Revisa los campos destacados antes de guardar.',
    'procedimentos.validationAtLeastOneStage':
        'Agrega al menos una etapa al procedimiento.',
    'procedimentos.validationStageTitle': 'Ingresa el título de la etapa.',
    'procedimentos.validationStageItem':
        'Cada etapa debe tener al menos un ítem.',
    'procedimentos.validationItemTitle': 'Ingresa el título del ítem.',
    'procedimentos.createdSuccess': 'Procedimiento creado.',
    'procedimentos.updatedSuccess': 'Procedimiento actualizado.',
    'procedimentos.discardChangesTitle': '¿Descartar cambios?',
    'procedimentos.discardChangesMessage':
        'Los cambios realizados en este procedimiento aún no se han guardado.',
    'procedimentos.keepEditing': 'Continuar editando',
    'procedimentos.discard': 'Descartar',
    'procedimentos.confirmDeleteStageTitle': '¿Eliminar etapa?',
    'procedimentos.confirmDeleteStageMessage':
        'Los ítems de esta etapa también serán removidos.',
    'procedimentos.confirmDeleteItemTitle': '¿Eliminar ítem?',
    'procedimentos.confirmDeleteItemMessage':
        'Este ítem será removido del procedimiento.',
    'procedimentos.editorDemoNotice':
        'Los cambios se mantendrán solo durante esta sesión.',
    'procedimentos.noStages': 'Ninguna etapa agregada',
    'procedimentos.itemRequiredHelp':
        'La lógica final de obligatoriedad se definirá en la integración operativa.',
    'procedimentos.previewAction': 'Previsualizar',
    'procedimentos.demonstration': 'Demostración',
    'procedimentos.responsePhoto': 'Tomar foto',
    'procedimentos.responseSignature': 'Firma',
    'procedimentos.responseLocation': 'Capturar ubicación',
    'procedimentos.responseBarcode': 'Leer código de barras',
    'procedimentos.responseImei': 'Informar IMEI',
    'procedimentos.responseDocument': 'Adjuntar documento',
    'procedimentos.responseAudio': 'Grabar audio',
    'procedimentos.responseFreeText': 'Texto libre',
    'procedimentos.responseNumber': 'Número',
    'procedimentos.responseDate': 'Fecha',
    'procedimentos.responseSingleChoice': 'Elección única',
    'procedimentos.responseMultipleChoice': 'Elección múltiple',
    'procedimentos.responsePhotoDescription':
        'Simula la captura de una foto como evidencia.',
    'procedimentos.responseSignatureDescription':
        'Simula la recolección de una firma.',
    'procedimentos.responseLocationDescription':
        'Simula la captura de una ubicación.',
    'procedimentos.responseBarcodeDescription':
        'Simula la lectura de un código de barras.',
    'procedimentos.responseImeiDescription':
        'Permite informar un IMEI manualmente.',
    'procedimentos.responseDocumentDescription':
        'Simula adjuntar un documento.',
    'procedimentos.responseAudioDescription': 'Simula una grabación de audio.',
    'procedimentos.responseFreeTextDescription':
        'Permite registrar una respuesta en texto.',
    'procedimentos.responseNumberDescription':
        'Permite registrar un valor numérico.',
    'procedimentos.responseDateDescription': 'Permite seleccionar una fecha.',
    'procedimentos.responseSingleChoiceDescription':
        'Permite seleccionar una opción.',
    'procedimentos.responseMultipleChoiceDescription':
        'Permite seleccionar una o más opciones.',
    'procedimentos.typeCategoryGuide': 'Orientar y confirmar',
    'procedimentos.typeCategoryCollect': 'Recolectar información',
    'procedimentos.typeCategoryEvidence': 'Registrar evidencia',
    'procedimentos.typeCategoryIdentify': 'Identificar',
    'procedimentos.itemTypePickerHelp':
        'Elige cómo el colaborador responderá o registrará esta acción.',
    'procedimentos.placeholderField': 'Placeholder',
    'procedimentos.unitField': 'Unidad',
    'procedimentos.choiceOptions': 'Opciones de elección',
    'procedimentos.addOption': 'Agregar opción',
    'procedimentos.removeOption': 'Eliminar opción',
    'procedimentos.optionField': 'Opción',
    'procedimentos.validationChoiceOptions': 'Ingresa al menos dos opciones.',
    'procedimentos.changeTypeTitle': '¿Cambiar tipo de ítem?',
    'procedimentos.changeTypeMessage':
        'Las opciones configuradas serán removidas para este tipo.',
    'procedimentos.simulatedTypeEditorHelp':
        'En modo demostración, esta captura será simulada sin usar recursos del dispositivo.',
    'procedimentos.previewTitle': 'Previsualización',
    'procedimentos.previewUntitledProcedure': 'Procedimiento sin nombre',
    'procedimentos.previewIncompleteProcedure':
        'Este procedimiento aún no tiene etapas para demostrar.',
    'procedimentos.previewOf': 'de',
    'procedimentos.previewProgressLabel': 'Acciones concluidas',
    'procedimentos.previewPendingMessage':
        'Hay acciones obligatorias pendientes en esta etapa.',
    'procedimentos.previewRequiredPending':
        'Responde esta acción obligatoria para continuar.',
    'procedimentos.previewNextStage': 'Siguiente etapa',
    'procedimentos.previewFinishDemo': 'Finalizar',
    'procedimentos.previewReviewStages': 'Revisar etapas',
    'procedimentos.previewSummaryTitle': 'Demostración concluida',
    'procedimentos.previewSummarySavedMessage':
        'Ninguna respuesta fue guardada.',
    'procedimentos.previewSummaryAnswered': 'Acciones respondidas.',
    'procedimentos.previewSummaryNoOptionalPending':
        'Ningún ítem opcional pendiente.',
    'procedimentos.previewSummaryOptionalPending': 'Ítem opcional pendiente.',
    'procedimentos.previewDiscardTitle': '¿Descartar respuestas?',
    'procedimentos.previewDiscardMessage':
        'Las respuestas de esta demostración serán descartadas al salir.',
    'procedimentos.previewConfirmAction': 'Confirmar acción',
    'procedimentos.previewUnderstood': 'Marcar como entendido',
    'procedimentos.previewUnderstoodDone': 'Entendido',
    'procedimentos.previewTextHint': 'Ingresa la respuesta',
    'procedimentos.previewNumberHint': 'Ingresa un número',
    'procedimentos.previewSelectDate': 'Seleccionar fecha',
    'procedimentos.previewImeiHint': 'Ingresa el IMEI',
    'procedimentos.previewUseDemoImei': 'Usar IMEI demostrativo',
    'procedimentos.previewTakePhoto': 'Tomar foto',
    'procedimentos.previewSimulateSignature': 'Simular firma',
    'procedimentos.previewCaptureLocation': 'Capturar ubicación',
    'procedimentos.previewSimulateBarcode': 'Simular lectura',
    'procedimentos.previewSimulateDocument': 'Simular anexo',
    'procedimentos.previewSimulateAudio': 'Simular grabación',
    'procedimentos.previewRemoveEvidence': 'Remover evidencia',
    'procedimentos.simulatedResourceNotice':
        'Recurso demostrativo. Ningún dato real será capturado.',
    'procedimentos.previewPhotoAdded': 'Foto agregada',
    'procedimentos.previewSignatureAdded': 'Firma agregada',
    'procedimentos.previewSignatureDemoDetail': 'Trazo demostrativo registrado',
    'procedimentos.previewLocationAdded': 'Ubicación de demostración capturada',
    'procedimentos.previewBarcodeAdded': 'Código leído',
    'procedimentos.previewDocumentAdded': 'Documento adjuntado',
    'procedimentos.previewAudioAdded': 'Audio grabado',
    'procedimentos.operationCashRegister': 'Caja',
    'procedimentos.operationCustomerRegistration': 'Registro de cliente',
    'procedimentos.triggerMomentBeforeStart': 'Antes de iniciar',
    'procedimentos.triggerMomentAfterStart': 'Después de iniciar',
    'procedimentos.triggerMomentBeforeFinish': 'Antes de concluir',
    'procedimentos.triggerMomentAfterFinish': 'Después de concluir',
    'procedimentos.triggerMomentBeforeDelivery': 'Antes de la entrega',
    'procedimentos.triggerMomentAfterDelivery': 'Después de la entrega',
    'procedimentos.triggerMomentOnDemand': 'Bajo demanda',
    'procedimentos.activationManual': 'Manual',
    'procedimentos.activationAutomatic': 'Automático',
    'procedimentos.activationManualDescription':
        'El colaborador podrá iniciar este procedimiento cuando sea necesario.',
    'procedimentos.activationAutomaticDescription':
        'En una integración futura, el procedimiento será presentado en el momento configurado.',
    'procedimentos.enforcementInformative': 'Informativo',
    'procedimentos.enforcementRecommended': 'Recomendado',
    'procedimentos.enforcementRequired': 'Obligatorio',
    'procedimentos.enforcementInformativeDescription':
        'Presenta el procedimiento sin exigir conclusión.',
    'procedimentos.enforcementRecommendedDescription':
        'Recomienda la conclusión, pero no debe bloquear la operación.',
    'procedimentos.enforcementRequiredDescription':
        'En una integración futura, exigirá conclusión antes de continuar.',
    'procedimentos.whenExecute': 'Cuándo ejecutar',
    'procedimentos.addTrigger': 'Agregar gatillo',
    'procedimentos.editTrigger': 'Editar gatillo',
    'procedimentos.deleteTrigger': 'Eliminar gatillo',
    'procedimentos.noTriggers': 'Ningún gatillo configurado.',
    'procedimentos.noTriggersDescription':
        'Sin gatillos, el procedimiento estará disponible solo para uso y previsualización dentro de este módulo.',
    'procedimentos.triggerCount': 'gatillos',
    'procedimentos.selectOperationContext': 'Seleccionar contexto',
    'procedimentos.selectTriggerMoment': 'Seleccionar momento',
    'procedimentos.activationMode': 'Modo de ejecución',
    'procedimentos.enforcementMode': 'Nivel de exigencia',
    'procedimentos.triggerEnabledHelp':
        'Controla si este gatillo será considerado en una integración futura.',
    'procedimentos.saveTrigger': 'Guardar gatillo',
    'procedimentos.triggerMomentCleared':
        'El momento fue limpiado porque no es compatible con el contexto seleccionado.',
    'procedimentos.validationTriggerOperation': 'Elige el contexto operativo.',
    'procedimentos.validationTriggerMoment': 'Elige el momento de ejecución.',
    'procedimentos.validationTriggerMomentInvalid':
        'Elige un momento compatible con el contexto.',
    'procedimentos.validationDuplicateTrigger':
        'Ya existe un gatillo con este contexto, momento y modo de ejecución.',
    'procedimentos.deleteTriggerTitle': '¿Eliminar gatillo?',
    'procedimentos.deleteTriggerMessage':
        'El procedimiento dejará de mostrarse en este momento operativo.',
    'procedimentos.triggerSummaryNone': 'Sin gatillos configurados',
    'procedimentos.triggerSummaryOnlyInactive': 'Gatillos inactivos',
    'procedimentos.executionConfiguration': 'Configuración de ejecución',
    'procedimentos.triggerSimulationNotice':
        'Simulación de gatillo. Ninguna operación real será bloqueada.',
    'procedimentos.manualDemoExecution': 'Ejecución manual de demostración.',
    'procedimentos.operationPointSaleStartBefore': 'Antes de iniciar una venta',
    'procedimentos.operationPointSaleStartBeforeDescription':
        'Se ejecuta antes de abrir el flujo de una nueva venta.',
    'procedimentos.mobilePointAvailable': 'Disponible en la aplicación móvil.',
    'procedimentos.operationalExecutionTitle': 'Antes de iniciar la venta',
    'procedimentos.operationalSummaryTitle': 'Procedimiento concluido',
    'procedimentos.operationalNoDataSaved':
        'Ninguna respuesta fue guardada en esta integración local experimental.',
    'procedimentos.completeAndStartSale': 'Concluir e iniciar venta',
    'procedimentos.experimentalIntegration': 'Integración experimental',
    'procedimentos.continueToStartSale': 'Continuar a la venta',
    'procedimentos.continueWithoutCompleting': 'Continuar sin concluir',
    'procedimentos.continueWithoutCompletingTitle': '¿Continuar sin concluir?',
    'procedimentos.continueWithoutCompletingMessage':
        'Este procedimiento es recomendado antes de iniciar la venta.',
    'procedimentos.continueAnyway': 'Continuar de todos modos',
    'procedimentos.returnToProcedure': 'Volver al procedimiento',
    'procedimentos.cancelSaleStartTitle': '¿Cancelar inicio de venta?',
    'procedimentos.cancelSaleStartMessage':
        'Este procedimiento es obligatorio. Al salir, la nueva venta no será iniciada.',
    'procedimentos.cancelSale': 'Cancelar venta',
    'procedimentos.sequenceProgressPrefix': 'Procedimiento',
    'procedimentos.previewNegativeTextLabel': '¿Qué faltó?',
    'procedimentos.previewNegativeTextHint': 'Describe qué faltó',
    'procedimentos.operationalLoadError':
        'No fue posible cargar los procedimientos.',
    'procedimentos.operationalBadge': 'Procedimiento operativo',
    'procedimentos.operationalExecutionTitleReal': 'Procedimiento operativo',
    'procedimentos.executionWillBeSaved':
        'Las respuestas y los horarios se guardarán al finalizar.',
    'procedimentos.completeAndContinue': 'Concluir y continuar',
    'procedimentos.continueOperation': 'Continuar operación',
    'procedimentos.processingSkip': 'Continuando...',
    'procedimentos.processingCancel': 'Cancelando...',
    'procedimentos.executionSaveError':
        'No fue posible guardar las respuestas. Inténtalo de nuevo.',
    'procedimentos.skipSuccessTitle': 'Procedimiento omitido',
    'procedimentos.cancelSuccessTitle': 'Operación cancelada',
    'procedimentos.completeSuccessMessage':
        'Las respuestas fueron guardadas y la operación puede continuar.',
    'procedimentos.skipSuccessMessage':
        'El procedimiento fue omitido y la operación continuará según la configuración actual.',
    'procedimentos.cancelSuccessMessage':
        'La operación se cerró antes de avanzar al siguiente paso.',
    'procedimentos.persistedConfiguration': 'Configuración sincronizada',
    'procedimentos.editorPersistenceNotice':
        'Los cambios se guardan para la empresa en el idioma actual.',
    'procedimentos.notifyAdmin': 'Notificar al ADMIN por push',
    'procedimentos.notifyAdminHelp':
        'Notifica a los administradores activos cuando ocurre la condición.',
    'procedimentos.notificationCondition': 'Cuándo notificar',
    'procedimentos.notificationAlways': 'En cada ejecución',
    'procedimentos.notificationNegative': 'Al registrar una respuesta negativa',
    'procedimentos.notificationSkipped': 'Al omitir el procedimiento',
    'procedimentos.analyticsTitle': 'Análisis de resultados',
    'procedimentos.analyticsExecutions': 'Ejecuciones',
    'procedimentos.analyticsCompletion': 'Tasa de conclusión',
    'procedimentos.analyticsNegative': 'Respuestas negativas',
    'procedimentos.analyticsAverageTime': 'Tiempo medio',
    'procedimentos.analyticsByQuestion': 'Resultados por pregunta',
    'procedimentos.analyticsRecent': 'Ejecuciones recientes',
    'procedimentos.analyticsEmpty': 'Aún no hay ejecuciones en este período.',
    'procedimentos.contextSale': 'Venta',
    'procedimentos.contextTechnicalService': 'Atención técnica',
    'procedimentos.contextCashRegister': 'Caja',

    // Gestión — secciones
    'gestao.title': 'Gestión',
    'gestao.hub.title': '¿Qué quieres gestionar?',
    'gestao.hub.subtitle':
        'Accede a catálogos, personas, finanzas y preferencias.',
    'gestao.hub.terminal.products': 'Gestiona tus productos y colaboradores',
    'gestao.hub.terminal.finance': 'Gestiona tus finanzas',
    'gestao.hub.terminal.preferences':
        'Ajusta tus preferencias y configuraciones',
    'gestao.catalog.title': 'Catálogo',
    'gestao.catalog.subtitle': 'Productos, categorías e inventario',
    'gestao.people.title': 'Personas',
    'gestao.people.subtitle': 'Clientes, equipo y socios',
    'gestao.finance.title': 'Financiero',
    'gestao.finance.subtitle': 'Cuentas, agenda y recibos',
    'gestao.settings.title': 'Configuración',
    'gestao.settings.selectorTitle': 'General',
    'gestao.settings.subtitle': 'Empresa, idioma e integraciones',

    // Gestión — ítems de Catálogo
    'gestao.catalog.productsServices': 'Productos y Servicios',
    'gestao.catalog.productsServicesDesc':
        'Salud, registros y revisión del catálogo',
    'gestao.catalog.categories': 'Categorías',
    'gestao.catalog.categoriesDesc': 'Organización del catálogo',
    'gestao.catalog.inventory': 'Inventario',
    'gestao.catalog.inventoryDesc': 'Saldos, entradas y ajustes',

    // Gestión — ítems de Personas
    'gestao.people.clients': 'Clientes',
    'gestao.people.clientsDesc': 'Base de atención y relación',
    'gestao.people.collaborators': 'Colaboradores',
    'gestao.people.collaboratorsDesc': 'Equipo, accesos y responsabilidades',
    'gestao.people.sixoUsers': 'Usuarios de Sixo',
    'gestao.people.sixoUsersDesc':
        'Base global protegida por el perfil SUPER',
    'gestao.people.suppliers': 'Proveedores',
    'gestao.people.suppliersDesc': 'Socios y compras del comercio',

    // Gestión — ítems de Financiero
    'gestao.finance.receivable': 'Cuentas por cobrar',
    'gestao.finance.receivableDesc': 'Cobros y facturas pendientes',
    'gestao.finance.payable': 'Cuentas por pagar',
    'gestao.finance.payableDesc': 'Gastos y compromisos',
    'gestao.finance.schedule': 'Agenda financiera',
    'gestao.finance.scheduleDesc': 'Previsiones, fiado y créditos',
    'gestao.finance.paymentMethods': 'Formas de cobro',
    'gestao.finance.paymentMethodsDesc':
        'Efectivo, tarjeta, Pix y otros medios',

    // Gestión — grupos de Configuración
    'gestao.settings.group.company': 'Empresa',
    'gestao.settings.group.teamAccess': 'Equipo y acceso',
    'gestao.settings.group.operation': 'Operación',
    'gestao.settings.group.communication': 'Comunicación',
    'gestao.settings.group.docsIntegrations': 'Documentos e integraciones',

    // Gestión — ítems de Configuración
    'gestao.settings.item.company.title': 'Empresa',
    'gestao.settings.item.company.subtitle':
        'Datos de registro e identidad del comercio',
    'gestao.settings.item.regionalization.title': 'Regionalización',
    'gestao.settings.item.regionalization.subtitle':
        'Idioma, moneda, país y formatos locales',
    'gestao.settings.item.users.title': 'Usuarios y permisos',
    'gestao.settings.item.users.subtitle':
        'Accesos, perfiles y seguridad del equipo',
    'gestao.settings.item.procedures.title': 'Procedimientos',
    'gestao.settings.item.procedures.subtitle':
        'Guías para ventas, servicios y entregas',
    'gestao.settings.item.notifications.title': 'Notificaciones',
    'gestao.settings.item.notifications.subtitle':
        'Eventos recibidos y alertas del sistema',
    'gestao.settings.item.pdfTemplates.title': 'Plantillas PDF',
    'gestao.settings.item.pdfTemplates.subtitle':
        'Presupuestos, OS, recibos y documentos',
    'gestao.settings.item.integrations.title': 'Integraciones',
    'gestao.settings.item.integrations.subtitle':
        'Servicios externos y automatizaciones',

    // Gestión — visión contextual móvil
    'gestao.overview.selectedArea': 'Área seleccionada',
    'gestao.overview.generalTitle': 'Vista general',
    'gestao.overview.valueUnavailable': '--',
    'gestao.overview.mainActions': 'Acciones principales',
    'gestao.overview.errorMessage':
        'Las acciones siguen disponibles. Intenta actualizar los datos en unos instantes.',
    'gestao.catalog.summaryTitle': 'Resumen del catálogo',
    'gestao.catalog.metric.products': 'Productos',
    'gestao.catalog.metric.productsServices': 'Productos y servicios',
    'gestao.catalog.metric.categories': 'Categorías',
    'gestao.catalog.metric.lowStock': 'Stock bajo',
    'gestao.catalog.lowStockAlertSemantic':
        'Indicador de atención para stock bajo',
    'gestao.catalog.loadError':
        'No fue posible cargar el resumen del catálogo.',
    'gestao.catalog.emptyTitle': 'Catálogo sin datos para mostrar',
    'gestao.catalog.emptyMessage':
        'Registra productos, servicios o categorías para completar los indicadores.',
    'gestao.catalog.permissionRestrictedTitle':
        'Catálogo restringido para este usuario',
    'gestao.catalog.permissionRestrictedMessage':
        'La acción de Productos y Servicios respeta los permisos actuales.',
    'gestao.catalog.lowStockTitle': 'El inventario necesita atención',
    'gestao.catalog.lowStockMessage':
        '{count} elemento(s) por debajo del límite configurado en el catálogo.',
    'gestao.catalog.lowStockAction': 'Ver elementos',
    'gestao.people.summaryTitle': 'Resumen de personas',
    'gestao.people.metric.clients': 'Clientes',
    'gestao.people.metric.collaborators': 'Colaboradores',
    'gestao.people.metric.suppliers': 'Proveedores',
    'gestao.people.suppliersUnavailableSemantic': 'Recurso próximamente',
    'gestao.people.loadError': 'No fue posible cargar el resumen de personas.',
    'gestao.people.emptyTitle': 'Ningún contacto cargado',
    'gestao.people.emptyMessage':
        'Clientes y colaboradores aparecerán aquí cuando estén registrados.',
    'gestao.people.suppliersBlockedTitle': 'Proveedores aún no está disponible',
    'gestao.people.suppliersBlockedMessage':
        'El recurso sigue marcado como Próximamente y no tiene navegación móvil activa.',
    'gestao.finance.actionGroup': 'Agenda y recursos',
    'gestao.finance.summaryTitle': 'Resumen financiero',
    'gestao.finance.metric.events': 'Próximos eventos',
    'gestao.finance.metric.receivableEvents': 'Por cobrar',
    'gestao.finance.metric.payableEvents': 'Por pagar',
    'gestao.finance.loadError': 'No fue posible cargar la agenda financiera.',
    'gestao.finance.emptyTitle': 'Agenda sin lanzamientos próximos',
    'gestao.finance.emptyMessage':
        'Abre la agenda financiera para crear previsiones y seguir vencimientos.',
    'gestao.finance.openSchedule': 'Abrir agenda',
    'gestao.finance.attentionTitle': 'Agenda con vencimientos próximos',
    'gestao.finance.attentionMessage':
        '{count} evento(s) vencido(s) o con vencimiento hoy en la agenda.',
    'gestao.finance.blockedResourcesTitle': 'Recursos financieros en evolución',
    'gestao.finance.blockedResourcesMessage':
        'Cuentas por cobrar, cuentas por pagar y formas de cobro continúan bloqueadas en mobile.',

    // Atención mobile
    'atendimento.mobile.title': 'Atención',
    'atendimento.mobile.heroTitle': '¿Qué deseas hacer?',
    'atendimento.mobile.heroSubtitle': 'Venta, servicio o cobro en pocos pasos',
    'atendimento.mobile.introTitle': 'Atención al Cliente',
    'atendimento.mobile.introLineSales': 'vender, cobrar, consultar',
    'atendimento.mobile.introLineReturns': 'devoluciones de productos',
    'atendimento.mobile.introLineServices': 'servicios, presupuestos, etc.',
    'atendimento.mobile.chooseOperation': 'Elige la operación para iniciar.',
    'atendimento.mobile.salesMenuTitle': 'Ventas',
    'atendimento.mobile.newSaleTitle': 'Ventas',
    'atendimento.mobile.newSaleSubtitle': 'Opciones',
    'atendimento.mobile.consultSalesTitle': 'Consultar ventas',
    'atendimento.mobile.consultSalesSubtitle': 'Consultar historial de ventas',
    'atendimento.mobile.newServiceTitle': 'Servicios',
    'atendimento.mobile.newServiceSubtitle': 'Crear o acompañar',
    'atendimento.mobile.servicesMenuTitle': 'Servicios',
    'atendimento.mobile.createServiceTitle': 'Nuevo servicio',
    'atendimento.mobile.createServiceSubtitle': 'Abrir nueva atención técnica',
    'atendimento.mobile.consultServicesInProgressTitle':
        'Consultar servicios en curso',
    'atendimento.mobile.consultServicesInProgressSubtitle':
        'Ver atenciones técnicas activas',
    'atendimento.mobile.receiveTitle': 'Cobrar',
    'atendimento.mobile.receiveSubtitle': 'Ventas abiertas',
    'atendimento.mobile.followToday': 'Seguimiento de hoy',
    'atendimento.mobile.salesToReceiveTitle': 'Ventas por cobrar',
    'atendimento.mobile.salesToReceiveSubtitle': 'Ventas no liquidadas',
    'atendimento.mobile.servicesInProgressTitle': 'Servicios en curso',
    'atendimento.mobile.servicesInProgressSubtitle':
        'Atenciones técnicas activas',
    'atendimento.mobile.moreOptions': 'Más opciones',
    'atendimento.mobile.cashOperationsTitle': 'Caja',
    'atendimento.mobile.cashOperationsSubtitle': 'Abrir y mover',
    'atendimento.mobile.counterLoadError': 'No fue posible actualizar ahora',
    'atendimento.mobile.servicesToReceiveTitle': 'Servicios por cobrar',
    'atendimento.mobile.servicesToReceiveSubtitle':
        'Atenciones técnicas con financiero abierto',
    'atendimento.mobile.technicalServicesPendingPaymentTitle':
        'Atenciones técnicas pendientes de pago',
    'atendimento.mobile.pendingPaymentsLoadingTitle': 'Cargando atenciones',
    'atendimento.mobile.pendingPaymentsLoadingSubtitle':
        'Buscando servicios con financiero abierto.',
    'atendimento.mobile.pendingPaymentHeaderTitle': 'Financiero abierto',
    'atendimento.mobile.pendingPaymentTotalOpen': 'Total abierto',
    'atendimento.mobile.pendingPaymentSection': 'Atenciones con saldo',
    'atendimento.mobile.pendingPaymentErrorTitle': 'No fue posible cargar',
    'atendimento.mobile.pendingPaymentErrorMessage':
        'Intenta actualizar las atenciones técnicas en instantes.',
    'atendimento.mobile.pendingPaymentEmptyTitle': 'Ningún servicio por cobrar',
    'atendimento.mobile.pendingPaymentEmptyMessage':
        'Las atenciones técnicas no tienen financiero abierto.',
    'atendimento.mobile.onePendingPaymentService':
        '1 atención con financiero abierto',
    'atendimento.mobile.pendingPaymentServices':
        'atenciones con financiero abierto',
    'atendimento.mobile.serviceNumber': 'Atención',
    'atendimento.mobile.openValue': 'Valor abierto',
    'atendimento.mobile.totalValue': 'Valor total',
    'atendimento.mobile.dueDate': 'Vence el',
    'atendimento.mobile.noDueDate': 'Sin vencimiento',
    'operacao.mobile.returnTitle': 'Devoluciones y Cambios',
    'operacao.mobile.returnSubtitle': 'Registrar devolución',
    'operacao.mobile.returnUnavailable': 'Próximamente',

    // Devoluciones mobile
    'devolucao.mobile.title': 'Devoluciones',
    'devolucao.mobile.introTitle': 'Localiza la venta',
    'devolucao.mobile.introSubtitle':
        'Usa el código del comprobante para iniciar una devolución o cambio.',
    'devolucao.mobile.saleCodeLabel': 'Código o ID de la venta',
    'devolucao.mobile.saleCodeHint': 'Ej.: VEN-1024',
    'devolucao.mobile.searchSale': 'Buscar venta',
    'devolucao.mobile.searching': 'Buscando...',
    'devolucao.mobile.operationCompleted': 'Operación concluida',
    'devolucao.mobile.saleFound': 'Venta encontrada',
    'devolucao.mobile.changeSale': 'Cambiar venta',
    'devolucao.mobile.unidentifiedCustomer': 'Cliente no identificado',
    'devolucao.mobile.productsValue': 'Valor de los productos',
    'devolucao.mobile.returnBalance': 'Saldo devolvible',
    'devolucao.mobile.hasEligibleItems': 'Hay artículos disponibles',
    'devolucao.mobile.noEligibleBalance': 'Sin artículos disponibles',
    'devolucao.mobile.operationTypeTitle': '¿Qué se hará?',
    'devolucao.mobile.operationTypeSubtitle':
        'Elige entre devolver o cambiar productos.',
    'devolucao.mobile.returnOnly': 'Solo devolución',
    'devolucao.mobile.exchange': 'Cambio',
    'devolucao.mobile.itemsTitle': 'Productos que regresan',
    'devolucao.mobile.itemsSubtitle':
        'Selecciona los artículos e informa cantidad, condición y motivo.',
    'devolucao.mobile.noItems':
        'Esta venta no tiene artículos disponibles para devolución.',
    'devolucao.mobile.soldValue': 'Vendido: {value}',
    'devolucao.mobile.availableValue': 'Disponible: {value}',
    'devolucao.mobile.quantity': 'Cantidad',
    'devolucao.mobile.maximumQuantity': 'Máximo: {value}',
    'devolucao.mobile.condition': 'Condición del producto',
    'devolucao.mobile.reason': 'Motivo de la devolución',
    'devolucao.mobile.stockReturn': 'Regresar al inventario',
    'devolucao.mobile.stockReturnOn':
        'El saldo disponible del producto será repuesto.',
    'devolucao.mobile.stockReturnOff':
        'La devolución se registrará sin reponer el inventario.',
    'devolucao.mobile.exchangeItemsTitle': 'Productos del cambio',
    'devolucao.mobile.exchangeItemsSubtitle':
        'Los nuevos productos saldrán del inventario al precio actual.',
    'devolucao.mobile.addProduct': 'Agregar producto',
    'devolucao.mobile.exchangeEmpty':
        'Agrega el producto que recibirá el cliente.',
    'devolucao.mobile.selectExchangeProduct': 'Elegir producto del cambio',
    'devolucao.mobile.searchProduct': 'Buscar producto',
    'devolucao.mobile.noProductsTitle': 'No se encontraron productos',
    'devolucao.mobile.noProductsMessage':
        'Revisa la búsqueda o el catálogo de productos activos.',
    'devolucao.mobile.productPrice': 'Precio actual: {value}',
    'devolucao.mobile.perUnit': '{value} por unidad',
    'devolucao.mobile.remove': 'Quitar producto',
    'devolucao.mobile.financialTitle': 'Ajuste financiero',
    'devolucao.mobile.returnedProducts': 'Productos devueltos',
    'devolucao.mobile.exchangeProducts': 'Productos del cambio',
    'devolucao.mobile.differenceReceive': 'Diferencia por cobrar',
    'devolucao.mobile.refundValue': 'Valor a reembolsar',
    'devolucao.mobile.customerPays': 'El cliente paga la diferencia.',
    'devolucao.mobile.companyRefunds': 'La empresa reembolsa al cliente.',
    'devolucao.mobile.noFinancialMovement': 'No habrá movimiento financiero.',
    'devolucao.mobile.paymentMethod': 'Forma de pago o reembolso',
    'devolucao.mobile.paymentHelper': 'Requiere una sesión de caja abierta.',
    'devolucao.mobile.selectPayment': 'Seleccionar forma',
    'devolucao.mobile.searchPayment': 'Buscar forma',
    'devolucao.mobile.noPaymentMethods': 'No hay formas disponibles',
    'devolucao.mobile.noPaymentMethodsMessage':
        'Configura una forma de cobro inmediato antes de concluir.',
    'devolucao.mobile.reviewTitle': 'Revisar y concluir',
    'devolucao.mobile.reviewSubtitle':
        'Confirma los datos antes de mover inventario y caja.',
    'devolucao.mobile.notes': 'Observaciones internas (opcional)',
    'devolucao.mobile.processing': 'Procesando...',
    'devolucao.mobile.completeExchange': 'Concluir cambio',
    'devolucao.mobile.completeReturn': 'Concluir devolución',
    'devolucao.mobile.confirmationHelper':
        'La confirmación puede mover inventario y registrar el ajuste en caja.',
    'devolucao.mobile.recentTitle': 'Operaciones recientes',
    'devolucao.mobile.recentSubtitle':
        'Últimas devoluciones y cambios de esta empresa.',
    'devolucao.mobile.loadingRecent': 'Cargando operaciones recientes',
    'devolucao.mobile.emptyRecent':
        'No se concluyeron devoluciones o cambios recientemente.',
    'devolucao.mobile.successMessage': 'Operación {code} concluida con éxito.',
    'devolucao.mobile.unexpectedError':
        'No fue posible concluir la operación. Inténtalo de nuevo.',
    'devolucao.mobile.validation.saleRequired':
        'Informa el código o identificador de la venta.',
    'devolucao.mobile.validation.invalidQuantity':
        'Informa una cantidad válida para {product}.',
    'devolucao.mobile.validation.quantityExceeded':
        'La cantidad de {product} supera el saldo devolvible.',
    'devolucao.mobile.validation.reasonRequired':
        'Informa el motivo de devolución de {product}.',
    'devolucao.mobile.validation.selectReturnItem':
        'Selecciona al menos un producto para devolver.',
    'devolucao.mobile.validation.selectExchangeItem':
        'Agrega al menos un producto para el cambio.',
    'devolucao.mobile.validation.selectPayment':
        'Selecciona la forma usada para ajustar la diferencia.',
    'devolucao.mobile.condition.sealed': 'Nuevo / sellado',
    'devolucao.mobile.condition.opened': 'Abierto',
    'devolucao.mobile.condition.used': 'Usado',
    'devolucao.mobile.condition.defective': 'Con defecto',
    'devolucao.mobile.condition.damaged': 'Averiado',
    'devolucao.mobile.condition.other': 'Otra condición',

    // Ventas no liquidadas mobile
    'vendasNaoLiquidadas.recebimentos': 'Cobros',
    'vendasNaoLiquidadas.semRecebimentos': 'Ningún cobro registrado.',
    'vendasNaoLiquidadas.referencia': 'Referencia',
    'vendasNaoLiquidadas.recebimento': 'Cobro',
    'vendasNaoLiquidadas.recebimentoTotal': 'Total',
    'vendasNaoLiquidadas.recebimentoParcial': 'Parcial',

    // Gestión — badges y encabezado admin
    'gestao.settings.badge.experimental': 'Experimental',
    'gestao.settings.badge.comingSoon': 'Próximamente',
    'gestao.settings.adminHeader.title': 'Configuración de la empresa',
    'gestao.settings.adminHeader.subtitle':
        'Organiza empresa, equipo, operación y comunicación.',
    'gestao.catalog.webCatalog': 'Catálogo web',
    'gestao.catalog.webCatalogDesc':
        'Experiencia completa del catálogo en el navegador',
    'gestao.catalog.webCatalogBadge': 'WEB',
    'gestao.featureInProgress': 'Flujo móvil en evolución.',
    'produto.webList.selection.titleMany': 'Seleccionar ítems',
    'produto.webList.selection.titleOne': 'Seleccionar ítem',
    'produto.webList.selection.subtitleMany':
        'Marca productos y servicios y agrega todo a la venta de una sola vez.',
    'produto.webList.selection.subtitleOne':
        'Búsqueda rápida para incluir un producto o servicio en la venta.',
    'produto.webList.edit.title': 'Editar productos',
    'produto.webList.edit.subtitle':
        'Gestiona tu catálogo de productos, stock, precios e imágenes.',
    'produto.webList.default.subtitle':
        'Consulta rápida del catálogo con acciones de mostrador.',
    'produto.webList.newItem': 'Nuevo ítem',
    'produto.webList.printPdf': 'Imprimir PDF',
    'produto.webList.publicCatalogLink': 'Enlace del catálogo',
    'produto.webList.publicCatalogPreparing': 'Preparando...',
    'produto.webList.publicCatalogCopied':
        'Enlace público del catálogo copiado.',
    'produto.webList.publicCatalogError':
        'No fue posible preparar el enlace del catálogo.',
    'catalogReservations.title': 'Reservas del catálogo',
    'catalogReservations.subtitle':
        'Acompaña las solicitudes recibidas por el catálogo virtual.',
    'catalogReservations.loadingTitle': 'Cargando reservas',
    'catalogReservations.loadingSubtitle':
        'Sincronizando las solicitudes de este comercio.',
    'catalogReservations.detailLoading': 'Cargando detalles',
    'catalogReservations.detailLoadingSubtitle':
        'Buscando los productos y datos del cliente.',
    'catalogReservations.detailTitle': 'Detalles de la reserva',
    'catalogReservations.empty': 'No se encontraron reservas.',
    'catalogReservations.error': 'No fue posible cargar las reservas.',
    'catalogReservations.status': 'Estado',
    'catalogReservations.filters.apply': 'Aplicar',
    'catalogReservations.filters.clear': 'Limpiar filtros',
    'catalogReservations.filters.status.selectedCount': '{count} seleccionados',
    'catalogReservations.filters.period': 'Período',
    'catalogReservations.filters.start': 'Inicio',
    'catalogReservations.filters.end': 'Fin',
    'catalogReservations.filters.date': 'Fecha',
    'catalogReservations.filters.date.all': 'Todas las fechas',
    'catalogReservations.filters.date.today': 'Hoy',
    'catalogReservations.filters.date.yesterday': 'Ayer',
    'catalogReservations.filters.date.last7Days': 'Ultimos 7 dias',
    'catalogReservations.filters.date.next7Days': 'Proximos 7 dias',
    'catalogReservations.filters.date.thisMonth': 'Este mes',
    'catalogReservations.filters.date.nextMonth': 'Próximo mes',
    'catalogReservations.filters.date.customRange': 'Intervalo personalizado',
    'catalogReservations.filters.date.pick': 'Elegir fecha',
    'catalogReservations.filters.date.pickRange': 'De dia a tal dia',
    'catalogReservations.filters.date.helpText': 'Seleccionar fecha',
    'catalogReservations.filters.date.startHelpText':
        'Seleccionar fecha inicial',
    'catalogReservations.filters.date.endHelpText': 'Seleccionar fecha final',
    'catalogReservations.filters.date.rangeHelpText': 'Seleccionar periodo',
    'catalogReservations.status.received': 'Recibida',
    'catalogReservations.status.analysis': 'En análisis',
    'catalogReservations.status.confirmed': 'Confirmada',
    'catalogReservations.status.cancelled': 'Cancelada',
    'catalogReservations.status.converted': 'Convertida en venta',
    'catalogReservations.convert.title': 'Convertir en venta',
    'catalogReservations.convert.description':
        'Valida el stock y crea una venta por cobrar con estos productos.',
    'catalogReservations.convert.action': 'Convertir en venta',
    'catalogReservations.convert.processing': 'Convirtiendo...',
    'catalogReservations.convert.confirmTitle':
        '¿Convertir la reserva en venta?',
    'catalogReservations.convert.confirmMessage':
        'Se validará el stock y los ítems se enviarán a una venta por cobrar.',
    'catalogReservations.convert.success':
        'Reserva convertida en una venta por cobrar.',
    'catalogReservations.convert.convertedTitle': 'Venta creada',
    'catalogReservations.convert.saleId': 'Venta',
    'catalogReservations.convert.error.stock':
        'Stock insuficiente para convertir esta reserva.',
    'catalogReservations.convert.error.confirmedOnly':
        'Confirme la reserva antes de convertirla en venta.',
    'catalogReservations.convert.error.processing':
        'Esta reserva ya se está convirtiendo. Actualice la pantalla.',
    'catalogReservations.convert.error.paymentConfig':
        'Configure un tipo de cobro futuro antes de la conversión.',
    'catalogReservations.convert.error.product':
        'Uno de los productos reservados ya no está disponible.',
    'catalogReservations.convert.error.generic':
        'No fue posible convertir la reserva en venta.',
    'catalogReservations.items': 'ítems',
    'catalogReservations.products': 'Productos reservados',
    'catalogReservations.notes': 'Observación',
    'catalogReservations.noNotes': 'No se informó ninguna observación.',
    'catalogReservations.previous': 'Página anterior',
    'catalogReservations.next': 'Página siguiente',
    'produto.webList.edit.banner':
        'Modo edición activo • {count} ítems encontrados • haz clic en un producto para cambiarlo.',
    'produto.webList.searchHint': 'Buscar por nombre, código o SKU...',
    'produto.webList.preferenceSaved':
        'Preferencia de visualización actualizada.',
    'produto.webList.view.vertical': 'Vertical',
    'produto.webList.view.horizontal': 'Horizontal',
    'produto.webList.view.list': 'Lista',
    'produto.webList.view.grid': 'Cuadrícula',
    'produto.webList.filter.category': 'Categoría',
    'produto.webList.filter.categoryAll': 'Todas las categorías',
    'produto.webList.filter.flags': 'Marcadores',
    'produto.webList.filter.flagsAll': 'Todos los ítems',
    'produto.webList.filter.flagsFavorites': 'Favoritos',
    'produto.webList.filter.flagsCatalog': 'En catálogo',
    'produto.webList.filter.flagsFavoritesCatalog': 'Favoritos y catálogo',
    'produto.webList.filter.statusAll': 'Todos',
    'produto.webList.filter.stockAll': 'Todos',
    'produto.webList.filter.stockAvailable': 'En stock',
    'produto.webList.filter.stockLow': 'Stock bajo',
    'produto.webList.filter.stockOut': 'Sin stock',
    'produto.webList.filter.stockNegative': 'Stock negativo',
    'produto.webList.sort.label': 'Orden',
    'produto.webList.sort.name': 'Ordenar por nombre',
    'produto.webList.sort.priceAsc': 'Menor precio',
    'produto.webList.sort.priceDesc': 'Mayor precio',
    'produto.webList.quick.withImage': 'Con imagen',
    'produto.webList.quick.lowStock': 'Stock bajo',
    'produto.webList.errorTitle': 'No se pudo cargar el catálogo.',
    'produto.webList.itemWithoutName': 'Ítem sin nombre',
    'produto.webList.table.product': 'Producto',
    'produto.webList.table.category': 'Categoría',
    'produto.webList.table.code': 'Código',
    'produto.webList.table.price': 'Precio',
    'produto.webList.itemsPerPageLabel': 'Ítems por página',
    'produto.webList.pagination.summary':
        'Mostrando {start} a {end} de {total} ítems',
    'produto.webList.stockNotApplicable': 'Sin control',
    'produto.webList.stockQuantity': 'Cant. {value}',
    'produto.webList.stockLow': 'Stock bajo',
    'produto.webList.stockOut': 'Sin stock',
    'produto.webList.stockNegative': 'Stock negativo',
    'produto.webList.codeUnavailable': 'Sin código',
    'produto.webList.viewAction': 'Ver',
    'produto.favorite.addTooltip': 'Marcar como favorito',
    'produto.favorite.removeTooltip': 'Quitar de favoritos',
    'produto.favorite.enabledFeedback': 'Favorito activado',
    'produto.favorite.disabledFeedback': 'Favorito desactivado',
    'produto.favorite.updateError':
        'No se pudo actualizar el favorito del producto.',
    'produto.catalog.enableTooltip': 'Disponibilizar para catálogo',
    'produto.catalog.disableTooltip':
        'Quitar de la disponibilidad para catálogo',
    'produto.catalog.enabledFeedback': 'Disponible para catálogo activado',
    'produto.catalog.disabledFeedback': 'Disponible para catálogo desactivado',
    'produto.catalog.updateError':
        'No se pudo actualizar la disponibilidad en el catálogo.',
    'produto.catalog.statusLabel': 'Catálogo',
    'produto.catalog.availableStatus': 'Disponible',
    'produto.catalog.unavailableStatus': 'No disponible',
  },
};
