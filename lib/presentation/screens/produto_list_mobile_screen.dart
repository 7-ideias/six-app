import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/utils/produto_helper.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/produto_cadastrar_mobile_screen.dart';

import '../../data/models/produto_model.dart';
import '../../providers/produtos_list_provider.dart';

class ProdutolistMobileScreen extends StatefulWidget {
  const ProdutolistMobileScreen({super.key, this.isSelecao = false});

  final bool isSelecao;

  @override
  State<ProdutolistMobileScreen> createState() => _ProdutolistMobileScreenState();
}

class _ProdutolistMobileScreenState extends State<ProdutolistMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  final TextEditingController _controllerBusca = TextEditingController();

  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];

  String termoBusca = '';
  String tipoSelecionado = 'PRODUTO';
  String ordenacao = 'nome';

  bool get _isProdutoSelecionado => tipoSelecionado == 'PRODUTO';

  @override
  void initState() {
    super.initState();
    Future.microtask(_recarregar);
  }

  @override
  void dispose() {
    _controllerBusca.dispose();
    super.dispose();
  }

  void atualizarListaComProvider(List<ProdutoModel> listaDeProdutos) {
    todosProdutos = listaDeProdutos;
    aplicarFiltroOrdenacao();
  }

  void aplicarFiltroOrdenacao() {
    final listaBase = ProdutoHelper.filtrarEOrdenarProdutos(
      produtos: todosProdutos,
      termoBusca: termoBusca,
      ordenacao: ordenacao,
    );

    setState(() {
      produtosFiltrados = listaBase
          .where((produto) => _matchesTipoSelecionado(produto, tipoSelecionado))
          .toList();
    });
  }

  bool _matchesTipoSelecionado(ProdutoModel produto, String tipo) {
    final valor = produto.tipoProduto;
    if (valor.trim().isEmpty) {
      return tipo == 'PRODUTO';
    }
    return valor.toUpperCase() == tipo.toUpperCase();
  }

  Future<void> _recarregar() async {
    await ProdutoHelper.retornarProdutosList(
      context,
      tipo: tipoSelecionado,
      onSucesso: atualizarListaComProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itensDaLista =
        produtosFiltrados.isNotEmpty || termoBusca.isNotEmpty || todosProdutos.isNotEmpty
            ? produtosFiltrados
            : todosProdutos;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Produtos e serviços',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
            children: [
              SixStaggeredEntry(child: _buildHeaderCard()),
              const SizedBox(height: 16),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 70),
                child: _buildTabs(),
              ),
              const SizedBox(height: 14),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 120),
                child: _buildSearchField(),
              ),
              const SizedBox(height: 14),
              SixStaggeredEntry(
                delay: const Duration(milliseconds: 170),
                child: _buildSummarySection(),
              ),
              const SizedBox(height: 18),
              _buildListHeader(itensDaLista.length),
              const SizedBox(height: 12),
              if (itensDaLista.isEmpty)
                const _EmptyState()
              else
                ...itensDaLista.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SixStaggeredEntry(
                      delay: Duration(milliseconds: 210 + (entry.key * 35).clamp(0, 220)),
                      child: _buildProdutoCard(entry.value),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isSelecao
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              elevation: 5,
              onPressed: _criarProduto,
              icon: const Icon(Icons.add_rounded),
              label: Text(_isProdutoSelecionado ? 'Novo produto' : 'Novo serviço'),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B1F3A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Icon(
              _isProdutoSelecionado
                  ? Icons.inventory_2_outlined
                  : Icons.design_services_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isProdutoSelecionado ? 'Catálogo de produtos' : 'Catálogo de serviços',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isProdutoSelecionado
                      ? 'Consulte preços, SKU, estoque e disponibilidade.'
                      : 'Consulte serviços, garantias e valores de atendimento.',
                  style: const TextStyle(
                    color: Color(0xFFD7E3F5),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Produtos',
              icon: Icons.inventory_2_outlined,
              selected: _isProdutoSelecionado,
              onTap: () => _selectTipo('PRODUTO'),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Serviços',
              icon: Icons.design_services_outlined,
              selected: tipoSelecionado == 'SERVICO' || tipoSelecionado == 'SERVIÇO',
              onTap: () => _selectTipo('SERVICO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _controllerBusca,
        onChanged: (value) {
          termoBusca = value;
          aplicarFiltroOrdenacao();
        },
        decoration: InputDecoration(
          hintText: _isProdutoSelecionado ? 'Buscar produto ou SKU' : 'Buscar serviço',
          hintStyle: const TextStyle(color: _mutedTextColor),
          prefixIcon: const Icon(Icons.search_rounded, color: _accentColor),
          suffixIcon: _controllerBusca.text.isEmpty
              ? IconButton(
                  icon: const Icon(Icons.tune_rounded, color: _titleTextColor),
                  onPressed: _showSortOptions,
                )
              : IconButton(
                  onPressed: () {
                    _controllerBusca.clear();
                    termoBusca = '';
                    aplicarFiltroOrdenacao();
                  },
                  icon: const Icon(Icons.close_rounded, color: _mutedTextColor),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Consumer<ProdutosListProvider<ProdutoModel>>(
      builder: (context, provider, _) {
        final response = provider.fullResponse;
        if (response is! ProdutoResponseModel) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Itens',
                value: response.skusTotaisNoEstoque.toString(),
                icon: Icons.widgets_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Sem estoque',
                value: _formatNumber(response.qtSemEstoque),
                icon: Icons.inventory_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Valor',
                value: _formatCurrency(response.vlEstoqueEmGrana),
                icon: Icons.payments_outlined,
                compact: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _isProdutoSelecionado ? 'Produtos cadastrados' : 'Serviços cadastrados',
            style: const TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count ${count == 1 ? 'item' : 'itens'}',
            style: const TextStyle(
              color: _accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProdutoCard(ProdutoModel produto) {
    final ativo = produto.ativo == true;
    final bool isProduto = _matchesTipoSelecionado(produto, 'PRODUTO');

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (widget.isSelecao) {
            Navigator.pop(context, produto);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Clicou em ${produto.nomeProduto}')),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isProduto ? Icons.inventory_2_outlined : Icons.design_services_outlined,
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            produto.nomeProduto,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              color: _titleTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(ativo: ativo),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          icon: Icons.qr_code_2_rounded,
                          label: produto.codigoDeBarras.isEmpty
                              ? 'Sem SKU'
                              : 'SKU ${produto.codigoDeBarras}',
                        ),
                        if (produto.modeloProduto.isNotEmpty)
                          _InfoChip(
                            icon: Icons.straighten_rounded,
                            label: produto.modeloProduto,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatCurrency(produto.precoVenda),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _titleTextColor,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTipo(String tipo) {
    if (tipoSelecionado == tipo) return;

    setState(() {
      tipoSelecionado = tipo;
      termoBusca = '';
      _controllerBusca.clear();
    });
    _recarregar();
  }

  void _criarProduto() {
    if (!_isProdutoSelecionado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fluxo mobile em evolução.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CadastroProdutoMobileScreen()),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ordenar catálogo',
                  style: TextStyle(
                    color: _titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _SortOptionTile(
                  title: 'Nome',
                  selected: ordenacao == 'nome',
                  onTap: () => _changeSort('nome'),
                ),
                const SizedBox(height: 10),
                _SortOptionTile(
                  title: 'Menor preço',
                  selected: ordenacao == 'precoAsc',
                  onTap: () => _changeSort('precoAsc'),
                ),
                const SizedBox(height: 10),
                _SortOptionTile(
                  title: 'Maior preço',
                  selected: ordenacao == 'precoDesc',
                  onTap: () => _changeSort('precoDesc'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeSort(String value) {
    Navigator.pop(context);
    ordenacao = value;
    aplicarFiltroOrdenacao();
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        color: selected ? _accentColor : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : _mutedTextColor),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : _mutedTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final int? numericValue = int.tryParse(value);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accentColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _mutedTextColor,
            ),
          ),
          const SizedBox(height: 4),
          if (numericValue == null)
            Text(
              value,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w900,
                color: _titleTextColor,
              ),
            )
          else
            SixAnimatedNumberText(
              value: value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _titleTextColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        ativo ? const Color(0xFFEAF8EE) : const Color(0xFFFEF2F2);
    final Color foregroundColor =
        ativo ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: foregroundColor,
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEFF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.sort_rounded,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Color(0xFF64748B)),
          SizedBox(height: 12),
          Text(
            'Nenhum item encontrado',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tente outro termo de busca ou altere a aba selecionada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.35),
          ),
        ],
      ),
    );
  }
}
