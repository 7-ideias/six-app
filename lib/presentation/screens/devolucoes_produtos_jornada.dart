import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/caixa_models.dart';
import '../../data/models/devolucao_produto_models.dart';
import '../../data/models/produto_model.dart';
import '../../data/services/devolucao_produto/devolucao_produto_api_client.dart';
import '../../domain/services/devolucao_produto/devolucao_produto_service.dart';
import '../../providers/locale_settings_provider.dart';
import '../theme/web_theme_tokens.dart';

class DevolucoesProdutosJornada extends StatefulWidget {
  const DevolucoesProdutosJornada({
    super.key,
    required this.web,
    this.scrollController,
    this.padding,
    this.service,
  });

  final bool web;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final DevolucaoProdutoService? service;

  @override
  State<DevolucoesProdutosJornada> createState() =>
      _DevolucoesProdutosJornadaState();
}

class _DevolucoesProdutosJornadaState
    extends State<DevolucoesProdutosJornada> {
  final TextEditingController _identificadorController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  late final DevolucaoProdutoService _service;

  VendaElegivelDevolucao? _venda;
  TipoDevolucaoProduto _tipo = TipoDevolucaoProduto.devolucao;
  final Map<String, _ItemDevolucaoEdicao> _itens =
      <String, _ItemDevolucaoEdicao>{};
  final Map<String, _ItemTrocaEdicao> _itensTroca =
      <String, _ItemTrocaEdicao>{};

  List<ProdutoModel> _produtosTroca = <ProdutoModel>[];
  List<TiposRecebimento> _tiposAcerto = <TiposRecebimento>[];
  List<DevolucaoProdutoResponse> _recentes = <DevolucaoProdutoResponse>[];

  String? _produtoTrocaSelecionadoId;
  String? _codigoTipoRecebimento;
  String? _chaveIdempotenciaAtual;
  String? _erro;
  DevolucaoProdutoResponse? _resultado;

  bool _carregandoApoio = true;
  bool _buscandoVenda = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? DevolucaoProdutoService();
    _carregarApoio();
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    _observacoesController.dispose();
    _descartarEditores();
    super.dispose();
  }

  Future<void> _carregarApoio() async {
    if (mounted) {
      setState(() {
        _carregandoApoio = true;
        _erro = null;
      });
    }

    try {
      final List<dynamic> resultados = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.listarProdutosParaTroca(),
        _service.listarTiposDeAcertoImediato(),
        _service.listarRecentes(),
      ]);
      if (!mounted) return;
      setState(() {
        _produtosTroca = resultados[0] as List<ProdutoModel>;
        _tiposAcerto = resultados[1] as List<TiposRecebimento>;
        _recentes = resultados[2] as List<DevolucaoProdutoResponse>;
        if (_tiposAcerto.isNotEmpty && _codigoTipoRecebimento == null) {
          _codigoTipoRecebimento = _tiposAcerto.first.codigoTipo;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) setState(() => _carregandoApoio = false);
    }
  }

  Future<void> _buscarVenda() async {
    FocusScope.of(context).unfocus();
    final String identificador = _identificadorController.text.trim();
    if (identificador.isEmpty) {
      _mostrarMensagem('Informe o código ou identificador da venda.');
      return;
    }

    setState(() {
      _buscandoVenda = true;
      _erro = null;
      _resultado = null;
    });

    try {
      final VendaElegivelDevolucao venda =
          await _service.buscarVendaElegivel(identificador);
      if (!mounted) return;
      _descartarEditores();
      setState(() {
        _venda = venda;
        _tipo = TipoDevolucaoProduto.devolucao;
        _chaveIdempotenciaAtual = null;
        _itensTroca.clear();
        for (final ItemVendaElegivelDevolucao item in venda.itens) {
          if (item.quantidadeDisponivel <= 0) continue;
          _itens[item.idItemVenda] = _ItemDevolucaoEdicao(item);
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _venda = null;
        _erro = _mensagemErro(error);
      });
    } finally {
      if (mounted) setState(() => _buscandoVenda = false);
    }
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    final VendaElegivelDevolucao? venda = _venda;
    if (venda == null) return;

    final List<ItemDevolvidoRequest> devolvidos = <ItemDevolvidoRequest>[];
    for (final _ItemDevolucaoEdicao edicao in _itens.values) {
      if (!edicao.selecionado) continue;
      final double? quantidade = _numero(edicao.quantidadeController.text);
      if (quantidade == null || quantidade <= 0) {
        _mostrarMensagem('Informe uma quantidade válida para ${edicao.item.nomeProduto}.');
        return;
      }
      if (quantidade - edicao.item.quantidadeDisponivel > 0.0001) {
        _mostrarMensagem(
          'A quantidade de ${edicao.item.nomeProduto} supera o saldo devolvível.',
        );
        return;
      }
      final String motivo = edicao.motivoController.text.trim();
      if (motivo.isEmpty) {
        _mostrarMensagem('Informe o motivo da devolução de ${edicao.item.nomeProduto}.');
        return;
      }
      devolvidos.add(
        ItemDevolvidoRequest(
          idItemVenda: edicao.item.idItemVenda,
          quantidade: quantidade,
          motivo: motivo,
          condicao: edicao.condicao,
          retornarAoEstoque: edicao.retornarAoEstoque,
        ),
      );
    }

    if (devolvidos.isEmpty) {
      _mostrarMensagem('Selecione pelo menos um produto para devolver.');
      return;
    }

    final List<ItemTrocaRequest> trocas = <ItemTrocaRequest>[];
    if (_tipo == TipoDevolucaoProduto.troca) {
      for (final _ItemTrocaEdicao edicao in _itensTroca.values) {
        final double? quantidade = _numero(edicao.quantidadeController.text);
        if (quantidade == null || quantidade <= 0) {
          _mostrarMensagem(
            'Informe uma quantidade válida para ${edicao.produto.nomeProduto}.',
          );
          return;
        }
        trocas.add(
          ItemTrocaRequest(
            idProduto: edicao.produto.id!,
            quantidade: quantidade,
          ),
        );
      }
      if (trocas.isEmpty) {
        _mostrarMensagem('Adicione pelo menos um produto para a troca.');
        return;
      }
    }

    final double saldo = _saldoFinanceiro;
    if (saldo.abs() > 0.009 &&
        (_codigoTipoRecebimento == null ||
            _codigoTipoRecebimento!.trim().isEmpty)) {
      _mostrarMensagem('Selecione a forma usada no acerto da diferença.');
      return;
    }

    final String chave = _chaveIdempotenciaAtual ?? _novaChaveIdempotencia();
    _chaveIdempotenciaAtual = chave;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final DevolucaoProdutoResponse resultado = await _service.registrar(
        RegistrarDevolucaoProdutoRequest(
          chaveIdempotencia: chave,
          identificadorVenda: venda.idOperacao,
          tipo: _tipo,
          itensDevolvidos: devolvidos,
          itensTroca: trocas,
          codigoTipoRecebimento:
              saldo.abs() > 0.009 ? _codigoTipoRecebimento : null,
          observacoes: _observacoesController.text,
        ),
      );
      if (!mounted) return;

      _descartarEditores();
      setState(() {
        _resultado = resultado;
        _venda = null;
        _identificadorController.clear();
        _observacoesController.clear();
        _itensTroca.clear();
        _chaveIdempotenciaAtual = null;
      });
      await _recarregarRecentes();
      if (!mounted) return;
      _mostrarMensagem(
        'Operação ${resultado.codigoDevolucao} concluída com sucesso.',
        sucesso: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _mensagemErro(error));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _recarregarRecentes() async {
    try {
      final List<DevolucaoProdutoResponse> recentes =
          await _service.listarRecentes();
      if (mounted) setState(() => _recentes = recentes);
    } catch (_) {
      // A operação principal já foi concluída; falha no histórico não a invalida.
    }
  }

  void _descartarEditores() {
    for (final _ItemDevolucaoEdicao item in _itens.values) {
      item.dispose();
    }
    for (final _ItemTrocaEdicao item in _itensTroca.values) {
      item.dispose();
    }
    _itens.clear();
    _itensTroca.clear();
  }

  void _invalidarChave() {
    _chaveIdempotenciaAtual = null;
    _resultado = null;
  }

  void _adicionarProdutoTroca() {
    final String? id = _produtoTrocaSelecionadoId;
    if (id == null || id.isEmpty) return;
    final ProdutoModel? produto = _produtoPorId(id);
    if (produto == null) return;

    setState(() {
      _invalidarChave();
      final _ItemTrocaEdicao? existente = _itensTroca[id];
      if (existente == null) {
        _itensTroca[id] = _ItemTrocaEdicao(produto);
      } else {
        final double quantidade = _numero(existente.quantidadeController.text) ?? 0;
        existente.quantidadeController.text = _quantidadeTexto(quantidade + 1);
      }
      _produtoTrocaSelecionadoId = null;
    });
  }

  ProdutoModel? _produtoPorId(String id) {
    for (final ProdutoModel produto in _produtosTroca) {
      if (produto.id == id) return produto;
    }
    return null;
  }

  double get _totalDevolvido {
    double total = 0;
    for (final _ItemDevolucaoEdicao edicao in _itens.values) {
      if (!edicao.selecionado) continue;
      total += (_numero(edicao.quantidadeController.text) ?? 0) *
          edicao.item.valorUnitario;
    }
    return total;
  }

  double get _totalTroca {
    if (_tipo != TipoDevolucaoProduto.troca) return 0;
    double total = 0;
    for (final _ItemTrocaEdicao edicao in _itensTroca.values) {
      total += (_numero(edicao.quantidadeController.text) ?? 0) *
          edicao.produto.precoVenda;
    }
    return total;
  }

  double get _saldoFinanceiro => _totalTroca - _totalDevolvido;

  String _novaChaveIdempotencia() {
    final int aleatorio = Random.secure().nextInt(0x7fffffff);
    return 'dev-${DateTime.now().microsecondsSinceEpoch}-$aleatorio';
  }

  double? _numero(String value) {
    final String normalizado = value.trim().replaceAll('.', '').replaceAll(',', '.');
    if (value.contains('.') && !value.contains(',')) {
      return double.tryParse(value.trim());
    }
    return double.tryParse(normalizado);
  }

  String _quantidadeTexto(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  String _moeda(double value) {
    try {
      return context.read<LocaleSettingsProvider>().formatCurrency(value);
    } catch (_) {
      return value.toStringAsFixed(2);
    }
  }

  String _mensagemErro(Object error) {
    if (error is DevolucaoProdutoApiException) return error.mensagemUsuario;
    if (error is DevolucaoProdutoValidacaoException) return error.mensagem;
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _mostrarMensagem(String mensagem, {bool sucesso = false}) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor: sucesso ? const Color(0xFF047857) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background = widget.web
        ? WebThemeTokens.of(context).workspaceBackground
        : theme.colorScheme.surface;
    final EdgeInsetsGeometry padding = widget.padding ??
        EdgeInsets.fromLTRB(widget.web ? 24 : 16, 18, widget.web ? 24 : 16, 32);

    return ColoredBox(
      color: background,
      child: RefreshIndicator(
        onRefresh: _carregarApoio,
        child: ListView(
          controller: widget.scrollController,
          padding: padding,
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildCabecalho(),
                    const SizedBox(height: 16),
                    if (_erro != null) ...<Widget>[
                      _buildErro(),
                      const SizedBox(height: 16),
                    ],
                    if (_resultado != null) ...<Widget>[
                      _buildResultado(),
                      const SizedBox(height: 16),
                    ],
                    _buildBuscaVenda(),
                    if (_venda != null) ...<Widget>[
                      const SizedBox(height: 16),
                      _buildResumoVenda(),
                      const SizedBox(height: 16),
                      _buildItensDevolucao(),
                      const SizedBox(height: 16),
                      _buildTipoOperacao(),
                      if (_tipo == TipoDevolucaoProduto.troca) ...<Widget>[
                        const SizedBox(height: 16),
                        _buildItensTroca(),
                      ],
                      const SizedBox(height: 16),
                      _buildAcertoFinanceiro(),
                      const SizedBox(height: 16),
                      _buildConfirmacao(),
                    ],
                    const SizedBox(height: 20),
                    _buildRecentes(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Devoluções e trocas',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Localize a venda, selecione os produtos e conclua estoque e acerto financeiro em uma única jornada.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildErro() {
    final ThemeData theme = Theme.of(context);
    return _SectionCard(
      borderColor: theme.colorScheme.error.withValues(alpha: 0.45),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _erro!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => setState(() => _erro = null),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    final DevolucaoProdutoResponse resultado = _resultado!;
    return _SectionCard(
      borderColor: const Color(0xFF10B981).withValues(alpha: 0.50),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Operação concluída',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${resultado.codigoDevolucao} • ${resultado.tipo} • ${resultado.status}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscaVenda() {
    return _SectionCard(
      title: '1. Localizar venda',
      subtitle: 'Use o identificador interno ou o código mostrado no comprovante.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool empilhar = constraints.maxWidth < 620;
          final Widget campo = TextField(
            controller: _identificadorController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscarVenda(),
            decoration: const InputDecoration(
              labelText: 'Código ou ID da venda',
              prefixIcon: Icon(Icons.receipt_long_outlined),
              border: OutlineInputBorder(),
            ),
          );
          final Widget botao = FilledButton.icon(
            onPressed: _buscandoVenda ? null : _buscarVenda,
            icon: _buscandoVenda
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(_buscandoVenda ? 'Buscando...' : 'Buscar venda'),
          );

          if (empilhar) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[campo, const SizedBox(height: 12), botao],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: campo),
              const SizedBox(width: 12),
              SizedBox(height: 56, child: botao),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumoVenda() {
    final VendaElegivelDevolucao venda = _venda!;
    return _SectionCard(
      title: 'Venda encontrada',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          _InfoChip(icon: Icons.tag_rounded, label: venda.codigoOperacao.isEmpty ? venda.idOperacao : venda.codigoOperacao),
          _InfoChip(icon: Icons.person_outline_rounded, label: venda.nomeCliente.isEmpty ? 'Cliente não identificado' : venda.nomeCliente),
          _InfoChip(icon: Icons.payments_outlined, label: _moeda(venda.valorTotalProdutos)),
          _InfoChip(
            icon: venda.possuiItensElegiveis
                ? Icons.check_circle_outline_rounded
                : Icons.block_rounded,
            label: venda.possuiItensElegiveis
                ? 'Possui itens devolvíveis'
                : 'Sem saldo devolvível',
          ),
        ],
      ),
    );
  }

  Widget _buildItensDevolucao() {
    return _SectionCard(
      title: '2. Produtos que retornam do cliente',
      subtitle: 'A quantidade disponível já desconta devoluções anteriores.',
      child: Column(
        children: <Widget>[
          for (final _ItemDevolucaoEdicao edicao in _itens.values) ...<Widget>[
            _buildItemDevolucao(edicao),
            if (edicao != _itens.values.last) const Divider(height: 28),
          ],
          if (_itens.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Esta venda não possui itens disponíveis para devolução.'),
            ),
        ],
      ),
    );
  }

  Widget _buildItemDevolucao(_ItemDevolucaoEdicao edicao) {
    final ThemeData theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: edicao.selecionado
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: edicao.selecionado
              ? theme.colorScheme.primary.withValues(alpha: 0.28)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: <Widget>[
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: edicao.selecionado,
            onChanged: (bool? value) {
              setState(() {
                _invalidarChave();
                edicao.selecionado = value == true;
              });
            },
            title: Text(
              edicao.item.nomeProduto,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Vendido: ${_quantidadeTexto(edicao.item.quantidadeVendida)} • Já devolvido: ${_quantidadeTexto(edicao.item.quantidadeJaDevolvida)} • Disponível: ${_quantidadeTexto(edicao.item.quantidadeDisponivel)} • ${_moeda(edicao.item.valorUnitario)} cada',
            ),
          ),
          if (edicao.selecionado) ...<Widget>[
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool empilhar = constraints.maxWidth < 720;
                final List<Widget> campos = <Widget>[
                  TextField(
                    controller: edicao.quantidadeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(_invalidarChave),
                    decoration: InputDecoration(
                      labelText: 'Quantidade',
                      helperText: 'Máx. ${_quantidadeTexto(edicao.item.quantidadeDisponivel)}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  DropdownButtonFormField<CondicaoProdutoDevolvido>(
                    value: edicao.condicao,
                    decoration: const InputDecoration(
                      labelText: 'Condição do produto',
                      border: OutlineInputBorder(),
                    ),
                    items: CondicaoProdutoDevolvido.values
                        .map(
                          (CondicaoProdutoDevolvido value) => DropdownMenuItem<CondicaoProdutoDevolvido>(
                            value: value,
                            child: Text(_condicaoLabel(value)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (CondicaoProdutoDevolvido? value) {
                      if (value == null) return;
                      setState(() {
                        _invalidarChave();
                        edicao.condicao = value;
                        if (value == CondicaoProdutoDevolvido.comDefeito ||
                            value == CondicaoProdutoDevolvido.avariado) {
                          edicao.retornarAoEstoque = false;
                        }
                      });
                    },
                  ),
                ];
                if (empilhar) {
                  return Column(
                    children: <Widget>[
                      campos[0],
                      const SizedBox(height: 12),
                      campos[1],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: campos[0]),
                    const SizedBox(width: 12),
                    Expanded(child: campos[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: edicao.motivoController,
              onChanged: (_) => _invalidarChave(),
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo da devolução',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: edicao.retornarAoEstoque,
              onChanged: (bool value) {
                setState(() {
                  _invalidarChave();
                  edicao.retornarAoEstoque = value;
                });
              },
              title: const Text('Retornar quantidade ao estoque'),
              subtitle: Text(
                edicao.retornarAoEstoque
                    ? 'O saldo disponível do produto será recomposto.'
                    : 'A devolução será registrada sem recompor o estoque.',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoOperacao() {
    return _SectionCard(
      title: '3. Destino comercial',
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: <Widget>[
          ChoiceChip(
            selected: _tipo == TipoDevolucaoProduto.devolucao,
            avatar: const Icon(Icons.assignment_return_outlined, size: 18),
            label: const Text('Somente devolução'),
            onSelected: (_) {
              setState(() {
                _invalidarChave();
                _tipo = TipoDevolucaoProduto.devolucao;
              });
            },
          ),
          ChoiceChip(
            selected: _tipo == TipoDevolucaoProduto.troca,
            avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Trocar por outros produtos'),
            onSelected: (_) {
              setState(() {
                _invalidarChave();
                _tipo = TipoDevolucaoProduto.troca;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItensTroca() {
    final Set<String> idsAdicionados = _itensTroca.keys.toSet();
    final List<ProdutoModel> disponiveis = _produtosTroca
        .where((ProdutoModel produto) => !idsAdicionados.contains(produto.id))
        .toList(growable: false);

    return _SectionCard(
      title: '4. Produtos que o cliente receberá',
      subtitle: 'Os produtos selecionados sairão do estoque pelo preço atual do cadastro.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool empilhar = constraints.maxWidth < 620;
              final Widget seletor = DropdownButtonFormField<String>(
                value: disponiveis.any(
                  (ProdutoModel item) => item.id == _produtoTrocaSelecionadoId,
                )
                    ? _produtoTrocaSelecionadoId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Produto de troca',
                  border: OutlineInputBorder(),
                ),
                items: disponiveis
                    .map(
                      (ProdutoModel produto) => DropdownMenuItem<String>(
                        value: produto.id,
                        child: Text(
                          '${produto.nomeProduto} • ${_moeda(produto.precoVenda)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (String? value) {
                  setState(() => _produtoTrocaSelecionadoId = value);
                },
              );
              final Widget botao = FilledButton.icon(
                onPressed: _produtoTrocaSelecionadoId == null
                    ? null
                    : _adicionarProdutoTroca,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar'),
              );
              if (empilhar) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    seletor,
                    const SizedBox(height: 12),
                    botao,
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(child: seletor),
                  const SizedBox(width: 12),
                  SizedBox(height: 56, child: botao),
                ],
              );
            },
          ),
          if (_carregandoApoio) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_itensTroca.isNotEmpty) const SizedBox(height: 16),
          for (final _ItemTrocaEdicao edicao in _itensTroca.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          edicao.produto.nomeProduto,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text('${_moeda(edicao.produto.precoVenda)} por unidade'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: edicao.quantidadeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(_invalidarChave),
                      decoration: const InputDecoration(
                        labelText: 'Qtd.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover',
                    onPressed: () {
                      setState(() {
                        _invalidarChave();
                        _itensTroca.remove(edicao.produto.id)?.dispose();
                      });
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcertoFinanceiro() {
    final double saldo = _saldoFinanceiro;
    final bool diferenca = saldo.abs() > 0.009;
    final String orientacao = saldo > 0.009
        ? 'O cliente paga a diferença.'
        : saldo < -0.009
            ? 'A empresa reembolsa o cliente.'
            : 'Não haverá movimento financeiro.';

    return _SectionCard(
      title: _tipo == TipoDevolucaoProduto.troca
          ? '5. Acerto financeiro'
          : '4. Reembolso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: <Widget>[
              _ValueCard(label: 'Produtos devolvidos', value: _moeda(_totalDevolvido)),
              _ValueCard(label: 'Produtos da troca', value: _moeda(_totalTroca)),
              _ValueCard(
                label: saldo >= 0 ? 'Diferença a receber' : 'Valor a reembolsar',
                value: _moeda(saldo.abs()),
                emphasized: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(orientacao, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (diferenca) ...<Widget>[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _tiposAcerto.any(
                (TiposRecebimento item) =>
                    item.codigoTipo == _codigoTipoRecebimento,
              )
                  ? _codigoTipoRecebimento
                  : null,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento ou reembolso',
                border: OutlineInputBorder(),
                helperText: 'Exige sessão de caixa aberta.',
              ),
              items: _tiposAcerto
                  .map(
                    (TiposRecebimento item) => DropdownMenuItem<String>(
                      value: item.codigoTipo,
                      child: Text(item.descricaoExibicao),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (String? value) {
                setState(() {
                  _invalidarChave();
                  _codigoTipoRecebimento = value;
                });
              },
            ),
            if (_tiposAcerto.isEmpty && !_carregandoApoio) ...<Widget>[
              const SizedBox(height: 10),
              const Text(
                'Nenhuma forma imediata ativa foi encontrada. Configure as formas de recebimento antes de concluir.',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmacao() {
    return _SectionCard(
      title: _tipo == TipoDevolucaoProduto.troca
          ? '6. Revisar e concluir'
          : '5. Revisar e concluir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _observacoesController,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => _invalidarChave(),
            decoration: const InputDecoration(
              labelText: 'Observações internas (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _salvando ? null : _registrar,
            icon: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              _salvando
                  ? 'Processando...'
                  : _tipo == TipoDevolucaoProduto.troca
                      ? 'Concluir troca'
                      : 'Concluir devolução',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A confirmação movimenta o estoque e, quando houver diferença, registra o movimento financeiro no caixa.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentes() {
    return _SectionCard(
      title: 'Operações recentes',
      subtitle: 'Últimas devoluções e trocas concluídas nesta empresa.',
      trailing: IconButton(
        tooltip: 'Atualizar',
        onPressed: _carregandoApoio ? null : _carregarApoio,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: _recentes.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Nenhuma devolução ou troca concluída recentemente.'),
            )
          : Column(
              children: <Widget>[
                for (int index = 0; index < _recentes.length; index++) ...<Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Icon(
                        _recentes[index].tipo == 'TROCA'
                            ? Icons.swap_horiz_rounded
                            : Icons.assignment_return_outlined,
                      ),
                    ),
                    title: Text(
                      _recentes[index].codigoDevolucao,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${_recentes[index].nomeCliente.isEmpty ? 'Cliente não identificado' : _recentes[index].nomeCliente} • ${_recentes[index].tipo}',
                    ),
                    trailing: Text(
                      _moeda(_recentes[index].saldoFinanceiro.abs()),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (index < _recentes.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }

  String _condicaoLabel(CondicaoProdutoDevolvido value) {
    return switch (value) {
      CondicaoProdutoDevolvido.novo => 'Novo / lacrado',
      CondicaoProdutoDevolvido.aberto => 'Aberto',
      CondicaoProdutoDevolvido.usado => 'Usado',
      CondicaoProdutoDevolvido.comDefeito => 'Com defeito',
      CondicaoProdutoDevolvido.avariado => 'Avariado',
      CondicaoProdutoDevolvido.outro => 'Outra condição',
    };
  }
}

class _ItemDevolucaoEdicao {
  _ItemDevolucaoEdicao(this.item)
      : quantidadeController = TextEditingController(
          text: item.quantidadeDisponivel >= 1
              ? '1'
              : item.quantidadeDisponivel.toString(),
        ),
        motivoController = TextEditingController();

  final ItemVendaElegivelDevolucao item;
  final TextEditingController quantidadeController;
  final TextEditingController motivoController;
  bool selecionado = false;
  bool retornarAoEstoque = true;
  CondicaoProdutoDevolvido condicao = CondicaoProdutoDevolvido.novo;

  void dispose() {
    quantidadeController.dispose();
    motivoController.dispose();
  }
}

class _ItemTrocaEdicao {
  _ItemTrocaEdicao(this.produto)
      : quantidadeController = TextEditingController(text: '1');

  final ProdutoModel produto;
  final TextEditingController quantidadeController;

  void dispose() => quantidadeController.dispose();
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.borderColor,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens? webTokens =
        theme.extension<WebThemeTokens>();
    final Color surface = webTokens?.cardBackground ?? theme.colorScheme.surface;
    final Color border = borderColor ??
        webTokens?.cardBorder ??
        theme.colorScheme.outlineVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null || trailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          if (title != null || subtitle != null) const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasized
            ? theme.colorScheme.primary.withValues(alpha: 0.09)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasized
              ? theme.colorScheme.primary.withValues(alpha: 0.30)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
