import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/catalogo_publico_configuracao_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

/// Prévia própria da jornada mobile do catálogo virtual.
///
/// O componente representa a página pública, mas não reutiliza nem embrulha a
/// tela de personalização Web.
class CatalogoVirtualMobilePreview extends StatelessWidget {
  const CatalogoVirtualMobilePreview({
    super.key,
    required this.configuration,
    this.compact = false,
  });

  final CatalogoPublicoConfiguracaoModel configuration;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final CatalogoPublicoPersonalizacaoModel personalization =
        configuration.personalizacao;
    final Color accent = _parseColor(personalization.corPrincipal);
    final Color background = switch (personalization.estilo) {
      CatalogoPublicoEstilo.classico => const Color(0xFFF4F7FA),
      CatalogoPublicoEstilo.minimalista => Colors.white,
      CatalogoPublicoEstilo.expressivo => _mix(accent, Colors.white, 0.93),
    };
    final Color ink = switch (personalization.estilo) {
      CatalogoPublicoEstilo.expressivo => _mix(
        accent,
        const Color(0xFF06152E),
        0.22,
      ),
      _ => const Color(0xFF10253E),
    };
    final String companyName = configuration.empresa.nome.isEmpty
        ? context.t(
            'catalog.publicPage.preview.storeFallback',
            fallback: 'Seu comércio',
          )
        : configuration.empresa.nome;
    final String title = personalization.titulo.trim().isEmpty
        ? companyName
        : personalization.titulo.trim();
    final double contentPadding = compact ? 11 : 14;

