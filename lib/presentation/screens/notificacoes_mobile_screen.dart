import 'package:flutter/material.dart';
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
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _surfaceElevatedColor => SixMobilePalette.surfaceElevated;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.border;
  static Color get _softAccentColor => SixMobilePalette.softAccentSurface;
  static Color get _iconSurfaceColor => SixMobilePalette.iconSurface;
  static Color get _errorColor => SixMobilePalette.error;
  static Color get _errorBorderColor => SixMobilePalette.errorBorder;

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
            icon: Icon(Icons.delete_outline_rounded),
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
                _buildEmptyState()
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

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: _mutedTextColor,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'Nenhuma mensagem recebida ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Quando uma nova venda chegar pelo WebSocket, ela aparecerá aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor, height: 1.35),
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
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(height: 10),
          ...events.map(
            (SixNotificationEvent event) => Padding(
              padding: EdgeInsets.only(bottom: 12),
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
    return Material(
      color: event.isUnread ? _surfaceElevatedColor : _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showEventDetails(context, event),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: event.isUnread ? _surfaceElevatedColor : _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  event.isError
                      ? _errorBorderColor
                      : event.isUnread
                      ? _accentColor.withValues(alpha: 0.58)
                      : _borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: SixMobilePalette.navigationShadow.withValues(
                  alpha: 0.70,
                ),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          event.isError
                              ? _errorBorderColor.withValues(alpha: 0.22)
                              : _iconSurfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _iconFor(event),
                      color: event.isError ? _errorColor : _primaryColor,
                      size: 23,
                    ),
                  ),
                  if (event.isUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Semantics(
                        label: 'Notificação não lida',
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: event.isError ? _errorColor : _accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: _surfaceColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _titleTextColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          event.timeLabel,
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(event.entity),
                        _buildChip(event.channel),
                        _buildChip(event.status, isError: event.isError),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, {bool isError = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            isError
                ? _errorBorderColor.withValues(alpha: 0.22)
                : _softAccentColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isError ? _errorColor : _accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, SixNotificationEvent event) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(color: _mutedTextColor, height: 1.4),
                ),
                SizedBox(height: 16),
                _buildDetailRow('Entidade', event.entity),
                _buildDetailRow('Canal', event.channel),
                _buildDetailRow('Status', event.status),
                _buildDetailRow('Horário', event.timeLabel),
                if (event.payload['valorTotal'] != null)
                  _buildDetailRow(
                    'Valor',
                    event.payload['valorTotal'].toString(),
                  ),
                if (event.payload['quantidadeItens'] != null)
                  _buildDetailRow(
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: _mutedTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _titleTextColor,
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
