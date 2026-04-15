import 'package:flutter/material.dart';

import '../../data/models/cliente_usuario_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';

class ClientesUsuarioListPage extends StatefulWidget {
  const ClientesUsuarioListPage({
    super.key,
    this.embedded = false,
    this.onBack,
    this.apiClient,
  });

  final bool embedded;
  final VoidCallback? onBack;
  final ClienteUsuarioApiClient? apiClient;

  @override
  State<ClientesUsuarioListPage> createState() =>
      _ClientesUsuarioListPageState();
}

class _ClientesUsuarioListPageState extends State<ClientesUsuarioListPage> {
  late final ClienteUsuarioApiClient _apiClient;
  final TextEditingController _buscaController = TextEditingController();

  bool _isLoading = false;
  String? _erro;
  ClienteUsuarioListResponse? _response;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? HttpClienteUsuarioApiClient();
    _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final response = await _apiClient.listarClientesUsuario();
      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } on ClienteUsuarioApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _erro = _mensagemErroPorStatus(e.statusCode);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _erro = 'Não foi possível carregar a lista de clientes.';
      });
    }
  }

  String _mensagemErroPorStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requisição inválida: header idUnicoDaEmpresa ausente ou inválido.';
      case 401:
        return 'Não autenticado: faça login novamente.';
      case 403:
        return 'Acesso negado: usuário sem vínculo com a empresa.';
      default:
        return 'Erro ao carregar clientes (HTTP $statusCode).';
    }
  }

  List<ClienteUsuario> _clientesFiltrados() {
    final List<ClienteUsuario> clientes =
        _response?.clientes ?? const <ClienteUsuario>[];
    if (_filtro.trim().isEmpty) {
      return clientes;
    }

    final String termo = _normalizar(_filtro);
    return clientes
        .where((ClienteUsuario cliente) {
          final String nome = _normalizar(cliente.nome);
          final String documento = _normalizar(cliente.documento);
          return nome.contains(termo) || documento.contains(termo);
        })
        .toList(growable: false);
  }

  String _normalizar(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return '-';
    }

    final DateTime local = data.toLocal();
    final String dia = local.day.toString().padLeft(2, '0');
    final String mes = local.month.toString().padLeft(2, '0');
    final String ano = local.year.toString();
    final String hora = local.hour.toString().padLeft(2, '0');
    final String minuto = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano $hora:$minuto';
  }

  String _formatarDataCurta(DateTime data) {
    final DateTime local = data.toLocal();
    final String dia = local.day.toString().padLeft(2, '0');
    final String mes = local.month.toString().padLeft(2, '0');
    final String ano = local.year.toString();
    return '$dia/$mes/$ano';
  }

  String _formatarMoeda(double value) {
    final String comDuasCasas = value.toStringAsFixed(2);
    final List<String> partes = comDuasCasas.split('.');
    String inteiro = partes.first;
    final String centavos = partes.last;
    final RegExp regExp = RegExp(r'(\d+)(\d{3})');

    while (regExp.hasMatch(inteiro)) {
      inteiro = inteiro.replaceAllMapped(regExp, (Match match) {
        return '${match.group(1)}.${match.group(2)}';
      });
    }

    return 'R\$ $inteiro,$centavos';
  }

  String _ultimoTrechoId(String id) {
    final String normalized = id.trim();
    if (normalized.isEmpty) {
      return '0000';
    }

    if (normalized.length <= 4) {
      return normalized.toUpperCase().padLeft(4, '0');
    }

    return normalized.substring(normalized.length - 4).toUpperCase();
  }

  List<_CompraMock> _montarComprasMock(ClienteUsuario cliente) {
    final DateTime now = DateTime.now();
    final DateTime base =
        cliente.criadoEm?.toLocal() ?? now.subtract(const Duration(days: 240));
    final double fator =
        (cliente.nome.length + cliente.documento.length + 35).toDouble();

    return <_CompraMock>[
      _CompraMock(
        descricao: 'Pedido PDV #${_ultimoTrechoId(cliente.id)}-01',
        data: base.add(const Duration(days: 18)),
        formaPagamento: 'Pix',
        valor: fator * 2.2,
      ),
      _CompraMock(
        descricao: 'Orçamento convertido #${_ultimoTrechoId(cliente.id)}-02',
        data: now.subtract(const Duration(days: 74)),
        formaPagamento: 'Cartão de crédito',
        valor: fator * 3.4,
      ),
      _CompraMock(
        descricao: 'Compra balcão #${_ultimoTrechoId(cliente.id)}-03',
        data: now.subtract(const Duration(days: 27)),
        formaPagamento: 'Dinheiro',
        valor: fator * 1.8,
      ),
      _CompraMock(
        descricao: 'Serviço avulso #${_ultimoTrechoId(cliente.id)}-04',
        data: now.subtract(const Duration(days: 5)),
        formaPagamento: 'Boleto',
        valor: fator * 1.3,
      ),
    ];
  }

  List<_DividaMock> _montarDividasMock(ClienteUsuario cliente) {
    final DateTime now = DateTime.now();
    final double fator =
        (cliente.nome.length + cliente.documento.length + 25).toDouble();

    final List<_DividaMock> dividas = <_DividaMock>[
      _DividaMock(
        descricao: 'Parcela crediário #${_ultimoTrechoId(cliente.id)}-A',
        vencimento: now.subtract(const Duration(days: 9)),
        valor: fator * 1.5,
        status: 'Atrasada',
      ),
      _DividaMock(
        descricao: 'Parcela crediário #${_ultimoTrechoId(cliente.id)}-B',
        vencimento: now.add(const Duration(days: 12)),
        valor: fator * 1.2,
        status: 'Em aberto',
      ),
    ];

    if (cliente.ativo) {
      dividas.add(
        _DividaMock(
          descricao: 'Acordo de pagamento #${_ultimoTrechoId(cliente.id)}-C',
          vencimento: now.add(const Duration(days: 32)),
          valor: fator * 0.9,
          status: 'Em aberto',
        ),
      );
    }

    return dividas;
  }

  List<_OrdemServicoMock> _montarOrdensServicoMock(ClienteUsuario cliente) {
    final DateTime now = DateTime.now();

    final List<_OrdemServicoMock> ordens = <_OrdemServicoMock>[
      _OrdemServicoMock(
        numero: 'OS-${_ultimoTrechoId(cliente.id)}-11',
        descricao: 'Troca de tela',
        dataAbertura: now.subtract(const Duration(days: 93)),
        dataFechamento: now.subtract(const Duration(days: 88)),
        status: 'Concluída',
      ),
      _OrdemServicoMock(
        numero: 'OS-${_ultimoTrechoId(cliente.id)}-12',
        descricao: 'Revisão geral do equipamento',
        dataAbertura: now.subtract(const Duration(days: 35)),
        dataFechamento: now.subtract(const Duration(days: 30)),
        status: 'Concluída',
      ),
    ];

    if (cliente.ativo) {
      ordens.add(
        _OrdemServicoMock(
          numero: 'OS-${_ultimoTrechoId(cliente.id)}-13',
          descricao: 'Diagnóstico avançado',
          dataAbertura: now.subtract(const Duration(days: 3)),
          dataFechamento: null,
          status: 'Aberta',
        ),
      );
    }

    return ordens;
  }

  void _atualizarClienteNaLista(ClienteUsuario atualizado) {
    final ClienteUsuarioListResponse? responseAtual = _response;
    if (responseAtual == null) {
      return;
    }

    final List<ClienteUsuario> novaLista = responseAtual.clientes
        .map(
          (ClienteUsuario cliente) =>
              cliente.id == atualizado.id ? atualizado : cliente,
        )
        .toList(growable: false);

    setState(() {
      _response = ClienteUsuarioListResponse(
        idUnicoDaEmpresa: responseAtual.idUnicoDaEmpresa,
        total: responseAtual.total,
        clientes: novaLista,
      );
    });
  }

  Future<void> _abrirEdicaoCliente(ClienteUsuario cliente) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nomeController = TextEditingController(
      text: cliente.nome,
    );
    final TextEditingController documentoController = TextEditingController(
      text: cliente.documento,
    );
    final TextEditingController emailController = TextEditingController(
      text: cliente.email,
    );
    final TextEditingController telefoneController = TextEditingController(
      text: cliente.telefone,
    );
    bool ativo = cliente.ativo;

    try {
      final ClienteUsuario?
      clienteAtualizado = await showDialog<ClienteUsuario>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext builderContext,
              void Function(void Function()) setDialogState,
            ) {
              return AlertDialog(
                title: Text('Editar cliente: ${cliente.nome}'),
                content: SizedBox(
                  width: 520,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            controller: nomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              border: OutlineInputBorder(),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o nome do cliente.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: documentoController,
                            decoration: const InputDecoration(
                              labelText: 'Documento',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: telefoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: ativo,
                            title: const Text('Cliente ativo'),
                            onChanged: (bool value) {
                              setDialogState(() {
                                ativo = value;
                              });
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fluxo inicial mockado: alterações salvas apenas localmente nesta listagem.',
                            style: Theme.of(builderContext).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }

                      Navigator.of(dialogContext).pop(
                        ClienteUsuario(
                          id: cliente.id,
                          idUsuario: cliente.idUsuario,
                          idUnicoDaEmpresa: cliente.idUnicoDaEmpresa,
                          ativo: ativo,
                          tipoPessoa: cliente.tipoPessoa,
                          documento: documentoController.text.trim(),
                          nome: nomeController.text.trim(),
                          telefone: telefoneController.text.trim(),
                          email: emailController.text.trim(),
                          observacoes: cliente.observacoes,
                          origemAutoCadastro: cliente.origemAutoCadastro,
                          enviadoEm: cliente.enviadoEm,
                          criadoEm: cliente.criadoEm,
                          atualizadoEm: DateTime.now(),
                          foto: cliente.foto,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || clienteAtualizado == null) {
        return;
      }

      _atualizarClienteNaLista(clienteAtualizado);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente atualizado com sucesso (mock local).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      nomeController.dispose();
      documentoController.dispose();
      emailController.dispose();
      telefoneController.dispose();
    }
  }

  Future<void> _abrirHistoricoCliente(ClienteUsuario cliente) async {
    final List<_CompraMock> compras = _montarComprasMock(cliente);
    final List<_DividaMock> dividas = _montarDividasMock(cliente);
    final List<_OrdemServicoMock> ordensServico = _montarOrdensServicoMock(
      cliente,
    );
    final List<_OrdemServicoMock> ordensAbertas = ordensServico
        .where((ordem) => ordem.status == 'Aberta')
        .toList(growable: false);

    final double totalCompras = compras.fold<double>(
      0,
      (double total, _CompraMock item) => total + item.valor,
    );
    final double totalDividasEmAberto = dividas
        .where((item) => item.status != 'Paga')
        .fold<double>(
          0,
          (double total, _DividaMock item) => total + item.valor,
        );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 1080,
            height: 680,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Histórico de ${cliente.nome}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            border: Border.all(color: Colors.amber.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: <Widget>[
                              Icon(Icons.info_outline, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Dados mockados para o desenho inicial. A API de histórico ainda não está ativa.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            _ResumoHistoricoCard(
                              titulo: 'Compras registradas',
                              valor: '${compras.length}',
                              subtitulo: _formatarMoeda(totalCompras),
                              icone: Icons.shopping_bag_outlined,
                            ),
                            _ResumoHistoricoCard(
                              titulo: 'Dívidas em aberto',
                              valor: '${dividas.length}',
                              subtitulo: _formatarMoeda(totalDividasEmAberto),
                              icone: Icons.account_balance_wallet_outlined,
                            ),
                            _ResumoHistoricoCard(
                              titulo: 'OS abertas',
                              valor: '${ordensAbertas.length}',
                              subtitulo:
                                  ordensAbertas.isEmpty
                                      ? 'Sem pendências'
                                      : 'Necessita acompanhamento',
                              icone: Icons.build_circle_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Histórico de compras',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: compras
                                .map(
                                  (_CompraMock item) => ListTile(
                                    leading: const Icon(Icons.point_of_sale),
                                    title: Text(item.descricao),
                                    subtitle: Text(
                                      '${_formatarDataCurta(item.data)} • ${item.formaPagamento}',
                                    ),
                                    trailing: Text(
                                      _formatarMoeda(item.valor),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Dívidas / crediário',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: dividas
                                .map(
                                  (_DividaMock item) => ListTile(
                                    leading: Icon(
                                      item.status == 'Atrasada'
                                          ? Icons.warning_amber_rounded
                                          : Icons.receipt_long_outlined,
                                      color:
                                          item.status == 'Atrasada'
                                              ? Colors.red.shade500
                                              : null,
                                    ),
                                    title: Text(item.descricao),
                                    subtitle: Text(
                                      'Vencimento: ${_formatarDataCurta(item.vencimento)} • ${item.status}',
                                    ),
                                    trailing: Text(
                                      _formatarMoeda(item.valor),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Histórico de ordens de serviço',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: ordensServico
                                .map(
                                  (_OrdemServicoMock item) => ListTile(
                                    leading: Icon(
                                      item.status == 'Aberta'
                                          ? Icons.work_history_outlined
                                          : Icons.check_circle_outline,
                                      color:
                                          item.status == 'Aberta'
                                              ? Colors.orange.shade700
                                              : Colors.green.shade600,
                                    ),
                                    title: Text(
                                      '${item.numero} • ${item.descricao}',
                                    ),
                                    subtitle: Text(
                                      item.dataFechamento == null
                                          ? 'Aberta em ${_formatarDataCurta(item.dataAbertura)}'
                                          : 'Aberta em ${_formatarDataCurta(item.dataAbertura)} • Fechada em ${_formatarDataCurta(item.dataFechamento!)}',
                                    ),
                                    trailing: Text(
                                      item.status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            item.status == 'Aberta'
                                                ? Colors.orange.shade700
                                                : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'OS abertas (se houver)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (ordensAbertas.isEmpty)
                          const Card(
                            child: ListTile(
                              leading: Icon(Icons.verified_outlined),
                              title: Text(
                                'Nenhuma OS aberta para este cliente.',
                              ),
                            ),
                          )
                        else
                          Card(
                            child: Column(
                              children: ordensAbertas
                                  .map(
                                    (_OrdemServicoMock item) => ListTile(
                                      leading: const Icon(
                                        Icons.engineering_outlined,
                                      ),
                                      title: Text(item.numero),
                                      subtitle: Text(
                                        '${item.descricao} • abertura em ${_formatarDataCurta(item.dataAbertura)}',
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
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
      },
    );
  }

  Widget _buildConteudo() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Carregando clientes...'),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 10),
            Text(_erro!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final List<ClienteUsuario> clientesFiltrados = _clientesFiltrados();
    final int total = _response?.total ?? 0;

    if ((_response?.clientes.isEmpty ?? true)) {
      return const Center(
        child: Text('Nenhum cliente encontrado para esta empresa.'),
      );
    }

    if (clientesFiltrados.isEmpty) {
      return const Center(
        child: Text('Nenhum cliente encontrado para o filtro informado.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 360,
              child: TextField(
                key: const Key('clientes-busca-input'),
                controller: _buscaController,
                onChanged: (value) {
                  setState(() {
                    _filtro = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Buscar por nome/documento',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Text('Total de registros: $total'),
            if (clientesFiltrados.length != total)
              Text('Exibindo: ${clientesFiltrados.length}'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('Documento')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Telefone')),
                  DataColumn(label: Text('Tipo Pessoa')),
                  DataColumn(label: Text('Ativo')),
                  DataColumn(label: Text('Criado em')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: clientesFiltrados
                    .map((ClienteUsuario cliente) {
                      return DataRow(
                        cells: <DataCell>[
                          DataCell(Text(cliente.nome)),
                          DataCell(Text(cliente.documento)),
                          DataCell(Text(cliente.email)),
                          DataCell(Text(cliente.telefone)),
                          DataCell(Text(cliente.tipoPessoa)),
                          DataCell(Text(cliente.ativo ? 'Sim' : 'Não')),
                          DataCell(Text(_formatarData(cliente.criadoEm))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Editar cliente',
                                  onPressed: () => _abrirEdicaoCliente(cliente),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Histórico de compras, dívidas e OS',
                                  onPressed:
                                      () => _abrirHistoricoCliente(cliente),
                                  icon: const Icon(Icons.history_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (widget.embedded && widget.onBack != null)
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              const Expanded(
                child: Text(
                  'Clientes List',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildConteudo()),
        ],
      ),
    );
  }
}

class _ResumoHistoricoCard extends StatelessWidget {
  const _ResumoHistoricoCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
  });

  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(icone, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.bodySmall,
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
}

class _CompraMock {
  _CompraMock({
    required this.descricao,
    required this.data,
    required this.formaPagamento,
    required this.valor,
  });

  final String descricao;
  final DateTime data;
  final String formaPagamento;
  final double valor;
}

class _DividaMock {
  _DividaMock({
    required this.descricao,
    required this.vencimento,
    required this.valor,
    required this.status,
  });

  final String descricao;
  final DateTime vencimento;
  final double valor;
  final String status;
}

class _OrdemServicoMock {
  _OrdemServicoMock({
    required this.numero,
    required this.descricao,
    required this.dataAbertura,
    required this.dataFechamento,
    required this.status,
  });

  final String numero;
  final String descricao;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String status;
}
