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
          displayLabel: 'R\$',
        ),
        _RegionalizacaoOption(
          value: 'USD',
          labelKey: 'configuracoes.currencyUsd',
          labelFallback: 'Dólar americano',
          subtitleFallback: 'USD',
          displayLabel: '\$',
        ),
        _RegionalizacaoOption(
          value: 'EUR',
          labelKey: 'configuracoes.currencyEur',
          labelFallback: 'Euro',
          subtitleFallback: 'EUR',
          displayLabel: '€',
        ),
        _RegionalizacaoOption(
          value: 'ARS',
          labelKey: 'configuracoes.currencyArs',
          labelFallback: 'Peso argentino',
          subtitleFallback: 'ARS',
          displayLabel: 'AR\$',
        ),
        _RegionalizacaoOption(
          value: 'MXN',
          labelKey: 'configuracoes.currencyMxn',
          labelFallback: 'Peso mexicano',
          subtitleFallback: 'MXN',
          displayLabel: 'MX\$',
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
        backgroundColor: erro ? SixMobilePalette.error : Color(0xFF16A34A),
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
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 24),
          children: <Widget>[
            if (_carregando || provider.regionalizacaoLoading)
              SixStaggeredEntry(
                delay: Duration(milliseconds: 130),
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
                delay: Duration(milliseconds: 120),
                child: _buildDisplayOverviewCard(context),
              ),
              if (_erro != null && _erro!.isNotEmpty) ...<Widget>[
                SizedBox(height: 12),
                _buildErrorCard(context),
              ],
              SizedBox(height: 12),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 170),
                child: _buildLanguageCard(context),
              ),
              SizedBox(height: 12),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 220),
                child: _buildFormatCard(context),
              ),
              SizedBox(height: 12),
              SixStaggeredEntry(
                delay: Duration(milliseconds: 270),
                child: _buildFinancialCard(context),
              ),
            ],
            SizedBox(height: 18),
            _buildActions(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildDisplayOverviewCard(BuildContext context) {
    final ConfiguracaoRegionalizacaoSistema draft =
        _montarConfiguracaoAtualizada();
    final _RegionalizacaoPreviewFormatter formatter =
        _RegionalizacaoPreviewFormatter(draft);
    final DateTime sampleDate = DateTime(2026, 12, 31, 18, 30);
    final String localeValue =
        '${_idiomaSelecionado.locale.languageCode}-${_paisSelecionado.value}';

    return Container(
      constraints: BoxConstraints(minHeight: 196),
      padding: EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF173DFF),
            Color(0xFF3D00D8),
            Color(0xFF2700A8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x3D3D00D8),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -6,
            bottom: -34,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 96,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      SixMobilePalette.onPrimary.withValues(alpha: 0.10),
                      SixMobilePalette.onPrimary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: ExcludeSemantics(
              child: _RegionalizacaoSummaryIllustration(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 78),
                child: Text(
                  context.t(
                    'configuracoes.displayLanguageRegionCurrency',
                    fallback: 'Idioma, região e moeda',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.onPrimary,
                    fontSize: 16,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.only(right: 72),
                child: Text(
                  context.t(
                    'configuracoes.regionalizationPreviewDescription',
                    fallback:
                        'Confira como moeda, datas e horários serão exibidos no app.',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.heroSupportingText,
                    fontSize: 12.5,
                    height: 1.24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(height: 34),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final List<Widget> metrics = <Widget>[
                    _RegionalizacaoSummaryMetric(
                      icon: Icons.payments_rounded,
                      value: formatter.formatCurrency(1234.5),
                      label: context.t(
                        'configuracoes.currencyPreview',
                        fallback: 'Moeda',
                      ),
                    ),
                    _RegionalizacaoSummaryMetric(
                      icon: Icons.calendar_month_rounded,
                      value: formatter.formatDate(sampleDate),
                      label: context.t(
                        'configuracoes.datePreview',
                        fallback: 'Data',
                      ),
                    ),
                    _RegionalizacaoSummaryMetric(
                      icon: Icons.access_time_rounded,
                      value: formatter.formatTime(sampleDate),
                      label: context.t(
                        'configuracoes.timePreview',
                        fallback: 'Hora',
                      ),
                    ),
                  ];
                  final bool compact =
                      constraints.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(1) >= 1.25;

                  if (compact) {
                    final double itemWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: metrics
                          .map(
                            (Widget metric) =>
                                SizedBox(width: itemWidth, child: metric),
                          )
                          .toList(growable: false),
                    );
                  }

                  return Row(
                    children: metrics
                        .map((Widget metric) => Expanded(child: metric))
                        .toList(growable: false),
                  );
                },
              ),
              SizedBox(height: 14),
              Align(
                alignment: Alignment.center,
                child: _RegionalizacaoLocaleBadge(
                  label: context.t(
                    'configuracoes.activeLocale',
                    fallback: 'Locale',
                  ),
                  value: localeValue,
                ),
              ),
            ],
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
          SizedBox(height: 10),
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
          SizedBox(height: 10),
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
          SizedBox(height: 10),
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
          SizedBox(height: 10),
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
                      (value) => setState(() {
                        _decimalSeparatorSelecionado = value;
                        if (_thousandSeparatorSelecionado.value ==
                            value.value) {
                          _thousandSeparatorSelecionado =
                              _thousandSeparatorOptions.firstWhere(
                                (item) => item.value != value.value,
                              );
                        }
                      }),
                ),
          ),
          SizedBox(height: 10),
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
                      (value) => setState(() {
                        _thousandSeparatorSelecionado = value;
                        if (_decimalSeparatorSelecionado.value == value.value) {
                          _decimalSeparatorSelecionado =
                              _decimalSeparatorOptions.firstWhere(
                                (item) => item.value != value.value,
                              );
                        }
                      }),
                ),
          ),
          SizedBox(height: 10),
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
          SizedBox(height: 12),
          _DecimalStepper(
            value: _decimalPlaces,
            onChanged: (value) => setState(() => _decimalPlaces = value),
          ),
          SizedBox(height: 12),
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
          SizedBox(height: 10),
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SixMobilePalette.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: SixMobilePalette.error),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _erro!,
              style: TextStyle(
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
            icon: Icon(Icons.refresh_rounded),
            label: Text(context.t('common.refresh', fallback: 'Atualizar')),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: saving || _carregando ? null : _salvar,
            icon:
                saving
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(Icons.save_rounded),
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
              cancelLabel: context.t('common.cancel', fallback: 'Cancelar'),
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
              searchHint: context.t('common.search', fallback: 'Buscar'),
              emptyTitle: context.t(
                'common.noResults',
                fallback: 'Nenhum resultado',
              ),
              emptySubtitle: context.t(
                'configuracoes.adjustSearch',
                fallback: 'Revise o termo buscado e tente novamente.',
              ),
              cancelLabel: context.t('common.cancel', fallback: 'Cancelar'),
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

class _RegionalizacaoSummaryIllustration extends StatelessWidget {
  const _RegionalizacaoSummaryIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            right: 18,
            top: 8,
            child: Transform.rotate(
              angle: -0.10,
              child: const _RegionalizacaoSummaryLayer(
                width: 33,
                height: 43,
                colors: <Color>[Color(0xFF253DFF), Color(0xFF7C3AED)],
                opacity: 0.44,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 4,
            child: Transform.rotate(
              angle: -0.04,
              child: const _RegionalizacaoSummaryLayer(
                width: 36,
                height: 48,
                colors: <Color>[Color(0xFF0EA5E9), Color(0xFF4338CA)],
                opacity: 0.70,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _RegionalizacaoSummaryLayer(
              width: 39,
              height: 52,
              colors: <Color>[Color(0xFF38BDF8), Color(0xFF4F46E5)],
              opacity: 1,
              child: Icon(
                Icons.language_rounded,
                size: 18,
                color: SixMobilePalette.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionalizacaoSummaryLayer extends StatelessWidget {
  const _RegionalizacaoSummaryLayer({
    required this.width,
    required this.height,
    required this.colors,
    required this.opacity,
    this.child,
  });

  final double width;
  final double height;
  final List<Color> colors;
  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SixMobilePalette.onPrimary.withValues(alpha: 0.22),
            width: 0.8,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: SixMobilePalette.primary.withValues(alpha: 0.24),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RegionalizacaoSummaryMetric extends StatelessWidget {
  const _RegionalizacaoSummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: SixMobilePalette.onPrimary.withValues(alpha: 0.86),
            size: 16,
          ),
          SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.onPrimary,
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SixMobilePalette.heroSupportingText,
              fontSize: 12,
              height: 1.12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionalizacaoLocaleBadge extends StatelessWidget {
  const _RegionalizacaoLocaleBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: SixMobilePalette.onPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: SixMobilePalette.onPrimary.withValues(alpha: 0.20),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.public_rounded,
              color: SixMobilePalette.onPrimary,
              size: 14,
            ),
            SizedBox(width: 6),
            Text(
              '$label $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SixMobilePalette.onPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSectionCard extends StatelessWidget {
  const _MobileSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SixMobilePalette.border),
        boxShadow: <BoxShadow>[
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
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 12.5,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SixMobilePalette.highlightedBorder.withValues(alpha: 0.45),
        ),
      ),
      child: Icon(icon, color: SixMobilePalette.accent, size: 21),
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
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: SixMobilePalette.accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.pin_rounded, color: SixMobilePalette.accent, size: 20),
          SizedBox(width: 10),
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
                  style: TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  value.toString(),
                  style: TextStyle(
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
          SizedBox(width: 8),
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
        minimumSize: Size(38, 38),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: SixMobilePalette.accent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SixMobilePalette.titleText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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

class _OptionPickerSheet extends StatefulWidget {
  const _OptionPickerSheet({
    required this.title,
    required this.searchHint,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.cancelLabel,
    required this.options,
    required this.selected,
  });

  final String title;
  final String searchHint;
  final String emptyTitle;
  final String emptySubtitle;
  final String cancelLabel;
  final List<_RegionalizacaoOption> options;
  final _RegionalizacaoOption selected;

  @override
  State<_OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<_OptionPickerSheet> {
  String _query = '';

  List<_RegionalizacaoOption> _filteredOptions(BuildContext context) {
    final String normalizedQuery = _normalize(_query);
    if (normalizedQuery.isEmpty) return widget.options;

    return widget.options.where((_RegionalizacaoOption option) {
      final String searchable = _normalize(
        '${option.label(context)} ${option.subtitle(context)} ${option.value}',
      );
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final List<_RegionalizacaoOption> filteredOptions = _filteredOptions(
      context,
    );
    final bool showSearch = widget.options.length >= 4;

    return _PickerShell(
      title: widget.title,
      itemCount: widget.options.length,
      cancelLabel: widget.cancelLabel,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            if (showSearch) ...<Widget>[
              _SheetSearchField(
                hint: widget.searchHint,
                onChanged: (String value) => setState(() => _query = value),
              ),
              SizedBox(height: 12),
            ],
            Expanded(
              child:
                  filteredOptions.isEmpty
                      ? _PickerEmptyState(
                        title: widget.emptyTitle,
                        subtitle: widget.emptySubtitle,
                      )
                      : ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.paddingOf(context).bottom + 8,
                        ),
                        itemCount: filteredOptions.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int index) {
                          final _RegionalizacaoOption option =
                              filteredOptions[index];
                          final bool isSelected =
                              option.value == widget.selected.value;
                          return _PickerOptionTile(
                            title: option.label(context),
                            subtitle: option.subtitle(context),
                            badge: option.badge,
                            selected: isSelected,
                            onTap: () => Navigator.of(context).pop(option),
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({
    required this.title,
    required this.cancelLabel,
    required this.options,
    required this.selected,
  });

  final String title;
  final String cancelLabel;
  final List<_LanguageOption> options;
  final _LanguageOption selected;

  @override
  Widget build(BuildContext context) {
    return _PickerShell(
      title: title,
      itemCount: options.length,
      cancelLabel: cancelLabel,
      builder: (BuildContext context, ScrollController scrollController) {
        return ListView.separated(
          controller: scrollController,
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 8,
          ),
          itemCount: options.length,
          separatorBuilder: (_, __) => SizedBox(height: 8),
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
        );
      },
    );
  }
}

typedef _PickerContentBuilder =
    Widget Function(BuildContext context, ScrollController scrollController);

class _PickerShell extends StatelessWidget {
  const _PickerShell({
    required this.title,
    required this.itemCount,
    required this.cancelLabel,
    required this.builder,
  });

  final String title;
  final int itemCount;
  final String cancelLabel;
  final _PickerContentBuilder builder;

  double _initialChildSize(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double base =
        itemCount <= 2
            ? 0.44
            : itemCount <= 3
            ? 0.52
            : itemCount <= 5
            ? 0.68
            : 0.78;

    if (textScale > 1.2) return (base + 0.08).clamp(0.52, 0.88);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final double initialSize = _initialChildSize(context);
    final double minSize = (initialSize - 0.12).clamp(0.36, initialSize);

    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: 0.90,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            decoration: BoxDecoration(
              color: SixMobilePalette.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.t('common.close', fallback: 'Fechar'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Semantics(
                  button: true,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(cancelLabel),
                  ),
                ),
                SizedBox(height: 8),
                Expanded(child: builder(context, scrollController)),
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
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$title, selecionado' : title,
      child: Material(
        color:
            selected
                ? SixMobilePalette.accent.withValues(alpha: 0.08)
                : SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 66),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    selected
                        ? SixMobilePalette.highlightedBorder
                        : SixMobilePalette.border,
                width: selected ? 1.4 : 1,
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
                    border: Border.all(
                      color:
                          selected
                              ? SixMobilePalette.highlightedBorder
                              : SixMobilePalette.border,
                    ),
                  ),
                  child: Text(
                    badge.trim().isEmpty ? '-' : badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          selected
                              ? SixMobilePalette.accent
                              : SixMobilePalette.primary,
                      fontSize: badge.length > 4 ? 10.5 : 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 160),
                  child:
                      selected
                          ? Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey<String>('selected'),
                            color: SixMobilePalette.accent,
                          )
                          : Icon(
                            Icons.radio_button_unchecked_rounded,
                            key: ValueKey<String>('unselected'),
                            color: SixMobilePalette.mutedText,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetSearchField extends StatelessWidget {
  const _SheetSearchField({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search_rounded),
        filled: true,
        fillColor: SixMobilePalette.softNeutralSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SixMobilePalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SixMobilePalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SixMobilePalette.highlightedBorder,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PickerEmptyState extends StatelessWidget {
  const _PickerEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SixMobilePalette.softNeutralSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SixMobilePalette.border),
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: SixMobilePalette.mutedText,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SixMobilePalette.titleText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SixMobilePalette.mutedText,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
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
    this.displayLabel,
  });

  final String value;
  final String labelKey;
  final String labelFallback;
  final String subtitleFallback;
  final String? displayLabel;
  String get badge =>
      (displayLabel ?? value).trim().isEmpty
          ? '—'
          : (displayLabel ?? value).trim();

  String label(BuildContext context) {
    return displayLabel ?? context.t(labelKey, fallback: labelFallback);
  }

  String subtitle(BuildContext context) {
    if (displayLabel == null) return subtitleFallback;
    return '$value - ${context.t(labelKey, fallback: labelFallback)}';
  }
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
    return '${LocaleSettingsProvider.currencySymbolForCode(formatting.currencyCode)} ${formatDecimal(value)}';
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
