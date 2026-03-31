
import 'package:appplanilha/presentation/screens/agenda_financeira_web.dart';
import 'package:appplanilha/presentation/screens/ordem_servico_web.dart';
import 'package:appplanilha/presentation/screens/pdv_page_web_orcamento.dart';
import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/presentation/screens/recebimento_pagamento_web.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/produto_model.dart';
import 'core/di/operacao_module.dart';
import 'design_system/themes/zebra_list_item.dart';
import 'domain/services/operacao/operacao_service.dart';
import 'top_navigation_bar.dart';

class PDVWeb extends StatefulWidget {
  const PDVWeb({super.key});

  @override
  State<PDVWeb> createState() => _PDVWebState();
}

class _PDVWebState extends State<PDVWeb> {

  final OperacaoService _operacaoService = OperacaoModule.operacaoService;

  bool _mostrarDashboardLateral = true;
  bool _mostrarAreaVenda = false;

  final List<Map<String, dynamic>> _produtosSelecionados = [];
  final Set<String> _formasSelecionadas = {};

  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _itensTotalController =
  TextEditingController(text: '0');
  final TextEditingController _clienteIdentificadoController =
  TextEditingController();

  void _logInfo(String message) {
    debugPrint('[PDVWeb][INFO] $message');
  }

  void _logError(
      String errorContext,
      Object error,
      StackTrace stackTrace,
      ) {
    debugPrint('[PDVWeb][ERROR] $errorContext');
    debugPrint('[PDVWeb][ERROR] $error');
    debugPrint('[PDVWeb][STACK] $stackTrace');

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'pdv_page_web',
        context: ErrorDescription(errorContext),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _logInfo('PDVWeb iniciado');
    _atualizarCamposDerivados();
  }

  @override
  void dispose() {
    _codigoBarrasController.dispose();
    _itensTotalController.dispose();
    _clienteIdentificadoController.dispose();
    super.dispose();
  }

