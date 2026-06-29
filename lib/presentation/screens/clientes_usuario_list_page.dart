import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  State<ClientesUsuarioListPage> createState() => _ClientesUsuarioListPageState();
}

class _ClientesUsuarioListPageState extends State<ClientesUsuarioListPage> {
  late final ClienteUsuarioApiClient _apiClient;
  final TextEditingController _buscaController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

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
      final ClienteUsuarioListResponse response = await _apiClient.listarClientesUsuario();
      if (!mounted) return;
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } on ClienteUsuarioApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erro = _mensagemErroPorStatus(e.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erro = 'Não foi possível carregar a lista de clientes.';
      });
    }
  }

  String _mensagemErroPorStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos ou empresa não informada.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Usuário sem vínculo com a empresa.';
      case 409:
        return 'Já existe cliente com documento ou e-mail informado.';
      default:
        return 'Erro ao carregar clientes (HTTP $statusCode).';
    }
  }

  List<ClienteUsuario> get _clientes => _response?.clientes ?? const <ClienteUsuario>[];

  List<ClienteUsuario> get _clientesFiltrados {
    final String termo = _normalizar(_filtro);
    if (termo.isEmpty) return _clientes;

    return _clientes.where((ClienteUsuario cliente) {
      return _normalizar(cliente.nome).contains(termo) ||
          _normalizar(cliente.documento).contains(termo) ||
          _normalizar(cliente.email).contains(termo) ||
          _normalizar(cliente.telefone).contains(termo);
    }).toList(growable: false);
  }

  int get _clientesAtivos => _clientes.where((ClienteUsuario cliente) => cliente.ativo).length;
  int get _clientesFiado => _clientes.where((ClienteUsuario cliente) => cliente.permiteCompraFiado).length;
  int get _clientesBloqueadosFiado => _clientes.where((ClienteUsuario cliente) => cliente.bloqueadoFiado).length;
  double get _limiteFiadoTotal => _clientes.fold<double>(0, (double total, ClienteUsuario cliente) => total + cliente.limiteFiado);
  double get _saldoFiadoTotal => _clientes.fold<double>(0, (double total, ClienteUsuario cliente) => total + cliente.saldoFiado);

  String _normalizar(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  String _money(double value) => _currencyFormatter.format(value);
  String _date(DateTime? value) => value == null ? '-' : _dateFormatter.format(value.toLocal());

  Future<void> _abrirCadastroCliente({ClienteUsuario? cliente}) async {
    final ClienteUsuarioRequest? request = await showDialog<ClienteUsuarioRequest>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _ClienteFormDialog(cliente: cliente),
    );

    if (request == null) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      if (cliente == null) {
        await _apiClient.cadastrarClienteUsuario(request);
      } else {
        await _apiClient.atualizarClienteUsuario(cliente.id, request);
      }
      await _carregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cliente == null ? 'Cliente cadastrado com sucesso.' : 'Cliente atualizado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ClienteUsuarioApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erro = _mensagemErroPorStatus(e.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erro = 'Não foi possível salvar o cliente.';
      });
    }
  }

  void _abrirHistoricoCliente(ClienteUsuario cliente) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeData theme = Theme.of(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: SizedBox(
            width: 980,
            height: 620,
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.07),
                    border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.person_search_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Visão do cliente: ${cliente.nome}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: <Widget>[
                            _historicoCard('Documento', cliente.documento, Icons.badge_outlined),
                            _historicoCard('Telefone', cliente.telefone.isEmpty ? '-' : cliente.telefone, Icons.phone_outlined),
                            _historicoCard('E-mail', cliente.email.isEmpty ? '-' : cliente.email, Icons.mail_outline),
                            _historicoCard('Fiado', cliente.permiteCompraFiado ? 'Liberado' : 'Não liberado', Icons.request_quote_outlined),
                            _historicoCard('Limite fiado', _money(cliente.limiteFiado), Icons.account_balance_wallet_outlined),
                            _historicoCard('Saldo fiado', _money(cliente.saldoFiado), Icons.receipt_long_outlined),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _infoBox(
                          title: 'Compras, serviços e fiado',
                          text: 'Esta tela já está preparada para receber o histórico real de vendas, serviços, contas em aberto e crediário. A próxima etapa é cruzar o cliente com movimentações de venda, assistência técnica e financeiro.',
                          icon: Icons.timeline_outlined,
                        ),
                        const SizedBox(height: 18),
                        _infoBox(
                          title: 'Endereço e observações',
                          text: '${_enderecoCliente(cliente)}\n${cliente.observacoes.isEmpty ? 'Sem observações cadastradas.' : cliente.observacoes}',
                          icon: Icons.location_on_outlined,
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

  String _enderecoCliente(ClienteUsuario cliente) {
    final List<String> partes = <String>[
      cliente.logradouro,
      cliente.numero,
      cliente.bairro,
      cliente.cidade,
      cliente.uf,
      cliente.cep,
    ].where((String value) => value.trim().isNotEmpty).toList(growable: false);
    return partes.isEmpty ? 'Endereço não informado.' : partes.join(', ');
  }

  Widget _historicoCard(String title, String value, IconData icon) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: 290,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({required String title, required String text, required IconData icon}) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget content = Column(
      children: <Widget>[
        _buildHeader(theme),
        Expanded(child: _buildBody(theme)),
      ],
    );

    if (widget.embedded) return content;
    return Scaffold(body: SafeArea(child: content));
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.groups_2_outlined, color: theme.colorScheme.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Clientes', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'Cadastro, relacionamento, compras a prazo e controle de fiado dos clientes da empresa.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(onPressed: _carregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Atualizar')),
              FilledButton.icon(onPressed: () => _abrirCadastroCliente(), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Novo cliente')),
              if (widget.onBack != null)
                IconButton.filledTonal(onPressed: widget.onBack, tooltip: 'Voltar', icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _response == null) return const Center(child: CircularProgressIndicator());
    if (_erro != null && _response == null) return _errorState(theme);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_erro != null) ...<Widget>[
            _inlineError(theme, _erro!),
            const SizedBox(height: 16),
          ],
          _kpiGrid(theme),
          const SizedBox(height: 18),
          _toolbar(theme),
          const SizedBox(height: 18),
          _clientesFiltrados.isEmpty ? _emptyState(theme) : _clientesGrid(theme),
        ],
      ),
    );
  }

  Widget _kpiGrid(ThemeData theme) {
    final List<_Kpi> kpis = <_Kpi>[
      _Kpi(Icons.groups_outlined, 'Clientes cadastrados', '${_clientes.length}'),
      _Kpi(Icons.verified_user_outlined, 'Clientes ativos', '$_clientesAtivos'),
      _Kpi(Icons.request_quote_outlined, 'Com fiado liberado', '$_clientesFiado'),
      _Kpi(Icons.block_outlined, 'Fiado bloqueado', '$_clientesBloqueadosFiado'),
      _Kpi(Icons.account_balance_wallet_outlined, 'Limite total fiado', _money(_limiteFiadoTotal), true),
      _Kpi(Icons.receipt_long_outlined, 'Saldo em aberto', _money(_saldoFiadoTotal)),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int crossAxisCount = constraints.maxWidth < 900 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 118,
          ),
          itemBuilder: (BuildContext context, int index) => _kpiCard(theme, kpis[index]),
        );
      },
    );
  }

  Widget _kpiCard(ThemeData theme, _Kpi kpi) {
    final Color background = kpi.highlight ? theme.colorScheme.primary : theme.colorScheme.surface;
    final Color foreground = kpi.highlight ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final Color muted = kpi.highlight ? theme.colorScheme.onPrimary.withOpacity(0.80) : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kpi.highlight ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kpi.highlight ? theme.colorScheme.onPrimary.withOpacity(0.14) : theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(kpi.icon, color: kpi.highlight ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(kpi.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Text(kpi.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontWeight: FontWeight.w900, fontSize: 21)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                labelText: 'Buscar por nome, documento, telefone ou e-mail',
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) => setState(() => _filtro = value),
            ),
          ),
          const SizedBox(width: 12),
          Text('${_clientesFiltrados.length} encontrados', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _clientesGrid(ThemeData theme) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 980;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _clientesFiltrados.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 1 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 270,
          ),
          itemBuilder: (BuildContext context, int index) => _clienteCard(theme, _clientesFiltrados[index]),
        );
      },
    );
  }

  Widget _clienteCard(ThemeData theme, ClienteUsuario cliente) {
    final bool fiadoOk = cliente.permiteCompraFiado && !cliente.bloqueadoFiado;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Text(_iniciais(cliente.nome), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('${cliente.tipoPessoa.isEmpty ? 'PF' : cliente.tipoPessoa} • ${cliente.documento}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              _statusChip(theme, cliente.ativo ? 'Ativo' : 'Inativo', cliente.ativo ? Colors.green.shade700 : theme.colorScheme.error),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _infoChip(theme, Icons.phone_outlined, cliente.telefone.isEmpty ? 'Sem telefone' : cliente.telefone),
              _infoChip(theme, Icons.mail_outline, cliente.email.isEmpty ? 'Sem e-mail' : cliente.email),
              _infoChip(theme, Icons.location_on_outlined, cliente.cidade.isEmpty ? 'Sem cidade' : '${cliente.cidade}/${cliente.uf}'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fiadoOk ? Colors.green.withOpacity(0.08) : theme.colorScheme.surfaceVariant.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: fiadoOk ? Colors.green.withOpacity(0.20) : theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.request_quote_outlined, color: fiadoOk ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cliente.permiteCompraFiado
                        ? 'Fiado: limite ${_money(cliente.limiteFiado)} • prazo ${cliente.prazoPagamentoDias} dias'
                        : 'Fiado não liberado para este cliente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirHistoricoCliente(cliente),
                  icon: const Icon(Icons.timeline_outlined),
                  label: const Text('Histórico'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _abrirCadastroCliente(cliente: cliente),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Atualizado em ${_date(cliente.atualizadoEm)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _iniciais(String nome) {
    final List<String> partes = nome.trim().split(' ').where((String item) => item.isNotEmpty).toList(growable: false);
    if (partes.isEmpty) return 'CL';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first.substring(0, 1)}${partes.last.substring(0, 1)}'.toUpperCase();
  }

  Widget _statusChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.colorScheme.outlineVariant)),
      child: Column(
        children: <Widget>[
          Icon(Icons.person_add_alt_1_rounded, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Nenhum cliente encontrado.', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Cadastre clientes para registrar vendas, serviços e compras a prazo.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: () => _abrirCadastroCliente(), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Novo cliente')),
        ],
      ),
    );
  }

  Widget _errorState(ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.30),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 42, color: theme.colorScheme.error),
            const SizedBox(height: 14),
            Text('Não foi possível carregar os clientes.', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_erro ?? '', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _carregar, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _inlineError(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.24)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _ClienteFormDialog extends StatefulWidget {
  const _ClienteFormDialog({this.cliente});

  final ClienteUsuario? cliente;

  @override
  State<_ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<_ClienteFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _documentoController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cepController;
  late final TextEditingController _logradouroController;
  late final TextEditingController _numeroController;
  late final TextEditingController _complementoController;
  late final TextEditingController _bairroController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _ufController;
  late final TextEditingController _observacoesController;
  late final TextEditingController _limiteFiadoController;
  late final TextEditingController _prazoFiadoController;

  String _tipoPessoa = 'PF';
  bool _ativo = true;
  bool _permiteFiado = false;
  bool _bloqueadoFiado = false;

  @override
  void initState() {
    super.initState();
    final ClienteUsuario? cliente = widget.cliente;
    _tipoPessoa = cliente?.tipoPessoa.isNotEmpty == true ? cliente!.tipoPessoa : 'PF';
    _ativo = cliente?.ativo ?? true;
    _permiteFiado = cliente?.permiteCompraFiado ?? false;
    _bloqueadoFiado = cliente?.bloqueadoFiado ?? false;
    _nomeController = TextEditingController(text: cliente?.nome ?? '');
    _documentoController = TextEditingController(text: cliente?.documento ?? '');
    _telefoneController = TextEditingController(text: cliente?.telefone ?? '');
    _emailController = TextEditingController(text: cliente?.email ?? '');
    _cepController = TextEditingController(text: cliente?.cep ?? '');
    _logradouroController = TextEditingController(text: cliente?.logradouro ?? '');
    _numeroController = TextEditingController(text: cliente?.numero ?? '');
    _complementoController = TextEditingController(text: cliente?.complemento ?? '');
    _bairroController = TextEditingController(text: cliente?.bairro ?? '');
    _cidadeController = TextEditingController(text: cliente?.cidade ?? '');
    _ufController = TextEditingController(text: cliente?.uf ?? '');
    _observacoesController = TextEditingController(text: cliente?.observacoes ?? '');
    _limiteFiadoController = TextEditingController(text: _formatNumber(cliente?.limiteFiado ?? 0));
    _prazoFiadoController = TextEditingController(text: '${cliente?.prazoPagamentoDias ?? 30}');
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _nomeController,
      _documentoController,
      _telefoneController,
      _emailController,
      _cepController,
      _logradouroController,
      _numeroController,
      _complementoController,
      _bairroController,
      _cidadeController,
      _ufController,
      _observacoesController,
      _limiteFiadoController,
      _prazoFiadoController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _formatNumber(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

  double _parseMoney(String value) {
    final String normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _decoration(label, icon),
      validator: requiredField
          ? (String? value) {
              if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
              return null;
            }
          : null,
    );
  }

  Widget _tipoPessoaDropdown() {
    return DropdownButtonFormField<String>(
      value: _tipoPessoa,
      isExpanded: true,
      decoration: _decoration('Tipo', Icons.badge_outlined),
      selectedItemBuilder: (BuildContext context) {
        return const <Widget>[
          Text('PF', overflow: TextOverflow.ellipsis),
          Text('PJ', overflow: TextOverflow.ellipsis),
        ];
      },
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(value: 'PF', child: Text('Pessoa física', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem<String>(value: 'PJ', child: Text('Pessoa jurídica', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (String? value) => setState(() => _tipoPessoa = value ?? 'PF'),
    );
  }

  void _salvar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ClienteUsuarioRequest(
        ativo: _ativo,
        tipoPessoa: _tipoPessoa,
        documento: _documentoController.text.trim(),
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        email: _emailController.text.trim(),
        cep: _cepController.text.trim(),
        logradouro: _logradouroController.text.trim(),
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        uf: _ufController.text.trim().toUpperCase(),
        observacoes: _observacoesController.text.trim(),
        foto: widget.cliente?.foto ?? '',
        permiteCompraFiado: _permiteFiado,
        limiteFiado: _permiteFiado ? _parseMoney(_limiteFiadoController.text) : 0,
        prazoPagamentoDias: _permiteFiado ? _parseInt(_prazoFiadoController.text) : 0,
        bloqueadoFiado: _bloqueadoFiado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool editando = widget.cliente != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 1040,
        height: 760,
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.07),
                border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.person_add_alt_1_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(editando ? 'Editar cliente' : 'Novo cliente', overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _sectionTitle(theme, 'Dados principais'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: <Widget>[
                          SizedBox(width: 220, child: _tipoPessoaDropdown()),
                          SizedBox(width: 360, child: _field(controller: _nomeController, label: 'Nome / Razão social', icon: Icons.person_outline, requiredField: true)),
                          SizedBox(width: 260, child: _field(controller: _documentoController, label: 'CPF / CNPJ', icon: Icons.credit_card_outlined, requiredField: true)),
                          SizedBox(width: 260, child: _field(controller: _telefoneController, label: 'Telefone / WhatsApp', icon: Icons.phone_outlined, keyboardType: TextInputType.phone)),
                          SizedBox(width: 360, child: _field(controller: _emailController, label: 'E-mail', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle(theme, 'Endereço'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: <Widget>[
                          SizedBox(width: 180, child: _field(controller: _cepController, label: 'CEP', icon: Icons.markunread_mailbox_outlined)),
                          SizedBox(width: 360, child: _field(controller: _logradouroController, label: 'Logradouro', icon: Icons.route_outlined)),
                          SizedBox(width: 120, child: _field(controller: _numeroController, label: 'Número', icon: Icons.numbers_outlined)),
                          SizedBox(width: 260, child: _field(controller: _complementoController, label: 'Complemento', icon: Icons.add_home_outlined)),
                          SizedBox(width: 260, child: _field(controller: _bairroController, label: 'Bairro', icon: Icons.location_city_outlined)),
                          SizedBox(width: 260, child: _field(controller: _cidadeController, label: 'Cidade', icon: Icons.location_on_outlined)),
                          SizedBox(width: 120, child: _field(controller: _ufController, label: 'UF', icon: Icons.map_outlined)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle(theme, 'Fiado / compra a prazo'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.32),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: <Widget>[
                            SwitchListTile.adaptive(
                              value: _permiteFiado,
                              title: const Text('Permitir compra fiado / a prazo'),
                              subtitle: const Text('Libera o cliente para pagar depois conforme limite e prazo configurados.'),
                              onChanged: (bool value) => setState(() => _permiteFiado = value),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: <Widget>[
                                SizedBox(width: 220, child: _field(controller: _limiteFiadoController, label: 'Limite de fiado', icon: Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number)),
                                SizedBox(width: 220, child: _field(controller: _prazoFiadoController, label: 'Prazo padrão em dias', icon: Icons.event_available_outlined, keyboardType: TextInputType.number)),
                                SizedBox(
                                  width: 320,
                                  child: SwitchListTile.adaptive(
                                    value: _bloqueadoFiado,
                                    title: const Text('Bloquear fiado'),
                                    subtitle: const Text('Impede novas vendas a prazo.'),
                                    onChanged: (bool value) => setState(() => _bloqueadoFiado = value),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle(theme, 'Status e observações'),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _ativo,
                        title: const Text('Cliente ativo'),
                        onChanged: (bool value) => setState(() => _ativo = value),
                      ),
                      const SizedBox(height: 12),
                      _field(controller: _observacoesController, label: 'Observações', icon: Icons.notes_outlined, maxLines: 4),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                  const SizedBox(width: 12),
                  FilledButton.icon(onPressed: _salvar, icon: const Icon(Icons.save_outlined), label: Text(editando ? 'Salvar alterações' : 'Cadastrar cliente')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900));
  }
}

class _Kpi {
  const _Kpi(this.icon, this.label, this.value, [this.highlight = false]);

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
}
