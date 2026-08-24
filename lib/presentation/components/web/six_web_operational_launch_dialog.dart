import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/caixa_models.dart';
import '../../../l10n/six_i18n.dart';
import '../../theme/web_theme_tokens.dart';

class SixWebOperationalLaunchSubmission {
  const SixWebOperationalLaunchSubmission({
    required this.operationType,
    required this.relatedType,
    required this.amount,
    required this.reference,
    required this.observation,
    required this.linkedSale,
  });

  final OperacaoCaixaTipo operationType;
  final TiposRecebimento relatedType;
  final double amount;
  final String reference;
  final String observation;
  final bool linkedSale;
}

Future<bool> showSixWebOperationalLaunchDialog({
  required BuildContext context,
  required String cashDeskName,
  required List<OperacaoCaixaTipo> operationTypes,
  required List<TiposRecebimento> relatedTypes,
  required String Function(OperacaoCaixaTipo) operationLabel,
  required IconData Function(OperacaoCaixaTipo) operationIcon,
  required String Function(TiposRecebimento) relatedTypeLabel,
  required String currencySymbol,
  required String Function(double) formatCurrency,
  required Future<void> Function(SixWebOperationalLaunchSubmission submission)
  onConfirm,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final bool? result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 280),
    pageBuilder: (
      BuildContext routeContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _OperationalLaunchRouteSurface(
        animation: animation,
        reduceMotion: reduceMotion,
        child: SixWebOperationalLaunchDialog(
          cashDeskName: cashDeskName,
          operationTypes: operationTypes,
          relatedTypes: relatedTypes,
          operationLabel: operationLabel,
          operationIcon: operationIcon,
          relatedTypeLabel: relatedTypeLabel,
          currencySymbol: currencySymbol,
          formatCurrency: formatCurrency,
          onConfirm: onConfirm,
        ),
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => child,
  );

  return result ?? false;
}

class SixWebOperationalLaunchDialog extends StatefulWidget {
  const SixWebOperationalLaunchDialog({
    super.key,
    required this.cashDeskName,
    required this.operationTypes,
    required this.relatedTypes,
    required this.operationLabel,
    required this.operationIcon,
    required this.relatedTypeLabel,
    required this.currencySymbol,
    required this.formatCurrency,
    required this.onConfirm,
  });

  final String cashDeskName;
  final List<OperacaoCaixaTipo> operationTypes;
  final List<TiposRecebimento> relatedTypes;
  final String Function(OperacaoCaixaTipo) operationLabel;
  final IconData Function(OperacaoCaixaTipo) operationIcon;
  final String Function(TiposRecebimento) relatedTypeLabel;
  final String currencySymbol;
  final String Function(double) formatCurrency;
  final Future<void> Function(SixWebOperationalLaunchSubmission submission)
  onConfirm;

  @override
  State<SixWebOperationalLaunchDialog> createState() =>
      _SixWebOperationalLaunchDialogState();
}

enum _OperationalLaunchState { form, review, processing, success, error }

class _SixWebOperationalLaunchDialogState
    extends State<SixWebOperationalLaunchDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;
  late final TextEditingController _observationController;
  late final AnimationController _iconController;

  OperacaoCaixaTipo? _selectedOperationType;
  TiposRecebimento? _selectedRelatedType;
  bool _linkedSale = false;
  String? _validationMessage;
  _OperationalLaunchState _state = _OperationalLaunchState.form;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  bool get _isBusy =>
      _state == _OperationalLaunchState.processing ||
      _state == _OperationalLaunchState.success;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _referenceController = TextEditingController();
    _observationController = TextEditingController();
    _selectedRelatedType =
        widget.relatedTypes.isNotEmpty ? widget.relatedTypes.first : null;
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _iconController.value = 1;
      } else {
        _iconController.forward();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _observationController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _handleEscape() {
    if (_isBusy) return;
    if (_state == _OperationalLaunchState.review ||
        _state == _OperationalLaunchState.error) {
      setState(() {
        _state = _OperationalLaunchState.form;
        _validationMessage = null;
      });
      return;
    }
    Navigator.of(context).pop(false);
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  double _parseCurrency(String text) {
    final cleaned =
        text
            .replaceAll(RegExp(r'[^0-9,.\-]'), '')
            .replaceAll('.', '')
            .replaceAll(' ', '')
            .replaceAll(',', '.')
            .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  SixWebOperationalLaunchSubmission? _buildSubmission() {
    if (_selectedOperationType == null) {
      _validationMessage = _txt(
        'caixa.operacoes.launchDialogTypeRequired',
        'Selecione o tipo da operação.',
      );
      return null;
    }
    if (_selectedRelatedType == null) {
      _validationMessage = _txt(
        'caixa.operacoes.launchDialogRelatedTypeRequired',
        'Selecione a forma relacionada.',
      );
      return null;
    }

    final double amount = _parseCurrency(_amountController.text);
    if (amount <= 0) {
      _validationMessage = _txt(
        'caixa.operacoes.launchDialogAmountRequired',
        'Informe um valor válido.',
      );
      return null;
    }

    _validationMessage = null;
    return SixWebOperationalLaunchSubmission(
      operationType: _selectedOperationType!,
      relatedType: _selectedRelatedType!,
      amount: amount,
      reference: _referenceController.text.trim(),
      observation: _observationController.text.trim(),
      linkedSale: _linkedSale,
    );
  }

  Future<void> _continueToReview() async {
    if (_isBusy) return;
    final submission = _buildSubmission();
    if (submission == null) {
      setState(() {});
      return;
    }
    setState(() {
      _state = _OperationalLaunchState.review;
      _validationMessage = null;
    });
  }

  Future<void> _confirm() async {
    if (_isBusy) return;
    final submission = _buildSubmission();
    if (submission == null) {
      setState(() => _state = _OperationalLaunchState.form);
      return;
    }

    setState(() => _state = _OperationalLaunchState.processing);
    try {
      await widget.onConfirm(submission);
      if (!mounted) return;
      setState(() => _state = _OperationalLaunchState.success);
      await Future<void>.delayed(
        Duration(milliseconds: _reduceMotion ? 350 : 820),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _OperationalLaunchState.error);
    }
  }

  void _back() {
    if (_isBusy) return;
    if (_state == _OperationalLaunchState.review ||
        _state == _OperationalLaunchState.error) {
      setState(() {
        _state = _OperationalLaunchState.form;
        _validationMessage = null;
      });
      return;
    }
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent =
        theme.brightness == Brightness.dark
            ? const Color(0xFF60A5FA)
            : const Color(0xFF2563EB);

    return PopScope(
      canPop: !_isBusy,
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.escape):
              const _DismissIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _DismissIntent: CallbackAction<_DismissIntent>(
              onInvoke: (intent) {
                _handleEscape();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Semantics(
              namesRoute: true,
              label: _txt(
                'caixa.operacoes.launchDialogTitle',
                'Registrar lançamento operacional',
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF020617).withValues(alpha: 0.30),
                        blurRadius: 44,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: tokens.surfaceElevated,
                      surfaceTintColor: Colors.transparent,
                      child: Stack(
                        children: <Widget>[
                          AnimatedSwitcher(
                            duration: Duration(
                              milliseconds: _reduceMotion ? 1 : 240,
                            ),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child:
                                _state == _OperationalLaunchState.success
                                    ? _buildSuccess(theme, tokens)
                                    : (_state == _OperationalLaunchState.form
                                        ? _buildForm(theme, tokens, accent)
                                        : _buildReview(theme, tokens, accent)),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(height: 3, color: accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, WebThemeTokens tokens, Color accent) {
    return SingleChildScrollView(
      key: const ValueKey<String>('operational-launch-form'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _OperationalLaunchIcon(
                animation: _iconController,
                accent: accent,
                surfaceColor: tokens.surfaceElevated,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'caixa.operacoes.launchDialogTitle',
                        'Registrar lançamento operacional',
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'caixa.operacoes.launchDialogSubtitle',
                        'Preencha os dados da operação e revise antes de registrar no caixa.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildContextSummary(theme, tokens),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              SizedBox(
                width: 280,
                child: _DialogSelectField<OperacaoCaixaTipo>(
                  key: const ValueKey<String>('operational-launch-type-field'),
                  label: _txt(
                    'caixa.operacoes.launchDialogTypeLabel',
                    'Tipo da operação',
                  ),
                  hint: _txt('caixa.operacoes.launchDialogSelect', 'Selecione'),
                  value: _selectedOperationType,
                  items: widget.operationTypes,
                  itemLabel: widget.operationLabel,
                  itemIcon: widget.operationIcon,
                  onSelected:
                      (OperacaoCaixaTipo item) =>
                          setState(() => _selectedOperationType = item),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  key: const ValueKey<String>(
                    'operational-launch-amount-field',
                  ),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  decoration: _inputDecoration(
                    theme,
                    tokens,
                    label: _txt(
                      'caixa.operacoes.launchDialogAmountLabel',
                      'Valor',
                    ),
                    hint: '0,00',
                    prefixText:
                        widget.currencySymbol.trim().isEmpty
                            ? null
                            : '${widget.currencySymbol} ',
                  ),
                ),
              ),
              SizedBox(
                width: 300,
                child: _DialogSelectField<TiposRecebimento>(
                  key: const ValueKey<String>(
                    'operational-launch-related-type-field',
                  ),
                  label: _txt(
                    'caixa.operacoes.launchDialogRelatedTypeLabel',
                    'Forma relacionada',
                  ),
                  hint: _txt('caixa.operacoes.launchDialogSelect', 'Selecione'),
                  value: _selectedRelatedType,
                  items: widget.relatedTypes,
                  itemLabel: widget.relatedTypeLabel,
                  itemIcon: (_) => Icons.payments_outlined,
                  onSelected:
                      (TiposRecebimento item) =>
                          setState(() => _selectedRelatedType = item),
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  key: const ValueKey<String>(
                    'operational-launch-reference-field',
                  ),
                  controller: _referenceController,
                  decoration: _inputDecoration(
                    theme,
                    tokens,
                    label: _txt(
                      'caixa.operacoes.launchDialogReferenceLabel',
                      'Referência / comprovante',
                    ),
                    hint: _txt(
                      'caixa.operacoes.launchDialogReferenceHint',
                      'Ex.: MOV-001',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('operational-launch-observation-field'),
            controller: _observationController,
            minLines: 4,
            maxLines: 4,
            decoration: _inputDecoration(
              theme,
              tokens,
              label: _txt(
                'caixa.operacoes.launchDialogObservationLabel',
                'Observação',
              ),
              hint: _txt(
                'caixa.operacoes.launchDialogObservationHint',
                'Descreva o motivo da movimentação com clareza.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            value: _linkedSale,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              _txt(
                'caixa.operacoes.launchDialogLinkedSaleLabel',
                'Possui vínculo com venda',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              _txt(
                'caixa.operacoes.launchDialogLinkedSaleHint',
                'Use em estornos ou situações relacionadas a atendimento anterior.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.secondaryText,
                height: 1.4,
              ),
            ),
            onChanged: (bool? value) {
              setState(() => _linkedSale = value ?? false);
            },
          ),
          if (_validationMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            _buildErrorBanner(
              theme,
              tokens,
              message: _validationMessage!,
              danger: false,
            ),
          ],
          const SizedBox(height: 20),
          Divider(height: 1, color: tokens.divider),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: _back,
                child: Text(_txt('common.cancel', 'Cancelar')),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _continueToReview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(
                  _txt(
                    'caixa.operacoes.launchDialogReviewAction',
                    'Revisar lançamento',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReview(ThemeData theme, WebThemeTokens tokens, Color accent) {
    final SixWebOperationalLaunchSubmission submission = _buildSubmission()!;
    return Padding(
      key: const ValueKey<String>('operational-launch-review'),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _OperationalLaunchIcon(
                animation: _iconController,
                accent: accent,
                surfaceColor: tokens.surfaceElevated,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'caixa.operacoes.launchDialogReviewTitle',
                        'Confirmar lançamento operacional?',
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'caixa.operacoes.launchDialogReviewSubtitle',
                        'Revise os dados abaixo antes de registrar a movimentação no caixa.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildReviewSummary(theme, tokens, submission),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.info.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: tokens.info, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _txt(
                    'caixa.operacoes.launchDialogChecklist',
                    'Resumo pronto para confirmação.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_state == _OperationalLaunchState.error) ...<Widget>[
            const SizedBox(height: 16),
            _buildErrorBanner(
              theme,
              tokens,
              message: _txt(
                'caixa.operacoes.launchDialogError',
                'Não foi possível registrar a movimentação. Verifique os dados e tente novamente.',
              ),
            ),
          ],
          const SizedBox(height: 22),
          Divider(height: 1, color: tokens.divider),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: _back,
                child: Text(
                  _txt(
                    'caixa.operacoes.launchDialogEditAction',
                    'Editar dados',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isBusy ? null : _confirm,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child:
                      _state == _OperationalLaunchState.processing
                          ? const SizedBox(
                            key: ValueKey<String>(
                              'operational-launch-progress',
                            ),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.save_outlined,
                            key: ValueKey<String>('operational-launch-save'),
                            size: 18,
                          ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _state == _OperationalLaunchState.processing
                        ? _txt(
                          'caixa.operacoes.launchDialogProcessing',
                          'Registrando...',
                        )
                        : (_state == _OperationalLaunchState.error
                            ? _txt('common.tryAgain', 'Tentar novamente')
                            : _txt(
                              'caixa.operacoes.launchDialogConfirmAction',
                              'Registrar movimentação',
                            )),
                    key: ValueKey<_OperationalLaunchState>(_state),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextSummary(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SummaryCell(
              icon: Icons.point_of_sale_outlined,
              label: _txt('caixa.operacoes.closeDialogCashDesk', 'Caixa'),
              value: widget.cashDeskName,
            ).build(theme, tokens),
          ),
          Container(
            width: 1,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: tokens.divider,
          ),
          Expanded(
            child: _SummaryCell(
              icon: Icons.payments_outlined,
              label: _txt(
                'caixa.operacoes.launchDialogAvailableMethods',
                'Formas ativas',
              ),
              value: widget.relatedTypes.length.toString(),
            ).build(theme, tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(
    ThemeData theme,
    WebThemeTokens tokens,
    SixWebOperationalLaunchSubmission submission,
  ) {
    final List<_SummaryCell> items = <_SummaryCell>[
      _SummaryCell(
        icon: widget.operationIcon(submission.operationType),
        label: _txt(
          'caixa.operacoes.launchDialogTypeLabel',
          'Tipo da operação',
        ),
        value: widget.operationLabel(submission.operationType),
      ),
      _SummaryCell(
        icon: Icons.account_balance_wallet_outlined,
        label: _txt('caixa.operacoes.launchDialogAmountLabel', 'Valor'),
        value: widget.formatCurrency(submission.amount),
      ),
      _SummaryCell(
        icon: Icons.payments_outlined,
        label: _txt(
          'caixa.operacoes.launchDialogRelatedTypeLabel',
          'Forma relacionada',
        ),
        value: widget.relatedTypeLabel(submission.relatedType),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 520;
              if (compact) {
                return Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < items.length;
                      index++
                    ) ...<Widget>[
                      items[index].build(theme, tokens),
                      if (index < items.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: tokens.divider),
                        ),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < items.length;
                    index++
                  ) ...<Widget>[
                    Expanded(child: items[index].build(theme, tokens)),
                    if (index < items.length - 1)
                      Container(
                        width: 1,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: tokens.divider,
                      ),
                  ],
                ],
              );
            },
          ),
          if (submission.reference.isNotEmpty ||
              submission.observation.isNotEmpty ||
              submission.linkedSale) ...<Widget>[
            const SizedBox(height: 14),
            Divider(height: 1, color: tokens.divider),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildTag(
                  theme,
                  tokens,
                  icon: Icons.point_of_sale_outlined,
                  text: widget.cashDeskName,
                ),
                if (submission.reference.isNotEmpty)
                  _buildTag(
                    theme,
                    tokens,
                    icon: Icons.tag_rounded,
                    text: submission.reference,
                  ),
                if (submission.linkedSale)
                  _buildTag(
                    theme,
                    tokens,
                    icon: Icons.link_rounded,
                    text: _txt(
                      'caixa.operacoes.launchDialogLinkedSaleTag',
                      'Vinculado a venda',
                    ),
                  ),
              ],
            ),
            if (submission.observation.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _txt(
                        'caixa.operacoes.launchDialogObservationLabel',
                        'Observação',
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      submission.observation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.primaryText,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTag(
    ThemeData theme,
    WebThemeTokens tokens, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tokens.info),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    ThemeData theme,
    WebThemeTokens tokens, {
    required String message,
    bool danger = true,
  }) {
    final Color accent = danger ? tokens.danger : tokens.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            danger ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme, WebThemeTokens tokens) {
    return Padding(
      key: const ValueKey<String>('operational-launch-success'),
      padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: _reduceMotion ? 1 : 360),
            curve: Curves.easeOutBack,
            tween: Tween<double>(begin: 0.72, end: 1),
            builder:
                (BuildContext context, double scale, Widget? child) =>
                    Transform.scale(scale: scale, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tokens.success.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: tokens.success, size: 42),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _txt(
              'caixa.operacoes.launchDialogSuccessTitle',
              'Movimentação registrada com sucesso',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _txt(
              'caixa.operacoes.launchDialogSuccessMessage',
              'O lançamento já aparece no histórico e no resumo do caixa.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme,
    WebThemeTokens tokens, {
    required String label,
    required String hint,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: tokens.inputBackground,
      labelStyle: TextStyle(
        color: tokens.secondaryText,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(color: tokens.mutedText),
      prefixStyle: TextStyle(
        color: tokens.secondaryText,
        fontWeight: FontWeight.w700,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
    );
  }
}

class _OperationalLaunchRouteSurface extends StatelessWidget {
  const _OperationalLaunchRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double progress =
            reduceMotion ? 1 : Curves.easeOutCubic.transform(animation.value);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 12 * progress,
                sigmaY: 12 * progress,
              ),
              child: ColoredBox(
                color: const Color(
                  0xFF0F172A,
                ).withValues(alpha: 0.70 * progress),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - progress)),
                      child: Transform.scale(
                        scale: 0.96 + (0.04 * progress),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _OperationalLaunchIcon extends StatelessWidget {
  const _OperationalLaunchIcon({
    required this.animation,
    required this.accent,
    required this.surfaceColor,
  });

  final Animation<double> animation;
  final Color accent;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double pulse = Curves.easeOutCubic.transform(
          const Interval(0, 0.72).transform(animation.value),
        );
        final double iconScale = Curves.easeOutBack.transform(
          const Interval(0.28, 1).transform(animation.value),
        );
        return SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: (1 - pulse) * 0.26,
                child: Transform.scale(
                  scale: 0.78 + (pulse * 0.46),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.45),
                        width: 2.2,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      accent.withValues(alpha: 0.22),
                      accent.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.24)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.84 + (iconScale * 0.16),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.20)),
                  ),
                  child: Icon(Icons.post_add_rounded, color: accent, size: 22),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DialogSelectField<T> extends StatefulWidget {
  const _DialogSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.itemIcon,
    required this.onSelected,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final IconData Function(T item) itemIcon;
  final ValueChanged<T> onSelected;

  @override
  State<_DialogSelectField<T>> createState() => _DialogSelectFieldState<T>();
}

class _DialogSelectFieldState<T> extends State<_DialogSelectField<T>> {
  bool _hovered = false;
  bool _open = false;

  Future<void> _openMenu() async {
    if (widget.items.isEmpty) return;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ThemeData theme = Theme.of(context);
    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size fieldSize = fieldBox.size;
    final RelativeRect position = RelativeRect.fromLTRB(
      fieldOffset.dx,
      fieldOffset.dy + fieldSize.height + 6,
      overlayBox.size.width - fieldOffset.dx - fieldSize.width,
      0,
    );

    setState(() => _open = true);
    final T? selected = await showMenu<T>(
      context: context,
      position: position,
      color: tokens.menuBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      items: widget.items
          .map((T item) {
            final bool isSelected = item == widget.value;
            return PopupMenuItem<T>(
              value: item,
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? tokens.selectedBackground
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isSelected ? tokens.selectedBorder : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? tokens.cardBackground
                                : tokens.surfaceElevated,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        widget.itemIcon(item),
                        size: 18,
                        color: tokens.info,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.itemLabel(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.primaryText,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: isSelected ? tokens.info : tokens.mutedText,
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = _hovered || _open;
    final String selectedLabel =
        widget.value == null
            ? widget.hint
            : widget.itemLabel(widget.value as T);

    return Semantics(
      button: true,
      label: widget.label,
      value: selectedLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _openMenu,
            child: AnimatedContainer(
              duration: WebThemeTokens.transitionDuration,
              curve: WebThemeTokens.transitionCurve,
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: active ? tokens.surfaceMuted : tokens.inputBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? tokens.selectedBorder : tokens.cardBorder,
                  width: active ? 1.4 : 1,
                ),
                boxShadow:
                    active
                        ? <BoxShadow>[
                          BoxShadow(
                            color: tokens.info.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                        : null,
              ),
              child: Row(
                children: <Widget>[
                  AnimatedContainer(
                    duration: WebThemeTokens.transitionDuration,
                    curve: WebThemeTokens.transitionCurve,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          active
                              ? tokens.info.withValues(alpha: 0.14)
                              : tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      widget.value == null
                          ? Icons.tune_rounded
                          : widget.itemIcon(widget.value as T),
                      size: 18,
                      color: active ? tokens.info : tokens.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.secondaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                widget.value == null
                                    ? tokens.secondaryText
                                    : tokens.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: WebThemeTokens.transitionDuration,
                    curve: WebThemeTokens.transitionCurve,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: active ? tokens.info : tokens.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCell {
  const _SummaryCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  Widget build(ThemeData theme, WebThemeTokens tokens) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: tokens.info, size: 19),
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
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}
