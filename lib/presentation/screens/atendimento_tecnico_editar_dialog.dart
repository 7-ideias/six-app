import 'package:flutter/material.dart';

import '../../data/models/atendimento_tecnico_models.dart';
import '../../data/models/produto_model.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import 'produto_lista_sub_painel_web.dart';

class AtendimentoTecnicoEditarDialog extends StatefulWidget {
  const AtendimentoTecnicoEditarDialog({super.key, required this.atendimento});

  final AtendimentoTecnicoModel atendimento;

  @override
  State<AtendimentoTecnicoEditarDialog> createState() => _AtendimentoTecnicoEditarDialogState();
}

class _AtendimentoTecnicoEditarDialogState extends State<AtendimentoTecnicoEditarDialog> {
  final AtendimentoTecnicoService _service = AtendimentoTecnicoService();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _tipoEquipamentoController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _acessoriosController = TextEditingController();
  final TextEditingController _defeitoController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _observacaoAuditoriaController = TextEditingController();

  late DateTime _validadeOrcamentoEm;
  final List<_AtendimentoItemEditavel> _itens = <_AtendimentoItemEditavel>[];
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final atendimento = widget.atendimento;
    final equipamento = atendimento.equipamento;
    _descricaoController.text = atendimento.descricao ?? '';
    _tipoEquipamentoController.text = equipamento?.tipo ?? '';
    _marcaController.text = equipamento?.marca ?? '';
    _modeloController.text = equipamento?.modelo ?? '';
    _numeroSerieController.text = equipamento?.numeroSerie ?? '';
    _imeiController.text = equipamento?.imei ?? '';
    _acessoriosController.text = equipamento?.acessorios ?? equipamento?.observacoesEntrada ?? '';
    _defeitoController.text = atendimento.defeitoRelatado ?? '';
    _diagnosticoController.text = atendimento.diagnosticoTecnico ?? '';
    _validadeOrcamentoEm = atendimento.validadeOrcamentoEm ?? DateTime.now().add(const Duration(days: 7));
    _itens.addAll(atendimento.itens.map(_AtendimentoItemEditavel.fromModel));
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
    _observacaoAuditoriaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarValidade() async {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _validadeOrcamentoEm.isBefore(inicio) ? inicio : _validadeOrcamentoEm,
      firstDate: inicio,
      lastDate: inicio.add(const Duration(days: 365)),
      helpText: 'Validade do orçamento',
    );
    if (selecionada == null) return;
    setState(() {
      _validadeOrcamentoEm = DateTime(selecionada.year, selecionada.month, selecionada.day);
    });
  }

  Future<void> _abrirSelecaoItens(String tipoInicial) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.88,
            height: MediaQuery.of(dialogContext).size.height * 0.86,
            child: SubPainelWebProdutoLista(
              isSelecao: true,
              permitirSelecaoMultipla: true,
              tipoInicial: tipoInicial,
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    final produtos = result is List ? result.whereType<ProdutoModel>().toList(growable: false) : <ProdutoModel>[if (result is ProdutoModel) result];
    if (produtos.isEmpty) return;
    setState(() {
      for (final produto in produtos) {
        _adicionarProduto(produto);
      }
    });
  }

  void _adicionarProduto(ProdutoModel produto) {
    final tipoCodigo = _ehServico(produto) ? 'SERVICE' : 'PRODUCT';
    final chave = '$tipoCodigo:${produto.id ?? produto.codigoDeBarras}:${produto.nomeProduto}';
    final index = _itens.indexWhere((item) => item.chave == chave);
    if (index >= 0) {
      _itens[index] = _itens[index].copyWith(quantidade: _itens[index].quantidade + 1);
      return;
    }
    _itens.add(_AtendimentoItemEditavel(
      chave: chave,
      idSku: produto.id ?? produto.codigoDeBarras,
      descricao: produto.nomeProduto,
      tipoCodigo: tipoCodigo,
      quantidade: 1,
      valorUnitario: produto.precoVenda,
    ));
  }

  bool _ehServico(ProdutoModel produto) {
    final tipo = produto.tipoProduto.trim().toUpperCase();
    return tipo == 'SERVICO' || tipo == 'SERVIÇO' || tipo == 'SERVICE';
  }

  void _alterarQuantidade(_AtendimentoItemEditavel item, int delta) {
    setState(() {
      final index = _itens.indexWhere((element) => element.chave == item.chave);
      if (index < 0) return;
      final quantidade = _itens[index].quantidade + delta;
      if (quantidade <= 0) {
        _itens.removeAt(index);
        return;
      }
      _itens[index] = _itens[index].copyWith(quantidade: quantidade);
    });
  }

  void _removerItem(_AtendimentoItemEditavel item) {
    setState(() => _itens.removeWhere((element) => element.chave == item.chave));
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    if (_validadeOrcamentoEm.isBefore(inicioHoje)) {
      _mostrarMensagem('A validade do orçamento não pode ser anterior à data atual.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await _service.atualizar(
        id: widget.atendimento.id,
        input: AtendimentoTecnicoUpdateInput(
          validadeOrcamentoEm: _validadeOrcamentoEm,
          descricao: _textoOuNulo(_descricaoController.text),
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
          itens: _itens.map((item) => item.toInput()).toList(growable: false),
          observacaoAuditoria: _textoOuNulo(_observacaoAuditoriaController.text),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível salvar as alterações: $error');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
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

  String _formatarMoeda(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating));
  }

  double get _total => _itens.fold<double>(0, (total, item) => total + item.total);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 820),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Editar ${widget.atendimento.numero}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  if (widget.atendimento.assinaturaAprovada || widget.atendimento.requerNovaAssinatura)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Ao salvar alterações de produtos, serviços, validade ou observações, esta versão do orçamento exigirá nova assinatura do cliente.',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                      ),
                    ),
                  _grid(<Widget>[
                    TextField(controller: _descricaoController, decoration: const InputDecoration(labelText: 'Descrição interna')),
                    InkWell(
                      onTap: _selecionarValidade,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Validade do orçamento', suffixIcon: Icon(Icons.event_outlined)),
                        child: Text(_formatarData(_validadeOrcamentoEm), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    TextField(controller: _tipoEquipamentoController, decoration: const InputDecoration(labelText: 'Tipo de equipamento')),
                    TextField(controller: _marcaController, decoration: const InputDecoration(labelText: 'Marca')),
                    TextField(controller: _modeloController, decoration: const InputDecoration(labelText: 'Modelo')),
                    TextField(controller: _numeroSerieController, decoration: const InputDecoration(labelText: 'Número de série')),
                    TextField(controller: _imeiController, decoration: const InputDecoration(labelText: 'IMEI')),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: _acessoriosController, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Acessórios / observações de entrada')),
                  const SizedBox(height: 12),
                  TextField(controller: _defeitoController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Defeito relatado')),
                  const SizedBox(height: 12),
                  TextField(controller: _diagnosticoController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Diagnóstico / novas observações técnicas')),
                  const SizedBox(height: 12),
                  TextField(controller: _observacaoAuditoriaController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Observação de auditoria da alteração', hintText: 'Ex.: cliente solicitou incluir película e retirar limpeza interna')),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(child: Text('Produtos e serviços', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(onPressed: () => _abrirSelecaoItens('PRODUTO'), icon: const Icon(Icons.inventory_2_outlined), label: const Text('Adicionar peça')),
                      const SizedBox(width: 8),
                      FilledButton.icon(onPressed: () => _abrirSelecaoItens('SERVICO'), icon: const Icon(Icons.handyman_outlined), label: const Text('Adicionar serviço')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_itens.isEmpty)
                    Text('Nenhum item vinculado.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                  else
                    ..._itens.map((item) => _itemRow(theme, item)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text('Total: ${_formatarMoeda(_total)}', style: const TextStyle(fontWeight: FontWeight.w900))),
                  TextButton(onPressed: _salvando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                    label: Text(_salvando ? 'Salvando...' : 'Salvar alterações'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(children: children.map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child)).toList());
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((child) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: child)).toList(),
        );
      },
    );
  }

  Widget _itemRow(ThemeData theme, _AtendimentoItemEditavel item) {
    final servico = item.tipoCodigo == 'SERVICE';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.38), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: <Widget>[
          Icon(servico ? Icons.handyman_outlined : Icons.inventory_2_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(item.descricao, style: const TextStyle(fontWeight: FontWeight.w900))),
          IconButton(onPressed: () => _alterarQuantidade(item, -1), icon: const Icon(Icons.remove_circle_outline)),
          Text(item.quantidade.toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
          IconButton(onPressed: () => _alterarQuantidade(item, 1), icon: const Icon(Icons.add_circle_outline)),
          SizedBox(width: 96, child: Text(_formatarMoeda(item.total), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
          IconButton(onPressed: () => _removerItem(item), icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}

class _AtendimentoItemEditavel {
  const _AtendimentoItemEditavel({required this.chave, required this.idSku, required this.descricao, required this.tipoCodigo, required this.quantidade, required this.valorUnitario});

  final String chave;
  final String? idSku;
  final String descricao;
  final String tipoCodigo;
  final int quantidade;
  final double valorUnitario;

  double get total => quantidade * valorUnitario;

  factory _AtendimentoItemEditavel.fromModel(AtendimentoTecnicoItemModel item) {
    return _AtendimentoItemEditavel(
      chave: '${item.tipoItemCodigo}:${item.idSku ?? item.id}:${item.descricaoSnapshot}',
      idSku: item.idSku,
      descricao: item.descricaoSnapshot,
      tipoCodigo: item.tipoItemCodigo,
      quantidade: item.quantidade <= 0 ? 1 : item.quantidade.round(),
      valorUnitario: item.valorUnitario,
    );
  }

  _AtendimentoItemEditavel copyWith({int? quantidade}) {
    return _AtendimentoItemEditavel(
      chave: chave,
      idSku: idSku,
      descricao: descricao,
      tipoCodigo: tipoCodigo,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario,
    );
  }

  AtendimentoTecnicoItemInput toInput() {
    final produto = tipoCodigo == 'PRODUCT';
    return AtendimentoTecnicoItemInput(
      tipoItemId: produto ? 10 : 20,
      tipoItemCodigo: tipoCodigo,
      idSku: idSku,
      descricaoSnapshot: descricao,
      quantidade: quantidade.toDouble(),
      valorUnitario: valorUnitario,
      movimentaEstoque: produto,
    );
  }
}
