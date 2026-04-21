import 'package:flutter/material.dart';

import '../../data/models/colaborador_usuario_model.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';

class ColaboradoresUsuarioListPage extends StatefulWidget {
  const ColaboradoresUsuarioListPage({
    super.key,
    this.embedded = false,
    this.onBack,
    this.apiClient,
  });

  final bool embedded;
  final VoidCallback? onBack;
  final ColaboradorUsuarioApiClient? apiClient;

  @override
  State<ColaboradoresUsuarioListPage> createState() =>
      _ColaboradoresUsuarioListPageState();
}

class _ColaboradoresUsuarioListPageState
    extends State<ColaboradoresUsuarioListPage> {
  late final ColaboradorUsuarioApiClient _apiClient;
  final TextEditingController _buscaController = TextEditingController();

  bool _isLoading = false;
  String? _erro;
  List<ColaboradorUsuarioResumo> _colaboradores =
      const <ColaboradorUsuarioResumo>[];
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? HttpColaboradorUsuarioApiClient();
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
      final List<ColaboradorUsuarioResumo> response =
          await _apiClient.listarColaboradores();
      if (!mounted) {
        return;
      }
      setState(() {
        _colaboradores = response;
        _isLoading = false;
      });
    } on ColaboradorUsuarioApiException catch (e) {
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
        _erro = 'Não foi possível carregar a lista de colaboradores.';
      });
    }
  }

  String _mensagemErroPorStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requisição inválida para listar colaboradores.';
      case 401:
        return 'Não autenticado: faça login novamente.';
      case 403:
        return 'Acesso negado: usuário sem vínculo com a empresa.';
      default:
        return 'Erro ao carregar colaboradores (HTTP $statusCode).';
    }
  }

  List<ColaboradorUsuarioResumo> _colaboradoresFiltrados() {
    if (_filtro.trim().isEmpty) {
      return _colaboradores;
    }

    final String termo = _normalizar(_filtro);
    return _colaboradores
        .where((ColaboradorUsuarioResumo colaborador) {
          final String nome = _normalizar(colaborador.nome);
          final String nomeDeGuerra = _normalizar(colaborador.nomeDeGuerra);
          final String celular = _normalizar(colaborador.celularDeAcesso);
          final String email = _normalizar(colaborador.email);
          return nome.contains(termo) ||
              nomeDeGuerra.contains(termo) ||
              celular.contains(termo) ||
              email.contains(termo);
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

  Map<String, dynamic> _ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
  }

  bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final String normalized = value?.toString().toLowerCase().trim() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'sim';
  }

  double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  double _toDouble(String value) {
    String normalized = value.trim().replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0.0;
  }

  void _atualizarColaboradorNaLista(ColaboradorUsuarioResumo colaborador) {
    setState(() {
      _colaboradores = _colaboradores
          .map(
            (ColaboradorUsuarioResumo item) =>
                item.idUnicoPessoal == colaborador.idUnicoPessoal
                    ? colaborador
                    : item,
          )
          .toList(growable: false);
    });
  }

  Future<void> _abrirEdicaoColaborador(ColaboradorUsuarioResumo resumo) async {
    setState(() {
      _isLoading = true;
    });

    ColaboradorUsuarioDetalhe detalhe;
    try {
      detalhe = await _apiClient.buscarColaborador(resumo.idUnicoPessoal);
    } on ColaboradorUsuarioApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensagemErroPorStatus(e.statusCode)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar o colaborador para edição.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    final Map<String, dynamic> payload = detalhe.toJson();
    final Map<String, dynamic> objPessoa = _ensureMap(payload['objPessoa']);
    final Map<String, dynamic> objDadosFuncionais = _ensureMap(
      payload['objDadosFuncionais'],
    );
    final Map<String, dynamic> objAutorizacoes = _ensureMap(
      payload['objAutorizacoes'],
    );
    final Map<String, dynamic> objProdutosPode = _ensureMap(
      objAutorizacoes['objProdutosPode'],
    );
    final Map<String, dynamic> objVendasPode = _ensureMap(
      objAutorizacoes['objVendasPode'],
    );
    final Map<String, dynamic> objAssistenciaTecnicaPode = _ensureMap(
      objAutorizacoes['objAssistenciaTecnicaPode'],
    );
    final Map<String, dynamic> objClientesPode = _ensureMap(
      objAutorizacoes['objClientesPode'],
    );
    final Map<String, dynamic> objRelatoriosPode = _ensureMap(
      objAutorizacoes['objRelatoriosPode'],
    );
    final Map<String, dynamic> objLancamentosFinanceirosPode = _ensureMap(
      objAutorizacoes['objLancamentosFinanceirosPode'],
    );

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nomeController = TextEditingController(
      text: objPessoa['nome']?.toString() ?? resumo.nome,
    );
    final TextEditingController nomeDeGuerraController = TextEditingController(
      text: objPessoa['nomeDeGuerra']?.toString() ?? resumo.nomeDeGuerra,
    );
    final TextEditingController celularDeAcessoController =
        TextEditingController(
          text:
              payload['celularDeAcesso']?.toString() ?? resumo.celularDeAcesso,
        );
    final TextEditingController celularController = TextEditingController(
      text: objPessoa['celular']?.toString() ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: objPessoa['email']?.toString() ?? resumo.email,
    );
    final TextEditingController cpfController = TextEditingController(
      text: objPessoa['cpf']?.toString() ?? '',
    );
    final TextEditingController rgController = TextEditingController(
      text: objPessoa['rg']?.toString() ?? '',
    );
    final TextEditingController dataNascimentoController =
        TextEditingController(
          text: objPessoa['dataDeNascimento']?.toString() ?? '',
        );
    final TextEditingController salarioController = TextEditingController(
      text: _parseDouble(objDadosFuncionais['salario']).toStringAsFixed(2),
    );
    final TextEditingController fotoController = TextEditingController(
      text: payload['foto']?.toString() ?? resumo.foto,
    );

    bool podeFazerDevolucao = _parseBool(objAutorizacoes['podeFazerDevolucao']);
    bool podeCadastrarProduto = _parseBool(
      objAutorizacoes['podeCadastrarProduto'],
    );
    bool podeVerEstoqueDeProduto = _parseBool(
      objProdutosPode['podeVerEstoqueDeProduto'],
    );
    bool podeEditarProduto = _parseBool(objProdutosPode['podeEditarProduto']);
    bool fazVenda = _parseBool(objVendasPode['fazVenda']);
    bool lancaServico = _parseBool(objAssistenciaTecnicaPode['lancaServico']);
    bool ehTecnico = _parseBool(
      objAssistenciaTecnicaPode['ehUmTecnicoEFazAssistenciaTecnica'],
    );
    bool podeEditarCliente = _parseBool(objClientesPode['podeEditarCliente']);
    bool geraRelatorioDeVendas = _parseBool(
      objRelatoriosPode['geraRelatorioDeVendas'],
    );
    bool podeReceberNoCaixa = _parseBool(
      objLancamentosFinanceirosPode['podeReceberNoCaixa'],
    );
    bool podeVerQuantoVendeu = _parseBool(
      objLancamentosFinanceirosPode['podeVerQuantoVendeu'],
    );

    try {
      final _EdicaoColaboradorResult?
      result = await showDialog<_EdicaoColaboradorResult>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext builderContext,
              void Function(void Function()) setDialogState,
            ) {
              Widget buildSwitch(
                String titulo,
                bool value,
                ValueChanged<bool> onChanged,
              ) {
                return SwitchListTile.adaptive(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(titulo),
                  value: value,
                  onChanged: (bool newValue) {
                    setDialogState(() {
                      onChanged(newValue);
                    });
                  },
                );
              }

              return AlertDialog(
                title: Text('Editar colaborador: ${resumo.nome}'),
                content: SizedBox(
                  width: 880,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              SizedBox(
                                width: 410,
                                child: TextFormField(
                                  controller: nomeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe o nome.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 410,
                                child: TextFormField(
                                  controller: nomeDeGuerraController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome de guerra',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 270,
                                child: TextFormField(
                                  controller: celularDeAcessoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Celular de acesso',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 270,
                                child: TextFormField(
                                  controller: celularController,
                                  decoration: const InputDecoration(
                                    labelText: 'Celular',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 270,
                                child: TextFormField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 270,
                                child: TextFormField(
                                  controller: cpfController,
                                  decoration: const InputDecoration(
                                    labelText: 'CPF',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 270,
                                child: TextFormField(
                                  controller: rgController,
                                  decoration: const InputDecoration(
                                    labelText: 'RG',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 270,
                                child: TextFormField(
                                  controller: dataNascimentoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Data nascimento',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 270,
                                child: TextFormField(
                                  controller: salarioController,
                                  decoration: const InputDecoration(
                                    labelText: 'Salário',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 552,
                                child: TextFormField(
                                  controller: fotoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Foto (URL)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 4),
                          Text(
                            'Autorizações',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 0,
                            children: <Widget>[
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Pode fazer devolução',
                                  podeFazerDevolucao,
                                  (bool value) => podeFazerDevolucao = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Pode cadastrar produto',
                                  podeCadastrarProduto,
                                  (bool value) => podeCadastrarProduto = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Pode ver estoque de produto',
                                  podeVerEstoqueDeProduto,
                                  (bool value) =>
                                      podeVerEstoqueDeProduto = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Pode editar produto',
                                  podeEditarProduto,
                                  (bool value) => podeEditarProduto = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Faz venda',
                                  fazVenda,
                                  (bool value) => fazVenda = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Lança serviço',
                                  lancaServico,
                                  (bool value) => lancaServico = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'É técnico e faz assistência',
                                  ehTecnico,
                                  (bool value) => ehTecnico = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Pode editar cliente',
                                  podeEditarCliente,
                                  (bool value) => podeEditarCliente = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Gera relatório de vendas',
                                  geraRelatorioDeVendas,
                                  (bool value) => geraRelatorioDeVendas = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Pode receber no caixa',
                                  podeReceberNoCaixa,
                                  (bool value) => podeReceberNoCaixa = value,
                                ),
                              ),
                              SizedBox(
                                width: 400,
                                child: buildSwitch(
                                  'Pode ver quanto vendeu',
                                  podeVerQuantoVendeu,
                                  (bool value) => podeVerQuantoVendeu = value,
                                ),
                              ),
                            ],
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

                      final Map<String, dynamic> editPayload = detalhe.toJson();
                      final Map<String, dynamic> payloadPessoa = _ensureMap(
                        editPayload['objPessoa'],
                      );
                      final Map<String, dynamic> payloadDadosFuncionais =
                          _ensureMap(editPayload['objDadosFuncionais']);
                      final Map<String, dynamic> payloadAutorizacoes =
                          _ensureMap(editPayload['objAutorizacoes']);
                      final Map<String, dynamic> payloadProdutosPode =
                          _ensureMap(payloadAutorizacoes['objProdutosPode']);
                      final Map<String, dynamic> payloadVendasPode = _ensureMap(
                        payloadAutorizacoes['objVendasPode'],
                      );
                      final Map<String, dynamic> payloadAssistenciaTecnicaPode =
                          _ensureMap(
                            payloadAutorizacoes['objAssistenciaTecnicaPode'],
                          );
                      final Map<String, dynamic> payloadClientesPode =
                          _ensureMap(payloadAutorizacoes['objClientesPode']);
                      final Map<String, dynamic> payloadRelatoriosPode =
                          _ensureMap(payloadAutorizacoes['objRelatoriosPode']);
                      final Map<String, dynamic>
                      payloadLancamentosFinanceirosPode = _ensureMap(
                        payloadAutorizacoes['objLancamentosFinanceirosPode'],
                      );

                      editPayload['foto'] = fotoController.text.trim();
                      editPayload['celularDeAcesso'] =
                          celularDeAcessoController.text.trim();

                      payloadPessoa['nome'] = nomeController.text.trim();
                      payloadPessoa['nomeDeGuerra'] =
                          nomeDeGuerraController.text.trim();
                      payloadPessoa['celular'] = celularController.text.trim();
                      payloadPessoa['email'] = emailController.text.trim();
                      payloadPessoa['cpf'] = cpfController.text.trim();
                      payloadPessoa['rg'] = rgController.text.trim();
                      payloadPessoa['dataDeNascimento'] =
                          dataNascimentoController.text.trim();
                      payloadPessoa['documento_DE_IDENTIFICACAO_UNICO_DA_EMPRESA'] =
                          payloadPessoa['documento_DE_IDENTIFICACAO_UNICO_DA_EMPRESA'] ??
                          cpfController.text.trim();
                      editPayload['objPessoa'] = payloadPessoa;

                      payloadDadosFuncionais['salario'] = _toDouble(
                        salarioController.text,
                      );
                      editPayload['objDadosFuncionais'] =
                          payloadDadosFuncionais;

                      payloadAutorizacoes['podeFazerDevolucao'] =
                          podeFazerDevolucao;
                      payloadAutorizacoes['podeCadastrarProduto'] =
                          podeCadastrarProduto;

                      payloadProdutosPode['podeVerEstoqueDeProduto'] =
                          podeVerEstoqueDeProduto;
                      payloadProdutosPode['podeEditarProduto'] =
                          podeEditarProduto;
                      payloadAutorizacoes['objProdutosPode'] =
                          payloadProdutosPode;

                      payloadVendasPode['fazVenda'] = fazVenda;
                      payloadAutorizacoes['objVendasPode'] = payloadVendasPode;

                      payloadAssistenciaTecnicaPode['lancaServico'] =
                          lancaServico;
                      payloadAssistenciaTecnicaPode['ehUmTecnicoEFazAssistenciaTecnica'] =
                          ehTecnico;
                      payloadAutorizacoes['objAssistenciaTecnicaPode'] =
                          payloadAssistenciaTecnicaPode;

                      payloadClientesPode['podeEditarCliente'] =
                          podeEditarCliente;
                      payloadAutorizacoes['objClientesPode'] =
                          payloadClientesPode;

                      payloadRelatoriosPode['geraRelatorioDeVendas'] =
                          geraRelatorioDeVendas;
                      payloadAutorizacoes['objRelatoriosPode'] =
                          payloadRelatoriosPode;

                      payloadLancamentosFinanceirosPode['podeReceberNoCaixa'] =
                          podeReceberNoCaixa;
                      payloadLancamentosFinanceirosPode['podeVerQuantoVendeu'] =
                          podeVerQuantoVendeu;
                      payloadAutorizacoes['objLancamentosFinanceirosPode'] =
                          payloadLancamentosFinanceirosPode;

                      editPayload['objAutorizacoes'] = payloadAutorizacoes;

                      final ColaboradorUsuarioResumo resumoAtualizado = resumo
                          .copyWith(
                            nome: nomeController.text.trim(),
                            nomeDeGuerra: nomeDeGuerraController.text.trim(),
                            celularDeAcesso:
                                celularDeAcessoController.text.trim(),
                            email: emailController.text.trim(),
                            foto: fotoController.text.trim(),
                          );

                      Navigator.of(dialogContext).pop(
                        _EdicaoColaboradorResult(
                          payload: editPayload,
                          resumoAtualizado: resumoAtualizado,
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

      if (!mounted || result == null) {
        return;
      }

      setState(() {
        _isLoading = true;
      });
      try {
        await _apiClient.editarColaborador(result.payload);
        if (!mounted) {
          return;
        }
        _atualizarColaboradorNaLista(result.resumoAtualizado);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador atualizado com sucesso.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } on ColaboradorUsuarioApiException catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao editar colaborador (HTTP ${e.statusCode}).'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao editar colaborador.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } finally {
      nomeController.dispose();
      nomeDeGuerraController.dispose();
      celularDeAcessoController.dispose();
      celularController.dispose();
      emailController.dispose();
      cpfController.dispose();
      rgController.dispose();
      dataNascimentoController.dispose();
      salarioController.dispose();
      fotoController.dispose();
    }
  }

  Widget _buildConteudo() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Carregando colaboradores...'),
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

    final List<ColaboradorUsuarioResumo> filtrados = _colaboradoresFiltrados();
    final int total = _colaboradores.length;

    if (_colaboradores.isEmpty) {
      return const Center(
        child: Text('Nenhum colaborador encontrado para esta empresa.'),
      );
    }

    if (filtrados.isEmpty) {
      return const Center(
        child: Text('Nenhum colaborador encontrado para o filtro informado.'),
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
                key: const Key('colaboradores-busca-input'),
                controller: _buscaController,
                onChanged: (String value) {
                  setState(() {
                    _filtro = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Buscar por nome/celular/email',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Text('Total de registros: $total'),
            if (filtrados.length != total)
              Text('Exibindo: ${filtrados.length}'),
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
                  DataColumn(label: Text('Nome de guerra')),
                  DataColumn(label: Text('Celular de acesso')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Cadastrado em')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: filtrados
                    .map((ColaboradorUsuarioResumo colaborador) {
                      return DataRow(
                        cells: <DataCell>[
                          DataCell(Text(colaborador.nome)),
                          DataCell(Text(colaborador.nomeDeGuerra)),
                          DataCell(Text(colaborador.celularDeAcesso)),
                          DataCell(Text(colaborador.email)),
                          DataCell(
                            Text(_formatarData(colaborador.dataCadastro)),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Editar colaborador',
                                  onPressed:
                                      () =>
                                          _abrirEdicaoColaborador(colaborador),
                                  icon: const Icon(Icons.edit_outlined),
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
                  'Colaboradores List',
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

class _EdicaoColaboradorResult {
  const _EdicaoColaboradorResult({
    required this.payload,
    required this.resumoAtualizado,
  });

  final Map<String, dynamic> payload;
  final ColaboradorUsuarioResumo resumoAtualizado;
}
