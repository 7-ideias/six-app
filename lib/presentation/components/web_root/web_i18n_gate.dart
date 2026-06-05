import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/web_i18n_store.dart';
import '../../../providers/locale_settings_provider.dart';

/// Porta de carregamento para telas que dependem das traduções de UI do
/// backend ([WebRootL10n]).
///
/// Como o app não tem mais textos embutidos, o conteúdo só é construído quando
/// as mensagens do locale corrente já estão em memória ([WebI18nStore]). Até lá
/// exibe um indicador de carregamento; se a busca terminou sem dados (backend
/// indisponível e sem cache), exibe um estado de erro com "tentar novamente".
///
/// Usa um [WidgetBuilder] (não um `child` pronto) para que `WebRootL10n.of` só
/// seja lido depois que o store estiver populado.
class WebI18nGate extends StatelessWidget {
  const WebI18nGate({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleSettingsProvider>();
    final code = provider.currentLocale.languageCode;

    if (WebI18nStore.instance.hasLanguage(code)) {
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
              const Text(
                'Não foi possível carregar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: provider.reloadWebTranslations,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
