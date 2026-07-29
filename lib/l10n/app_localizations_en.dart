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
}
