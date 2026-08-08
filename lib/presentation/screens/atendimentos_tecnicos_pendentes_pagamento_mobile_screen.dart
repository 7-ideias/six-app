import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../components/mobile_motion.dart';
import '../components/six_backend_loading.dart';

class AtendimentosTecnicosPendentesPagamentoMobileScreen
    extends StatefulWidget {
  const AtendimentosTecnicosPendentesPagamentoMobileScreen({
    super.key,
    this.service,
  });

  final AtendimentoTecnicoService? service;

  @override
  State<AtendimentosTecnicosPendentesPagamentoMobileScreen> createState() =>
      _AtendimentosTecnicosPendentesPagamentoMobileScreenState();
}

class _AtendimentosTecnicosPendentesPagamentoMobileScreenState
    extends State<AtendimentosTecnicosPendentesPagamentoMobileScreen> {
  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = Color(0xFF0F766E);

  late final AtendimentoTecnicoService _service;
  late Future<List<AtendimentoTecnicoModel>> _future;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AtendimentoTecnicoService();
    _future = _carregar();
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  Future<List<AtendimentoTecnicoModel>> _carregar() async {
    final List<AtendimentoTecnicoModel> atendimentos = await _service.listar();
    final List<AtendimentoTecnicoModel> pendentes = atendimentos
      .where(_temFinanceiroAberto)
      .toList(growable: false)..sort(_ordenarPendencias);
    return pendentes;
  }

  Future<void> _recarregar() async {
    setState(() => _future = _carregar());
    await _future;
  }

  bool _temFinanceiroAberto(AtendimentoTecnicoModel atendimento) {
    return !atendimento.operacaoLiquidada && atendimento.valorEmAberto > 0;
  }

  int _ordenarPendencias(
    AtendimentoTecnicoModel first,
    AtendimentoTecnicoModel second,
  ) {
    final DateTime firstDate =
        first.dataVencimentoEm ??
        first.dataAtualizacao ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime secondDate =
        second.dataVencimentoEm ??
        second.dataAtualizacao ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final int dateCompare = firstDate.compareTo(secondDate);
    if (dateCompare != 0) return dateCompare;
    return first.numero.compareTo(second.numero);
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}',
    );

    return SixMobilePageShell(
      title: _t(
        'atendimento.mobile.technicalServicesPendingPaymentTitle',
        'Atendimentos técnicos pendentes de pagamento',
      ),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 8,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      leading: IconButton(
        tooltip: _t('common.back', 'Voltar'),
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: _t('common.refresh', 'Atualizar'),
          onPressed: _recarregar,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bodyBuilder: _buildContent,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _recarregar,
        color: _accentColor,
        backgroundColor: SixMobilePalette.surface,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
          children: <Widget>[
            FutureBuilder<List<AtendimentoTecnicoModel>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<AtendimentoTecnicoModel>> snapshot,
              ) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return SixBackendLoading.messages(
                    title: _t(
                      'atendimento.mobile.pendingPaymentsLoadingTitle',
                      'Carregando atendimentos',
                    ),
                    subtitle: _t(
                      'atendimento.mobile.pendingPaymentsLoadingSubtitle',
                      'Buscando serviços com financeiro em aberto.',
                    ),
                    animation: SixBackendLoadingAnimation.skeletonPulse,
                    leadingIcon: Icons.cloud_sync_outlined,
                  );
                }

                if (snapshot.hasError) {
                  return _errorState();
                }

                return _successState(
                  atendimentos:
                      snapshot.data ?? const <AtendimentoTecnicoModel>[],
                  reduceMotion: reduceMotion,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _successState({
    required List<AtendimentoTecnicoModel> atendimentos,
    required bool reduceMotion,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _entry(
          _header(atendimentos: atendimentos, reduceMotion: reduceMotion),
          reduceMotion: reduceMotion,
        ),
        const SizedBox(height: 18),
        _entry(
          _section(
            _t(
              'atendimento.mobile.pendingPaymentSection',
              'Atendimentos com saldo',
            ),
          ),
          delay: const Duration(milliseconds: 70),
          reduceMotion: reduceMotion,
        ),
        const SizedBox(height: 12),
        if (atendimentos.isEmpty)
          _entry(
            _emptyState(),
            delay: const Duration(milliseconds: 110),
            reduceMotion: reduceMotion,
          )
        else
          ...atendimentos.asMap().entries.map((
            MapEntry<int, AtendimentoTecnicoModel> entry,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _entry(
                _atendimentoCard(entry.value),
                delay: Duration(milliseconds: 110 + entry.key * 40),
                reduceMotion: reduceMotion,
              ),
            );
          }),
      ],
    );
  }

  Widget _entry(
    Widget child, {
    Duration delay = Duration.zero,
    required bool reduceMotion,
  }) {
    if (reduceMotion) return child;
    return SixStaggeredEntry(delay: delay, child: child);
  }

  Widget _header({
    required List<AtendimentoTecnicoModel> atendimentos,
    required bool reduceMotion,
  }) {
    final double totalAberto = atendimentos.fold<double>(
      0,
      (double total, AtendimentoTecnicoModel atendimento) =>
          total + atendimento.valorEmAberto,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.heroShadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _icon(
                Icons.home_repair_service_outlined,
                bg: _withAlpha(SixMobilePalette.onPrimary, 0.12),
                fg: SixMobilePalette.onPrimary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _t(
                        'atendimento.mobile.pendingPaymentHeaderTitle',
                        'Financeiro aberto',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pendingCountLabel(atendimentos.length),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.heroSupportingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _withAlpha(SixMobilePalette.onPrimary, 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _withAlpha(SixMobilePalette.onPrimary, 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _t(
                    'atendimento.mobile.pendingPaymentTotalOpen',
                    'Total em aberto',
                  ),
                  style: const TextStyle(
                    color: SixMobilePalette.heroLabelText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>(
                    'atendimento-pending-total-${totalAberto.toStringAsFixed(2)}',
                  ),
                  tween: Tween<double>(begin: 0, end: totalAberto),
                  duration:
                      reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (
                    BuildContext context,
                    double animatedValue,
                    Widget? child,
                  ) {
                    return Text(
                      _formatarMoeda(animatedValue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _atendimentoCard(AtendimentoTecnicoModel atendimento) {
    final String cliente = _clienteLabel(atendimento);
    final String equipamento = _equipamentoTitulo(atendimento);
    final String vencimento = _formatarVencimento(atendimento.dataVencimentoEm);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(22),
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
            children: <Widget>[
              _icon(
                Icons.build_circle_outlined,
                bg: SixMobilePalette.softNeutralSurface,
                fg: _accentColor,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${_t('atendimento.mobile.serviceNumber', 'Atendimento')} ${atendimento.numero}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.titleText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cliente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SixMobilePalette.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill(_statusLabel(atendimento)),
              _pill(vencimento),
              if (equipamento.isNotEmpty) _pill(equipamento),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _amountBlock(
                  label: _t('atendimento.mobile.openValue', 'Valor em aberto'),
                  value: _formatarMoeda(atendimento.valorEmAberto),
                  highlight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _amountBlock(
                  label: _t('atendimento.mobile.totalValue', 'Valor total'),
                  value: _formatarMoeda(atendimento.valorTotalAtendimento),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountBlock({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            highlight
                ? _accentColor.withAlpha(22)
                : SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              highlight ? _accentColor.withAlpha(52) : SixMobilePalette.border,
        ),
      ),
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight ? _accentColor : SixMobilePalette.titleText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return _messageState(
      icon: Icons.wifi_off_rounded,
      title: _t(
        'atendimento.mobile.pendingPaymentErrorTitle',
        'Não foi possível carregar',
      ),
      message: _t(
        'atendimento.mobile.pendingPaymentErrorMessage',
        'Tente atualizar os atendimentos técnicos em instantes.',
      ),
    );
  }

  Widget _emptyState() {
    return _messageState(
      icon: Icons.check_circle_outline_rounded,
      title: _t(
        'atendimento.mobile.pendingPaymentEmptyTitle',
        'Nenhum serviço a receber',
      ),
      message: _t(
        'atendimento.mobile.pendingPaymentEmptyMessage',
        'Os atendimentos técnicos estão sem financeiro em aberto.',
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SixMobilePalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Column(
        children: <Widget>[
          _icon(
            icon,
            bg: SixMobilePalette.softNeutralSurface,
            fg: _accentColor,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SixMobilePalette.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: SixMobilePalette.titleText,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _icon(
    IconData icon, {
    required Color bg,
    required Color fg,
    double size = 46,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: fg, size: size * 0.48),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SixMobilePalette.softNeutralSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SixMobilePalette.border),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: SixMobilePalette.mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _pendingCountLabel(int count) {
    if (count == 1) {
      return _t(
        'atendimento.mobile.onePendingPaymentService',
        '1 atendimento com financeiro aberto',
      );
    }

    return '$count ${_t('atendimento.mobile.pendingPaymentServices', 'atendimentos com financeiro aberto')}';
  }

  String _clienteLabel(AtendimentoTecnicoModel atendimento) {
    final String cliente = atendimento.nomeClienteSnapshot?.trim() ?? '';
    return cliente.isEmpty
        ? _t('atendimentoTecnico.customerNotInformed', 'Cliente não informado')
        : cliente;
  }

  String _statusLabel(AtendimentoTecnicoModel atendimento) {
    final String statusBackend = atendimento.statusNomePtBr?.trim() ?? '';
    if (statusBackend.isNotEmpty) return statusBackend;
    final String codigo = atendimento.statusCodigo.trim();
    return codigo.isEmpty
        ? _t('atendimentoTecnico.status.empty', 'Sem status')
        : codigo;
  }

  String _equipamentoTitulo(AtendimentoTecnicoModel atendimento) {
    final AtendimentoTecnicoEquipamentoModel? equipamento =
        atendimento.equipamento;
    final List<String> partes = <String>[
      equipamento?.tipo ?? '',
      equipamento?.marca ?? '',
      equipamento?.modelo ?? '',
    ].where((String value) => value.trim().isNotEmpty).toList(growable: false);
    return partes.join(' ');
  }

  String _formatarVencimento(DateTime? value) {
    if (value == null) {
      return _t('atendimento.mobile.noDueDate', 'Sem vencimento');
    }
    final String label = _t('atendimento.mobile.dueDate', 'Vence em');
    return '$label ${context.read<LocaleSettingsProvider>().formatDate(value)}';
  }

  String _formatarMoeda(num value) {
    return context.read<LocaleSettingsProvider>().formatCurrency(value);
  }

  Color _withAlpha(Color color, double opacity) {
    return color.withAlpha((opacity.clamp(0, 1) * 255).round());
  }
}
