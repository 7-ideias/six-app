// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Six';

  @override
  String get pdvQuickServiceDescription =>
      'Fast checkout service, item inclusion and sale closing.';

  @override
  String get aiAssistantAsk => 'Ask AI';

  @override
  String get aiAssistantHint => 'Type your question';

  @override
  String get aiAssistantSending => 'Sending...';

  @override
  String get aiAssistantHelped => 'Did it help?';

  @override
  String get aiAssistantHelpedButton => 'Helped';

  @override
  String get aiAssistantDidNotHelp => 'Did not help';

  @override
  String get aiAssistantExamples => 'Examples';

  @override
  String get aiAssistantSources => 'Sources';

  @override
  String get aiAssistantRetry => 'Retry';

  @override
  String get aiAssistantError => 'Could not get an AI answer right now.';

  @override
  String get aiAssistantClose => 'Close';

  @override
  String get aiAssistantHowCanIHelp => 'How can I help in Six?';

  @override
  String get aiAssistantFeedbackThanks => 'Feedback saved.';

  @override
  String get pdvWebTitle => 'Front desk';

  @override
  String get pdvWebSessionActive => 'Session active';

  @override
  String get pdvCashSessionChecking => 'Checking cash session';

  @override
  String get pdvCashSessionUnavailable => 'Session unavailable';

  @override
  String get pdvCashSessionNotOpen => 'No open session';

  @override
  String get pdvCashSessionClosed => 'Session closed';

  @override
  String get pdvWebStatusInProgress => 'In progress';

  @override
  String get pdvWebSearchItemAction => 'Search item';

  @override
  String get pdvWebIdentifyCustomerAction => 'Identify customer';

  @override
  String get pdvWebReceiveAction => 'Receive';

  @override
  String get pdvWebReceiveLaterAction => 'Receive later';

  @override
  String get pdvWebSalesToReceiveAction => 'Sales to receive';

  @override
  String get pdvWebExpandModeAction => 'Expand front desk';

  @override
  String get pdvWebExitExpandedModeAction => 'Exit expanded mode';

  @override
  String get pdvWebCloseFrontDeskAction => 'Close front desk';

  @override
  String get pdvWebCloseFrontDeskConfirmTitle => 'Close front desk?';

  @override
  String get pdvWebCloseFrontDeskConfirmMessage =>
      'There is an ongoing sale. If you close this screen, you can continue this sale later.';

  @override
  String get pdvWebContinueSaleAction => 'Continue sale';

  @override
  String get pdvWebAvailableShortcutsLabel => 'Shortcuts available';

  @override
  String get pdvWebClearSaleAction => 'Clear sale';

  @override
  String get pdvWebClearSaleConfirmTitle => 'Clear current sale?';

  @override
  String get pdvWebClearSaleConfirmMessage =>
      'Items and entered data in this sale will be removed.';

  @override
  String get pdvWebBackAction => 'Back';

  @override
  String get pdvWebReadOrSearchToStartMessage =>
      'Scan a barcode or search a product to start the sale.';

  @override
  String get pdvWebBarcodeFieldLabel => 'Barcode';

  @override
  String get pdvWebFocusBarcodeFieldAction => 'Focus input';

  @override
  String get pdvWebItemsSectionTitle => 'Sale items';

  @override
  String get pdvWebItemsCounterLabel => 'items';

  @override
  String get pdvWebTableHeaderItem => 'Item';

  @override
  String get pdvWebTableHeaderQuantity => 'Qty';

  @override
  String get pdvWebTableHeaderUnitPrice => 'Unit price';

  @override
  String get pdvWebTableHeaderSubtotal => 'Subtotal';

  @override
  String get pdvWebTableHeaderActions => 'Actions';

  @override
  String get pdvWebItemTypeService => 'Service';

  @override
  String get pdvWebItemTypeProduct => 'Product';

  @override
  String get pdvWebCodeLabel => 'Code';

  @override
  String get pdvWebDecreaseQuantityAction => 'Decrease quantity';

  @override
  String get pdvWebIncreaseQuantityAction => 'Increase quantity';

  @override
  String get pdvWebRemoveItemAction => 'Remove item';

  @override
  String get pdvWebCustomerNotInformedStatus => 'Customer not identified';

  @override
  String get pdvWebCustomerIdentifiedStatus => 'Customer identified';

  @override
  String get pdvWebNoItemsAddedTitle => 'No item added';

  @override
  String get pdvWebCurrentSaleTitle => 'Current sale';

  @override
  String get pdvWebCustomerLabel => 'Customer';

  @override
  String get pdvWebPaymentLabel => 'Payment';

  @override
  String get pdvWebPaymentDefinedOnReceiveLabel => 'Set during receive';

  @override
  String get pdvWebSubtotalLabel => 'Subtotal';

  @override
  String get pdvWebTotalLabel => 'Total';

  @override
  String get pdvWebReadyToStartSaleHint => 'Scan an item to start a new sale.';

  @override
  String get pdvWebRegisteringAction => 'Registering...';

  @override
  String get pdvWebClosePaymentAction => 'Close receive';

  @override
  String get pdvWebCompleteRemainingAction => 'Fill remaining';

  @override
  String get pdvWebConfirmDistributionAction => 'Confirm distribution';

  @override
  String get pdvWebConfirmReceiveAction => 'Confirm receive';

  @override
  String get pdvWebConfirmReceiveMessagePrefix =>
      'Do you want to confirm receiving in the amount of';

  @override
  String get pdvWebDefinePaymentAction => 'Set payment';

  @override
  String get pdvWebDistributedTotalLabel => 'Distributed total';

  @override
  String get pdvWebEditPaymentAction => 'Edit payment';

  @override
  String get pdvWebPaymentDefinedLabel => 'Payment set';

  @override
  String get pdvWebPaymentDistributionReadyLabel =>
      'Distribution is ready for confirmation.';

  @override
  String get pdvWebPaymentDistributionReviewLabel =>
      'Adjust values to match the sale total.';

  @override
  String get pdvWebPaymentIncompleteLabel => 'Payment incomplete';

  @override
  String get pdvWebPaymentMethodsSelectedLabel => 'methods';

  @override
  String get pdvWebPaymentMethodsTitle => 'Payment methods';

  @override
  String get pdvWebPaymentMismatchMessage =>
      'The sum of payment methods must match the sale total.';

  @override
  String get pdvWebPaymentMismatchTitle => 'Review distribution';

  @override
  String get pdvWebPaymentNeedsReviewHint =>
      'Review distribution to match the sale total.';

  @override
  String get pdvWebPaymentOverlayTitle => 'Receiving';

  @override
  String get pdvWebPaymentSummaryTitle => 'Distribution summary';

  @override
  String get pdvWebPaymentValueFieldLabel => 'Amount';

  @override
  String get pdvWebProcessingReceiveAction => 'Processing...';

  @override
  String get pdvWebReceivedTotalLabel => 'Received total';

  @override
  String get pdvWebRemainingAmountLabel => 'Remaining amount';

  @override
  String get pdvWebReviewPaymentAction => 'Review payment';

  @override
  String get pdvWebSaleTotalLabel => 'Sale total';

  @override
  String get pdvWebSelectPaymentMethodHint =>
      'Select a method to enter values.';

  @override
  String get pdvWebSelectPaymentMethodMessage =>
      'Choose at least one method and enter an amount to continue.';

  @override
  String get pdvWebSelectPaymentMethodTitle => 'Select a payment method';

  @override
  String get procedimentosTitle => 'Procedures';

  @override
  String get procedimentosSubtitle =>
      'Guides for sales, service and deliveries';

  @override
  String get procedimentosIntroTitle =>
      'Configure guidance for sales, service and deliveries.';

  @override
  String get procedimentosDemoData => 'Demo data';

  @override
  String get procedimentosFiltersLabel => 'Procedure filters';

  @override
  String get procedimentosFilterAll => 'All';

  @override
  String get procedimentosFilterActive => 'Active';

  @override
  String get procedimentosFilterInactive => 'Inactive';

  @override
  String get procedimentosNewProcedure => 'New procedure';

  @override
  String get procedimentosCreateProcedure => 'Create procedure';

  @override
  String get procedimentosOpenAction => 'Open';

  @override
  String get procedimentosCreateUnavailable =>
      'Procedure creation will be available in the next step.';

  @override
  String get procedimentosEditUnavailable =>
      'Editing this procedure will be available in the next step.';

  @override
  String get procedimentosLoading => 'Loading procedures';

  @override
  String get procedimentosEmptyTitle => 'No procedures configured';

  @override
  String get procedimentosEmptyDescription =>
      'Create guidance to support the team at key moments of the operation.';

  @override
  String get procedimentosFilteredEmptyTitle => 'No procedures in this filter';

  @override
  String get procedimentosFilteredEmptyDescription =>
      'Change the filter to see other demo procedures.';

  @override
  String get procedimentosErrorTitle => 'Could not load procedures';

  @override
  String get procedimentosErrorDescription => 'Try again in a moment.';

  @override
  String get procedimentosStatusDraft => 'Draft';

  @override
  String get procedimentosOperationSale => 'Sale';

  @override
  String get procedimentosOperationTechnicalService => 'Technical service';

  @override
  String get procedimentosOperationQuote => 'Quote';

  @override
  String get procedimentosOperationDelivery => 'Delivery';

  @override
  String get procedimentosMomentBeforeStart => 'Before starting';

  @override
  String get procedimentosMomentBeforeFinish => 'Before finishing';

  @override
  String get procedimentosMomentBeforeDelivery => 'Before delivery';

  @override
  String get procedimentosStageSingular => 'stage';

  @override
  String get procedimentosStagePlural => 'stages';

  @override
  String get procedimentosItemSingular => 'item';

  @override
  String get procedimentosItemPlural => 'items';

  @override
  String procedimentosStageProgress(int current, int total) {
    return 'Stage $current of $total';
  }

  @override
  String procedimentosProcedureSequence(int current, int total) {
    return 'Procedure $current of $total';
  }

  @override
  String procedimentosActionsCompleted(int answered, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      answered,
      locale: localeName,
      other: '$answered of $total actions completed',
      one: '1 of $total action completed',
      zero: '0 of $total actions completed',
    );
    return '$_temp0';
  }

  @override
  String procedimentosAnsweredActionsSummary(int answered, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      answered,
      locale: localeName,
      other: '$answered of $total actions answered.',
      one: '1 of $total action answered.',
      zero: '0 of $total actions answered.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosOptionalPendingSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count optional items pending.',
      one: '1 optional item pending.',
      zero: 'No optional items pending.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosRequiredPendingSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count required items pending.',
      one: '1 required item pending.',
      zero: 'No required items pending.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0';
  }

  @override
  String procedimentosStageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stages',
      one: '1 stage',
      zero: '0 stages',
    );
    return '$_temp0';
  }

  @override
  String procedimentosStructureSummary(int stages, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      stages,
      locale: localeName,
      other: '$stages stages',
      one: '1 stage',
      zero: '0 stages',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String procedimentosStageSemantics(int order, String title, int itemCount) {
    String _temp0 = intl.Intl.pluralLogic(
      itemCount,
      locale: localeName,
      other: '$itemCount items',
      one: '1 item',
      zero: '0 items',
    );
    return 'Stage $order: $title. $_temp0.';
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
    return 'Option $index';
  }

  @override
  String get procedimentosEditorNewTitle => 'New procedure';

  @override
  String get procedimentosEditorEditTitle => 'Edit procedure';

  @override
  String get procedimentosGeneralInfo => 'General information';

  @override
  String get procedimentosNameField => 'Name';

  @override
  String get procedimentosDescriptionField => 'Description';

  @override
  String get procedimentosOperationContext => 'Operational context';

  @override
  String get procedimentosMomentField => 'Moment';

  @override
  String get procedimentosRequireCompletion => 'Require procedure completion';

  @override
  String get procedimentosRequireCompletionHelp =>
      'In a future integration, this procedure may require completion before continuing the operation.';

  @override
  String get procedimentosStages => 'Stages';

  @override
  String get procedimentosAddStage => 'Add stage';

  @override
  String get procedimentosEditStage => 'Edit stage';

  @override
  String get procedimentosDeleteStage => 'Delete stage';

  @override
  String get procedimentosItems => 'Items';

  @override
  String get procedimentosAddItem => 'Add item';

  @override
  String get procedimentosEditItem => 'Edit item';

  @override
  String get procedimentosDeleteItem => 'Delete item';

  @override
  String get procedimentosItemType => 'Item type';

  @override
  String get procedimentosStageTitleField => 'Stage title';

  @override
  String get procedimentosItemTitleField => 'Title or instruction';

  @override
  String get procedimentosItemGuidanceField => 'Supporting text';

  @override
  String get procedimentosSaveStage => 'Save stage';

  @override
  String get procedimentosSaveItem => 'Save item';

  @override
  String get procedimentosResponseInstruction => 'Instruction';

  @override
  String get procedimentosResponseConfirmation => 'Confirmation';

  @override
  String get procedimentosResponseYesNo => 'Yes or no';

  @override
  String get procedimentosResponseInstructionDescription =>
      'Shows an instruction to the staff member.';

  @override
  String get procedimentosResponseConfirmationDescription =>
      'Requires the staff member to confirm an action.';

  @override
  String get procedimentosResponseYesNoDescription =>
      'Shows an objective question.';

  @override
  String get procedimentosValidationName => 'Enter the procedure name.';

  @override
  String get procedimentosValidationReviewFields =>
      'Review the highlighted fields before saving.';

  @override
  String get procedimentosValidationAtLeastOneStage =>
      'Add at least one stage to the procedure.';

  @override
  String get procedimentosValidationStageTitle => 'Enter the stage title.';

  @override
  String get procedimentosValidationStageItem =>
      'Each stage needs at least one item.';

  @override
  String get procedimentosValidationItemTitle => 'Enter the item title.';

  @override
  String get procedimentosCreatedSuccess => 'Procedure created.';

  @override
  String get procedimentosUpdatedSuccess => 'Procedure updated.';

  @override
  String get procedimentosDiscardChangesTitle => 'Discard changes?';

  @override
  String get procedimentosDiscardChangesMessage =>
      'The changes made to this procedure have not been saved yet.';

  @override
  String get procedimentosKeepEditing => 'Keep editing';

  @override
  String get procedimentosDiscard => 'Discard';

  @override
  String get procedimentosConfirmDeleteStageTitle => 'Delete stage?';

  @override
  String get procedimentosConfirmDeleteStageMessage =>
      'The items in this stage will also be removed.';

  @override
  String get procedimentosConfirmDeleteItemTitle => 'Delete item?';

  @override
  String get procedimentosConfirmDeleteItemMessage =>
      'This item will be removed from the procedure.';

  @override
  String get procedimentosEditorDemoNotice =>
      'Changes will be kept only during this session.';

  @override
  String get procedimentosNoStages => 'No stages added';

  @override
  String get procedimentosItemRequiredHelp =>
      'The final required behavior will be defined in the operational integration.';

  @override
  String get procedimentosPreviewAction => 'Preview';

  @override
  String get procedimentosDemonstration => 'Demo';

  @override
  String get procedimentosResponsePhoto => 'Take photo';

  @override
  String get procedimentosResponseSignature => 'Signature';

  @override
  String get procedimentosResponseLocation => 'Capture location';

  @override
  String get procedimentosResponseBarcode => 'Read barcode';

  @override
  String get procedimentosResponseImei => 'Enter IMEI';

  @override
  String get procedimentosResponseDocument => 'Attach document';

  @override
  String get procedimentosResponseAudio => 'Record audio';

  @override
  String get procedimentosResponseFreeText => 'Free text';

  @override
  String get procedimentosResponseNumber => 'Number';

  @override
  String get procedimentosResponseDate => 'Date';

  @override
  String get procedimentosResponseSingleChoice => 'Single choice';

  @override
  String get procedimentosResponseMultipleChoice => 'Multiple choice';

  @override
  String get procedimentosResponsePhotoDescription =>
      'Simulates capturing a photo as evidence.';

  @override
  String get procedimentosResponseSignatureDescription =>
      'Simulates collecting a signature.';

  @override
  String get procedimentosResponseLocationDescription =>
      'Simulates capturing a location.';

  @override
  String get procedimentosResponseBarcodeDescription =>
      'Simulates reading a barcode.';

  @override
  String get procedimentosResponseImeiDescription =>
      'Allows entering an IMEI manually.';

  @override
  String get procedimentosResponseDocumentDescription =>
      'Simulates attaching a document.';

  @override
  String get procedimentosResponseAudioDescription =>
      'Simulates an audio recording.';

  @override
  String get procedimentosResponseFreeTextDescription =>
      'Allows recording a text response.';

  @override
  String get procedimentosResponseNumberDescription =>
      'Allows recording a numeric value.';

  @override
  String get procedimentosResponseDateDescription => 'Allows selecting a date.';

  @override
  String get procedimentosResponseSingleChoiceDescription =>
      'Allows selecting one option.';

  @override
  String get procedimentosResponseMultipleChoiceDescription =>
      'Allows selecting one or more options.';

  @override
  String get procedimentosTypeCategoryGuide => 'Guide and confirm';

  @override
  String get procedimentosTypeCategoryCollect => 'Collect information';

  @override
  String get procedimentosTypeCategoryEvidence => 'Record evidence';

  @override
  String get procedimentosTypeCategoryIdentify => 'Identify';

  @override
  String get procedimentosItemTypePickerHelp =>
      'Choose how the staff member will respond to or record this action.';

  @override
  String get procedimentosPlaceholderField => 'Placeholder';

  @override
  String get procedimentosUnitField => 'Unit';

  @override
  String get procedimentosChoiceOptions => 'Choice options';

  @override
  String get procedimentosAddOption => 'Add option';

  @override
  String get procedimentosRemoveOption => 'Remove option';

  @override
  String get procedimentosOptionField => 'Option';

  @override
  String get procedimentosValidationChoiceOptions =>
      'Enter at least two options.';

  @override
  String get procedimentosChangeTypeTitle => 'Change item type?';

  @override
  String get procedimentosChangeTypeMessage =>
      'The configured options will be removed for this type.';

  @override
  String get procedimentosSimulatedTypeEditorHelp =>
      'In demo mode, this capture will be simulated without using device resources.';

  @override
  String get procedimentosPreviewTitle => 'Preview';

  @override
  String get procedimentosPreviewUntitledProcedure => 'Untitled procedure';

  @override
  String get procedimentosPreviewIncompleteProcedure =>
      'This procedure does not have stages to demonstrate yet.';

  @override
  String get procedimentosPreviewOf => 'of';

  @override
  String get procedimentosPreviewProgressLabel => 'Completed actions';

  @override
  String get procedimentosPreviewPendingMessage =>
      'There are required actions pending in this stage.';

  @override
  String get procedimentosPreviewRequiredPending =>
      'Answer this required action to continue.';

  @override
  String get procedimentosPreviewNextStage => 'Next stage';

  @override
  String get procedimentosPreviewFinishDemo => 'Finish';

  @override
  String get procedimentosPreviewReviewStages => 'Review stages';

  @override
  String get procedimentosPreviewSummaryTitle => 'Demo completed';

  @override
  String get procedimentosPreviewSummarySavedMessage =>
      'No response was saved.';

  @override
  String get procedimentosPreviewSummaryAnswered => 'Answered actions.';

  @override
  String get procedimentosPreviewSummaryNoOptionalPending =>
      'No optional items pending.';

  @override
  String get procedimentosPreviewSummaryOptionalPending =>
      'Optional item pending.';

  @override
  String get procedimentosPreviewDiscardTitle => 'Discard responses?';

  @override
  String get procedimentosPreviewDiscardMessage =>
      'The responses from this demo will be discarded when leaving.';

  @override
  String get procedimentosPreviewConfirmAction => 'Confirm action';

  @override
  String get procedimentosPreviewUnderstood => 'Mark as understood';

  @override
  String get procedimentosPreviewUnderstoodDone => 'Understood';

  @override
  String get procedimentosPreviewTextHint => 'Enter the response';

  @override
  String get procedimentosPreviewNumberHint => 'Enter a number';

  @override
  String get procedimentosPreviewSelectDate => 'Select date';

  @override
  String get procedimentosPreviewImeiHint => 'Enter IMEI';

  @override
  String get procedimentosPreviewUseDemoImei => 'Use demo IMEI';

  @override
  String get procedimentosPreviewTakePhoto => 'Take photo';

  @override
  String get procedimentosPreviewSimulateSignature => 'Simulate signature';

  @override
  String get procedimentosPreviewCaptureLocation => 'Capture location';

  @override
  String get procedimentosPreviewSimulateBarcode => 'Simulate reading';

  @override
  String get procedimentosPreviewSimulateDocument => 'Simulate attachment';

  @override
  String get procedimentosPreviewSimulateAudio => 'Simulate recording';

  @override
  String get procedimentosPreviewRemoveEvidence => 'Remove evidence';

  @override
  String get procedimentosSimulatedResourceNotice =>
      'Demo resource. No real data will be captured.';

  @override
  String get procedimentosPreviewPhotoAdded => 'Photo added';

  @override
  String get procedimentosPreviewSignatureAdded => 'Signature added';

  @override
  String get procedimentosPreviewSignatureDemoDetail => 'Demo stroke recorded';

  @override
  String get procedimentosPreviewLocationAdded => 'Demo location captured';

  @override
  String get procedimentosPreviewBarcodeAdded => 'Code read';

  @override
  String get procedimentosPreviewDocumentAdded => 'Document attached';

  @override
  String get procedimentosPreviewAudioAdded => 'Audio recorded';

  @override
  String get procedimentosOperationCashRegister => 'Cash register';

  @override
  String get procedimentosOperationCustomerRegistration =>
      'Customer registration';

  @override
  String get procedimentosTriggerMomentBeforeStart => 'Before starting';

  @override
  String get procedimentosTriggerMomentAfterStart => 'After starting';

  @override
  String get procedimentosTriggerMomentBeforeFinish => 'Before completing';

  @override
  String get procedimentosTriggerMomentAfterFinish => 'After completing';

  @override
  String get procedimentosTriggerMomentBeforeDelivery => 'Before delivery';

  @override
  String get procedimentosTriggerMomentAfterDelivery => 'After delivery';

  @override
  String get procedimentosTriggerMomentOnDemand => 'On demand';

  @override
  String get procedimentosActivationManual => 'Manual';

  @override
  String get procedimentosActivationAutomatic => 'Automatic';

  @override
  String get procedimentosActivationManualDescription =>
      'The staff member can start this procedure when needed.';

  @override
  String get procedimentosActivationAutomaticDescription =>
      'In a future integration, the procedure will be shown at the configured moment.';

  @override
  String get procedimentosEnforcementInformative => 'Informative';

  @override
  String get procedimentosEnforcementRecommended => 'Recommended';

  @override
  String get procedimentosEnforcementRequired => 'Required';

  @override
  String get procedimentosEnforcementInformativeDescription =>
      'Shows the procedure without requiring completion.';

  @override
  String get procedimentosEnforcementRecommendedDescription =>
      'Recommends completion, but should not block the operation.';

  @override
  String get procedimentosEnforcementRequiredDescription =>
      'In a future integration, it will require completion before continuing.';

  @override
  String get procedimentosWhenExecute => 'When to execute';

  @override
  String get procedimentosAddTrigger => 'Add trigger';

  @override
  String get procedimentosEditTrigger => 'Edit trigger';

  @override
  String get procedimentosDeleteTrigger => 'Delete trigger';

  @override
  String get procedimentosNoTriggers => 'No triggers configured.';

  @override
  String get procedimentosNoTriggersDescription =>
      'Without triggers, the procedure will only be available for use and preview inside this module.';

  @override
  String get procedimentosTriggerCount => 'triggers';

  @override
  String get procedimentosSelectOperationContext => 'Select context';

  @override
  String get procedimentosSelectTriggerMoment => 'Select moment';

  @override
  String get procedimentosActivationMode => 'Execution mode';

  @override
  String get procedimentosEnforcementMode => 'Enforcement level';

  @override
  String get procedimentosTriggerEnabledHelp =>
      'Controls whether this trigger will be considered in a future integration.';

  @override
  String get procedimentosSaveTrigger => 'Save trigger';

  @override
  String get procedimentosTriggerMomentCleared =>
      'The moment was cleared because it is not compatible with the selected context.';

  @override
  String get procedimentosValidationTriggerOperation =>
      'Choose the operational context.';

  @override
  String get procedimentosValidationTriggerMoment =>
      'Choose the execution moment.';

  @override
  String get procedimentosValidationTriggerMomentInvalid =>
      'Choose a moment compatible with the context.';

  @override
  String get procedimentosValidationDuplicateTrigger =>
      'A trigger with this context, moment and execution mode already exists.';

  @override
  String get procedimentosDeleteTriggerTitle => 'Delete trigger?';

  @override
  String get procedimentosDeleteTriggerMessage =>
      'The procedure will no longer be shown at this operational moment.';

  @override
  String get procedimentosTriggerSummaryNone => 'No triggers configured';

  @override
  String get procedimentosTriggerSummaryOnlyInactive => 'Inactive triggers';

  @override
  String get procedimentosExecutionConfiguration => 'Execution configuration';

  @override
  String get procedimentosTriggerSimulationNotice =>
      'Trigger simulation. No real operation will be blocked.';

  @override
  String get procedimentosManualDemoExecution => 'Manual demo execution.';

  @override
  String get procedimentosOperationPointSaleStartBefore =>
      'Before starting a sale';

  @override
  String get procedimentosOperationPointSaleStartBeforeDescription =>
      'Runs before opening the new sale flow.';

  @override
  String get procedimentosMobilePointAvailable =>
      'Available in the mobile app.';

  @override
  String get procedimentosOperationalExecutionTitle =>
      'Before starting the sale';

  @override
  String get procedimentosOperationalSummaryTitle => 'Procedure completed';

  @override
  String get procedimentosOperationalNoDataSaved =>
      'No response was saved in this local experimental integration.';

  @override
  String get procedimentosCompleteAndStartSale => 'Complete and start sale';

  @override
  String get procedimentosExperimentalIntegration => 'Experimental integration';

  @override
  String get procedimentosContinueToStartSale => 'Continue to sale';

  @override
  String get procedimentosContinueWithoutCompleting =>
      'Continue without completing';

  @override
  String get procedimentosContinueWithoutCompletingTitle =>
      'Continue without completing?';

  @override
  String get procedimentosContinueWithoutCompletingMessage =>
      'This procedure is recommended before starting the sale.';

  @override
  String get procedimentosContinueAnyway => 'Continue anyway';

  @override
  String get procedimentosReturnToProcedure => 'Return to procedure';

  @override
  String get procedimentosCancelSaleStartTitle => 'Cancel sale start?';

  @override
  String get procedimentosCancelSaleStartMessage =>
      'This procedure is required. If you leave, the new sale will not be started.';

  @override
  String get procedimentosCancelSale => 'Cancel sale';

  @override
  String get procedimentosSequenceProgressPrefix => 'Procedure';

  @override
  String get procedimentosPreviewNegativeTextLabel => 'What was missing?';

  @override
  String get procedimentosPreviewNegativeTextHint =>
      'Describe what was missing';

  @override
  String get procedimentosOperationalLoadError => 'Could not load procedures.';
}

