
import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/produto_model.dart';
import '../../design_system/themes/zebra_list_item.dart';
import '../../top_navigation_bar.dart';

enum _ModoOperacao { nenhum, venda, orcamento }

class OrcamentoWeb extends StatefulWidget {
  const OrcamentoWeb({super.key});

  @override
  State<OrcamentoWeb> createState() => _OrcamentoWebState();
}

class _OrcamentoWebState extends State<OrcamentoWeb> {
  bool _mostrarDashboardLateral = true;
  _ModoOperacao _modoOperacao = _ModoOperacao.orcamento;

  final List<Map<String, dynamic>> _produtosSelecionados = [];
  final Set<String> _formasSelecionadas = {};

  final TextEditingController _codigoBarrasController =
      TextEditingController();
  final TextEditingController _itensTotalController =
      TextEditingController(text: '0');
  final TextEditingController _clienteIdentificadoController =
      TextEditingController();

  final PageController _orcamentoPageController = PageController(
    viewportFraction: 0.92,
  );

  int _etapaOrcamentoAtual = 0;

  final TextEditingController _orcamentoNomeClienteController =
      TextEditingController(text: 'Marina Oliveira');
  final TextEditingController _orcamentoTelefoneController =
      TextEditingController(text: '(47) 99999-0001');
  final TextEditingController _orcamentoEmailController =
      TextEditingController(text: 'marina.oliveira@email.com');
  final TextEditingController _orcamentoDocumentoController =
      TextEditingController(text: '123.456.789-00');
  final TextEditingController _orcamentoEquipamentoController =
      TextEditingController(text: 'iPhone 13 128GB');
  final TextEditingController _orcamentoMarcaController =
      TextEditingController(text: 'Apple');
  final TextEditingController _orcamentoModeloController =
      TextEditingController(text: 'A2633');
  final TextEditingController _orcamentoSerialController =
      TextEditingController(text: 'SN-IP13-009988');
  final TextEditingController _orcamentoAcessoriosController =
      TextEditingController(text: 'Capa, película e cabo USB-C');
  final TextEditingController _orcamentoDefeitoRelatadoController =
      TextEditingController(
    text:
        'Tela sem imagem após queda. Cliente relata vibração normal e sons de notificações.',
  );
  final TextEditingController _orcamentoObservacoesTecnicasController =
      TextEditingController(
    text:
        'Estrutura preservada. Indício de dano no display. Recomenda-se teste de tela e revisão do conector.',
  );
  final TextEditingController _orcamentoPrazoController =
      TextEditingController(text: '2 dias úteis');
  final TextEditingController _orcamentoGarantiaController =
      TextEditingController(text: '90 dias para peças e serviço');
  final TextEditingController _orcamentoObservacoesFinaisController =
      TextEditingController(
    text:
        'Mock para futura integração com backend. Enviar aprovação por WhatsApp, e-mail e gerar PDF.',
  );

  final List<Map<String, dynamic>> _checklistDiagnostico = [
    {
      'titulo': 'Liga normalmente',
      'descricao': 'Equipamento energiza e apresenta sinais básicos de vida.',
      'ok': true,
    },
    {
      'titulo': 'Tela apresenta imagem',
      'descricao': 'Display principal está funcional.',
      'ok': false,
    },
    {
      'titulo': 'Toque responde',
      'descricao': 'Touchscreen responde corretamente em toda a área.',
      'ok': false,
    },
    {
      'titulo': 'Carregamento funcional',
      'descricao': 'Conector e bateria respondem no teste inicial.',
      'ok': true,
    },
    {
      'titulo': 'Sem indício de oxidação',
      'descricao': 'Verificação visual inicial da placa e conectores.',
      'ok': true,
    },
  ];

