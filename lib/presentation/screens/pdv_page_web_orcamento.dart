import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/sub_painel_cadastro_cliente.dart';
import 'package:appplanilha/sub_painel_cadastro_colaborador.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:flutter/material.dart';

import '../../data/models/produto_model.dart';
import '../../mock_cadastros_store.dart';
import '../../top_navigation_bar.dart';

class OrcamentoWeb extends StatefulWidget {
  const OrcamentoWeb({super.key});

  @override
  State<OrcamentoWeb> createState() => _OrcamentoWebState();
}

class _OrcamentoWebState extends State<OrcamentoWeb> {
  final PageController _pageController = PageController();

  final TextEditingController _numeroController = TextEditingController(text: 'ORC-2026-00127');
  final TextEditingController _clienteNomeController = TextEditingController(text: 'Marina Oliveira');
  final TextEditingController _clienteTelefoneController = TextEditingController(text: '(47) 99999-0001');
  final TextEditingController _clienteEmailController = TextEditingController(text: 'marina.oliveira@email.com');
  final TextEditingController _clienteDocumentoController = TextEditingController(text: '123.456.789-00');
  final TextEditingController _responsavelComercialController = TextEditingController(text: 'Juliana Rocha');
  final TextEditingController _equipamentoController = TextEditingController(text: 'iPhone 13 128GB');
  final TextEditingController _marcaController = TextEditingController(text: 'Apple');
  final TextEditingController _modeloController = TextEditingController(text: 'A2633');
  final TextEditingController _serialController = TextEditingController(text: 'SN-IP13-009988');
  final TextEditingController _acessoriosController = TextEditingController(text: 'Capa, película e cabo USB-C');
  final TextEditingController _defeitoController = TextEditingController(
    text: 'Tela sem imagem após queda. Cliente relata vibração normal e sons de notificações.',
  );
  final TextEditingController _observacoesTecnicasController = TextEditingController(
    text: 'Estrutura preservada. Indício de dano no display. Recomenda-se teste de tela e revisão do conector.',
  );
  final TextEditingController _prazoController = TextEditingController(text: '2 dias úteis');
  final TextEditingController _garantiaController = TextEditingController(text: '90 dias para peças e serviço');
  final TextEditingController _observacoesFinaisController = TextEditingController(
    text: 'Mock local pronto para futura integração com backend e conversão em OS.',
  );

  final List<Map<String, dynamic>> _checklist = <Map<String, dynamic>>[
    <String, dynamic>{'titulo': 'Liga normalmente', 'descricao': 'Equipamento energiza e apresenta sinais básicos de vida.', 'ok': true},
    <String, dynamic>{'titulo': 'Tela apresenta imagem', 'descricao': 'Display principal está funcional.', 'ok': false},
    <String, dynamic>{'titulo': 'Touch responde', 'descricao': 'Touchscreen responde corretamente.', 'ok': false},
    <String, dynamic>{'titulo': 'Carregamento funcional', 'descricao': 'Conector e bateria respondem no teste inicial.', 'ok': true},
  ];

  final List<Map<String, dynamic>> _itens = <Map<String, dynamic>>[
    <String, dynamic>{'tipo': 'servico', 'nome': 'Troca de display OLED premium', 'detalhe': 'Mão de obra técnica especializada', 'quantidade': 1, 'valor': 790.0, 'selecionado': true},
    <String, dynamic>{'tipo': 'servico', 'nome': 'Revisão interna e testes funcionais', 'detalhe': 'Checklist completo de entrega', 'quantidade': 1, 'valor': 90.0, 'selecionado': true},
    <String, dynamic>{'tipo': 'produto', 'nome': 'Película de proteção 3D', 'detalhe': 'Opcional sugerido', 'quantidade': 1, 'valor': 49.9, 'selecionado': false},
  ];

  final List<Map<String, dynamic>> _canais = <Map<String, dynamic>>[
    <String, dynamic>{'titulo': 'WhatsApp', 'icone': Icons.chat, 'selecionado': true},
    <String, dynamic>{'titulo': 'E-mail', 'icone': Icons.email_outlined, 'selecionado': true},
    <String, dynamic>{'titulo': 'Telegram', 'icone': Icons.send, 'selecionado': false},
    <String, dynamic>{'titulo': 'SMS', 'icone': Icons.sms_outlined, 'selecionado': false},
  ];

