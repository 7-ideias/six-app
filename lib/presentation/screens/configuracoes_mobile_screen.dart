import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

import 'empresa_configuracao_mobile.dart';
import 'regionalizacao_mobile_screen.dart';

class ConfiguracoesMobileScreen extends StatelessWidget {
  const ConfiguracoesMobileScreen({super.key});

  static const Color backgroundColor = SixMobilePalette.background;
  static const Color primaryColor = SixMobilePalette.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SixMobilePalette.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: SixMobilePalette.primary,
        foregroundColor: SixMobilePalette.onPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: const BackButton(),
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildSectionLabel('Empresa'),
            const SizedBox(height: 8),
            _ConfigTile(
              icon: Icons.storefront_outlined,
              title: 'Empresa',
              subtitle: 'Dados cadastrais e identidade do comércio',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EmpresaConfiguracaoMobile(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ConfigTile(
              icon: Icons.language_outlined,
              title: 'Regionalização',
              subtitle: 'Idioma, moeda, país e formatos locais',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RegionalizacaoMobileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: SixMobilePalette.mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  const _ConfigTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: SixMobilePalette.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          hoverColor: SixMobilePalette.accent.withValues(alpha: 0.06),
          focusColor: SixMobilePalette.accent.withValues(alpha: 0.08),
          splashColor: SixMobilePalette.accent.withValues(alpha: 0.08),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: SixMobilePalette.onPrimary.withValues(alpha: 0.62),
                width: 0.8,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: SixMobilePalette.navigationShadow.withValues(
                    alpha: 0.45,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SixMobilePalette.softAccentSurface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: SixMobilePalette.highlightedBorder.withValues(
                        alpha: 0.42,
                      ),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(icon, color: SixMobilePalette.accent, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.titleText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SixMobilePalette.mutedText,
                          fontSize: 12,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SixMobilePalette.mutedText.withValues(alpha: 0.82),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
