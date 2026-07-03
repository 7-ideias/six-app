import 'package:flutter/material.dart';

import '../../l10n/six_i18n.dart';
import 'empresa_configuracao_screen.dart';
import 'regionalizacao_configuracao_content.dart';

class ConfiguracoesMobileScreen extends StatelessWidget {
  const ConfiguracoesMobileScreen({super.key});

  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);

  static const Color backgroundColor = _backgroundColor;
  static const Color primaryColor = _primaryColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _ConfigTile(
              icon: Icons.storefront_outlined,
              title: 'Empresa',
              subtitle: 'Dados do comércio e identidade',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _EmpresaMobilePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ConfigTile(
              icon: Icons.language_outlined,
              title: 'Regionalização',
              subtitle: 'Idioma, moeda e formato local',
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
}

class _EmpresaMobilePage extends StatelessWidget {
  const _EmpresaMobilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConfiguracoesMobileScreen.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: ConfiguracoesMobileScreen.primaryColor,
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: const Text(
          'Empresa',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      body: const SafeArea(
        child: EmpresaConfiguracaoForm(embedded: false),
      ),
    );
  }
}

class RegionalizacaoMobileScreen extends StatelessWidget {
  const RegionalizacaoMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConfiguracoesMobileScreen.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: ConfiguracoesMobileScreen.primaryColor,
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: Text(
          context.t('regionalizacao.regionalizacao'),
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      body: const SafeArea(
        child: RegionalizacaoConfiguracaoContent(),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: ConfiguracoesMobileScreen.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }
}
