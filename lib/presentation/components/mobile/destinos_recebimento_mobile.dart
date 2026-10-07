import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/recebimento_forma_input.dart';
import 'package:sixpos/data/models/destino_recebimento_draft.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'conta_financeira_mobile_field.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';

Future<List<RecebimentoFormaInput>?> selecionarDestinosMobile(
  BuildContext context,
  List<RecebimentoFormaInput> formas,
) {
  return showModalBottomSheet<List<RecebimentoFormaInput>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .88,
          child: DestinosRecebimentoMobile(formas: formas),
        ),
  );
}

class DestinosRecebimentoMobile extends StatefulWidget {
  const DestinosRecebimentoMobile({
    super.key,
    required this.formas,
    this.service,
  });
  final List<RecebimentoFormaInput> formas;
  final ConfiguracaoFinanceiraService? service;
  @override
  State<DestinosRecebimentoMobile> createState() =>
      _DestinosRecebimentoMobileState();
}

class _DestinosRecebimentoMobileState extends State<DestinosRecebimentoMobile> {
  late final _drafts = widget.formas.map(DestinoRecebimentoDraft.new).toList();
  late final _service =
      widget.service ?? ConfiguracaoFinanceiraService('EMPRESA');
  List<ConfiguracaoFinanceira> _contas = [], _maquinas = [];
  bool _loading = true, _erro = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final result = await Future.wait([
        _service.listar('CONTAS'),
        _service.listar('MAQUININHAS'),
      ]);
      if (!mounted) return;
      setState(() {
        _contas = result[0];
        _maquinas = result[1];
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _erro = true;
        });
    }
  }

  Future<void> _selecionar(DestinoRecebimentoDraft d, String grupo) async {
    final id = await selecionarContaMobile(
      context,
      'EMPRESA',
      grupo: grupo,
      service: _service,
      permitirLimpar: grupo == 'MAQUININHAS',
    );
    if (id == null || !mounted) return;
    setState(() {
      if (grupo == 'CONTAS') {
        d.contaId = id;
      } else {
        d.maquininhaId = id.isEmpty ? null : id;
        if (id.isNotEmpty) {
          final m = _maquinas.firstWhere((m) => m.id == id);
          d.contaId = m.contaDestinoId;
          d.futuro = true;
        }
      }
    });
  }

  double _numero(String text) {
    final locale = context.read<LocaleSettingsProvider>();
    return double.tryParse(
          text
              .replaceAll(locale.thousandSeparator, '')
              .replaceAll(locale.decimalSeparator, '.'),
        ) ??
        -1;
  }

  String _nome(String? id, List<ConfiguracaoFinanceira> itens) {
    for (final item in itens) {
      if (item.id == id) return item.nome;
    }
    return context.t('space.none');
  }

  Widget _item(DestinoRecebimentoDraft d, int index) {
    final locale = context.watch<LocaleSettingsProvider>();
    final fields = <Widget>[
      TextFormField(
        key: ValueKey('valor-$index-${_drafts.length}'),
        initialValue: locale.formatDecimal(d.valor),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: context.t('machine.gross')),
        onChanged: (v) => setState(() => d.valor = _numero(v)),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.point_of_sale),
        onPressed: () => _selecionar(d, 'MAQUININHAS'),
        label: Text(
          '${context.t('machine.machine')}: ${_nome(d.maquininhaId, _maquinas)}',
        ),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.account_balance_outlined),
        onPressed: () => _selecionar(d, 'CONTAS'),
        label: Text(
          '${context.t('space.account')}: ${_nome(d.contaId, _contas)}',
        ),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(context.t('machine.future')),
        value: d.futuro,
        onChanged: (v) => setState(() => d.futuro = v),
      ),
      if (d.futuro)
        OutlinedButton.icon(
          icon: const Icon(Icons.event),
          label: Text(
            '${context.t('machine.expectedDate')}: ${locale.formatDate(d.data)}',
          ),
          onPressed: () async {
            final date = await showModalBottomSheet<DateTime>(
              context: context,
              useSafeArea: true,
              builder:
                  (ctx) => SafeArea(
                    child: SizedBox(
                      height: 440,
                      child: CalendarDatePicker(
                        initialDate: d.data,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        onDateChanged: (v) => Navigator.pop(ctx, v),
                      ),
                    ),
                  ),
            );
            if (date != null && mounted) setState(() => d.data = date);
          },
        ),
      TextFormField(
        initialValue: locale.formatDecimal(d.taxa),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: context.t('machine.fee')),
        onChanged: (v) => setState(() => d.taxa = _numero(v)),
      ),
      Text(
        '${context.t('machine.net')}: ${locale.formatCurrency(d.valor - d.taxa)}',
      ),
    ];
    return Card(
      key: ObjectKey(d),
      color: context.sixMobileColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              d.origem.descricao ?? d.origem.codigo,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: fields,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.call_split),
              label: Text(context.t('machine.split')),
              onPressed:
                  () => setState(() {
                    final metade = (d.valor * 50).round() / 100;
                    d.valor -= metade;
                    _drafts.insert(
                      index + 1,
                      DestinoRecebimentoDraft(
                        RecebimentoFormaInput(
                          codigo: d.origem.codigo,
                          descricao: d.origem.descricao,
                          valor: metade,
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valido = distribuicaoFinanceiraValida(_drafts, widget.formas);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.t('machine.destinations'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(context.t('machine.destinationHint')),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _loading
                      ? SixBackendLoading(
                        title: context.t('space.loading'),
                        subtitle: context.t('machine.destinations'),
                      )
                      : _erro
                      ? Center(
                        child: TextButton(
                          onPressed: _load,
                          child: Text(context.t('space.retry')),
                        ),
                      )
                      : ListView(
                        children: [
                          for (var i = 0; i < _drafts.length; i++)
                            _item(_drafts[i], i),
                        ],
                      ),
            ),
            if (!_loading && !valido) Text(context.t('machine.review')),
            const SizedBox(height: 8),
            FilledButton(
              onPressed:
                  !_loading && !_erro && valido
                      ? () => Navigator.pop(
                        context,
                        _drafts.map((d) => d.toInput()).toList(),
                      )
                      : null,
              child: Text(context.t('space.save')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('space.cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
