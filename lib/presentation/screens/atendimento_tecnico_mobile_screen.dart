import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/cliente_usuario_model.dart';
import '../../data/services/cliente_usuario/cliente_usuario_api_client.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';

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

  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final ClienteUsuarioApiClient _clienteApiClient = HttpClienteUsuarioApiClient();

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
  ClienteUsuario? _clienteSelecionado;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  DateTime _validadeOrcamentoEm = _defaultDate();
  DateTime _vencimentoFinanceiroEm = _defaultDate();

  static DateTime _inicioHoje() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _defaultDate() => _inicioHoje().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _carregarClientes();
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

  Future<void> _carregarClientes() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final response = await _clienteApiClient.listarClientesUsuario();
      if (!mounted) return;
      setState(() {
        _clientes = response.clientes.where((cliente) => cliente.ativo).toList();
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

  Future<void> _selecionarValidadeOrcamento() async {
    final data = await _selecionarData(
      initialDate: _validadeOrcamentoEm,
      helpText: 'Validade do orçamento',
    );
    if (data == null) return;
    setState(() => _validadeOrcamentoEm = data);
  }

  Future<void> _selecionarVencimentoFinanceiro() async {
    final data = await _selecionarData(
      initialDate: _vencimentoFinanceiroEm,
      helpText: 'Vencimento financeiro',
    );
    if (data == null) return;
    setState(() => _vencimentoFinanceiroEm = data);
  }

  Future<DateTime?> _selecionarData({
    required DateTime initialDate,
    required String helpText,
  }) async {
    final inicio = _inicioHoje();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(inicio) ? inicio : initialDate,
      firstDate: inicio,
      lastDate: inicio.add(const Duration(days: 365)),
      helpText: helpText,
    );
    if (selected == null) return null;
    return DateTime(selected.year, selected.month, selected.day);
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

    setState(() => _salvando = true);
    try {
      final atendimento = await _service.criar(
        AtendimentoTecnicoCreateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          descricao: _textoOuNulo(_descricaoController.text),
          idCliente: cliente.id,
          nomeClienteSnapshot: cliente.nome,
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
      _descricaoController.clear();
      _tipoEquipamentoController.text = 'SMARTPHONE';
      _marcaController.clear();
      _modeloController.clear();
      _numeroSerieController.clear();
      _imeiController.clear();
      _acessoriosController.clear();
      _defeitoController.clear();
      _diagnosticoController.clear();
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
          onRefresh: _carregarClientes,
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
      child: const Row(
        children: <Widget>[
          _HeaderIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Iniciar assistência',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Cliente, equipamento e defeito em uma tela rápida para balcão.',
                  style: TextStyle(color: Color(0xFFD7E3F5), height: 1.35),
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
          Expanded(child: Text('Carregando clientes...')),
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
            'Não foi possível carregar os clientes',
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
            onPressed: _carregarClientes,
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
          DropdownButtonFormField<ClienteUsuario>(
            value: _clienteSelecionado,
            isExpanded: true,
            decoration: _inputDecoration(
              label: 'Cliente',
              icon: Icons.person_search_outlined,
            ),
            hint: const Text('Selecione um cliente'),
            items: _clientes
                .map(
                  (cliente) => DropdownMenuItem<ClienteUsuario>(
                    value: cliente,
                    child: Text(
                      cliente.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (cliente) => setState(() => _clienteSelecionado = cliente),
          ),
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
                  label: 'Vencimento',
                  value: _formatarData(_vencimentoFinanceiroEm),
                  onTap: _selecionarVencimentoFinanceiro,
                ),
              ),
            ],
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null ? null : Icon(icon, size: 21),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accentColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
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
