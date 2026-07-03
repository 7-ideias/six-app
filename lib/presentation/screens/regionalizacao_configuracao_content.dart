import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/regionalizacao_models.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile_motion.dart';

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
  final TextEditingController _numberPatternController =
      TextEditingController();

  ConfiguracaoRegionalizacaoSistema? _configuracaoAtual;
  _LanguageOption _idiomaSelecionado = _LanguageOption.portugues;
  _RegionalizacaoOption _paisSelecionado = _countryOptions.first;
  _RegionalizacaoOption _moedaSelecionada = _currencyOptions.first;
  _RegionalizacaoOption _timeZoneSelecionado = _timeZoneOptions.first;
  _RegionalizacaoOption _dateFormatSelecionado = _dateFormatOptions.first;
  _RegionalizacaoOption _timeFormatSelecionado = _timeFormatOptions.first;
  _RegionalizacaoOption _decimalSeparatorSelecionado =
      _decimalSeparatorOptions.first;
  _RegionalizacaoOption _thousandSeparatorSelecionado =
      _thousandSeparatorOptions.first;
  _RegionalizacaoOption _firstDaySelecionado = _firstDayOptions.first;
  int _decimalPlaces = 2;
  bool _allowMultipleCurrencies = false;
  bool _applyFinancialRounding = true;
  bool _carregando = true;
  String? _erro;

  static const List<_LanguageOption> _idiomas = <_LanguageOption>[
    _LanguageOption.portugues,
    _LanguageOption.ingles,
    _LanguageOption.espanhol,
  ];

  static const List<_RegionalizacaoOption> _countryOptions =
      <_RegionalizacaoOption>[
    _RegionalizacaoOption(
      value: 'BR',
      labelKey: 'configuracoes.countryBrazil',
      labelFallback: 'Brasil',
      subtitleFallback: 'pt-BR',
    ),
    _RegionalizacaoOption(
      value: 'US',
      labelKey: 'configuracoes.countryUnitedStates',
      labelFallback: 'Estados Unidos',
      subtitleFallback: 'en-US',
    ),
    _RegionalizacaoOption(
      value: 'ES',
      labelKey: 'configuracoes.countrySpain',
      labelFallback: 'Espanha',
      subtitleFallback: 'es-ES',
    ),
  ];

  static const List<_RegionalizacaoOption> _currencyOptions =
      <_RegionalizacaoOption>[
    _RegionalizacaoOption(
      value: 'BRL',
      labelKey: 'configuracoes.currencyBrl',
      labelFallback: 'Real brasileiro',
      subtitleFallback: 'BRL',
    ),
    _RegionalizacaoOption(
      value: 'USD',
      labelKey: 'configuracoes.currencyUsd',
      labelFallback: 'Dólar americano',
      subtitleFallback: 'USD',
    ),
    _RegionalizacaoOption(
      value: 'EUR',
      labelKey: 'configuracoes.currencyEur',
      labelFallback: 'Euro',
      subtitleFallback: 'EUR',
    ),
    _RegionalizacaoOption(
      value: 'ARS',
      labelKey: 'configuracoes.currencyArs',
      labelFallback: 'Peso argentino',
      subtitleFallback: 'ARS',
    ),
    _RegionalizacaoOption(
      value: 'MXN',
      labelKey: 'configuracoes.currencyMxn',
      labelFallback: 'Peso mexicano',
      subtitleFallback: 'MXN',
    ),
  ];

  static const List<_RegionalizacaoOption> _timeZoneOptions =
      <_RegionalizacaoOption>[
    _RegionalizacaoOption(
      value: 'America/Sao_Paulo',
      labelKey: 'configuracoes.timeZoneSaoPaulo',
      labelFallback: 'São Paulo',
      subtitleFallback: 'America/Sao_Paulo',
    ),
    _RegionalizacaoOption(
      value: 'America/New_York',
      labelKey: 'configuracoes.timeZoneNewYork',
      labelFallback: 'Nova York',
      subtitleFallback: 'America/New_York',
    ),
    _RegionalizacaoOption(
      value: 'Europe/Madrid',
      labelKey: 'configuracoes.timeZoneMadrid',
      labelFallback: 'Madri',
      subtitleFallback: 'Europe/Madrid',
    ),
    _RegionalizacaoOption(
      value: 'UTC',
      labelKey: 'configuracoes.timeZoneUtc',
      labelFallback: 'UTC',
      subtitleFallback: 'UTC',
    ),
  ];

  static const List<_RegionalizacaoOption> _dateFormatOptions =
      <_RegionalizacaoOption>[
    _RegionalizacaoOption(
      value: 'dd/MM/yyyy',
      labelKey: 'configuracoes.dateFormatBr',
      labelFallback: '31/12/2026',
      subtitleFallback: 'dd/MM/yyyy',
    ),
    _RegionalizacaoOption(
      value: 'MM/dd/yyyy',
      labelKey: 'configuracoes.dateFormatUs',
      labelFallback: '12/31/2026',
      subtitleFallback: 'MM/dd/yyyy',
    ),
    _RegionalizacaoOption(
      value: 'yyyy-MM-dd',
      labelKey: 'configuracoes.dateFormatIso',
      labelFallback: '2026-12-31',
      subtitleFallback: 'yyyy-MM-dd',
    ),
  ];

  static const List<_RegionalizacaoOption> _timeFormatOptions =
      <_RegionalizacaoOption>[
    _RegionalizacaoOption(
      value: '24h',
      labelKey: 'configuracoes.timeFormat24h',
      labelFallback: '24 horas',
      subtitleFallback: '18:30',
    ),
    _RegionalizacaoOption(
      value: '12h',
      labelKey: 'configuracoes.timeFormat12h',
      labelFallback: '12 horas',
      subtitleFallback: '06:30 PM',
    ),
  ];

  static const List<_RegionalizacaoOption> _decimalSeparatorOptions =
      <_RegionalizacaoOption>[
    _RegionalizacaoOption(
      value: ',',
      labelKey: 'configuracoes.decimalComma',
      labelFallback: 'Vírgula',
      subtitleFallback: '10,50',
    ),
    _RegionalizacaoOption(
      value: '.',
      labelKey: 'configuracoes.decimalDot',
      labelFallback: 'Ponto',
      subtitleFallback: '10.50',
    ),
  ];

  static const List<_RegionalizacaoOption> _thousandSeparatorOptions =
      <_RegionalizacaoOption>[
    _RegionalizacaoOption(
      value: '.',
      labelKey: 'configuracoes.thousandDot',
      labelFallback: 'Ponto',
      subtitleFallback: '1.000',
    ),
    _RegionalizacaoOption(
      value: ',',
      labelKey: 'configuracoes.thousandComma',
      labelFallback: 'Vírgula',
      subtitleFallback: '1,000',
    ),
    _RegionalizacaoOption(
      value: ' ',
      labelKey: 'configuracoes.thousandSpace',
      labelFallback: 'Espaço',
      subtitleFallback: '1 000',
    ),
  ];

  static const List<_RegionalizacaoOption> _firstDayOptions =
      <_RegionalizacaoOption>[
    _RegionalizacaoOption(
      value: 'MONDAY',
      labelKey: 'common.monday',
      labelFallback: 'Segunda-feira',
      subtitleFallback: 'MONDAY',
    ),
    _RegionalizacaoOption(
      value: 'SUNDAY',
      labelKey: 'common.sunday',
      labelFallback: 'Domingo',
      subtitleFallback: 'SUNDAY',
    ),
    _RegionalizacaoOption(
      value: 'SATURDAY',
      labelKey: 'common.saturday',
      labelFallback: 'Sábado',
      subtitleFallback: 'SATURDAY',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carregarRegionalizacao();
  }

  @override
  void dispose() {
    _numberPatternController.dispose();
    super.dispose();
  }

  Future<void> _carregarRegionalizacao() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final config = await context
          .read<LocaleSettingsProvider>()
          .carregarRegionalizacaoDaEmpresa();

      if (!mounted) return;
      setState(() => _aplicarConfiguracao(config));
    } catch (e) {
      if (!mounted) return;
      final fallback = context.read<LocaleSettingsProvider>().companyConfig;
      setState(() {
        _aplicarConfiguracao(fallback);
        _erro = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _salvar() async {
    final provider = context.read<LocaleSettingsProvider>();
    if (provider.regionalizacaoSaving) return;

    FocusScope.of(context).unfocus();
    final novaConfiguracao = _montarConfiguracaoAtualizada();

    setState(() => _erro = null);

    try {
      final configSalva = await provider.saveCompanyConfigAndApply(
        novaConfiguracao,
      );

      if (!mounted) return;
      setState(() => _aplicarConfiguracao(configSalva));
      _mostrarMensagem(
        context.t(
          'common.savedSuccessfully',
          fallback: 'Configurações salvas com sucesso.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
      _mostrarMensagem(
        '${context.t('configuracoes.settingsSaveError', fallback: 'Erro ao salvar configurações')}: $_erro',
        erro: true,
      );
    }
  }

  void _aplicarConfiguracao(ConfiguracaoRegionalizacaoSistema config) {
    final formatting = config.formatting;
    _configuracaoAtual = config;
    _idiomaSelecionado = _LanguageOption.fromConfig(config);
    _paisSelecionado = _optionFromValue(_countryOptions, config.countryCode);
    _moedaSelecionada = _optionFromValue(
      _currencyOptions,
      formatting.currencyCode,
    );
    _timeZoneSelecionado = _optionFromValue(
      _timeZoneOptions,
      formatting.timeZone,
    );
    _dateFormatSelecionado = _optionFromValue(
      _dateFormatOptions,
      formatting.dateFormat,
    );
    _timeFormatSelecionado = _optionFromValue(
      _timeFormatOptions,
      formatting.timeFormat,
    );
    _decimalSeparatorSelecionado = _optionFromValue(
      _decimalSeparatorOptions,
      formatting.decimalSeparator,
    );
    _thousandSeparatorSelecionado = _optionFromValue(
      _thousandSeparatorOptions,
      formatting.thousandSeparator,
    );
    _firstDaySelecionado = _optionFromValue(
      _firstDayOptions,
      formatting.firstDayOfWeek,
    );
    _decimalPlaces = formatting.decimalPlaces.clamp(0, 6).toInt();
    _allowMultipleCurrencies = formatting.allowMultipleCurrencies;
    _applyFinancialRounding = formatting.applyFinancialRounding;
    _numberPatternController.text = formatting.numberPattern;
  }

  ConfiguracaoRegionalizacaoSistema _montarConfiguracaoAtualizada() {
    final config = _configuracaoAtual ??
        ConfiguracaoRegionalizacaoSistema.defaultConfiguration();
    final pattern = _numberPatternController.text.trim().isEmpty
        ? _suggestNumberPattern()
        : _numberPatternController.text.trim();

    return config.copyWith(
      languageCode: _idiomaSelecionado.locale.languageCode,
      countryCode: _paisSelecionado.value,
      formatting: config.formatting.copyWith(
        currencyCode: _moedaSelecionada.value,
        timeZone: _timeZoneSelecionado.value,
        dateFormat: _dateFormatSelecionado.value,
        timeFormat: _timeFormatSelecionado.value,
        decimalSeparator: _decimalSeparatorSelecionado.value,
        thousandSeparator: _thousandSeparatorSelecionado.value,
        firstDayOfWeek: _firstDaySelecionado.value,
        numberPattern: pattern,
        decimalPlaces: _decimalPlaces,
        allowMultipleCurrencies: _allowMultipleCurrencies,
        applyFinancialRounding: _applyFinancialRounding,
      ),
    );
  }

  _RegionalizacaoOption _optionFromValue(
    List<_RegionalizacaoOption> options,
    String value,
  ) {
    for (final option in options) {
      if (option.value == value) return option;
    }

    return _RegionalizacaoOption(
      value: value,
      labelKey: 'configuracoes.customRegionalValue',
      labelFallback: value.isEmpty ? 'Não informado' : value,
      subtitleFallback: value,
    );
  }

  List<_RegionalizacaoOption> _optionsWithSelected(
    List<_RegionalizacaoOption> options,
    _RegionalizacaoOption selected,
  ) {
    if (options.any((option) => option.value == selected.value)) {
      return options;
    }

    return <_RegionalizacaoOption>[selected, ...options];
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            erro ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleSettingsProvider>();
    final padding = widget.embedded
        ? EdgeInsets.zero
        : const EdgeInsets.fromLTRB(16, 16, 16, 24);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight =
            widget.embedded || !constraints.hasBoundedHeight
                ? 0
                : (constraints.maxHeight - 40)
                    .clamp(0, constraints.maxHeight)
                    .toDouble();

        return SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.embedded ? 1160 : 760,
                minHeight: minHeight,
              ),
              child: SixStaggeredEntry(
                delay: const Duration(milliseconds: 70),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints inner) {
                    return _buildContent(
                      context,
                      inner.maxWidth,
                      provider,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    double availableWidth,
    LocaleSettingsProvider provider,
  ) {
    final theme = Theme.of(context);

    if (_carregando || provider.regionalizacaoLoading) {
      return _RegionalizacaoSkeleton(embedded: widget.embedded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!widget.embedded) _buildMobileHero(context),
        if (!widget.embedded) const SizedBox(height: 18),
        _buildPreviewCard(context, theme, provider),
        const SizedBox(height: 16),
        if (_erro != null && _erro!.isNotEmpty) ...<Widget>[
          _buildErro(context),
          const SizedBox(height: 16),
        ],
        _buildIdiomaLocalizacaoCard(context, theme),
        const SizedBox(height: 16),
        _buildFormatosCard(context, theme),
        const SizedBox(height: 16),
        _buildFinanceiroCard(context, theme),
        const SizedBox(height: 18),
        _buildActions(context, provider),
      ],
    );
  }

  Widget _buildMobileHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0B1F3A), Color(0xFF123B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Icon(Icons.language_rounded, color: Colors.white),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(
                    'configuracoes.descRegionalization',
                    fallback:
                        'Idioma, país, moeda, fuso horário e padrões financeiros da empresa.',
                  ),
                  style: const TextStyle(color: Color(0xCCE2E8F0), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    ThemeData theme,
    LocaleSettingsProvider provider,
  ) {
    final draft = _montarConfiguracaoAtualizada();
    final sampleProvider = _RegionalizacaoPreviewFormatter(draft);
    final now = DateTime(2026, 12, 31, 18, 30);

    final items = <_RegionalizacaoPreviewItem>[
      _RegionalizacaoPreviewItem(
        icon: Icons.payments_rounded,
        label: context.t('configuracoes.currencyPreview', fallback: 'Moeda'),
        value: sampleProvider.formatCurrency(1234.5),
      ),
      _RegionalizacaoPreviewItem(
        icon: Icons.calendar_month_rounded,
        label: context.t('configuracoes.datePreview', fallback: 'Data'),
        value: sampleProvider.formatDate(now),
      ),
      _RegionalizacaoPreviewItem(
        icon: Icons.access_time_rounded,
        label: context.t('configuracoes.timePreview', fallback: 'Hora'),
        value: sampleProvider.formatTime(now),
      ),
      _RegionalizacaoPreviewItem(
        icon: Icons.public_rounded,
        label: context.t('configuracoes.activeLocale', fallback: 'Locale'),
        value: '${_idiomaSelecionado.locale.languageCode}-${_paisSelecionado.value}',
      ),
    ];

    return _RegionalizacaoCard(
      embedded: widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSectionHeader(
            context: context,
            icon: Icons.visibility_rounded,
            title: context.t(
              'configuracoes.regionalizationPreview',
              fallback: 'Prévia aplicada ao app',
            ),
            subtitle: context.t(
              'configuracoes.regionalizationPreviewDescription',
              fallback:
                  'Esses exemplos mostram como moeda, números, datas e horas ficarão disponíveis para outras telas via Provider.',
            ),
            trailing: _buildStatusBadge(
              context: context,
              theme: theme,
              icon: Icons.hub_rounded,
              label: provider.currencyCode,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 760;
              final double spacing = 12;
              final double itemWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: _buildPreviewItem(context, theme, item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(
    BuildContext context,
    ThemeData theme,
    _RegionalizacaoPreviewItem item,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(item.icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdiomaLocalizacaoCard(BuildContext context, ThemeData theme) {
    return _RegionalizacaoCard(
      embedded: widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSectionHeader(
            context: context,
            icon: Icons.translate_rounded,
            title: context.t(
              'configuracoes.localeGroup',
              fallback: 'Idioma e localização',
            ),
            subtitle: context.t(
              'configuracoes.localeGroupDescription',
              fallback:
                  'Define o idioma da empresa, país/região, fuso horário e primeiro dia da semana.',
            ),
            trailing: _buildStatusBadge(
              context: context,
              theme: theme,
              icon: Icons.edit_rounded,
              label: context.t('common.editable', fallback: 'Editável'),
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          _buildLanguageOptions(context, theme),
          const SizedBox(height: 18),
          _buildOptionGroup(
            context: context,
            theme: theme,
            title: context.t('configuracoes.countryCode', fallback: 'País/região'),
            icon: Icons.flag_rounded,
            options: _optionsWithSelected(_countryOptions, _paisSelecionado),
            selected: _paisSelecionado,
            onSelected: (option) => setState(() => _paisSelecionado = option),
          ),
          const SizedBox(height: 18),
          _buildOptionGroup(
            context: context,
            theme: theme,
            title: context.t('configuracoes.timeZone', fallback: 'Fuso horário'),
            icon: Icons.schedule_rounded,
            options: _optionsWithSelected(_timeZoneOptions, _timeZoneSelecionado),
            selected: _timeZoneSelecionado,
            onSelected: (option) => setState(() => _timeZoneSelecionado = option),
          ),
          const SizedBox(height: 18),
          _buildOptionGroup(
            context: context,
            theme: theme,
            title: context.t(
              'configuracoes.firstDayOfWeek',
              fallback: 'Primeiro dia da semana',
            ),
            icon: Icons.event_available_rounded,
            options: _optionsWithSelected(_firstDayOptions, _firstDaySelecionado),
            selected: _firstDaySelecionado,
            onSelected: (option) => setState(() => _firstDaySelecionado = option),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOptions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildGroupTitle(
          context,
          theme,
          Icons.language_rounded,
          context.t('configuracoes.systemLanguage', fallback: 'Idioma do sistema'),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 720;
            final double spacing = compact ? 10 : 12;
            final double itemWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - (spacing * 2)) / 3;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: _idiomas
                  .map(
                    (option) => SizedBox(
                      width: itemWidth,
                      child: _buildLanguageOption(
                        context: context,
                        theme: theme,
                        option: option,
                        selected: option == _idiomaSelecionado,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required ThemeData theme,
    required _LanguageOption option,
    required bool selected,
  }) {
    return _SelectableContainer(
      selected: selected,
      onTap: () => setState(() => _idiomaSelecionado = option),
      child: Row(
        children: <Widget>[
          _buildOptionIcon(theme, option.badge, selected),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  option.label(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  option.description(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildSelectedIcon(theme, selected),
        ],
      ),
    );
  }

  Widget _buildFormatosCard(BuildContext context, ThemeData theme) {
    return _RegionalizacaoCard(
      embedded: widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSectionHeader(
            context: context,
            icon: Icons.format_list_numbered_rounded,
            title: context.t(
              'configuracoes.formattingGroup',
              fallback: 'Formatos',
            ),
            subtitle: context.t(
              'configuracoes.formattingGroupDescription',
              fallback:
                  'Controla como datas, horas, números e casas decimais serão exibidos no app.',
            ),
          ),
          const SizedBox(height: 20),
          _buildOptionGroup(
            context: context,
            theme: theme,
            title: context.t('configuracoes.dateFormat', fallback: 'Formato de data'),
            icon: Icons.calendar_month_rounded,
            options: _optionsWithSelected(_dateFormatOptions, _dateFormatSelecionado),
            selected: _dateFormatSelecionado,
            onSelected: (option) => setState(() => _dateFormatSelecionado = option),
          ),
          const SizedBox(height: 18),
          _buildOptionGroup(
            context: context,
            theme: theme,
            title: context.t('configuracoes.timeFormat', fallback: 'Formato de hora'),
            icon: Icons.access_time_rounded,
            options: _optionsWithSelected(_timeFormatOptions, _timeFormatSelecionado),
            selected: _timeFormatSelecionado,
            onSelected: (option) => setState(() => _timeFormatSelecionado = option),
          ),
          const SizedBox(height: 18),
          _buildOptionGroup(
            context: context,
            theme: theme,
            title: context.t(
              'configuracoes.decimalSeparator',
              fallback: 'Separador decimal',
            ),
            icon: Icons.more_horiz_rounded,
            options: _optionsWithSelected(
              _decimalSeparatorOptions,
              _decimalSeparatorSelecionado,
            ),
            selected: _decimalSeparatorSelecionado,
            onSelected: (option) {
              setState(() {
                _decimalSeparatorSelecionado = option;
                if (_thousandSeparatorSelecionado.value == option.value) {
                  _thousandSeparatorSelecionado = _thousandSeparatorOptions
                      .firstWhere((item) => item.value != option.value);
                }
                _numberPatternController.text = _suggestNumberPattern();
              });
            },
          ),
          const SizedBox(height: 18),
          _buildOptionGroup(
            context: context,
            theme: theme,
            title: context.t(
              'configuracoes.thousandSeparator',
              fallback: 'Separador de milhar',
            ),
            icon: Icons.drag_indicator_rounded,
            options: _optionsWithSelected(
              _thousandSeparatorOptions,
              _thousandSeparatorSelecionado,
            ),
            selected: _thousandSeparatorSelecionado,
            onSelected: (option) {
              setState(() {
                _thousandSeparatorSelecionado = option;
                if (_decimalSeparatorSelecionado.value == option.value) {
                  _decimalSeparatorSelecionado = _decimalSeparatorOptions
                      .firstWhere((item) => item.value != option.value);
                }
                _numberPatternController.text = _suggestNumberPattern();
              });
            },
          ),
          const SizedBox(height: 18),
          _buildDecimalPlacesSelector(context, theme),
          const SizedBox(height: 18),
          _buildNumberPatternField(context, theme),
        ],
      ),
    );
  }

  Widget _buildFinanceiroCard(BuildContext context, ThemeData theme) {
    return _RegionalizacaoCard(
      embedded: widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSectionHeader(
            context: context,
            icon: Icons.payments_rounded,
            title: context.t(
              'configuracoes.financialGroup',
              fallback: 'Financeiro',
            ),
            subtitle: context.t(
              'configuracoes.financialGroupDescription',
              fallback:
                  'Define a moeda principal e deixa regras financeiras disponíveis globalmente no app.',
            ),
          ),
          const SizedBox(height: 20),
          _buildOptionGroup(
            context: context,
            theme: theme,
            title: context.t('configuracoes.currencyCode', fallback: 'Moeda'),
            icon: Icons.account_balance_wallet_rounded,
            options: _optionsWithSelected(_currencyOptions, _moedaSelecionada),
            selected: _moedaSelecionada,
            onSelected: (option) => setState(() => _moedaSelecionada = option),
          ),
          const SizedBox(height: 18),
          _buildSwitchCard(
            context: context,
            theme: theme,
            value: _allowMultipleCurrencies,
            icon: Icons.currency_exchange_rounded,
            title: context.t(
              'configuracoes.allowMultipleCurrencies',
              fallback: 'Permitir múltiplas moedas',
            ),
            subtitle: context.t(
              'configuracoes.allowMultipleCurrenciesDescription',
              fallback:
                  'Apenas persiste a preferência. O fluxo de venda multi-moedas não é alterado nesta etapa.',
            ),
            onChanged: (value) => setState(() => _allowMultipleCurrencies = value),
          ),
          const SizedBox(height: 12),
          _buildSwitchCard(
            context: context,
            theme: theme,
            value: _applyFinancialRounding,
            icon: Icons.calculate_rounded,
            title: context.t(
              'configuracoes.applyFinancialRounding',
              fallback: 'Aplicar arredondamento financeiro',
            ),
            subtitle: context.t(
              'configuracoes.applyFinancialRoundingDescription',
              fallback:
                  'Disponibiliza a regra para cálculos e formatações financeiras centralizadas.',
            ),
            onChanged: (value) => setState(() => _applyFinancialRounding = value),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionGroup({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<_RegionalizacaoOption> options,
    required _RegionalizacaoOption selected,
    required ValueChanged<_RegionalizacaoOption> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildGroupTitle(context, theme, icon, title),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 760;
            final double spacing = 10;
            final double itemWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: options
                  .map(
                    (option) => SizedBox(
                      width: itemWidth,
                      child: _SelectableContainer(
                        selected: option.value == selected.value,
                        onTap: () => onSelected(option),
                        child: Row(
                          children: <Widget>[
                            _buildOptionIcon(
                              theme,
                              option.value.trim().isEmpty
                                  ? '—'
                                  : option.value.trim(),
                              option.value == selected.value,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    option.label(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    option.subtitle(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildSelectedIcon(theme, option.value == selected.value),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDecimalPlacesSelector(BuildContext context, ThemeData theme) {
    final options = <int>[0, 1, 2, 3, 4, 5, 6];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildGroupTitle(
          context,
          theme,
          Icons.exposure_plus_1_rounded,
          context.t('configuracoes.decimalPlaces', fallback: 'Casas decimais'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (value) => ChoiceChip(
                  label: Text(value.toString()),
                  selected: _decimalPlaces == value,
                  onSelected: (_) {
                    setState(() {
                      _decimalPlaces = value;
                      _numberPatternController.text = _suggestNumberPattern();
                    });
                  },
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNumberPatternField(BuildContext context, ThemeData theme) {
    return TextField(
      controller: _numberPatternController,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: context.t(
          'configuracoes.numberPattern',
          fallback: 'Padrão numérico',
        ),
        helperText: context.t(
          'configuracoes.numberPatternDescription',
          fallback:
              'Valor técnico enviado ao backend para futuras formatações avançadas.',
        ),
        prefixIcon: const Icon(Icons.pin_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildSwitchCard({
    required BuildContext context,
    required ThemeData theme,
    required bool value,
    required IconData icon,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        secondary: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, LocaleSettingsProvider provider) {
    final bool saving = provider.regionalizacaoSaving;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 520;

        final Widget reloadButton = OutlinedButton.icon(
          onPressed: saving ? null : _carregarRegionalizacao,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            context.t('common.reload', fallback: 'Recarregar'),
          ),
        );

        final Widget saveButton = FilledButton.icon(
          onPressed: saving ? null : _salvar,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            saving
                ? context.t('common.saving', fallback: 'Salvando...')
                : context.t('common.saveChanges', fallback: 'Salvar alterações'),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              saveButton,
              const SizedBox(height: 10),
              reloadButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            reloadButton,
            const SizedBox(width: 12),
            saveButton,
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 560;

        final Widget titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (trailing == null) return titleBlock;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              titleBlock,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: trailing),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            trailing,
          ],
        );
      },
    );
  }

  Widget _buildGroupTitle(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String title,
  ) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionIcon(ThemeData theme, String value, bool selected) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.withOpacity(0.12)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: value.length > 3 ? 11 : 13,
          fontWeight: FontWeight.w900,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSelectedIcon(ThemeData theme, bool selected) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: selected
          ? Icon(
              Icons.check_circle_rounded,
              key: const ValueKey<String>('selected'),
              color: theme.colorScheme.primary,
            )
          : Icon(
              Icons.radio_button_unchecked_rounded,
              key: const ValueKey<String>('unselected'),
              color: theme.colorScheme.outline,
            ),
    );
  }

  Widget _buildStatusBadge({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErro(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _erro!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _carregando ? null : _carregarRegionalizacao,
            child: Text(
              context.t('common.tryAgain', fallback: 'Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }

  String _suggestNumberPattern() {
    final decimals = _decimalPlaces <= 0
        ? ''
        : '${_decimalSeparatorSelecionado.value}${'0' * _decimalPlaces}';
    return '#${_thousandSeparatorSelecionado.value}##0$decimals';
  }
}

class _SelectableContainer extends StatelessWidget {
  const _SelectableContainer({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color borderColor =
        selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;
    final Color backgroundColor = selected
        ? theme.colorScheme.primary.withOpacity(0.08)
        : theme.colorScheme.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RegionalizacaoCard extends StatelessWidget {
  const _RegionalizacaoCard({
    required this.child,
    required this.embedded,
  });

  final Widget child;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(embedded ? 22 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(embedded ? 0.03 : 0.05),
            blurRadius: embedded ? 18 : 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RegionalizacaoSkeleton extends StatelessWidget {
  const _RegionalizacaoSkeleton({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _RegionalizacaoCard(
      embedded: embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _skeletonBox(width: 48, height: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _skeletonBox(width: 220, height: 18),
                    const SizedBox(height: 8),
                    _skeletonBox(width: 360, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _skeletonBox(width: 240, height: 72),
              _skeletonBox(width: 240, height: 72),
              _skeletonBox(width: 240, height: 72),
            ],
          ),
          const SizedBox(height: 18),
          _skeletonBox(width: double.infinity, height: 110),
          const SizedBox(height: 12),
          _skeletonBox(width: double.infinity, height: 110),
        ],
      ),
    );
  }

  Widget _skeletonBox({required double width, required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.35, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(opacity: value, child: child);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _RegionalizacaoOption {
  const _RegionalizacaoOption({
    required this.value,
    required this.labelKey,
    required this.labelFallback,
    required this.subtitleFallback,
  });

  final String value;
  final String labelKey;
  final String labelFallback;
  final String subtitleFallback;

  String label(BuildContext context) {
    return context.t(labelKey, fallback: labelFallback);
  }

  String subtitle(BuildContext context) => subtitleFallback;
}

class _LanguageOption {
  const _LanguageOption({
    required this.labelKey,
    required this.labelFallback,
    required this.descriptionKey,
    required this.descriptionFallback,
    required this.badge,
    required this.locale,
  });

  final String labelKey;
  final String labelFallback;
  final String descriptionKey;
  final String descriptionFallback;
  final String badge;
  final Locale locale;

  String label(BuildContext context) {
    return context.t(labelKey, fallback: labelFallback);
  }

  String description(BuildContext context) {
    return context.t(descriptionKey, fallback: descriptionFallback);
  }

  static const _LanguageOption portugues = _LanguageOption(
    labelKey: 'configuracoes.languagePortuguese',
    labelFallback: 'Português',
    descriptionKey: 'configuracoes.languagePortugueseDescription',
    descriptionFallback: 'Brasil • pt-BR',
    badge: 'PT',
    locale: Locale('pt', 'BR'),
  );

  static const _LanguageOption ingles = _LanguageOption(
    labelKey: 'configuracoes.languageEnglish',
    labelFallback: 'English',
    descriptionKey: 'configuracoes.languageEnglishDescription',
    descriptionFallback: 'United States • en-US',
    badge: 'EN',
    locale: Locale('en', 'US'),
  );

  static const _LanguageOption espanhol = _LanguageOption(
    labelKey: 'configuracoes.languageSpanish',
    labelFallback: 'Español',
    descriptionKey: 'configuracoes.languageSpanishDescription',
    descriptionFallback: 'España • es-ES',
    badge: 'ES',
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

class _RegionalizacaoPreviewItem {
  const _RegionalizacaoPreviewItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _RegionalizacaoPreviewFormatter {
  const _RegionalizacaoPreviewFormatter(this.config);

  final ConfiguracaoRegionalizacaoSistema config;

  AppRegionalFormatting get formatting => config.formatting;

  String formatDecimal(num value) {
    final int casasDecimais = formatting.decimalPlaces.clamp(0, 6).toInt();
    final String normalizado = value.toStringAsFixed(casasDecimais);
    final bool negativo = normalizado.startsWith('-');
    final List<String> partes = normalizado.replaceFirst('-', '').split('.');
    final String inteiro = _aplicarSeparadorDeMilhar(partes.first);
    final String decimal = casasDecimais > 0 && partes.length > 1
        ? '${formatting.decimalSeparator}${partes[1]}'
        : '';

    return '${negativo ? '-' : ''}$inteiro$decimal';
  }

  String formatCurrency(num value) {
    return '${formatting.currencyCode} ${formatDecimal(value)}';
  }

  String formatDate(DateTime value) {
    final String day = _twoDigits(value.day);
    final String month = _twoDigits(value.month);
    final String year = value.year.toString().padLeft(4, '0');

    switch (formatting.dateFormat) {
      case 'MM/dd/yyyy':
        return '$month/$day/$year';
      case 'yyyy-MM-dd':
        return '$year-$month-$day';
      case 'dd-MM-yyyy':
        return '$day-$month-$year';
      case 'dd/MM/yyyy':
      default:
        return '$day/$month/$year';
    }
  }

  String formatTime(DateTime value) {
    if (formatting.timeFormat.toLowerCase() == '12h') {
      final bool afternoon = value.hour >= 12;
      final int hour12 = value.hour == 0
          ? 12
          : value.hour > 12
              ? value.hour - 12
              : value.hour;
      return '${_twoDigits(hour12)}:${_twoDigits(value.minute)} ${afternoon ? 'PM' : 'AM'}';
    }

    return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }

  String _aplicarSeparadorDeMilhar(String value) {
    final buffer = StringBuffer();
    int contador = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      if (contador > 0 && contador % 3 == 0) {
        buffer.write(formatting.thousandSeparator);
      }
      buffer.write(value[i]);
      contador++;
    }

    return buffer.toString().split('').reversed.join();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
