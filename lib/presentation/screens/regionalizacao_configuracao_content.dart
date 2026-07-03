import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/regionalizacao/regionalizacao_api_client.dart';
import '../../domain/models/regionalizacao_models.dart';
import '../../domain/services/regionalizacao/regionalizacao_service.dart';
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

      _mostrarMensagem(
        context.t(
          'common.savedSuccessfully',
          fallback: 'Configurações salvas com sucesso.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _idiomaSelecionado = _LanguageOption.fromConfig(config);
      });

      _mostrarMensagem(
        '${context.t('configuracoes.settingsSaveError', fallback: 'Erro ao salvar configurações')}: $_erro',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
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
                    return _buildContent(context, inner.maxWidth);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, double availableWidth) {
    final theme = Theme.of(context);

    if (_carregando) {
      return _RegionalizacaoSkeleton(embedded: widget.embedded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!widget.embedded) _buildMobileHero(context),
        if (!widget.embedded) const SizedBox(height: 18),
        if (_erro != null && _erro!.isNotEmpty) ...<Widget>[
          _buildErro(context),
          const SizedBox(height: 16),
        ],
        _buildIdiomaCard(context, theme),
        const SizedBox(height: 16),
        _buildResumoRegionalizacao(context, theme),
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

  Widget _buildIdiomaCard(BuildContext context, ThemeData theme) {
    return _RegionalizacaoCard(
      embedded: widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSectionHeader(
            context: context,
            icon: Icons.translate_rounded,
            title: context.t(
              'configuracoes.systemLanguage',
              fallback: 'Idioma do sistema',
            ),
            subtitle: context.t(
              'configuracoes.systemLanguageDescription',
              fallback:
                  'Escolha o idioma aplicado para a empresa. Os demais padrões continuam vindo da regionalização atual.',
            ),
            trailing: _buildEditableBadge(context, theme),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required ThemeData theme,
    required _LanguageOption option,
    required bool selected,
  }) {
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
          onTap: _salvando
              ? null
              : () => setState(() => _idiomaSelecionado = option),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withOpacity(0.12)
                        : theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    option.badge,
                    style: const TextStyle(fontSize: 20),
                  ),
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
                AnimatedSwitcher(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 520;

        final Widget reloadButton = OutlinedButton.icon(
          onPressed: _salvando ? null : _carregarRegionalizacao,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            context.t('common.reload', fallback: 'Recarregar'),
          ),
        );

        final Widget saveButton = FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            _salvando
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

  Widget _buildResumoRegionalizacao(BuildContext context, ThemeData theme) {
    final config = _configuracaoAtual;
    if (config == null) return const SizedBox.shrink();

    final formatting = config.formatting;
    final groups = <_RegionalizacaoGroup>[
      _RegionalizacaoGroup(
        icon: Icons.public_rounded,
        title: context.t(
          'configuracoes.localeGroup',
          fallback: 'Localização',
        ),
        subtitle: context.t(
          'configuracoes.localeGroupDescription',
          fallback: 'Códigos usados para idioma, país e calendário.',
        ),
        items: <_RegionalizacaoInfo>[
          _RegionalizacaoInfo(
            icon: Icons.language_rounded,
            label: context.t('configuracoes.languageCode', fallback: 'Idioma'),
            value: '${_idiomaSelecionado.label(context)} '
                '(${_idiomaSelecionado.locale.languageCode})',
          ),
          _RegionalizacaoInfo(
            icon: Icons.flag_rounded,
            label: context.t('configuracoes.countryCode', fallback: 'País/região'),
            value: _idiomaSelecionado.locale.countryCode ?? config.countryCode,
          ),
          _RegionalizacaoInfo(
            icon: Icons.schedule_rounded,
            label: context.t('configuracoes.timeZone', fallback: 'Fuso horário'),
            value: formatting.timeZone,
          ),
          _RegionalizacaoInfo(
            icon: Icons.event_available_rounded,
            label: context.t(
              'configuracoes.firstDayOfWeek',
              fallback: 'Primeiro dia da semana',
            ),
            value: _formatFirstDayOfWeek(context, formatting.firstDayOfWeek),
          ),
        ],
      ),
      _RegionalizacaoGroup(
        icon: Icons.format_list_numbered_rounded,
        title: context.t(
          'configuracoes.formattingGroup',
          fallback: 'Formatos',
        ),
        subtitle: context.t(
          'configuracoes.formattingGroupDescription',
          fallback: 'Como datas, horas e números aparecem no app.',
        ),
        items: <_RegionalizacaoInfo>[
          _RegionalizacaoInfo(
            icon: Icons.calendar_month_rounded,
            label: context.t('configuracoes.dateFormat', fallback: 'Formato de data'),
            value: formatting.dateFormat,
          ),
          _RegionalizacaoInfo(
            icon: Icons.access_time_rounded,
            label: context.t('configuracoes.timeFormat', fallback: 'Formato de hora'),
            value: formatting.timeFormat,
          ),
          _RegionalizacaoInfo(
            icon: Icons.more_horiz_rounded,
            label: context.t(
              'configuracoes.decimalSeparator',
              fallback: 'Separador decimal',
            ),
            value: formatting.decimalSeparator,
          ),
          _RegionalizacaoInfo(
            icon: Icons.drag_indicator_rounded,
            label: context.t(
              'configuracoes.thousandSeparator',
              fallback: 'Separador de milhar',
            ),
            value: formatting.thousandSeparator,
          ),
          _RegionalizacaoInfo(
            icon: Icons.pin_rounded,
            label: context.t('configuracoes.numberPattern', fallback: 'Padrão numérico'),
            value: formatting.numberPattern,
          ),
          _RegionalizacaoInfo(
            icon: Icons.exposure_plus_1_rounded,
            label: context.t('configuracoes.decimalPlaces', fallback: 'Casas decimais'),
            value: formatting.decimalPlaces.toString(),
          ),
        ],
      ),
      _RegionalizacaoGroup(
        icon: Icons.payments_rounded,
        title: context.t(
          'configuracoes.financialGroup',
          fallback: 'Financeiro',
        ),
        subtitle: context.t(
          'configuracoes.financialGroupDescription',
          fallback: 'Moeda e regras de arredondamento aplicadas nas operações.',
        ),
        items: <_RegionalizacaoInfo>[
          _RegionalizacaoInfo(
            icon: Icons.account_balance_wallet_rounded,
            label: context.t('configuracoes.currencyCode', fallback: 'Moeda'),
            value: formatting.currencyCode,
          ),
          _RegionalizacaoInfo(
            icon: Icons.currency_exchange_rounded,
            label: context.t(
              'configuracoes.allowMultipleCurrencies',
              fallback: 'Permitir múltiplas moedas',
            ),
            value: _formatBool(context, formatting.allowMultipleCurrencies),
          ),
          _RegionalizacaoInfo(
            icon: Icons.calculate_rounded,
            label: context.t(
              'configuracoes.applyFinancialRounding',
              fallback: 'Arredondamento financeiro',
            ),
            value: _formatBool(context, formatting.applyFinancialRounding),
          ),
        ],
      ),
    ];

    return _RegionalizacaoCard(
      embedded: widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSectionHeader(
            context: context,
            icon: Icons.tune_rounded,
            title: context.t(
              'configuracoes.currentRegionalization',
              fallback: 'Configuração atual',
            ),
            subtitle: context.t(
              'configuracoes.currentRegionalizationDescription',
              fallback:
                  'Resumo dos dados retornados pela API de regionalização. Campos não editáveis ficam disponíveis para conferência.',
            ),
            trailing: _buildReadOnlyBadge(context, theme),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 820;
              final double spacing = 14;
              final double itemWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: groups
                    .map(
                      (group) => SizedBox(
                        width: group == groups.last && !compact
                            ? constraints.maxWidth
                            : itemWidth,
                        child: _buildInfoGroup(context, theme, group),
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

  Widget _buildInfoGroup(
    BuildContext context,
    ThemeData theme,
    _RegionalizacaoGroup group,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(group.icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      group.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      group.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...group.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildInfoRow(context, theme, item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ThemeData theme,
    _RegionalizacaoInfo item,
  ) {
    final value = item.value.trim().isEmpty
        ? context.t('common.notInformed', fallback: 'Não informado')
        : item.value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(item.icon, size: 17, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
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
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableBadge(BuildContext context, ThemeData theme) {
    return _buildStatusBadge(
      context: context,
      theme: theme,
      icon: Icons.edit_rounded,
      label: context.t('common.editable', fallback: 'Editável'),
      color: theme.colorScheme.primary,
    );
  }

  Widget _buildReadOnlyBadge(BuildContext context, ThemeData theme) {
    return _buildStatusBadge(
      context: context,
      theme: theme,
      icon: Icons.lock_outline_rounded,
      label: context.t('common.readOnly', fallback: 'Somente leitura'),
      color: theme.colorScheme.onSurfaceVariant,
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

  String _formatBool(BuildContext context, bool value) {
    return value
        ? context.t('common.yes', fallback: 'Sim')
        : context.t('common.no', fallback: 'Não');
  }

  String _formatFirstDayOfWeek(BuildContext context, String value) {
    switch (value.toUpperCase()) {
      case 'MONDAY':
        return context.t('common.monday', fallback: 'Segunda-feira');
      case 'SUNDAY':
        return context.t('common.sunday', fallback: 'Domingo');
      case 'SATURDAY':
        return context.t('common.saturday', fallback: 'Sábado');
      default:
        return value;
    }
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

class _RegionalizacaoGroup {
  const _RegionalizacaoGroup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<_RegionalizacaoInfo> items;
}

class _RegionalizacaoInfo {
  const _RegionalizacaoInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
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
    badge: 'BR',
    locale: Locale('pt', 'BR'),
  );

  static const _LanguageOption ingles = _LanguageOption(
    labelKey: 'configuracoes.languageEnglish',
    labelFallback: 'English',
    descriptionKey: 'configuracoes.languageEnglishDescription',
    descriptionFallback: 'United States • en-US',
    badge: 'US',
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
