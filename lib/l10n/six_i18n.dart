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
    'auth.appleLoginMock': 'Login com Apple (mocked)',
    'auth.termsPrefix':
        'Ao clicar em "Continuar", declaro ter lido e concordo com os ',
    'auth.terms': 'Termos de Uso e Política de Privacidade',
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
    'auth.appleLoginMock': 'Apple sign-in (mocked)',
    'auth.termsPrefix':
        'By clicking "Continue", I confirm that I have read and agree with the ',
    'auth.terms': 'Terms of Use and Privacy Policy',
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
    'auth.appleLoginMock': 'Inicio de sesión con Apple (mocked)',
    'auth.termsPrefix':
        'Al hacer clic en "Continuar", declaro que leí y acepto los ',
    'auth.terms': 'Términos de Uso y Política de Privacidad',
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
  },
};
