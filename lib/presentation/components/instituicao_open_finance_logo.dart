import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Nunca deixa falhas, imagens ausentes ou URLs não reconhecidas quebrarem a tela.
class InstituicaoOpenFinanceLogo extends StatelessWidget {
  const InstituicaoOpenFinanceLogo({
    super.key,
    required this.url,
    this.size = 48,
    this.color,
  });

  final String? url;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.credit_card_outlined,
      color: color ?? Theme.of(context).colorScheme.primary,
      size: size * 0.70,
    );
    final uri = url == null ? null : Uri.tryParse(url!);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return SizedBox(width: size, height: size, child: Center(child: fallback));
    }

    final isSvg = uri.path.toLowerCase().endsWith('.svg');
    return SizedBox(
      width: size,
      height: size,
      child: isSvg
          ? SvgPicture.network(
              uri.toString(),
              fit: BoxFit.contain,
              placeholderBuilder: (_) => Center(child: fallback),
              errorBuilder: (_, __, ___) => Center(child: fallback),
            )
          : CachedNetworkImage(
              imageUrl: uri.toString(),
              fit: BoxFit.contain,
              placeholder: (_, __) => Center(child: fallback),
              errorWidget: (_, __, ___) => Center(child: fallback),
            ),
    );
  }
}
