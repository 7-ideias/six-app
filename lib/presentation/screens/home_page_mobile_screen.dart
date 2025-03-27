import 'dart:io';

import 'package:appplanilha/pdv_page_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../components/custom_nav_bar.dart';
import 'drawer_mobile.dart';
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
    final temaDaAplicacao = Theme.of(context);

    return kIsWeb ? PDVWeb() : Scaffold(
      appBar: AppBar(
        backgroundColor: temaDaAplicacao.appBarTheme.backgroundColor,
        title: Text('home'),
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
      drawer: AppDrawer(
        image: _image,
        onPickImage: _pickImage,
      ),
      // body: buildPaddingComCardsFlutuantes(),
      body: Row(
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
      bottomNavigationBar: kIsWeb ? null : CustomBottomNavBar(initialIndex: 1),
    );
  }

  Padding buildPaddingComCardsFlutuantes() {
    return Padding(
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
