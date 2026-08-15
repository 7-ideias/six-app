import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Spike visual isolado do Lote 0 de Etiquetas.
///
/// Não participa da navegação principal, não persiste dados e não conversa com
/// o backend. O objetivo é provar a conversão mm -> px e a experiência mínima
/// de seleção, movimento e redimensionamento no Flutter Web.
class EtiquetaEditorWebSpike extends StatefulWidget {
  const EtiquetaEditorWebSpike({super.key});

  @override
  State<EtiquetaEditorWebSpike> createState() =>
      _EtiquetaEditorWebSpikeState();
}

class _EtiquetaEditorWebSpikeState extends State<EtiquetaEditorWebSpike> {
  static const double _labelWidthMm = 50;
  static const double _labelHeightMm = 30;

  List<_SpikeElement> _elements = _initialElements();
  String _selectedElementId = 'product-name';

  _SpikeElement get _selectedElement => _elements.firstWhere(
    (_SpikeElement element) => element.id == _selectedElementId,
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiquetas · Lote 0 · Editor Web Spike'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '50 × 30 mm',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 980;
          final Widget leftPanel = _buildElementPanel(context);
          final Widget canvas = _buildCanvasCard(context);
          final Widget properties = _buildPropertiesPanel(context);

          if (compact) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  leftPanel,
                  const SizedBox(height: 16),
                  SizedBox(height: 460, child: canvas),
                  const SizedBox(height: 16),
                  properties,
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(width: 250, child: leftPanel),
                const SizedBox(width: 16),
                Expanded(child: canvas),
                const SizedBox(width: 16),
                SizedBox(width: 280, child: properties),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildElementPanel(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Elementos de prova',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecione um elemento, arraste dentro da etiqueta e use o canto inferior direito para redimensionar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final _SpikeElement element in _elements) ...<Widget>[
              _ElementSelector(
                element: element,
                selected: element.id == _selectedElementId,
                onTap: () => setState(() => _selectedElementId = element.id),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Resetar geometria'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                'Este entrypoint é descartável/controlado: sem persistência, sem API e sem alteração da Sidebar do SixApp.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Canvas proporcional',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'A geometria continua em milímetros; pixels existem apenas no render.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.straighten_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double availableWidth = math
                      .max(120.0, constraints.maxWidth - 48.0)
                      .toDouble();
                  final double availableHeight = math
                      .max(100.0, constraints.maxHeight - 48.0)
                      .toDouble();
                  final double scale = math
                      .max(
                        1.0,
                        math.min(
                          availableWidth / _labelWidthMm,
                          availableHeight / _labelHeightMm,
                        ),
                      )
                      .toDouble();

                  return Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '1 mm = ${scale.toStringAsFixed(2)} px neste preview',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: _labelWidthMm * scale,
                              height: _labelHeightMm * scale,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.outline,
                                  width: 1.2,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: colors.shadow.withValues(alpha: 0.10),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  for (final _SpikeElement element in _elements)
                                    _SpikeElementWidget(
                                      key: ValueKey<String>(element.id),
                                      element: element,
                                      scale: scale,
                                      selected:
                                          element.id == _selectedElementId,
                                      onSelected: () => setState(
                                        () => _selectedElementId = element.id,
                                      ),
                                      onMove: (Offset deltaPx) {
                                        _moveElement(
                                          element.id,
                                          dxMm: deltaPx.dx / scale,
                                          dyMm: deltaPx.dy / scale,
                                        );
                                      },
                                      onResize: (Offset deltaPx) {
                                        _resizeElement(
                                          element.id,
                                          dwMm: deltaPx.dx / scale,
                                          dhMm: deltaPx.dy / scale,
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final _SpikeElement selected = _selectedElement;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Geometria em mm',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selected.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _GeometryRow(label: 'X', value: selected.xMm),
            _GeometryRow(label: 'Y', value: selected.yMm),
            _GeometryRow(label: 'Largura', value: selected.widthMm),
            _GeometryRow(label: 'Altura', value: selected.heightMm),
            const SizedBox(height: 14),
            Divider(color: colors.outlineVariant),
            const SizedBox(height: 10),
            _InfoLine(label: 'Etiqueta', value: '50 × 30 mm'),
            _InfoLine(label: 'Origem', value: 'canto superior esquerdo'),
            _InfoLine(label: 'Persistência', value: 'nenhuma'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Critério do spike: o elemento nunca pode sair dos limites de 0–50 mm × 0–30 mm, independentemente da escala em pixels.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveElement(
    String id, {
    required double dxMm,
    required double dyMm,
  }) {
    setState(() {
      _elements = <_SpikeElement>[
        for (final _SpikeElement element in _elements)
          if (element.id != id)
            element
          else
            element.copyWith(
              xMm: _clamp(
                element.xMm + dxMm,
                0,
                _labelWidthMm - element.widthMm,
              ),
              yMm: _clamp(
                element.yMm + dyMm,
                0,
                _labelHeightMm - element.heightMm,
              ),
            ),
      ];
    });
  }

  void _resizeElement(
    String id, {
    required double dwMm,
    required double dhMm,
  }) {
    setState(() {
      _elements = <_SpikeElement>[
        for (final _SpikeElement element in _elements)
          if (element.id != id)
            element
          else
            element.copyWith(
              widthMm: _clamp(
                element.widthMm + dwMm,
                element.minWidthMm,
                _labelWidthMm - element.xMm,
              ),
              heightMm: _clamp(
                element.heightMm + dhMm,
                element.minHeightMm,
                _labelHeightMm - element.yMm,
              ),
            ),
      ];
    });
  }

  void _reset() {
    setState(() {
      _elements = _initialElements();
      _selectedElementId = 'product-name';
    });
  }

  static double _clamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}

class _ElementSelector extends StatelessWidget {
  const _ElementSelector({
    required this.element,
    required this.selected,
    required this.onTap,
  });

  final _SpikeElement element;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.55)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(element.icon, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                element.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpikeElementWidget extends StatelessWidget {
  const _SpikeElementWidget({
    super.key,
    required this.element,
    required this.scale,
    required this.selected,
    required this.onSelected,
    required this.onMove,
    required this.onResize,
  });

  final _SpikeElement element;
  final double scale;
  final bool selected;
  final VoidCallback onSelected;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Positioned(
      left: element.xMm * scale,
      top: element.yMm * scale,
      width: element.widthMm * scale,
      height: element.heightMm * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSelected,
                onPanStart: (_) => onSelected(),
                onPanUpdate: (DragUpdateDetails details) =>
                    onMove(details.delta),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primaryContainer.withValues(alpha: 0.38)
                        : colors.surfaceContainerHighest.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: selected ? colors.primary : colors.outlineVariant,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _ElementPreview(element: element),
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              right: -6,
              bottom: -6,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (DragUpdateDetails details) =>
                      onResize(details.delta),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: colors.onPrimary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ElementPreview extends StatelessWidget {
  const _ElementPreview({required this.element});

  final _SpikeElement element;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    switch (element.kind) {
      case _SpikeElementKind.text:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Fone Bluetooth XYZ',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      case _SpikeElementKind.price:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '123,45',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      case _SpikeElementKind.barcode:
        return Padding(
          padding: const EdgeInsets.all(4),
          child: CustomPaint(
            painter: _BarcodePlaceholderPainter(color: colors.onSurface),
            child: const SizedBox.expand(),
          ),
        );
    }
  }
}

class _BarcodePlaceholderPainter extends CustomPainter {
  const _BarcodePlaceholderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double unit = math.max(1.0, size.width / 95.0).toDouble();
    double x = 0;
    int index = 0;

    while (x < size.width) {
      final double barWidth = unit * (index % 4 == 0 ? 3 : 1);
      final double heightFactor = index % 5 == 0 ? 0.82 : 1.0;
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          size.height * (1 - heightFactor),
          math.min(barWidth, size.width - x).toDouble(),
          size.height * heightFactor,
        ),
        paint,
      );
      x += barWidth + unit;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePlaceholderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GeometryRow extends StatelessWidget {
  const _GeometryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(
              '${value.toStringAsFixed(1)} mm',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SpikeElementKind { text, price, barcode }

class _SpikeElement {
  const _SpikeElement({
    required this.id,
    required this.title,
    required this.icon,
    required this.kind,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
    required this.minWidthMm,
    required this.minHeightMm,
  });

  final String id;
  final String title;
  final IconData icon;
  final _SpikeElementKind kind;
  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;
  final double minWidthMm;
  final double minHeightMm;

  _SpikeElement copyWith({
    double? xMm,
    double? yMm,
    double? widthMm,
    double? heightMm,
  }) {
    return _SpikeElement(
      id: id,
      title: title,
      icon: icon,
      kind: kind,
      xMm: xMm ?? this.xMm,
      yMm: yMm ?? this.yMm,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      minWidthMm: minWidthMm,
      minHeightMm: minHeightMm,
    );
  }
}

List<_SpikeElement> _initialElements() {
  return const <_SpikeElement>[
    _SpikeElement(
      id: 'product-name',
      title: 'Texto · nome do produto',
      icon: Icons.title_rounded,
      kind: _SpikeElementKind.text,
      xMm: 3,
      yMm: 3,
      widthMm: 44,
      heightMm: 6,
      minWidthMm: 12,
      minHeightMm: 4,
    ),
    _SpikeElement(
      id: 'price',
      title: 'Preço · preview',
      icon: Icons.payments_outlined,
      kind: _SpikeElementKind.price,
      xMm: 3,
      yMm: 10,
      widthMm: 22,
      heightMm: 6,
      minWidthMm: 10,
      minHeightMm: 4,
    ),
    _SpikeElement(
      id: 'barcode',
      title: 'Barcode · placeholder',
      icon: Icons.qr_code_2_rounded,
      kind: _SpikeElementKind.barcode,
      xMm: 3,
      yMm: 18,
      widthMm: 44,
      heightMm: 8,
      minWidthMm: 16,
      minHeightMm: 5,
    ),
  ];
}
