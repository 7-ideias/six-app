import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../data/models/ai_assistant_models.dart';
import '../../../domain/services/ia/ai_assistant_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/six_i18n.dart';
import '../../../providers/colaborador_autorizacoes_provider.dart';
import '../../../providers/locale_settings_provider.dart';
import '../six_backend_loading.dart';
import 'ai_assistant_example_list.dart';
import 'ai_assistant_feedback_actions.dart';
import 'ai_assistant_message_bubble.dart';

class AiAssistantPanel extends StatelessWidget {
  const AiAssistantPanel({
    super.key,
    required this.modulo,
    required this.telaAtual,
    required this.onClose,
    this.onMinimize,
    this.onToggleExpanded,
    this.onOpenSupport,
    this.expanded = false,
  });

  final String modulo;
  final String telaAtual;
  final VoidCallback onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onToggleExpanded;
  final VoidCallback? onOpenSupport;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Size screenSize = MediaQuery.sizeOf(context);
    final EdgeInsets viewPadding = MediaQuery.viewPaddingOf(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double fallbackWidth = math.max(
          280,
          screenSize.width - viewPadding.horizontal - 28,
        );
        final double fallbackHeight = math.max(
          360,
          screenSize.height - viewPadding.vertical - 28,
        );
        final double availableWidth = _finiteOrFallback(
          constraints.maxWidth,
          fallbackWidth,
        );
        final double availableHeight = _finiteOrFallback(
          constraints.maxHeight,
          fallbackHeight,
        );
        final double panelWidth = _panelDimension(
          max: availableWidth,
          preferred: expanded ? 1080 : 760,
          minimum: 320,
        );
        final double panelHeight = _panelDimension(
          max: availableHeight,
          preferred: expanded ? availableHeight : 920,
          minimum: 420,
        );
        final bool compact = panelWidth < 560;
        final BorderRadius panelRadius = BorderRadius.circular(
          compact ? 18 : 24,
        );

        return Material(
          color: colorScheme.surface,
          elevation: 24,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          borderRadius: panelRadius,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: panelWidth,
            height: panelHeight,
            child: Column(
              children: <Widget>[
                _AiAssistantPanelToolbar(
                  expanded: expanded,
                  compact: compact,
                  l10n: l10n,
                  onToggleExpanded: onToggleExpanded,
                  onOpenSupport: onOpenSupport,
                  onMinimize: onMinimize ?? onClose,
                  onClose: onClose,
                ),
                Expanded(
                  child: AiAssistantConversationBody(
                    modulo: modulo,
                    telaAtual: telaAtual,
                    isMobile: false,
                    onOpenSupport: onOpenSupport,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

double _finiteOrFallback(double value, double fallback) {
  if (value.isFinite && value > 0) {
    return value;
  }
  return fallback;
}

double _panelDimension({
  required double max,
  required double preferred,
  required double minimum,
}) {
  final double safeMax = max.isFinite && max > 0 ? max : preferred;
  if (safeMax < minimum) {
    return safeMax;
  }
  if (!preferred.isFinite || preferred <= 0) {
    return safeMax;
  }
  return math.min(safeMax, preferred);
}

class _AiAssistantPanelToolbar extends StatelessWidget {
  const _AiAssistantPanelToolbar({
    required this.expanded,
    required this.compact,
    required this.l10n,
    required this.onToggleExpanded,
    required this.onOpenSupport,
    required this.onMinimize,
    required this.onClose,
  });

  final bool expanded;
  final bool compact;
  final AppLocalizations? l10n;
  final VoidCallback? onToggleExpanded;
  final VoidCallback? onOpenSupport;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double size = compact ? 38 : 42;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 18,
        compact ? 10 : 14,
        compact ? 12 : 16,
        0,
      ),
      child: SizedBox(
        height: size,
        child: Row(
          children: <Widget>[
            const Spacer(),
            if (onOpenSupport != null) ...<Widget>[
              _AiAssistantToolbarButton(
                size: size,
                icon: Icons.support_agent_rounded,
                tooltip: context.t(
                  'chatSupport.lis.open',
                  fallback: 'Falar com o suporte',
                ),
                onPressed: onOpenSupport,
              ),
              const SizedBox(width: 8),
            ],
            _AiAssistantToolbarButton(
              size: size,
              icon:
                  expanded
                      ? Icons.close_fullscreen_rounded
                      : Icons.open_in_full_rounded,
              tooltip:
                  expanded
                      ? l10n?.aiAssistantCollapse ?? 'Reduzir assistente'
                      : l10n?.aiAssistantExpand ?? 'Expandir assistente',
              onPressed: onToggleExpanded,
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: l10n?.aiAssistantFocusLabel ?? 'Assistente em foco',
              child: Semantics(
                label: l10n?.aiAssistantFocusLabel ?? 'Assistente em foco',
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.72),
                      width: 1.4,
                    ),
                  ),
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    color: colorScheme.onSurface,
                    size: compact ? 18 : 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _AiAssistantToolbarButton(
              size: size,
              icon: Icons.keyboard_arrow_down_rounded,
              tooltip: l10n?.aiAssistantMinimize ?? 'Minimizar',
              onPressed: onMinimize,
            ),
            const SizedBox(width: 8),
            _AiAssistantToolbarButton(
              size: size,
              icon: Icons.close_rounded,
              tooltip: l10n?.aiAssistantClose ?? 'Fechar',
              onPressed: onClose,
              backgroundColor: colorScheme.errorContainer.withValues(
                alpha: 0.64,
              ),
              foregroundColor: colorScheme.onErrorContainer,
              borderColor: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAssistantToolbarButton extends StatelessWidget {
  const _AiAssistantToolbarButton({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: size * 0.48),
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor ?? Colors.transparent,
        foregroundColor: foregroundColor ?? colorScheme.onSurfaceVariant,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color:
                borderColor ??
                colorScheme.outlineVariant.withValues(alpha: 0.78),
          ),
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
    this.onOpenSupport,
  });

  final String modulo;
  final String telaAtual;
  final bool isMobile;
  final VoidCallback? onOpenSupport;

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
      _lastQuestion = question;
      _response = null;
      _feedbackSent = false;
    });
    _scrollToBottom();

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
      perfilUsuario =
          context.read<ColaboradorAutorizacoesProvider>().tipoPerfilUnificado;
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

  void _startNewQuestion() {
    if (_sending) return;
    setState(() {
      _lastQuestion = null;
      _response = null;
      _error = null;
      _feedbackSent = false;
    });
    _questionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return Column(
      children: <Widget>[
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child:
                _lastQuestion == null && !_sending && _error == null
                    ? _AiAssistantWelcome(
                      key: const ValueKey<String>('ai-assistant-welcome'),
                      l10n: l10n,
                      isMobile: widget.isMobile,
                      onOpenSupport: widget.onOpenSupport,
                    )
                    : _AiAssistantConversationView(
                      key: const ValueKey<String>('ai-assistant-conversation'),
                      scrollController: _scrollController,
                      l10n: l10n,
                      isMobile: widget.isMobile,
                      sending: _sending,
                      error: _error,
                      lastQuestion: _lastQuestion,
                      response: _response,
                      feedbackSent: _feedbackSent,
                      sendingFeedback: _sendingFeedback,
                      onRetry: _sendQuestion,
                      onFeedback: _sendFeedback,
                      onAction: _handleAction,
                    ),
          ),
        ),
        _AiAssistantComposer(
          controller: _questionController,
          l10n: l10n,
          isMobile: widget.isMobile,
          sending: _sending,
          hasConversation: _lastQuestion != null || _response != null,
          onSend: _sendQuestion,
          onNewQuestion: _startNewQuestion,
        ),
      ],
    );
  }
}

class _AiAssistantWelcome extends StatelessWidget {
  const _AiAssistantWelcome({
    super.key,
    required this.l10n,
    required this.isMobile,
    this.onOpenSupport,
  });

  final AppLocalizations? l10n;
  final bool isMobile;
  final VoidCallback? onOpenSupport;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final double avatarSize = isMobile ? 78 : 92;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: isMobile ? 22 : 44,
      vertical: isMobile ? 24 : 34,
    );

    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 360),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _AiAssistantAvatar(size: avatarSize, useWebImage: kIsWeb),
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback:
                    (Rect bounds) => LinearGradient(
                      colors: <Color>[
                        colorScheme.primary,
                        Color.lerp(colorScheme.primary, Colors.cyan, 0.42) ??
                            colorScheme.primary,
                      ],
                    ).createShader(bounds),
                child: Text(
                  l10n?.aiAssistantWelcomeTitle ?? 'Olá! Sou a Lis',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    height: 1.04,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  l10n?.aiAssistantWelcomeSubtitle ??
                      'Estou aqui para ajudar em suas solicitações e tirar dúvidas sobre o SixoApp.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onOpenSupport != null) ...<Widget>[
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: onOpenSupport,
                  icon: const Icon(Icons.support_agent_rounded),
                  label: Text(
                    context.t(
                      'chatSupport.lis.open',
                      fallback: 'Falar com o suporte',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AiAssistantAvatar extends StatelessWidget {
  const _AiAssistantAvatar({required this.size, required this.useWebImage});

  final double size;
  final bool useWebImage;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget fallback = Container(
      color: colorScheme.primary.withValues(alpha: 0.10),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.42,
        color: colorScheme.primary,
      ),
    );

    return Semantics(
      label:
          AppLocalizations.of(context)?.aiAssistantAvatarLabel ??
          'Avatar da assistente Lis',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colorScheme.primary,
              Color.lerp(colorScheme.primary, Colors.cyanAccent, 0.62) ??
                  colorScheme.primary,
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child:
              useWebImage
                  ? Image.network(
                    'images/atendente_login_web.webp',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => fallback,
                  )
                  : fallback,
        ),
      ),
    );
  }
}

class _AiAssistantConversationView extends StatelessWidget {
  const _AiAssistantConversationView({
    super.key,
    required this.scrollController,
    required this.l10n,
    required this.isMobile,
    required this.sending,
    required this.error,
    required this.lastQuestion,
    required this.response,
    required this.feedbackSent,
    required this.sendingFeedback,
    required this.onRetry,
    required this.onFeedback,
    required this.onAction,
  });

  final ScrollController scrollController;
  final AppLocalizations? l10n;
  final bool isMobile;
  final bool sending;
  final String? error;
  final String? lastQuestion;
  final AiAssistantResponseModel? response;
  final bool feedbackSent;
  final bool sendingFeedback;
  final VoidCallback onRetry;
  final Future<void> Function(bool helped) onFeedback;
  final void Function(AiAssistantActionModel action) onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 14 : 20,
        isMobile ? 16 : 24,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (error != null)
            _AiAssistantErrorMessage(
              message: error!,
              retryLabel: l10n?.aiAssistantRetry ?? 'Tentar novamente',
              onRetry: sending ? null : onRetry,
            ),
          if (lastQuestion != null)
            AiAssistantMessageBubble(text: lastQuestion!, isUser: true),
          if (sending) ...<Widget>[
            const SizedBox(height: 2),
            SixBackendLoading(
              title: l10n?.aiAssistantThinkingTitle ?? 'Lis está analisando',
              subtitle:
                  l10n?.aiAssistantThinkingSubtitle ??
                  'Buscando a melhor resposta para o contexto desta tela.',
              animation: SixBackendLoadingAnimation.waveDots,
              leadingIcon: Icons.auto_awesome_outlined,
              compact: true,
              borderRadius: 16,
            ),
          ],
          if (response != null) ...<Widget>[
            AiAssistantMessageBubble(text: response!.resposta),
            const SizedBox(height: 10),
            AiAssistantExampleList(
              title: l10n?.aiAssistantExamples ?? 'Exemplos',
              examples: response!.exemplos,
            ),
            if (response!.fontes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                l10n?.aiAssistantSources ?? 'Fontes',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: response!.fontes
                    .map(
                      (String source) => Chip(
                        label: Text(
                          source,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.76,
                          ),
                        ),
                        backgroundColor: colorScheme.surfaceContainerLowest,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (response!.acoes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: response!.acoes
                    .map(
                      (AiAssistantActionModel action) => OutlinedButton.icon(
                        onPressed: () => onAction(action),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(
                          action.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 16),
            AiAssistantFeedbackActions(
              title: l10n?.aiAssistantHelped ?? 'Ajudou?',
              helpedLabel: l10n?.aiAssistantHelpedButton ?? 'Ajudou',
              notHelpedLabel: l10n?.aiAssistantDidNotHelp ?? 'Não ajudou',
              onFeedback: onFeedback,
              loading: sendingFeedback,
              sent: feedbackSent,
            ),
          ],
        ],
      ),
    );
  }
}

class _AiAssistantErrorMessage extends StatelessWidget {
  const _AiAssistantErrorMessage({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _AiAssistantComposer extends StatelessWidget {
  const _AiAssistantComposer({
    required this.controller,
    required this.l10n,
    required this.isMobile,
    required this.sending,
    required this.hasConversation,
    required this.onSend,
    required this.onNewQuestion,
  });

  final TextEditingController controller;
  final AppLocalizations? l10n;
  final bool isMobile;
  final bool sending;
  final bool hasConversation;
  final VoidCallback onSend;
  final VoidCallback onNewQuestion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 24,
        10,
        isMobile ? 14 : 24,
        isMobile ? 14 : 22,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.28),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isMobile ? 0.04 : 0.06),
              blurRadius: isMobile ? 12 : 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Tooltip(
              message:
                  hasConversation
                      ? l10n?.aiAssistantNewQuestion ?? 'Nova pergunta'
                      : l10n?.aiAssistantAttachUnavailable ??
                          'Anexos ainda não disponíveis',
              child: IconButton(
                onPressed: hasConversation && !sending ? onNewQuestion : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  disabledForegroundColor: colorScheme.onSurface.withValues(
                    alpha: 0.36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText:
                      l10n?.aiAssistantHint ?? 'Como posso te ajudar hoje?',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: sending ? null : onSend,
              tooltip: l10n?.aiAssistantSend ?? 'Enviar',
              icon:
                  sending
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                      : const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.primary,
                disabledForegroundColor: colorScheme.primary.withValues(
                  alpha: 0.42,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
