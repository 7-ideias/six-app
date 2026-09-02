import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/chat_suporte_models.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/chat_suporte_provider.dart';
import '../../providers/colaborador_autorizacoes_provider.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/six_backend_loading.dart';

class ChatSuporteMobileScreen extends StatefulWidget {
  const ChatSuporteMobileScreen({
    super.key,
    this.idConversaInicial,
    this.idEmpresaInicial,
  });

  final String? idConversaInicial;
  final String? idEmpresaInicial;

  @override
  State<ChatSuporteMobileScreen> createState() =>
      _ChatSuporteMobileScreenState();
}

class _ChatSuporteMobileScreenState extends State<ChatSuporteMobileScreen> {
  static const int _maxImages = 5;
  static const int _maxImageBytes = 5 * 1024 * 1024;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<ChatSuporteImagemUpload> _selectedImages =
      <ChatSuporteImagemUpload>[];

  late final ChatSuporteProvider _provider;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    final bool isSuper = context
        .read<ColaboradorAutorizacoesProvider>()
        .ehSuperUsuario;
    _provider = ChatSuporteProvider(
      ehSuper: isSuper,
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
    _scrollController.dispose();
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
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool showingConversation = _provider.conversaSelecionada != null;
    final String title = _provider.ehSuper && !showingConversation
        ? context.t(
            'chatSupport.mobile.inboxTitle',
            fallback: 'Central de suporte',
          )
        : context.t('chatSupport.title', fallback: 'Suporte');

    return PopScope(
      canPop: !(_provider.ehSuper && showingConversation),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _provider.ehSuper && showingConversation) {
          unawaited(_provider.limparSelecao());
        }
      },
      child: SixMobilePageShell(
        title: title,
        backgroundColor: SixMobilePalette.background,
        primaryColor: SixMobilePalette.primary,
        secondaryColor: SixMobilePalette.secondary,
        accentColor: SixMobilePalette.accent,
        scrollController: _scrollController,
        leading: _provider.ehSuper && showingConversation
            ? IconButton(
                tooltip: context.t('common.back', fallback: 'Voltar'),
                onPressed: _provider.limparSelecao,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        actions: <Widget>[
          IconButton(
            tooltip: context.t('common.refresh', fallback: 'Atualizar'),
            onPressed: _provider.carregando ? null : _provider.atualizar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bodyBuilder: (context, controller, topInset) {
          if (_provider.carregando && _provider.conversaSelecionada == null) {
            return _buildLoading(context, colors, topInset);
          }
          if (_provider.ehSuper && !showingConversation) {
            return _buildInbox(context, colors, controller, topInset);
          }
          return _buildConversation(context, colors, controller, topInset);
        },
      ),
    );
  }

  Widget _buildLoading(
    BuildContext context,
    SixMobileColorScheme colors,
    double topInset,
  ) {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 24),
      children: <Widget>[
        SixBackendLoading.messages(
          title: context.t(
            'chatSupport.loading.title',
            fallback: 'Carregando conversas',
          ),
          subtitle: context.t(
            'chatSupport.loading.subtitle',
            fallback: 'Sincronizando as mensagens com a equipe de suporte.',
          ),
          compact: true,
          backgroundColor: colors.surface,
          borderColor: colors.border,
        ),
      ],
    );
  }

  Widget _buildInbox(
    BuildContext context,
    SixMobileColorScheme colors,
    ScrollController controller,
    double topInset,
  ) {
    return RefreshIndicator(
      onRefresh: _provider.atualizar,
      child: ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 28),
        children: <Widget>[
          _buildInboxSummary(context, colors),
          const SizedBox(height: 14),
          _buildFilters(context, colors),
          if (_provider.erro != null) ...<Widget>[
            const SizedBox(height: 12),
            _buildError(context, colors),
          ],
          const SizedBox(height: 14),
          if (_provider.conversas.isEmpty)
            _buildEmptyInbox(context, colors)
          else
            ..._provider.conversas.map(
              (ChatSuporteConversaModel conversa) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildConversationCard(context, colors, conversa),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInboxSummary(BuildContext context, SixMobileColorScheme colors) {
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.navigationShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.softAccentSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.support_agent_rounded, color: colors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'chatSupport.mobile.queue',
                    fallback: 'Fila de atendimento',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.titleText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context
                      .t(
                        'chatSupport.mobile.queueSummary',
                        fallback:
                            '{waiting} aguardando · {unread} mensagens não lidas',
                      )
                      .replaceAll('{waiting}', waiting.toString())
                      .replaceAll('{unread}', unread.toString()),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, SixMobileColorScheme colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChatSuporteFiltro.values
            .map((ChatSuporteFiltro filtro) {
              final bool selected = _provider.filtro == filtro;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  onSelected: (_) => _provider.alterarFiltro(filtro),
                  label: Text(_filterLabel(context, filtro)),
                  avatar: Icon(_filterIcon(filtro), size: 17),
                  selectedColor: colors.softAccentSurface,
                  backgroundColor: colors.surface,
                  side: BorderSide(
                    color: selected ? colors.accent : colors.border,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? colors.accent : colors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildConversationCard(
    BuildContext context,
    SixMobileColorScheme colors,
    ChatSuporteConversaModel conversa,
  ) {
    final int unread = conversa.naoLidasPeloSuporte;
    return Semantics(
      button: true,
      label: context
          .t(
            'chatSupport.openConversation',
            fallback: 'Abrir conversa de {name}',
          )
          .replaceAll('{name}', conversa.nomeSolicitante),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _provider.selecionarConversa(conversa),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: unread > 0 ? colors.accent : colors.border,
                width: unread > 0 ? 1.3 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                _avatar(colors, conversa.nomeSolicitante),
                const SizedBox(width: 12),
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
                                    color: colors.titleText,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (unread > 0) _unreadBadge(colors, unread),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        conversa.nomeEmpresa,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          _statusChip(context, colors, conversa.status),
                          const Spacer(),
                          Text(
                            _conversationTime(context, conversa),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.mutedText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: colors.mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversation(
    BuildContext context,
    SixMobileColorScheme colors,
    ScrollController controller,
    double topInset,
  ) {
    final ChatSuporteConversaModel? conversa = _provider.conversaSelecionada;
    if (conversa == null) {
      return _buildErrorState(context, colors, topInset);
    }
    final bool canSend =
        !_provider.ehSuper ||
        (conversa.status == ChatSuporteStatus.emAtendimento &&
            _provider.conversaAtribuidaAMim);

    return Column(
      children: <Widget>[
        SizedBox(height: topInset + 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildConversationHeader(context, colors, conversa),
        ),
        if (_provider.erro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _buildError(context, colors),
          ),
        Expanded(
          child: _provider.carregandoMensagens && _provider.mensagens.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
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
                    backgroundColor: colors.surface,
                    borderColor: colors.border,
                  ),
                )
              : _buildMessages(context, colors, controller),
        ),
        if (_provider.ehSuper && !canSend)
          _buildSuperAction(context, colors, conversa)
        else
          _buildComposer(context, colors, conversa),
      ],
    );
  }

  Widget _buildConversationHeader(
    BuildContext context,
    SixMobileColorScheme colors,
    ChatSuporteConversaModel conversa,
  ) {
    final String title = _provider.ehSuper
        ? conversa.nomeSolicitante
        : context.t(
            'chatSupport.teamName',
            fallback: 'Equipe de suporte SixoApp',
          );
    final String retention = context
        .t('chatSupport.retention', fallback: 'histórico por {days} dias')
        .replaceAll('{days}', conversa.retencaoDias.toString());
    final String subtitle = '${conversa.nomeEmpresa} · $retention';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          _provider.ehSuper
              ? _avatar(colors, conversa.nomeSolicitante)
              : Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.softAccentSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: colors.accent,
                  ),
                ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.titleText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.mutedText),
                ),
              ],
            ),
          ),
          _statusChip(context, colors, conversa.status),
          if (_provider.ehSuper && _provider.conversaAtribuidaAMim)
            PopupMenuButton<String>(
              enabled: !_provider.enviando && !_provider.executandoAcao,
              tooltip: context.t(
                'chatSupport.actions.title',
                fallback: 'Ações do atendimento',
              ),
              color: colors.surfaceElevated,
              onSelected: (String value) {
                if (value == 'release') unawaited(_provider.liberar());
                if (value == 'close') unawaited(_confirmClose(context));
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'release',
                  child: Text(
                    context.t(
                      'chatSupport.actions.release',
                      fallback: 'Liberar atendimento',
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'close',
                  child: Text(
                    context.t(
                      'chatSupport.actions.close',
                      fallback: 'Concluir atendimento',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMessages(
    BuildContext context,
    SixMobileColorScheme colors,
    ScrollController controller,
  ) {
    if (_provider.mensagens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.forum_outlined, color: colors.mutedText, size: 38),
              const SizedBox(height: 12),
              Text(
                context.t(
                  'chatSupport.emptyConversation.title',
                  fallback: 'Comece uma conversa',
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.titleText,
                  fontWeight: FontWeight.w800,
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
                ).textTheme.bodyMedium?.copyWith(color: colors.mutedText),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      itemCount: _provider.mensagens.length + (_provider.possuiMais ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (_provider.possuiMais && index == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
        final ChatSuporteMensagemModel mensagem =
            _provider.mensagens[messageIndex];
        final bool showDate =
            messageIndex == 0 ||
            !_sameDay(
              _provider.mensagens[messageIndex - 1].criadaEm,
              mensagem.criadaEm,
            );
        return Column(
          children: <Widget>[
            if (showDate) _dateDivider(context, colors, mensagem.criadaEm),
            _buildMessageBubble(context, colors, mensagem),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    SixMobileColorScheme colors,
    ChatSuporteMensagemModel mensagem,
  ) {
    final bool isMine = _provider.ehSuper
        ? mensagem.remetenteTipo == ChatSuporteRemetenteTipo.superUsuario
        : mensagem.remetenteTipo == ChatSuporteRemetenteTipo.usuario;
    final Color bubbleColor = isMine
        ? colors.softAccentSurface
        : colors.surface;
    final Color borderColor = isMine ? colors.accent : colors.border;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(isMine ? 17 : 5),
            bottomRight: Radius.circular(isMine ? 5 : 17),
          ),
          border: Border.all(color: borderColor.withValues(alpha: 0.72)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_provider.ehSuper || !isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  mensagem.nomeRemetente,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            for (final ChatSuporteArquivoModel arquivo in mensagem.arquivos)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _buildRemoteImage(context, colors, arquivo),
              ),
            if (mensagem.texto != null)
              Text(
                mensagem.texto!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.titleText),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  context.read<LocaleSettingsProvider>().formatTime(
                    mensagem.criadaEm,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.mutedText),
                ),
                if (isMine) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    _wasRead(mensagem)
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 15,
                    color: _wasRead(mensagem)
                        ? colors.accent
                        : colors.mutedText,
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
    SixMobileColorScheme colors,
    ChatSuporteArquivoModel arquivo,
  ) {
    return FutureBuilder<Uint8List>(
      future: _provider.carregarArquivo(arquivo),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 210,
            height: 145,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.softSurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: snapshot.hasError
                ? Icon(Icons.broken_image_outlined, color: colors.error)
                : CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
          );
        }
        return Semantics(
          button: true,
          label: context
              .t('chatSupport.image.open', fallback: 'Abrir imagem {name}')
              .replaceAll('{name}', arquivo.nomeArquivo),
          child: GestureDetector(
            onTap: () =>
                _openImage(context, snapshot.data!, arquivo.nomeArquivo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.memory(
                snapshot.data!,
                width: 210,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 210,
                  height: 145,
                  color: colors.softSurface,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image_outlined, color: colors.error),
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
    SixMobileColorScheme colors,
    ChatSuporteConversaModel conversa,
  ) {
    final bool waiting = conversa.status == ChatSuporteStatus.aguardandoSuporte;
    final String message = waiting
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.mutedText),
              ),
            ),
            if (waiting) ...<Widget>[
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _provider.executandoAcao ? null : _provider.assumir,
                icon: const Icon(Icons.pan_tool_alt_rounded, size: 18),
                label: Text(
                  context.t('chatSupport.actions.take', fallback: 'Assumir'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    SixMobileColorScheme colors,
    ChatSuporteConversaModel conversa,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
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
                    Icon(Icons.refresh_rounded, size: 16, color: colors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.t(
                          'chatSupport.user.reopenHint',
                          fallback:
                              'Sua próxima mensagem reabrirá o atendimento.',
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_selectedImages.isNotEmpty) _buildSelectedImages(colors),
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
                      : () => _showImageSource(colors),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                ),
                const SizedBox(width: 8),
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
                      fillColor: colors.softSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(19),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(19),
                        borderSide: BorderSide(color: colors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: context.t(
                    'chatSupport.send',
                    fallback: 'Enviar mensagem',
                  ),
                  child: IconButton.filled(
                    onPressed: _provider.enviando || _provider.executandoAcao
                        ? null
                        : _sendMessage,
                    icon: _provider.enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImages(SixMobileColorScheme colors) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
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
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImages.removeAt(index)),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: colors.error,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showImageSource(SixMobileColorScheme colors) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.strongBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.t(
                  'chatSupport.attach.title',
                  fallback: 'Adicionar imagem',
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.titleText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _sourceButton(
                      context,
                      colors,
                      icon: Icons.photo_library_outlined,
                      label: context.t(
                        'chatSupport.attach.gallery',
                        fallback: 'Galeria',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        unawaited(_pickFromGallery());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sourceButton(
                      context,
                      colors,
                      icon: Icons.photo_camera_outlined,
                      label: context.t(
                        'chatSupport.attach.camera',
                        fallback: 'Câmera',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        unawaited(_pickFromCamera());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sourceButton(
    BuildContext context,
    SixMobileColorScheme colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colors.softSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: <Widget>[
              Icon(icon, color: colors.accent, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.titleText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> files = await _imagePicker.pickMultiImage(
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    await _addSelectedFiles(files);
  }

  Future<void> _pickFromCamera() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (file != null) await _addSelectedFiles(<XFile>[file]);
  }

  Future<void> _addSelectedFiles(List<XFile> files) async {
    if (!mounted) return;
    final String tooLargeMessage = context.t(
      'chatSupport.attach.tooLarge',
      fallback: 'Cada imagem pode ter no máximo 5 MB.',
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
    final List<ChatSuporteImagemUpload> valid = <ChatSuporteImagemUpload>[];
    for (final XFile file in files.take(available)) {
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.length > _maxImageBytes) {
        _showFeedback(tooLargeMessage);
        continue;
      }
      valid.add(ChatSuporteImagemUpload(nomeArquivo: file.name, dados: bytes));
    }
    if (!mounted || valid.isEmpty) return;
    setState(() => _selectedImages.addAll(valid));
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

  Future<void> _confirmClose(BuildContext context) async {
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final SixMobileColorScheme colors = context.sixMobileColors;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.task_alt_rounded, size: 38, color: colors.accent),
              const SizedBox(height: 12),
              Text(
                context.t(
                  'chatSupport.close.title',
                  fallback: 'Concluir este atendimento?',
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.titleText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t(
                  'chatSupport.close.subtitle',
                  fallback:
                      'Se o usuário enviar outra mensagem, a conversa voltará para a fila.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.mutedText),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        context.t('common.cancel', fallback: 'Cancelar'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        context.t(
                          'chatSupport.actions.close',
                          fallback: 'Concluir',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (confirmed == true) await _provider.encerrar();
  }

  void _openImage(BuildContext context, Uint8List bytes, String name) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(name, overflow: TextOverflow.ellipsis),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Image.memory(bytes),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, SixMobileColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.errorBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorText(context, _provider.erro),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.titleText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInbox(BuildContext context, SixMobileColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.inbox_outlined, size: 38, color: colors.mutedText),
          const SizedBox(height: 12),
          Text(
            context.t(
              'chatSupport.emptyInbox.title',
              fallback: 'Nenhuma conversa nesta fila',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.titleText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            context.t(
              'chatSupport.emptyInbox.subtitle',
              fallback: 'Novas solicitações aparecerão aqui em tempo real.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    SixMobileColorScheme colors,
    double topInset,
  ) {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, topInset + 16, 16, 24),
      children: <Widget>[
        _buildError(context, colors),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _provider.initialize,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            context.t('common.tryAgain', fallback: 'Tentar novamente'),
          ),
        ),
      ],
    );
  }

  Widget _avatar(SixMobileColorScheme colors, String name) {
    final String initial = name.trim().isEmpty
        ? 'S'
        : name.trim()[0].toUpperCase();
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.softAccentSurface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        initial,
        style: TextStyle(color: colors.accent, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _unreadBadge(SixMobileColorScheme colors, int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: SixMobilePalette.notificationBadge,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statusChip(
    BuildContext context,
    SixMobileColorScheme colors,
    ChatSuporteStatus status,
  ) {
    final Color foreground = switch (status) {
      ChatSuporteStatus.aguardandoSuporte => colors.error,
      ChatSuporteStatus.emAtendimento => colors.accent,
      ChatSuporteStatus.encerrada => colors.mutedText,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: foreground.withValues(alpha: 0.32)),
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
    SixMobileColorScheme colors,
    DateTime date,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(color: colors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              context.read<LocaleSettingsProvider>().formatDate(date),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.mutedText),
            ),
          ),
          Expanded(child: Divider(color: colors.border)),
        ],
      ),
    );
  }

  String _filterLabel(BuildContext context, ChatSuporteFiltro filtro) {
    return switch (filtro) {
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

  IconData _filterIcon(ChatSuporteFiltro filtro) {
    return switch (filtro) {
      ChatSuporteFiltro.todas => Icons.forum_outlined,
      ChatSuporteFiltro.aguardando => Icons.schedule_rounded,
      ChatSuporteFiltro.minhas => Icons.person_pin_circle_outlined,
      ChatSuporteFiltro.encerradas => Icons.task_alt_rounded,
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
    if (_sameDay(date, DateTime.now())) return locale.formatTime(date);
    return locale.formatDate(date);
  }

  bool _wasRead(ChatSuporteMensagemModel message) {
    return _provider.ehSuper
        ? message.lidaPeloSolicitanteEm != null
        : message.lidaPeloSuporteEm != null;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
