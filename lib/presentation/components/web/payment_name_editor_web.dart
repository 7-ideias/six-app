import 'package:flutter/material.dart';

import '../../../data/models/caixa_models.dart';
import '../../../data/services/caixa/caixa_api_client.dart';
import '../../../domain/services/caixa/caixa_service.dart';
import '../../../l10n/six_i18n.dart';

class PaymentNameEditorWeb extends StatefulWidget {
  const PaymentNameEditorWeb({
    super.key,
    required this.tipo,
    required this.service,
  });
  final TiposRecebimento tipo;
  final CaixaService service;

  @override
  State<PaymentNameEditorWeb> createState() => _PaymentNameEditorWebState();
}

class _PaymentNameEditorWebState extends State<PaymentNameEditorWeb> {
  late final _name = TextEditingController(text: widget.tipo.descricaoExibicao);
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
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
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            error is CaixaApiException && error.statusCode == 403
                ? 'paymentSettings.forbidden'
                : error is CaixaApiException && error.statusCode == 401
                ? 'paymentSettings.expired'
                : 'paymentSettings.saveError';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      icon: const Icon(Icons.edit_outlined),
      title: Text(context.t('paymentSettings.edit')),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.t('paymentSettings.contextHint')),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  enabled: !_saving,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.t('paymentSettings.name'),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? context.t('paymentSettings.required')
                              : null,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      context.t(_error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.t('paymentSettings.cancel')),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.check),
          label: Text(context.t('paymentSettings.save')),
        ),
      ],
    ),
  );
}
