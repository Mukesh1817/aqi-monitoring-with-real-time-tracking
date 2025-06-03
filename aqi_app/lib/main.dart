import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'aqi_dashboard.dart';
import 'data_service.dart';
import 'database_helper.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize database with error handling
    await _initializeDatabase();
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => DataService()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {  

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize app: ${e.toString()}',
              style: const TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeDatabase() async {
  try {
    print('🔄 Initializing database...');
    final db = await DatabaseHelper.instance.database;
    final records = await db.query('history', limit: 1);
    print('✅ Database initialized with ${records.length} records');
  } catch (e) {
    print('❌ Database initialization failed: $e');
    rethrow; // Re-throw to be caught in main()
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AQI Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AQIDashboard(
        dataService: Provider.of<DataService>(context, listen: false),
      ),
    );
  }
}