import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_portal_service.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/agenda_email_texts.dart';
import '../../../providers/agenda_email_reenvio_controller.dart';
import '../../../providers/colaborador_autorizacoes_provider.dart';
import 'agenda_email_reenvio_mobile_sheet.dart';

class AgendaEmailReenvioMobileButton extends StatefulWidget {
  const AgendaEmailReenvioMobileButton({
    super.key,
    required this.service,
    required this.idUsuario,
  });

  final AdminPortalService service;
  final String idUsuario;

  @override
  State<AgendaEmailReenvioMobileButton> createState() =>
      _AgendaEmailReenvioMobileButtonState();
}

class _AgendaEmailReenvioMobileButtonState
    extends State<AgendaEmailReenvioMobileButton> {
  bool _aberto = false;

  Future<void> _abrir() async {
    if (_aberto || ModalRoute.of(context)?.isCurrent == false) return;
    setState(() => _aberto = true);
    final controller = AgendaEmailReenvioController(
      widget.service,
      widget.idUsuario,
    );
    try {
      controller.carregar();
      await showAgendaEmailMobileSheet(context, controller);
    } finally {
      controller.dispose();
      if (mounted) setState(() => _aberto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<ColaboradorAutorizacoesProvider>().ehSuperUsuario) {
      return const SizedBox.shrink();
    }
    final colors = context.sixMobileColors;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.accent,
        backgroundColor: colors.softAccentSurface,
        side: BorderSide(color: colors.border),
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: _aberto || widget.idUsuario.isEmpty ? null : _abrir,
      icon: const Icon(Icons.forward_to_inbox_outlined),
      label: Text(agendaEmailText(context, 'action')),
    );
  }
}
