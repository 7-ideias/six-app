import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  late Future<_ListaAtendimentosState> _future;
  bool _alterandoStatus = false;
  bool _gerandoLink = false;

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

  Future<_ListaAtendimentosState> _carregar() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _service.buscarDominiosBase(),
      _service.listar(),
    ]);

    return _ListaAtendimentosState(
      dominios: results[0] as AtendimentoTecnicoDominiosBaseModel,
      atendimentos: results[1] as List<AtendimentoTecnicoModel>,
    );
  }

  void _onBuscaChanged() {
    if (mounted) setState(() {});
  }

  void _recarregar() {
    setState(() => _future = _carregar());
  }

  List<AtendimentoTecnicoModel> _filtrar(List<AtendimentoTecnicoModel> itens) {
    final termo = _buscaController.text.trim().toLowerCase();
    if (termo.isEmpty) return itens;
    return itens.where((atendimento) {
      final equipamento = atendimento.equipamento;
      final texto = <String>[
        atendimento.numero,
        atendimento.nomeClienteSnapshot ?? '',
        atendimento.statusCodigo,
        atendimento.statusNomePtBr ?? '',
        atendimento.assinaturaAprovada ? 'assinado assinatura aprovado' : '',
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

  DominioOpcaoModel? _statusAtual(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    for (final opcao in status) {
      if (opcao.id == atendimento.statusId) return opcao;
    }
    return status.isEmpty ? null : status.first;
  }

  String _statusLabel(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final nomeBackend = atendimento.statusNomePtBr?.trim() ?? '';
    if (nomeBackend.isNotEmpty) return nomeBackend;
    return _statusLabelPorCodigo(atendimento.statusCodigo, status);
  }

  String _statusLabelPorCodigo(String? codigo, List<DominioOpcaoModel> status) {
    final normalizado = codigo?.trim().toUpperCase() ?? '';
    if (normalizado.isEmpty) return 'Sem status anterior';
    for (final opcao in status) {
      if (opcao.codigo.trim().toUpperCase() == normalizado) {
        return opcao.nomePadraoPtBr.trim().isEmpty ? opcao.codigo : opcao.nomePadraoPtBr;
      }
    }
    return normalizado;
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

  String _assinaturaResumo(AtendimentoTecnicoModel atendimento) {
    final nome = atendimento.assinaturaNomeAssinante?.trim() ?? '';
    final data = _formatarData(atendimento.assinaturaDataHora);
    if (nome.isEmpty && data == '-') return 'Assinado';
    if (nome.isEmpty) return 'Assinado em $data';
    if (data == '-') return 'Assinado por $nome';
    return 'Assinado por $nome em $data';
  }

  String _equipamentoTitulo(AtendimentoTecnicoModel atendimento) {
    final equipamento = atendimento.equipamento;
    final partes = <String>[
      equipamento?.tipo ?? '',
      equipamento?.marca ?? '',
      equipamento?.modelo ?? '',
    ].where((parte) => parte.trim().isNotEmpty).toList(growable: false);
    return partes.isEmpty ? atendimento.numero : partes.join(' ');
  }

  Future<void> _gerarLinkAssinatura(AtendimentoTecnicoModel atendimento) async {
    if (_gerandoLink) return;
    setState(() => _gerandoLink = true);
    try {
      final baseUrl = '${Uri.base.origin}/atendimento/assinatura';
      final response = await _service.gerarLinkAssinatura(
        id: atendimento.id,
        baseUrl: baseUrl,
      );
      final link = response['link']?.toString() ?? '';
      if (link.isEmpty) {
        throw Exception('Link não retornado pelo backend.');
      }
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Link de assinatura'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Link copiado para a área de transferência.'),
                const SizedBox(height: 12),
                SelectableText(link),
                const SizedBox(height: 12),
                const Text(
                  'Envie este link ao cliente por WhatsApp ou e-mail para aprovação e assinatura do serviço.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível gerar o link: $error');
    } finally {
      if (mounted) setState(() => _gerandoLink = false);
    }
  }

  Future<void> _abrirAlterarStatusDialog(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) async {
    if (status.isEmpty || _alterandoStatus) return;
    final observacaoController = TextEditingController();
    DominioOpcaoModel? statusSelecionado = _statusAtual(atendimento, status);

    final alterou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Mudar status'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<DominioOpcaoModel>(
                      value: statusSelecionado,
                      decoration: const InputDecoration(labelText: 'Novo status'),
                      items: status.map((opcao) {
                        return DropdownMenuItem<DominioOpcaoModel>(
                          value: opcao,
                          child: Text(opcao.nomePadraoPtBr),
                        );
                      }).toList(),
                      onChanged: (opcao) => setDialogState(() => statusSelecionado = opcao),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: observacaoController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observação da mudança',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: statusSelecionado == null
                      ? null
                      : () async {
                          setState(() => _alterandoStatus = true);
                          try {
                            await _service.alterarStatus(
                              id: atendimento.id,
                              status: statusSelecionado!,
                              observacao: observacaoController.text.trim().isEmpty
                                  ? null
                                  : observacaoController.text.trim(),
                            );
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
                          } catch (error) {
                            if (mounted) _mostrarMensagem('Não foi possível alterar o status: $error');
                          } finally {
                            if (mounted) setState(() => _alterandoStatus = false);
                          }
                        },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    observacaoController.dispose();
    if (alterou == true && mounted) {
      _recarregar();
      _mostrarMensagem('Status atualizado no histórico.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = FutureBuilder<_ListaAtendimentosState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(mensagem: snapshot.error.toString(), onRetry: _recarregar);
        }
        final state = snapshot.data!;
        final atendimentos = _filtrar(state.atendimentos);
        return Column(
          children: <Widget>[
            _buildHeader(theme, state.atendimentos.length, atendimentos.length),
            const SizedBox(height: 18),
            Expanded(
              child: atendimentos.isEmpty
                  ? Center(child: Text('Nenhum atendimento encontrado.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                  : ListView.separated(
                      itemCount: atendimentos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildAtendimentoCard(
                        theme,
                        atendimentos[index],
                        state.dominios.statusAtendimentoTecnico,
                      ),
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
        title: const Text('Atendimentos criados'),
        leading: widget.onBack == null ? null : IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded)),
      ),
      body: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }

  Widget _buildHeader(ThemeData theme, int total, int filtrados) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 420,
            child: Row(
              children: <Widget>[
                Icon(Icons.fact_check_outlined, color: theme.colorScheme.primary, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Atendimentos criados', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      Text('Consulte, altere status e gere link de assinatura.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _chip(theme, '$total total', Icons.assignment_outlined),
          _chip(theme, '$filtrados visíveis', Icons.filter_alt_outlined),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), labelText: 'Buscar atendimento'),
            ),
          ),
          OutlinedButton.icon(onPressed: _recarregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
        ],
      ),
    );
  }

  Widget _buildAtendimentoCard(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) {
    final statusTexto = _statusLabel(atendimento, status);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirDetalhes(atendimento, status),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.devices_other_outlined, color: theme.colorScheme.primary, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_equipamentoTitulo(atendimento), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${atendimento.numero} • ${atendimento.nomeClienteSnapshot ?? 'Cliente não informado'}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                    if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(atendimento.defeitoRelatado!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (atendimento.assinaturaAprovada)
                          _signedChip(theme),
                        _chip(theme, statusTexto, Icons.flag_outlined),
                        _chip(theme, '${atendimento.itens.length} item(ns)', Icons.inventory_2_outlined),
                        _chip(theme, '${atendimento.historicoStatus.length} mov.', Icons.history_rounded),
                        _chip(theme, _formatarMoeda(atendimento.valorTotalAtendimento), Icons.payments_outlined),
                        _chip(theme, _formatarData(atendimento.dataAtualizacao), Icons.schedule_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                direction: Axis.vertical,
                spacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _gerarLinkAssinatura(atendimento),
                    icon: const Icon(Icons.draw_outlined, size: 18),
                    label: Text(_gerandoLink ? 'Gerando...' : 'Link assinatura'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _abrirAlterarStatusDialog(atendimento, status),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Mudar status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDetalhes(AtendimentoTecnicoModel atendimento, List<DominioOpcaoModel> status) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(atendimento.numero),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (atendimento.assinaturaAprovada)
                  _detailLine('Assinatura', _assinaturaResumo(atendimento)),
                _detailLine('Cliente', atendimento.nomeClienteSnapshot ?? 'Cliente não informado'),
                _detailLine('Status', _statusLabel(atendimento, status)),
                _detailLine('Total', _formatarMoeda(atendimento.valorTotalAtendimento)),
                if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty) _detailLine('Defeito', atendimento.defeitoRelatado!),
                if ((atendimento.diagnosticoTecnico ?? '').trim().isNotEmpty) _detailLine('Diagnóstico', atendimento.diagnosticoTecnico!),
                const SizedBox(height: 16),
                const Text('Itens', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (atendimento.itens.isEmpty)
                  const Text('Nenhum item vinculado.')
                else
                  ...atendimento.itens.map((item) => _detailLine(item.tipoItemCodigo == 'SERVICE' ? 'Serviço' : 'Produto', '${item.descricaoSnapshot} • ${item.quantidade.toStringAsFixed(0)} x ${_formatarMoeda(item.valorUnitario)}')),
                const SizedBox(height: 16),
                const Text('Histórico de status', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (atendimento.historicoStatus.isEmpty)
                  const Text('Nenhuma mudança registrada.')
                else
                  ...atendimento.historicoStatus.reversed.map((item) {
                    final anterior = item.statusAnteriorNomePtBr ?? _statusLabelPorCodigo(item.statusAnteriorCodigo, status);
                    final novo = item.statusNomePtBr ?? _statusLabelPorCodigo(item.statusCodigo, status);
                    final observacao = item.observacao?.trim() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${_formatarData(item.dataHora)} • $anterior → $novo${observacao.isEmpty ? '' : ' • $observacao'}'),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          OutlinedButton.icon(
            onPressed: () => _gerarLinkAssinatura(atendimento),
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Link assinatura'),
          ),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _signedChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.verified_rounded, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'Assinado',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Não foi possível carregar os atendimentos.\n$mensagem', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _ListaAtendimentosState {
  const _ListaAtendimentosState({required this.dominios, required this.atendimentos});

  final AtendimentoTecnicoDominiosBaseModel dominios;
  final List<AtendimentoTecnicoModel> atendimentos;
}
