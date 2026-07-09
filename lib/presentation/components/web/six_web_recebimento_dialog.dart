import 'package:flutter/material.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';

enum SixWebRecebimentoTipo { total, parcial }

class SixWebRecebimentoResultado {
  const SixWebRecebimentoResultado({
    required this.tipo,
    required this.valor,
    required this.codigoTipoRecebimento,
    required this.descricaoTipoRecebimento,
    required this.formaPagamentoBackend,
    this.observacao,
  });

  final SixWebRecebimentoTipo tipo;
  final double valor;
  final String codigoTipoRecebimento;
  final String descricaoTipoRecebimento;
  final String formaPagamentoBackend;
  final String? observacao;

  bool get total => tipo == SixWebRecebimentoTipo.total;
  bool get parcial => tipo == SixWebRecebimentoTipo.parcial;
}

class SixWebTipoRecebimentoOpcao {
  const SixWebTipoRecebimentoOpcao({
    required this.codigoTipo,
    required this.descricao,
    required this.formaPagamentoBackend,
  });

  final String codigoTipo;
  final String descricao;
  final String formaPagamentoBackend;
}

class SixWebRecebimentoDialog extends StatefulWidget {
  const SixWebRecebimentoDialog({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.valorAberto,
    this.contato,
    this.permitirParcial = true,
    this.observacaoInicial,
    this.codigoTipoInicial,
  });

  final String titulo;
  final String descricao;
  final double valorAberto;
  final String? contato;
  final bool permitirParcial;
  final String? observacaoInicial;
  final String? codigoTipoInicial;

  static Future<SixWebRecebimentoResultado?> show(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required double valorAberto,
    String? contato,
    bool permitirParcial = true,
    String? observacaoInicial,
    String? codigoTipoInicial,
  }) {
    return showDialog<SixWebRecebimentoResultado>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SixWebRecebimentoDialog(
        titulo: titulo,
        descricao: descricao,
        valorAberto: valorAberto,
        contato: contato,
        permitirParcial: permitirParcial,
        observacaoInicial: observacaoInicial,
        codigoTipoInicial: codigoTipoInicial,
      ),
    );
  }

  @override
  State<SixWebRecebimentoDialog> createState() => _SixWebRecebimentoDialogState();
}

class _SixWebRecebimentoDialogState extends State<SixWebRecebimentoDialog> {
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  bool _carregandoTipos = true;
  String? _erroValor;
  SixWebRecebimentoTipo _tipo = SixWebRecebimentoTipo.total;
  List<SixWebTipoRecebimentoOpcao> _opcoes = _opcoesFallback;
  SixWebTipoRecebimentoOpcao _opcaoSelecionada = _opcoesFallback.first;

  static const List<SixWebTipoRecebimentoOpcao> _opcoesFallback = <SixWebTipoRecebimentoOpcao>[
    SixWebTipoRecebimentoOpcao(codigoTipo: 'tipo1', descricao: 'Dinheiro', formaPagamentoBackend: 'DINHEIRO'),
    SixWebTipoRecebimentoOpcao(codigoTipo: 'tipo2', descricao: 'Pix', formaPagamentoBackend: 'PIX'),
    SixWebTipoRecebimentoOpcao(codigoTipo: 'tipo3', descricao: 'Cartão de crédito', formaPagamentoBackend: 'CARTAO_CREDITO'),
    SixWebTipoRecebimentoOpcao(codigoTipo: 'tipo4', descricao: 'Cartão de débito', formaPagamentoBackend: 'CARTAO_DEBITO'),
    SixWebTipoRecebimentoOpcao(codigoTipo: 'tipo5', descricao: 'Boleto', formaPagamentoBackend: 'BOLETO'),
    SixWebTipoRecebimentoOpcao(codigoTipo: 'tipo7', descricao: 'Débito automático', formaPagamentoBackend: 'DEBITO_AUTOMATICO'),
  ];

