import 'package:flutter/material.dart';

import '../../core/services/notificacao_service.dart';

class NotificacoesMobileScreen extends StatefulWidget {
  const NotificacoesMobileScreen({super.key});

  @override
  State<NotificacoesMobileScreen> createState() => _NotificacoesMobileScreenState();
}

class _NotificacoesMobileScreenState extends State<NotificacoesMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  final NotificacaoService _notificacaoService = NotificacaoService();

  @override
  void initState() {
    super.initState();
    _notificacaoService.addListener(_onNotificacoesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificacaoService.marcarTodasComoLidas();
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

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Notificações',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          if (events.isNotEmpty)
            IconButton(
              tooltip: 'Limpar notificações',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _notificacaoService.limpar,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            if (events.isEmpty)
              _buildEmptyState()
            else
              ...groups.entries.map(
                (entry) => _buildGroup(context, entry.key, entry.value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          _HeaderIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Central de mensagens',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Mensagens recebidas do backend em tempo real para a empresa atual.',
                  style: TextStyle(
                    color: Color(0xFFD7E3F5),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _buildSummaryCard(
                value: _notificacaoService.total.toString(),
                label: 'Recebidas',
                icon: Icons.notifications_active_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildSummaryCard(
                value: _notificacaoService.comErro.toString(),
                label: 'Com erro',
                icon: Icons.report_problem_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
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
            style: TextStyle(
              color: _mutedTextColor,
              height: 1.35,
            ),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _titleTextColor,
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

  Widget _buildNotificationCard(BuildContext context, SixNotificationEvent event) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showEventDetails(context, event),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: event.isError ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
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
                      color: event.isError
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _iconFor(event),
                      color: event.isError ? const Color(0xFFDC2626) : _primaryColor,
                      size: 23,
                    ),
                  ),
                  if (event.isUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: event.isError ? const Color(0xFFDC2626) : _accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
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
                            style: const TextStyle(
                              color: _titleTextColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          event.timeLabel,
                          style: const TextStyle(
                            color: _mutedTextColor,
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
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
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
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isError ? const Color(0xFFDC2626) : _accentColor,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: const TextStyle(
                    color: _mutedTextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Entidade', event.entity),
                _buildDetailRow('Canal', event.channel),
                _buildDetailRow('Status', event.status),
                _buildDetailRow('Horário', event.timeLabel),
                if (event.payload['valorTotal'] != null)
                  _buildDetailRow('Valor', event.payload['valorTotal'].toString()),
                if (event.payload['quantidadeItens'] != null)
                  _buildDetailRow('Itens', event.payload['quantidadeItens'].toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: _mutedTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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
    final Map<String, List<SixNotificationEvent>> groups = <String, List<SixNotificationEvent>>{};

    for (final SixNotificationEvent event in events) {
      groups.putIfAbsent(event.groupTitle, () => <SixNotificationEvent>[]).add(event);
    }

    return groups;
  }

  IconData _iconFor(SixNotificationEvent event) {
    final String tipoDeEvento = event.payload['tipoDeEvento']?.toString().toUpperCase() ?? '';
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

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
    );
  }
}
