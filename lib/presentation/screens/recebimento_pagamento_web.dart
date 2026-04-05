
import 'package:flutter/material.dart';

import '../../core/di/operacao_module.dart';
import '../../data/models/operacao_models.dart';
import '../../domain/services/operacao/operacao_service.dart';
import '../../top_navigation_bar.dart';

class RecebimentoPagamentoWeb extends StatefulWidget {
  const RecebimentoPagamentoWeb({
    super.key,
    required this.valorTotalVenda,
    required this.itensResumo,
    required this.idColaborador,
    required this.nomeColaborador,
    this.clienteNome,
    this.numeroVenda,
    this.operacaoService,
    this.embedded = false,
    this.onBack,
    this.onSuccess,
  });

  final double valorTotalVenda;
  final List<Map<String, dynamic>> itensResumo;
  final String idColaborador;
  final String nomeColaborador;
  final String? clienteNome;
  final String? numeroVenda;
  final OperacaoService? operacaoService;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;

  @override
  State<RecebimentoPagamentoWeb> createState() =>
      _RecebimentoPagamentoWebState();
}

class _RecebimentoPagamentoWebState extends State<RecebimentoPagamentoWeb> {
  late final List<Map<String, dynamic>> _itensResumo;

  late final OperacaoService _operacaoService;
  bool _salvandoOperacao = false;

  List<Map<String, dynamic>> _formasPagamentoVisiveis() {
    return _formasPagamento
        .where((forma) => forma['selecionado'] == true)
        .toList();
  }