/// The translations for English, as used in the United States (`en_US`).
class AppLocalizationsEnUs extends AppLocalizationsEn {
  AppLocalizationsEnUs() : super('en_US');

  @override
  String get appTitle => 'Six';

  @override
  String get aiAssistantAsk => 'Ask AI';

  @override
  String get aiAssistantHint => 'Type your question';

  @override
  String get aiAssistantSending => 'Sending...';

  @override
  String get aiAssistantHelped => 'Did it help?';

  @override
  String get aiAssistantHelpedButton => 'Helped';

  @override
  String get aiAssistantDidNotHelp => 'Did not help';

  @override
  String get aiAssistantExamples => 'Examples';

  @override
  String get aiAssistantSources => 'Sources';

  @override
  String get aiAssistantRetry => 'Retry';

  @override
  String get aiAssistantError => 'Could not get an AI answer right now.';

  @override
  String get aiAssistantClose => 'Close';

  @override
  String get aiAssistantHowCanIHelp => 'How can I help in Six?';

  @override
  String get aiAssistantFeedbackThanks => 'Feedback saved.';

  @override
  String get procedimentosTitle => 'Procedures';

  @override
  String get procedimentosSubtitle =>
      'Guides for sales, service and deliveries';

  @override
  String get procedimentosIntroTitle =>
      'Configure guidance for sales, service and deliveries.';

