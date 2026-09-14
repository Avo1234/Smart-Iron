import 'package:flutter/material.dart';
import 'controllers/iron_controller.dart';
import 'screens/connection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/alert_service.dart';
import 'services/reactive_ble_transport.dart';
import 'services/settings_service.dart';

class AppColors {
  static const surfaceBase = Color(0xFFFAF7F2);
  static const surfaceCard = Colors.white;
  static const surfaceBorder = Color(0xFFE8E1D7);
  static const brand700 = Color(0xFF8A3F23);
  static const brand500 = Color(0xFFB85028);
  static const brand200 = Color(0xFFF2D7C8);
  static const brand100 = Color(0xFFF9EDE6);
  static const brand50 = Color(0xFFFDF8F5);
  static const textDark = Color(0xFF1C1917);
  static const textMuted = Color(0xFF78716C);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = LocalNotificationSink();
  await notifications.initialize();
  final controller = IronController(
    ReactiveBleTransport(),
    settings: SettingsService(),
    alerts: AlertService(notifications),
  );
  await controller.initialize();
  runApp(SmartIronApp(controller: controller));
}

class SmartIronApp extends StatelessWidget {
  const SmartIronApp({super.key, required this.controller});
  final IronController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart Iron',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      scaffoldBackgroundColor: AppColors.surfaceBase,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand700,
        surface: AppColors.surfaceBase,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
    ),
    home: AnimatedBuilder(
      animation: controller,
      builder: (_, child) => controller.connected
          ? DashboardScreen(controller: controller)
          : ConnectionScreen(controller: controller),
    ),
  );
}
