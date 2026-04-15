import 'dart:convert';

import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'core/services/lib_core_services_colaborador_service.dart';
import 'data/models/lib_data_models_colaborador_model.dart';

class SubPainelCadastroColaborador extends SubPainelWebGeneral {
  const SubPainelCadastroColaborador({
    super.key,
    required super.body,
    required super.textoDaAppBar,
  });
}

void showSubPainelCadastroColaborador(
  BuildContext context,
  String textoDaAppBar,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return SubPainelCadastroColaborador(
        textoDaAppBar: textoDaAppBar,
        body: const CadastroColaboradorWebBody(),
      );
    },
  );
}

class CadastroColaboradorWebBody extends StatefulWidget {
  const CadastroColaboradorWebBody({super.key});

  @override
  State<CadastroColaboradorWebBody> createState() =>
      _CadastroColaboradorWebBodyState();
}

class _CadastroColaboradorWebBodyState
    extends State<CadastroColaboradorWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ColaboradorService _colaboradorService = ColaboradorService();

  final TextEditingController _fotoController = TextEditingController();
  final TextEditingController _celularDeAcessoController =
      TextEditingController(text: '+55');
  final TextEditingController _senhaAcessoController = TextEditingController(
    text: '123456',
  );
  final TextEditingController _idUnicoDoUsuarioController =
      TextEditingController(text: 'USR-');
  final TextEditingController _dataCadastroController = TextEditingController(
    text: _formatDateTime(DateTime.now()),
  );
  final TextEditingController _idUnicoDaEmpresaController =
      TextEditingController();
  final TextEditingController _idDeQuemCadastrouController =
      TextEditingController();

  final TextEditingController _idiomaPreferencialController =
      TextEditingController(text: 'pt-BR');
  final TextEditingController _fusoHorarioController = TextEditingController(
    text: 'America/Sao_Paulo',
  );
  final TextEditingController _statusController = TextEditingController(
    text: 'ATIVO',
  );
  final TextEditingController _idColaboradorAtualizacaoController =
      TextEditingController(text: 'COLAB-0001');

  final TextEditingController _dataDeContratacaoController =
      TextEditingController(text: _formatDate(DateTime.now()));
  final TextEditingController _salarioController = TextEditingController(
    text: '0,00',
  );

  final TextEditingController _departamentoController = TextEditingController(
    text: 'Operações',
  );
  final TextEditingController _tipoContratoController = TextEditingController(
    text: 'CLT',
  );
  final TextEditingController _centroDeCustoController = TextEditingController(
    text: 'Assistência Técnica',
  );

  final TextEditingController _atencaoController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _nomeDeGuerraController = TextEditingController();
  final TextEditingController _celularController = TextEditingController(
    text: '+55',
  );
  final TextEditingController _senhaPessoaController = TextEditingController(
    text: '000000',
  );
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _rgController = TextEditingController();
  final TextEditingController _dataNascimentoController = TextEditingController(
    text: '1990-01-01',
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoUnicoEmpresaController =
      TextEditingController();

  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _localidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();
  final TextEditingController _paisController = TextEditingController(
    text: 'BR',
  );

  final TextEditingController _cargoController = TextEditingController(
    text: 'Técnico',
  );
  final TextEditingController _comissaoProdutosController =
      TextEditingController(text: '0,00');
  final TextEditingController _comissaoVendasController = TextEditingController(
    text: '0,00',
  );
  final TextEditingController _comissaoAssistenciaController =
      TextEditingController(text: '0,00');

  final TextEditingController _tipoDocumentoGlobalController =
      TextEditingController(text: 'CPF');
  final TextEditingController _numeroDocumentoGlobalController =
      TextEditingController();
  final TextEditingController _paisDocumentoController = TextEditingController(
    text: 'BR',
  );
  final TextEditingController _nacionalidadeController = TextEditingController(
    text: 'Brasileira',
  );
  final TextEditingController _paisResidenciaController = TextEditingController(
    text: 'BR',
  );

  final TextEditingController _modoCapturaFotoController =
      TextEditingController(text: 'upload');
  final TextEditingController _hashFotoController = TextEditingController();
  final TextEditingController _dataCapturaFotoController =
      TextEditingController(text: _formatDateTime(DateTime.now()));

  final TextEditingController _moedaPagamentoController = TextEditingController(
    text: 'BRL',
  );
  final TextEditingController _periodicidadePagamentoController =
      TextEditingController(text: 'mensal');
  final TextEditingController _valorBasePagamentoController =
      TextEditingController(text: '0,00');
  final TextEditingController _metodoPagamentoController =
      TextEditingController(text: 'transferencia_bancaria');
  final TextEditingController _bancoController = TextEditingController();
  final TextEditingController _agenciaController = TextEditingController();
  final TextEditingController _contaController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _swiftController = TextEditingController();
  final TextEditingController _pixController = TextEditingController();
  final TextEditingController _diaPagamentoController = TextEditingController(
    text: '5',
  );

  final TextEditingController _escopoDadosController = TextEditingController(
    text: 'empresa',
  );

  bool _colaboradorAtivo = true;
  bool _podeFazerDevolucao = true;
  bool _podeCadastrarProduto = true;

  bool _podeVerEstoqueDeProduto = true;
  bool _podeEditarProduto = true;

  bool _fazVenda = false;
  bool _lancaServico = true;
  bool _ehTecnico = true;
  bool _podeEditarCliente = true;
  bool _geraRelatorioDeVendas = true;
  bool _podeReceberNoCaixa = true;
  bool _podeVerQuantoVendeu = true;
  bool _consentimentoUsoImagem = true;
  bool _incluirNaAgendaFinanceira = true;
  bool _podeAcessarAgendaFinanceira = true;
  bool _podeEditarDadosPagamento = false;
  bool _podeExportarRelatorios = true;
  bool _podeGerenciarPermissoes = false;

  bool _isLoading = false;
  String _perfilSelecionado = 'TÉCNICO';

  static const List<String> _perfis = <String>[
    'TÉCNICO',
    'COMERCIAL',
    'ATENDIMENTO',
    'ADMINISTRATIVO',
  ];

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
  void initState() {
    super.initState();
    _carregarContextoDaSessao();
  }

  Future<void> _carregarContextoDaSessao() async {
    final AuthService authService = AuthService();
    final String empresaId = (await authService.getEmpresaId())?.trim() ?? '';
    final String userId = (await authService.getUserId())?.trim() ?? '';
    if (!mounted) {
      return;
    }

    setState(() {
      if (empresaId.isNotEmpty) {
        _idUnicoDaEmpresaController.text = empresaId;
        if (_documentoUnicoEmpresaController.text.trim().isEmpty) {
          _documentoUnicoEmpresaController.text = empresaId;
        }
      }
      if (userId.isNotEmpty) {
        _idDeQuemCadastrouController.text = userId;
      }
    });
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _fotoController,
      _celularDeAcessoController,
      _senhaAcessoController,
      _idUnicoDoUsuarioController,
      _dataCadastroController,
      _idUnicoDaEmpresaController,
      _idDeQuemCadastrouController,
      _dataDeContratacaoController,
      _salarioController,
      _atencaoController,
      _nomeController,
      _nomeDeGuerraController,
      _celularController,
      _senhaPessoaController,
      _cpfController,
      _rgController,
      _dataNascimentoController,
      _emailController,
      _documentoUnicoEmpresaController,
      _cepController,
      _logradouroController,
      _complementoController,
      _bairroController,
      _localidadeController,
      _ufController,
      _cargoController,
      _comissaoProdutosController,
      _comissaoVendasController,
      _comissaoAssistenciaController,
      _idiomaPreferencialController,
      _fusoHorarioController,
      _statusController,
      _idColaboradorAtualizacaoController,
      _departamentoController,
      _tipoContratoController,
      _centroDeCustoController,
      _paisController,
      _tipoDocumentoGlobalController,
      _numeroDocumentoGlobalController,
      _paisDocumentoController,
      _nacionalidadeController,
      _paisResidenciaController,
      _modoCapturaFotoController,
      _hashFotoController,
      _dataCapturaFotoController,
      _moedaPagamentoController,
      _periodicidadePagamentoController,
      _valorBasePagamentoController,
      _metodoPagamentoController,
      _bancoController,
      _agenciaController,
      _contaController,
      _ibanController,
      _swiftController,
      _pixController,
      _diaPagamentoController,
      _escopoDadosController,
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
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
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
      firstDate: DateTime(1950),
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
                  Icons.group_add_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Cadastro de colaborador',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Conectado ao backend do SixBack para cadastrar técnicos e equipe operacional.',
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
                const Icon(Icons.wifi_tethering, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'Enviando...' : 'Pronto para envio',
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
            width: 100,
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

  void _aplicarPerfil(String perfil) {
    setState(() {
      _perfilSelecionado = perfil;

      switch (perfil) {
        case 'TÉCNICO':
          _cargoController.text = 'Técnico';
          _ehTecnico = true;
          _lancaServico = true;
          _fazVenda = false;
          _podeReceberNoCaixa = false;
          break;
        case 'COMERCIAL':
          _cargoController.text = 'Comercial';
          _ehTecnico = false;
          _lancaServico = false;
          _fazVenda = true;
          _podeReceberNoCaixa = true;
          break;
        case 'ATENDIMENTO':
          _cargoController.text = 'Atendimento';
          _ehTecnico = false;
          _lancaServico = false;
          _fazVenda = true;
          _podeReceberNoCaixa = true;
          break;
        case 'ADMINISTRATIVO':
          _cargoController.text = 'Administrativo';
          _ehTecnico = false;
          _lancaServico = false;
          _fazVenda = false;
          _podeReceberNoCaixa = true;
          break;
      }
    });
  }

  String _usoEsperado() {
    switch (_perfilSelecionado) {
      case 'TÉCNICO':
        return 'Responsável por execução e reparo';
      case 'COMERCIAL':
        return 'Responsável por vendas e relacionamento';
      case 'ATENDIMENTO':
        return 'Responsável por recepção e acompanhamento';
      case 'ADMINISTRATIVO':
        return 'Responsável por apoio interno e financeiro';
      default:
        return '-';
    }
  }

  ColaboradorCadastroRequest _montarRequest() {
    return ColaboradorCadastroRequest(
      idUnicoDaEmpresa: _idUnicoDaEmpresaController.text.trim(),
      idDeQuemCadastrou: _idDeQuemCadastrouController.text.trim(),
      foto: _fotoController.text.trim(),
      celularDeAcesso: _celularDeAcessoController.text.trim(),
      senhaParaPermitirOAcessoDoColaborador: _senhaAcessoController.text.trim(),
      objInformacoesDoCadastro: ColaboradorInformacoesCadastro(
        idUnicoDoUsuario: _idUnicoDoUsuarioController.text.trim(),
        dataCadastro: _dataCadastroController.text.trim(),
        idiomaPreferencial: _idiomaPreferencialController.text.trim(),
        fusoHorario: _fusoHorarioController.text.trim(),
        status: _statusController.text.trim(),
      ),
      objDadosFuncionais: ColaboradorDadosFuncionais(
        dataDeContratacao: _dataDeContratacaoController.text.trim(),
        salario: _toDouble(_salarioController),
        cargo: _cargoController.text.trim(),
        departamento: _departamentoController.text.trim(),
        tipoContrato: _tipoContratoController.text.trim(),
        centroDeCusto: _centroDeCustoController.text.trim(),
      ),
      objPessoa: ColaboradorPessoa(
        atencao: _atencaoController.text.trim(),
        nome: _nomeController.text.trim(),
        nomeDeGuerra: _nomeDeGuerraController.text.trim(),
        celular: _celularController.text.trim(),
        senha: _senhaPessoaController.text.trim(),
        cpf: _cpfController.text.trim(),
        rg: _rgController.text.trim(),
        dataDeNascimento: _dataNascimentoController.text.trim(),
        email: _emailController.text.trim(),
        objEndereco: ColaboradorEndereco(
          cep: _cepController.text.trim(),
          logradouro: _logradouroController.text.trim(),
          complemento: _complementoController.text.trim(),
          bairro: _bairroController.text.trim(),
          localidade: _localidadeController.text.trim(),
          uf: _ufController.text.trim(),
          pais: _paisController.text.trim(),
        ),
        documentoIdentificacaoUnicoDaEmpresa:
            _documentoUnicoEmpresaController.text.trim(),
      ),
      objAutorizacoes: ColaboradorAutorizacoes(
        podeFazerDevolucao: _podeFazerDevolucao,
        podeCadastrarProduto: _podeCadastrarProduto,
        objProdutosPode: ColaboradorProdutosPode(
          podeVerEstoqueDeProduto: _podeVerEstoqueDeProduto,
          podeEditarProduto: _podeEditarProduto,
          valorDaComissao: _toDouble(_comissaoProdutosController),
        ),
        objVendasPode: ColaboradorVendasPode(
          fazVenda: _fazVenda,
          comissaoDeVendas: _toDouble(_comissaoVendasController),
        ),
        objAssistenciaTecnicaPode: ColaboradorAssistenciaTecnicaPode(
          lancaServico: _lancaServico,
          ehUmTecnicoEFazAssistenciaTecnica: _ehTecnico,
          comissaoDeAssistencia: _toDouble(_comissaoAssistenciaController),
        ),
        objClientesPode: ColaboradorClientesPode(
          podeEditarCliente: _podeEditarCliente,
        ),
        objRelatoriosPode: ColaboradorRelatoriosPode(
          geraRelatorioDeVendas: _geraRelatorioDeVendas,
        ),
        objLancamentosFinanceirosPode: ColaboradorLancamentosFinanceirosPode(
          podeReceberNoCaixa: _podeReceberNoCaixa,
          podeVerQuantoVendeu: _podeVerQuantoVendeu,
        ),
      ),
      objIdentidadeGlobal: ColaboradorIdentidadeGlobal(
        tipoDocumento: _tipoDocumentoGlobalController.text.trim(),
        numeroDocumento: _numeroDocumentoGlobalController.text.trim(),
        paisDoDocumento: _paisDocumentoController.text.trim(),
        nacionalidade: _nacionalidadeController.text.trim(),
        paisResidencia: _paisResidenciaController.text.trim(),
      ),
      objFotoRegistro: ColaboradorFotoRegistro(
        modoCaptura: _modoCapturaFotoController.text.trim(),
        urlFoto: _fotoController.text.trim(),
        hashArquivo: _hashFotoController.text.trim(),
        dataCaptura: _dataCapturaFotoController.text.trim(),
        consentimentoUsoImagem: _consentimentoUsoImagem,
      ),
      objDadosPagamento: ColaboradorDadosPagamento(
        moeda: _moedaPagamentoController.text.trim().toUpperCase(),
        periodicidadePagamento: _periodicidadePagamentoController.text.trim(),
        valorBase: _toDouble(_valorBasePagamentoController),
        metodoPagamentoPreferencial: _metodoPagamentoController.text.trim(),
        banco: _bancoController.text.trim(),
        agencia: _agenciaController.text.trim(),
        conta: _contaController.text.trim(),
        iban: _ibanController.text.trim(),
        swiftBic: _swiftController.text.trim(),
        chavePix: _pixController.text.trim(),
        diaDePagamento: int.tryParse(_diaPagamentoController.text.trim()) ?? 5,
        incluirNaAgendaFinanceira: _incluirNaAgendaFinanceira,
      ),
      objPermissoesAplicacao: ColaboradorPermissoesAplicacao(
        podeAcessarAgendaFinanceira: _podeAcessarAgendaFinanceira,
        podeEditarDadosPagamento: _podeEditarDadosPagamento,
        podeExportarRelatorios: _podeExportarRelatorios,
        podeGerenciarPermissoes: _podeGerenciarPermissoes,
        escopoDeDados: _escopoDadosController.text.trim(),
        modulosPermitidos: <String>[
          if (_fazVenda) 'vendas',
          if (_lancaServico) 'assistencia_tecnica',
          if (_podeReceberNoCaixa) 'caixa',
          if (_podeAcessarAgendaFinanceira) 'agenda_financeira',
          if (_podeCadastrarProduto) 'produtos',
          if (_podeEditarCliente) 'clientes',
        ],
      ),
    );
  }

  ColaboradorAtualizacaoRequest _montarAtualizacaoRequest() {
    final ColaboradorCadastroRequest base = _montarRequest();

    return ColaboradorAtualizacaoRequest(
      idUnicoDaEmpresa: base.idUnicoDaEmpresa,
      idDeQuemCadastrou: base.idDeQuemCadastrou,
      idColaborador: _idColaboradorAtualizacaoController.text.trim(),
      foto: base.foto,
      celularDeAcesso: base.celularDeAcesso,
      senhaParaPermitirOAcessoDoColaborador:
          base.senhaParaPermitirOAcessoDoColaborador,
      objInformacoesDoCadastro: base.objInformacoesDoCadastro,
      objDadosFuncionais: base.objDadosFuncionais,
      objPessoa: base.objPessoa,
      objAutorizacoes: base.objAutorizacoes,
      objIdentidadeGlobal: base.objIdentidadeGlobal,
      objFotoRegistro: base.objFotoRegistro,
      objDadosPagamento: base.objDadosPagamento,
      objPermissoesAplicacao: base.objPermissoesAplicacao,
    );
  }

  Future<void> _salvarColaborador() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ColaboradorCadastroRequest request = _montarRequest();
      final ColaboradorCadastroResponse response = await _colaboradorService
          .cadastrarColaborador(request);

      if (!mounted) {
        return;
      }

      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final ColaboradorAtualizacaoRequest updateRequest =
          _montarAtualizacaoRequest();

      String message =
          'Colaborador cadastrado com sucesso!\n\n'
          'Payload POST sugerido:\n${encoder.convert(request.toJson())}\n\n'
          'Payload PUT sugerido:\n${encoder.convert(updateRequest.toJson())}';

      if (response.body.trim().isNotEmpty) {
        try {
          final Object decoded = jsonDecode(response.body);
          message =
              '$message\n\nResposta do backend:\n${encoder.convert(decoded)}';
        } catch (_) {
          message = '$message\n\nResposta do backend:\n${response.body}';
        }
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Sucesso'),
            content: SingleChildScrollView(child: Text(message)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Erro ao cadastrar'),
            content: SingleChildScrollView(child: Text(e.toString())),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
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

  Widget _buildFotoPreviewCard(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String url = _fotoController.text.trim();

    return _buildSectionCard(
      context: context,
      title: 'Foto e acesso',
      subtitle: 'O backend recebe a URL da foto e as credenciais iniciais.',
      icon: Icons.photo_camera_back_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colorScheme.outline.withOpacity(0.16)),
              color: colorScheme.primary.withOpacity(0.04),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                url.isNotEmpty
                    ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _buildFotoPlaceholder(context);
                      },
                    )
                    : _buildFotoPlaceholder(context),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context: context,
            controller: _fotoController,
            label: 'URL da foto',
            icon: Icons.link_outlined,
            hintText: 'https://meuservidor.com/fotos/colaborador.jpg',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: 260,
                child: _buildTextField(
                  context: context,
                  controller: _celularDeAcessoController,
                  label: 'Celular de acesso',
                  icon: Icons.smartphone_outlined,
                  hintText: '+5535999991111',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildTextField(
                  context: context,
                  controller: _senhaAcessoController,
                  label: 'Senha para permitir acesso',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  requiredField: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: 210,
                child: _buildTextField(
                  context: context,
                  controller: _modoCapturaFotoController,
                  label: 'Modo captura',
                  icon: Icons.camera_alt_outlined,
                  hintText: 'upload/camera',
                ),
              ),
              SizedBox(
                width: 270,
                child: _buildTextField(
                  context: context,
                  controller: _hashFotoController,
                  label: 'Hash arquivo foto',
                  icon: Icons.fingerprint_outlined,
                ),
              ),
              SizedBox(
                width: 260,
                child: _buildDateField(
                  context: context,
                  controller: _dataCapturaFotoController,
                  label: 'Data da captura',
                  icon: Icons.timelapse_outlined,
                  includeTime: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            context: context,
            title: 'Consentimento para uso da imagem',
            subtitle:
                'Autoriza utilização da foto em perfis e documentos internos.',
            value: _consentimentoUsoImagem,
            onChanged: (bool value) {
              _consentimentoUsoImagem = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFotoPlaceholder(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: colorScheme.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Informe uma URL para foto do colaborador',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'A imagem será usada como preview local e enviada no payload.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.62),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildResumoCard(BuildContext context) {
    final String nome =
        _nomeController.text.trim().isEmpty ? '-' : _nomeController.text.trim();

    return _buildSectionCard(
      context: context,
      title: 'Resumo do cadastro',
      subtitle: 'Conferência rápida antes de salvar.',
      icon: Icons.description_outlined,
      child: Column(
        children: <Widget>[
          _buildInfoRow('Nome', nome),
          _buildInfoRow(
            'Cargo',
            _cargoController.text.trim().isEmpty
                ? '-'
                : _cargoController.text.trim(),
          ),
          _buildInfoRow('Perfil', _perfilSelecionado),
          _buildInfoRow('Status', _colaboradorAtivo ? 'Ativo' : 'Inativo'),
          _buildInfoRow('Uso esperado', _usoEsperado(), isLast: true),
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
            'Revise os dados e conclua o cadastro do colaborador.',
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
                onPressed: _isLoading ? null : _salvarColaborador,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: Text(_isLoading ? 'Salvando...' : 'Salvar colaborador'),
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

        final Widget identidadeAcesso = _buildSectionCard(
          context: context,
          title: 'Identidade do cadastro',
          subtitle: 'Dados de rastreabilidade e vínculo do colaborador.',
          icon: Icons.badge_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 240 : (telaMedia ? 240 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _idUnicoDoUsuarioController,
                  label: 'ID único do usuário',
                  icon: Icons.vpn_key_outlined,
                  hintText: 'USR-0001',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 280 : (telaMedia ? 280 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _idUnicoDaEmpresaController,
                  label: 'ID único da empresa',
                  icon: Icons.apartment_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 300 : (telaMedia ? 300 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _idDeQuemCadastrouController,
                  label: 'ID de quem cadastrou',
                  icon: Icons.person_pin_circle_outlined,
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
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _idiomaPreferencialController,
                  label: 'Idioma (locale)',
                  icon: Icons.language_outlined,
                  hintText: 'pt-BR / en-US',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 260 : (telaMedia ? 260 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _fusoHorarioController,
                  label: 'Fuso horário',
                  icon: Icons.public_outlined,
                  hintText: 'America/Sao_Paulo',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 200 : (telaMedia ? 200 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _statusController,
                  label: 'Status',
                  icon: Icons.toggle_on_outlined,
                  hintText: 'ATIVO',
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _idColaboradorAtualizacaoController,
                  label: 'ID colaborador (PUT)',
                  icon: Icons.edit_note_outlined,
                  hintText: 'COLAB-0001',
                  requiredField: true,
                ),
              ),
            ],
          ),
        );

        final Widget dadosPessoais = _buildSectionCard(
          context: context,
          title: 'Dados pessoais',
          subtitle:
              'Informações básicas da pessoa para identificação no sistema.',
          icon: Icons.person_outline,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _atencaoController,
                  label: 'Atenção',
                  icon: Icons.info_outline,
                  hintText: 'Observação curta',
                ),
              ),
              SizedBox(
                width: telaGrande ? 340 : (telaMedia ? 320 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _nomeController,
                  label: 'Nome completo',
                  icon: Icons.person_outline,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 260 : (telaMedia ? 260 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _nomeDeGuerraController,
                  label: 'Nome de guerra',
                  icon: Icons.emoji_people_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 240 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _celularController,
                  label: 'Celular',
                  icon: Icons.phone_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 260 : (telaMedia ? 260 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _emailController,
                  label: 'E-mail',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _cpfController,
                  label: 'CPF',
                  icon: Icons.badge_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : (telaMedia ? 320 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _documentoUnicoEmpresaController,
                  label: 'Documento único da empresa',
                  icon: Icons.business_center_outlined,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _rgController,
                  label: 'RG',
                  icon: Icons.credit_card_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildDateField(
                  context: context,
                  controller: _dataNascimentoController,
                  label: 'Data de nascimento',
                  icon: Icons.cake_outlined,
                  includeTime: false,
                ),
              ),
              SizedBox(
                width: telaGrande ? 240 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _senhaPessoaController,
                  label: 'Senha da pessoa',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  requiredField: true,
                ),
              ),
            ],
          ),
        );

        final Widget endereco = _buildSectionCard(
          context: context,
          title: 'Endereço',
          subtitle: 'Campos enviados para o objeto de endereço do backend.',
          icon: Icons.home_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 190 : (telaMedia ? 190 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _cepController,
                  label: 'CEP',
                  icon: Icons.markunread_mailbox_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 340 : (telaMedia ? 320 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _logradouroController,
                  label: 'Logradouro',
                  icon: Icons.map_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 260 : (telaMedia ? 240 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _complementoController,
                  label: 'Complemento',
                  icon: Icons.add_location_alt_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _bairroController,
                  label: 'Bairro',
                  icon: Icons.location_city_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _localidadeController,
                  label: 'Localidade',
                  icon: Icons.pin_drop_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 120 : (telaMedia ? 120 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _ufController,
                  label: 'UF',
                  icon: Icons.flag_outlined,
                ),
              ),
              SizedBox(
                width: telaGrande ? 120 : (telaMedia ? 120 : double.infinity),
                child: _buildTextField(
                  context: context,
                  controller: _paisController,
                  label: 'País',
                  icon: Icons.flag_circle_outlined,
                  hintText: 'BR',
                ),
              ),
            ],
          ),
        );

        final Widget dadosFuncionais = _buildSectionCard(
          context: context,
          title: 'Dados funcionais e perfil',
          subtitle:
              'Definição operacional para orientar permissões e uso esperado.',
          icon: Icons.work_outline,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildDateField(
                      context: context,
                      controller: _dataDeContratacaoController,
                      label: 'Data de contratação',
                      icon: Icons.event_available_outlined,
                      includeTime: false,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _salarioController,
                      label: 'Salário',
                      icon: Icons.attach_money_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _cargoController,
                      label: 'Cargo',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 240 : (telaMedia ? 240 : double.infinity),
                    child: DropdownButtonFormField<String>(
                      value: _perfilSelecionado,
                      decoration: _inputDecoration(
                        context,
                        'Perfil operacional',
                        icon: Icons.verified_user_outlined,
                      ),
                      items:
                          _perfis
                              .map(
                                (String perfil) => DropdownMenuItem<String>(
                                  value: perfil,
                                  child: Text(perfil),
                                ),
                              )
                              .toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        _aplicarPerfil(value);
                      },
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 240 : (telaMedia ? 240 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _departamentoController,
                      label: 'Departamento',
                      icon: Icons.account_tree_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 180 : (telaMedia ? 180 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _tipoContratoController,
                      label: 'Tipo contrato',
                      icon: Icons.assignment_ind_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 240 : (telaMedia ? 240 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _centroDeCustoController,
                      label: 'Centro de custo',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: telaGrande ? 360 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: 'Colaborador ativo',
                  subtitle:
                      'Disponível para ser escolhido nos fluxos da OS e do orçamento.',
                  value: _colaboradorAtivo,
                  onChanged: (bool value) {
                    _colaboradorAtivo = value;
                  },
                ),
              ),
            ],
          ),
        );

        final Widget autorizacoesGerais = _buildSectionCard(
          context: context,
          title: 'Autorização geral',
          subtitle: 'Regras principais de atuação e autonomia no sistema.',
          icon: Icons.admin_panel_settings_outlined,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: 'Pode fazer devolução',
                  subtitle: 'Permite processar devoluções no balcão.',
                  value: _podeFazerDevolucao,
                  onChanged: (bool value) {
                    _podeFazerDevolucao = value;
                  },
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: 'Pode cadastrar produto',
                  subtitle: 'Permite inclusão de novos produtos.',
                  value: _podeCadastrarProduto,
                  onChanged: (bool value) {
                    _podeCadastrarProduto = value;
                  },
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: 'Pode editar cliente',
                  subtitle: 'Permite alterar cadastro de clientes.',
                  value: _podeEditarCliente,
                  onChanged: (bool value) {
                    _podeEditarCliente = value;
                  },
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: 'Gera relatório de vendas',
                  subtitle: 'Permite acessar relatórios comerciais.',
                  value: _geraRelatorioDeVendas,
                  onChanged: (bool value) {
                    _geraRelatorioDeVendas = value;
                  },
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: 'Pode receber no caixa',
                  subtitle: 'Permite registrar recebimento no caixa.',
                  value: _podeReceberNoCaixa,
                  onChanged: (bool value) {
                    _podeReceberNoCaixa = value;
                  },
                ),
              ),
              SizedBox(
                width: telaGrande ? 320 : double.infinity,
                child: _buildSwitchTile(
                  context: context,
                  title: 'Pode ver quanto vendeu',
                  subtitle: 'Permite consultar vendas e resultados.',
                  value: _podeVerQuantoVendeu,
                  onChanged: (bool value) {
                    _podeVerQuantoVendeu = value;
                  },
                ),
              ),
            ],
          ),
        );

        final Widget autorizacoesModulos = _buildSectionCard(
          context: context,
          title: 'Permissões por módulo',
          subtitle:
              'Campos que refletem diretamente o objeto de autorizações do backend.',
          icon: Icons.tune_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Pode ver estoque de produto',
                      subtitle: 'Leitura de estoque e saldo.',
                      value: _podeVerEstoqueDeProduto,
                      onChanged: (bool value) {
                        _podeVerEstoqueDeProduto = value;
                      },
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Pode editar produto',
                      subtitle: 'Alteração de informações do produto.',
                      value: _podeEditarProduto,
                      onChanged: (bool value) {
                        _podeEditarProduto = value;
                      },
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 260 : (telaMedia ? 260 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _comissaoProdutosController,
                      label: 'Comissão em produtos',
                      icon: Icons.percent_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Faz venda',
                      subtitle: 'Permite criar vendas.',
                      value: _fazVenda,
                      onChanged: (bool value) {
                        _fazVenda = value;
                      },
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 260 : (telaMedia ? 260 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _comissaoVendasController,
                      label: 'Comissão de vendas',
                      icon: Icons.monetization_on_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Lança serviço',
                      subtitle: 'Permite registrar serviços e etapas.',
                      value: _lancaServico,
                      onChanged: (bool value) {
                        _lancaServico = value;
                      },
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'É técnico e faz assistência',
                      subtitle: 'Aparece como técnico responsável.',
                      value: _ehTecnico,
                      onChanged: (bool value) {
                        _ehTecnico = value;
                      },
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 260 : (telaMedia ? 260 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _comissaoAssistenciaController,
                      label: 'Comissão de assistência',
                      icon: Icons.build_circle_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final Widget dadosGlobaisPagamento = _buildSectionCard(
          context: context,
          title: 'Identidade global, pagamento e governança',
          subtitle:
              'Campos para operação internacional, foto auditável e agenda financeira.',
          icon: Icons.language_outlined,
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width:
                        telaGrande ? 180 : (telaMedia ? 180 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _tipoDocumentoGlobalController,
                      label: 'Tipo documento',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 240 : (telaMedia ? 240 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _numeroDocumentoGlobalController,
                      label: 'Documento global',
                      icon: Icons.pin_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 120 : (telaMedia ? 120 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _paisDocumentoController,
                      label: 'País doc.',
                      icon: Icons.flag_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _nacionalidadeController,
                      label: 'Nacionalidade',
                      icon: Icons.public_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 120 : (telaMedia ? 120 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _paisResidenciaController,
                      label: 'País residência',
                      icon: Icons.home_work_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width:
                        telaGrande ? 140 : (telaMedia ? 140 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _moedaPagamentoController,
                      label: 'Moeda',
                      icon: Icons.currency_exchange_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 180 : (telaMedia ? 180 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _periodicidadePagamentoController,
                      label: 'Periodicidade',
                      icon: Icons.repeat_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 170 : (telaMedia ? 170 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _valorBasePagamentoController,
                      label: 'Valor base',
                      icon: Icons.monetization_on_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _metodoPagamentoController,
                      label: 'Método pagamento',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 120 : (telaMedia ? 120 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _diaPagamentoController,
                      label: 'Dia pgto',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _bancoController,
                      label: 'Banco',
                      icon: Icons.account_balance_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 160 : (telaMedia ? 160 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _agenciaController,
                      label: 'Agência',
                      icon: Icons.numbers_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 200 : (telaMedia ? 200 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _contaController,
                      label: 'Conta',
                      icon: Icons.credit_card_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 240 : (telaMedia ? 240 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _ibanController,
                      label: 'IBAN',
                      icon: Icons.travel_explore_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _swiftController,
                      label: 'SWIFT/BIC',
                      icon: Icons.swap_horiz_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 220 : (telaMedia ? 220 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _pixController,
                      label: 'Chave PIX',
                      icon: Icons.pix_outlined,
                    ),
                  ),
                  SizedBox(
                    width:
                        telaGrande ? 200 : (telaMedia ? 200 : double.infinity),
                    child: _buildTextField(
                      context: context,
                      controller: _escopoDadosController,
                      label: 'Escopo de dados',
                      icon: Icons.security_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Incluir na agenda financeira',
                      subtitle:
                          'Registra eventos de pagamento automaticamente.',
                      value: _incluirNaAgendaFinanceira,
                      onChanged:
                          (bool value) => _incluirNaAgendaFinanceira = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Acessar agenda financeira',
                      subtitle:
                          'Permite visualização de eventos e títulos da agenda.',
                      value: _podeAcessarAgendaFinanceira,
                      onChanged:
                          (bool value) => _podeAcessarAgendaFinanceira = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Editar dados de pagamento',
                      subtitle:
                          'Permite alterar banco, conta e política de pagamento.',
                      value: _podeEditarDadosPagamento,
                      onChanged:
                          (bool value) => _podeEditarDadosPagamento = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Exportar relatórios',
                      subtitle: 'Permite exportação de dados em massa.',
                      value: _podeExportarRelatorios,
                      onChanged:
                          (bool value) => _podeExportarRelatorios = value,
                    ),
                  ),
                  SizedBox(
                    width: telaGrande ? 320 : double.infinity,
                    child: _buildSwitchTile(
                      context: context,
                      title: 'Gerenciar permissões',
                      subtitle:
                          'Concede autonomia para controlar acessos de outros usuários.',
                      value: _podeGerenciarPermissoes,
                      onChanged:
                          (bool value) => _podeGerenciarPermissoes = value,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        final Widget conteudoEsquerdo = Column(
          children: <Widget>[
            identidadeAcesso,
            const SizedBox(height: 20),
            dadosPessoais,
            const SizedBox(height: 20),
            endereco,
            const SizedBox(height: 20),
            dadosFuncionais,
            const SizedBox(height: 20),
            dadosGlobaisPagamento,
            const SizedBox(height: 20),
            autorizacoesGerais,
            const SizedBox(height: 20),
            autorizacoesModulos,
          ],
        );

        final Widget conteudoDireito = Column(
          children: <Widget>[
            _buildFotoPreviewCard(context),
            const SizedBox(height: 20),
            _buildResumoCard(context),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1380),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    if (telaGrande)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 8, child: conteudoEsquerdo),
                          const SizedBox(width: 24),
                          Expanded(flex: 4, child: conteudoDireito),
                        ],
                      )
                    else ...<Widget>[
                      _buildFotoPreviewCard(context),
                      const SizedBox(height: 20),
                      _buildResumoCard(context),
                      const SizedBox(height: 20),
                      conteudoEsquerdo,
                    ],
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
