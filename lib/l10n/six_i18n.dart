import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'web_i18n_store.dart';

extension SixI18nBuildContext on BuildContext {
  /// Resolve textos do Six a partir do pacote de traduções carregado do backend.
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
      return value;
    }

    final resolvedFallback =
        fallback ?? _fallbacks[code]?[key] ?? _fallbacks['pt']?[key];
    if (resolvedFallback != null && resolvedFallback.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[i18n] chave ausente: $key para idioma=$code. Usando fallback.',
        );
      }
      return resolvedFallback;
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
    'app.title': 'Six',
    'common.save': 'Salvar',
    'common.cancel': 'Cancelar',
    'common.back': 'Voltar',
    'common.close': 'Fechar',
    'common.edit': 'Editar',
    'common.delet\u0065': 'Excluir',
    'common.search': 'Buscar',
    'common.clear': 'Limpar',
    'common.confirm': 'Confirmar',
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
    'recebimento.valorEmAberto': 'Valor em aberto',
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
    'web.navigation.operations': 'Operações',
    'web.navigation.operations.pos': 'Frente de caixa',
    'web.navigation.operations.technicalService': 'Assistências técnicas',
    'web.navigation.operations.purchases': 'Compras',
    'web.navigation.operations.reservations': 'Reservas',
    'web.navigation.catalog': 'Catálogo',
    'web.navigation.catalog.products': 'Produtos',
    'web.navigation.catalog.services': 'Serviços',
    'web.navigation.catalog.stock': 'Estoque',
    'web.navigation.catalog.categories': 'Categorias',
    'produto.dashboard.importSpreadsheetSoon':
        'Importar via planilha (em breve)',
    'web.navigation.people': 'Pessoas',
    'web.navigation.people.customers': 'Clientes',
    'web.navigation.people.collaborators': 'Colaboradores',
    'web.navigation.people.performance': 'Desempenho',
    'web.navigation.cash': 'Caixa',
    'web.navigation.financial': 'Financeiro',
    'web.navigation.financial.agenda': 'Agenda financeira',
    'web.navigation.settings': 'Configurações',
    'web.navigation.reports': 'Relatórios',
    'web.navigation.unavailable': 'Destino indisponível nesta versão.',
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
    'web.header.logout': 'Sair',
    'workspaceHome.title': 'Meu dia no SixApp',
    'workspaceHome.greeting': 'Olá, {name}',
    'workspaceHome.unknownUser': 'usuário',
    'workspaceHome.companyFallback': 'Comércio atual',
    'workspaceHome.operationalDate': 'Hoje: {date}',
    'workspaceHome.refreshTooltip': 'Atualizar resumo do dia',
    'workspaceHome.loading.title': 'Carregando resumo do dia',
    'workspaceHome.loading.subtitle':
        'Buscando a situação atual desta empresa.',
    'workspaceHome.error.title': 'Não foi possível carregar o resumo do dia.',
    'workspaceHome.section.today': 'Situação de hoje',
    'workspaceHome.section.attention': 'Precisa da sua atenção',
    'workspaceHome.section.quickActions': 'Ações rápidas',
    'workspaceHome.empty.today':
        'Nenhum bloco do resumo está disponível para suas permissões.',
    'workspaceHome.empty.attention': 'Nenhuma pendência importante agora.',
    'workspaceHome.empty.quickActions':
        'Nenhuma ação rápida disponível para suas permissões.',
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
    'streak.keepUsing': 'Use o SixApp todos os dias para manter sua ofensiva.',
    'streak.startedToday': 'Sua ofensiva começou hoje.',
    'streak.loading': 'Carregando seus dias de ofensiva.',
    'streak.loadError': 'Não foi possível carregar sua ofensiva.',
    'mobile.nav.dash': 'dash',
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
    'auth.noAccount': 'Ainda não tem uma conta?',
    'auth.createAccount': 'Criar conta',
    'auth.signInWithApple': 'Entrar com Apple',
    'auth.signInWithGoogle': 'Entrar com Google',
    'auth.googleLoginError': 'Não foi possível concluir o login com Google.',
    'webAuthGate.temporaryError.title': 'Não foi possível validar sua sessão',
    'webAuthGate.temporaryError.message':
        'Verifique sua conexão ou aguarde o backend responder e tente novamente.',
    'auth.appleLoginMock': 'Login com Apple (mocked)',
    'auth.termsPrefix':
        'Ao clicar em "Continuar", declaro ter lido e concordo com os ',
    'auth.terms': 'Termos de Uso e Política de Privacidade',
    'auth.entry.title': 'Bem-vindo ao Six',
    'auth.entry.subtitle':
        'Antes de continuar, diga como deseja acessar o app.',
    'auth.entry.hasAccountTitle': 'Já tenho uma conta',
    'auth.entry.hasAccountSubtitle':
        'Entre com seu e-mail e senha para acessar sua empresa.',
    'auth.entry.loginAction': 'Entrar',
    'auth.entry.newAccountTitle': 'Sou novo por aqui',
    'auth.entry.newAccountSubtitle':
        'Veja um resumo rápido e crie sua conta para começar.',
    'auth.entry.newAccountAction': 'Conhecer o Six',
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
        'Acompanhe indicadores e prepare sua operação para evoluir com o Six.',
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

    // Gestão — seções
    'gestao.title': 'Gestão',
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
    'gestao.people.suppliers': 'Fornecedores',
    'gestao.people.suppliersDesc': 'Parceiros e compras do comércio',

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
    'atendimento.mobile.chooseOperation': 'Escolha a operação para iniciar.',
    'atendimento.mobile.salesMenuTitle': 'Vendas',
    'atendimento.mobile.newSaleTitle': 'Nova venda',
    'atendimento.mobile.newSaleSubtitle': 'Vender produtos',
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
    'atendimento.mobile.cashOperationsTitle': 'Operações de caixa',
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
    'operacao.mobile.returnTitle': 'Devoluções',
    'operacao.mobile.returnSubtitle': 'Registrar devolução',
    'operacao.mobile.returnUnavailable': 'Em breve',

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
    'app.title': 'Six',
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.back': 'Back',
    'common.close': 'Close',
    'common.edit': 'Edit',
    'common.delet\u0065': 'Delete',
    'common.search': 'Search',
    'common.clear': 'Clear',
    'common.confirm': 'Confirm',
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
    'recebimento.valorEmAberto': 'Outstanding amount',
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
    'web.navigation.catalog.products': 'Products',
    'web.navigation.catalog.services': 'Services',
    'web.navigation.catalog.stock': 'Stock',
    'web.navigation.catalog.categories': 'Categories',
    'produto.dashboard.importSpreadsheetSoon':
        'Import via spreadsheet (coming soon)',
    'web.navigation.people': 'People',
    'web.navigation.people.customers': 'Customers',
    'web.navigation.people.collaborators': 'Team members',
    'web.navigation.people.performance': 'Performance',
    'web.navigation.cash': 'Cash register',
    'web.navigation.financial': 'Financial',
    'web.navigation.financial.agenda': 'Financial agenda',
    'web.navigation.settings': 'Settings',
    'web.navigation.reports': 'Reports',
    'web.navigation.unavailable': 'Destination unavailable in this version.',
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
    'web.header.logout': 'Sign out',
    'workspaceHome.title': 'My day in SixApp',
    'workspaceHome.greeting': 'Hello, {name}',
    'workspaceHome.unknownUser': 'user',
    'workspaceHome.companyFallback': 'Current business',
    'workspaceHome.operationalDate': 'Today: {date}',
    'workspaceHome.refreshTooltip': 'Refresh day summary',
    'workspaceHome.loading.title': 'Loading day summary',
    'workspaceHome.loading.subtitle':
        'Fetching the current situation for this business.',
    'workspaceHome.error.title': 'Could not load the day summary.',
    'workspaceHome.section.today': 'Today status',
    'workspaceHome.section.attention': 'Needs your attention',
    'workspaceHome.section.quickActions': 'Quick actions',
    'workspaceHome.empty.today':
        'No summary block is available for your permissions.',
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
    'streak.keepUsing': 'Use SixApp every day to keep your streak.',
    'streak.startedToday': 'Your streak started today.',
    'streak.loading': 'Loading your streak days.',
    'streak.loadError': 'Could not load your streak.',
    'mobile.nav.dash': 'dash',
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
    'webAuthGate.temporaryError.title': 'Could not validate your session',
    'webAuthGate.temporaryError.message':
        'Check your connection or wait for the backend to respond, then try again.',
    'auth.appleLoginMock': 'Apple sign-in (mocked)',
    'auth.termsPrefix':
        'By clicking "Continue", I confirm that I have read and agree with the ',
    'auth.terms': 'Terms of Use and Privacy Policy',
    'auth.entry.title': 'Welcome to Six',
    'auth.entry.subtitle':
        'Before continuing, choose how you want to access the app.',
    'auth.entry.hasAccountTitle': 'I already have an account',
    'auth.entry.hasAccountSubtitle':
        'Sign in with your email and password to access your company.',
    'auth.entry.loginAction': 'Sign in',
    'auth.entry.newAccountTitle': 'I am new here',
    'auth.entry.newAccountSubtitle':
        'See a quick overview and create your account to get started.',
    'auth.entry.newAccountAction': 'Explore Six',
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
        'Track indicators and prepare your operation to evolve with Six.',
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
    'atendimento.mobile.chooseOperation': 'Choose the operation to start.',
    'atendimento.mobile.salesMenuTitle': 'Sales',
    'atendimento.mobile.newSaleTitle': 'New sale',
    'atendimento.mobile.newSaleSubtitle': 'Sell products',
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
    'atendimento.mobile.cashOperationsTitle': 'Cash operations',
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
    'operacao.mobile.returnTitle': 'Returns',
    'operacao.mobile.returnSubtitle': 'Register return',
    'operacao.mobile.returnUnavailable': 'Coming soon',

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
    'app.title': 'Six',
    'common.save': 'Guardar',
    'common.cancel': 'Cancelar',
    'common.back': 'Volver',
    'common.close': 'Cerrar',
    'common.edit': 'Editar',
    'common.delet\u0065': 'Eliminar',
    'common.search': 'Buscar',
    'common.clear': 'Limpiar',
    'common.confirm': 'Confirmar',
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
    'recebimento.valorEmAberto': 'Valor pendiente',
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
    'web.navigation.catalog.products': 'Productos',
    'web.navigation.catalog.services': 'Servicios',
    'web.navigation.catalog.stock': 'Inventario',
    'web.navigation.catalog.categories': 'Categorías',
    'produto.dashboard.importSpreadsheetSoon':
        'Importar por hoja de cálculo (próximamente)',
    'web.navigation.people': 'Personas',
    'web.navigation.people.customers': 'Clientes',
    'web.navigation.people.collaborators': 'Colaboradores',
    'web.navigation.people.performance': 'Desempeño',
    'web.navigation.cash': 'Caja',
    'web.navigation.financial': 'Financiero',
    'web.navigation.financial.agenda': 'Agenda financiera',
    'web.navigation.settings': 'Configuración',
    'web.navigation.reports': 'Informes',
    'web.navigation.unavailable': 'Destino no disponible en esta versión.',
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
    'web.header.logout': 'Salir',
    'workspaceHome.title': 'Mi día en SixApp',
    'workspaceHome.greeting': 'Hola, {name}',
    'workspaceHome.unknownUser': 'usuario',
    'workspaceHome.companyFallback': 'Comercio actual',
    'workspaceHome.operationalDate': 'Hoy: {date}',
    'workspaceHome.refreshTooltip': 'Actualizar resumen del día',
    'workspaceHome.loading.title': 'Cargando resumen del día',
    'workspaceHome.loading.subtitle':
        'Buscando la situación actual de este comercio.',
    'workspaceHome.error.title': 'No fue posible cargar el resumen del día.',
    'workspaceHome.section.today': 'Situación de hoy',
    'workspaceHome.section.attention': 'Necesita tu atención',
    'workspaceHome.section.quickActions': 'Acciones rápidas',
    'workspaceHome.empty.today':
        'Ningún bloque del resumen está disponible para tus permisos.',
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
    'streak.keepUsing': 'Usa SixApp todos los días para mantener tu racha.',
    'streak.startedToday': 'Tu racha empezó hoy.',
    'streak.loading': 'Cargando tus días de racha.',
    'streak.loadError': 'No se pudo cargar tu racha.',
    'mobile.nav.dash': 'dash',
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
    'webAuthGate.temporaryError.title': 'No se pudo validar tu sesión',
    'webAuthGate.temporaryError.message':
        'Verifica tu conexión o espera a que el backend responda y vuelve a intentarlo.',
    'auth.appleLoginMock': 'Inicio de sesión con Apple (mocked)',
    'auth.termsPrefix':
        'Al hacer clic en "Continuar", declaro que leí y acepto los ',
    'auth.terms': 'Términos de Uso y Política de Privacidad',
    'auth.entry.title': 'Bienvenido a Six',
    'auth.entry.subtitle':
        'Antes de continuar, elige cómo quieres acceder a la app.',
    'auth.entry.hasAccountTitle': 'Ya tengo una cuenta',
    'auth.entry.hasAccountSubtitle':
        'Entra con tu correo y contraseña para acceder a tu empresa.',
    'auth.entry.loginAction': 'Entrar',
    'auth.entry.newAccountTitle': 'Soy nuevo aquí',
    'auth.entry.newAccountSubtitle':
        'Mira un resumen rápido y crea tu cuenta para comenzar.',
    'auth.entry.newAccountAction': 'Conocer Six',
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
        'Acompaña indicadores y prepara tu operación para evolucionar con Six.',
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

    // Gestión — secciones
    'gestao.title': 'Gestión',
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
    'atendimento.mobile.chooseOperation': 'Elige la operación para iniciar.',
    'atendimento.mobile.salesMenuTitle': 'Ventas',
    'atendimento.mobile.newSaleTitle': 'Nueva venta',
    'atendimento.mobile.newSaleSubtitle': 'Vender productos',
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
    'atendimento.mobile.cashOperationsTitle': 'Operaciones de caja',
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
    'operacao.mobile.returnTitle': 'Devoluciones',
    'operacao.mobile.returnSubtitle': 'Registrar devolución',
    'operacao.mobile.returnUnavailable': 'Próximamente',

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
