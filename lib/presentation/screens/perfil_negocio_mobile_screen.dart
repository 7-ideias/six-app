import 'package:flutter/material.dart';

import '../../core/services/perfil_negocio_service.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../l10n/perfil_negocio_texts.dart';
import '../../providers/perfil_negocio_editor_controller.dart';
import '../components/mobile/perfil_negocio_mobile_form.dart';
import '../components/mobile/six_mobile_page_shell.dart';

class PerfilNegocioMobileScreen extends StatefulWidget {
  const PerfilNegocioMobileScreen({super.key});

  @override
  State<PerfilNegocioMobileScreen> createState() =>
      _PerfilNegocioMobileScreenState();
}

class _PerfilNegocioMobileScreenState extends State<PerfilNegocioMobileScreen> {
  PerfilNegocioEditorController? _controller;
  String? _bootstrapError;
  int _etapa = 0;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final PerfilNegocioService service = PerfilNegocioService();
    try {
      final String empresaId = await service.empresaAtual();
      if (!mounted) {
        service.dispose();
        return;
      }
      final PerfilNegocioEditorController controller =
          PerfilNegocioEditorController(empresaId: empresaId, service: service);
      controller.addListener(_onControllerChanged);
      setState(() => _controller = controller);
      await controller.carregar();
    } catch (_) {
      service.dispose();
      if (mounted) setState(() => _bootstrapError = 'loadError');
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return SixMobilePageShell(
      title: perfilNegocioText(context, 'profile'),
      backgroundColor: colors.background,
      primaryColor: colors.primary,
      secondaryColor: colors.secondary,
      accentColor: colors.accent,
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 28),
          children: <Widget>[
            if (_bootstrapError != null)
              _BootstrapError(
                text: perfilNegocioText(context, _bootstrapError!),
                onRetry: () {
                  setState(() => _bootstrapError = null);
                  _inicializar();
                },
              )
            else if (_controller == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: colors.accent),
                ),
              )
            else ...<Widget>[
              PerfilNegocioMobileForm(
                controller: _controller!,
                etapa: _etapa,
              ),
              const SizedBox(height: 22),
              _actions(colors),
            ],
          ],
        );
      },
    );
  }

  Widget _actions(SixMobileColorScheme colors) {
    final PerfilNegocioEditorController controller = _controller!;
    if (controller.carregando || controller.catalogo == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: <Widget>[
        if (_etapa > 0) ...<Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.salvando
                  ? null
                  : () => setState(() => _etapa--),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(perfilNegocioText(context, 'back')),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.titleText,
                side: BorderSide(color: colors.strongBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: controller.salvando ? null : _primaryAction,
            icon: controller.salvando
                ? SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onAccent,
                    ),
                  )
                : Icon(
                    _etapa == 2
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
            label: Text(
              perfilNegocioText(
                context,
                _etapa == 2 ? 'save' : 'continue',
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _primaryAction() async {
    final PerfilNegocioEditorController controller = _controller!;
    if (!controller.validarEtapa(_etapa)) return;
    if (_etapa < 2) {
      setState(() => _etapa++);
      return;
    }
    if (!await _confirmar()) return;
    final bool salvo = await controller.salvar();
    if (salvo && mounted) Navigator.of(context).pop(true);
  }

  Future<bool> _confirmar() async {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  perfilNegocioText(context, 'confirmTitle'),
                  style: TextStyle(
                    color: colors.titleText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  perfilNegocioText(context, 'confirmBody'),
                  style: TextStyle(
                    color: colors.mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: Text(perfilNegocioText(context, 'cancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: Text(perfilNegocioText(context, 'save')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.errorBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, color: colors.error),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.titleText),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(perfilNegocioText(context, 'retry')),
          ),
        ],
      ),
    );
  }
}
