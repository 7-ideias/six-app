import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/produto_model.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
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

  late DateTime _validadeOrcamentoEm;
  late DateTime _vencimentoFinanceiroEm;
  bool _salvando = false;

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: <Widget>[
            _hero(),
            const SizedBox(height: 16),
            _formCard(),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
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
                  '${_clienteLabel(widget.atendimento)} • ${_itens.length} item(ns)',
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
        idTecnicoResponsavel: null,
        nomeTecnicoResponsavel: null,
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

    setState(() => _salvando = true);
    try {
      await _service.atualizar(
        id: widget.atendimento.id,
        input: AtendimentoTecnicoUpdateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          descricao: _textoOuNulo(_descricaoController.text),
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
          itens: _itens.map((item) => item.toInput()).toList(growable: false),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    IconData? icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null ? null : Icon(icon, size: 21),
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

  AtendimentoTecnicoItemInput toInput() {
    return AtendimentoTecnicoItemInput(
      tipoItemId: tipoItemId,
      tipoItemCodigo: tipoCodigo,
      idSku: idSku,
      descricaoSnapshot: descricao,
      quantidade: quantidade.toDouble(),
      valorUnitario: valorUnitario,
      desconto: desconto,
      idTecnicoResponsavel: idTecnicoResponsavel,
      nomeTecnicoResponsavel: nomeTecnicoResponsavel,
      movimentaEstoque: movimentaEstoque,
    );
  }
}
