import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/catalogo_reserva_service.dart';
import 'package:sixpos/data/models/catalogo_reserva_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class CatalogoReservasWebDialog extends StatefulWidget {
  const CatalogoReservasWebDialog({super.key});

  @override
  State<CatalogoReservasWebDialog> createState() =>
      _CatalogoReservasWebDialogState();
}

class _CatalogoReservasWebDialogState extends State<CatalogoReservasWebDialog> {
  final CatalogoReservaService _service = CatalogoReservaService();

  CatalogoReservaPaginaModel? _pagina;
  CatalogoReservaDetalheModel? _detalhe;
  CatalogoReservaStatus? _filtroStatus;
  String? _idSelecionado;
  String? _erro;
  bool _carregando = true;
  bool _carregandoDetalhe = false;
  bool _atualizandoStatus = false;
  bool _convertendo = false;

  List<_CatalogoReservaDropdownOption<CatalogoReservaStatus>>
  _statusDropdownOptions(BuildContext context) {
    return CatalogoReservaStatus.values
        .map(
          (CatalogoReservaStatus status) =>
              _CatalogoReservaDropdownOption<CatalogoReservaStatus>(
                value: status,
                label: _statusLabel(context, status),
                enabled: status != CatalogoReservaStatus.convertida,
              ),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => _carregar());
  }

