import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/web_dashboard_widgets.dart';

class FornecedoresWebPage extends StatelessWidget {
  const FornecedoresWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      children: <Widget>[
        _header(context),
        const Expanded(child: _FornecedoresBody()),
      ],
    );
    final Widget closeAwareContent = onBack == null
        ? content
        : _EscCloseScope(onEscape: onBack, child: content);

    if (embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: closeAwareContent,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Fornecedores')),
      body: SafeArea(child: closeAwareContent),
    );
  }

  Widget _header(BuildContext context) {
    return SixWebDashboardHeader(
      icon: Icons.local_shipping_outlined,
      title: 'Fornecedores',
      subtitle:
          'Gestão de fornecedores, contatos comerciais, documentos e condições de compra.',
      onBack: onBack,
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Novo fornecedor'),
        ),
      ],
    );
  }
}

class _FornecedoresBody extends StatelessWidget {
  const _FornecedoresBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 900;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          children: <Widget>[
            SixWebEntry(order: 0, child: _kpis(compact)),
            const SizedBox(height: 18),
            SixWebEntry(order: 2, child: _searchSection(context)),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Fornecedores encontrados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const Chip(label: Text('0')),
              ],
            ),
            const SizedBox(height: 12),
            const _FornecedorRoadmapCard(
              icon: Icons.business_center_outlined,
              title: 'Cadastro de fornecedores',
              description:
                  'Estrutura preparada para fornecedores com documento, contatos, endereço e condições comerciais.',
              badge: 'Em evolução',
            ),
            const SizedBox(height: 12),
            const _FornecedorRoadmapCard(
              icon: Icons.assignment_outlined,
              title: 'Histórico de compras',
              description:
                  'Próximo passo: vincular entradas de estoque, notas e relacionamento de compra por fornecedor.',
              badge: 'Roadmap',
            ),
          ],
        );
      },
    );
  }

  Widget _kpis(bool compact) {
    const List<_FornecedorMetric> metrics = <_FornecedorMetric>[
      _FornecedorMetric(Icons.local_shipping_outlined, 'Fornecedores', 0),
      _FornecedorMetric(Icons.verified_outlined, 'Ativos', 0),
      _FornecedorMetric(Icons.inventory_2_outlined, 'Com itens vinculados', 0),
      _FornecedorMetric(Icons.warning_amber_rounded, 'Cadastro incompleto', 0, true),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 118,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _FornecedorMetric metric = metrics[index];
        return SixWebKpiCard(
          icon: metric.icon,
          label: metric.label,
          value: metric.value.toDouble(),
          formatter: (double value) => value.round().toString(),
          highlight: metric.highlight,
        );
      },
    );
  }

  Widget _searchSection(BuildContext context) {
    return SixWebSectionCard(
      title: 'Busca e filtros',
      subtitle: 'Encontre fornecedores por nome, documento, telefone ou e-mail.',
      icon: Icons.search_rounded,
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          hintText: 'Buscar fornecedor...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _FornecedorRoadmapCard extends StatefulWidget {
  const _FornecedorRoadmapCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;

  @override
  State<_FornecedorRoadmapCard> createState() => _FornecedorRoadmapCardState();
}

class _FornecedorRoadmapCardState extends State<_FornecedorRoadmapCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2.0 : 0.0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered
              ? theme.colorScheme.primary.withValues(alpha: 0.025)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered
                ? theme.colorScheme.primary.withValues(alpha: 0.30)
                : theme.colorScheme.outlineVariant,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: _hovered ? 0.10 : 0.05),
              blurRadius: _hovered ? 18.0 : 14.0,
              offset: Offset(0, _hovered ? 8.0 : 6.0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(widget.badge),
                        avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
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
}

class _CloseDialogIntent extends Intent {
  const _CloseDialogIntent();
}

class _EscCloseScope extends StatelessWidget {
  const _EscCloseScope({required this.child, this.onEscape});

  final Widget child;
  final VoidCallback? onEscape;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _CloseDialogIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CloseDialogIntent: CallbackAction<_CloseDialogIntent>(
            onInvoke: (_) {
              final VoidCallback? handler = onEscape;
              if (handler != null) {
                handler();
              } else {
                Navigator.of(context).maybePop();
              }
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _FornecedorMetric {
  const _FornecedorMetric(this.icon, this.label, this.value, [this.highlight = false]);

  final IconData icon;
  final String label;
  final int value;
  final bool highlight;
}
