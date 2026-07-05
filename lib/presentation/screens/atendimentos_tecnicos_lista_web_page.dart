import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/dominio_models.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';

class AtendimentosTecnicosListaWebPage extends StatefulWidget {
  const AtendimentosTecnicosListaWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<AtendimentosTecnicosListaWebPage> createState() =>
      _AtendimentosTecnicosListaWebPageState();
}

class _AtendimentosTecnicosListaWebPageState
    extends State<AtendimentosTecnicosListaWebPage> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final TextEditingController _buscaController = TextEditingController();

  late Future<_AtendimentosListaState> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
    _buscaController.addListener(_onBuscaChanged);
  }

  @override
  void dispose() {
    _buscaController.removeListener(_onBuscaChanged);
    _buscaController.dispose();
    super.dispose();
  }

  Future<_AtendimentosListaState> _carregar() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _service.buscarDominiosBase(),
      _service.listar(),
    ]);

    return _AtendimentosListaState(
      dominios: results[0] as AtendimentoTecnicoDominiosBaseModel,
      atendimentos: results[1] as List<AtendimentoTecnicoModel>,
    );
  }

  void _onBuscaChanged() {
    if (mounted) setState(() {});
  }

  void _recarregar() {
    setState(() {
      _future = _carregar();
    });
  }

  List<AtendimentoTecnicoModel> _filtrar(
    List<AtendimentoTecnicoModel> atendimentos,
  ) {
    final termo = _buscaController.text.trim().toLowerCase();
    if (termo.isEmpty) return atendimentos;

    return atendimentos.where((atendimento) {
      final equipamento = atendimento.equipamento;
      final texto = <String>[
        atendimento.numero,
        atendimento.descricao ?? '',
        atendimento.nomeClienteSnapshot ?? '',
        atendimento.statusCodigo,
        equipamento?.tipo ?? '',
        equipamento?.marca ?? '',
        equipamento?.modelo ?? '',
        equipamento?.imei ?? '',
        atendimento.defeitoRelatado ?? '',
        atendimento.diagnosticoTecnico ?? '',
      ].join(' ').toLowerCase();
      return texto.contains(termo);
    }).toList(growable: false);
  }

  String _statusLabel(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    for (final opcao in status) {
      if (opcao.id == atendimento.statusId &&
          opcao.nomePadraoPtBr.trim().isNotEmpty) {
        return opcao.nomePadraoPtBr;
      }
    }
    return atendimento.statusCodigo;
  }

  String _formatarMoeda(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    final dia = value.day.toString().padLeft(2, '0');
    final mes = value.month.toString().padLeft(2, '0');
    final ano = value.year.toString();
    final hora = value.hour.toString().padLeft(2, '0');
    final minuto = value.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano $hora:$minuto';
  }

  String _equipamentoTitulo(AtendimentoTecnicoModel atendimento) {
    final equipamento = atendimento.equipamento;
    if (equipamento == null) return atendimento.numero;

    final partes = <String>[
      equipamento.tipo ?? '',
      equipamento.marca ?? '',
      equipamento.modelo ?? '',
    ].where((parte) => parte.trim().isNotEmpty).toList(growable: false);

    if (partes.isEmpty) return atendimento.numero;
    return partes.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = FutureBuilder<_AtendimentosListaState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ListaErrorState(
            mensagem: snapshot.error.toString(),
            onRetry: _recarregar,
          );
        }

        final state = snapshot.data!;
        final atendimentos = _filtrar(state.atendimentos);

        return Column(
          children: <Widget>[
            _buildHeader(theme, state.atendimentos.length, atendimentos.length),
            const SizedBox(height: 18),
            Expanded(
              child: state.atendimentos.isEmpty
                  ? _buildEmptyState(theme)
                  : atendimentos.isEmpty
                      ? _buildNoResultsState(theme)
                      : _buildList(theme, state, atendimentos),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return Padding(padding: const EdgeInsets.all(20), child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimentos criados'),
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
      body: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }

  Widget _buildHeader(ThemeData theme, int total, int filtrados) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final title = Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atendimentos criados',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consulte os atendimentos técnicos gravados no backend.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _metricChip(theme, '$total', 'total', Icons.assignment_outlined),
              _metricChip(theme, '$filtrados', 'visíveis', Icons.filter_alt_outlined),
              SizedBox(
                width: compact ? double.infinity : 320,
                child: TextField(
                  controller: _buscaController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Buscar atendimento',
                    hintText: 'Cliente, número, status, equipamento...',
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _recarregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[title, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: title),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    ThemeData theme,
    _AtendimentosListaState state,
    List<AtendimentoTecnicoModel> atendimentos,
  ) {
    return ListView.separated(
      itemCount: atendimentos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildAtendimentoCard(
          theme,
          atendimentos[index],
          state.dominios.statusAtendimentoTecnico,
        );
      },
    );
  }

  Widget _buildAtendimentoCard(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final equipamento = atendimento.equipamento;
    final statusTexto = _statusLabel(atendimento, status);
    final quantidadeItens = atendimento.itens.length;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirDetalhes(atendimento, statusTexto),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final info = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.devices_other_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _equipamentoTitulo(atendimento),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${atendimento.numero} • ${atendimento.nomeClienteSnapshot ?? 'Cliente não informado'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            atendimento.defeitoRelatado!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );

              final chips = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                children: <Widget>[
                  _smallChip(theme, statusTexto, Icons.flag_outlined),
                  _smallChip(
                    theme,
                    '$quantidadeItens item(ns)',
                    Icons.inventory_2_outlined,
                  ),
                  _smallChip(
                    theme,
                    _formatarMoeda(atendimento.valorTotalAtendimento),
                    Icons.payments_outlined,
                  ),
                  _smallChip(
                    theme,
                    _formatarData(atendimento.dataAtualizacao),
                    Icons.schedule_outlined,
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[info, const SizedBox(height: 14), chips],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: info),
                  const SizedBox(width: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: chips,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDetalhes(
    AtendimentoTecnicoModel atendimento,
    String statusTexto,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final equipamento = atendimento.equipamento;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.assignment_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          atendimento.numero,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _smallChip(theme, statusTexto, Icons.flag_outlined),
                          _smallChip(
                            theme,
                            _formatarMoeda(atendimento.valorTotalAtendimento),
                            Icons.payments_outlined,
                          ),
                          _smallChip(
                            theme,
                            _formatarData(atendimento.dataAtualizacao),
                            Icons.schedule_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _detailSection(
                        theme,
                        title: 'Cliente',
                        lines: <String>[
                          atendimento.nomeClienteSnapshot ?? 'Cliente não informado',
                          if ((atendimento.idCliente ?? '').isNotEmpty)
                            'ID: ${atendimento.idCliente}',
                        ],
                      ),
                      _detailSection(
                        theme,
                        title: 'Equipamento',
                        lines: <String>[
                          if ((equipamento?.tipo ?? '').trim().isNotEmpty)
                            'Tipo: ${equipamento!.tipo}',
                          if ((equipamento?.marca ?? '').trim().isNotEmpty)
                            'Marca: ${equipamento!.marca}',
                          if ((equipamento?.modelo ?? '').trim().isNotEmpty)
                            'Modelo: ${equipamento!.modelo}',
                          if ((equipamento?.numeroSerie ?? '').trim().isNotEmpty)
                            'Número de série: ${equipamento!.numeroSerie}',
                          if ((equipamento?.imei ?? '').trim().isNotEmpty)
                            'IMEI: ${equipamento!.imei}',
                          if ((equipamento?.acessorios ?? '').trim().isNotEmpty)
                            'Acessórios: ${equipamento!.acessorios}',
                        ],
                      ),
                      _detailSection(
                        theme,
                        title: 'Defeito e diagnóstico',
                        lines: <String>[
                          atendimento.defeitoRelatado?.trim().isNotEmpty == true
                              ? 'Defeito: ${atendimento.defeitoRelatado}'
                              : 'Defeito não informado',
                          atendimento.diagnosticoTecnico?.trim().isNotEmpty == true
                              ? 'Diagnóstico: ${atendimento.diagnosticoTecnico}'
                              : 'Diagnóstico não informado',
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Itens',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (atendimento.itens.isEmpty)
                        Text(
                          'Nenhum item vinculado.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        ...atendimento.itens.map(
                          (item) => _detailItem(theme, item),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailSection(
    ThemeData theme, {
    required String title,
    required List<String> lines,
  }) {
    final visibleLines = lines
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (visibleLines.isEmpty)
            Text(
              'Não informado',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            ...visibleLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailItem(ThemeData theme, AtendimentoTecnicoItemModel item) {
    final isServico = item.tipoItemCodigo == 'SERVICE';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isServico ? Icons.handyman_outlined : Icons.inventory_2_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.descricaoSnapshot,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${item.quantidade.toStringAsFixed(0)} x ${_formatarMoeda(item.valorUnitario)}',
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              _formatarMoeda(item.valorTotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.assignment_late_outlined,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhum atendimento criado ainda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um atendimento técnico pelo fluxo de abertura para ele aparecer aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Text(
        'Nenhum atendimento encontrado para a busca.',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _metricChip(ThemeData theme, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _smallChip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaErrorState extends StatelessWidget {
  const _ListaErrorState({required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
