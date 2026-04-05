import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/produto_model.dart';
import '../../top_navigation_bar.dart';

class OrdemServicoWeb extends StatefulWidget {
  const OrdemServicoWeb({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<OrdemServicoWeb> createState() => _OrdemServicoWebState();
}

class _OrdemServicoWebState extends State<OrdemServicoWeb> {
  final PageController _pageController = PageController(viewportFraction: 1.0);

  int _etapaAtual = 0;

  final TextEditingController _numeroOsController =
      TextEditingController(text: 'OS-2026-00458');
  final TextEditingController _nomeClienteController =
      TextEditingController(text: 'Marina Oliveira');
  final TextEditingController _telefoneController =
      TextEditingController(text: '(47) 99999-0001');
  final TextEditingController _emailController =
      TextEditingController(text: 'marina.oliveira@email.com');
  final TextEditingController _documentoController =
      TextEditingController(text: '123.456.789-00');
  final TextEditingController _equipamentoController =
      TextEditingController(text: 'iPhone 13 128GB');
  final TextEditingController _marcaController =
      TextEditingController(text: 'Apple');
  final TextEditingController _modeloController =
      TextEditingController(text: 'A2633');
  final TextEditingController _serialController =
      TextEditingController(text: 'SN-IP13-009988');
  final TextEditingController _acessoriosController =
      TextEditingController(text: 'Capa, película e cabo USB-C');
  final TextEditingController _defeitoRelatadoController = TextEditingController(
    text:
        'Tela sem imagem após queda. Cliente relata vibração normal e sons de notificações.',
  );
  final TextEditingController _diagnosticoController = TextEditingController(
    text:
        'Display comprometido, conector de tela com folga. Recomendado troca de display, testes de face ID, brilho e toque.',
  );
  final TextEditingController _observacoesInternasController =
      TextEditingController(
    text:
        'Cliente autorizou contato por WhatsApp. Priorizar fechamento em até 48h e registrar fotos do antes/depois.',
  );
  final TextEditingController _prazoController =
      TextEditingController(text: '2 dias úteis');
  final TextEditingController _garantiaController =
      TextEditingController(text: '90 dias para peças e serviço');
  final TextEditingController _responsavelTecnicoController =
      TextEditingController(text: 'André Souza');
  final TextEditingController _checkinObservacoesController =
      TextEditingController(
    text:
        'Aparelho recebido ligado, sem imagem, com pequenas marcas na carcaça lateral.',
  );

  final List<String> _statusOpcoes = const [
    'Aberta',
    'Triagem',
    'Aguardando aprovação',
    'Aguardando peça',
    'Em execução',
    'Pronta para entrega',
    'Finalizada',
  ];

  final List<String> _prioridades = const [
    'Baixa',
    'Normal',
    'Alta',
    'Urgente',
  ];

  final List<String> _origens = const [
    'Balcão',
    'WhatsApp',
    'Instagram',
    'Site',
    'Indicação',
  ];

  final List<String> _tiposAtendimento = const [
    'Assistência técnica',
    'Manutenção preventiva',
    'Instalação',
    'Garantia',
    'Diagnóstico',
  ];

  String _statusSelecionado = 'Aguardando aprovação';
  String _prioridadeSelecionada = 'Alta';
  String _origemSelecionada = 'WhatsApp';
  String _tipoAtendimentoSelecionado = 'Assistência técnica';
  bool _clienteAutorizaContato = true;
  bool _clienteAprovouDiagnostico = true;
  bool _requerSinal = true;
  bool _equipamentoReserva = false;
  bool _entregaDomicilio = false;

  final List<Map<String, dynamic>> _checklistEntrada = [
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
      'titulo': 'Touch responde',
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

  final List<Map<String, dynamic>> _tarefasExecucao = [
    {
      'titulo': 'Triagem inicial concluída',
      'responsavel': 'André Souza',
      'status': 'Concluída',
      'duracao': '15 min',
      'ok': true,
    },
    {
      'titulo': 'Teste de display provisório',
      'responsavel': 'André Souza',
      'status': 'Em andamento',
      'duracao': '20 min',
      'ok': false,
    },
    {
      'titulo': 'Validação do Face ID',
      'responsavel': 'Marcos Lima',
      'status': 'Pendente',
      'duracao': '10 min',
      'ok': false,
    },
  ];

  final List<Map<String, dynamic>> _itensOs = [
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
      'nome': 'Revisão interna e testes finais',
      'detalhe': 'Checklist completo de entrega',
      'quantidade': 1,
      'valor': 90.00,
      'selecionado': true,
    },
    {
      'tipo': 'produto',
      'nome': 'Película de proteção 3D',
      'detalhe': 'Opcional sugerido na entrega',
      'quantidade': 1,
      'valor': 49.90,
      'selecionado': false,
    },
    {
      'tipo': 'produto',
      'nome': 'Capa magnética premium',
      'detalhe': 'Upsell no fechamento',
      'quantidade': 1,
      'valor': 79.90,
      'selecionado': false,
    },
  ];

  final List<Map<String, dynamic>> _historico = [
    {
      'titulo': 'OS aberta no balcão',
      'descricao': 'Cliente identificado e aparelho recebido para triagem.',
      'tempo': 'Hoje • 09:14',
      'icone': Icons.add_task,
    },
    {
      'titulo': 'Diagnóstico registrado',
      'descricao': 'Hipótese principal validada e orçamento preparado.',
      'tempo': 'Hoje • 09:42',
      'icone': Icons.medical_information_outlined,
    },
    {
      'titulo': 'Mensagem enviada ao cliente',
      'descricao': 'Resumo do orçamento enviado por WhatsApp.',
      'tempo': 'Hoje • 09:47',
      'icone': Icons.chat_bubble_outline,
    },
  ];

  final List<Map<String, dynamic>> _canaisComunicacao = [
    {'titulo': 'WhatsApp', 'selecionado': true, 'icone': Icons.chat},
    {'titulo': 'E-mail', 'selecionado': true, 'icone': Icons.email_outlined},
    {'titulo': 'Telegram', 'selecionado': false, 'icone': Icons.send},
    {'titulo': 'SMS', 'selecionado': false, 'icone': Icons.sms_outlined},
  ];

  void _logInfo(String message) {
    debugPrint('[OrdemServicoWeb][INFO] $message');
  }

  @override
  void initState() {
    super.initState();
    _logInfo('OrdemServicoWeb iniciada');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _numeroOsController.dispose();
    _nomeClienteController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _documentoController.dispose();
    _equipamentoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _serialController.dispose();
    _acessoriosController.dispose();
    _defeitoRelatadoController.dispose();
    _diagnosticoController.dispose();
    _observacoesInternasController.dispose();
    _prazoController.dispose();
    _garantiaController.dispose();
    _responsavelTecnicoController.dispose();
    _checkinObservacoesController.dispose();
    super.dispose();
  }

  Future<void> _abrirSelecaoProdutoWeb() async {
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

    if (result != null) {
      setState(() {
        _itensOs.add({
          'tipo': 'produto',
          'nome': result.nomeProduto,
          'detalhe': 'Produto adicionado manualmente à OS',
          'quantidade': 1,
          'valor': (result.precoVenda as num).toDouble(),
          'selecionado': true,
        });
      });
    }
  }

  List<Map<String, dynamic>> _etapas() {
    return const [
      {
        'titulo': 'Abertura',
        'descricao': 'Status, origem e contexto inicial',
        'icone': Icons.assignment_add,
      },
      {
        'titulo': 'Cliente e item',
        'descricao': 'Cadastro, equipamento e check-in',
        'icone': Icons.devices_other_outlined,
      },
      {
        'titulo': 'Diagnóstico',
        'descricao': 'Checklist, defeito e parecer técnico',
        'icone': Icons.medical_information_outlined,
      },
      {
        'titulo': 'Execução',
        'descricao': 'Tarefas, técnico e progresso',
        'icone': Icons.engineering_outlined,
      },
      {
        'titulo': 'Itens e custos',
        'descricao': 'Serviços, peças e aprovação',
        'icone': Icons.inventory_2_outlined,
      },
      {
        'titulo': 'Entrega',
        'descricao': 'Prazo, garantia e fechamento',
        'icone': Icons.verified_outlined,
      },
    ];
  }

  int _totalEtapas() => _etapas().length;

  bool _estaNaUltimaEtapa() => _etapaAtual == _totalEtapas() - 1;

  void _irParaEtapa(int index) {
    setState(() {
      _etapaAtual = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _avancar() {
    if (_estaNaUltimaEtapa()) {
      _mostrarDialogMensagem(
        'Ordem de serviço pronta',
        'No futuro, aqui você poderá persistir a OS, gerar PDF, compartilhar e converter o fluxo em faturamento/entrega.',
      );
      return;
    }
    _irParaEtapa(_etapaAtual + 1);
  }

  void _voltar() {
    if (_etapaAtual == 0) {
      if (widget.embedded) {
        widget.onBack?.call();
        return;
      }

      Navigator.of(context).maybePop();
      return;
    }

    _irParaEtapa(_etapaAtual - 1);
  }

  double _totalSelecionado() {
    return _itensOs.where((item) => item['selecionado'] == true).fold<double>(
          0,
          (soma, item) =>
              soma +
              (((item['valor'] ?? 0) as num).toDouble() *
                  ((item['quantidade'] ?? 1) as int)),
        );
  }

  double _valorSinal() => _requerSinal ? _totalSelecionado() * 0.30 : 0;

  int _quantidadeItensSelecionados() {
    return _itensOs.where((item) => item['selecionado'] == true).fold<int>(
          0,
          (soma, item) => soma + ((item['quantidade'] ?? 1) as int),
        );
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
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
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
        alignLabelWithHint: maxLines > 1,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(icon),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 20 : 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildDropdown<T>({
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
      width: 320,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w700),
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
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildCardEtapa({
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
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoLinha(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
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
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoLinhaValor(String titulo, double valor,
      {bool destaque = false}) {
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

  Widget _buildResumoLateral() {
    final total = _totalSelecionado();
    final sinal = _valorSinal();

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
              'Resumo da OS',
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
                    _buildResumoLinha('OS', _numeroOsController.text),
                    _buildResumoLinha('Cliente', _nomeClienteController.text),
                    _buildResumoLinha(
                        'Equipamento', _equipamentoController.text),
                    _buildResumoLinha('Status', _statusSelecionado),
                    _buildResumoLinha('Técnico', _responsavelTecnicoController.text),
                    _buildResumoLinha('Prazo', _prazoController.text),
                    const Divider(height: 28),
                    Text(
                      'Itens selecionados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ..._itensOs
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
                    _buildResumoLinhaValor(
                        'Qtd. itens', _quantidadeItensSelecionados().toDouble(),
                        destaque: false),
                    _buildResumoLinhaValor('Subtotal', total),
                    _buildResumoLinhaValor('Sinal sugerido', sinal),
                    const SizedBox(height: 10),
                    _buildResumoLinhaValor('Total', total, destaque: true),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () {
                        _mostrarDialogMensagem(
                          'Mock de geração',
                          'No futuro, aqui você poderá gerar PDF da ordem de serviço, compartilhar com o cliente e armazenar o documento.',
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

  Widget _buildHistoricoLateral() {
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
            'Linha do tempo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ..._historico.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icone'] as IconData,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['titulo'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(item['descricao'] as String),
                        const SizedBox(height: 2),
                        Text(
                          item['tempo'] as String,
                          style: TextStyle(
                            fontSize: 12,
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
        ],
      ),
    );
  }

  Widget _buildEtapaAbertura() {
    return _buildCardEtapa(
      titulo: '1. Abertura da ordem de serviço',
      subtitulo:
          'Registre o contexto da OS, o status inicial, o canal de entrada e a criticidade da demanda.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _numeroOsController,
                    label: 'Número da OS',
                    icon: Icons.tag_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Status atual',
                    value: _statusSelecionado,
                    items: _statusOpcoes,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _statusSelecionado = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Origem',
                    value: _origemSelecionada,
                    items: _origens,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _origemSelecionada = value);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Prioridade',
                    value: _prioridadeSelecionada,
                    items: _prioridades,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _prioridadeSelecionada = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDropdown<String>(
              label: 'Tipo de atendimento',
              value: _tipoAtendimentoSelecionado,
              items: _tiposAtendimento,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _tipoAtendimentoSelecionado = value);
              },
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
                  _buildInfoPill('Fluxo de abertura guiado', Icons.auto_awesome),
                  _buildInfoPill('Aprovação digital prevista', Icons.verified_user),
                  _buildInfoPill('Comunicação multicanal', Icons.chat_bubble_outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtapaClienteItem() {
    return _buildCardEtapa(
      titulo: '2. Cliente, equipamento e check-in',
      subtitulo:
          'Centralize os dados da pessoa, do item recebido e os registros de entrada da operação.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nomeClienteController,
                    label: 'Nome do cliente',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _documentoController,
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
                  child: _buildTextField(
                    controller: _telefoneController,
                    label: 'Telefone / WhatsApp',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
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
                  child: _buildTextField(
                    controller: _equipamentoController,
                    label: 'Equipamento / item',
                    icon: Icons.devices_other_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _serialController,
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
                  child: _buildTextField(
                    controller: _marcaController,
                    label: 'Marca',
                    icon: Icons.business_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _modeloController,
                    label: 'Modelo / versão',
                    icon: Icons.category_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _acessoriosController,
              label: 'Acessórios entregues',
              icon: Icons.cable_outlined,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _checkinObservacoesController,
              label: 'Observações de check-in',
              icon: Icons.rule_folder_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _buildChoiceStatus(
                  titulo: 'Cliente autoriza contato',
                  descricao: 'Permite envio de status e aprovações durante a OS.',
                  value: _clienteAutorizaContato,
                  onChanged: (value) {
                    setState(() => _clienteAutorizaContato = value);
                  },
                ),
                _buildChoiceStatus(
                  titulo: 'Equipamento reserva',
                  descricao: 'Separar unidade reserva enquanto a OS estiver ativa.',
                  value: _equipamentoReserva,
                  onChanged: (value) {
                    setState(() => _equipamentoReserva = value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtapaDiagnostico() {
    return _buildCardEtapa(
      titulo: '3. Diagnóstico e validação técnica',
      subtitulo:
          'Registre o defeito, a hipótese técnica e o checklist de entrada com linguagem clara para a equipe.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextField(
              controller: _defeitoRelatadoController,
              label: 'Defeito relatado pelo cliente',
              icon: Icons.report_problem_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _diagnosticoController,
              label: 'Diagnóstico técnico / parecer inicial',
              icon: Icons.engineering_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _observacoesInternasController,
              label: 'Observações internas',
              icon: Icons.sticky_note_2_outlined,
              maxLines: 3,
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
            ..._checklistEntrada.map((item) {
              final bool ok = item['ok'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => item['ok'] = !ok),
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
                          ok
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
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
                              Text(item['descricao'] as String),
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

  Widget _buildEtapaExecucao() {
    return _buildCardEtapa(
      titulo: '4. Execução, técnico e progresso operacional',
      subtitulo:
          'Distribua atividades, acompanhe andamento e mantenha a OS atualizada para a equipe e para o atendimento.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _responsavelTecnicoController,
                    label: 'Técnico responsável',
                    icon: Icons.person_pin_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Status da OS',
                    value: _statusSelecionado,
                    items: _statusOpcoes,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _statusSelecionado = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tarefas da execução',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            ..._tarefasExecucao.map((tarefa) {
              final bool ok = tarefa['ok'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: ok
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.08)
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: ok
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.40)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: ok,
                        onChanged: (value) {
                          setState(() => tarefa['ok'] = value ?? false);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tarefa['titulo'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                _buildInfoPill(
                                  tarefa['responsavel'] as String,
                                  Icons.person_outline,
                                ),
                                _buildInfoPill(
                                  tarefa['status'] as String,
                                  Icons.flag_outlined,
                                ),
                                _buildInfoPill(
                                  tarefa['duracao'] as String,
                                  Icons.schedule_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEtapaItensCustos() {
    return _buildCardEtapa(
      titulo: '5. Itens, custos e aprovação do cliente',
      subtitulo:
          'Componha a OS com serviços e peças, permita ajustes e deixe a proposta pronta para aprovação e faturamento.',
      child: Column(
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: _abrirSelecaoProdutoWeb,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Adicionar produto'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _mostrarDialogMensagem(
                    'Sugestão futura',
                    'No futuro, aqui você poderá buscar serviços padronizados, kits e bundles por categoria.',
                  );
                },
                icon: const Icon(Icons.build_outlined),
                label: const Text('Adicionar serviço'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _itensOs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _itensOs[index];
                final bool selecionado = item['selecionado'] == true;
                final int quantidade = (item['quantidade'] ?? 1) as int;
                final double valor = ((item['valor'] ?? 0) as num).toDouble();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: selecionado
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.08)
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: selecionado
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.40)
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selecionado,
                        onChanged: (value) {
                          setState(() => item['selecionado'] = value ?? false);
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
                                  color:
                                      Theme.of(context).colorScheme.primary,
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
                            Text(item['detalhe'] as String),
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
                                if (quantidade > 1) item['quantidade'] = quantidade - 1;
                              });
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$quantidade',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => item['quantidade'] = quantidade + 1);
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _buildChoiceStatus(
                titulo: 'Diagnóstico aprovado',
                descricao: 'Cliente já aprovou a continuidade da execução.',
                value: _clienteAprovouDiagnostico,
                onChanged: (value) {
                  setState(() => _clienteAprovouDiagnostico = value);
                },
              ),
              _buildChoiceStatus(
                titulo: 'Solicitar sinal',
                descricao: 'Reserva de peça e início do serviço após pagamento parcial.',
                value: _requerSinal,
                onChanged: (value) {
                  setState(() => _requerSinal = value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEtapaEntrega() {
    return _buildCardEtapa(
      titulo: '6. Entrega, garantia e fechamento',
      subtitulo:
          'Prepare a conclusão da OS com prazo, garantia, canais de comunicação e condições de entrega.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _prazoController,
                    label: 'Prazo estimado',
                    icon: Icons.schedule_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _garantiaController,
                    label: 'Garantia',
                    icon: Icons.verified_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Canais de comunicação',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _canaisComunicacao.map((canal) {
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
                    setState(() => canal['selecionado'] = value);
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
                  titulo: 'Entrega em domicílio',
                  descricao: 'Preparar rota, taxa e confirmação de recebimento.',
                  value: _entregaDomicilio,
                  onChanged: (value) {
                    setState(() => _entregaDomicilio = value);
                  },
                ),
                _buildChoiceStatus(
                  titulo: 'Autorizar contato automático',
                  descricao: 'Preparar futuras notificações por WhatsApp, e-mail e Telegram.',
                  value: _clienteAutorizaContato,
                  onChanged: (value) {
                    setState(() => _clienteAutorizaContato = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximos passos recomendados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _buildBulletPasso('Persistir OS com status e histórico operacional'),
                  _buildBulletPasso('Gerar PDF da OS para compartilhamento e impressão'),
                  _buildBulletPasso('Converter itens aprovados em cobrança/faturamento'),
                  _buildBulletPasso('Notificar cliente sobre conclusão e retirada'),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildBarraNavegacao() {
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
                onPressed: _voltar,
                icon: const Icon(Icons.arrow_back),
                label: Text(_etapaAtual == 0 ? 'Sair' : 'Voltar'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _mostrarDialogMensagem(
                    'Salvar rascunho',
                    'No futuro, aqui você poderá salvar a ordem de serviço em andamento sem concluir o fluxo.',
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar rascunho'),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Etapa ${_etapaAtual + 1} de ${_totalEtapas()}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FilledButton.icon(
                onPressed: _avancar,
                icon: Icon(
                  _estaNaUltimaEtapa()
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward,
                ),
                label: Text(
                  _estaNaUltimaEtapa() ? 'Concluir' : 'Próxima etapa',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget conteudo = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                          theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.65),
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
                                    Icons.assignment_turned_in_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Fluxo de Ordem de Serviço',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            _buildBadgeInformativo(
                              'Etapa ${_etapaAtual + 1}/${_totalEtapas()}',
                              Icons.view_carousel_outlined,
                            ),
                            _buildBadgeInformativo(
                              _statusSelecionado,
                              Icons.flag_outlined,
                            ),
                            _buildBadgeInformativo(
                              _prioridadeSelecionada,
                              Icons.bolt_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tela completa de ordem de serviço inspirada em padrões atuais de gestão operacional: intake organizado, acompanhamento de status, aprovação do cliente, execução por técnico, itens da OS e fechamento com garantia e comunicação.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: alturaCurta ? 12 : 18),
                        SizedBox(
                          height: alturaCurta ? 96 : 108,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _totalEtapas(),
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final etapa = _etapas()[index];
                              final selecionada = index == _etapaAtual;
                              final concluida = index < _etapaAtual;

                              return InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => _irParaEtapa(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: alturaCurta ? 220 : 248,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: alturaCurta ? 12 : 16,
                                    vertical: alturaCurta ? 10 : 14,
                                  ),
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
                                            : theme.colorScheme
                                            .surfaceContainerHighest,
                                        foregroundColor: selecionada
                                            ? theme.colorScheme.primary
                                            : concluida
                                            ? Colors.white
                                            : theme.colorScheme
                                            .onSurfaceVariant,
                                        child: Icon(
                                          etapa['icone'] as IconData,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              etapa['titulo'] as String,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
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
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 12,
                                                height: 1.15,
                                                color: selecionada
                                                    ? Colors.white.withOpacity(0.90)
                                                    : theme.colorScheme
                                                    .onSurfaceVariant,
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
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _etapaAtual = index);
                            },
                            children: [
                              _buildEtapaAbertura(),
                              _buildEtapaClienteItem(),
                              _buildEtapaDiagnostico(),
                              _buildEtapaExecucao(),
                              _buildEtapaItensCustos(),
                              _buildEtapaEntrega(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        SizedBox(
                          width: 380,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildResumoLateral()),
                              const SizedBox(height: 14),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: _buildHistoricoLateral(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: alturaCurta ? 10 : 16),
                  _buildBarraNavegacao(),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return Container(
        color: theme.colorScheme.surfaceContainerLowest,
        child: conteudo,
      );
    }

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
            ],
            onSelect: (value) {
              if (value == 'Produtos') {
                showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
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
            title: 'Ajuda',
            subItems: ['Suporte', 'Sobre'],
          ),
        ],
        onNotificationPressed: () {},
      ),
      body: conteudo,
    );
  }

}
