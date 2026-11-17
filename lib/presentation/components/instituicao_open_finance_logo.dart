import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Exibe imagem da marca, mas nunca deixa uma falha HTTP/CORS virar UI quebrada.
/// O nome é usado apenas como fallback visual; não faz associação por substring.
class InstituicaoOpenFinanceLogo extends StatelessWidget {
  const InstituicaoOpenFinanceLogo({
    super.key,
    required this.url,
    this.nome,
    this.size = 48,
    this.color,
  });

  final String? url;
  final String? nome;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isNu = nome?.trim().toLowerCase() == 'nubank' ||
        nome?.trim().toLowerCase() == 'nu';
    final fallback = isNu
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF820AD1),
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: Center(
              child: Text(
                'Nu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
        : Center(
            child: Icon(
              Icons.credit_card_outlined,
              color: color ?? Theme.of(context).colorScheme.primary,
              size: size * 0.70,
            ),
          );

    final uri = url == null ? null : Uri.tryParse(url!);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return SizedBox(width: size, height: size, child: fallback);
    }

    final isSvg = uri.path.toLowerCase().endsWith('.svg');
    return SizedBox(
      width: size,
      height: size,
      child: isSvg
          ? SvgPicture.network(
              uri.toString(),
              fit: BoxFit.contain,
              placeholderBuilder: (_) => fallback,
              errorBuilder: (_, __, ___) => fallback,
            )
          : CachedNetworkImage(
              imageUrl: uri.toString(),
              fit: BoxFit.contain,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}