  @override
  void initState() {
    super.initState();
    _valorController.text = _formatarValorDigitavel(widget.valorAberto);
    _observacaoController.text = widget.observacaoInicial ?? '';
    _carregarTipos();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarTipos() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes = await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<SixWebTipoRecebimentoOpcao> opcoes = _montarOpcoes(informacoes.tiposRecebimento);
      if (!mounted) return;
      setState(() {
        if (opcoes.isNotEmpty) _opcoes = opcoes;
        _opcaoSelecionada = _resolverInicial(_opcoes);
        _carregandoTipos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _opcaoSelecionada = _resolverInicial(_opcoes);
        _carregandoTipos = false;
      });
    }
  }

  List<SixWebTipoRecebimentoOpcao> _montarOpcoes(List<TiposRecebimento> tipos) {
    final List<TiposRecebimento> ativos = tipos
        .where((TiposRecebimento tipo) => tipo.ativo)
        .where((TiposRecebimento tipo) => tipo.naturezaRecebimento.trim().toUpperCase() != 'FUTURO')
        .toList()
      ..sort((TiposRecebimento a, TiposRecebimento b) => a.ordemExibicao.compareTo(b.ordemExibicao));

    final List<SixWebTipoRecebimentoOpcao> opcoes = <SixWebTipoRecebimentoOpcao>[];
    for (final TiposRecebimento tipo in ativos) {
      final String codigo = tipo.codigoTipo.trim().toLowerCase();
      final String? backend = _formaPagamentoBackendPorCodigo(codigo);
      if (backend == null) continue;
      final String descricao = tipo.descricaoExibicao.trim().isNotEmpty
          ? tipo.descricaoExibicao.trim()
          : _descricaoPadraoPorBackend(backend);
      if (descricao.isEmpty) continue;
      if (opcoes.any((SixWebTipoRecebimentoOpcao opcao) => opcao.codigoTipo == codigo)) continue;
      opcoes.add(SixWebTipoRecebimentoOpcao(codigoTipo: codigo, descricao: descricao, formaPagamentoBackend: backend));
    }
    return opcoes;
  }

  SixWebTipoRecebimentoOpcao _resolverInicial(List<SixWebTipoRecebimentoOpcao> opcoes) {
    final String inicial = widget.codigoTipoInicial?.trim().toLowerCase() ?? '';
    if (inicial.isNotEmpty) {
      for (final SixWebTipoRecebimentoOpcao opcao in opcoes) {
        if (opcao.codigoTipo == inicial) return opcao;
      }
    }
    return opcoes.isEmpty ? _opcoesFallback.first : opcoes.first;
  }

  void _alterarTipo(SixWebRecebimentoTipo tipo) {
    setState(() {
      _tipo = tipo;
      _erroValor = null;
      if (tipo == SixWebRecebimentoTipo.total) {
        _valorController.text = _formatarValorDigitavel(widget.valorAberto);
      }
    });
  }

  void _confirmar() {
    final double valor = _parseValor(_valorController.text);
    if (valor <= 0) {
      setState(() => _erroValor = 'Informe um valor maior que zero.');
      return;
    }
    if (_tipo == SixWebRecebimentoTipo.parcial && valor >= widget.valorAberto) {
      setState(() => _erroValor = 'Para parcial, informe um valor menor que o aberto.');
      return;
    }
    if (_tipo == SixWebRecebimentoTipo.total && (valor - widget.valorAberto).abs() > 0.009) {
      setState(() => _erroValor = 'Para total, o valor precisa quitar o saldo em aberto.');
      return;
    }

    Navigator.of(context).pop(
      SixWebRecebimentoResultado(
        tipo: _tipo,
        valor: valor,
        codigoTipoRecebimento: _opcaoSelecionada.codigoTipo,
        descricaoTipoRecebimento: _opcaoSelecionada.descricao,
        formaPagamentoBackend: _opcaoSelecionada.formaPagamentoBackend,
        observacao: _observacaoController.text.trim().isEmpty ? null : _observacaoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.titulo, style: const TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (widget.contato != null && widget.contato!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(widget.contato!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text('Valor em aberto', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
                  Text(_formatarMoeda(widget.valorAberto), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (widget.permitirParcial)
              SegmentedButton<SixWebRecebimentoTipo>(
                selected: <SixWebRecebimentoTipo>{_tipo},
                onSelectionChanged: (Set<SixWebRecebimentoTipo> value) => _alterarTipo(value.first),
                segments: const <ButtonSegment<SixWebRecebimentoTipo>>[
                  ButtonSegment<SixWebRecebimentoTipo>(value: SixWebRecebimentoTipo.total, label: Text('Total'), icon: Icon(Icons.done_all_rounded)),
                  ButtonSegment<SixWebRecebimentoTipo>(value: SixWebRecebimentoTipo.parcial, label: Text('Parcial'), icon: Icon(Icons.call_split_rounded)),
                ],
              ),
            if (widget.permitirParcial) const SizedBox(height: 14),
            TextField(
              controller: _valorController,
              enabled: _tipo == SixWebRecebimentoTipo.parcial,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _tipo == SixWebRecebimentoTipo.total ? 'Valor total' : 'Valor parcial',
                errorText: _erroValor,
                prefixText: 'R\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SixWebTipoRecebimentoOpcao>(
              value: _opcaoSelecionada,
              decoration: InputDecoration(
                labelText: 'Tipo de recebimento',
                helperText: _carregandoTipos ? 'Carregando tipos ativos...' : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: _opcoes
                  .map((SixWebTipoRecebimentoOpcao opcao) => DropdownMenuItem<SixWebTipoRecebimentoOpcao>(value: opcao, child: Text(opcao.descricao)))
                  .toList(growable: false),
              onChanged: _carregandoTipos ? null : (SixWebTipoRecebimentoOpcao? value) {
                if (value == null) return;
                setState(() => _opcaoSelecionada = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacaoController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Observação',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _carregandoTipos ? null : _confirmar,
          icon: const Icon(Icons.payments_rounded),
          label: Text(_tipo == SixWebRecebimentoTipo.total ? 'Receber total' : 'Receber parcial'),
        ),
      ],
    );
  }

  String _formatarMoeda(double valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  String _formatarValorDigitavel(double valor) => valor.toStringAsFixed(2).replaceAll('.', ',');

  double _parseValor(String value) {
    final String texto = value.trim().replaceAll('R\$', '').trim();
    final String normalizado = texto.contains(',') && texto.contains('.')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto.replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
  }

  String? _formaPagamentoBackendPorCodigo(String codigoTipo) {
    switch (codigoTipo.trim().toLowerCase()) {
      case 'tipo1':
        return 'DINHEIRO';
      case 'tipo2':
        return 'PIX';
      case 'tipo3':
        return 'CARTAO_CREDITO';
      case 'tipo4':
        return 'CARTAO_DEBITO';
      case 'tipo5':
        return 'BOLETO';
      case 'tipo7':
        return 'DEBITO_AUTOMATICO';
      default:
        return null;
    }
  }

  String _descricaoPadraoPorBackend(String backend) {
    switch (backend) {
      case 'DINHEIRO':
        return 'Dinheiro';
      case 'PIX':
        return 'Pix';
      case 'CARTAO_CREDITO':
        return 'Cartão de crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de débito';
      case 'BOLETO':
        return 'Boleto';
      case 'DEBITO_AUTOMATICO':
        return 'Débito automático';
      default:
        return backend;
    }
  }
}