  final List<String> _statusDisponiveis = <String>['Rascunho', 'Enviado', 'Em negociação', 'Aprovado', 'Reprovado', 'Expirado', 'Cancelado'];
  final List<String> _prioridades = <String>['Baixa', 'Normal', 'Alta', 'Urgente'];
  final List<String> _origens = <String>['Balcão', 'WhatsApp', 'Instagram', 'Site', 'Marketplace'];

  String _statusSelecionado = 'Rascunho';
  String _prioridadeSelecionada = 'Alta';
  String _origemSelecionada = 'WhatsApp';
  bool _requerSinal = true;
  bool _autorizaContato = true;
  bool _equipamentoReserva = false;
  int _step = 0;

  List<Map<String, dynamic>> get _steps => const <Map<String, dynamic>>[
    <String, dynamic>{'titulo': 'Cliente', 'descricao': 'Quem solicita e contexto comercial', 'icone': Icons.person_outline},
    <String, dynamic>{'titulo': 'Equipamento', 'descricao': 'Entrada, identificação e acessórios', 'icone': Icons.devices_other_outlined},
    <String, dynamic>{'titulo': 'Diagnóstico', 'descricao': 'Defeito e checklist técnico', 'icone': Icons.medical_information_outlined},
    <String, dynamic>{'titulo': 'Itens', 'descricao': 'Serviços, peças e opcionais', 'icone': Icons.inventory_2_outlined},
    <String, dynamic>{'titulo': 'Condições', 'descricao': 'Prazo, canais e conversão futura em OS', 'icone': Icons.verified_outlined},
  ];

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _numeroController,
      _clienteNomeController,
      _clienteTelefoneController,
      _clienteEmailController,
      _clienteDocumentoController,
      _responsavelComercialController,
      _equipamentoController,
      _marcaController,
      _modeloController,
      _serialController,
      _acessoriosController,
      _defeitoController,
      _observacoesTecnicasController,
      _prazoController,
      _garantiaController,
      _observacoesFinaisController,
    ]) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _irParaEtapa(int index) {
    setState(() => _step = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  double _totalSelecionado() {
    return _itens.where((Map<String, dynamic> item) => item['selecionado'] == true).fold<double>(
      0,
          (double total, Map<String, dynamic> item) => total + (((item['valor'] ?? 0) as num).toDouble() * ((item['quantidade'] ?? 1) as int)),
    );
  }

  double _sinalSugerido() => _requerSinal ? _totalSelecionado() * 0.30 : 0;

  Future<void> _selecionarCliente() async {
    final ClienteMock? cliente = await showSelecaoClienteDialog(context);
    if (cliente == null) {
      return;
    }
    setState(() {
      _clienteNomeController.text = cliente.nome;
      _clienteTelefoneController.text = cliente.telefone;
      _clienteEmailController.text = cliente.email;
      _clienteDocumentoController.text = cliente.documento;
      _observacoesFinaisController.text = cliente.observacoes;
    });
  }

  Future<void> _selecionarResponsavel() async {
    final ColaboradorMock? colaborador = await showSelecaoColaboradorDialog(
      context,
      titulo: 'Selecionar responsável comercial',
    );
    if (colaborador == null) {
      return;
    }
    setState(() {
      _responsavelComercialController.text = colaborador.nome;
    });
  }

  Future<void> _abrirSelecaoProdutoWeb() async {
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
        'detalhe': 'Produto adicionado manualmente ao orçamento',
        'quantidade': 1,
        'valor': (result.precoVenda as num).toDouble(),
        'selecionado': true,
      });
    });
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Fechar')),
          ],
        );
      },
    );
  }

  Widget _buildCardEtapa(String titulo, String subtitulo, Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(subtitulo, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Expanded(child: SizedBox(width: double.infinity, child: child)),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _stepCliente() {
    return _buildCardEtapa(
      '1. Cliente e contexto do orçamento',
      'Mantenha orçamento e ordem de serviço separados, mas desde agora com vínculo claro com cliente e responsável comercial.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(onPressed: _selecionarCliente, icon: const Icon(Icons.person_search_outlined), label: const Text('Selecionar cliente cadastrado')),
                OutlinedButton.icon(onPressed: () => showSubPainelCadastroCliente(context, 'Cadastro de Clientes'), icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('Novo cliente')),
                OutlinedButton.icon(onPressed: _selecionarResponsavel, icon: const Icon(Icons.badge_outlined), label: const Text('Selecionar responsável comercial')),
                OutlinedButton.icon(onPressed: () => showSubPainelCadastroColaborador(context, 'Cadastro de Colaboradores'), icon: const Icon(Icons.group_add_outlined), label: const Text('Novo colaborador')),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: <Widget>[Expanded(child: _tf(_numeroController, 'Número do orçamento', Icons.tag_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_responsavelComercialController, 'Responsável comercial', Icons.person_pin_outlined))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[Expanded(child: _tf(_clienteNomeController, 'Nome do cliente', Icons.person_outline)), const SizedBox(width: 14), Expanded(child: _tf(_clienteDocumentoController, 'CPF / Documento', Icons.badge_outlined))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[Expanded(child: _tf(_clienteTelefoneController, 'Telefone / WhatsApp', Icons.phone_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_clienteEmailController, 'E-mail', Icons.email_outlined))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _origemSelecionada,
                  decoration: InputDecoration(labelText: 'Origem', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: _origens.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                  onChanged: (String? value) => setState(() => _origemSelecionada = value ?? _origemSelecionada),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _prioridadeSelecionada,
                  decoration: InputDecoration(labelText: 'Prioridade', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: _prioridades.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                  onChanged: (String? value) => setState(() => _prioridadeSelecionada = value ?? _prioridadeSelecionada),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stepEquipamento() {
    return _buildCardEtapa(
      '2. Equipamento recebido',
      'A proposta comercial pode nascer antes da OS, mas já deve registrar o equipamento com qualidade.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[Expanded(child: _tf(_equipamentoController, 'Descrição do equipamento', Icons.devices_other_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_serialController, 'Serial / IMEI / Patrimônio', Icons.confirmation_number_outlined))]),
            const SizedBox(height: 14),
            Row(children: <Widget>[Expanded(child: _tf(_marcaController, 'Marca', Icons.business_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_modeloController, 'Modelo / Versão', Icons.category_outlined))]),
            const SizedBox(height: 14),
            _tf(_acessoriosController, 'Acessórios entregues', Icons.cable_outlined),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: <Widget>[
                SizedBox(
                  width: 320,
                  child: SwitchListTile(
                    value: _equipamentoReserva,
                    onChanged: (bool value) => setState(() => _equipamentoReserva = value),
                    title: const Text('Equipamento reserva'),
                    subtitle: const Text('Separar unidade reserva enquanto a análise estiver em andamento.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: SwitchListTile(
                    value: _autorizaContato,
                    onChanged: (bool value) => setState(() => _autorizaContato = value),
                    title: const Text('Autoriza contato automático'),
                    subtitle: const Text('Preparar futuras automações por WhatsApp, e-mail e Telegram.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDiagnostico() {
    return _buildCardEtapa(
      '3. Diagnóstico técnico inicial',
      'Aqui o orçamento permanece proposta comercial, mas já nasce tecnicamente consistente.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _tf(_defeitoController, 'Defeito relatado pelo cliente', Icons.report_problem_outlined, maxLines: 4),
            const SizedBox(height: 14),
            _tf(_observacoesTecnicasController, 'Observações técnicas iniciais', Icons.engineering_outlined, maxLines: 4),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Checklist de entrada', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
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
                      border: Border.all(color: ok ? Colors.green.withOpacity(0.30) : Theme.of(context).colorScheme.outlineVariant),
                      color: ok ? Colors.green.withOpacity(0.08) : Theme.of(context).colorScheme.surface,
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

  Widget _stepItens() {
    return _buildCardEtapa(
      '4. Composição do orçamento',
      'Serviços e produtos permanecem no orçamento até aprovação, sem virar execução operacional ainda.',
      Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FilledButton.icon(onPressed: _abrirSelecaoProdutoWeb, icon: const Icon(Icons.add_shopping_cart_outlined), label: const Text('Adicionar produto')),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _itens.add(<String, dynamic>{'tipo': 'servico', 'nome': 'Serviço adicional mock', 'detalhe': 'Serviço incluído manualmente', 'quantidade': 1, 'valor': 120.0, 'selecionado': true});
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
                final bool selecionado = item['selecionado'] == true;
                final int quantidade = (item['quantidade'] ?? 1) as int;
                final double valor = ((item['valor'] ?? 0) as num).toDouble();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: selecionado ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Theme.of(context).colorScheme.surface,
                    border: Border.all(color: selecionado ? Theme.of(context).colorScheme.primary.withOpacity(0.40) : Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: <Widget>[
                      Checkbox(value: selecionado, onChanged: (bool? value) => setState(() => item['selecionado'] = value ?? false)),
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
                          IconButton(onPressed: () => setState(() { if (quantidade > 1) item['quantidade'] = quantidade - 1; }), icon: const Icon(Icons.remove_circle_outline)),
                          Text('$quantidade', style: const TextStyle(fontWeight: FontWeight.w700)),
                          IconButton(onPressed: () => setState(() => item['quantidade'] = quantidade + 1), icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 120, child: Text('R\$ ${(valor * quantidade).toStringAsFixed(2)}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
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

  Widget _stepCondicoes() {
    return _buildCardEtapa(
      '5. Condições e fechamento comercial',
      'Última etapa do orçamento antes de compartilhar e, futuramente, converter em ordem de serviço.',
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[Expanded(child: _tf(_prazoController, 'Prazo estimado', Icons.schedule_outlined)), const SizedBox(width: 14), Expanded(child: _tf(_garantiaController, 'Garantia', Icons.verified_outlined))]),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _statusSelecionado,
              decoration: InputDecoration(labelText: 'Status do orçamento', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              items: _statusDisponiveis.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
              onChanged: (String? value) => setState(() => _statusSelecionado = value ?? _statusSelecionado),
            ),
            const SizedBox(height: 14),
            _tf(_observacoesFinaisController, 'Observações finais', Icons.note_alt_outlined, maxLines: 4),
            const SizedBox(height: 18),
            Align(alignment: Alignment.centerLeft, child: Text('Canais de aprovação e comunicação', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _canais.map((Map<String, dynamic> canal) {
                final bool selecionado = canal['selecionado'] == true;
                return FilterChip(
                  selected: selecionado,
                  avatar: Icon(canal['icone'] as IconData, size: 18, color: selecionado ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary),
                  label: Text(canal['titulo'] as String),
                  onSelected: (bool value) => setState(() => canal['selecionado'] = value),
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
                    value: _requerSinal,
                    onChanged: (bool value) => setState(() => _requerSinal = value),
                    title: const Text('Solicitar sinal'),
                    subtitle: const Text('Reserva da peça e início do serviço após pagamento parcial.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: SwitchListTile(
                    value: _autorizaContato,
                    onChanged: (bool value) => setState(() => _autorizaContato = value),
                    title: const Text('Autorizar contato automático'),
                    subtitle: const Text('Mantém o orçamento pronto para futura automação multicanal.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumo() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Resumo do orçamento', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _infoRow('Número', _numeroController.text),
                    _infoRow('Cliente', _clienteNomeController.text),
                    _infoRow('Responsável', _responsavelComercialController.text),
                    _infoRow('Equipamento', _equipamentoController.text),
                    _infoRow('Status', _statusSelecionado),
                    const Divider(height: 26),
                    ..._itens.where((Map<String, dynamic> item) => item['selecionado'] == true).map((Map<String, dynamic> item) {
                      final int quantidade = (item['quantidade'] ?? 1) as int;
                      final double valor = ((item['valor'] ?? 0) as num).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text('${item['nome']} ($quantidade x)', style: const TextStyle(fontWeight: FontWeight.w600))),
                            Text('R\$ ${(valor * quantidade).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 26),
                    _valueRow('Subtotal', _totalSelecionado()),
                    _valueRow('Sinal sugerido', _sinalSugerido()),
                    _valueRow('Total', _totalSelecionado(), strong: true),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _showInfo('Orçamento pronto', 'Fluxo mock concluído. Na próxima etapa você pode conectar persistência, PDF, link público e conversão para OS.'),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Gerar PDF / compartilhar'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showInfo('Converter em OS', 'O desenho já foi preparado para manter orçamento e ordem de serviço separados, com conversão futura a partir do backend.'),
                      icon: const Icon(Icons.assignment_turned_in_outlined),
                      label: const Text('Preparar conversão em OS'),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _valueRow(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: strong ? 16 : 14, fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
          const Spacer(),
          Text('R\$ ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: strong ? 18 : 14, fontWeight: strong ? FontWeight.w900 : FontWeight.w700, color: strong ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _header() {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[theme.colorScheme.primary.withOpacity(0.08), theme.colorScheme.surfaceContainerHighest.withOpacity(0.65)]),
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
                  CircleAvatar(radius: 24, backgroundColor: theme.colorScheme.primary, child: const Icon(Icons.request_quote, color: Colors.white)),
                  const SizedBox(width: 12),
                  Text('Fluxo de Orçamento', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              _badge('Etapa ${_step + 1}/${_steps.length}', Icons.view_carousel_outlined),
              _badge(_statusSelecionado, Icons.flag_outlined),
              _badge(_prioridadeSelecionada, Icons.bolt_outlined),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Esta versão mantém orçamento e ordem de serviço separados no domínio, como recomendado. Também já considera cliente cadastrado e responsável comercial colaborador.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 92,
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
                  onTap: () => _irParaEtapa(index),
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
                              Text(step['descricao'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: selected ? Colors.white.withOpacity(0.90) : theme.colorScheme.onSurfaceVariant)),
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
    );
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text(text, style: const TextStyle(fontWeight: FontWeight.w700))]),
    );
  }

  Widget _navBar() {
    final bool last = _step == _steps.length - 1;
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
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () {
                  if (_step == 0) {
                    Navigator.of(context).maybePop();
                    return;
                  }
                  _irParaEtapa(_step - 1);
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(_step == 0 ? 'Sair' : 'Voltar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showInfo('Cancelar orçamento', 'O orçamento pode ser cancelado sem contaminar a OS, reforçando a separação de domínio recomendada.'),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('Etapa ${_step + 1} de ${_steps.length}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
              FilledButton.icon(
                onPressed: () {
                  if (last) {
                    _showInfo('Orçamento concluído', 'Fluxo mock finalizado com cliente e colaborador integrados ao processo.');
                    return;
                  }
                  _irParaEtapa(_step + 1);
                },
                icon: Icon(last ? Icons.check_circle_outline : Icons.arrow_forward),
                label: Text(last ? 'Concluir' : 'Próxima etapa'),
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
        subItems: const <String>['Clientes', 'Colaboradores', 'Produtos', 'Produtos List'],
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
          if (value == 'Produtos List') {
            _abrirSelecaoProdutoWeb();
          }
        },
      ),
      const TopNavItemData(title: 'Relatórios', subItems: <String>['Vendas', 'Estoque', 'Financeiro']),
      const TopNavItemData(title: 'Executar', subItems: <String>['Processar Pagamentos', 'Fechar Caixa']),
      const TopNavItemData(title: 'Configurações', subItems: <String>['Sistema', 'Usuários']),
      const TopNavItemData(title: 'Automações', subItems: <String>['Tarefas Agendadas']),
      const TopNavItemData(title: 'Ajuda', subItems: <String>['Suporte', 'Sobre']),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[_stepCliente(), _stepEquipamento(), _stepDiagnostico(), _stepItens(), _stepCondicoes()];

    return Scaffold(
      appBar: TopNavigationBar(items: _navItems(), onNotificationPressed: () {}),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                _header(),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (int index) => setState(() => _step = index),
                          children: pages,
                        ),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(width: 380, child: _resumo()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _navBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