  @override
  String get procedimentosDemoData => 'Demo data';

  @override
  String get procedimentosFiltersLabel => 'Procedure filters';

  @override
  String get procedimentosFilterAll => 'All';

  @override
  String get procedimentosFilterActive => 'Active';

  @override
  String get procedimentosFilterInactive => 'Inactive';

  @override
  String get procedimentosNewProcedure => 'New procedure';

  @override
  String get procedimentosCreateProcedure => 'Create procedure';

  @override
  String get procedimentosOpenAction => 'Open';

  @override
  String get procedimentosCreateUnavailable =>
      'Procedure creation will be available in the next step.';

  @override
  String get procedimentosEditUnavailable =>
      'Editing this procedure will be available in the next step.';

  @override
  String get procedimentosLoading => 'Loading procedures';

  @override
  String get procedimentosEmptyTitle => 'No procedures configured';

  @override
  String get procedimentosEmptyDescription =>
      'Create guidance to support the team at key moments of the operation.';

  @override
  String get procedimentosFilteredEmptyTitle => 'No procedures in this filter';

  @override
  String get procedimentosFilteredEmptyDescription =>
      'Change the filter to see other demo procedures.';

  @override
  String get procedimentosErrorTitle => 'Could not load procedures';

  @override
  String get procedimentosErrorDescription => 'Try again in a moment.';

