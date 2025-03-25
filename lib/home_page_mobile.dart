import 'dart:io';

import 'package:appplanilha/pdv_page_web.dart';
import 'package:appplanilha/presentation/pages/produtoList_mobile_screen.dart';
import 'package:appplanilha/providers/theme_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'cadastro_cliente.dart';
import 'custom_nav_bar.dart';
import 'new_screen.dart';
import 'preferences_screen.dart';
import 'widget_catalog.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class HomePageMobile extends StatefulWidget {
  const HomePageMobile({super.key, required this.title});

  final String title;

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  DateTimeRange? _selectedDateRange;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selected = await _picker.pickImage(source: source);
    if (selected != null) {
      setState(() {
        _image = File(selected.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? PDVWeb() : Scaffold(
      appBar: AppBar(
        title: Text('dashboard_title'),
        // title: Text(kIsWeb ? AppLocalizations.of(context)!.dashboard_web_title : AppLocalizations.of(context)!.dashboard_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text("Nome do Usuário"),
              accountEmail: Text("email@exemplo.com"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null ? Icon(Icons.camera_alt, size: 24.0) : null,
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Carregar da Galeria'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Tirar Foto'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Cadastro de Cliente'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CadastroClienteScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add_call),
              title: Text('Cadastro de Produtos'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProdutolistMobileScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Página Inicial'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.widgets),
              title: Text('Exemplos de Widgets'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WidgetCatalog()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.new_releases),
              title: Text('Nova Tela'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Modo Escuro'),
              trailing: Switch(
                value: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark,
                onChanged: (value) {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Preferências'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PreferencesScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: const Icon(Icons.filter_list),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      hintText: 'Buscar...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return _buildDashboardCard(
                    data[index]['title']!,
                    data[index]['count']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: kIsWeb? null : CustomBottomNavBar(),
    );
  }

  static final List<Map<String, String>> data = [
    {'title': 'OTs em revisão', 'count': '33'},
    {'title': 'OTs em processo', 'count': '27'},
    {'title': 'OTs finalizadas', 'count': '94'},
    {'title': 'OTs atrasadas', 'count': '10'},
    {'title': 'OTs pendentes', 'count': '15'},
    {'title': 'OTs canceladas', 'count': '7'},
    {'title': 'OTs em auditoria', 'count': '12'},
    {'title': 'OTs para reabertura', 'count': '5'},
    {'title': 'OTs em verificação', 'count': '9'},
    {'title': 'OTs com erro', 'count': '4'},
    {'title': 'OTs urgentes', 'count': '20'},
    {'title': 'OTs concluídas hoje', 'count': '30'},
    {'title': 'OTs em análise', 'count': '8'},
    {'title': 'OTs em espera', 'count': '11'},
  ];

  Widget _buildDashboardCard(String title, String count) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
