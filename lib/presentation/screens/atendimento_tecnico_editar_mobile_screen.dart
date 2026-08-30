import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/produto_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../design_system/themes/six_mobile_palette.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../l10n/six_i18n.dart';
import '../../providers/locale_settings_provider.dart';
import '../components/date_selector_mobile_bottom_sheet.dart';
import '../components/mobile/six_mobile_page_shell.dart';
import '../utils/atendimento_tecnico_foto_payload.dart';
import 'cliente_usuario_cadastro_mobile_screen.dart';
import 'produto_list_mobile_screen.dart';

class AtendimentoTecnicoEditarMobileScreen extends StatefulWidget {
  const AtendimentoTecnicoEditarMobileScreen({
    super.key,
    required this.atendimento,
    this.service,
    this.clienteApiClient,
    this.colaboradorApiClient,
  });

  final AtendimentoTecnicoModel atendimento;
  final AtendimentoTecnicoService? service;
  final ClienteUsuarioApiClient? clienteApiClient;
  final ColaboradorUsuarioApiClient? colaboradorApiClient;

  @override
  State<AtendimentoTecnicoEditarMobileScreen> createState() =>
      _AtendimentoTecnicoEditarMobileScreenState();
}

class _AtendimentoTecnicoEditarMobileScreenState
    extends State<AtendimentoTecnicoEditarMobileScreen> {
  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _primaryColor => SixMobilePalette.primary;
  static Color get _secondaryColor => SixMobilePalette.secondary;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softSurfaceColor => SixMobilePalette.softNeutralSurface;
  static Color get _softAccentSurfaceColor =>
      SixMobilePalette.softAccentSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _onPrimaryColor => SixMobilePalette.onPrimary;
  static Color get _heroSupportingTextColor =>
      SixMobilePalette.heroSupportingText;
  static Color get _heroShadowColor => SixMobilePalette.heroShadow;
  static Color get _cardShadowColor => SixMobilePalette.navigationShadow;

  late final AtendimentoTecnicoService _service;
  late final ClienteUsuarioApiClient _clienteApiClient;
  late final ColaboradorUsuarioApiClient _colaboradorApiClient;
  final List<_AtendimentoItemEditavelMobile> _itens =
      <_AtendimentoItemEditavelMobile>[];
  final List<AtendimentoTecnicoFotoInput> _fotos =
      <AtendimentoTecnicoFotoInput>[];
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _descricaoController;
  late final TextEditingController _tipoController;
  late final TextEditingController _marcaController;
  late final TextEditingController _modeloController;
  late final TextEditingController _numeroSerieController;
  late final TextEditingController _imeiController;
  late final TextEditingController _acessoriosController;
  late final TextEditingController _defeitoController;
  late final TextEditingController _diagnosticoController;
  late final TextEditingController _observacaoAuditoriaController;

  List<_ClienteAtendimentoMobile> _clientes = <_ClienteAtendimentoMobile>[];
  List<_ResponsavelTecnicoMobile> _responsaveis = <_ResponsavelTecnicoMobile>[];
  _ClienteAtendimentoMobile? _clienteSelecionado;
  _ResponsavelTecnicoMobile? _responsavelSelecionado;
  late DateTime _validadeOrcamentoEm;
  late DateTime _vencimentoFinanceiroEm;
  late DateTime _dataEntregaPrevista;
  bool _salvando = false;
  bool _carregandoDados = false;

  double get _totalItens => _itens.fold<double>(
    0,
    (double total, _AtendimentoItemEditavelMobile item) => total + item.total,
  );

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AtendimentoTecnicoService();
    _clienteApiClient =
        widget.clienteApiClient ?? HttpClienteUsuarioApiClient();
    _colaboradorApiClient =
        widget.colaboradorApiClient ?? HttpColaboradorUsuarioApiClient();
    final AtendimentoTecnicoModel atendimento = widget.atendimento;
    final AtendimentoTecnicoEquipamentoModel equipamento =
        atendimento.equipamento ?? AtendimentoTecnicoEquipamentoModel();

    _clienteSelecionado = _clienteInicial(atendimento);
    _responsavelSelecionado = _responsavelInicial(atendimento);
    _clientes = <_ClienteAtendimentoMobile>[
      if (_clienteSelecionado != null) _clienteSelecionado!,
    ];

    _descricaoController = TextEditingController(
      text: atendimento.descricao ?? '',
    );
    _tipoController = TextEditingController(text: equipamento.tipo ?? '');
    _marcaController = TextEditingController(text: equipamento.marca ?? '');
    _modeloController = TextEditingController(text: equipamento.modelo ?? '');
    _numeroSerieController = TextEditingController(
      text: equipamento.numeroSerie ?? '',
    );
    _imeiController = TextEditingController(text: equipamento.imei ?? '');
    _acessoriosController = TextEditingController(
      text: equipamento.acessorios ?? equipamento.observacoesEntrada ?? '',
    );
    _defeitoController = TextEditingController(
      text: atendimento.defeitoRelatado ?? '',
    );
    _diagnosticoController = TextEditingController(
      text: atendimento.diagnosticoTecnico ?? '',
    );
    _observacaoAuditoriaController = TextEditingController(
      text: 'Atualização realizada pelo mobile.',
    );

    _validadeOrcamentoEm = _normalizarData(
      atendimento.validadeOrcamentoEm ?? DateTime.now().add(Duration(days: 7)),
    );
    _vencimentoFinanceiroEm = _normalizarData(
      atendimento.dataVencimentoEm ?? _validadeOrcamentoEm,
    );
    _dataEntregaPrevista = _normalizarData(
      atendimento.dataEntregaPrevista ?? _validadeOrcamentoEm,
    );
    _itens.addAll(
      atendimento.itens.map(_AtendimentoItemEditavelMobile.fromModel),
    );
    _fotos.addAll(
      atendimento.fotos.map(AtendimentoTecnicoFotoPayload.fromModel),
    );
    _carregarCadastros();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _tipoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _numeroSerieController.dispose();
    _imeiController.dispose();
    _acessoriosController.dispose();
    _defeitoController.dispose();
    _diagnosticoController.dispose();
    _observacaoAuditoriaController.dispose();
    super.dispose();
  }

  Future<void> _carregarCadastros() async {
    if (mounted) {
      setState(() => _carregandoDados = true);
    }

    try {
      final ClienteUsuarioListResponse clientesResponse =
          await _clienteApiClient.listarClientesUsuario();
      final List<ColaboradorUsuarioResumo> colaboradores =
          await _colaboradorApiClient.listarTecnicosAssistenciaTecnica();
      final List<_ClienteAtendimentoMobile> clientes = clientesResponse.clientes
          .where((ClienteUsuario cliente) => cliente.ativo)
          .map(_ClienteAtendimentoMobile.fromCliente)
          .toList(growable: true);
      final List<_ResponsavelTecnicoMobile> responsaveis = _montarResponsaveis(
        colaboradores,
      ).toList(growable: true);

      final _ClienteAtendimentoMobile? clienteAtual = _clienteSelecionado;
      if (clienteAtual != null &&
          !clientes.any(
            (_ClienteAtendimentoMobile item) => item.id == clienteAtual.id,
          )) {
        clientes.insert(0, clienteAtual);
      }

      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _responsaveis = responsaveis;
        _clienteSelecionado = _resolverClienteSelecionado(clientes);
        _responsavelSelecionado = _resolverResponsavelSelecionado(responsaveis);
        _carregandoDados = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoDados = false);
      _mostrarMensagem('Não foi possível carregar clientes e responsáveis.');
    }
  }

  _ClienteAtendimentoMobile? _clienteInicial(
    AtendimentoTecnicoModel atendimento,
  ) {
    final String id = atendimento.idCliente?.trim() ?? '';
    final String nome = atendimento.nomeClienteSnapshot?.trim() ?? '';
    if (id.isEmpty && nome.isEmpty) return null;
    return _ClienteAtendimentoMobile(
      id: id,
      nome: nome.isEmpty ? 'Cliente não informado' : nome,
      subtitulo:
          id.isEmpty ? 'Snapshot do atendimento' : 'Cliente do atendimento',
      nomeInformado: nome.isNotEmpty,
      podeSincronizarCadastro: nome.isNotEmpty,
    );
  }

  _ResponsavelTecnicoMobile? _responsavelInicial(
    AtendimentoTecnicoModel atendimento,
  ) {
    final String id = atendimento.idTecnicoResponsavel?.trim() ?? '';
    final String nome =
        atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    if (id.isEmpty && nome.isEmpty) return null;
    return _ResponsavelTecnicoMobile(
      id: id,
      nome: nome.isEmpty ? 'Responsável não informado' : nome,
      subtitulo:
          id.isEmpty ? 'Snapshot do atendimento' : 'Responsável do atendimento',
    );
  }

  _ClienteAtendimentoMobile? _resolverClienteSelecionado(
    List<_ClienteAtendimentoMobile> clientes,
  ) {
    final _ClienteAtendimentoMobile? atual = _clienteSelecionado;
    if (atual == null) return null;
    if (!atual.podeSincronizarCadastro || atual.id.trim().isEmpty) {
      return atual;
    }
    return clientes.firstWhere(
      (_ClienteAtendimentoMobile item) => item.id == atual.id,
      orElse: () => atual,
    );
  }

  _ResponsavelTecnicoMobile? _resolverResponsavelSelecionado(
    List<_ResponsavelTecnicoMobile> responsaveis,
  ) {
    if (responsaveis.isEmpty) return null;
    final _ResponsavelTecnicoMobile? atual = _responsavelSelecionado;
    if (atual == null) return null;
    for (final _ResponsavelTecnicoMobile responsavel in responsaveis) {
      if (responsavel.id == atual.id) return responsavel;
    }
    return atual;
  }

  List<_ResponsavelTecnicoMobile> _montarResponsaveis(
    List<ColaboradorUsuarioResumo> colaboradores,
  ) {
    final Map<String, _ResponsavelTecnicoMobile> mapa =
        <String, _ResponsavelTecnicoMobile>{};

    void add(_ResponsavelTecnicoMobile responsavel) {
      final String key =
          responsavel.id.trim().isNotEmpty
              ? responsavel.id.trim()
              : responsavel.nome.toLowerCase().trim();
      if (key.isEmpty || mapa.containsKey(key)) return;
      mapa[key] = responsavel;
    }

    for (final ColaboradorUsuarioResumo colaborador in colaboradores) {
      if (!colaborador.ehTecnicoAssistenciaTecnica) continue;
      final String id =
          colaborador.idUnicoPessoal.trim().isNotEmpty
              ? colaborador.idUnicoPessoal.trim()
              : colaborador.email.trim();
      final String nome =
          colaborador.nomeDeGuerra.trim().isNotEmpty
              ? colaborador.nomeDeGuerra.trim()
              : colaborador.nome.trim().isNotEmpty
              ? colaborador.nome.trim()
              : colaborador.email.trim();
      if (id.isEmpty && nome.isEmpty) continue;

      final String subtitulo = <String>[
        'Colaborador',
        colaborador.email,
        colaborador.celularDeAcesso,
      ].where((String item) => item.trim().isNotEmpty).join(' • ');

      add(
        _ResponsavelTecnicoMobile(
          id: id.isEmpty ? nome : id,
          nome: nome.isEmpty ? 'Colaborador' : nome,
          subtitulo: subtitulo,
        ),
      );
    }

    return mapa.values.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    context.select<LocaleSettingsProvider, String>(
      (LocaleSettingsProvider provider) =>
          '${provider.currencyCode}|${provider.thousandSeparator}|'
          '${provider.decimalSeparator}|${provider.decimalPlaces}|'
          '${provider.dateFormat}',
    );

    return SixMobilePageShell(
      title: _t('atendimentoTecnico.mobile.editTitle', 'Editar atendimento'),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      enableAnimatedBackground: false,
      toolbarHeight: 48,
      initialContentSpacing: 8,
      scrollEffectOffset: 28,
      scrolledSurfaceOpacity: 0.70,
      leading: IconButton(
        tooltip: _t('common.back', 'Voltar'),
        icon: Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bodyBuilder: _buildContent,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    double topInset,
  ) {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _carregarCadastros,
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 24),
          children: <Widget>[_hero(), SizedBox(height: 16), _formCard()],
        ),
      ),
    );
  }

  String _t(String key, String fallback) => context.t(key, fallback: fallback);

  Widget _hero() {
    final String cliente =
        _clienteSelecionado?.nome.trim().isNotEmpty == true
            ? _clienteSelecionado!.nome
            : _clienteLabel(widget.atendimento);
    final String? responsavel = _responsavelSelecionado?.nome;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _heroShadowColor,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Color(0x33FFFFFF)),
            ),
            child: Icon(Icons.edit_note_rounded, color: _onPrimaryColor),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.atendimento.numero,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _onPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  responsavel == null || responsavel.trim().isEmpty
                      ? '$cliente • ${_itens.length} item(ns)'
                      : '$cliente • $responsavel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _heroSupportingTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionTitle('Dados principais'),
          SizedBox(height: 12),
          if (_carregandoDados) ...<Widget>[
            LinearProgressIndicator(minHeight: 3),
            SizedBox(height: 12),
          ],
          _clienteSelectorField(),
          SizedBox(height: 12),
          _responsavelSelectorField(),
          SizedBox(height: 12),
          TextField(
            controller: _descricaoController,
            decoration: _inputDecoration(
              label: 'Descrição interna',
              icon: Icons.notes_outlined,
            ),
          ),
          SizedBox(height: 16),
          _sectionTitle('Equipamento'),
          SizedBox(height: 12),
          TextField(
            controller: _tipoController,
            decoration: _inputDecoration(
              label: 'Tipo de equipamento',
              icon: Icons.devices_other_outlined,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _marcaController,
                  decoration: _inputDecoration(
                    label: 'Marca',
                    icon: Icons.business_outlined,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _modeloController,
                  decoration: _inputDecoration(
                    label: 'Modelo',
                    icon: Icons.category_outlined,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _numeroSerieController,
                  decoration: _inputDecoration(
                    label: 'Nº série',
                    icon: Icons.confirmation_number_outlined,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _imeiController,
                  decoration: _inputDecoration(
                    label: 'IMEI',
                    icon: Icons.qr_code_2_outlined,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _acessoriosController,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDecoration(
              label: 'Acessórios / observações',
              icon: Icons.cable_outlined,
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 16),
          _sectionTitle('Relato técnico'),
          SizedBox(height: 12),
          TextField(
            controller: _defeitoController,
            minLines: 3,
            maxLines: 5,
            decoration: _inputDecoration(
              label: 'Defeito relatado pelo cliente',
              icon: Icons.report_problem_outlined,
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _diagnosticoController,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration(
              label: 'Diagnóstico técnico',
              icon: Icons.engineering_outlined,
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 16),
          _photosSectionMobile(),
          SizedBox(height: 16),
          _sectionTitle('Datas'),
          SizedBox(height: 12),
          _dateTile(
            label: 'Entrega prevista',
            value: _formatarData(_dataEntregaPrevista),
            onTap: _selecionarEntregaPrevista,
          ),
          SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _dateTile(
                  label: 'Validade',
                  value: _formatarData(_validadeOrcamentoEm),
                  onTap: _selecionarValidade,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _dateTile(
                  label: 'Vencimento financeiro',
                  value: _formatarData(_vencimentoFinanceiroEm),
                  onTap: _selecionarVencimento,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _itensSection(),
          SizedBox(height: 16),
          _sectionTitle('Auditoria'),
          SizedBox(height: 12),
          TextField(
            controller: _observacaoAuditoriaController,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration(
              label: 'Observação da alteração',
              icon: Icons.manage_history_rounded,
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon:
                  _salvando
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.3),
                      )
                      : Icon(Icons.save_outlined),
              label: Text(_salvando ? 'Salvando...' : 'Salvar atendimento'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clienteSelectorField() {
    final _ClienteAtendimentoMobile? cliente = _clienteSelecionado;
    final bool hasSelection = cliente != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _abrirSelecaoCliente,
        child: InputDecorator(
          isEmpty: false,
          decoration: _inputDecoration(
            label: 'Cliente',
            icon: Icons.person_search_outlined,
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Text(
            hasSelection ? cliente.nome : 'Selecione um cliente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasSelection ? _titleTextColor : _mutedTextColor,
              fontWeight: hasSelection ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _responsavelSelectorField() {
    final _ResponsavelTecnicoMobile? responsavel = _responsavelSelecionado;
    final bool hasSelection = responsavel != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _abrirSelecaoResponsavel,
        child: InputDecorator(
          isEmpty: false,
          decoration: _inputDecoration(
            label: 'Responsável técnico',
            icon: Icons.engineering_outlined,
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
          ),
          child: Text(
            hasSelection ? responsavel.nome : 'Selecione o responsável',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasSelection ? _titleTextColor : _mutedTextColor,
              fontWeight: hasSelection ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirSelecaoCliente() async {
    final Object? result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext context) {
        return _ClienteAtendimentoSelectorMobile(
          clientes: _clientes,
          clienteSelecionado: _clienteSelecionado,
        );
      },
    );

    if (result == null || !mounted) return;
    if (result is _CadastrarClienteAtendimentoAction) {
      await _cadastrarClientePeloAtendimento();
      return;
    }
    if (result is _ClienteAtendimentoMobile) {
      setState(() => _clienteSelecionado = result);
    }
  }

  Future<void> _cadastrarClientePeloAtendimento() async {
    final ClienteUsuario? cliente = await Navigator.of(
      context,
    ).push<ClienteUsuario>(
      MaterialPageRoute<ClienteUsuario>(
        builder:
            (_) => ClienteUsuarioCadastroMobileScreen(
              apiClient: _clienteApiClient,
              returnSavedCliente: true,
            ),
      ),
    );

    if (cliente == null || !mounted) return;
    final _ClienteAtendimentoMobile atendimentoCliente =
        _ClienteAtendimentoMobile.fromCliente(cliente);
    setState(() {
      final List<_ClienteAtendimentoMobile> clientes =
          _clientes
              .where(
                (_ClienteAtendimentoMobile item) =>
                    item.id != atendimentoCliente.id,
              )
              .toList();
      clientes.insert(0, atendimentoCliente);
      _clientes = clientes;
      _clienteSelecionado = atendimentoCliente;
    });
  }

  Future<void> _abrirSelecaoResponsavel() async {
    if (_responsaveis.isEmpty) {
      _mostrarMensagem('Nenhum responsável técnico disponível para seleção.');
      return;
    }

    final _ResponsavelTecnicoMobile? responsavel =
        await showModalBottomSheet<_ResponsavelTecnicoMobile>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Color(0x66000000),
          builder: (BuildContext context) {
            return _ResponsavelTecnicoSelectorMobile(
              responsaveis: _responsaveis,
              responsavelSelecionado: _responsavelSelecionado,
            );
          },
        );

    if (responsavel == null || !mounted) return;
    setState(() => _responsavelSelecionado = responsavel);
  }

  Widget _photosSectionMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _t('atendimentoTecnico.photos.title', 'Fotos do serviço'),
                    style: TextStyle(
                      color: _titleTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    _t(
                      'atendimentoTecnico.photos.hint',
                      'Registre o estado do equipamento. Máximo de 10 fotos.',
                    ),
                    style: TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _softAccentSurfaceColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_fotos.length}/${AtendimentoTecnicoFotoPayload.maxFotos}',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 116,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              if (_fotos.length < AtendimentoTecnicoFotoPayload.maxFotos)
                _addPhotoTileMobile(),
              ..._fotos.asMap().entries.map(
                (MapEntry<int, AtendimentoTecnicoFotoInput> entry) =>
                    _photoTileMobile(entry.key, entry.value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _addPhotoTileMobile() {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: _salvando ? null : _selecionarFotosMobile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 104,
          decoration: BoxDecoration(
            color: _softSurfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_a_photo_outlined, color: _accentColor),
              const SizedBox(height: 7),
              Text(
                _t('atendimentoTecnico.photos.add', 'Adicionar'),
                style: TextStyle(
                  color: _titleTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoTileMobile(int index, AtendimentoTecnicoFotoInput foto) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              AtendimentoTecnicoFotoPayload.previewBytes(foto),
              width: 104,
              height: 116,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: Material(
              color: Colors.black.withValues(alpha: 0.62),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap:
                    _salvando
                        ? null
                        : () => setState(() => _fotos.removeAt(index)),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarFotosMobile() async {
    if (_fotos.length >= AtendimentoTecnicoFotoPayload.maxFotos) {
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.photos.limit',
          'O limite é de 10 fotos por atendimento.',
        ),
      );
      return;
    }
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder:
          (BuildContext context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(_t('atendimentoTecnico.photos.camera', 'Câmera')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(_t('atendimentoTecnico.photos.gallery', 'Galeria')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
    );
    if (source == null || !mounted) return;

    try {
      final List<XFile> arquivos;
      if (source == ImageSource.camera) {
        final XFile? arquivo = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 72,
        );
        arquivos = arquivo == null ? <XFile>[] : <XFile>[arquivo];
      } else {
        arquivos = await _imagePicker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 72,
        );
      }
      final int restantes =
          AtendimentoTecnicoFotoPayload.maxFotos - _fotos.length;
      final List<AtendimentoTecnicoFotoInput> adicionadas =
          <AtendimentoTecnicoFotoInput>[];
      for (final XFile arquivo in arquivos.take(restantes)) {
        adicionadas.add(await AtendimentoTecnicoFotoPayload.fromXFile(arquivo));
      }
      if (!mounted || adicionadas.isEmpty) return;
      setState(() => _fotos.addAll(adicionadas));
    } on AtendimentoTecnicoFotoException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(_photoErrorMessage(error.code));
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        _t(
          'atendimentoTecnico.photos.readError',
          'Não foi possível carregar a foto selecionada.',
        ),
      );
    }
  }

  String _photoErrorMessage(String code) {
    return switch (code) {
      'PHOTO_TOO_LARGE' => _t(
        'atendimentoTecnico.photos.tooLarge',
        'A foto ficou muito grande. Tente outra imagem ou reduza a resolução.',
      ),
      'PHOTO_FORMAT_UNSUPPORTED' => _t(
        'atendimentoTecnico.photos.formatUnsupported',
        'Use fotos nos formatos JPG ou PNG.',
      ),
      _ => _t(
        'atendimentoTecnico.photos.invalid',
        'A foto selecionada não é válida.',
      ),
    };
  }

  Widget _itensSection() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.inventory_2_outlined, color: _accentColor),
              SizedBox(width: 8),
              Expanded(child: _sectionTitle('Produtos e serviços')),
              Text(
                _formatarMoeda(_totalItens),
                style: TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_itens.isEmpty) _emptyItens() else ..._itens.map(_itemTile),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _salvando ? null : _abrirSelecaoItens,
              icon: Icon(Icons.add_shopping_cart_rounded),
              label: Text('Adicionar produto ou serviço'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyItens() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SixMobilePalette.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        'Nenhum produto ou serviço vinculado. Adicione itens para compor o atendimento.',
        style: TextStyle(color: _mutedTextColor, height: 1.35),
      ),
    );
  }

  Widget _itemTile(_AtendimentoItemEditavelMobile item) {
    final bool servico = item.isServico;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SixMobilePalette.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _softAccentSurfaceColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    servico
                        ? Icons.handyman_outlined
                        : Icons.inventory_2_outlined,
                    color: _accentColor,
                    size: 21,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '${servico ? 'Serviço' : 'Produto'} • ${_formatarMoeda(item.valorUnitario)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _salvando ? null : () => _removerItem(item),
                  icon: Icon(Icons.delete_outline_rounded),
                  color: SixMobilePalette.error,
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                _quantityButton(
                  icon: Icons.remove_rounded,
                  onTap: _salvando ? null : () => _alterarQuantidade(item, -1),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '${item.quantidade}',
                    style: TextStyle(
                      color: _titleTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _quantityButton(
                  icon: Icons.add_rounded,
                  onTap: _salvando ? null : () => _alterarQuantidade(item, 1),
                ),
                Spacer(),
                Text(
                  _formatarMoeda(item.total),
                  style: TextStyle(
                    color: _titleTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: _softAccentSurfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: _accentColor, size: 20),
        ),
      ),
    );
  }

  Future<void> _abrirSelecaoItens() async {
    final dynamic result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder:
            (_) => ProdutolistMobileScreen(
              isSelecao: true,
              permitirSelecaoMultipla: true,
            ),
      ),
    );

    if (!mounted || result == null) return;

    final List<ProdutoModel> produtos =
        result is List
            ? result.whereType<ProdutoModel>().toList(growable: false)
            : <ProdutoModel>[if (result is ProdutoModel) result];
    if (produtos.isEmpty) return;

    setState(() {
      for (final ProdutoModel produto in produtos) {
        _adicionarProduto(produto);
      }
    });
  }

  void _adicionarProduto(ProdutoModel produto) {
    final bool servico = _ehServico(produto);
    final String tipoCodigo = servico ? 'SERVICE' : 'PRODUCT';
    final String chave =
        '$tipoCodigo:${produto.id ?? produto.codigoDeBarras}:${produto.nomeProduto}';
    final int index = _itens.indexWhere((item) => item.chave == chave);

    if (index >= 0) {
      _itens[index] = _itens[index].copyWith(
        quantidade: _itens[index].quantidade + 1,
      );
      return;
    }

    _itens.add(
      _AtendimentoItemEditavelMobile(
        chave: chave,
        idSku: produto.id ?? produto.codigoDeBarras,
        descricao: produto.nomeProduto,
        tipoItemId: servico ? 20 : 10,
        tipoCodigo: tipoCodigo,
        tipoItemI18nKey: servico ? 'service' : 'product',
        quantidade: 1,
        valorUnitario: produto.precoVenda,
        desconto: 0,
        idTecnicoResponsavel: _responsavelSelecionado?.id,
        nomeTecnicoResponsavel: _responsavelSelecionado?.nome,
        movimentaEstoque: !servico,
      ),
    );
  }

  bool _ehServico(ProdutoModel produto) {
    final String tipo = produto.tipoProduto.trim().toUpperCase();
    return tipo == 'SERVICO' || tipo == 'SERVIÇO' || tipo == 'SERVICE';
  }

  void _alterarQuantidade(_AtendimentoItemEditavelMobile item, int delta) {
    setState(() {
      final int index = _itens.indexWhere(
        (element) => element.chave == item.chave,
      );
      if (index < 0) return;
      final int quantidade = _itens[index].quantidade + delta;
      if (quantidade <= 0) {
        _itens.removeAt(index);
        return;
      }
      _itens[index] = _itens[index].copyWith(quantidade: quantidade);
    });
  }

  void _removerItem(_AtendimentoItemEditavelMobile item) {
    setState(
      () => _itens.removeWhere((element) => element.chave == item.chave),
    );
  }

  Future<void> _selecionarValidade() async {
    final DateTime? data = await _selecionarData(
      title: 'Validade do orçamento',
      initialDate: _validadeOrcamentoEm,
      applyButtonLabel: 'Aplicar data',
    );
    if (data == null || !mounted) return;
    setState(() => _validadeOrcamentoEm = data);
  }

  Future<void> _selecionarVencimento() async {
    final DateTime? data = await _selecionarData(
      title: 'Vencimento financeiro',
      initialDate: _vencimentoFinanceiroEm,
      applyButtonLabel: 'Aplicar vencimento',
    );
    if (data == null || !mounted) return;
    setState(() => _vencimentoFinanceiroEm = data);
  }

  Future<void> _selecionarEntregaPrevista() async {
    final DateTime? data = await _selecionarData(
      title: 'Entrega prevista',
      initialDate: _dataEntregaPrevista,
      applyButtonLabel: 'Aplicar entrega',
      firstDate: DateTime(2000),
    );
    if (data == null || !mounted) return;
    setState(() => _dataEntregaPrevista = data);
  }

  Future<DateTime?> _selecionarData({
    required String title,
    required DateTime initialDate,
    required String applyButtonLabel,
    DateTime? firstDate,
  }) async {
    final DateTime inicio = _normalizarData(DateTime.now());
    final DateTime primeiraData = firstDate ?? inicio;
    final DateTime initial =
        initialDate.isBefore(primeiraData) ? primeiraData : initialDate;
    final DateTime? selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66000000),
      builder: (BuildContext context) {
        return DateSelectorMobileBottomSheet(
          title: title,
          initialDate: initial,
          firstDate: primeiraData,
          lastDate: inicio.add(Duration(days: 365)),
          applyButtonLabel: applyButtonLabel,
        );
      },
    );

    return selected == null ? null : _normalizarData(selected);
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final _ClienteAtendimentoMobile? cliente = _clienteSelecionado;
    if (cliente == null) {
      _mostrarMensagem('Selecione um cliente antes de salvar.');
      return;
    }
    final String? idCliente = _textoOuNulo(cliente.id);
    final String? nomeClienteSnapshot =
        cliente.nomeInformado ? _textoOuNulo(cliente.nome) : null;

    final _ResponsavelTecnicoMobile? responsavel = _responsavelSelecionado;
    setState(() => _salvando = true);
    try {
      await _service.atualizar(
        id: widget.atendimento.id,
        input: AtendimentoTecnicoUpdateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          dataEntregaPrevista: _dataEntregaPrevista,
          descricao: _textoOuNulo(_descricaoController.text),
          idCliente: idCliente,
          nomeClienteSnapshot: nomeClienteSnapshot,
          idTecnicoResponsavel: responsavel?.id,
          nomeTecnicoResponsavelSnapshot: responsavel?.nome,
          equipamento: AtendimentoTecnicoEquipamentoModel(
            tipo: _textoOuNulo(_tipoController.text),
            marca: _textoOuNulo(_marcaController.text),
            modelo: _textoOuNulo(_modeloController.text),
            numeroSerie: _textoOuNulo(_numeroSerieController.text),
            imei: _textoOuNulo(_imeiController.text),
            acessorios: _textoOuNulo(_acessoriosController.text),
            observacoesEntrada: _textoOuNulo(_acessoriosController.text),
          ),
          defeitoRelatado: _textoOuNulo(_defeitoController.text),
          diagnosticoTecnico: _textoOuNulo(_diagnosticoController.text),
          fotos: List<AtendimentoTecnicoFotoInput>.unmodifiable(_fotos),
          itens: _itens
              .map((item) => item.toInput(responsavel: responsavel))
              .toList(growable: false),
          observacaoAuditoria: _textoOuNulo(
            _observacaoAuditoriaController.text,
          ),
        ),
        dataVencimentoEm: _vencimentoFinanceiroEm,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Atendimento atualizado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível salvar: $error');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _titleTextColor,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _softSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Icon(Icons.event_outlined, size: 17, color: _accentColor),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    bool alignLabelWithHint = false,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null ? null : Icon(icon, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _softSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _accentColor, width: 1.4),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  String _clienteLabel(AtendimentoTecnicoModel atendimento) {
    final String cliente = atendimento.nomeClienteSnapshot?.trim() ?? '';
    return cliente.isEmpty ? 'Cliente não informado' : cliente;
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  String? _textoOuNulo(String value) {
    final String text = value.trim();
    return text.isEmpty ? null : text;
  }

  DateTime _normalizarData(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatarData(DateTime value) {
    return context.read<LocaleSettingsProvider>().formatDate(value);
  }

  String _formatarMoeda(double value) {
    return context.read<LocaleSettingsProvider>().formatCurrency(value);
  }
}

class _ClienteAtendimentoMobile {
  const _ClienteAtendimentoMobile({
    required this.id,
    required this.nome,
    required this.subtitulo,
    required this.nomeInformado,
    this.podeSincronizarCadastro = true,
  });

  final String id;
  final String nome;
  final String subtitulo;
  final bool nomeInformado;
  final bool podeSincronizarCadastro;

  factory _ClienteAtendimentoMobile.fromCliente(ClienteUsuario cliente) {
    final String nome = cliente.nome.trim();
    final String subtitulo = <String>[
      cliente.telefone,
      cliente.email,
      cliente.documento,
    ].where((String value) => value.trim().isNotEmpty).join(' • ');
    return _ClienteAtendimentoMobile(
      id: cliente.id,
      nome: nome.isEmpty ? 'Cliente sem nome' : nome,
      subtitulo: subtitulo,
      nomeInformado: nome.isNotEmpty,
    );
  }
}

class _ResponsavelTecnicoMobile {
  const _ResponsavelTecnicoMobile({
    required this.id,
    required this.nome,
    required this.subtitulo,
  });

  final String id;
  final String nome;
  final String subtitulo;
}

class _AtendimentoItemEditavelMobile {
  const _AtendimentoItemEditavelMobile({
    required this.chave,
    required this.idSku,
    required this.descricao,
    required this.tipoItemId,
    required this.tipoCodigo,
    required this.tipoItemI18nKey,
    required this.quantidade,
    required this.valorUnitario,
    required this.desconto,
    required this.idTecnicoResponsavel,
    required this.nomeTecnicoResponsavel,
    required this.movimentaEstoque,
  });

  final String chave;
  final String? idSku;
  final String descricao;
  final int tipoItemId;
  final String tipoCodigo;
  final String tipoItemI18nKey;
  final int quantidade;
  final double valorUnitario;
  final double desconto;
  final String? idTecnicoResponsavel;
  final String? nomeTecnicoResponsavel;
  final bool movimentaEstoque;

  bool get isServico {
    final String normalizado = tipoCodigo.trim().toUpperCase();
    return normalizado == 'SERVICE' ||
        normalizado == 'SERVICO' ||
        normalizado == 'SERVIÇO';
  }

  double get total => (quantidade * valorUnitario) - desconto;

  factory _AtendimentoItemEditavelMobile.fromModel(
    AtendimentoTecnicoItemModel item,
  ) {
    final String tipoCodigo =
        item.tipoItemCodigo.trim().isEmpty
            ? (item.movimentaEstoque ? 'PRODUCT' : 'SERVICE')
            : item.tipoItemCodigo;
    return _AtendimentoItemEditavelMobile(
      chave: '$tipoCodigo:${item.idSku ?? item.id}:${item.descricaoSnapshot}',
      idSku: item.idSku,
      descricao: item.descricaoSnapshot,
      tipoItemId: item.tipoItemId,
      tipoCodigo: tipoCodigo,
      tipoItemI18nKey: item.tipoItemI18nKey,
      quantidade: item.quantidade <= 0 ? 1 : item.quantidade.round(),
      valorUnitario: item.valorUnitario,
      desconto: item.desconto,
      idTecnicoResponsavel: item.idTecnicoResponsavel,
      nomeTecnicoResponsavel: item.nomeTecnicoResponsavel,
      movimentaEstoque: item.movimentaEstoque,
    );
  }

  _AtendimentoItemEditavelMobile copyWith({int? quantidade}) {
    return _AtendimentoItemEditavelMobile(
      chave: chave,
      idSku: idSku,
      descricao: descricao,
      tipoItemId: tipoItemId,
      tipoCodigo: tipoCodigo,
      tipoItemI18nKey: tipoItemI18nKey,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario,
      desconto: desconto,
      idTecnicoResponsavel: idTecnicoResponsavel,
      nomeTecnicoResponsavel: nomeTecnicoResponsavel,
      movimentaEstoque: movimentaEstoque,
    );
  }

  AtendimentoTecnicoItemInput toInput({
    _ResponsavelTecnicoMobile? responsavel,
  }) {
    return AtendimentoTecnicoItemInput(
      tipoItemId: tipoItemId,
      tipoItemCodigo: tipoCodigo,
      idSku: idSku,
      descricaoSnapshot: descricao,
      quantidade: quantidade.toDouble(),
      valorUnitario: valorUnitario,
      desconto: desconto,
      idTecnicoResponsavel: responsavel?.id ?? idTecnicoResponsavel,
      nomeTecnicoResponsavel: responsavel?.nome ?? nomeTecnicoResponsavel,
      movimentaEstoque: movimentaEstoque,
    );
  }
}

class _ClienteAtendimentoSelectorMobile extends StatefulWidget {
  const _ClienteAtendimentoSelectorMobile({
    required this.clientes,
    required this.clienteSelecionado,
  });

  final List<_ClienteAtendimentoMobile> clientes;
  final _ClienteAtendimentoMobile? clienteSelecionado;

  @override
  State<_ClienteAtendimentoSelectorMobile> createState() =>
      _ClienteAtendimentoSelectorMobileState();
}

class _CadastrarClienteAtendimentoAction {
  const _CadastrarClienteAtendimentoAction();
}

class _ClienteAtendimentoSelectorMobileState
    extends State<_ClienteAtendimentoSelectorMobile> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_ClienteAtendimentoMobile> get _clientesFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.clientes;
    return widget.clientes
        .where((_ClienteAtendimentoMobile item) {
          return _normalize('${item.nome} ${item.subtitulo}').contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SelectorShell(
      title: 'Selecionar cliente',
      subtitle: 'Busque e toque para trocar o cliente do atendimento.',
      icon: Icons.person_search_outlined,
      searchHint: 'Buscar cliente',
      searchController: _searchController,
      onSearchChanged: (String value) => setState(() => _filter = value),
      onClearSearch: () {
        _searchController.clear();
        setState(() => _filter = '');
      },
      leadingAction: _SelectorInlineAction(
        icon: Icons.person_add_alt_1_rounded,
        label: context.t(
          'atendimentoTecnico.client.create',
          fallback: 'Cadastrar cliente',
        ),
        onTap:
            () => Navigator.of(
              context,
            ).pop(const _CadastrarClienteAtendimentoAction()),
      ),
      childBuilder: (ScrollController scrollController) {
        final List<_ClienteAtendimentoMobile> clientes = _clientesFiltrados;
        if (clientes.isEmpty) {
          return const _SelectorEmptyState(text: 'Nenhum cliente encontrado.');
        }
        return ListView.separated(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(18, 0, 18, 22),
          itemBuilder: (BuildContext context, int index) {
            final _ClienteAtendimentoMobile cliente = clientes[index];
            return _SelectorItem(
              title: cliente.nome,
              subtitle: cliente.subtitulo,
              icon: Icons.person_outline_rounded,
              selected: widget.clienteSelecionado?.id == cliente.id,
              onTap: () => Navigator.of(context).pop(cliente),
            );
          },
          separatorBuilder: (_, __) => SizedBox(height: 10),
          itemCount: clientes.length,
        );
      },
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _ResponsavelTecnicoSelectorMobile extends StatefulWidget {
  const _ResponsavelTecnicoSelectorMobile({
    required this.responsaveis,
    required this.responsavelSelecionado,
  });

  final List<_ResponsavelTecnicoMobile> responsaveis;
  final _ResponsavelTecnicoMobile? responsavelSelecionado;

  @override
  State<_ResponsavelTecnicoSelectorMobile> createState() =>
      _ResponsavelTecnicoSelectorMobileState();
}

class _ResponsavelTecnicoSelectorMobileState
    extends State<_ResponsavelTecnicoSelectorMobile> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_ResponsavelTecnicoMobile> get _responsaveisFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.responsaveis;
    return widget.responsaveis
        .where((_ResponsavelTecnicoMobile item) {
          return _normalize('${item.nome} ${item.subtitulo}').contains(term);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SelectorShell(
      title: 'Responsável técnico',
      subtitle: 'Selecione um técnico autorizado para assistência.',
      icon: Icons.engineering_outlined,
      searchHint: 'Buscar responsável',
      searchController: _searchController,
      onSearchChanged: (String value) => setState(() => _filter = value),
      onClearSearch: () {
        _searchController.clear();
        setState(() => _filter = '');
      },
      childBuilder: (ScrollController scrollController) {
        final List<_ResponsavelTecnicoMobile> responsaveis =
            _responsaveisFiltrados;
        if (responsaveis.isEmpty) {
          return const _SelectorEmptyState(
            text: 'Nenhum responsável encontrado.',
          );
        }
        return ListView.separated(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(18, 0, 18, 22),
          itemBuilder: (BuildContext context, int index) {
            final _ResponsavelTecnicoMobile responsavel = responsaveis[index];
            return _SelectorItem(
              title: responsavel.nome,
              subtitle: responsavel.subtitulo,
              icon: Icons.person_outline_rounded,
              selected: widget.responsavelSelecionado?.id == responsavel.id,
              onTap: () => Navigator.of(context).pop(responsavel),
            );
          },
          separatorBuilder: (_, __) => SizedBox(height: 10),
          itemCount: responsaveis.length,
        );
      },
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

typedef _SelectorChildBuilder =
    Widget Function(ScrollController scrollController);

class _SelectorShell extends StatelessWidget {
  const _SelectorShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.searchHint,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.childBuilder,
    this.leadingAction,
  });

  static Color get _backgroundColor => SixMobilePalette.background;
  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softAccentSurfaceColor =>
      SixMobilePalette.softAccentSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;

  final String title;
  final String subtitle;
  final IconData icon;
  final String searchHint;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final _SelectorChildBuilder childBuilder;
  final Widget? leadingAction;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.activeBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _softAccentSurfaceColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: _accentColor),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                if (leadingAction != null) ...<Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: leadingAction!,
                  ),
                  SizedBox(height: 12),
                ],
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: Icon(Icons.search_rounded),
                      suffixIcon:
                          searchController.text.isEmpty
                              ? null
                              : IconButton(
                                icon: Icon(Icons.close_rounded),
                                onPressed: onClearSearch,
                              ),
                      filled: true,
                      fillColor: _surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _accentColor, width: 1.4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(child: childBuilder(scrollController)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectorInlineAction extends StatelessWidget {
  const _SelectorInlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _SelectorEmptyState extends StatelessWidget {
  const _SelectorEmptyState({required this.text});

  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _borderColor => SixMobilePalette.activeBorder;

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 22),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor),
          ),
        ),
      ],
    );
  }
}

class _SelectorItem extends StatelessWidget {
  const _SelectorItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  static Color get _accentColor => SixMobilePalette.accent;
  static Color get _surfaceColor => SixMobilePalette.surface;
  static Color get _softAccentSurfaceColor =>
      SixMobilePalette.softAccentSurface;
  static Color get _iconSurfaceColor => SixMobilePalette.iconSurface;
  static Color get _mutedTextColor => SixMobilePalette.mutedText;
  static Color get _titleTextColor => SixMobilePalette.titleText;
  static Color get _borderColor => SixMobilePalette.activeBorder;
  static Color get _highlightedBorderColor =>
      SixMobilePalette.highlightedBorder;

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? _softAccentSurfaceColor : _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _highlightedBorderColor : _borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    selected
                        ? _accentColor.withValues(alpha: 0.12)
                        : _iconSurfaceColor,
                child: Icon(
                  icon,
                  color: selected ? _accentColor : _titleTextColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _titleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...<Widget>[
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _mutedTextColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: Duration(milliseconds: 140),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _accentColor,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
