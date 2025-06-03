import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data_service.dart';
import 'history_screen.dart';
import 'ai_predictions_screen.dart';

class AQIDashboard extends StatefulWidget {
  final DataService dataService;

  const AQIDashboard({super.key, required this.dataService});

  @override
  State<AQIDashboard> createState() => _AQIDashboardState();
}

class _AQIDashboardState extends State<AQIDashboard> {
  String selectedParameter = 'AQI';
  Timer? _timer;
  DateTime lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.dataService.addListener(_onDataUpdated);
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _checkDataTimeout();
      setState(() {});
    });
  }

  @override
  void dispose() {
    widget.dataService.removeListener(_onDataUpdated);
    _timer?.cancel();
    super.dispose();
  }

  void _onDataUpdated() {
    lastUpdate = DateTime.now();
    setState(() {});
  }

  void _checkDataTimeout() {
    if (DateTime.now().difference(lastUpdate).inSeconds > 10) {
      setState(() {
        print("Data is stale. Last update was more than 10 seconds ago.");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestData = {
      'Temperature': widget.dataService.temperature,
      'Humidity': widget.dataService.humidity,
      'AQI': widget.dataService.aqi,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("AQI Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildGauges(latestData),
                const SizedBox(height: 20),
                _buildParameterButtons(),
                const SizedBox(height: 20),
                _buildLineChart(widget.dataService.realTimeData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Center(
              child: Text(
                "MENU",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.teal),
            title: const Text("History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => HistoryScreen(dataService: widget.dataService)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights, color: Colors.teal),
            title: const Text("AI Predictions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
              builder: (context) => const AIPredictionsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGauges(Map<String, dynamic> latestData) {
    return Column(
      children: [
        _buildGauge("Temperature", latestData['Temperature'] ?? 0, "°C"),
        const SizedBox(height: 20),
        _buildGauge("Humidity", latestData['Humidity'] ?? 0, "%"),
        const SizedBox(height: 20),
        _buildGauge("AQI", latestData['AQI'] ?? 0, ""),
      ],
    );
  }

  Widget _buildGauge(String title, double value, String unit) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            width: 120,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: title == "AQI" ? 0 : 0,
                  maximum: title == "AQI" ? 500 : (title == "Temperature" ? 50 : 100),
                  ranges: _getGaugeRanges(title),
                  pointers: <GaugePointer>[NeedlePointer(value: value)],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "$value $unit",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  List<GaugeRange> _getGaugeRanges(String title) {
    if (title == "AQI") {
      return [
        GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
        GaugeRange(startValue: 50, endValue: 100, color: Colors.yellow),
        GaugeRange(startValue: 100, endValue: 150, color: Colors.orange),
        GaugeRange(startValue: 150, endValue: 200, color: Colors.red),
        GaugeRange(startValue: 200, endValue: 300, color: Colors.purple),
        GaugeRange(startValue: 300, endValue: 500, color: Colors.brown),
      ];
    } else {
      return [
        GaugeRange(startValue: 0, endValue: 40, color: Colors.blue),
        GaugeRange(startValue: 40, endValue: 70, color: Colors.green),
        GaugeRange(startValue: 70, endValue: 100, color: Colors.orange),
      ];
    }
  }

  Widget _buildParameterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildParameterButton("Temperature", Colors.red),
        _buildParameterButton("Humidity", Colors.blue),
        _buildParameterButton("AQI", Colors.green),
      ],
    );
  }

  Widget _buildParameterButton(String title, Color color) {
    bool isSelected = selectedParameter == title.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => selectedParameter = title.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Text(title, style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          color: color
        )),
      ),
    );
  }

Widget _buildLineChart(List<Map<String, dynamic>> realTimeData) {
  // Get only the last 8 data points
  final limitedData = realTimeData.length > 8 
      ? realTimeData.sublist(realTimeData.length - 8)
      : realTimeData;

  if (limitedData.isEmpty) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Text(
          "No graph data available",
          style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.7)),
        ),
      ),
    );
  }

  final spots = _generateChartSpots(limitedData);
  final lineColor = _getLineColor();
  final maxY = _getMaxYValue();

  return SizedBox(
    height: 250,
    child: Card(
      elevation: 4,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: lineColor, // Dynamic color matching the graph
              ),
              child: Text("Real-Time $selectedParameter (Last 8 readings)"),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 7, // Fixed to show 8 points (0-7)
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getGridInterval(maxY),
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt() + 1}', 
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _getGridInterval(maxY),
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  List<FlSpot> _generateChartSpots(List<Map<String, dynamic>> data) {
    return List.generate(data.length, (index) {
      final entry = data[index];
      double value = 0;
      
      switch (selectedParameter.toLowerCase()) {
        case "temperature":
          value = entry['Temperature']?.toDouble() ?? 0;
          break;
        case "humidity":
          value = entry['Humidity']?.toDouble() ?? 0;
          break;
        case "aqi":
        default:
          value = entry['AQI']?.toDouble() ?? 0;
      }

      return FlSpot(index.toDouble(), value);
    });
  }

  Color _getLineColor() {
    switch (selectedParameter.toLowerCase()) {
      case "temperature": return Colors.red;
      case "humidity": return Colors.blue;
      case "aqi":
      default: return Colors.green;
    }
  }

  double _getMaxYValue() {
    switch (selectedParameter.toLowerCase()) {
      case "temperature": return 50;
      case "humidity": return 100;
      case "aqi":
      default: return 500;
    }
  }

  double _getGridInterval(double maxY) {
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;
    return 100;
  }
}