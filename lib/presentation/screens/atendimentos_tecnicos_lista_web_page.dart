import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/dominio_models.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import 'atendimento_tecnico_editar_dialog.dart';
import 'atendimento_tecnico_receber_dialog.dart';
import 'atendimentos_tecnicos_web_page.dart';

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
    setState(() {
      _future = _carregar();
    });
  }

  void _fechar() {
    final VoidCallback? onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _novoAtendimento() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: SizedBox(
            width: size.width * 0.96,
            height: size.height * 0.92,
            child: AtendimentosTecnicosWebPage(
              embedded: true,
              onBack: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );

    if (mounted) {
      _recarregar();
    }
  }

  List<AtendimentoTecnicoModel> _filtrar(List<AtendimentoTecnicoModel> itens) {
    final termo = _buscaController.text.trim().toLowerCase();
    if (termo.isEmpty) return itens;
    return itens
        .where((atendimento) {
          final equipamento = atendimento.equipamento;
          final texto =
              <String>[
                atendimento.numero,
                atendimento.nomeClienteSnapshot ?? '',
                atendimento.statusCodigo,
                atendimento.statusNomePtBr ?? '',
                atendimento.assinaturaAprovada
                    ? 'assinado assinatura aprovado'
                    : '',
                atendimento.requerNovaAssinatura
                    ? 'nova assinatura pendente assinatura'
                    : '',
                atendimento.operacaoLiquidada
                    ? 'liquidada pago recebido'
                    : 'nao liquidada não liquidada aberto pendente',
                atendimento.statusLiquidacaoCodigo,
                'versao ${atendimento.versaoOrcamento}',
                equipamento?.tipo ?? '',
                equipamento?.marca ?? '',
                equipamento?.modelo ?? '',
                equipamento?.imei ?? '',
                atendimento.defeitoRelatado ?? '',
                atendimento.diagnosticoTecnico ?? '',
              ].join(' ').toLowerCase();
          return texto.contains(termo);
        })
        .toList(growable: false);
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
        return opcao.nomePadraoPtBr.trim().isEmpty
            ? opcao.codigo
            : opcao.nomePadraoPtBr;
      }
    }
    return normalizado;
  }

  String _formatarMoeda(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    final dia = value.day.toString().padLeft(2, '0');
    final mes = value.month.toString().padLeft(2, '0');
    final ano = value.year.toString();
    final hora = value.hour.toString().padLeft(2, '0');
    final minuto = value.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano $hora:$minuto';
  }

  String _formatarDataCurta(DateTime? value) {
    if (value == null) return '-';
    final dia = value.day.toString().padLeft(2, '0');
    final mes = value.month.toString().padLeft(2, '0');
    final ano = value.year.toString();
    return '$dia/$mes/$ano';
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

  int _totalEmAberto(List<AtendimentoTecnicoModel> atendimentos) =>
      atendimentos
          .where((atendimento) => !atendimento.operacaoLiquidada)
          .length;

  int _totalAssinados(List<AtendimentoTecnicoModel> atendimentos) =>
      atendimentos
          .where((atendimento) => atendimento.assinaturaAprovada)
          .length;

  double _valorAberto(List<AtendimentoTecnicoModel> atendimentos) =>
      atendimentos.fold<double>(
        0,
        (total, atendimento) => total + atendimento.valorEmAberto,
      );

  Future<void> _abrirEditarAtendimento(
    AtendimentoTecnicoModel atendimento,
  ) async {
    final alterou = await showDialog<bool>(
      context: context,
      builder: (_) => AtendimentoTecnicoEditarDialog(atendimento: atendimento),
    );
    if (alterou == true && mounted) {
      _recarregar();
      _mostrarMensagem(
        'Atendimento atualizado. O histórico de auditoria foi registrado e uma nova assinatura pode ser solicitada.',
      );
    }
  }

  Future<void> _abrirRecebimento(AtendimentoTecnicoModel atendimento) async {
    if (atendimento.operacaoLiquidada || atendimento.valorEmAberto <= 0) {
      _mostrarMensagem('Este atendimento já está liquidado.');
      return;
    }
    final recebeu = await showDialog<bool>(
      context: context,
      builder: (_) => AtendimentoTecnicoReceberDialog(atendimento: atendimento),
    );
    if (recebeu == true && mounted) {
      _recarregar();
      _mostrarMensagem('Recebimento lançado e auditoria registrada.');
    }
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
      if (link.isEmpty) throw Exception('Link não retornado pelo backend.');
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
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
                    Text(
                      atendimento.requerNovaAssinatura
                          ? 'Este atendimento foi alterado depois da última assinatura. Envie este novo link para o cliente assinar a versão atual.'
                          : 'Envie este link ao cliente por WhatsApp ou e-mail para aprovação e assinatura do serviço.',
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
                      decoration: const InputDecoration(
                        labelText: 'Novo status',
                      ),
                      items:
                          status
                              .map(
                                (opcao) => DropdownMenuItem<DominioOpcaoModel>(
                                  value: opcao,
                                  child: Text(opcao.nomePadraoPtBr),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (opcao) =>
                              setDialogState(() => statusSelecionado = opcao),
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
                  onPressed:
                      statusSelecionado == null
                          ? null
                          : () async {
                            setState(() => _alterandoStatus = true);
                            try {
                              await _service.alterarStatus(
                                id: atendimento.id,
                                status: statusSelecionado!,
                                observacao:
                                    observacaoController.text.trim().isEmpty
                                        ? null
                                        : observacaoController.text.trim(),
                              );
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(true);
                              }
                            } catch (error) {
                              if (mounted) {
                                _mostrarMensagem(
                                  'Não foi possível alterar o status: $error',
                                );
                              }
                            } finally {
                              if (mounted)
                                setState(() => _alterandoStatus = false);
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
          return _buildLoading(theme);
        }
        if (snapshot.hasError) {
          return _ErrorState(
            mensagem: snapshot.error.toString(),
            onRetry: _recarregar,
          );
        }
        final state = snapshot.data!;
        final atendimentos = _filtrar(state.atendimentos);
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 920;
            final horizontalPadding = isCompact ? 16.0 : 28.0;
            return Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.16),
              child: Column(
                children: <Widget>[
                  _buildHeader(
                    theme,
                    total: state.atendimentos.length,
                    filtrados: atendimentos.length,
                    isCompact: isCompact,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      10,
                    ),
                    child: Column(
                      children: <Widget>[
                        _buildResumo(theme, state.atendimentos, isCompact),
                        const SizedBox(height: 12),
                        _buildBusca(theme, isCompact),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        16,
                      ),
                      child:
                          atendimentos.isEmpty
                              ? _EmptyState(onRetry: _recarregar)
                              : ListView.separated(
                                itemCount: atendimentos.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 10),
                                itemBuilder:
                                    (context, index) => _buildAtendimentoCard(
                                      theme,
                                      atendimentos[index],
                                      state.dominios.statusAtendimentoTecnico,
                                      isCompact,
                                    ),
                              ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final Widget escAwareContent = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _fechar,
      },
      child: Focus(autofocus: true, child: content),
    );

    if (widget.embedded) return escAwareContent;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimentos criados'),
        leading:
            widget.onBack == null
                ? null
                : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
      ),
      body: escAwareContent,
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 12),
              Text('Carregando atendimentos...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme, {
    required int total,
    required int filtrados,
    required bool isCompact,
  }) {
    final colorScheme = theme.colorScheme;
    final titleBlock = Row(
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.fact_check_outlined,
            color: colorScheme.primary,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Atendimentos criados',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 21 : 24,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Consulte, receba, edite, audite e gere assinatura.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.66),
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
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _headerButton(theme, Icons.refresh_rounded, 'Atualizar', _recarregar),
        FilledButton.icon(
          onPressed: _novoAtendimento,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Novo atendimento'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        _metricBadge(theme, '$total total', Icons.assignment_outlined),
        _metricBadge(theme, '$filtrados visíveis', Icons.filter_alt_outlined),
        if (widget.onBack != null) _closeButton(context),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 28,
        isCompact ? 16 : 22,
        isCompact ? 16 : 28,
        isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.14)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child:
          isCompact
              ? Column(
                children: <Widget>[
                  titleBlock,
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
              : Row(
                children: <Widget>[
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  actions,
                ],
              ),
    );
  }

  Widget _buildResumo(
    ThemeData theme,
    List<AtendimentoTecnicoModel> atendimentos,
    bool isCompact,
  ) {
    final total = atendimentos.length;
    final emAberto = _totalEmAberto(atendimentos);
    final assinados = _totalAssinados(atendimentos);
    final valorAberto = _valorAberto(atendimentos);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            isCompact
                ? constraints.maxWidth
                : ((constraints.maxWidth - 36) / 4).clamp(190.0, 360.0);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Atendimentos',
              value: '$total',
              helper: 'Total criado',
              icon: Icons.assignment_turned_in_outlined,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Em aberto',
              value: '$emAberto',
              helper: 'Aguardam recebimento',
              icon: Icons.account_balance_wallet_outlined,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Assinados',
              value: '$assinados',
              helper: 'Com aceite do cliente',
              icon: Icons.verified_rounded,
            ),
            _summaryCard(
              theme,
              width: cardWidth,
              label: 'Valor aberto',
              value: _formatarMoeda(valorAberto),
              helper: 'Saldo pendente',
              icon: Icons.payments_outlined,
              highlight: true,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required double width,
    required String label,
    required String value,
    required String helper,
    required IconData icon,
    bool highlight = false,
  }) {
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                highlight
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.12),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    highlight
                        ? Colors.white.withOpacity(0.15)
                        : colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: highlight ? Colors.white : colorScheme.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          highlight
                              ? Colors.white.withOpacity(0.86)
                              : colorScheme.onSurface.withOpacity(0.62),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlight ? Colors.white : colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          highlight
                              ? Colors.white.withOpacity(0.78)
                              : colorScheme.onSurface.withOpacity(0.56),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusca(ThemeData theme, bool isCompact) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText:
                    'Buscar atendimento por cliente, status, equipamento ou número...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                ),
                suffixIcon:
                    _buscaController.text.trim().isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _buscaController.clear(),
                        ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          if (!isCompact) ...<Widget>[
            const SizedBox(width: 12),
            _metricBadge(
              theme,
              'Auditoria ativa',
              Icons.manage_history_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAtendimentoCard(
    ThemeData theme,
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
    bool isCompact,
  ) {
    final statusTexto = _statusLabel(atendimento, status);
    final colorScheme = theme.colorScheme;
    final bool pendente = !atendimento.operacaoLiquidada;
    final clienteSnapshot = atendimento.nomeClienteSnapshot?.trim() ?? '';
    final String cliente =
        clienteSnapshot.isNotEmpty ? clienteSnapshot : 'Cliente não informado';

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.devices_other_outlined,
            color: colorScheme.primary,
            size: 25,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _equipamentoTitulo(atendimento),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!isCompact) ...<Widget>[
                    const SizedBox(width: 10),
                    _coloredChip(
                      theme,
                      pendente ? 'Em aberto' : 'Liquidada',
                      pendente
                          ? Icons.account_balance_wallet_outlined
                          : Icons.price_check_rounded,
                      pendente ? colorScheme.error : colorScheme.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${atendimento.numero} • $cliente',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  atendimento.defeitoRelatado!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.72),
                    height: 1.25,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (isCompact)
                    atendimento.operacaoLiquidada
                        ? _liquidadaChip(theme)
                        : _naoLiquidadaChip(theme),
                  if (atendimento.assinaturaAprovada) _signedChip(theme),
                  if (atendimento.requerNovaAssinatura)
                    _pendingSignatureChip(theme),
                  _chip(theme, statusTexto, Icons.flag_outlined),
                  _chip(
                    theme,
                    'v${atendimento.versaoOrcamento}',
                    Icons.tag_outlined,
                  ),
                  _chip(
                    theme,
                    '${atendimento.itens.length} item(ns)',
                    Icons.inventory_2_outlined,
                  ),
                  _chip(
                    theme,
                    '${atendimento.historicoAuditoria.length} aud.',
                    Icons.manage_history_rounded,
                  ),
                  _metricChip(
                    theme,
                    'Total',
                    _formatarMoeda(atendimento.valorTotalAtendimento),
                    Icons.payments_outlined,
                  ),
                  _metricChip(
                    theme,
                    'Aberto',
                    _formatarMoeda(atendimento.valorEmAberto),
                    Icons.account_balance_wallet_outlined,
                  ),
                  _chip(
                    theme,
                    'Validade ${_formatarDataCurta(atendimento.validadeOrcamentoEm)}',
                    Icons.event_available_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      direction: isCompact ? Axis.horizontal : Axis.vertical,
      spacing: 8,
      runSpacing: 8,
      alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
      children: <Widget>[
        _actionButton(
          theme,
          label: 'Receber',
          icon: Icons.payments_outlined,
          onPressed:
              atendimento.operacaoLiquidada
                  ? null
                  : () => _abrirRecebimento(atendimento),
          filled: true,
        ),
        _actionButton(
          theme,
          label: 'Editar',
          icon: Icons.edit_note_rounded,
          onPressed: () => _abrirEditarAtendimento(atendimento),
        ),
        _actionButton(
          theme,
          label: _gerandoLink ? 'Gerando...' : 'Link assinatura',
          icon: Icons.draw_outlined,
          onPressed: () => _gerarLinkAssinatura(atendimento),
        ),
        _actionButton(
          theme,
          label: 'Mudar status',
          icon: Icons.swap_horiz_rounded,
          onPressed: () => _abrirAlterarStatusDialog(atendimento, status),
        ),
      ],
    );

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirDetalhes(atendimento, status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(isCompact ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.outline.withOpacity(0.13)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child:
              isCompact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      content,
                      const SizedBox(height: 14),
                      actions,
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: content),
                      const SizedBox(width: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 164),
                        child: actions,
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Future<void> _abrirDetalhes(
    AtendimentoTecnicoModel atendimento,
    List<DominioOpcaoModel> status,
  ) async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              '${atendimento.numero} • versão ${atendimento.versaoOrcamento}',
            ),
            content: SizedBox(
              width: 860,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _detailLine(
                      'Liquidação',
                      atendimento.operacaoLiquidada
                          ? 'Liquidada'
                          : 'Não liquidada',
                    ),
                    _detailLine(
                      'Total',
                      _formatarMoeda(atendimento.valorTotalAtendimento),
                    ),
                    _detailLine(
                      'Recebido',
                      _formatarMoeda(atendimento.valorRecebido),
                    ),
                    _detailLine(
                      'Em aberto',
                      _formatarMoeda(atendimento.valorEmAberto),
                    ),
                    if (atendimento.assinaturaAprovada)
                      _detailLine('Assinatura', _assinaturaResumo(atendimento)),
                    if (atendimento.requerNovaAssinatura)
                      _detailLine(
                        'Assinatura',
                        'Pendente para a versão atual do orçamento',
                      ),
                    _detailLine(
                      'Cliente',
                      atendimento.nomeClienteSnapshot ??
                          'Cliente não informado',
                    ),
                    _detailLine('Status', _statusLabel(atendimento, status)),
                    _detailLine(
                      'Validade',
                      _formatarDataCurta(atendimento.validadeOrcamentoEm),
                    ),
                    if ((atendimento.defeitoRelatado ?? '').trim().isNotEmpty)
                      _detailLine('Defeito', atendimento.defeitoRelatado!),
                    if ((atendimento.diagnosticoTecnico ?? '')
                        .trim()
                        .isNotEmpty)
                      _detailLine(
                        'Diagnóstico',
                        atendimento.diagnosticoTecnico!,
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Recebimentos',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    if (atendimento.recebimentos.isEmpty)
                      const Text('Nenhum recebimento lançado.')
                    else
                      ...atendimento.recebimentos.reversed.map(
                        (item) => _detailLine(
                          item.nomeFormaRecebimento,
                          '${_formatarMoeda(item.valor)} • ${_formatarData(item.dataHora)}${(item.observacao ?? '').trim().isEmpty ? '' : ' • ${item.observacao}'}',
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Itens',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    if (atendimento.itens.isEmpty)
                      const Text('Nenhum item vinculado.')
                    else
                      ...atendimento.itens.map(
                        (item) => _detailLine(
                          item.tipoItemCodigo == 'SERVICE'
                              ? 'Serviço'
                              : 'Produto',
                          '${item.descricaoSnapshot} • ${item.quantidade.toStringAsFixed(0)} x ${_formatarMoeda(item.valorUnitario)}',
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Histórico de auditoria',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    if (atendimento.historicoAuditoria.isEmpty)
                      const Text('Nenhuma auditoria registrada.')
                    else
                      ...atendimento.historicoAuditoria.reversed.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${_formatarData(item.dataHora)} • v${item.versaoOrcamento} • ${item.tipo}${(item.observacao ?? '').trim().isEmpty ? '' : ' • ${item.observacao}'}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Histórico de status',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    if (atendimento.historicoStatus.isEmpty)
                      const Text('Nenhuma mudança registrada.')
                    else
                      ...atendimento.historicoStatus.reversed.map((item) {
                        final anterior =
                            item.statusAnteriorNomePtBr ??
                            _statusLabelPorCodigo(
                              item.statusAnteriorCodigo,
                              status,
                            );
                        final novo =
                            item.statusNomePtBr ??
                            _statusLabelPorCodigo(item.statusCodigo, status);
                        final observacao = item.observacao?.trim() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${_formatarData(item.dataHora)} • $anterior → $novo${observacao.isEmpty ? '' : ' • $observacao'}',
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              FilledButton.icon(
                onPressed:
                    atendimento.operacaoLiquidada
                        ? null
                        : () => _abrirRecebimento(atendimento),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Receber'),
              ),
              OutlinedButton.icon(
                onPressed: () => _abrirEditarAtendimento(atendimento),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Editar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _gerarLinkAssinatura(atendimento),
                icon: const Icon(Icons.draw_outlined),
                label: const Text('Link assinatura'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fechar'),
              ),
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
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _headerButton(
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _actionButton(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 13);
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: FilledButton.styleFrom(padding: padding, shape: shape),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(padding: padding, shape: shape),
    );
  }

  Widget _closeButton(BuildContext context) {
    return Material(
      color: const Color(0xFFE53935),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          if (widget.onBack != null) {
            widget.onBack!.call();
            return;
          }
          Navigator.of(context).maybePop();
        },
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _metricBadge(ThemeData theme, String label, IconData icon) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _signedChip(ThemeData theme) => _coloredChip(
    theme,
    'Assinado',
    Icons.verified_rounded,
    theme.colorScheme.primary,
  );

  Widget _pendingSignatureChip(ThemeData theme) => _coloredChip(
    theme,
    'Nova assinatura pendente',
    Icons.pending_actions_rounded,
    theme.colorScheme.error,
  );

  Widget _liquidadaChip(ThemeData theme) => _coloredChip(
    theme,
    'Liquidada',
    Icons.price_check_rounded,
    theme.colorScheme.primary,
  );

  Widget _naoLiquidadaChip(ThemeData theme) => _coloredChip(
    theme,
    'Não liquidada',
    Icons.account_balance_wallet_outlined,
    theme.colorScheme.error,
  );

  Widget _coloredChip(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.search_off_rounded,
              color: theme.colorScheme.primary,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhum atendimento encontrado.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajuste a busca ou atualize a lista.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar'),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              'Não foi possível carregar os atendimentos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
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

class _ListaAtendimentosState {
  const _ListaAtendimentosState({
    required this.dominios,
    required this.atendimentos,
  });

  final AtendimentoTecnicoDominiosBaseModel dominios;
  final List<AtendimentoTecnicoModel> atendimentos;
}
