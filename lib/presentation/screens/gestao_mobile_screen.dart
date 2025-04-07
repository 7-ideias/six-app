import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_nav_bar.dart';
import '../components/drawer_mobile.dart';

class GestaoMobileScreen extends StatefulWidget {
  const GestaoMobileScreen({super.key});

  @override
  State<GestaoMobileScreen> createState() => _GestaoMobileScreenState();
}

class _GestaoMobileScreenState extends State<GestaoMobileScreen> {
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

  final List<BarChartGroupData> barData = [
    BarChartGroupData(
        x: 0, barRods: [BarChartRodData(toY: 50, color: Colors.teal)]),
    BarChartGroupData(
        x: 1, barRods: [BarChartRodData(toY: 80, color: Colors.teal)]),
    BarChartGroupData(
        x: 2, barRods: [BarChartRodData(toY: 30, color: Colors.teal)]),
    BarChartGroupData(
        x: 3, barRods: [BarChartRodData(toY: 90, color: Colors.teal)]),
  ];

  final List<PieChartSectionData> pieData = [
    PieChartSectionData(
        value: 40, title: 'Serviços', color: Colors.teal, radius: 60),
    PieChartSectionData(
        value: 30, title: 'Produtos', color: Colors.amber, radius: 60),
    PieChartSectionData(
        value: 20, title: 'Garantias', color: Colors.deepOrange, radius: 60),
    PieChartSectionData(
        value: 10, title: 'Outros', color: Colors.grey, radius: 60),
  ];

  DateTimeRange? _selectedDateRange;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão')),
      drawer: AppDrawerDoMobile(
        image: _image,
        onPickImage: _pickImage,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo geral',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInfoCard(
                    'Faturamento', 'R\$ 12.450,00', Icons.monetization_on),
                _buildInfoCard('Clientes', '134', Icons.people),
                _buildInfoCard('Produtos', '87', Icons.inventory),
                _buildInfoCard('Assistências', '25', Icons.build),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Vendas por Mês',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const months = ['Jan', 'Fev', 'Mar', 'Abr'];
                          return Text(months[value.toInt() % months.length]);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  barGroups: barData,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Distribuição de Receita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  sections: pieData,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Filtros rápidos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('Últimos 7 dias'),
                    selected: true,
                    onSelected: (_) {}),
                FilterChip(label: const Text('Este mês'),
                    selected: false,
                    onSelected: (_) {}),
                FilterChip(label: const Text('Ano atual'),
                    selected: false,
                    onSelected: (_) {}),
                ActionChip(
                  label: Text(
                    _selectedDateRange != null
                        ? '${_selectedDateRange!.start
                        .day}/${_selectedDateRange!.start
                        .month} - ${_selectedDateRange!.end
                        .day}/${_selectedDateRange!.end.month}'
                        : 'Escolher datas',
                  ),
                  onPressed: _selectDateRange,
                  avatar: const Icon(Icons.date_range, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: kIsWeb ? null : CustomBottomNavBar(initialIndex: 0),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.teal),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle()),
          ],
        ),
      ),
    );
  }
}
