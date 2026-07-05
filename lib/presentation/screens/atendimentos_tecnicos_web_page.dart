import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/dominio_models.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';

class AtendimentosTecnicosWebPage extends StatefulWidget {
  const AtendimentosTecnicosWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<AtendimentosTecnicosWebPage> createState() =>
      _AtendimentosTecnicosWebPageState();
}

class _AtendimentosTecnicosWebPageState
    extends State<AtendimentosTecnicosWebPage> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  late Future<_AtendimentoTecnicoViewState> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<_AtendimentoTecnicoViewState> _carregar() async {
    final dominios = await _service.buscarDominiosBase();
    final atendimentos = await _service.listar();
    return _AtendimentoTecnicoViewState(
      dominios: dominios,
      atendimentos: atendimentos,
    );
  }

  void _recarregar() {
    setState(() {
      _future = _carregar();
    });
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

  Future<void> _abrirNovoAtendimentoDialog(
    AtendimentoTecnicoDominiosBaseModel dominios,
  ) async {
    final criado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _NovoAtendimentoTecnicoDialog(
          service: _service,
          dominios: dominios,
        );
      },
    );

    if (criado == true && mounted) {
      _recarregar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atendimento técnico criado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = FutureBuilder<_AtendimentoTecnicoViewState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AtendimentoTecnicoErrorState(
            mensagem: snapshot.error.toString(),
            onRetry: _recarregar,
          );
        }

        final state = snapshot.data!;
        return Column(
          children: <Widget>[
            _buildHeader(theme, state.dominios),
            const SizedBox(height: 18),
            Expanded(
              child:
                  state.atendimentos.isEmpty
                      ? _buildEmptyState(theme, state.dominios)
                      : ListView.separated(
                        itemCount: state.atendimentos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final atendimento = state.atendimentos[index];
                          return _buildAtendimentoCard(
                            theme,
                            atendimento,
                            state.dominios.statusAtendimentoTecnico,
                          );
                        },
                      ),
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
        title: const Text('Atendimentos técnicos'),
        leading:
            widget.onBack == null
                ? null
                : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
      ),
      body: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AtendimentoTecnicoDominiosBaseModel dominios,
  ) {
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
          final compact = constraints.maxWidth < 760;
          final intro = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Atendimentos técnicos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fluxo único para diagnóstico, orçamento, peças, mão de obra, execução e entrega.',
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
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _recarregar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
              FilledButton.icon(
                onPressed: () => _abrirNovoAtendimentoDialog(dominios),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Novo atendimento'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[intro, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: intro),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    AtendimentoTecnicoDominiosBaseModel dominios,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.assignment_add,
              size: 54,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum atendimento técnico ainda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie o primeiro atendimento para validar o novo modelo com IDs estáveis de status e itens mistos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _abrirNovoAtendimentoDialog(dominios),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar atendimento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtendimentoCard(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final equipamento = atendimento.equipamento;
    final titulo =
        equipamento == null
            ? atendimento.numero
            : '${equipamento.marca ?? ''} ${equipamento.modelo ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final info = Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
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
                      titulo.isEmpty ? atendimento.numero : titulo,
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
                  ],
                ),
              ),
            ],
          );

          final chips = Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: <Widget>[
              _chip(theme, _statusLabel(atendimento, status), Icons.flag_outlined),
              _chip(
                theme,
                atendimento.valorTotalAtendimento.toStringAsFixed(2),
                Icons.payments_outlined,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[info, const SizedBox(height: 12), chips],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: info),
              const SizedBox(width: 12),
              chips,
            ],
          );
        },
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NovoAtendimentoTecnicoDialog extends StatefulWidget {
  const _NovoAtendimentoTecnicoDialog({
    required this.service,
    required this.dominios,
  });

  final AtendimentoTecnicoService service;
  final AtendimentoTecnicoDominiosBaseModel dominios;

  @override
  State<_NovoAtendimentoTecnicoDialog> createState() =>
      _NovoAtendimentoTecnicoDialogState();
}

class _NovoAtendimentoTecnicoDialogState
    extends State<_NovoAtendimentoTecnicoDialog> {
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _equipamentoController = TextEditingController();
  final TextEditingController _defeitoController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _clienteController.dispose();
    _equipamentoController.dispose();
    _defeitoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await widget.service.criar(
        AtendimentoTecnicoCreateInput(
          descricao: 'Atendimento técnico criado pela tela web',
          nomeClienteSnapshot:
              _clienteController.text.trim().isEmpty
                  ? null
                  : _clienteController.text.trim(),
          equipamento: AtendimentoTecnicoEquipamentoModel(
            tipo: 'SMARTPHONE',
            modelo:
                _equipamentoController.text.trim().isEmpty
                    ? null
                    : _equipamentoController.text.trim(),
          ),
          defeitoRelatado:
              _defeitoController.text.trim().isEmpty
                  ? null
                  : _defeitoController.text.trim(),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo atendimento técnico'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(labelText: 'Cliente'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _equipamentoController,
              decoration: const InputDecoration(labelText: 'Equipamento'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _defeitoController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Defeito relatado'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon:
              _salvando
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.check_rounded),
          label: Text(_salvando ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}

class _AtendimentoTecnicoErrorState extends StatelessWidget {
  const _AtendimentoTecnicoErrorState({
    required this.mensagem,
    required this.onRetry,
  });

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 42),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar os atendimentos.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtendimentoTecnicoViewState {
  const _AtendimentoTecnicoViewState({
    required this.dominios,
    required this.atendimentos,
  });

  final AtendimentoTecnicoDominiosBaseModel dominios;
  final List<AtendimentoTecnicoModel> atendimentos;
}
