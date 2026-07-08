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
}
