import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../l10n/agenda_email_texts.dart';
import '../../../providers/agenda_email_reenvio_controller.dart';
import '../../theme/web_theme_tokens.dart';
import '../six_backend_loading.dart';

Future<void> showAgendaEmailWebDialog(
  BuildContext context,
  AgendaEmailReenvioController controller,
) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: agendaEmailText(context, 'title'),
    barrierColor: Colors.transparent,
    transitionDuration:
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 280),
    transitionBuilder:
        (context, animation, secondary, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .96, end: 1).animate(animation),
            child: child,
          ),
        ),
    pageBuilder: (_, _, _) => _AgendaEmailWebDialog(controller: controller),
  );
}

class _AgendaEmailWebDialog extends StatefulWidget {
  const _AgendaEmailWebDialog({required this.controller});
  final AgendaEmailReenvioController controller;
  @override
  State<_AgendaEmailWebDialog> createState() => _AgendaEmailWebDialogState();
}

class _AgendaEmailWebDialogState extends State<_AgendaEmailWebDialog> {
  bool _success = false;
  Future<void> _send() async {
    await widget.controller.enviar();
    if (!mounted || widget.controller.resultado?.status != 'ENVIADO') return;
    setState(() => _success = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final t = WebThemeTokens.of(context);
      final busy = c.enviando || _success;
      return PopScope(
        canPop: !busy,
        child: Semantics(
          namesRoute: true,
          label: agendaEmailText(context, 'title'),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: ColoredBox(
                    color: const Color(0xFF06152F).withValues(alpha: .72),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 620),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: t.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: t.cardBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey(_success),
                            tween: Tween(begin: .85, end: 1),
                            duration:
                                MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 650),
                            builder:
                                (_, value, child) =>
                                    Transform.scale(scale: value, child: child),
                            child: Icon(
                              _success
                                  ? Icons.check_circle_outline
                                  : Icons.mark_email_read_outlined,
                              size: 36,
                              color:
                                  _success
                                      ? t.success
                                      : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            agendaEmailText(context, 'title'),
                            style: TextStyle(
                              color: t.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            agendaEmailText(context, 'description'),
                            style: TextStyle(color: t.secondaryText),
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
                              backgroundColor: t.surfaceMuted,
                              borderColor: t.cardBorder,
                            )
                          else if (c.destinos.isEmpty && c.mensagem == null)
                            Text(
                              agendaEmailText(context, 'empty'),
                              style: TextStyle(color: t.secondaryText),
                            )
                          else if (c.resultado == null)
                            ...c.destinos.map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color:
                                      c.selecionado == d
                                          ? t.selectedBackground
                                          : t.surfaceMuted,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Semantics(
                                    selected: c.selecionado == d,
                                    button: true,
                                    child: InkWell(
                                      onTap: () => c.selecionar(d),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Icon(
                                              c.selecionado == d
                                                  ? Icons.radio_button_checked
                                                  : Icons.radio_button_off,
                                              color: t.primaryText,
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
                                                      color: t.primaryText,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  Text(
                                                    d.email,
                                                    style: TextStyle(
                                                      color: t.secondaryText,
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
                                style: TextStyle(
                                  color:
                                      c.resultado?.status == 'ENVIADO'
                                          ? t.success
                                          : t.primaryText,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed:
                                    busy
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                child: Text(
                                  agendaEmailText(
                                    context,
                                    c.resultado == null ? 'cancel' : 'close',
                                  ),
                                ),
                              ),
                              if (c.resultado == null && c.destinos.isNotEmpty)
                                FilledButton.icon(
                                  onPressed:
                                      busy || c.selecionado == null
                                          ? null
                                          : _send,
                                  icon: const Icon(Icons.send_outlined),
                                  label: Text(
                                    agendaEmailText(
                                      context,
                                      c.mensagem == null ? 'confirm' : 'retry',
                                    ),
                                  ),
                                ),
                              if (!c.carregando &&
                                  c.destinos.isEmpty &&
                                  c.mensagem != null)
                                FilledButton(
                                  onPressed: c.carregar,
                                  child: Text(
                                    agendaEmailText(context, 'retry'),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
