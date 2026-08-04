import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/domain/models/regionalizacao_models.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class RegionalizacaoMobileScreen extends StatefulWidget {
  const RegionalizacaoMobileScreen({super.key});

  @override
  State<RegionalizacaoMobileScreen> createState() =>
      _RegionalizacaoMobileScreenState();
}

class _RegionalizacaoMobileScreenState
    extends State<RegionalizacaoMobileScreen> {
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

  Future<void> _carregarRegionalizacao() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final ConfiguracaoRegionalizacaoSistema config =
          await context
              .read<LocaleSettingsProvider>()
              .carregarRegionalizacaoDaEmpresa();
      if (!mounted) return;
      setState(() => _aplicarConfiguracao(config));
    } catch (e) {
      if (!mounted) return;
      final ConfiguracaoRegionalizacaoSistema fallback =
          context.read<LocaleSettingsProvider>().companyConfig;
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
    final LocaleSettingsProvider provider =
        context.read<LocaleSettingsProvider>();
    if (provider.regionalizacaoSaving) return;

    FocusScope.of(context).unfocus();
    setState(() => _erro = null);

    try {
      final ConfiguracaoRegionalizacaoSistema configSalva = await provider
          .saveCompanyConfigAndApply(_montarConfiguracaoAtualizada());

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
    final AppRegionalFormatting formatting = config.formatting;
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
  }

  ConfiguracaoRegionalizacaoSistema _montarConfiguracaoAtualizada() {
    final ConfiguracaoRegionalizacaoSistema config =
        _configuracaoAtual ??
        ConfiguracaoRegionalizacaoSistema.defaultConfiguration();

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
        numberPattern: _suggestNumberPattern(),
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
    for (final _RegionalizacaoOption option in options) {
      if (option.value == value) return option;
    }

    return _RegionalizacaoOption(
      value: value,
      labelKey: 'configuracoes.customRegionalValue',
      labelFallback:
          value.isEmpty
              ? context.t('common.notInformed', fallback: 'Não informada')
              : value,
      subtitleFallback: value,
    );
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            erro ? SixMobilePalette.error : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LocaleSettingsProvider provider =
        context.watch<LocaleSettingsProvider>();

    return SixMobilePageShell(
      title: context.t(
        'configuracoes.regionalizationTitle',
        fallback: 'Regionalização',
      ),
      backgroundColor: SixMobilePalette.background,
      primaryColor: SixMobilePalette.primary,
      secondaryColor: SixMobilePalette.secondary,
      accentColor: SixMobilePalette.accent,
      leading: IconButton(
        tooltip: context.t('common.back', fallback: 'Voltar'),
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: context.t('common.refresh', fallback: 'Atualizar'),
          icon: const Icon(Icons.refresh_rounded),
          onPressed:
              provider.regionalizacaoSaving ? null : _carregarRegionalizacao,
        ),
      ],
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 24),
          children: <Widget>[
            SixStaggeredEntry(
              delay: const Duration(milliseconds: 70),
              child: _buildHero(context),
            ),
            const SizedBox(height: 14),
            if (_carregando || provider.regionalizacaoLoading)
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 130),
                child: SixBackendLoading(
                  title: context.t(
                    'configuracoes.regionalizationLoadingTitle',
                    fallback: 'Carregando regionalização',
                  ),
                  subtitle: context.t(
                    'configuracoes.regionalizationLoadingSubtitle',
                    fallback: 'Sincronizando as configurações da empresa.',
                  ),
                  compact: true,
                  animation: SixBackendLoadingAnimation.skeletonPulse,
                  leadingIcon: Icons.public_rounded,
                ),
              )
            else ...<Widget>[
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 120),
                child: _buildPreviewCard(context, provider),
              ),
              if (_erro != null && _erro!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _buildErrorCard(context),
              ],
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 170),
                child: _buildLanguageCard(context),
              ),
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 220),
                child: _buildFormatCard(context),
              ),
              const SizedBox(height: 12),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 270),
                child: _buildFinancialCard(context),
              ),
            ],
            const SizedBox(height: 18),
            _buildActions(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SixMobilePalette.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _IconBox(
            icon: Icons.public_rounded,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            iconColor: SixMobilePalette.onPrimary,
            borderColor: Colors.white.withValues(alpha: 0.18),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.t(
                    'configuracoes.descRegionalization',
                    fallback:
                        'Idioma, país, moeda, fuso horário, formatos de data e padronização financeira da empresa.',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.heroSupportingText,
                    fontSize: 13,
                    height: 1.28,
                  ),
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
    LocaleSettingsProvider provider,
  ) {
    final ConfiguracaoRegionalizacaoSistema draft =
        _montarConfiguracaoAtualizada();
    final _RegionalizacaoPreviewFormatter formatter =
        _RegionalizacaoPreviewFormatter(draft);
    final DateTime sampleDate = DateTime(2026, 12, 31, 18, 30);

    return _MobileSectionCard(
      icon: Icons.visibility_rounded,
      title: context.t(
        'configuracoes.regionalizationPreview',
        fallback: 'Prévia aplicada ao app',
      ),
      subtitle: context.t(
        'configuracoes.regionalizationPreviewDescription',
        fallback: 'Confira como moeda, datas e horários serão exibidos no app.',
      ),
      trailing: _StatusChip(
        icon: Icons.hub_rounded,
        label: provider.currencyCode,
      ),
      child: Column(
        children: <Widget>[
          _PreviewTile(
            icon: Icons.payments_rounded,
            label: context.t(
              'configuracoes.currencyPreview',
              fallback: 'Moeda',
            ),
            value: formatter.formatCurrency(1234.5),
          ),
          _PreviewTile(
            icon: Icons.calendar_month_rounded,
            label: context.t('configuracoes.datePreview', fallback: 'Data'),
            value: formatter.formatDate(sampleDate),
          ),
          _PreviewTile(
            icon: Icons.access_time_rounded,
            label: context.t('configuracoes.timePreview', fallback: 'Hora'),
            value: formatter.formatTime(sampleDate),
          ),
          _PreviewTile(
            icon: Icons.language_rounded,
            label: context.t('configuracoes.activeLocale', fallback: 'Locale'),
            value:
                '${_idiomaSelecionado.locale.languageCode}-${_paisSelecionado.value}',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    return _MobileSectionCard(
      icon: Icons.translate_rounded,
      title: context.t(
        'configuracoes.languageAndRegionalConventions',
        fallback: 'Idioma e convenções regionais',
      ),
      subtitle: context.t(
        'configuracoes.languageAndRegionalConventionsDesc',
        fallback:
            'Defina a experiência local da empresa, incluindo idioma, fuso e padrões de exibição.',
      ),
      child: Column(
        children: <Widget>[
          _SelectionField(
            icon: Icons.language_rounded,
            title: context.t(
              'configuracoes.systemLanguage',
              fallback: 'Idioma do sistema',
            ),
            value: _idiomaSelecionado.label(context),
            subtitle: _idiomaSelecionado.description(context),
            onTap: () => _selecionarIdioma(context),
          ),
          const SizedBox(height: 10),
          _SelectionField(
            icon: Icons.flag_rounded,
            title: context.t(
              'configuracoes.countryRegion',
              fallback: 'País / região',
            ),
            value: _paisSelecionado.label(context),
            subtitle: _paisSelecionado.subtitle(context),
            onTap:
                () => _selecionarOpcao(
                  context: context,
                  title: context.t(
                    'configuracoes.countryRegion',
                    fallback: 'País / região',
                  ),
                  options: _optionsWithSelected(
                    _countryOptions,
                    _paisSelecionado,
                  ),
                  selected: _paisSelecionado,
                  onSelected:
                      (value) => setState(() => _paisSelecionado = value),
                ),
          ),
          const SizedBox(height: 10),
          _SelectionField(
            icon: Icons.schedule_rounded,
            title: context.t(
              'configuracoes.timeZone',
              fallback: 'Fuso horário',
            ),
            value: _timeZoneSelecionado.label(context),
            subtitle: _timeZoneSelecionado.subtitle(context),
            onTap:
                () => _selecionarOpcao(
                  context: context,
                  title: context.t(
                    'configuracoes.timeZone',
                    fallback: 'Fuso horário',
                  ),
                  options: _optionsWithSelected(
                    _timeZoneOptions,
                    _timeZoneSelecionado,
                  ),
                  selected: _timeZoneSelecionado,
                  onSelected:
                      (value) => setState(() => _timeZoneSelecionado = value),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(BuildContext context) {
    return _MobileSectionCard(
      icon: Icons.format_list_numbered_rounded,
      title: context.t(
        'configuracoes.numberFormat',
        fallback: 'Formato numérico',
      ),
      subtitle: context.t(
        'configuracoes.mobileFormatsDescription',
        fallback: 'Controle como datas, horas e separadores aparecem no app.',
      ),
      child: Column(
        children: <Widget>[
          _SelectionField(
            icon: Icons.calendar_month_rounded,
            title: context.t(
              'configuracoes.dateFormat',
              fallback: 'Formato de data',
            ),
            value: _dateFormatSelecionado.label(context),
            subtitle: _dateFormatSelecionado.subtitle(context),
            onTap:
                () => _selecionarOpcao(
                  context: context,
                  title: context.t(
                    'configuracoes.dateFormat',
                    fallback: 'Formato de data',
                  ),
                  options: _optionsWithSelected(
                    _dateFormatOptions,
                    _dateFormatSelecionado,
                  ),
                  selected: _dateFormatSelecionado,
                  onSelected:
                      (value) => setState(() => _dateFormatSelecionado = value),
                ),
          ),
          const SizedBox(height: 10),
          _SelectionField(
            icon: Icons.access_time_rounded,
            title: context.t(
              'configuracoes.timeFormat',
              fallback: 'Formato de hora',
            ),
            value: _timeFormatSelecionado.label(context),
            subtitle: _timeFormatSelecionado.subtitle(context),
            onTap:
                () => _selecionarOpcao(
                  context: context,
                  title: context.t(
                    'configuracoes.timeFormat',
                    fallback: 'Formato de hora',
                  ),
                  options: _optionsWithSelected(
                    _timeFormatOptions,
                    _timeFormatSelecionado,
                  ),
                  selected: _timeFormatSelecionado,
                  onSelected:
                      (value) => setState(() => _timeFormatSelecionado = value),
                ),
          ),
          const SizedBox(height: 10),
          _SelectionField(
            icon: Icons.looks_one_rounded,
            title: context.t(
              'configuracoes.decimalSeparator',
              fallback: 'Separador decimal',
            ),
            value: _decimalSeparatorSelecionado.label(context),
            subtitle: _decimalSeparatorSelecionado.subtitle(context),
            onTap:
                () => _selecionarOpcao(
                  context: context,
                  title: context.t(
                    'configuracoes.decimalSeparator',
                    fallback: 'Separador decimal',
                  ),
                  options: _optionsWithSelected(
                    _decimalSeparatorOptions,
                    _decimalSeparatorSelecionado,
                  ),
                  selected: _decimalSeparatorSelecionado,
                  onSelected:
                      (value) =>
                          setState(() => _decimalSeparatorSelecionado = value),
                ),
          ),
          const SizedBox(height: 10),
          _SelectionField(
            icon: Icons.view_week_rounded,
            title: context.t(
              'configuracoes.thousandSeparator',
              fallback: 'Separador de milhar',
            ),
            value: _thousandSeparatorSelecionado.label(context),
            subtitle: _thousandSeparatorSelecionado.subtitle(context),
            onTap:
                () => _selecionarOpcao(
                  context: context,
                  title: context.t(
                    'configuracoes.thousandSeparator',
                    fallback: 'Separador de milhar',
                  ),
                  options: _optionsWithSelected(
                    _thousandSeparatorOptions,
                    _thousandSeparatorSelecionado,
                  ),
                  selected: _thousandSeparatorSelecionado,
                  onSelected:
                      (value) =>
                          setState(() => _thousandSeparatorSelecionado = value),
                ),
          ),
          const SizedBox(height: 10),
          _SelectionField(
            icon: Icons.today_rounded,
            title: context.t(
              'configuracoes.firstDayOfWeek',
              fallback: 'Primeiro dia da semana',
            ),
            value: _firstDaySelecionado.label(context),
            subtitle: _firstDaySelecionado.subtitle(context),
            onTap:
                () => _selecionarOpcao(
                  context: context,
                  title: context.t(
                    'configuracoes.firstDayOfWeek',
                    fallback: 'Primeiro dia da semana',
                  ),
                  options: _optionsWithSelected(
                    _firstDayOptions,
                    _firstDaySelecionado,
                  ),
                  selected: _firstDaySelecionado,
                  onSelected:
                      (value) => setState(() => _firstDaySelecionado = value),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(BuildContext context) {
    return _MobileSectionCard(
      icon: Icons.account_balance_wallet_rounded,
      title: context.t(
        'configuracoes.currencyAndFinancialStandard',
        fallback: 'Moeda e padronização financeira',
      ),
      subtitle: context.t(
        'configuracoes.currencyAndFinancialStandardDesc',
        fallback:
            'Essas definições influenciam dashboards, vendas, orçamentos e documentos.',
      ),
      child: Column(
        children: <Widget>[
          _SelectionField(
            icon: Icons.payments_rounded,
            title: context.t(
              'configuracoes.mainCurrency',
              fallback: 'Moeda principal',
            ),
            value: _moedaSelecionada.label(context),
            subtitle: _moedaSelecionada.subtitle(context),
            onTap:
                () => _selecionarOpcao(
                  context: context,
                  title: context.t(
                    'configuracoes.mainCurrency',
                    fallback: 'Moeda principal',
                  ),
                  options: _optionsWithSelected(
                    _currencyOptions,
                    _moedaSelecionada,
                  ),
                  selected: _moedaSelecionada,
                  onSelected:
                      (value) => setState(() => _moedaSelecionada = value),
                ),
          ),
          const SizedBox(height: 12),
          _DecimalStepper(
            value: _decimalPlaces,
            onChanged: (value) => setState(() => _decimalPlaces = value),
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            icon: Icons.currency_exchange_rounded,
            title: context.t(
              'configuracoes.allowMultipleCurrencies',
              fallback: 'Permitir múltiplas moedas',
            ),
            subtitle: context.t(
              'configuracoes.allowMultipleCurrenciesDesc',
              fallback: 'Mantém a base preparada para cenários internacionais.',
            ),
            value: _allowMultipleCurrencies,
            onChanged:
                (value) => setState(() => _allowMultipleCurrencies = value),
          ),
          const SizedBox(height: 10),
          _SwitchTile(
            icon: Icons.price_check_rounded,
            title: context.t(
              'configuracoes.applyFinancialRounding',
              fallback: 'Aplicar arredondamento financeiro',
            ),
            subtitle: context.t(
              'configuracoes.applyFinancialRoundingDesc',
              fallback: 'Padroniza cálculos e evita divergências de centavos.',
            ),
            value: _applyFinancialRounding,
            onChanged:
                (value) => setState(() => _applyFinancialRounding = value),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: SixMobilePalette.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _erro!,
              style: const TextStyle(
                color: SixMobilePalette.error,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
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

  Widget _buildActions(BuildContext context, LocaleSettingsProvider provider) {
    final bool saving = provider.regionalizacaoSaving;

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: saving ? null : _carregarRegionalizacao,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.t('common.refresh', fallback: 'Atualizar')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: saving || _carregando ? null : _salvar,
            icon:
                saving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save_rounded),
            label: Text(
              saving
                  ? context.t('common.saving', fallback: 'Salvando...')
                  : context.t('common.save', fallback: 'Salvar'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selecionarIdioma(BuildContext context) async {
    final _LanguageOption? selecionado =
        await showModalBottomSheet<_LanguageOption>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.42),
          builder: (BuildContext sheetContext) {
            return _LanguagePickerSheet(
              title: context.t(
                'configuracoes.systemLanguage',
                fallback: 'Idioma do sistema',
              ),
              options: _idiomas,
              selected: _idiomaSelecionado,
            );
          },
        );

    if (selecionado == null || !mounted) return;
    setState(() {
      _idiomaSelecionado = selecionado;
      _paisSelecionado = _optionFromValue(
        _countryOptions,
        selecionado.locale.countryCode ?? _paisSelecionado.value,
      );
    });
  }

  Future<void> _selecionarOpcao({
    required BuildContext context,
    required String title,
    required List<_RegionalizacaoOption> options,
    required _RegionalizacaoOption selected,
    required ValueChanged<_RegionalizacaoOption> onSelected,
  }) async {
    final _RegionalizacaoOption? selecionada =
        await showModalBottomSheet<_RegionalizacaoOption>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.42),
          builder: (BuildContext sheetContext) {
            return _OptionPickerSheet(
              title: title,
              options: options,
              selected: selected,
            );
          },
        );

    if (selecionada == null || !mounted) return;
    onSelected(selecionada);
  }

  List<_RegionalizacaoOption> _optionsWithSelected(
    List<_RegionalizacaoOption> options,
    _RegionalizacaoOption selected,
  ) {
    if (options.any((option) => option.value == selected.value)) return options;
    return <_RegionalizacaoOption>[selected, ...options];
  }

  String _suggestNumberPattern() {
    final String decimals =
        _decimalPlaces <= 0
            ? ''
            : '${_decimalSeparatorSelecionado.value}${'0' * _decimalPlaces}';
    return '#${_thousandSeparatorSelecionado.value}##0$decimals';
  }
}

class _MobileSectionCard extends StatelessWidget {
  const _MobileSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.navigationShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _IconBox(icon: icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 12.5,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    this.backgroundColor = SixMobilePalette.softAccentSurface,
    this.iconColor = SixMobilePalette.accent,
    this.borderColor = SixMobilePalette.highlightedBorder,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, color: iconColor, size: 21),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: SixMobilePalette.highlightedBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: SixMobilePalette.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: SixMobilePalette.accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : const Border(
                  bottom: BorderSide(color: SixMobilePalette.border),
                ),
      ),
      child: Row(
        children: <Widget>[
          _IconBox(
            icon: icon,
            backgroundColor: SixMobilePalette.softNeutralSurface,
            iconColor: SixMobilePalette.primary,
            borderColor: SixMobilePalette.border,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 14,
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
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $value',
      child: Material(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: SixMobilePalette.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: SixMobilePalette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecimalStepper extends StatelessWidget {
  const _DecimalStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.pin_rounded,
            color: SixMobilePalette.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'configuracoes.decimalPlaces',
                    fallback: 'Casas decimais',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: context.t('common.decrease', fallback: 'Diminuir'),
            onPressed: value <= 0 ? null : () => onChanged(value - 1),
          ),
          const SizedBox(width: 8),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: context.t('common.increase', fallback: 'Aumentar'),
            onPressed: value >= 6 ? null : () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size(38, 38),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: SixMobilePalette.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 11.5,
                    height: 1.24,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: SixMobilePalette.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _OptionPickerSheet extends StatelessWidget {
  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<_RegionalizacaoOption> options;
  final _RegionalizacaoOption selected;

  @override
  Widget build(BuildContext context) {
    return _PickerShell(
      title: title,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final _RegionalizacaoOption option = options[index];
          final bool isSelected = option.value == selected.value;
          return _PickerOptionTile(
            title: option.label(context),
            subtitle: option.subtitle(context),
            badge: option.value,
            selected: isSelected,
            onTap: () => Navigator.of(context).pop(option),
          );
        },
      ),
    );
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<_LanguageOption> options;
  final _LanguageOption selected;

  @override
  Widget build(BuildContext context) {
    return _PickerShell(
      title: title,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final _LanguageOption option = options[index];
          final bool isSelected = option == selected;
          return _PickerOptionTile(
            title: option.label(context),
            subtitle: option.description(context),
            badge: option.badge,
            selected: isSelected,
            onTap: () => Navigator.of(context).pop(option),
          );
        },
      ),
    );
  }
}

class _PickerShell extends StatelessWidget {
  const _PickerShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.36,
      maxChildSize: 0.88,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SixMobilePalette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.t('common.close', fallback: 'Fechar'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  const _PickerOptionTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected
              ? SixMobilePalette.accent.withValues(alpha: 0.08)
              : SixMobilePalette.softNeutralSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? SixMobilePalette.highlightedBorder
                      : SixMobilePalette.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? SixMobilePalette.accent.withValues(alpha: 0.12)
                          : SixMobilePalette.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: SixMobilePalette.accent,
                ),
            ],
          ),
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
    descriptionFallback: 'Brasil - pt-BR',
    badge: 'PT',
    locale: Locale('pt', 'BR'),
  );

  static const _LanguageOption ingles = _LanguageOption(
    labelKey: 'configuracoes.languageEnglish',
    labelFallback: 'English',
    descriptionKey: 'configuracoes.languageEnglishDescription',
    descriptionFallback: 'United States - en-US',
    badge: 'EN',
    locale: Locale('en', 'US'),
  );

  static const _LanguageOption espanhol = _LanguageOption(
    labelKey: 'configuracoes.languageSpanish',
    labelFallback: 'Español',
    descriptionKey: 'configuracoes.languageSpanishDescription',
    descriptionFallback: 'España - es-ES',
    badge: 'ES',
    locale: Locale('es', 'ES'),
  );

  static _LanguageOption fromConfig(ConfiguracaoRegionalizacaoSistema config) {
    final String languageCode = config.languageCode.toLowerCase();

    if (languageCode == 'en') return ingles;
    if (languageCode == 'es') return espanhol;
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

class _RegionalizacaoPreviewFormatter {
  const _RegionalizacaoPreviewFormatter(this.config);

  final ConfiguracaoRegionalizacaoSistema config;

  AppRegionalFormatting get formatting => config.formatting;

  String formatDecimal(num value) {
    final int decimalPlaces = formatting.decimalPlaces.clamp(0, 6).toInt();
    final String normalized = value.toStringAsFixed(decimalPlaces);
    final bool negative = normalized.startsWith('-');
    final List<String> parts = normalized.replaceFirst('-', '').split('.');
    final String integer = _applyThousandSeparator(parts.first);
    final String decimal =
        decimalPlaces > 0 && parts.length > 1
            ? '${formatting.decimalSeparator}${parts[1]}'
            : '';

    return '${negative ? '-' : ''}$integer$decimal';
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
      final int hour12 =
          value.hour == 0
              ? 12
              : value.hour > 12
              ? value.hour - 12
              : value.hour;
      return '${_twoDigits(hour12)}:${_twoDigits(value.minute)} ${afternoon ? 'PM' : 'AM'}';
    }

    return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }

  String _applyThousandSeparator(String value) {
    final StringBuffer buffer = StringBuffer();
    int count = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(formatting.thousandSeparator);
      }
      buffer.write(value[i]);
      count++;
    }

    return buffer.toString().split('').reversed.join();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
