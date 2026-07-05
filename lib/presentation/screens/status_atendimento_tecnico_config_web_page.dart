import 'package:flutter/material.dart';

import '../../data/models/dominio_models.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';

class StatusAtendimentoTecnicoConfigWebPage extends StatefulWidget {
  const StatusAtendimentoTecnicoConfigWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<StatusAtendimentoTecnicoConfigWebPage> createState() =>
      _StatusAtendimentoTecnicoConfigWebPageState();
}

class _StatusAtendimentoTecnicoConfigWebPageState
    extends State<StatusAtendimentoTecnicoConfigWebPage> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final Map<String, TextEditingController> _ptControllers = <String, TextEditingController>{};
  final Map<String, TextEditingController> _enControllers = <String, TextEditingController>{};
  final Map<String, TextEditingController> _esControllers = <String, TextEditingController>{};

  late Future<List<DominioStatusAtendimentoCustomizacaoModel>> _future;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      ..._ptControllers.values,
      ..._enControllers.values,
      ..._esControllers.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<List<DominioStatusAtendimentoCustomizacaoModel>> _carregar() async {
    final status = await _service.listarCustomizacoesStatusAtendimento();
    _sincronizarControllers(status);
    return status;
  }

  void _sincronizarControllers(
    List<DominioStatusAtendimentoCustomizacaoModel> status,
  ) {
    for (final item in status) {
      _ptControllers.putIfAbsent(
        item.statusCodigo,
        () => TextEditingController(),
      ).text = item.nomeAtualPtBr;
      _enControllers.putIfAbsent(
        item.statusCodigo,
        () => TextEditingController(),
      ).text = item.nomeAtualEnUs;
      _esControllers.putIfAbsent(
        item.statusCodigo,
        () => TextEditingController(),
      ).text = item.nomeAtualEsEs;
    }
  }

  void _recarregar() {
    setState(() => _future = _carregar());
  }

  Future<void> _salvar(
    List<DominioStatusAtendimentoCustomizacaoModel> status,
  ) async {
    if (_salvando) return;
    setState(() => _salvando = true);

    try {
      final payload = status.map((item) {
        return item.toCustomizacaoJson(
          nomePtBr: _ptControllers[item.statusCodigo]?.text ?? item.nomeAtualPtBr,
          nomeEnUs: _enControllers[item.statusCodigo]?.text ?? item.nomeAtualEnUs,
          nomeEsEs: _esControllers[item.statusCodigo]?.text ?? item.nomeAtualEsEs,
        );
      }).toList(growable: false);

      await _service.salvarCustomizacoesStatusAtendimento(payload);
      if (!mounted) return;
      _recarregar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomes dos status salvos com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar os status: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _restaurarPadrao(DominioStatusAtendimentoCustomizacaoModel item) {
    setState(() {
      _ptControllers[item.statusCodigo]?.text = item.nomePadraoPtBr;
      _enControllers[item.statusCodigo]?.text = item.nomePadraoEnUs;
      _esControllers[item.statusCodigo]?.text = item.nomePadraoEsEs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = FutureBuilder<List<DominioStatusAtendimentoCustomizacaoModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _StatusConfigErrorState(
            mensagem: snapshot.error.toString(),
            onRetry: _recarregar,
          );
        }

        final status = snapshot.data ?? <DominioStatusAtendimentoCustomizacaoModel>[];
        return Column(
          children: <Widget>[
            _buildHeader(theme, status),
            const SizedBox(height: 18),
            Expanded(
              child: status.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.separated(
                      itemCount: status.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildStatusCard(
                        theme,
                        status[index],
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            _buildFooter(theme, status),
          ],
        );
      },
    );

    if (widget.embedded) {
      return Padding(padding: const EdgeInsets.all(20), child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status do atendimento técnico'),
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

  Widget _buildHeader(
    ThemeData theme,
    List<DominioStatusAtendimentoCustomizacaoModel> status,
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
          final compact = constraints.maxWidth < 840;
          final title = Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Nomes dos status',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalize como os status aparecem no atendimento técnico. O código interno continua estável para regras e integrações.',
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
            children: <Widget>[
              _metricChip(theme, '${status.length}', 'status', Icons.flag_outlined),
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
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    DominioStatusAtendimentoCustomizacaoModel item,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.nomeAtualPtBr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _smallChip(theme, item.statusCodigo, Icons.code_rounded),
                        if (item.finalizador)
                          _smallChip(theme, 'finalizador', Icons.check_circle_outline),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final fields = _buildFields(theme, item, compact);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                title,
                const SizedBox(height: 14),
                fields,
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _restaurarPadrao(item),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Restaurar padrão'),
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 280, child: title),
              const SizedBox(width: 16),
              Expanded(child: fields),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _restaurarPadrao(item),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Padrão'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFields(
    ThemeData theme,
    DominioStatusAtendimentoCustomizacaoModel item,
    bool compact,
  ) {
    final fields = <Widget>[
      TextField(
        controller: _ptControllers[item.statusCodigo],
        decoration: InputDecoration(
          labelText: 'Nome em português',
          helperText: 'Padrão: ${item.nomePadraoPtBr}',
        ),
      ),
      TextField(
        controller: _enControllers[item.statusCodigo],
        decoration: InputDecoration(
          labelText: 'Nome em inglês',
          helperText: 'Padrão: ${item.nomePadraoEnUs}',
        ),
      ),
      TextField(
        controller: _esControllers[item.statusCodigo],
        decoration: InputDecoration(
          labelText: 'Nome em espanhol',
          helperText: 'Padrão: ${item.nomePadraoEsEs}',
        ),
      ),
    ];

    if (compact) {
      return Column(
        children: fields
            .map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: field,
              ),
            )
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .map(
            (field) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: field,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFooter(
    ThemeData theme,
    List<DominioStatusAtendimentoCustomizacaoModel> status,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Após salvar, os novos nomes passam a aparecer na lista e no modal de mudança de status.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _salvando || status.isEmpty ? null : () => _salvar(status),
            icon: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_salvando ? 'Salvando...' : 'Salvar nomes'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Text(
        'Nenhum status encontrado para configuração.',
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
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

class _StatusConfigErrorState extends StatelessWidget {
  const _StatusConfigErrorState({required this.mensagem, required this.onRetry});

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
          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 42),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar os status.',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
