import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/six_i18n.dart';
import '../../../l10n/web_i18n_store.dart';
import '../../../providers/locale_settings_provider.dart';

/// Porta de carregamento para telas que dependem das traduções de UI do
/// backend.
///
/// Como os textos vêm do backend, o conteúdo só é construído quando as mensagens
/// do locale corrente já estão em memória ([SixI18nStore]). Até lá exibe um
/// indicador de carregamento; se a busca terminou sem dados (backend indisponível
/// e sem cache), exibe um estado de erro com fallback mínimo embarcado.
///
/// Usa um [WidgetBuilder] (não um `child` pronto) para que os acessores de i18n
/// só sejam lidos depois que o store estiver populado.
class SixI18nGate extends StatelessWidget {
  const SixI18nGate({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleSettingsProvider>();
    final code = provider.currentLocale.languageCode;

    if (SixI18nStore.instance.hasLanguage(code)) {
      return builder(context);
    }

    // Enquanto o provider não terminou de inicializar ou ainda está buscando,
    // mostra carregamento (evita um flash do estado de erro no cold start).
    if (!provider.initialized || provider.i18nLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                context.t('common.unableToLoad'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: provider.reloadTranslations,
                icon: const Icon(Icons.refresh),
                label: Text(context.t('common.tryAgain')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias de compatibilidade para telas antigas que ainda importam WebI18nGate.
class WebI18nGate extends SixI18nGate {
  const WebI18nGate({super.key, required super.builder});
}
