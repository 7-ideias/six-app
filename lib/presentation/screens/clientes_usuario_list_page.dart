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
