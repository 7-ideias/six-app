import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/six_i18n.dart';
import '../controllers/pdv_selecao_imagens_controller.dart';
import 'six_cached_network_image.dart';

class PdvCategorias extends StatelessWidget {
  const PdvCategorias({
    super.key,
    required this.tipo,
    required this.onChanged,
    required this.photoHeight,
    required this.spacing,
    required this.surface,
    required this.foreground,
    required this.accent,
    required this.border,
  });

  final String tipo;
  final ValueChanged<String> onChanged;
  final double photoHeight, spacing;
  final Color surface, foreground, accent, border;

  @override
  Widget build(BuildContext context) {
    final images = context.watch<PdvSelecaoImagensController?>();
    final hasPhoto =
        images?.url('PRODUTO') != null || images?.url('SERVICO') != null;
    return Row(
      children: [
        for (final category in ['PRODUTO', 'SERVICO']) ...[
          if (category == 'SERVICO') SizedBox(width: spacing),
          Expanded(
            child: PdvCategoriaButton(
              key: ValueKey('pdv-categoria-$category'),
              label: context.t(
                category == 'PRODUTO'
                    ? 'catalogHub.modules.products'
                    : 'catalogHub.modules.services',
              ),
              icon:
                  category == 'PRODUTO'
                      ? Icons.inventory_2_outlined
                      : Icons.design_services_outlined,
              selected: category == tipo,
              onTap: () => onChanged(category),
              url: images?.url(category),
              height: hasPhoto ? photoHeight : 52,
              surface: surface,
              foreground: foreground,
              accent: accent,
              border: border,
            ),
          ),
        ],
      ],
    );
  }
}

/// A legenda e a seleção continuam disponíveis durante o download ou sem arte.
class PdvCategoriaButton extends StatelessWidget {
  const PdvCategoriaButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.url,
    required this.height,
    required this.surface,
    required this.foreground,
    required this.accent,
    required this.border,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? url;
  final double height;
  final Color surface, foreground, accent, border;

  @override
  Widget build(BuildContext context) {
    final photo = url != null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected && !photo ? accent : border),
    );
    final color = photo ? Colors.white : foreground;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      child: Material(
        color: surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (photo)
              Positioned.fill(
                child: SixCachedNetworkImage(
                  key: ValueKey(url),
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  placeholder: ColoredBox(color: surface),
                  errorBuilder: (_, __, ___) => ColoredBox(color: surface),
                ),
              ),
            if (photo)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x12000000), Color(0xC9000000)],
                    ),
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Align(
                alignment: photo ? Alignment.bottomLeft : Alignment.centerLeft,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (!photo) ...[
                              Icon(
                                icon,
                                size: 18,
                                color: selected ? accent : foreground,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: 3,
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? (photo ? Colors.lightBlueAccent : accent)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: shape,
                  onTap: onTap,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
