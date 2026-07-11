part of 'pdv_page_web.dart';

bool acionarPdvFrenteCaixaPeloElemento(Element element) {
  if (element is StatefulElement && element.state is _PDVWebState) {
    (element.state as _PDVWebState)._iniciarVenda();
    return true;
  }

  return false;
}

extension _PdvPageWebVendaSection on _PDVWebState {
  Future<void> _abrirVendasAReceberWeb() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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

  Widget _buildVendaHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            _pdvTheme.highlightColor.withValues(alpha: 0.10),
            _pdvTheme.backgroundSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _pdvTheme.iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.point_of_sale_rounded, size: 32, color: _pdvTheme.iconColor),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Frente de caixa',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _pdvTheme.primaryText),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cockpit operacional para atendimento rápido, leitura de itens, recebimentos e vendas em aberto.',
                  style: TextStyle(fontSize: 14, height: 1.40, color: _pdvTheme.secondaryText),
                ),
              ],
            ),
          ),
          _buildTopBadge('F2 Buscar item', Icons.search_rounded),
          _buildTopBadge('F4 Identificar cliente', Icons.person_search_rounded),
          _buildTopBadge('F8 Receber', Icons.payments_rounded),
          _buildTopBadge('ESC Cancelar', Icons.close_rounded),
          FilledButton.icon(
            onPressed: _abrirVendasAReceberWeb,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Vendas a receber'),
            style: FilledButton.styleFrom(
              backgroundColor: _pdvTheme.actionButtonBackground,
              foregroundColor: _pdvTheme.actionButtonForeground,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: _pdvTheme.iconColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: _pdvTheme.primaryText)),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required String label, required String value, bool destaque = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: destaque ? _pdvTheme.iconColor : _pdvTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: destaque ? _pdvTheme.iconColor : _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[BoxShadow(color: _pdvTheme.cardShadow, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: destaque ? Colors.white.withValues(alpha: 0.18) : _pdvTheme.iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: destaque ? Colors.white : _pdvTheme.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: destaque ? Colors.white.withValues(alpha: 0.85) : _pdvTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: destaque ? Colors.white : _pdvTheme.primaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraOperacional() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[BoxShadow(color: _pdvTheme.cardShadow, blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Faixa operacional',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _pdvTheme.primaryText),
                ),
              ),
              Text('Foco: velocidade, clareza e fechamento seguro', style: TextStyle(color: _pdvTheme.secondaryText, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _pdvTheme.backgroundPage,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _pdvTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Leitura / busca de item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _pdvTheme.secondaryText)),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _codigoBarrasController,
                              focusNode: _codigoBarrasFocusNode,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Passe um item ou digite um código',
                                labelText: 'Código de barras',
                                prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                                suffixIcon: IconButton(tooltip: 'Focar leitura', onPressed: _focarCodigoBarras, icon: const Icon(Icons.keyboard_alt_outlined)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: _pdvTheme.cardBorder)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            height: 58,
                            child: OutlinedButton.icon(
                              onPressed: _abrirSelecaoProdutoWeb,
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Buscar item'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _pdvTheme.actionButtonBackground, width: 1.6),
                                foregroundColor: _pdvTheme.actionButtonBackground,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  children: <Widget>[
                    Row(children: <Widget>[
                      Expanded(child: _buildMetricCard(icon: Icons.shopping_bag_outlined, label: 'Itens', value: _itensTotalController.text, destaque: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard(icon: Icons.person_outline_rounded, label: 'Cliente', value: _clienteAtualLabel())),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: <Widget>[
                      Expanded(child: _buildMetricCard(icon: Icons.point_of_sale_outlined, label: 'Caixa / sessão', value: 'Sessão ativa')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard(icon: Icons.payments_outlined, label: 'Total parcial', value: _formatCurrency(_calcularTotal()))),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTabelaItens() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: _pdvTheme.backgroundPage, borderRadius: BorderRadius.circular(16), border: Border.all(color: _pdvTheme.cardBorder)),
      child: Row(
        children: <Widget>[
          _buildHeaderCell('Item', flex: 5),
          _buildHeaderCell('Qtd', flex: 2, alignEnd: true),
          _buildHeaderCell('Unitário', flex: 2, alignEnd: true),
          _buildHeaderCell('Subtotal', flex: 2, alignEnd: true),
          _buildHeaderCell('Ações', flex: 2, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex, bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(label, style: TextStyle(fontSize: 12, letterSpacing: 0.4, fontWeight: FontWeight.w800, color: _pdvTheme.secondaryText)),
      ),
    );
  }

  Widget _buildLinhaTabelaItem(Map<String, dynamic> produto, int index) {
    final int quantidade = (produto['quantidade'] ?? 1) as int;
    final double preco = ((produto['preco'] ?? 0) as num).toDouble();
    final double subtotal = _calcularSubtotal(produto);

    return ZebraListItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _pdvTheme.cardBorder),
          color: index.isEven ? _pdvTheme.backgroundSurface : _pdvTheme.backgroundPage,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: _pdvTheme.iconColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
                    child: Icon(_ehServicoItem(produto) ? Icons.design_services_outlined : Icons.inventory_2_outlined, color: _pdvTheme.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(produto['nome']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _pdvTheme.primaryText)),
                        const SizedBox(height: 4),
                        Text('${_ehServicoItem(produto) ? 'Serviço' : 'Produto'} • Código: ${produto['codigo']?.toString().isNotEmpty == true ? produto['codigo'] : '-'}', style: TextStyle(fontSize: 12, color: _pdvTheme.secondaryText, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(quantidade.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _pdvTheme.primaryText)))),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(_formatCurrency(preco), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _pdvTheme.primaryText)))),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(_formatCurrency(subtotal), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _pdvTheme.iconColor)))),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(spacing: 4, children: <Widget>[
                  IconButton(tooltip: 'Diminuir', onPressed: () => _alterarQuantidade(produto, -1), icon: const Icon(Icons.remove_circle_outline)),
                  IconButton(tooltip: 'Aumentar', onPressed: () => _alterarQuantidade(produto, 1), icon: const Icon(Icons.add_circle_outline)),
                  IconButton(tooltip: 'Remover', onPressed: () => _removerProduto(produto), icon: Icon(Icons.delete_outline_rounded, color: _pdvTheme.warningColor)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVazioGuiado() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget content = Container(
          constraints: const BoxConstraints(maxWidth: 760),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: _pdvTheme.backgroundPage, borderRadius: BorderRadius.circular(28), border: Border.all(color: _pdvTheme.cardBorder)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(color: _pdvTheme.iconColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(28)),
                child: Icon(Icons.shopping_cart_checkout_rounded, size: 46, color: _pdvTheme.iconColor),
              ),
              const SizedBox(height: 20),
              Text('Passe um item ou pesquise produto/serviço', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _pdvTheme.primaryText)),
              const SizedBox(height: 10),
              Text('Quando a venda começar, esta área vira a grade operacional dos itens. Você também pode consultar vendas já registradas para receber depois.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: _pdvTheme.secondaryText)),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  _buildQuickActionButton(icon: Icons.search_rounded, label: 'Buscar item', onPressed: _abrirSelecaoProdutoWeb),
                  _buildQuickActionButton(icon: Icons.person_add_alt_1_rounded, label: 'Identificar cliente', onPressed: _abrirDialogClienteRapido),
                  _buildQuickActionButton(icon: Icons.build_circle_outlined, label: 'Adicionar serviço', onPressed: _adicionarServicoRapido),
                  _buildQuickActionButton(icon: Icons.receipt_long_outlined, label: 'Vendas a receber', onPressed: _abrirVendasAReceberWeb),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: <Widget>[
                _buildHintChip('F2 buscar produto'),
                _buildHintChip('F4 identificar cliente'),
                _buildHintChip('F8 receber'),
                _buildHintChip('ESC cancelar venda'),
              ]),
            ],
          ),
        );

        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
          child: SingleChildScrollView(primary: false, child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: Center(child: content))),
        );
      },
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _pdvTheme.actionButtonBackground,
        side: BorderSide(color: _pdvTheme.actionButtonBackground),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildHintChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: _pdvTheme.backgroundSurface, borderRadius: BorderRadius.circular(999), border: Border.all(color: _pdvTheme.cardBorder)),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: _pdvTheme.secondaryText)),
    );
  }

  Widget _buildGradeOperacional() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _pdvTheme.cardBackground, borderRadius: BorderRadius.circular(24), border: Border.all(color: _pdvTheme.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text('Itens da venda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _pdvTheme.primaryText)),
                const SizedBox(height: 4),
                Text('Formato operacional com leitura rápida de item, quantidade, preço e subtotal.', style: TextStyle(fontSize: 13, color: _pdvTheme.secondaryText)),
              ]),
            ),
            _buildTopBadge('${_calcularQuantidadeItens()} item(ns)', Icons.shopping_basket_outlined),
          ]),
          const SizedBox(height: 18),
          Expanded(
            child: _produtosSelecionados.isEmpty
                ? _buildEstadoVazioGuiado()
                : Column(children: <Widget>[
                    _buildHeaderTabelaItens(),
                    const SizedBox(height: 2),
                    Expanded(
                      child: ListView.builder(
                        controller: _gradeItensScrollController,
                        primary: false,
                        itemCount: _produtosSelecionados.length,
                        itemBuilder: (BuildContext context, int index) => _buildLinhaTabelaItem(_produtosSelecionados[index], index),
                      ),
                    ),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoVendaLateral() {
    final double total = _calcularTotal();
    final int quantidadeItens = _calcularQuantidadeItens();

    Widget buildResumoHeader() {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _pdvTheme.cardBorder))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: Text('Venda atual', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _pdvTheme.primaryText))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _pdvTheme.successColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
              child: Text('Em andamento', style: TextStyle(color: _pdvTheme.successColor, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 16),
          _buildResumoInfoTile(Icons.person_outline_rounded, 'Cliente', _clienteAtualLabel()),
          const SizedBox(height: 10),
          _buildResumoInfoTile(Icons.receipt_long_outlined, 'Itens', '$quantidadeItens item(ns)'),
          const SizedBox(height: 10),
          _buildResumoInfoTile(Icons.payments_outlined, 'Pagamento', _formasSelecionadas.isEmpty ? 'Não definido' : _formasSelecionadas.join(', ')),
        ]),
      );
    }

    Widget buildResumoConteudo() {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text('Resumo rápido', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _pdvTheme.secondaryText)),
          const SizedBox(height: 12),
          if (_produtosSelecionados.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _pdvTheme.backgroundPage, borderRadius: BorderRadius.circular(18), border: Border.all(color: _pdvTheme.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text('Nenhum item adicionado ainda.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _pdvTheme.primaryText)),
                const SizedBox(height: 10),
                Text('Use o painel como atalho operacional ou consulte vendas a receber.', style: TextStyle(fontSize: 13, height: 1.40, color: _pdvTheme.secondaryText)),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                  _buildMiniAction('Trocar cliente', Icons.person_search_rounded, _abrirDialogClienteRapido),
                  _buildMiniAction('Buscar item', Icons.search_rounded, _abrirSelecaoProdutoWeb),
                  _buildMiniAction('Vendas a receber', Icons.receipt_long_outlined, _abrirVendasAReceberWeb),
                ]),
              ]),
            )
          else
            ..._produtosSelecionados.map((Map<String, dynamic> produto) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _pdvTheme.backgroundPage, borderRadius: BorderRadius.circular(16), border: Border.all(color: _pdvTheme.cardBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(produto['nome']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: _pdvTheme.primaryText)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    Expanded(child: Text('${produto['quantidade']} x ${_formatCurrency(((produto['preco'] ?? 0) as num).toDouble())}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _pdvTheme.secondaryText, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Text(_formatCurrency(_calcularSubtotal(produto)), style: TextStyle(color: _pdvTheme.primaryText, fontWeight: FontWeight.w900)),
                  ]),
                ]),
              );
            }),
        ]),
      );
    }

    Widget buildResumoFooter() {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _pdvTheme.backgroundPage, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)), border: Border(top: BorderSide(color: _pdvTheme.cardBorder))),
        child: Column(children: <Widget>[
          _buildResumoLinhaValor('Subtotal', _formatCurrency(total)),
          const SizedBox(height: 10),
          _buildResumoLinhaValor('Desconto', _formatCurrency(0)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _pdvTheme.iconColor, borderRadius: BorderRadius.circular(18)),
            child: Row(children: <Widget>[
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text('Total', style: TextStyle(color: Colors.white.withValues(alpha: 0.80), fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(_formatCurrency(total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
              ])),
              const SizedBox(width: 12),
              Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 28)),
            ]),
          ),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[BoxShadow(color: _pdvTheme.cardShadow, blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool shortHeight = constraints.maxHeight < 560;

          if (shortHeight) {
            return SingleChildScrollView(
              controller: _resumoVendaScrollController,
              primary: false,
              child: Column(
                children: <Widget>[
                  buildResumoHeader(),
                  buildResumoConteudo(),
                  buildResumoFooter(),
                ],
              ),
            );
          }

          return Column(
            children: <Widget>[
              buildResumoHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _resumoVendaScrollController,
                  primary: false,
                  child: buildResumoConteudo(),
                ),
              ),
              buildResumoFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumoInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(width: 38, height: 38, decoration: BoxDecoration(color: _pdvTheme.iconColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: _pdvTheme.iconColor)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _pdvTheme.secondaryText)),
          const SizedBox(height: 2),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _pdvTheme.primaryText)),
        ])),
      ],
    );
  }

  Widget _buildMiniAction(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16), label: Text(label), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));
  }

  Widget _buildResumoLinhaValor(String label, String valor) {
    return Row(children: <Widget>[
      Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: _pdvTheme.secondaryText))),
      Text(valor, style: TextStyle(fontWeight: FontWeight.w900, color: _pdvTheme.primaryText)),
    ]);
  }

  Widget _buildBarraFechamento(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[BoxShadow(color: _pdvTheme.cardShadow, blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          Wrap(spacing: 18, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text('Barra de fechamento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _pdvTheme.secondaryText)),
              const SizedBox(height: 6),
              Text(_formatCurrency(total), style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _pdvTheme.iconColor)),
            ]),
            _buildFooterInfoCard('Subtotal', _formatCurrency(total)),
            _buildFooterInfoCard('Desconto', _formatCurrency(0)),
            _buildFooterInfoCard('Itens', '${_calcularQuantidadeItens()}'),
          ]),
          Wrap(spacing: 12, runSpacing: 12, children: <Widget>[
            OutlinedButton.icon(
              onPressed: _produtosSelecionados.isEmpty || _registrandoReceberDepois ? null : _pausarVenda,
              icon: _registrandoReceberDepois ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.schedule_send_outlined),
              label: Text(_registrandoReceberDepois ? 'Registrando...' : 'Receber depois'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(190, 54), padding: const EdgeInsets.symmetric(horizontal: 20), side: BorderSide(color: _pdvTheme.actionButtonBackground, width: 1.5), foregroundColor: _pdvTheme.actionButtonBackground, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            ),
            FilledButton.icon(
              onPressed: _produtosSelecionados.isEmpty ? null : _abrirTelaRecebimento,
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Receber'),
              style: FilledButton.styleFrom(minimumSize: const Size(170, 54), padding: const EdgeInsets.symmetric(horizontal: 24), backgroundColor: _pdvTheme.actionButtonBackground, foregroundColor: _pdvTheme.actionButtonForeground, textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            ),
            OutlinedButton.icon(
              onPressed: _abrirVendasAReceberWeb,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Vendas a receber'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(190, 54), padding: const EdgeInsets.symmetric(horizontal: 20), side: BorderSide(color: _pdvTheme.actionButtonBackground, width: 1.5), foregroundColor: _pdvTheme.actionButtonBackground, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            ),
            OutlinedButton.icon(
              onPressed: _confirmarCancelamentoVenda,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 54), padding: const EdgeInsets.symmetric(horizontal: 20), side: BorderSide(color: _pdvTheme.warningColor, width: 1.5), foregroundColor: _pdvTheme.warningColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildFooterInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: _pdvTheme.backgroundPage, borderRadius: BorderRadius.circular(18), border: Border.all(color: _pdvTheme.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12, color: _pdvTheme.secondaryText, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, color: _pdvTheme.primaryText, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _buildAreaVenda(double total) {
    Widget buildMain() {
      return Column(
        children: <Widget>[
          _buildVendaHero(),
          const SizedBox(height: 18),
          _buildBarraOperacional(),
          const SizedBox(height: 18),
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
              Expanded(flex: 7, child: _buildGradeOperacional()),
              const SizedBox(width: 18),
              SizedBox(width: 380, child: _buildResumoVendaLateral()),
            ]),
          ),
          const SizedBox(height: 18),
          _buildBarraFechamento(total),
        ],
      );
    }

    return Expanded(
      child: Focus(
        autofocus: true,
        focusNode: _atalhosFocusNode,
        onKeyEvent: _handleAtalhoPdv,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compactHeight = constraints.maxHeight < 760;
            final bool compactWidth = constraints.maxWidth < 1360;
            final double mainHeight = compactHeight ? 560 : constraints.maxHeight - 300;

            if (compactHeight || compactWidth) {
              return ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: _areaVendaScrollController,
                  primary: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: compactHeight ? 940 : constraints.maxHeight),
                    child: Column(children: <Widget>[
                      _buildVendaHero(),
                      const SizedBox(height: 18),
                      _buildBarraOperacional(),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: mainHeight,
                        child: compactWidth
                            ? Column(children: <Widget>[
                                Expanded(child: _buildGradeOperacional()),
                                const SizedBox(height: 18),
                                SizedBox(height: 420, child: _buildResumoVendaLateral()),
                              ])
                            : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                                Expanded(flex: 7, child: _buildGradeOperacional()),
                                const SizedBox(width: 18),
                                SizedBox(width: 380, child: _buildResumoVendaLateral()),
                              ]),
                      ),
                      const SizedBox(height: 18),
                      _buildBarraFechamento(total),
                    ]),
                  ),
                ),
              );
            }

            return buildMain();
          },
        ),
      ),
    );
  }
}