  Future<void> _carregar({int pagina = 0, String? selecionarId}) async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final CatalogoReservaPaginaModel resultado = await _service.listar(
        status: _filtroStatus,
        pagina: pagina,
      );
      if (!mounted) return;
      final String? proximoId = _resolverIdSelecionado(
        resultado,
        selecionarId ?? _idSelecionado,
      );
      setState(() {
        _pagina = resultado;
        _idSelecionado = proximoId;
        _detalhe = null;
        _carregando = false;
      });
      if (proximoId != null) {
        await _carregarDetalhe(proximoId);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.toString();
        _carregando = false;
      });
    }
  }

  String? _resolverIdSelecionado(
    CatalogoReservaPaginaModel pagina,
    String? candidato,
  ) {
    if (candidato != null &&
        pagina.reservas.any(
          (CatalogoReservaResumoModel item) => item.idReserva == candidato,
        )) {
      return candidato;
    }
    return pagina.reservas.isEmpty ? null : pagina.reservas.first.idReserva;
  }

  Future<void> _carregarDetalhe(String idReserva) async {
    setState(() {
      _idSelecionado = idReserva;
      _carregandoDetalhe = true;
      _erro = null;
    });
    try {
      final CatalogoReservaDetalheModel detalhe = await _service.consultar(
        idReserva,
      );
      if (!mounted || _idSelecionado != idReserva) return;
      setState(() {
        _detalhe = detalhe;
        _carregandoDetalhe = false;
      });
    } catch (error) {
      if (!mounted || _idSelecionado != idReserva) return;
      setState(() {
        _erro = error.toString();
        _carregandoDetalhe = false;
      });
    }
  }

  Future<void> _atualizarStatus(CatalogoReservaStatus status) async {
    final CatalogoReservaDetalheModel? detalhe = _detalhe;
    if (detalhe == null || _atualizandoStatus || detalhe.status == status) {
      return;
    }
    setState(() {
      _atualizandoStatus = true;
      _erro = null;
    });
    try {
      final CatalogoReservaDetalheModel atualizado = await _service
          .atualizarStatus(idReserva: detalhe.idReserva, status: status);
      if (!mounted) return;
      setState(() => _detalhe = atualizado);
      await _carregar(
        pagina: _pagina?.pagina ?? 0,
        selecionarId: atualizado.idReserva,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = error.toString());
    } finally {
      if (mounted) setState(() => _atualizandoStatus = false);
    }
  }

  Future<void> _converterEmVenda() async {
    final CatalogoReservaDetalheModel? detalhe = _detalhe;
    if (detalhe == null || _convertendo) return;

    final bool confirmado =
        await showDialog<bool>(
          context: context,
          builder:
              (BuildContext dialogContext) => AlertDialog(
                title: Text(
                  context.t(
                    'catalogReservations.convert.confirmTitle',
                    fallback: 'Converter reserva em venda?',
                  ),
                ),
                content: Text(
                  context.t(
                    'catalogReservations.convert.confirmMessage',
                    fallback:
                        'O estoque será validado e os itens serão enviados para uma venda a receber.',
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      context.t('common.cancel', fallback: 'Cancelar'),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.t(
                        'catalogReservations.convert.action',
                        fallback: 'Converter em venda',
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (!confirmado || !mounted) return;

    setState(() {
      _convertendo = true;
      _erro = null;
    });
    try {
      final CatalogoReservaConversaoModel conversao = await _service
          .converterEmVenda(detalhe.idReserva);
      if (!mounted) return;
      await _carregar(
        pagina: _pagina?.pagina ?? 0,
        selecionarId: conversao.idReserva,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'catalogReservations.convert.success',
              fallback: 'Reserva convertida em venda a receber.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErroConversao(error));
    } finally {
      if (mounted) setState(() => _convertendo = false);
    }
  }

  String _mensagemErroConversao(Object error) {
    if (error is CatalogoReservaServiceException) {
      return switch (error.codigo) {
        'ESTOQUE_INSUFICIENTE_PARA_RESERVA' => context.t(
          'catalogReservations.convert.error.stock',
          fallback: 'Estoque insuficiente para converter esta reserva.',
        ),
        'RESERVA_PRECISA_ESTAR_CONFIRMADA' => context.t(
          'catalogReservations.convert.error.confirmedOnly',
          fallback: 'Confirme a reserva antes de convertê-la em venda.',
        ),
        'CONVERSAO_RESERVA_EM_ANDAMENTO' => context.t(
          'catalogReservations.convert.error.processing',
          fallback: 'Esta reserva já está sendo convertida. Atualize a tela.',
        ),
        'VENDA_RESERVA_RECEBIMENTO_NAO_CONFIGURADO' => context.t(
          'catalogReservations.convert.error.paymentConfig',
          fallback:
              'Configure um tipo de recebimento futuro antes da conversão.',
        ),
        'PRODUTO_RESERVA_NAO_DISPONIVEL' => context.t(
          'catalogReservations.convert.error.product',
          fallback: 'Um dos produtos reservados não está mais disponível.',
        ),
        _ => context.t(
          'catalogReservations.convert.error.generic',
          fallback: 'Não foi possível converter a reserva em venda.',
        ),
      };
    }
    return context.t(
      'catalogReservations.convert.error.generic',
      fallback: 'Não foi possível converter a reserva em venda.',
    );
  }

  void _alterarFiltro(CatalogoReservaStatus? status) {
    if (_filtroStatus == status) return;
    setState(() => _filtroStatus = status);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240, maxHeight: 860),
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: tokens.workspaceBackground,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: <Widget>[
              _buildHeader(context, tokens),
              Expanded(child: _buildBody(context, tokens)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WebThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
      decoration: BoxDecoration(
        color: tokens.headerBackground,
        border: Border(bottom: BorderSide(color: tokens.headerBorder)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.inventory_outlined, color: tokens.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    'catalogReservations.title',
                    fallback: 'Reservas do catálogo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.t(
                    'catalogReservations.subtitle',
                    fallback:
                        'Acompanhe solicitações recebidas pelo catálogo virtual.',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.secondaryText),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed:
                _carregando
                    ? null
                    : () => _carregar(
                      pagina: _pagina?.pagina ?? 0,
                      selecionarId: _idSelecionado,
                    ),
            tooltip: context.t('common.refresh', fallback: 'Atualizar'),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: context.t('common.close', fallback: 'Fechar'),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WebThemeTokens tokens) {
    if (_carregando && _pagina == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: SixBackendLoading.messages(
          title: context.t(
            'catalogReservations.loadingTitle',
            fallback: 'Carregando reservas',
          ),
          subtitle: context.t(
            'catalogReservations.loadingSubtitle',
            fallback: 'Sincronizando as solicitações deste comércio.',
          ),
          leadingIcon: Icons.inventory_outlined,
        ),
      );
    }

    if (_erro != null && _pagina == null) {
      return _buildError(context, tokens);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compacto = constraints.maxWidth < 860;
        final Widget lista = _buildListPanel(context, tokens);
        final Widget detalhe = _buildDetailPanel(context, tokens);
        if (compacto) {
          return Column(
            children: <Widget>[
              Expanded(child: lista),
              if (_idSelecionado != null)
                SizedBox(height: constraints.maxHeight * 0.48, child: detalhe),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: 430, child: lista),
            VerticalDivider(width: 1, color: tokens.divider),
            Expanded(child: detalhe),
          ],
        );
      },
    );
  }

  Widget _buildListPanel(BuildContext context, WebThemeTokens tokens) {
    final CatalogoReservaPaginaModel pagina =
        _pagina ??
        const CatalogoReservaPaginaModel(
          reservas: <CatalogoReservaResumoModel>[],
          pagina: 0,
          tamanho: 20,
          totalPaginas: 0,
          totalElementos: 0,
        );
    return Container(
      color: tokens.surface,
      child: Column(
        children: <Widget>[
          _buildFilters(context, tokens),
          if (_erro != null)
            _buildInlineError(context, tokens)
          else if (pagina.reservas.isEmpty)
            Expanded(child: _buildEmpty(context, tokens))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: pagina.reservas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  return _buildReservaCard(
                    context,
                    tokens,
                    pagina.reservas[index],
                  );
                },
              ),
            ),
          _buildPagination(context, tokens, pagina),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WebThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _statusChip(context, tokens, null),
            for (final CatalogoReservaStatus status
                in CatalogoReservaStatus.values) ...<Widget>[
              const SizedBox(width: 8),
              _statusChip(context, tokens, status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(
    BuildContext context,
    WebThemeTokens tokens,
    CatalogoReservaStatus? status,
  ) {
    final bool selecionado = _filtroStatus == status;
    return ChoiceChip(
      selected: selecionado,
      onSelected: (_) => _alterarFiltro(status),
      label: Text(
        status == null
            ? context.t('common.all', fallback: 'Todos')
            : _statusLabel(context, status),
      ),
      labelStyle: TextStyle(
        color: selecionado ? tokens.primaryText : tokens.secondaryText,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildReservaCard(
    BuildContext context,
    WebThemeTokens tokens,
    CatalogoReservaResumoModel reserva,
  ) {
    final bool selecionada = reserva.idReserva == _idSelecionado;
    final Color statusColor = _statusColor(tokens, reserva.status);
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    return Material(
      color: selecionada ? tokens.selectedBackground : tokens.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _carregarDetalhe(reserva.idReserva),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionada ? tokens.selectedBorder : tokens.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      reserva.nomeCliente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _statusBadge(
                    _statusLabel(context, reserva.status),
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDateTime(regionalizacao, reserva.criadaEm),
                style: TextStyle(color: tokens.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: tokens.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${reserva.quantidadeTotal} ${context.t('catalogReservations.items', fallback: 'itens')}',
                    style: TextStyle(color: tokens.secondaryText),
                  ),
                  const Spacer(),
                  Text(
                    regionalizacao.formatCurrency(reserva.valorTotal),
                    style: TextStyle(
                      color: tokens.financialPositive,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(BuildContext context, WebThemeTokens tokens) {
    if (_idSelecionado == null) {
      return _buildEmpty(context, tokens);
    }
    if (_carregandoDetalhe || _detalhe == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: SixBackendLoading.messages(
          title: context.t(
            'catalogReservations.detailLoading',
            fallback: 'Carregando detalhes',
          ),
          subtitle: context.t(
            'catalogReservations.detailLoadingSubtitle',
            fallback: 'Buscando os produtos e dados do cliente.',
          ),
          compact: true,
          leadingIcon: Icons.receipt_long_outlined,
        ),
      );
    }

    final CatalogoReservaDetalheModel detalhe = _detalhe!;
    final LocaleSettingsProvider regionalizacao =
        context.watch<LocaleSettingsProvider>();
    return Container(
      color: tokens.workspaceBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.t(
                          'catalogReservations.detailTitle',
                          fallback: 'Detalhes da reserva',
                        ),
                        style: TextStyle(
                          color: tokens.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${_idReservaCurto(detalhe.idReserva)}',
                        style: TextStyle(color: tokens.mutedText),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: _CatalogoReservaDropdown<CatalogoReservaStatus>(
                    label: context.t(
                      'catalogReservations.status',
                      fallback: 'Status',
                    ),
                    value: detalhe.status,
                    valueLabel: _statusLabel(context, detalhe.status),
                    options: _statusDropdownOptions(context),
                    enabled:
                        !_atualizandoStatus &&
                        !_convertendo &&
                        detalhe.status != CatalogoReservaStatus.convertida,
                    onSelected: _atualizarStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoCard(
              tokens,
              icon: Icons.person_outline_rounded,
              title: detalhe.cliente.nome,
              lines: <String>[
                if (detalhe.cliente.telefone.isNotEmpty)
                  detalhe.cliente.telefone,
                if (detalhe.cliente.email.isNotEmpty) detalhe.cliente.email,
                _formatDateTime(regionalizacao, detalhe.criadaEm),
              ],
            ),
            const SizedBox(height: 18),
            _buildConversionCard(context, tokens, regionalizacao, detalhe),
            const SizedBox(height: 18),
            Text(
              context.t(
                'catalogReservations.products',
                fallback: 'Produtos reservados',
              ),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final CatalogoReservaItemModel item in detalhe.itens)
              _buildItem(context, tokens, regionalizacao, item),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.cardBorder),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '${detalhe.quantidadeTotal} ${context.t('catalogReservations.items', fallback: 'itens')}',
                    style: TextStyle(color: tokens.secondaryText),
                  ),
                  const Spacer(),
                  Text(
                    regionalizacao.formatCurrency(detalhe.valorTotal),
                    style: TextStyle(
                      color: tokens.financialPositive,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.t('catalogReservations.notes', fallback: 'Observação'),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detalhe.observacao.isEmpty
                  ? context.t(
                    'catalogReservations.noNotes',
                    fallback: 'Nenhuma observação informada.',
                  )
                  : detalhe.observacao,
              style: TextStyle(color: tokens.secondaryText, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard(
    BuildContext context,
    WebThemeTokens tokens,
    LocaleSettingsProvider regionalizacao,
    CatalogoReservaDetalheModel detalhe,
  ) {
    final bool convertida = detalhe.status == CatalogoReservaStatus.convertida;
    final bool podeConverter =
        detalhe.status == CatalogoReservaStatus.confirmada;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            convertida
                ? tokens.success.withValues(alpha: 0.08)
                : tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              convertida
                  ? tokens.success.withValues(alpha: 0.35)
                  : tokens.cardBorder,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  convertida
                      ? Icons.check_circle_outline_rounded
                      : Icons.point_of_sale_outlined,
                  color: convertida ? tokens.success : tokens.info,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.t(
                          convertida
                              ? 'catalogReservations.convert.convertedTitle'
                              : 'catalogReservations.convert.title',
                          fallback:
                              convertida
                                  ? 'Venda criada'
                                  : 'Converter em venda',
                        ),
                        style: TextStyle(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        convertida
                            ? '${context.t('catalogReservations.convert.saleId', fallback: 'Venda')} #${_idReservaCurto(detalhe.idOperacaoVenda)}${detalhe.convertidaEm == null ? '' : ' • ${_formatDateTime(regionalizacao, detalhe.convertidaEm)}'}'
                            : context.t(
                              'catalogReservations.convert.description',
                              fallback:
                                  'Valida o estoque e cria uma venda a receber com estes produtos.',
                            ),
                        style: TextStyle(
                          color: tokens.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!convertida)
            FilledButton.icon(
              onPressed:
                  podeConverter && !_convertendo ? _converterEmVenda : null,
              icon:
                  _convertendo
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.point_of_sale_outlined),
              label: Text(
                context.t(
                  _convertendo
                      ? 'catalogReservations.convert.processing'
                      : 'catalogReservations.convert.action',
                  fallback:
                      _convertendo ? 'Convertendo...' : 'Converter em venda',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    WebThemeTokens tokens,
    LocaleSettingsProvider regionalizacao,
    CatalogoReservaItemModel item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item.quantidade}×',
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.nomeProduto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.modeloProduto.isNotEmpty)
                  Text(
                    item.modeloProduto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.mutedText, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            regionalizacao.formatCurrency(item.valorTotal),
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(
    BuildContext context,
    WebThemeTokens tokens,
    CatalogoReservaPaginaModel pagina,
  ) {
    final int paginaExibida = pagina.totalPaginas == 0 ? 0 : pagina.pagina + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed:
                pagina.pagina > 0
                    ? () => _carregar(pagina: pagina.pagina - 1)
                    : null,
            tooltip: context.t(
              'catalogReservations.previous',
              fallback: 'Página anterior',
            ),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              '$paginaExibida / ${pagina.totalPaginas}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed:
                pagina.pagina + 1 < pagina.totalPaginas
                    ? () => _carregar(pagina: pagina.pagina + 1)
                    : null,
            tooltip: context.t(
              'catalogReservations.next',
              fallback: 'Próxima página',
            ),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WebThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: tokens.danger, size: 42),
            const SizedBox(height: 12),
            Text(
              context.t(
                'catalogReservations.error',
                fallback: 'Não foi possível carregar as reservas.',
              ),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _carregar(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                context.t('common.tryAgain', fallback: 'Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineError(BuildContext context, WebThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _carregar(),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Icon(Icons.refresh_rounded, color: tokens.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t(
                      'catalogReservations.error',
                      fallback: 'Não foi possível carregar as reservas.',
                    ),
                    style: TextStyle(color: tokens.danger),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WebThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.inventory_2_outlined, color: tokens.mutedText, size: 44),
            const SizedBox(height: 12),
            Text(
              context.t(
                'catalogReservations.empty',
                fallback: 'Nenhuma reserva encontrada.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    WebThemeTokens tokens, {
    required IconData icon,
    required String title,
    required List<String> lines,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: tokens.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                for (final String line in lines.where(
                  (String item) => item.isNotEmpty,
                ))
                  Text(line, style: TextStyle(color: tokens.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, CatalogoReservaStatus status) {
    return switch (status) {
      CatalogoReservaStatus.recebida => context.t(
        'catalogReservations.status.received',
        fallback: 'Recebida',
      ),
      CatalogoReservaStatus.emAnalise => context.t(
        'catalogReservations.status.analysis',
        fallback: 'Em análise',
      ),
      CatalogoReservaStatus.confirmada => context.t(
        'catalogReservations.status.confirmed',
        fallback: 'Confirmada',
      ),
      CatalogoReservaStatus.cancelada => context.t(
        'catalogReservations.status.cancelled',
        fallback: 'Cancelada',
      ),
      CatalogoReservaStatus.convertida => context.t(
        'catalogReservations.status.converted',
        fallback: 'Convertida em venda',
      ),
    };
  }

  Color _statusColor(WebThemeTokens tokens, CatalogoReservaStatus status) {
    return switch (status) {
      CatalogoReservaStatus.recebida => tokens.info,
      CatalogoReservaStatus.emAnalise => tokens.warning,
      CatalogoReservaStatus.confirmada => tokens.success,
      CatalogoReservaStatus.cancelada => tokens.danger,
      CatalogoReservaStatus.convertida => tokens.financialPositive,
    };
  }

  String _formatDateTime(
    LocaleSettingsProvider regionalizacao,
    DateTime? value,
  ) {
    if (value == null) return '';
    final DateTime local = value.toLocal();
    return '${regionalizacao.formatDate(local)} • ${regionalizacao.formatTime(local)}';
  }

  String _idReservaCurto(String idReserva) {
    return idReserva.length <= 12 ? idReserva : idReserva.substring(0, 12);
  }
}

class _CatalogoReservaDropdownOption<T> {
  const _CatalogoReservaDropdownOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

class _CatalogoReservaDropdown<T> extends StatefulWidget {
  const _CatalogoReservaDropdown({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.options,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final T value;
  final String valueLabel;
  final List<_CatalogoReservaDropdownOption<T>> options;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  State<_CatalogoReservaDropdown<T>> createState() =>
      _CatalogoReservaDropdownState<T>();
}

class _CatalogoReservaDropdownState<T>
    extends State<_CatalogoReservaDropdown<T>> {
  bool _hovered = false;
  bool _open = false;

  Future<void> _openMenu() async {
    if (!widget.enabled || widget.options.isEmpty) return;

    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (fieldBox == null || overlayBox == null) return;

    final Offset fieldOffset = fieldBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size fieldSize = fieldBox.size;
    final WebThemeTokens tokens = WebThemeTokens.of(context);

    setState(() => _open = true);
    final T? selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        fieldOffset.dx,
        fieldOffset.dy + fieldSize.height + 6,
        overlayBox.size.width - fieldOffset.dx - fieldSize.width,
        0,
      ),
      color: tokens.menuBackground,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      items: widget.options
          .map((_CatalogoReservaDropdownOption<T> option) {
            final bool selected = option.value == widget.value;
            final ThemeData theme = Theme.of(context);

            return PopupMenuItem<T>(
              value: option.enabled ? option.value : null,
              enabled: option.enabled,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Opacity(
                opacity: option.enabled ? 1 : 0.55,
                child: Row(
                  children: <Widget>[
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: selected ? tokens.info : tokens.mutedText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.primaryText,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );

    if (!mounted) return;
    setState(() => _open = false);
    if (selected != null && selected != widget.value) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool active = widget.enabled && (_hovered || _open);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      value: widget.valueLabel,
      child: AnimatedOpacity(
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
        opacity: widget.enabled ? 1 : 0.6,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Tooltip(
            message: widget.label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.enabled ? _openMenu : null,
                child: AnimatedContainer(
                  duration: WebThemeTokens.transitionDuration,
                  curve: WebThemeTokens.transitionCurve,
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                  decoration: BoxDecoration(
                    color:
                        active ? tokens.surfaceMuted : tokens.inputBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active ? tokens.selectedBorder : tokens.cardBorder,
                      width: active ? 1.4 : 1,
                    ),
                    boxShadow:
                        active
                            ? <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                            : null,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: tokens.secondaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.valueLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: WebThemeTokens.transitionDuration,
                        curve: WebThemeTokens.transitionCurve,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: active ? tokens.info : tokens.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
