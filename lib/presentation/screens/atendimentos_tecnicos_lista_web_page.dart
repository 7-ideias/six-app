import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/dominio_models.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../providers/locale_settings_provider.dart';
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
  static const String _semTecnicoKey = '__sem_tecnico__';

  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final ColaboradorUsuarioApiClient _colaboradorApiClient =
      HttpColaboradorUsuarioApiClient();
  final TextEditingController _buscaController = TextEditingController();

  late Future<_ListaAtendimentosState> _future;
  bool _alterandoStatus = false;
  bool _gerandoLink = false;
  DateTime? _dataInicioFiltro;
  DateTime? _dataFimFiltro;
  String? _tecnicoFiltroKey;

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
      _colaboradorApiClient.listarTecnicosAssistenciaTecnica(),
    ]);
    return _ListaAtendimentosState(
      dominios: results[0] as AtendimentoTecnicoDominiosBaseModel,
      atendimentos: results[1] as List<AtendimentoTecnicoModel>,
      tecnicos: results[2] as List<ColaboradorUsuarioResumo>,
    );
  }

  void _onBuscaChanged() {
    if (mounted) setState(() {});
  }

  bool get _possuiFiltrosAtivos =>
      _buscaController.text.trim().isNotEmpty ||
      _dataInicioFiltro != null ||
      _dataFimFiltro != null ||
      _tecnicoFiltroKey != null;

  void _limparFiltros() {
    setState(() {
      _dataInicioFiltro = null;
      _dataFimFiltro = null;
      _tecnicoFiltroKey = null;
      _buscaController.clear();
    });
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
    final inicio =
        _dataInicioFiltro == null ? null : _inicioDoDia(_dataInicioFiltro!);
    final fim = _dataFimFiltro == null ? null : _fimDoDia(_dataFimFiltro!);
    final tecnicoKey = _tecnicoFiltroKey;

    return itens
        .where((atendimento) {
          final dataReferencia = _dataReferenciaFiltro(atendimento);
          if (inicio != null) {
            if (dataReferencia == null || dataReferencia.isBefore(inicio)) {
              return false;
            }
          }
          if (fim != null) {
            if (dataReferencia == null || dataReferencia.isAfter(fim)) {
              return false;
            }
          }
          if (tecnicoKey != null &&
              _tecnicoKeyAtendimento(atendimento) != tecnicoKey) {
            return false;
          }

          if (termo.isEmpty) return true;

          final equipamento = atendimento.equipamento;
          final texto =
              <String>[
                atendimento.numero,
                atendimento.nomeClienteSnapshot ?? '',
                atendimento.nomeTecnicoResponsavelSnapshot ?? '',
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

  DateTime _inicioDoDia(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _fimDoDia(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  DateTime? _dataReferenciaFiltro(AtendimentoTecnicoModel atendimento) {
    return atendimento.dataAtualizacao ??
        atendimento.dataUltimaAlteracaoOrcamento ??
        atendimento.dataVencimentoEm ??
        atendimento.validadeOrcamentoEm;
  }

  String _tecnicoKeyAtendimento(AtendimentoTecnicoModel atendimento) {
    final id = atendimento.idTecnicoResponsavel?.trim() ?? '';
    if (id.isNotEmpty) return id;
    final nome = atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    if (nome.isNotEmpty) return nome.toLowerCase();
    return _semTecnicoKey;
  }

  String _tecnicoLabelAtendimento(AtendimentoTecnicoModel atendimento) {
    final nome = atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    return nome.isEmpty ? 'Sem técnico responsável' : nome;
  }

  List<_TecnicoFiltroOption> _tecnicoOptions(
    List<AtendimentoTecnicoModel> atendimentos,
    List<ColaboradorUsuarioResumo> tecnicos,
  ) {
    final Map<String, _TecnicoFiltroOption> mapa =
        <String, _TecnicoFiltroOption>{};
    for (final ColaboradorUsuarioResumo tecnico in tecnicos) {
      if (!tecnico.ehTecnicoAssistenciaTecnica) continue;
      final String id =
          tecnico.idUnicoPessoal.trim().isNotEmpty
              ? tecnico.idUnicoPessoal.trim()
              : tecnico.email.trim();
      final String nome =
          tecnico.nomeDeGuerra.trim().isNotEmpty
              ? tecnico.nomeDeGuerra.trim()
              : tecnico.nome.trim().isNotEmpty
              ? tecnico.nome.trim()
              : tecnico.email.trim();
      final String key = id.isNotEmpty ? id : nome.toLowerCase();
      if (key.isEmpty || nome.isEmpty) continue;
      mapa[key] = _TecnicoFiltroOption(key: key, label: nome);
    }
    if (atendimentos.any(
      (AtendimentoTecnicoModel atendimento) =>
          _tecnicoKeyAtendimento(atendimento) == _semTecnicoKey,
    )) {
      mapa[_semTecnicoKey] = const _TecnicoFiltroOption(
        key: _semTecnicoKey,
        label: 'Sem técnico responsável',
      );
    }
    final options = mapa.values.toList(growable: false)..sort((a, b) {
      if (a.key == _semTecnicoKey) return 1;
      if (b.key == _semTecnicoKey) return -1;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return options;
  }

  String _tecnicoFiltroLabel(List<_TecnicoFiltroOption> options) {
    final key = _tecnicoFiltroKey;
    if (key == null) return 'Todos os técnicos';
    for (final option in options) {
      if (option.key == key) return option.label;
    }
    return 'Técnico selecionado';
  }

  String _periodoFiltroLabel() {
    final inicio = _dataInicioFiltro;
    final fim = _dataFimFiltro;
    if (inicio == null && fim == null) return 'Todas as datas';
    if (inicio != null && fim != null) {
      return '${_formatarDataCurta(inicio)} até ${_formatarDataCurta(fim)}';
    }
    if (inicio != null) return 'A partir de ${_formatarDataCurta(inicio)}';
    return 'Até ${_formatarDataCurta(fim!)}';
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
      context.read<LocaleSettingsProvider>().formatCurrency(value);

  String _formatarData(DateTime? value) {
    if (value == null) return '-';
    final locale = context.read<LocaleSettingsProvider>();
    return '${locale.formatDate(value)} ${locale.formatTime(value)}';
  }

  String _formatarDataCurta(DateTime? value) {
    if (value == null) return '-';
    return context.read<LocaleSettingsProvider>().formatDate(value);
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
    final alterou = await showDialog<bool>(
      context: context,
      barrierDismissible: !_alterandoStatus,
      builder: (dialogContext) {
        return _AlterarStatusAtendimentoWebDialog(
          atendimento: atendimento,
          status: status,
          statusAtual: _statusAtual(atendimento, status),
          statusAtualLabel: _statusLabel(atendimento, status),
          onSalvar: (DominioOpcaoModel novoStatus, String? observacao) async {
            setState(() => _alterandoStatus = true);
            try {
              await _service.alterarStatus(
                id: atendimento.id,
                status: novoStatus,
                observacao: observacao,
              );
              return true;
            } finally {
              if (mounted) {
                setState(() => _alterandoStatus = false);
              }
            }
          },
        );
      },
    );

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
    context.select<LocaleSettingsProvider, String>(
      (provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}|${provider.timeFormat}',
    );

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
                        _buildBusca(
                          theme,
                          isCompact,
                          state.atendimentos,
                          state.tecnicos,
                        ),
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

  Widget _buildBusca(
    ThemeData theme,
    bool isCompact,
    List<AtendimentoTecnicoModel> atendimentos,
    List<ColaboradorUsuarioResumo> tecnicos,
  ) {
    final colorScheme = theme.colorScheme;
    final tecnicoOptions = _tecnicoOptions(atendimentos, tecnicos);
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double searchWidth =
              isCompact
                  ? constraints.maxWidth
                  : (constraints.maxWidth * 0.44).clamp(320.0, 560.0);
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    hintText:
                        'Buscar por cliente, técnico, status, equipamento ou número...',
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
              _filterTrigger(
                theme,
                width: isCompact ? constraints.maxWidth : 220,
                label: 'Data',
                value: _periodoFiltroLabel(),
                icon: Icons.event_outlined,
                onTap: _abrirFiltroDataWeb,
              ),
              _tecnicoFilterMenu(
                theme,
                width: isCompact ? constraints.maxWidth : 240,
                options: tecnicoOptions,
              ),
              if (_possuiFiltrosAtivos)
                OutlinedButton.icon(
                  onPressed: _limparFiltros,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Limpar filtros'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              if (!isCompact)
                _metricBadge(
                  theme,
                  'Auditoria ativa',
                  Icons.manage_history_rounded,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _abrirFiltroDataWeb() async {
    final result = await showDialog<_PeriodoFiltro>(
      context: context,
      builder: (context) {
        return _PeriodoFiltroWebDialog(
          dataInicio: _dataInicioFiltro,
          dataFim: _dataFimFiltro,
          formatarData: _formatarDataCurta,
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _dataInicioFiltro = result.dataInicio;
      _dataFimFiltro = result.dataFim;
    });
  }

  Widget _filterTrigger(
    ThemeData theme, {
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: _filterDisplay(theme, label: label, value: value, icon: icon),
        ),
      ),
    );
  }

  Widget _filterDisplay(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: colorScheme.primary, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.58),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _tecnicoFilterMenu(
    ThemeData theme, {
    required double width,
    required List<_TecnicoFiltroOption> options,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Filtrar por técnico responsável',
      onSelected: (value) {
        setState(() {
          _tecnicoFiltroKey = value == '__todos__' ? null : value;
        });
      },
      itemBuilder:
          (context) => <PopupMenuEntry<String>>[
            CheckedPopupMenuItem<String>(
              value: '__todos__',
              checked: _tecnicoFiltroKey == null,
              child: const Text('Todos os técnicos'),
            ),
            const PopupMenuDivider(),
            ...options.map(
              (option) => CheckedPopupMenuItem<String>(
                value: option.key,
                checked: _tecnicoFiltroKey == option.key,
                child: Text(option.label),
              ),
            ),
          ],
      child: SizedBox(
        width: width,
        child: _filterDisplay(
          theme,
          label: 'Técnico responsável',
          value: _tecnicoFiltroLabel(options),
          icon: Icons.engineering_outlined,
        ),
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
                  _chip(
                    theme,
                    _tecnicoLabelAtendimento(atendimento),
                    Icons.engineering_outlined,
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
                    'Atualização ${_formatarDataCurta(_dataReferenciaFiltro(atendimento))}',
                    Icons.update_rounded,
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

typedef _SalvarStatusAtendimento =
    Future<bool> Function(DominioOpcaoModel status, String? observacao);

class _AlterarStatusAtendimentoWebDialog extends StatefulWidget {
  const _AlterarStatusAtendimentoWebDialog({
    required this.atendimento,
    required this.status,
    required this.statusAtual,
    required this.statusAtualLabel,
    required this.onSalvar,
  });

  final AtendimentoTecnicoModel atendimento;
  final List<DominioOpcaoModel> status;
  final DominioOpcaoModel? statusAtual;
  final String statusAtualLabel;
  final _SalvarStatusAtendimento onSalvar;

  @override
  State<_AlterarStatusAtendimentoWebDialog> createState() =>
      _AlterarStatusAtendimentoWebDialogState();
}

class _AlterarStatusAtendimentoWebDialogState
    extends State<_AlterarStatusAtendimentoWebDialog> {
  late DominioOpcaoModel? _statusSelecionado = widget.statusAtual;
  final TextEditingController _observacaoController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final statusSelecionado = _statusSelecionado;
    if (statusSelecionado == null || _salvando) return;
    setState(() => _salvando = true);
    final observacao = _observacaoController.text.trim();
    final salvou = await widget.onSalvar(
      statusSelecionado,
      observacao.isEmpty ? null : observacao,
    );
    if (!mounted) return;
    setState(() => _salvando = false);
    if (salvou) {
      Navigator.of(context).pop(true);
    }
  }

  String get _cliente {
    final nome = widget.atendimento.nomeClienteSnapshot?.trim() ?? '';
    return nome.isEmpty ? 'Cliente não informado' : nome;
  }

  String get _equipamento {
    final equipamento = widget.atendimento.equipamento;
    final partes = <String>[
      equipamento?.tipo ?? '',
      equipamento?.marca ?? '',
      equipamento?.modelo ?? '',
    ].where((parte) => parte.trim().isNotEmpty).toList(growable: false);
    return partes.isEmpty ? widget.atendimento.numero : partes.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 520;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 24,
                      compact ? 18 : 22,
                      compact ? 12 : 16,
                      compact ? 16 : 18,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.06),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withOpacity(0.14),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
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
                                'Mudar status',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Registre a próxima etapa do atendimento técnico.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed:
                              _salvando
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                          tooltip: 'Fechar',
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 18 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _StatusContextCard(
                          numero: widget.atendimento.numero,
                          equipamento: _equipamento,
                          cliente: _cliente,
                          statusAtual: widget.statusAtualLabel,
                        ),
                        const SizedBox(height: 16),
                        _StatusWebSelector(
                          label: 'Novo status',
                          value: _statusSelecionado,
                          options: widget.status,
                          enabled: !_salvando,
                          onChanged:
                              (value) =>
                                  setState(() => _statusSelecionado = value),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _observacaoController,
                          enabled: !_salvando,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Observação da mudança',
                            hintText:
                                'Informe um detalhe útil para o histórico, se necessário.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 24,
                      14,
                      compact ? 18 : 24,
                      compact ? 18 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outline.withOpacity(0.12),
                        ),
                      ),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment:
                          compact ? WrapAlignment.start : WrapAlignment.end,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed:
                              _salvando
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton.icon(
                          onPressed:
                              _statusSelecionado == null || _salvando
                                  ? null
                                  : _salvar,
                          icon:
                              _salvando
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                  : const Icon(Icons.check_rounded),
                          label: Text(_salvando ? 'Salvando...' : 'Salvar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusContextCard extends StatelessWidget {
  const _StatusContextCard({
    required this.numero,
    required this.equipamento,
    required this.cliente,
    required this.statusAtual,
  });

  final String numero;
  final String equipamento;
  final String cliente;
  final String statusAtual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.devices_other_outlined,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  equipamento,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$numero • $cliente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _StatusPill(
                      icon: Icons.flag_outlined,
                      label: 'Status atual',
                      value: statusAtual,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusWebSelector extends StatefulWidget {
  const _StatusWebSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final DominioOpcaoModel? value;
  final List<DominioOpcaoModel> options;
  final ValueChanged<DominioOpcaoModel> onChanged;
  final bool enabled;

  @override
  State<_StatusWebSelector> createState() => _StatusWebSelectorState();
}

class _StatusWebSelectorState extends State<_StatusWebSelector> {
  final GlobalKey _fieldKey = GlobalKey();
  bool _opened = false;

  Future<void> _openMenu() async {
    if (!widget.enabled) return;
    final context = _fieldKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(
          renderBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    setState(() => _opened = true);
    final selected = await showMenu<DominioOpcaoModel>(
      context: context,
      position: position,
      constraints: BoxConstraints.tightFor(width: renderBox.size.width),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      items:
          widget.options
              .map(
                (option) => PopupMenuItem<DominioOpcaoModel>(
                  value: option,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          option.nomePadraoPtBr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (option.id == widget.value?.id)
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
    if (!mounted) return;
    setState(() => _opened = false);
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final value = widget.value?.nomePadraoPtBr ?? 'Selecione um status';
    return InkWell(
      key: _fieldKey,
      onTap: _openMenu,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              widget.enabled
                  ? colorScheme.surface
                  : colorScheme.surfaceVariant.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _opened
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.flag_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          widget.enabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedRotation(
              turns: _opened ? 0.5 : 0,
              duration: const Duration(milliseconds: 160),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodoFiltroWebDialog extends StatefulWidget {
  const _PeriodoFiltroWebDialog({
    required this.dataInicio,
    required this.dataFim,
    required this.formatarData,
  });

  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String Function(DateTime?) formatarData;

  @override
  State<_PeriodoFiltroWebDialog> createState() =>
      _PeriodoFiltroWebDialogState();
}

class _PeriodoFiltroWebDialogState extends State<_PeriodoFiltroWebDialog> {
  late DateTime? _inicio = widget.dataInicio;
  late DateTime? _fim = widget.dataFim;
  late final TextEditingController _inicioController = TextEditingController(
    text: _inicio == null ? '' : widget.formatarData(_inicio),
  );
  late final TextEditingController _fimController = TextEditingController(
    text: _fim == null ? '' : widget.formatarData(_fim),
  );
  String? _erro;

  @override
  void dispose() {
    _inicioController.dispose();
    _fimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    return AlertDialog(
      title: const Text('Filtrar por data'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Use a data de atualização do atendimento.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _dateInput(
                    theme,
                    controller: _inicioController,
                    label: 'Início',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateInput(
                    theme,
                    controller: _fimController,
                    label: 'Fim',
                  ),
                ),
              ],
            ),
            if (_erro != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _erro!,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ActionChip(
                  label: const Text('Hoje'),
                  onPressed: () => _setPeriodo(now, now),
                ),
                ActionChip(
                  label: const Text('Últimos 7 dias'),
                  onPressed:
                      () => _setPeriodo(
                        now.subtract(const Duration(days: 6)),
                        now,
                      ),
                ),
                ActionChip(
                  label: const Text('Últimos 30 dias'),
                  onPressed:
                      () => _setPeriodo(
                        now.subtract(const Duration(days: 29)),
                        now,
                      ),
                ),
                ActionChip(
                  label: const Text('Este mês'),
                  onPressed:
                      () => _setPeriodo(DateTime(now.year, now.month), now),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed:
              () => Navigator.of(
                context,
              ).pop(const _PeriodoFiltro(dataInicio: null, dataFim: null)),
          child: const Text('Limpar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _aplicar,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _dateInput(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
  }) {
    final colorScheme = theme.colorScheme;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/mm/aaaa',
        prefixIcon: Icon(Icons.event_outlined, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      onSubmitted: (_) => _aplicar(),
    );
  }

  void _aplicar() {
    final inicio = _parseData(_inicioController.text);
    final fim = _parseData(_fimController.text);

    if (inicio == null && _inicioController.text.trim().isNotEmpty) {
      setState(() => _erro = 'Informe a data inicial em um formato válido.');
      return;
    }
    if (fim == null && _fimController.text.trim().isNotEmpty) {
      setState(() => _erro = 'Informe a data final em um formato válido.');
      return;
    }
    if (inicio != null && fim != null && fim.isBefore(inicio)) {
      setState(() => _erro = 'A data final não pode ser anterior à inicial.');
      return;
    }

    Navigator.of(context).pop(_PeriodoFiltro(dataInicio: inicio, dataFim: fim));
  }

  DateTime? _parseData(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final iso = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$').firstMatch(text);
    if (iso != null) {
      return _validDate(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }

    final local = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})$',
    ).firstMatch(text);
    if (local == null) return null;

    final first = int.parse(local.group(1)!);
    final second = int.parse(local.group(2)!);
    final rawYear = int.parse(local.group(3)!);
    final year = rawYear < 100 ? rawYear + 2000 : rawYear;

    if (first > 12) return _validDate(year, second, first);
    if (second > 12) return _validDate(year, first, second);
    return _validDate(year, second, first);
  }

  DateTime? _validDate(int year, int month, int day) {
    if (year < 2000 || year > DateTime.now().year + 5) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  void _setPeriodo(DateTime inicio, DateTime fim) {
    setState(() {
      _inicio = DateTime(inicio.year, inicio.month, inicio.day);
      _fim = DateTime(fim.year, fim.month, fim.day);
      _inicioController.text = widget.formatarData(_inicio);
      _fimController.text = widget.formatarData(_fim);
      _erro = null;
    });
  }
}

class _PeriodoFiltro {
  const _PeriodoFiltro({required this.dataInicio, required this.dataFim});

  final DateTime? dataInicio;
  final DateTime? dataFim;
}

class _TecnicoFiltroOption {
  const _TecnicoFiltroOption({required this.key, required this.label});

  final String key;
  final String label;
}

class _ListaAtendimentosState {
  const _ListaAtendimentosState({
    required this.dominios,
    required this.atendimentos,
    required this.tecnicos,
  });

  final AtendimentoTecnicoDominiosBaseModel dominios;
  final List<AtendimentoTecnicoModel> atendimentos;
  final List<ColaboradorUsuarioResumo> tecnicos;
}
