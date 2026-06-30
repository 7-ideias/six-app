import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/di/operacao_module.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/operacao_models.dart';
import '../../data/models/produto_model.dart';
import '../../domain/services/operacao/operacao_service.dart';
import '../../providers/usuario_provider.dart';
import 'produto_list_mobile_screen.dart';

class PdvMobileScreen extends StatefulWidget {
  const PdvMobileScreen({super.key});

  @override
  State<PdvMobileScreen> createState() => _PdvMobileScreenState();
}

class _PdvMobileScreenState extends State<PdvMobileScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _produtosSelecionados = <Map<String, dynamic>>[];
  final List<String> _formasPagamento = <String>[
    'Dinheiro',
    'Cartão Crédito',
    'Cartão Débito',
    'Pix',
    'Fiado',
  ];
  final Map<String, TextEditingController> _valorPorForma = <String, TextEditingController>{};
  final Set<String> _formasSelecionadas = <String>{};
  final OperacaoService _operacaoService = OperacaoModule.operacaoService;

  bool _finalizandoVenda = false;

  @override
  void dispose() {
    _searchController.dispose();
    for (final TextEditingController controller in _valorPorForma.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _abrirSelecaoProduto() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutolistMobileScreen(isSelecao: true),
      ),
    );

    if (result != null && result is ProdutoModel) {
      setState(() {
        _produtosSelecionados.add(<String, dynamic>{
          'id': result.id ?? result.codigoDeBarras,
          'nome': result.nomeProduto,
          'preco': result.precoVenda,
          'quantidade': 1,
          'ehServico': result.tipoProduto.toUpperCase() == 'SERVICO',
        });
      });
    }
  }

  Future<void> _finalizarVenda() async {
    if (_produtosSelecionados.isEmpty) {
      _mostrarSnack('Adicione pelo menos um produto ou serviço.');
      return;
    }

    if (_formasSelecionadas.isEmpty) {
      _mostrarSnack('Selecione pelo menos uma forma de pagamento.');
      return;
    }

    final double total = _calcularTotal();
    final List<FormaPagamentoSelecionada> formasPagamento = _montarFormasPagamento(total);
    final double totalRecebido = formasPagamento.fold<double>(
      0,
      (double soma, FormaPagamentoSelecionada forma) => soma + forma.valor,
    );

    if ((totalRecebido - total).abs() > 0.009) {
      _mostrarSnack('A soma das formas de pagamento deve ser igual ao total da venda.');
      return;
    }

    setState(() {
      _finalizandoVenda = true;
    });

    try {
      final String idColaborador = await AuthService().getUserId() ?? '';
      final usuario = UsuarioProvider().usuario;
      final String nomeColaborador = _nomeColaboradorAtual();
      final DateTime dataOperacao = DateTime.now();

      final OperacaoVendaInput input = OperacaoVendaInput(
        descricao: 'Venda mobile ${dataOperacao.toIso8601String()}',
        idColaborador: idColaborador,
        nomeColaborador: nomeColaborador,
        itens: _montarItensDaVenda(),
        formasPagamento: formasPagamento,
        dataOperacao: dataOperacao,
      );

      final OperacaoInserirResponse response = await _operacaoService.finalizarVenda(input);

      if (!mounted) return;

      setState(() {
        _produtosSelecionados.clear();
        _formasSelecionadas.clear();
        for (final TextEditingController controller in _valorPorForma.values) {
          controller.clear();
        }
      });

      final String uuid = response.uuid.trim();
      await _mostrarDialogMensagem(
        titulo: 'Venda finalizada',
        mensagem: uuid.isEmpty
            ? 'Venda enviada com sucesso para o backend.'
            : 'Venda enviada com sucesso.\nUUID: $uuid',
      );
    } catch (e) {
      if (!mounted) return;
      await _mostrarDialogMensagem(
        titulo: 'Erro ao finalizar venda',
        mensagem: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _finalizandoVenda = false;
        });
      }
    }
  }

  void _cancelarVenda() {
    setState(() {
      _produtosSelecionados.clear();
      _formasSelecionadas.clear();
      for (final TextEditingController controller in _valorPorForma.values) {
        controller.clear();
      }
    });
    _mostrarSnack('Venda cancelada.');
  }

  Future<void> _receberDepois() async {
    _mostrarSnack('Receber depois será ligado ao financeiro em uma próxima etapa.');
  }

  List<ItemVendaAtual> _montarItensDaVenda() {
    return _produtosSelecionados.map((Map<String, dynamic> item) {
      return ItemVendaAtual(
        idProduto: (item['id'] ?? '').toString(),
        nome: (item['nome'] ?? '').toString(),
        quantidade: ((item['quantidade'] ?? 1) as num).toInt(),
        valorUnitario: ((item['preco'] ?? 0.0) as num).toDouble(),
        ehServico: item['ehServico'] == true,
      );
    }).toList(growable: false);
  }

  List<FormaPagamentoSelecionada> _montarFormasPagamento(double totalVenda) {
    if (_formasSelecionadas.length == 1) {
      final String forma = _formasSelecionadas.first;
      final double valorDigitado = _valorDigitadoForma(forma);
      return <FormaPagamentoSelecionada>[
        FormaPagamentoSelecionada(
          codigo: _codigoFormaPagamento(forma),
          valor: valorDigitado > 0 ? valorDigitado : totalVenda,
        ),
      ];
    }

    return _formasSelecionadas.map((String forma) {
      return FormaPagamentoSelecionada(
        codigo: _codigoFormaPagamento(forma),
        valor: _valorDigitadoForma(forma),
      );
    }).toList(growable: false);
  }

  double _valorDigitadoForma(String forma) {
    final String raw = _valorPorForma[forma]?.text ?? '';
    final String normalizado = raw.replaceAll('R\$', '').replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0.0;
  }

  String _codigoFormaPagamento(String forma) {
    switch (forma) {
      case 'Dinheiro':
        return 'TIPO1';
      case 'Pix':
        return 'TIPO2';
      case 'Cartão Crédito':
        return 'TIPO3';
      case 'Cartão Débito':
        return 'TIPO4';
      case 'Fiado':
        return 'TIPO6';
      default:
        return 'TIPO10';
    }
  }

  String _nomeColaboradorAtual() {
    final usuario = UsuarioProvider().usuario;
    if (usuario == null) {
      return 'Colaborador';
    }

    if (usuario.nomeDeGuerra.trim().isNotEmpty) {
      return usuario.nomeDeGuerra.trim();
    }

    final String nomeCompleto = '${usuario.nome} ${usuario.sobrenome}'.trim();
    return nomeCompleto.isEmpty ? 'Colaborador' : nomeCompleto;
  }

  Future<void> _mostrarDialogMensagem({
    required String titulo,
    required String mensagem,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Widget _buildProdutoCard(Map<String, dynamic> produto) {
    final String nome = produto['nome']?.toString() ?? '';
    final double preco = ((produto['preco'] ?? 0) as num).toDouble();
    final int quantidade = ((produto['quantidade'] ?? 1) as num).toInt();

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${preco.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _finalizandoVenda
                        ? null
                        : () {
                            setState(() {
                              if (quantidade > 1) {
                                produto['quantidade'] = quantidade - 1;
                              } else {
                                _produtosSelecionados.remove(produto);
                              }
                            });
                          },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.remove, size: 18, color: Colors.redAccent),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$quantidade',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _finalizandoVenda
                        ? null
                        : () {
                            setState(() {
                              produto['quantidade'] = quantidade + 1;
                            });
                          },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.add, size: 18, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Remover item',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _finalizandoVenda
                  ? null
                  : () {
                      setState(() {
                        _produtosSelecionados.remove(produto);
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCupomFiscal() {
    final double total = _calcularTotal();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(4, 16, 4, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE89A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
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
        children: <Widget>[
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
          ..._produtosSelecionados.map((Map<String, dynamic> produto) {
            final String nome = produto['nome']?.toString() ?? '';
            final double preco = ((produto['preco'] ?? 0.0) as num).toDouble();
            final int quantidade = ((produto['quantidade'] ?? 1) as num).toInt();
            final double subtotal = preco * quantidade;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                    children: <Widget>[
                      Text(
                        '$quantidade x R\$ ${preco.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B5B1E)),
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
          _buildLinhaResumo('Subtotal', total),
          _buildLinhaResumo('Desconto', 0.0),
          const SizedBox(height: 6),
          _buildLinhaResumo('TOTAL', total, destaque: true),
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

  Widget _buildLinhaResumo(String label, double valor, {bool destaque = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPagamentoField(String forma) {
    _valorPorForma.putIfAbsent(forma, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _valorPorForma[forma],
        enabled: !_finalizandoVenda,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Valor em $forma',
          prefixIcon: const Icon(Icons.attach_money),
          helperText: _formasSelecionadas.length == 1
              ? 'Opcional: se vazio, usa o total da venda.'
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  double _calcularTotal() {
    return _produtosSelecionados.fold<double>(
      0.0,
      (double soma, Map<String, dynamic> item) {
        final double preco = ((item['preco'] ?? 0.0) as num).toDouble();
        final int quantidade = ((item['quantidade'] ?? 1) as num).toInt();
        return soma + (preco * quantidade);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double total = _calcularTotal();
    final int quantidade = _produtosSelecionados.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('PDV - Ponto de Venda'),
            Text(
              'Itens: $quantidade    Total: R\$ ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_produtosSelecionados.isNotEmpty) ...<Widget>[
                const Text(
                  'Itens selecionados',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._produtosSelecionados.map(_buildProdutoCard),
                const SizedBox(height: 24),
                const Text(
                  'Formas de pagamento',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _formasPagamento.map((String forma) {
                    final bool selecionado = _formasSelecionadas.contains(forma);
                    return FilterChip(
                      label: Text(forma),
                      selected: selecionado,
                      onSelected: _finalizandoVenda
                          ? null
                          : (bool selected) {
                              setState(() {
                                if (selected) {
                                  _formasSelecionadas.add(forma);
                                } else {
                                  _formasSelecionadas.remove(forma);
                                }
                              });
                            },
                      selectedColor: Colors.green.shade200,
                    );
                  }).toList(growable: false),
                ),
                ..._formasSelecionadas.map(_buildPagamentoField),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  onPressed: _finalizandoVenda ? null : _finalizarVenda,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _finalizandoVenda
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _finalizandoVenda ? 'Enviando...' : 'Finalizar Venda',
                    style: const TextStyle(fontSize: 18),
                  ),
                ).animate().fade(duration: 600.ms).slideY(begin: 1, curve: Curves.easeOut),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _finalizandoVenda ? null : _cancelarVenda,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar', style: TextStyle(fontSize: 18)),
                ).animate().fade(duration: 600.ms).slideY(begin: 1, curve: Curves.easeOut),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _finalizandoVenda ? null : _receberDepois,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.schedule_send_outlined),
                  label: const Text('Receber depois', style: TextStyle(fontSize: 18)),
                ).animate().fade(duration: 600.ms).slideY(begin: 1, curve: Curves.easeOut),
                const SizedBox(height: 16),
                _buildResumoCupomFiscal(),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text('Adicione produtos ou serviços para iniciar a venda.'),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _finalizandoVenda ? null : _abrirSelecaoProduto,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }
}