  final List<Map<String, dynamic>> _servicosOrcamento = [
    {
      'tipo': 'servico',
      'nome': 'Troca de display OLED premium',
      'detalhe': 'Mão de obra técnica especializada',
      'quantidade': 1,
      'valor': 790.00,
      'selecionado': true,
    },
    {
      'tipo': 'servico',
      'nome': 'Revisão interna e testes funcionais',
      'detalhe': 'Checklist completo de entrega',
      'quantidade': 1,
      'valor': 90.00,
      'selecionado': true,
    },
    {
      'tipo': 'produto',
      'nome': 'Película de proteção 3D',
      'detalhe': 'Opcional sugerido',
      'quantidade': 1,
      'valor': 49.90,
      'selecionado': false,
    },
    {
      'tipo': 'produto',
      'nome': 'Capa magnética premium',
      'detalhe': 'Opcional sugerido',
      'quantidade': 1,
      'valor': 79.90,
      'selecionado': false,
    },
  ];

  final List<Map<String, dynamic>> _canaisAprovacao = [
    {'titulo': 'WhatsApp', 'selecionado': true, 'icone': Icons.chat},
    {'titulo': 'E-mail', 'selecionado': true, 'icone': Icons.email_outlined},
    {'titulo': 'Telegram', 'selecionado': false, 'icone': Icons.send},
    {'titulo': 'SMS', 'selecionado': false, 'icone': Icons.sms_outlined},
  ];

  final List<String> _prioridadesOrcamento = [
    'Baixa',
    'Normal',
    'Alta',
    'Urgente',
  ];
  final List<String> _origensOrcamento = [
    'Balcão',
    'WhatsApp',
    'Instagram',
    'Site',
    'Marketplace',
  ];
  final List<String> _statusInternoOrcamento = [
    'Triagem',
    'Aguardando aprovação',
    'Em execução',
    'Finalizado',
  ];

  String _orcamentoPrioridadeSelecionada = 'Alta';
  String _orcamentoOrigemSelecionada = 'WhatsApp';
  String _orcamentoStatusSelecionado = 'Aguardando aprovação';
  bool _orcamentoRequerSinal = true;
  bool _orcamentoAutorizaContato = true;
  bool _orcamentoEquipamentoReserva = false;

  void _logInfo(String message) {
    debugPrint('[OrcamentoWeb][INFO] $message');
  }

