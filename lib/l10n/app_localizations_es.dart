// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'SixoApp';

  @override
  String get pdvQuickServiceDescription =>
      'Servicio rápido en caja, inclusión de artículos y cierre de venta.';

  @override
  String get aiAssistantAsk => 'Preguntar a la IA';

  @override
  String get aiAssistantHint => '¿Cómo puedo ayudarte hoy?';

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
  String get aiAssistantHowCanIHelp => '¿Cómo puedo ayudarte en SixoApp?';

  @override
  String get aiAssistantFeedbackThanks => 'Feedback registrado.';

  @override
  String get aiAssistantWelcomeTitle => '¡Hola! Soy Lis';

  @override
  String get aiAssistantWelcomeSubtitle =>
      'Estoy aquí para ayudar con tus solicitudes y resolver dudas sobre SixoApp.';

  @override
  String get aiAssistantAvatarLabel => 'Avatar de la asistente Lis';

  @override
  String get aiAssistantExpand => 'Expandir asistente';

  @override
  String get aiAssistantCollapse => 'Reducir asistente';

  @override
  String get aiAssistantFocusLabel => 'Asistente en foco';

  @override
  String get aiAssistantMinimize => 'Minimizar';

  @override
  String get aiAssistantMinimizedLabel => 'Lis minimizada';

  @override
  String get aiAssistantMinimizedTooltip => 'Abrir asistente minimizado';

  @override
  String get aiAssistantNewQuestion => 'Nueva pregunta';

  @override
  String get aiAssistantAttachUnavailable =>
      'Los adjuntos aún no están disponibles';

  @override
  String get aiAssistantSend => 'Enviar';

  @override
  String get aiAssistantThinkingTitle => 'Lis está analizando';

  @override
  String get aiAssistantThinkingSubtitle =>
      'Buscando la mejor respuesta para el contexto de esta pantalla.';

  @override
  String get pdvWebTitle => 'Frente de caja';

  @override
  String get pdvWebSessionActive => 'Sesión activa';

  @override
  String get pdvCashSessionChecking => 'Verificando sesión de caja';

  @override
  String get pdvCashSessionUnavailable => 'Sesión no disponible';

  @override
  String get pdvCashSessionNotOpen => 'Sin sesión abierta';

  @override
  String get pdvCashSessionClosed => 'Sesión cerrada';

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

  @override
  String get procedimentosTitle => 'Procedimientos';

  @override
  String get procedimentosSubtitle =>
      'Guías para ventas, atenciones y entregas';

  @override
  String get procedimentosIntroTitle =>
      'Configura orientaciones para ventas, atenciones y entregas.';

  @override
  String get procedimentosDemoData => 'Datos demostrativos';

  @override
  String get procedimentosFiltersLabel => 'Filtros de procedimientos';

  @override
  String get procedimentosFilterAll => 'Todos';

  @override
  String get procedimentosFilterActive => 'Activos';

  @override
  String get procedimentosFilterInactive => 'Inactivos';

  @override
  String get procedimentosNewProcedure => 'Nuevo procedimiento';

  @override
  String get procedimentosCreateProcedure => 'Crear procedimiento';

  @override
  String get procedimentosOpenAction => 'Abrir';

  @override
  String get procedimentosCreateUnavailable =>
      'La creación de procedimientos estará disponible en la próxima etapa.';

  @override
  String get procedimentosEditUnavailable =>
      'La edición de este procedimiento estará disponible en la próxima etapa.';

  @override
  String get procedimentosLoading => 'Cargando procedimientos';

  @override
  String get procedimentosEmptyTitle => 'Ningún procedimiento configurado';

  @override
  String get procedimentosEmptyDescription =>
      'Crea orientaciones para apoyar al equipo en los momentos importantes de la operación.';

  @override
  String get procedimentosFilteredEmptyTitle =>
      'Ningún procedimiento en este filtro';

  @override
  String get procedimentosFilteredEmptyDescription =>
      'Cambia el filtro para ver otros procedimientos demostrativos.';

  @override
  String get procedimentosErrorTitle =>
      'No fue posible cargar los procedimientos';

  @override
  String get procedimentosErrorDescription =>
      'Inténtalo nuevamente en unos instantes.';

  @override
  String get procedimentosStatusDraft => 'Borrador';

  @override
  String get procedimentosOperationSale => 'Venta';

  @override
  String get procedimentosOperationTechnicalService => 'Atención técnica';

  @override
  String get procedimentosOperationQuote => 'Presupuesto';

  @override
  String get procedimentosOperationDelivery => 'Entrega';

  @override
  String get procedimentosMomentBeforeStart => 'Antes de iniciar';

  @override
  String get procedimentosMomentBeforeFinish => 'Antes de finalizar';

  @override
  String get procedimentosMomentBeforeDelivery => 'Antes de la entrega';

  @override
  String get procedimentosStageSingular => 'etapa';

  @override
  String get procedimentosStagePlural => 'etapas';

  @override
  String get procedimentosItemSingular => 'ítem';

  @override
  String get procedimentosItemPlural => 'ítems';

  @override
  String procedimentosStageProgress(int current, int total) {
    return 'Etapa $current de $total';
  }

  @override
  String procedimentosProcedureSequence(int current, int total) {
    return 'Procedimiento $current de $total';
  }

  @override
  String procedimentosActionsCompleted(int answered, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      answered,
      locale: localeName,
      other: '$answered de $total acciones concluidas',
      one: '1 de $total acción concluida',
      zero: '0 de $total acciones concluidas',
    );
    return '$_temp0';
  }

  @override
  String procedimentosAnsweredActionsSummary(int answered, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      answered,
      locale: localeName,
      other: '$answered de $total acciones respondidas.',
      one: '1 de $total acción respondida.',
      zero: '0 de $total acciones respondidas.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosOptionalPendingSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ítems opcionales pendientes.',
      one: '1 ítem opcional pendiente.',
      zero: 'Ningún ítem opcional pendiente.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosRequiredPendingSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ítems obligatorios pendientes.',
      one: '1 ítem obligatorio pendiente.',
      zero: 'Ningún ítem obligatorio pendiente.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ítems',
      one: '1 ítem',
      zero: '0 ítems',
    );
    return '$_temp0';
  }

  @override
  String procedimentosStageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etapas',
      one: '1 etapa',
      zero: '0 etapas',
    );
    return '$_temp0';
  }

  @override
  String procedimentosStructureSummary(int stages, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      stages,
      locale: localeName,
      other: '$stages etapas',
      one: '1 etapa',
      zero: '0 etapas',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items ítems',
      one: '1 ítem',
      zero: '0 ítems',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String procedimentosStageSemantics(int order, String title, int itemCount) {
    String _temp0 = intl.Intl.pluralLogic(
      itemCount,
      locale: localeName,
      other: '$itemCount ítems',
      one: '1 ítem',
      zero: '0 ítems',
    );
    return 'Etapa $order: $title. $_temp0.';
  }

  @override
  String procedimentosExecutionItemSemantics(
    String requiredLabel,
    String title,
    String type,
  ) {
    return '$requiredLabel: $title. $type.';
  }

  @override
  String procedimentosExecutionItemStatus(String type, String requiredLabel) {
    return '$type • $requiredLabel';
  }

  @override
  String procedimentosResponseTypeSemantics(String label, String description) {
    return '$label. $description.';
  }

  @override
  String procedimentosResponseTypeSimulatedSemantics(
    String label,
    String description,
    String demoLabel,
  ) {
    return '$label. $description. $demoLabel.';
  }

  @override
  String procedimentosTriggerSemantics(
    String operation,
    String moment,
    String activation,
    String enforcement,
    String status,
  ) {
    return '$operation, $moment, $activation, $enforcement, $status';
  }

  @override
  String procedimentosTriggerSummarySingle(String operation, String moment) {
    return '$operation, $moment';
  }

  @override
  String procedimentosTriggerSummaryMultiple(String first, int remaining) {
    return '$first • +$remaining';
  }

  @override
  String procedimentosOptionNumber(int index) {
    return 'Opción $index';
  }

  @override
  String get procedimentosEditorNewTitle => 'Nuevo procedimiento';

  @override
  String get procedimentosEditorEditTitle => 'Editar procedimiento';

  @override
  String get procedimentosGeneralInfo => 'Información general';

  @override
  String get procedimentosNameField => 'Nombre';

  @override
  String get procedimentosDescriptionField => 'Descripción';

  @override
  String get procedimentosOperationContext => 'Contexto operativo';

  @override
  String get procedimentosMomentField => 'Momento';

  @override
  String get procedimentosRequireCompletion =>
      'Exigir conclusión de este procedimiento';

  @override
  String get procedimentosRequireCompletionHelp =>
      'En una integración futura, este procedimiento podrá exigir conclusión antes de continuar la operación.';

  @override
  String get procedimentosStages => 'Etapas';

  @override
  String get procedimentosAddStage => 'Agregar etapa';

  @override
  String get procedimentosEditStage => 'Editar etapa';

  @override
  String get procedimentosDeleteStage => 'Eliminar etapa';

  @override
  String get procedimentosItems => 'Ítems';

  @override
  String get procedimentosAddItem => 'Agregar ítem';

  @override
  String get procedimentosEditItem => 'Editar ítem';

  @override
  String get procedimentosDeleteItem => 'Eliminar ítem';

  @override
  String get procedimentosItemType => 'Tipo de ítem';

  @override
  String get procedimentosStageTitleField => 'Título de la etapa';

  @override
  String get procedimentosItemTitleField => 'Título o instrucción';

  @override
  String get procedimentosItemGuidanceField => 'Texto de apoyo';

  @override
  String get procedimentosSaveStage => 'Guardar etapa';

  @override
  String get procedimentosSaveItem => 'Guardar ítem';

  @override
  String get procedimentosResponseInstruction => 'Orientación';

  @override
  String get procedimentosResponseConfirmation => 'Confirmación';

  @override
  String get procedimentosResponseYesNo => 'Sí o no';

  @override
  String get procedimentosResponseInstructionDescription =>
      'Presenta una instrucción al colaborador.';

  @override
  String get procedimentosResponseConfirmationDescription =>
      'Exige que el colaborador confirme una acción.';

  @override
  String get procedimentosResponseYesNoDescription =>
      'Presenta una pregunta objetiva.';

  @override
  String get procedimentosValidationName =>
      'Ingresa el nombre del procedimiento.';

  @override
  String get procedimentosValidationReviewFields =>
      'Revisa los campos destacados antes de guardar.';

  @override
  String get procedimentosValidationAtLeastOneStage =>
      'Agrega al menos una etapa al procedimiento.';

  @override
  String get procedimentosValidationStageTitle =>
      'Ingresa el título de la etapa.';

  @override
  String get procedimentosValidationStageItem =>
      'Cada etapa debe tener al menos un ítem.';

  @override
  String get procedimentosValidationItemTitle => 'Ingresa el título del ítem.';

  @override
  String get procedimentosCreatedSuccess => 'Procedimiento creado.';

  @override
  String get procedimentosUpdatedSuccess => 'Procedimiento actualizado.';

  @override
  String get procedimentosDiscardChangesTitle => '¿Descartar cambios?';

  @override
  String get procedimentosDiscardChangesMessage =>
      'Los cambios realizados en este procedimiento aún no se han guardado.';

  @override
  String get procedimentosKeepEditing => 'Continuar editando';

  @override
  String get procedimentosDiscard => 'Descartar';

  @override
  String get procedimentosConfirmDeleteStageTitle => '¿Eliminar etapa?';

  @override
  String get procedimentosConfirmDeleteStageMessage =>
      'Los ítems de esta etapa también serán removidos.';

  @override
  String get procedimentosConfirmDeleteItemTitle => '¿Eliminar ítem?';

  @override
  String get procedimentosConfirmDeleteItemMessage =>
      'Este ítem será removido del procedimiento.';

  @override
  String get procedimentosEditorDemoNotice =>
      'Los cambios se mantendrán solo durante esta sesión.';

  @override
  String get procedimentosNoStages => 'Ninguna etapa agregada';

  @override
  String get procedimentosItemRequiredHelp =>
      'La lógica final de obligatoriedad se definirá en la integración operativa.';

  @override
  String get procedimentosPreviewAction => 'Previsualizar';

  @override
  String get procedimentosDemonstration => 'Demostración';

  @override
  String get procedimentosResponsePhoto => 'Tomar foto';

  @override
  String get procedimentosResponseSignature => 'Firma';

  @override
  String get procedimentosResponseLocation => 'Capturar ubicación';

  @override
  String get procedimentosResponseBarcode => 'Leer código de barras';

  @override
  String get procedimentosResponseImei => 'Informar IMEI';

  @override
  String get procedimentosResponseDocument => 'Adjuntar documento';

  @override
  String get procedimentosResponseAudio => 'Grabar audio';

  @override
  String get procedimentosResponseFreeText => 'Texto libre';

  @override
  String get procedimentosResponseNumber => 'Número';

  @override
  String get procedimentosResponseDate => 'Fecha';

  @override
  String get procedimentosResponseSingleChoice => 'Elección única';

  @override
  String get procedimentosResponseMultipleChoice => 'Elección múltiple';

  @override
  String get procedimentosResponsePhotoDescription =>
      'Simula la captura de una foto como evidencia.';

  @override
  String get procedimentosResponseSignatureDescription =>
      'Simula la recolección de una firma.';

  @override
  String get procedimentosResponseLocationDescription =>
      'Simula la captura de una ubicación.';

  @override
  String get procedimentosResponseBarcodeDescription =>
      'Simula la lectura de un código de barras.';

  @override
  String get procedimentosResponseImeiDescription =>
      'Permite informar un IMEI manualmente.';

  @override
  String get procedimentosResponseDocumentDescription =>
      'Simula adjuntar un documento.';

  @override
  String get procedimentosResponseAudioDescription =>
      'Simula una grabación de audio.';

  @override
  String get procedimentosResponseFreeTextDescription =>
      'Permite registrar una respuesta en texto.';

  @override
  String get procedimentosResponseNumberDescription =>
      'Permite registrar un valor numérico.';

  @override
  String get procedimentosResponseDateDescription =>
      'Permite seleccionar una fecha.';

  @override
  String get procedimentosResponseSingleChoiceDescription =>
      'Permite seleccionar una opción.';

  @override
  String get procedimentosResponseMultipleChoiceDescription =>
      'Permite seleccionar una o más opciones.';

  @override
  String get procedimentosTypeCategoryGuide => 'Orientar y confirmar';

  @override
  String get procedimentosTypeCategoryCollect => 'Recolectar información';

  @override
  String get procedimentosTypeCategoryEvidence => 'Registrar evidencia';

  @override
  String get procedimentosTypeCategoryIdentify => 'Identificar';

  @override
  String get procedimentosItemTypePickerHelp =>
      'Elige cómo el colaborador responderá o registrará esta acción.';

  @override
  String get procedimentosPlaceholderField => 'Placeholder';

  @override
  String get procedimentosUnitField => 'Unidad';

  @override
  String get procedimentosChoiceOptions => 'Opciones de elección';

  @override
  String get procedimentosAddOption => 'Agregar opción';

  @override
  String get procedimentosRemoveOption => 'Eliminar opción';

  @override
  String get procedimentosOptionField => 'Opción';

  @override
  String get procedimentosValidationChoiceOptions =>
      'Ingresa al menos dos opciones.';

  @override
  String get procedimentosChangeTypeTitle => '¿Cambiar tipo de ítem?';

  @override
  String get procedimentosChangeTypeMessage =>
      'Las opciones configuradas serán removidas para este tipo.';

  @override
  String get procedimentosSimulatedTypeEditorHelp =>
      'En modo demostración, esta captura será simulada sin usar recursos del dispositivo.';

  @override
  String get procedimentosPreviewTitle => 'Previsualización';

  @override
  String get procedimentosPreviewUntitledProcedure =>
      'Procedimiento sin nombre';

  @override
  String get procedimentosPreviewIncompleteProcedure =>
      'Este procedimiento aún no tiene etapas para demostrar.';

  @override
  String get procedimentosPreviewOf => 'de';

  @override
  String get procedimentosPreviewProgressLabel => 'Acciones concluidas';

  @override
  String get procedimentosPreviewPendingMessage =>
      'Hay acciones obligatorias pendientes en esta etapa.';

  @override
  String get procedimentosPreviewRequiredPending =>
      'Responde esta acción obligatoria para continuar.';

  @override
  String get procedimentosPreviewNextStage => 'Siguiente etapa';

  @override
  String get procedimentosPreviewFinishDemo => 'Finalizar';

  @override
  String get procedimentosPreviewReviewStages => 'Revisar etapas';

  @override
  String get procedimentosPreviewSummaryTitle => 'Demostración concluida';

  @override
  String get procedimentosPreviewSummarySavedMessage =>
      'Ninguna respuesta fue guardada.';

  @override
  String get procedimentosPreviewSummaryAnswered => 'Acciones respondidas.';

  @override
  String get procedimentosPreviewSummaryNoOptionalPending =>
      'Ningún ítem opcional pendiente.';

  @override
  String get procedimentosPreviewSummaryOptionalPending =>
      'Ítem opcional pendiente.';

  @override
  String get procedimentosPreviewDiscardTitle => '¿Descartar respuestas?';

  @override
  String get procedimentosPreviewDiscardMessage =>
      'Las respuestas de esta demostración serán descartadas al salir.';

  @override
  String get procedimentosPreviewConfirmAction => 'Confirmar acción';

  @override
  String get procedimentosPreviewUnderstood => 'Marcar como entendido';

  @override
  String get procedimentosPreviewUnderstoodDone => 'Entendido';

  @override
  String get procedimentosPreviewTextHint => 'Ingresa la respuesta';

  @override
  String get procedimentosPreviewNumberHint => 'Ingresa un número';

  @override
  String get procedimentosPreviewSelectDate => 'Seleccionar fecha';

  @override
  String get procedimentosPreviewImeiHint => 'Ingresa el IMEI';

  @override
  String get procedimentosPreviewUseDemoImei => 'Usar IMEI demostrativo';

  @override
  String get procedimentosPreviewTakePhoto => 'Tomar foto';

  @override
  String get procedimentosPreviewSimulateSignature => 'Simular firma';

  @override
  String get procedimentosPreviewCaptureLocation => 'Capturar ubicación';

  @override
  String get procedimentosPreviewSimulateBarcode => 'Simular lectura';

  @override
  String get procedimentosPreviewSimulateDocument => 'Simular anexo';

  @override
  String get procedimentosPreviewSimulateAudio => 'Simular grabación';

  @override
  String get procedimentosPreviewRemoveEvidence => 'Remover evidencia';

  @override
  String get procedimentosSimulatedResourceNotice =>
      'Recurso demostrativo. Ningún dato real será capturado.';

  @override
  String get procedimentosPreviewPhotoAdded => 'Foto agregada';

  @override
  String get procedimentosPreviewSignatureAdded => 'Firma agregada';

  @override
  String get procedimentosPreviewSignatureDemoDetail =>
      'Trazo demostrativo registrado';

  @override
  String get procedimentosPreviewLocationAdded =>
      'Ubicación de demostración capturada';

  @override
  String get procedimentosPreviewBarcodeAdded => 'Código leído';

  @override
  String get procedimentosPreviewDocumentAdded => 'Documento adjuntado';

  @override
  String get procedimentosPreviewAudioAdded => 'Audio grabado';

  @override
  String get procedimentosOperationCashRegister => 'Caja';

  @override
  String get procedimentosOperationCustomerRegistration =>
      'Registro de cliente';

  @override
  String get procedimentosTriggerMomentBeforeStart => 'Antes de iniciar';

  @override
  String get procedimentosTriggerMomentAfterStart => 'Después de iniciar';

  @override
  String get procedimentosTriggerMomentBeforeFinish => 'Antes de concluir';

  @override
  String get procedimentosTriggerMomentAfterFinish => 'Después de concluir';

  @override
  String get procedimentosTriggerMomentBeforeDelivery => 'Antes de la entrega';

  @override
  String get procedimentosTriggerMomentAfterDelivery => 'Después de la entrega';

  @override
  String get procedimentosTriggerMomentOnDemand => 'Bajo demanda';

  @override
  String get procedimentosActivationManual => 'Manual';

  @override
  String get procedimentosActivationAutomatic => 'Automático';

  @override
  String get procedimentosActivationManualDescription =>
      'El colaborador podrá iniciar este procedimiento cuando sea necesario.';

  @override
  String get procedimentosActivationAutomaticDescription =>
      'En una integración futura, el procedimiento será presentado en el momento configurado.';

  @override
  String get procedimentosEnforcementInformative => 'Informativo';

  @override
  String get procedimentosEnforcementRecommended => 'Recomendado';

  @override
  String get procedimentosEnforcementRequired => 'Obligatorio';

  @override
  String get procedimentosEnforcementInformativeDescription =>
      'Presenta el procedimiento sin exigir conclusión.';

  @override
  String get procedimentosEnforcementRecommendedDescription =>
      'Recomienda la conclusión, pero no debe bloquear la operación.';

  @override
  String get procedimentosEnforcementRequiredDescription =>
      'En una integración futura, exigirá conclusión antes de continuar.';

  @override
  String get procedimentosWhenExecute => 'Cuándo ejecutar';

  @override
  String get procedimentosAddTrigger => 'Agregar gatillo';

  @override
  String get procedimentosEditTrigger => 'Editar gatillo';

  @override
  String get procedimentosDeleteTrigger => 'Eliminar gatillo';

  @override
  String get procedimentosNoTriggers => 'Ningún gatillo configurado.';

  @override
  String get procedimentosNoTriggersDescription =>
      'Sin gatillos, el procedimiento estará disponible solo para uso y previsualización dentro de este módulo.';

  @override
  String get procedimentosTriggerCount => 'gatillos';

  @override
  String get procedimentosSelectOperationContext => 'Seleccionar contexto';

  @override
  String get procedimentosSelectTriggerMoment => 'Seleccionar momento';

  @override
  String get procedimentosActivationMode => 'Modo de ejecución';

  @override
  String get procedimentosEnforcementMode => 'Nivel de exigencia';

  @override
  String get procedimentosTriggerEnabledHelp =>
      'Controla si este gatillo será considerado en una integración futura.';

  @override
  String get procedimentosSaveTrigger => 'Guardar gatillo';

  @override
  String get procedimentosTriggerMomentCleared =>
      'El momento fue limpiado porque no es compatible con el contexto seleccionado.';

  @override
  String get procedimentosValidationTriggerOperation =>
      'Elige el contexto operativo.';

  @override
  String get procedimentosValidationTriggerMoment =>
      'Elige el momento de ejecución.';

  @override
  String get procedimentosValidationTriggerMomentInvalid =>
      'Elige un momento compatible con el contexto.';

  @override
  String get procedimentosValidationDuplicateTrigger =>
      'Ya existe un gatillo con este contexto, momento y modo de ejecución.';

  @override
  String get procedimentosDeleteTriggerTitle => '¿Eliminar gatillo?';

  @override
  String get procedimentosDeleteTriggerMessage =>
      'El procedimiento dejará de mostrarse en este momento operativo.';

  @override
  String get procedimentosTriggerSummaryNone => 'Sin gatillos configurados';

  @override
  String get procedimentosTriggerSummaryOnlyInactive => 'Gatillos inactivos';

  @override
  String get procedimentosExecutionConfiguration =>
      'Configuración de ejecución';

  @override
  String get procedimentosTriggerSimulationNotice =>
      'Simulación de gatillo. Ninguna operación real será bloqueada.';

  @override
  String get procedimentosManualDemoExecution =>
      'Ejecución manual de demostración.';

  @override
  String get procedimentosOperationPointSaleStartBefore =>
      'Antes de iniciar una venta';

  @override
  String get procedimentosOperationPointSaleStartBeforeDescription =>
      'Se ejecuta antes de abrir el flujo de una nueva venta.';

  @override
  String get procedimentosMobilePointAvailable =>
      'Disponible en la aplicación móvil.';

  @override
  String get procedimentosOperationalExecutionTitle =>
      'Antes de iniciar la venta';

  @override
  String get procedimentosOperationalSummaryTitle => 'Procedimiento concluido';

  @override
  String get procedimentosOperationalNoDataSaved =>
      'Ninguna respuesta fue guardada en esta integración local experimental.';

  @override
  String get procedimentosCompleteAndStartSale => 'Concluir e iniciar venta';

  @override
  String get procedimentosExperimentalIntegration => 'Integración experimental';

  @override
  String get procedimentosContinueToStartSale => 'Continuar a la venta';

  @override
  String get procedimentosContinueWithoutCompleting => 'Continuar sin concluir';

  @override
  String get procedimentosContinueWithoutCompletingTitle =>
      '¿Continuar sin concluir?';

  @override
  String get procedimentosContinueWithoutCompletingMessage =>
      'Este procedimiento es recomendado antes de iniciar la venta.';

  @override
  String get procedimentosContinueAnyway => 'Continuar de todos modos';

  @override
  String get procedimentosReturnToProcedure => 'Volver al procedimiento';

  @override
  String get procedimentosCancelSaleStartTitle => '¿Cancelar inicio de venta?';

  @override
  String get procedimentosCancelSaleStartMessage =>
      'Este procedimiento es obligatorio. Al salir, la nueva venta no será iniciada.';

  @override
  String get procedimentosCancelSale => 'Cancelar venta';

  @override
  String get procedimentosSequenceProgressPrefix => 'Procedimiento';

  @override
  String get procedimentosPreviewNegativeTextLabel => '¿Qué faltó?';

  @override
  String get procedimentosPreviewNegativeTextHint => 'Describe qué faltó';

  @override
  String get procedimentosOperationalLoadError =>
      'No fue posible cargar los procedimientos.';
}
