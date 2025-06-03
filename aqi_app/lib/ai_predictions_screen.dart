import 'package:flutter/material.dart';
import 'database_helper.dart';

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  State<AIPredictionsScreen> createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  final List<double> _predictions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _calculatePredictions();
  }

  Future<void> _calculatePredictions() async {
    try {
      final history = await DatabaseHelper.instance.getLastSevenDaysExcludingToday();
      
      if (history.isEmpty) throw Exception('No historical data available');
      if (history.length < 3) throw Exception('Need at least 3 days of data');

      final aqiValues = history.map((e) => e['AQI'] as double).toList();
      
      // Calculate 3-day predictions based on trend
      setState(() {
        _predictions.clear();
        _predictions.addAll(_calculateTrendPredictions(aqiValues));
        _isLoading = false;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  List<double> _calculateTrendPredictions(List<double> historicalAqi) {
    final predictions = <double>[];
    final lastValue = historicalAqi.last;
    final avgValue = historicalAqi.reduce((a, b) => a + b) / historicalAqi.length;
    
    // Calculate 3-day trend (simple moving average + last value influence)
    for (int i = 1; i <= 3; i++) {
      final trendFactor = 0.6; // Weight for recent trend (0-1)
      final dayPrediction = (lastValue * trendFactor) + (avgValue * (1 - trendFactor));
      
      // Add small random variation (±5%) to avoid identical values
      final variation = (dayPrediction * 0.05) * (i - 1);
      predictions.add(dayPrediction + (i.isOdd ? variation : -variation));
    }

    return predictions.map((v) => v.clamp(0, 500).toDouble()).toList();

  }

  void _handleError(dynamic error) {
    setState(() {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    });
  }

  Color _getAqiColor(double aqi) {
    if (aqi < 50) return Colors.green;
    if (aqi < 100) return Colors.yellow.shade700;
    if (aqi < 150) return Colors.orange;
    if (aqi < 200) return Colors.red;
    if (aqi < 300) return Colors.purple;
    return Colors.brown.shade800;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AQI Trend Forecast',style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calculating trends...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '3-Day AQI Trend Forecast',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _predictions.length,
            itemBuilder: (context, index) {
              final aqi = _predictions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAqiColor(aqi).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTrendIcon(index),
                      color: _getAqiColor(aqi),
                    ),
                  ),
                  title: Text('Day ${index + 1}'),
                  subtitle: Text(_getTrendDescription(index)),
                  trailing: Text(
                    aqi.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getAqiColor(aqi),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _getOverallTrend(),
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.teal.shade600,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTrendIcon(int index) {
    if (index == 0) return Icons.trending_neutral;
    return _predictions[index] > _predictions[index-1] 
        ? Icons.trending_up 
        : Icons.trending_down;
  }

  String _getTrendDescription(int index) {
    if (index == 0) return 'Similar to recent average';
    final change = ((_predictions[index] - _predictions[index-1]) / _predictions[index-1] * 100).abs();
    return _predictions[index] > _predictions[index-1]
        ? '↑ ${change.toStringAsFixed(1)}% from previous day'
        : '↓ ${change.toStringAsFixed(1)}% from previous day';
  }

  String _getOverallTrend() {
    final totalChange = _predictions.last - _predictions.first;
    final percentChange = (totalChange / _predictions.first * 100).abs();
    
    if (percentChange < 5) return 'Stable AQI expected over next 3 days';
    return totalChange > 0
        ? 'Overall increasing trend (▲ ${percentChange.toStringAsFixed(1)}%)'
        : 'Overall improving trend (▼ ${percentChange.toStringAsFixed(1)}%)';
  }
}