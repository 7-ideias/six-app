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
