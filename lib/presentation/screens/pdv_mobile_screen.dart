import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

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

enum _DecisaoVenda { confirmar, cancelar }

class _PdvMobileScreenState extends State<PdvMobileScreen> {
  final List<Map<String, dynamic>> _produtosSelecionados = <Map<String, dynamic>>[];
  final Map<String, TextEditingController> _valorPorForma = <String, TextEditingController>{};
  final Set<String> _formasSelecionadas = <String>{};
  final OperacaoService _operacaoService = OperacaoModule.operacaoService;

  final List<_FormaPagamentoMobile> _formasPagamento = const <_FormaPagamentoMobile>[
    _FormaPagamentoMobile(
      codigo: 'TIPO1',
      titulo: 'Dinheiro',
      descricao: 'Recebimento no caixa com conferência imediata.',
      icone: Icons.payments_outlined,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO2',
      titulo: 'Pix',
      descricao: 'Confirmação rápida por chave, QR Code ou copia e cola.',
      icone: Icons.qr_code_2_outlined,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO3',
      titulo: 'Cartão de crédito',
      descricao: 'Recebimento à vista ou parcelado pela operadora.',
      icone: Icons.credit_card_outlined,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO4',
      titulo: 'Cartão de débito',
      descricao: 'Liquidação imediata pela maquininha.',
      icone: Icons.point_of_sale_outlined,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO5',
      titulo: 'Boleto',
      descricao: 'Pagamento posterior com baixa futura.',
      icone: Icons.receipt_long_outlined,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO6',
      titulo: 'Fiado',
      descricao: 'Lançamento em aberto para cobrança posterior.',
      icone: Icons.history_toggle_off_outlined,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO7',
      titulo: 'Crediário',
      descricao: 'Parcelamento próprio para cobrança futura.',
      icone: Icons.event_note_outlined,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO8',
      titulo: 'Convênio',
      descricao: 'Recebimento vinculado a convênio ou parceria.',
      icone: Icons.people_outline,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO9',
      titulo: 'Vale',
      descricao: 'Uso de vale, crédito interno ou voucher.',
      icone: Icons.confirmation_number_outlined,
    ),
    _FormaPagamentoMobile(
      codigo: 'TIPO10',
      titulo: 'Outros',
      descricao: 'Outra forma de recebimento aceita pelo comércio.',
      icone: Icons.more_horiz_outlined,
    ),
  ];

  bool _finalizandoVenda = false;

