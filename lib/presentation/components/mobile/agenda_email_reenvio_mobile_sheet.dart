import 'package:flutter/material.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/agenda_email_texts.dart';
import '../../../providers/agenda_email_reenvio_controller.dart';
import '../six_backend_loading.dart';

Future<void> showAgendaEmailMobileSheet(
  BuildContext context,
  AgendaEmailReenvioController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _AgendaEmailMobileSheet(controller: controller),
  );
}

class _AgendaEmailMobileSheet extends StatelessWidget {
  const _AgendaEmailMobileSheet({required this.controller});
  final AgendaEmailReenvioController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      final colors = context.sixMobileColors;
      return PopScope(
        canPop: !c.enviando,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.strongBorder,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    c.resultado?.status == 'ENVIADO'
                        ? Icons.check_circle_outline
                        : Icons.outgoing_mail,
                    size: 32,
                    color: colors.accent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    agendaEmailText(context, 'title'),
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: colors.titleText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    agendaEmailText(context, 'description'),
                    style: TextStyle(color: colors.mutedText),
                  ),
                  const SizedBox(height: 20),
                  if (c.carregando || c.enviando)
                    SixBackendLoading(
                      title: agendaEmailText(
                        context,
                        c.enviando ? 'sending' : 'loading',
                      ),
                      subtitle: '',
                      compact: true,
                      backgroundColor: colors.softSurface,
                      borderColor: colors.border,
                    )
                  else if (c.destinos.isEmpty && c.mensagem == null)
                    Text(
                      agendaEmailText(context, 'empty'),
                      style: TextStyle(color: colors.mutedText),
                    )
                  else if (c.resultado == null)
                    ...c.destinos.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color:
                              c.selecionado == d
                                  ? colors.softAccentSurface
                                  : colors.softSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  c.selecionado == d
                                      ? colors.accent
                                      : colors.border,
                            ),
                          ),
                          child: Semantics(
                            selected: c.selecionado == d,
                            button: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => c.selecionar(d),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      c.selecionado == d
                                          ? Icons.check_circle
                                          : Icons.storefront_outlined,
                                      color: colors.accent,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d.nomeEmpresa,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: colors.titleText,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            d.email,
                                            style: TextStyle(
                                              color: colors.mutedText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (c.mensagem != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        agendaEmailText(context, c.mensagem!),
                        style: TextStyle(color: colors.titleText),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (c.resultado == null && c.destinos.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.onAccent,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed:
                          c.enviando || c.selecionado == null ? null : c.enviar,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(
                        agendaEmailText(
                          context,
                          c.mensagem == null ? 'confirm' : 'retry',
                        ),
                      ),
                    ),
                  if (!c.carregando && c.destinos.isEmpty && c.mensagem != null)
                    OutlinedButton(
                      onPressed: c.carregar,
                      child: Text(agendaEmailText(context, 'retry')),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.titleText,
                      side: BorderSide(color: colors.border),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed:
                        c.enviando ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      agendaEmailText(
                        context,
                        c.resultado == null ? 'cancel' : 'close',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
