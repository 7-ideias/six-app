import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sixpos/data/services/compras/compra_api_client.dart';

/// Recebimento independente da confirmacao financeira da compra.
/// O backend limita quantidades e garante idempotencia em cada item de estoque.
class ComprasRecebimentoPage extends StatefulWidget {
  const ComprasRecebimentoPage({
    super.key, required this.api, required this.compra,
  });
  final CompraApiClient api;
  final Map<String, dynamic> compra;

  @override
  State<ComprasRecebimentoPage> createState() => _ComprasRecebimentoPageState();
}

class _ComprasRecebimentoPageState extends State<ComprasRecebimentoPage> {
  final Map<String, TextEditingController> _quantidades = {};
  final _observacoes = TextEditingController();
  late final String _idempotencia;
  bool _salvando = false;

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

  List<Map<String,dynamic>> get _itens {
    final itens = widget.compra['itens'] as List? ?? [];
    return itens.whereType<Map<String,dynamic>>()
        .where((item) => item['movimentaEstoque'] == true)
        .toList(growable: false);
  }

  double _recebido(String id) {
    double total = 0;
    final entregas = widget.compra['recebimentos'] as List? ?? [];
    for (final entrega in entregas.whereType<Map<String,dynamic>>()) {
      final itens = entrega['itens'] as List? ?? [];
      for (final item in itens.whereType<Map<String,dynamic>>()) {
        if (item['itemId']?.toString() == id) total += _number(item['quantidade']);
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _idempotencia = 'entrega-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}';
    for (final item in _itens) {
      _quantidades[item['id'].toString()] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _quantidades.values) controller.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_salvando) return;
    final List<Map<String,dynamic>> itens = [];
    for (final item in _itens) {
      final id = item['id'].toString();
      final informado = _quantidades[id]!.text.trim().replaceAll(',', '.');
      if (informado.isEmpty) continue;
      final quantidade = double.tryParse(informado) ?? 0;
      final disponivel = _number(item['quantidade']) - _recebido(id);
      if (!quantidade.isFinite || quantidade <= 0 || quantidade > disponivel + 0.000001) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantidade inválida para ${item['descricao']} (restante: $disponivel).')));
        return;
      }
      itens.add({'itemId': id, 'quantidade': quantidade});
    }
    if (itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a quantidade efetivamente recebida.')));
      return;
    }
    setState(() => _salvando = true);
    try {
      final resultado = await widget.api.receber(
        widget.compra['id'].toString(), _idempotencia, itens,
        observacoes: _observacoes.text.trim());
      if (!mounted) return;
      final entregas = resultado['recebimentos'] as List? ?? [];
      final pendentes = entregas.whereType<Map<String,dynamic>>().any(
        (r) => r['status'] == 'PENDENTE' || r['status'] == 'ERRO');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pendentes
          ? 'Recebimento registrado. A entrada no estoque está pendente de sincronização.'
          : 'Mercadoria recebida e estoque atualizado.'),
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao registrar recebimento: $e')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itens = _itens;
    final possuiSaldo = itens.any((item) =>
        _number(item['quantidade']) - _recebido(item['id'].toString()) > 0);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Receber mercadorias', style: theme.textTheme.titleLarge)),
          IconButton(onPressed: _salvando ? null : () => Navigator.pop(context),
              tooltip: 'Fechar', icon: const Icon(Icons.close_rounded)),
        ]),
        Text(
          'Compra ${widget.compra['numero'] ?? ''} · Apenas o recebido entra no estoque.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Expanded(child: ListView(children: [
          if (itens.isEmpty)
            const Padding(padding: EdgeInsets.all(20),
              child: Text('Esta compra não possui produtos estocáveis.')),
          for (final item in itens)
            Builder(builder: (_) {
              final id = item['id'].toString();
              final total = _number(item['quantidade']);
              final ja = _recebido(id);
              final pendente = max(0.0, total - ja);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['descricao']?.toString() ?? 'Produto',
                      style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('Pedido: $total · Já registrado: $ja · Disponível: $pendente',
                      style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextField(
                      key: Key('recebimento-quantidade-$id'),
                      controller: _quantidades[id],
                      enabled: !_salvando && pendente > 0,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true, border: const OutlineInputBorder(),
                        labelText: 'Quantidade recebida agora',
                        helperText: pendente == 0 ? 'Item totalmente recebido' : null,
                      ),
                    ),
                  ]),
                ),
              );
            }),
          TextField(
            controller: _observacoes,
            enabled: !_salvando,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observações desta entrega',
              border: OutlineInputBorder()),
          ),
        ])),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _salvando || !possuiSaldo ? null : _registrar,
          icon: _salvando ? const SizedBox(width: 18,height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.inventory_2_outlined),
          label: Text(_salvando ? 'Registrando...' : 'Confirmar recebimento'),
        ),
      ]),
    );
  }
}
