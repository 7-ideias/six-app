import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.dark_mode),
                const SizedBox(width: 8),
                const Text("Modo escuro"),
                const Spacer(),
                Switch(
                  value: Provider
                      .of<ThemeProvider>(context)
                      .themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(
                        value);
                  },
                ),
              ],
            ),
          ), // MODO ESCURO
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
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (BuildContext context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.5,
                    // 50% da tela
                    minChildSize: 0.3,
                    maxChildSize: 0.5,
                    expand: false,
                    builder: (context, scrollController) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            const Text('Selecione o idioma', style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.language),
                              title: const Text('Português (BR)'),
                              onTap: () {
                                // TODO: mudar idioma para pt_BR
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.language),
                              title: const Text('English (US)'),
                              onTap: () {
                                // TODO: mudar idioma para en_US
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },

          ),
          const Divider(height: 0),
          ListTile(
            title: const Text('Exportar clientes'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: implementar exportação de clientes
            },
          ),// EXPORTAR CLIENTES

        ],
      ),
    );
  }
}
