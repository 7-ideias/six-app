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

class AtendimentoTecnicoMobileScreen extends StatefulWidget {
  const AtendimentoTecnicoMobileScreen({super.key});

  @override
  State<AtendimentoTecnicoMobileScreen> createState() =>
      _AtendimentoTecnicoMobileScreenState();
}

class _AtendimentoTecnicoMobileScreenState
    extends State<AtendimentoTecnicoMobileScreen> {
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
  final List<_AtendimentoItemMobile> _itens = <_AtendimentoItemMobile>[];

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _tipoEquipamentoController =
      TextEditingController(text: 'SMARTPHONE');
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _acessoriosController = TextEditingController();
  final TextEditingController _defeitoController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();

  List<ClienteUsuario> _clientes = const <ClienteUsuario>[];
  List<_ResponsavelTecnicoMobile> _responsaveis =
      const <_ResponsavelTecnicoMobile>[];
  ClienteUsuario? _clienteSelecionado;
  _ResponsavelTecnicoMobile? _responsavelSelecionado;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  DateTime _validadeOrcamentoEm = _defaultDate();
  DateTime _vencimentoFinanceiroEm = _defaultDate();

  int get _quantidadeItens => _itens.fold<int>(
        0,
        (int total, _AtendimentoItemMobile item) => total + item.quantidade,
      );

  double get _totalItens => _itens.fold<double>(
        0,
        (double total, _AtendimentoItemMobile item) => total + item.total,
      );

  static DateTime _inicioHoje() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _defaultDate() => _inicioHoje().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _tipoEquipamentoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _numeroSerieController.dispose();
    _imeiController.dispose();
    _acessoriosController.dispose();
    _defeitoController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final response = await _clienteApiClient.listarClientesUsuario();
      final List<ColaboradorUsuarioResumo> colaboradores =
          await _colaboradorApiClient.listarColaboradores();
      final _ResponsavelTecnicoMobile? admin = await _carregarAdminAtual();
      final List<_ResponsavelTecnicoMobile> responsaveis =
          _montarResponsaveis(admin, colaboradores);

      if (!mounted) return;
      setState(() {
        _clientes = response.clientes.where((cliente) => cliente.ativo).toList();
        _responsaveis = responsaveis;
        _responsavelSelecionado ??= responsaveis.isEmpty ? null : responsaveis.first;
        _carregando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.toString();
        _carregando = false;
      });
    }
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

  Future<void> _selecionarValidadeOrcamento() async {
    final data = await _selecionarData(
      initialDate: _validadeOrcamentoEm,
      title: 'Validade do orçamento',
      applyButtonLabel: 'Aplicar data',
    );
    if (data == null) return;
    setState(() => _validadeOrcamentoEm = data);
  }

  Future<void> _selecionarVencimentoFinanceiro() async {
    final data = await _selecionarData(
      initialDate: _vencimentoFinanceiroEm,
      title: 'Vencimento financeiro',
      applyButtonLabel: 'Aplicar vencimento',
    );
    if (data == null) return;
    setState(() => _vencimentoFinanceiroEm = data);
  }

  Future<DateTime?> _selecionarData({
    required DateTime initialDate,
    required String title,
    required String applyButtonLabel,
  }) async {
    final inicio = _inicioHoje();
    final initial = initialDate.isBefore(inicio) ? inicio : initialDate;
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (context) {
        return DateSelectorMobileBottomSheet(
          title: title,
          initialDate: initial,
          firstDate: inicio,
          lastDate: inicio.add(const Duration(days: 365)),
          applyButtonLabel: applyButtonLabel,
        );
      },
    );

    if (selected == null) return null;
    return DateTime(selected.year, selected.month, selected.day);
  }

  Future<void> _abrirSelecaoCliente() async {
    if (_clientes.isEmpty) {
      _mostrarMensagem('Nenhum cliente disponível para seleção.');
      return;
    }

    final cliente = await showModalBottomSheet<ClienteUsuario>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (context) {
        return AtendimentoTecnicoClienteSelectorMobile(
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
      builder: (context) {
        return AtendimentoTecnicoResponsavelSelectorMobile(
          responsaveis: _responsaveis,
          responsavelSelecionado: _responsavelSelecionado,
        );
      },
    );

    if (responsavel == null || !mounted) return;
    setState(() => _responsavelSelecionado = responsavel);
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
      _AtendimentoItemMobile(
        chave: chave,
        idSku: produto.id ?? produto.codigoDeBarras,
        descricao: produto.nomeProduto.trim().isEmpty
            ? 'Item sem nome'
            : produto.nomeProduto,
        tipoItemId: servico ? 20 : 10,
        tipoCodigo: tipoCodigo,
        quantidade: 1,
        valorUnitario: produto.precoVenda,
        desconto: 0,
        movimentaEstoque: !servico,
      ),
    );
  }

  bool _ehServico(ProdutoModel produto) {
    final String tipo = produto.tipoProduto.trim().toUpperCase();
    return tipo == 'SERVICO' || tipo == 'SERVIÇO' || tipo == 'SERVICE';
  }

  void _alterarQuantidade(_AtendimentoItemMobile item, int delta) {
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

  void _removerItem(_AtendimentoItemMobile item) {
    setState(() => _itens.removeWhere((element) => element.chave == item.chave));
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final cliente = _clienteSelecionado;
    if (cliente == null) {
      _mostrarMensagem('Selecione um cliente antes de iniciar o atendimento.');
      return;
    }

    if (_defeitoController.text.trim().isEmpty) {
      _mostrarMensagem('Informe o defeito relatado pelo cliente.');
      return;
    }

    final _ResponsavelTecnicoMobile? responsavel = _responsavelSelecionado;

    setState(() => _salvando = true);
    try {
      final atendimento = await _service.criar(
        AtendimentoTecnicoCreateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          descricao: _textoOuNulo(_descricaoController.text),
          idCliente: cliente.id,
          nomeClienteSnapshot: cliente.nome,
          idTecnicoResponsavel: responsavel?.id,
          nomeTecnicoResponsavelSnapshot: responsavel?.nome,
          equipamento: AtendimentoTecnicoEquipamentoModel(
            tipo: _textoOuNulo(_tipoEquipamentoController.text),
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
        ),
        dataVencimentoEm: _vencimentoFinanceiroEm,
      );

      if (!mounted) return;
      _limparFormulario();
      _mostrarMensagem(
        atendimento.numero.trim().isEmpty
            ? 'Atendimento técnico iniciado.'
            : 'Atendimento ${atendimento.numero} iniciado.',
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível iniciar o atendimento: $error');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _limparFormulario() {
    setState(() {
      _clienteSelecionado = null;
      _responsavelSelecionado =
          _responsaveis.isEmpty ? null : _responsaveis.first;
      _descricaoController.clear();
      _tipoEquipamentoController.text = 'SMARTPHONE';
      _marcaController.clear();
      _modeloController.clear();
      _numeroSerieController.clear();
      _imeiController.clear();
      _acessoriosController.clear();
      _defeitoController.clear();
      _diagnosticoController.clear();
      _itens.clear();
      _validadeOrcamentoEm = _defaultDate();
      _vencimentoFinanceiroEm = _defaultDate();
    });
  }

  String? _textoOuNulo(String value) {
    final texto = value.trim();
    return texto.isEmpty ? null : texto;
  }

  String _formatarData(DateTime value) {
    final dia = value.day.toString().padLeft(2, '0');
    final mes = value.month.toString().padLeft(2, '0');
    final ano = value.year.toString();
    return '$dia/$mes/$ano';
  }

  String _formatarMoeda(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
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
          'Novo atendimento técnico',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarDados,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 16),
              if (_carregando)
                _buildLoadingCard()
              else if (_erro != null)
                _buildErrorCard()
              else
                _buildFormCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String? responsavel = _responsavelSelecionado?.nome;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
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
          const _HeaderIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Iniciar assistência',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  responsavel != null && responsavel.trim().isNotEmpty
                      ? 'Responsável: $responsavel'
                      : _itens.isEmpty
                          ? 'Cliente, equipamento e defeito em uma tela rápida para balcão.'
                          : '$_quantidadeItens item(ns) • ${_formatarMoeda(_totalItens)}',
                  maxLines: 2,
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

  Widget _buildLoadingCard() {
    return _card(
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Carregando clientes e responsáveis...')),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Não foi possível carregar os dados',
            style: TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _erro ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _mutedTextColor),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _carregarDados,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionTitle('Dados principais'),
          const SizedBox(height: 12),
          _clienteSelectorField(),
          const SizedBox(height: 12),
          _responsavelSelectorField(),
          const SizedBox(height: 12),
          TextField(
            controller: _descricaoController,
            decoration: _inputDecoration(
              label: 'Descrição interna',
              hint: 'Ex.: Troca de tela iPhone 11',
              icon: Icons.notes_outlined,
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Equipamento'),
          const SizedBox(height: 12),
          TextField(
            controller: _tipoEquipamentoController,
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
              hint: 'Ex.: sem carregador, com capa, tela trincada...',
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
              hint: 'Descreva o problema informado no balcão.',
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
              label: 'Diagnóstico técnico inicial',
              hint: 'Opcional neste primeiro momento.',
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
                  onTap: _selecionarValidadeOrcamento,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTile(
                  label: 'Vencimento financeiro',
                  value: _formatarData(_vencimentoFinanceiroEm),
                  onTap: _selecionarVencimentoFinanceiro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _itensSection(),
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
                  : const Icon(Icons.playlist_add_check_rounded),
              label: Text(
                _salvando
                    ? 'Iniciando atendimento...'
                    : 'Iniciar atendimento técnico',
              ),
            ),
          ),
        ],
      ),
    );
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
        'Nenhum produto ou serviço vinculado. Você pode iniciar com ou sem itens.',
        style: TextStyle(color: _mutedTextColor, height: 1.35),
      ),
    );
  }

  Widget _itemTile(_AtendimentoItemMobile item) {
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

  Widget _clienteSelectorField() {
    final ClienteUsuario? cliente = _clienteSelecionado;
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
                  const Icon(
                    Icons.event_outlined,
                    size: 17,
                    color: _accentColor,
                  ),
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
}

class _AtendimentoItemMobile {
  const _AtendimentoItemMobile({
    required this.chave,
    required this.idSku,
    required this.descricao,
    required this.tipoItemId,
    required this.tipoCodigo,
    required this.quantidade,
    required this.valorUnitario,
    required this.desconto,
    required this.movimentaEstoque,
  });

  final String chave;
  final String? idSku;
  final String descricao;
  final int tipoItemId;
  final String tipoCodigo;
  final int quantidade;
  final double valorUnitario;
  final double desconto;
  final bool movimentaEstoque;

  bool get isServico {
    final String normalizado = tipoCodigo.trim().toUpperCase();
    return normalizado == 'SERVICE' ||
        normalizado == 'SERVICO' ||
        normalizado == 'SERVIÇO';
  }

  double get total => (quantidade * valorUnitario) - desconto;

  _AtendimentoItemMobile copyWith({int? quantidade}) {
    return _AtendimentoItemMobile(
      chave: chave,
      idSku: idSku,
      descricao: descricao,
      tipoItemId: tipoItemId,
      tipoCodigo: tipoCodigo,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario,
      desconto: desconto,
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
      idTecnicoResponsavel: responsavel?.id,
      nomeTecnicoResponsavel: responsavel?.nome,
      movimentaEstoque: movimentaEstoque,
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

class AtendimentoTecnicoResponsavelSelectorMobile extends StatefulWidget {
  const AtendimentoTecnicoResponsavelSelectorMobile({
    super.key,
    required this.responsaveis,
    required this.responsavelSelecionado,
  });

  final List<_ResponsavelTecnicoMobile> responsaveis;
  final _ResponsavelTecnicoMobile? responsavelSelecionado;

  @override
  State<AtendimentoTecnicoResponsavelSelectorMobile> createState() =>
      _AtendimentoTecnicoResponsavelSelectorMobileState();
}

class _AtendimentoTecnicoResponsavelSelectorMobileState
    extends State<AtendimentoTecnicoResponsavelSelectorMobile> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<_ResponsavelTecnicoMobile> get _responsaveisFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) return widget.responsaveis;
    return widget.responsaveis.where((_ResponsavelTecnicoMobile item) {
      final String source = _normalize('${item.nome} ${item.subtitulo}');
      return source.contains(term);
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        final List<_ResponsavelTecnicoMobile> responsaveis =
            _responsaveisFiltrados;

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
                        child: const Icon(
                          Icons.engineering_outlined,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Responsável técnico',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Selecione o ADMIN ou colaborador responsável.',
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
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _filter = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar responsável',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filter = '');
                              },
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
                Expanded(
                  child: responsaveis.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                          itemBuilder: (BuildContext context, int index) {
                            final _ResponsavelTecnicoMobile responsavel =
                                responsaveis[index];
                            final bool selected = _isSelected(responsavel);
                            return _ResponsavelSelectorItem(
                              responsavel: responsavel,
                              selected: selected,
                              onTap: () => Navigator.of(context).pop(responsavel),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: responsaveis.length,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
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
          child: const Text(
            'Nenhum responsável encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor),
          ),
        ),
      ],
    );
  }

  bool _isSelected(_ResponsavelTecnicoMobile responsavel) {
    final _ResponsavelTecnicoMobile? selected = widget.responsavelSelecionado;
    if (selected == null) return false;
    return selected.id == responsavel.id;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _ResponsavelSelectorItem extends StatelessWidget {
  const _ResponsavelSelectorItem({
    required this.responsavel,
    required this.selected,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final _ResponsavelTecnicoMobile responsavel;
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
                    ? _accentColor.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                child: Icon(
                  responsavel.isAdmin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline_rounded,
                  color: selected ? _accentColor : _primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      responsavel.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (responsavel.subtitulo.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        responsavel.subtitulo,
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

class AtendimentoTecnicoClienteSelectorMobile extends StatefulWidget {
  const AtendimentoTecnicoClienteSelectorMobile({
    super.key,
    required this.clientes,
    required this.clienteSelecionado,
  });

  final List<ClienteUsuario> clientes;
  final ClienteUsuario? clienteSelecionado;

  @override
  State<AtendimentoTecnicoClienteSelectorMobile> createState() =>
      _AtendimentoTecnicoClienteSelectorMobileState();
}

class _AtendimentoTecnicoClienteSelectorMobileState
    extends State<AtendimentoTecnicoClienteSelectorMobile> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<ClienteUsuario> get _clientesFiltrados {
    final String term = _normalize(_filter);
    if (term.isEmpty) {
      return widget.clientes;
    }

    return widget.clientes.where((ClienteUsuario cliente) {
      final String source = _normalize(
        '${cliente.nome} ${cliente.telefone} ${cliente.email} ${cliente.documento}',
      );
      return source.contains(term);
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        final List<ClienteUsuario> clientes = _clientesFiltrados;

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
                        child: const Icon(
                          Icons.person_search_outlined,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Selecionar cliente',
                              style: TextStyle(
                                color: _titleTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Busque e toque para vincular ao atendimento.',
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
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _filter = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filter = '');
                              },
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
                Expanded(
                  child: clientes.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                          itemBuilder: (BuildContext context, int index) {
                            final ClienteUsuario cliente = clientes[index];
                            final bool selected = _isSelected(cliente);
                            return _ClienteSelectorItem(
                              cliente: cliente,
                              selected: selected,
                              onTap: () => Navigator.of(context).pop(cliente),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: clientes.length,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
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
          child: Column(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.search_off_rounded, color: _primaryColor),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nenhum cliente encontrado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _titleTextColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Tente buscar por nome, telefone, e-mail ou documento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _mutedTextColor, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSelected(ClienteUsuario cliente) {
    final ClienteUsuario? selected = widget.clienteSelecionado;
    if (selected == null) {
      return false;
    }
    return selected.id == cliente.id;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _ClienteSelectorItem extends StatelessWidget {
  const _ClienteSelectorItem({
    required this.cliente,
    required this.selected,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final ClienteUsuario cliente;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String subtitle = _subtitle(cliente);

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
                    ? _accentColor.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                child: Text(
                  _initials(cliente.nome),
                  style: TextStyle(
                    color: selected ? _accentColor : _primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cliente.nome.isEmpty ? 'Cliente sem nome' : cliente.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...<Widget>[
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

  static String _subtitle(ClienteUsuario cliente) {
    return <String>[
      cliente.telefone,
      cliente.email,
      cliente.documento,
    ].where((String value) => value.trim().isNotEmpty).join(' • ');
  }

  static String _initials(String name) {
    final List<String> parts =
        name.trim().split(' ').where((String item) => item.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'CL';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: const Icon(Icons.build_circle_rounded, color: Colors.white),
    );
  }
}
