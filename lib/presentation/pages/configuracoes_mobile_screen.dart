import 'package:flutter/material.dart';

class ConfiguracoesMobileScreen extends StatelessWidget {
  const ConfiguracoesMobileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: const BackButton(),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text(
              'Idioma',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Portuguese (BR)'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              // TODO: implementar seleção de idioma
            },
          ),
          const Divider(height: 0),
          ListTile(
            title: const Text('Exportar clientes'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: implementar exportação de clientes
            },
          ),
        ],
      ),
    );
  }
}
