import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/pdv_mobile_screen.dart';
import 'package:sixpos/presentation/screens/vendas_nao_liquidadas_mobile_screen.dart';

import '../components/custom_nav_bar.dart';

class OperacaoMobileScreen extends StatefulWidget {
  const OperacaoMobileScreen({super.key});

  @override
  State<OperacaoMobileScreen> createState() => _OperacaoMobileScreenState();
}

class _OperacaoMobileScreenState extends State<OperacaoMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Atendimento', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
      ),
      body: _buildContent(context),
      bottomNavigationBar: kIsWeb ? null : const CustomBottomNavBar(initialIndex: 2),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          SixStaggeredEntry(delay: const Duration(milliseconds: 70), child: _buildQuickServiceHeader()),
          const SizedBox(height: 18),
          SixStaggeredEntry(delay: const Duration(milliseconds: 120), child: _buildSectionTitle('Atendimento rápido')),
          const SizedBox(height: 12),
          SixStaggeredEntry(delay: const Duration(milliseconds: 170), child: _buildQuickActions(context)),
          const SizedBox(height: 24),
          SixStaggeredEntry(delay: const Duration(milliseconds: 230), child: _buildSectionTitle('Acompanhamento')),
          const SizedBox(height: 12),
          ..._buildTrackingTiles(context),
          const SizedBox(height: 12),
          SixStaggeredEntry(delay: const Duration(milliseconds: 420), child: _buildSectionTitle('Caixa')),
          const SizedBox(height: 12),
          SixStaggeredEntry(delay: const Duration(milliseconds: 470), child: _buildCashTile(context)),
        ],
      ),
    );
  }

  Widget _buildQuickServiceHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [_primaryColor, _secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x260B1F3A), blurRadius: 22, offset: Offset(0, 12))],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x33FFFFFF))),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Balcão digital', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Venda, orçamento e assistência técnica em poucos passos.', style: TextStyle(color: Color(0xFFD7E3F5), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildPrimaryActionCard(
          title: 'Nova venda',
          subtitle: 'Abrir atendimento no caixa',
          icon: Icons.point_of_sale_rounded,
          onTap: () => _navigateTo(context, const PdvMobileScreen()),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                SizedBox(width: width, child: _buildSecondaryActionCard(title: 'Novo orçamento', icon: Icons.request_quote_rounded, onTap: _showFeatureInProgress)),
                SizedBox(width: width, child: _buildSecondaryActionCard(title: 'Nova assistência', icon: Icons.handyman_rounded, onTap: _showFeatureInProgress)),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildTrackingTiles(BuildContext context) {
    final List<_TrackingItem> items = <_TrackingItem>[
      _TrackingItem(
        title: 'Vendas a receber',
        subtitle: 'Vendas não liquidadas',
        count: '0',
        icon: Icons.point_of_sale_outlined,
        onTap: () => _navigateTo(context, const VendasNaoLiquidadasMobileScreen()),
      ),
      _TrackingItem(title: 'Orçamentos pendentes', subtitle: 'Aguardando retorno do cliente', count: '9', icon: Icons.description_outlined, onTap: _showFeatureInProgress),
      _TrackingItem(title: 'Assistências em revisão', subtitle: 'Aguardando análise técnica', count: '9', icon: Icons.fact_check_outlined, onTap: _showFeatureInProgress),
      _TrackingItem(title: 'Assistências em execução', subtitle: 'Serviços técnicos em andamento', count: '27', icon: Icons.build_circle_outlined, onTap: _showFeatureInProgress),
    ];

    return items.asMap().entries.map((entry) {
      final int delay = 280 + (entry.key * 45);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SixStaggeredEntry(delay: Duration(milliseconds: delay), child: _buildTrackingTile(entry.value)),
      );
    }).toList(growable: false);
  }

  Widget _buildPrimaryActionCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: Row(
            children: <Widget>[
              _iconBox(icon, background: const Color(0xFFEFF6FF), color: _accentColor, size: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _iconBox(icon, background: const Color(0xFFEFF6FF), color: _accentColor, size: 42),
              const SizedBox(height: 14),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w800, height: 1.15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingTile(_TrackingItem item) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: Row(
            children: <Widget>[
              _iconBox(item.icon, background: const Color(0xFFF1F5F9), color: _primaryColor, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _titleTextColor, fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SixAnimatedNumberText(value: item.count, style: const TextStyle(color: _titleTextColor, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashTile(BuildContext context) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateTo(context, const VendasNaoLiquidadasMobileScreen()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: <Widget>[
              _iconBox(Icons.point_of_sale_outlined, background: const Color(0xFFEFF6FF), color: _accentColor, size: 46),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Caixa a receber', style: TextStyle(color: _titleTextColor, fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Liquidar vendas deixadas para depois', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _mutedTextColor, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, {required Color background, required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size >= 48 ? 18 : 14)),
      child: Icon(icon, color: color, size: size >= 48 ? 24 : 22),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: _titleTextColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.1));
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => page));
  }

  void _showFeatureInProgress() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fluxo mobile em evolução.'), behavior: SnackBarBehavior.floating));
  }
}

class _TrackingItem {
  const _TrackingItem({required this.title, required this.subtitle, required this.count, required this.icon, required this.onTap});

  final String title;
  final String subtitle;
  final String count;
  final IconData icon;
  final VoidCallback onTap;
}
