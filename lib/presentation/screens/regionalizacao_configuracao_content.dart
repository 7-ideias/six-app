import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../domain/models/regionalizacao_models.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';

class RegionalizacaoConfiguracaoContent extends StatefulWidget {
  const RegionalizacaoConfiguracaoContent({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<RegionalizacaoConfiguracaoContent> createState() =>
      _RegionalizacaoConfiguracaoContentState();
}

class _RegionalizacaoConfiguracaoContentState
    extends State<RegionalizacaoConfiguracaoContent> {
  late final RegionalizacaoService _regionalizacaoService;

  ConfiguracaoRegionalizacaoSistema? _configuracaoAtual;
  _LanguageOption _idiomaSelecionado = _LanguageOption.portugues;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  static const List<_LanguageOption> _idiomas = <_LanguageOption>[
    _LanguageOption.portugues,
    _LanguageOption.ingles,
    _LanguageOption.espanhol,
  ];

  @override
  void initState() {
    super.initState();
    _regionalizacaoService = RegionalizacaoService(
      apiClient: HttpRegionalizacaoApiClient(),
    );
    _carregarRegionalizacao();
  }

  Future<void> _carregarRegionalizacao() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final response = await _regionalizacaoService.buscarRegionalizacao();
      final config = _regionalizacaoService.converterResponseParaDominio(
        response,
      );

      if (!mounted) return;
      await context
          .read<LocaleSettingsProvider>()
          .atualizarConfiguracaoDaEmpresa(config);

      setState(() {
        _configuracaoAtual = config;
        _idiomaSelecionado = _LanguageOption.fromConfig(config);
      });
    } catch (e) {
      if (!mounted) return;
      final fallback = context.read<LocaleSettingsProvider>().companyConfig;
      setState(() {
        _configuracaoAtual = fallback;
        _idiomaSelecionado = _LanguageOption.fromConfig(fallback);
        _erro = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _salvar() async {
    final config = _configuracaoAtual;
    if (config == null || _salvando) return;

    final novaConfiguracao = config.copyWith(
      languageCode: _idiomaSelecionado.locale.languageCode,
      countryCode: _idiomaSelecionado.locale.countryCode,
      formatting: config.formatting,
    );

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await context
          .read<LocaleSettingsProvider>()
          .saveCompanyConfigAndApply(novaConfiguracao);

      if (!mounted) return;
      setState(() {
        _configuracaoAtual = novaConfiguracao;
        _idiomaSelecionado = _LanguageOption.fromConfig(novaConfiguracao);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'configuracoes.settingsSaved',
              fallback: 'Configurações salvas com sucesso.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _idiomaSelecionado = _LanguageOption.fromConfig(config);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.t('configuracoes.settingsSaveError', fallback: 'Erro ao salvar configurações')}: $_erro',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.embedded ? 0 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Card(
            elevation: widget.embedded ? 0 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              context.t(
                                'configuracoes.regionalizationTitle',
                                fallback: 'Regionalização',
                              ),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.t(
                                'configuracoes.descRegionalization',
                                fallback:
                                    'Idioma, país, moeda, fuso horário, formatos de data e padronização financeira da empresa.',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<_LanguageOption>(
                    value: _idiomaSelecionado,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'configuracoes.systemLanguage',
                        fallback: 'Idioma do sistema',
                      ),
                      helperText:
                          'Será salvo em /private/api/caixa/configuracoes/regionalizacao',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    items: _idiomas
                        .map(
                          (option) => DropdownMenuItem<_LanguageOption>(
                            value: option,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: _salvando
                        ? null
                        : (option) {
                            if (option == null) return;
                            setState(() => _idiomaSelecionado = option);
                          },
                  ),
                  const SizedBox(height: 18),
                  _buildResumoRegionalizacao(context),
                  if (_erro != null && _erro!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    _buildErro(context),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: _salvando ? null : _carregarRegionalizacao,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          context.t('common.tryAgain', fallback: 'Tentar novamente'),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _salvando ? null : _salvar,
                        icon: _salvando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          context.t('common.save', fallback: 'Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumoRegionalizacao(BuildContext context) {
    final config = _configuracaoAtual;
    if (config == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final formatting = config.formatting;

    final items = <MapEntry<String, String>>[
      MapEntry('languageCode', _idiomaSelecionado.locale.languageCode),
      MapEntry('countryCode', _idiomaSelecionado.locale.countryCode ?? ''),
      MapEntry('currencyCode', formatting.currencyCode),
      MapEntry('timeZone', formatting.timeZone),
      MapEntry('dateFormat', formatting.dateFormat),
      MapEntry('timeFormat', formatting.timeFormat),
      MapEntry('decimalSeparator', formatting.decimalSeparator),
      MapEntry('thousandSeparator', formatting.thousandSeparator),
      MapEntry('firstDayOfWeek', formatting.firstDayOfWeek),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => Chip(
                label: Text('${item.key}: ${item.value}'),
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildErro(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _erro!,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.label,
    required this.locale,
  });

  final String label;
  final Locale locale;

  static const _LanguageOption portugues = _LanguageOption(
    label: 'Português (Brasil)',
    locale: Locale('pt', 'BR'),
  );

  static const _LanguageOption ingles = _LanguageOption(
    label: 'English (US)',
    locale: Locale('en', 'US'),
  );

  static const _LanguageOption espanhol = _LanguageOption(
    label: 'Español',
    locale: Locale('es', 'ES'),
  );

  static _LanguageOption fromConfig(ConfiguracaoRegionalizacaoSistema config) {
    final languageCode = config.languageCode.toLowerCase();
    final countryCode = config.countryCode.toUpperCase();

    if (languageCode == 'en') return ingles;
    if (languageCode == 'es') return espanhol;
    if (languageCode == 'pt' && countryCode == 'BR') return portugues;
    return portugues;
  }

  @override
  bool operator ==(Object other) {
    return other is _LanguageOption &&
        other.locale.languageCode == locale.languageCode &&
        other.locale.countryCode == locale.countryCode;
  }

  @override
  int get hashCode => Object.hash(locale.languageCode, locale.countryCode);
}