  @override
  void dispose() {
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

  Future<void> _abrirResumoFinalizacao() async {
    if (_produtosSelecionados.isEmpty) {
      _mostrarSnack('Inclua pelo menos um produto ou serviço para liberar a venda.');
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

    final _DecisaoVenda? decisao = await _mostrarResumoFinalizacao(
      formasPagamento: formasPagamento,
      total: total,
    );

    if (!mounted || decisao == null) {
      return;
    }

    if (decisao == _DecisaoVenda.cancelar) {
      _cancelarVenda();
      return;
    }

    await _enviarVenda(formasPagamento);
  }

  Future<void> _enviarVenda(List<FormaPagamentoSelecionada> formasPagamento) async {
    final List<Map<String, dynamic>> produtosResumo = _clonarProdutosSelecionados();
    final double totalResumo = _calcularTotal();

    setState(() {
      _finalizandoVenda = true;
    });

    try {
      final String idColaborador = await AuthService().getUserId() ?? '';
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

      final _ResumoVendaFinalizada resumo = _ResumoVendaFinalizada(
        uuid: response.uuid.trim(),
        produtos: produtosResumo,
        formasPagamento: List<FormaPagamentoSelecionada>.from(formasPagamento),
        total: totalResumo,
        operador: nomeColaborador,
        dataOperacao: dataOperacao,
      );

      _limparVendaAtual();
      await _mostrarResumoVendaFinalizada(resumo);
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

  List<Map<String, dynamic>> _clonarProdutosSelecionados() {
    return _produtosSelecionados.map((Map<String, dynamic> item) {
      return <String, dynamic>{
        'id': item['id'],
        'nome': item['nome'],
        'preco': item['preco'],
        'quantidade': item['quantidade'],
        'ehServico': item['ehServico'],
      };
    }).toList(growable: false);
  }

  void _limparVendaAtual() {
    setState(() {
      _produtosSelecionados.clear();
      _formasSelecionadas.clear();
      for (final TextEditingController controller in _valorPorForma.values) {
        controller.clear();
      }
    });
  }

  void _cancelarVenda() {
    _limparVendaAtual();
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
      final String codigo = _formasSelecionadas.first;
      final double valorDigitado = _valorDigitadoForma(codigo);
      return <FormaPagamentoSelecionada>[
        FormaPagamentoSelecionada(
          codigo: codigo,
          valor: valorDigitado > 0 ? valorDigitado : totalVenda,
        ),
      ];
    }

    return _formasSelecionadas.map((String codigo) {
      return FormaPagamentoSelecionada(
        codigo: codigo,
        valor: _valorDigitadoForma(codigo),
      );
    }).toList(growable: false);
  }

  double _valorDigitadoForma(String codigoForma) {
    final String raw = _valorPorForma[codigoForma]?.text ?? '';
    final String normalizado = raw.replaceAll('R\$', '').replaceAll(',', '.').trim();
    return double.tryParse(normalizado) ?? 0.0;
  }

  double _valorSelecionadoTotal() {
    if (_formasSelecionadas.isEmpty) {
      return 0.0;
    }

    return _montarFormasPagamento(_calcularTotal()).fold<double>(
      0.0,
      (double soma, FormaPagamentoSelecionada forma) => soma + forma.valor,
    );
  }

  double _valorRestante() {
    return _calcularTotal() - _valorSelecionadoTotal();
  }

  int _quantidadeTotalItens() {
    return _produtosSelecionados.fold<int>(
      0,
      (int soma, Map<String, dynamic> item) => soma + ((item['quantidade'] ?? 1) as num).toInt(),
    );
  }

  int _quantidadeTotalItensResumo(List<Map<String, dynamic>> produtos) {
    return produtos.fold<int>(
      0,
      (int soma, Map<String, dynamic> item) => soma + ((item['quantidade'] ?? 1) as num).toInt(),
    );
  }

  _FormaPagamentoMobile _formaPorCodigo(String codigo) {
    return _formasPagamento.firstWhere(
      (_FormaPagamentoMobile forma) => forma.codigo == codigo,
      orElse: () => const _FormaPagamentoMobile(
        codigo: 'TIPO10',
        titulo: 'Outros',
        descricao: 'Outra forma de recebimento aceita pelo comércio.',
        icone: Icons.more_horiz_outlined,
      ),
    );
  }

  String _rotuloForma(String codigo) {
    return _formaPorCodigo(codigo).titulo;
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }

  String _formatarDataHora(DateTime data) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(data.day)}/${twoDigits(data.month)}/${data.year} ${twoDigits(data.hour)}:${twoDigits(data.minute)}';
  }

  void _preencherValorRestante(String codigoForma) {
    _valorPorForma.putIfAbsent(codigoForma, () => TextEditingController());
    final TextEditingController controller = _valorPorForma[codigoForma]!;
    final double atual = _valorDigitadoForma(codigoForma);
    final double restante = _valorRestante();
    final double novoValor = (atual + restante).clamp(0.0, _calcularTotal()).toDouble();

    setState(() {
      controller.text = novoValor.toStringAsFixed(2);
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      _formasSelecionadas.add(codigoForma);
    });
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
          icon: Icon(
            titulo.toLowerCase().contains('erro')
                ? Icons.error_outline
                : Icons.check_circle_outline,
            color: titulo.toLowerCase().contains('erro')
                ? Colors.redAccent
                : Theme.of(context).colorScheme.primary,
          ),
          title: Text(titulo),
          content: Text(mensagem),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarSnack(String mensagem) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<_DecisaoVenda?> _mostrarResumoFinalizacao({
    required List<FormaPagamentoSelecionada> formasPagamento,
    required double total,
  }) {
    return showModalBottomSheet<_DecisaoVenda>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        final ThemeData theme = Theme.of(bottomSheetContext);

        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.fact_check_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Conferir venda',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Revise os itens e deslize para confirmar.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildResumoConfirmacaoCard(total),
                          const SizedBox(height: 12),
                          _buildSecaoResumoModal(
                            titulo: 'Itens da venda',
                            icone: Icons.inventory_2_outlined,
                            children: _produtosSelecionados.map((Map<String, dynamic> produto) {
                              final String nome = produto['nome']?.toString() ?? '';
                              final double preco = ((produto['preco'] ?? 0.0) as num).toDouble();
                              final int quantidade = ((produto['quantidade'] ?? 1) as num).toInt();
                              return _buildLinhaResumoModal(
                                nome,
                                '$quantidade x ${_formatarValor(preco)}',
                                _formatarValor(preco * quantidade),
                              );
                            }).toList(growable: false),
                          ),
                          const SizedBox(height: 12),
                          _buildSecaoResumoModal(
                            titulo: 'Pagamento',
                            icone: Icons.account_balance_wallet_outlined,
                            children: formasPagamento.map((FormaPagamentoSelecionada forma) {
                              return _buildLinhaResumoModal(
                                _rotuloForma(forma.codigo),
                                forma.codigo,
                                _formatarValor(forma.valor),
                              );
                            }).toList(growable: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SlideConfirmButton(
                    label: _finalizandoVenda ? 'Enviando venda...' : 'Deslize para fechar a venda',
                    disabled: _finalizandoVenda,
                    onConfirm: () {
                      Navigator.of(bottomSheetContext).pop(_DecisaoVenda.confirmar);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(bottomSheetContext).pop(),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Voltar para editar'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(bottomSheetContext).pop(_DecisaoVenda.cancelar);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Cancelar venda'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _mostrarResumoVendaFinalizada(_ResumoVendaFinalizada resumo) async {
    final GlobalKey resumoKey = GlobalKey();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        final ThemeData theme = Theme.of(bottomSheetContext);

        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F6EC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Venda finalizada',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Resumo pronto para compartilhar.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: RepaintBoundary(
                          key: resumoKey,
                          child: _buildResumoVendaCompartilhavel(resumo),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _compartilharResumoComoImagem(resumoKey),
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('Compartilhar resumo como imagem'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(bottomSheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Fechar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _compartilharResumoComoImagem(GlobalKey resumoKey) async {
    try {
      final BuildContext? resumoContext = resumoKey.currentContext;
      final RenderObject? renderObject = resumoContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        _mostrarSnack('Não foi possível preparar a imagem do resumo.');
        return;
      }

      final ui.Image imagem = await renderObject.toImage(pixelRatio: 3);
      final ByteData? byteData = await imagem.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? bytes = byteData?.buffer.asUint8List();
      if (bytes == null || bytes.isEmpty) {
        _mostrarSnack('Não foi possível gerar a imagem do resumo.');
        return;
      }

      await Share.shareXFiles(
        <XFile>[
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'resumo-venda-six.png',
          ),
        ],
        text: 'Resumo da venda',
      );
    } catch (e) {
      _mostrarSnack('Falha ao compartilhar o resumo da venda.');
    }
  }

  Widget _buildResumoVendaCompartilhavel(_ResumoVendaFinalizada resumo) {
    final int quantidadeItens = _quantidadeTotalItensResumo(resumo.produtos);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 430),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE89A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6D89A)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Center(
              child: Text(
                'RESUMO DA VENDA',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFF5C4B00),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFD8C67A), thickness: 1),
            const SizedBox(height: 8),
            ...resumo.produtos.map((Map<String, dynamic> produto) {
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
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3E3300),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '$quantidade x ${_formatarValor(preco)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B5B1E),
                            ),
                          ),
                        ),
                        Text(
                          _formatarValor(subtotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
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
            _buildLinhaCupom('Itens', '$quantidadeItens'),
            _buildLinhaCupom('Subtotal', _formatarValor(resumo.total)),
            _buildLinhaCupom('Desconto', _formatarValor(0.0)),
            const SizedBox(height: 6),
            _buildLinhaCupom('TOTAL', _formatarValor(resumo.total), destaque: true),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFD8C67A), thickness: 1),
            const SizedBox(height: 8),
            const Text(
              'Pagamento',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5C4B00),
              ),
            ),
            const SizedBox(height: 6),
            ...resumo.formasPagamento.map((FormaPagamentoSelecionada forma) {
              return _buildLinhaCupom(
                _rotuloForma(forma.codigo),
                _formatarValor(forma.valor),
              );
            }),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFD8C67A), thickness: 1),
            const SizedBox(height: 8),
            _buildInfoCupom('Operador', resumo.operador),
            _buildInfoCupom('Data', _formatarDataHora(resumo.dataOperacao)),
            if (resumo.uuid.isNotEmpty) _buildInfoCupom('UUID', resumo.uuid),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaCupom(String label, String valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: destaque ? 15 : 13,
                fontWeight: destaque ? FontWeight.w900 : FontWeight.w700,
                color: const Color(0xFF3E3300),
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: destaque ? 15 : 13,
              fontWeight: destaque ? FontWeight.w900 : FontWeight.w700,
              color: const Color(0xFF3E3300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCupom(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        '$label: $valor',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5C4B00),
        ),
      ),
    );
  }

  Widget _buildResumoConfirmacaoCard(double total) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withOpacity(0.10),
            theme.colorScheme.primaryContainer.withOpacity(0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.22)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Total da venda',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatarValor(total),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          _buildBadgeResumo('${_quantidadeTotalItens()} item(ns)', Icons.shopping_bag_outlined),
        ],
      ),
    );
  }

  Widget _buildSecaoResumoModal({
    required String titulo,
    required IconData icone,
    required List<Widget> children,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icone, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLinhaResumoModal(String titulo, String subtitulo, String valor) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutoCard(Map<String, dynamic> produto) {
    final ThemeData theme = Theme.of(context);
    final String nome = produto['nome']?.toString() ?? '';
    final double preco = ((produto['preco'] ?? 0) as num).toDouble();
    final int quantidade = ((produto['quantidade'] ?? 1) as num).toInt();
    final bool ehServico = produto['ehServico'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              ehServico ? Icons.build_outlined : Icons.shopping_bag_outlined,
              color: theme.colorScheme.primary,
            ),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatarValor(preco),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.72),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildIconeQuantidade(
                  icon: Icons.remove_rounded,
                  color: Colors.redAccent,
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantidade',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
                _buildIconeQuantidade(
                  icon: Icons.add_rounded,
                  color: theme.colorScheme.primary,
                  onTap: _finalizandoVenda
                      ? null
                      : () {
                          setState(() {
                            produto['quantidade'] = quantidade + 1;
                          });
                        },
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Remover item',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
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
    ).animate().fade(duration: 350.ms).slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _buildIconeQuantidade({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildResumoDaVendaCard() {
    final ThemeData theme = Theme.of(context);
    final double total = _calcularTotal();
    final double totalSelecionado = _valorSelecionadoTotal();
    final double restante = _valorRestante();
    final bool pagamentoConferido =
        _formasSelecionadas.isNotEmpty && restante.abs() <= 0.009;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resumo da venda',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _buildBadgeResumo('${_formasSelecionadas.length} forma(s)', Icons.payments_outlined),
            ],
          ),
          const SizedBox(height: 14),
          _buildLinhaResumo('Subtotal', total),
          _buildLinhaResumo('Total selecionado', totalSelecionado),
          _buildLinhaResumo(
            pagamentoConferido ? 'Conferido' : 'Falta distribuir',
            pagamentoConferido ? 0.0 : restante,
            destaque: true,
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pagamentoConferido
                  ? const Color(0xFFE9F6EC)
                  : const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              pagamentoConferido
                  ? 'Valores prontos para conferência final.'
                  : 'Selecione uma forma e complete o valor total antes de finalizar.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: pagamentoConferido
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFB26A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaResumo(String label, double valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: destaque ? 15 : 13,
                fontWeight: destaque ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatarValor(valor.abs()),
            style: TextStyle(
              fontSize: destaque ? 15 : 13,
              fontWeight: destaque ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeResumo(String texto, IconData icone) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icone, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagamentoField(String codigoForma) {
    final ThemeData theme = Theme.of(context);
    final _FormaPagamentoMobile forma = _formaPorCodigo(codigoForma);
    _valorPorForma.putIfAbsent(codigoForma, () => TextEditingController());

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(forma.icone, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  forma.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: _finalizandoVenda ? null : () => _preencherValorRestante(codigoForma),
                child: const Text('Completar'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            forma.descricao,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valorPorForma[codigoForma],
            enabled: !_finalizandoVenda,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Valor recebido',
              prefixText: 'R\$ ',
              helperText: _formasSelecionadas.length == 1
                  ? 'Se ficar vazio, o total da venda será usado.'
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoItens() {
    return _buildCardSecao(
      titulo: 'Itens selecionados',
      subtitulo: '${_quantidadeTotalItens()} item(ns) na venda',
      icone: Icons.shopping_cart_outlined,
      child: Column(
        children: _produtosSelecionados.map(_buildProdutoCard).toList(growable: false),
      ),
    );
  }

  Widget _buildSecaoPagamento() {
    final ThemeData theme = Theme.of(context);

    return _buildCardSecao(
      titulo: 'Formas de pagamento',
      subtitulo: 'Escolha uma ou mais opções para distribuir o valor.',
      icone: Icons.account_balance_wallet_outlined,
      trailing: _buildBadgeResumo('${_formasPagamento.length} opções', Icons.grid_view_rounded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formasPagamento.map((_FormaPagamentoMobile forma) {
              final bool selecionado = _formasSelecionadas.contains(forma.codigo);
              return FilterChip(
                label: Text(forma.titulo),
                avatar: Icon(
                  forma.icone,
                  size: 18,
                  color: selecionado
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
                selected: selecionado,
                onSelected: _finalizandoVenda
                    ? null
                    : (bool selected) {
                        setState(() {
                          if (selected) {
                            _formasSelecionadas.add(forma.codigo);
                          } else {
                            _formasSelecionadas.remove(forma.codigo);
                            _valorPorForma[forma.codigo]?.clear();
                          }
                        });
                      },
                selectedColor: theme.colorScheme.primary,
                checkmarkColor: theme.colorScheme.onPrimary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selecionado
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
                side: BorderSide(
                  color: selecionado
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              );
            }).toList(growable: false),
          ),
          if (_formasSelecionadas.isEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _buildEstadoMenor(
              icone: Icons.touch_app_outlined,
              titulo: 'Nenhuma forma selecionada',
              mensagem: 'Toque em uma opção acima para habilitar o valor recebido.',
            ),
          ] else ...<Widget>[
            const SizedBox(height: 4),
            ..._formasSelecionadas.map(_buildPagamentoField),
          ],
        ],
      ),
    );
  }

  Widget _buildCardSecao({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Widget child,
    Widget? trailing,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icone, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildEstadoMenor({
    required IconData icone,
    required String titulo,
    required String mensagem,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(icone, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  mensagem,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildEstadoVazio() {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.add_shopping_cart,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Venda ainda vazia',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Inclua pelo menos um produto ou serviço para liberar pagamento e finalização da venda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _finalizandoVenda ? null : _abrirSelecaoProduto,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar produto ou serviço'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text('Finalização bloqueada sem itens'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ).animate().fade(duration: 450.ms).slideY(begin: 0.08, curve: Curves.easeOut),
    );
  }

  Widget _buildBottomActions() {
    final ThemeData theme = Theme.of(context);
    final double total = _calcularTotal();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total ${_formatarValor(total)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${_quantidadeTotalItens()} item(ns)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _finalizandoVenda ? null : _abrirResumoFinalizacao,
              icon: _finalizandoVenda
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: Text(_finalizandoVenda ? 'Enviando...' : 'Finalizar venda'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _finalizandoVenda ? null : _receberDepois,
                    icon: const Icon(Icons.schedule_send_outlined),
                    label: const Text('Receber depois'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _finalizandoVenda ? null : _cancelarVenda,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    final ThemeData theme = Theme.of(context);
    final double total = _calcularTotal();
    final int quantidade = _quantidadeTotalItens();
    final bool temItens = _produtosSelecionados.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('PDV - Ponto de Venda'),
            Text(
              'Itens: $quantidade    Total: ${_formatarValor(total)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, temItens ? 18 : 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (temItens) ...<Widget>[
                _buildSecaoItens(),
                _buildSecaoPagamento(),
                _buildResumoDaVendaCard(),
              ] else
                _buildEstadoVazio(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: temItens ? _buildBottomActions() : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finalizandoVenda ? null : _abrirSelecaoProduto,
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text(
          'Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ResumoVendaFinalizada {
  const _ResumoVendaFinalizada({
    required this.uuid,
    required this.produtos,
    required this.formasPagamento,
    required this.total,
    required this.operador,
    required this.dataOperacao,
  });

  final String uuid;
  final List<Map<String, dynamic>> produtos;
  final List<FormaPagamentoSelecionada> formasPagamento;
  final double total;
  final String operador;
  final DateTime dataOperacao;
}

class _FormaPagamentoMobile {
  const _FormaPagamentoMobile({
    required this.codigo,
    required this.titulo,
    required this.descricao,
    required this.icone,
  });

  final String codigo;
  final String titulo;
  final String descricao;
  final IconData icone;
}

class _SlideConfirmButton extends StatefulWidget {
  const _SlideConfirmButton({
    required this.label,
    required this.onConfirm,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onConfirm;
  final bool disabled;

  @override
  State<_SlideConfirmButton> createState() => _SlideConfirmButtonState();
}

class _SlideConfirmButtonState extends State<_SlideConfirmButton> {
  static const double _thumbSize = 52;
  double _dragPercent = 0.0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool disabled = widget.disabled || _confirmed;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double maxDrag = (width - _thumbSize - 6).clamp(1.0, double.infinity).toDouble();

        return GestureDetector(
          onHorizontalDragUpdate: disabled
              ? null
              : (DragUpdateDetails details) {
                  final double delta = details.primaryDelta ?? 0.0;
                  setState(() {
                    _dragPercent = (_dragPercent + delta / maxDrag).clamp(0.0, 1.0).toDouble();
                  });
                },
          onHorizontalDragEnd: disabled
              ? null
              : (_) {
                  if (_dragPercent >= 0.82) {
                    setState(() {
                      _dragPercent = 1.0;
                      _confirmed = true;
                    });
                    widget.onConfirm();
                  } else {
                    setState(() {
                      _dragPercent = 0.0;
                    });
                  }
                },
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: disabled
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: disabled
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.primary.withOpacity(0.30),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: width * _dragPercent,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(disabled ? 0.10 : 0.24),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: disabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  left: 3 + (_dragPercent * maxDrag),
                  top: 3,
                  bottom: 3,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: disabled ? theme.colorScheme.outlineVariant : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
