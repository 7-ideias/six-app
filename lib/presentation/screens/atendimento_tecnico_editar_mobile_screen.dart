import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/models/colaborador_usuario_model.dart';
import '../../data/models/produto_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../domain/services/usuario/usuario_service.dart';
import '../../providers/usuario_provider.dart';
import '../components/date_selector_mobile_bottom_sheet.dart';
import 'produto_list_mobile_screen.dart';

class AtendimentoTecnicoEditarMobileScreen extends StatefulWidget {
  const AtendimentoTecnicoEditarMobileScreen({
    super.key,
    required this.atendimento,
  });

  final AtendimentoTecnicoModel atendimento;

  @override
  State<AtendimentoTecnicoEditarMobileScreen> createState() =>
      _AtendimentoTecnicoEditarMobileScreenState();
}

class _AtendimentoTecnicoEditarMobileScreenState
    extends State<AtendimentoTecnicoEditarMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final ClienteUsuarioApiClient _clienteApiClient = HttpClienteUsuarioApiClient();
  final ColaboradorUsuarioApiClient _colaboradorApiClient =
      HttpColaboradorUsuarioApiClient();
  final List<_AtendimentoItemEditavelMobile> _itens =
      <_AtendimentoItemEditavelMobile>[];

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

  List<_ClienteAtendimentoMobile> _clientes = const <_ClienteAtendimentoMobile>[];
  List<_ResponsavelTecnicoMobile> _responsaveis =
      const <_ResponsavelTecnicoMobile>[];
  _ClienteAtendimentoMobile? _clienteSelecionado;
  _ResponsavelTecnicoMobile? _responsavelSelecionado;
  late DateTime _validadeOrcamentoEm;
  late DateTime _vencimentoFinanceiroEm;
  bool _salvando = false;
  bool _carregandoDados = false;

  double get _totalItens => _itens.fold<double>(
        0,
        (double total, _AtendimentoItemEditavelMobile item) => total + item.total,
      );

  @override
  void initState() {
    super.initState();
    final AtendimentoTecnicoModel atendimento = widget.atendimento;
    final AtendimentoTecnicoEquipamentoModel equipamento =
        atendimento.equipamento ?? const AtendimentoTecnicoEquipamentoModel();

    _clienteSelecionado = _clienteInicial(atendimento);
    _responsavelSelecionado = _responsavelInicial(atendimento);
    _clientes = <_ClienteAtendimentoMobile>[
      if (_clienteSelecionado != null) _clienteSelecionado!,
    ];
    _responsaveis = <_ResponsavelTecnicoMobile>[
      if (_responsavelSelecionado != null) _responsavelSelecionado!,
    ];

    _descricaoController = TextEditingController(text: atendimento.descricao ?? '');
    _tipoController = TextEditingController(text: equipamento.tipo ?? '');
    _marcaController = TextEditingController(text: equipamento.marca ?? '');
    _modeloController = TextEditingController(text: equipamento.modelo ?? '');
    _numeroSerieController = TextEditingController(text: equipamento.numeroSerie ?? '');
    _imeiController = TextEditingController(text: equipamento.imei ?? '');
    _acessoriosController = TextEditingController(
      text: equipamento.acessorios ?? equipamento.observacoesEntrada ?? '',
    );
    _defeitoController = TextEditingController(text: atendimento.defeitoRelatado ?? '');
    _diagnosticoController = TextEditingController(
      text: atendimento.diagnosticoTecnico ?? '',
    );
    _observacaoAuditoriaController = TextEditingController(
      text: 'Atualização realizada pelo mobile.',
    );

    _validadeOrcamentoEm = _normalizarData(
      atendimento.validadeOrcamentoEm ?? DateTime.now().add(const Duration(days: 7)),
    );
    _vencimentoFinanceiroEm = _normalizarData(
      atendimento.dataVencimentoEm ?? _validadeOrcamentoEm,
    );
    _itens.addAll(
      atendimento.itens.map(_AtendimentoItemEditavelMobile.fromModel),
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
          await _colaboradorApiClient.listarColaboradores();
      final _ResponsavelTecnicoMobile? admin = await _carregarAdminAtual();
      final List<_ClienteAtendimentoMobile> clientes = clientesResponse.clientes
          .where((ClienteUsuario cliente) => cliente.ativo)
          .map(_ClienteAtendimentoMobile.fromCliente)
          .toList(growable: true);
      final List<_ResponsavelTecnicoMobile> responsaveis =
          _montarResponsaveis(admin, colaboradores).toList(growable: true);

      final _ClienteAtendimentoMobile? clienteAtual = _clienteSelecionado;
      if (clienteAtual != null &&
          !clientes.any((_ClienteAtendimentoMobile item) => item.id == clienteAtual.id)) {
        clientes.insert(0, clienteAtual);
      }

      final _ResponsavelTecnicoMobile? responsavelAtual = _responsavelSelecionado;
      if (responsavelAtual != null &&
          !responsaveis.any((_ResponsavelTecnicoMobile item) => item.id == responsavelAtual.id)) {
        responsaveis.insert(0, responsavelAtual);
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

  _ClienteAtendimentoMobile? _clienteInicial(AtendimentoTecnicoModel atendimento) {
    final String id = atendimento.idCliente?.trim() ?? '';
    final String nome = atendimento.nomeClienteSnapshot?.trim() ?? '';
    if (id.isEmpty && nome.isEmpty) return null;
    return _ClienteAtendimentoMobile(
      id: id,
      nome: nome.isEmpty ? 'Cliente não informado' : nome,
      subtitulo: id.isEmpty ? 'Snapshot do atendimento' : 'Cliente do atendimento',
    );
  }

  _ResponsavelTecnicoMobile? _responsavelInicial(AtendimentoTecnicoModel atendimento) {
    final String id = atendimento.idTecnicoResponsavel?.trim() ?? '';
    final String nome = atendimento.nomeTecnicoResponsavelSnapshot?.trim() ?? '';
    if (id.isEmpty && nome.isEmpty) return null;
    return _ResponsavelTecnicoMobile(
      id: id,
      nome: nome.isEmpty ? 'Responsável não informado' : nome,
      subtitulo: id.isEmpty ? 'Snapshot do atendimento' : 'Responsável do atendimento',
    );
  }

  _ClienteAtendimentoMobile? _resolverClienteSelecionado(
    List<_ClienteAtendimentoMobile> clientes,
  ) {
    final _ClienteAtendimentoMobile? atual = _clienteSelecionado;
    if (atual == null) return clientes.isEmpty ? null : clientes.first;
    return clientes.firstWhere(
      (_ClienteAtendimentoMobile item) => item.id == atual.id,
      orElse: () => atual,
    );
  }

  _ResponsavelTecnicoMobile? _resolverResponsavelSelecionado(
    List<_ResponsavelTecnicoMobile> responsaveis,
  ) {
    final _ResponsavelTecnicoMobile? atual = _responsavelSelecionado;
    if (atual == null) return responsaveis.isEmpty ? null : responsaveis.first;
    return responsaveis.firstWhere(
      (_ResponsavelTecnicoMobile item) => item.id == atual.id,
      orElse: () => atual,
    );
  }

  Future<_ResponsavelTecnicoMobile?> _carregarAdminAtual() async {
    final AuthService authService = AuthService();
    final String idUsuario = (await authService.getUserId())?.trim() ?? '';

    try {
      if (UsuarioProvider().usuario == null) {
        await UsuarioService().buscarDadosDoUsuario_atualizaProviders();
      }
    } catch (_) {
      // Mantem a tela funcional mesmo quando os dados pessoais nao carregarem.
    }

    final UsuarioModel? usuario = UsuarioProvider().usuario;
    final String email =
        (usuario?.email.trim().isNotEmpty == true
                ? usuario!.email.trim()
                : (await authService.getUserEmail())?.trim()) ??
            '';
    final String nome = _nomeUsuario(usuario, fallbackEmail: email);
    final String id = idUsuario.isNotEmpty ? idUsuario : email;

    if (id.isEmpty && nome.isEmpty) return null;

    return _ResponsavelTecnicoMobile(
      id: id.isEmpty ? nome : id,
      nome: nome.isEmpty ? 'ADMIN' : nome,
      subtitulo: email.isEmpty ? 'ADMIN do sistema' : 'ADMIN do sistema • $email',
      isAdmin: true,
    );
  }

  String _nomeUsuario(UsuarioModel? usuario, {required String fallbackEmail}) {
    if (usuario == null) return fallbackEmail;
    final String nomeDeGuerra = usuario.nomeDeGuerra.trim();
    if (nomeDeGuerra.isNotEmpty) return nomeDeGuerra;
    final String nomeCompleto = <String>[usuario.nome, usuario.sobrenome]
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .join(' ');
    if (nomeCompleto.isNotEmpty) return nomeCompleto;
    return fallbackEmail;
  }

  List<_ResponsavelTecnicoMobile> _montarResponsaveis(
    _ResponsavelTecnicoMobile? admin,
    List<ColaboradorUsuarioResumo> colaboradores,
  ) {
    final Map<String, _ResponsavelTecnicoMobile> mapa =
        <String, _ResponsavelTecnicoMobile>{};

    void add(_ResponsavelTecnicoMobile responsavel) {
      final String key = responsavel.id.trim().isNotEmpty
          ? responsavel.id.trim()
          : responsavel.nome.toLowerCase().trim();
      if (key.isEmpty || mapa.containsKey(key)) return;
      mapa[key] = responsavel;
    }

    if (admin != null) add(admin);

    for (final ColaboradorUsuarioResumo colaborador in colaboradores) {
      final String id = colaborador.idUnicoPessoal.trim().isNotEmpty
          ? colaborador.idUnicoPessoal.trim()
          : colaborador.email.trim();
      final String nome = colaborador.nomeDeGuerra.trim().isNotEmpty
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Editar atendimento',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarCadastros,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: <Widget>[
              _hero(),
              const SizedBox(height: 16),
              _formCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final String cliente = _clienteSelecionado?.nome.trim().isNotEmpty == true
        ? _clienteSelecionado!.nome
        : _clienteLabel(widget.atendimento);
    final String? responsavel = _responsavelSelecionado?.nome;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x260B1F3A),
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
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.atendimento.numero,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  responsavel == null || responsavel.trim().isEmpty
                      ? '$cliente • ${_itens.length} item(ns)'
                      : '$cliente • $responsavel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFD7E3F5), height: 1.35),
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
          const SizedBox(height: 12),
          if (_carregandoDados) ...<Widget>[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 12),
          ],
          _clienteSelectorField(),
          const SizedBox(height: 12),
          _responsavelSelectorField(),
          const SizedBox(height: 12),
          TextField(
            controller: _descricaoController,
            decoration: _inputDecoration(
              label: 'Descrição interna',
              icon: Icons.notes_outlined,
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Equipamento'),
          const SizedBox(height: 12),
          TextField(
            controller: _tipoController,
            decoration: _inputDecoration(
              label: 'Tipo de equipamento',
              icon: Icons.devices_other_outlined,
            ),
          ),
          const SizedBox(height: 12),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 12),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          _sectionTitle('Relato técnico'),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          _sectionTitle('Datas'),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _dateTile(
                  label: 'Validade',
                  value: _formatarData(_validadeOrcamentoEm),
                  onTap: _selecionarValidade,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTile(
                  label: 'Vencimento financeiro',
                  value: _formatarData(_vencimentoFinanceiroEm),
                  onTap: _selecionarVencimento,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _itensSection(),
          const SizedBox(height: 16),
          _sectionTitle('Auditoria'),
          const SizedBox(height: 12),
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
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    )
                  : const Icon(Icons.save_outlined),
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
          isEmpty: !hasSelection,
          decoration: _inputDecoration(
            label: 'Cliente',
            icon: Icons.person_search_outlined,
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
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
          isEmpty: !hasSelection,
          decoration: _inputDecoration(
            label: 'Responsável técnico',
            icon: Icons.engineering_outlined,
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
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
    if (_clientes.isEmpty) {
      _mostrarMensagem('Nenhum cliente disponível para seleção.');
      return;
    }

    final _ClienteAtendimentoMobile? cliente =
        await showModalBottomSheet<_ClienteAtendimentoMobile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (BuildContext context) {
        return _ClienteAtendimentoSelectorMobile(
          clientes: _clientes,
          clienteSelecionado: _clienteSelecionado,
        );
      },
    );

    if (cliente == null || !mounted) return;
    setState(() => _clienteSelecionado = cliente);
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
      barrierColor: const Color(0x66000000),
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

  Widget _itensSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.inventory_2_outlined, color: _accentColor),
              const SizedBox(width: 8),
              Expanded(child: _sectionTitle('Produtos e serviços')),
              Text(
                _formatarMoeda(_totalItens),
                style: const TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_itens.isEmpty)
            _emptyItens()
          else
            ..._itens.map(_itemTile),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _salvando ? null : _abrirSelecaoItens,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Adicionar produto ou serviço'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyItens() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: const Text(
        'Nenhum produto ou serviço vinculado. Adicione itens para compor o atendimento.',
        style: TextStyle(color: _mutedTextColor, height: 1.35),
      ),
    );
  }

  Widget _itemTile(_AtendimentoItemEditavelMobile item) {
    final bool servico = item.isServico;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    servico ? Icons.handyman_outlined : Icons.inventory_2_outlined,
                    color: _accentColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _titleTextColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${servico ? 'Serviço' : 'Produto'} • ${_formatarMoeda(item.valorUnitario)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _quantityButton(
                  icon: Icons.remove_rounded,
                  onTap: _salvando ? null : () => _alterarQuantidade(item, -1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '${item.quantidade}',
                    style: const TextStyle(
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
                const Spacer(),
                Text(
                  _formatarMoeda(item.total),
                  style: const TextStyle(
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

  Widget _quantityButton({required IconData icon, required VoidCallback? onTap}) {
    return Material(
      color: const Color(0xFFEFF6FF),
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
        builder: (_) => const ProdutolistMobileScreen(
          isSelecao: true,
          permitirSelecaoMultipla: true,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final List<ProdutoModel> produtos = result is List
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
    final String chave = '$tipoCodigo:${produto.id ?? produto.codigoDeBarras}:${produto.nomeProduto}';
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
      final int index = _itens.indexWhere((element) => element.chave == item.chave);
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
    setState(() => _itens.removeWhere((element) => element.chave == item.chave));
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

  Future<DateTime?> _selecionarData({
    required String title,
    required DateTime initialDate,
    required String applyButtonLabel,
  }) async {
    final DateTime inicio = _normalizarData(DateTime.now());
    final DateTime initial = initialDate.isBefore(inicio) ? inicio : initialDate;
    final DateTime? selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (BuildContext context) {
        return DateSelectorMobileBottomSheet(
          title: title,
          initialDate: initial,
          firstDate: inicio,
          lastDate: inicio.add(const Duration(days: 365)),
          applyButtonLabel: applyButtonLabel,
        );
      },
    );

    return selected == null ? null : _normalizarData(selected);
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final _ClienteAtendimentoMobile? cliente = _clienteSelecionado;
    if (cliente == null || cliente.id.trim().isEmpty) {
      _mostrarMensagem('Selecione um cliente antes de salvar.');
      return;
    }

    final _ResponsavelTecnicoMobile? responsavel = _responsavelSelecionado;

    setState(() => _salvando = true);
    try {
      await _service.atualizar(
        id: widget.atendimento.id,
        input: AtendimentoTecnicoUpdateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          descricao: _textoOuNulo(_descricaoController.text),
          idCliente: cliente.id,
          nomeClienteSnapshot: cliente.nome,
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
          itens: _itens
              .map((item) => item.toInput(responsavel: responsavel))
              .toList(growable: false),
          observacaoAuditoria: _textoOuNulo(_observacaoAuditoriaController.text),
        ),
        dataVencimentoEm: _vencimentoFinanceiroEm,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
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
      style: const TextStyle(
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
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
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
                style: const TextStyle(
                  color: _mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  const Icon(Icons.event_outlined, size: 17, color: _accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accentColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
    final String dia = value.day.toString().padLeft(2, '0');
    final String mes = value.month.toString().padLeft(2, '0');
    return '$dia/$mes/${value.year}';
  }

  String _formatarMoeda(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _ClienteAtendimentoMobile {
  const _ClienteAtendimentoMobile({
    required this.id,
    required this.nome,
    required this.subtitulo,
  });

  final String id;
  final String nome;
  final String subtitulo;

  factory _ClienteAtendimentoMobile.fromCliente(ClienteUsuario cliente) {
    final String subtitulo = <String>[
      cliente.telefone,
      cliente.email,
      cliente.documento,
    ].where((String value) => value.trim().isNotEmpty).join(' • ');
    return _ClienteAtendimentoMobile(
      id: cliente.id,
      nome: cliente.nome.trim().isEmpty ? 'Cliente sem nome' : cliente.nome,
      subtitulo: subtitulo,
    );
  }
}

class _ResponsavelTecnicoMobile {
  const _ResponsavelTecnicoMobile({
    required this.id,
    required this.nome,
    required this.subtitulo,
    this.isAdmin = false,
  });

  final String id;
  final String nome;
  final String subtitulo;
  final bool isAdmin;
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
    final String tipoCodigo = item.tipoItemCodigo.trim().isEmpty
        ? (item.movimentaEstoque ? 'PRODUCT' : 'SERVICE')
        : item.tipoItemCodigo;
    return _AtendimentoItemEditavelMobile(
      chave: '${tipoCodigo}:${item.idSku ?? item.id}:${item.descricaoSnapshot}',
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

class _ClienteAtendimentoSelectorMobileState
    extends State<_ClienteAtendimentoSelectorMobile> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_ClienteAtendimentoMobile> get _clientesFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.clientes;
    return widget.clientes.where((_ClienteAtendimentoMobile item) {
      return _normalize('${item.nome} ${item.subtitulo}').contains(term);
    }).toList(growable: false);
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
      childBuilder: (ScrollController scrollController) {
        final List<_ClienteAtendimentoMobile> clientes = _clientesFiltrados;
        if (clientes.isEmpty) return const _SelectorEmptyState(text: 'Nenhum cliente encontrado.');
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
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
          separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    return widget.responsaveis.where((_ResponsavelTecnicoMobile item) {
      return _normalize('${item.nome} ${item.subtitulo}').contains(term);
    }).toList(growable: false);
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
      subtitle: 'Selecione o ADMIN ou colaborador responsável.',
      icon: Icons.engineering_outlined,
      searchHint: 'Buscar responsável',
      searchController: _searchController,
      onSearchChanged: (String value) => setState(() => _filter = value),
      onClearSearch: () {
        _searchController.clear();
        setState(() => _filter = '');
      },
      childBuilder: (ScrollController scrollController) {
        final List<_ResponsavelTecnicoMobile> responsaveis = _responsaveisFiltrados;
        if (responsaveis.isEmpty) {
          return const _SelectorEmptyState(text: 'Nenhum responsável encontrado.');
        }
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          itemBuilder: (BuildContext context, int index) {
            final _ResponsavelTecnicoMobile responsavel = responsaveis[index];
            return _SelectorItem(
              title: responsavel.nome,
              subtitle: responsavel.subtitulo,
              icon: responsavel.isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline_rounded,
              selected: widget.responsavelSelecionado?.id == responsavel.id,
              onTap: () => Navigator.of(context).pop(responsavel),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: responsaveis.length,
        );
      },
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

typedef _SelectorChildBuilder = Widget Function(ScrollController scrollController);

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
  });

  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final String title;
  final String subtitle;
  final IconData icon;
  final String searchHint;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final _SelectorChildBuilder childBuilder;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: _primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: const TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
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
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: onClearSearch,
                            ),
                      filled: true,
                      fillColor: _surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: _accentColor, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: childBuilder(scrollController)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectorEmptyState extends StatelessWidget {
  const _SelectorEmptyState({required this.text});

  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedTextColor),
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

  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

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
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFFBFDBFE) : _borderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? _accentColor.withOpacity(0.12)
                    : const Color(0xFFF1F5F9),
                child: Icon(icon, color: selected ? _accentColor : _primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 140),
                child: const Icon(
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
