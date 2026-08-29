import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/colaborador_convite_web_service.dart';
import '../../core/utils/colaborador_cadastro_quality.dart';
import '../../data/models/colaborador_convite_model.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/web_dashboard_widgets.dart';
import '../theme/web_theme_tokens.dart';

class ColaboradorConviteWebBody extends StatefulWidget {
  const ColaboradorConviteWebBody({super.key});

  @override
  State<ColaboradorConviteWebBody> createState() =>
      _ColaboradorConviteWebBodyState();
}

class _ColaboradorConviteWebBodyState extends State<ColaboradorConviteWebBody> {
  static const double _compactBreakpoint = 760;
  static const double _wideBreakpoint = 1180;

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
  bool _acessaEtiquetas = false;
  bool _geraRelatorio = false;
  bool _gerenciaPermissoes = false;
  bool _isLoading = false;
  ColaboradorConviteResponse? _ultimoConvite;

  bool get _cadastroCompleto =>
      _tipoCadastro == ColaboradorCadastroQuality.tipoCompleto;

  List<String> get _etapas => _cadastroCompleto
      ? <String>[
          _t('colaborador.journey.essentialStep', 'Essenciais'),
          _t('colaborador.journey.personalStep', 'Pessoa e endereço'),
          _t('colaborador.journey.contractStep', 'Contrato e pagamento'),
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

  List<String> _permissoesSelecionadas() => <String>[
    if (_fazVenda) 'VENDAS_CRIAR',
    if (_lancaServico) 'ASSISTENCIA_TECNICA_CRIAR',
    if (_editaCliente) 'CLIENTES_EDITAR',
    if (_podeReceberNoCaixa) 'FINANCEIRO_ACESSAR',
    if (_podeVerQuantoVendeu) 'VENDAS_CONSULTAR',
    if (_acessaEtiquetas) 'ETIQUETAS_GERENCIAR',
    if (_geraRelatorio) 'RELATORIOS_GERAR',
    if (_gerenciaPermissoes) 'PERMISSOES_GERENCIAR',
  ];

  QualidadeCadastroColaborador get _qualidade {
    final double valor = _parseDecimal(_valorBase.text);
    return ColaboradorCadastroQuality.calcular(
      tipoCadastro: _tipoCadastro,
      entrada: EntradaQualidadeCadastroColaborador(
        nomeInformado: _nome.text.trim().isNotEmpty,
        emailInformado: _email.text.trim().contains('@'),
        celularInformado:
            _celular.text.trim().replaceAll(RegExp(r'\D'), '').length >= 10,
        permissoesConfiguradas: _permissoesSelecionadas().isNotEmpty,
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
        remuneracaoInformada: valor > 0 && _moeda.isNotEmpty,
        pagamentoInformado:
            _periodicidade.isNotEmpty &&
            int.tryParse(_diaPagamento.text.trim()) != null,
      ),
    );
  }

  double _parseDecimal(String value) {
    String raw = value.trim().replaceAll(' ', '');
    if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      raw = raw.replaceAll(',', '.');
    }
    return double.tryParse(raw) ?? 0;
  }

  ColaboradorConviteRequest _request() {
    final QualidadeCadastroColaborador qualidade = _qualidade;
    return ColaboradorConviteRequest(
      nome: _nome.text.trim(),
      email: _email.text.trim(),
      celular: _celular.text.trim(),
      permissoes: _permissoesSelecionadas(),
      tipoCadastro: _tipoCadastro,
      percentualQualidadeCadastro: qualidade.percentual,
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
      _isLoading = true;
      _ultimoConvite = null;
    });

