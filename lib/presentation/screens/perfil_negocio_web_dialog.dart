import 'package:flutter/material.dart';

import '../../core/services/perfil_negocio_service.dart';
import '../../l10n/perfil_negocio_texts.dart';
import '../../providers/perfil_negocio_editor_controller.dart';
import '../components/web/perfil_negocio_web_form.dart';
import '../theme/web_theme_tokens.dart';

Future<bool> showPerfilNegocioWebDialog(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PerfilNegocioWebDialog(),
  );
  return result == true;
}

class PerfilNegocioWebDialog extends StatefulWidget {
  const PerfilNegocioWebDialog({super.key});

  @override
  State<PerfilNegocioWebDialog> createState() => _PerfilNegocioWebDialogState();
}

class _PerfilNegocioWebDialogState extends State<PerfilNegocioWebDialog> {
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
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Column(
            children: <Widget>[
              _header(tokens),
              Divider(height: 1, color: tokens.divider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: _content(tokens),
                ),
              ),
              Divider(height: 1, color: tokens.divider),
              _actions(tokens),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(WebThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 18, 20),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  perfilNegocioText(context, 'profile'),
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  perfilNegocioText(context, 'description'),
                  style: TextStyle(
                    color: tokens.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: perfilNegocioText(context, 'cancel'),
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _content(WebThemeTokens tokens) {
    if (_bootstrapError != null) {
      return Center(
        child: Column(
          children: <Widget>[
            Icon(Icons.cloud_off_outlined, color: tokens.danger),
            const SizedBox(height: 10),
            Text(
              perfilNegocioText(context, _bootstrapError!),
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.primaryText),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: () {
                setState(() => _bootstrapError = null);
                _inicializar();
              },
              child: Text(perfilNegocioText(context, 'retry')),
            ),
          ],
        ),
      );
    }
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PerfilNegocioWebForm(controller: _controller!, etapa: _etapa);
  }

  Widget _actions(WebThemeTokens tokens) {
    final PerfilNegocioEditorController? controller = _controller;
    final bool disabled =
        controller == null ||
        controller.carregando ||
        controller.catalogo == null ||
        controller.salvando;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: <Widget>[
          if (_etapa > 0)
            OutlinedButton.icon(
              onPressed: disabled ? null : () => setState(() => _etapa--),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(perfilNegocioText(context, 'back')),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(perfilNegocioText(context, 'cancel')),
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: disabled ? null : _primaryAction,
            icon: controller?.salvando == true
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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
              backgroundColor: const Color(0xFF061D4B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _primaryAction() async {
    final PerfilNegocioEditorController controller = _controller!;
    if (!controller.validarEtapa(_etapa)) return;
    if (_etapa < 2) {
      setState(() => _etapa++);
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(perfilNegocioText(context, 'confirmTitle')),
        content: Text(perfilNegocioText(context, 'confirmBody')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(perfilNegocioText(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(perfilNegocioText(context, 'save')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final bool salvo = await controller.salvar();
    if (salvo && mounted) Navigator.pop(context, true);
  }
}
