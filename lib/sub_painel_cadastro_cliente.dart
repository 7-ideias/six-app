import 'package:appplanilha/core/services/auth_service.dart';
import 'package:appplanilha/core/services/auto_customer_token_service.dart';
import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mock_cadastros_store.dart';

class SubPainelCadastroCliente extends SubPainelWebGeneral {
  const SubPainelCadastroCliente({
    super.key,
    required super.body,
    required super.textoDaAppBar,
  });
}

void showSubPainelCadastroCliente(BuildContext context, String textoDaAppBar) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return SubPainelCadastroCliente(
        textoDaAppBar: textoDaAppBar,
        body: const CadastroClienteWebBody(),
      );
    },
  );
}

class CadastroClienteWebBody extends StatefulWidget {
  const CadastroClienteWebBody({super.key});

  @override
  State<CadastroClienteWebBody> createState() => _CadastroClienteWebBodyState();
}

class _CadastroClienteWebBodyState extends State<CadastroClienteWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AutoCustomerTokenService _autoCustomerTokenService =
      AutoCustomerTokenService();

  final TextEditingController _idExternoController = TextEditingController(
    text: 'CLI-',
  );
  final TextEditingController _dataCadastroController = TextEditingController(
    text: _formatDateTime(DateTime.now()),
  );
  final TextEditingController _idUnicoDaEmpresaController =
      TextEditingController();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _nomeFantasiaController = TextEditingController();
  final TextEditingController _tipoPessoaController = TextEditingController(
    text: 'PF',
  );
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _inscricaoEstadualController =
      TextEditingController();
  final TextEditingController _dataNascimentoFundacaoController =
      TextEditingController(text: _formatDate(DateTime(1990, 1, 1)));

  final TextEditingController _telefoneController = TextEditingController(
    text: '+55',
  );
  final TextEditingController _whatsappController = TextEditingController(
    text: '+55',
  );
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();
  final TextEditingController _paisController = TextEditingController(
    text: 'BR',
  );

  final TextEditingController _limiteCreditoController = TextEditingController(
    text: '0,00',
  );
  final TextEditingController _prazoPagamentoController = TextEditingController(
    text: '30',
  );
  final TextEditingController _descontoPadraoController = TextEditingController(
    text: '0,00',
  );
  final TextEditingController _scoreCreditoController = TextEditingController(
    text: '500',
  );

  final TextEditingController _canalEnvioLinkController = TextEditingController(
    text: 'WhatsApp',
  );
  final TextEditingController _destinoEnvioLinkController =
      TextEditingController();
  final TextEditingController _linkAutoCadastroController =
      TextEditingController();
  final TextEditingController
  _mensagemConviteController = TextEditingController(
    text:
        'Olá! Use este link para concluir seu auto-cadastro e liberar compras no crediário.',
  );

  final TextEditingController _observacoesController = TextEditingController();

  bool _clienteAtivo = true;
  bool _autorizaContato = true;
  bool _aceitaWhatsapp = true;
  bool _aceitaEmail = true;
  bool _permiteCompraPrazo = true;
  bool _bloqueadoInadimplencia = false;
  bool _habilitarAutoCadastro = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarIdUnicoDaEmpresa();
  }

  Future<void> _carregarIdUnicoDaEmpresa() async {
    final String empresaId = (await AuthService().getEmpresaId())?.trim() ?? '';
    if (!mounted || empresaId.isEmpty) {
      return;
    }

    setState(() {
      _idUnicoDaEmpresaController.text = empresaId;
    });
  }

  static String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _formatDateTime(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    final String second = value.second.toString().padLeft(2, '0');
    return '${value.year}-$month-$day'
        'T$hour:$minute:$second';
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _idExternoController,
      _dataCadastroController,
      _idUnicoDaEmpresaController,
      _nomeController,
      _nomeFantasiaController,
      _tipoPessoaController,
      _documentoController,
      _inscricaoEstadualController,
      _dataNascimentoFundacaoController,
      _telefoneController,
      _whatsappController,
      _emailController,
      _cepController,
      _logradouroController,
      _numeroController,
      _complementoController,
      _bairroController,
      _cidadeController,
      _ufController,
      _paisController,
      _limiteCreditoController,
      _prazoPagamentoController,
      _descontoPadraoController,
      _scoreCreditoController,
      _canalEnvioLinkController,
      _destinoEnvioLinkController,
      _linkAutoCadastroController,
      _mensagemConviteController,
      _observacoesController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    IconData? icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: _inputDecoration(
        context,
        label,
        icon: icon,
        hintText: hintText,
      ),
      validator:
          requiredField
              ? (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              }
              : null,
      onTap: onTap,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool includeTime,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _inputDecoration(
        context,
        label,
        icon: icon,
        suffixIcon: IconButton(
          onPressed:
              () => _selecionarData(controller, includeTime: includeTime),
          icon: const Icon(Icons.calendar_today_outlined),
        ),
      ),
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      },
      onTap: () => _selecionarData(controller, includeTime: includeTime),
      onChanged: (_) => setState(() {}),
    );
  }

  Future<void> _selecionarData(
    TextEditingController controller, {
    required bool includeTime,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    DateTime finalValue = pickedDate;

    if (includeTime) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (pickedTime != null) {
        finalValue = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
      controller.text = _formatDateTime(finalValue);
    } else {
      controller.text = _formatDate(finalValue);
    }

    setState(() {});
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Cadastro de cliente',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Cadastro completo para vendas, crediário e auto-cadastro por link.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.credit_score, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'Salvando...' : 'Pronto para cadastro',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.16)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.62),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: (bool newValue) {
              onChanged(newValue);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 12),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(
                  bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
                ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.54),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  double _toDouble(TextEditingController controller) {
    String raw = controller.text.trim().replaceAll(' ', '');

    if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else if (raw.contains(',')) {
      raw = raw.replaceAll(',', '.');
    }

    return double.tryParse(raw) ?? 0.0;
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _fallbackErroGeracaoLink(AutoCustomerTokenApiResponse response) {
    switch (response.statusCode) {
      case 403:
        return 'Usuário sem vínculo com a empresa selecionada.';
      case 404:
        return 'Empresa inválida ou não encontrada.';
      case 400:
        return 'Dados inválidos para gerar o link.';
      case 500:
        return 'Falha ao gerar token de auto-cadastro.';
      default:
        return 'Erro ao gerar link (HTTP ${response.statusCode}).';
    }
  }

  Future<void> _gerarLinkAutoCadastro() async {
    final String empresaId = _idUnicoDaEmpresaController.text.trim();
    if (empresaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o ID único da empresa para gerar o link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final GlobalKey<FormState> modalFormKey = GlobalKey<FormState>();
    final TextEditingController tipoPessoaController = TextEditingController(
      text:
          _tipoPessoaController.text.trim().isEmpty
              ? 'PF'
              : _tipoPessoaController.text.trim().toUpperCase(),
    );
    final TextEditingController baseUrlController = TextEditingController();
    String tokenGerado = '';
    String linkGerado = '';
    String expiracaoGerada = '';
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setModalState,
          ) {
            Future<void> gerar() async {
              if (!modalFormKey.currentState!.validate()) {
                return;
              }

              setModalState(() {
                isLoading = true;
              });

              try {
                final AutoCustomerTokenApiResponse response =
                    await _autoCustomerTokenService.gerarToken(
                      idUnicoDaEmpresa: empresaId,
                      tipoPessoa:
                          tipoPessoaController.text.trim().toUpperCase(),
                      validadeMinutos: 1440,
                      baseUrl: baseUrlController.text.trim(),
                    );

                if (!mounted) {
                  return;
                }

                final String message =
                    response.message.trim().isNotEmpty
                        ? response.message.trim()
                        : (response.isSuccess
                            ? 'Token de auto-cadastro criado com sucesso.'
                            : _fallbackErroGeracaoLink(response));

                if (!response.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                await Clipboard.setData(ClipboardData(text: response.link));

                setState(() {
                  _tipoPessoaController.text =
                      tipoPessoaController.text.trim().toUpperCase();
                  _linkAutoCadastroController.text = response.link;
                });

                setModalState(() {
                  tokenGerado = response.token;
                  linkGerado = response.link;
                  expiracaoGerada = response.expiracao;
                });

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$message Link copiado para a área de transferência.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Falha ao gerar link: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } finally {
                if (mounted) {
                  setModalState(() {
                    isLoading = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Gerar link de auto-cadastro'),
              content: SizedBox(
                width: 620,
                child: Form(
                  key: modalFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          initialValue:
                              tipoPessoaController.text.trim().toUpperCase() ==
                                      'PJ'
                                  ? 'PJ'
                                  : 'PF',
                          decoration: const InputDecoration(
                            labelText: 'Tipo pessoa',
                            border: OutlineInputBorder(),
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'PF',
                              child: Text('PF'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'PJ',
                              child: Text('PJ'),
                            ),
                          ],
                          onChanged: (String? value) {
                            tipoPessoaController.text = value ?? 'PF';
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: '1440 minutos',
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Validade fixa',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: baseUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Base URL (opcional)',
                            hintText:
                                'http://localhost:39441/cliente/auto-cadastro',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (linkGerado.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 18),
                          SelectableText('Token: $tokenGerado'),
                          const SizedBox(height: 8),
                          SelectableText('Expiração: $expiracaoGerada'),
                          const SizedBox(height: 8),
                          SelectableText('Link: $linkGerado'),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: linkGerado),
                              );
                              if (!mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Link copiado com sucesso.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_outlined),
                            label: const Text('Copiar link'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fechar'),
                ),
                FilledButton.icon(
                  onPressed: isLoading ? null : gerar,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.link_outlined),
                  label: Text(isLoading ? 'Gerando...' : 'Gerar link'),
                ),
              ],
            );
          },
        );
      },
    );

    tipoPessoaController.dispose();
    baseUrlController.dispose();
  }

  Future<void> _copiarLinkAutoCadastro() async {
    if (_linkAutoCadastroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gere o link antes de copiar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: _linkAutoCadastroController.text.trim()),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Link de auto-cadastro copiado para a área de transferência.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _simularEnvioLink() {
    if (_linkAutoCadastroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gere o link antes de enviar para o cliente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String destino = _destinoEnvioLinkController.text.trim();
    if (destino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o destino para envio do link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String canal = _canalEnvioLinkController.text.trim();
    final String mensagem = _mensagemConviteController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Link enviado via $canal para $destino. Mensagem: $mensagem',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ClienteMock _montarCliente() {
    return ClienteMock(
      id: MockCadastrosStore.proximoClienteId(),
      idExterno: _idExternoController.text.trim(),
      dataCadastro: _dataCadastroController.text.trim(),
      nome: _nomeController.text.trim(),
      nomeFantasia: _nomeFantasiaController.text.trim(),
      tipoPessoa: _tipoPessoaController.text.trim().toUpperCase(),
      telefone: _telefoneController.text.trim(),
      whatsapp: _whatsappController.text.trim(),
      email: _emailController.text.trim(),
      documento: _documentoController.text.trim(),
      inscricaoEstadual: _inscricaoEstadualController.text.trim(),
      dataNascimentoFundacao: _dataNascimentoFundacaoController.text.trim(),
      cep: _cepController.text.trim(),
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      complemento: _complementoController.text.trim(),
      bairro: _bairroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      uf: _ufController.text.trim(),
      pais: _paisController.text.trim(),
      limiteCredito: _toDouble(_limiteCreditoController),
      prazoPagamentoDias:
          int.tryParse(_prazoPagamentoController.text.trim()) ?? 30,
      descontoPadrao: _toDouble(_descontoPadraoController),
      scoreCredito: int.tryParse(_scoreCreditoController.text.trim()) ?? 500,
      clienteAtivo: _clienteAtivo,
      autorizaContato: _autorizaContato,
      aceitaWhatsapp: _aceitaWhatsapp,
      aceitaEmail: _aceitaEmail,
      permiteCompraPrazo: _permiteCompraPrazo,
      bloqueadoInadimplencia: _bloqueadoInadimplencia,
      linkAutoCadastro: _linkAutoCadastroController.text.trim(),
      observacoes: _observacoesController.text.trim(),
    );
  }

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ClienteMock cliente = _montarCliente();
      MockCadastrosStore.adicionarCliente(cliente);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Cliente cadastrado'),
            content: SingleChildScrollView(
              child: Text(
                'Cadastro salvo com sucesso para ${cliente.nome}.\n'
                'Limite de crédito: R\$ ${_formatCurrency(cliente.limiteCredito)}\n'
                'Cliente apto para compras a prazo: '
                '${cliente.permiteCompraPrazo && !cliente.bloqueadoInadimplencia ? 'Sim' : 'Não'}',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildResumoCard(BuildContext context) {
    final String nome =
        _nomeController.text.trim().isEmpty ? '-' : _nomeController.text.trim();
    final String documento =
        _documentoController.text.trim().isEmpty
            ? '-'
            : _documentoController.text.trim();

    return _buildSectionCard(
      context: context,
      title: 'Resumo do cadastro',
      subtitle: 'Conferência rápida antes de salvar.',
      icon: Icons.description_outlined,
      child: Column(
        children: <Widget>[
          _buildInfoRow('Nome', nome),
          _buildInfoRow('Documento', documento),
          _buildInfoRow(
            'Limite crédito',
            'R\$ ${_formatCurrency(_toDouble(_limiteCreditoController))}',
          ),
          _buildInfoRow(
            'Condição',
            _bloqueadoInadimplencia
                ? 'Bloqueado por inadimplência'
                : (_permiteCompraPrazo
                    ? 'Compra a prazo liberada'
                    : 'Somente à vista'),
          ),
          _buildInfoRow(
            'Auto-cadastro',
            _habilitarAutoCadastro ? 'Habilitado' : 'Desabilitado',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          const Text(
            'Cadastro completo do cliente com dados de crédito e auto-cadastro por link.',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: _isLoading ? null : _salvarCliente,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: Text(_isLoading ? 'Salvando...' : 'Salvar cliente'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool telaGrande = constraints.maxWidth >= 1120;
        final bool telaMedia = constraints.maxWidth >= 760;

        final Widget identidadeCadastro = _buildSectionCard(
          context: context,
          title: 'Identidade do cadastro',
          subtitle: 'Rastreabilidade e vínculo interno do cliente.',
          icon: Icons.badge_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 240 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _idExternoController,
                  label: 'ID cliente (interno)',
                  icon: Icons.vpn_key_outlined,
                  hintText: 'CLI-0001',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 260 : (telaMedia ? 260 : double.infinity),
                child: _buildDateField(
                  context: context,
                  controller: _dataCadastroController,
                  label: 'Data do cadastro',
                  icon: Icons.schedule_outlined,
                  includeTime: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 200 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _tipoPessoaController,
                  label: 'Tipo pessoa',
                  icon: Icons.apartment_outlined,
                  hintText: 'PF ou PJ',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : (telaMedia ? 320 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _idUnicoDaEmpresaController,
                  label: 'ID único da empresa',
                  icon: Icons.business_outlined,
                  hintText: 'Obrigatório para auto-cadastro público',
                  requiredField: _habilitarAutoCadastro,
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : (telaMedia ? 300 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _nomeController,
                  label: 'Nome completo / Razão social',
                  icon: Icons.person_outline,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 280 : (telaMedia ? 280 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _nomeFantasiaController,
                  label: 'Nome fantasia / Apelido',
                  icon: Icons.tag_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 240 : (telaMedia ? 260 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _documentoController,
                  label: 'CPF/CNPJ',
                  icon: Icons.badge_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 240 : (telaMedia ? 260 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _inscricaoEstadualController,
                  label: 'Inscrição estadual',
                  icon: Icons.verified_user_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 240 : (telaMedia ? 240 : double.infinity),
                child: _buildDateField(
                  context: context,
                  controller: _dataNascimentoFundacaoController,
                  label: 'Nascimento/Fundação',
                  icon: Icons.cake_outlined,
                  includeTime: false,
                ),
              ),
            ],
          ),
        );

        final Widget contatoCliente = _buildSectionCard(
          context: context,
          title: 'Contato e relacionamento',
          subtitle: 'Canais oficiais para vendas e comunicação.',
          icon: Icons.phone_in_talk_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width:
                        telaGrande ? 250 : (telaMedia ? 260 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _telefoneController,
                      label: 'Telefone principal',
                      icon: Icons.phone_outlined,
                      requiredField: true,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 250 : (telaMedia ? 260 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _whatsappController,
                      label: 'WhatsApp',
                      icon: Icons.chat_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 360 : (telaMedia ? 320 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _emailController,
                      label: 'E-mail',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: telaGrande ? 300 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Cliente ativo',
                      subtitle:
                          'Define se o cadastro pode participar de vendas.',
                      value: _clienteAtivo,
                      onChanged: (bool value) => _clienteAtivo = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 300 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Autoriza contato comercial',
                      subtitle:
                          'Permite lembretes de orçamento, OS e cobrança.',
                      value: _autorizaContato,
                      onChanged: (bool value) => _autorizaContato = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 300 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Canal WhatsApp',
                      subtitle: 'Define preferência pelo canal WhatsApp.',
                      value: _aceitaWhatsapp,
                      onChanged: (bool value) => _aceitaWhatsapp = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 300 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Canal e-mail',
                      subtitle: 'Autoriza envio de comunicações por e-mail.',
                      value: _aceitaEmail,
                      onChanged: (bool value) => _aceitaEmail = value,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final Widget enderecoCliente = _buildSectionCard(
          context: context,
          title: 'Endereço',
          subtitle: 'Dados para entrega, cobrança e emissão de documentos.',
          icon: Icons.location_on_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 200 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _cepController,
                  label: 'CEP',
                  icon: Icons.pin_drop_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 360 : (telaMedia ? 340 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _logradouroController,
                  label: 'Logradouro',
                  icon: Icons.home_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 150 : (telaMedia ? 160 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _numeroController,
                  label: 'Número',
                  icon: Icons.format_list_numbered,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 280 : (telaMedia ? 320 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _complementoController,
                  label: 'Complemento',
                  icon: Icons.apartment_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 260 : (telaMedia ? 260 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _bairroController,
                  label: 'Bairro',
                  icon: Icons.location_city_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 280 : (telaMedia ? 280 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _cidadeController,
                  label: 'Cidade',
                  icon: Icons.location_city,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 140 : (telaMedia ? 140 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _ufController,
                  label: 'UF',
                  icon: Icons.map_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 180 : (telaMedia ? 180 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _paisController,
                  label: 'País',
                  icon: Icons.flag_outlined,
                  requiredField: true,
                ),
              ),
            ],
          ),
        );

        final Widget financeiroCredito = _buildSectionCard(
          context: context,
          title: 'Financeiro e limite de crédito',
          subtitle: 'Parâmetros de compra a prazo e política de cobrança.',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width:
                        telaGrande ? 250 : (telaMedia ? 260 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _limiteCreditoController,
                      label: 'Limite de crédito (R\$)',
                      icon: Icons.credit_score_outlined,
                      keyboardType: TextInputType.number,
                      requiredField: true,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 230 : (telaMedia ? 230 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _prazoPagamentoController,
                      label: 'Prazo pagamento (dias)',
                      icon: Icons.timelapse_outlined,
                      keyboardType: TextInputType.number,
                      requiredField: true,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 230 : (telaMedia ? 230 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _descontoPadraoController,
                      label: 'Desconto padrão (%)',
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 190 : (telaMedia ? 200 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _scoreCreditoController,
                      label: 'Score de crédito',
                      icon: Icons.query_stats_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Permite compra a prazo',
                      subtitle:
                          'Libera uso do limite de crédito em novas vendas.',
                      value: _permiteCompraPrazo,
                      onChanged: (bool value) => _permiteCompraPrazo = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Bloqueado por inadimplência',
                      subtitle:
                          'Impede novas compras até regularização financeira.',
                      value: _bloqueadoInadimplencia,
                      onChanged:
                          (bool value) => _bloqueadoInadimplencia = value,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final Widget autoCadastro = _buildSectionCard(
          context: context,
          title: 'Auto-cadastro por link',
          subtitle:
              'Gere, copie e envie o link para o cliente finalizar cadastro.',
          icon: Icons.link_outlined,
          child: Column(
            children: <Widget>[
              _buildSwitchTile(
                context: context,
                title: 'Habilitar auto-cadastro',
                subtitle:
                    'Quando ativo, o cliente recebe um link para revisar e completar os dados.',
                value: _habilitarAutoCadastro,
                onChanged: (bool value) => _habilitarAutoCadastro = value,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _canalEnvioLinkController,
                      label: 'Canal de envio',
                      icon: Icons.alt_route_outlined,
                      hintText: 'WhatsApp, E-mail, SMS',
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 360 : (telaMedia ? 320 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _destinoEnvioLinkController,
                      label: 'Destino do envio',
                      icon: Icons.send_outlined,
                      hintText: '+55... ou email@dominio.com',
                      requiredField: _habilitarAutoCadastro,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context: context,
                controller: _linkAutoCadastroController,
                label: 'Link de auto-cadastro',
                icon: Icons.link,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context: context,
                controller: _mensagemConviteController,
                label: 'Mensagem de convite',
                icon: Icons.message_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed:
                        _habilitarAutoCadastro ? _gerarLinkAutoCadastro : null,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Gerar link'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _habilitarAutoCadastro ? _copiarLinkAutoCadastro : null,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar link'),
                  ),
                  FilledButton.icon(
                    onPressed:
                        _habilitarAutoCadastro ? _simularEnvioLink : null,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Enviar para cliente'),
                  ),
                ],
              ),
            ],
          ),
        );

        final Widget observacoes = _buildSectionCard(
          context: context,
          title: 'Observações comerciais',
          subtitle: 'Notas internas para atendimento e pós-venda.',
          icon: Icons.notes_outlined,
          child: _buildTextField(
            context: context,
            controller: _observacoesController,
            label: 'Observações',
            icon: Icons.note_alt_outlined,
            maxLines: 4,
          ),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    if (telaMedia)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            flex: telaGrande ? 7 : 8,
                            child: Column(
                              children: <Widget>[
                                identidadeCadastro,
                                const SizedBox(height: 20),
                                contatoCliente,
                                const SizedBox(height: 20),
                                enderecoCliente,
                                const SizedBox(height: 20),
                                financeiroCredito,
                                const SizedBox(height: 20),
                                autoCadastro,
                                const SizedBox(height: 20),
                                observacoes,
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: telaGrande ? 4 : 3,
                            child: _buildResumoCard(context),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: <Widget>[
                          identidadeCadastro,
                          const SizedBox(height: 20),
                          contatoCliente,
                          const SizedBox(height: 20),
                          enderecoCliente,
                          const SizedBox(height: 20),
                          financeiroCredito,
                          const SizedBox(height: 20),
                          autoCadastro,
                          const SizedBox(height: 20),
                          observacoes,
                          const SizedBox(height: 20),
                          _buildResumoCard(context),
                        ],
                      ),
                    const SizedBox(height: 24),
                    _buildActionsBar(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
