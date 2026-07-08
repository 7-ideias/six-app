import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../data/models/ai_assistant_models.dart';
import '../../../domain/services/ia/ai_assistant_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/colaborador_autorizacoes_provider.dart';
import '../../../providers/locale_settings_provider.dart';
import 'ai_assistant_example_list.dart';
import 'ai_assistant_feedback_actions.dart';
import 'ai_assistant_message_bubble.dart';

class AiAssistantPanel extends StatelessWidget {
  const AiAssistantPanel({
    super.key,
    required this.modulo,
    required this.telaAtual,
    required this.onClose,
  });

  final String modulo;
  final String telaAtual;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 14,
      child: SizedBox(
        width: 430,
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n?.aiAssistantAsk ?? 'Perguntar a IA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: l10n?.aiAssistantClose ?? 'Fechar',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AiAssistantConversationBody(
                modulo: modulo,
                telaAtual: telaAtual,
                isMobile: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiAssistantConversationBody extends StatefulWidget {
  const AiAssistantConversationBody({
    super.key,
    required this.modulo,
    required this.telaAtual,
    required this.isMobile,
  });

  final String modulo;
  final String telaAtual;
  final bool isMobile;

  @override
  State<AiAssistantConversationBody> createState() =>
      _AiAssistantConversationBodyState();
}

class _AiAssistantConversationBodyState
    extends State<AiAssistantConversationBody> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiAssistantService _service = AiAssistantService();
  final AuthService _authService = AuthService();

  bool _sending = false;
  bool _sendingFeedback = false;
  bool _feedbackSent = false;
  String? _lastQuestion;
  String? _error;
  AiAssistantResponseModel? _response;

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion() async {
    if (_sending) return;

    final String question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final AiAssistantRequestModel request = await _buildRequest(question);
      final AiAssistantResponseModel response = await _service.perguntar(
        request,
      );

      if (!mounted) return;
      setState(() {
        _lastQuestion = question;
        _response = response;
        _feedbackSent = false;
      });
      _questionController.clear();
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            AppLocalizations.of(context)?.aiAssistantError ??
            'Nao foi possivel obter resposta da IA agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<AiAssistantRequestModel> _buildRequest(String question) async {
    String idioma = 'pt-BR';
    try {
      idioma =
          context.read<LocaleSettingsProvider>().currentLocale.toLanguageTag();
      if (idioma.trim().isEmpty) {
        idioma = 'pt-BR';
      }
    } catch (_) {
      idioma = 'pt-BR';
    }

    String perfilUsuario = 'DESCONHECIDO';
    List<String> permissoes = <String>[];
    try {
      perfilUsuario = await _authService.getUserProfileType();
      permissoes = await _authService.getUserPermissions();
    } catch (_) {
      perfilUsuario = 'DESCONHECIDO';
      permissoes = <String>[];
    }

    permissoes = _mergePermissions(permissoes, _permissionsFromProvider());

    return AiAssistantRequestModel(
      pergunta: question,
      idioma: idioma,
      plataforma: kIsWeb ? 'web' : 'mobile',
      modulo: widget.modulo.trim().isEmpty ? 'geral' : widget.modulo,
      telaAtual:
          widget.telaAtual.trim().isEmpty ? 'desconhecida' : widget.telaAtual,
      perfilUsuario: perfilUsuario,
      permissoes: permissoes,
    );
  }

  List<String> _permissionsFromProvider() {
    try {
      final ColaboradorAutorizacoesProvider provider =
          context.read<ColaboradorAutorizacoesProvider>();
      final autorizacoes = provider.autorizacoes;
      final List<String> flags = <String>[
        if (autorizacoes.objAssistenciaTecnicaPode.lancaServico)
          'LANCAR_SERVICO',
        if (autorizacoes.objClientesPode.podeEditarCliente) 'EDITAR_CLIENTE',
        if (autorizacoes.objVendasPode.fazVenda) 'FAZER_VENDA',
        if (autorizacoes.objProdutosPode.podeEditarProduto) 'EDITAR_PRODUTO',
        if (autorizacoes.objLancamentosFinanceirosPode.podeReceberNoCaixa)
          'PODE_RECEBER_NO_CAIXA',
        if (autorizacoes.objLancamentosFinanceirosPode.podeVerQuantoVendeu)
          'PODE_VER_QUANTO_VENDEU',
      ];
      return flags;
    } catch (_) {
      return <String>[];
    }
  }

  List<String> _mergePermissions(List<String> current, List<String> extra) {
    return <String>{
      ...current,
      ...extra,
    }.where((String value) => value.trim().isNotEmpty).toList(growable: false);
  }

  Future<void> _sendFeedback(bool helped) async {
    if (_sendingFeedback || _feedbackSent) return;
    if (_lastQuestion == null || _response == null) return;

    setState(() => _sendingFeedback = true);
    try {
      await _service.enviarFeedback(
        AiAssistantFeedbackRequestModel(
          pergunta: _lastQuestion!,
          resposta: _response!.resposta,
          util: helped,
          comentario: null,
        ),
      );
      if (!mounted) return;
      setState(() => _feedbackSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.aiAssistantFeedbackThanks ??
                'Feedback registrado.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.aiAssistantError ??
                'Nao foi possivel enviar o feedback.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingFeedback = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleAction(AiAssistantActionModel action) {
    if (action.tipo.toLowerCase() != 'navegacao') return;
    if (action.rota.trim().isEmpty) return;

    try {
      Navigator.of(context).pushNamed(action.rota);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action.label),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(16, widget.isMobile ? 12 : 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_lastQuestion == null && !_sending)
                  Text(
                    l10n?.aiAssistantHowCanIHelp ?? 'Como posso ajudar no Six?',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (_sending) ...<Widget>[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.aiAssistantSending ?? 'Enviando...',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _sending ? null : _sendQuestion,
                          child: Text(
                            l10n?.aiAssistantRetry ?? 'Tentar novamente',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_lastQuestion != null)
                  AiAssistantMessageBubble(text: _lastQuestion!, isUser: true),
                if (_response != null) ...<Widget>[
                  AiAssistantMessageBubble(text: _response!.resposta),
                  const SizedBox(height: 8),
                  AiAssistantExampleList(
                    title: l10n?.aiAssistantExamples ?? 'Exemplos',
                    examples: _response!.exemplos,
                  ),
                  if (_response!.fontes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      l10n?.aiAssistantSources ?? 'Fontes',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _response!.fontes
                          .map(
                            (String source) => Chip(
                              label: Text(
                                source,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  if (_response!.acoes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _response!.acoes
                          .map(
                            (AiAssistantActionModel action) =>
                                OutlinedButton.icon(
                                  onPressed: () => _handleAction(action),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 18,
                                  ),
                                  label: Text(action.label),
                                ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 14),
                  AiAssistantFeedbackActions(
                    title: l10n?.aiAssistantHelped ?? 'Ajudou?',
                    helpedLabel: l10n?.aiAssistantHelpedButton ?? 'Ajudou',
                    notHelpedLabel: l10n?.aiAssistantDidNotHelp ?? 'Nao ajudou',
                    onFeedback: _sendFeedback,
                    loading: _sendingFeedback,
                    sent: _feedbackSent,
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, widget.isMobile ? 12 : 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _questionController,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _sendQuestion(),
                  decoration: InputDecoration(
                    hintText: l10n?.aiAssistantHint ?? 'Digite sua duvida',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _sendQuestion,
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                child:
                    _sending
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
