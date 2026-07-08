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
}
