import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../data/models/ai_assistant_models.dart';
import '../../../domain/services/ia/ai_assistant_service.dart';

class AiAssistantFeedbackActions extends StatefulWidget {
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
  State<AiAssistantFeedbackActions> createState() =>
      _AiAssistantFeedbackActionsState();
}

class _AiAssistantFeedbackActionsState
    extends State<AiAssistantFeedbackActions> {
  bool _localSent = false;

  bool get _disabled => widget.loading || widget.sent || _localSent;

  @override
  Widget build(BuildContext context) {
    final _FeedbackTexts texts = _FeedbackTexts.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _disabled ? null : () => widget.onFeedback(true),
              icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
              label: Text(widget.helpedLabel),
            ),
            OutlinedButton.icon(
              onPressed: _disabled
                  ? null
                  : () => _openNegativeFeedbackDialog(context, texts),
              icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
              label: Text(widget.notHelpedLabel),
            ),
            OutlinedButton.icon(
              onPressed: _disabled
                  ? null
                  : () => _openSuggestionDialog(context, texts),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
              label: Text(texts.suggestionButton),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openNegativeFeedbackDialog(
    BuildContext outerContext,
    _FeedbackTexts texts,
  ) async {
    final TextEditingController commentController = TextEditingController();
    String selectedReason = 'INCORRETA';
    bool createSuggestion = false;
    bool sending = false;

    await showDialog<void>(
      context: outerContext,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogBuildContext, StateSetter dialogSetState) {
          return AlertDialog(
            title: Text(texts.negativeTitle),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(texts.negativeQuestion),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: texts.reasons.entries
                        .map(
                          (MapEntry<String, String> entry) =>
                              DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: sending
                        ? null
                        : (String? value) {
                            if (value != null) {
                              dialogSetState(() => selectedReason = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    enabled: !sending,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: texts.commentHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: createSuggestion,
                    onChanged: sending
                        ? null
                        : (bool? value) => dialogSetState(
                              () => createSuggestion = value ?? false,
                            ),
                    title: Text(texts.createSuggestion),
                    subtitle: Text(texts.createSuggestionHint),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed:
                    sending ? null : () => Navigator.pop(dialogContext),
                child: Text(texts.cancel),
              ),
              FilledButton.icon(
                onPressed: sending
                    ? null
                    : () async {
                        dialogSetState(() => sending = true);
                        final String locale =
                            Localizations.localeOf(dialogBuildContext)
                                .toLanguageTag();
                        final String comment = commentController.text.trim();
                        try {
                          await AiAssistantService().enviarFeedback(
                            AiAssistantFeedbackRequestModel(
                              pergunta: texts.genericQuestion,
                              resposta: texts.genericAnswer,
                              util: false,
                              motivo: selectedReason,
                              comentario: comment.isEmpty ? null : comment,
                              modulo: widget.modulo,
                              telaAtual: widget.telaAtual,
                              plataforma: kIsWeb ? 'web' : 'mobile',
                              idioma: locale,
                            ),
                          );

                          if (createSuggestion) {
                            final String description = comment.isEmpty
                                ? '${texts.reasons[selectedReason]} — ${texts.genericSuggestionContext}'
                                : comment;
                            await AiAssistantService().enviarSugestao(
                              AiAssistantSuggestionRequestModel(
                                descricao: description,
                                idioma: locale,
                                plataforma: kIsWeb ? 'web' : 'mobile',
                                modulo: widget.modulo,
                                telaAtual: widget.telaAtual,
                              ),
                            );
                          }

                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.pop(dialogContext);

                          if (!mounted) return;
                          setState(() => _localSent = true);
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                createSuggestion
                                    ? texts.feedbackAndSuggestionSuccess
                                    : texts.feedbackSuccess,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (_) {
                          if (!dialogContext.mounted) return;
                          dialogSetState(() => sending = false);
                          if (!outerContext.mounted) return;
                          ScaffoldMessenger.of(outerContext).showSnackBar(
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
      ),
    );

    commentController.dispose();
  }

  Future<void> _openSuggestionDialog(
    BuildContext outerContext,
    _FeedbackTexts texts,
  ) async {
    final TextEditingController controller = TextEditingController();
    bool sending = false;

    await showDialog<void>(
      context: outerContext,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogBuildContext, StateSetter dialogSetState) {
          return AlertDialog(
            title: Text(texts.suggestionTitle),
            content: SizedBox(
              width: 480,
              child: TextField(
                controller: controller,
                autofocus: true,
                enabled: !sending,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: texts.suggestionHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed:
                    sending ? null : () => Navigator.pop(dialogContext),
                child: Text(texts.cancel),
              ),
              FilledButton.icon(
                onPressed: sending
                    ? null
                    : () async {
                        final String description = controller.text.trim();
                        if (description.isEmpty) return;
                        dialogSetState(() => sending = true);
                        try {
                          final Locale locale =
                              Localizations.localeOf(dialogBuildContext);
                          await AiAssistantService().enviarSugestao(
                            AiAssistantSuggestionRequestModel(
                              descricao: description,
                              idioma: locale.toLanguageTag(),
                              plataforma: kIsWeb ? 'web' : 'mobile',
                              modulo: widget.modulo,
                              telaAtual: widget.telaAtual,
                            ),
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!outerContext.mounted) return;
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            SnackBar(
                              content: Text(texts.suggestionSuccess),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (_) {
                          if (!dialogContext.mounted) return;
                          dialogSetState(() => sending = false);
                          if (!outerContext.mounted) return;
                          ScaffoldMessenger.of(outerContext).showSnackBar(
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
      ),
    );

    controller.dispose();
  }
}

class _FeedbackTexts {
  const _FeedbackTexts({
    required this.suggestionButton,
    required this.suggestionTitle,
    required this.suggestionHint,
    required this.negativeTitle,
    required this.negativeQuestion,
    required this.commentHint,
    required this.createSuggestion,
    required this.createSuggestionHint,
    required this.cancel,
    required this.send,
    required this.feedbackSuccess,
    required this.feedbackAndSuggestionSuccess,
    required this.suggestionSuccess,
    required this.error,
    required this.genericQuestion,
    required this.genericAnswer,
    required this.genericSuggestionContext,
    required this.reasons,
  });

  final String suggestionButton;
  final String suggestionTitle;
  final String suggestionHint;
  final String negativeTitle;
  final String negativeQuestion;
  final String commentHint;
  final String createSuggestion;
  final String createSuggestionHint;
  final String cancel;
  final String send;
  final String feedbackSuccess;
  final String feedbackAndSuggestionSuccess;
  final String suggestionSuccess;
  final String error;
  final String genericQuestion;
  final String genericAnswer;
  final String genericSuggestionContext;
  final Map<String, String> reasons;

  factory _FeedbackTexts.of(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    if (language == 'es') {
      return const _FeedbackTexts(
        suggestionButton: 'Enviar idea',
        suggestionTitle: 'Idea o sugerencia',
        suggestionHint: 'Cuéntanos qué podría mejorar en Six...',
        negativeTitle: 'Cuéntanos qué faltó',
        negativeQuestion: '¿Por qué esta respuesta no te ayudó?',
        commentHint: 'Agrega más detalles (opcional)',
        createSuggestion: 'Registrar también como nueva idea',
        createSuggestionHint:
            'La idea aparecerá para evaluación del equipo de Six.',
        cancel: 'Cancelar',
        send: 'Enviar',
        feedbackSuccess: 'Gracias. Tu evaluación fue registrada.',
        feedbackAndSuggestionSuccess: 'Evaluación e idea registradas.',
        suggestionSuccess: 'Sugerencia registrada. ¡Gracias!',
        error: 'No fue posible enviar la información.',
        genericQuestion: 'Evaluación negativa después de una respuesta de IA',
        genericAnswer: 'Respuesta evaluada en el asistente de Six',
        genericSuggestionContext:
            'Necesidad identificada después de una respuesta de IA.',
        reasons: <String, String>{
          'INCORRETA': 'La respuesta estaba incorrecta',
          'NAO_ENCONTREI': 'No encontré lo que necesitaba',
          'NAO_FICOU_CLARA': 'La explicación no fue clara',
          'FUNCIONALIDADE_INEXISTENTE': 'Six no tiene lo que necesito',
          'OUTRO': 'Otro motivo',
        },
      );
    }
    if (language == 'en') {
      return const _FeedbackTexts(
        suggestionButton: 'Send idea',
        suggestionTitle: 'Idea or suggestion',
        suggestionHint: 'Tell us what could be improved in Six...',
        negativeTitle: 'Tell us what was missing',
        negativeQuestion: 'Why did this answer not help?',
        commentHint: 'Add more details (optional)',
        createSuggestion: 'Also register as a new idea',
        createSuggestionHint:
            'The idea will be available for the Six team to review.',
        cancel: 'Cancel',
        send: 'Send',
        feedbackSuccess: 'Thanks. Your feedback was recorded.',
        feedbackAndSuggestionSuccess: 'Feedback and idea recorded.',
        suggestionSuccess: 'Suggestion recorded. Thank you!',
        error: 'The information could not be sent.',
        genericQuestion: 'Negative rating after an AI answer',
        genericAnswer: 'Answer rated in the Six assistant',
        genericSuggestionContext: 'Need identified after an AI answer.',
        reasons: <String, String>{
          'INCORRETA': 'The answer was incorrect',
          'NAO_ENCONTREI': 'I did not find what I needed',
          'NAO_FICOU_CLARA': 'The explanation was unclear',
          'FUNCIONALIDADE_INEXISTENTE': 'Six does not have what I need',
          'OUTRO': 'Another reason',
        },
      );
    }
    return const _FeedbackTexts(
      suggestionButton: 'Enviar ideia',
      suggestionTitle: 'Ideia ou sugestão',
      suggestionHint: 'Conte o que poderia melhorar no Six...',
      negativeTitle: 'Conte o que faltou',
      negativeQuestion: 'Por que esta resposta não ajudou?',
      commentHint: 'Acrescente mais detalhes (opcional)',
      createSuggestion: 'Registrar também como nova ideia',
      createSuggestionHint:
          'A ideia ficará disponível para avaliação da equipe do Six.',
      cancel: 'Cancelar',
      send: 'Enviar',
      feedbackSuccess: 'Obrigado. Sua avaliação foi registrada.',
      feedbackAndSuggestionSuccess: 'Avaliação e ideia registradas.',
      suggestionSuccess: 'Sugestão registrada. Obrigado!',
      error: 'Não foi possível enviar as informações.',
      genericQuestion: 'Avaliação negativa após resposta da IA',
      genericAnswer: 'Resposta avaliada no assistente do Six',
      genericSuggestionContext:
          'Necessidade identificada após uma resposta da IA.',
      reasons: <String, String>{
        'INCORRETA': 'A resposta estava incorreta',
        'NAO_ENCONTREI': 'Não encontrei o que precisava',
        'NAO_FICOU_CLARA': 'A explicação não ficou clara',
        'FUNCIONALIDADE_INEXISTENTE': 'O Six não possui o que preciso',
        'OUTRO': 'Outro motivo',
      },
    );
  }
}