  Future<void> _abrirSelecaoProdutoWeb() async {
    try {
      _logInfo('Abrindo dialog de seleção de produto');

      final result = await showDialog<ProdutoModel>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: SubPainelWebProdutoLista(isSelecao: true),
            ),
          );
        },
      );

      _logInfo(
        'Dialog de seleção fechado. Retorno nulo? ${result == null}',
      );

      if (result != null) {
        _logInfo(
          'Produto retornado: nome=${result.nomeProduto}, codigo=${result.codigoDeBarras}, preco=${result.precoVenda}',
        );
        _adicionarProdutoSelecionado(result);
      }
    } catch (error, stackTrace) {
      _logError('Erro ao abrir seleção de produto web', error, stackTrace);
      if (mounted) {
        _mostrarDialogMensagem(
          'Erro',
          'Falha ao abrir a seleção de produtos. Veja os logs.',
        );
      }
    }
  }

  void _iniciarVenda() {
    setState(() {
      _mostrarAreaVenda = true;
    });
  }

  Future<void> _confirmarCancelamentoVenda() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar venda'),
          content: const Text(
            'Deseja realmente cancelar a venda atual?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      _cancelarVenda();
    }
  }

  void _cancelarVenda() {
    try {
      _logInfo('Cancelando venda atual');

      setState(() {
        _produtosSelecionados.clear();
        _formasSelecionadas.clear();
        _codigoBarrasController.clear();
        _itensTotalController.text = '0';
        _clienteIdentificadoController.clear();
        _mostrarAreaVenda = false;
      });
    } catch (error, stackTrace) {
      _logError('Erro ao cancelar venda', error, stackTrace);
      _mostrarDialogMensagem(
        'Erro',
        'Falha ao cancelar a venda. Veja os logs.',
      );
    }
  }

  void _adicionarProdutoSelecionado(ProdutoModel produto) {
    try {
      _logInfo(
        'Adicionando produto selecionado: nome=${produto.nomeProduto}, codigo=${produto.codigoDeBarras}, preco=${produto.precoVenda}',
      );

      setState(() {
        final indexExistente = _produtosSelecionados.indexWhere(
              (item) => _mesmoProduto(item, produto),
        );

        if (indexExistente >= 0) {
          _produtosSelecionados[indexExistente]['quantidade'] =
              (_produtosSelecionados[indexExistente]['quantidade'] ?? 1) + 1;

          _logInfo(
            'Produto já existia. Nova quantidade=${_produtosSelecionados[indexExistente]['quantidade']}',
          );
        } else {
          _produtosSelecionados.add({
            'id': _extrairIdProduto(produto),
            'codigo': produto.codigoDeBarras,
            'nome': produto.nomeProduto,
            'preco': (produto.precoVenda as num).toDouble(),
            'quantidade': 1,
            'produtoOriginal': produto,
          });

          _logInfo(
            'Produto incluído na lista. Total de linhas=${_produtosSelecionados.length}',
          );
        }

        _atualizarCamposDerivados();
      });

      _logInfo(
        'Estado após inclusão: linhas=${_produtosSelecionados.length}, itens=${_calcularQuantidadeItens()}, total=${_calcularTotal()}',
      );
    } catch (error, stackTrace) {
      _logError('Erro ao adicionar produto selecionado', error, stackTrace);
      _mostrarDialogMensagem(
        'Erro',
        'Falha ao adicionar o produto. Veja os logs.',
      );
    }
  }

  bool _mesmoProduto(Map<String, dynamic> item, ProdutoModel produto) {
    try {
      final idItem = item['id'];
      final idProduto = _extrairIdProduto(produto);

      if (idItem != null && idProduto != null) {
        return idItem == idProduto;
      }

      final codigoItem = item['codigo']?.toString();
      final codigoProduto = produto.codigoDeBarras?.toString();

      if (codigoItem != null &&
          codigoItem.isNotEmpty &&
          codigoProduto != null &&
          codigoProduto.isNotEmpty) {
        return codigoItem == codigoProduto;
      }

      return item['nome'] == produto.nomeProduto;
    } catch (error, stackTrace) {
      _logError('Erro ao comparar produto existente', error, stackTrace);
      return false;
    }
  }

  dynamic _extrairIdProduto(ProdutoModel produto) {
    try {
      final dynamic p = produto;
      return p.id ?? p.uuid ?? p.idUnico ?? p.codigo;
    } catch (error, stackTrace) {
      _logError('Erro ao extrair id do produto', error, stackTrace);
      return null;
    }
  }

  void _alterarQuantidade(Map<String, dynamic> produto, int delta) {
    try {
      _logInfo(
        'Alterando quantidade. Produto=${produto['nome']}, delta=$delta',
      );

      setState(() {
        final quantidadeAtual = (produto['quantidade'] ?? 1) as int;
        final novaQuantidade = quantidadeAtual + delta;

        if (novaQuantidade <= 0) {
          _produtosSelecionados.remove(produto);
          _logInfo('Produto removido por quantidade <= 0');
        } else {
          produto['quantidade'] = novaQuantidade;
          _logInfo('Nova quantidade=$novaQuantidade');
        }

        _atualizarCamposDerivados();
      });
    } catch (error, stackTrace) {
      _logError('Erro ao alterar quantidade', error, stackTrace);
    }
  }

  void _removerProduto(Map<String, dynamic> produto) {
    try {
      _logInfo('Removendo produto=${produto['nome']}');
      setState(() {
        _produtosSelecionados.remove(produto);
        _atualizarCamposDerivados();
      });
    } catch (error, stackTrace) {
      _logError('Erro ao remover produto', error, stackTrace);
    }
  }

  void _atualizarCamposDerivados() {
    try {
      _itensTotalController.text = _calcularQuantidadeItens().toString();
      _logInfo(
        'Campos derivados atualizados. Itens total=${_itensTotalController.text}',
      );
    } catch (error, stackTrace) {
      _logError('Erro ao atualizar campos derivados', error, stackTrace);
    }
  }

  double _calcularTotal() {
    try {
      return _produtosSelecionados.fold<double>(
        0.0,
            (soma, item) =>
        soma +
            (((item['preco'] ?? 0.0) as num).toDouble() *
                ((item['quantidade'] ?? 1) as int)),
      );
    } catch (error, stackTrace) {
      _logError('Erro ao calcular total', error, stackTrace);
      return 0.0;
    }
  }

  int _calcularQuantidadeItens() {
    try {
      return _produtosSelecionados.fold<int>(
        0,
            (soma, item) => soma + ((item['quantidade'] ?? 1) as int),
      );
    } catch (error, stackTrace) {
      _logError('Erro ao calcular quantidade de itens', error, stackTrace);
      return 0;
    }
  }

  Widget _buildResumoCupomFiscalWeb() {
    final total = _calcularTotal();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE89A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6D89A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'RESUMO DA VENDA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Color(0xFF5C4B00),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFD8C67A), thickness: 1),
          const SizedBox(height: 8),
          if (_produtosSelecionados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum item adicionado.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B5B1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ..._produtosSelecionados.map((produto) {
              final nome = produto['nome'] ?? '';
              final preco = (produto['preco'] ?? 0.0).toDouble();
              final quantidade = (produto['quantidade'] ?? 1) as int;
              final subtotal = preco * quantidade;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3E3300),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$quantidade x R\$ ${preco.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B5B1E),
                          ),
                        ),
                        Text(
                          'R\$ ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3E3300),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const Divider(color: Color(0xFFD8C67A), thickness: 1),
          const SizedBox(height: 8),
          _buildLinhaResumoWeb(
            'Itens',
            _calcularQuantidadeItens().toDouble(),
            mostrarComoMoeda: false,
          ),
          _buildLinhaResumoWeb('Subtotal', total),
          _buildLinhaResumoWeb('Desconto', 0.0),
          const SizedBox(height: 6),
          _buildLinhaResumoWeb('TOTAL', total, destaque: true),
          const SizedBox(height: 10),
          Text(
            'Pagamento: ${_formasSelecionadas.isEmpty ? 'Não definido' : _formasSelecionadas.join(', ')}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C4B00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaResumoWeb(
      String label,
      double valor, {
        bool destaque = false,
        bool mostrarComoMoeda = true,
      }) {
    final textoValor = mostrarComoMoeda
        ? 'R\$ ${valor.toStringAsFixed(2)}'
        : valor.toInt().toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF3E3300),
          ),
        ),
        Text(
          textoValor,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF3E3300),
          ),
        ),
      ],
    );
  }

  Widget _buildTopActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 220,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(
            width: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
          foregroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildModoOperacaoButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    String badge;
    String descricao;

    switch (label) {
      case 'Vendas':
        badge = 'Fluxo principal';
        descricao =
        'Atendimento rápido no caixa, inclusão de itens e fechamento da venda.';
        break;
      case 'Orçamento':
        badge = 'Assistência técnica';
        descricao = 'Monte propostas elegantes, ...';
        break;
      default:
        badge = 'Operação interna';
        descricao = 'Controle financeiro ....';
    }

    final theme = Theme.of(context);

    return SizedBox(
      width: 300,
      height: 290,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              label == 'Vendas'
                                  ? Icons.flash_on_rounded
                                  : label == 'Orçamento'
                                  ? Icons.auto_awesome
                                  : Icons.settings_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              badge,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.north_east_rounded,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    descricao,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoSidebarHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Resumo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Tooltip(
            message: 'Ocultar painel',
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _mostrarDashboardLateral = false;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoSidebar() {
    final theme = Theme.of(context);

    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResumoSidebarHeader(),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.70),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Painel operacional',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Acompanhe rapidamente os principais indicadores do balcão e da operação.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildDashboardCard(
                  data[index]['title']!,
                  data[index]['count']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoSidebarCollapsed() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 14, right: 12),
      child: Tooltip(
        message: 'Mostrar painel',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _mostrarDashboardLateral = true;
            });
          },
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Resumo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogMensagem(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeletorModoOperacao() {
    return Expanded(
      child: Center(
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _buildModoOperacaoButton(
              context: context,
              icon: Icons.point_of_sale,
              label: 'Vendas',
              onPressed: _iniciarVenda,
            ),
            _buildModoOperacaoButton(
              context: context,
              icon: Icons.request_quote,
              label: 'Orçamento',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OrcamentoWeb(),
                  ),
                );
              },
            ),
            _buildModoOperacaoButton(
              context: context,
              icon: Icons.account_balance_wallet,
              label: 'Operações de caixa',
              onPressed: () {
                _mostrarDialogMensagem(
                  'Não implementado',
                  'O fluxo de operações de caixa ainda não foi implementado.',
                );
              },
            ),
            _buildModoOperacaoButton(
              context: context,
              icon: Icons.account_balance_wallet,
              label: 'Ordem de Serviço',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OrdemServicoWeb(),
                  ),
                );
              },
            ),
            _buildModoOperacaoButton(
              context: context,
              icon: Icons.monetization_on,
              label: labelAgendaFinanceira(),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AgendaFinanceiraWeb(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String labelAgendaFinanceira() => 'Agenda Financeira';

  Widget _buildAreaVenda(double total) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "F R E N T E   D E   C A I X A",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codigoBarrasController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: "Código de Barras",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'Buscar produto',
                      onPressed: _abrirSelecaoProdutoWeb,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _itensTotalController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Itens Total",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _clienteIdentificadoController,
                  decoration: const InputDecoration(
                    labelText: "Cliente Identificado",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _produtosSelecionados.isEmpty
                      ? Center(
                    child: Text(
                      'Nenhum item selecionado.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                      : ListView.builder(
                    itemCount: _produtosSelecionados.length,
                    itemBuilder: (context, index) {
                      try {
                        final produto = _produtosSelecionados[index];
                        final quantidade =
                        (produto['quantidade'] ?? 1) as int;
                        final preco =
                        ((produto['preco'] ?? 0.0) as num).toDouble();

                        return ZebraListItem(
                          index: index,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Icon(
                                Icons.inventory_2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              produto['nome'] ?? '',
                            ),
                            subtitle: Text(
                              'Qtd: $quantidade • R\$ ${preco.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                  onPressed: () => _alterarQuantidade(
                                    produto,
                                    -1,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                  ),
                                  onPressed: () => _alterarQuantidade(
                                    produto,
                                    1,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removerProduto(
                                    produto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } catch (error, stackTrace) {
                        _logError(
                          'Erro ao renderizar item da lista no PDV',
                          error,
                          stackTrace,
                        );
                        return const ListTile(
                          title: Text(
                            'Erro ao renderizar item',
                          ),
                        );
                      }
                    },
                  ),
                ),
                const Divider(),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenWidth = constraints.maxWidth;
                    final double fontSize = screenWidth > 600 ? 40 : 20;
                    final double buttonFontSize =
                    screenWidth > 600 ? 24 : 16;
                    final EdgeInsets buttonPadding = screenWidth > 600
                        ? const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    )
                        : const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    );

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Total: R\$ ${total.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              icon: Icon(
                                Icons.check,
                                size: buttonFontSize,
                              ),
                              label: Text(
                                "Pausar",
                                style: TextStyle(
                                  fontSize: buttonFontSize,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: buttonPadding,
                              ),
                              onPressed: () {
                                _mostrarDialogMensagem(
                                  'Pausar',
                                  'A ideia é receber depois e deixar a venda aberta.',
                                );
                              },
                            ),
                            OutlinedButton.icon(
                              icon: Icon(
                                Icons.check,
                                size: buttonFontSize,
                              ),
                              label: Text(
                                "Finalizar",
                                style: TextStyle(
                                  fontSize: buttonFontSize,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: buttonPadding,
                              ),
                              onPressed: () {
                                if (_produtosSelecionados.isEmpty) {
                                  _mostrarDialogMensagem(
                                    'Venda vazia',
                                    'Adicione pelo menos um item antes de finalizar.',
                                  );
                                  return;
                                }

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RecebimentoPagamentoWeb(
                                      valorTotalVenda: _calcularTotal(),
                                      itensResumo: _montarItensResumoPagamento(),
                                      clienteNome: _clienteIdentificadoController.text.trim(),
                                      numeroVenda: '',
                                      idColaborador: 'idUnicoDoColaborador',
                                      nomeColaborador: 'Nome do colaborador',
                                      operacaoService: _operacaoService,
                                    ),
                                  ),
                                );
                              },
                            ),
                            OutlinedButton.icon(
                              icon: Icon(
                                Icons.cancel,
                                size: buttonFontSize,
                              ),
                              label: Text(
                                "Cancelar",
                                style: TextStyle(
                                  fontSize: buttonFontSize,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: buttonPadding,
                                side: const BorderSide(
                                  width: 2,
                                ),
                              ),
                              onPressed: _confirmarCancelamentoVenda,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: _buildResumoCupomFiscalWeb(),
            ),
          ),
        ],
      ),
    );
  }

  static final List<Map<String, String>> data = [
    {'title': 'Vendas Abertas', 'count': '2'},
    {'title': 'Ordens Abertas', 'count': '2'},
    {'title': 'OTs em revisão', 'count': '33'},
    {'title': 'OTs em processo', 'count': '27'},
    {'title': 'OTs finalizadas', 'count': '94'},
    {'title': 'OTs atrasadas', 'count': '10'},
  ];

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();

    return Scaffold(
      appBar: TopNavigationBar(
        items: [
          TopNavItemData(
            title: 'Início',
            subItems: const [
              'Preferências do Sistema',
              'Painel Administrativo',
            ],
            onSelect: (value) {
              if (value == 'Painel Administrativo') {
                showSubPainelConfiguracoes(context, 'Configurações');
              }
            },
          ),
          const TopNavItemData(
            title: 'Permitir',
            subItems: [
              'Gerenciar Permissões',
              'Alterar Configurações',
            ],
          ),
          TopNavItemData(
            title: 'Cadastros',
            subItems: const [
              'Clientes',
              'Produtos',
              'Fornecedores',
              'Produtos List',
            ],
            onSelect: (value) {
              if (value == 'Produtos') {
                showSubPainelCadastroProduto(
                  context,
                  'Cadastro de Produtos',
                );
              }

              if (value == 'Produtos List') {
                _abrirSelecaoProdutoWeb();
              }
            },
          ),
          const TopNavItemData(
            title: 'Relatórios',
            subItems: [
              'Vendas',
              'Estoque',
              'Financeiro',
            ],
          ),
          const TopNavItemData(
            title: 'Executar',
            subItems: [
              'Processar Pagamentos',
              'Fechar Caixa',
            ],
          ),
          const TopNavItemData(
            title: 'Configurações',
            subItems: [
              'Sistema',
              'Usuários',
            ],
          ),
          const TopNavItemData(
            title: 'Automações',
            subItems: [
              'Tarefas Agendadas',
            ],
          ),
          const TopNavItemData(
            title: 'Ajuda',
            subItems: [
              'Suporte',
              'Sobre',
            ],
          ),
        ],
        onNotificationPressed: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mostrarDashboardLateral) ...[
              _buildResumoSidebar(),
              const SizedBox(width: 20),
            ] else ...[
              _buildResumoSidebarCollapsed(),
            ],
            Expanded(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildTopActionButton(
                                  context: context,
                                  icon: Icons.person_search,
                                  label: 'Buscar Cliente',
                                  onPressed: () {
                                    _mostrarDialogMensagem(
                                      'Buscar Cliente',
                                      'Aqui você pode implementar uma busca por nome, CPF, telefone etc.',
                                    );
                                  },
                                ),
                                _buildTopActionButton(
                                  context: context,
                                  icon: Icons.person_search,
                                  label: 'Vendedor',
                                  onPressed: () {
                                    _mostrarDialogMensagem(
                                      'Atribuir vendedor',
                                      'Aqui você pode implementar uma busca por nome, CPF, telefone etc.',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.construction),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _mostrarAreaVenda
                          ? _buildAreaVenda(total)
                          : _buildSeletorModoOperacao(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  List<Map<String, dynamic>> _montarItensResumoPagamento() {
    return _produtosSelecionados.map((produto) {
      final quantidade = (produto['quantidade'] ?? 1) as int;
      final precoUnitario = ((produto['preco'] ?? 0.0) as num).toDouble();

      return {
        'id': produto['id'],
        'codigo': produto['codigo'],
        'nome': produto['nome'] ?? '',
        'quantidade': quantidade,
        'valor': precoUnitario,
        'subtotal': precoUnitario * quantidade,
        'ehServico': false,
      };
    }).toList();
  }

}
