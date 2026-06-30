import 'package:flutter/material.dart';

class NotificacoesMobileScreen extends StatelessWidget {
  const NotificacoesMobileScreen({super.key});

  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  static const List<_NotificationGroup> _groups = [
    _NotificationGroup(
      title: 'Hoje',
      events: [
        _NotificationEvent(
          time: '11:32',
          title: 'Assistência entrou em revisão',
          description: 'OS #1023 recebeu atualização do backend e aguarda análise técnica.',
          entity: 'Assistência #1023',
          channel: 'APP',
          status: 'NÃO LIDA',
          icon: Icons.handyman_outlined,
          isUnread: true,
        ),
        _NotificationEvent(
          time: '10:48',
          title: 'WhatsApp enviado ao cliente',
          description: 'João recebeu a notificação de orçamento disponível para aprovação.',
          entity: 'Orçamento #556',
          channel: 'WHATSAPP',
          status: 'ENVIADO',
          icon: Icons.chat_outlined,
          isUnread: true,
        ),
        _NotificationEvent(
          time: '09:15',
          title: 'Falha ao enviar email',
          description: 'O backend registrou erro no envio do comprovante para Maria.',
          entity: 'Venda #884',
          channel: 'EMAIL',
          status: 'ERRO',
          icon: Icons.error_outline_rounded,
          isUnread: true,
          isError: true,
        ),
      ],
    ),
    _NotificationGroup(
      title: 'Ontem',
      events: [
        _NotificationEvent(
          time: '17:40',
          title: 'Orçamento aprovado',
          description: 'Cliente aprovou o orçamento e a assistência pode seguir para execução.',
          entity: 'Orçamento #549',
          channel: 'WEBHOOK',
          status: 'PROCESSADO',
          icon: Icons.check_circle_outline_rounded,
        ),
        _NotificationEvent(
          time: '15:22',
          title: 'Venda aguardando pagamento',
          description: 'Venda finalizada no PDV mobile com recebimento pendente.',
          entity: 'Venda #871',
          channel: 'APP',
          status: 'PENDENTE',
          icon: Icons.payments_outlined,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            ..._groups.map((group) => _buildGroup(context, group)),
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
                  'Eventos do backend, webhooks e notificações enviadas ao cliente.',
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
                value: '3',
                label: 'Não lidas',
                icon: Icons.mark_email_unread_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildSummaryCard(
                value: '1',
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

  Widget _buildGroup(BuildContext context, _NotificationGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.title,
            style: const TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          ...group.events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNotificationCard(context, event),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, _NotificationEvent event) {
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
                      event.icon,
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
                          event.time,
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

  void _showEventDetails(BuildContext context, _NotificationEvent event) {
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
                _buildDetailRow('Horário', event.time),
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

class _NotificationGroup {
  const _NotificationGroup({
    required this.title,
    required this.events,
  });

  final String title;
  final List<_NotificationEvent> events;
}

class _NotificationEvent {
  const _NotificationEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.entity,
    required this.channel,
    required this.status,
    required this.icon,
    this.isUnread = false,
    this.isError = false,
  });

  final String time;
  final String title;
  final String description;
  final String entity;
  final String channel;
  final String status;
  final IconData icon;
  final bool isUnread;
  final bool isError;
}
