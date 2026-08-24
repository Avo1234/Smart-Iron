import 'package:flutter/material.dart';
import 'controllers/iron_controller.dart';
import 'screens/connection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/alert_service.dart';
import 'services/reactive_ble_transport.dart';
import 'services/settings_service.dart';

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
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffe65100)),
      useMaterial3: true,
    ),
    home: AnimatedBuilder(
      animation: controller,
      builder: (_, child) => controller.connected
          ? DashboardScreen(controller: controller)
          : ConnectionScreen(controller: controller),
    ),
  );
}
