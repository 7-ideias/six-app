import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../data/models/ai_assistant_models.dart';
import '../../../domain/services/ia/ai_assistant_service.dart';

class AiAssistantFeedbackActions extends StatelessWidget {
  const AiAssistantFeedbackActions({
    super.key,
    required this.title,
    required this.helpedLabel,
    required this.notHelpedLabel,
    required this.onFeedback,
    this.loading = false,
    this.sent = false,
    this.modulo = 'geral',
    this.telaAtual = 'assistente_ia',
  });

  final String title;
  final String helpedLabel;
  final String notHelpedLabel;
  final Future<void> Function(bool helped) onFeedback;
  final bool loading;
  final bool sent;
  final String modulo;
  final String telaAtual;

  @override
  Widget build(BuildContext context) {
    final _SuggestionTexts texts = _SuggestionTexts.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: loading || sent ? null : () => onFeedback(true),
              icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
              label: Text(helpedLabel),
            ),
            OutlinedButton.icon(
              onPressed: loading || sent ? null : () => onFeedback(false),
              icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
              label: Text(notHelpedLabel),
            ),
            OutlinedButton.icon(
              onPressed: () => _openSuggestionDialog(context, texts),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
              label: Text(texts.button),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openSuggestionDialog(
    BuildContext context,
    _SuggestionTexts texts,
  ) async {
    final TextEditingController controller = TextEditingController();
    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(texts.title),
              content: SizedBox(
                width: 480,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: texts.hint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(dialogContext),
                  child: Text(texts.cancel),
                ),
                FilledButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          final String description = controller.text.trim();
                          if (description.isEmpty) return;
                          setState(() => sending = true);
                          try {
                            final Locale locale = Localizations.localeOf(context);
                            await AiAssistantService().enviarSugestao(
                              AiAssistantSuggestionRequestModel(
                                descricao: description,
                                idioma: locale.toLanguageTag(),
                                plataforma: kIsWeb ? 'web' : 'mobile',
                                modulo: modulo,
                                telaAtual: telaAtual,
                              ),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(texts.success),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (_) {
                            if (!dialogContext.mounted) return;
                            setState(() => sending = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(texts.error),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(texts.send),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }
}

class _SuggestionTexts {
  const _SuggestionTexts({
    required this.button,
    required this.title,
    required this.hint,
    required this.cancel,
    required this.send,
    required this.success,
    required this.error,
  });

  final String button;
  final String title;
  final String hint;
  final String cancel;
  final String send;
  final String success;
  final String error;

  factory _SuggestionTexts.of(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    if (language == 'es') {
      return const _SuggestionTexts(
        button: 'Enviar idea',
        title: 'Idea o sugerencia',
        hint: 'Cuéntanos qué podría mejorar en Six...',
        cancel: 'Cancelar',
        send: 'Enviar',
        success: 'Sugerencia registrada. ¡Gracias por ayudar a mejorar Six!',
        error: 'No fue posible enviar la sugerencia.',
      );
    }
    if (language == 'en') {
      return const _SuggestionTexts(
        button: 'Send idea',
        title: 'Idea or suggestion',
        hint: 'Tell us what could be improved in Six...',
        cancel: 'Cancel',
        send: 'Send',
        success: 'Suggestion recorded. Thanks for helping improve Six!',
        error: 'The suggestion could not be sent.',
      );
    }
    return const _SuggestionTexts(
      button: 'Enviar ideia',
      title: 'Ideia ou sugestão',
      hint: 'Conte o que poderia melhorar no Six...',
      cancel: 'Cancelar',
      send: 'Enviar',
      success: 'Sugestão registrada. Obrigado por ajudar a evoluir o Six!',
      error: 'Não foi possível enviar a sugestão.',
    );
  }
}
