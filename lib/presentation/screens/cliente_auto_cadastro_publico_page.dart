import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sixpos/core/services/auto_customer_public_service.dart';

class ClienteAutoCadastroPublicoPage extends StatefulWidget {
  const ClienteAutoCadastroPublicoPage({super.key, required this.initialUri});

  final Uri initialUri;

  @override
  State<ClienteAutoCadastroPublicoPage> createState() =>
      _ClienteAutoCadastroPublicoPageState();
}

class _ClienteAutoCadastroPublicoPageState
    extends State<ClienteAutoCadastroPublicoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AutoCustomerPublicService _publicService = AutoCustomerPublicService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  bool _aceitaTermos = false;
  bool _isSending = false;
  bool _isValidatingToken = true;
  bool _linkJaUtilizado = false;
  bool _cadastroEnviadoComSucesso = false;
  String _tipoPessoa = 'PF';
  String _documentoOriginal = '';
  String _mensagemSucesso =
      'Recebemos seu auto-cadastro com sucesso. Nossa equipe vai validar os dados.';
  String _mensagemLinkIndisponivel =
      'Link já atualizado/utilizado. Solicite um novo link para novo envio.';

  @override
  void initState() {
    super.initState();
    _precarregarDadosDoLink();
    _validarTokenNoBackend();
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
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _query(String key, {String fallback = ''}) {
    final String? value = widget.initialUri.queryParameters[key];
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return value.trim();
  }

  void _precarregarDadosDoLink() {
    _tipoPessoa =
        _query('tipo', fallback: 'PF').toUpperCase() == 'PJ' ? 'PJ' : 'PF';
    _documentoOriginal = _query('doc');
    if (_documentoOriginal.isNotEmpty) {
      _documentoController.text = _documentoOriginal;
    }
  }

  void _aplicarClienteAtual(AutoCustomerPublicCustomer customer) {
    _tipoPessoa = customer.tipoPessoa;
    _documentoOriginal =
        customer.documento.trim().isEmpty
            ? _documentoOriginal
            : customer.documento.trim();
    _nomeController.text = customer.nome;
    _documentoController.text = customer.documento;
    _telefoneController.text = customer.telefone;
    _emailController.text = customer.email;
    _cepController.text = customer.cep;
    _logradouroController.text = customer.logradouro;
    _numeroController.text = customer.numero;
    _complementoController.text = customer.complemento;
    _bairroController.text = customer.bairro;
    _cidadeController.text = customer.cidade;
    _ufController.text = customer.uf;
    _observacoesController.text = customer.observacoes;
  }

  Future<void> _validarTokenNoBackend() async {
    final String token = _query('token');
    final String idUnicoDaEmpresa = _query('idUnicoDaEmpresa');

    if (token.isEmpty || idUnicoDaEmpresa.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isValidatingToken = false;
        _linkJaUtilizado = true;
        _mensagemLinkIndisponivel =
            'Link inválido. Solicite um novo link para auto-cadastro.';
      });
      return;
    }

    try {
      final AutoCustomerPublicResponse response = await _publicService
          .validarToken(
            idUnicoDaEmpresa: idUnicoDaEmpresa,
            token: token,
            documento: _documentoOriginal,
          );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          if (response.customer != null) {
            _aplicarClienteAtual(response.customer!);
          }
          _isValidatingToken = false;
          _linkJaUtilizado = false;
        });
        return;
      }

      setState(() {
        _isValidatingToken = false;
        _linkJaUtilizado =
            response.statusCode == 404 ||
            response.statusCode == 409 ||
            response.statusCode == 410;
        _mensagemLinkIndisponivel = _mensagemDoBody(
          response.body,
          fallback:
              'Link indisponível. Solicite um novo link para auto-cadastro.',
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isValidatingToken = false;
      });
    }
  }

  String _mensagemDoBody(String body, {required String fallback}) {
    if (body.trim().isEmpty) {
      return fallback;
    }

    try {
      final Object decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final Object? message = decoded['message'] ?? decoded['mensagem'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}

    return fallback;
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  String _tipoCadastroAtual() {
    final bool hasDetailedData = <String>[
      _cepController.text,
      _logradouroController.text,
      _numeroController.text,
      _complementoController.text,
      _bairroController.text,
      _cidadeController.text,
      _ufController.text,
      _observacoesController.text,
    ].any((String value) => value.trim().isNotEmpty);
    return hasDetailedData ? 'COMPLETO' : 'SIMPLES';
  }

  int _percentualQualidade(String tipoCadastro) {
    final bool isComplete = tipoCadastro == 'COMPLETO';
    final List<_QualidadeItem> items =
        isComplete
            ? <_QualidadeItem>[
              _QualidadeItem(20, _nomeController.text.trim().isNotEmpty),
              _QualidadeItem(20, _documentoController.text.trim().isNotEmpty),
              _QualidadeItem(
                15,
                _telefoneController.text.replaceAll(RegExp(r'\D'), '').length >=
                    8,
              ),
              _QualidadeItem(10, _emailValido(_emailController.text.trim())),
              _QualidadeItem(10, _cepController.text.trim().isNotEmpty),
              _QualidadeItem(
                20,
                <String>[
                  _logradouroController.text,
                  _numeroController.text,
                  _bairroController.text,
                  _cidadeController.text,
                  _ufController.text,
                ].every((String value) => value.trim().isNotEmpty),
              ),
              _QualidadeItem(5, _observacoesController.text.trim().isNotEmpty),
            ]
            : <_QualidadeItem>[
              _QualidadeItem(35, _nomeController.text.trim().isNotEmpty),
              _QualidadeItem(30, _documentoController.text.trim().isNotEmpty),
              _QualidadeItem(
                20,
                _telefoneController.text.replaceAll(RegExp(r'\D'), '').length >=
                    8,
              ),
              _QualidadeItem(15, _emailValido(_emailController.text.trim())),
            ];
    return items
        .where((item) => item.ok)
        .fold<int>(0, (int total, _QualidadeItem item) => total + item.peso);
  }

  bool _emailValido(String value) {
    if (value.isEmpty) {
      return false;
    }
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  Future<void> _enviarCadastro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_aceitaTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirme os termos para concluir o auto-cadastro.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String token = _query('token');
    final String idUnicoDaEmpresa = _query('idUnicoDaEmpresa');
    final String documentoAtual = _documentoController.text.trim();
    final String tipoCadastro = _tipoCadastroAtual();

    if (idUnicoDaEmpresa.isEmpty) {
      _mostrarAviso('Link inválido: idUnicoDaEmpresa não informado.');
      return;
    }

    if (token.isEmpty) {
      _mostrarAviso('Link inválido: token de auto-cadastro ausente.');
      return;
    }

    if (_isValidatingToken) {
      _mostrarAviso('Aguarde a validação do link.');
      return;
    }

    if (_linkJaUtilizado) {
      _mostrarAviso(
        'Este link já foi utilizado. Solicite um novo link atualizado.',
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final AutoCustomerPublicResponse response = await _publicService
          .enviarAutoCadastro(
            idUnicoDaEmpresa: idUnicoDaEmpresa,
            token: token,
            documentoOriginal: _documentoOriginal,
            tipoPessoa: _tipoPessoa,
            tipoCadastro: tipoCadastro,
            percentualQualidadeCadastro: _percentualQualidade(tipoCadastro),
            documento: documentoAtual,
            nome: _nomeController.text.trim(),
            telefone: _telefoneController.text.trim(),
            email: _emailController.text.trim(),
            cep: _cepController.text.trim(),
            logradouro: _logradouroController.text.trim(),
            numero: _numeroController.text.trim(),
            complemento: _complementoController.text.trim(),
            bairro: _bairroController.text.trim(),
            cidade: _cidadeController.text.trim(),
            uf: _ufController.text.trim(),
            observacoes: _observacoesController.text.trim(),
            origem: widget.initialUri.toString(),
          );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201) {
        setState(() {
          _documentoOriginal = documentoAtual;
          _linkJaUtilizado = true;
          _cadastroEnviadoComSucesso = true;
          _mensagemSucesso =
              response.message.isNotEmpty
                  ? response.message
                  : _mensagemDoBody(
                    response.body,
                    fallback:
                        'Recebemos seu auto-cadastro com sucesso. Nossa equipe vai validar os dados.',
                  );
        });
        return;
      }

      if (response.statusCode == 409 || response.statusCode == 410) {
        setState(() {
          _linkJaUtilizado = true;
          _mensagemLinkIndisponivel =
              response.message.isNotEmpty
                  ? response.message
                  : _mensagemDoBody(
                    response.body,
                    fallback:
                        'Este link já foi atualizado/consumido. Solicite um novo link.',
                  );
        });
        _mostrarAviso(_mensagemLinkIndisponivel);
        return;
      }

      _mostrarAviso(
        response.message.isNotEmpty
            ? response.message
            : _mensagemDoBody(
              response.body,
              fallback:
                  'Não foi possível concluir o auto-cadastro (HTTP ${response.statusCode}).',
            ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _mostrarAviso('Falha ao enviar auto-cadastro. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _dec(label),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String token = _query('token', fallback: '-');
    final String idUnicoDaEmpresa = _query('idUnicoDaEmpresa', fallback: '-');

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child:
                    _cadastroEnviadoComSucesso
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.verified_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Dados enviados com sucesso',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(_mensagemSucesso),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              child: Text(
                                'Pode fechar esta guia do navegador.',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        )
                        : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Auto-cadastro de cliente',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Revise os dados atuais e ajuste o que for necessário antes de concluir.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: <Widget>[
                                  Chip(label: Text('Token: $token')),
                                  Chip(
                                    label: Text('Empresa: $idUnicoDaEmpresa'),
                                  ),
                                  Chip(label: Text('Tipo: $_tipoPessoa')),
                                ],
                              ),
                              if (_isValidatingToken) ...<Widget>[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Validando link de auto-cadastro...',
                                          style: TextStyle(
                                            color:
                                                theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_linkJaUtilizado) ...<Widget>[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  child: Text(
                                    _mensagemLinkIndisponivel,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              _field(
                                _nomeController,
                                'Nome completo / Razão social',
                                enabled: !_linkJaUtilizado,
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _field(
                                _documentoController,
                                'Documento (CPF/CNPJ)',
                                enabled: !_linkJaUtilizado,
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _field(
                                _telefoneController,
                                'Telefone / WhatsApp',
                                enabled: !_linkJaUtilizado,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _field(
                                _emailController,
                                'E-mail',
                                enabled: !_linkJaUtilizado,
                                keyboardType: TextInputType.emailAddress,
                                validator: (String? value) {
                                  final String email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return null;
                                  }
                                  if (!_emailValido(email)) {
                                    return 'E-mail inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Endereço',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: <Widget>[
                                  SizedBox(
                                    width: 180,
                                    child: _field(
                                      _cepController,
                                      'CEP',
                                      enabled: !_linkJaUtilizado,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 220,
                                    child: _field(
                                      _ufController,
                                      'UF',
                                      enabled: !_linkJaUtilizado,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 420,
                                    child: _field(
                                      _cidadeController,
                                      'Cidade',
                                      enabled: !_linkJaUtilizado,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _field(
                                _logradouroController,
                                'Logradouro',
                                enabled: !_linkJaUtilizado,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: <Widget>[
                                  SizedBox(
                                    width: 220,
                                    child: _field(
                                      _numeroController,
                                      'Número',
                                      enabled: !_linkJaUtilizado,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 320,
                                    child: _field(
                                      _bairroController,
                                      'Bairro',
                                      enabled: !_linkJaUtilizado,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 320,
                                    child: _field(
                                      _complementoController,
                                      'Complemento',
                                      enabled: !_linkJaUtilizado,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _field(
                                _observacoesController,
                                'Observações',
                                enabled: !_linkJaUtilizado,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 14),
                              CheckboxListTile(
                                value: _aceitaTermos,
                                contentPadding: EdgeInsets.zero,
                                onChanged:
                                    _linkJaUtilizado
                                        ? null
                                        : (bool? value) {
                                          setState(() {
                                            _aceitaTermos = value ?? false;
                                          });
                                        },
                                title: const Text(
                                  'Confirmo que os dados informados são verdadeiros.',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed:
                                    _isSending ||
                                            _isValidatingToken ||
                                            _linkJaUtilizado
                                        ? null
                                        : _enviarCadastro,
                                icon:
                                    _isSending
                                        ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                label: Text(
                                  _isSending
                                      ? 'Enviando...'
                                      : 'Salvar cadastro',
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QualidadeItem {
  const _QualidadeItem(this.peso, this.ok);

  final int peso;
  final bool ok;
}
