import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/recebivel_venda_service.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';

class RecebiveisVendasWeb extends StatefulWidget {
  const RecebiveisVendasWeb({super.key});
  @override
  State<RecebiveisVendasWeb> createState() => _RecebiveisVendasWebState();
}

class _RecebiveisVendasWebState extends State<RecebiveisVendasWeb> {
  final _service = RecebivelVendaService();
  List<RecebivelVenda> _items = [];
  bool _loading = true, _error = false, _saving = false;
  String _filtro = 'PREVISTO';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await _service.listar();
      if (mounted) setState(() => _items = result);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acao(RecebivelVenda item) async {
    if (_saving) return;
    final locale = context.read<LocaleSettingsProvider>();
    final valor = TextEditingController(
      text: locale.formatDecimal(item.liquido),
    );
    DateTime data = DateTime.now();
    double numero() =>
        double.tryParse(
          valor.text
              .replaceAll(locale.thousandSeparator, '')
              .replaceAll(locale.decimalSeparator, '.'),
        ) ??
        0;
    Widget form(BuildContext ctx, StateSetter update) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t(
            item.status == 'PREVISTO' ? 'machine.confirm' : 'machine.reverse',
          ),
          style: Theme.of(ctx).textTheme.titleLarge,
        ),
        Text(
          [
            item.codigoOperacao,
            item.descricao,
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
        const SizedBox(height: 16),
        if (item.status == 'PREVISTO') ...[
          TextField(
            controller: valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.t('machine.actualAmount'),
            ),
            onChanged: (_) => update(() {}),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(locale.formatDate(data)),
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: data,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (selected != null && ctx.mounted)
                update(() => data = selected);
            },
          ),
        ] else
          Text(context.t('machine.reverseHint')),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              item.status != 'PREVISTO' || numero() > 0
                  ? () => Navigator.pop(ctx, true)
                  : null,
          child: Text(context.t('space.save')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.t('space.cancel')),
        ),
      ],
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, update) => Dialog(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: form(ctx, update),
                    ),
                  ),
                ),
          ),
    );
    final amount = numero();
    valor.dispose();
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      if (item.status == 'PREVISTO') {
        await _service.confirmar(item.id, data, amount);
      } else {
        await _service.estornar(item.id);
      }
      if (mounted) await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.t('space.saveError'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleSettingsProvider>();
    final visible = _items.where((r) => r.status == _filtro).toList();
    final content = <Widget>[
      Text(context.t('machine.receivablesHint')),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in ['PREVISTO', 'RECEBIDO', 'CANCELADO'])
            ChoiceChip(
              label: Text(context.t('machine.' + s)),
              selected: _filtro == s,
              onSelected: (_) => setState(() => _filtro = s),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (_loading)
        SixBackendLoading(
          title: context.t('space.loading'),
          subtitle: context.t('machine.receivables'),
        )
      else if (_error)
        TextButton(onPressed: _load, child: Text(context.t('space.retry')))
      else if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.t('space.empty')),
        )
      else ...[
        for (final item in visible)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    [
                      item.codigoOperacao,
                      item.descricao,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    [
                      item.maquininha,
                      item.conta,
                    ].where((v) => v.isNotEmpty).join(' · '),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${context.t('machine.gross')}: ${locale.formatCurrency(item.bruto)}',
                      ),
                      Text(
                        '${context.t('machine.fee')}: ${locale.formatCurrency(item.taxa)}',
                      ),
                      Text(
                        '${context.t('machine.net')}: ${locale.formatCurrency(item.liquido)}',
                      ),
                    ],
                  ),
                  Text(
                    '${context.t('machine.expectedDate')}: ${locale.formatDate(item.data)}',
                  ),
                  if (item.status == 'RECEBIDO')
                    Text(
                      '${context.t('machine.actualAmount')}: ${locale.formatCurrency(item.valorRecebido ?? 0)} · ${item.dataRecebimento == null ? '' : locale.formatDate(item.dataRecebimento!)}',
                    ),
                  if (item.status != 'CANCELADO')
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => _acao(item),
                        child: Text(
                          context.t(
                            item.status == 'PREVISTO'
                                ? 'machine.confirm'
                                : 'machine.reverse',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
      TextButton(
        onPressed: _loading || _saving ? null : _load,
        child: Text(context.t('space.retry')),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.t('machine.receivables'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(padding: const EdgeInsets.all(24), children: content),
        ),
      ),
    );
  }
}
