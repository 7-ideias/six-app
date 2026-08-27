import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';

import '../../core/services/notificacao_service.dart';

class NotificacoesMobileScreen extends StatefulWidget {
  const NotificacoesMobileScreen({
    super.key,
    this.marcarComoLidasAoAbrir = true,
  });

  final bool marcarComoLidasAoAbrir;

  @override
  State<NotificacoesMobileScreen> createState() =>
      _NotificacoesMobileScreenState();
}

class _NotificacoesMobileScreenState extends State<NotificacoesMobileScreen> {
  final NotificacaoService _notificacaoService = NotificacaoService();

  @override
  void initState() {
    super.initState();
    _notificacaoService.addListener(_onNotificacoesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.marcarComoLidasAoAbrir) {
        _notificacaoService.marcarTodasComoLidas();
      }
    });
  }

  @override
  void dispose() {
    _notificacaoService.removeListener(_onNotificacoesChanged);
    super.dispose();
  }

  void _onNotificacoesChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<SixNotificationEvent> events = _notificacaoService.notificacoes;
    final Map<String, List<SixNotificationEvent>> groups = _groupEvents(events);

    return SixMobilePageShell(
      title: 'Notificações',
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 4,
      scrollEffectOffset: 24,
      scrolledSurfaceOpacity: 0.66,
      actions: <Widget>[
        if (events.isNotEmpty)
          IconButton(
            tooltip: 'Limpar notificações',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _notificacaoService.limpar,
          ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
            children: [
              if (events.isEmpty)
                _buildEmptyState(context)
              else
                ...groups.entries.map(
                  (entry) => _buildGroup(context, entry.key, entry.value),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: colors.mutedText,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma mensagem recebida ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.titleText,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quando uma nova venda chegar pelo WebSocket, ela aparecerá aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.mutedText, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String title,
    List<SixNotificationEvent> events,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          ...events.map(
            (SixNotificationEvent event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNotificationCard(context, event),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    SixNotificationEvent event,
  ) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool isUnread = event.isUnread;
    final Color cardColor = isUnread ? colors.surfaceElevated : colors.surface;
    final Color cardBorderColor =
        event.isError
            ? colors.errorBorder
            : isUnread
            ? colors.strongBorder
            : colors.border;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showEventDetails(context, event),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.navigationShadow.withValues(alpha: 0.52),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          event.isError
                              ? colors.errorBorder.withValues(alpha: 0.24)
                              : isUnread
                              ? colors.softAccentSurface
                              : colors.iconSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _iconFor(event),
                      color:
                          event.isError
                              ? colors.error
                              : isUnread
                              ? colors.accent
                              : colors.titleText,
                      size: 23,
                    ),
                  ),
                  if (isUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Semantics(
                        label: 'Notificação não lida',
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: event.isError ? colors.error : colors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: cardColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.titleText,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          event.timeLabel,
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _buildChip(
                          context,
                          event.entity,
                          emphasis: _shouldHighlightEntity(event),
                        ),
                        _buildChip(context, event.channel),
                        _buildChip(
                          context,
                          event.status,
                          emphasis: isUnread && !event.isError,
                          isError: event.isError,
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
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label, {
    bool emphasis = false,
    bool isError = false,
  }) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            isError
                ? colors.errorBorder.withValues(alpha: 0.22)
                : emphasis
                ? colors.softAccentSurface
                : colors.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              isError
                  ? colors.errorBorder.withValues(alpha: 0.84)
                  : emphasis
                  ? colors.accent.withValues(alpha: 0.20)
                  : colors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:
              isError
                  ? colors.error
                  : emphasis
                  ? colors.accent
                  : colors.mutedText,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, SixNotificationEvent event) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        final SixMobileColorScheme colors = context.sixMobileColors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.title,
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(color: colors.mutedText, height: 1.4),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(context, 'Entidade', event.entity),
                _buildDetailRow(context, 'Canal', event.channel),
                _buildDetailRow(context, 'Status', event.status),
                _buildDetailRow(context, 'Horário', event.timeLabel),
                if (event.payload['valorTotal'] != null)
                  _buildDetailRow(
                    context,
                    'Valor',
                    event.payload['valorTotal'].toString(),
                  ),
                if (event.payload['quantidadeItens'] != null)
                  _buildDetailRow(
                    context,
                    'Itens',
                    event.payload['quantidadeItens'].toString(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: colors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colors.titleText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<SixNotificationEvent>> _groupEvents(
    List<SixNotificationEvent> events,
  ) {
    final Map<String, List<SixNotificationEvent>> groups =
        <String, List<SixNotificationEvent>>{};

    for (final SixNotificationEvent event in events) {
      groups
          .putIfAbsent(event.groupTitle, () => <SixNotificationEvent>[])
          .add(event);
    }

    return groups;
  }

  bool _shouldHighlightEntity(SixNotificationEvent event) {
    return event.entity.length <= 32 && !event.entity.contains(' ');
  }

  IconData _iconFor(SixNotificationEvent event) {
    final String tipoDeEvento =
        event.payload['tipoDeEvento']?.toString().toUpperCase() ?? '';
    final String channel = event.channel.toUpperCase();

    if (event.isError) {
      return Icons.error_outline_rounded;
    }

    if (tipoDeEvento == 'NOVA_VENDA') {
      return Icons.point_of_sale_rounded;
    }

    if (channel.contains('WHATSAPP') || channel.contains('TELEGRAM')) {
      return Icons.chat_outlined;
    }

    if (channel.contains('EMAIL')) {
      return Icons.mail_outline_rounded;
    }

    return Icons.campaign_rounded;
  }
}
