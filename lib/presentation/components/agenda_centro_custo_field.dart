import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';

class AgendaCentroCustoField extends StatefulWidget {
  const AgendaCentroCustoField({
    super.key,
    this.initialId,
    this.initialName,
    required this.onChanged,
    this.enabled = true,
  });

  final String? initialId;
  final String? initialName;
  final ValueChanged<CentroCustoModel?> onChanged;
  final bool enabled;

  @override
  State<AgendaCentroCustoField> createState() => _AgendaCentroCustoFieldState();
}

class _AgendaCentroCustoFieldState extends State<AgendaCentroCustoField> {
  final AgendaFinanceiraLancamentoService _service =
      AgendaFinanceiraLancamentoService();
  List<CentroCustoModel> _centros = <CentroCustoModel>[];
  String? _selecionadoId;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _selecionadoId = widget.initialId?.trim().isEmpty == true
        ? null
        : widget.initialId;
    _carregar();
  }

  @override
  void didUpdateWidget(covariant AgendaCentroCustoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialId != oldWidget.initialId) {
      _selecionadoId = widget.initialId?.trim().isEmpty == true
          ? null
          : widget.initialId;
    }
  }

  Future<void> _carregar() async {
    try {
      final centros = await _service.listarCentrosCusto();
      if (!mounted) return;
      setState(() {
        _centros = centros;
        if (_selecionadoId != null &&
            !_centros.any((centro) => centro.id == _selecionadoId)) {
          _selecionadoId = null;
        }
      });
    } catch (_) {
      // O lançamento continua disponível sem centro de custos.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cadastrar() async {
    final nomeController = TextEditingController();
    final codigoController = TextEditingController();
    String tipo = 'AMBOS';
    final CentroCustoModel? criado = await showDialog<CentroCustoModel>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo centro de custos'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nomeController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código (opcional)',
                    hintText: 'Ex.: ADM, LOJA-01',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'AMBOS',
                      child: Text('Custo e resultado'),
                    ),
                    DropdownMenuItem(
                      value: 'CUSTO',
                      child: Text('Somente custo'),
                    ),
                    DropdownMenuItem(
                      value: 'RESULTADO',
                      child: Text('Somente resultado'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => tipo = value ?? 'AMBOS'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final nome = nomeController.text.trim();
                if (nome.isEmpty) return;
                try {
                  final centro = await _service.criarCentroCusto(
                    nome: nome,
                    codigo: codigoController.text,
                    tipo: tipo,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(centro);
                  }
                } catch (_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Não foi possível cadastrar o centro de custos.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
    nomeController.dispose();
    codigoController.dispose();
    if (criado == null || !mounted) return;
    setState(() {
      _centros = <CentroCustoModel>[..._centros, criado]
        ..sort((a, b) => a.nome.compareTo(b.nome));
      _selecionadoId = criado.id;
    });
    widget.onChanged(criado);
  }

  @override
  Widget build(BuildContext context) {
    final String legado = widget.initialName?.trim() ?? '';
    return DropdownButtonFormField<String>(
      key: ValueKey('${widget.initialId}|$legado|${_centros.length}'),
      value: _centros.any((centro) => centro.id == _selecionadoId)
          ? _selecionadoId
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Centro de custos',
        hintText: legado.isEmpty ? 'Sem centro de custos' : legado,
        prefixIcon: const Icon(Icons.account_tree_outlined),
        suffixIcon: _carregando
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: 'Cadastrar centro de custos',
                onPressed: widget.enabled ? _cadastrar : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
      ),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Sem centro de custos'),
        ),
        ..._centros.map(
          (centro) => DropdownMenuItem<String>(
            value: centro.id,
            child: Text(centro.descricao, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: !widget.enabled || _carregando
          ? null
          : (value) {
              final id = value?.trim() ?? '';
              setState(() => _selecionadoId = id.isEmpty ? null : id);
              CentroCustoModel? centro;
              for (final item in _centros) {
                if (item.id == id) {
                  centro = item;
                  break;
                }
              }
              widget.onChanged(centro);
            },
    );
  }
}
