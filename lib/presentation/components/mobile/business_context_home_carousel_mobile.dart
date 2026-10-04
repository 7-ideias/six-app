import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/perfil_negocio_model.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/perfil_negocio_texts.dart';
import '../../../providers/home_banners_provider.dart';
import '../perfil_negocio_icons.dart';
import '../six_cached_network_image.dart';
import '../six_backend_loading.dart';

class BusinessContextHomeCarouselMobile extends StatelessWidget {
  const BusinessContextHomeCarouselMobile({
    super.key,
    required this.onConfigure,
  });

  final Future<void> Function() onConfigure;

  @override
  Widget build(BuildContext context) {
    final HomeBannersProvider provider = context.watch<HomeBannersProvider>();
    final SixMobileColorScheme colors = context.sixMobileColors;
    final HomeBannersModel? dados = provider.dados;

    if (provider.carregando && dados == null) {
      return SixBackendLoading(
        title: perfilNegocioText(context, 'loading'),
        subtitle: perfilNegocioText(context, 'description'),
        compact: true,
        backgroundColor: colors.surface,
        borderColor: colors.border,
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
                  color: colors.titleText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (dados.perfilNegocio.podeEditar)
              TextButton.icon(
                onPressed: onConfigure,
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: Text(perfilNegocioText(context, 'edit')),
                style: TextButton.styleFrom(
                  foregroundColor: colors.accent,
                  backgroundColor: colors.softAccentSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.border),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 8),
            itemCount: dados.banners.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final BannerHomeModel banner = dados.banners[index];
              return SizedBox(
                width: MediaQuery.sizeOf(context).width.clamp(280, 338).toDouble(),
                child: _BannerCard(
                  banner: banner,
                  imageUrl: banner.imagemPara(physicalWidth),
                ),
              );
            },
          ),
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          border: Border.all(color: colors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (imageUrl != null)
              SixCachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: _fallback(context),
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
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const <double>[0.25, 0.55, 1],
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
                      fontWeight: FontWeight.w600,
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.primary,
            colors.secondary,
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.72, -0.35),
        child: Icon(
          perfilNegocioIcon(banner.tema),
          size: 72,
          color: colors.onPrimary.withValues(alpha: 0.22),
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.softAccentSurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: colors.accent, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text,
                  style: TextStyle(
                    color: colors.titleText,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => onPressed(),
                  child: Text(buttonText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
