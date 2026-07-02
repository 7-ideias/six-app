import 'package:flutter/material.dart';

class GestorCockpitWebPage extends StatelessWidget {
  final VoidCallback? onBack;

  const GestorCockpitWebPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    const List<String> tabs = <String>[
      'Vendas e assistências',
      'Clientes',
      'Vendedores',
      'Produtos',
      'Estoque',
      'Satisfação',
    ];

    return DefaultTabController(
      length: tabs.length,
      child: ColoredBox(
        color: colors.surface,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: <Widget>[
                  Icon(Icons.space_dashboard_rounded, color: colors.primary, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Cockpit do gestor', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Central executiva web com filtros de período, produto, cliente e vendedor.', style: TextStyle(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (onBack != null) OutlinedButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Voltar')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const <Widget>[
                  _FilterChip(label: 'Período'),
                  _FilterChip(label: 'Produto'),
                  _FilterChip(label: 'Cliente'),
                  _FilterChip(label: 'Vendedor'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              isScrollable: true,
              tabs: tabs.map((String label) => Tab(text: label)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: tabs.map((String title) => _DashboardTab(title: title)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), avatar: const Icon(Icons.tune_rounded, size: 16));
  }
}

class _DashboardTab extends StatelessWidget {
  final String title;

  const _DashboardTab({required this.title});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: <Widget>[
              _KpiCard(title: 'Indicador principal', value: '0', icon: Icons.trending_up_rounded),
              _KpiCard(title: 'Volume do período', value: '0', icon: Icons.bar_chart_rounded),
              _KpiCard(title: 'Pendências', value: '0', icon: Icons.pending_actions_rounded),
              _KpiCard(title: 'Atenções', value: '0', icon: Icons.warning_amber_rounded),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: colors.outlineVariant)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 14),
                for (final double value in <double>[0.92, 0.76, 0.58, 0.41]) ...<Widget>[
                  LinearProgressIndicator(value: value, minHeight: 12),
                  const SizedBox(height: 12),
                ],
                Text('Dados demonstrativos para validar a experiência do cockpit gestor.', style: TextStyle(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KpiCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 250,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: colors.outlineVariant)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Icon(icon, color: colors.primary),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        ]),
      ),
    );
  }
}
