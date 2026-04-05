
import 'package:flutter/material.dart';

class AgendaFinanceiraWeb extends StatefulWidget {
  const AgendaFinanceiraWeb({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<AgendaFinanceiraWeb> createState() => _AgendaFinanceiraWebState();
}

class _AgendaFinanceiraWebState extends State<AgendaFinanceiraWeb> {

  void _voltarTelaAnterior() {
    if (widget.embedded) {
      widget.onBack?.call();
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  final ScrollController _mainScrollController = ScrollController();

  final List<String> _periodos = const [
    'Hoje',
    'Próximos 7 dias',
    'Este mês',
    'Próximo mês',
    'Personalizado',
  ];

  final List<String> _tipos = const [
    'Todos',
    'Receber',
    'Pagar',
  ];

  final List<String> _statusDisponiveis = const [
    'Todos',
    'Previsto',
    'Pendente',
    'Vence hoje',
    'Vencido',
    'Pago',
    'Recebido',
    'Parcial',
    'Cancelado',
  ];

  final List<String> _origens = const [
    'Todas',
    'Venda',
    'Ordem de serviço',
    'Despesa manual',
    'Compra',
    'Parcela',
    'Movimentação de caixa',
  ];

  String _periodoSelecionado = 'Próximos 7 dias';
  String _tipoSelecionado = 'Todos';
  String _statusSelecionado = 'Todos';
  String _origemSelecionada = 'Todas';
  String _empresaSelecionada = 'Matriz Centro';
  bool _mostrarSomenteCriticos = false;

  int _abaSelecionada = 0;
  Map<String, dynamic>? _lancamentoSelecionado;

  final List<String> _abas = const [
    'Agenda',
    'Calendário',
    'Fluxo previsto',
  ];

  final List<Map<String, dynamic>> _empresas = const [
    {'id': 'emp-001', 'nome': 'Matriz Centro'},
    {'id': 'emp-002', 'nome': 'Filial Norte'},
  ];

  final List<Map<String, dynamic>> _cardsResumo = const [
    {
      'titulo': 'Receber hoje',
      'valor': 'R\$ 4.580,00',
      'icone': Icons.south_west_rounded,
      'ajuda': '3 lançamentos previstos para entrada no dia.',
    },
    {
      'titulo': 'Pagar hoje',
      'valor': 'R\$ 2.145,00',
      'icone': Icons.north_east_rounded,
      'ajuda': '2 contas com vencimento no dia.',
    },
    {
      'titulo': 'Vencidos a receber',
      'valor': 'R\$ 1.790,00',
      'icone': Icons.warning_amber_rounded,
      'ajuda': 'Clientes com cobrança pendente.',
    },
    {
      'titulo': 'Vencidos a pagar',
      'valor': 'R\$ 930,00',
      'icone': Icons.error_outline_rounded,
      'ajuda': 'Compromissos atrasados com fornecedores.',
    },
    {
      'titulo': 'Saldo previsto da semana',
      'valor': 'R\$ 6.215,00',
      'icone': Icons.query_stats_rounded,
      'ajuda': 'Entradas previstas menos saídas previstas.',
    },
    {
      'titulo': 'Saldo previsto do mês',
      'valor': 'R\$ 18.940,00',
      'icone': Icons.account_balance_wallet_outlined,
      'ajuda': 'Indicador consolidado do período atual.',
    },
  ];

  final List<Map<String, dynamic>> _gruposAgenda = [
    {
      'grupo': 'Atrasados',
      'descricao':
      'Compromissos que já passaram do vencimento e precisam de ação imediata.',
      'itens': [
        {
          'id': 'fin-1001',
          'tipo': 'receber',
          'descricao': 'OS #2481 - Troca de display',
          'contato': 'Marina Oliveira',
          'valor': 790.00,
          'vencimento': '28/03/2026',
          'status': 'Vencido',
          'origem': 'Ordem de serviço',
          'formaPagamento': 'Pix',
          'empresa': 'Matriz Centro',
          'categoria': 'Serviços técnicos',
          'responsavel': 'Carlos Lima',
          'observacoes': 'Cliente pediu reenvio do link de pagamento.',
          'historico': [
            'OS concluída em 26/03/2026',
            'Cobrança enviada em 27/03/2026',
            'Sem confirmação de pagamento até o momento',
          ],
          'acoes': ['Receber', 'Enviar cobrança', 'Registrar parcial', 'Detalhes'],
        },
        {
          'id': 'fin-1002',
          'tipo': 'pagar',
          'descricao': 'Fornecedor Atlas Peças - NF 5561',
          'contato': 'Atlas Importadora',
          'valor': 930.00,
          'vencimento': '29/03/2026',
          'status': 'Vencido',
          'origem': 'Compra',
          'formaPagamento': 'Boleto',
          'empresa': 'Matriz Centro',
          'categoria': 'Reposição de estoque',
          'responsavel': 'Aline Costa',
          'observacoes':
          'Prioridade alta para evitar bloqueio de fornecimento.',
          'historico': [
            'Compra lançada em 21/03/2026',
            'Boleto anexado em 22/03/2026',
            'Fornecedor cobrou retorno comercial',
          ],
          'acoes': ['Pagar', 'Reagendar', 'Cancelar', 'Detalhes'],
        },
      ],
    },
    {
      'grupo': 'Hoje',
      'descricao': 'Compromissos financeiros que vencem no dia.',
      'itens': [
        {
          'id': 'fin-1003',
          'tipo': 'receber',
          'descricao': 'Venda balcão #PV-9201',
          'contato': 'Lucas Fernandes',
          'valor': 245.90,
          'vencimento': '30/03/2026',
          'status': 'Vence hoje',
          'origem': 'Venda',
          'formaPagamento': 'Cartão de crédito',
          'empresa': 'Matriz Centro',
          'categoria': 'Venda de acessórios',
          'responsavel': 'Bruna Neri',
          'observacoes': 'Cliente confirmou pagamento no fim da tarde.',
          'historico': [
            'Venda registrada hoje às 09:12',
            'Pagamento agendado para captura às 18:00',
          ],
          'acoes': ['Receber', 'Detalhes'],
        },
        {
          'id': 'fin-1004',
          'tipo': 'pagar',
          'descricao': 'Conta de internet da loja',
          'contato': 'Connect Fibra',
          'valor': 329.00,
          'vencimento': '30/03/2026',
          'status': 'Vence hoje',
          'origem': 'Despesa manual',
          'formaPagamento': 'Débito automático',
          'empresa': 'Matriz Centro',
          'categoria': 'Infraestrutura',
          'responsavel': 'Carlos Lima',
          'observacoes': 'Confirmar se o débito foi processado.',
          'historico': [
            'Despesa recorrente lançada automaticamente',
            'Débito previsto para hoje',
          ],
          'acoes': ['Pagar', 'Detalhes'],
        },
      ],
    },
    {
      'grupo': 'Próximos dias',
      'descricao': 'Previsão operacional para os próximos vencimentos.',
      'itens': [
        {
          'id': 'fin-1005',
          'tipo': 'receber',
          'descricao': 'Plano fidelidade empresas - parcela 03/06',
          'contato': 'Clínica Vida Plena',
          'valor': 1250.00,
          'vencimento': '02/04/2026',
          'status': 'Pendente',
          'origem': 'Parcela',
          'formaPagamento': 'Transferência',
          'empresa': 'Filial Norte',
          'categoria': 'Contrato recorrente',
          'responsavel': 'Andréia Souza',
          'observacoes': 'Cliente costuma pagar até o vencimento.',
          'historico': [
            'Contrato recorrente ativo',
            'Parcela gerada automaticamente',
          ],
          'acoes': ['Enviar lembrete', 'Detalhes'],
        },
        {
          'id': 'fin-1006',
          'tipo': 'pagar',
          'descricao': 'Folha técnica terceirizada',
          'contato': 'Equipe Fast Repair',
          'valor': 1780.00,
          'vencimento': '03/04/2026',
          'status': 'Previsto',
          'origem': 'Ordem de serviço',
          'formaPagamento': 'Pix',
          'empresa': 'Filial Norte',
          'categoria': 'Terceiros',
          'responsavel': 'Renata Alves',
          'observacoes':
          'Pagamento vinculado a serviços concluídos da semana.',
          'historico': [
            'Apuração criada automaticamente pelo módulo operacional',
          ],
          'acoes': ['Pagar', 'Detalhes'],
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _lancamentoSelecionado =
    _gruposAgenda.first['itens'].first as Map<String, dynamic>;
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  Color _corTipo(String tipo) {
    return tipo == 'receber'
        ? const Color(0xFF0F9D58)
        : const Color(0xFFC66A00);
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Vencido':
        return const Color(0xFFC62828);
      case 'Vence hoje':
        return const Color(0xFFEF6C00);
      case 'Pago':
      case 'Recebido':
        return const Color(0xFF2E7D32);
      case 'Parcial':
        return const Color(0xFF6A1B9A);
      case 'Cancelado':
        return const Color(0xFF616161);
      default:
        return const Color(0xFF1565C0);
    }
  }

  List<Map<String, dynamic>> get _itensFiltrados {
    return _gruposAgenda
        .expand((grupo) => (grupo['itens'] as List).cast<Map<String, dynamic>>())
        .where((item) {
      final bateTipo = _tipoSelecionado == 'Todos' ||
          (_tipoSelecionado == 'Receber' && item['tipo'] == 'receber') ||
          (_tipoSelecionado == 'Pagar' && item['tipo'] == 'pagar');

      final bateStatus =
          _statusSelecionado == 'Todos' || item['status'] == _statusSelecionado;

      final bateOrigem =
          _origemSelecionada == 'Todas' || item['origem'] == _origemSelecionada;

      final bateEmpresa = item['empresa'] == _empresaSelecionada;

      final bateCritico = !_mostrarSomenteCriticos ||
          item['status'] == 'Vencido' ||
          item['status'] == 'Vence hoje';

      return bateTipo && bateStatus && bateOrigem && bateEmpresa && bateCritico;
    }).toList();
  }

  List<Map<String, dynamic>> _itensPorGrupo(String grupo) {
    final grupoEncontrado = _gruposAgenda.firstWhere(
          (g) => g['grupo'] == grupo,
      orElse: () => {'itens': <Map<String, dynamic>>[]},
    );

    return (grupoEncontrado['itens'] as List)
        .cast<Map<String, dynamic>>()
        .where((item) => _itensFiltrados.any((filtrado) => filtrado['id'] == item['id']))
        .toList();
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 16,
        spacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.calendar_month_rounded,
                          color: Colors.white),
                    ),
                    Text(
                      'Agenda Financeira',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _buildChipInfo(
                      context,
                      icon: Icons.store_mall_directory_outlined,
                      text: _empresaSelecionada,
                    ),
                    _buildChipInfo(
                      context,
                      icon: Icons.tune_rounded,
                      text: _periodoSelecionado,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Central operacional para acompanhar recebimentos, pagamentos, atrasos, previsões de caixa e ações imediatas do financeiro.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _voltarTelaAnterior,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              _buildHeaderAction(
                context,
                icon: Icons.add_card_rounded,
                label: 'Novo lançamento',
              ),
              _buildHeaderAction(
                context,
                icon: Icons.picture_as_pdf_outlined,
                label: 'Exportar PDF',
              ),
              _buildHeaderAction(
                context,
                icon: Icons.notifications_active_outlined,
                label: 'Cobranças',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipInfo(BuildContext context,
      {required IconData icon, required String text}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(BuildContext context,
      {required IconData icon, required String label}) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(170, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildResumoCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width > 1500
            ? (width - 40) / 3
            : width > 1000
            ? (width - 24) / 2
            : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _cardsResumo.map((card) {
            return SizedBox(
              width: cardWidth,
              child: _buildResumoCard(context, card),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildResumoCard(BuildContext context, Map<String, dynamic> card) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
              Icon(card['icone'] as IconData, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['titulo'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card['valor'] as String,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card['ajuda'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarFiltros(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final campoLargo = width > 1600 ? 220.0 : 190.0;
            final campoMedio = width > 1600 ? 180.0 : 160.0;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildDropdownBox(
                  context,
                  label: 'Período',
                  value: _periodoSelecionado,
                  items: _periodos,
                  onChanged: (value) =>
                      setState(() => _periodoSelecionado = value!),
                  width: campoLargo,
                ),
                _buildDropdownBox(
                  context,
                  label: 'Tipo',
                  value: _tipoSelecionado,
                  items: _tipos,
                  onChanged: (value) =>
                      setState(() => _tipoSelecionado = value!),
                  width: campoMedio,
                ),
                _buildDropdownBox(
                  context,
                  label: 'Status',
                  value: _statusSelecionado,
                  items: _statusDisponiveis,
                  onChanged: (value) =>
                      setState(() => _statusSelecionado = value!),
                  width: campoMedio,
                ),
                _buildDropdownBox(
                  context,
                  label: 'Origem',
                  value: _origemSelecionada,
                  items: _origens,
                  onChanged: (value) =>
                      setState(() => _origemSelecionada = value!),
                  width: campoLargo,
                ),
                _buildDropdownBox(
                  context,
                  label: 'Empresa',
                  value: _empresaSelecionada,
                  items: _empresas.map((e) => e['nome'] as String).toList(),
                  onChanged: (value) =>
                      setState(() => _empresaSelecionada = value!),
                  width: campoLargo,
                ),
                FilterChip(
                  selected: _mostrarSomenteCriticos,
                  onSelected: (value) =>
                      setState(() => _mostrarSomenteCriticos = value),
                  label: const Text('Somente críticos'),
                  avatar: const Icon(Icons.priority_high_rounded, size: 18),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Buscar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdownBox(
      BuildContext context, {
        required String label,
        required String value,
        required List<String> items,
        required ValueChanged<String?> onChanged,
        required double width,
      }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildAbas(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(_abas.length, (index) {
          final selecionada = _abaSelecionada == index;
          return ChoiceChip(
            selected: selecionada,
            label: Text(_abas[index]),
            onSelected: (_) => setState(() => _abaSelecionada = index),
          );
        }),
      ),
    );
  }

  Widget _buildAreaPrincipal(BuildContext context) {
    switch (_abaSelecionada) {
      case 1:
        return _buildCalendarioMock(context);
      case 2:
        return _buildFluxoPrevisto(context);
      default:
        return _buildListaAgenda(context);
    }
  }

  Widget _buildListaAgenda(BuildContext context) {
    final gruposVisiveis = _gruposAgenda
        .where((grupo) => _itensPorGrupo(grupo['grupo'] as String).isNotEmpty)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: gruposVisiveis.isEmpty
            ? const Center(
          child: Text('Nenhum lançamento encontrado com os filtros atuais.'),
        )
            : ListView.separated(
          controller: _mainScrollController,
          itemCount: gruposVisiveis.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final grupo = gruposVisiveis[index];
            final nome = grupo['grupo'] as String;
            final itens = _itensPorGrupo(nome);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  grupo['descricao'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                ...itens.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLancamentoCard(context, item),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLancamentoCard(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final corTipo = _corTipo(item['tipo'] as String);
    final corStatus = _corStatus(item['status'] as String);
    final selecionado = _lancamentoSelecionado?['id'] == item['id'];

    return InkWell(
      onTap: () => setState(() => _lancamentoSelecionado = item),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.colorScheme.primary.withOpacity(0.05)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selecionado ? 1.6 : 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final empilhar = constraints.maxWidth < 980;

            if (empilhar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLancamentoBadges(context, item, corTipo, corStatus),
                  const SizedBox(height: 14),
                  _buildLancamentoConteudo(context, item),
                  const SizedBox(height: 14),
                  _buildLancamentoValorEAcoes(context, item, corTipo),
                ],
              );
            }

            return Column(
              children: [
                _buildLancamentoBadges(context, item, corTipo, corStatus),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildLancamentoConteudo(context, item),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 280,
                      child: _buildLancamentoValorEAcoes(context, item, corTipo),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLancamentoBadges(
      BuildContext context,
      Map<String, dynamic> item,
      Color corTipo,
      Color corStatus,
      ) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: corTipo.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item['tipo'] == 'receber'
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                size: 18,
                color: corTipo,
              ),
              const SizedBox(width: 8),
              Text(
                item['tipo'] == 'receber' ? 'Receber' : 'Pagar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: corTipo,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: corStatus.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item['status'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: corStatus,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item['origem'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLancamentoConteudo(
      BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['descricao'] as String,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _buildMiniInfo(context, Icons.person_outline, item['contato'] as String),
            _buildMiniInfo(
              context,
              Icons.event_outlined,
              'Vence em ${item['vencimento']}',
            ),
            _buildMiniInfo(
              context,
              Icons.credit_card_outlined,
              item['formaPagamento'] as String,
            ),
            _buildMiniInfo(
              context,
              Icons.category_outlined,
              item['categoria'] as String,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item['observacoes'] as String,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLancamentoValorEAcoes(
      BuildContext context, Map<String, dynamic> item, Color corTipo) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'R\$ ${(item['valor'] as double).toStringAsFixed(2)}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: corTipo,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: (item['acoes'] as List).take(3).map((acao) {
            return OutlinedButton(
              onPressed: () {},
              child: Text(acao.toString()),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarioMock(BuildContext context) {
    final dias = List.generate(30, (index) => index + 1);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendário financeiro',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visão mensal com densidade de compromissos, vencidos e dias críticos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: dias.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final dia = dias[index];
                  final critico = {2, 5, 12, 19, 26}.contains(dia);
                  final movimento = {1, 4, 9, 15, 21, 30}.contains(dia);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: critico
                          ? const Color(0xFFFFF2F0)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: critico
                            ? const Color(0xFFE57373)
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dia',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        if (movimento)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '3 lançamentos',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        if (critico) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Dia crítico',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFluxoPrevisto(BuildContext context) {
    final barras = [
      {'mes': 'Abr', 'entra': 12600.0, 'sai': 8900.0},
      {'mes': 'Mai', 'entra': 14150.0, 'sai': 9720.0},
      {'mes': 'Jun', 'entra': 13400.0, 'sai': 10110.0},
      {'mes': 'Jul', 'entra': 15220.0, 'sai': 10850.0},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            Text(
              'Fluxo previsto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumo visual das entradas e saídas esperadas para apoiar decisões de caixa.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ...barras.map((barra) {
              final entra = barra['entra'] as double;
              final sai = barra['sai'] as double;
              final saldo = entra - sai;
              final maxValor = 16000.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barra['mes'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBarraFluxo(
                        context,
                        label: 'Entradas',
                        valor: entra,
                        maxValor: maxValor,
                        color: const Color(0xFF0F9D58),
                      ),
                      const SizedBox(height: 10),
                      _buildBarraFluxo(
                        context,
                        label: 'Saídas',
                        valor: sai,
                        maxValor: maxValor,
                        color: const Color(0xFFC66A00),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Saldo previsto: R\$ ${saldo.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: saldo >= 0
                              ? const Color(0xFF0F9D58)
                              : const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraFluxo(
      BuildContext context, {
        required String label,
        required double valor,
        required double maxValor,
        required Color color,
      }) {
    final double ratio = (valor / maxValor).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label • R\$ ${valor.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 14,
            backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPainelDetalheUnificado(BuildContext context) {
    final item = _lancamentoSelecionado ?? _itensFiltrados.firstOrNull;
    return _buildDetalheLancamento(context, item);
  }

  Widget _buildDetalheLancamento(
      BuildContext context, Map<String, dynamic>? item) {
    final theme = Theme.of(context);

    if (item == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Center(
          child: Text('Selecione um lançamento para ver detalhes.'),
        ),
      );
    }

    final corTipo = _corTipo(item['tipo'] as String);
    final totalReceber = _itensFiltrados
        .where((i) => i['tipo'] == 'receber')
        .fold<double>(0, (soma, i) => soma + (i['valor'] as double));
    final totalPagar = _itensFiltrados
        .where((i) => i['tipo'] == 'pagar')
        .fold<double>(0, (soma, i) => soma + (i['valor'] as double));
    final saldo = totalReceber - totalPagar;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            Text(
              'Detalhe do lançamento',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item['descricao'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'R\$ ${(item['valor'] as double).toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: corTipo,
              ),
            ),
            const SizedBox(height: 18),
            _buildLinhaDetalhe('Contato', item['contato'] as String),
            _buildLinhaDetalhe('Vencimento', item['vencimento'] as String),
            _buildLinhaDetalhe('Status', item['status'] as String),
            _buildLinhaDetalhe('Origem', item['origem'] as String),
            _buildLinhaDetalhe(
                'Forma de pagamento', item['formaPagamento'] as String),
            _buildLinhaDetalhe('Empresa', item['empresa'] as String),
            _buildLinhaDetalhe('Categoria', item['categoria'] as String),
            _buildLinhaDetalhe('Responsável', item['responsavel'] as String),
            const Divider(height: 28),
            Text(
              'Ações rápidas',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: (item['acoes'] as List).map((acao) {
                return OutlinedButton(
                  onPressed: () {},
                  child: Text(acao.toString()),
                );
              }).toList(),
            ),
            const Divider(height: 28),
            Text(
              'Resumo do período',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _buildIndicadorLateral('Total a receber', totalReceber),
            _buildIndicadorLateral('Total a pagar', totalPagar),
            _buildIndicadorLateral('Saldo previsto', saldo, destaque: true),
            _buildIndicadorTexto('Alertas financeiros', '2 cobranças críticas'),
            const Divider(height: 28),
            Text(
              'Observações',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['observacoes'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const Divider(height: 28),
            Text(
              'Histórico',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...((item['historico'] as List).map(
                  (evento) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(evento.toString())),
                  ],
                ),
              ),
            )),
            const Divider(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Abrir origem'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.attach_file_outlined),
                  label: const Text('Comprovante'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaDetalhe(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorLateral(String label, double valor,
      {bool destaque = false}) {
    final color = destaque
        ? (valor >= 0 ? const Color(0xFF0F9D58) : const Color(0xFFC62828))
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorTexto(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget conteudo = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildResumoCards(context),
          const SizedBox(height: 16),
          _buildToolbarFiltros(context),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildAbas(context),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final larguraEstreita = constraints.maxWidth < 1380;

                if (larguraEstreita) {
                  return Column(
                    children: [
                      Expanded(
                        child: _buildAreaPrincipal(context),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: constraints.maxHeight * 0.50,
                        child: _buildPainelDetalheUnificado(context),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 8,
                      child: _buildAreaPrincipal(context),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 420,
                      child: _buildPainelDetalheUnificado(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return Container(
        color: theme.colorScheme.surfaceContainerLowest,
        child: SafeArea(child: conteudo),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: conteudo,
      ),
    );
  }
}

extension _FirstOrNull on List<Map<String, dynamic>> {
  Map<String, dynamic>? get firstOrNull => isEmpty ? null : first;
}
