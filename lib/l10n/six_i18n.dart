Warning: truncated output (original token count: 120955)
Total output lines: 8498

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
    'agenda.journey.currentCompany': 'Empresa atual',
    'agenda.journey.type': 'Tipo',
    'agenda.journey.space': 'Espaço',
    'agenda.journey.details': 'Detalhes',
    'agenda.journey.recurrence': 'Recorrência',
    'agenda.journey.step': 'Etapa {step} de 4',
    'agenda.journey.typeTitle': 'Você vai pagar ou receber?',
    'agenda.journey.typeHint': 'Comece escolhendo o tipo de lançamento.',
    'agenda.journey.payHint': 'Uma conta ou despesa que você precisa pagar.',
    'agenda.journey.receiveHint': 'Um valor que você tem a receber.',
    'agenda.journey.spaceTitle': 'Esse lançamento é pessoal ou da empresa?',
    'agenda.journey.spaceHint': 'Escolha onde organizar essa conta.',
    'agenda.journey.personalHint':
        'Suas contas pessoais, separadas das finanças da empresa.',
    'agenda.journey.companyHint': 'Finanças da empresa selecionada:',
    'agenda.journey.detailsTitle': 'Quais são os dados do lançamento?',
    'agenda.journey.detailsHint':
        'Informe a descrição, o valor e o vencimento. Complete os demais dados conforme precisar.',
    'agenda.journey.recurrenceTitle': 'Esse lançamento se repete?',
    'agenda.journey.recurrenceHint':
        'Defina a repetição e confira o resumo antes de salvar.',
    'agenda.journey.once': 'Uma única vez',
    'agenda.journey.onceHint': 'Criar apenas este lançamento.',
    'agenda.journey.repeat': 'Repetir',
    'agenda.journey.repeatHint': 'Repetir o valor em novos vencimentos.',
    'agenda.journey.back': 'Voltar',
    'agenda.journey.continue': 'Continuar',
    'agenda.journey.perOccurrence': 'Valor por ocorrência',
    'agenda.journey.perOccurrenceHint':
        'O valor informado será repetido em cada ocorrência; não será dividido em parcelas.',
    'agenda.journey.firstDue': 'Primeiro vencimento',
    'agenda.journey.settlementFirst':
        'Após salvar, confirme a baixa deste lançamento. Se houver repetição, os próximos vencimentos continuarão em aberto.',
    'agenda.journey.spaceResetHint':
        'Ao trocar o espaço, conta, categoria, centro de custo, contato e responsável serão limpos, e a forma prevista será recarregada. Descrição, valor e datas serão mantidos.',
    'agenda.journey.discardTitle': 'Descartar este lançamento?',
    'agenda.journey.discardHint':
        'Os dados preenchidos ainda não foram salvos.',
    'agenda.journey.keepEditing': 'Continuar preenchendo',
    'agenda.journey.discard': 'Descartar',
    'agenda.journey.invalidAmount': 'Informe um valor maior que zero.',
    'suppliers.web.title': 'Fornecedores',
    'suppliers.web.subtitle':
        'Gestão de fornecedores, parceiros e contatos comerciais.',
    'suppliers.web.refresh': 'Atualizar',
    'suppliers.web.permissions': 'Permissões',
    'suppliers.web.new': 'Novo fornecedor',
    'suppliers.web.registered': 'Fornecedores cadastrados',
    'suppliers.web.activePlural': 'Ativos',
    'suppliers.web.inactivePlural': 'Inativos',
    'suppliers.web.found': 'Fornecedores encontrados',
    'suppliers.web.searchTitle': 'Busca e filtros',
    'suppliers.web.searchHint':
        'Buscar por nome, documento, telefone ou e-mail',
    'suppliers.web.clear': 'Limpar busca',
    'suppliers.web.all': 'Todos',
    'suppliers.web.empty': 'Nenhum fornecedor cadastrado',
    'suppliers.web.emptyHint': 'Os fornecedores cadastrados aparecerão aqui.',
    'suppliers.web.emptySearch': 'Nenhum fornecedor encontrado',
    'suppliers.web.emptySearchHint':
        'Revise a busca ou os filtros para encontrar fornecedores.',
    'suppliers.web.clearFilters': 'Limpar filtros',
    'suppliers.web.loadError': 'Não foi possível carregar os fornecedores',
    'suppliers.web.retry': 'Tentar novamente',
    'suppliers.web.active': 'Ativo',
    'suppliers.web.inactive': 'Inativo',
    'suppliers.web.edit': 'Editar',
    'suppliers.web.view': 'Consultar',
    'usuariosSixo.lastLogin.label': 'Última entrada',
    'usuariosSixo.lastLogin.noRecord': 'Sem registro',
    'usuariosSixo.lastLogin.noRecordHint':
        'Ainda não há registro de login para este usuário.',
    'usuariosSixo.lastLogin.today': 'Hoje',
    'usuariosSixo.lastLogin.yesterday': 'Ontem',
    'usuariosSixo.lastLogin.hint':
        'Login concluído com sucesso. A renovação automática da sessão não conta como nova entrada.',
    'purchases.permission.read': 'Consultar compras',
    'purchases.permission.readDescription': 'Consultar compras deste comércio.',
    'purchases.permission.create': 'Criar compras',
    'purchases.permission.createDescription': 'Cadastrar novos rascunhos.',
    'purchases.permission.edit': 'Editar compras',
    'purchases.permission.editDescription': 'Alterar compras em rascunho.',
    'purchases.permission.confirm': 'Confirmar compras',
    'purchases.permission.confirmDescription':
        'Confirmar e gerar contas a pagar.',
    'purchases.permission.cancel': 'Cancelar compras',
    'purchases.permission.cancelDescription':
        'Cancelar pedidos conforme regras financeiras.',
    'purchases.permission.receive': 'Receber mercadorias',
    'purchases.permission.receiveDescription':
        'Registrar a entrada efetiva dos produtos.',
    'suppliers.permission.read': 'Consultar fornecedores',
    'suppliers.permission.readDescription': 'Consultar fornecedores da conta.',
    'suppliers.permission.create': 'Cadastrar fornecedores',
    'suppliers.permission.createDescription': 'Criar novos fornecedores.',
    'suppliers.permission.edit': 'Editar fornecedores',
    'suppliers.permission.editDescription': 'Alterar cadastros existentes.',
    'suppliers.permission.disable': 'Ativar / inativar fornecedores',
    'suppliers.permission.disableDescription':
        'Alterar status dos fornecedores.',
    'space.createAccount': 'Cadastrar conta',
    'space.emptyAccountHint': 'Cadastre uma conta aqui para continuar.',
    'dateSelector.applyDate': 'Aplicar data',
    'dateSelector.hint': 'Escolha uma data sem sair do atendimento.',
    'dateSelector.today': 'Hoje',
    'dateSelector.tomorrow': 'Amanhã',
    'dateSelector.inDays': 'Em {days} dias',
    'dateSelector.shortcuts': 'Atalhos rápidos',
    'space.actualAccount': 'Conta utilizada',
    'space.PESSOAL': 'Pessoal',
    'space.EMPRESA': 'Empresa',
    'space.settings': 'Configurações do espaço',
    'space.CONTAS': 'Contas financeiras',
    'space.CATEGORIAS': 'Categorias',
    'space.CENTROS': 'Centros de custos',
    'space.add': 'Adicionar',
    'space.edit': 'Editar',
    'space.name': 'Nome',
    'space.institution': 'Instituição (opcional)',
    'space.BANCO': 'Banco',
    'space.CARTEIRA': 'Carteira',
    'space.CAIXA': 'Caixa',
    'space.RECEITA': 'Receita',
    'space.DESPESA': 'Despesa',
    'space.AMBOS': 'Ambos',
    'space.CUSTO': 'Custo',
    'space.RESULTADO': 'Resultado',
    'space.active': 'Ativo',
    'space.inactive': 'Inativo',
    'space.save': 'Salvar',
    'space.cancel': 'Cancelar',
    'space.loading': 'Carregando…',
    'space.retry': 'Não foi possível carregar. Tentar novamente',
    'space.empty': 'Nenhum cadastro neste espaço.',
    'space.emptyHint': 'Cadastre uma opção nas configurações deste espaço.',
    'space.required': 'Informe um nome.',
    'space.saveError':
        'Não foi possível salvar. Verifique sua permissão e tente novamente.',
    'space.history': 'Desativar preserva os lançamentos e o histórico.',
    'space.account': 'Conta prevista',
    'machine.cashAutomatic': 'Entrada automática no caixa',
    'pdv.receipt.amountEntered': 'Valor informado',
    'pdv.receipt.readyToFinish': 'Tudo pronto para concluir',
    'pdv.receipt.summary': 'Resumo do recebimento',
    'pdv.receipt.remainingOpen': 'Saldo em aberto',
    'pdv.receipt.readyPartial': 'Tudo pronto para confirmar o parcial',
    'ir.title': 'Separar para o Imposto de Renda',
    'ir.hint': 'Marcar para revisão na declaração. Não indica dedutibilidade.',
    'ir.limit':
        'Comprovantes: até 3 imagens JPG, PNG ou WebP, de até 2 MB cada.',
    'ir.add': 'Adicionar comprovante',
    'ir.camera': 'Fotografar',
    'ir.fileError':
        'Não foi possível anexar. Use uma imagem JPG, PNG ou WebP de até 2 MB.',
    'ir.remove': 'Remover comprovante',
    'ir.view': 'Visualizar comprovante',
    'ir.filter': 'Separados para IR',

    'space.formSpace': 'Espaço financeiro',
    'space.editLocked':
        'O espaço de um lançamento existente não pode ser alterado neste formulário.',
    'agenda.settlement.sourceAccount': 'Conta de saída',
    'agenda.settlement.destinationAccount': 'Conta de destino',
    'agenda.settlement.accountRequired': 'Selecione a conta para confirmar.',

    'space.none': 'Não informada',
    'paymentSettings.contextHint':
        'O novo nome será usado nas telas deste comércio. O tipo financeiro e os valores das operações permanecem os mesmos.',
    'paymentSettings.title': 'Formas de recebimento',
    'paymentSettings.hint':
        'Altere o nome exibido sem mudar o tipo financeiro.',
    'paymentSettings.name': 'Descrição de exibição',
    'paymentSettings.required': 'Informe um nome.',
    'paymentSettings.save': 'Salvar',
    'paymentSettings.cancel': 'Cancelar',
    'paymentSettings.refresh': 'Atualizar',
    'paymentSettings.empty': 'Nenhuma forma de recebimento disponível.',
    'paymentSettings.loadError':
        'Não foi possível carregar as formas de recebimento.',
    'paymentSettings.saveError': 'Não foi possível salvar. Tente novamente.',
    'paymentSettings.forbidden':
        'Você não possui permissão para editar as formas de recebimento.',
    'paymentSettings.expired': 'Sessão expirada. Faça login novamente.',
    'paymentSettings.saved': 'Forma de recebimento atualizada.',
    'paymentSettings.active': 'Ativo',
    'paymentSettings.inactive': 'Inativo',
    'paymentSettings.edit': 'Editar nome',
    'paymentSettings.loading': 'Carregando formas de recebimento',
    'agenda.form.overdueOne': 'Vencido há 1 dia',
    'agenda.form.option.sale': 'Venda',
    'agenda.form.option.service': 'Ordem de serviço',
    'agenda.form.option.expense': 'Despesa manual',
    'agenda.form.option.purchase': 'Compra',
    'agenda.form.option.installment': 'Parcela',
    'agenda.form.option.cashMovement': 'Movimentação de caixa',
    'agenda.form.option.bankSlip': 'Boleto',
    'agenda.form.option.transfer': 'Transferência',
    'agenda.form.option.credit': 'Cartão de crédito',
    'agenda.form.option.debit': 'Cartão de débito',
    'agenda.form.option.directDebit': 'Débito automático',
    'agenda.form.option.cash': 'Dinheiro',
    'agenda.form.actualDate': 'Data do pagamento ou recebimento',
    'agenda.form.saveReceive': 'Salvar e confirmar recebimento',
    'agenda.form.create': 'Novo lançamento',
    'agenda.form.edit': 'Editar lançamento',
    'agenda.form.subtitle':
        'Organize a conta e planeje o pagamento ou recebimento.',
    'agenda.form.main': 'Dados do lançamento',
    'agenda.form.payable': 'A pagar',
    'agenda.form.receivable': 'A receber',
    'agenda.form.description': 'Descrição',
    'agenda.form.amount': 'Valor total',
    'agenda.form.situation': 'Status',
    'agenda.form.open': 'Pendente',
    'agenda.form.planned': 'Previsto',
    'agenda.form.partial': 'Parcial',
    'agenda.form.paid': 'Pago',
    'agenda.form.received': 'Recebido',
    'agenda.form.cancelled': 'Cancelado',
    'agenda.form.competence': 'Competência',
    'agenda.competence.monthYearTitle': 'Competência · mês/ano',
    'agenda.competence.selectMonthYear': 'Selecione somente o mês e o ano.',
    'agenda.competence.previousYear': 'Ano anterior',
    'agenda.competence.nextYear': 'Próximo ano',
    'agenda.competence.apply': 'Aplicar',
    'agenda.saleItems.title': 'Produtos e serviços',
    'agenda.saleItems.empty':
        'Os itens dessa venda antiga não estão disponíveis no histórico.',
    'agenda.saleItems.product': 'Produto',
    'agenda.saleItems.service': 'Serviço',
    'agenda.saleItems.quantity': 'Qtd.',
    'agenda.saleItems.sharePdf': 'Compartilhar / salvar PDF',
    'agenda.saleItems.downloadPdf': 'Baixar comprovante PDF',
    'agenda.saleItems.pdfA4': 'Comprovante A4',
    'agenda.saleItems.pdfCupom': 'Cupom térmico',
    'agenda.competence.back': 'Voltar',
    'agenda.calendar.launchSingular': 'lançamento',
    'agenda.calendar.launchPlural': 'lançamentos',
    'agenda.calendar.expand': 'Expandir lançamentos',
    'agenda.calendar.collapse': 'Recolher lançamentos',
    'agenda.calendar.received': 'Recebido',
    'agenda.calendar.paid': 'Pago',
    'agenda.calendar.toReceive': 'A receber',
    'agenda.calendar.toPay': 'A pagar',
    'agenda.calendar.outstanding': 'Em aberto',
    'agenda.form.competenceHint':
        'Período ao qual a conta pertence, independentemente do pagamento.',
    'agenda.form.dates': 'Vencimento e pagamento',
    'agenda.form.due': 'Vencimento original',
    'agenda.form.dueHint': 'Prazo original da conta.',
    'agenda.form.forecastPay': 'Previsão de pagamento',
    'agenda.form.forecastReceive': 'Previsão de recebimento',
    'agenda.form.forecastPayHint': 'Quando você pretende pagar. Opcional.',
    'agenda.form.forecastReceiveHint': 'Quando você espera receber. Opcional.',
    'agenda.form.forecastHint':
        'A previsão não altera o vencimento nem confirma o pagamento.',
    'agenda.form.overdue': 'Vencido há {days} dias',
    'agenda.form.alreadyPaid': 'Já paguei esta conta',
    'agenda.form.alreadyReceived': 'Já recebi este valor',
    'agenda.form.settleAfterSave':
        'Após salvar, confirme a data, o valor e a forma de pagamento.',
    'agenda.form.classification': 'Classificação',
    'agenda.form.customer': 'Cliente',
    'agenda.form.supplier': 'Fornecedor',
    'agenda.form.category': 'Categoria',
    'agenda.form.paymentMethod': 'Forma prevista de pagamento',
    'agenda.form.additional': 'Mais informações (opcional)',
    'agenda.form.origin': 'Origem',
    'agenda.form.company': 'Empresa',
    'agenda.form.transactionDate': 'Data do fato gerador',
    'agenda.form.transactionHint':
        'Data em que a compra, venda ou despesa ocorreu. Não é a data de cadastro nem de pagamento.',
    'agenda.form.responsible': 'Responsável',
    'agenda.form.document': 'Documento fiscal',
    'agenda.form.reference': 'Referência externa',
    'agenda.form.customerId': 'Identificador do cliente',
    'agenda.form.supplierId': 'Identificador do fornecedor',
    'agenda.form.notes': 'Observações (opcional)',
    'agenda.form.summary': 'Resumo do lançamento',
    'agenda.form.notSet': 'Não informado',
    'agenda.form.paidValue': 'Valor pago',
    'agenda.form.receivedValue': 'Valor recebido',
    'agenda.form.registered': 'Registrado em',
    'agenda.form.onSave': 'Ao salvar',
    'agenda.form.registeredHint':
        'Data de cadastro preenchida automaticamente.',
    'agenda.form.settlementHint':
        'O pagamento ou recebimento só é confirmado ao registrar a baixa.',
    'agenda.form.locked':
        'Este lançamento possui confirmação financeira. Tipo, situação e valor ficam protegidos.',
    'agenda.form.forecastRecurrenceHint':
        'A previsão vale para este vencimento. Os próximos mantêm suas próprias datas.',
    'agenda.form.delete': 'Excluir lançamento',
    'agenda.form.cancel': 'Cancelar',
    'agenda.form.save': 'Salvar lançamento',
    'agenda.form.update': 'Atualizar lançamento',
    'agenda.form.saving': 'Salvando…',
    'agenda.form.saveContinue': 'Salvar e confirmar pagamento',
    'agenda.form.clearForecast': 'Limpar previsão',
    'agenda.form.required': 'Campo obrigatório',
    'agenda.settlement.payTitle': 'Pagar lançamento',
    'agenda.settlement.receiveTitle': 'Receber lançamento',
    'agenda.settlement.payTotal': 'Pagar total',
    'agenda.settlement.payPartial': 'Pagar parcial',
    'agenda.settlement.methods': 'Formas de pagamento',
    'agenda.settlement.methodType': 'Tipo de pagamento',
    'agenda.settlement.values': 'Valores do pagamento',
    'agenda.settlement.alreadyPaid': 'Valor já pago',
    'agenda.settlement.loadingMethods': 'Carregando formas de pagamento...',
    'agenda.settlement.duplicateMethod':
        'Cada forma de pagamento pode ser usada apenas uma vez.',
    'agenda.settlement.choosePayment': 'Como deseja pagar este lançamento?',
    'agenda.settlement.success': 'Liquidação registrada com sucesso.',
    'agenda.launchDetails.dialogBarrier': 'Detalhes do lançamento financeiro',
    'agenda.launchDelete.dialogBarrier':
        'Confirmar exclusão do lançamento financeiro',
    'agenda.launchDelete.title': 'Excluir lançamento financeiro?',
    'agenda.launchDelete.subtitle':
        'Revise o resumo antes de apagar. Esta ação remove o lançamento e suas confirmações financeiras vinculadas.',
    'agenda.launchDelete.summaryLaunch': 'Lançamento',
    'agenda.launchDelete.summaryAmount': 'Valor',
    'agenda.launchDelete.summaryStatus': 'Status',
    'agenda.launchDelete.impact':
        'O lançamento será apagado definitivamente junto com confirmações, parciais e vínculos financeiros exibidos neste detalhe.',
    'agenda.launchDelete.processing': 'Excluindo...',
    'agenda.launchDelete.confirm': 'Excluir lançamento',
    'agenda.launchDelete.successTitle': 'Lançamento excluído',
    'agenda.launchDelete.successMessage':
        'A Agenda Financeira será atualizada com o lançamento removido.',
    'agenda.launchDelete.error':
        'Não foi possível excluir o lançamento agora. Tente novamente em instantes.',
    'agenda.launchDelete.apiError': 'Falha ao excluir lançamento.',
    'agenda.launchDelete.unnamedLaunch': 'Lançamento sem descrição',
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
    'common.completed': 'Concluído',
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
    'pdv.mobile.finalizingSale': 'Finalizando sua venda...',
    'pdv.mobile.finalizingSaleSemantics': 'SixoApp finalizando sua venda',
    'pdv.mobile.saleCompleted': 'Venda concluída',
    'pdv.mobile.saleCompletedSemantics': 'Venda concluída com sucesso',
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
    'catalog.publicPage.title': 'Catálogo virtual',
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
        'Catálogo salvo e publicado com sucesso.',
    'catalog.publicPage.saveSuccessDraft':
        'Personalização salva. Publique quando estiver pronta.',
    'catalog.publicPage.saveError':
        'Não foi possível salvar o catálogo virtual.',
    'catalog.publicPage.openError':
        'Não foi possível abrir o catálogo em uma nova aba.',
    'catalog.publicPage.linkCopied': 'Link público copiado.',
    'catalog.publicPage.shareSubject': 'Catálogo de {title}',
    'catalog.publicPage.shareFallback':
        'O compartilhamento não está disponível. O link foi copiado.',
    'catalog.publicPage.loadErrorTitle':
        'Não foi possível carregar o catálogo virtual',
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
    'web.navigation.adminPlans': 'Planos',
    'web.navigation.financial': 'Financeiro',
    'web.navigation.financial.agenda': 'Agenda financeira',
    'web.navigation.settings': 'Configurações',
    'web.navigation.reports': 'Relatórios',
    'web.navigation.unavailable': 'Destino indisponível nesta versão.',
    'usuariosSixo.title': 'Usuários do Sixo',
    'usuariosSixo.subtitle':
        'Consulte os usuários cadastrados com acesso exclusivo para o perfil SUPER.',
    'usuariosSixo.summarySemantics': 'Resumo dos usuários cadastrados no Sixo',
    'usuariosSixo.summaryTitle': 'Base global de usuários',
    'usuariosSixo.summarySubtitle':
        'Consulta protegida pelo perfil SUPER do token.',
    'usuariosSixo.totalLabel': 'usuários',
    'usuariosSixo.totalRegistered': 'Usuários cadastrados',
    'usuariosSixo.searchHint': 'Buscar por nome, e-mail, celular ou perfil',
    'usuariosSixo.resultsLabel': 'encontrados',
    'usuariosSixo.forbiddenTitle': 'Acesso exclusivo para SUPER',
    'usuariosSixo.forbiddenMessage':
        'Seu perfil não possui permissão para consultar os usuários do Sixo.',
    'usuariosSixo.loading': 'Carregando usuários do Sixo',
    'usuariosSixo.loadErrorTitle': 'Não foi possível carregar os usuários',
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
    'usuariosSixo.detail.loadError': 'Não foi possível carregar os detalhes.',
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
    'usuariosSixo.passwordReset.title': 'Resetar senha',
    'usuariosSixo.passwordReset.subtitle':
        'Use esta ação quando o usuário precisar redefinir a senha de acesso.',
    'usuariosSixo.passwordReset.dialogTitle': 'Resetar a senha deste usuário?',
    'usuariosSixo.passwordReset.dialogMessage':
        'A ação será aplicada imediatamente ao usuário selecionado.',
    'usuariosSixo.passwordReset.action': 'Resetar senha',
    'usuariosSixo.passwordReset.successMessage':
        'O reset de senha foi concluído com sucesso.',
    'usuariosSixo.passwordReset.errorMessage':
        'Não foi possível resetar a senha agora. Tente novamente.',
    'initialOnboarding.eyebrow': 'Configuração inicial',
    'initialOnboarding.step': 'Etapa',
    'initialOnboarding.of': 'de',
    'initialOnboarding.languageTitle': 'Escolha seu idioma',
    'initialOnboarding.languageSubtitle':
        'Português vem selecionado por padrão. Você pode trocar agora.',
    'initialOnboarding.identityTitle': 'Vamos começar pelo essencial',
    'initialOnboarding.identitySubtitle':
        'Confirme seus dados para personalizarmos sua experiência.',
    'initialOnboarding.identitySectionTitle': 'Seus dados',
    'initialOnboarding.businessTitle': 'O que seu negócio faz?',
    'initialOnboarding.businessSubtitle':
        'Isso apenas organiza módulos e atalhos. Você poderá alterar depois.',
    'initialOnboarding.languageQuestion': 'Em qual idioma deseja continuar?',
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
    'colaboradores.firstCollaboratorTitle': 'Cadastre seu primeiro colaborador',
    'colaboradores.firstCollaboratorSubtitle':
        'Comece adicionando quem vai ajudar nas vendas, atendimentos ou gestão do comércio.',
    'colaboradores.noCollaboratorFoundSubtitle':
        'Tente buscar por outro nome, e-mail, celular ou apelido.',
    'colaborador.invite.shareAction': 'Compartilhar convite',
    'colaborador.invite.sendAction': 'Enviar convite',
    'colaborador.invite.generateAndEmail': 'Gerar e enviar por e-mail',
    'colaborador.invite.emailAction': 'Enviar direto pelo e-mail',
    'colaborador.invite.emailActionSubtitle':
        'O convite será enviado para o e-mail informado.',
    'colaborador.invite.shareActionSubtitle':
        'Use WhatsApp, mensagens ou outro app do aparelho.',
    'colaborador.invite.actionTitle': 'Enviar convite',
    'colaborador.invite.actionSubtitle':
        'Escolha como o colaborador vai receber o convite.',
    'colaborador.invite.sendingEmail': 'Enviando...',
    'colaborador.invite.emailSent': 'Convite enviado por e-mail.',
    'colaborador.invite.shareSubject': 'Convite SixoApp',
    'colaborador.invite.shareMessage':
        'Olá! Use este link para aceitar o convite de colaborador no SixoApp:\n{link}',
    'colaborador.invite.shareFallback':
        'O compartilhamento não está disponível. O link foi copiado.',
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
    'workspaceHome.viewSelector': 'Selecionar visão da tela inicial',
    'workspaceHome.view.operational': 'Operacional',
    'workspaceHome.view.performance': 'Desempenho',
    'performance.dashboard.teamTitle': 'Desempenho da equipe',
    'performance.dashboard.myTitle': 'Meu desempenho',
    'performance.dashboard.subtitle':
        'Metas ativas, vendas, assistências e situação do caixa em um só lugar.',
    'performance.dashboard.mobileSubtitle':
        'Metas, vendas, assistências e caixa em tempo quase real.',
    'performance.dashboard.staleData':
        'Os últimos dados continuam visíveis. Não foi possível atualizar agora.',
    'performance.dashboard.live': 'Atualização automática',
    'performance.dashboard.liveShort': 'Ao vivo',
    'performance.dashboard.allCollaborators': 'Todos os colaboradores',
    'performance.dashboard.selectedCollaborators': '{count} colaboradores',
    'performance.dashboard.filterTitle': 'Filtrar colaboradores',
    'performance.dashboard.filterHint': 'Selecione um ou mais colaboradores.',
    'performance.dashboard.searchCollaborators': 'Buscar colaborador',
    'performance.dashboard.noCollaboratorsFound':
        'Nenhum colaborador encontrado.',
    'performance.dashboard.periodFilter': 'Selecionar período',
    'performance.dashboard.periodToday': 'Hoje',
    'performance.dashboard.period7Days': 'Últimos 7 dias',
    'performance.dashboard.period30Days': 'Últimos 30 dias',
    'performance.dashboard.periodMonth': 'Mês atual',
    'performance.dashboard.score': 'Desempenho',
    'performance.dashboard.activeGoals': '{count} metas ativas',
    'performance.dashboard.sales': 'Vendas',
    'performance.dashboard.salesCount': '{count} vendas',
    'performance.dashboard.assistance': 'Assistências',
    'performance.dashboard.finishedCount': '{count} finalizadas',
    'performance.dashboard.assistanceCaption': '{count} finalizadas • {amount}',
    'performance.dashboard.cash': 'Caixa',
    'performance.dashboard.cashUnavailable': 'Indisponível',
    'performance.dashboard.cashOpen': 'Aberto',
    'performance.dashboard.cashClosed': 'Fechado',
    'performance.dashboard.cashCaption': 'Situação do comércio atual',
    'performance.dashboard.cashCaptionMine': 'Situação do meu caixa',
    'performance.dashboard.teamComparison': 'Comparativo da equipe',
    'performance.dashboard.goalProgress': 'Progresso das metas',
    'performance.dashboard.chartCaption':
        'Percentual realizado em relação ao objetivo do período.',
    'performance.dashboard.chartEmpty':
        'Não há metas com dados para o gráfico.',
    'performance.dashboard.goalsTitle': 'Metas ativas',
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
    'workspaceHome.quickAction.newSale': 'Vendas',
    'workspaceHome.quickAction.newTechnicalService': 'Serviços',
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
    'catalogHealth.mobile.title': 'Saúde do catálogo',
    'catalogHealth.mobile.description':
        'Qualidade de fotos, categorias e informações dos itens ativos.',
    'catalogHealth.mobile.pendingTitle': 'Pendências do catálogo',
    'catalogHealth.mobile.pendingSubtitle':
        'Revise os cadastros que precisam de atenção.',
    'catalogHealth.mobile.managementTitle': 'Gestão do catálogo',
    'catalogHealth.mobile.managementSubtitle':
        'Organização e ferramentas dos seus itens.',
    'catalogHealth.mobile.categories': 'Categorias',
    'catalogHealth.mobile.categoriesDescription': 'Organizar itens',
    'catalogHealth.mobile.labels': 'Etiquetas',
    'catalogHealth.mobile.labelsDescription': 'Modelos na Web',
    'catalogHealth.mobile.labelsWebOnly':
        'A criação e a impressão de etiquetas estão disponíveis na versão Web.',
    'catalogHealth.mobile.webBadge': 'WEB',
    'catalogHealth.metric.missingPhoto': 'Sem foto',
    'catalogHealth.metric.missingPhotoDescription':
        'Produtos que precisam de uma imagem.',
    'catalogHealth.metric.incompleteRegistration': 'Cadastro incompleto',
    'catalogHealth.metric.incompleteRegistrationDescription':
        'Itens com informações essenciais pendentes.',
    'catalogHealth.metric.missingCategory': 'Sem categoria',
    'catalogHealth.metric.missingCategoryDescription':
        'Itens ainda sem organização definida.',
    'catalogHealth.metric.withoutSales': 'Sem vendas recentes',
    'catalogHealth.metric.withoutSalesDescription':
        'Produtos sem movimentação de saída recente.',
    'catalogHub.web.title': 'Produtos',
    'catalogHub.web.subtitle':
        'Cuide da qualidade do catálogo e acesse cadastros, categorias e etiquetas.',
    'catalogHub.list.subtitle':
        'Gerencie produtos, serviços, preços, imagens e organização.',
    'catalogHub.actions.newProduct': 'Novo produto',
    'catalogHub.actions.newService': 'Novo serviço',
    'catalogHub.actions.newItem': 'Novo item',
    'catalogHub.states.noAccessTitle': 'Acesso ao catálogo indisponível',
    'catalogHub.states.noAccessDescription':
        'Seu perfil não permite visualizar produtos e serviços deste comércio.',
    'catalogHub.states.loadErrorTitle':
        'Não foi possível carregar a saúde do catálogo',
    'catalogHub.states.loadErrorDescription':
        'Os acessos do catálogo continuam disponíveis. Tente atualizar o diagnóstico.',
    'catalogHub.states.emptyTitle': 'Comece seu catálogo',
    'catalogHub.states.emptyDescription':
        'Cadastre o primeiro produto ou serviço. A saúde do catálogo será calculada automaticamente.',
    'catalogHub.health.title': 'Saúde do catálogo',
    'catalogHub.health.description':
        'Qualidade dos cadastros e prontidão dos itens para venda.',
    'catalogHub.health.catalogIssues': 'Pendências cadastrais',
    'catalogHub.health.qualityTitle': 'Qualidade do cadastro',
    'catalogHub.health.qualitySubtitle':
        'Fotos, categorias e informações que ajudam o cliente a decidir.',
    'catalogHub.health.noQualityIssues':
        'Nenhuma pendência cadastral encontrada.',
    'catalogHub.management.title': 'Gestão do catálogo',
    'catalogHub.management.subtitle':
        'Cadastros e ferramentas do catálogo ficam centralizados aqui.',
    'catalogHub.modules.products': 'Produtos',
    'catalogHub.modules.productsDescription':
        'Cadastre, revise e publique itens de venda.',
    'catalogHub.modules.services': 'Serviços',
    'catalogHub.modules.servicesDescription':
        'Organize serviços, preços e garantias.',
    'catalogHub.modules.categories': 'Categorias',
    'catalogHub.modules.categoriesDescription':
        'Agrupe produtos e serviços para facilitar a operação.',
    'catalogHub.modules.labels': 'Etiquetas',
    'catalogHub.modules.labelsDescription':
        'Crie modelos e imprima etiquetas de produtos.',
    'catalogHub.modules.virtualCatalog': 'Catálogo virtual',
    'catalogHub.modules.virtualCatalogDescription':
        'Personalize sua vitrine, publique itens e compartilhe com seus clientes.',
    'catalog.virtualCatalog.loading': 'Preparando catálogo virtual...',
    'catalogHub.stock.title': 'Disponibilidade do estoque',
    'catalogHub.stock.noIssues': 'Nenhuma indisponibilidade exige atenção.',
    'catalogHub.stock.issues':
        '{count} ocorrências precisam de atenção operacional.',
    'catalogHub.stock.openManagement': 'Abrir estoque',
    'stockMovement.entry.title': 'Registrar entrada',
    'stockMovement.exit.title': 'Registrar saída',
    'stockMovement.subtitle':
        'A movimentação será registrada com usuário, data e motivo.',
    'stockMovement.mobile.subtitle': 'Informe o item, a quantidade e o motivo.',
    'stockMovement.product': 'Produto',
    'stockMovement.unnamedProduct': 'Produto sem nome',
    'stockMovement.currentBalance': 'Saldo atual: {value}',
    'stockMovement.quantity': 'Quantidade',
    'stockMovement.unitCost': 'Custo unitário (opcional)',
    'stockMovement.reason': 'Motivo',
    'stockMovement.reasonHint':
        'Ex.: recebimento do fornecedor ou ajuste de inventário',
    'stockMovement.mobile.reasonHint':
        'Ex.: recebimento ou ajuste de inventário',
    'stockMovement.validation.product': 'Selecione um produto.',
    'stockMovement.validation.quantity':
        'Informe uma quantidade maior que zero.',
    'stockMovement.validation.cost': 'Informe um custo válido.',
    'stockMovement.validation.reason': 'Informe o motivo da movimentação.',
    'stockMovement.saving': 'Registrando...',
    'stockMovement.confirm': 'Confirmar movimentação',
    'stockMovement.success':
        'Movimentação registrada. O estoque foi atualizado.',
    'stockMovement.emptyProducts':
        'Cadastre um produto antes de movimentar o estoque.',
    'stockMovement.errors.loadProducts':
        'Não foi possível carregar os produtos.',
    'stockMovement.errors.save': 'Não foi possível registrar a movimentação.',
    'stockMovement.errors.insufficientStock':
        'A saída é maior que o saldo disponível.',
    'stockMovement.errors.permission':
        'Seu perfil não permite movimentar o estoque.',
    'stockMovement.errors.productNotFound':
        'O produto não foi encontrado neste comércio.',
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
    'atendimentoTecnico.web.loading': 'Carregando atendimentos técnicos',
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
        'Buscar por cliente, técnico, status, equipamento ou número',
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
    'atendimentoTecnico.mobile.inProgressTitle': 'Serviços em andamento',
    'atendimentoTecnico.mobile.inProgressDescription':
        'Atendimentos técnicos ativos em execução ou aguardando a próxima etapa.',
    'atendimentoTecnico.mobile.inProgressEmptyTitle':
        'Nenhum serviço em andamento no momento.',
    'atendimentoTecnico.mobile.inProgressEmptyMessage':
        'Quando um atendimento técnico ativo for criado, ele aparecerá aqui.',
    'atendimentoTecnico.mobile.inProgressErrorTitle':
        'Não foi possível consultar os serviços em andamento. Tente novamente.',
    'atendimentoTecnico.mobile.inProgressLoading':
        'Carregando serviços em andamento',
    'atendimentoTecnico.mobile.inProgressSection': 'Serviços em andamento',
    'atendimentoTecnico.mobile.inProgressFilteredSection':
        'Resultado do filtro',
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
    'atendimentoTecnico.mobile.closedTitle': 'Serviços já encerrados',
    'atendimentoTecnico.mobile.closedDescription':
        'Atendimentos técnicos entregues, cancelados ou encerrados sem reparo.',
    'atendimentoTecnico.mobile.closedEmptyTitle':
        'Nenhum serviço encerrado encontrado.',
    'atendimentoTecnico.mobile.closedEmptyMessage':
        'Quando um atendimento for entregue, cancelado ou encerrado sem reparo, ele aparecerá aqui.',
    'atendimentoTecnico.mobile.closedErrorTitle':
        'Não foi possível consultar os serviços encerrados. Tente novamente.',
    'atendimentoTecnico.mobile.closedLoading': 'Carregando serviços encerrados',
    'atendimentoTecnico.mobile.closedSection': 'Serviços encerrados',
    'atendimentoTecnico.mobile.closedFilteredSection': 'Resultado do filtro',
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
    'atendimentoTecnico.mobile.startedSuccess': 'Atendimento técnico iniciado.',
    'atendimentoTecnico.mobile.startedSuccessWithNumber':
        'Atendimento {number} iniciado.',
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
    'auth.mobileLogin.invalidCredentialsError':
        'E-mail ou senha inválidos. Verifique e tente novamente.',
    'auth.mobileLogin.genericError':
        'Não foi possível entrar agora. Tente novamente.',
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
    'auth.termsAgreement.prefix': 'Concordo com os ',
    'auth.termsOfService': 'Termos de Serviço',
    'auth.termsAgreement.suffix': ' e a Política de Privacidade.',
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
    'auth.mobileAccountCreated.heroTitle': 'Conta criada',
    'auth.mobileAccountCreated.heroSubtitle':
        'Seu espaço no SixoApp está pronto para começar.',
    'auth.mobileAccountCreated.title': 'Tudo certo!',
    'auth.mobileAccountCreated.message':
        'Sua conta foi criada com sucesso. Faça login para começar a usar o SixoApp.',
    'auth.mobileAccountCreated.loginAction': 'Ir para o login',
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
    'procedimentos.restrictedTitle': 'Ajustes restritos para este usuário',
    'procedimentos.restrictedDescription':
        'Você pode consultar os procedimentos da empresa, mas apenas administradores podem criar, editar e analisar essas configurações.',
    'procedimentos.editorRestrictedNotice':
        'Consulta liberada. Somente administradores podem salvar alterações neste procedimento.',
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
        'Traço dem…55955 tokens truncated…os?',
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
    'catalogHealth.mobile.title': 'Salud del catálogo',
    'catalogHealth.mobile.description':
        'Calidad de fotos, categorías y datos de los artículos activos.',
    'catalogHealth.mobile.pendingTitle': 'Pendientes del catálogo',
    'catalogHealth.mobile.pendingSubtitle':
        'Revise los registros que necesitan atención.',
    'catalogHealth.mobile.managementTitle': 'Gestión del catálogo',
    'catalogHealth.mobile.managementSubtitle':
        'Organización y herramientas para sus artículos.',
    'catalogHealth.mobile.categories': 'Categorías',
    'catalogHealth.mobile.categoriesDescription': 'Organizar artículos',
    'catalogHealth.mobile.labels': 'Etiquetas',
    'catalogHealth.mobile.labelsDescription': 'Modelos en Web',
    'catalogHealth.mobile.labelsWebOnly':
        'La creación e impresión de etiquetas están disponibles en la versión Web.',
    'catalogHealth.mobile.webBadge': 'WEB',
    'catalogHealth.status.critical': 'Crítico',
    'catalogHealth.status.warning': 'Atención',
    'catalogHealth.status.healthy': 'Saludable',
    'catalogHealth.status.default': 'Salud',
    'catalogHealth.metric.missingPhoto': 'Sin foto',
    'catalogHealth.metric.missingPhotoDescription':
        'Productos que necesitan una imagen.',
    'catalogHealth.metric.incompleteRegistration': 'Registro incompleto',
    'catalogHealth.metric.incompleteRegistrationDescription':
        'Artículos con información esencial pendiente.',
    'catalogHealth.metric.missingCategory': 'Sin categoría',
    'catalogHealth.metric.missingCategoryDescription':
        'Artículos que aún no están organizados.',
    'catalogHealth.metric.withoutSales': 'Sin ventas recientes',
    'catalogHealth.metric.withoutSalesDescription':
        'Productos sin movimiento de salida reciente.',
    'catalogHub.web.title': 'Productos',
    'catalogHub.web.subtitle':
        'Mejore la calidad del catálogo y acceda a artículos, categorías y etiquetas.',
    'catalogHub.list.subtitle':
        'Gestione productos, servicios, precios, imágenes y organización.',
    'catalogHub.actions.newProduct': 'Nuevo producto',
    'catalogHub.actions.newService': 'Nuevo servicio',
    'catalogHub.actions.newItem': 'Nuevo artículo',
    'catalogHub.states.noAccessTitle': 'Acceso al catálogo no disponible',
    'catalogHub.states.noAccessDescription':
        'Su perfil no puede ver el catálogo de este comercio.',
    'catalogHub.states.loadErrorTitle':
        'No se pudo cargar la salud del catálogo',
    'catalogHub.states.loadErrorDescription':
        'Las herramientas siguen disponibles. Intente actualizar el diagnóstico.',
    'catalogHub.states.emptyTitle': 'Comience su catálogo',
    'catalogHub.states.emptyDescription':
        'Cree el primer producto o servicio. La salud se calculará automáticamente.',
    'catalogHub.health.title': 'Salud del catálogo',
    'catalogHub.health.description':
        'Calidad de los registros y preparación para la venta.',
    'catalogHub.health.catalogIssues': 'Pendientes del catálogo',
    'catalogHub.health.qualityTitle': 'Calidad del registro',
    'catalogHub.health.qualitySubtitle':
        'Fotos, categorías y datos que ayudan al cliente a decidir.',
    'catalogHub.health.noQualityIssues':
        'No se encontraron pendientes de calidad.',
    'catalogHub.management.title': 'Gestión del catálogo',
    'catalogHub.management.subtitle':
        'Los registros y herramientas del catálogo se centralizan aquí.',
    'catalogHub.modules.products': 'Productos',
    'catalogHub.modules.productsDescription':
        'Cree, revise y publique artículos de venta.',
    'catalogHub.modules.services': 'Servicios',
    'catalogHub.modules.servicesDescription':
        'Organice servicios, precios y garantías.',
    'catalogHub.modules.categories': 'Categorías',
    'catalogHub.modules.categoriesDescription':
        'Agrupe productos y servicios para facilitar la operación.',
    'catalogHub.modules.labels': 'Etiquetas',
    'catalogHub.modules.labelsDescription':
        'Cree modelos e imprima etiquetas de productos.',
    'catalogHub.modules.virtualCatalog': 'Catálogo virtual',
    'catalogHub.modules.virtualCatalogDescription':
        'Personalice su vitrina, publique artículos y compártala con sus clientes.',
    'catalog.virtualCatalog.loading': 'Preparando catálogo virtual...',
    'catalogHub.stock.title': 'Disponibilidad del inventario',
    'catalogHub.stock.noIssues':
        'Ningún problema de disponibilidad requiere atención.',
    'catalogHub.stock.issues':
        '{count} incidencias necesitan atención operativa.',
    'catalogHub.stock.openManagement': 'Abrir inventario',
    'stockMovement.entry.title': 'Registrar entrada',
    'stockMovement.exit.title': 'Registrar salida',
    'stockMovement.subtitle':
        'El movimiento incluirá el usuario, la fecha y el motivo.',
    'stockMovement.mobile.subtitle':
        'Informe el artículo, la cantidad y el motivo.',
    'stockMovement.product': 'Producto',
    'stockMovement.unnamedProduct': 'Producto sin nombre',
    'stockMovement.currentBalance': 'Saldo actual: {value}',
    'stockMovement.quantity': 'Cantidad',
    'stockMovement.unitCost': 'Costo unitario (opcional)',
    'stockMovement.reason': 'Motivo',
    'stockMovement.reasonHint':
        'Ej.: recepción del proveedor o ajuste de inventario',
    'stockMovement.mobile.reasonHint': 'Ej.: recepción o ajuste de inventario',
    'stockMovement.validation.product': 'Seleccione un producto.',
    'stockMovement.validation.quantity': 'Informe una cantidad mayor que cero.',
    'stockMovement.validation.cost': 'Informe un costo válido.',
    'stockMovement.validation.reason': 'Informe el motivo del movimiento.',
    'stockMovement.saving': 'Registrando...',
    'stockMovement.confirm': 'Confirmar movimiento',
    'stockMovement.success':
        'Movimiento registrado. El inventario fue actualizado.',
    'stockMovement.emptyProducts':
        'Cree un producto antes de mover el inventario.',
    'stockMovement.errors.loadProducts': 'No se pudieron cargar los productos.',
    'stockMovement.errors.save': 'No se pudo registrar el movimiento.',
    'stockMovement.errors.insufficientStock':
        'La salida supera el saldo disponible.',
    'stockMovement.errors.permission':
        'Su perfil no permite mover el inventario.',
    'stockMovement.errors.productNotFound':
        'El producto no fue encontrado en este comercio.',
    'catalog.publicPage.title': 'Catálogo virtual',
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
        'Catálogo guardado y publicado correctamente.',
    'catalog.publicPage.saveSuccessDraft':
        'Personalización guardada. Publícala cuando esté lista.',
    'catalog.publicPage.saveError':
        'No fue posible guardar el catálogo virtual.',
    'catalog.publicPage.openError':
        'No fue posible abrir el catálogo en una nueva pestaña.',
    'catalog.publicPage.linkCopied': 'Enlace público copiado.',
    'catalog.publicPage.shareSubject': 'Catálogo de {title}',
    'catalog.publicPage.shareFallback':
        'Compartir no está disponible. Se copió el enlace público.',
    'catalog.publicPage.loadErrorTitle':
        'No fue posible cargar el catálogo virtual',
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
    'web.navigation.adminPlans': 'Planes',
    'web.navigation.financial': 'Financiero',
    'web.navigation.financial.agenda': 'Agenda financiera',
    'web.navigation.settings': 'Configuración',
    'web.navigation.reports': 'Informes',
    'web.navigation.unavailable': 'Destino no disponible en esta versión.',
    'usuariosSixo.title': 'Usuarios de Sixo',
    'usuariosSixo.subtitle':
        'Consulta todos los usuarios registrados con acceso exclusivo para el perfil SUPER.',
    'usuariosSixo.summarySemantics': 'Resumen de usuarios registrados en Sixo',
    'usuariosSixo.summaryTitle': 'Base global de usuarios',
    'usuariosSixo.summarySubtitle':
        'Consulta protegida por el perfil SUPER del token.',
    'usuariosSixo.totalLabel': 'usuarios',
    'usuariosSixo.totalRegistered': 'Usuarios registrados',
    'usuariosSixo.searchHint': 'Buscar por nombre, correo, celular o perfil',
    'usuariosSixo.resultsLabel': 'encontrados',
    'usuariosSixo.forbiddenTitle': 'Acceso exclusivo para SUPER',
    'usuariosSixo.forbiddenMessage':
        'Tu perfil no tiene permiso para consultar los usuarios de Sixo.',
    'usuariosSixo.loading': 'Cargando usuarios de Sixo',
    'usuariosSixo.loadErrorTitle': 'No fue posible cargar los usuarios',
    'usuariosSixo.loadError': 'Verifica tu conexión e inténtalo de nuevo.',
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
    'usuariosSixo.detail.loadError': 'No fue posible cargar los detalles.',
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
    'usuariosSixo.onboarding.resetTitle':
        '¿Solicitar nuevamente el onboarding?',
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
    'usuariosSixo.passwordReset.title': 'Restablecer contraseña',
    'usuariosSixo.passwordReset.subtitle':
        'Usa esta acción cuando el usuario necesite redefinir su contraseña de acceso.',
    'usuariosSixo.passwordReset.dialogTitle':
        '¿Restablecer la contraseña de este usuario?',
    'usuariosSixo.passwordReset.dialogMessage':
        'La acción se aplicará inmediatamente al usuario seleccionado.',
    'usuariosSixo.passwordReset.action': 'Restablecer contraseña',
    'usuariosSixo.passwordReset.successMessage':
        'El restablecimiento de contraseña se completó correctamente.',
    'usuariosSixo.passwordReset.errorMessage':
        'No fue posible restablecer la contraseña ahora. Inténtalo de nuevo.',
    'initialOnboarding.eyebrow': 'Configuración inicial',
    'initialOnboarding.step': 'Paso',
    'initialOnboarding.of': 'de',
    'initialOnboarding.languageTitle': 'Elige tu idioma',
    'initialOnboarding.languageSubtitle':
        'Portugués está seleccionado por defecto. Puedes cambiarlo ahora.',
    'initialOnboarding.identityTitle': 'Empecemos por lo esencial',
    'initialOnboarding.identitySubtitle':
        'Confirma tus datos para personalizar tu experiencia.',
    'initialOnboarding.identitySectionTitle': 'Tus datos',
    'initialOnboarding.businessTitle': '¿Qué hace tu negocio?',
    'initialOnboarding.businessSubtitle':
        'Esto solo organiza módulos y accesos. Podrás cambiarlo después.',
    'initialOnboarding.languageQuestion': '¿En qué idioma deseas continuar?',
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
    'initialOnboarding.userNameRequired': 'Ingresa tu nombre para continuar.',
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
    'colaboradores.firstCollaboratorTitle': 'Registra tu primer colaborador',
    'colaboradores.firstCollaboratorSubtitle':
        'Empieza agregando a quien ayudará en ventas, atención o gestión del comercio.',
    'colaboradores.noCollaboratorFoundSubtitle':
        'Intenta buscar por otro nombre, correo, celular o apodo.',
    'colaborador.invite.shareAction': 'Compartir invitación',
    'colaborador.invite.sendAction': 'Enviar invitación',
    'colaborador.invite.generateAndEmail': 'Generar y enviar por e-mail',
    'colaborador.invite.emailAction': 'Enviar directo por e-mail',
    'colaborador.invite.emailActionSubtitle':
        'La invitación se enviará al e-mail informado.',
    'colaborador.invite.shareActionSubtitle':
        'Usa WhatsApp, mensajes u otra app del dispositivo.',
    'colaborador.invite.actionTitle': 'Enviar invitación',
    'colaborador.invite.actionSubtitle':
        'Elige cómo el colaborador recibirá la invitación.',
    'colaborador.invite.sendingEmail': 'Enviando...',
    'colaborador.invite.emailSent': 'Invitación enviada por e-mail.',
    'colaborador.invite.shareSubject': 'Invitación SixoApp',
    'colaborador.invite.shareMessage':
        '¡Hola! Usa este link para aceptar la invitación de colaborador en SixoApp:\n{link}',
    'colaborador.invite.shareFallback':
        'El uso compartido no está disponible. El link fue copiado.',
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
    'workspaceHome.viewSelector': 'Seleccionar vista de inicio',
    'workspaceHome.view.operational': 'Operacional',
    'workspaceHome.view.performance': 'Desempeño',
    'performance.dashboard.teamTitle': 'Desempeño del equipo',
    'performance.dashboard.myTitle': 'Mi desempeño',
    'performance.dashboard.subtitle':
        'Metas activas, ventas, asistencias y situación de caja en un solo lugar.',
    'performance.dashboard.mobileSubtitle':
        'Metas, ventas, asistencias y caja con actualización casi en vivo.',
    'performance.dashboard.staleData':
        'Los últimos datos siguen visibles. No fue posible actualizarlos ahora.',
    'performance.dashboard.live': 'Actualización automática',
    'performance.dashboard.liveShort': 'En vivo',
    'performance.dashboard.allCollaborators': 'Todos los colaboradores',
    'performance.dashboard.selectedCollaborators': '{count} colaboradores',
    'performance.dashboard.filterTitle': 'Filtrar colaboradores',
    'performance.dashboard.filterHint': 'Selecciona uno o más colaboradores.',
    'performance.dashboard.searchCollaborators': 'Buscar colaborador',
    'performance.dashboard.noCollaboratorsFound':
        'No se encontraron colaboradores.',
    'performance.dashboard.periodFilter': 'Seleccionar período',
    'performance.dashboard.periodToday': 'Hoy',
    'performance.dashboard.period7Days': 'Últimos 7 días',
    'performance.dashboard.period30Days': 'Últimos 30 días',
    'performance.dashboard.periodMonth': 'Mes actual',
    'performance.dashboard.score': 'Desempeño',
    'performance.dashboard.activeGoals': '{count} metas activas',
    'performance.dashboard.sales': 'Ventas',
    'performance.dashboard.salesCount': '{count} ventas',
    'performance.dashboard.assistance': 'Asistencias',
    'performance.dashboard.finishedCount': '{count} finalizadas',
    'performance.dashboard.assistanceCaption': '{count} finalizadas • {amount}',
    'performance.dashboard.cash': 'Caja',
    'performance.dashboard.cashUnavailable': 'No disponible',
    'performance.dashboard.cashOpen': 'Abierta',
    'performance.dashboard.cashClosed': 'Cerrada',
    'performance.dashboard.cashCaption': 'Situación actual del comercio',
    'performance.dashboard.cashCaptionMine': 'Situación de mi caja',
    'performance.dashboard.teamComparison': 'Comparativo del equipo',
    'performance.dashboard.goalProgress': 'Progreso de las metas',
    'performance.dashboard.chartCaption':
        'Porcentaje realizado respecto al objetivo del período.',
    'performance.dashboard.chartEmpty':
        'No hay datos de metas para el gráfico.',
    'performance.dashboard.goalsTitle': 'Metas activas',
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
    'workspaceHome.quickAction.newSale': 'Ventas',
    'workspaceHome.quickAction.newTechnicalService': 'Servicios',
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
    'atendimentoTecnico.web.loading': 'Cargando servicios técnicos',
    'atendimentoTecnico.mobile.loading': 'Cargando servicios técnicos',
    'atendimentoTecnico.mobile.emptyFilteredMessage':
        'No se encontraron servicios con los filtros seleccionados.',
    'atendimentoTecnico.mobile.searchHint':
        'Buscar por cliente, técnico, estado, equipo o número',
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
    'atendimentoTecnico.mobile.inProgressTitle': 'Servicios en curso',
    'atendimentoTecnico.mobile.inProgressDescription':
        'Atenciones técnicas activas en ejecución o esperando la siguiente etapa.',
    'atendimentoTecnico.mobile.inProgressEmptyTitle':
        'No hay servicios en curso en este momento.',
    'atendimentoTecnico.mobile.inProgressEmptyMessage':
        'Cuando se cree una atención técnica activa, aparecerá aquí.',
    'atendimentoTecnico.mobile.inProgressErrorTitle':
        'No se pudieron consultar los servicios en curso. Intenta nuevamente.',
    'atendimentoTecnico.mobile.inProgressLoading':
        'Cargando servicios en curso',
    'atendimentoTecnico.mobile.inProgressSection': 'Servicios en curso',
    'atendimentoTecnico.mobile.inProgressFilteredSection':
        'Resultado del filtro',
    'atendimentoTecnico.mobile.waitingApprovalTitle':
        'Presupuestos en espera de aprobación',
    'atendimentoTecnico.mobile.waitingApprovalDescription':
        'Servicios enviados al cliente que todavía necesitan aprobación.',
    'atendimentoTecnico.mobile.waitingApprovalEmptyTitle':
        'No hay presupuestos en espera de aprobación por ahora.',
    'atendimentoTecnico.mobile.waitingApprovalEmptyMessage':
        'Cuando un presupuesto sea enviado y quede esperando la decisión del cliente, aparecerá aquí.',
    'atendimentoTecnico.mobile.waitingApprovalErrorTitle':
        'No se pudieron consultar los presupuestos. Intenta nuevamente.',
    'atendimentoTecnico.mobile.waitingApprovalLoading':
        'Cargando presupuestos en espera de aprobación',
    'atendimentoTecnico.mobile.waitingApprovalSection':
        'Presupuestos en espera de aprobación',
    'atendimentoTecnico.mobile.waitingApprovalFilteredSection':
        'Resultado del filtro',
    'atendimentoTecnico.mobile.closedTitle': 'Servicios ya cerrados',
    'atendimentoTecnico.mobile.closedDescription':
        'Atenciones técnicas entregadas, canceladas o cerradas sin reparación.',
    'atendimentoTecnico.mobile.closedEmptyTitle':
        'No se encontraron servicios cerrados.',
    'atendimentoTecnico.mobile.closedEmptyMessage':
        'Cuando una atención sea entregada, cancelada o cerrada sin reparación, aparecerá aquí.',
    'atendimentoTecnico.mobile.closedErrorTitle':
        'No se pudieron consultar los servicios cerrados. Intenta nuevamente.',
    'atendimentoTecnico.mobile.closedLoading': 'Cargando servicios cerrados',
    'atendimentoTecnico.mobile.closedSection': 'Servicios cerrados',
    'atendimentoTecnico.mobile.closedFilteredSection': 'Resultado del filtro',
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
    'atendimentoTecnico.mobile.startedSuccess': 'Atención técnica iniciada.',
    'atendimentoTecnico.mobile.startedSuccessWithNumber':
        'Atención {number} iniciada.',
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
    'auth.mobileLogin.invalidCredentialsError':
        'Correo o contraseña inválidos. Verifícalos e inténtalo de nuevo.',
    'auth.mobileLogin.genericError':
        'No pudimos iniciar sesión ahora. Inténtalo de nuevo.',
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
    'auth.termsAgreement.prefix': 'Acepto los ',
    'auth.termsOfService': 'Términos de Servicio',
    'auth.termsAgreement.suffix': ' y la Política de Privacidad.',
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
    'auth.mobileAccountCreated.heroTitle': 'Cuenta creada',
    'auth.mobileAccountCreated.heroSubtitle':
        'Tu espacio en SixoApp está listo para comenzar.',
    'auth.mobileAccountCreated.title': '¡Todo listo!',
    'auth.mobileAccountCreated.message':
        'Tu cuenta se creó correctamente. Inicia sesión para empezar a usar SixoApp.',
    'auth.mobileAccountCreated.loginAction': 'Ir al inicio de sesión',
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
    'procedimentos.restrictedTitle': 'Ajustes restringidos para este usuario',
    'procedimentos.restrictedDescription':
        'Puedes consultar los procedimientos de la empresa, pero solo los administradores pueden crear, editar y analizar estas configuraciones.',
    'procedimentos.editorRestrictedNotice':
        'La consulta está permitida. Solo los administradores pueden guardar cambios en este procedimiento.',
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
    'procedimentos.operationPointSaleFinishBefore':
        'Antes de finalizar una venta',
    'procedimentos.operationPointSaleFinishBeforeDescription':
        'Se ejecuta antes de concluir la venta en curso.',
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
    'gestao.people.sixoUsersDesc': 'Base global protegida por el perfil SUPER',
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
    'atendimento.mobile.returnsShort': 'Devoluciones',
    'atendimento.mobile.editorialSubtitle': '¿Cómo podemos ayudar hoy?',
    'atendimento.mobile.cashSummary': 'Apertura, movimientos y cierre',
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
    'atendimento.mobile.createServiceTitle': 'Servicios',
    'atendimento.mobile.createServiceSubtitle': 'Abrir nueva atención técnica',
    'atendimento.mobile.consultServicesInProgressTitle':
        'Consultar servicios en curso',
    'atendimento.mobile.consultServicesInProgressSubtitle':
        'Ver atenciones técnicas activas',
    'atendimento.mobile.closedServicesTitle': 'Servicios ya cerrados',
    'atendimento.mobile.closedServicesSubtitle':
        'Consultar atenciones técnicas cerradas',
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
    'catalogReservations.openCatalog': 'Abrir catálogo virtual',
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
