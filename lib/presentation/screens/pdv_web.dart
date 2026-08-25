part of '../../pagina_principal_web.dart';

bool acionarPdvFrenteCaixaPeloElemento(Element element) {
  if (element is StatefulElement && element.state is _PaginaPrincipalWebState) {
    (element.state as _PaginaPrincipalWebState)._iniciarVenda();
    return true;
  }

  return false;
}

extension _PdvWeb on _PaginaPrincipalWebState {
  bool get _vendaPossuiItens => _produtosSelecionados.isNotEmpty;

  bool get _consultandoVendaNaoLiquidada =>
      _vendaNaoLiquidadaEmConsulta != null;

  bool get _vendaNaoLiquidadaPossuiRecebimentoAnterior {
    final VendaNaoLiquidadaModel? venda = _vendaNaoLiquidadaEmConsulta;
    if (venda == null) return false;
    return venda.recebimentos.isNotEmpty ||
        (venda.valorOriginal - venda.valorAberto).abs() > 0.009;
  }

  bool get _vendaNaoLiquidadaPermiteEdicaoItens =>
      _consultandoVendaNaoLiquidada &&
      !_vendaNaoLiquidadaPossuiRecebimentoAnterior;

  bool get _pdvPodeEditarVenda =>
      _pdvPodeLancarVenda &&
      (!_consultandoVendaNaoLiquidada || _vendaNaoLiquidadaPermiteEdicaoItens);

  bool get _pdvPodeEditarCliente =>
      _pdvPodeLancarVenda && !_consultandoVendaNaoLiquidada;

  double get _totalParaRecebimentoAtual {
    if (_vendaNaoLiquidadaPermiteEdicaoItens) {
      return _calcularTotal();
    }
    return _vendaNaoLiquidadaEmConsulta?.valorAberto ?? _calcularTotal();
  }

  bool get _vendaNaoLiquidadaPossuiAlteracoesNosItens {
    final VendaNaoLiquidadaModel? venda = _vendaNaoLiquidadaEmConsulta;
    if (venda == null || !_vendaNaoLiquidadaPermiteEdicaoItens) {
      return false;
    }
    return _assinaturaItensVendaNaoLiquidada(venda.itens) !=
        _assinaturaItensPdv();
  }

  bool get _clienteSelecionadoNaVenda {
    return _clienteIdentificado != null ||
        _clienteIdentificadoController.text.trim().isNotEmpty;
  }

