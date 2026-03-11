import 'package:appplanilha/core/enums/tipo_cadastro_enum.dart';
import 'package:appplanilha/core/utils/produto_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/produto_model.dart';
import '../../design_system/components/mobile/mobile_gereneral.dart';
import '../../providers/produtos_list_provider.dart';


class ProdutolistMobileScreen extends MobileGeneralScreen {
  ProdutolistMobileScreen({super.key})
      : super(
    body: SafeArea(
      child: ProdutoListaBody(),
    ),
    textoDaAppBar: 'Lista de Produtos',
    tipoCadastroEnum: TipoCadastroEnum.PRODUTOS_E_OU_SERVICOS,
  );
}


// class ProdutolistMobileScreen extends MobileGeneralScreen {
//   ProdutolistMobileScreen({super.key})
//       : super(
//     body: const ProdutoListaBody(),
//     textoDaAppBar: 'Lista de Produtos',
//     tipoCadastroEnum: TipoCadastroEnum.PRODUTOS_E_OU_SERVICOS,
//   );
// }

class ProdutoListaBody extends StatefulWidget {
  const ProdutoListaBody({super.key});

  @override
  State<ProdutoListaBody> createState() => _ProdutoListaBodyState();
}

class _ProdutoListaBodyState extends State<ProdutoListaBody> {
  final TextEditingController _controllerBusca = TextEditingController();

  List<ProdutoModel> todosProdutos = [];
  List<ProdutoModel> produtosFiltrados = [];

  String termoBusca = '';
  String tipoSelecionado = 'PRODUTO';
  String ordenacao = 'nome';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ProdutoHelper.retornarProdutosList(
        context,
        onSucesso: atualizarListaComProvider,
      );
    });
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
    final dynamic p = produto;

    try {
      final dynamic valor =
          p.tipoProduto ??
              p.tipoPoduto ??
              p.tipoCadastro ??
              p.tipo ??
              p.categoria;

      if (valor == null) {
        return tipo == 'PRODUTO';
      }

      return valor.toString().toUpperCase() == tipo.toUpperCase();
    } catch (_) {
      return tipo == 'PRODUTO';
    }
  }

  Future<void> _recarregar() async {
    await ProdutoHelper.retornarProdutosList(
      context,
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
      backgroundColor: const Color(0xFFF6F7FB),
      body: Column(
        children: [
          _buildTabs(),
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildSummarySection(),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recarregar,
              child: itensDaLista.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  _EmptyState(),
                ],
              )
                  : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: itensDaLista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final produto = itensDaLista[index];
                  return _buildProdutoCard(produto);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controllerBusca,
        onChanged: (value) {
          termoBusca = value;
          aplicarFiltroOrdenacao();
        },
        decoration: InputDecoration(
          hintText: 'Buscar produto ou SKU',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _controllerBusca.text.isEmpty
              ? null
              : IconButton(
            onPressed: () {
              _controllerBusca.clear();
              termoBusca = '';
              aplicarFiltroOrdenacao();
            },
            icon: const Icon(Icons.close_rounded),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.3),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                label: 'Produtos',
                selected: tipoSelecionado == 'PRODUTO',
                onTap: () {
                  setState(() {
                    tipoSelecionado = 'PRODUTO';
                  });
                  aplicarFiltroOrdenacao();
                },
              ),
            ),
            Expanded(
              child: _TabButton(
                label: 'Serviços',
                selected: tipoSelecionado == 'SERVICO' ||
                    tipoSelecionado == 'SERVIÇO',
                onTap: () {
                  setState(() {
                    tipoSelecionado = 'SERVICO';
                  });
                  aplicarFiltroOrdenacao();
                },
              ),
            ),
          ],
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Itens',
                  value: response.itensTotaisNoEstoque.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Sem estoque',
                  value: response.qtSemEstoque.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Valor',
                  value: 'R\$ ${response.vlEstoqueEmGrana.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProdutoCard(ProdutoModel produto) {
    final ativo = produto.ativo == true;

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Clicou em ${produto.nomeProduto}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nomeProduto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SKU: ${produto.codigoDeBarras}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'R\$ ${produto.precoVenda.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(ativo: ativo),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: Material(
        color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool ativo;

  const _StatusChip({required this.ativo});

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
    ativo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final foregroundColor =
    ativo ? const Color(0xFF166534) : const Color(0xFF991B1B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 56,
          color: Color(0xFF9CA3AF),
        ),
        SizedBox(height: 12),
        Text(
          'Nenhum item encontrado',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Tente outro termo de busca ou altere a aba selecionada.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}