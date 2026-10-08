import 'package:flutter/material.dart';

import '../../../data/models/caixa_models.dart';
import '../../../data/services/caixa/caixa_api_client.dart';
import '../../../domain/services/caixa/caixa_service.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/six_i18n.dart';

String _errorMessage(Object error, String fallback) {
  if (error is CaixaApiException) {
    if (error.statusCode == 403) return 'paymentSettings.forbidden';
    if (error.statusCode == 401) return 'paymentSettings.expired';
  }
  return 'paymentSettings.$fallback';
}

class PaymentNameEditorMobile extends StatefulWidget {
  const PaymentNameEditorMobile({
    super.key,
    required this.tipo,
    required this.service,
  });
  final TiposRecebimento tipo;
  final CaixaService service;

  @override
  State<PaymentNameEditorMobile> createState() =>
      _PaymentNameEditorMobileState();
}

class _PaymentNameEditorMobileState extends State<PaymentNameEditorMobile> {
  late final TextEditingController _name = TextEditingController(
    text: widget.tipo.descricaoExibicao,
  );
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _errorKey;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    try {
      final saved = await widget.service.atualizarNomeTipoRecebimento(
        codigoTipo: widget.tipo.codigoTipo,
        nome: _name.text.trim(),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted)
        setState(() {
          _saving = false;
          _errorKey = _errorMessage(error, 'saveError');
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t('paymentSettings.edit'),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: colors.titleText),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.t('paymentSettings.contextHint'),
                    style: TextStyle(color: colors.mutedText),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    maxLength: 100,
                    enabled: !_saving,
                    autofocus: true,
                    style: TextStyle(color: colors.titleText),
                    decoration: InputDecoration(
                      labelText: context.t('paymentSettings.name'),
                      filled: true,
                      fillColor: colors.surfaceElevated,
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? context.t('paymentSettings.required')
                                : null,
                  ),
                  if (_errorKey != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        context.t(_errorKey!),
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                    ),
                    onPressed: _saving ? null : _save,
                    child:
                        _saving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(context.t('paymentSettings.save')),
                  ),
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(context.t('paymentSettings.cancel')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