    try {
      final ColaboradorConviteResponse response = await _service.criarConvite(
        _request(),
      );
      if (!mounted) return;
      setState(() => _ultimoConvite = response);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _linkConvite(ColaboradorConviteResponse convite) =>
      '${Uri.base.origin}/colaborador/convites/${convite.codigo}';

  Future<void> _copiarLink() async {
    final ColaboradorConviteResponse? convite = _ultimoConvite;
    if (convite == null) return;
    await Clipboard.setData(ClipboardData(text: _linkConvite(convite)));
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

  void _selecionarTipo(String tipo) {
    if (_isLoading || _tipoCadastro == tipo) return;
    setState(() {
      _tipoCadastro = tipo;
      _etapaAtual = 0;
      _ultimoConvite = null;
    });
  }

  void _avancar() {
    if (_etapaAtual == 0 && !_formKey.currentState!.validate()) return;
    if (_etapaAtual < _etapas.length - 1) {
      setState(() => _etapaAtual += 1);
    } else {
      _criarConvite();
    }
  }

  void _voltar() {
    if (_etapaAtual > 0) {
      setState(() => _etapaAtual -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    context.watch<LocaleSettingsProvider>();
    return Material(
      color: tokens.surfaceElevated,
      child: Column(
        children: <Widget>[
          SixWebDashboardHeader(
            icon: Icons.group_add_outlined,
            title: _t('colaboradores.newCollaborator', 'Novo colaborador'),
            subtitle: _t(
              'colaborador.journey.subtitle',
              'Escolha a profundidade do cadastro e acompanhe a qualidade dos dados.',
            ),
            onBack: () => Navigator.of(context).pop(),
            actions: const <Widget>[],
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact =
                      constraints.maxWidth < _compactBreakpoint;
                  final bool wide = constraints.maxWidth >= _wideBreakpoint;
                  return Column(
                    children: <Widget>[
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SixWebEntry(
                                order: 0,
                                child: _modeSelector(compact),
                              ),
                              const SizedBox(height: 16),
                              SixWebEntry(
                                order: 1,
                                child: _qualityAndSteps(compact),
                              ),
                              const SizedBox(height: 18),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: KeyedSubtree(
                                  key: ValueKey<String>(
                                    '$_tipoCadastro-$_etapaAtual',
                                  ),
                                  child: _stepContent(
                                    compact: compact,
                                    wide: wide,
                                  ),
                                ),
                              ),
                              if (_ultimoConvite != null) ...<Widget>[
                                const SizedBox(height: 18),
                                _inviteResult(_ultimoConvite!),
                              ],
                            ],
                          ),
                        ),
                      ),
                      _actionsBar(compact),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSelector(bool compact) {
    final List<Widget> cards = <Widget>[
      _modeCard(
        type: ColaboradorCadastroQuality.tipoSimples,
        icon: Icons.bolt_rounded,
        title: _t('colaborador.journey.simple', 'Cadastro simples'),
        subtitle: _t(
          'colaborador.journey.simpleSubtitle',
          'Nome, e-mail, celular e permissões. Ideal para convidar rapidamente.',
        ),
      ),
      _modeCard(
        type: ColaboradorCadastroQuality.tipoCompleto,
        icon: Icons.assignment_ind_outlined,
        title: _t('colaborador.journey.complete', 'Cadastro completo'),
        subtitle: _t(
          'colaborador.journey.completeSubtitle',
          'Inclui documentos, endereço, função, contrato e pagamento.',
        ),
      ),
    ];
    return SixWebSectionCard(
      title: _t('colaborador.journey.choose', 'Escolha a jornada'),
      subtitle: _t(
        'colaborador.journey.chooseSubtitle',
        'Você pode trocar o nível sem perder os dados já preenchidos.',
      ),
      icon: Icons.route_outlined,
      child: compact
          ? Column(
              children: <Widget>[
                cards[0],
                const SizedBox(height: 12),
                cards[1],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ],
            ),
    );
  }

  Widget _modeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool selected = _tipoCadastro == type;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _selecionarTipo(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? tokens.selectedBackground : tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? tokens.selectedBorder : tokens.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tokens.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: tokens.info),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: tokens.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.secondaryText,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? tokens.info : tokens.statusNeutral,
            ),
          ],
        ),
      ),
    );
  }

