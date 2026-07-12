// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Six';

  @override
  String get pdvQuickServiceDescription =>
      'Atendimento rápido no caixa, inclusão de itens e fechamento da venda.';

  @override
  String get aiAssistantAsk => 'Perguntar à IA';

  @override
  String get aiAssistantHint => 'Digite sua dúvida';

  @override
  String get aiAssistantSending => 'Enviando...';

  @override
  String get aiAssistantHelped => 'Ajudou?';

  @override
  String get aiAssistantHelpedButton => 'Ajudou';

  @override
  String get aiAssistantDidNotHelp => 'Não ajudou';

  @override
  String get aiAssistantExamples => 'Exemplos';

  @override
  String get aiAssistantSources => 'Fontes';

  @override
  String get aiAssistantRetry => 'Tentar novamente';

  @override
  String get aiAssistantError => 'Não foi possível obter resposta da IA agora.';

  @override
  String get aiAssistantClose => 'Fechar';

  @override
  String get aiAssistantHowCanIHelp => 'Como posso ajudar no Six?';

  @override
  String get aiAssistantFeedbackThanks => 'Feedback registrado.';

  @override
  String get pdvWebTitle => 'Frente de caixa';

  @override
  String get pdvWebSessionActive => 'Sessão ativa';

  @override
  String get pdvWebStatusInProgress => 'Em andamento';

  @override
  String get pdvWebSearchItemAction => 'Buscar item';

  @override
  String get pdvWebIdentifyCustomerAction => 'Identificar cliente';

  @override
  String get pdvWebReceiveAction => 'Receber';

  @override
  String get pdvWebReceiveLaterAction => 'Receber depois';

  @override
  String get pdvWebSalesToReceiveAction => 'Vendas a receber';

  @override
  String get pdvWebExpandModeAction => 'Expandir frente de caixa';

  @override
  String get pdvWebExitExpandedModeAction => 'Sair do modo expandido';

  @override
  String get pdvWebClearSaleAction => 'Limpar venda';

  @override
  String get pdvWebClearSaleConfirmTitle => 'Limpar venda atual?';

  @override
  String get pdvWebClearSaleConfirmMessage =>
      'Os itens e dados preenchidos nesta venda serão removidos.';

  @override
  String get pdvWebBackAction => 'Voltar';

  @override
  String get pdvWebReadOrSearchToStartMessage =>
      'Leia um código de barras ou busque um produto para iniciar a venda.';

  @override
  String get pdvWebBarcodeFieldLabel => 'Código de barras';

  @override
  String get pdvWebFocusBarcodeFieldAction => 'Focar leitura';

  @override
  String get pdvWebItemsSectionTitle => 'Itens da venda';

  @override
  String get pdvWebItemsCounterLabel => 'itens';

  @override
  String get pdvWebTableHeaderItem => 'Item';

  @override
  String get pdvWebTableHeaderQuantity => 'Qtd';

  @override
  String get pdvWebTableHeaderUnitPrice => 'Unitário';

  @override
  String get pdvWebTableHeaderSubtotal => 'Subtotal';

  @override
  String get pdvWebTableHeaderActions => 'Ações';

  @override
  String get pdvWebItemTypeService => 'Serviço';

  @override
  String get pdvWebItemTypeProduct => 'Produto';

  @override
  String get pdvWebCodeLabel => 'Código';

  @override
  String get pdvWebDecreaseQuantityAction => 'Diminuir';

  @override
  String get pdvWebIncreaseQuantityAction => 'Aumentar';

  @override
  String get pdvWebRemoveItemAction => 'Remover';

  @override
  String get pdvWebNoItemsAddedTitle => 'Nenhum item adicionado';

  @override
  String get pdvWebCurrentSaleTitle => 'Venda atual';

  @override
  String get pdvWebCustomerLabel => 'Cliente';

  @override
  String get pdvWebPaymentLabel => 'Pagamento';

  @override
  String get pdvWebPaymentDefinedOnReceiveLabel => 'Definir no recebimento';

  @override
  String get pdvWebSubtotalLabel => 'Subtotal';

  @override
  String get pdvWebTotalLabel => 'Total';

  @override
  String get pdvWebReadyToStartSaleHint =>
      'Leia um item para iniciar uma nova venda.';

  @override
  String get pdvWebRegisteringAction => 'Registrando...';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'Six';

  @override
  String get aiAssistantAsk => 'Perguntar à IA';

  @override
  String get aiAssistantHint => 'Digite sua dúvida';

  @override
  String get aiAssistantSending => 'Enviando...';

  @override
  String get aiAssistantHelped => 'Ajudou?';

  @override
  String get aiAssistantHelpedButton => 'Ajudou';

  @override
  String get aiAssistantDidNotHelp => 'Não ajudou';

  @override
  String get aiAssistantExamples => 'Exemplos';

  @override
  String get aiAssistantSources => 'Fontes';

  @override
  String get aiAssistantRetry => 'Tentar novamente';

  @override
  String get aiAssistantError => 'Não foi possível obter resposta da IA agora.';

  @override
  String get aiAssistantClose => 'Fechar';

  @override
  String get aiAssistantHowCanIHelp => 'Como posso ajudar no Six?';

  @override
  String get aiAssistantFeedbackThanks => 'Feedback registrado.';
}