  final List<Map<String, dynamic>> _formasPagamento = [
    {
      'codigo': 'TIPO1',
      'titulo': 'Dinheiro',
      'descricao': 'Recebimento no caixa com troco e conferência imediata.',
      'icone': Icons.payments_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO2',
      'titulo': 'Pix',
      'descricao': 'Confirmação rápida via chave, QR Code ou copia e cola.',
      'icone': Icons.qr_code_2_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO3',
      'titulo': 'Cartão de crédito',
      'descricao': 'Recebimento parcelado ou à vista com operadora.',
      'icone': Icons.credit_card_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO4',
      'titulo': 'Cartão de débito',
      'descricao': 'Liquidação imediata com confirmação de maquininha.',
      'icone': Icons.point_of_sale_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO5',
      'titulo': 'Boleto',
      'descricao': 'Emissão para pagamento posterior com baixa futura.',
      'icone': Icons.receipt_long_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO6',
      'titulo': 'Fiado',
      'descricao': 'Lançamento em aberto para cobrança posterior.',
      'icone': Icons.history_toggle_off_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO7',
      'titulo': 'Crediário',
      'descricao': 'Lançamento em aberto para cobrança posterior.',
      'icone': Icons.history_toggle_off_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO8',
      'titulo': 'Convênio',
      'descricao': 'Lançamento em aberto para cobrança posterior.',
      'icone': Icons.history_toggle_off_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO9',
      'titulo': 'Vale',
      'descricao': 'Lançamento em aberto para cobrança posterior.',
      'icone': Icons.history_toggle_off_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
    {
      'codigo': 'TIPO10',
      'titulo': 'Outros',
      'descricao': 'Outros tipos.',
      'icone': Icons.history_toggle_off_outlined,
      'selecionado': false,
      'valor': 0.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _itensResumo = List<Map<String, dynamic>>.from(widget.itensResumo);
    _operacaoService = widget.operacaoService ?? OperacaoModule.operacaoService;
  }

  double _valorSelecionadoTotal() {
    return _formasPagamento
        .where((forma) => forma['selecionado'] == true)
        .fold<double>(
          0.0,
          (soma, forma) => soma + ((forma['valor'] ?? 0.0) as double),
        );
  }

  int _quantidadeFormasSelecionadas() {
    return _formasPagamento
        .where((forma) => forma['selecionado'] == true)
        .length;
  }

  double _valorRestante() {
    return widget.valorTotalVenda - _valorSelecionadoTotal();
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }

  Future<void> _fecharTela() async {
    if (widget.embedded) {
      widget.onBack?.call();
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  List<FormaPagamentoSelecionada> _montarFormasSelecionadas() {
    return _formasPagamento
        .where((forma) => forma['selecionado'] == true)
        .map(
          (forma) => FormaPagamentoSelecionada(
        codigo: (forma['codigo'] ?? '').toString(),
        valor: ((forma['valor'] ?? 0.0) as num).toDouble(),
      ),
    )
        .toList();
  }

  List<ItemVendaAtual> _montarItensDaVenda() {
    return _itensResumo.map((item) {
      final idProduto = (item['id'] ??
          item['codigo'] ??
          item['idSKU'] ??
          item['idCodigoUnicoDoProduto'] ??
          '')
          .toString();

      return ItemVendaAtual(
        idProduto: idProduto,
        nome: (item['nome'] ?? '').toString(),
        quantidade: (item['quantidade'] ?? 1) as int,
        valorUnitario: ((item['valor'] ?? 0.0) as num).toDouble(),
        ehServico: (item['ehServico'] ?? false) == true,
      );
    }).toList();
  }

  void _preencherValorRestante(Map<String, dynamic> forma) {
    final restante = _valorRestante();
    final valorAtual = ((forma['valor'] ?? 0.0) as double);
    final novoValor = valorAtual + restante;

    setState(() {
      forma['valor'] = novoValor < 0 ? 0.0 : novoValor;
      forma['selecionado'] = true;
    });
  }

  void _alternarForma(Map<String, dynamic> forma, bool selecionado) {
    setState(() {
      forma['selecionado'] = selecionado;

      if (!selecionado) {
        forma['valor'] = 0.0;
      }
    });
  }

  void _alterarValorForma(Map<String, dynamic> forma, String value) {
    final normalizado = value.replaceAll('R\$', '').replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalizado) ?? 0.0;
    setState(() {
      forma['valor'] = parsed < 0 ? 0.0 : parsed;
      if (parsed > 0) {
        forma['selecionado'] = true;
      }
    });
  }

  Future<void> _mostrarDialogMensagem({
    required String titulo,
    required String mensagem,
    bool sucesso = false,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            sucesso ? Icons.check_circle_outline : Icons.info_outline,
            color: sucesso
                ? const Color(0xFF2E7D32)
                : Theme.of(context).colorScheme.primary,
            size: 34,
          ),
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarOperacao() async {

    if (_quantidadeFormasSelecionadas() == 0) {
      await _mostrarDialogMensagem(
        titulo: 'Selecione uma forma de pagamento',
        mensagem:
        'Para confirmar a operação, escolha pelo menos uma forma de pagamento.',
      );
      return;
    }

    final diferenca = (_valorSelecionadoTotal() - widget.valorTotalVenda).abs();
    if (diferenca > 0.009) {
      await _mostrarDialogMensagem(
        titulo: 'Ajuste os valores para finalizar',
        mensagem:
        'A soma das formas selecionadas deve ser exatamente igual ao total da venda.',
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            Icons.verified_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 34,
          ),
          title: const Text('Confirmar operação'),
          content: Text(
            'Deseja confirmar o recebimento/pagamento no valor de ${_formatarValor(widget.valorTotalVenda)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      _salvandoOperacao = true;
    });

    try {
      final response = await _operacaoService.finalizarVenda(
        OperacaoVendaInput(
          descricao: 'Venda ${widget.numeroVenda ?? 'em andamento'}',
          idColaborador: widget.idColaborador,
          nomeColaborador: widget.nomeColaborador,
          itens: _montarItensDaVenda(),
          formasPagamento: _montarFormasSelecionadas(),
        ),
      );

      if (!mounted) return;

      await _mostrarDialogMensagem(
        titulo: 'Operação concluída',
        mensagem: 'Venda enviada com sucesso. UUID: ${response.uuid}',
        sucesso: true,
      );

      if (!mounted) return;

      if (widget.embedded) {
        widget.onSuccess?.call();
      } else {
        await _fecharTela();
      }
    } catch (e) {
      if (!mounted) return;

      await _mostrarDialogMensagem(
        titulo: 'Erro ao enviar operação',
        mensagem: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvandoOperacao = false;
        });
      }
    }
  }

  Widget _buildBadgeInformativo(String texto, IconData icone) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPremium(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recebimento / Pagamento',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          _buildBadgeInformativo(
            (widget.numeroVenda?.trim().isNotEmpty ?? false)
                ? widget.numeroVenda!.trim()
                : 'Venda em andamento',
            Icons.receipt_long_outlined,
          ),
          _buildBadgeInformativo(
            (widget.clienteNome?.trim().isNotEmpty ?? false)
                ? widget.clienteNome!.trim()
                : 'Cliente não identificado',
            Icons.person_outline,
          ),
          _buildBadgeInformativo(
            '${_quantidadeFormasSelecionadas()} forma(s) ativa(s)',
            Icons.payments_outlined,
          ),
          _buildBadgeInformativo(
            'Total ${_formatarValor(widget.valorTotalVenda)}',
            Icons.attach_money_outlined,
          ),
          const SizedBox(width: 6),
          Text(
            'Selecione uma ou mais formas, distribua os valores e confirme a operação com segurança.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelFormaPagamento(Map<String, dynamic> forma) {
    final theme = Theme.of(context);
    final bool selecionado = forma['selecionado'] == true;
    final double valor = (forma['valor'] ?? 0.0) as double;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selecionado
            ? theme.colorScheme.primary.withOpacity(0.07)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selecionado
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selecionado ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(selecionado ? 0.06 : 0.03),
            blurRadius: selecionado ? 16 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: selecionado,
                onChanged: (value) => _alternarForma(forma, value ?? false),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  forma['icone'] as IconData,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  forma['titulo'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _formatarValor(valor),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            forma['descricao'] as String,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  enabled: selecionado,
                  initialValue: valor == 0.0 ? '' : valor.toStringAsFixed(2),
                  decoration: InputDecoration(
                    labelText: 'Valor para esta forma',
                    hintText: '0.00',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (value) => _alterarValorForma(forma, value),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _preencherValorRestante(forma),
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Completar restante'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(170, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPainelEsquerdo() {
    final theme = Theme.of(context);
    final formasVisiveis = _formasPagamentoVisiveis();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Formas de pagamento',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _buildBadgeInformativo(
                  '${_formasPagamento.length} opções',
                  Icons.grid_view_rounded,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Clique em uma forma para exibir o card correspondente. Clique novamente para ocultar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _formasPagamento.map((forma) {
                final selecionado = forma['selecionado'] == true;

                return FilterChip(
                  label: Text(forma['titulo'] as String),
                  selected: selecionado,
                  avatar: Icon(
                    forma['icone'] as IconData,
                    size: 18,
                    color: selecionado
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                  onSelected: (selected) => _alternarForma(forma, selected),
                  selectedColor: theme.colorScheme.primary,
                  checkmarkColor: theme.colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selecionado
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  side: BorderSide(
                    color: selecionado
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: formasVisiveis.isEmpty
                  ? Center(
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 38,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma forma aberta',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione uma forma de pagamento acima para exibir o card e preencher o valor.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SingleChildScrollView(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: formasVisiveis.map((forma) {
                    return SizedBox(
                      width: 520,
                      child: _buildPainelFormaPagamento(forma),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaResumo(String titulo, String valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: destaque ? 15 : 14,
                fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: destaque ? 16 : 14,
              fontWeight: destaque ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoDaVenda() {
    final theme = Theme.of(context);
    final totalSelecionado = _valorSelecionadoTotal();
    final restante = _valorRestante();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo da venda',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _buildLinhaResumo(
              'Venda',
              (widget.numeroVenda?.trim().isNotEmpty ?? false)
                  ? widget.numeroVenda!.trim()
                  : 'Em andamento',
            ),
            _buildLinhaResumo(
              'Cliente',
              (widget.clienteNome?.trim().isNotEmpty ?? false)
                  ? widget.clienteNome!.trim()
                  : 'Não identificado',
            ),
            const Divider(height: 28),
            Text(
              'Itens da operação',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _itensResumo.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _itensResumo[index];
                  final int quantidade = (item['quantidade'] ?? 1) as int;
                  final double valor = ((item['valor'] ?? 0.0) as num).toDouble();

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${item['nome']} ($quantidade x)',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          _formatarValor(valor * quantidade),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 28),
            _buildLinhaResumo(
              'Formas selecionadas',
              _quantidadeFormasSelecionadas().toString(),
            ),
            _buildLinhaResumo(
              'Total selecionado',
              _formatarValor(totalSelecionado),
            ),
            _buildLinhaResumo(
              'Valor restante',
              _formatarValor(restante),
              destaque: true,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: restante.abs() < 0.009
                    ? const Color(0xFFE9F6EC)
                    : const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                restante.abs() < 0.009
                    ? 'Valores conferidos. A operação está pronta para confirmação.'
                    : 'Ajuste a soma das formas de pagamento até alcançar o valor total da venda.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: restante.abs() < 0.009
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFB26A00),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraAcoes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _fecharTela,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Total da venda: ${_formatarValor(widget.valorTotalVenda)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FilledButton.icon(
                onPressed: _salvandoOperacao ? null : _confirmarOperacao,
                icon: _salvandoOperacao
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_salvandoOperacao ? 'Enviando...' : 'Confirmar'),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyResponsivo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool larguraEstreita = constraints.maxWidth < 1450;

        if (larguraEstreita) {
          return Column(
            children: [
              Expanded(
                child: _buildPainelEsquerdo(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 420,
                child: _buildResumoDaVenda(),
              ),
              const SizedBox(height: 16),
              _buildBarraAcoes(),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: _buildPainelEsquerdo(),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 420,
                    child: _buildResumoDaVenda(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildBarraAcoes(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget conteudo = Column(
      children: [
        _buildHeaderPremium(context),
        const SizedBox(height: 16),
        Expanded(
          child: _buildBodyResponsivo(),
        ),
      ],
    );

    if (widget.embedded) {
      return conteudo;
    }

    return Scaffold(
      appBar: TopNavigationBar(
        items: const [
          TopNavItemData(
            title: 'Início',
            subItems: ['Preferências do Sistema', 'Painel Administrativo'],
          ),
          TopNavItemData(
            title: 'Permitir',
            subItems: ['Gerenciar Permissões', 'Alterar Configurações'],
          ),
          TopNavItemData(
            title: 'Cadastros',
            subItems: ['Clientes', 'Produtos', 'Fornecedores'],
          ),
          TopNavItemData(
            title: 'Relatórios',
            subItems: ['Vendas', 'Estoque', 'Financeiro'],
          ),
          TopNavItemData(
            title: 'Executar',
            subItems: ['Processar Pagamentos', 'Fechar Caixa'],
          ),
          TopNavItemData(
            title: 'Configurações',
            subItems: ['Sistema', 'Usuários'],
          ),
          TopNavItemData(
            title: 'Automações',
            subItems: ['Tarefas Agendadas'],
          ),
          TopNavItemData(
            title: 'Ajuda',
            subItems: ['Suporte', 'Sobre'],
          ),
        ],
        onNotificationPressed: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: conteudo,
      ),
    );
  }

}
