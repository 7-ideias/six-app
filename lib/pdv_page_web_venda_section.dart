part of 'pagina_principal_web.dart';

bool acionarPdvFrenteCaixaPeloElemento(Element element) {
  if (element is StatefulElement && element.state is _PaginaPrincipalWebState) {
    (element.state as _PaginaPrincipalWebState)._iniciarVenda();
    return true;
  }

  return false;
}

extension _PdvPageWebVendaSection on _PaginaPrincipalWebState {
  bool get _vendaPossuiItens => _produtosSelecionados.isNotEmpty;

  bool get _clienteSelecionadoNaVenda {
    return _clienteIdentificado != null ||
        _clienteIdentificadoController.text.trim().isNotEmpty;
  }

  Future<void> _abrirVendasAReceberWeb() async {
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
            width: size.width * 0.90,
            height: size.height * 0.86,
            child: const VendasAReceberWebWidget(),
          ),
        );
      },
    );

    if (mounted && _moduloAtual == ModuloCentralPDV.vendas) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focarCodigoBarras();
      });
    }
  }

  Widget _buildCabecalhoVendaCompacto() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool expandido = _modoExpandidoFrenteCaixa;
    final bool temPagamentoConfirmado = _temPagamentoConfirmado();
    final bool pagamentoCompleto = _pagamentoConfirmadoCompleto();
    final bool pagamentoPrecisaRevisao = _pagamentoConfirmadoPrecisaRevisao();
    final bool clienteNaoInformado =
        _vendaPossuiItens && !_clienteSelecionadoNaVenda;
    final Duration transicaoAcoes =
        _prefereReducaoDeMovimento
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 160);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      l10n?.pdvWebTitle ?? 'Frente de caixa',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: _pdvTheme.primaryText,
                      ),
                    ),
                    _buildAtalhoPdvChip(
                      icon: Icons.point_of_sale_outlined,
                      label: l10n?.pdvWebSessionActive ?? 'Sessão ativa',
                    ),
                    if (_vendaPossuiItens)
                      _buildStatusChip(
                        label: l10n?.pdvWebStatusInProgress ?? 'Em andamento',
                        icon: Icons.play_circle_outline_rounded,
                        foregroundColor: _pdvTheme.successColor,
                        backgroundColor: _pdvTheme.successColor.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    if (clienteNaoInformado)
                      _buildStatusChip(
                        label:
                            l10n?.pdvWebCustomerNotInformedStatus ??
                            'Cliente não informado',
                        icon: Icons.person_off_outlined,
                        foregroundColor: _pdvTheme.warningColor,
                        backgroundColor: _pdvTheme.warningColor.withValues(
                          alpha: 0.15,
                        ),
                      )
                    else if (_vendaPossuiItens && _clienteSelecionadoNaVenda)
                      _buildStatusChip(
                        label:
                            l10n?.pdvWebCustomerIdentifiedStatus ??
                            'Cliente identificado',
                        icon: Icons.person_outline_rounded,
                        foregroundColor: _pdvTheme.iconColor,
                        backgroundColor: _pdvTheme.iconColor.withValues(
                          alpha: 0.11,
                        ),
                      ),
                    if (temPagamentoConfirmado)
                      _buildChipStatusPagamento(
                        l10n: l10n,
                        pagamentoCompleto: pagamentoCompleto,
                        pagamentoPrecisaRevisao: pagamentoPrecisaRevisao,
                      ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: transicaoAcoes,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        axisAlignment: -1,
                        child: child,
                      ),
                    );
                  },
                  child:
                      _atalhosContextuaisDisponiveis
                          ? Padding(
                            key: const ValueKey<String>('on-wrap'),
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildAtalhosContextuaisCabecalho(l10n),
                          )
                          : const SizedBox.shrink(key: ValueKey<String>('off')),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            children: <Widget>[
              Tooltip(
                message:
                    expandido
                        ? (l10n?.pdvWebExitExpandedModeAction ??
                            'Sair do modo expandido')
                        : (l10n?.pdvWebExpandModeAction ??
                            'Expandir frente de caixa'),
                child: Semantics(
                  button: true,
                  label:
                      expandido
                          ? (l10n?.pdvWebExitExpandedModeAction ??
                              'Sair do modo expandido')
                          : (l10n?.pdvWebExpandModeAction ??
                              'Expandir frente de caixa'),
                  child: IconButton(
                    onPressed: _alternarModoExpandidoFrenteCaixa,
                    constraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 42,
                    ),
                    icon: Icon(
                      expandido ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: _pdvTheme.iconColor,
                    ),
                  ),
                ),
              ),
              Tooltip(
                message:
                    l10n?.pdvWebCloseFrontDeskAction ??
                    'Fechar frente de caixa',
                child: Semantics(
                  button: true,
                  label:
                      l10n?.pdvWebCloseFrontDeskAction ??
                      'Fechar frente de caixa',
                  child: IconButton(
                    onPressed: _confirmarFecharFrenteCaixa,
                    constraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 42,
                    ),
                    icon: Icon(Icons.close, color: _pdvTheme.iconColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAtalhosContextuaisCabecalho(AppLocalizations? l10n) {
    return Wrap(
      key: const ValueKey<String>('on'),
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _buildAtalhoPdvChip(
          icon: Icons.keyboard_command_key_rounded,
          label: l10n?.pdvWebAvailableShortcutsLabel ?? 'Atalhos disponíveis',
        ),
        _buildAtalhoPdvChip(
          icon: Icons.search_rounded,
          label: 'F2 ${l10n?.pdvWebSearchItemAction ?? 'Buscar item'}',
        ),
        _buildAtalhoPdvChip(
          icon: Icons.person_search_rounded,
          label:
              'F4 ${l10n?.pdvWebIdentifyCustomerAction ?? 'Identificar cliente'}',
        ),
        _buildAtalhoPdvChip(
          icon: Icons.payments_outlined,
          label: 'F8 ${l10n?.pdvWebReceiveAction ?? 'Receber'}',
        ),
        _buildAtalhoPdvChip(
          icon: Icons.delete_sweep_outlined,
          label: 'ESC ${l10n?.pdvWebClearSaleAction ?? 'Limpar venda'}',
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required IconData icon,
    required Color foregroundColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtalhoPdvChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundPage,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: _pdvTheme.iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _pdvTheme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeituraBuscaItem() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final Duration transicaoAcoes =
        _prefereReducaoDeMovimento
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 160);

    return FocusTraversalGroup(
      child: FocusScope(
        node: _barcodeInteractionFocusScopeNode,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _pdvTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _pdvTheme.cardBorder),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 980;

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildCampoLeitura(l10n),
                    AnimatedSwitcher(
                      duration: transicaoAcoes,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: child,
                          ),
                        );
                      },
                      child:
                          _atalhosContextuaisDisponiveis
                              ? Padding(
                                key: const ValueKey<String>('on'),
                                padding: const EdgeInsets.only(top: 10),
                                child: _buildAcoesOperacionaisCodigoBarras(
                                  l10n,
                                  compact: true,
                                ),
                              )
                              : const SizedBox.shrink(
                                key: ValueKey<String>('off'),
                              ),
                    ),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: _buildCampoLeitura(l10n)),
                  AnimatedSwitcher(
                    duration: transicaoAcoes,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axis: Axis.horizontal,
                          axisAlignment: -1,
                          child: child,
                        ),
                      );
                    },
                    child:
                        _atalhosContextuaisDisponiveis
                            ? Padding(
                              key: const ValueKey<String>('on'),
                              padding: const EdgeInsets.only(left: 10),
                              child: _buildAcoesOperacionaisCodigoBarras(
                                l10n,
                                compact: false,
                              ),
                            )
                            : const SizedBox.shrink(
                              key: ValueKey<String>('off'),
                            ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAcoesOperacionaisCodigoBarras(
    AppLocalizations? l10n, {
    required bool compact,
  }) {
    if (compact) {
      return Row(
        children: <Widget>[
          Expanded(
            child: _buildBotaoAcaoCodigoBarras(
              tooltip: l10n?.pdvWebSearchItemAction ?? 'Buscar item',
              icon: Icons.search_rounded,
              label: l10n?.pdvWebSearchItemAction ?? 'Buscar item',
              onPressed: _abrirSelecaoProdutoWeb,
            ),
          ),
          if (_vendaPossuiItens) ...<Widget>[
            const SizedBox(width: 8),
            Expanded(
              child: _buildBotaoAcaoCodigoBarras(
                tooltip:
                    l10n?.pdvWebIdentifyCustomerAction ?? 'Identificar cliente',
                icon: Icons.person_add_alt_1_outlined,
                label:
                    l10n?.pdvWebIdentifyCustomerAction ?? 'Identificar cliente',
                onPressed: _abrirDialogClienteRapido,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 52,
          child: _buildBotaoAcaoCodigoBarras(
            tooltip: l10n?.pdvWebSearchItemAction ?? 'Buscar item',
            icon: Icons.search_rounded,
            label: l10n?.pdvWebSearchItemAction ?? 'Buscar item',
            onPressed: _abrirSelecaoProdutoWeb,
          ),
        ),
        if (_vendaPossuiItens) ...<Widget>[
          const SizedBox(width: 8),
          SizedBox(
            height: 52,
            child: _buildBotaoAcaoCodigoBarras(
              tooltip:
                  l10n?.pdvWebIdentifyCustomerAction ?? 'Identificar cliente',
              icon: Icons.person_add_alt_1_outlined,
              label:
                  l10n?.pdvWebIdentifyCustomerAction ?? 'Identificar cliente',
              onPressed: _abrirDialogClienteRapido,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBotaoAcaoCodigoBarras({
    required String tooltip,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: label,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  Widget _buildCampoLeitura(AppLocalizations? l10n) {
    return TextField(
      controller: _codigoBarrasController,
      focusNode: _codigoBarrasFocusNode,
      autofocus: true,
      decoration: InputDecoration(
        isDense: true,
        hintText:
            l10n?.pdvWebReadOrSearchToStartMessage ??
            'Leia um código de barras ou busque um produto para iniciar a venda.',
        labelText: l10n?.pdvWebBarcodeFieldLabel ?? 'Código de barras',
        prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
        suffixIcon: IconButton(
          tooltip: l10n?.pdvWebFocusBarcodeFieldAction ?? 'Focar leitura',
          onPressed: _focarCodigoBarras,
          icon: const Icon(Icons.keyboard_alt_outlined),
        ),
        filled: true,
        fillColor: _pdvTheme.backgroundPage,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _pdvTheme.cardBorder),
        ),
      ),
    );
  }

  Widget _buildHeaderTabelaItens() {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundPage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          _buildHeaderCell(l10n?.pdvWebTableHeaderItem ?? 'Item', flex: 6),
          _buildHeaderCell(
            l10n?.pdvWebTableHeaderQuantity ?? 'Qtd',
            flex: 3,
            alignEnd: true,
          ),
          _buildHeaderCell(
            l10n?.pdvWebTableHeaderUnitPrice ?? 'Unitário',
            flex: 2,
            alignEnd: true,
          ),
          _buildHeaderCell(
            l10n?.pdvWebTableHeaderSubtotal ?? 'Subtotal',
            flex: 2,
            alignEnd: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label, {
    required int flex,
    bool alignEnd = false,
  }) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _pdvTheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildLinhaTabelaItem(Map<String, dynamic> produto, int index) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final int quantidade = (produto['quantidade'] ?? 1) as int;
    final double preco = ((produto['preco'] ?? 0) as num).toDouble();
    final double subtotal = _calcularSubtotal(produto);
    final bool ehServico = _ehServicoItem(produto);
    final String itemKey = _itemVisualKey(produto);
    final _PdvItemVisualFeedback? feedback = _itemVisualFeedbackForKey(itemKey);
    final Color baseColor =
        index.isEven ? _pdvTheme.backgroundSurface : _pdvTheme.backgroundPage;
    final Color rowColor =
        feedback == null
            ? baseColor
            : Color.alphaBlend(
              _itemFeedbackHighlightColor(feedback),
              baseColor,
            );
    final Duration transicaoCorLinha =
        _prefereReducaoDeMovimento
            ? Duration.zero
            : const Duration(milliseconds: 180);

    return ZebraListItem(
      index: index,
      child: AnimatedContainer(
        key: _itemRowKey(itemKey),
        duration: transicaoCorLinha,
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _pdvTheme.cardBorder),
          color: rowColor,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _pdvTheme.iconColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      ehServico
                          ? Icons.design_services_outlined
                          : Icons.inventory_2_outlined,
                      color: _pdvTheme.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          produto['nome']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _pdvTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ehServico ? (l10n?.pdvWebItemTypeService ?? 'Serviço') : (l10n?.pdvWebItemTypeProduct ?? 'Produto')} • ${l10n?.pdvWebCodeLabel ?? 'Código'}: ${produto['codigo']?.toString().isNotEmpty == true ? produto['codigo'] : '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _pdvTheme.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildBotaoQuantidadeItem(
                      tooltip:
                          l10n?.pdvWebDecreaseQuantityAction ??
                          'Diminuir quantidade',
                      semanticLabel:
                          l10n?.pdvWebDecreaseQuantityAction ??
                          'Diminuir quantidade',
                      icon: Icons.remove_circle_outline,
                      onPressed: () => _alterarQuantidade(produto, -1),
                      foregroundColor: _pdvTheme.iconColor,
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        quantidade.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _pdvTheme.primaryText,
                        ),
                      ),
                    ),
                    _buildBotaoQuantidadeItem(
                      tooltip:
                          l10n?.pdvWebIncreaseQuantityAction ??
                          'Aumentar quantidade',
                      semanticLabel:
                          l10n?.pdvWebIncreaseQuantityAction ??
                          'Aumentar quantidade',
                      icon: Icons.add_circle_outline,
                      onPressed: () => _alterarQuantidade(produto, 1),
                      foregroundColor: _pdvTheme.iconColor,
                    ),
                    const SizedBox(width: 2),
                    _buildBotaoQuantidadeItem(
                      tooltip: l10n?.pdvWebRemoveItemAction ?? 'Remover item',
                      semanticLabel:
                          l10n?.pdvWebRemoveItemAction ?? 'Remover item',
                      icon: Icons.delete_outline_rounded,
                      onPressed: () => _removerProduto(produto),
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatCurrency(preco),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _pdvTheme.primaryText,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatCurrency(subtotal),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _pdvTheme.iconColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoQuantidadeItem({
    required String tooltip,
    required String semanticLabel,
    required IconData icon,
    required VoidCallback onPressed,
    required Color foregroundColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          splashRadius: 20,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          style: IconButton.styleFrom(
            foregroundColor: foregroundColor,
            hoverColor: foregroundColor.withValues(alpha: 0.12),
            focusColor: foregroundColor.withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVazioItens() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _pdvTheme.backgroundPage,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _pdvTheme.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.shopping_cart_outlined,
              color: _pdvTheme.iconColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.pdvWebNoItemsAddedTitle ?? 'Nenhum item adicionado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _pdvTheme.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n?.pdvWebReadOrSearchToStartMessage ??
                  'Leia um código de barras ou busque um produto para iniciar a venda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _pdvTheme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoItensVenda() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final int quantidadeItens = _calcularQuantidadeItens();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n?.pdvWebItemsSectionTitle ?? 'Itens da venda',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _pdvTheme.primaryText,
                  ),
                ),
              ),
              if (quantidadeItens > 0)
                _buildAtalhoPdvChip(
                  icon: Icons.shopping_basket_outlined,
                  label:
                      '${quantidadeItens.toString()} ${l10n?.pdvWebItemsCounterLabel ?? 'itens'}',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                _produtosSelecionados.isEmpty
                    ? _buildEstadoVazioItens()
                    : Column(
                      children: <Widget>[
                        _buildHeaderTabelaItens(),
                        const SizedBox(height: 2),
                        Expanded(
                          child: ListView.builder(
                            controller: _gradeItensScrollController,
                            primary: false,
                            itemCount: _produtosSelecionados.length,
                            itemBuilder: (BuildContext context, int index) {
                              return _buildLinhaTabelaItem(
                                _produtosSelecionados[index],
                                index,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoVendaLateral() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final double total = _calcularTotal();
    final String cliente =
        _clienteSelecionadoNaVenda
            ? _clienteAtualLabel()
            : (l10n?.pdvWebIdentifyCustomerAction ?? 'Identificar cliente');
    final List<FormaPagamentoSelecionada> formasPagamento =
        _formasPagamentoConfirmadas
            .where((FormaPagamentoSelecionada forma) => forma.valor > 0)
            .toList(growable: false);
    final bool temPagamentoConfirmado = formasPagamento.isNotEmpty;
    final bool pagamentoCompleto = _pagamentoConfirmadoCompleto();
    final bool pagamentoPrecisaRevisao = _pagamentoConfirmadoPrecisaRevisao();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: SingleChildScrollView(
        controller: _resumoVendaScrollController,
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n?.pdvWebCurrentSaleTitle ?? 'Venda atual',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _pdvTheme.primaryText,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _pdvTheme.successColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n?.pdvWebStatusInProgress ?? 'Em andamento',
                        style: TextStyle(
                          color: _pdvTheme.successColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (temPagamentoConfirmado)
                      _buildChipStatusPagamento(
                        l10n: l10n,
                        pagamentoCompleto: pagamentoCompleto,
                        pagamentoPrecisaRevisao: pagamentoPrecisaRevisao,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_clienteSelecionadoNaVenda)
              _buildResumoInfoTile(
                icon: Icons.person_outline_rounded,
                label: l10n?.pdvWebCustomerLabel ?? 'Cliente',
                value: cliente,
              )
            else
              OutlinedButton.icon(
                onPressed: _abrirDialogClienteRapido,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(
                  l10n?.pdvWebIdentifyCustomerAction ?? 'Identificar cliente',
                ),
              ),
            const SizedBox(height: 10),
            if (temPagamentoConfirmado)
              _buildSecaoPagamentoConfirmado(
                l10n: l10n,
                formasPagamento: formasPagamento,
              )
            else
              OutlinedButton.icon(
                onPressed: _abrirTelaRecebimento,
                icon: const Icon(Icons.payments_outlined),
                label: Text(
                  l10n?.pdvWebDefinePaymentAction ?? 'Definir pagamento',
                ),
              ),
            const SizedBox(height: 12),
            Divider(color: _pdvTheme.cardBorder, height: 1),
            const SizedBox(height: 12),
            _buildResumoLinhaValor(
              l10n?.pdvWebSubtotalLabel ?? 'Subtotal',
              _formatCurrency(total),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pdvTheme.iconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n?.pdvWebTotalLabel ?? 'Total',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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

  Widget _buildChipStatusPagamento({
    required AppLocalizations? l10n,
    required bool pagamentoCompleto,
    required bool pagamentoPrecisaRevisao,
  }) {
    final Color textoCor;
    final Color fundoCor;
    final String label;

    if (pagamentoCompleto) {
      textoCor = _pdvTheme.successColor;
      fundoCor = _pdvTheme.successColor.withValues(alpha: 0.12);
      label = l10n?.pdvWebPaymentDefinedLabel ?? 'Pagamento definido';
    } else if (pagamentoPrecisaRevisao) {
      textoCor = _pdvTheme.warningColor;
      fundoCor = _pdvTheme.warningColor.withValues(alpha: 0.14);
      label = l10n?.pdvWebReviewPaymentAction ?? 'Revisar pagamento';
    } else {
      textoCor = _pdvTheme.secondaryText;
      fundoCor = _pdvTheme.backgroundPage;
      label = l10n?.pdvWebPaymentIncompleteLabel ?? 'Pagamento incompleto';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fundoCor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: textoCor, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildSecaoPagamentoConfirmado({
    required AppLocalizations? l10n,
    required List<FormaPagamentoSelecionada> formasPagamento,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundPage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n?.pdvWebPaymentMethodsTitle ?? 'Formas de recebimento',
                  style: TextStyle(
                    color: _pdvTheme.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _editarPagamentoConfirmado,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                  l10n?.pdvWebEditPaymentAction ?? 'Editar pagamento',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final FormaPagamentoSelecionada forma in formasPagamento)
            _buildResumoLinhaValor(
              _rotuloFormaPagamento(forma),
              _formatCurrency(forma.valor),
            ),
          const SizedBox(height: 4),
          Divider(color: _pdvTheme.cardBorder, height: 1),
          const SizedBox(height: 8),
          _buildResumoLinhaValor(
            l10n?.pdvWebReceivedTotalLabel ?? 'Total recebido',
            _formatCurrency(_totalPagamentoConfirmado()),
          ),
          _buildResumoLinhaValor(
            l10n?.pdvWebRemainingAmountLabel ?? 'Valor restante',
            _formatCurrency(_restantePagamentoConfirmado()),
          ),
          if (_pagamentoConfirmadoPrecisaRevisao()) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              l10n?.pdvWebPaymentNeedsReviewHint ??
                  'Revise a distribuição para fechar o total da venda.',
              style: TextStyle(
                color: _pdvTheme.warningColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _rotuloFormaPagamento(FormaPagamentoSelecionada forma) {
    final String codigo = forma.codigo.trim().toUpperCase();
    final String? descricao = _descricoesFormaPagamentoPorCodigo[codigo];
    if (descricao != null && descricao.trim().isNotEmpty) {
      return descricao.trim();
    }
    return codigo;
  }

  Widget _buildResumoInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _pdvTheme.iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _pdvTheme.iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _pdvTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _pdvTheme.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoLinhaValor(String label, String valor) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _pdvTheme.secondaryText,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _pdvTheme.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildBarraFechamento(double total) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool temItens = _vendaPossuiItens;
    final bool podeLimpar = _vendaTemDadosTemporariosPreenchidos();
    final bool pagamentoDefinido = _temPagamentoConfirmado();
    final bool pagamentoCompleto = _pagamentoConfirmadoCompleto();
    final bool pagamentoPrecisaRevisao = _pagamentoConfirmadoPrecisaRevisao();

    final String labelAcaoPrincipal;
    if (!temItens) {
      labelAcaoPrincipal = l10n?.pdvWebReceiveAction ?? 'Receber';
    } else if (pagamentoPrecisaRevisao) {
      labelAcaoPrincipal =
          '${l10n?.pdvWebReviewPaymentAction ?? 'Revisar pagamento'} — ${_formatCurrency(total)}';
    } else if (pagamentoCompleto) {
      labelAcaoPrincipal =
          '${l10n?.pdvWebConfirmReceiveAction ?? 'Confirmar recebimento'} — ${_formatCurrency(total)}';
    } else if (pagamentoDefinido) {
      labelAcaoPrincipal =
          '${l10n?.pdvWebEditPaymentAction ?? 'Editar pagamento'} — ${_formatCurrency(total)}';
    } else {
      labelAcaoPrincipal =
          '${l10n?.pdvWebReceiveAction ?? 'Receber'} — ${_formatCurrency(total)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          temItens
              ? Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    _formatCurrency(total),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _pdvTheme.iconColor,
                    ),
                  ),
                  _buildAtalhoPdvChip(
                    icon: Icons.shopping_bag_outlined,
                    label:
                        '${_calcularQuantidadeItens()} ${l10n?.pdvWebItemsCounterLabel ?? 'itens'}',
                  ),
                  _buildAtalhoPdvChip(
                    icon: Icons.payments_outlined,
                    label: l10n?.pdvWebSubtotalLabel ?? 'Subtotal',
                  ),
                  if (pagamentoDefinido)
                    _buildAtalhoPdvChip(
                      icon:
                          pagamentoCompleto
                              ? Icons.verified_outlined
                              : Icons.warning_amber_rounded,
                      label:
                          pagamentoCompleto
                              ? (l10n?.pdvWebPaymentDefinedLabel ??
                                  'Pagamento definido')
                              : (l10n?.pdvWebReviewPaymentAction ??
                                  'Revisar pagamento'),
                    ),
                ],
              )
              : Text(
                l10n?.pdvWebReadyToStartSaleHint ??
                    'Leia um item para iniciar uma nova venda.',
                style: TextStyle(
                  color: _pdvTheme.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed:
                    temItens && !_registrandoReceberDepois
                        ? _pausarVenda
                        : null,
                icon:
                    _registrandoReceberDepois
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.schedule_send_outlined),
                label: Text(
                  _registrandoReceberDepois
                      ? (l10n?.pdvWebRegisteringAction ?? 'Registrando...')
                      : (l10n?.pdvWebReceiveLaterAction ?? 'Receber depois'),
                ),
              ),
              FilledButton.icon(
                onPressed: temItens ? _acionarRecebimentoPrincipal : null,
                icon: const Icon(Icons.payments_rounded),
                label: Text(labelAcaoPrincipal),
              ),
              OutlinedButton.icon(
                onPressed: _abrirVendasAReceberWeb,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(
                  l10n?.pdvWebSalesToReceiveAction ?? 'Vendas a receber',
                ),
              ),
              if (podeLimpar)
                OutlinedButton.icon(
                  onPressed: _confirmarLimparVendaAtual,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(l10n?.pdvWebClearSaleAction ?? 'Limpar venda'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _pdvTheme.warningColor,
                    side: BorderSide(color: _pdvTheme.warningColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaVenda(double total) {
    return Expanded(
      child: Focus(
        autofocus: true,
        focusNode: _atalhosFocusNode,
        onKeyEvent: _handleAtalhoPdv,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compactWidth = constraints.maxWidth < 1220;
            final bool exibirResumo = _vendaPossuiItens;

            return Column(
              children: <Widget>[
                _buildCabecalhoVendaCompacto(),
                const SizedBox(height: 10),
                _buildLeituraBuscaItem(),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      exibirResumo
                          ? (compactWidth
                              ? Column(
                                children: <Widget>[
                                  Expanded(child: _buildSecaoItensVenda()),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: (constraints.maxHeight * 0.34)
                                        .clamp(220.0, 320.0),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      child: _buildResumoVendaLateral(),
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(
                                    flex: 74,
                                    child: _buildSecaoItensVenda(),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 26,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      child: _buildResumoVendaLateral(),
                                    ),
                                  ),
                                ],
                              ))
                          : _buildSecaoItensVenda(),
                ),
                const SizedBox(height: 10),
                _buildBarraFechamento(total),
              ],
            );
          },
        ),
      ),
    );
  }
}
