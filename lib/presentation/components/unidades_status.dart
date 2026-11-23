import 'package:flutter/material.dart';
import '../../l10n/six_i18n.dart';
import 'six_backend_loading.dart';

class UnidadesStatus extends StatelessWidget {
  const UnidadesStatus({
    super.key,
    required this.erro,
    required this.recarregar,
  });
  final bool erro;
  final VoidCallback recarregar;
  @override
  Widget build(BuildContext context) =>
      erro
          ? TextButton.icon(
            icon: const Icon(Icons.refresh),
            onPressed: recarregar,
            label: Text(context.t('units.retry')),
          )
          : SixBackendLoading(
            compact: true,
            title: context.t('units.loading'),
            subtitle: context.t('units.title'),
          );
}
