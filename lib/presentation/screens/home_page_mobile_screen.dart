import 'dart:io';

import 'package:appplanilha/pdv_page_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_nav_bar.dart';
import '../components/drawer_mobile.dart';
import 'catalogo_disponivel_mobile_screen.dart';
import 'catalogo_nao_disponivel_mobile_screen.dart';
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
        title: Text(widget.title),
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
      drawer: AppDrawerDoMobile(
        image: _image,
        onPickImage: _pickImage,
      ),
      body: buildPaddingComCardsFlutuantes(),
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
              itemCount: cardsVisaoDasOperacoes.length,
              itemBuilder: (context, index) {
                return _buildDashboardCard(
                  cardsVisaoDasOperacoes[index]['title']!,
                  cardsVisaoDasOperacoes[index]['count']!,
                  cardsVisaoDasOperacoes[index]['mapeamentoDePara'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static final List<Map<String, String>> cardsVisaoDasOperacoes = [
    {
      'title': 'Catálogo Disponível',
      'count': '10',
      'mapeamentoDePara': 'CATALOGODISPONIVEL'
    },
    {
      'title': 'Catálogo Não Ativo',
      'count': '0',
      'mapeamentoDePara': 'CATALOGONAOATIVO'
    },
    {'title': 'Vendas - não pagas', 'count': '33'},
    {'title': 'OTs em revisão', 'count': '33'},
    {'title': 'OTs em processo', 'count': '27'},
    // {'title': 'OTs finalizadas', 'count': '94'},
    // {'title': 'OTs atrasadas', 'count': '10'},
    // {'title': 'OTs pendentes', 'count': '15'},
    // {'title': 'OTs canceladas', 'count': '7'},
    // {'title': 'OTs em auditoria', 'count': '12'},
    // {'title': 'OTs para reabertura', 'count': '5'},
    // {'title': 'OTs em verificação', 'count': '9'},
    // {'title': 'OTs com erro', 'count': '4'},
    // {'title': 'OTs urgentes', 'count': '20'},
    // {'title': 'OTs concluídas hoje', 'count': '30'},
    // {'title': 'OTs em análise', 'count': '8'},
    // {'title': 'OTs em espera', 'count': '11'},
  ];

  Widget _buildDashboardCard(String title, String count,
      String? mapeamentoDePara) {
    return GestureDetector(
      onTap: () {
        if (mapeamentoDePara == 'CATALOGONAOATIVO') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>
                MeuCatalogoMobileScreen()), // substitua por sua tela real
          );
        }
        if (mapeamentoDePara == 'CATALOGODISPONIVEL') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>
                CatalogoDisponivelMobileScreen()), // substitua por sua tela real
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold),
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
      ),
    );
  }

}