  Future<void> _abrirVendasAReceberWeb() async {
    final VendaNaoLiquidadaModel? vendaSelecionada =
        await showDialog<VendaNaoLiquidadaModel>(
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
                child: VendasAReceberWebWidget(
                  onAbrirNoPdv:
                      (VendaNaoLiquidadaModel venda) =>
                          Navigator.of(dialogContext).pop(venda),
                ),
              ),
            );
          },
        );

    if (!mounted) {
      return;
    }

    if (vendaSelecionada != null) {
      await _carregarVendaNaoLiquidadaNoPdv(vendaSelecionada);
      return;
    }

    if (_moduloAtual == ModuloCentralPDV.vendas &&
        !_consultandoVendaNaoLiquidada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focarCodigoBarras();
      });
    }
  }

  Future<void> _carregarVendaNaoLiquidadaNoPdv(
    VendaNaoLiquidadaModel vendaSelecionada,
  ) async {
    VendaNaoLiquidadaModel? vendaAtualizada;
    try {
      final List<VendaNaoLiquidadaModel> vendas =
          await _vendaNaoLiquidadaApiClient.listar();
      for (final VendaNaoLiquidadaModel venda in vendas) {
        if (venda.idRecebimento == vendaSelecionada.idRecebimento) {
          vendaAtualizada = venda;
          break;
        }
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagemVendaNaoLiquidada(
        context.t(
          'pdv.openSale.loadErrorTitle',
          fallback: 'Não foi possível abrir a venda',
        ),
        e.toString().replaceAll('Exception: ', ''),
      );
      return;
    }

    if (!mounted) return;
    if (vendaAtualizada == null) {
      _mostrarMensagemVendaNaoLiquidada(
        context.t(
          'pdv.openSale.unavailableTitle',
          fallback: 'Venda não disponível',
        ),
        context.t(
          'pdv.openSale.unavailableMessage',
          fallback:
              'A venda pode ter sido recebida ou cancelada por outro usuário.',
        ),
      );
      return;
    }

    final bool substituindoOutraVenda =
        _vendaTemDadosTemporariosPreenchidos() &&
        _vendaNaoLiquidadaEmConsulta?.idRecebimento !=
            vendaAtualizada.idRecebimento;
    if (substituindoOutraVenda) {
      final bool substituir =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text(
                  context.t(
                    'pdv.openSale.replaceTitle',
                    fallback: 'Substituir a venda atual?',
                  ),
                ),
                content: Text(
                  context.t(
                    'pdv.openSale.replaceMessage',
                    fallback:
                        'Os dados que estão no PDV serão substituídos pela venda em aberto selecionada.',
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.t('common.back', fallback: 'Voltar')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.t(
                        'pdv.openSale.replaceAction',
                        fallback: 'Abrir venda',
                      ),
                    ),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!substituir || !mounted) {
        return;
      }
    }

    final VendaNaoLiquidadaModel venda = vendaAtualizada;
    setState(() {
      _produtosSelecionados.clear();
      for (int index = 0; index < venda.itens.length; index++) {
        final VendaNaoLiquidadaItemModel item = venda.itens[index];
        final String tipoProduto = item.ehServico ? 'SERVICO' : 'PRODUTO';
        final String idProduto = item.idProduto.trim();
        final String chaveBase =
            idProduto.isNotEmpty
                ? '$tipoProduto:id:$idProduto'
                : '$tipoProduto:nome:${item.nome.trim().toLowerCase()}|preco:${item.valorUnitario.toStringAsFixed(4)}';
        final String chaveItem = '$chaveBase|venda-aberta:$index';
        _produtosSelecionados.add(<String, dynamic>{
          'id': item.idProduto,
          'codigo': '',
          'nome': item.nome,
          'preco': item.valorUnitario,
          'quantidade': item.quantidade,
          'tipoProduto': tipoProduto,
          'ehServico': item.ehServico,
          'chaveItem': chaveItem,
          'vendaNaoLiquidadaSnapshot': true,
        });
      }
      _formasPagamentoConfirmadas = <FormaPagamentoSelecionada>[];
      _descricoesFormaPagamentoPorCodigo = <String, String>{};
      _pagamentoParcialConfirmado = false;
      _codigoBarrasController.clear();
      _clienteIdentificado = null;
      _clienteIdentificadoController.text = venda.nomeCliente.trim();
      _vendaNaoLiquidadaEmConsulta = venda;
      _recebendoVendaNaoLiquidada = false;
      _clearAllItemVisualState();
      _atualizarCamposDerivados();
      _moduloAtual = ModuloCentralPDV.vendas;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    await _carregarSessaoCaixaPdv();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t(
            _vendaNaoLiquidadaPermiteEdicaoItens
                ? 'pdv.openSale.loadedMessage'
                : 'pdv.openSale.loadedReadOnlyMessage',
            fallback:
                _vendaNaoLiquidadaPermiteEdicaoItens
                    ? 'Venda carregada para revisão. Você pode incluir, remover e alterar quantidades antes de receber.'
                    : 'Venda carregada para consulta. Como já existem recebimentos, os itens permanecem bloqueados.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (_vendaNaoLiquidadaPermiteEdicaoItens) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focarCodigoBarras();
      });
    }
  }

  void _mostrarMensagemVendaNaoLiquidada(String titulo, String mensagem) {
    showDialog<void>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: Text(titulo),
            content: Text(mensagem),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.t('common.close', fallback: 'Fechar')),
              ),
            ],
          ),
    );
  }

  Future<void> _receberVendaNaoLiquidadaEmConsulta() async {
    final VendaNaoLiquidadaModel? venda = _vendaNaoLiquidadaEmConsulta;
    if (venda == null || _recebendoVendaNaoLiquidada) {
      return;
    }

    if (!await _garantirSessaoCaixaAbertaParaVenda() || !mounted) {
      return;
    }

    final List<VendaNaoLiquidadaItemModel> itensRevisados =
        _vendaNaoLiquidadaPermiteEdicaoItens
            ? _montarItensVendaNaoLiquidadaDoPdv()
            : <VendaNaoLiquidadaItemModel>[];
    if (_vendaNaoLiquidadaPermiteEdicaoItens && itensRevisados.isEmpty) {
      _mostrarMensagemVendaNaoLiquidada(
        context.t(
          'pdv.openSale.emptyItemsTitle',
          fallback: 'A venda precisa ter itens',
        ),
        context.t(
          'pdv.openSale.emptyItemsMessage',
          fallback:
              'Inclua pelo menos um produto ou serviço antes de receber a venda.',
        ),
      );
      return;
    }
    final bool possuiItensInvalidos = itensRevisados.any(
      (VendaNaoLiquidadaItemModel item) =>
          item.nome.isEmpty || item.quantidade <= 0 || item.valorUnitario < 0,
    );
    if (possuiItensInvalidos) {
      _mostrarMensagemVendaNaoLiquidada(
        context.t(
          'pdv.openSale.invalidItemsTitle',
          fallback: 'Revise os itens da venda',
        ),
        context.t(
          'pdv.openSale.invalidItemsMessage',
          fallback:
              'Todos os itens precisam ter nome, quantidade positiva e valor válido.',
        ),
      );
      return;
    }

    final bool possuiAlteracoes = _vendaNaoLiquidadaPossuiAlteracoesNosItens;
    if (possuiAlteracoes) {
      final bool confirmou = await _confirmarAlteracoesVendaNaoLiquidada(venda);
      if (!confirmou || !mounted) return;
    }

    final double valorParaReceber = _totalParaRecebimentoAtual;

    final SixWebRecebimentoResultado? resultado =
        await SixWebRecebimentoDialog.show(
          context,
          titulo: context.t(
            'pdv.openSale.receiveTitle',
            fallback: 'Receber saldo da venda',
          ),
          descricao: venda.descricao,
          contato:
              venda.nomeCliente.trim().isEmpty
                  ? null
                  : venda.nomeCliente.trim(),
          valorAberto: valorParaReceber,
          permitirParcial: false,
          observacaoInicial: context.t(
            possuiAlteracoes
                ? 'pdv.openSale.updatedReceiptNote'
                : 'pdv.openSale.receiptNote',
            fallback:
                possuiAlteracoes
                    ? 'Venda revisada e recebida pelo PDV web.'
                    : 'Saldo recebido pelo PDV web.',
          ),
          codigoTipoInicial: venda.codigoTipoRecebimento,
        );

    if (resultado == null || !mounted) {
      return;
    }

    setState(() => _recebendoVendaNaoLiquidada = true);
    try {
      final bool vendaPermaneceAtual =
          await _validarVendaNaoLiquidadaAntesDaLiquidacao(venda);
      if (!vendaPermaneceAtual || !mounted) return;

      final String? idSessaoCaixa = _sessaoCaixaPdv?.idSessaoCaixa.trim();
      await _vendaNaoLiquidadaApiClient.liquidar(
        idRecebimento: venda.idRecebimento,
        input: LiquidarVendaNaoLiquidadaInput(
          codigoTipoRecebimento: resultado.codigoTipoRecebimento,
          valorRecebido: resultado.valor,
          recebimentos: resultado.recebimentos,
          itens:
              possuiAlteracoes
                  ? itensRevisados
                  : <VendaNaoLiquidadaItemModel>[],
          observacao: resultado.observacao,
          referencia:
              venda.idOperacaoApp.isNotEmpty
                  ? venda.idOperacaoApp
                  : venda.idOperacaoFinanceira,
          idSessaoCaixa:
              idSessaoCaixa == null || idSessaoCaixa.isEmpty
                  ? null
                  : idSessaoCaixa,
        ),
      );

      if (!mounted) return;
      _limparVendaAposSucessoRecebimento();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'pdv.openSale.receivedMessage',
              fallback: 'Venda recebida com sucesso.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagemVendaNaoLiquidada(
        context.t(
          'pdv.openSale.receiptErrorTitle',
          fallback: 'Não foi possível receber a venda',
        ),
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _recebendoVendaNaoLiquidada = false);
      }
    }
  }

  List<VendaNaoLiquidadaItemModel> _montarItensVendaNaoLiquidadaDoPdv() {
    return _produtosSelecionados
        .map((Map<String, dynamic> produto) {
          final String idProduto =
              (produto['id'] ?? produto['codigo'] ?? '').toString().trim();
          return VendaNaoLiquidadaItemModel(
            idProduto: idProduto,
            nome: (produto['nome'] ?? '').toString().trim(),
            quantidade: (produto['quantidade'] ?? 1) as int,
            valorUnitario: ((produto['preco'] ?? 0) as num).toDouble(),
            ehServico: _ehServicoItem(produto),
          );
        })
        .toList(growable: false);
  }

  String _assinaturaItensVendaNaoLiquidada(
    List<VendaNaoLiquidadaItemModel> itens,
  ) {
    final List<String> assinaturas = itens
      .map(
        (VendaNaoLiquidadaItemModel item) => _assinaturaItemVendaNaoLiquidada(
          idProduto: item.idProduto,
          nome: item.nome,
          quantidade: item.quantidade,
          valorUnitario: item.valorUnitario,
          ehServico: item.ehServico,
        ),
      )
      .toList(growable: false)..sort();
    return assinaturas.join('\n');
  }

  String _assinaturaItensPdv() {
    final List<String> assinaturas = _produtosSelecionados
      .map((Map<String, dynamic> item) {
        return _assinaturaItemVendaNaoLiquidada(
          idProduto: (item['id'] ?? item['codigo'] ?? '').toString(),
          nome: (item['nome'] ?? '').toString(),
          quantidade: (item['quantidade'] ?? 1) as int,
          valorUnitario: ((item['preco'] ?? 0) as num).toDouble(),
          ehServico: _ehServicoItem(item),
        );
      })
      .toList(growable: false)..sort();
    return assinaturas.join('\n');
  }

  String _assinaturaItemVendaNaoLiquidada({
    required String idProduto,
    required String nome,
    required int quantidade,
    required double valorUnitario,
    required bool ehServico,
  }) {
    return '${ehServico ? 'S' : 'P'}|${idProduto.trim()}|${nome.trim()}|$quantidade|${valorUnitario.toStringAsFixed(4)}';
  }

  Future<bool> _confirmarAlteracoesVendaNaoLiquidada(
    VendaNaoLiquidadaModel venda,
  ) async {
    final double novoTotal = _calcularTotal();
    final double diferenca = novoTotal - venda.valorOriginal;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              icon: const Icon(Icons.edit_note_rounded),
              title: Text(
                context.t(
                  'pdv.openSale.confirmChangesTitle',
                  fallback: 'Confirmar itens revisados?',
                ),
              ),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildResumoLinhaValor(
                      context.t(
                        'pdv.openSale.originalTotal',
                        fallback: 'Total original',
                      ),
                      _formatCurrency(venda.valorOriginal),
                    ),
                    const SizedBox(height: 8),
                    _buildResumoLinhaValor(
                      context.t(
                        'pdv.openSale.currentTotal',
                        fallback: 'Novo total',
                      ),
                      _formatCurrency(novoTotal),
                    ),
                    const SizedBox(height: 8),
                    _buildResumoLinhaValor(
                      context.t(
                        'pdv.openSale.totalDifference',
                        fallback: 'Diferença',
                      ),
                      _formatCurrency(diferenca),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.t(
                        'pdv.openSale.confirmChangesMessage',
                        fallback:
                            'Ao receber, a nova composição de itens será aplicada e o estoque e o financeiro serão conciliados.',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.t('common.back', fallback: 'Voltar')),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    context.t(
                      'pdv.openSale.continueToReceipt',
                      fallback: 'Continuar para recebimento',
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _validarVendaNaoLiquidadaAntesDaLiquidacao(
    VendaNaoLiquidadaModel vendaOriginal,
  ) async {
    final List<VendaNaoLiquidadaModel> vendas =
        await _vendaNaoLiquidadaApiClient.listar();
    VendaNaoLiquidadaModel? vendaAtual;
    for (final VendaNaoLiquidadaModel venda in vendas) {
      if (venda.idRecebimento == vendaOriginal.idRecebimento) {
        vendaAtual = venda;
        break;
      }
    }
    if (vendaAtual == null) {
      _mostrarMensagemVendaNaoLiquidada(
        context.t(
          'pdv.openSale.unavailableTitle',
          fallback: 'Venda não disponível',
        ),
        context.t(
          'pdv.openSale.unavailableMessage',
          fallback:
              'A venda pode ter sido recebida ou cancelada por outro usuário.',
        ),
      );
      return false;
    }

    final bool permaneceIgual =
        (vendaAtual.valorOriginal - vendaOriginal.valorOriginal).abs() <=
            0.009 &&
        (vendaAtual.valorAberto - vendaOriginal.valorAberto).abs() <= 0.009 &&
        vendaAtual.status == vendaOriginal.status &&
        _assinaturaItensVendaNaoLiquidada(vendaAtual.itens) ==
            _assinaturaItensVendaNaoLiquidada(vendaOriginal.itens);
    if (permaneceIgual) return true;

    _mostrarMensagemVendaNaoLiquidada(
      context.t('pdv.openSale.outdatedTitle', fallback: 'A venda foi alterada'),
      context.t(
        'pdv.openSale.outdatedMessage',
        fallback:
            'Outra operação modificou esta venda. Feche a consulta e abra novamente para trabalhar com os dados atuais.',
      ),
    );
    return false;
  }

  Widget _buildCabecalhoVendaCompacto() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final bool expandido = _modoExpandidoFrenteCaixa;
    final bool temPagamentoConfirmado = _temPagamentoConfirmado();
    final bool pagamentoCompleto = _pagamentoConfirmadoCompleto();
    final bool pagamentoParcial = _pagamentoConfirmadoParcial();
    final bool pagamentoPrecisaRevisao = _pagamentoConfirmadoPrecisaRevisao();
    final bool clienteNaoInformado =
        (_vendaPossuiItens || _consultandoVendaNaoLiquidada) &&
        !_clienteSelecionadoNaVenda;
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
                    _buildSessaoCaixaPdvChip(l10n),
                    if (_sessaoCaixaPdv != null)
                      _buildTempoAtivoSessaoCaixaPdvChip(_sessaoCaixaPdv!),
                    if (_consultandoVendaNaoLiquidada)
                      _buildStatusChip(
                        label: context.t(
                          _vendaNaoLiquidadaPermiteEdicaoItens
                              ? 'pdv.openSale.editStatus'
                              : 'pdv.openSale.status',
                          fallback:
                              _vendaNaoLiquidadaPermiteEdicaoItens
                                  ? 'Edição de itens'
                                  : 'Venda em aberto',
                        ),
                        icon:
                            _vendaNaoLiquidadaPermiteEdicaoItens
                                ? Icons.edit_note_rounded
                                : Icons.lock_outline_rounded,
                        foregroundColor: _pdvTheme.iconColor,
                        backgroundColor: _pdvTheme.iconColor.withValues(
                          alpha: 0.11,
                        ),
                      )
                    else if (_vendaPossuiItens)
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
                    else if ((_vendaPossuiItens ||
                            _consultandoVendaNaoLiquidada) &&
                        _clienteSelecionadoNaVenda)
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
                        pagamentoParcial: pagamentoParcial,
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
                message: context.t(
                  'pdv.openCashOperations',
                  fallback: 'Operações de caixa',
                ),
                child: Semantics(
                  button: true,
                  label: context.t(
                    'pdv.openCashOperations',
                    fallback: 'Operações de caixa',
                  ),
                  child: IconButton(
                    onPressed:
                        () => _abrirOperacoesCaixa(
                          retorno: ModuloCentralPDV.vendas,
                        ),
                    constraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 42,
                    ),
                    icon: Icon(
                      Icons.point_of_sale_rounded,
                      color: _pdvTheme.iconColor,
                    ),
                  ),
                ),
              ),
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

  Widget _buildSessaoCaixaPdvChip(AppLocalizations? l10n) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    if (_carregandoSessaoCaixaPdv) {
      return _buildStatusChip(
        label: l10n?.pdvCashSessionChecking ?? 'Verificando sessão do caixa',
        icon: Icons.sync_rounded,
        foregroundColor: tokens.info,
        backgroundColor: tokens.info.withValues(alpha: 0.11),
      );
    }

    if (_erroSessaoCaixaPdv) {
      return _buildStatusChip(
        label: l10n?.pdvCashSessionUnavailable ?? 'Sessão indisponível',
        icon: Icons.cloud_off_outlined,
        foregroundColor: tokens.danger,
        backgroundColor: tokens.danger.withValues(alpha: 0.12),
      );
    }

    final CaixaSessao? sessao = _sessaoCaixaPdv;
    if (sessao == null) {
      return _buildStatusChip(
        label: l10n?.pdvCashSessionNotOpen ?? 'Sem sessão aberta',
        icon: Icons.point_of_sale_outlined,
        foregroundColor: tokens.statusNeutral,
        backgroundColor: tokens.surfaceMuted,
      );
    }

    final bool aberta = _sessaoCaixaPdvAberta(sessao);
    final Color foreground = aberta ? tokens.success : tokens.statusNeutral;
    return _buildStatusChip(
      label: _labelSessaoCaixaPdv(sessao, l10n),
      icon: aberta ? Icons.point_of_sale_outlined : Icons.lock_clock_outlined,
      foregroundColor: foreground,
      backgroundColor:
          aberta ? tokens.success.withValues(alpha: 0.12) : tokens.surfaceMuted,
    );
  }

  String _labelSessaoCaixaPdv(CaixaSessao sessao, AppLocalizations? l10n) {
    final String nomeCaixa = sessao.nomeCaixa.trim();
    final String nomeColaborador = sessao.nomeColaboradorAbertura.trim();
    final String statusLabel =
        _sessaoCaixaPdvAberta(sessao)
            ? (l10n?.pdvWebSessionActive ?? 'Sessão ativa')
            : (l10n?.pdvCashSessionClosed ?? 'Sessão fechada');

    final List<String> partes = <String>[];
    if (nomeCaixa.isNotEmpty) {
      partes.add(nomeCaixa);
    }
    partes.add(statusLabel);
    if (nomeColaborador.isNotEmpty) {
      partes.add(nomeColaborador);
    }

    return partes.join(' · ');
  }

  Widget _buildTempoAtivoSessaoCaixaPdvChip(CaixaSessao sessao) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Duration? tempoAtivo = _tempoAtivoSessaoCaixaPdv(sessao);
    if (tempoAtivo == null) {
      return const SizedBox.shrink();
    }

    return _buildStatusChip(
      label: _formatarTempoAtivoSessaoCaixaPdv(tempoAtivo),
      icon: Icons.schedule_rounded,
      foregroundColor: tokens.info,
      backgroundColor: tokens.info.withValues(alpha: 0.11),
    );
  }

  Duration? _tempoAtivoSessaoCaixaPdv(CaixaSessao sessao) {
    if (!_sessaoCaixaPdvAberta(sessao)) {
      return null;
    }

    final DateTime? abertura = _parseDataHoraSessaoCaixaPdv(
      sessao.dataHoraAbertura,
    );
    if (abertura == null) {
      return null;
    }

    final Duration diferenca = _referenciaTempoSessaoCaixaPdv.difference(
      abertura,
    );
    return diferenca.isNegative ? Duration.zero : diferenca;
  }

  DateTime? _parseDataHoraSessaoCaixaPdv(String rawValue) {
    final String normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final DateTime? parsed =
        DateTime.tryParse(normalized) ??
        DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
    if (parsed == null) {
      return null;
    }

    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  String _formatarTempoAtivoSessaoCaixaPdv(Duration duration) {
    final int totalHours = duration.inHours;
    final int totalMinutes = duration.inMinutes;
    final int remainingMinutes = totalMinutes.remainder(60);

    if (totalHours > 0) {
      return '${totalHours}h ${remainingMinutes}m';
    }

    return '${totalMinutes}m';
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

  Widget _buildAvisoVendaNaoLiquidadaEmConsulta() {
    final ThemeData theme = Theme.of(context);
    final bool permiteEdicao = _vendaNaoLiquidadaPermiteEdicaoItens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            permiteEdicao
                ? Icons.edit_note_rounded
                : Icons.lock_outline_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t(
                    permiteEdicao
                        ? 'pdv.openSale.editTitle'
                        : 'pdv.openSale.readOnlyTitle',
                    fallback:
                        permiteEdicao
                            ? 'Revise os itens antes de receber'
                            : 'Consulta de venda em aberto',
                  ),
                  style: TextStyle(
                    color: _pdvTheme.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.t(
                    permiteEdicao
                        ? 'pdv.openSale.editSubtitle'
                        : (_vendaNaoLiquidadaPossuiRecebimentoAnterior
                            ? 'pdv.openSale.partialReadOnlySubtitle'
                            : 'pdv.openSale.readOnlySubtitle'),
                    fallback:
                        permiteEdicao
                            ? 'Inclua, remova ou altere quantidades. As mudanças serão aplicadas somente ao receber a venda.'
                            : (_vendaNaoLiquidadaPossuiRecebimentoAnterior
                                ? 'Esta venda já possui recebimentos. Para preservar o histórico financeiro, os itens permanecem bloqueados.'
                                : 'Produtos, quantidades e preços estão bloqueados nesta etapa. Revise os dados e receba o saldo.'),
                  ),
                  style: TextStyle(color: _pdvTheme.secondaryText),
                ),
              ],
            ),
          ),
        ],
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
              onPressed: _pdvPodeEditarVenda ? _abrirSelecaoProdutoWeb : null,
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
                onPressed:
                    _pdvPodeEditarCliente ? _abrirDialogClienteRapido : null,
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
            onPressed: _pdvPodeEditarVenda ? _abrirSelecaoProdutoWeb : null,
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
              onPressed:
                  _pdvPodeEditarCliente ? _abrirDialogClienteRapido : null,
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
    required VoidCallback? onPressed,
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
      enabled: _pdvPodeEditarVenda,
      decoration: InputDecoration(
        isDense: true,
        hintText:
            l10n?.pdvWebReadOrSearchToStartMessage ??
            'Leia um código de barras ou busque um produto para iniciar a venda.',
        labelText: l10n?.pdvWebBarcodeFieldLabel ?? 'Código de barras',
        prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
        suffixIcon: IconButton(
          tooltip: l10n?.pdvWebFocusBarcodeFieldAction ?? 'Focar leitura',
          onPressed: _pdvPodeEditarVenda ? _focarCodigoBarras : null,
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
    final bool podeEditarVenda = _pdvPodeEditarVenda;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
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
                      onPressed:
                          podeEditarVenda
                              ? () => _alterarQuantidade(produto, -1)
                              : null,
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
                      onPressed:
                          podeEditarVenda
                              ? () => _alterarQuantidade(produto, 1)
                              : null,
                      foregroundColor: _pdvTheme.iconColor,
                    ),
                    const SizedBox(width: 2),
                    _buildBotaoQuantidadeItem(
                      tooltip: l10n?.pdvWebRemoveItemAction ?? 'Remover item',
                      semanticLabel:
                          l10n?.pdvWebRemoveItemAction ?? 'Remover item',
                      icon: Icons.delete_outline_rounded,
                      onPressed:
                          podeEditarVenda
                              ? () => _removerProduto(produto)
                              : null,
                      foregroundColor: tokens.danger,
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
    required VoidCallback? onPressed,
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
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool dark = theme.colorScheme.brightness == Brightness.dark;
    final VendaNaoLiquidadaModel? vendaEmConsulta =
        _vendaNaoLiquidadaEmConsulta;
    final double total = vendaEmConsulta?.valorOriginal ?? _calcularTotal();
    final double saldoAberto =
        _vendaNaoLiquidadaPermiteEdicaoItens
            ? _calcularTotal()
            : (vendaEmConsulta?.valorAberto ?? total);
    final double diferencaTotal = saldoAberto - total;
    final String cliente =
        _clienteSelecionadoNaVenda
            ? _clienteAtualLabel()
            : context.t('common.notInformed', fallback: 'Não informado');
    final List<FormaPagamentoSelecionada> formasPagamento =
        _formasPagamentoConfirmadas
            .where((FormaPagamentoSelecionada forma) => forma.valor > 0)
            .toList(growable: false);
    final bool temPagamentoConfirmado = formasPagamento.isNotEmpty;
    final bool pagamentoCompleto = _pagamentoConfirmadoCompleto();
    final bool pagamentoParcial = _pagamentoConfirmadoParcial();
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
                    _consultandoVendaNaoLiquidada
                        ? context.t(
                          'pdv.openSale.status',
                          fallback: 'Venda em aberto',
                        )
                        : (l10n?.pdvWebCurrentSaleTitle ?? 'Venda atual'),
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
                        _consultandoVendaNaoLiquidada
                            ? context.t(
                              _vendaNaoLiquidadaPermiteEdicaoItens
                                  ? 'pdv.openSale.editStatus'
                                  : 'pdv.openSale.readOnlyStatus',
                              fallback:
                                  _vendaNaoLiquidadaPermiteEdicaoItens
                                      ? 'Edição de itens'
                                      : 'Somente consulta',
                            )
                            : (l10n?.pdvWebStatusInProgress ?? 'Em andamento'),
                        style: TextStyle(
                          color: _pdvTheme.successColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_vendaNaoLiquidadaPossuiAlteracoesNosItens)
                      _buildStatusChip(
                        label: context.t(
                          'pdv.openSale.pendingChanges',
                          fallback: 'Alterações pendentes',
                        ),
                        icon: Icons.pending_actions_outlined,
                        foregroundColor: _pdvTheme.warningColor,
                        backgroundColor: _pdvTheme.warningColor.withValues(
                          alpha: 0.13,
                        ),
                      ),
                    if (temPagamentoConfirmado)
                      _buildChipStatusPagamento(
                        l10n: l10n,
                        pagamentoCompleto: pagamentoCompleto,
                        pagamentoParcial: pagamentoParcial,
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
            else if (_consultandoVendaNaoLiquidada)
              _buildResumoInfoTile(
                icon: Icons.person_off_outlined,
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
                style: _pdvOutlinedCtaStyle(),
              ),
            const SizedBox(height: 10),
            if (temPagamentoConfirmado)
              _buildSecaoPagamentoConfirmado(
                l10n: l10n,
                formasPagamento: formasPagamento,
              )
            else
              OutlinedButton.icon(
                onPressed:
                    _recebendoVendaNaoLiquidada
                        ? null
                        : (_vendaNaoLiquidadaPermiteEdicaoItens &&
                            !_vendaPossuiItens)
                        ? null
                        : _abrirTelaRecebimento,
                icon: const Icon(Icons.payments_outlined),
                label: Text(
                  _consultandoVendaNaoLiquidada
                      ? context.t(
                        _vendaNaoLiquidadaPermiteEdicaoItens
                            ? 'pdv.openSale.receiveUpdatedSale'
                            : 'pdv.openSale.receiveBalance',
                        fallback:
                            _vendaNaoLiquidadaPermiteEdicaoItens
                                ? 'Receber venda revisada'
                                : 'Receber saldo',
                      )
                      : (l10n?.pdvWebDefinePaymentAction ??
                          'Definir pagamento'),
                ),
                style: _pdvOutlinedCtaStyle(),
              ),
            const SizedBox(height: 12),
            Divider(color: _pdvTheme.cardBorder, height: 1),
            const SizedBox(height: 12),
            _buildResumoLinhaValorAnimado(
              _consultandoVendaNaoLiquidada
                  ? context.t(
                    'pdv.openSale.originalTotal',
                    fallback: 'Total original',
                  )
                  : (l10n?.pdvWebSubtotalLabel ?? 'Subtotal'),
              total,
            ),
            if (_vendaNaoLiquidadaPossuiAlteracoesNosItens) ...<Widget>[
              const SizedBox(height: 8),
              _buildResumoLinhaValorAnimado(
                context.t(
                  'pdv.openSale.totalDifference',
                  fallback: 'Diferença',
                ),
                diferencaTotal,
              ),
            ],
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark ? tokens.surfaceElevated : _pdvTheme.iconColor,
                borderRadius: BorderRadius.circular(12),
                border: dark ? Border.all(color: tokens.selectedBorder) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _consultandoVendaNaoLiquidada
                        ? context.t(
                          _vendaNaoLiquidadaPermiteEdicaoItens
                              ? 'pdv.openSale.currentTotal'
                              : 'pdv.openSale.openBalance',
                          fallback:
                              _vendaNaoLiquidadaPermiteEdicaoItens
                                  ? 'Novo total'
                                  : 'Saldo em aberto',
                        )
                        : (l10n?.pdvWebTotalLabel ?? 'Total'),
                    style: TextStyle(
                      color:
                          dark
                              ? tokens.secondaryText
                              : Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _PdvAnimatedCurrencyText(
                    value: saldoAberto,
                    formatter: _formatCurrency,
                    duration:
                        _prefereReducaoDeMovimento
                            ? Duration.zero
                            : const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: dark ? tokens.info : Colors.white,
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
    required bool pagamentoParcial,
    required bool pagamentoPrecisaRevisao,
  }) {
    final Color textoCor;
    final Color fundoCor;
    final String label;

    if (pagamentoCompleto) {
      textoCor = _pdvTheme.successColor;
      fundoCor = _pdvTheme.successColor.withValues(alpha: 0.12);
      label = l10n?.pdvWebPaymentDefinedLabel ?? 'Pagamento definido';
    } else if (pagamentoParcial) {
      textoCor = _pdvTheme.iconColor;
      fundoCor = _pdvTheme.iconColor.withValues(alpha: 0.12);
      label = context.t(
        'pdv.receipt.partialDefined',
        fallback: 'Parcial definido',
      );
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
                style: _pdvTextCtaStyle(),
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
          _buildResumoLinhaValorAnimado(
            l10n?.pdvWebReceivedTotalLabel ?? 'Total recebido',
            _totalPagamentoConfirmado(),
          ),
          _buildResumoLinhaValorAnimado(
            l10n?.pdvWebRemainingAmountLabel ?? 'Valor restante',
            _restantePagamentoConfirmado(),
          ),
          if (_pagamentoConfirmadoParcial()) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              context.t(
                'pdv.receipt.partialReady',
                fallback:
                    'Recebimento parcial pronto. O saldo ficará em aberto.',
              ),
              style: TextStyle(
                color: _pdvTheme.iconColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (_pagamentoConfirmadoPrecisaRevisao()) ...<Widget>[
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

  Widget _buildResumoLinhaValorAnimado(String label, double value) {
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
        _PdvAnimatedCurrencyText(
          value: value,
          formatter: _formatCurrency,
          duration:
              _prefereReducaoDeMovimento
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
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
    final bool temItens = _vendaPossuiItens || _consultandoVendaNaoLiquidada;
    final bool podeLancarVenda = _pdvPodeLancarVenda;
    final bool podeLimpar = _vendaTemDadosTemporariosPreenchidos();
    final bool pagamentoDefinido = _temPagamentoConfirmado();
    final bool pagamentoCompleto = _pagamentoConfirmadoCompleto();
    final bool pagamentoParcial = _pagamentoConfirmadoParcial();
    final bool pagamentoPrecisaRevisao = _pagamentoConfirmadoPrecisaRevisao();
    final double valorRecebimento = _totalParaRecebimentoAtual;
    final bool podeReceber =
        !_vendaNaoLiquidadaPermiteEdicaoItens || _vendaPossuiItens;

    final String labelAcaoPrincipal;
    if (_consultandoVendaNaoLiquidada) {
      labelAcaoPrincipal =
          '${context.t(_vendaNaoLiquidadaPermiteEdicaoItens ? 'pdv.openSale.receiveUpdatedSale' : 'pdv.openSale.receiveBalance', fallback: _vendaNaoLiquidadaPermiteEdicaoItens ? 'Receber venda revisada' : 'Receber saldo')} — ${_formatCurrency(valorRecebimento)}';
    } else if (!temItens) {
      labelAcaoPrincipal = l10n?.pdvWebReceiveAction ?? 'Receber';
    } else if (pagamentoParcial) {
      labelAcaoPrincipal =
          '${context.t('pdv.receipt.confirmPartial', fallback: 'Confirmar parcial')} — ${_formatCurrency(_totalPagamentoConfirmado())}';
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
                  _PdvAnimatedCurrencyText(
                    value:
                        _consultandoVendaNaoLiquidada
                            ? valorRecebimento
                            : total,
                    formatter: _formatCurrency,
                    duration:
                        _prefereReducaoDeMovimento
                            ? Duration.zero
                            : const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
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
                    label:
                        _consultandoVendaNaoLiquidada
                            ? context.t(
                              _vendaNaoLiquidadaPermiteEdicaoItens
                                  ? 'pdv.openSale.currentTotal'
                                  : 'pdv.openSale.openBalance',
                              fallback:
                                  _vendaNaoLiquidadaPermiteEdicaoItens
                                      ? 'Novo total'
                                      : 'Saldo em aberto',
                            )
                            : (l10n?.pdvWebSubtotalLabel ?? 'Subtotal'),
                  ),
                  if (_vendaNaoLiquidadaPossuiAlteracoesNosItens)
                    _buildAtalhoPdvChip(
                      icon: Icons.pending_actions_outlined,
                      label: context.t(
                        'pdv.openSale.pendingChanges',
                        fallback: 'Alterações pendentes',
                      ),
                    ),
                  if (pagamentoDefinido)
                    _buildAtalhoPdvChip(
                      icon:
                          pagamentoCompleto
                              ? Icons.verified_outlined
                              : pagamentoParcial
                              ? Icons.account_balance_wallet_outlined
                              : Icons.warning_amber_rounded,
                      label:
                          pagamentoCompleto
                              ? (l10n?.pdvWebPaymentDefinedLabel ??
                                  'Pagamento definido')
                              : pagamentoParcial
                              ? context.t(
                                'pdv.receipt.partialDefined',
                                fallback: 'Parcial definido',
                              )
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
              if (!_consultandoVendaNaoLiquidada)
                OutlinedButton.icon(
                  onPressed:
                      temItens && podeLancarVenda && !_registrandoReceberDepois
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
                  style: _pdvOutlinedCtaStyle(),
                ),
              FilledButton.icon(
                onPressed:
                    temItens &&
                            podeReceber &&
                            podeLancarVenda &&
                            !_recebendoVendaNaoLiquidada
                        ? _acionarRecebimentoPrincipal
                        : null,
                icon:
                    _recebendoVendaNaoLiquidada
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.payments_rounded),
                label: Text(labelAcaoPrincipal),
                style: _pdvFilledCtaStyle(),
              ),
              OutlinedButton.icon(
                onPressed:
                    () =>
                        _abrirOperacoesCaixa(retorno: ModuloCentralPDV.vendas),
                icon: const Icon(Icons.point_of_sale_rounded),
                label: Text(
                  context.t(
                    'pdv.openCashOperations',
                    fallback: 'Operações de caixa',
                  ),
                ),
                style: _pdvOutlinedCtaStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _abrirVendasAReceberWeb,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(
                  l10n?.pdvWebSalesToReceiveAction ?? 'Vendas a receber',
                ),
                style: _pdvOutlinedCtaStyle(),
              ),
              if (podeLimpar)
                OutlinedButton.icon(
                  onPressed: _confirmarLimparVendaAtual,
                  icon: Icon(
                    _consultandoVendaNaoLiquidada
                        ? Icons.close_rounded
                        : Icons.delete_sweep_outlined,
                  ),
                  label: Text(
                    _consultandoVendaNaoLiquidada
                        ? context.t(
                          _vendaNaoLiquidadaPossuiAlteracoesNosItens
                              ? 'pdv.openSale.discardAction'
                              : 'pdv.openSale.exitAction',
                          fallback:
                              _vendaNaoLiquidadaPossuiAlteracoesNosItens
                                  ? 'Descartar e sair'
                                  : 'Sair da consulta',
                        )
                        : (l10n?.pdvWebClearSaleAction ?? 'Limpar venda'),
                  ),
                  style:
                      _consultandoVendaNaoLiquidada
                          ? _pdvOutlinedCtaStyle()
                          : _pdvDangerOutlinedCtaStyle(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvisoSessaoCaixaObrigatoriaPdv() {
    final bool primeiraSincronizacaoEmAndamento =
        _carregandoSessaoCaixaPdv && !_sessaoCaixaPdvSincronizada;
    if (primeiraSincronizacaoEmAndamento) {
      return const SizedBox.shrink();
    }

    if (_pdvPodeLancarVenda) {
      return const SizedBox.shrink();
    }

    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final Color color = _erroSessaoCaixaPdv ? tokens.danger : tokens.warning;
    final String title =
        _carregandoSessaoCaixaPdv
            ? context.t(
              'pdv.cashSessionCheckingTitle',
              fallback: 'Verificando sessão do caixa',
            )
            : _erroSessaoCaixaPdv
            ? context.t(
              'pdv.cashSessionUnavailableTitle',
              fallback: 'Não foi possível validar o caixa',
            )
            : context.t(
              'pdv.cashSessionRequiredTitle',
              fallback: 'Abra o caixa para vender',
            );
    final String message =
        _carregandoSessaoCaixaPdv
            ? context.t(
              'pdv.cashSessionCheckingMessage',
              fallback:
                  'Aguarde a sincronização antes de lançar uma nova venda.',
            )
            : _erroSessaoCaixaPdv
            ? context.t(
              'pdv.cashSessionUnavailableMessage',
              fallback:
                  'Atualize a sessão ou acesse operações de caixa para conferir a situação.',
            )
            : context.t(
              'pdv.cashSessionRequiredMessage',
              fallback:
                  'Abra uma sessão de caixa antes de lançar vendas no PDV.',
            );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 760;
          final Widget text = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                _carregandoSessaoCaixaPdv
                    ? Icons.sync_rounded
                    : Icons.lock_open_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _pdvTheme.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final Widget actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed:
                    _carregandoSessaoCaixaPdv ? null : _carregarSessaoCaixaPdv,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.t('common.refresh', fallback: 'Atualizar')),
                style: _pdvOutlinedCtaStyle(),
              ),
              FilledButton.icon(
                onPressed:
                    () =>
                        _abrirOperacoesCaixa(retorno: ModuloCentralPDV.vendas),
                icon: const Icon(Icons.point_of_sale_rounded),
                label: Text(
                  context.t(
                    'pdv.openCashOperations',
                    fallback: 'Operações de caixa',
                  ),
                ),
                style: _pdvFilledCtaStyle(),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                text,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: text),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
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
            final bool exibirResumo =
                _vendaPossuiItens || _consultandoVendaNaoLiquidada;

            return Column(
              children: <Widget>[
                _buildCabecalhoVendaCompacto(),
                const SizedBox(height: 10),
                if (_consultandoVendaNaoLiquidada) ...<Widget>[
                  _buildAvisoVendaNaoLiquidadaEmConsulta(),
                  const SizedBox(height: 10),
                ],
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

  ButtonStyle _pdvOutlinedCtaStyle() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: _pdvTheme.iconColor,
      disabledForegroundColor: tokens.disabledForeground,
      side: BorderSide(color: _pdvTheme.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.disabledBackground.withValues(alpha: 0.22);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return _pdvTheme.iconColor.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: _pdvTheme.cardBorder.withValues(alpha: 0.55),
          );
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return BorderSide(color: _pdvTheme.iconColor.withValues(alpha: 0.42));
        }
        return BorderSide(color: _pdvTheme.cardBorder);
      }),
    );
  }

  ButtonStyle _pdvDangerOutlinedCtaStyle() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: tokens.danger,
      disabledForegroundColor: tokens.disabledForeground,
      side: BorderSide(color: tokens.danger.withValues(alpha: 0.58)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.disabledBackground.withValues(alpha: 0.22);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return tokens.danger.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
    );
  }

  ButtonStyle _pdvFilledCtaStyle() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return FilledButton.styleFrom(
      foregroundColor: _pdvTheme.actionButtonForeground,
      backgroundColor: _pdvTheme.actionButtonBackground,
      disabledForegroundColor: tokens.disabledForeground,
      disabledBackgroundColor: tokens.disabledBackground,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }

  ButtonStyle _pdvTextCtaStyle() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return TextButton.styleFrom(
      foregroundColor: _pdvTheme.iconColor,
      disabledForegroundColor: tokens.disabledForeground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return _pdvTheme.iconColor.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
    );
  }
}

class _PdvAnimatedCurrencyText extends StatefulWidget {
  const _PdvAnimatedCurrencyText({
    required this.value,
    required this.style,
    required this.formatter,
    required this.duration,
    required this.curve,
    this.maxLines,
    this.overflow,
  });

  final double value;
  final TextStyle style;
  final String Function(double) formatter;
  final Duration duration;
  final Curve curve;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<_PdvAnimatedCurrencyText> createState() =>
      _PdvAnimatedCurrencyTextState();
}

class _PdvAnimatedCurrencyTextState extends State<_PdvAnimatedCurrencyText> {
  late double _currentVisualValue;
  late double _animationStartValue;
  late double _targetValue;

  @override
  void initState() {
    super.initState();
    _currentVisualValue = widget.value;
    _animationStartValue = widget.value;
    _targetValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _PdvAnimatedCurrencyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _targetValue) {
      return;
    }

    setState(() {
      _animationStartValue = _currentVisualValue;
      _targetValue = widget.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Duration duration = widget.duration;

    if (duration == Duration.zero) {
      _currentVisualValue = widget.value;
      _animationStartValue = widget.value;
      _targetValue = widget.value;
      return Text(
        widget.formatter(widget.value),
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        style: widget.style,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _animationStartValue, end: _targetValue),
      duration: duration,
      curve: widget.curve,
      builder: (BuildContext context, double animatedValue, Widget? child) {
        _currentVisualValue = animatedValue;
        return Text(
          widget.formatter(animatedValue),
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          style: widget.style,
        );
      },
    );
  }
}
