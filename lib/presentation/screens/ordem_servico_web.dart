import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/sub_painel_cadastro_cliente.dart';
import 'package:appplanilha/sub_painel_cadastro_colaborador.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/produto_model.dart';
import '../../mock_cadastros_store.dart';
import '../../top_navigation_bar.dart';

class OrdemServicoWeb extends StatefulWidget {
  const OrdemServicoWeb({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<OrdemServicoWeb> createState() => _OrdemServicoWebState();
}

class _OrdemServicoWebState extends State<OrdemServicoWeb> {
  final PageController _pageController = PageController();
  int _step = 0;

  final TextEditingController _osController = TextEditingController(text: 'OS-2026-00458');
  final TextEditingController _orcamentoOrigemController = TextEditingController(text: 'ORC-2026-00127');
  final TextEditingController _clienteController = TextEditingController(text: 'Marina Oliveira');
  final TextEditingController _telefoneController = TextEditingController(text: '(47) 99999-0001');
  final TextEditingController _emailController = TextEditingController(text: 'marina.oliveira@email.com');
  final TextEditingController _documentoController = TextEditingController(text: '123.456.789-00');
  final TextEditingController _equipamentoController = TextEditingController(text: 'iPhone 13 128GB');
  final TextEditingController _marcaController = TextEditingController(text: 'Apple');
  final TextEditingController _modeloController = TextEditingController(text: 'A2633');
  final TextEditingController _serialController = TextEditingController(text: 'SN-IP13-009988');
  final TextEditingController _acessoriosController = TextEditingController(text: 'Capa, película e cabo USB-C');
  final TextEditingController _defeitoController = TextEditingController(text: 'Tela sem imagem após queda. Cliente relata vibração e sons de notificações.');
  final TextEditingController _diagnosticoController = TextEditingController(text: 'Display comprometido e conector com folga. Recomendado troca de display e testes finais.');
  final TextEditingController _observacoesController = TextEditingController(text: 'Cliente autorizou contato por WhatsApp. Priorizar fechamento em até 48h.');
  final TextEditingController _prazoController = TextEditingController(text: '2 dias úteis');
  final TextEditingController _garantiaController = TextEditingController(text: '90 dias para peças e serviço');
  final TextEditingController _tecnicoController = TextEditingController(text: 'André Souza');
  final TextEditingController _checkinController = TextEditingController(text: 'Aparelho recebido ligado, sem imagem, com leves marcas laterais.');
  final TextEditingController _assinanteController = TextEditingController(text: 'Marina Oliveira');

  final List<String> _statusDisponiveis = <String>['Aberta', 'Em análise', 'Aguardando aprovação', 'Aprovada', 'Em execução', 'Aguardando peça', 'Pronta', 'Entregue', 'Cancelada', 'Sem reparo'];
  final List<String> _prioridades = <String>['Baixa', 'Normal', 'Alta', 'Urgente'];
  final List<String> _origens = <String>['Balcão', 'WhatsApp', 'Instagram', 'Site', 'Indicação'];
  final List<String> _tipos = <String>['Assistência técnica', 'Manutenção preventiva', 'Instalação', 'Garantia', 'Diagnóstico'];

  String _statusSelecionado = 'Em análise';
  String _prioridadeSelecionada = 'Alta';
  String _origemSelecionada = 'WhatsApp';
  String _tipoSelecionado = 'Assistência técnica';
  bool _autorizaContato = true;
  bool _aprovou = true;
  bool _requerSinal = true;
  bool _reserva = false;
  bool _entrega = false;
  bool _assinou = false;
  DateTime? _assinadoEm;
  List<Offset?> _pontos = <Offset?>[];

  final List<Map<String, dynamic>> _checklist = <Map<String, dynamic>>[
    <String, dynamic>{'titulo': 'Liga normalmente', 'descricao': 'Equipamento energiza e apresenta sinais básicos de vida.', 'ok': true},
    <String, dynamic>{'titulo': 'Tela apresenta imagem', 'descricao': 'Display principal está funcional.', 'ok': false},
    <String, dynamic>{'titulo': 'Touch responde', 'descricao': 'Touch responde corretamente em toda a área.', 'ok': false},
    <String, dynamic>{'titulo': 'Carregamento funcional', 'descricao': 'Conector e bateria respondem no teste inicial.', 'ok': true},
  ];

  final List<Map<String, dynamic>> _tarefas = <Map<String, dynamic>>[
    <String, dynamic>{'titulo': 'Triagem inicial concluída', 'responsavel': 'André Souza', 'status': 'Concluída', 'duracao': '15 min', 'ok': true},
    <String, dynamic>{'titulo': 'Teste de display provisório', 'responsavel': 'André Souza', 'status': 'Em andamento', 'duracao': '20 min', 'ok': false},
    <String, dynamic>{'titulo': 'Validação final', 'responsavel': 'Marcos Lima', 'status': 'Pendente', 'duracao': '10 min', 'ok': false},
  ];

  final List<Map<String, dynamic>> _itens = <Map<String, dynamic>>[
    <String, dynamic>{'tipo': 'servico', 'nome': 'Troca de display OLED premium', 'detalhe': 'Mão de obra técnica especializada', 'quantidade': 1, 'valor': 790.0, 'selecionado': true},
    <String, dynamic>{'tipo': 'servico', 'nome': 'Revisão interna e testes finais', 'detalhe': 'Checklist completo de entrega', 'quantidade': 1, 'valor': 90.0, 'selecionado': true},
    <String, dynamic>{'tipo': 'produto', 'nome': 'Película de proteção 3D', 'detalhe': 'Opcional sugerido na entrega', 'quantidade': 1, 'valor': 49.9, 'selecionado': false},
  ];

  final List<Map<String, dynamic>> _timeline = <Map<String, dynamic>>[
    <String, dynamic>{'titulo': 'OS aberta no balcão', 'descricao': 'Cliente identificado e aparelho recebido para triagem.', 'hora': 'Hoje • 09:14', 'icone': Icons.add_task},
    <String, dynamic>{'titulo': 'Diagnóstico registrado', 'descricao': 'Hipótese principal validada e orçamento vinculado.', 'hora': 'Hoje • 09:42', 'icone': Icons.medical_information_outlined},
    <String, dynamic>{'titulo': 'Mensagem enviada ao cliente', 'descricao': 'Resumo do orçamento enviado por WhatsApp.', 'hora': 'Hoje • 09:47', 'icone': Icons.chat_bubble_outline},
  ];

  final List<Map<String, dynamic>> _canais = <Map<String, dynamic>>[
    <String, dynamic>{'titulo': 'WhatsApp', 'selecionado': true, 'icone': Icons.chat},
    <String, dynamic>{'titulo': 'E-mail', 'selecionado': true, 'icone': Icons.email_outlined},
    <String, dynamic>{'titulo': 'Telegram', 'selecionado': false, 'icone': Icons.send},
    <String, dynamic>{'titulo': 'SMS', 'selecionado': false, 'icone': Icons.sms_outlined},
  ];

  List<Map<String, dynamic>> get _steps => const <Map<String, dynamic>>[
    <String, dynamic>{'titulo': 'Abertura', 'descricao': 'Status, origem e contexto', 'icone': Icons.assignment_add},
    <String, dynamic>{'titulo': 'Cliente e item', 'descricao': 'Cadastro e check-in', 'icone': Icons.devices_other_outlined},
    <String, dynamic>{'titulo': 'Diagnóstico', 'descricao': 'Defeito e checklist', 'icone': Icons.medical_information_outlined},
    <String, dynamic>{'titulo': 'Execução', 'descricao': 'Técnico e tarefas', 'icone': Icons.engineering_outlined},
    <String, dynamic>{'titulo': 'Itens e custos', 'descricao': 'Peças, serviços e aprovação', 'icone': Icons.inventory_2_outlined},
    <String, dynamic>{'titulo': 'Entrega', 'descricao': 'Prazo, QR e assinatura', 'icone': Icons.verified_outlined},
  ];

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _osController,
      _orcamentoOrigemController,
      _clienteController,
      _telefoneController,
      _emailController,
      _documentoController,
      _equipamentoController,
      _marcaController,
      _modeloController,
      _serialController,
      _acessoriosController,
      _defeitoController,
      _diagnosticoController,
      _observacoesController,
      _prazoController,
      _garantiaController,
      _tecnicoController,
      _checkinController,
      _assinanteController,
    ]) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  double _total() {
    return _itens.where((Map<String, dynamic> e) => e['selecionado'] == true).fold<double>(0, (double total, Map<String, dynamic> e) => total + (((e['valor'] ?? 0) as num).toDouble() * ((e['quantidade'] ?? 1) as int)));
  }

