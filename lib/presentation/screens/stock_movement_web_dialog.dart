import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/produto_service.dart';
import 'package:sixpos/core/utils/produto_cadastro_form_utils.dart';
import 'package:sixpos/data/models/produto_model.dart';
import 'package:sixpos/data/models/stock_movement_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

Future<bool?> showStockMovementWebDialog({
  required BuildContext context,
  required StockMovementType type,
  required ProdutoService produtoService,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) =>
        _StockMovementWebDialog(type: type, produtoService: produtoService),
  );
}

class _StockMovementWebDialog extends StatefulWidget {
  const _StockMovementWebDialog({
    required this.type,
    required this.produtoService,
  });

  final StockMovementType type;
  final ProdutoService produtoService;

  @override
  State<_StockMovementWebDialog> createState() =>
      _StockMovementWebDialogState();
}

class _StockMovementWebDialogState extends State<_StockMovementWebDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  List<ProdutoModel> _products = const <ProdutoModel>[];
  ProdutoModel? _selectedProduct;
  bool _loadingProducts = true;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEntry => widget.type == StockMovementType.entry;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
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
        _loadingProducts = false;
        _selectedProduct = products.length == 1 ? products.first : null;
      });
    } on StockMovementException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _errorMessage = _messageForError(context, error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _errorMessage = context.t(
          'stockMovement.errors.loadProducts',
          fallback: 'Não foi possível carregar os produtos.',
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _submitting) return;
    final ProdutoModel product = _selectedProduct!;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await widget.produtoService.registrarMovimentacaoEstoque(
        StockMovementRequest(
          productId: product.id!,
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
        _submitting = false;
        _errorMessage = _messageForError(context, error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = context.t(
          'stockMovement.errors.save',
          fallback: 'Não foi possível registrar a movimentação.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color accent = _isEntry ? tokens.success : tokens.warning;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Material(
          color: tokens.surfaceElevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 18),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _isEntry
                            ? Icons.add_box_outlined
                            : Icons.indeterminate_check_box_outlined,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 13),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: tokens.primaryText,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.t(
                              'stockMovement.subtitle',
                              fallback:
                                  'A movimentação será registrada com usuário, data e motivo.',
                            ),
                            style: TextStyle(color: tokens.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.divider),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_errorMessage != null) ...<Widget>[
                          _ErrorBanner(message: _errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        if (_loadingProducts)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_products.isEmpty)
                          _EmptyProducts()
                        else ...<Widget>[
                          DropdownButtonFormField<ProdutoModel>(
                            initialValue: _selectedProduct,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: context.t(
                                'stockMovement.product',
                                fallback: 'Produto',
                              ),
                              prefixIcon: const Icon(
                                Icons.inventory_2_outlined,
                              ),
                            ),
                            items: _products
                                .map(
                                  (
                                    ProdutoModel product,
                                  ) => DropdownMenuItem<ProdutoModel>(
                                    value: product,
                                    child: Text(
                                      product.nomeProduto.isEmpty
                                          ? context.t(
                                              'stockMovement.unnamedProduct',
                                              fallback: 'Produto sem nome',
                                            )
                                          : product.nomeProduto,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: _submitting
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
                            const SizedBox(height: 10),
                            _BalancePreview(product: _selectedProduct!),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  enabled: !_submitting,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: context.t(
                                      'stockMovement.quantity',
                                      fallback: 'Quantidade',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.numbers_rounded,
                                    ),
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
                              ),
                              if (_isEntry) ...<Widget>[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _costController,
                                    enabled: !_submitting,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: context.t(
                                        'stockMovement.unitCost',
                                        fallback: 'Custo unitário (opcional)',
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.payments_outlined,
                                      ),
                                    ),
                                    validator: (String? value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return null;
                                      }
                                      final double? number = _number(
                                        context,
                                        value!,
                                      );
                                      if (number == null || number < 0) {
                                        return context.t(
                                          'stockMovement.validation.cost',
                                          fallback: 'Informe um custo válido.',
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _reasonController,
                            enabled: !_submitting,
                            maxLength: 240,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: context.t(
                                'stockMovement.reason',
                                fallback: 'Motivo',
                              ),
                              hintText: context.t(
                                'stockMovement.reasonHint',
                                fallback:
                                    'Ex.: recebimento do fornecedor ou ajuste de inventário',
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (String? value) =>
                                (value ?? '').trim().isEmpty
                                ? context.t(
                                    'stockMovement.validation.reason',
                                    fallback:
                                        'Informe o motivo da movimentação.',
                                  )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: tokens.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        context.t('common.cancel', fallback: 'Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed:
                          _loadingProducts || _products.isEmpty || _submitting
                          ? null
                          : _submit,
                      icon: _submitting
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
                        _submitting
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalancePreview extends StatelessWidget {
  const _BalancePreview({required this.product});

  final ProdutoModel product;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
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
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.inventory_outlined, size: 18, color: tokens.info),
          const SizedBox(width: 8),
          Text(
            context
                .t(
                  'stockMovement.currentBalance',
                  fallback: 'Saldo atual: {value}',
                )
                .replaceFirst('{value}', _quantity(balance)),
            style: TextStyle(
              color: tokens.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: <Widget>[
          const Icon(Icons.inventory_2_outlined, size: 42),
          const SizedBox(height: 10),
          Text(
            context.t(
              'stockMovement.emptyProducts',
              fallback: 'Cadastre um produto antes de movimentar o estoque.',
            ),
            textAlign: TextAlign.center,
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
