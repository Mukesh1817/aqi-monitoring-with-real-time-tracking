import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'database_helper.dart';
import 'dart:convert';

class DataService extends ChangeNotifier {
  double temperature = 0.0;
  double humidity = 0.0;
  double aqi = 0.0;
  List<Map<String, dynamic>> realTimeData = [];
  List<Map<String, dynamic>> historicalData = [];
  late IOWebSocketChannel _channel;

  DataService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    print("Initializing DataService...");
    await _loadHistoricalData();
    _connectWebSocket();
    await DatabaseHelper.instance.clearOldData();
  }

  void _connectWebSocket() {
    try {
      print("Connecting to WebSocket...");
      _channel = IOWebSocketChannel.connect('ws://192.168.29.173:81');
      _channel.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );
      print("WebSocket connected.");
    } catch (e) {
      print("WebSocket connection failed: $e");
      Future.delayed(const Duration(seconds: 5), _connectWebSocket);
    }
  }

  void _handleWebSocketMessage(message) {
    print("Received WebSocket message: $message");

    if (message is String) {
      try {
        final data = jsonDecode(message);
        if (data['aqi'] == null || data['temperature'] == null || data['humidity'] == null) {
          throw Exception('Missing required fields in WebSocket data');
        }

        _updateCurrentData(
          data['aqi'].toDouble(),
          data['temperature'].toDouble(),
          data['humidity'].toDouble()
        );
      } catch (e) {
        print("WebSocket JSON decode error: $e");
      }
    } else {
      print("Non-string WebSocket message received.");
    }
  }

  void _handleWebSocketError(dynamic error) {
    print("WebSocket error: $error");
    Future.delayed(const Duration(seconds: 5), _connectWebSocket);
  }

  void _handleWebSocketDone() {
    print("WebSocket disconnected. Reconnecting...");
    Future.delayed(const Duration(seconds: 5), _connectWebSocket);
  }

  Future<void> _updateCurrentData(double newAqi, double newTemp, double newHumidity) async {
    aqi = newAqi;
    temperature = newTemp;
    humidity = newHumidity;

    _updateRealTimeData(newAqi, newTemp, newHumidity);

    try {
      await DatabaseHelper.instance.upsertDailyData(newAqi, newTemp, newHumidity);
      await _loadHistoricalData();
    } catch (e) {
      print('Database error: $e');
    }

    notifyListeners();
  }

  void _updateRealTimeData(double aqi, double temp, double humidity) {
    final now = DateTime.now();
    if (realTimeData.isNotEmpty) {
      final lastTime = DateTime.parse(realTimeData.last['time']);
      if (now.difference(lastTime).inSeconds < 10) return;
    }

    if (realTimeData.length >= 24) realTimeData.removeAt(0);
    realTimeData.add({
      'AQI': aqi,
      'Temperature': temp,
      'Humidity': humidity,
      'time': now.toString()
    });
  }

  Future<void> _loadHistoricalData() async {
    try {
      historicalData = await DatabaseHelper.instance.getHistoricalData();
      print('Loaded ${historicalData.length} historical records');
      notifyListeners();
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  List<Map<String, dynamic>> getHistoryData() => historicalData;

  @override
  void dispose() {
    print("Closing WebSocket connection...");
    _channel.sink.close();
    super.dispose();
  }
}