    return ColoredBox(
      color: background,
      child: Column(
        children: <Widget>[
          _CatalogPreviewHeader(
            companyName: companyName,
            logoBase64: configuration.empresa.logoBase64,
            personalization: personalization,
            accent: accent,
            ink: ink,
            compact: compact,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _CatalogPreviewHero(
                    configuration: configuration,
                    title: title,
                    companyName: companyName,
                    accent: accent,
                    ink: ink,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 11 : 16),
                  Text(
                    context.t(
                      'catalog.publicPage.preview.products',
                      fallback: 'Produtos disponíveis',
                    ),
                    style: TextStyle(
                      color: accent,
                      fontSize: compact ? 8 : 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.65,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.t(
                      'catalog.publicPage.preview.chooseItems',
                      fallback: 'Escolha seus itens',
                    ),
                    style: TextStyle(
                      color: ink,
                      fontSize: compact ? 14 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: compact ? 9 : 12),
                  _CatalogPreviewProducts(
                    configuration: configuration,
                    accent: accent,
                    ink: ink,
                    compact: compact,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogPreviewHeader extends StatelessWidget {
  const _CatalogPreviewHeader({
    required this.companyName,
    required this.logoBase64,
    required this.personalization,
    required this.accent,
    required this.ink,
    required this.compact,
  });

  final String companyName;
  final String logoBase64;
  final CatalogoPublicoPersonalizacaoModel personalization;
  final Color accent;
  final Color ink;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool expressive =
        personalization.estilo == CatalogoPublicoEstilo.expressivo;
    final Color foreground = expressive ? Colors.white : ink;

    return Container(
      height: compact ? 45 : 52,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
      decoration: BoxDecoration(
        color: expressive
            ? _mix(accent, const Color(0xFF00163A), 0.28)
            : Colors.white.withValues(alpha: 0.97),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: <Widget>[
          _CatalogPreviewLogo(
            raw: logoBase64,
            accent: accent,
            size: compact ? 27 : 31,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: expressive
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: expressive ? Colors.white24 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              'PT · EN · ES',
              style: TextStyle(
                color: expressive ? Colors.white : const Color(0xFF64748B),
                fontSize: compact ? 6.5 : 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogPreviewHero extends StatelessWidget {
  const _CatalogPreviewHero({
    required this.configuration,
    required this.title,
    required this.companyName,
    required this.accent,
    required this.ink,
    required this.compact,
  });

  final CatalogoPublicoConfiguracaoModel configuration;
  final String title;
  final String companyName;
  final Color accent;
  final Color ink;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final CatalogoPublicoPersonalizacaoModel personalization =
        configuration.personalizacao;
    final bool expressive =
        personalization.estilo == CatalogoPublicoEstilo.expressivo;
    final Color foreground = expressive ? Colors.white : ink;
    final String contact = configuration.empresa.whatsapp.isNotEmpty
        ? 'WhatsApp'
        : configuration.empresa.telefone.isNotEmpty
        ? configuration.empresa.telefone
        : configuration.empresa.email;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 15),
      decoration: BoxDecoration(
        gradient: switch (personalization.estilo) {
          CatalogoPublicoEstilo.classico => LinearGradient(
            colors: <Color>[Colors.white, _mix(accent, Colors.white, 0.91)],
          ),
          CatalogoPublicoEstilo.minimalista => null,
          CatalogoPublicoEstilo.expressivo => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              _mix(accent, const Color(0xFF00163A), 0.20),
              accent,
            ],
          ),
        },
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(
          color: expressive ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _CatalogPreviewLogo(
                raw: configuration.empresa.logoBase64,
                accent: accent,
                size: compact ? 36 : 44,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.78),
                    fontSize: compact ? 8 : 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: compact ? 16 : 21,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (personalization.descricao.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              personalization.descricao.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.72),
                fontSize: compact ? 8 : 10,
                height: 1.3,
              ),
            ),
          ],
          if (personalization.exibirEndereco &&
              configuration.empresa.endereco.isNotEmpty) ...<Widget>[
            const SizedBox(height: 7),
            Row(
              children: <Widget>[
                Icon(
                  Icons.location_on_outlined,
                  color: foreground.withValues(alpha: 0.75),
                  size: compact ? 11 : 13,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    configuration.empresa.endereco,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.72),
                      fontSize: compact ? 7 : 9,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (personalization.exibirContato && contact.isNotEmpty) ...<Widget>[
            const SizedBox(height: 9),
            Container(
              constraints: const BoxConstraints(maxWidth: 180),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: expressive
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: expressive ? Colors.white24 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: compact ? 10 : 12,
                    color: expressive ? Colors.white : accent,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: expressive ? Colors.white : accent,
                        fontSize: compact ? 7 : 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogPreviewProducts extends StatelessWidget {
  const _CatalogPreviewProducts({
    required this.configuration,
    required this.accent,
    required this.ink,
    required this.compact,
  });

  final CatalogoPublicoConfiguracaoModel configuration;
  final Color accent;
  final Color ink;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final List<CatalogoPublicoProdutoPreviewModel> products = configuration
        .produtos
        .take(compact ? 2 : 4)
        .toList(growable: false);

    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 18 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.inventory_2_outlined,
              color: accent,
              size: compact ? 22 : 28,
            ),
            const SizedBox(height: 8),
            Text(
              context.t(
                'catalog.publicPage.preview.empty',
                fallback: 'Marque produtos como disponíveis para o catálogo.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (int index = 0; index < products.length; index += 1) ...<Widget>[
          _CatalogPreviewProductCard(
            product: products[index],
            personalization: configuration.personalizacao,
            accent: accent,
            ink: ink,
            compact: compact,
          ),
          if (index < products.length - 1) SizedBox(height: compact ? 7 : 9),
        ],
      ],
    );
  }
}

class _CatalogPreviewProductCard extends StatelessWidget {
  const _CatalogPreviewProductCard({
    required this.product,
    required this.personalization,
    required this.accent,
    required this.ink,
    required this.compact,
  });

  final CatalogoPublicoProdutoPreviewModel product;
  final CatalogoPublicoPersonalizacaoModel personalization;
  final Color accent;
  final Color ink;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool dense =
        personalization.densidade == CatalogoPublicoDensidade.compacta;
    final String formattedPrice = context
        .read<LocaleSettingsProvider>()
        .formatCurrency(product.preco);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact || dense ? 12 : 15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: compact ? 70 : 86,
            height: compact ? 74 : 92,
            child: _CatalogPreviewProductImage(
              product: product,
              accent: accent,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(compact || dense ? 8 : 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (product.modelo.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      product.modelo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: compact ? 7 : 8,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      if (personalization.exibirPrecos)
                        Expanded(
                          child: Text(
                            formattedPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: compact ? 9 : 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      Container(
                        width: compact ? 22 : 25,
                        height: compact ? 22 : 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: compact ? 13 : 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogPreviewProductImage extends StatelessWidget {
  const _CatalogPreviewProductImage({
    required this.product,
    required this.accent,
  });

  final CatalogoPublicoProdutoPreviewModel product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (product.imagemBase64.isNotEmpty) {
      try {
        final String payload = product.imagemBase64.contains(',')
            ? product.imagemBase64.split(',').last
            : product.imagemBase64;
        return Image.memory(
          base64Decode(payload),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    if (product.imagemUrl.isNotEmpty) {
      return Image.network(
        product.imagemUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return ColoredBox(
      color: _mix(accent, Colors.white, 0.91),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: accent.withValues(alpha: 0.58),
        ),
      ),
    );
  }
}

class _CatalogPreviewLogo extends StatelessWidget {
  const _CatalogPreviewLogo({
    required this.raw,
    required this.accent,
    required this.size,
  });

  final String raw;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Icon(
      Icons.storefront_rounded,
      color: accent,
      size: size * 0.5,
    );
    Widget child = fallback;

    if (raw.isNotEmpty) {
      try {
        final String payload = raw.contains(',') ? raw.split(',').last : raw;
        final Uint8List bytes = base64Decode(payload);
        child = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        // A prévia mantém um ícone neutro se a logo cadastrada for inválida.
      }
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _mix(accent, Colors.white, 0.90),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: child,
    );
  }
}

Color _parseColor(String value) {
  final RegExpMatch? match = RegExp(
    r'^#([0-9A-Fa-f]{6})$',
  ).firstMatch(value.trim());
  if (match == null) return const Color(0xFF126BFF);
  return Color(int.parse('FF${match.group(1)}', radix: 16));
}

Color _mix(Color foreground, Color background, double backgroundWeight) {
  return Color.lerp(foreground, background, backgroundWeight)!;
}
