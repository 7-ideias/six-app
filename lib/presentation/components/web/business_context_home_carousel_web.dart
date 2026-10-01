import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/perfil_negocio_model.dart';
import '../../../l10n/perfil_negocio_texts.dart';
import '../../../providers/home_banners_provider.dart';
import '../../theme/web_theme_tokens.dart';
import '../perfil_negocio_icons.dart';
import '../six_backend_loading.dart';

class BusinessContextHomeCarouselWeb extends StatelessWidget {
  const BusinessContextHomeCarouselWeb({
    super.key,
    required this.onConfigure,
  });

  final Future<void> Function() onConfigure;

  @override
  Widget build(BuildContext context) {
    final HomeBannersProvider provider = context.watch<HomeBannersProvider>();
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final HomeBannersModel? dados = provider.dados;

    if (provider.carregando && dados == null) {
      return SixBackendLoading(
        title: perfilNegocioText(context, 'loading'),
        subtitle: perfilNegocioText(context, 'description'),
        backgroundColor: tokens.surfaceElevated,
        borderColor: tokens.cardBorder,
      );
    }

    if (dados == null) {
      return _StateCard(
        icon: Icons.cloud_off_outlined,
        text: perfilNegocioText(context, provider.erro ?? 'loadError'),
        buttonText: perfilNegocioText(context, 'retry'),
        onPressed: () => provider.carregar(force: true),
      );
    }

    if (!dados.perfilNegocio.configurado) {
      if (!dados.perfilNegocio.podeEditar) return const SizedBox.shrink();
      return _StateCard(
        icon: Icons.auto_awesome_rounded,
        text: perfilNegocioText(context, 'invite'),
        buttonText: perfilNegocioText(context, 'configure'),
        onPressed: onConfigure,
      );
    }

    if (dados.banners.isEmpty) return const SizedBox.shrink();

    final double physicalWidth =
        MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                perfilNegocioText(context, 'homeTitle'),
                style: TextStyle(
                  color: tokens.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (dados.perfilNegocio.podeEditar)
              OutlinedButton.icon(
                onPressed: onConfigure,
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: Text(perfilNegocioText(context, 'edit')),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth >= 1080
                ? (constraints.maxWidth - 36) / 4
                : constraints.maxWidth >= 720
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: dados.banners.map((BannerHomeModel banner) {
                return SizedBox(
                  width: width,
                  height: 225,
                  child: _BannerCard(
                    banner: banner,
                    imageUrl: banner.imagemPara(physicalWidth),
                  ),
                );
              }).toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.imageUrl});
  final BannerHomeModel banner;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(context),
              )
            else
              _fallback(context),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  stops: const <double>[0.22, 0.55, 1],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    perfilNegocioText(
                      context,
                      'banner.${banner.tema}.title',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    perfilNegocioText(
                      context,
                      'banner.${banner.tema}.subtitle',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                      height: 1.3,
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

  Widget _fallback(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tokens.surfaceMuted,
            const Color(0xFF0B2D63),
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.72, -0.35),
        child: Icon(
          perfilNegocioIcon(banner.tema),
          size: 76,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.text,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String text;
  final String buttonText;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tokens.primaryText,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          FilledButton.tonal(
            onPressed: () => onPressed(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
