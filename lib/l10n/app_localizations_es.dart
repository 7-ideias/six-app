// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Six';

  @override
  String get pdvQuickServiceDescription =>
      'Servicio rápido en caja, inclusión de artículos y cierre de venta.';

  @override
  String get aiAssistantAsk => 'Preguntar a la IA';

  @override
  String get aiAssistantHint => 'Escribe tu duda';

  @override
  String get aiAssistantSending => 'Enviando...';

  @override
  String get aiAssistantHelped => '¿Ayudó?';

  @override
  String get aiAssistantHelpedButton => 'Ayudó';

  @override
  String get aiAssistantDidNotHelp => 'No ayudó';

  @override
  String get aiAssistantExamples => 'Ejemplos';

  @override
  String get aiAssistantSources => 'Fuentes';

  @override
  String get aiAssistantRetry => 'Reintentar';

  @override
  String get aiAssistantError =>
      'No fue posible obtener respuesta de IA ahora.';

  @override
  String get aiAssistantClose => 'Cerrar';

  @override
  String get aiAssistantHowCanIHelp => '¿Cómo puedo ayudarte en Six?';

  @override
  String get aiAssistantFeedbackThanks => 'Feedback registrado.';

  @override
  String get pdvWebTitle => 'Frente de caja';

  @override
  String get pdvWebSessionActive => 'Sesión activa';

  @override
  String get pdvWebStatusInProgress => 'En curso';

  @override
  String get pdvWebSearchItemAction => 'Buscar artículo';

  @override
  String get pdvWebIdentifyCustomerAction => 'Identificar cliente';

  @override
  String get pdvWebReceiveAction => 'Cobrar';

  @override
  String get pdvWebReceiveLaterAction => 'Cobrar después';

  @override
  String get pdvWebSalesToReceiveAction => 'Ventas por cobrar';

  @override
  String get pdvWebExpandModeAction => 'Expandir frente de caja';

  @override
  String get pdvWebExitExpandedModeAction => 'Salir del modo expandido';

  @override
  String get pdvWebCloseFrontDeskAction => 'Cerrar frente de caja';

  @override
  String get pdvWebCloseFrontDeskConfirmTitle => '¿Cerrar frente de caja?';

  @override
  String get pdvWebCloseFrontDeskConfirmMessage =>
      'Hay una venta en curso. Si cierras esta pantalla, podrás continuar esta venta más tarde.';

  @override
  String get pdvWebContinueSaleAction => 'Continuar venta';

  @override
  String get pdvWebAvailableShortcutsLabel => 'Atajos disponibles';

  @override
  String get pdvWebClearSaleAction => 'Limpiar venta';

  @override
  String get pdvWebClearSaleConfirmTitle => '¿Limpiar venta actual?';

  @override
  String get pdvWebClearSaleConfirmMessage =>
      'Se eliminarán los artículos y los datos completados de esta venta.';

  @override
  String get pdvWebBackAction => 'Volver';

  @override
  String get pdvWebReadOrSearchToStartMessage =>
      'Lee un código de barras o busca un producto para iniciar la venta.';

  @override
  String get pdvWebBarcodeFieldLabel => 'Código de barras';

  @override
  String get pdvWebFocusBarcodeFieldAction => 'Enfocar lectura';

  @override
  String get pdvWebItemsSectionTitle => 'Artículos de la venta';

  @override
  String get pdvWebItemsCounterLabel => 'artículos';

  @override
  String get pdvWebTableHeaderItem => 'Artículo';

  @override
  String get pdvWebTableHeaderQuantity => 'Cant.';

  @override
  String get pdvWebTableHeaderUnitPrice => 'Unitario';

  @override
  String get pdvWebTableHeaderSubtotal => 'Subtotal';

  @override
  String get pdvWebTableHeaderActions => 'Acciones';

  @override
  String get pdvWebItemTypeService => 'Servicio';

  @override
  String get pdvWebItemTypeProduct => 'Producto';

  @override
  String get pdvWebCodeLabel => 'Código';

  @override
  String get pdvWebDecreaseQuantityAction => 'Disminuir cantidad';

  @override
  String get pdvWebIncreaseQuantityAction => 'Aumentar cantidad';

  @override
  String get pdvWebRemoveItemAction => 'Eliminar artículo';

  @override
  String get pdvWebCustomerNotInformedStatus => 'Cliente no informado';

  @override
  String get pdvWebCustomerIdentifiedStatus => 'Cliente identificado';

  @override
  String get pdvWebNoItemsAddedTitle => 'Ningún artículo agregado';

  @override
  String get pdvWebCurrentSaleTitle => 'Venta actual';

  @override
  String get pdvWebCustomerLabel => 'Cliente';

  @override
  String get pdvWebPaymentLabel => 'Pago';

  @override
  String get pdvWebPaymentDefinedOnReceiveLabel => 'Definir al cobrar';

  @override
  String get pdvWebSubtotalLabel => 'Subtotal';

  @override
  String get pdvWebTotalLabel => 'Total';

  @override
  String get pdvWebReadyToStartSaleHint =>
      'Lee un artículo para iniciar una nueva venta.';

  @override
  String get pdvWebRegisteringAction => 'Registrando...';

  @override
  String get pdvWebClosePaymentAction => 'Cerrar cobro';

  @override
  String get pdvWebCompleteRemainingAction => 'Completar restante';

  @override
  String get pdvWebConfirmDistributionAction => 'Confirmar distribución';

  @override
  String get pdvWebConfirmReceiveAction => 'Confirmar cobro';

  @override
  String get pdvWebConfirmReceiveMessagePrefix =>
      '¿Deseas confirmar el cobro por';

  @override
  String get pdvWebDefinePaymentAction => 'Definir pago';

  @override
  String get pdvWebDistributedTotalLabel => 'Total distribuido';

  @override
  String get pdvWebEditPaymentAction => 'Editar pago';

  @override
  String get pdvWebPaymentDefinedLabel => 'Pago definido';

  @override
  String get pdvWebPaymentDistributionReadyLabel =>
      'Distribución lista para confirmar.';

  @override
  String get pdvWebPaymentDistributionReviewLabel =>
      'Ajusta los valores para cerrar el total de la venta.';

  @override
  String get pdvWebPaymentIncompleteLabel => 'Pago incompleto';

  @override
  String get pdvWebPaymentMethodsSelectedLabel => 'formas';

  @override
  String get pdvWebPaymentMethodsTitle => 'Formas de cobro';

  @override
  String get pdvWebPaymentMismatchMessage =>
      'La suma de las formas debe coincidir con el total de la venta.';

  @override
  String get pdvWebPaymentMismatchTitle => 'Revisar distribución';

  @override
  String get pdvWebPaymentNeedsReviewHint =>
      'Revisa la distribución para cerrar el total de la venta.';

  @override
  String get pdvWebPaymentOverlayTitle => 'Cobro';

  @override
  String get pdvWebPaymentSummaryTitle => 'Resumen de distribución';

  @override
  String get pdvWebPaymentValueFieldLabel => 'Valor';

  @override
  String get pdvWebProcessingReceiveAction => 'Procesando...';

  @override
  String get pdvWebReceivedTotalLabel => 'Total recibido';

  @override
  String get pdvWebRemainingAmountLabel => 'Valor restante';

  @override
  String get pdvWebReviewPaymentAction => 'Revisar pago';

  @override
  String get pdvWebSaleTotalLabel => 'Total de la venta';

  @override
  String get pdvWebSelectPaymentMethodHint =>
      'Selecciona una forma para informar valores.';

  @override
  String get pdvWebSelectPaymentMethodMessage =>
      'Elige al menos una forma e informa un valor para continuar.';

  @override
  String get pdvWebSelectPaymentMethodTitle => 'Selecciona una forma de cobro';
}
