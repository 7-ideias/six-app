import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WidgetCatalog extends StatefulWidget {
  const WidgetCatalog({Key? key}) : super(key: key);

  @override
  _WidgetCatalogState createState() => _WidgetCatalogState();
}

class _WidgetCatalogState extends State<WidgetCatalog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Widgets'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildSectionTitle("Gráfico de Linhas Animado"),
          AnimatedLineChart(),
          _buildSectionTitle("Gráfico de Barras Horizontais"),
          HorizontalBarChart(),
          _buildSectionTitle("Gráfico de Dispersão"),
          ScatterChartWidget(),
          _buildSectionTitle("Gráfico de Linhas com Sombras"),
          LineChartWithShadow(),
          _buildSectionTitle("Gráfico de Área com Gradiente"),
          GradientAreaChart(),
          _buildSectionTitle("Gráfico de Radar"),
          RadarChartWidget(),
          _buildSectionTitle("Gráfico de Barras Animadas"),
          AnimatedBarChart(),
          _buildSectionTitle("Gráfico de Linha Interativo"),
          InteractiveLineChart(),
          _buildSectionTitle("Gráfico de Pizza Expansível"),
          ExpandingPieChart(),
          _buildSectionTitle("Gráfico Gauge (Medidor Circular)"),
          GaugeChartWidget(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ============================
// 1. GRÁFICO DE LINHAS ANIMADO
// ============================
class AnimatedLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8.0),
      decoration: _boxDecoration(),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(10, (i) => FlSpot(i.toDouble(), (i * 2).toDouble())),
              isCurved: true,
              gradient: LinearGradient(
                colors: [Colors.blue]),
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.3)])),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================
// 2. GRÁFICO DE BARRAS HORIZONTAIS
// ============================
class HorizontalBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8.0),
      decoration: _boxDecoration(),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.center,
          barGroups: List.generate(5, (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: (index + 1) * 10, gradient: LinearGradient(
              colors: [Colors.purple]), width: 15),
            ],
          )),
        ),
      ),
    );
  }
}

// ============================
// 3. GRÁFICO DE DISPERSÃO (SCATTER PLOT)
// ============================
class ScatterChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8.0),
      decoration: _boxDecoration(),
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: List.generate(10, (i) => ScatterSpot(i.toDouble(), (i % 5).toDouble())),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
        ),
      ),
    );
  }
}

// ============================
// 4. GRÁFICO DE LINHAS COM SOMBRAS
// ============================
class LineChartWithShadow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8.0),
      decoration: _boxDecoration(),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(10, (i) => FlSpot(i.toDouble(), (i % 5 + 1) * 10.toDouble())),
              isCurved: true,
              gradient: LinearGradient(
                colors: [Color.fromARGB(128, 255, 165, 0), Colors.white], // Corrigido aqui!
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              barWidth: 3,
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  colors: [Colors.red.withOpacity(0.3)])),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================
// 5. GRÁFICO DE ÁREA COM GRADIENTE
// ============================
class GradientAreaChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8.0),
      decoration: _boxDecoration(),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(10, (i) => FlSpot(i.toDouble(), (i * 3).toDouble())),
              isCurved: true,
              color: Colors.orange, // Aqui, `color` substitui `gradient`
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Color.fromARGB(128, 255, 165, 0), Colors.white], // Corrigido aqui!
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ============================
// 6. GRÁFICO DE BARRAS ANIMADAS
// ============================
class AnimatedBarChart extends StatefulWidget {
  @override
  _AnimatedBarChartState createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8.0),
      decoration: _boxDecoration(),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.center,
          barGroups: List.generate(5, (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (index + 1) * 10,
                gradient: LinearGradient(
                  colors:[Colors.teal]),
                width: 15,
              ),
            ],
          )),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

// ============================
// 7. GRÁFICO DE LINHA INTERATIVO
// ============================
class InteractiveLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8.0),
      decoration: _boxDecoration(),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(enabled: true),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(10, (i) => FlSpot(i.toDouble(), (i * 2).toDouble())),
              isCurved: true,
              gradient: LinearGradient(
                colors:[Colors.purple]),
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                  colors:[Colors.purple.withOpacity(0.3)])),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================
// 8. GRÁFICO DE PIZZA EXPANSÍVEL
// ============================
class ExpandingPieChart extends StatefulWidget {
  @override
  _ExpandingPieChartState createState() => _ExpandingPieChartState();
}

class _ExpandingPieChartState extends State<ExpandingPieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16.0),
      decoration: _boxDecoration(),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: List.generate(4, (index) {
            final isTouched = index == touchedIndex;
            final double radius = isTouched ? 60 : 50;

            return PieChartSectionData(
              value: (index + 1) * 10,
              title: "${(index + 1) * 10}%",
              color: [Colors.blue, Colors.green, Colors.orange, Colors.red][index],
              radius: radius,
              titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                } else {
                  touchedIndex = null;
                }
              });
            },
          ),
        ),
      ),
    );
  }
}

// ============================
// 9. GRÁFICO GAUGE (MEDIDOR CIRCULAR)
// ============================
class GaugeChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(8.0),
      decoration: _boxDecoration(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: 0.7,
              strokeWidth: 10,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              backgroundColor: Colors.grey[300]!,
            ),
          ),
          Text("70%", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================
// 10. GRÁFICO DE RADAR (Radar Chart)
// ============================
class RadarChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16.0),
      decoration: _boxDecoration(),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon, // Estiliza o gráfico como um polígono
          dataSets: [
            RadarDataSet(
              dataEntries: [
                RadarEntry(value: 4),
                RadarEntry(value: 3),
                RadarEntry(value: 5),
                RadarEntry(value: 2),
                RadarEntry(value: 4),
              ],
              borderColor: Colors.blue,
              fillColor: Color.fromARGB(128, 33, 150, 243), // Azul com transparência
              entryRadius: 2,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, angle) => RadarChartTitle(
            text: ["Força", "Velocidade", "Resistência", "Agilidade", "Precisão"][index],
            angle: angle,
          ),
        ),
      ),
    );
  }
}



// ============================
// Função para decoração do container
// ============================
BoxDecoration _boxDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
  );
}

