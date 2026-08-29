import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/services/colaborador_convite_web_service.dart';
import '../../core/utils/colaborador_cadastro_quality.dart';
import '../../data/models/colaborador_convite_model.dart';
import '../../design_system/themes/six_mobile_color_scheme.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/mobile/six_mobile_page_shell.dart';

class ColaboradorCadastroMobileScreen extends StatefulWidget {
  const ColaboradorCadastroMobileScreen({super.key});

  @override
  State<ColaboradorCadastroMobileScreen> createState() =>
      _ColaboradorCadastroMobileScreenState();
}

class _ColaboradorCadastroMobileScreenState
    extends State<ColaboradorCadastroMobileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ColaboradorConviteWebService _service = ColaboradorConviteWebService();

  final TextEditingController _nome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _celular = TextEditingController(text: '+55');
  final TextEditingController _nomeSocial = TextEditingController();
  final TextEditingController _cpf = TextEditingController();
  final TextEditingController _rg = TextEditingController();
  final TextEditingController _dataNascimento = TextEditingController();
  final TextEditingController _cep = TextEditingController();
  final TextEditingController _logradouro = TextEditingController();
  final TextEditingController _numero = TextEditingController();
  final TextEditingController _complemento = TextEditingController();
  final TextEditingController _bairro = TextEditingController();
  final TextEditingController _cidade = TextEditingController();
  final TextEditingController _estado = TextEditingController();
  final TextEditingController _pais = TextEditingController(text: 'BR');
  final TextEditingController _numeroContrato = TextEditingController();
  final TextEditingController _cargo = TextEditingController();
  final TextEditingController _departamento = TextEditingController();
  final TextEditingController _dataInicio = TextEditingController();
  final TextEditingController _dataTermino = TextEditingController();
  final TextEditingController _cargaHoraria = TextEditingController();
  final TextEditingController _valorBase = TextEditingController();
  final TextEditingController _diaPagamento = TextEditingController();
  final TextEditingController _banco = TextEditingController();
  final TextEditingController _agencia = TextEditingController();
  final TextEditingController _conta = TextEditingController();
  final TextEditingController _chavePix = TextEditingController();
  final TextEditingController _escopoServico = TextEditingController();
  final TextEditingController _observacoes = TextEditingController();

  String _tipoCadastro = ColaboradorCadastroQuality.tipoSimples;
  String _tipoVinculo = 'CLT';
  String _regimeTrabalho = 'PRESENCIAL';
  String _moeda = 'BRL';
  String _periodicidade = 'MENSAL';
  String _metodoPagamento = 'TRANSFERENCIA';
  int _etapaAtual = 0;

  bool _fazVenda = true;
  bool _lancaServico = true;
  bool _editaCliente = true;
  bool _podeReceberNoCaixa = false;
  bool _podeVerQuantoVendeu = false;
  bool _geraRelatorio = false;
  bool _gerenciaPermissoes = false;
  bool _loading = false;
  ColaboradorConviteResponse? _convite;

  SixMobileColorScheme get _colors => context.sixMobileColors;
  bool get _cadastroCompleto =>
      _tipoCadastro == ColaboradorCadastroQuality.tipoCompleto;

  List<String> get _etapas => _cadastroCompleto
      ? <String>[
          _t('colaborador.journey.essentialStep', 'Essenciais'),
          _t('colaborador.journey.personalStep', 'Pessoa'),
          _t('colaborador.journey.contractStep', 'Contrato'),
          _t('colaborador.journey.permissionsStep', 'Permissões'),
        ]
      : <String>[
          _t('colaborador.journey.essentialStep', 'Essenciais'),
          _t('colaborador.journey.permissionsStep', 'Permissões'),
        ];

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _nome,
      _email,
      _celular,
      _nomeSocial,
      _cpf,
      _rg,
      _dataNascimento,
      _cep,
      _logradouro,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _estado,
      _pais,
      _numeroContrato,
      _cargo,
      _departamento,
      _dataInicio,
      _dataTermino,
      _cargaHoraria,
      _valorBase,
      _diaPagamento,
      _banco,
      _agencia,
      _conta,
      _chavePix,
      _escopoServico,
      _observacoes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  List<String> _permissoes() => <String>[
    if (_fazVenda) 'VENDAS_CRIAR',
    if (_lancaServico) 'ASSISTENCIA_TECNICA_CRIAR',
    if (_editaCliente) 'CLIENTES_EDITAR',
    if (_podeReceberNoCaixa) 'FINANCEIRO_ACESSAR',
    if (_podeVerQuantoVendeu) 'VENDAS_CONSULTAR',
    if (_geraRelatorio) 'RELATORIOS_GERAR',
    if (_gerenciaPermissoes) 'PERMISSOES_GERENCIAR',
  ];

  double _parseDecimal(String value) {
    String raw = value.trim().replaceAll(' ', '');
    if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      raw = raw.replaceAll(',', '.');
    }
    return double.tryParse(raw) ?? 0;
  }

  QualidadeCadastroColaborador get _qualidade =>
      ColaboradorCadastroQuality.calcular(
        tipoCadastro: _tipoCadastro,
        entrada: EntradaQualidadeCadastroColaborador(
          nomeInformado: _nome.text.trim().isNotEmpty,
          emailInformado: _email.text.trim().contains('@'),
          celularInformado:
              _celular.text.replaceAll(RegExp(r'\D'), '').length >= 10,
          permissoesConfiguradas: _permissoes().isNotEmpty,
          documentosInformados:
              (_cpf.text.trim().isNotEmpty || _rg.text.trim().isNotEmpty) &&
              _dataNascimento.text.trim().isNotEmpty,
          enderecoInformado:
              _cep.text.trim().isNotEmpty && _cidade.text.trim().isNotEmpty,
          funcaoInformada:
              _cargo.text.trim().isNotEmpty &&
              _departamento.text.trim().isNotEmpty,
          contratoInformado:
              _tipoVinculo.isNotEmpty && _dataInicio.text.trim().isNotEmpty,
          remuneracaoInformada:
              _parseDecimal(_valorBase.text) > 0 && _moeda.isNotEmpty,
          pagamentoInformado:
              _periodicidade.isNotEmpty &&
              int.tryParse(_diaPagamento.text.trim()) != null,
        ),
      );

  ColaboradorConviteRequest _request() {
    return ColaboradorConviteRequest(
      nome: _nome.text.trim(),
      email: _email.text.trim(),
      celular: _celular.text.trim(),
      permissoes: _permissoes(),
      tipoCadastro: _tipoCadastro,
      percentualQualidadeCadastro: _qualidade.percentual,
      dadosPessoais: !_cadastroCompleto
          ? null
          : ColaboradorDadosPessoaisCadastro(
              nomeSocial: _nomeSocial.text.trim(),
              cpf: _cpf.text.trim(),
              rg: _rg.text.trim(),
              dataNascimento: _dataNascimento.text.trim(),
              cep: _cep.text.trim(),
              logradouro: _logradouro.text.trim(),
              numero: _numero.text.trim(),
              complemento: _complemento.text.trim(),
              bairro: _bairro.text.trim(),
              cidade: _cidade.text.trim(),
              estado: _estado.text.trim(),
              pais: _pais.text.trim().toUpperCase(),
            ),
      dadosContratuais: !_cadastroCompleto
          ? null
          : ColaboradorDadosContratuaisCadastro(
              tipoVinculo: _tipoVinculo,
              numeroContrato: _numeroContrato.text.trim(),
              cargo: _cargo.text.trim(),
              departamento: _departamento.text.trim(),
              dataInicio: _dataInicio.text.trim(),
              dataTermino: _dataTermino.text.trim(),
              cargaHorariaSemanal: int.tryParse(_cargaHoraria.text.trim()),
              regimeTrabalho: _regimeTrabalho,
              valorBase: _parseDecimal(_valorBase.text),
              moeda: _moeda,
              periodicidadePagamento: _periodicidade,
              diaPagamento: int.tryParse(_diaPagamento.text.trim()),
              metodoPagamento: _metodoPagamento,
              banco: _banco.text.trim(),
              agencia: _agencia.text.trim(),
              conta: _conta.text.trim(),
              chavePix: _chavePix.text.trim(),
              escopoPrestacaoServico: _escopoServico.text.trim(),
              observacoes: _observacoes.text.trim(),
            ),
    );
  }

  Future<void> _criarConvite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _convite = null;
    });
    try {
      final ColaboradorConviteResponse response = await _service.criarConvite(
        _request(),
      );
      if (!mounted) return;
      setState(() => _convite = response);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'colaboradores.inviteCreatedSuccessfully',
              'Convite de colaborador criado com sucesso.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _inviteLink(ColaboradorConviteResponse convite) {
    final Uri configured = Uri.parse(AppConfig.autoCustomerBaseUrl);
    final String origin = configured.hasScheme && configured.host.isNotEmpty
        ? configured.origin
        : Uri.base.origin;
    return '$origin/colaborador/convites/${convite.codigo}';
  }

  Future<void> _copiarLink() async {
    final ColaboradorConviteResponse? convite = _convite;
    if (convite == null) return;
    await Clipboard.setData(ClipboardData(text: _inviteLink(convite)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t('colaboradores.inviteLinkCopied', 'Link do convite copiado.'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectJourney(String tipo) {
    if (_loading || _tipoCadastro == tipo) return;
    setState(() {
      _tipoCadastro = tipo;
      _etapaAtual = 0;
      _convite = null;
    });
  }

  void _next() {
    if (_etapaAtual == 0 && !_formKey.currentState!.validate()) return;
    if (_etapaAtual < _etapas.length - 1) {
      setState(() => _etapaAtual += 1);
    } else {
      _criarConvite();
    }
  }

  void _back() {
    if (_etapaAtual > 0) {
      setState(() => _etapaAtual -= 1);
    } else {
      Navigator.of(context).pop(_convite != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleSettingsProvider>();
    return PopScope(
      canPop: !_loading && _etapaAtual == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && !_loading) _back();
      },
      child: SixMobilePageShell(
        title: _t('colaboradores.newCollaborator', 'Novo colaborador'),
        backgroundColor: _colors.background,
        primaryColor: _colors.primary,
        secondaryColor: _colors.secondary,
        accentColor: _colors.accent,
        enableAnimatedBackground: false,
        toolbarHeight: 48,
        leading: IconButton(
          onPressed: _loading ? null : _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        bottomNavigationBar: _bottomActions(),
        bodyBuilder:
            (
              BuildContext context,
              ScrollController controller,
              double topInset,
            ) {
              return Form(
                key: _formKey,
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
                  children: <Widget>[
                    _journeySelector(),
                    const SizedBox(height: 14),
                    _qualityCard(),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder:
                          (Widget child, Animation<double> value) =>
                              FadeTransition(
                                opacity: value,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.03, 0),
                                    end: Offset.zero,
                                  ).animate(value),
                                  child: child,
                                ),
                              ),
                      child: KeyedSubtree(
                        key: ValueKey<String>('$_tipoCadastro-$_etapaAtual'),
                        child: _stepContent(),
                      ),
                    ),
                    if (_convite != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _inviteResult(_convite!),
                    ],
                  ],
                ),
              );
            },
      ),
    );
  }

  Widget _journeySelector() {
    return _section(
      title: _t('colaborador.journey.choose', 'Escolha a jornada'),
      subtitle: _t(
        'colaborador.journey.chooseSubtitle',
        'Troque o nível sem perder os dados preenchidos.',
      ),
      icon: Icons.route_outlined,
      child: Column(
        children: <Widget>[
          _journeyOption(
            type: ColaboradorCadastroQuality.tipoSimples,
            icon: Icons.bolt_rounded,
            title: _t('colaborador.journey.simple', 'Cadastro simples'),
            subtitle: _t(
              'colaborador.journey.simpleSubtitle',
              'Nome, e-mail, celular e permissões.',
            ),
          ),
          const SizedBox(height: 10),
          _journeyOption(
            type: ColaboradorCadastroQuality.tipoCompleto,
            icon: Icons.assignment_ind_outlined,
            title: _t('colaborador.journey.complete', 'Cadastro completo'),
            subtitle: _t(
              'colaborador.journey.completeSubtitle',
              'Documentos, endereço, função, contrato e pagamento.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeyOption({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = _tipoCadastro == type;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _selectJourney(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _colors.softAccentSurface : _colors.softSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _colors.accent : _colors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _colors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _colors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: _colors.titleText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _colors.mutedText,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? _colors.accent : _colors.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _qualityCard() {
    final QualidadeCadastroColaborador quality = _qualidade;
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    final List<MelhoriaQualidadeCadastroColaborador> improvements = quality
        .melhorias
        .take(2)
        .toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: quality.percentual / 100),
                duration: const Duration(milliseconds: 320),
                builder: (_, double value, __) => SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          color: _colors.accent,
                          backgroundColor: _colors.border,
                        ),
                      ),
                      Text(
                        locale.formatPercent(value * 100),
                        style: TextStyle(
                          color: _colors.titleText,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _t('colaborador.quality.title', 'Qualidade do cadastro'),
                      style: TextStyle(
                        color: _colors.titleText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _qualityLevel(quality.nivel),
                      style: TextStyle(
                        color: _colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (improvements.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: improvements
                  .map(
                    (
                      MelhoriaQualidadeCadastroColaborador improvement,
                    ) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _colors.softSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _colors.border),
                      ),
                      child: Text(
                        '${_improvementLabel(improvement.criterio)} +${locale.formatPercent(improvement.pontos)}',
                        style: TextStyle(
                          color: _colors.titleText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: _colors.border),
          const SizedBox(height: 13),
          Text(
            '${_t('colaborador.journey.step', 'Etapa')} ${_etapaAtual + 1} '
            '${_t('colaborador.journey.of', 'de')} ${_etapas.length} · ${_etapas[_etapaAtual]}',
            style: TextStyle(
              color: _colors.titleText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: List<Widget>.generate(_etapas.length, (int index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index == _etapas.length - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: index <= _etapaAtual
                        ? _colors.accent
                        : _colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _stepContent() {
    if (_etapaAtual == 0) return _essentialSection();
    if (_cadastroCompleto && _etapaAtual == 1) return _personalSection();
    if (_cadastroCompleto && _etapaAtual == 2) return _contractSection();
    return _permissionsSection();
  }

  Widget _essentialSection() {
    return _section(
      title: _t('colaborador.journey.essentialTitle', 'Dados essenciais'),
      subtitle: _t(
        'colaborador.journey.essentialSubtitle',
        'Informações usadas no convite e na identificação.',
      ),
      icon: Icons.contact_mail_outlined,
      child: Column(
        children: <Widget>[
          _field(
            controller: _nome,
            label: _t('colaboradores.collaboratorName', 'Nome do colaborador'),
            icon: Icons.person_outline,
            validator: _required(
              _t('colaboradores.nameRequired', 'Informe o nome.'),
            ),
          ),
          _gap(),
          _field(
            controller: _email,
            label: _t('colaboradores.loginEmail', 'E-mail de login'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (String? value) =>
                value == null || !value.trim().contains('@')
                ? _t('colaboradores.emailRequired', 'Informe um e-mail válido.')
                : null,
          ),
          _gap(),
          _field(
            controller: _celular,
            label: _t('colaboradores.phone', 'Celular'),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _required(
              _t('colaborador.validation.phone', 'Informe o celular.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalSection() {
    return Column(
      children: <Widget>[
        _section(
          title: _t('colaborador.personal.title', 'Dados pessoais'),
          subtitle: _t(
            'colaborador.personal.subtitle',
            'Documentos e identificação complementar.',
          ),
          icon: Icons.badge_outlined,
          child: Column(
            children: <Widget>[
              _field(
                controller: _nomeSocial,
                label: _t('colaborador.personal.socialName', 'Nome social'),
                icon: Icons.record_voice_over_outlined,
              ),
              _gap(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _field(
                      controller: _cpf,
                      label: _t('colaborador.personal.taxId', 'CPF/documento'),
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      controller: _rg,
                      label: _t(
                        'colaborador.personal.identity',
                        'RG/identidade',
                      ),
                      icon: Icons.credit_card_outlined,
                    ),
                  ),
                ],
              ),
              _gap(),
              _dateField(
                controller: _dataNascimento,
                label: _t(
                  'colaborador.personal.birthDate',
                  'Data de nascimento',
                ),
                icon: Icons.cake_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _section(
          title: _t('colaborador.address.title', 'Endereço'),
          subtitle: _t(
            'colaborador.address.subtitle',
            'Endereço de referência do colaborador.',
          ),
          icon: Icons.home_work_outlined,
          child: Column(
            children: <Widget>[
              _field(
                controller: _cep,
                label: 'CEP',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
              ),
              _gap(),
              _field(
                controller: _logradouro,
                label: _t('colaborador.address.street', 'Logradouro'),
                icon: Icons.route_outlined,
              ),
              _gap(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _field(
                      controller: _numero,
                      label: _t('colaborador.address.number', 'Número'),
                      icon: Icons.numbers_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      controller: _complemento,
                      label: _t(
                        'colaborador.address.complement',
                        'Complemento',
                      ),
                      icon: Icons.add_home_outlined,
                    ),
                  ),
                ],
              ),
              _gap(),
              _field(
                controller: _bairro,
                label: _t('colaborador.address.district', 'Bairro'),
                icon: Icons.location_city_outlined,
              ),
              _gap(),
              _field(
                controller: _cidade,
                label: _t('colaborador.address.city', 'Cidade'),
                icon: Icons.location_on_outlined,
              ),
              _gap(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _field(
                      controller: _estado,
                      label: _t('colaborador.address.state', 'Estado'),
                      icon: Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      controller: _pais,
                      label: _t('colaborador.address.country', 'País'),
                      icon: Icons.public_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contractSection() {
    return Column(
      children: <Widget>[
        _section(
          title: _t('colaborador.contract.title', 'Vínculo e contrato'),
          subtitle: _t(
            'colaborador.contract.subtitle',
            'Contrato de trabalho ou prestação de serviço.',
          ),
          icon: Icons.assignment_outlined,
          child: Column(
            children: <Widget>[
              _choiceGroup(
                title: _t('colaborador.contract.linkType', 'Tipo de vínculo'),
                values: const <String>[
                  'CLT',
                  'PRESTACAO_SERVICO',
                  'ESTAGIO',
                  'TEMPORARIO',
                ],
                selected: _tipoVinculo,
                label: _contractTypeLabel,
                onSelected: (String value) =>
                    setState(() => _tipoVinculo = value),
              ),
              _gap(),
              _field(
                controller: _numeroContrato,
                label: _t('colaborador.contract.number', 'Número do contrato'),
                icon: Icons.tag_outlined,
              ),
              _gap(),
              _field(
                controller: _cargo,
                label: _t('colaborador.contract.role', 'Cargo/função'),
                icon: Icons.work_outline,
              ),
              _gap(),
              _field(
                controller: _departamento,
                label: _t('colaborador.contract.department', 'Departamento'),
                icon: Icons.account_tree_outlined,
              ),
              _gap(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _dateField(
                      controller: _dataInicio,
                      label: _t('colaborador.contract.startDate', 'Início'),
                      icon: Icons.event_available_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateField(
                      controller: _dataTermino,
                      label: _t('colaborador.contract.endDate', 'Término'),
                      icon: Icons.event_busy_outlined,
                    ),
                  ),
                ],
              ),
              _gap(),
              _field(
                controller: _cargaHoraria,
                label: _t(
                  'colaborador.contract.weeklyHours',
                  'Carga horária semanal',
                ),
                icon: Icons.schedule_outlined,
                keyboardType: TextInputType.number,
              ),
              _gap(),
              _choiceGroup(
                title: _t(
                  'colaborador.contract.workMode',
                  'Regime de trabalho',
                ),
                values: const <String>['PRESENCIAL', 'HIBRIDO', 'REMOTO'],
                selected: _regimeTrabalho,
                label: _workModeLabel,
                onSelected: (String value) =>
                    setState(() => _regimeTrabalho = value),
              ),
              if (_tipoVinculo == 'PRESTACAO_SERVICO') ...<Widget>[
                _gap(),
                _field(
                  controller: _escopoServico,
                  label: _t(
                    'colaborador.contract.serviceScope',
                    'Escopo da prestação de serviço',
                  ),
                  icon: Icons.fact_check_outlined,
                  maxLines: 3,
                ),
              ],
              _gap(),
              _field(
                controller: _observacoes,
                label: _t(
                  'colaborador.contract.notes',
                  'Observações contratuais',
                ),
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _section(
          title: _t('colaborador.payment.title', 'Remuneração e pagamento'),
          subtitle: _t(
            'colaborador.payment.subtitle',
            'Condições financeiras e conta preferencial.',
          ),
          icon: Icons.payments_outlined,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _field(
                      controller: _valorBase,
                      label: _t('colaborador.payment.baseValue', 'Valor base'),
                      icon: Icons.monetization_on_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 108,
                    child: _choiceField(
                      label: _t('colaborador.payment.currency', 'Moeda'),
                      value: _moeda,
                      values: const <String>['BRL', 'USD', 'EUR'],
                      labelFor: (String value) => value,
                      onSelected: (String value) =>
                          setState(() => _moeda = value),
                    ),
                  ),
                ],
              ),
              _gap(),
              _choiceField(
                label: _t('colaborador.payment.frequency', 'Periodicidade'),
                value: _periodicidade,
                values: const <String>[
                  'MENSAL',
                  'QUINZENAL',
                  'SEMANAL',
                  'POR_SERVICO',
                ],
                labelFor: _frequencyLabel,
                onSelected: (String value) =>
                    setState(() => _periodicidade = value),
              ),
              _gap(),
              _field(
                controller: _diaPagamento,
                label: _t('colaborador.payment.day', 'Dia de pagamento'),
                icon: Icons.calendar_month_outlined,
                keyboardType: TextInputType.number,
              ),
              _gap(),
              _choiceField(
                label: _t('colaborador.payment.method', 'Método de pagamento'),
                value: _metodoPagamento,
                values: const <String>[
                  'TRANSFERENCIA',
                  'PIX',
                  'DINHEIRO',
                  'OUTRO',
                ],
                labelFor: _paymentMethodLabel,
                onSelected: (String value) =>
                    setState(() => _metodoPagamento = value),
              ),
              _gap(),
              _field(
                controller: _banco,
                label: _t('colaborador.payment.bank', 'Banco'),
                icon: Icons.account_balance_outlined,
              ),
              _gap(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _field(
                      controller: _agencia,
                      label: _t('colaborador.payment.branch', 'Agência'),
                      icon: Icons.numbers_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      controller: _conta,
                      label: _t('colaborador.payment.account', 'Conta'),
                      icon: Icons.credit_card_outlined,
                    ),
                  ),
                ],
              ),
              _gap(),
              _field(
                controller: _chavePix,
                label: _t('colaborador.payment.pix', 'Chave PIX'),
                icon: Icons.pix_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _permissionsSection() {
    return _section(
      title: _t('colaboradores.initialPermissions', 'Permissões iniciais'),
      subtitle: _t(
        'colaborador.permissions.subtitle',
        'As permissões essenciais continuam com o comportamento atual.',
      ),
      icon: Icons.security_outlined,
      child: Column(
        children: <Widget>[
          _permission(
            title: _t('colaboradores.sales', 'Vendas'),
            subtitle: _t('colaboradores.canCreateSales', 'Pode criar vendas.'),
            icon: Icons.point_of_sale_outlined,
            value: _fazVenda,
            onChanged: (bool value) => setState(() => _fazVenda = value),
          ),
          _permission(
            title: _t(
              'colaboradores.technicalAssistance',
              'Assistência técnica',
            ),
            subtitle: _t(
              'colaboradores.canCreateTechnicalServices',
              'Pode lançar atendimentos técnicos.',
            ),
            icon: Icons.handyman_outlined,
            value: _lancaServico,
            onChanged: (bool value) => setState(() => _lancaServico = value),
          ),
          _permission(
            title: _t('colaboradores.customers', 'Clientes'),
            subtitle: _t(
              'colaboradores.canEditCustomers',
              'Pode editar clientes.',
            ),
            icon: Icons.people_alt_outlined,
            value: _editaCliente,
            onChanged: (bool value) => setState(() => _editaCliente = value),
          ),
          _permission(
            title: _t('colaboradores.finance', 'Financeiro'),
            subtitle: _t(
              'colaboradores.canReceiveAtCashier',
              'Pode receber no caixa.',
            ),
            icon: Icons.account_balance_wallet_outlined,
            value: _podeReceberNoCaixa,
            onChanged: (bool value) =>
                setState(() => _podeReceberNoCaixa = value),
          ),
          _permission(
            title: _t('colaboradores.salesSummary', 'Resumo das vendas'),
            subtitle: _t(
              'colaboradores.canViewSalesSummary',
              'Pode consultar quanto vendeu.',
            ),
            icon: Icons.query_stats_outlined,
            value: _podeVerQuantoVendeu,
            onChanged: (bool value) =>
                setState(() => _podeVerQuantoVendeu = value),
          ),
          _permission(
            title: _t('colaboradores.reports', 'Relatórios'),
            subtitle: _t(
              'colaboradores.canGenerateReports',
              'Pode gerar relatórios.',
            ),
            icon: Icons.analytics_outlined,
            value: _geraRelatorio,
            onChanged: (bool value) => setState(() => _geraRelatorio = value),
          ),
          _permission(
            title: _t('colaboradores.permissions', 'Permissões'),
            subtitle: _t(
              'colaboradores.canManagePermissions',
              'Pode gerenciar permissões.',
            ),
            icon: Icons.verified_user_outlined,
            value: _gerenciaPermissoes,
            onChanged: (bool value) =>
                setState(() => _gerenciaPermissoes = value),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _colors.border),
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
                  color: _colors.softAccentSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _colors.accent),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: _colors.titleText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _colors.mutedText,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: _loading,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => setState(() {}),
      decoration: _input(label, icon),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: _loading ? null : () => _pickDate(controller, label),
      decoration: _input(label, icon).copyWith(
        suffixIcon: controller.text.isEmpty
            ? const Icon(Icons.calendar_today_outlined)
            : IconButton(
                onPressed: _loading ? null : () => setState(controller.clear),
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _colors.accent),
    filled: true,
    fillColor: _colors.softSurface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: _colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: _colors.accent, width: 1.4),
    ),
  );

  Future<void> _pickDate(TextEditingController controller, String title) async {
    DateTime selected = DateTime.tryParse(controller.text) ?? DateTime.now();
    final DateTime? result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        DateTime draft = selected;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) =>
              Container(
                decoration: BoxDecoration(
                  color: _colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _colors.strongBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: _colors.titleText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CalendarDatePicker(
                      initialDate: draft,
                      firstDate: DateTime(1940),
                      lastDate: DateTime(2100),
                      onDateChanged: (DateTime value) =>
                          setSheetState(() => draft = value),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Text(_t('common.cancel', 'Cancelar')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(draft),
                            child: Text(_t('common.apply', 'Aplicar')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() => controller.text = _isoDate(result));
    }
  }

  String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Widget _choiceGroup({
    required String title,
    required List<String> values,
    required String selected,
    required String Function(String) label,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: _colors.titleText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (String value) => ChoiceChip(
                  label: Text(label(value)),
                  selected: value == selected,
                  onSelected: _loading
                      ? null
                      : (bool active) {
                          if (active) onSelected(value);
                        },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _choiceField({
    required String label,
    required String value,
    required List<String> values,
    required String Function(String) labelFor,
    required ValueChanged<String> onSelected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _loading
          ? null
          : () => _pickChoice(
              title: label,
              selected: value,
              values: values,
              labelFor: labelFor,
              onSelected: onSelected,
            ),
      child: InputDecorator(
        decoration: _input(label, Icons.expand_more_rounded),
        child: Text(
          labelFor(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _colors.titleText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _pickChoice({
    required String title,
    required String selected,
    required List<String> values,
    required String Function(String) labelFor,
    required ValueChanged<String> onSelected,
  }) async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => Container(
        decoration: BoxDecoration(
          color: _colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: _colors.strongBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: _colors.titleText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ...values.map(
              (String value) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  value == selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: value == selected ? _colors.accent : _colors.mutedText,
                ),
                title: Text(
                  labelFor(value),
                  style: TextStyle(
                    color: _colors.titleText,
                    fontWeight: value == selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) onSelected(result);
  }

  Widget _permission({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: value ? _colors.softAccentSurface : _colors.softSurface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: value ? _colors.accent : _colors.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: value ? _colors.accent : _colors.mutedText,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: _colors.titleText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: _colors.mutedText, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: _loading ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions() {
    final bool last = _etapaAtual == _etapas.length - 1;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: _colors.surfaceElevated,
          border: Border(top: BorderSide(color: _colors.border)),
        ),
        child: Row(
          children: <Widget>[
            OutlinedButton(
              onPressed: _loading ? null : _back,
              child: Text(
                _etapaAtual == 0
                    ? _t('common.cancel', 'Cancelar')
                    : _t('common.back', 'Voltar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _loading ? null : _next,
                icon: _loading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        last
                            ? Icons.send_outlined
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  _loading
                      ? _t('colaborador.invite.generating', 'Gerando...')
                      : last
                      ? _t('colaborador.invite.generate', 'Gerar convite')
                      : _t('common.continue', 'Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteResult(ColaboradorConviteResponse convite) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.softAccentSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _colors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.mark_email_read_outlined, color: _colors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t('colaborador.invite.created', 'Convite criado'),
                  style: TextStyle(
                    color: _colors.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            _inviteLink(convite),
            style: TextStyle(color: _colors.mutedText, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _copiarLink,
              icon: const Icon(Icons.copy_outlined),
              label: Text(_t('colaborador.invite.copy', 'Copiar link')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 11);
  String? Function(String?) _required(String message) =>
      (String? value) => value == null || value.trim().isEmpty ? message : null;

  String _qualityLevel(NivelQualidadeCadastroColaborador level) =>
      switch (level) {
        NivelQualidadeCadastroColaborador.essencial => _t(
          'colaborador.quality.levelEssential',
          'Essencial',
        ),
        NivelQualidadeCadastroColaborador.prontoParaConvidar => _t(
          'colaborador.quality.levelReady',
          'Pronto para convidar',
        ),
        NivelQualidadeCadastroColaborador.bemPreparado => _t(
          'colaborador.quality.levelPrepared',
          'Bem preparado',
        ),
        NivelQualidadeCadastroColaborador.excelente => _t(
          'colaborador.quality.levelExcellent',
          'Excelente',
        ),
      };

  String _improvementLabel(CriterioQualidadeCadastroColaborador criterio) =>
      switch (criterio) {
        CriterioQualidadeCadastroColaborador.nome => _t(
          'colaborador.quality.actionName',
          'Informar nome',
        ),
        CriterioQualidadeCadastroColaborador.email => _t(
          'colaborador.quality.actionEmail',
          'Informar e-mail',
        ),
        CriterioQualidadeCadastroColaborador.celular => _t(
          'colaborador.quality.actionPhone',
          'Informar celular',
        ),
        CriterioQualidadeCadastroColaborador.permissoes => _t(
          'colaborador.quality.actionPermissions',
          'Revisar permissões',
        ),
        CriterioQualidadeCadastroColaborador.documentos => _t(
          'colaborador.quality.actionDocuments',
          'Completar documentos',
        ),
        CriterioQualidadeCadastroColaborador.endereco => _t(
          'colaborador.quality.actionAddress',
          'Completar endereço',
        ),
        CriterioQualidadeCadastroColaborador.funcao => _t(
          'colaborador.quality.actionRole',
          'Informar função',
        ),
        CriterioQualidadeCadastroColaborador.contrato => _t(
          'colaborador.quality.actionContract',
          'Detalhar contrato',
        ),
        CriterioQualidadeCadastroColaborador.remuneracao => _t(
          'colaborador.quality.actionCompensation',
          'Informar remuneração',
        ),
        CriterioQualidadeCadastroColaborador.pagamento => _t(
          'colaborador.quality.actionPayment',
          'Configurar pagamento',
        ),
      };

  String _contractTypeLabel(String value) => switch (value) {
    'PRESTACAO_SERVICO' => _t(
      'colaborador.contract.serviceProvider',
      'Prestação de serviço',
    ),
    'ESTAGIO' => _t('colaborador.contract.internship', 'Estágio'),
    'TEMPORARIO' => _t('colaborador.contract.temporary', 'Temporário'),
    _ => _t('colaborador.contract.employment', 'Contrato de trabalho'),
  };

  String _workModeLabel(String value) => switch (value) {
    'HIBRIDO' => _t('colaborador.contract.hybrid', 'Híbrido'),
    'REMOTO' => _t('colaborador.contract.remote', 'Remoto'),
    _ => _t('colaborador.contract.onsite', 'Presencial'),
  };

  String _frequencyLabel(String value) => switch (value) {
    'QUINZENAL' => _t('colaborador.payment.biweekly', 'Quinzenal'),
    'SEMANAL' => _t('colaborador.payment.weekly', 'Semanal'),
    'POR_SERVICO' => _t('colaborador.payment.perService', 'Por serviço'),
    _ => _t('colaborador.payment.monthly', 'Mensal'),
  };

  String _paymentMethodLabel(String value) => switch (value) {
    'PIX' => 'PIX',
    'DINHEIRO' => _t('colaborador.payment.cash', 'Dinheiro'),
    'OUTRO' => _t('colaborador.payment.other', 'Outro'),
    _ => _t('colaborador.payment.transfer', 'Transferência'),
  };
}
