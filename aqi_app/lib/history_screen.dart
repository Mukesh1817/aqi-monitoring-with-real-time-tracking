import 'package:flutter/material.dart';
import 'data_service.dart';

class HistoryScreen extends StatelessWidget {
  final DataService dataService;

  const HistoryScreen({super.key, required this.dataService});

  String _formatValue(dynamic value) {
    return value != null 
      ? (value as double).toStringAsFixed(1)
      : '--';
  }

  @override
  Widget build(BuildContext context) {
    final historyData = dataService.getHistoryData();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("History", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: historyData.isEmpty
          ? const Center(child: Text("No history data available"))
          : ListView.builder(
              itemCount: historyData.length,
              itemBuilder: (context, index) {
                final entry = historyData[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      entry['date'] ?? 'Unknown date',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("AQI: ${_formatValue(entry['AQI'])}"),
                        Text("Temp: ${_formatValue(entry['Temperature'])}°C"),
                        Text("Humidity: ${_formatValue(entry['Humidity'])}%"),
                        
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}