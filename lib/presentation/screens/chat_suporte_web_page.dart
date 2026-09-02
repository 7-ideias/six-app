import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/chat_suporte_models.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/chat_suporte_provider.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/six_backend_loading.dart';
import '../components/web/six_web_chat_support_close_dialog.dart';
import '../components/web_dashboard_widgets.dart';
import '../theme/web_theme_tokens.dart';

class ChatSuporteWebPage extends StatefulWidget {
  const ChatSuporteWebPage({
    super.key,
    this.idConversaInicial,
    this.idEmpresaInicial,
  });

  final String? idConversaInicial;
  final String? idEmpresaInicial;

  @override
  State<ChatSuporteWebPage> createState() => _ChatSuporteWebPageState();
}

class _ChatSuporteWebPageState extends State<ChatSuporteWebPage> {
  static const int _maxImages = 5;
  static const int _maxImageBytes = 5 * 1024 * 1024;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<ChatSuporteImagemUpload> _selectedImages =
      <ChatSuporteImagemUpload>[];

  late final ChatSuporteProvider _provider;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _provider = ChatSuporteProvider(
      ehSuper: context.read<ColaboradorAutorizacoesProvider>().ehSuperUsuario,
      idConversaInicial: widget.idConversaInicial,
      idEmpresaInicial: widget.idEmpresaInicial,
    )..addListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_provider.initialize());
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    _messageController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final int messageCount = _provider.mensagens.length;
    final bool shouldScroll =
        messageCount > _lastMessageCount && !_provider.carregandoAnteriores;
    _lastMessageCount = messageCount;
    setState(() {});
    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!_messageScrollController.hasClients) return;
    _messageScrollController.animateTo(
      _messageScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          SixWebDashboardHeader(
            icon: Icons.support_agent_rounded,
            title: _provider.ehSuper
                ? context.t(
                    'chatSupport.web.inboxTitle',
                    fallback: 'Central de suporte',
                  )
                : context.t('chatSupport.title', fallback: 'Suporte'),
            subtitle: _provider.ehSuper
                ? context.t(
                    'chatSupport.web.inboxSubtitle',
                    fallback:
                        'Atenda solicitações em tempo real e acompanhe o histórico.',
                  )
                : context.t(
                    'chatSupport.web.subtitle',
                    fallback:
                        'Converse diretamente com a equipe de suporte SixoApp.',
                  ),
            actions: <Widget>[
              OutlinedButton.icon(
                onPressed: _provider.carregando ? null : _provider.atualizar,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.t('common.refresh', fallback: 'Atualizar')),
              ),
            ],
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: _buildBody(context, tokens)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WebThemeTokens tokens) {
    if (_provider.carregando && _provider.conversaSelecionada == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SixBackendLoading.messages(
            title: context.t(
              'chatSupport.loading.title',
              fallback: 'Carregando conversas',
            ),
            subtitle: context.t(
              'chatSupport.loading.subtitle',
              fallback: 'Sincronizando as mensagens com a equipe de suporte.',
            ),
            backgroundColor: tokens.surface,
            borderColor: tokens.cardBorder,
          ),
        ),
      );
    }

    if (!_provider.ehSuper) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: _surface(tokens, child: _buildConversation(context, tokens)),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 900;
        if (compact) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _surface(
              tokens,
              child: _provider.conversaSelecionada == null
                  ? _buildInbox(context, tokens)
                  : _buildConversation(context, tokens, compact: true),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: _surface(
            tokens,
            child: Row(
              children: <Widget>[
                SizedBox(width: 370, child: _buildInbox(context, tokens)),
                VerticalDivider(width: 1, color: tokens.divider),
                Expanded(
                  child: _provider.conversaSelecionada == null
                      ? _buildNoSelection(context, tokens)
                      : _buildConversation(context, tokens),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _surface(WebThemeTokens tokens, {required Widget child}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInbox(BuildContext context, WebThemeTokens tokens) {
    return Column(
      children: <Widget>[
        _buildInboxSummary(context, tokens),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: _buildFilters(context, tokens),
        ),
        if (_provider.erro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: _buildError(context, tokens),
          ),
        Expanded(
          child: _provider.conversas.isEmpty
              ? _buildEmptyInbox(context, tokens)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 14),
                  itemCount: _provider.conversas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
                  itemBuilder: (BuildContext context, int index) =>
                      _buildConversationTile(
                        context,
                        tokens,
                        _provider.conversas[index],
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildInboxSummary(BuildContext context, WebThemeTokens tokens) {
    final int waiting = _provider.conversas
        .where(
          (ChatSuporteConversaModel item) =>
              item.status == ChatSuporteStatus.aguardandoSuporte,
        )
        .length;
    final int unread = _provider.conversas.fold<int>(
      0,
      (int total, ChatSuporteConversaModel item) =>
          total + item.naoLidasPeloSuporte,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border(bottom: BorderSide(color: tokens.divider)),
      ),
      child: Row(
        children: <Widget>[
          _metric(
            context,
            tokens,
            icon: Icons.schedule_rounded,
            value: waiting.toString(),
            label: context.t(
              'chatSupport.metric.waiting',
              fallback: 'aguardando',
            ),
            color: tokens.warning,
          ),
          const SizedBox(width: 12),
          _metric(
            context,
            tokens,
            icon: Icons.mark_chat_unread_outlined,
            value: unread.toString(),
            label: context.t(
              'chatSupport.metric.unread',
              fallback: 'não lidas',
            ),
            color: tokens.info,
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    WebThemeTokens tokens, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: tokens.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WebThemeTokens tokens) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ChatSuporteFiltro.values
          .map((ChatSuporteFiltro filter) {
            final bool selected = _provider.filtro == filter;
            return ChoiceChip(
              selected: selected,
              onSelected: (_) => _provider.alterarFiltro(filter),
              label: Text(_filterLabel(context, filter)),
              selectedColor: tokens.selectedBackground,
              backgroundColor: tokens.surface,
              side: BorderSide(
                color: selected ? tokens.selectedBorder : tokens.cardBorder,
              ),
              labelStyle: TextStyle(
                color: selected ? tokens.info : tokens.secondaryText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              visualDensity: VisualDensity.compact,
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    WebThemeTokens tokens,
    ChatSuporteConversaModel conversa,
  ) {
    final bool selected = _provider.conversaSelecionada?.id == conversa.id;
    final int unread = conversa.naoLidasPeloSuporte;
    return Semantics(
      button: true,
      selected: selected,
      label: context
          .t(
            'chatSupport.openConversation',
            fallback: 'Abrir conversa de {name}',
          )
          .replaceAll('{name}', conversa.nomeSolicitante),
      child: Material(
        color: selected ? tokens.selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _provider.selecionarConversa(conversa),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected
                    ? tokens.selectedBorder
                    : unread > 0
                    ? tokens.info.withValues(alpha: 0.52)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: <Widget>[
                _avatar(tokens, conversa.nomeSolicitante),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              conversa.nomeSolicitante,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: tokens.primaryText,
                                    fontWeight: unread > 0
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (unread > 0) _unreadBadge(tokens, unread),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conversa.nomeEmpresa,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.mutedText,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: <Widget>[
                          _statusChip(context, tokens, conversa.status),
                          const Spacer(),
                          Text(
                            _conversationTime(context, conversa),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: tokens.mutedText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversation(
    BuildContext context,
    WebThemeTokens tokens, {
    bool compact = false,
  }) {
    final ChatSuporteConversaModel? conversa = _provider.conversaSelecionada;
    if (conversa == null) return _buildErrorState(context, tokens);
    final bool canSend =
        !_provider.ehSuper ||
        (conversa.status == ChatSuporteStatus.emAtendimento &&
            _provider.conversaAtribuidaAMim);
    return Column(
      children: <Widget>[
        _buildConversationHeader(context, tokens, conversa, compact: compact),
        if (_provider.erro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: _buildError(context, tokens),
          ),
        Expanded(
          child: _provider.carregandoMensagens && _provider.mensagens.isEmpty
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SixBackendLoading.messages(
                      title: context.t(
                        'chatSupport.loading.messages',
                        fallback: 'Buscando mensagens',
                      ),
                      subtitle: context.t(
                        'chatSupport.loading.secureHistory',
                        fallback: 'Carregando o histórico protegido.',
                      ),
                      compact: true,
                      backgroundColor: tokens.surface,
                      borderColor: tokens.cardBorder,
                    ),
                  ),
                )
              : _buildMessages(context, tokens),
        ),
        if (_provider.ehSuper && !canSend)
          _buildSuperAction(context, tokens, conversa)
        else
          _buildComposer(context, tokens, conversa),
      ],
    );
  }

  Widget _buildConversationHeader(
    BuildContext context,
    WebThemeTokens tokens,
    ChatSuporteConversaModel conversa, {
    required bool compact,
  }) {
    final String title = _provider.ehSuper
        ? conversa.nomeSolicitante
        : context.t(
            'chatSupport.teamName',
            fallback: 'Equipe de suporte SixoApp',
          );
    final String retention = context
        .t('chatSupport.retention', fallback: 'histórico por {days} dias')
        .replaceAll('{days}', conversa.retencaoDias.toString());
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border(bottom: BorderSide(color: tokens.divider)),
      ),
      child: Row(
        children: <Widget>[
          if (compact && _provider.ehSuper) ...<Widget>[
            IconButton(
              tooltip: context.t('common.back', fallback: 'Voltar'),
              onPressed: _provider.limparSelecao,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
          ],
          _provider.ehSuper
              ? _avatar(tokens, conversa.nomeSolicitante)
              : Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tokens.info.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.support_agent_rounded, color: tokens.info),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${conversa.nomeEmpresa} · $retention',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
                ),
              ],
            ),
          ),
          _statusChip(context, tokens, conversa.status),
          if (_provider.ehSuper && _provider.conversaAtribuidaAMim) ...<Widget>[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              enabled: !_provider.enviando && !_provider.executandoAcao,
              tooltip: context.t(
                'chatSupport.actions.title',
                fallback: 'Ações do atendimento',
              ),
              color: tokens.menuBackground,
              onSelected: (String action) {
                if (action == 'release') unawaited(_provider.liberar());
                if (action == 'close') unawaited(_confirmClose(conversa));
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'release',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_remove_alt_1_outlined),
                    title: Text(
                      context.t(
                        'chatSupport.actions.release',
                        fallback: 'Liberar atendimento',
                      ),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'close',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.task_alt_rounded),
                    title: Text(
                      context.t(
                        'chatSupport.actions.close',
                        fallback: 'Concluir atendimento',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessages(BuildContext context, WebThemeTokens tokens) {
    if (_provider.mensagens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.forum_outlined, color: tokens.mutedText, size: 44),
              const SizedBox(height: 14),
              Text(
                context.t(
                  'chatSupport.emptyConversation.title',
                  fallback: 'Comece uma conversa',
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.t(
                  'chatSupport.emptyConversation.subtitle',
                  fallback:
                      'Conte o que está acontecendo. Você também pode enviar imagens.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.secondaryText),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _messageScrollController,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
      itemCount: _provider.mensagens.length + (_provider.possuiMais ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (_provider.possuiMais && index == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextButton.icon(
                onPressed: _provider.carregandoAnteriores
                    ? null
                    : _provider.carregarAnteriores,
                icon: _provider.carregandoAnteriores
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.history_rounded),
                label: Text(
                  context.t(
                    'chatSupport.loadOlder',
                    fallback: 'Carregar mensagens anteriores',
                  ),
                ),
              ),
            ),
          );
        }
        final int messageIndex = index - (_provider.possuiMais ? 1 : 0);
        final ChatSuporteMensagemModel message =
            _provider.mensagens[messageIndex];
        final bool showDate =
            messageIndex == 0 ||
            !_sameDay(
              _provider.mensagens[messageIndex - 1].criadaEm,
              message.criadaEm,
            );
        return Column(
          children: <Widget>[
            if (showDate) _dateDivider(context, tokens, message.criadaEm),
            _buildMessageBubble(context, tokens, message),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    WebThemeTokens tokens,
    ChatSuporteMensagemModel message,
  ) {
    final bool mine = _provider.ehSuper
        ? message.remetenteTipo == ChatSuporteRemetenteTipo.superUsuario
        : message.remetenteTipo == ChatSuporteRemetenteTipo.usuario;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: mine ? tokens.selectedBackground : tokens.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 5),
            bottomRight: Radius.circular(mine ? 5 : 18),
          ),
          border: Border.all(
            color: mine ? tokens.selectedBorder : tokens.cardBorder,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_provider.ehSuper || !mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  message.nomeRemetente,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.info,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            for (final ChatSuporteArquivoModel file in message.arquivos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRemoteImage(context, tokens, file),
              ),
            if (message.texto != null)
              SelectableText(
                message.texto!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.primaryText,
                  height: 1.38,
                ),
              ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  context.read<LocaleSettingsProvider>().formatTime(
                    message.criadaEm,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: tokens.mutedText),
                ),
                if (mine) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    _wasRead(message)
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 16,
                    color: _wasRead(message) ? tokens.info : tokens.mutedText,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteImage(
    BuildContext context,
    WebThemeTokens tokens,
    ChatSuporteArquivoModel file,
  ) {
    return FutureBuilder<Uint8List>(
      future: _provider.carregarArquivo(file),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 300,
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: snapshot.hasError
                ? Icon(Icons.broken_image_outlined, color: tokens.danger)
                : CircularProgressIndicator(strokeWidth: 2, color: tokens.info),
          );
        }
        return Semantics(
          button: true,
          label: context
              .t('chatSupport.image.open', fallback: 'Abrir imagem {name}')
              .replaceAll('{name}', file.nomeArquivo),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openImage(snapshot.data!, file.nomeArquivo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                snapshot.data!,
                width: 300,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 300,
                  height: 180,
                  color: tokens.surfaceMuted,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: tokens.danger,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuperAction(
    BuildContext context,
    WebThemeTokens tokens,
    ChatSuporteConversaModel conversa,
  ) {
    final bool waiting = conversa.status == ChatSuporteStatus.aguardandoSuporte;
    final String text = waiting
        ? context.t(
            'chatSupport.super.takeHint',
            fallback: 'Assuma a conversa para responder ao usuário.',
          )
        : conversa.status == ChatSuporteStatus.encerrada
        ? context.t(
            'chatSupport.super.closedHint',
            fallback: 'A conversa será reaberta quando o usuário responder.',
          )
        : context
              .t(
                'chatSupport.super.assignedOther',
                fallback: 'Atendimento com {name}.',
              )
              .replaceAll(
                '{name}',
                conversa.nomeSuperResponsavel ?? 'outro SUPER',
              );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            waiting ? Icons.pan_tool_alt_outlined : Icons.info_outline_rounded,
            color: waiting ? tokens.info : tokens.mutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.secondaryText),
            ),
          ),
          if (waiting) ...<Widget>[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _provider.executandoAcao ? null : _provider.assumir,
              icon: const Icon(Icons.pan_tool_alt_rounded, size: 18),
              label: Text(
                context.t(
                  'chatSupport.actions.take',
                  fallback: 'Assumir atendimento',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    WebThemeTokens tokens,
    ChatSuporteConversaModel conversa,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (conversa.status == ChatSuporteStatus.encerrada &&
              !_provider.ehSuper)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Icon(Icons.refresh_rounded, size: 17, color: tokens.info),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      context.t(
                        'chatSupport.user.reopenHint',
                        fallback:
                            'Sua próxima mensagem reabrirá o atendimento.',
                      ),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedImages.isNotEmpty) _buildSelectedImages(tokens),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              IconButton.filledTonal(
                tooltip: context.t(
                  'chatSupport.attach',
                  fallback: 'Adicionar imagem',
                ),
                onPressed: _provider.enviando || _provider.executandoAcao
                    ? null
                    : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !_provider.enviando && !_provider.executandoAcao,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: context.t(
                      'chatSupport.composer.hint',
                      fallback: 'Digite uma mensagem',
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: tokens.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: tokens.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: tokens.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _provider.enviando || _provider.executandoAcao
                    ? null
                    : _sendMessage,
                icon: _provider.enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 19),
                label: Text(context.t('chatSupport.send', fallback: 'Enviar')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImages(WebThemeTokens tokens) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 10),
        itemCount: _selectedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final ChatSuporteImagemUpload image = _selectedImages[index];
          return Stack(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  image.dados,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 3,
                top: 3,
                child: IconButton.filled(
                  tooltip: context.t(
                    'chatSupport.attach.remove',
                    fallback: 'Remover imagem',
                  ),
                  onPressed: () =>
                      setState(() => _selectedImages.removeAt(index)),
                  icon: const Icon(Icons.close_rounded, size: 15),
                  style: IconButton.styleFrom(
                    backgroundColor: tokens.surfaceElevated.withValues(
                      alpha: 0.94,
                    ),
                    foregroundColor: tokens.danger,
                    minimumSize: const Size(26, 26),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImages() async {
    final String tooLargeMessage = context.t(
      'chatSupport.attach.tooLarge',
      fallback: 'Cada imagem pode ter no máximo 5 MB.',
    );
    final String readErrorMessage = context.t(
      'chatSupport.attach.readError',
      fallback: 'Não foi possível carregar as imagens selecionadas.',
    );
    final int available = _maxImages - _selectedImages.length;
    if (available <= 0) {
      _showFeedback(
        context.t(
          'chatSupport.attach.limit',
          fallback: 'Você pode enviar até 5 imagens por mensagem.',
        ),
      );
      return;
    }
    try {
      final List<XFile> files = await _imagePicker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      final List<ChatSuporteImagemUpload> valid = <ChatSuporteImagemUpload>[];
      for (final XFile file in files.take(available)) {
        final Uint8List bytes = await file.readAsBytes();
        if (bytes.length > _maxImageBytes) {
          _showFeedback(tooLargeMessage);
          continue;
        }
        valid.add(
          ChatSuporteImagemUpload(nomeArquivo: file.name, dados: bytes),
        );
      }
      if (!mounted || valid.isEmpty) return;
      setState(() => _selectedImages.addAll(valid));
    } catch (_) {
      _showFeedback(readErrorMessage);
    }
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;
    final bool sent = await _provider.enviarMensagem(
      texto: text,
      imagens: List<ChatSuporteImagemUpload>.from(_selectedImages),
    );
    if (!sent || !mounted) return;
    _messageController.clear();
    setState(_selectedImages.clear);
    _scrollToBottom();
  }

  Future<void> _confirmClose(ChatSuporteConversaModel conversa) async {
    await showSixWebChatSupportCloseDialog(
      context: context,
      requesterName: conversa.nomeSolicitante,
      companyName: conversa.nomeEmpresa,
      onConfirm: () async {
        final bool closed = await _provider.encerrar();
        if (!closed) throw StateError('chat-support-close-failed');
      },
    );
  }

  Future<void> _openImage(Uint8List bytes, String name) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.86),
      builder: (BuildContext context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(child: Image.memory(bytes)),
              ),
            ),
            Positioned(
              top: 18,
              left: 22,
              right: 22,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: context.t('common.close', fallback: 'Fechar'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelection(BuildContext context, WebThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tokens.info.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_outlined, color: tokens.info, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              context.t(
                'chatSupport.web.selectTitle',
                fallback: 'Selecione uma conversa',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              context.t(
                'chatSupport.web.selectSubtitle',
                fallback:
                    'Escolha uma solicitação na fila para visualizar o histórico.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInbox(BuildContext context, WebThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.inbox_outlined, size: 40, color: tokens.mutedText),
            const SizedBox(height: 12),
            Text(
              context.t(
                'chatSupport.emptyInbox.title',
                fallback: 'Nenhuma conversa nesta fila',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.t(
                'chatSupport.emptyInbox.subtitle',
                fallback: 'Novas solicitações aparecerão aqui em tempo real.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WebThemeTokens tokens) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildError(context, tokens),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _provider.initialize,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.t('common.tryAgain', fallback: 'Tentar novamente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WebThemeTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorText(context, _provider.erro),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(WebThemeTokens tokens, String name) {
    final String initial = name.trim().isEmpty
        ? 'S'
        : name.trim()[0].toUpperCase();
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.info.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Text(
        initial,
        style: TextStyle(color: tokens.info, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _unreadBadge(WebThemeTokens tokens, int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tokens.info, shape: BoxShape.circle),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: tokens.onInfo,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statusChip(
    BuildContext context,
    WebThemeTokens tokens,
    ChatSuporteStatus status,
  ) {
    final Color foreground = switch (status) {
      ChatSuporteStatus.aguardandoSuporte => tokens.warning,
      ChatSuporteStatus.emAtendimento => tokens.info,
      ChatSuporteStatus.encerrada => tokens.statusNeutral,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: foreground.withValues(alpha: 0.30)),
      ),
      child: Text(
        _statusLabel(context, status),
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _dateDivider(
    BuildContext context,
    WebThemeTokens tokens,
    DateTime date,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(color: tokens.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              context.read<LocaleSettingsProvider>().formatDate(date),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.mutedText),
            ),
          ),
          Expanded(child: Divider(color: tokens.divider)),
        ],
      ),
    );
  }

  String _filterLabel(BuildContext context, ChatSuporteFiltro filter) {
    return switch (filter) {
      ChatSuporteFiltro.todas => context.t(
        'chatSupport.filter.all',
        fallback: 'Todas',
      ),
      ChatSuporteFiltro.aguardando => context.t(
        'chatSupport.filter.waiting',
        fallback: 'Aguardando',
      ),
      ChatSuporteFiltro.minhas => context.t(
        'chatSupport.filter.mine',
        fallback: 'Minhas',
      ),
      ChatSuporteFiltro.encerradas => context.t(
        'chatSupport.filter.closed',
        fallback: 'Encerradas',
      ),
    };
  }

  String _statusLabel(BuildContext context, ChatSuporteStatus status) {
    return switch (status) {
      ChatSuporteStatus.aguardandoSuporte => context.t(
        'chatSupport.status.waiting',
        fallback: 'Aguardando',
      ),
      ChatSuporteStatus.emAtendimento => context.t(
        'chatSupport.status.inService',
        fallback: 'Em atendimento',
      ),
      ChatSuporteStatus.encerrada => context.t(
        'chatSupport.status.closed',
        fallback: 'Encerrada',
      ),
    };
  }

  String _conversationTime(
    BuildContext context,
    ChatSuporteConversaModel conversa,
  ) {
    final DateTime date = conversa.ultimaMensagemEm ?? conversa.atualizadaEm;
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    return _sameDay(date, DateTime.now())
        ? locale.formatTime(date)
        : locale.formatDate(date);
  }

  bool _wasRead(ChatSuporteMensagemModel message) {
    return _provider.ehSuper
        ? message.lidaPeloSolicitanteEm != null
        : message.lidaPeloSuporteEm != null;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _errorText(BuildContext context, String? code) {
    return switch (code) {
      'CHAT_SUPORTE_CONVERSA_JA_ASSUMIDA' => context.t(
        'chatSupport.error.alreadyAssigned',
        fallback: 'Outro SUPER assumiu esta conversa.',
      ),
      'CHAT_SUPORTE_ATENDIMENTO_NAO_ATRIBUIDO' => context.t(
        'chatSupport.error.notAssigned',
        fallback: 'Assuma a conversa antes de responder.',
      ),
      'CHAT_SUPORTE_LIMITE_IMAGENS_EXCEDIDO' => context.t(
        'chatSupport.error.imageLimit',
        fallback: 'O limite é de 5 imagens por mensagem.',
      ),
      'CHAT_SUPORTE_IMAGEM_MUITO_GRANDE' ||
      'CHAT_SUPORTE_UPLOAD_MUITO_GRANDE' => context.t(
        'chatSupport.error.imageTooLarge',
        fallback: 'Uma das imagens ultrapassa o limite de 5 MB.',
      ),
      'CHAT_SUPORTE_FORMATO_IMAGEM_NAO_SUPORTADO' => context.t(
        'chatSupport.error.imageFormat',
        fallback: 'Use imagens JPG, PNG ou WebP.',
      ),
      'CHAT_SUPORTE_MENSAGEM_VAZIA' => context.t(
        'chatSupport.error.emptyMessage',
        fallback: 'Digite uma mensagem ou selecione uma imagem.',
      ),
      'CHAT_SUPORTE_SEM_ACESSO_EMPRESA' ||
      'CHAT_SUPORTE_ACESSO_NEGADO' ||
      'CHAT_SUPORTE_EMPRESA_DIVERGENTE' => context.t(
        'chatSupport.error.forbidden',
        fallback: 'Você não possui acesso a esta conversa.',
      ),
      _ => context.t(
        'chatSupport.error.generic',
        fallback: 'Não foi possível atualizar o chat. Tente novamente.',
      ),
    };
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
