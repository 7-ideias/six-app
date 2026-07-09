import 'package:flutter/material.dart';
import 'package:sixpos/core/services/agenda_financeira_acoes_financeiras.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';

class VendasAReceberWebWidget extends StatefulWidget {
  const VendasAReceberWebWidget({super.key});

  @override
  State<VendasAReceberWebWidget> createState() => _VendasAReceberWebWidgetState();
}

class _VendasAReceberWebWidgetState extends State<VendasAReceberWebWidget> {
  final AgendaFinanceiraLancamentoService _lancamentoService = AgendaFinanceiraLancamentoService();
  final AgendaFinanceiraAcoesFinanceiras _acoesService = AgendaFinanceiraAcoesFinanceiras();
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();

  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now().add(const Duration(days: 30));
  bool _carregando = false;
  bool _recebendo = false;
  String _formaSelecionada = 'Pix';

  List<String> _formasRecebimento = <String>[
    'Pix',
    'Boleto',
    'Transferência',
    'Cartão de crédito',
    'Cartão de débito',
    'Débito automático',
    'Dinheiro',
  ];

  final Map<String, String> _backendPorDescricaoFormaPagamento = <String, String>{
    'Pix': 'PIX',
    'Boleto': 'BOLETO',
    'Transferência': 'TRANSFERENCIA',
    'Cartão de crédito': 'CARTAO_CREDITO',
    'Cartão Crédito': 'CARTAO_CREDITO',
    'Cartão de débito': 'CARTAO_DEBITO',
    'Cartão Débito': 'CARTAO_DEBITO',
    'Débito automático': 'DEBITO_AUTOMATICO',
    'Dinheiro': 'DINHEIRO',
  };

  final List<Map<String, dynamic>> _vendas = <Map<String, dynamic>>[];

