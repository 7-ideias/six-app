import 'cartoes_credito_mobile_screen.dart';
import 'gastos_categorias_mobile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/providers/management_overview_provider.dart';
import '../components/mobile/agenda_financeira_lancamento_card_mobile.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/six_backend_loading.dart';
import '../components/date_selector_mobile_bottom_sheet.dart';
import 'agenda_financeira_mobile_screen.dart';
import 'formas_recebimento_configuracao_mobile_screen.dart';

class FinanceiroResumoMobileScreen extends StatefulWidget {
  const FinanceiroResumoMobileScreen({
    super.key,
    this.overviewProvider,
    this.notificationIcon,
    this.onNotifications,
    this.onNavigate,
  });
  final ManagementOverviewProvider? overviewProvider;
  final Widget? notificationIcon;
  final VoidCallback? onNotifications;
  final void Function(BuildContext, Widget)? onNavigate;
  @override
  State<FinanceiroResumoMobileScreen> createState() =>
      _FinanceiroResumoMobileScreenState();
}

class _FinanceiroResumoMobileScreenState
    extends State<FinanceiroResumoMobileScreen> {
  late final _provider =
      widget.overviewProvider ??
      ManagementOverviewProvider(
        companyNow: () => context.read<LocaleSettingsProvider>().calendarNow,
      );
  String _espaco = 'EMPRESA';
  int _periodo = 1;
  bool _contextSelected = false;

  bool get _pessoal => _espaco == 'PESSOAL';
  Duration get _motionDuration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 350);
  late DateTime _inicio, _fim;
  bool _loading = true;
  bool _error = false;
  ManagementFinanceOverview? _data;
  DateTime? _updated;
  int _request = 0;
  DateTime get _hoje {
    final n = context.read<LocaleSettingsProvider>().calendarNow;
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _aplicarPeriodo(1);
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final prefs = await UsuarioService()
          .carregarPreferenciasIndividuaisDoCache();
      if (!mounted || _contextSelected) return;
      _espaco =
          prefs?.agendaFinanceiraFiltrosMobile.espacoFinanceiro ?? 'EMPRESA';
    } catch (_) {}
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _request++;
    if (widget.overviewProvider == null) _provider.dispose();
    super.dispose();
  }

  AgendaFinanceiraPeriodoRequest get _intervalo =>
      AgendaFinanceiraPeriodoRequest(
        modo: 'PERSONALIZADO',
        dataInicio: _inicio,
        dataFim: _fim,
      );

  void _aplicarPeriodo(int i) {
    _periodo = i;
    final h = _hoje;
    switch (i) {
      case 0:
        _inicio = h;
        _fim = h;
      case 1:
        _inicio = h;
        _fim = DateTime(h.year, h.month, h.day + 7);
      case 2:
        _inicio = DateTime(h.year, h.month, 1);
        _fim = DateTime(h.year, h.month + 1, 0);
      case 3:
        _inicio = DateTime(h.year, h.month + 1, 1);
        _fim = DateTime(h.year, h.month + 2, 0);
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = false;
      _data = null;
      _updated = null;
    });
    final result = await _provider.consultarFinanceiro(
      espaco: _espaco,
      periodo: _intervalo,
    );
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _error = result.hasError || result.data == null;
      _data = result.data;
      if (!_error) _updated = DateTime.now().toUtc();
    });
  }

  Future<void> _abrirAgenda({
    AgendaContasMobile? contas,
    bool hoje = false,
  }) async {
    final page = AgendaFinanceiraMobileScreen(
      contas: contas,
      espacoInicial: _espaco,
      periodoInicial: hoje
          ? AgendaFinanceiraPeriodoRequest(
              modo: 'HOJE',
              dataInicio: _hoje,
              dataFim: _hoje,
            )
          : _intervalo,
    );
    if (widget.onNavigate != null) {
      widget.onNavigate!(context, page);
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) await _load();
  }

  Future<void> _selecionarPeriodo() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.sixMobileColors.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ctx.t('finance.mobile.period'),
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            for (int i = 0; i < 5; i++)
              ListTile(
                title: Text(ctx.t('finance.mobile.period.$i')),
                trailing: _periodo == i
                    ? Icon(Icons.check, color: ctx.sixMobileColors.accent)
                    : null,
                onTap: () => Navigator.pop(ctx, i),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == 4) {
      Future<DateTime?> escolher(
        String key,
        DateTime initial,
        DateTime first,
      ) => showModalBottomSheet<DateTime>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: context.sixMobileColors.surface,
        builder: (_) => DateSelectorMobileBottomSheet(
          title: context.t(key),
          initialDate: initial,
          firstDate: first,
          lastDate: DateTime(_hoje.year + 10, 12, 31),
        ),
      );
      final inicio = await escolher(
        'finance.mobile.start',
        _inicio,
        DateTime(2000),
      );
      if (!mounted || inicio == null) return;
      final fim = await escolher(
        'finance.mobile.end',
        _fim.isBefore(inicio) ? inicio : _fim,
        inicio,
      );
      if (!mounted || fim == null) return;
      setState(() {
        _periodo = 4;
        _inicio = inicio;
        _fim = fim;
      });
    } else {
      setState(() => _aplicarPeriodo(selected));
    }
    await _load();
  }

  Widget _card(Widget child) {
    final c = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }

  Widget _numero(double value) {
    final regional = context.watch<LocaleSettingsProvider>();
    // Keep the complete localized amount; allow wrapping instead of shrinking
    // the user's text scale or abbreviating large international currencies.
    return Text(
      regional.formatCurrency(value),
      softWrap: true,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: context.sixMobileColors.titleText,
      ),
    );
  }

  Widget _valor(bool receber, ManagementFinanceOverview data) {
    final c = context.sixMobileColors;
    final count = receber ? data.receivableEvents : data.payableEvents;
    final cor = AgendaFinanceiraLancamentoCardMobile.corNatureza(
      context,
      receber,
    );
    final countLabel = context
        .t(
          'finance.mobile.${receber ? 'receipts' : 'payments'}.${count == 0
              ? 'zero'
              : count == 1
              ? 'one'
              : 'many'}',
        )
        .replaceAll('{count}', '$count');
    return InkWell(
      onTap: () => _abrirAgenda(
        contas: receber ? AgendaContasMobile.receber : AgendaContasMobile.pagar,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  receber ? Icons.south_west : Icons.north_east,
                  color: cor,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: context.t(
                            receber
                                ? 'gestao.finance.metric.receivableEvents'
                                : 'gestao.finance.metric.payableEvents',
                          ),
                          style: TextStyle(
                            color: c.titleText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' · $countLabel',
                          style: TextStyle(color: c.mutedText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _numero(receber ? data.totalReceber : data.totalPagar),
          ],
        ),
      ),
    );
  }

  Widget _resumo(ManagementFinanceOverview data) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('gestao.finance.summaryTitle'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.sixMobileColors.titleText,
          ),
        ),
        const SizedBox(height: 6),
        _valor(true, data),
        const Divider(height: 12),
        _valor(false, data),
        const Divider(height: 12),
        InkWell(
          onTap: _abrirAgenda,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: context.sixMobileColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${data.totalEvents} ${context.t('gestao.finance.metric.events')}',
                    style: TextStyle(color: context.sixMobileColors.titleText),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _contextSelector() {
    final c = context.sixMobileColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = _pessoal
        ? (dark ? const Color(0xFF594C32) : const Color(0xFFF4E8CC))
        : c.softAccentSurface;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: _motionDuration,
                curve: Curves.easeInOutCubic,
                alignment: _pessoal
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: .5,
                  heightFactor: 1,
                  child: AnimatedContainer(
                    duration: _motionDuration,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final space in ['EMPRESA', 'PESSOAL'])
                  Expanded(
                    child: Semantics(
                      selected: _espaco == space,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (space == _espaco) return;
                          setState(() {
                            _contextSelected = true;
                            _espaco = space;
                          });
                          _load();
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  space == 'EMPRESA'
                                      ? Icons.storefront_outlined
                                      : Icons.person_outline,
                                  size: 19,
                                  color: c.titleText,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    context.t('space.$space'),
                                    style: TextStyle(
                                      color: c.titleText,
                                      fontSize: 14,
                                      fontWeight: _espaco == space
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _acesso(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback action,
  ) {
    final c = context.sixMobileColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context
                            .t(title)
                            .replaceAll(
                              '{count}',
                              '${_data?.dueTodayEvents ?? 0}',
                            ),
                        style: TextStyle(
                          color: c.titleText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t(subtitle),
                        style: TextStyle(color: c.mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sixMobileColors;
    final regional = context.watch<LocaleSettingsProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final topColor = _pessoal ? const Color(0xFF39352D) : c.primary;
    final title = context.t(
      _pessoal ? 'finance.mobile.personalTitle' : 'finance.mobile.companyTitle',
    );
    return SixMobilePageShell(
      title: title,
      titleWidget: AnimatedSwitcher(
        duration: _motionDuration,
        child: Text(
          title,
          key: ValueKey(_espaco),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundBuilder: (_, child) => AnimatedContainer(
        duration: _motionDuration,
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .18, .44, .72, 1],
            colors: _pessoal
                ? [
                    topColor,
                    dark ? const Color(0xFF514730) : const Color(0xFFA99B7A),
                    dark ? const Color(0xFF302C23) : const Color(0xFFF0E5CD),
                    c.background,
                    c.background,
                  ]
                : [
                    c.primary,
                    Color.lerp(c.primary, c.secondary, .5)!,
                    Color.lerp(c.secondary, c.background, .7)!,
                    c.background,
                    c.background,
                  ],
          ),
        ),
        child: child,
      ),
      backgroundColor: c.background,
      primaryColor: topColor,
      secondaryColor: c.secondary,
      accentColor: c.accent,
      enableAnimatedBackground: false,
      appBarAnimationDuration: _motionDuration,
      actions: [
        IconButton(
          tooltip: context.t('common.refresh'),
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
        if (widget.onNotifications != null)
          IconButton(
            tooltip: context.t('gestao.settings.item.notifications.title'),
            onPressed: widget.onNotifications,
            icon:
                widget.notificationIcon ??
                const Icon(Icons.notifications_outlined),
          ),
      ],
      bodyBuilder: (_, scroll, inset) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, inset + 10, 16, 24),
          children: [
            _contextSelector(),
            const SizedBox(height: 12),
            Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: c.border),
                ),
                leading: Icon(Icons.date_range_outlined, color: c.accent),
                title: Text(context.t('finance.mobile.period.$_periodo')),
                subtitle: Text(
                  '${regional.formatDate(_inicio)} – ${regional.formatDate(_fim)}',
                ),
                trailing: const Icon(Icons.expand_more),
                onTap: _loading ? null : _selecionarPeriodo,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              SixBackendLoading(
                title: context.t('finance.mobile.loading'),
                subtitle: context.t('finance.mobile.openPeriod'),
                compact: true,
                backgroundColor: c.surface,
                borderColor: c.border,
              )
            else if (_error)
              _card(
                Column(
                  children: [
                    Icon(Icons.cloud_off_outlined, color: c.error),
                    const SizedBox(height: 8),
                    Text(context.t('gestao.finance.loadError')),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text(context.t('finance.mobile.retry')),
                    ),
                  ],
                ),
              )
            else if (_data != null) ...[
              TweenAnimationBuilder<double>(
                key: ValueKey('summary-$_espaco-$_request'),
                tween: Tween(begin: 0, end: 1),
                duration: _motionDuration,
                builder: (_, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: _resumo(_data!),
              ),
              if (_updated != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    context
                        .t('agenda.mobile.updated')
                        .replaceAll('{time}', regional.formatTime(_updated!)),
                    textAlign: TextAlign.end,
                    style: TextStyle(color: c.mutedText, fontSize: 12),
                  ),
                ),
              if (_data!.dueTodayEvents > 0)
                _acesso(
                  'finance.mobile.dueToday',
                  'finance.mobile.viewToday',
                  Icons.schedule,
                  AgendaFinanceiraLancamentoCardMobile.corStatus(
                    context,
                    'Vence hoje',
                  ),
                  () => _abrirAgenda(hoje: true),
                ),
              if (_data!.totalEvents == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    context.t('finance.mobile.empty'),
                    style: TextStyle(color: c.mutedText),
                  ),
                ),
            ],
            const SizedBox(height: 10),
            Text(
              context.t('finance.mobile.shortcuts'),
              style: TextStyle(color: c.mutedText, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _acesso(
              'gestao.finance.schedule',
              'finance.mobile.allEntries',
              Icons.event_note_outlined,
              c.accent,
              _abrirAgenda,
            ),
            _acesso(
              'gestao.finance.receivable',
              'gestao.finance.receivableDesc',
              Icons.south_west,
              AgendaFinanceiraLancamentoCardMobile.corNatureza(context, true),
              () => _abrirAgenda(contas: AgendaContasMobile.receber),
            ),
            _acesso(
              'gestao.finance.payable',
              'gestao.finance.payableDesc',
              Icons.north_east,
              c.error,
              () => _abrirAgenda(contas: AgendaContasMobile.pagar),
            ),
            _acesso(
              'cards.title',
              'invoices.title',
              Icons.credit_card_outlined,
              c.accent,
              () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CartoesCreditoMobileScreen(espaco: _espaco),
                  ),
                );
                if (mounted) _load();
              },
            ),
            _acesso(
              'gastos.title',
              'mobile.cards.categoryHint',
              Icons.pie_chart_outline,
              c.accent,
              () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GastosCategoriasMobileScreen(
                      espaco: _espaco,
                      inicio: _inicio,
                      fim: _fim,
                    ),
                  ),
                );
                if (mounted) _load();
              },
            ),
            _acesso(
              'gestao.finance.paymentMethods',
              'gestao.finance.paymentMethodsDesc',
              Icons.account_balance_wallet_outlined,
              c.mutedText,
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const FormasRecebimentoConfiguracaoMobileScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
