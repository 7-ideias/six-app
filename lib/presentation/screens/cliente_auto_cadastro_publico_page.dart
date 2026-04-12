import 'dart:convert';

import 'package:appplanilha/core/services/auto_customer_public_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClienteAutoCadastroPublicoPage extends StatefulWidget {
  const ClienteAutoCadastroPublicoPage({super.key, required this.initialUri});

  final Uri initialUri;

  @override
  State<ClienteAutoCadastroPublicoPage> createState() =>
      _ClienteAutoCadastroPublicoPageState();
}

class _ClienteAutoCadastroPublicoPageState
    extends State<ClienteAutoCadastroPublicoPage> {
  static const String _usedTokensKey = 'auto_customer_used_tokens';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AutoCustomerPublicService _publicService = AutoCustomerPublicService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  bool _aceitaTermos = false;
  bool _isSending = false;
  bool _linkJaUtilizado = false;

  @override
  void initState() {
    super.initState();
    _precarregarDadosDoLink();
    _validarTokenJaUtilizadoLocalmente();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    _observacoesController.dispose();
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
    final String documento = _query('doc');
    if (documento.isNotEmpty) {
      _documentoController.text = documento;
    }
  }

  Future<void> _validarTokenJaUtilizadoLocalmente() async {
    final String token = _query('token');
    if (token.isEmpty) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> usedTokens =
        prefs.getStringList(_usedTokensKey) ?? <String>[];
    final bool used = usedTokens.contains(token);

    if (!mounted) {
      return;
    }

    setState(() {
      _linkJaUtilizado = used;
    });
  }

  Future<void> _marcarTokenComoUtilizado() async {
    final String token = _query('token');
    if (token.isEmpty) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> usedTokens =
        prefs.getStringList(_usedTokensKey) ?? <String>[];
    if (!usedTokens.contains(token)) {
      usedTokens.add(token);
      await prefs.setStringList(_usedTokensKey, usedTokens);
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
    final String tipo = _query('tipo', fallback: 'PF');
    final String documento = _documentoController.text.trim();

    if (idUnicoDaEmpresa.isEmpty) {
      _mostrarAviso('Link inválido: idUnicoDaEmpresa não informado.');
      return;
    }

    if (token.isEmpty) {
      _mostrarAviso('Link inválido: token de auto-cadastro ausente.');
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
            tipoPessoa: tipo,
            documento: documento,
            nome: _nomeController.text.trim(),
            telefone: _telefoneController.text.trim(),
            email: _emailController.text.trim(),
            enderecoCompleto: _enderecoController.text.trim(),
            observacoes: _observacoesController.text.trim(),
            origem: widget.initialUri,
          );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _marcarTokenComoUtilizado();
        setState(() {
          _linkJaUtilizado = true;
        });

        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cadastro enviado'),
              content: Text(
                _mensagemDoBody(
                  response.body,
                  fallback:
                      'Recebemos seu auto-cadastro com sucesso. Nossa equipe vai validar os dados.',
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
        return;
      }

      if (response.statusCode == 409 ||
          response.statusCode == 410 ||
          response.statusCode == 422) {
        await _marcarTokenComoUtilizado();
        setState(() {
          _linkJaUtilizado = true;
        });
        _mostrarAviso(
          _mensagemDoBody(
            response.body,
            fallback:
                'Este link já foi atualizado/consumido. Solicite um novo link.',
          ),
        );
        return;
      }

      _mostrarAviso(
        _mensagemDoBody(
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String token = _query('token', fallback: '-');
    final String tipo = _query('tipo', fallback: 'PF');
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
                child: Form(
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
                        'Página pública sem login. Complete seus dados para liberar atendimento e compras.',
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
                          Chip(label: Text('Empresa: $idUnicoDaEmpresa')),
                          Chip(label: Text('Tipo: $tipo')),
                        ],
                      ),
                      if (_linkJaUtilizado) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.error),
                          ),
                          child: Text(
                            'Link já atualizado/utilizado. Solicite um novo link para novo envio.',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo / Razão social',
                          border: OutlineInputBorder(),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _documentoController,
                        decoration: const InputDecoration(
                          labelText: 'Documento (CPF/CNPJ)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone / WhatsApp',
                          border: OutlineInputBorder(),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _enderecoController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço completo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _observacoesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CheckboxListTile(
                        value: _aceitaTermos,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool? value) {
                          setState(() {
                            _aceitaTermos = value ?? false;
                          });
                        },
                        title: const Text(
                          'Confirmo que os dados informados são verdadeiros.',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed:
                            _isSending || _linkJaUtilizado
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
                                : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isSending ? 'Enviando...' : 'Concluir auto-cadastro',
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
