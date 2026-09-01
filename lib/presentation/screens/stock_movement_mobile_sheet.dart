import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/produto_cadastro_form_utils.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/stock_movement_model.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

Future<bool?> showStockMovementMobileSheet({
  required BuildContext context,
  required StockMovementType type,
  required ProdutoService produtoService,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) =>
        _StockMovementMobileSheet(type: type, produtoService: produtoService),
  );
}

class _StockMovementMobileSheet extends StatefulWidget {
  const _StockMovementMobileSheet({
    required this.type,
    required this.produtoService,
  });

  final StockMovementType type;
  final ProdutoService produtoService;

  @override
  State<_StockMovementMobileSheet> createState() =>
      _StockMovementMobileSheetState();
}

class _StockMovementMobileSheetState extends State<_StockMovementMobileSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  List<ProdutoModel> _products = const <ProdutoModel>[];
  ProdutoModel? _selectedProduct;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEntry => widget.type == StockMovementType.entry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<ProdutoModel> products = await widget.produtoService
          .buscarProdutosAtivosParaEstoque();
      if (!mounted) return;
      products.sort(
        (ProdutoModel first, ProdutoModel second) => first.nomeProduto
            .toLowerCase()
            .compareTo(second.nomeProduto.toLowerCase()),
      );
      setState(() {
        _products = products;
        _selectedProduct = products.length == 1 ? products.first : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.t(
          'stockMovement.errors.loadProducts',
          fallback: 'Não foi possível carregar os produtos.',
        );
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.produtoService.registrarMovimentacaoEstoque(
        StockMovementRequest(
          productId: _selectedProduct!.id!,
          type: widget.type,
          quantity: _number(context, _quantityController.text)!,
          unitCost: _isEntry ? _number(context, _costController.text) : null,
          reason: _reasonController.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StockMovementException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _messageForError(context, error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = context.t(
          'stockMovement.errors.save',
          fallback: 'Não foi possível registrar a movimentação.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.strongBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.softAccentSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isEntry
                          ? Icons.add_box_outlined
                          : Icons.indeterminate_check_box_outlined,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _isEntry
                              ? context.t(
                                  'stockMovement.entry.title',
                                  fallback: 'Registrar entrada',
                                )
                              : context.t(
                                  'stockMovement.exit.title',
                                  fallback: 'Registrar saída',
                                ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.titleText,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.t(
                            'stockMovement.mobile.subtitle',
                            fallback:
                                'Informe o item, a quantidade e o motivo.',
                          ),
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (_error != null) ...<Widget>[
                        _MobileError(message: _error!),
                        const SizedBox(height: 14),
                      ],
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_products.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text(
                              context.t(
                                'stockMovement.emptyProducts',
                                fallback:
                                    'Cadastre um produto antes de movimentar o estoque.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.mutedText),
                            ),
                          ),
                        )
                      else ...<Widget>[
                        DropdownButtonFormField<ProdutoModel>(
                          initialValue: _selectedProduct,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.t(
                              'stockMovement.product',
                              fallback: 'Produto',
                            ),
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                          ),
                          items: _products
                              .map(
                                (ProdutoModel product) =>
                                    DropdownMenuItem<ProdutoModel>(
                                      value: product,
                                      child: Text(
                                        product.nomeProduto,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: _saving
                              ? null
                              : (ProdutoModel? value) =>
                                    setState(() => _selectedProduct = value),
                          validator: (ProdutoModel? value) => value == null
                              ? context.t(
                                  'stockMovement.validation.product',
                                  fallback: 'Selecione um produto.',
                                )
                              : null,
                        ),
                        if (_selectedProduct != null) ...<Widget>[
                          const SizedBox(height: 9),
                          _MobileBalance(product: _selectedProduct!),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _quantityController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: context.t(
                              'stockMovement.quantity',
                              fallback: 'Quantidade',
                            ),
                            prefixIcon: const Icon(Icons.numbers_rounded),
                          ),
                          validator: (String? value) {
                            final double? number = _number(
                              context,
                              value ?? '',
                            );
                            if (number == null || number <= 0) {
                              return context.t(
                                'stockMovement.validation.quantity',
                                fallback:
                                    'Informe uma quantidade maior que zero.',
                              );
                            }
                            return null;
                          },
                        ),
                        if (_isEntry) ...<Widget>[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _costController,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: context.t(
                                'stockMovement.unitCost',
                                fallback: 'Custo unitário (opcional)',
                              ),
                              prefixIcon: const Icon(Icons.payments_outlined),
                            ),
                            validator: (String? value) {
                              if ((value ?? '').trim().isEmpty) return null;
                              final double? number = _number(context, value!);
                              return number == null || number < 0
                                  ? context.t(
                                      'stockMovement.validation.cost',
                                      fallback: 'Informe um custo válido.',
                                    )
                                  : null;
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _reasonController,
                          enabled: !_saving,
                          minLines: 2,
                          maxLines: 3,
                          maxLength: 240,
                          decoration: InputDecoration(
                            labelText: context.t(
                              'stockMovement.reason',
                              fallback: 'Motivo',
                            ),
                            hintText: context.t(
                              'stockMovement.mobile.reasonHint',
                              fallback:
                                  'Ex.: recebimento ou ajuste de inventário',
                            ),
                            alignLabelWithHint: true,
                          ),
                          validator: (String? value) =>
                              (value ?? '').trim().isEmpty
                              ? context.t(
                                  'stockMovement.validation.reason',
                                  fallback: 'Informe o motivo da movimentação.',
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading || _products.isEmpty || _saving
                      ? null
                      : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isEntry
                              ? Icons.add_box_outlined
                              : Icons.indeterminate_check_box_outlined,
                        ),
                  label: Text(
                    _saving
                        ? context.t(
                            'stockMovement.saving',
                            fallback: 'Registrando...',
                          )
                        : context.t(
                            'stockMovement.confirm',
                            fallback: 'Confirmar movimentação',
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileBalance extends StatelessWidget {
  const _MobileBalance({required this.product});

  final ProdutoModel product;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    final double balance =
        product.objEntradaSaidaProduto?.fold<double>(
          0,
          (double total, ObjEntradaSaidaProduto item) =>
              total + item.quantidade,
        ) ??
        0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.inventory_outlined, color: colors.accent, size: 18),
          const SizedBox(width: 8),
          Text(
            context
                .t(
                  'stockMovement.currentBalance',
                  fallback: 'Saldo atual: {value}',
                )
                .replaceFirst('{value}', _quantity(balance)),
            style: TextStyle(
              color: colors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileError extends StatelessWidget {
  const _MobileError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.errorBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: colors.error),
          const SizedBox(width: 9),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.titleText)),
          ),
        ],
      ),
    );
  }
}

double? _number(BuildContext context, String value) {
  final LocaleSettingsProvider locale = context
      .read<LocaleSettingsProvider>();
  return ProdutoCadastroFormUtils.tryParseDecimal(
    value,
    numberFormat: ProdutoCadastroNumberFormat(
      decimalSeparator: locale.decimalSeparator,
      thousandSeparator: locale.thousandSeparator,
    ),
  );
}

String _quantity(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceAll('.', ',');
}

String _messageForError(BuildContext context, StockMovementException error) {
  final String code = error.errorCode.toUpperCase();
  if (code.contains('ESTOQUE_INSUFICIENTE')) {
    return context.t(
      'stockMovement.errors.insufficientStock',
      fallback: 'A saída é maior que o saldo disponível.',
    );
  }
  if (code.contains('PERMISSAO') || error.statusCode == 403) {
    return context.t(
      'stockMovement.errors.permission',
      fallback: 'Seu perfil não permite movimentar o estoque.',
    );
  }
  if (code.contains('PRODUTO_NAO_ENCONTRADO') || error.statusCode == 404) {
    return context.t(
      'stockMovement.errors.productNotFound',
      fallback: 'O produto não foi encontrado neste comércio.',
    );
  }
  return context.t(
    'stockMovement.errors.save',
    fallback: 'Não foi possível registrar a movimentação.',
  );
}
