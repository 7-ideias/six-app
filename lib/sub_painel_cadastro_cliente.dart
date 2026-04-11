import 'dart:convert';

import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';

import 'core/services/cliente_local_service.dart';
import 'data/models/cliente_cadastro_model.dart';
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
  final ClienteLocalService _clienteLocalService = ClienteLocalService();

  final TextEditingController _idExternoController =
      TextEditingController(text: 'CLI-0001');
  final TextEditingController _idAtualizacaoController =
      TextEditingController(text: 'CLI-ID-0001');
  final TextEditingController _dataCadastroController =
      TextEditingController(text: _formatDateTime(DateTime.now()));
  final TextEditingController _idiomaController =
      TextEditingController(text: 'pt-BR');
  final TextEditingController _fusoController =
      TextEditingController(text: 'America/Sao_Paulo');
  final TextEditingController _statusController =
      TextEditingController(text: 'ATIVO');

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _nomeSocialController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController(text: '1990-01-01');
  final TextEditingController _observacoesController = TextEditingController();

  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _paisController = TextEditingController(text: 'BR');

  final TextEditingController _tipoDocumentoGlobalController =
      TextEditingController(text: 'CPF');
  final TextEditingController _numeroDocumentoGlobalController =
      TextEditingController();
  final TextEditingController _paisDocumentoController =
      TextEditingController(text: 'BR');
  final TextEditingController _nacionalidadeController =
      TextEditingController(text: 'Brasileira');

  final TextEditingController _moedaController = TextEditingController(text: 'BRL');
  final TextEditingController _limiteCreditoController =
      TextEditingController(text: '0,00');
  final TextEditingController _diaFechamentoController =
      TextEditingController(text: '10');
  final TextEditingController _metodoPagamentoController =
      TextEditingController(text: 'pix');
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _swiftController = TextEditingController();
  final TextEditingController _pixController = TextEditingController();

  final TextEditingController _fotoUrlController = TextEditingController();
  final TextEditingController _modoCapturaController =
      TextEditingController(text: 'upload');
  final TextEditingController _dataCapturaController =
      TextEditingController(text: _formatDateTime(DateTime.now()));
  final TextEditingController _hashFotoController = TextEditingController();

  bool _autorizaContato = true;
  bool _aceitaWhatsapp = true;
  bool _aceitaEmail = true;
  bool _aceitaSms = false;
  bool _incluirAgendaFinanceira = true;
  bool _podeReceberComunicados = true;
  bool _compartilharComFinanceiro = true;
  bool _compartilharComTecnico = true;
  bool _consentimentoLgpd = true;
  bool _consentimentoImagem = true;

  bool _isSaving = false;

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
      _idAtualizacaoController,
      _dataCadastroController,
      _idiomaController,
      _fusoController,
      _statusController,
      _nomeController,
      _nomeSocialController,
      _telefoneController,
      _emailController,
      _documentoController,
      _dataNascimentoController,
      _observacoesController,
      _logradouroController,
      _numeroController,
      _complementoController,
      _bairroController,
      _cidadeController,
      _estadoController,
      _cepController,
      _paisController,
      _tipoDocumentoGlobalController,
      _numeroDocumentoGlobalController,
      _paisDocumentoController,
      _nacionalidadeController,
      _moedaController,
      _limiteCreditoController,
      _diaFechamentoController,
      _metodoPagamentoController,
      _ibanController,
      _swiftController,
      _pixController,
      _fotoUrlController,
      _modoCapturaController,
      _dataCapturaController,
      _hashFotoController,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  double _toDouble(TextEditingController controller) {
    String raw = controller.text.trim();

    if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      raw = raw.replaceAll(',', '.');
    }

    return double.tryParse(raw) ?? 0;
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _tf({
    required TextEditingController c,
    required String l,
    required IconData i,
    bool req = false,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      decoration: _dec(l, i),
      validator: req
          ? (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            }
          : null,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _card(String title, String subtitle, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text(subtitle),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  ClienteCadastroRequest _postRequest() {
    return ClienteCadastroRequest(
      objInformacoesCadastro: ClienteInformacoesCadastro(
        idClienteExterno: _idExternoController.text.trim(),
        dataCadastro: _dataCadastroController.text.trim(),
        idiomaPreferido: _idiomaController.text.trim(),
        fusoHorario: _fusoController.text.trim(),
        status: _statusController.text.trim(),
      ),
      objPessoa: ClientePessoa(
        nome: _nomeController.text.trim(),
        nomeSocial: _nomeSocialController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim(),
        documento: _documentoController.text.trim(),
        dataNascimento: _dataNascimentoController.text.trim(),
        observacoes: _observacoesController.text.trim(),
      ),
      objEndereco: ClienteEndereco(
        logradouro: _logradouroController.text.trim(),
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
        cep: _cepController.text.trim(),
        pais: _paisController.text.trim(),
      ),
      objPreferenciasContato: ClientePreferenciasContato(
        autorizaContato: _autorizaContato,
        canalPreferido: _aceitaWhatsapp ? 'whatsapp' : 'email',
        aceitaWhatsapp: _aceitaWhatsapp,
        aceitaEmail: _aceitaEmail,
        aceitaSms: _aceitaSms,
      ),
      objIdentidadeGlobal: ClienteIdentidadeGlobal(
        tipoDocumento: _tipoDocumentoGlobalController.text.trim(),
        numeroDocumento: _numeroDocumentoGlobalController.text.trim(),
        paisDocumento: _paisDocumentoController.text.trim(),
        nacionalidade: _nacionalidadeController.text.trim(),
      ),
      objFinanceiro: ClienteFinanceiro(
        moedaPreferencial: _moedaController.text.trim().toUpperCase(),
        limiteCredito: _toDouble(_limiteCreditoController),
        diaFechamentoFatura: int.tryParse(_diaFechamentoController.text.trim()) ?? 10,
        metodoPagamentoPreferencial: _metodoPagamentoController.text.trim(),
        iban: _ibanController.text.trim(),
        swift: _swiftController.text.trim(),
        chavePix: _pixController.text.trim(),
        incluirNaAgendaFinanceira: _incluirAgendaFinanceira,
      ),
      objPermissoes: ClientePermissoes(
        podeReceberComunicados: _podeReceberComunicados,
        podeCompartilharDadosComFinanceiro: _compartilharComFinanceiro,
        podeCompartilharDadosComTecnico: _compartilharComTecnico,
        consentimentoLgpd: _consentimentoLgpd,
      ),
      objFotoRegistro: ClienteFotoRegistro(
        urlFoto: _fotoUrlController.text.trim(),
        modoCaptura: _modoCapturaController.text.trim(),
        dataCaptura: _dataCapturaController.text.trim(),
        hashArquivo: _hashFotoController.text.trim(),
        consentimentoUsoImagem: _consentimentoImagem,
      ),
    );
  }

  ClienteAtualizacaoRequest _putRequest() {
    final ClienteCadastroRequest base = _postRequest();

    return ClienteAtualizacaoRequest(
      idCliente: _idAtualizacaoController.text.trim(),
      objInformacoesCadastro: base.objInformacoesCadastro,
      objPessoa: base.objPessoa,
      objEndereco: base.objEndereco,
      objPreferenciasContato: base.objPreferenciasContato,
      objIdentidadeGlobal: base.objIdentidadeGlobal,
      objFinanceiro: base.objFinanceiro,
      objPermissoes: base.objPermissoes,
      objFotoRegistro: base.objFotoRegistro,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final ClienteCadastroRequest post = _postRequest();
      final ClienteAtualizacaoRequest put = _putRequest();

      final ClienteLocalResponse response =
          await _clienteLocalService.cadastrarCliente(post);

      final ClienteMock cliente = ClienteMock(
        id: MockCadastrosStore.proximoClienteId(),
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        email: _emailController.text.trim(),
        documento: _documentoController.text.trim(),
        observacoes: _observacoesController.text.trim(),
      );
      MockCadastrosStore.adicionarCliente(cliente);

      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final Object decoded = jsonDecode(response.body);

      final String message = 'Cliente cadastrado localmente (sem backend).\n\n'
          'POST (criação):\n${encoder.convert(post.toJson())}\n\n'
          'PUT (atualização):\n${encoder.convert(put.toJson())}\n\n'
          'Resposta mock do serviço:\n${encoder.convert(decoded)}';

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Cliente cadastrado'),
            content: SingleChildScrollView(child: Text(message)),
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
    } catch (e) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Erro ao cadastrar cliente'),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _card(
                  'Cadastro de cliente (global + financeiro)',
                  'Sem backend por enquanto, mas com payload completo de POST e PUT para futura integração.',
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      SizedBox(width: 220, child: _tf(c: _idExternoController, l: 'ID externo', i: Icons.vpn_key_outlined, req: true)),
                      SizedBox(width: 220, child: _tf(c: _idAtualizacaoController, l: 'ID atualização (PUT)', i: Icons.edit_note_outlined, req: true)),
                      SizedBox(width: 220, child: _tf(c: _idiomaController, l: 'Idioma', i: Icons.language_outlined, req: true)),
                      SizedBox(width: 260, child: _tf(c: _fusoController, l: 'Fuso horário', i: Icons.public_outlined, req: true)),
                      SizedBox(width: 180, child: _tf(c: _statusController, l: 'Status', i: Icons.toggle_on_outlined, req: true)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  'Dados pessoais e contato',
                  'Informações de identificação e relacionamento.',
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      SizedBox(width: 320, child: _tf(c: _nomeController, l: 'Nome', i: Icons.person_outline, req: true)),
                      SizedBox(width: 280, child: _tf(c: _nomeSocialController, l: 'Nome social', i: Icons.people_outline)),
                      SizedBox(width: 260, child: _tf(c: _documentoController, l: 'Documento', i: Icons.badge_outlined, req: true)),
                      SizedBox(width: 260, child: _tf(c: _telefoneController, l: 'Telefone', i: Icons.phone_outlined, req: true)),
                      SizedBox(width: 320, child: _tf(c: _emailController, l: 'E-mail', i: Icons.email_outlined)),
                      SizedBox(width: 220, child: _tf(c: _dataNascimentoController, l: 'Data nascimento', i: Icons.cake_outlined)),
                      SizedBox(width: 420, child: _tf(c: _observacoesController, l: 'Observações', i: Icons.note_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  'Endereço e identidade internacional',
                  'Campos para operação em múltiplos países.',
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      SizedBox(width: 280, child: _tf(c: _logradouroController, l: 'Logradouro', i: Icons.map_outlined)),
                      SizedBox(width: 120, child: _tf(c: _numeroController, l: 'Número', i: Icons.numbers_outlined)),
                      SizedBox(width: 220, child: _tf(c: _complementoController, l: 'Complemento', i: Icons.add_location_alt_outlined)),
                      SizedBox(width: 220, child: _tf(c: _bairroController, l: 'Bairro', i: Icons.location_city_outlined)),
                      SizedBox(width: 220, child: _tf(c: _cidadeController, l: 'Cidade', i: Icons.location_on_outlined)),
                      SizedBox(width: 130, child: _tf(c: _estadoController, l: 'Estado', i: Icons.flag_outlined)),
                      SizedBox(width: 180, child: _tf(c: _cepController, l: 'CEP', i: Icons.markunread_mailbox_outlined)),
                      SizedBox(width: 110, child: _tf(c: _paisController, l: 'País', i: Icons.public_outlined)),
                      SizedBox(width: 150, child: _tf(c: _tipoDocumentoGlobalController, l: 'Tipo doc', i: Icons.credit_card_outlined)),
                      SizedBox(width: 240, child: _tf(c: _numeroDocumentoGlobalController, l: 'Doc global', i: Icons.pin_outlined)),
                      SizedBox(width: 120, child: _tf(c: _paisDocumentoController, l: 'País doc', i: Icons.flag_circle_outlined)),
                      SizedBox(width: 220, child: _tf(c: _nacionalidadeController, l: 'Nacionalidade', i: Icons.travel_explore_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  'Financeiro + foto + consentimentos',
                  'Inclui dados para agenda financeira futura e auditoria de imagem.',
                  Column(
                    children: <Widget>[
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          SizedBox(width: 120, child: _tf(c: _moedaController, l: 'Moeda', i: Icons.currency_exchange_outlined)),
                          SizedBox(width: 180, child: _tf(c: _limiteCreditoController, l: 'Limite crédito', i: Icons.account_balance_wallet_outlined)),
                          SizedBox(width: 180, child: _tf(c: _diaFechamentoController, l: 'Dia fechamento', i: Icons.calendar_month_outlined)),
                          SizedBox(width: 220, child: _tf(c: _metodoPagamentoController, l: 'Método pagamento', i: Icons.payments_outlined)),
                          SizedBox(width: 240, child: _tf(c: _ibanController, l: 'IBAN', i: Icons.swap_horizontal_circle_outlined)),
                          SizedBox(width: 240, child: _tf(c: _swiftController, l: 'SWIFT', i: Icons.swap_calls_outlined)),
                          SizedBox(width: 260, child: _tf(c: _pixController, l: 'PIX', i: Icons.pix_outlined)),
                          SizedBox(width: 340, child: _tf(c: _fotoUrlController, l: 'URL foto', i: Icons.image_outlined)),
                          SizedBox(width: 180, child: _tf(c: _modoCapturaController, l: 'Modo captura', i: Icons.camera_alt_outlined)),
                          SizedBox(width: 280, child: _tf(c: _dataCapturaController, l: 'Data captura', i: Icons.timelapse_outlined)),
                          SizedBox(width: 260, child: _tf(c: _hashFotoController, l: 'Hash foto', i: Icons.fingerprint_outlined)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          FilterChip(
                            label: const Text('Autoriza contato'),
                            selected: _autorizaContato,
                            onSelected: (bool v) => setState(() => _autorizaContato = v),
                          ),
                          FilterChip(
                            label: const Text('WhatsApp'),
                            selected: _aceitaWhatsapp,
                            onSelected: (bool v) => setState(() => _aceitaWhatsapp = v),
                          ),
                          FilterChip(
                            label: const Text('E-mail'),
                            selected: _aceitaEmail,
                            onSelected: (bool v) => setState(() => _aceitaEmail = v),
                          ),
                          FilterChip(
                            label: const Text('SMS'),
                            selected: _aceitaSms,
                            onSelected: (bool v) => setState(() => _aceitaSms = v),
                          ),
                          FilterChip(
                            label: const Text('Agenda financeira'),
                            selected: _incluirAgendaFinanceira,
                            onSelected: (bool v) => setState(() => _incluirAgendaFinanceira = v),
                          ),
                          FilterChip(
                            label: const Text('Receber comunicados'),
                            selected: _podeReceberComunicados,
                            onSelected: (bool v) => setState(() => _podeReceberComunicados = v),
                          ),
                          FilterChip(
                            label: const Text('Compartilhar financeiro'),
                            selected: _compartilharComFinanceiro,
                            onSelected: (bool v) => setState(() => _compartilharComFinanceiro = v),
                          ),
                          FilterChip(
                            label: const Text('Compartilhar técnico'),
                            selected: _compartilharComTecnico,
                            onSelected: (bool v) => setState(() => _compartilharComTecnico = v),
                          ),
                          FilterChip(
                            label: const Text('Consentimento LGPD'),
                            selected: _consentimentoLgpd,
                            onSelected: (bool v) => setState(() => _consentimentoLgpd = v),
                          ),
                          FilterChip(
                            label: const Text('Consentimento imagem'),
                            selected: _consentimentoImagem,
                            onSelected: (bool v) => setState(() => _consentimentoImagem = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _salvar,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Salvando...' : 'Salvar cliente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
