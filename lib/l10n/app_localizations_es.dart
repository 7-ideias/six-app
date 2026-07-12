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
  String get pdvWebDecreaseQuantityAction => 'Disminuir';

  @override
  String get pdvWebIncreaseQuantityAction => 'Aumentar';

  @override
  String get pdvWebRemoveItemAction => 'Eliminar';

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
}
