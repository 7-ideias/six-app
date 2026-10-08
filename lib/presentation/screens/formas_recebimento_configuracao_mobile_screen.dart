import '../components/mobile/payment_name_editor_mobile.dart';

import 'package:flutter/material.dart';

import '../../core/di/caixa_module.dart';
import '../../data/models/caixa_models.dart';
import '../../data/services/caixa/caixa_api_client.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../domain/services/caixa/caixa_service.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/six_backend_loading.dart';

class FormasRecebimentoConfiguracaoMobileScreen extends StatefulWidget {
  const FormasRecebimentoConfiguracaoMobileScreen({super.key, this.service});

  final CaixaService? service;

  @override
  State<FormasRecebimentoConfiguracaoMobileScreen> createState() =>
      _FormasRecebimentoConfiguracaoMobileScreenState();
}

class _FormasRecebimentoConfiguracaoMobileScreenState
    extends State<FormasRecebimentoConfiguracaoMobileScreen> {
  late final CaixaService _service = widget.service ?? CaixaModule.caixaService;
  List<TiposRecebimento> _tipos = [];
  bool _loading = true;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorKey = null;
    });
    try {
      final tipos = List<TiposRecebimento>.of(
        await _service.listarTiposRecebimentoConfiguraveis(),
      );
      tipos.sort((a, b) {
        final order = a.ordemExibicao.compareTo(b.ordemExibicao);
        return order != 0 ? order : a.codigoTipo.compareTo(b.codigoTipo);
      });
      if (mounted) setState(() => _tipos = tipos);
    } catch (error) {
      if (mounted)
        setState(() => _errorKey = _errorMessage(error, 'loadError'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(TiposRecebimento tipo) async {
    final saved = await showModalBottomSheet<TiposRecebimento>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: context.sixMobileColors.surface,
      builder: (_) => PaymentNameEditorMobile(tipo: tipo, service: _service),
    );
    if (!mounted || saved == null) return;
    setState(() {
      _tipos = [
        for (final item in _tipos)
          if (item.codigoTipo == saved.codigoTipo) saved else item,
      ];
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t('paymentSettings.saved'))));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sixMobileColors;
    return SixMobilePageShell(
      title: context.t('paymentSettings.title'),
      backgroundColor: colors.background,
      primaryColor: colors.primary,
      secondaryColor: colors.secondary,
      accentColor: colors.accent,
      enableAnimatedBackground: false,
      actions: [
        IconButton(
          tooltip: context.t('paymentSettings.refresh'),
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      bodyBuilder:
          (context, controller, topInset) => RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topInset + 16, 16, 32),
              children: [
                Text(
                  context.t('paymentSettings.hint'),
                  style: TextStyle(color: colors.mutedText),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  SixBackendLoading(
                    title: context.t('paymentSettings.loading'),
                    subtitle: context.t('paymentSettings.hint'),
                  )
                else if (_errorKey != null) ...[
                  Text(
                    context.t(_errorKey!),
                    style: TextStyle(color: colors.error),
                  ),
                  TextButton(
                    onPressed: _load,
                    child: Text(context.t('paymentSettings.refresh')),
                  ),
                ] else if (_tipos.isEmpty)
                  Text(
                    context.t('paymentSettings.empty'),
                    style: TextStyle(color: colors.mutedText),
                  )
                else
                  for (final tipo in _tipos)
                    Card(
                      color: colors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          Icons.payments_outlined,
                          color: colors.primary,
                        ),
                        title: Text(
                          tipo.descricaoExibicao,
                          style: TextStyle(color: colors.titleText),
                        ),
                        subtitle: Text(
                          context.t(
                            tipo.ativo
                                ? 'paymentSettings.active'
                                : 'paymentSettings.inactive',
                          ),
                          style: TextStyle(color: colors.mutedText),
                        ),
                        trailing: IconButton(
                          tooltip: context.t('paymentSettings.edit'),
                          onPressed: () => _edit(tipo),
                          icon: Icon(
                            Icons.edit_outlined,
                            color: colors.primary,
                          ),
                        ),
                        onTap: () => _edit(tipo),
                      ),
                    ),
              ],
            ),
          ),
    );
  }
}

String _errorMessage(Object error, String fallback) {
  if (error is CaixaApiException) {
    if (error.statusCode == 403) return 'paymentSettings.forbidden';
    if (error.statusCode == 401) return 'paymentSettings.expired';
  }
  return 'paymentSettings.$fallback';
}
