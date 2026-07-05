import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';

class AtendimentoTecnicoReceberDialog extends StatefulWidget {
  const AtendimentoTecnicoReceberDialog({super.key, required this.atendimento});

  final AtendimentoTecnicoModel atendimento;

  @override
  State<AtendimentoTecnicoReceberDialog> createState() => _AtendimentoTecnicoReceberDialogState();
}

class _AtendimentoTecnicoReceberDialogState extends State<AtendimentoTecnicoReceberDialog> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  String _formaCodigo = 'tipo1';
  String _formaNome = 'Dinheiro';
  bool _salvando = false;

  static const List<_FormaRecebimento> _formas = <_FormaRecebimento>[
    _FormaRecebimento('tipo1', 'Dinheiro'),
    _FormaRecebimento('tipo2', 'Pix'),
    _FormaRecebimento('tipo3', 'Cartão de débito'),
    _FormaRecebimento('tipo4', 'Cartão de crédito'),
    _FormaRecebimento('tipo5', 'Boleto'),
    _FormaRecebimento('tipo6', 'A receber'),
    _FormaRecebimento('tipo7', 'Transferência'),
    _FormaRecebimento('tipo8', 'Voucher'),
    _FormaRecebimento('tipo9', 'Crédito da loja'),
    _FormaRecebimento('tipo10', 'Outro'),
  ];

  @override
  void initState() {
    super.initState();
    _valorController.text = _formatarNumero(widget.atendimento.valorEmAberto > 0 ? widget.atendimento.valorEmAberto : widget.atendimento.valorTotalAtendimento);
  }

  @override
  void dispose() {
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  double _parseValor(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  String _formatarNumero(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

  String _formatarMoeda(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _salvar() async {
    if (_salvando) return;
    final valor = _parseValor(_valorController.text);
    if (valor <= 0) {
      _mostrarMensagem('Informe um valor de recebimento válido.');
      return;
    }
    if (valor > widget.atendimento.valorEmAberto) {
      _mostrarMensagem('O valor não pode ser maior que o saldo em aberto.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await _service.receber(
        id: widget.atendimento.id,
        input: AtendimentoTecnicoRecebimentoInput(
          codigoFormaRecebimento: _formaCodigo,
          nomeFormaRecebimento: _formaNome,
          valor: valor,
          observacao: _observacaoController.text.trim().isEmpty ? null : _observacaoController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível lançar o recebimento: $error');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Receber ${widget.atendimento.numero}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _info(theme, 'Total', _formatarMoeda(widget.atendimento.valorTotalAtendimento)),
                _info(theme, 'Recebido', _formatarMoeda(widget.atendimento.valorRecebido)),
                _info(theme, 'Em aberto', _formatarMoeda(widget.atendimento.valorEmAberto)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _formaCodigo,
              decoration: const InputDecoration(labelText: 'Forma de recebimento'),
              items: _formas.map((forma) => DropdownMenuItem<String>(value: forma.codigo, child: Text(forma.nome))).toList(),
              onChanged: (value) {
                if (value == null) return;
                final forma = _formas.firstWhere((item) => item.codigo == value);
                setState(() {
                  _formaCodigo = forma.codigo;
                  _formaNome = forma.nome;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor recebido'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacaoController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Observação opcional'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _salvando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.payments_outlined),
          label: Text(_salvando ? 'Salvando...' : 'Lançar recebimento'),
        ),
      ],
    );
  }

  Widget _info(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontWeight: FontWeight.w900))]),
    );
  }
}

class _FormaRecebimento {
  const _FormaRecebimento(this.codigo, this.nome);
  final String codigo;
  final String nome;
}
