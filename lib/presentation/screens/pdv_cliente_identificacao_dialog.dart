import 'package:flutter/material.dart';

import '../../core/di/cliente_usuario_module.dart';
import '../../core/services/cliente_usuario_service.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';

class ClienteIdentificacaoVendaResult {
  const ClienteIdentificacaoVendaResult({this.cliente, this.limpar = false});

  final ClienteUsuario? cliente;
  final bool limpar;
}

class PdvClienteIdentificacaoDialog extends StatefulWidget {
  const PdvClienteIdentificacaoDialog({
    super.key,
    this.clienteAtual,
    this.apiClient,
    this.clienteUsuarioService,
  });

  final ClienteUsuario? clienteAtual;
  final ClienteUsuarioApiClient? apiClient;
  final ClienteUsuarioService? clienteUsuarioService;

  @override
  State<PdvClienteIdentificacaoDialog> createState() =>
      _PdvClienteIdentificacaoDialogState();
}

class _PdvClienteIdentificacaoDialogState
    extends State<PdvClienteIdentificacaoDialog> {
  late final ClienteUsuarioService _clienteUsuarioService;
  final TextEditingController _buscaController = TextEditingController();

  bool _loading = true;
  String? _erro;
  List<ClienteUsuario> _clientes = <ClienteUsuario>[];
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _clienteUsuarioService = widget.clienteUsuarioService ??
        (widget.apiClient != null
            ? ClienteUsuarioService(apiClient: widget.apiClient!)
            : ClienteUsuarioModule.clienteUsuarioService);
    _carregarClientes();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final List<ClienteUsuario> clientes =
          await _clienteUsuarioService.listarClientesAtivos();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = 'Não foi possível carregar os clientes.';
      });
    }
  }

  List<ClienteUsuario> get _clientesFiltrados {
    return _clienteUsuarioService.filtrarClientes(_clientes, _filtro);
  }

  void _selecionar(ClienteUsuario cliente) {
    Navigator.of(context).pop(ClienteIdentificacaoVendaResult(cliente: cliente));
  }

  void _limparCliente() {
    Navigator.of(context).pop(const ClienteIdentificacaoVendaResult(limpar: true));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 920,
        height: 680,
        child: Column(
          children: <Widget>[
            _header(theme),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
              child: TextField(
                controller: _buscaController,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  labelText: 'Buscar cliente por nome, documento, telefone ou e-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onChanged: (String value) => setState(() => _filtro = value),
              ),
            ),
            Expanded(child: _body(theme)),
            _footer(theme),
          ],
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.person_search_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Identificar cliente',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecione um cliente cadastrado para vincular a venda, fiado, crediário e histórico.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 42, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(_erro!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _carregarClientes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final List<ClienteUsuario> clientes = _clientesFiltrados;
    if (clientes.isEmpty) {
      return Center(
        child: Text(
          _filtro.trim().isEmpty
              ? 'Nenhum cliente ativo cadastrado.'
              : 'Nenhum cliente encontrado.',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
      itemCount: clientes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        return _clienteTile(theme, clientes[index]);
      },
    );
  }

  Widget _clienteTile(ThemeData theme, ClienteUsuario cliente) {
    final bool selecionado = widget.clienteAtual?.id == cliente.id;
    final bool fiadoLiberado = cliente.permiteCompraFiado && !cliente.bloqueadoFiado;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _selecionar(cliente),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionado ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                _iniciais(cliente.nome),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cliente.tipoPessoa.isEmpty ? 'PF' : cliente.tipoPessoa} • ${cliente.documento.isEmpty ? 'Sem documento' : cliente.documento}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fiadoLiberado
                        ? 'Fiado liberado • limite R\$ ${cliente.limiteFiado.toStringAsFixed(2)} • ${cliente.prazoPagamentoDias} dias'
                        : cliente.permiteCompraFiado
                        ? 'Fiado bloqueado para novas vendas'
                        : 'Cliente sem fiado liberado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cliente.bloqueadoFiado
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _selecionar(cliente),
              icon: Icon(selecionado ? Icons.check_circle_outline : Icons.person_add_alt_1_rounded),
              label: Text(selecionado ? 'Selecionado' : 'Selecionar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          if (widget.clienteAtual != null)
            OutlinedButton.icon(
              onPressed: _limparCliente,
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Remover cliente da venda'),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  String _iniciais(String nome) {
    final List<String> partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (partes.isEmpty) return 'CL';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first.substring(0, 1)}${partes.last.substring(0, 1)}'.toUpperCase();
  }
}