  void _logError(
    String errorContext,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[OrcamentoWeb][ERROR] $errorContext');
    debugPrint('[OrcamentoWeb][ERROR] $error');
    debugPrint('[OrcamentoWeb][STACK] $stackTrace');

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
    _logInfo('OrcamentoWeb iniciado');
    _atualizarCamposDerivados();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _modoOperacao = _ModoOperacao.orcamento;
        _etapaOrcamentoAtual = 0;
      });

      if (_orcamentoPageController.hasClients) {
        _orcamentoPageController.jumpToPage(0);
      }
    });
  }

  @override
  void dispose() {
    _codigoBarrasController.dispose();
    _itensTotalController.dispose();
    _clienteIdentificadoController.dispose();
    _orcamentoPageController.dispose();
    _orcamentoNomeClienteController.dispose();
    _orcamentoTelefoneController.dispose();
    _orcamentoEmailController.dispose();
    _orcamentoDocumentoController.dispose();
    _orcamentoEquipamentoController.dispose();
    _orcamentoMarcaController.dispose();
    _orcamentoModeloController.dispose();
    _orcamentoSerialController.dispose();
    _orcamentoAcessoriosController.dispose();
    _orcamentoDefeitoRelatadoController.dispose();
    _orcamentoObservacoesTecnicasController.dispose();
    _orcamentoPrazoController.dispose();
    _orcamentoGarantiaController.dispose();
    _orcamentoObservacoesFinaisController.dispose();
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
      _modoOperacao = _ModoOperacao.venda;
    });
  }

  void _iniciarOrcamento() {
    setState(() {
      _modoOperacao = _ModoOperacao.orcamento;
      _etapaOrcamentoAtual = 0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_orcamentoPageController.hasClients) {
        _orcamentoPageController.jumpToPage(0);
      }
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

  Future<void> _confirmarCancelamentoOrcamento() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar orçamento'),
          content: const Text(
            'Deseja realmente sair do fluxo de orçamento? Os dados mockados permanecerão para facilitar a futura implementação.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continuar orçamento'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      setState(() {
        _modoOperacao = _ModoOperacao.nenhum;
        _etapaOrcamentoAtual = 0;
      });
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
        _modoOperacao = _ModoOperacao.nenhum;
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

  double _calcularTotalOrcamentoSelecionado() {
    return _servicosOrcamento
        .where((item) => item['selecionado'] == true)
        .fold<double>(
          0,
          (soma, item) =>
              soma +
              (((item['valor'] ?? 0.0) as num).toDouble() *
                  ((item['quantidade'] ?? 1) as int)),
        );
  }

  double _calcularValorSinalOrcamento() {
    if (!_orcamentoRequerSinal) {
      return 0;
    }
    return _calcularTotalOrcamentoSelecionado() * 0.30;
  }

  int _calcularTotalEtapasOrcamento() => 5;

  bool _estaNaUltimaEtapaOrcamento() {
    return _etapaOrcamentoAtual == _calcularTotalEtapasOrcamento() - 1;
  }

  void _irParaEtapaOrcamento(int index) {
    setState(() {
      _etapaOrcamentoAtual = index;
    });

    _orcamentoPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _avancarEtapaOrcamento() {
    if (_estaNaUltimaEtapaOrcamento()) {
      _mostrarDialogMensagem(
        'Orçamento pronto',
        'Fluxo concluído com sucesso. No futuro, aqui você poderá persistir, gerar PDF, compartilhar e enviar para aprovação.',
      );
      return;
    }

    _irParaEtapaOrcamento(_etapaOrcamentoAtual + 1);
  }

  void _voltarEtapaOrcamento() {
    if (_etapaOrcamentoAtual == 0) {
      _confirmarCancelamentoOrcamento();
      return;
    }

    _irParaEtapaOrcamento(_etapaOrcamentoAtual - 1);
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
    return SizedBox(
      width: 280,
      height: 280,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
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
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
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
              onPressed: _iniciarOrcamento,
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
          ],
        ),
      ),
    );
  }

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
                                        onPressed: () =>
                                            _alterarQuantidade(produto, -1),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed: () =>
                                            _alterarQuantidade(produto, 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _removerProduto(produto),
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
                                _mostrarDialogMensagem(
                                  'Finalizar',
                                  'A ideia é confirmar o tipo de venda e propor alguma coisa.',
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

  Widget _buildAreaOrcamento() {
    final theme = Theme.of(context);

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool alturaCurta = constraints.maxHeight < 760;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(alturaCurta ? 14 : 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.08),
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(
                                Icons.request_quote,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Fluxo de Orçamento de Serviço',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        _buildBadgeInformativo(
                          'Etapa ${_etapaOrcamentoAtual + 1}/${_calcularTotalEtapasOrcamento()}',
                          Icons.view_carousel_outlined,
                        ),
                        _buildBadgeInformativo(
                          _orcamentoStatusSelecionado,
                          Icons.flag_outlined,
                        ),
                        _buildBadgeInformativo(
                          _orcamentoPrioridadeSelecionada,
                          Icons.bolt_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Jornada sequencial inspirada em softwares atuais de assistência técnica: entrada do cliente, identificação do equipamento, diagnóstico, composição do orçamento e aprovação clara.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: alturaCurta ? 12 : 18),
                    SizedBox(
                      height: alturaCurta ? 82 : 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _calcularTotalEtapasOrcamento(),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final etapa = _dadosEtapasOrcamento()[index];
                          final selecionada = index == _etapaOrcamentoAtual;
                          final concluida = index < _etapaOrcamentoAtual;

                          return InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _irParaEtapaOrcamento(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: alturaCurta ? 220 : 250,
                              padding: EdgeInsets.all(alturaCurta ? 12 : 16),
                              decoration: BoxDecoration(
                                color: selecionada
                                    ? theme.colorScheme.primary
                                    : concluida
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selecionada
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                  width: selecionada ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      selecionada ? 0.10 : 0.04,
                                    ),
                                    blurRadius: selecionada ? 18 : 8,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: selecionada
                                        ? Colors.white
                                        : concluida
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surfaceContainerHighest,
                                    foregroundColor: selecionada
                                        ? theme.colorScheme.primary
                                        : concluida
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                    child: Icon(
                                      etapa['icone'] as IconData,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          etapa['titulo'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontSize: 15,
                                            height: 1.1,
                                            color: selecionada
                                                ? Colors.white
                                                : theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          etapa['descricao'] as String,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 12,
                                            height: 1.15,
                                            color: selecionada
                                                ? Colors.white.withOpacity(0.90)
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: alturaCurta ? 12 : 18),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _orcamentoPageController,
                        onPageChanged: (index) {
                          setState(() {
                            _etapaOrcamentoAtual = index;
                          });
                        },
                        children: [
                          _buildEtapaClienteOrcamento(),
                          _buildEtapaEquipamentoOrcamento(),
                          _buildEtapaDiagnosticoOrcamento(),
                          _buildEtapaItensOrcamento(),
                          _buildEtapaCondicoesOrcamento(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 370,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildResumoLateralOrcamento(),
                          ),
                          const SizedBox(height: 14),
                          Flexible(
                            child: SingleChildScrollView(
                              child: _buildCardsProximosPassos(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: alturaCurta ? 10 : 16),
              _buildBarraNavegacaoOrcamento(),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _dadosEtapasOrcamento() {
    return [
      {
        'titulo': 'Cliente',
        'descricao': 'Quem solicita e qual o canal de entrada',
        'icone': Icons.person_outline,
      },
      {
        'titulo': 'Equipamento',
        'descricao': 'Identificação, acessórios e histórico',
        'icone': Icons.devices_other_outlined,
      },
      {
        'titulo': 'Diagnóstico',
        'descricao': 'Checklist técnico e defeito relatado',
        'icone': Icons.medical_information_outlined,
      },
      {
        'titulo': 'Itens',
        'descricao': 'Serviços, peças e opcionais',
        'icone': Icons.inventory_2_outlined,
      },
      {
        'titulo': 'Condições',
        'descricao': 'Prazo, garantia, aprovação e envio',
        'icone': Icons.verified_outlined,
      },
    ];
  }

  Widget _buildBadgeInformativo(String texto, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapaClienteOrcamento() {
    return _buildCardEtapaOrcamento(
      titulo: '1. Identificação do cliente e contexto do orçamento',
      subtitulo:
      'Comece registrando quem solicitou o atendimento e por onde a demanda chegou.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoNomeClienteController,
                    label: 'Nome do cliente',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoDocumentoController,
                    label: 'CPF / Documento',
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoTelefoneController,
                    label: 'Telefone / WhatsApp',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoEmailController,
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownOrcamento<String>(
                    label: 'Origem do atendimento',
                    value: _orcamentoOrigemSelecionada,
                    items: _origensOrcamento,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _orcamentoOrigemSelecionada = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdownOrcamento<String>(
                    label: 'Prioridade',
                    value: _orcamentoPrioridadeSelecionada,
                    items: _prioridadesOrcamento,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _orcamentoPrioridadeSelecionada = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildInfoPill('Cliente ativo desde 2025', Icons.loyalty_outlined),
                  _buildInfoPill('3 atendimentos anteriores', Icons.history),
                  _buildInfoPill('Canal preferido: WhatsApp', Icons.chat_bubble_outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtapaEquipamentoOrcamento() {
    return _buildCardEtapaOrcamento(
      titulo: '2. Equipamento recebido',
      subtitulo:
      'Identifique o bem, os acessórios entregues e os dados que ajudam o técnico na triagem.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoEquipamentoController,
                    label: 'Descrição do equipamento',
                    icon: Icons.devices_other_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoSerialController,
                    label: 'Serial / IMEI / Patrimônio',
                    icon: Icons.confirmation_number_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoMarcaController,
                    label: 'Marca',
                    icon: Icons.business_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoModeloController,
                    label: 'Modelo / Versão',
                    icon: Icons.category_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextFieldOrcamento(
              controller: _orcamentoAcessoriosController,
              label: 'Acessórios entregues com o equipamento',
              icon: Icons.cable_outlined,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _buildChoiceStatus(
                  titulo: 'Equipamento reserva',
                  descricao:
                  'Separar unidade reserva enquanto o item estiver em manutenção.',
                  value: _orcamentoEquipamentoReserva,
                  onChanged: (value) {
                    setState(() {
                      _orcamentoEquipamentoReserva = value;
                    });
                  },
                ),
                _buildChoiceStatus(
                  titulo: 'Cliente autoriza contato',
                  descricao:
                  'Permite envio de status durante diagnóstico e execução.',
                  value: _orcamentoAutorizaContato,
                  onChanged: (value) {
                    setState(() {
                      _orcamentoAutorizaContato = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtapaDiagnosticoOrcamento() {
    return _buildCardEtapaOrcamento(
      titulo: '3. Diagnóstico técnico inicial',
      subtitulo:
      'Registre defeito relatado, observações técnicas e checklist perceptível para equipe e cliente.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextFieldOrcamento(
              controller: _orcamentoDefeitoRelatadoController,
              label: 'Defeito relatado pelo cliente',
              icon: Icons.report_problem_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            _buildTextFieldOrcamento(
              controller: _orcamentoObservacoesTecnicasController,
              label: 'Observações técnicas iniciais',
              icon: Icons.engineering_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Checklist de entrada',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ..._checklistDiagnostico.map((item) {
              final bool ok = item['ok'] == true;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      item['ok'] = !ok;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ok
                            ? Colors.green.withOpacity(0.30)
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                      color: ok
                          ? Colors.green.withOpacity(0.08)
                          : Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ok ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: ok
                              ? Colors.green
                              : Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['titulo'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['descricao'] as String,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEtapaItensOrcamento() {
    return _buildCardEtapaOrcamento(
      titulo: '4. Composição do orçamento',
      subtitulo:
          'Monte a proposta com serviços principais, peças e opcionais. O resumo lateral reage em tempo real.',
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _servicosOrcamento.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _servicosOrcamento[index];
                final bool selecionado = item['selecionado'] == true;
                final int quantidade = (item['quantidade'] ?? 1) as int;
                final double valor = ((item['valor'] ?? 0) as num).toDouble();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: selecionado
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: selecionado
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.40)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selecionado,
                        onChanged: (value) {
                          setState(() {
                            item['selecionado'] = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  item['tipo'] == 'produto'
                                      ? Icons.inventory_2_outlined
                                      : Icons.build_circle_outlined,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['nome'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['detalhe'] as String,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if (quantidade > 1) {
                                  item['quantidade'] = quantidade - 1;
                                }
                              });
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$quantidade',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                item['quantidade'] = quantidade + 1;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: Text(
                          'R\$ ${(valor * quantidade).toStringAsFixed(2)}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapaCondicoesOrcamento() {
    return _buildCardEtapaOrcamento(
      titulo: '5. Prazo, garantia e canais de aprovação',
      subtitulo:
      'Feche a proposta com condições comerciais, observações e meios de aprovação futura.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoPrazoController,
                    label: 'Prazo estimado',
                    icon: Icons.schedule_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextFieldOrcamento(
                    controller: _orcamentoGarantiaController,
                    label: 'Garantia',
                    icon: Icons.verified_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDropdownOrcamento<String>(
              label: 'Status interno do orçamento',
              value: _orcamentoStatusSelecionado,
              items: _statusInternoOrcamento,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _orcamentoStatusSelecionado = value;
                });
              },
            ),
            const SizedBox(height: 14),
            _buildTextFieldOrcamento(
              controller: _orcamentoObservacoesFinaisController,
              label: 'Observações finais e notas para integração futura',
              icon: Icons.note_alt_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Canais de aprovação e comunicação',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _canaisAprovacao.map((canal) {
                final selecionado = canal['selecionado'] == true;
                return FilterChip(
                  selected: selecionado,
                  avatar: Icon(
                    canal['icone'] as IconData,
                    size: 18,
                    color: selecionado
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(canal['titulo'] as String),
                  onSelected: (value) {
                    setState(() {
                      canal['selecionado'] = value;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _buildChoiceStatus(
                  titulo: 'Solicitar sinal',
                  descricao:
                  'Reserva da peça e início do serviço após pagamento parcial.',
                  value: _orcamentoRequerSinal,
                  onChanged: (value) {
                    setState(() {
                      _orcamentoRequerSinal = value;
                    });
                  },
                ),
                _buildChoiceStatus(
                  titulo: 'Autorizar contato automático',
                  descricao:
                  'Preparar futura automação por WhatsApp, e-mail e Telegram.',
                  value: _orcamentoAutorizaContato,
                  onChanged: (value) {
                    setState(() {
                      _orcamentoAutorizaContato = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardEtapaOrcamento({
    required String titulo,
    required String subtitulo,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRect(
                child: SizedBox(
                  width: double.infinity,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoLateralOrcamento() {
    final total = _calcularTotalOrcamentoSelecionado();
    final sinal = _calcularValorSinalOrcamento();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do orçamento',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResumoLinhaOrcamento(
                      'Cliente',
                      _orcamentoNomeClienteController.text,
                    ),
                    _buildResumoLinhaOrcamento(
                      'Equipamento',
                      _orcamentoEquipamentoController.text,
                    ),
                    _buildResumoLinhaOrcamento(
                      'Status',
                      _orcamentoStatusSelecionado,
                    ),
                    _buildResumoLinhaOrcamento(
                      'Prazo',
                      _orcamentoPrazoController.text,
                    ),
                    const Divider(height: 28),
                    Text(
                      'Itens selecionados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._servicosOrcamento
                        .where((item) => item['selecionado'] == true)
                        .map((item) {
                      final quantidade = (item['quantidade'] ?? 1) as int;
                      final valor = ((item['valor'] ?? 0) as num).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item['tipo'] == 'produto'
                                  ? Icons.inventory_2_outlined
                                  : Icons.build_circle_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${item['nome']} ($quantidade x)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'R\$ ${(valor * quantidade).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 26),
                    _buildResumoLinhaValorOrcamento('Subtotal', total),
                    _buildResumoLinhaValorOrcamento('Sinal sugerido', sinal),
                    const SizedBox(height: 10),
                    _buildResumoLinhaValorOrcamento(
                      'Total',
                      total,
                      destaque: true,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () {
                        _mostrarDialogMensagem(
                          'Mock de geração',
                          'No futuro, aqui você poderá gerar PDF, compartilhar por WhatsApp/e-mail e registrar a proposta no backend.',
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Gerar PDF / Compartilhar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsProximosPassos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximos passos sugeridos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          _buildBulletPasso('Persistir orçamento em backend com status e histórico'),
          _buildBulletPasso('Gerar PDF com assinatura visual da marca'),
          _buildBulletPasso('Enviar link de aprovação por WhatsApp, e-mail e Telegram'),
          _buildBulletPasso('Converter orçamento aprovado em ordem de serviço'),
        ],
      ),
    );
  }

  Widget _buildBulletPasso(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  Widget _buildResumoLinhaOrcamento(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              titulo,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor.isEmpty ? '-' : valor,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoLinhaValorOrcamento(
    String titulo,
    double valor, {
    bool destaque = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: destaque ? 16 : 14,
              fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: destaque ? 18 : 14,
              fontWeight: destaque ? FontWeight.w900 : FontWeight.w700,
              color: destaque
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraNavegacaoOrcamento() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _voltarEtapaOrcamento,
                icon: const Icon(Icons.arrow_back),
                label: Text(_etapaOrcamentoAtual == 0 ? 'Sair' : 'Voltar'),
              ),
              OutlinedButton.icon(
                onPressed: _confirmarCancelamentoOrcamento,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Etapa ${_etapaOrcamentoAtual + 1} de ${_calcularTotalEtapasOrcamento()}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FilledButton.icon(
                onPressed: _avancarEtapaOrcamento,
                icon: Icon(
                  _estaNaUltimaEtapaOrcamento()
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward,
                ),
                label: Text(
                  _estaNaUltimaEtapaOrcamento() ? 'Concluir' : 'Próxima etapa',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(180, 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldOrcamento({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  Widget _buildDropdownOrcamento<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChoiceStatus({
    required String titulo,
    required String descricao,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      width: 310,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(descricao),
      ),
    );
  }

  Widget _buildInfoPill(String texto, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
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
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAreaOrcamento(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