  double _sinalValor() => _requerSinal ? _total() * .30 : 0;
  int _qtd() => _itens.where((Map<String, dynamic> e) => e['selecionado'] == true).fold<int>(0, (int total, Map<String, dynamic> e) => total + ((e['quantidade'] ?? 1) as int));
  int _okCheck() => _checklist.where((Map<String, dynamic> e) => e['ok'] == true).length;
  int _okTarefas() => _tarefas.where((Map<String, dynamic> e) => e['ok'] == true).length;
  bool get _last => _step == _steps.length - 1;

  String _link() => 'http://localhost:39441/ordem-servico/${_osController.text.trim().toLowerCase().replaceAll(' ', '-').replaceAll('/', '-')}';

  String _dt(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _go(int index) {
    setState(() => _step = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  Future<void> _selecionarCliente() async {
    final ClienteMock? cliente = await showSelecaoClienteDialog(context);
    if (cliente == null) {
      return;
    }
    setState(() {
      _clienteController.text = cliente.nome;
      _telefoneController.text = cliente.telefone;
      _emailController.text = cliente.email;
      _documentoController.text = cliente.documento;
      _assinanteController.text = cliente.nome;
      _observacoesController.text = cliente.observacoes;
    });
  }

  Future<void> _selecionarTecnico() async {
    final ColaboradorMock? colaborador = await showSelecaoColaboradorDialog(context, titulo: 'Selecionar técnico responsável');
    if (colaborador == null) {
      return;
    }
    setState(() {
      _tecnicoController.text = colaborador.nome;
      if (_tarefas.isNotEmpty) {
        _tarefas.first['responsavel'] = colaborador.nome;
      }
    });
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _link()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link do resumo copiado para a área de transferência.')));
  }

  Future<void> _pickProduto() async {
    final ProdutoModel? result = await showDialog<ProdutoModel>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.80,
            height: MediaQuery.of(context).size.height * 0.80,
            child: SubPainelWebProdutoLista(isSelecao: true),
          ),
        );
      },
    );
    if (result == null) {
      return;
    }
    setState(() {
      _itens.add(<String, dynamic>{
        'tipo': 'produto',
        'nome': result.nomeProduto,
        'detalhe': 'Produto adicionado manualmente à OS',
        'quantidade': 1,
        'valor': (result.precoVenda as num).toDouble(),
        'selecionado': true,
      });
      _timeline.insert(0, <String, dynamic>{'titulo': 'Produto incluído na OS', 'descricao': '${result.nomeProduto} foi adicionado ao fluxo da ordem de serviço.', 'hora': 'Agora', 'icone': Icons.add_box_outlined});
    });
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Fechar'))],
      ),
    );
  }

  Future<void> _confirmCancelAll() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Cancelar tudo'),
        content: const Text('Deseja descartar todo o fluxo da ordem de serviço e voltar para a tela anterior?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Continuar editando')),
          FilledButton.icon(onPressed: () => Navigator.of(dialogContext).pop(true), icon: const Icon(Icons.delete_outline), label: const Text('Cancelar tudo')),
        ],
      ),
    );
    if (ok == true) {
      if (widget.embedded) {
        widget.onBack?.call();
      } else {
        Navigator.of(context).maybePop();
      }
    }
  }

  Future<void> _signDialog() async {
    final TextEditingController nome = TextEditingController(text: _assinanteController.text);
    List<Offset?> temp = List<Offset?>.from(_pontos);

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (_, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Assinatura digital do cliente'),
              content: SizedBox(
                width: 760,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nome,
                      decoration: const InputDecoration(labelText: 'Nome do assinante', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    _SignaturePad(points: temp, onChanged: (List<Offset?> value) => setModalState(() => temp = value)),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
                TextButton.icon(onPressed: () => setModalState(() => temp = <Offset?>[]), icon: const Icon(Icons.refresh), label: const Text('Limpar')),
                FilledButton.icon(
                  onPressed: () {
                    if (temp.whereType<Offset>().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça a assinatura antes de salvar.')));
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Salvar assinatura'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      setState(() {
        _assinanteController.text = nome.text.trim();
        _pontos = temp;
        _assinou = true;
        _assinadoEm = DateTime.now();
        _timeline.insert(0, <String, dynamic>{'titulo': 'Assinatura digital coletada', 'descricao': 'Cliente revisou o resumo da OS e assinou digitalmente.', 'hora': 'Agora', 'icone': Icons.draw_outlined});
      });
    }

    nome.dispose();
  }

  Widget _tf(TextEditingController controller, String label, IconData icon, {int lines = 1}) {
    return TextField(
      controller: controller,
      maxLines: lines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: lines > 1,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _dd(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
      items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
    );
  }

  Widget _stepCard(String title, String sub, Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(sub, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Expanded(child: SizedBox(width: double.infinity, child: child)),
          ],
        ),
      ),
    );
  }

  Widget _stepAbertura() {
    return _stepCard(
      '1. Abertura da ordem de serviço',
      'A OS passa a representar execução operacional real, ligada ao cliente e podendo nascer de um orçamento aprovado.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[Expanded(child: _tf(_osController, 'Número da OS', Icons.tag_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_orcamentoOrigemController, 'Orçamento de origem', Icons.request_quote_outlined))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[Expanded(child: _dd('Status atual', _statusSelecionado, _statusDisponiveis, (String? value) => setState(() => _statusSelecionado = value ?? _statusSelecionado))), const SizedBox(width: 14), Expanded(child: _dd('Prioridade', _prioridadeSelecionada, _prioridades, (String? value) => setState(() => _prioridadeSelecionada = value ?? _prioridadeSelecionada)))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[Expanded(child: _dd('Origem', _origemSelecionada, _origens, (String? value) => setState(() => _origemSelecionada = value ?? _origemSelecionada))), const SizedBox(width: 14), Expanded(child: _dd('Tipo de atendimento', _tipoSelecionado, _tipos, (String? value) => setState(() => _tipoSelecionado = value ?? _tipoSelecionado)))]),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.06), borderRadius: BorderRadius.circular(18)),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _pill('Fluxo guiado', Icons.auto_awesome),
                  _pill('QR para o cliente', Icons.qr_code_rounded),
                  _pill('Assinatura digital', Icons.draw_rounded),
                  _pill('Ligada ao orçamento', Icons.link_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCliente() {
    return _stepCard(
      '2. Cliente, equipamento e check-in',
      'O executor do reparo será o dono do app ou um colaborador cadastrado, então cliente e equipe precisam existir no fluxo desde cedo.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(onPressed: _selecionarCliente, icon: const Icon(Icons.person_search_outlined), label: const Text('Selecionar cliente cadastrado')),
                OutlinedButton.icon(onPressed: () => showSubPainelCadastroCliente(context, 'Cadastro de Clientes'), icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('Novo cliente')),
                OutlinedButton.icon(onPressed: _selecionarTecnico, icon: const Icon(Icons.engineering_outlined), label: const Text('Selecionar técnico responsável')),
                OutlinedButton.icon(onPressed: () => showSubPainelCadastroColaborador(context, 'Cadastro de Colaboradores'), icon: const Icon(Icons.group_add_outlined), label: const Text('Novo colaborador')),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: <Widget>[Expanded(child: _tf(_clienteController, 'Nome do cliente', Icons.person_outline)), const SizedBox(width: 14), Expanded(child: _tf(_documentoController, 'CPF / Documento', Icons.badge_outlined))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[Expanded(child: _tf(_telefoneController, 'Telefone / WhatsApp', Icons.phone_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_emailController, 'E-mail', Icons.email_outlined))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[Expanded(child: _tf(_equipamentoController, 'Equipamento / item', Icons.devices_other_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_serialController, 'Serial / IMEI / Patrimônio', Icons.confirmation_number_outlined))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[Expanded(child: _tf(_marcaController, 'Marca', Icons.business_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_modeloController, 'Modelo / versão', Icons.category_outlined))]),
            const SizedBox(height: 14),
            _tf(_acessoriosController, 'Acessórios entregues', Icons.cable_outlined),
            const SizedBox(height: 14),
            _tf(_checkinController, 'Observações de check-in', Icons.rule_folder_outlined, lines: 3),
          ],
        ),
      ),
    );
  }

  Widget _stepDiagnostico() {
    return _stepCard(
      '3. Diagnóstico e validação técnica',
      'Aqui a OS deixa de ser apenas proposta e passa a refletir o andamento operacional do reparo.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _tf(_defeitoController, 'Defeito relatado pelo cliente', Icons.report_problem_outlined, lines: 4),
            const SizedBox(height: 14),
            _tf(_diagnosticoController, 'Diagnóstico técnico / parecer inicial', Icons.engineering_outlined, lines: 4),
            const SizedBox(height: 14),
            _tf(_observacoesController, 'Observações internas', Icons.sticky_note_2_outlined, lines: 3),
            const SizedBox(height: 18),
            Align(alignment: Alignment.centerLeft, child: Text('Checklist de entrada', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            const SizedBox(height: 10),
            ..._checklist.map((Map<String, dynamic> item) {
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
                      border: Border.all(color: ok ? Colors.green.withOpacity(.30) : Theme.of(context).colorScheme.outlineVariant),
                      color: ok ? Colors.green.withOpacity(.08) : Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, color: ok ? Colors.green : Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(item['titulo'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _stepExecucao() {
    return _stepCard(
      '4. Execução, técnico e progresso operacional',
      'O técnico responsável deve ser um colaborador cadastrado ou o dono da conta.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(onPressed: _selecionarTecnico, icon: const Icon(Icons.person_pin_outlined), label: const Text('Selecionar técnico')),
                OutlinedButton.icon(onPressed: () => showSubPainelCadastroColaborador(context, 'Cadastro de Colaboradores'), icon: const Icon(Icons.group_add_outlined), label: const Text('Novo colaborador')),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: <Widget>[Expanded(child: _tf(_tecnicoController, 'Técnico responsável', Icons.person_pin_outlined)), const SizedBox(width: 14), Expanded(child: _dd('Status da OS', _statusSelecionado, _statusDisponiveis, (String? value) => setState(() => _statusSelecionado = value ?? _statusSelecionado)))]),
            const SizedBox(height: 18),
            Align(alignment: Alignment.centerLeft, child: Text('Tarefas da execução', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            const SizedBox(height: 10),
            ..._tarefas.map((Map<String, dynamic> item) {
              final bool ok = item['ok'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: ok ? Theme.of(context).colorScheme.primary.withOpacity(.08) : Theme.of(context).colorScheme.surface,
                    border: Border.all(color: ok ? Theme.of(context).colorScheme.primary.withOpacity(.40) : Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: <Widget>[
                      Checkbox(value: ok, onChanged: (bool? value) => setState(() => item['ok'] = value ?? false)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item['titulo'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: <Widget>[
                                _pill(item['responsavel'] as String, Icons.person_outline),
                                _pill(item['status'] as String, Icons.flag_outlined),
                                _pill(item['duracao'] as String, Icons.schedule_outlined),
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

  Widget _stepItens() {
    return _stepCard(
      '5. Itens, custos e aprovação do cliente',
      'A OS pode nascer de um orçamento aprovado ou diretamente do atendimento, mas a execução financeira e operacional acontece aqui.',
      Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FilledButton.icon(onPressed: _pickProduto, icon: const Icon(Icons.add_shopping_cart_outlined), label: const Text('Adicionar produto')),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _itens.add(<String, dynamic>{'tipo': 'servico', 'nome': 'Serviço adicional mock', 'detalhe': 'Serviço incluído manualmente na OS', 'quantidade': 1, 'valor': 120.0, 'selecionado': true});
                }),
                icon: const Icon(Icons.build_outlined),
                label: const Text('Adicionar serviço'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _itens.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, int index) {
                final Map<String, dynamic> item = _itens[index];
                final bool selected = item['selecionado'] == true;
                final int quantity = (item['quantidade'] ?? 1) as int;
                final double value = ((item['valor'] ?? 0) as num).toDouble();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.08) : Theme.of(context).colorScheme.surface,
                    border: Border.all(color: selected ? Theme.of(context).colorScheme.primary.withOpacity(.40) : Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: <Widget>[
                      Checkbox(value: selected, onChanged: (bool? value) => setState(() => item['selecionado'] = value ?? false)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item['nome'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 6),
                            Text(item['detalhe'] as String),
                          ],
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          IconButton(onPressed: () => setState(() { if (quantity > 1) item['quantidade'] = quantity - 1; }), icon: const Icon(Icons.remove_circle_outline)),
                          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
                          IconButton(onPressed: () => setState(() => item['quantidade'] = quantity + 1), icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 120, child: Text('R\$ ${(value * quantity).toStringAsFixed(2)}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
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
            children: <Widget>[
              SizedBox(
                width: 320,
                child: SwitchListTile(
                  value: _aprovou,
                  onChanged: (bool value) => setState(() => _aprovou = value),
                  title: const Text('Diagnóstico aprovado'),
                  subtitle: const Text('Cliente já aprovou a continuidade da execução.'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                ),
              ),
              SizedBox(
                width: 320,
                child: SwitchListTile(
                  value: _requerSinal,
                  onChanged: (bool value) => setState(() => _requerSinal = value),
                  title: const Text('Solicitar sinal'),
                  subtitle: const Text('Reserva de peça e início do serviço após pagamento parcial.'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardQr() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Resumo para o cliente', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('O cliente pode abrir este resumo no celular, revisar as informações da OS e assinar digitalmente neste fluxo mockado.'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 720;
              final Widget qr = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                child: Column(
                  children: <Widget>[
                    _FakeQrCode(data: _link(), size: 164),
                    const SizedBox(height: 10),
                    Text('QR do resumo da OS', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              );
              final Widget info = Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _rowInfo('Link', _link()),
                      _rowInfo('Cliente', _clienteController.text),
                      _rowInfo('Contato', _telefoneController.text),
                      _rowInfo('Status', _statusSelecionado),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.icon(onPressed: _copyLink, icon: const Icon(Icons.copy_outlined), label: const Text('Copiar link')),
                          OutlinedButton.icon(onPressed: () => _showInfo('Prévia do resumo do cliente', 'Neste fluxo mockado, este link abrirá uma página pública com resumo da OS e aceite digital.'), icon: const Icon(Icons.open_in_new_rounded), label: const Text('Pré-visualizar')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              if (compact) {
                return Column(children: <Widget>[qr, const SizedBox(height: 12), info]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[qr, const SizedBox(width: 14), info]);
            },
          ),
        ],
      ),
    );
  }

  Widget _cardSign() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Assinatura digital do cliente', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_assinou ? 'Assinatura coletada com sucesso neste mock. O fluxo já está pronto para futura persistência no backend.' : 'Ainda não foi coletada. Use o botão abaixo para abrir o quadro de assinatura do cliente.'),
          const SizedBox(height: 14),
          if (_assinou)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withOpacity(.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(.35))),
              child: Row(children: <Widget>[const Icon(Icons.verified_rounded, color: Colors.green), const SizedBox(width: 10), Expanded(child: Text('Assinatura realizada por ${_assinanteController.text.trim().isEmpty ? 'cliente' : _assinanteController.text.trim()} em ${_dt(_assinadoEm)}.', style: const TextStyle(fontWeight: FontWeight.w700)))]),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(onPressed: _signDialog, icon: Icon(_assinou ? Icons.edit_note_rounded : Icons.draw_rounded), label: Text(_assinou ? 'Refazer assinatura' : 'Coletar assinatura')),
              if (_assinou)
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _assinou = false;
                    _assinadoEm = null;
                    _pontos = <Offset?>[];
                  }),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover assinatura'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepEntrega() {
    return _stepCard(
      '6. Entrega, link, QR e assinatura digital',
      'A OS já nasce com fluxo público de acompanhamento preparado, enquanto o orçamento permanece como entidade separada.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[Expanded(child: _tf(_prazoController, 'Prazo estimado', Icons.schedule_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_garantiaController, 'Garantia', Icons.verified_outlined))]),
            const SizedBox(height: 18),
            Align(alignment: Alignment.centerLeft, child: Text('Canais de comunicação', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _canais.map((Map<String, dynamic> item) {
                final bool selected = item['selecionado'] == true;
                return FilterChip(
                  selected: selected,
                  avatar: Icon(item['icone'] as IconData, size: 18, color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary),
                  label: Text(item['titulo'] as String),
                  onSelected: (bool value) => setState(() => item['selecionado'] = value),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: <Widget>[
                SizedBox(
                  width: 320,
                  child: SwitchListTile(
                    value: _entrega,
                    onChanged: (bool value) => setState(() => _entrega = value),
                    title: const Text('Entrega em domicílio'),
                    subtitle: const Text('Preparar rota, taxa e confirmação de recebimento.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: SwitchListTile(
                    value: _autorizaContato,
                    onChanged: (bool value) => setState(() => _autorizaContato = value),
                    title: const Text('Autorizar contato automático'),
                    subtitle: const Text('Preparar futuras notificações por WhatsApp, e-mail e Telegram.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _cardQr(),
            const SizedBox(height: 18),
            _cardSign(),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 96, child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _valueRow(String title, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Text(title, style: TextStyle(fontSize: strong ? 16 : 14, fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
          const Spacer(),
          Text('R\$ ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: strong ? 18 : 14, fontWeight: strong ? FontWeight.w900 : FontWeight.w700, color: strong ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text(text, style: const TextStyle(fontWeight: FontWeight.w700))]),
    );
  }

  Widget _summary() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Resumo da OS', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _rowInfo('OS', _osController.text),
                    _rowInfo('Orçamento', _orcamentoOrigemController.text),
                    _rowInfo('Cliente', _clienteController.text),
                    _rowInfo('Equipamento', _equipamentoController.text),
                    _rowInfo('Status', _statusSelecionado),
                    _rowInfo('Técnico', _tecnicoController.text),
                    _rowInfo('Prazo', _prazoController.text),
                    _rowInfo('Assinatura', _assinou ? 'Coletada em ${_dt(_assinadoEm)}' : 'Pendente'),
                    const Divider(height: 28),
                    _summaryMetric('Checklist técnico', '${_okCheck()}/${_checklist.length}', Icons.fact_check_outlined),
                    const SizedBox(height: 12),
                    _summaryMetric('Tarefas concluídas', '${_okTarefas()}/${_tarefas.length}', Icons.task_alt_outlined),
                    const SizedBox(height: 16),
                    ..._itens.where((Map<String, dynamic> item) => item['selecionado'] == true).map((Map<String, dynamic> item) {
                      final int quantity = (item['quantidade'] ?? 1) as int;
                      final double value = ((item['valor'] ?? 0) as num).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text('${item['nome']} ($quantity x)', style: const TextStyle(fontWeight: FontWeight.w600))),
                            Text('R\$ ${(value * quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 26),
                    _valueRow('Qtd. itens', _qtd().toDouble()),
                    _valueRow('Subtotal', _total()),
                    _valueRow('Sinal sugerido', _sinalValor()),
                    _valueRow('Total', _total(), strong: true),
                    const SizedBox(height: 18),
                    FilledButton.icon(onPressed: _copyLink, icon: const Icon(Icons.link_rounded), label: const Text('Copiar link do cliente'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Row(
        children: <Widget>[
          CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.10), child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _history() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Linha do tempo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ..._timeline.map((Map<String, dynamic> item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.10), borderRadius: BorderRadius.circular(12)),
                    child: Icon(item['icone'] as IconData, size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item['titulo'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(item['descricao'] as String),
                        const SizedBox(height: 2),
                        Text(item['hora'] as String, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[theme.colorScheme.primary.withOpacity(.08), theme.colorScheme.surfaceContainerHighest.withOpacity(.65)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircleAvatar(radius: 24, backgroundColor: theme.colorScheme.primary, child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white)),
                  const SizedBox(width: 12),
                  Text('Fluxo de Ordem de Serviço', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              _pill('Etapa ${_step + 1}/${_steps.length}', Icons.view_carousel_outlined),
              _pill(_statusSelecionado, Icons.flag_outlined),
              _pill(_prioridadeSelecionada, Icons.bolt_outlined),
              if (_assinou) _pill('Assinada', Icons.verified_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Aqui a recomendação foi aplicada: orçamento e OS continuam separados, mas a OS já considera cliente cadastrado e técnico colaborador como peças centrais do fluxo.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _steps.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, int index) {
                final Map<String, dynamic> step = _steps[index];
                final bool selected = index == _step;
                final bool done = index < _step;
                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _go(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 248,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? theme.colorScheme.primary : done ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, width: selected ? 2 : 1),
                    ),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: selected ? Colors.white : done ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: selected ? theme.colorScheme.primary : done ? Colors.white : theme.colorScheme.onSurfaceVariant,
                          child: Icon(step['icone'] as IconData, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(step['titulo'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(color: selected ? Colors.white : theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(step['descricao'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: selected ? Colors.white.withOpacity(.90) : theme.colorScheme.onSurfaceVariant)),
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(onPressed: _confirmCancelAll, style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white), icon: const Icon(Icons.close_rounded), label: const Text('Cancelar tudo e voltar')),
              OutlinedButton.icon(onPressed: _copyLink, icon: const Icon(Icons.link_rounded), label: const Text('Copiar link do resumo')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () {
                  if (_step == 0) {
                    if (widget.embedded) {
                      widget.onBack?.call();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                    return;
                  }
                  _go(_step - 1);
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(_step == 0 ? 'Sair' : 'Voltar'),
              ),
              OutlinedButton.icon(onPressed: () => _showInfo('Salvar rascunho', 'Na próxima etapa você pode persistir a OS em backend sem concluir o fluxo.'), icon: const Icon(Icons.save_outlined), label: const Text('Salvar rascunho')),
              OutlinedButton.icon(onPressed: _confirmCancelAll, icon: const Icon(Icons.close_rounded), label: const Text('Cancelar tudo'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade200))),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('Etapa ${_step + 1} de ${_steps.length}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
              FilledButton.icon(
                onPressed: () {
                  if (_last) {
                    _showInfo('Fluxo concluído', _assinou ? 'A OS foi concluída com assinatura digital mockada.' : 'A OS foi concluída. Você ainda pode coletar a assinatura do cliente neste fluxo.');
                    return;
                  }
                  _go(_step + 1);
                },
                icon: Icon(_last ? Icons.check_circle_outline : Icons.arrow_forward),
                label: Text(_last ? 'Concluir' : 'Próxima etapa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<TopNavItemData> _navItems() {
    return <TopNavItemData>[
      TopNavItemData(
        title: 'Início',
        subItems: const <String>['Preferências do Sistema', 'Painel Administrativo'],
        onSelect: (String value) {
          if (value == 'Painel Administrativo') {
            showSubPainelConfiguracoes(context, 'Configurações');
          }
        },
      ),
      const TopNavItemData(title: 'Permitir', subItems: <String>['Gerenciar Permissões', 'Alterar Configurações']),
      TopNavItemData(
        title: 'Cadastros',
        subItems: const <String>['Clientes', 'Colaboradores', 'Produtos'],
        onSelect: (String value) {
          if (value == 'Clientes') {
            showSubPainelCadastroCliente(context, 'Cadastro de Clientes');
          }
          if (value == 'Colaboradores') {
            showSubPainelCadastroColaborador(context, 'Cadastro de Colaboradores');
          }
          if (value == 'Produtos') {
            showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
          }
        },
      ),
      const TopNavItemData(title: 'Relatórios', subItems: <String>['Vendas', 'Estoque', 'Financeiro']),
      const TopNavItemData(title: 'Executar', subItems: <String>['Processar Pagamentos', 'Fechar Caixa']),
      const TopNavItemData(title: 'Configurações', subItems: <String>['Sistema', 'Usuários']),
      const TopNavItemData(title: 'Ajuda', subItems: <String>['Suporte', 'Sobre']),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> pages = <Widget>[_stepAbertura(), _stepCliente(), _stepDiagnostico(), _stepExecucao(), _stepItens(), _stepEntrega()];

    final Widget body = Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (_, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 1250;
              return Column(
                children: <Widget>[
                  _header(theme),
                  const SizedBox(height: 18),
                  Expanded(
                    child: compact
                        ? Column(
                      children: <Widget>[
                        Expanded(
                          child: PageView(controller: _pageController, onPageChanged: (int index) => setState(() => _step = index), children: pages),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 340,
                          child: Row(children: <Widget>[Expanded(child: _summary()), const SizedBox(width: 14), Expanded(child: SingleChildScrollView(child: _history()))]),
                        ),
                      ],
                    )
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(child: PageView(controller: _pageController, onPageChanged: (int index) => setState(() => _step = index), children: pages)),
                        const SizedBox(width: 18),
                        SizedBox(
                          width: 390,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(child: _summary()),
                              const SizedBox(height: 14),
                              Flexible(child: SingleChildScrollView(child: _history())),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _navBar(),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return Container(color: theme.colorScheme.surfaceContainerLowest, child: body);
    }

    return Scaffold(appBar: TopNavigationBar(items: _navItems(), onNotificationPressed: () {}), body: body);
  }
}

class _FakeQrCode extends StatelessWidget {
  const _FakeQrCode({required this.data, this.size = 160});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    const int dimension = 21;
    final int seed = data.codeUnits.fold<int>(0, (int a, int b) => a + b);

    bool finder(int row, int col) {
      const List<List<int>> patterns = <List<int>>[
        <int>[0, 0],
        <int>[0, 14],
        <int>[14, 0],
      ];
      for (final List<int> point in patterns) {
        if (row >= point[0] && row < point[0] + 7 && col >= point[1] && col < point[1] + 7) {
          final int localRow = row - point[0];
          final int localCol = col - point[1];
          return localRow == 0 || localRow == 6 || localCol == 0 || localCol == 6 || (localRow >= 2 && localRow <= 4 && localCol >= 2 && localCol <= 4);
        }
      }
      return false;
    }

    bool black(int row, int col) {
      if (finder(row, col)) {
        return true;
      }
      final int value = (row * 31 + col * 17 + seed) % 7;
      return value == 0 || value == 2 || value == 5;
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(
        children: List<Widget>.generate(
          dimension,
              (int row) => Expanded(
            child: Row(
              children: List<Widget>.generate(
                dimension,
                    (int col) => Expanded(child: Container(color: black(row, col) ? Colors.black : Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePad extends StatelessWidget {
  const _SignaturePad({required this.points, required this.onChanged});

  final List<Offset?> points;
  final ValueChanged<List<Offset?>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onPanStart: (DragStartDetails details) => onChanged(<Offset?>[...points, details.localPosition]),
          onPanUpdate: (DragUpdateDetails details) => onChanged(<Offset?>[...points, details.localPosition]),
          onPanEnd: (_) => onChanged(<Offset?>[...points, null]),
          child: CustomPaint(
            painter: _SignaturePainter(points: points),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.points});

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (int index = 0; index < points.length - 1; index++) {
      final Offset? a = points[index];
      final Offset? b = points[index + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => oldDelegate.points != points;
}