  double get _totalAberto => _vendas.fold<double>(0, (double soma, Map<String, dynamic> item) => soma + _toDouble(item['valorRestante'] ?? item['valor']));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _carregarFormasRecebimento();
      await _consultar();
    });
  }

  Future<void> _carregarFormasRecebimento() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes = await _caixaApiClient.getInformacoesBasicasDoCaixa();
      final List<String> formas = _montarFormasRecebimento(informacoes.tiposRecebimento);
      if (!mounted || formas.isEmpty) return;
      setState(() {
        _formasRecebimento = formas;
        if (!_formasRecebimento.contains(_formaSelecionada)) {
          _formaSelecionada = _formasRecebimento.first;
        }
      });
    } catch (_) {
      // Mantém fallback local para não bloquear recebimentos se a configuração não carregar.
    }
  }

  List<String> _montarFormasRecebimento(List<TiposRecebimento> tipos) {
    final List<TiposRecebimento> ativos = tipos.where((TiposRecebimento tipo) => tipo.ativo).toList()
      ..sort((TiposRecebimento a, TiposRecebimento b) => a.ordemExibicao.compareTo(b.ordemExibicao));

    final List<String> descricoes = <String>[];
    for (final TiposRecebimento tipo in ativos) {
      final String descricao = tipo.descricaoExibicao.trim();
      if (descricao.isEmpty || descricoes.contains(descricao)) continue;
      descricoes.add(descricao);
      _backendPorDescricaoFormaPagamento[descricao] = _backendPorCodigoTipo(tipo.codigoTipo) ?? _backendPorDescricao(descricao);
    }
    return descricoes;
  }

  String? _backendPorCodigoTipo(String codigoTipo) {
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
      case 'tipo6':
        return 'TRANSFERENCIA';
      case 'tipo7':
        return 'DEBITO_AUTOMATICO';
      default:
        return null;
    }
  }

  String _backendPorDescricao(String descricao) {
    final String normalizado = _normalizar(descricao).toUpperCase();
    if (normalizado.contains('PIX')) return 'PIX';
    if (normalizado.contains('BOLETO')) return 'BOLETO';
    if (normalizado.contains('CREDITO')) return 'CARTAO_CREDITO';
    if (normalizado.contains('DEBITO AUTOMATICO')) return 'DEBITO_AUTOMATICO';
    if (normalizado.contains('DEBITO')) return 'CARTAO_DEBITO';
    if (normalizado.contains('TRANSFER')) return 'TRANSFERENCIA';
    if (normalizado.contains('DINHEIRO')) return 'DINHEIRO';
    return normalizado.replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  }

  Future<void> _consultar() async {
    if (_carregando) return;
    setState(() => _carregando = true);
    try {
      final Map<String, dynamic> payload = await _lancamentoService.consultarLancamentos(
        AgendaFinanceiraConsultaRequest(
          periodo: AgendaFinanceiraPeriodoRequest(
            modo: 'PERSONALIZADO',
            dataInicio: _normalizarData(_dataInicio),
            dataFim: _normalizarData(_dataFim),
          ),
          filtros: AgendaFinanceiraFiltrosRequest(
            tipo: 'RECEBER',
            status: const <String>['PREVISTO', 'PENDENTE', 'VENCE_HOJE', 'VENCIDO', 'PARCIAL'],
            origens: const <String>['VENDA'],
            categorias: const <String>[],
            formasPagamento: const <String>[],
            somenteCriticos: false,
          ),
          visaoSelecionada: 'AGENDA',
        ),
      );
      if (!mounted) return;
      setState(() {
        _vendas
          ..clear()
          ..addAll(_mapearVendas(payload));
      });
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao consultar vendas a receber (${e.statusCode}).')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível consultar vendas a receber.')));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> _mapearVendas(Map<String, dynamic> payload) {
    final List<Map<String, dynamic>> itens = <Map<String, dynamic>>[];
    final dynamic gruposRaw = payload['gruposAgenda'];
    if (gruposRaw is! List) return itens;

    for (final dynamic grupoRaw in gruposRaw) {
      if (grupoRaw is! Map<String, dynamic>) continue;
      final dynamic itensRaw = grupoRaw['itens'];
      if (itensRaw is! List) continue;
      for (final dynamic itemRaw in itensRaw) {
        if (itemRaw is! Map<String, dynamic>) continue;
        final String status = (itemRaw['status'] ?? '').toString().toUpperCase();
        final String origem = (itemRaw['origem'] ?? '').toString().toUpperCase();
        if (status == 'RECEBIDO' || status == 'PAGO' || status == 'CANCELADO') continue;
        if (origem.isNotEmpty && origem != 'VENDA') continue;
        itens.add(<String, dynamic>{
          'id': itemRaw['idLancamento']?.toString() ?? itemRaw['id']?.toString() ?? '',
          'descricao': itemRaw['descricao']?.toString() ?? 'Venda sem descrição',
          'cliente': itemRaw['nomeContato']?.toString() ?? itemRaw['contato']?.toString() ?? 'Cliente não informado',
          'valorOriginal': _toDouble(itemRaw['valorOriginal'] ?? itemRaw['valor']),
          'valorConfirmado': _toDouble(itemRaw['valorConfirmado']),
          'valorRestante': _toDouble(itemRaw['valorRestante'] ?? itemRaw['valor']),
          'vencimento': _formatarData(itemRaw['dataVencimento']?.toString()),
          'status': _statusLabel(status),
          'formaPagamento': _formaLabel(itemRaw['formaPagamento']?.toString()),
        });
      }
    }
    return itens;
  }

  Future<void> _selecionarData({required bool inicio}) async {
    final DateTime dataAtual = inicio ? _dataInicio : _dataFim;
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: dataAtual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selecionada == null) return;
    setState(() {
      if (inicio) {
        _dataInicio = _normalizarData(selecionada);
        if (_dataFim.isBefore(_dataInicio)) _dataFim = _dataInicio;
      } else {
        _dataFim = _normalizarData(selecionada);
        if (_dataInicio.isAfter(_dataFim)) _dataInicio = _dataFim;
      }
    });
  }

  Future<void> _receberVenda(Map<String, dynamic> venda) async {
    final double valor = _toDouble(venda['valorRestante'] ?? venda['valorOriginal']);
    final String idLancamento = venda['id']?.toString() ?? '';
    if (idLancamento.trim().isEmpty || valor <= 0) return;

    String formaSelecionada = _formasRecebimento.contains(_formaSelecionada) ? _formaSelecionada : _formasRecebimento.first;
    final bool confirmou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Receber venda'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(venda['descricao']?.toString() ?? 'Venda'),
                    const SizedBox(height: 8),
                    Text('Valor em aberto: ${_formatCurrency(valor)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: formaSelecionada,
                      decoration: const InputDecoration(labelText: 'Forma de recebimento'),
                      items: _formasRecebimento.map((String forma) => DropdownMenuItem<String>(value: forma, child: Text(forma))).toList(),
                      onChanged: (String? value) {
                        if (value == null) return;
                        setDialogState(() => formaSelecionada = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Confirmar recebimento'),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;

    if (!confirmou) return;
    setState(() {
      _recebendo = true;
      _formaSelecionada = formaSelecionada;
    });
    try {
      await _acoesService.executarTotal(
        idLancamento: idLancamento,
        request: AgendaFinanceiraLiquidacaoRequest(
          tipoLiquidacao: 'TOTAL',
          dataLiquidacao: DateTime.now(),
          valorLiquidado: valor,
          formaPagamentoRealizada: _backendPorDescricaoFormaPagamento[formaSelecionada] ?? _backendPorDescricao(formaSelecionada),
          observacoes: 'Recebimento de venda realizado pelo frente de caixa web.',
          referenciaExterna: idLancamento,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venda recebida com sucesso.')));
      await _consultar();
    } on AgendaFinanceiraLancamentoApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao receber venda (${e.statusCode}).')));
    } finally {
      if (mounted) setState(() => _recebendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(theme),
              const SizedBox(height: 14),
              _buildFiltros(theme),
              if (_carregando || _recebendo) ...const <Widget>[
                SizedBox(height: 10),
                LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 14),
              _buildResumo(theme),
              const SizedBox(height: 14),
              Expanded(child: _buildLista(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Vendas a receber', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              Text('Vendas não liquidadas, com filtro por vencimento e recebimento direto no caixa.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded), tooltip: 'Fechar'),
      ],
    );
  }

  Widget _buildFiltros(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _dateButton(theme, 'Data inicial', _dataInicio, () => _selecionarData(inicio: true)),
          _dateButton(theme, 'Data final', _dataFim, () => _selecionarData(inicio: false)),
          FilledButton.icon(
            onPressed: _carregando ? null : _consultar,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Filtrar'),
          ),
          OutlinedButton.icon(
            onPressed: _carregando
                ? null
                : () {
                    setState(() {
                      _dataInicio = DateTime.now();
                      _dataFim = DateTime.now();
                    });
                    _consultar();
                  },
            icon: const Icon(Icons.today_outlined),
            label: const Text('Hoje'),
          ),
        ],
      ),
    );
  }

  Widget _dateButton(ThemeData theme, String label, DateTime data, VoidCallback onTap) {
    return SizedBox(
      width: 190,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text(_formatarDataBr(data), style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildResumo(ThemeData theme) {
    return Row(
      children: <Widget>[
        Expanded(child: _summaryCard(theme, 'Vendas abertas', _vendas.length.toString(), Icons.shopping_bag_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(theme, 'Total a receber', _formatCurrency(_totalAberto), Icons.payments_outlined)),
      ],
    );
  }

  Widget _summaryCard(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(ThemeData theme) {
    if (_vendas.isEmpty && !_carregando) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Text('Nenhuma venda a receber no período.'),
        ),
      );
    }

    return ListView.separated(
      itemCount: _vendas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> venda = _vendas[index];
        return _vendaCard(theme, venda);
      },
    );
  }

  Widget _vendaCard(ThemeData theme, Map<String, dynamic> venda) {
    final double valorAberto = _toDouble(venda['valorRestante'] ?? venda['valorOriginal']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(venda['status']?.toString() ?? 'Pendente')),
                    Chip(label: Text('Vence em ${venda['vencimento']}')),
                    Chip(label: Text(venda['formaPagamento']?.toString() ?? 'Forma não informada')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(venda['descricao']?.toString() ?? 'Venda', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(venda['cliente']?.toString() ?? 'Cliente não informado', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(_formatCurrency(valorAberto), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _recebendo ? null : () => _receberVenda(venda),
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Receber'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _normalizarData(DateTime data) => DateTime(data.year, data.month, data.day);

  String _normalizar(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PREVISTO':
        return 'Previsto';
      case 'VENCE_HOJE':
        return 'Vence hoje';
      case 'VENCIDO':
        return 'Vencido';
      case 'PARCIAL':
        return 'Parcial';
      default:
        return 'Pendente';
    }
  }

  String _formaLabel(String? forma) {
    switch ((forma ?? '').toUpperCase()) {
      case 'PIX':
        return 'Pix';
      case 'BOLETO':
        return 'Boleto';
      case 'TRANSFERENCIA':
        return 'Transferência';
      case 'CARTAO_CREDITO':
        return 'Cartão de crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de débito';
      case 'DEBITO_AUTOMATICO':
        return 'Débito automático';
      case 'DINHEIRO':
        return 'Dinheiro';
      default:
        return forma?.trim().isNotEmpty == true ? forma! : 'Forma não informada';
    }
  }

  String _formatarData(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    try {
      return _formatarDataBr(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String _formatarDataBr(DateTime data) => '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  String _formatCurrency(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final String texto = value.trim();
      final String normalizado = texto.contains(',') && texto.contains('.') ? texto.replaceAll('.', '').replaceAll(',', '.') : texto.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }
    return 0;
  }
}
