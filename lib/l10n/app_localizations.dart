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
  /// **'SixoApp'**
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
  /// **'How can I help today?'**
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
  /// **'How can I help in SixoApp?'**
  String get aiAssistantHowCanIHelp;

  /// No description provided for @aiAssistantFeedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved.'**
  String get aiAssistantFeedbackThanks;

  /// No description provided for @aiAssistantWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m Lis'**
  String get aiAssistantWelcomeTitle;

  /// No description provided for @aiAssistantWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m here to help with your requests and answer questions about SixoApp.'**
  String get aiAssistantWelcomeSubtitle;

  /// No description provided for @aiAssistantAvatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Assistant Lis avatar'**
  String get aiAssistantAvatarLabel;

  /// No description provided for @aiAssistantExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand assistant'**
  String get aiAssistantExpand;

  /// No description provided for @aiAssistantCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse assistant'**
  String get aiAssistantCollapse;

  /// No description provided for @aiAssistantFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Assistant in focus'**
  String get aiAssistantFocusLabel;

  /// No description provided for @aiAssistantMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get aiAssistantMinimize;

  /// No description provided for @aiAssistantMinimizedLabel.
  ///
  /// In en, this message translates to:
  /// **'Lis minimized'**
  String get aiAssistantMinimizedLabel;

  /// No description provided for @aiAssistantMinimizedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open minimized assistant'**
  String get aiAssistantMinimizedTooltip;

  /// No description provided for @aiAssistantNewQuestion.
  ///
  /// In en, this message translates to:
  /// **'New question'**
  String get aiAssistantNewQuestion;

  /// No description provided for @aiAssistantAttachUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Attachments are not available yet'**
  String get aiAssistantAttachUnavailable;

  /// No description provided for @aiAssistantSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiAssistantSend;

  /// No description provided for @aiAssistantThinkingTitle.
  ///
  /// In en, this message translates to:
  /// **'Lis is analyzing'**
  String get aiAssistantThinkingTitle;

  /// No description provided for @aiAssistantThinkingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finding the best answer for this screen context.'**
  String get aiAssistantThinkingSubtitle;

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

  /// No description provided for @pdvCashSessionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking cash session'**
  String get pdvCashSessionChecking;

  /// No description provided for @pdvCashSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable'**
  String get pdvCashSessionUnavailable;

  /// No description provided for @pdvCashSessionNotOpen.
  ///
  /// In en, this message translates to:
  /// **'No open session'**
  String get pdvCashSessionNotOpen;

  /// No description provided for @pdvCashSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Session closed'**
  String get pdvCashSessionClosed;

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

  /// No description provided for @procedimentosStageProgress.
  ///
  /// In en, this message translates to:
  /// **'Stage {current} of {total}'**
  String procedimentosStageProgress(int current, int total);

  /// No description provided for @procedimentosProcedureSequence.
  ///
  /// In en, this message translates to:
  /// **'Procedure {current} of {total}'**
  String procedimentosProcedureSequence(int current, int total);

  /// No description provided for @procedimentosActionsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{answered, plural, =0{0 of {total} actions completed} =1{1 of {total} action completed} other{{answered} of {total} actions completed}}'**
  String procedimentosActionsCompleted(int answered, int total);

  /// No description provided for @procedimentosAnsweredActionsSummary.
  ///
  /// In en, this message translates to:
  /// **'{answered, plural, =0{0 of {total} actions answered.} =1{1 of {total} action answered.} other{{answered} of {total} actions answered.}}'**
  String procedimentosAnsweredActionsSummary(int answered, int total);

  /// No description provided for @procedimentosOptionalPendingSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No optional items pending.} =1{1 optional item pending.} other{{count} optional items pending.}}'**
  String procedimentosOptionalPendingSummary(int count);

  /// No description provided for @procedimentosRequiredPendingSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No required items pending.} =1{1 required item pending.} other{{count} required items pending.}}'**
  String procedimentosRequiredPendingSummary(int count);

  /// No description provided for @procedimentosItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 items} =1{1 item} other{{count} items}}'**
  String procedimentosItemCount(int count);

  /// No description provided for @procedimentosStageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 stages} =1{1 stage} other{{count} stages}}'**
  String procedimentosStageCount(int count);

  /// No description provided for @procedimentosStructureSummary.
  ///
  /// In en, this message translates to:
  /// **'{stages, plural, =0{0 stages} =1{1 stage} other{{stages} stages}} • {items, plural, =0{0 items} =1{1 item} other{{items} items}}'**
  String procedimentosStructureSummary(int stages, int items);

  /// No description provided for @procedimentosStageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Stage {order}: {title}. {itemCount, plural, =0{0 items} =1{1 item} other{{itemCount} items}}.'**
  String procedimentosStageSemantics(int order, String title, int itemCount);

  /// No description provided for @procedimentosExecutionItemSemantics.
  ///
  /// In en, this message translates to:
  /// **'{requiredLabel}: {title}. {type}.'**
  String procedimentosExecutionItemSemantics(
    String requiredLabel,
    String title,
    String type,
  );

  /// No description provided for @procedimentosExecutionItemStatus.
  ///
  /// In en, this message translates to:
  /// **'{type} • {requiredLabel}'**
  String procedimentosExecutionItemStatus(String type, String requiredLabel);

  /// No description provided for @procedimentosResponseTypeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}. {description}.'**
  String procedimentosResponseTypeSemantics(String label, String description);

  /// No description provided for @procedimentosResponseTypeSimulatedSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}. {description}. {demoLabel}.'**
  String procedimentosResponseTypeSimulatedSemantics(
    String label,
    String description,
    String demoLabel,
  );

  /// No description provided for @procedimentosTriggerSemantics.
  ///
  /// In en, this message translates to:
  /// **'{operation}, {moment}, {activation}, {enforcement}, {status}'**
  String procedimentosTriggerSemantics(
    String operation,
    String moment,
    String activation,
    String enforcement,
    String status,
  );

  /// No description provided for @procedimentosTriggerSummarySingle.
  ///
  /// In en, this message translates to:
  /// **'{operation}, {moment}'**
  String procedimentosTriggerSummarySingle(String operation, String moment);

  /// No description provided for @procedimentosTriggerSummaryMultiple.
  ///
  /// In en, this message translates to:
  /// **'{first} • +{remaining}'**
  String procedimentosTriggerSummaryMultiple(String first, int remaining);

  /// No description provided for @procedimentosOptionNumber.
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String procedimentosOptionNumber(int index);

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

  /// No description provided for @procedimentosPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get procedimentosPreviewAction;

  /// No description provided for @procedimentosDemonstration.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get procedimentosDemonstration;

  /// No description provided for @procedimentosResponsePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get procedimentosResponsePhoto;

  /// No description provided for @procedimentosResponseSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get procedimentosResponseSignature;

  /// No description provided for @procedimentosResponseLocation.
  ///
  /// In en, this message translates to:
  /// **'Capture location'**
  String get procedimentosResponseLocation;

  /// No description provided for @procedimentosResponseBarcode.
  ///
  /// In en, this message translates to:
  /// **'Read barcode'**
  String get procedimentosResponseBarcode;

  /// No description provided for @procedimentosResponseImei.
  ///
  /// In en, this message translates to:
  /// **'Enter IMEI'**
  String get procedimentosResponseImei;

  /// No description provided for @procedimentosResponseDocument.
  ///
  /// In en, this message translates to:
  /// **'Attach document'**
  String get procedimentosResponseDocument;

  /// No description provided for @procedimentosResponseAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get procedimentosResponseAudio;

  /// No description provided for @procedimentosResponseFreeText.
  ///
  /// In en, this message translates to:
  /// **'Free text'**
  String get procedimentosResponseFreeText;

  /// No description provided for @procedimentosResponseNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get procedimentosResponseNumber;

  /// No description provided for @procedimentosResponseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get procedimentosResponseDate;

  /// No description provided for @procedimentosResponseSingleChoice.
  ///
  /// In en, this message translates to:
  /// **'Single choice'**
  String get procedimentosResponseSingleChoice;

  /// No description provided for @procedimentosResponseMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get procedimentosResponseMultipleChoice;

  /// No description provided for @procedimentosResponsePhotoDescription.
  ///
  /// In en, this message translates to:
  /// **'Simulates capturing a photo as evidence.'**
  String get procedimentosResponsePhotoDescription;

  /// No description provided for @procedimentosResponseSignatureDescription.
  ///
  /// In en, this message translates to:
  /// **'Simulates collecting a signature.'**
  String get procedimentosResponseSignatureDescription;

  /// No description provided for @procedimentosResponseLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Simulates capturing a location.'**
  String get procedimentosResponseLocationDescription;

  /// No description provided for @procedimentosResponseBarcodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Simulates reading a barcode.'**
  String get procedimentosResponseBarcodeDescription;

  /// No description provided for @procedimentosResponseImeiDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows entering an IMEI manually.'**
  String get procedimentosResponseImeiDescription;

  /// No description provided for @procedimentosResponseDocumentDescription.
  ///
  /// In en, this message translates to:
  /// **'Simulates attaching a document.'**
  String get procedimentosResponseDocumentDescription;

  /// No description provided for @procedimentosResponseAudioDescription.
  ///
  /// In en, this message translates to:
  /// **'Simulates an audio recording.'**
  String get procedimentosResponseAudioDescription;

  /// No description provided for @procedimentosResponseFreeTextDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows recording a text response.'**
  String get procedimentosResponseFreeTextDescription;

  /// No description provided for @procedimentosResponseNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows recording a numeric value.'**
  String get procedimentosResponseNumberDescription;

  /// No description provided for @procedimentosResponseDateDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows selecting a date.'**
  String get procedimentosResponseDateDescription;

  /// No description provided for @procedimentosResponseSingleChoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows selecting one option.'**
  String get procedimentosResponseSingleChoiceDescription;

  /// No description provided for @procedimentosResponseMultipleChoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows selecting one or more options.'**
  String get procedimentosResponseMultipleChoiceDescription;

  /// No description provided for @procedimentosTypeCategoryGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide and confirm'**
  String get procedimentosTypeCategoryGuide;

  /// No description provided for @procedimentosTypeCategoryCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect information'**
  String get procedimentosTypeCategoryCollect;

  /// No description provided for @procedimentosTypeCategoryEvidence.
  ///
  /// In en, this message translates to:
  /// **'Record evidence'**
  String get procedimentosTypeCategoryEvidence;

  /// No description provided for @procedimentosTypeCategoryIdentify.
  ///
  /// In en, this message translates to:
  /// **'Identify'**
  String get procedimentosTypeCategoryIdentify;

  /// No description provided for @procedimentosItemTypePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose how the staff member will respond to or record this action.'**
  String get procedimentosItemTypePickerHelp;

  /// No description provided for @procedimentosPlaceholderField.
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get procedimentosPlaceholderField;

  /// No description provided for @procedimentosUnitField.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get procedimentosUnitField;

  /// No description provided for @procedimentosChoiceOptions.
  ///
  /// In en, this message translates to:
  /// **'Choice options'**
  String get procedimentosChoiceOptions;

  /// No description provided for @procedimentosAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get procedimentosAddOption;

  /// No description provided for @procedimentosRemoveOption.
  ///
  /// In en, this message translates to:
  /// **'Remove option'**
  String get procedimentosRemoveOption;

  /// No description provided for @procedimentosOptionField.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get procedimentosOptionField;

  /// No description provided for @procedimentosValidationChoiceOptions.
  ///
  /// In en, this message translates to:
  /// **'Enter at least two options.'**
  String get procedimentosValidationChoiceOptions;

  /// No description provided for @procedimentosChangeTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change item type?'**
  String get procedimentosChangeTypeTitle;

  /// No description provided for @procedimentosChangeTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'The configured options will be removed for this type.'**
  String get procedimentosChangeTypeMessage;

  /// No description provided for @procedimentosSimulatedTypeEditorHelp.
  ///
  /// In en, this message translates to:
  /// **'In demo mode, this capture will be simulated without using device resources.'**
  String get procedimentosSimulatedTypeEditorHelp;

  /// No description provided for @procedimentosPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get procedimentosPreviewTitle;

  /// No description provided for @procedimentosPreviewUntitledProcedure.
  ///
  /// In en, this message translates to:
  /// **'Untitled procedure'**
  String get procedimentosPreviewUntitledProcedure;

  /// No description provided for @procedimentosPreviewIncompleteProcedure.
  ///
  /// In en, this message translates to:
  /// **'This procedure does not have stages to demonstrate yet.'**
  String get procedimentosPreviewIncompleteProcedure;

  /// No description provided for @procedimentosPreviewOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get procedimentosPreviewOf;

  /// No description provided for @procedimentosPreviewProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed actions'**
  String get procedimentosPreviewProgressLabel;

  /// No description provided for @procedimentosPreviewPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'There are required actions pending in this stage.'**
  String get procedimentosPreviewPendingMessage;

  /// No description provided for @procedimentosPreviewRequiredPending.
  ///
  /// In en, this message translates to:
  /// **'Answer this required action to continue.'**
  String get procedimentosPreviewRequiredPending;

  /// No description provided for @procedimentosPreviewNextStage.
  ///
  /// In en, this message translates to:
  /// **'Next stage'**
  String get procedimentosPreviewNextStage;

  /// No description provided for @procedimentosPreviewFinishDemo.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get procedimentosPreviewFinishDemo;

  /// No description provided for @procedimentosPreviewReviewStages.
  ///
  /// In en, this message translates to:
  /// **'Review stages'**
  String get procedimentosPreviewReviewStages;

  /// No description provided for @procedimentosPreviewSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo completed'**
  String get procedimentosPreviewSummaryTitle;

  /// No description provided for @procedimentosPreviewSummarySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'No response was saved.'**
  String get procedimentosPreviewSummarySavedMessage;

  /// No description provided for @procedimentosPreviewSummaryAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered actions.'**
  String get procedimentosPreviewSummaryAnswered;

  /// No description provided for @procedimentosPreviewSummaryNoOptionalPending.
  ///
  /// In en, this message translates to:
  /// **'No optional items pending.'**
  String get procedimentosPreviewSummaryNoOptionalPending;

  /// No description provided for @procedimentosPreviewSummaryOptionalPending.
  ///
  /// In en, this message translates to:
  /// **'Optional item pending.'**
  String get procedimentosPreviewSummaryOptionalPending;

  /// No description provided for @procedimentosPreviewDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard responses?'**
  String get procedimentosPreviewDiscardTitle;

  /// No description provided for @procedimentosPreviewDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'The responses from this demo will be discarded when leaving.'**
  String get procedimentosPreviewDiscardMessage;

  /// No description provided for @procedimentosPreviewConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm action'**
  String get procedimentosPreviewConfirmAction;

  /// No description provided for @procedimentosPreviewUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Mark as understood'**
  String get procedimentosPreviewUnderstood;

  /// No description provided for @procedimentosPreviewUnderstoodDone.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get procedimentosPreviewUnderstoodDone;

  /// No description provided for @procedimentosPreviewTextHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the response'**
  String get procedimentosPreviewTextHint;

  /// No description provided for @procedimentosPreviewNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get procedimentosPreviewNumberHint;

  /// No description provided for @procedimentosPreviewSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get procedimentosPreviewSelectDate;

  /// No description provided for @procedimentosPreviewImeiHint.
  ///
  /// In en, this message translates to:
  /// **'Enter IMEI'**
  String get procedimentosPreviewImeiHint;

  /// No description provided for @procedimentosPreviewUseDemoImei.
  ///
  /// In en, this message translates to:
  /// **'Use demo IMEI'**
  String get procedimentosPreviewUseDemoImei;

  /// No description provided for @procedimentosPreviewTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get procedimentosPreviewTakePhoto;

  /// No description provided for @procedimentosPreviewSimulateSignature.
  ///
  /// In en, this message translates to:
  /// **'Simulate signature'**
  String get procedimentosPreviewSimulateSignature;

  /// No description provided for @procedimentosPreviewCaptureLocation.
  ///
  /// In en, this message translates to:
  /// **'Capture location'**
  String get procedimentosPreviewCaptureLocation;

  /// No description provided for @procedimentosPreviewSimulateBarcode.
  ///
  /// In en, this message translates to:
  /// **'Simulate reading'**
  String get procedimentosPreviewSimulateBarcode;

  /// No description provided for @procedimentosPreviewSimulateDocument.
  ///
  /// In en, this message translates to:
  /// **'Simulate attachment'**
  String get procedimentosPreviewSimulateDocument;

  /// No description provided for @procedimentosPreviewSimulateAudio.
  ///
  /// In en, this message translates to:
  /// **'Simulate recording'**
  String get procedimentosPreviewSimulateAudio;

  /// No description provided for @procedimentosPreviewRemoveEvidence.
  ///
  /// In en, this message translates to:
  /// **'Remove evidence'**
  String get procedimentosPreviewRemoveEvidence;

  /// No description provided for @procedimentosSimulatedResourceNotice.
  ///
  /// In en, this message translates to:
  /// **'Demo resource. No real data will be captured.'**
  String get procedimentosSimulatedResourceNotice;

  /// No description provided for @procedimentosPreviewPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get procedimentosPreviewPhotoAdded;

  /// No description provided for @procedimentosPreviewSignatureAdded.
  ///
  /// In en, this message translates to:
  /// **'Signature added'**
  String get procedimentosPreviewSignatureAdded;

  /// No description provided for @procedimentosPreviewSignatureDemoDetail.
  ///
  /// In en, this message translates to:
  /// **'Demo stroke recorded'**
  String get procedimentosPreviewSignatureDemoDetail;

  /// No description provided for @procedimentosPreviewLocationAdded.
  ///
  /// In en, this message translates to:
  /// **'Demo location captured'**
  String get procedimentosPreviewLocationAdded;

  /// No description provided for @procedimentosPreviewBarcodeAdded.
  ///
  /// In en, this message translates to:
  /// **'Code read'**
  String get procedimentosPreviewBarcodeAdded;

  /// No description provided for @procedimentosPreviewDocumentAdded.
  ///
  /// In en, this message translates to:
  /// **'Document attached'**
  String get procedimentosPreviewDocumentAdded;

  /// No description provided for @procedimentosPreviewAudioAdded.
  ///
  /// In en, this message translates to:
  /// **'Audio recorded'**
  String get procedimentosPreviewAudioAdded;

  /// No description provided for @procedimentosOperationCashRegister.
  ///
  /// In en, this message translates to:
  /// **'Cash register'**
  String get procedimentosOperationCashRegister;

  /// No description provided for @procedimentosOperationCustomerRegistration.
  ///
  /// In en, this message translates to:
  /// **'Customer registration'**
  String get procedimentosOperationCustomerRegistration;

  /// No description provided for @procedimentosTriggerMomentBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Before starting'**
  String get procedimentosTriggerMomentBeforeStart;

  /// No description provided for @procedimentosTriggerMomentAfterStart.
  ///
  /// In en, this message translates to:
  /// **'After starting'**
  String get procedimentosTriggerMomentAfterStart;

  /// No description provided for @procedimentosTriggerMomentBeforeFinish.
  ///
  /// In en, this message translates to:
  /// **'Before completing'**
  String get procedimentosTriggerMomentBeforeFinish;

  /// No description provided for @procedimentosTriggerMomentAfterFinish.
  ///
  /// In en, this message translates to:
  /// **'After completing'**
  String get procedimentosTriggerMomentAfterFinish;

  /// No description provided for @procedimentosTriggerMomentBeforeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Before delivery'**
  String get procedimentosTriggerMomentBeforeDelivery;

  /// No description provided for @procedimentosTriggerMomentAfterDelivery.
  ///
  /// In en, this message translates to:
  /// **'After delivery'**
  String get procedimentosTriggerMomentAfterDelivery;

  /// No description provided for @procedimentosTriggerMomentOnDemand.
  ///
  /// In en, this message translates to:
  /// **'On demand'**
  String get procedimentosTriggerMomentOnDemand;

  /// No description provided for @procedimentosActivationManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get procedimentosActivationManual;

  /// No description provided for @procedimentosActivationAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get procedimentosActivationAutomatic;

  /// No description provided for @procedimentosActivationManualDescription.
  ///
  /// In en, this message translates to:
  /// **'The staff member can start this procedure when needed.'**
  String get procedimentosActivationManualDescription;

  /// No description provided for @procedimentosActivationAutomaticDescription.
  ///
  /// In en, this message translates to:
  /// **'In a future integration, the procedure will be shown at the configured moment.'**
  String get procedimentosActivationAutomaticDescription;

  /// No description provided for @procedimentosEnforcementInformative.
  ///
  /// In en, this message translates to:
  /// **'Informative'**
  String get procedimentosEnforcementInformative;

  /// No description provided for @procedimentosEnforcementRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get procedimentosEnforcementRecommended;

  /// No description provided for @procedimentosEnforcementRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get procedimentosEnforcementRequired;

  /// No description provided for @procedimentosEnforcementInformativeDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows the procedure without requiring completion.'**
  String get procedimentosEnforcementInformativeDescription;

  /// No description provided for @procedimentosEnforcementRecommendedDescription.
  ///
  /// In en, this message translates to:
  /// **'Recommends completion, but should not block the operation.'**
  String get procedimentosEnforcementRecommendedDescription;

  /// No description provided for @procedimentosEnforcementRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'In a future integration, it will require completion before continuing.'**
  String get procedimentosEnforcementRequiredDescription;

  /// No description provided for @procedimentosWhenExecute.
  ///
  /// In en, this message translates to:
  /// **'When to execute'**
  String get procedimentosWhenExecute;

  /// No description provided for @procedimentosAddTrigger.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get procedimentosAddTrigger;

  /// No description provided for @procedimentosEditTrigger.
  ///
  /// In en, this message translates to:
  /// **'Edit trigger'**
  String get procedimentosEditTrigger;

  /// No description provided for @procedimentosDeleteTrigger.
  ///
  /// In en, this message translates to:
  /// **'Delete trigger'**
  String get procedimentosDeleteTrigger;

  /// No description provided for @procedimentosNoTriggers.
  ///
  /// In en, this message translates to:
  /// **'No triggers configured.'**
  String get procedimentosNoTriggers;

  /// No description provided for @procedimentosNoTriggersDescription.
  ///
  /// In en, this message translates to:
  /// **'Without triggers, the procedure will only be available for use and preview inside this module.'**
  String get procedimentosNoTriggersDescription;

  /// No description provided for @procedimentosTriggerCount.
  ///
  /// In en, this message translates to:
  /// **'triggers'**
  String get procedimentosTriggerCount;

  /// No description provided for @procedimentosSelectOperationContext.
  ///
  /// In en, this message translates to:
  /// **'Select context'**
  String get procedimentosSelectOperationContext;

  /// No description provided for @procedimentosSelectTriggerMoment.
  ///
  /// In en, this message translates to:
  /// **'Select moment'**
  String get procedimentosSelectTriggerMoment;

  /// No description provided for @procedimentosActivationMode.
  ///
  /// In en, this message translates to:
  /// **'Execution mode'**
  String get procedimentosActivationMode;

  /// No description provided for @procedimentosEnforcementMode.
  ///
  /// In en, this message translates to:
  /// **'Enforcement level'**
  String get procedimentosEnforcementMode;

  /// No description provided for @procedimentosTriggerEnabledHelp.
  ///
  /// In en, this message translates to:
  /// **'Controls whether this trigger will be considered in a future integration.'**
  String get procedimentosTriggerEnabledHelp;

  /// No description provided for @procedimentosSaveTrigger.
  ///
  /// In en, this message translates to:
  /// **'Save trigger'**
  String get procedimentosSaveTrigger;

  /// No description provided for @procedimentosTriggerMomentCleared.
  ///
  /// In en, this message translates to:
  /// **'The moment was cleared because it is not compatible with the selected context.'**
  String get procedimentosTriggerMomentCleared;

  /// No description provided for @procedimentosValidationTriggerOperation.
  ///
  /// In en, this message translates to:
  /// **'Choose the operational context.'**
  String get procedimentosValidationTriggerOperation;

  /// No description provided for @procedimentosValidationTriggerMoment.
  ///
  /// In en, this message translates to:
  /// **'Choose the execution moment.'**
  String get procedimentosValidationTriggerMoment;

  /// No description provided for @procedimentosValidationTriggerMomentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a moment compatible with the context.'**
  String get procedimentosValidationTriggerMomentInvalid;

  /// No description provided for @procedimentosValidationDuplicateTrigger.
  ///
  /// In en, this message translates to:
  /// **'A trigger with this context, moment and execution mode already exists.'**
  String get procedimentosValidationDuplicateTrigger;

  /// No description provided for @procedimentosDeleteTriggerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete trigger?'**
  String get procedimentosDeleteTriggerTitle;

  /// No description provided for @procedimentosDeleteTriggerMessage.
  ///
  /// In en, this message translates to:
  /// **'The procedure will no longer be shown at this operational moment.'**
  String get procedimentosDeleteTriggerMessage;

  /// No description provided for @procedimentosTriggerSummaryNone.
  ///
  /// In en, this message translates to:
  /// **'No triggers configured'**
  String get procedimentosTriggerSummaryNone;

  /// No description provided for @procedimentosTriggerSummaryOnlyInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive triggers'**
  String get procedimentosTriggerSummaryOnlyInactive;

  /// No description provided for @procedimentosExecutionConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Execution configuration'**
  String get procedimentosExecutionConfiguration;

  /// No description provided for @procedimentosTriggerSimulationNotice.
  ///
  /// In en, this message translates to:
  /// **'Trigger simulation. No real operation will be blocked.'**
  String get procedimentosTriggerSimulationNotice;

  /// No description provided for @procedimentosManualDemoExecution.
  ///
  /// In en, this message translates to:
  /// **'Manual demo execution.'**
  String get procedimentosManualDemoExecution;

  /// No description provided for @procedimentosOperationPointSaleStartBefore.
  ///
  /// In en, this message translates to:
  /// **'Before starting a sale'**
  String get procedimentosOperationPointSaleStartBefore;

  /// No description provided for @procedimentosOperationPointSaleStartBeforeDescription.
  ///
  /// In en, this message translates to:
  /// **'Runs before opening the new sale flow.'**
  String get procedimentosOperationPointSaleStartBeforeDescription;

  /// No description provided for @procedimentosMobilePointAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available in the mobile app.'**
  String get procedimentosMobilePointAvailable;

  /// No description provided for @procedimentosOperationalExecutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Before starting the sale'**
  String get procedimentosOperationalExecutionTitle;

  /// No description provided for @procedimentosOperationalSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Procedure completed'**
  String get procedimentosOperationalSummaryTitle;

  /// No description provided for @procedimentosOperationalNoDataSaved.
  ///
  /// In en, this message translates to:
  /// **'No response was saved in this local experimental integration.'**
  String get procedimentosOperationalNoDataSaved;

  /// No description provided for @procedimentosCompleteAndStartSale.
  ///
  /// In en, this message translates to:
  /// **'Complete and start sale'**
  String get procedimentosCompleteAndStartSale;

  /// No description provided for @procedimentosExperimentalIntegration.
  ///
  /// In en, this message translates to:
  /// **'Experimental integration'**
  String get procedimentosExperimentalIntegration;

  /// No description provided for @procedimentosContinueToStartSale.
  ///
  /// In en, this message translates to:
  /// **'Continue to sale'**
  String get procedimentosContinueToStartSale;

  /// No description provided for @procedimentosContinueWithoutCompleting.
  ///
  /// In en, this message translates to:
  /// **'Continue without completing'**
  String get procedimentosContinueWithoutCompleting;

  /// No description provided for @procedimentosContinueWithoutCompletingTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue without completing?'**
  String get procedimentosContinueWithoutCompletingTitle;

  /// No description provided for @procedimentosContinueWithoutCompletingMessage.
  ///
  /// In en, this message translates to:
  /// **'This procedure is recommended before starting the sale.'**
  String get procedimentosContinueWithoutCompletingMessage;

  /// No description provided for @procedimentosContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get procedimentosContinueAnyway;

  /// No description provided for @procedimentosReturnToProcedure.
  ///
  /// In en, this message translates to:
  /// **'Return to procedure'**
  String get procedimentosReturnToProcedure;

  /// No description provided for @procedimentosCancelSaleStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale start?'**
  String get procedimentosCancelSaleStartTitle;

  /// No description provided for @procedimentosCancelSaleStartMessage.
  ///
  /// In en, this message translates to:
  /// **'This procedure is required. If you leave, the new sale will not be started.'**
  String get procedimentosCancelSaleStartMessage;

  /// No description provided for @procedimentosCancelSale.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale'**
  String get procedimentosCancelSale;

  /// No description provided for @procedimentosSequenceProgressPrefix.
  ///
  /// In en, this message translates to:
  /// **'Procedure'**
  String get procedimentosSequenceProgressPrefix;

  /// No description provided for @procedimentosPreviewNegativeTextLabel.
  ///
  /// In en, this message translates to:
  /// **'What was missing?'**
  String get procedimentosPreviewNegativeTextLabel;

  /// No description provided for @procedimentosPreviewNegativeTextHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what was missing'**
  String get procedimentosPreviewNegativeTextHint;

  /// No description provided for @procedimentosOperationalLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load procedures.'**
  String get procedimentosOperationalLoadError;
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