  @override
  String get procedimentosStatusDraft => 'Draft';

  @override
  String get procedimentosOperationSale => 'Sale';

  @override
  String get procedimentosOperationTechnicalService => 'Technical service';

  @override
  String get procedimentosOperationQuote => 'Quote';

  @override
  String get procedimentosOperationDelivery => 'Delivery';

  @override
  String get procedimentosMomentBeforeStart => 'Before starting';

  @override
  String get procedimentosMomentBeforeFinish => 'Before finishing';

  @override
  String get procedimentosMomentBeforeDelivery => 'Before delivery';

  @override
  String get procedimentosStageSingular => 'stage';

  @override
  String get procedimentosStagePlural => 'stages';

  @override
  String get procedimentosItemSingular => 'item';

  @override
  String get procedimentosItemPlural => 'items';

  @override
  String procedimentosStageProgress(int current, int total) {
    return 'Stage $current of $total';
  }

  @override
  String procedimentosProcedureSequence(int current, int total) {
    return 'Procedure $current of $total';
  }

  @override
  String procedimentosActionsCompleted(int answered, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      answered,
      locale: localeName,
      other: '$answered of $total actions completed',
      one: '1 of $total action completed',
      zero: '0 of $total actions completed',
    );
    return '$_temp0';
  }

  @override
  String procedimentosAnsweredActionsSummary(int answered, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      answered,
      locale: localeName,
      other: '$answered of $total actions answered.',
      one: '1 of $total action answered.',
      zero: '0 of $total actions answered.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosOptionalPendingSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count optional items pending.',
      one: '1 optional item pending.',
      zero: 'No optional items pending.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosRequiredPendingSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count required items pending.',
      one: '1 required item pending.',
      zero: 'No required items pending.',
    );
    return '$_temp0';
  }

  @override
  String procedimentosItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0';
  }

  @override
  String procedimentosStageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stages',
      one: '1 stage',
      zero: '0 stages',
    );
    return '$_temp0';
  }

  @override
  String procedimentosStructureSummary(int stages, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      stages,
      locale: localeName,
      other: '$stages stages',
      one: '1 stage',
      zero: '0 stages',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String procedimentosStageSemantics(int order, String title, int itemCount) {
    String _temp0 = intl.Intl.pluralLogic(
      itemCount,
      locale: localeName,
      other: '$itemCount items',
      one: '1 item',
      zero: '0 items',
    );
    return 'Stage $order: $title. $_temp0.';
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
    return 'Option $index';
  }

  @override
  String get procedimentosEditorNewTitle => 'New procedure';

  @override
  String get procedimentosEditorEditTitle => 'Edit procedure';

  @override
  String get procedimentosGeneralInfo => 'General information';

  @override
  String get procedimentosNameField => 'Name';

  @override
  String get procedimentosDescriptionField => 'Description';

  @override
  String get procedimentosOperationContext => 'Operational context';

  @override
  String get procedimentosMomentField => 'Moment';

  @override
  String get procedimentosRequireCompletion => 'Require procedure completion';

  @override
  String get procedimentosRequireCompletionHelp =>
      'In a future integration, this procedure may require completion before continuing the operation.';

  @override
  String get procedimentosStages => 'Stages';

  @override
  String get procedimentosAddStage => 'Add stage';

  @override
  String get procedimentosEditStage => 'Edit stage';

  @override
  String get procedimentosDeleteStage => 'Delete stage';

  @override
  String get procedimentosItems => 'Items';

  @override
  String get procedimentosAddItem => 'Add item';

  @override
  String get procedimentosEditItem => 'Edit item';

  @override
  String get procedimentosDeleteItem => 'Delete item';

  @override
  String get procedimentosItemType => 'Item type';

  @override
  String get procedimentosStageTitleField => 'Stage title';

  @override
  String get procedimentosItemTitleField => 'Title or instruction';

  @override
  String get procedimentosItemGuidanceField => 'Supporting text';

  @override
  String get procedimentosSaveStage => 'Save stage';

  @override
  String get procedimentosSaveItem => 'Save item';

  @override
  String get procedimentosResponseInstruction => 'Instruction';

  @override
  String get procedimentosResponseConfirmation => 'Confirmation';

  @override
  String get procedimentosResponseYesNo => 'Yes or no';

  @override
  String get procedimentosResponseInstructionDescription =>
      'Shows an instruction to the staff member.';

  @override
  String get procedimentosResponseConfirmationDescription =>
      'Requires the staff member to confirm an action.';

  @override
  String get procedimentosResponseYesNoDescription =>
      'Shows an objective question.';

  @override
  String get procedimentosValidationName => 'Enter the procedure name.';

  @override
  String get procedimentosValidationReviewFields =>
      'Review the highlighted fields before saving.';

  @override
  String get procedimentosValidationAtLeastOneStage =>
      'Add at least one stage to the procedure.';

  @override
  String get procedimentosValidationStageTitle => 'Enter the stage title.';

  @override
  String get procedimentosValidationStageItem =>
      'Each stage needs at least one item.';

  @override
  String get procedimentosValidationItemTitle => 'Enter the item title.';

  @override
  String get procedimentosCreatedSuccess => 'Procedure created.';

  @override
  String get procedimentosUpdatedSuccess => 'Procedure updated.';

  @override
  String get procedimentosDiscardChangesTitle => 'Discard changes?';

  @override
  String get procedimentosDiscardChangesMessage =>
      'The changes made to this procedure have not been saved yet.';

  @override
  String get procedimentosKeepEditing => 'Keep editing';

  @override
  String get procedimentosDiscard => 'Discard';

  @override
  String get procedimentosConfirmDeleteStageTitle => 'Delete stage?';

  @override
  String get procedimentosConfirmDeleteStageMessage =>
      'The items in this stage will also be removed.';

  @override
  String get procedimentosConfirmDeleteItemTitle => 'Delete item?';

  @override
  String get procedimentosConfirmDeleteItemMessage =>
      'This item will be removed from the procedure.';

  @override
  String get procedimentosEditorDemoNotice =>
      'Changes will be kept only during this session.';

  @override
  String get procedimentosNoStages => 'No stages added';

  @override
  String get procedimentosItemRequiredHelp =>
      'The final required behavior will be defined in the operational integration.';

  @override
  String get procedimentosPreviewAction => 'Preview';

  @override
  String get procedimentosDemonstration => 'Demo';

  @override
  String get procedimentosResponsePhoto => 'Take photo';

  @override
  String get procedimentosResponseSignature => 'Signature';

  @override
  String get procedimentosResponseLocation => 'Capture location';

  @override
  String get procedimentosResponseBarcode => 'Read barcode';

  @override
  String get procedimentosResponseImei => 'Enter IMEI';

  @override
  String get procedimentosResponseDocument => 'Attach document';

  @override
  String get procedimentosResponseAudio => 'Record audio';

  @override
  String get procedimentosResponseFreeText => 'Free text';

  @override
  String get procedimentosResponseNumber => 'Number';

  @override
  String get procedimentosResponseDate => 'Date';

  @override
  String get procedimentosResponseSingleChoice => 'Single choice';

  @override
  String get procedimentosResponseMultipleChoice => 'Multiple choice';

  @override
  String get procedimentosResponsePhotoDescription =>
      'Simulates capturing a photo as evidence.';

  @override
  String get procedimentosResponseSignatureDescription =>
      'Simulates collecting a signature.';

  @override
  String get procedimentosResponseLocationDescription =>
      'Simulates capturing a location.';

  @override
  String get procedimentosResponseBarcodeDescription =>
      'Simulates reading a barcode.';

  @override
  String get procedimentosResponseImeiDescription =>
      'Allows entering an IMEI manually.';

  @override
  String get procedimentosResponseDocumentDescription =>
      'Simulates attaching a document.';

  @override
  String get procedimentosResponseAudioDescription =>
      'Simulates an audio recording.';

  @override
  String get procedimentosResponseFreeTextDescription =>
      'Allows recording a text response.';

  @override
  String get procedimentosResponseNumberDescription =>
      'Allows recording a numeric value.';

  @override
  String get procedimentosResponseDateDescription => 'Allows selecting a date.';

  @override
  String get procedimentosResponseSingleChoiceDescription =>
      'Allows selecting one option.';

  @override
  String get procedimentosResponseMultipleChoiceDescription =>
      'Allows selecting one or more options.';

  @override
  String get procedimentosTypeCategoryGuide => 'Guide and confirm';

  @override
  String get procedimentosTypeCategoryCollect => 'Collect information';

  @override
  String get procedimentosTypeCategoryEvidence => 'Record evidence';

  @override
  String get procedimentosTypeCategoryIdentify => 'Identify';

  @override
  String get procedimentosItemTypePickerHelp =>
      'Choose how the staff member will respond to or record this action.';

  @override
  String get procedimentosPlaceholderField => 'Placeholder';

  @override
  String get procedimentosUnitField => 'Unit';

  @override
  String get procedimentosChoiceOptions => 'Choice options';

  @override
  String get procedimentosAddOption => 'Add option';

  @override
  String get procedimentosRemoveOption => 'Remove option';

  @override
  String get procedimentosOptionField => 'Option';

  @override
  String get procedimentosValidationChoiceOptions =>
      'Enter at least two options.';

  @override
  String get procedimentosChangeTypeTitle => 'Change item type?';

  @override
  String get procedimentosChangeTypeMessage =>
      'The configured options will be removed for this type.';

  @override
  String get procedimentosSimulatedTypeEditorHelp =>
      'In demo mode, this capture will be simulated without using device resources.';

  @override
  String get procedimentosPreviewTitle => 'Preview';

  @override
  String get procedimentosPreviewUntitledProcedure => 'Untitled procedure';

  @override
  String get procedimentosPreviewIncompleteProcedure =>
      'This procedure does not have stages to demonstrate yet.';

  @override
  String get procedimentosPreviewOf => 'of';

  @override
  String get procedimentosPreviewProgressLabel => 'Completed actions';

  @override
  String get procedimentosPreviewPendingMessage =>
      'There are required actions pending in this stage.';

  @override
  String get procedimentosPreviewRequiredPending =>
      'Answer this required action to continue.';

  @override
  String get procedimentosPreviewNextStage => 'Next stage';

  @override
  String get procedimentosPreviewFinishDemo => 'Finish';

  @override
  String get procedimentosPreviewReviewStages => 'Review stages';

  @override
  String get procedimentosPreviewSummaryTitle => 'Demo completed';

  @override
  String get procedimentosPreviewSummarySavedMessage =>
      'No response was saved.';

  @override
  String get procedimentosPreviewSummaryAnswered => 'Answered actions.';

  @override
  String get procedimentosPreviewSummaryNoOptionalPending =>
      'No optional items pending.';

  @override
  String get procedimentosPreviewSummaryOptionalPending =>
      'Optional item pending.';

  @override
  String get procedimentosPreviewDiscardTitle => 'Discard responses?';

  @override
  String get procedimentosPreviewDiscardMessage =>
      'The responses from this demo will be discarded when leaving.';

  @override
  String get procedimentosPreviewConfirmAction => 'Confirm action';

  @override
  String get procedimentosPreviewUnderstood => 'Mark as understood';

  @override
  String get procedimentosPreviewUnderstoodDone => 'Understood';

  @override
  String get procedimentosPreviewTextHint => 'Enter the response';

  @override
  String get procedimentosPreviewNumberHint => 'Enter a number';

  @override
  String get procedimentosPreviewSelectDate => 'Select date';

  @override
  String get procedimentosPreviewImeiHint => 'Enter IMEI';

  @override
  String get procedimentosPreviewUseDemoImei => 'Use demo IMEI';

  @override
  String get procedimentosPreviewTakePhoto => 'Take photo';

  @override
  String get procedimentosPreviewSimulateSignature => 'Simulate signature';

  @override
  String get procedimentosPreviewCaptureLocation => 'Capture location';

  @override
  String get procedimentosPreviewSimulateBarcode => 'Simulate reading';

  @override
  String get procedimentosPreviewSimulateDocument => 'Simulate attachment';

  @override
  String get procedimentosPreviewSimulateAudio => 'Simulate recording';

  @override
  String get procedimentosPreviewRemoveEvidence => 'Remove evidence';

  @override
  String get procedimentosSimulatedResourceNotice =>
      'Demo resource. No real data will be captured.';

  @override
  String get procedimentosPreviewPhotoAdded => 'Photo added';

  @override
  String get procedimentosPreviewSignatureAdded => 'Signature added';

  @override
  String get procedimentosPreviewSignatureDemoDetail => 'Demo stroke recorded';

  @override
  String get procedimentosPreviewLocationAdded => 'Demo location captured';

  @override
  String get procedimentosPreviewBarcodeAdded => 'Code read';

  @override
  String get procedimentosPreviewDocumentAdded => 'Document attached';

  @override
  String get procedimentosPreviewAudioAdded => 'Audio recorded';

  @override
  String get procedimentosOperationCashRegister => 'Cash register';

  @override
  String get procedimentosOperationCustomerRegistration =>
      'Customer registration';

  @override
  String get procedimentosTriggerMomentBeforeStart => 'Before starting';

  @override
  String get procedimentosTriggerMomentAfterStart => 'After starting';

  @override
  String get procedimentosTriggerMomentBeforeFinish => 'Before completing';

  @override
  String get procedimentosTriggerMomentAfterFinish => 'After completing';

  @override
  String get procedimentosTriggerMomentBeforeDelivery => 'Before delivery';

  @override
  String get procedimentosTriggerMomentAfterDelivery => 'After delivery';

  @override
  String get procedimentosTriggerMomentOnDemand => 'On demand';

  @override
  String get procedimentosActivationManual => 'Manual';

  @override
  String get procedimentosActivationAutomatic => 'Automatic';

  @override
  String get procedimentosActivationManualDescription =>
      'The staff member can start this procedure when needed.';

  @override
  String get procedimentosActivationAutomaticDescription =>
      'In a future integration, the procedure will be shown at the configured moment.';

  @override
  String get procedimentosEnforcementInformative => 'Informative';

  @override
  String get procedimentosEnforcementRecommended => 'Recommended';

  @override
  String get procedimentosEnforcementRequired => 'Required';

  @override
  String get procedimentosEnforcementInformativeDescription =>
      'Shows the procedure without requiring completion.';

  @override
  String get procedimentosEnforcementRecommendedDescription =>
      'Recommends completion, but should not block the operation.';

  @override
  String get procedimentosEnforcementRequiredDescription =>
      'In a future integration, it will require completion before continuing.';

  @override
  String get procedimentosWhenExecute => 'When to execute';

  @override
  String get procedimentosAddTrigger => 'Add trigger';

  @override
  String get procedimentosEditTrigger => 'Edit trigger';

  @override
  String get procedimentosDeleteTrigger => 'Delete trigger';

  @override
  String get procedimentosNoTriggers => 'No triggers configured.';

  @override
  String get procedimentosNoTriggersDescription =>
      'Without triggers, the procedure will only be available for use and preview inside this module.';

  @override
  String get procedimentosTriggerCount => 'triggers';

  @override
  String get procedimentosSelectOperationContext => 'Select context';

  @override
  String get procedimentosSelectTriggerMoment => 'Select moment';

  @override
  String get procedimentosActivationMode => 'Execution mode';

  @override
  String get procedimentosEnforcementMode => 'Enforcement level';

  @override
  String get procedimentosTriggerEnabledHelp =>
      'Controls whether this trigger will be considered in a future integration.';

  @override
  String get procedimentosSaveTrigger => 'Save trigger';

  @override
  String get procedimentosTriggerMomentCleared =>
      'The moment was cleared because it is not compatible with the selected context.';

  @override
  String get procedimentosValidationTriggerOperation =>
      'Choose the operational context.';

  @override
  String get procedimentosValidationTriggerMoment =>
      'Choose the execution moment.';

  @override
  String get procedimentosValidationTriggerMomentInvalid =>
      'Choose a moment compatible with the context.';

  @override
  String get procedimentosValidationDuplicateTrigger =>
      'A trigger with this context, moment and execution mode already exists.';

  @override
  String get procedimentosDeleteTriggerTitle => 'Delete trigger?';

  @override
  String get procedimentosDeleteTriggerMessage =>
      'The procedure will no longer be shown at this operational moment.';

  @override
  String get procedimentosTriggerSummaryNone => 'No triggers configured';

  @override
  String get procedimentosTriggerSummaryOnlyInactive => 'Inactive triggers';

  @override
  String get procedimentosExecutionConfiguration => 'Execution configuration';

  @override
  String get procedimentosTriggerSimulationNotice =>
      'Trigger simulation. No real operation will be blocked.';

  @override
  String get procedimentosManualDemoExecution => 'Manual demo execution.';

  @override
  String get procedimentosOperationPointSaleStartBefore =>
      'Before starting a sale';

  @override
  String get procedimentosOperationPointSaleStartBeforeDescription =>
      'Runs before opening the new sale flow.';

  @override
  String get procedimentosMobilePointAvailable =>
      'Available in the mobile app.';

  @override
  String get procedimentosOperationalExecutionTitle =>
      'Before starting the sale';

  @override
  String get procedimentosOperationalSummaryTitle => 'Procedure completed';

  @override
  String get procedimentosOperationalNoDataSaved =>
      'No response was saved in this local experimental integration.';

  @override
  String get procedimentosCompleteAndStartSale => 'Complete and start sale';

  @override
  String get procedimentosExperimentalIntegration => 'Experimental integration';

  @override
  String get procedimentosContinueToStartSale => 'Continue to sale';

  @override
  String get procedimentosContinueWithoutCompleting =>
      'Continue without completing';

  @override
  String get procedimentosContinueWithoutCompletingTitle =>
      'Continue without completing?';

  @override
  String get procedimentosContinueWithoutCompletingMessage =>
      'This procedure is recommended before starting the sale.';

  @override
  String get procedimentosContinueAnyway => 'Continue anyway';

  @override
  String get procedimentosReturnToProcedure => 'Return to procedure';

  @override
  String get procedimentosCancelSaleStartTitle => 'Cancel sale start?';

  @override
  String get procedimentosCancelSaleStartMessage =>
      'This procedure is required. If you leave, the new sale will not be started.';

  @override
  String get procedimentosCancelSale => 'Cancel sale';

  @override
  String get procedimentosSequenceProgressPrefix => 'Procedure';

  @override
  String get procedimentosPreviewNegativeTextLabel => 'What was missing?';

  @override
  String get procedimentosPreviewNegativeTextHint =>
      'Describe what was missing';

  @override
  String get procedimentosOperationalLoadError => 'Could not load procedures.';
}
