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
