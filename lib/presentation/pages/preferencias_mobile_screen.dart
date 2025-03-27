import 'package:appplanilha/presentation/pages/preferencias_sub_pedidos_catalogos_mobile_screen.dart';
import 'package:flutter/material.dart';

class PreferencesMobileScreen extends StatefulWidget {
  const PreferencesMobileScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesMobileScreen> createState() =>
      _PreferencesMobileScreenState();
}

class _PreferencesMobileScreenState extends State<PreferencesMobileScreen> {
  List<_PreferenceItem> _buildItems(BuildContext context) {
    return [
      _PreferenceItem(
        icon: Icons.library_books_outlined,
        title: 'Pedidos & Catálogos',
        subtitle: 'Escolha campos, unidades e muito mais',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonalizarPedidosCatalogosScreen(),
            ),
          );
        },
      ),
      _PreferenceItem(
        icon: Icons.calendar_today_outlined,
        title: 'Agenda',
        subtitle: 'Configure seus compromissos',
        onTap: () {},
      ),
      _PreferenceItem(
        icon: Icons.payments_outlined,
        title: 'Pagamentos',
        subtitle: 'Escolha métodos e condições de pagamento',
        onTap: () {},
      ),
      _PreferenceItem(
        icon: Icons.attach_money_outlined,
        title: 'Financeiro',
        subtitle: 'Escolha moeda e categorias de custos',
        onTap: () {},
      ),
      _PreferenceItem(
        icon: Icons.description_outlined,
        title: 'Documentos',
        subtitle: 'Escolha modelo, cor, tipo e mais',
        onTap: () {},
      ),
      _PreferenceItem(
        icon: Icons.article_outlined,
        title: 'Textos padronizados',
        subtitle: 'Crie textos padronizados para os pedidos',
        onTap: () {},
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferências'),
        leading: const BackButton(),
      ),
      body: ListView.separated(
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Icon(item.icon, color: Colors.deepPurple),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: item.onTap,
          );
        },
      ),
    );
  }
}

class _PreferenceItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _PreferenceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
