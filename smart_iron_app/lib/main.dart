import 'package:flutter/material.dart';
import 'views/wireless_iron_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartIronApp());
}

class SmartIronApp extends StatelessWidget {
  const SmartIronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Iron Control Panel',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[950],
        
        // FIXED HERE: Changed CardTheme to CardThemeData
        cardTheme: CardThemeData(
          color: Colors.black,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[900],
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      
      home: const WirelessIronController(),
    );
  }
}