  Widget _qualityAndSteps(bool compact) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final QualidadeCadastroColaborador qualidade = _qualidade;
    final LocaleSettingsProvider locale = context
        .read<LocaleSettingsProvider>();
    final List<MelhoriaQualidadeCadastroColaborador> melhorias = qualidade
        .melhorias
        .take(2)
        .toList(growable: false);
    final Widget quality = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: qualidade.percentual / 100),
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
                    color: tokens.info,
                    backgroundColor: tokens.cardBorder,
                  ),
                ),
                Text(
                  locale.formatPercent(value * 100),
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _t('colaborador.quality.title', 'Qualidade do cadastro'),
              style: TextStyle(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _qualityLevel(qualidade.nivel),
              style: TextStyle(
                color: tokens.info,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
    final Widget suggestions = melhorias.isEmpty
        ? Text(
            _t(
              'colaborador.quality.completeMessage',
              'Cadastro bem preparado para esta jornada.',
            ),
            style: TextStyle(color: tokens.secondaryText),
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: melhorias
                .map(
                  (MelhoriaQualidadeCadastroColaborador melhoria) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tokens.cardBorder),
                    ),
                    child: Text(
                      '${_improvementLabel(melhoria.criterio)} +${locale.formatPercent(melhoria.pontos)}',
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (compact) ...<Widget>[
            quality,
            const SizedBox(height: 12),
            suggestions,
          ] else
            Row(
              children: <Widget>[
                SizedBox(width: 290, child: quality),
                const SizedBox(width: 20),
                Expanded(child: suggestions),
              ],
            ),
          const SizedBox(height: 14),
          Divider(height: 1, color: tokens.cardBorder),
          const SizedBox(height: 14),
          Text(
            '${_t('colaborador.journey.step', 'Etapa')} ${_etapaAtual + 1} '
            '${_t('colaborador.journey.of', 'de')} ${_etapas.length} · ${_etapas[_etapaAtual]}',
            style: TextStyle(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List<Widget>.generate(_etapas.length, (int index) {
              final bool active = index <= _etapaAtual;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index == _etapas.length - 1 ? 0 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: active ? tokens.info : tokens.cardBorder,
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

  Widget _stepContent({required bool compact, required bool wide}) {
    if (_etapaAtual == 0) return _essentialSection(compact, wide);
    if (_cadastroCompleto && _etapaAtual == 1) {
      return _personalSection(compact, wide);
    }
    if (_cadastroCompleto && _etapaAtual == 2) {
      return _contractSection(compact, wide);
    }
    return _permissionsSection(compact, wide);
  }

  Widget _essentialSection(bool compact, bool wide) {
    final double width = compact ? double.infinity : (wide ? 350 : 300);
    return SixWebSectionCard(
      title: _t('colaborador.journey.essentialTitle', 'Dados essenciais'),
      subtitle: _t(
        'colaborador.journey.essentialSubtitle',
        'Informações usadas no convite e na identificação do colaborador.',
      ),
      icon: Icons.contact_mail_outlined,
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: <Widget>[
          _field(
            controller: _nome,
            label: _t('colaboradores.collaboratorName', 'Nome do colaborador'),
            icon: Icons.person_outline,
            width: width,
            validator: _required(
              _t('colaboradores.nameRequired', 'Informe o nome.'),
            ),
          ),
          _field(
            controller: _email,
            label: _t('colaboradores.loginEmail', 'E-mail de login'),
            icon: Icons.email_outlined,
            width: width,
            keyboardType: TextInputType.emailAddress,
            validator: (String? value) {
              if (value == null || !value.trim().contains('@')) {
                return _t(
                  'colaboradores.emailRequired',
                  'Informe um e-mail válido.',
                );
              }
              return null;
            },
          ),
          _field(
            controller: _celular,
            label: _t('colaboradores.phone', 'Celular'),
            icon: Icons.phone_outlined,
            width: compact ? double.infinity : 240,
            keyboardType: TextInputType.phone,
            validator: _required(
              _t('colaborador.validation.phone', 'Informe o celular.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalSection(bool compact, bool wide) {
    final double normal = compact ? double.infinity : (wide ? 280 : 250);
    final double large = compact ? double.infinity : (wide ? 420 : 350);
    return Column(
      children: <Widget>[
        SixWebSectionCard(
          title: _t('colaborador.personal.title', 'Dados pessoais'),
          subtitle: _t(
            'colaborador.personal.subtitle',
            'Documentos e identificação complementar. Campos não obrigatórios melhoram a qualidade.',
          ),
          icon: Icons.badge_outlined,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _field(
                controller: _nomeSocial,
                label: _t('colaborador.personal.socialName', 'Nome social'),
                icon: Icons.record_voice_over_outlined,
                width: large,
              ),
              _field(
                controller: _cpf,
                label: _t('colaborador.personal.taxId', 'CPF/documento fiscal'),
                icon: Icons.badge_outlined,
                width: normal,
              ),
              _field(
                controller: _rg,
                label: _t('colaborador.personal.identity', 'RG/identidade'),
                icon: Icons.credit_card_outlined,
                width: normal,
              ),
              _field(
                controller: _dataNascimento,
                label: _t('colaborador.personal.birthDate', 'Nascimento'),
                icon: Icons.cake_outlined,
                width: normal,
                hint: 'AAAA-MM-DD',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SixWebSectionCard(
          title: _t('colaborador.address.title', 'Endereço'),
          subtitle: _t(
            'colaborador.address.subtitle',
            'Endereço de referência do colaborador.',
          ),
          icon: Icons.home_work_outlined,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _field(
                controller: _cep,
                label: 'CEP',
                icon: Icons.pin_drop_outlined,
                width: compact ? double.infinity : 180,
              ),
              _field(
                controller: _logradouro,
                label: _t('colaborador.address.street', 'Logradouro'),
                icon: Icons.route_outlined,
                width: large,
              ),
              _field(
                controller: _numero,
                label: _t('colaborador.address.number', 'Número'),
                icon: Icons.numbers_outlined,
                width: compact ? double.infinity : 150,
              ),
              _field(
                controller: _complemento,
                label: _t('colaborador.address.complement', 'Complemento'),
                icon: Icons.add_home_outlined,
                width: normal,
              ),
              _field(
                controller: _bairro,
                label: _t('colaborador.address.district', 'Bairro'),
                icon: Icons.location_city_outlined,
                width: normal,
              ),
              _field(
                controller: _cidade,
                label: _t('colaborador.address.city', 'Cidade'),
                icon: Icons.location_on_outlined,
                width: normal,
              ),
              _field(
                controller: _estado,
                label: _t('colaborador.address.state', 'Estado'),
                icon: Icons.map_outlined,
                width: compact ? double.infinity : 160,
              ),
              _field(
                controller: _pais,
                label: _t('colaborador.address.country', 'País'),
                icon: Icons.public_outlined,
                width: compact ? double.infinity : 140,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contractSection(bool compact, bool wide) {
    final double normal = compact ? double.infinity : (wide ? 270 : 240);
    final double large = compact ? double.infinity : (wide ? 390 : 330);
    return Column(
      children: <Widget>[
        SixWebSectionCard(
          title: _t('colaborador.contract.title', 'Vínculo e contrato'),
          subtitle: _t(
            'colaborador.contract.subtitle',
            'Organize contratos de trabalho e de prestação de serviço no mesmo fluxo.',
          ),
          icon: Icons.assignment_outlined,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _dropdown(
                value: _tipoVinculo,
                label: _t('colaborador.contract.linkType', 'Tipo de vínculo'),
                icon: Icons.handshake_outlined,
                width: normal,
                values: const <String>[
                  'CLT',
                  'PRESTACAO_SERVICO',
                  'ESTAGIO',
                  'TEMPORARIO',
                  'OUTRO',
                ],
                labelFor: _contractTypeLabel,
                onChanged: (String value) =>
                    setState(() => _tipoVinculo = value),
              ),
              _field(
                controller: _numeroContrato,
                label: _t('colaborador.contract.number', 'Número do contrato'),
                icon: Icons.tag_outlined,
                width: normal,
              ),
              _field(
                controller: _cargo,
                label: _t('colaborador.contract.role', 'Cargo/função'),
                icon: Icons.work_outline,
                width: large,
              ),
              _field(
                controller: _departamento,
                label: _t('colaborador.contract.department', 'Departamento'),
                icon: Icons.account_tree_outlined,
                width: normal,
              ),
              _field(
                controller: _dataInicio,
                label: _t(
                  'colaborador.contract.startDate',
                  'Início do vínculo',
                ),
                icon: Icons.event_available_outlined,
                width: normal,
                hint: 'AAAA-MM-DD',
              ),
              _field(
                controller: _dataTermino,
                label: _t('colaborador.contract.endDate', 'Término previsto'),
                icon: Icons.event_busy_outlined,
                width: normal,
                hint: 'AAAA-MM-DD',
              ),
              _field(
                controller: _cargaHoraria,
                label: _t('colaborador.contract.weeklyHours', 'Horas semanais'),
                icon: Icons.schedule_outlined,
                width: compact ? double.infinity : 190,
                keyboardType: TextInputType.number,
              ),
              _dropdown(
                value: _regimeTrabalho,
                label: _t(
                  'colaborador.contract.workMode',
                  'Regime de trabalho',
                ),
                icon: Icons.laptop_mac_outlined,
                width: normal,
                values: const <String>['PRESENCIAL', 'HIBRIDO', 'REMOTO'],
                labelFor: _workModeLabel,
                onChanged: (String value) =>
                    setState(() => _regimeTrabalho = value),
              ),
              if (_tipoVinculo == 'PRESTACAO_SERVICO')
                _field(
                  controller: _escopoServico,
                  label: _t(
                    'colaborador.contract.serviceScope',
                    'Escopo da prestação de serviço',
                  ),
                  icon: Icons.fact_check_outlined,
                  width: compact ? double.infinity : (wide ? 660 : 560),
                  maxLines: 3,
                ),
              _field(
                controller: _observacoes,
                label: _t(
                  'colaborador.contract.notes',
                  'Observações contratuais',
                ),
                icon: Icons.notes_outlined,
                width: compact ? double.infinity : (wide ? 660 : 560),
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SixWebSectionCard(
          title: _t('colaborador.payment.title', 'Remuneração e pagamento'),
          subtitle: _t(
            'colaborador.payment.subtitle',
            'Condições financeiras e dados preferenciais de pagamento.',
          ),
          icon: Icons.payments_outlined,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _field(
                controller: _valorBase,
                label: _t('colaborador.payment.baseValue', 'Valor base'),
                icon: Icons.monetization_on_outlined,
                width: normal,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _dropdown(
                value: _moeda,
                label: _t('colaborador.payment.currency', 'Moeda'),
                icon: Icons.currency_exchange_outlined,
                width: compact ? double.infinity : 160,
                values: const <String>['BRL', 'USD', 'EUR'],
                labelFor: (String value) => value,
                onChanged: (String value) => setState(() => _moeda = value),
              ),
              _dropdown(
                value: _periodicidade,
                label: _t('colaborador.payment.frequency', 'Periodicidade'),
                icon: Icons.repeat_outlined,
                width: normal,
                values: const <String>[
                  'MENSAL',
                  'QUINZENAL',
                  'SEMANAL',
                  'POR_SERVICO',
                ],
                labelFor: _frequencyLabel,
                onChanged: (String value) =>
                    setState(() => _periodicidade = value),
              ),
              _field(
                controller: _diaPagamento,
                label: _t('colaborador.payment.day', 'Dia de pagamento'),
                icon: Icons.calendar_month_outlined,
                width: compact ? double.infinity : 190,
                keyboardType: TextInputType.number,
              ),
              _dropdown(
                value: _metodoPagamento,
                label: _t('colaborador.payment.method', 'Método de pagamento'),
                icon: Icons.account_balance_wallet_outlined,
                width: normal,
                values: const <String>[
                  'TRANSFERENCIA',
                  'PIX',
                  'DINHEIRO',
                  'OUTRO',
                ],
                labelFor: _paymentMethodLabel,
                onChanged: (String value) =>
                    setState(() => _metodoPagamento = value),
              ),
              _field(
                controller: _banco,
                label: _t('colaborador.payment.bank', 'Banco'),
                icon: Icons.account_balance_outlined,
                width: normal,
              ),
              _field(
                controller: _agencia,
                label: _t('colaborador.payment.branch', 'Agência'),
                icon: Icons.numbers_outlined,
                width: compact ? double.infinity : 170,
              ),
              _field(
                controller: _conta,
                label: _t('colaborador.payment.account', 'Conta'),
                icon: Icons.credit_card_outlined,
                width: normal,
              ),
              _field(
                controller: _chavePix,
                label: _t('colaborador.payment.pix', 'Chave PIX'),
                icon: Icons.pix_outlined,
                width: large,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _permissionsSection(bool compact, bool wide) {
    final List<Widget> cards = <Widget>[
      _switchCard(
        title: _t('colaboradores.sales', 'Vendas'),
        subtitle: _t('colaboradores.canCreateSales', 'Pode criar vendas.'),
        icon: Icons.point_of_sale_outlined,
        value: _fazVenda,
        onChanged: (bool value) => setState(() => _fazVenda = value),
      ),
      _switchCard(
        title: _t('colaboradores.technicalAssistance', 'Assistência técnica'),
        subtitle: _t(
          'colaboradores.canCreateTechnicalServices',
          'Pode lançar atendimentos técnicos.',
        ),
        icon: Icons.handyman_outlined,
        value: _lancaServico,
        onChanged: (bool value) => setState(() => _lancaServico = value),
      ),
      _switchCard(
        title: _t('colaboradores.customers', 'Clientes'),
        subtitle: _t('colaboradores.canEditCustomers', 'Pode editar clientes.'),
        icon: Icons.people_alt_outlined,
        value: _editaCliente,
        onChanged: (bool value) => setState(() => _editaCliente = value),
      ),
      _switchCard(
        title: _t('colaboradores.finance', 'Financeiro'),
        subtitle: _t(
          'colaboradores.canReceiveAtCashier',
          'Pode receber no caixa.',
        ),
        icon: Icons.account_balance_wallet_outlined,
        value: _podeReceberNoCaixa,
        onChanged: (bool value) => setState(() => _podeReceberNoCaixa = value),
      ),
      _switchCard(
        title: _t('colaboradores.salesSummary', 'Resumo das vendas'),
        subtitle: _t(
          'colaboradores.canViewSalesSummary',
          'Pode consultar o resumo das vendas.',
        ),
        icon: Icons.query_stats_outlined,
        value: _podeVerQuantoVendeu,
        onChanged: (bool value) => setState(() => _podeVerQuantoVendeu = value),
      ),
      _switchCard(
        title: _t('colaboradores.labels', 'Etiquetas'),
        subtitle: _t(
          'colaboradores.canManageLabels',
          'Pode criar e gerar etiquetas.',
        ),
        icon: Icons.local_offer_outlined,
        value: _acessaEtiquetas,
        onChanged: (bool value) => setState(() => _acessaEtiquetas = value),
      ),
      _switchCard(
        title: _t('colaboradores.reports', 'Relatórios'),
        subtitle: _t(
          'colaboradores.canGenerateReports',
          'Pode gerar relatórios.',
        ),
        icon: Icons.analytics_outlined,
        value: _geraRelatorio,
        onChanged: (bool value) => setState(() => _geraRelatorio = value),
      ),
      _switchCard(
        title: _t('colaboradores.permissions', 'Permissões'),
        subtitle: _t(
          'colaboradores.canManagePermissions',
          'Pode gerenciar permissões.',
        ),
        icon: Icons.verified_user_outlined,
        value: _gerenciaPermissoes,
        onChanged: (bool value) => setState(() => _gerenciaPermissoes = value),
      ),
    ];
    return SixWebSectionCard(
      title: _t('colaboradores.initialPermissions', 'Permissões iniciais'),
      subtitle: _t(
        'colaborador.permissions.subtitle',
        'As permissões essenciais continuam com o comportamento atual.',
      ),
      icon: Icons.security_outlined,
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: cards
            .map(
              (Widget child) => SizedBox(
                width: compact ? double.infinity : (wide ? 330 : 300),
                child: child,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double width,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: _isLoading,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _decoration(label, icon, hint: hint),
        validator: validator,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required IconData icon,
    required double width,
    required List<String> values,
    required String Function(String) labelFor,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _decoration(label, icon),
        items: values
            .map(
              (String item) => DropdownMenuItem<String>(
                value: item,
                child: Text(labelFor(item), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(growable: false),
        onChanged: _isLoading
            ? null
            : (String? selected) {
                if (selected != null) onChanged(selected);
              },
      ),
    );
  }

  String? Function(String?) _required(String message) =>
      (String? value) => value == null || value.trim().isEmpty ? message : null;

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: tokens.info),
      filled: true,
      fillColor: tokens.inputBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: value ? tokens.selectedBackground : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? tokens.selectedBorder : tokens.cardBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: value ? tokens.info : tokens.statusNeutral),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: _isLoading ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionsBar(bool compact) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool last = _etapaAtual == _etapas.length - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border(top: BorderSide(color: tokens.cardBorder)),
      ),
      child: Row(
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _voltar,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(
              _etapaAtual == 0
                  ? _t('common.cancel', 'Cancelar')
                  : _t('common.back', 'Voltar'),
            ),
          ),
          const Spacer(),
          if (_ultimoConvite != null) ...<Widget>[
            OutlinedButton.icon(
              onPressed: _copiarLink,
              icon: const Icon(Icons.copy_outlined),
              label: Text(_t('colaborador.invite.copy', 'Copiar link')),
            ),
            const SizedBox(width: 10),
          ],
          FilledButton.icon(
            onPressed: _isLoading ? null : _avancar,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    last ? Icons.send_outlined : Icons.arrow_forward_rounded,
                  ),
            label: Text(
              _isLoading
                  ? _t('colaborador.invite.generating', 'Gerando convite...')
                  : last
                  ? _t('colaborador.invite.generate', 'Gerar convite')
                  : _t('common.continue', 'Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inviteResult(ColaboradorConviteResponse convite) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.selectedBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.selectedBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.mark_email_read_outlined, color: tokens.info, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _t('colaborador.invite.created', 'Convite criado'),
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  _linkConvite(convite),
                  style: TextStyle(color: tokens.secondaryText),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _copiarLink,
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
    );
  }

  String _contractTypeLabel(String value) => switch (value) {
    'PRESTACAO_SERVICO' => _t(
      'colaborador.contract.serviceProvider',
      'Prestação de serviço',
    ),
    'ESTAGIO' => _t('colaborador.contract.internship', 'Estágio'),
    'TEMPORARIO' => _t('colaborador.contract.temporary', 'Temporário'),
    'OUTRO' => _t('colaborador.contract.other', 'Outro'),
    _ => _t('colaborador.contract.employment', 'Contrato de trabalho (CLT)'),
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
    _ => _t('colaborador.payment.transfer', 'Transferência bancária'),
  };
}
