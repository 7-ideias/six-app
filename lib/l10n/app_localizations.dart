import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'US'),
    Locale('es'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Six'**
  String get appTitle;

  /// No description provided for @pdvQuickServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Fast checkout service, item inclusion and sale closing.'**
  String get pdvQuickServiceDescription;

  /// No description provided for @aiAssistantAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get aiAssistantAsk;

  /// No description provided for @aiAssistantHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get aiAssistantHint;

  /// No description provided for @aiAssistantSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get aiAssistantSending;

  /// No description provided for @aiAssistantHelped.
  ///
  /// In en, this message translates to:
  /// **'Did it help?'**
  String get aiAssistantHelped;

  /// No description provided for @aiAssistantHelpedButton.
  ///
  /// In en, this message translates to:
  /// **'Helped'**
  String get aiAssistantHelpedButton;

  /// No description provided for @aiAssistantDidNotHelp.
  ///
  /// In en, this message translates to:
  /// **'Did not help'**
  String get aiAssistantDidNotHelp;

  /// No description provided for @aiAssistantExamples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get aiAssistantExamples;

  /// No description provided for @aiAssistantSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get aiAssistantSources;

  /// No description provided for @aiAssistantRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get aiAssistantRetry;

  /// No description provided for @aiAssistantError.
  ///
  /// In en, this message translates to:
  /// **'Could not get an AI answer right now.'**
  String get aiAssistantError;

  /// No description provided for @aiAssistantClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get aiAssistantClose;

  /// No description provided for @aiAssistantHowCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help in Six?'**
  String get aiAssistantHowCanIHelp;

  /// No description provided for @aiAssistantFeedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved.'**
  String get aiAssistantFeedbackThanks;

  /// No description provided for @pdvWebTitle.
  ///
  /// In en, this message translates to:
  /// **'Front desk'**
  String get pdvWebTitle;

  /// No description provided for @pdvWebSessionActive.
  ///
  /// In en, this message translates to:
  /// **'Session active'**
  String get pdvWebSessionActive;

  /// No description provided for @pdvWebStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get pdvWebStatusInProgress;

  /// No description provided for @pdvWebSearchItemAction.
  ///
  /// In en, this message translates to:
  /// **'Search item'**
  String get pdvWebSearchItemAction;

  /// No description provided for @pdvWebIdentifyCustomerAction.
  ///
  /// In en, this message translates to:
  /// **'Identify customer'**
  String get pdvWebIdentifyCustomerAction;

  /// No description provided for @pdvWebReceiveAction.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get pdvWebReceiveAction;

  /// No description provided for @pdvWebReceiveLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Receive later'**
  String get pdvWebReceiveLaterAction;

  /// No description provided for @pdvWebSalesToReceiveAction.
  ///
  /// In en, this message translates to:
  /// **'Sales to receive'**
  String get pdvWebSalesToReceiveAction;

  /// No description provided for @pdvWebExpandModeAction.
  ///
  /// In en, this message translates to:
  /// **'Expand front desk'**
  String get pdvWebExpandModeAction;

  /// No description provided for @pdvWebExitExpandedModeAction.
  ///
  /// In en, this message translates to:
  /// **'Exit expanded mode'**
  String get pdvWebExitExpandedModeAction;

  /// No description provided for @pdvWebCloseFrontDeskAction.
  ///
  /// In en, this message translates to:
  /// **'Close front desk'**
  String get pdvWebCloseFrontDeskAction;

  /// No description provided for @pdvWebCloseFrontDeskConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Close front desk?'**
  String get pdvWebCloseFrontDeskConfirmTitle;

  /// No description provided for @pdvWebCloseFrontDeskConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'There is an ongoing sale. If you close this screen, you can continue this sale later.'**
  String get pdvWebCloseFrontDeskConfirmMessage;

  /// No description provided for @pdvWebContinueSaleAction.
  ///
  /// In en, this message translates to:
  /// **'Continue sale'**
  String get pdvWebContinueSaleAction;

  /// No description provided for @pdvWebAvailableShortcutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts available'**
  String get pdvWebAvailableShortcutsLabel;

  /// No description provided for @pdvWebClearSaleAction.
  ///
  /// In en, this message translates to:
  /// **'Clear sale'**
  String get pdvWebClearSaleAction;

  /// No description provided for @pdvWebClearSaleConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear current sale?'**
  String get pdvWebClearSaleConfirmTitle;

  /// No description provided for @pdvWebClearSaleConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Items and entered data in this sale will be removed.'**
  String get pdvWebClearSaleConfirmMessage;

  /// No description provided for @pdvWebBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get pdvWebBackAction;

  /// No description provided for @pdvWebReadOrSearchToStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode or search a product to start the sale.'**
  String get pdvWebReadOrSearchToStartMessage;

  /// No description provided for @pdvWebBarcodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get pdvWebBarcodeFieldLabel;

  /// No description provided for @pdvWebFocusBarcodeFieldAction.
  ///
  /// In en, this message translates to:
  /// **'Focus input'**
  String get pdvWebFocusBarcodeFieldAction;

  /// No description provided for @pdvWebItemsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale items'**
  String get pdvWebItemsSectionTitle;

  /// No description provided for @pdvWebItemsCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get pdvWebItemsCounterLabel;

  /// No description provided for @pdvWebTableHeaderItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get pdvWebTableHeaderItem;

  /// No description provided for @pdvWebTableHeaderQuantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get pdvWebTableHeaderQuantity;

  /// No description provided for @pdvWebTableHeaderUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get pdvWebTableHeaderUnitPrice;

  /// No description provided for @pdvWebTableHeaderSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get pdvWebTableHeaderSubtotal;

  /// No description provided for @pdvWebTableHeaderActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get pdvWebTableHeaderActions;

  /// No description provided for @pdvWebItemTypeService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get pdvWebItemTypeService;

  /// No description provided for @pdvWebItemTypeProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get pdvWebItemTypeProduct;

  /// No description provided for @pdvWebCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get pdvWebCodeLabel;

  /// No description provided for @pdvWebDecreaseQuantityAction.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get pdvWebDecreaseQuantityAction;

  /// No description provided for @pdvWebIncreaseQuantityAction.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get pdvWebIncreaseQuantityAction;

  /// No description provided for @pdvWebRemoveItemAction.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get pdvWebRemoveItemAction;

  /// No description provided for @pdvWebCustomerNotInformedStatus.
  ///
  /// In en, this message translates to:
  /// **'Customer not identified'**
  String get pdvWebCustomerNotInformedStatus;

  /// No description provided for @pdvWebCustomerIdentifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Customer identified'**
  String get pdvWebCustomerIdentifiedStatus;

  /// No description provided for @pdvWebNoItemsAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'No item added'**
  String get pdvWebNoItemsAddedTitle;

  /// No description provided for @pdvWebCurrentSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Current sale'**
  String get pdvWebCurrentSaleTitle;

  /// No description provided for @pdvWebCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get pdvWebCustomerLabel;

  /// No description provided for @pdvWebPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get pdvWebPaymentLabel;

  /// No description provided for @pdvWebPaymentDefinedOnReceiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Set during receive'**
  String get pdvWebPaymentDefinedOnReceiveLabel;

  /// No description provided for @pdvWebSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get pdvWebSubtotalLabel;

  /// No description provided for @pdvWebTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get pdvWebTotalLabel;

  /// No description provided for @pdvWebReadyToStartSaleHint.
  ///
  /// In en, this message translates to:
  /// **'Scan an item to start a new sale.'**
  String get pdvWebReadyToStartSaleHint;

  /// No description provided for @pdvWebRegisteringAction.
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get pdvWebRegisteringAction;

  /// No description provided for @pdvWebClosePaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Close receive'**
  String get pdvWebClosePaymentAction;

  /// No description provided for @pdvWebCompleteRemainingAction.
  ///
  /// In en, this message translates to:
  /// **'Fill remaining'**
  String get pdvWebCompleteRemainingAction;

  /// No description provided for @pdvWebConfirmDistributionAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm distribution'**
  String get pdvWebConfirmDistributionAction;

  /// No description provided for @pdvWebConfirmReceiveAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm receive'**
  String get pdvWebConfirmReceiveAction;

  /// No description provided for @pdvWebConfirmReceiveMessagePrefix.
  ///
  /// In en, this message translates to:
  /// **'Do you want to confirm receiving in the amount of'**
  String get pdvWebConfirmReceiveMessagePrefix;

  /// No description provided for @pdvWebDefinePaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Set payment'**
  String get pdvWebDefinePaymentAction;

  /// No description provided for @pdvWebDistributedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Distributed total'**
  String get pdvWebDistributedTotalLabel;

  /// No description provided for @pdvWebEditPaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get pdvWebEditPaymentAction;

  /// No description provided for @pdvWebPaymentDefinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment set'**
  String get pdvWebPaymentDefinedLabel;

  /// No description provided for @pdvWebPaymentDistributionReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution is ready for confirmation.'**
  String get pdvWebPaymentDistributionReadyLabel;

  /// No description provided for @pdvWebPaymentDistributionReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjust values to match the sale total.'**
  String get pdvWebPaymentDistributionReviewLabel;

  /// No description provided for @pdvWebPaymentIncompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment incomplete'**
  String get pdvWebPaymentIncompleteLabel;

  /// No description provided for @pdvWebPaymentMethodsSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'methods'**
  String get pdvWebPaymentMethodsSelectedLabel;

  /// No description provided for @pdvWebPaymentMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get pdvWebPaymentMethodsTitle;

  /// No description provided for @pdvWebPaymentMismatchMessage.
  ///
  /// In en, this message translates to:
  /// **'The sum of payment methods must match the sale total.'**
  String get pdvWebPaymentMismatchMessage;

  /// No description provided for @pdvWebPaymentMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Review distribution'**
  String get pdvWebPaymentMismatchTitle;

  /// No description provided for @pdvWebPaymentNeedsReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Review distribution to match the sale total.'**
  String get pdvWebPaymentNeedsReviewHint;

  /// No description provided for @pdvWebPaymentOverlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get pdvWebPaymentOverlayTitle;

  /// No description provided for @pdvWebPaymentSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Distribution summary'**
  String get pdvWebPaymentSummaryTitle;

  /// No description provided for @pdvWebPaymentValueFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get pdvWebPaymentValueFieldLabel;

  /// No description provided for @pdvWebProcessingReceiveAction.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get pdvWebProcessingReceiveAction;

  /// No description provided for @pdvWebReceivedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Received total'**
  String get pdvWebReceivedTotalLabel;

  /// No description provided for @pdvWebRemainingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount'**
  String get pdvWebRemainingAmountLabel;

  /// No description provided for @pdvWebReviewPaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Review payment'**
  String get pdvWebReviewPaymentAction;

  /// No description provided for @pdvWebSaleTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale total'**
  String get pdvWebSaleTotalLabel;

  /// No description provided for @pdvWebSelectPaymentMethodHint.
  ///
  /// In en, this message translates to:
  /// **'Select a method to enter values.'**
  String get pdvWebSelectPaymentMethodHint;

  /// No description provided for @pdvWebSelectPaymentMethodMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one method and enter an amount to continue.'**
  String get pdvWebSelectPaymentMethodMessage;

  /// No description provided for @pdvWebSelectPaymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a payment method'**
  String get pdvWebSelectPaymentMethodTitle;

  /// No description provided for @procedimentosTitle.
  ///
  /// In en, this message translates to:
  /// **'Procedures'**
  String get procedimentosTitle;

  /// No description provided for @procedimentosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guides for sales, service and deliveries'**
  String get procedimentosSubtitle;

  /// No description provided for @procedimentosIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure guidance for sales, service and deliveries.'**
  String get procedimentosIntroTitle;

  /// No description provided for @procedimentosDemoData.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get procedimentosDemoData;

  /// No description provided for @procedimentosFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Procedure filters'**
  String get procedimentosFiltersLabel;

  /// No description provided for @procedimentosFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get procedimentosFilterAll;

  /// No description provided for @procedimentosFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get procedimentosFilterActive;

  /// No description provided for @procedimentosFilterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get procedimentosFilterInactive;

  /// No description provided for @procedimentosNewProcedure.
  ///
  /// In en, this message translates to:
  /// **'New procedure'**
  String get procedimentosNewProcedure;

  /// No description provided for @procedimentosCreateProcedure.
  ///
  /// In en, this message translates to:
  /// **'Create procedure'**
  String get procedimentosCreateProcedure;

  /// No description provided for @procedimentosOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get procedimentosOpenAction;

  /// No description provided for @procedimentosCreateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Procedure creation will be available in the next step.'**
  String get procedimentosCreateUnavailable;

  /// No description provided for @procedimentosEditUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Editing this procedure will be available in the next step.'**
  String get procedimentosEditUnavailable;

  /// No description provided for @procedimentosLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading procedures'**
  String get procedimentosLoading;

  /// No description provided for @procedimentosEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No procedures configured'**
  String get procedimentosEmptyTitle;

  /// No description provided for @procedimentosEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create guidance to support the team at key moments of the operation.'**
  String get procedimentosEmptyDescription;

  /// No description provided for @procedimentosFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No procedures in this filter'**
  String get procedimentosFilteredEmptyTitle;

  /// No description provided for @procedimentosFilteredEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Change the filter to see other demo procedures.'**
  String get procedimentosFilteredEmptyDescription;

  /// No description provided for @procedimentosErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load procedures'**
  String get procedimentosErrorTitle;

  /// No description provided for @procedimentosErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get procedimentosErrorDescription;

  /// No description provided for @procedimentosStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get procedimentosStatusDraft;

  /// No description provided for @procedimentosOperationSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get procedimentosOperationSale;

  /// No description provided for @procedimentosOperationTechnicalService.
  ///
  /// In en, this message translates to:
  /// **'Technical service'**
  String get procedimentosOperationTechnicalService;

  /// No description provided for @procedimentosOperationQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get procedimentosOperationQuote;

  /// No description provided for @procedimentosOperationDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get procedimentosOperationDelivery;

  /// No description provided for @procedimentosMomentBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Before starting'**
  String get procedimentosMomentBeforeStart;

  /// No description provided for @procedimentosMomentBeforeFinish.
  ///
  /// In en, this message translates to:
  /// **'Before finishing'**
  String get procedimentosMomentBeforeFinish;

  /// No description provided for @procedimentosMomentBeforeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Before delivery'**
  String get procedimentosMomentBeforeDelivery;

  /// No description provided for @procedimentosStageSingular.
  ///
  /// In en, this message translates to:
  /// **'stage'**
  String get procedimentosStageSingular;

  /// No description provided for @procedimentosStagePlural.
  ///
  /// In en, this message translates to:
  /// **'stages'**
  String get procedimentosStagePlural;

  /// No description provided for @procedimentosItemSingular.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get procedimentosItemSingular;

  /// No description provided for @procedimentosItemPlural.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get procedimentosItemPlural;

  /// No description provided for @procedimentosEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New procedure'**
  String get procedimentosEditorNewTitle;

  /// No description provided for @procedimentosEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit procedure'**
  String get procedimentosEditorEditTitle;

  /// No description provided for @procedimentosGeneralInfo.
  ///
  /// In en, this message translates to:
  /// **'General information'**
  String get procedimentosGeneralInfo;

  /// No description provided for @procedimentosNameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get procedimentosNameField;

  /// No description provided for @procedimentosDescriptionField.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get procedimentosDescriptionField;

  /// No description provided for @procedimentosOperationContext.
  ///
  /// In en, this message translates to:
  /// **'Operational context'**
  String get procedimentosOperationContext;

  /// No description provided for @procedimentosMomentField.
  ///
  /// In en, this message translates to:
  /// **'Moment'**
  String get procedimentosMomentField;

  /// No description provided for @procedimentosRequireCompletion.
  ///
  /// In en, this message translates to:
  /// **'Require procedure completion'**
  String get procedimentosRequireCompletion;

  /// No description provided for @procedimentosRequireCompletionHelp.
  ///
  /// In en, this message translates to:
  /// **'In a future integration, this procedure may require completion before continuing the operation.'**
  String get procedimentosRequireCompletionHelp;

  /// No description provided for @procedimentosStages.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get procedimentosStages;

  /// No description provided for @procedimentosAddStage.
  ///
  /// In en, this message translates to:
  /// **'Add stage'**
  String get procedimentosAddStage;

  /// No description provided for @procedimentosEditStage.
  ///
  /// In en, this message translates to:
  /// **'Edit stage'**
  String get procedimentosEditStage;

  /// No description provided for @procedimentosDeleteStage.
  ///
  /// In en, this message translates to:
  /// **'Delete stage'**
  String get procedimentosDeleteStage;

  /// No description provided for @procedimentosItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get procedimentosItems;

  /// No description provided for @procedimentosAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get procedimentosAddItem;

  /// No description provided for @procedimentosEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get procedimentosEditItem;

  /// No description provided for @procedimentosDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get procedimentosDeleteItem;

  /// No description provided for @procedimentosItemType.
  ///
  /// In en, this message translates to:
  /// **'Item type'**
  String get procedimentosItemType;

  /// No description provided for @procedimentosStageTitleField.
  ///
  /// In en, this message translates to:
  /// **'Stage title'**
  String get procedimentosStageTitleField;

  /// No description provided for @procedimentosItemTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title or instruction'**
  String get procedimentosItemTitleField;

  /// No description provided for @procedimentosItemGuidanceField.
  ///
  /// In en, this message translates to:
  /// **'Supporting text'**
  String get procedimentosItemGuidanceField;

  /// No description provided for @procedimentosSaveStage.
  ///
  /// In en, this message translates to:
  /// **'Save stage'**
  String get procedimentosSaveStage;

  /// No description provided for @procedimentosSaveItem.
  ///
  /// In en, this message translates to:
  /// **'Save item'**
  String get procedimentosSaveItem;

  /// No description provided for @procedimentosResponseInstruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get procedimentosResponseInstruction;

  /// No description provided for @procedimentosResponseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get procedimentosResponseConfirmation;

  /// No description provided for @procedimentosResponseYesNo.
  ///
  /// In en, this message translates to:
  /// **'Yes or no'**
  String get procedimentosResponseYesNo;

  /// No description provided for @procedimentosResponseInstructionDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows an instruction to the staff member.'**
  String get procedimentosResponseInstructionDescription;

  /// No description provided for @procedimentosResponseConfirmationDescription.
  ///
  /// In en, this message translates to:
  /// **'Requires the staff member to confirm an action.'**
  String get procedimentosResponseConfirmationDescription;

  /// No description provided for @procedimentosResponseYesNoDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows an objective question.'**
  String get procedimentosResponseYesNoDescription;

  /// No description provided for @procedimentosValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter the procedure name.'**
  String get procedimentosValidationName;

  /// No description provided for @procedimentosValidationReviewFields.
  ///
  /// In en, this message translates to:
  /// **'Review the highlighted fields before saving.'**
  String get procedimentosValidationReviewFields;

  /// No description provided for @procedimentosValidationAtLeastOneStage.
  ///
  /// In en, this message translates to:
  /// **'Add at least one stage to the procedure.'**
  String get procedimentosValidationAtLeastOneStage;

  /// No description provided for @procedimentosValidationStageTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the stage title.'**
  String get procedimentosValidationStageTitle;

  /// No description provided for @procedimentosValidationStageItem.
  ///
  /// In en, this message translates to:
  /// **'Each stage needs at least one item.'**
  String get procedimentosValidationStageItem;

  /// No description provided for @procedimentosValidationItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the item title.'**
  String get procedimentosValidationItemTitle;

  /// No description provided for @procedimentosCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Procedure created.'**
  String get procedimentosCreatedSuccess;

  /// No description provided for @procedimentosUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Procedure updated.'**
  String get procedimentosUpdatedSuccess;

  /// No description provided for @procedimentosDiscardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get procedimentosDiscardChangesTitle;

  /// No description provided for @procedimentosDiscardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'The changes made to this procedure have not been saved yet.'**
  String get procedimentosDiscardChangesMessage;

  /// No description provided for @procedimentosKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get procedimentosKeepEditing;

  /// No description provided for @procedimentosDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get procedimentosDiscard;

  /// No description provided for @procedimentosConfirmDeleteStageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete stage?'**
  String get procedimentosConfirmDeleteStageTitle;

  /// No description provided for @procedimentosConfirmDeleteStageMessage.
  ///
  /// In en, this message translates to:
  /// **'The items in this stage will also be removed.'**
  String get procedimentosConfirmDeleteStageMessage;

  /// No description provided for @procedimentosConfirmDeleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get procedimentosConfirmDeleteItemTitle;

  /// No description provided for @procedimentosConfirmDeleteItemMessage.
  ///
  /// In en, this message translates to:
  /// **'This item will be removed from the procedure.'**
  String get procedimentosConfirmDeleteItemMessage;

  /// No description provided for @procedimentosEditorDemoNotice.
  ///
  /// In en, this message translates to:
  /// **'Changes will be kept only during this session.'**
  String get procedimentosEditorDemoNotice;

  /// No description provided for @procedimentosNoStages.
  ///
  /// In en, this message translates to:
  /// **'No stages added'**
  String get procedimentosNoStages;

  /// No description provided for @procedimentosItemRequiredHelp.
  ///
  /// In en, this message translates to:
  /// **'The final required behavior will be defined in the operational integration.'**
  String get procedimentosItemRequiredHelp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
