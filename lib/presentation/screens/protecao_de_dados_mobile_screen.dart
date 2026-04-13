import 'package:appplanilha/presentation/screens/certeza_mobile_screen.dart';
import 'package:flutter/material.dart';

class ProtecaoDeDadosScreen extends StatelessWidget {
  const ProtecaoDeDadosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proteção de dados'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Estas são medidas extremas e irreversíveis.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          _buildOption(
            context,
            title: 'Exportar dados',
            subtitle: 'Você receberá tudo que salvou',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CertezaMobileScreen()),
              );
            },
          ),
          _buildOption(
            context,
            title: 'Revogar consentimento',
            subtitle: 'Excluir seus dados pessoais',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CertezaMobileScreen()),
              );
            },
          ),
          _buildOption(
            context,
            title: 'Excluir todos os dados dos clientes',
            subtitle: 'Todos os seus clientes serão excluídos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CertezaMobileScreen()),
              );
            },
          ),
          _buildOption(
            context,
            title: 'Deletar conta',
            subtitle: 'Tudo será apagado',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CertezaMobileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(height: 0),
      ],
    );
  }
}
