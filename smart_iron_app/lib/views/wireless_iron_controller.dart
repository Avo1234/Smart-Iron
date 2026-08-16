import 'package:flutter/material.dart';
import '../models/fabric_mode.dart';
import '../services/iron_websocket_service.dart';
import '../widgets/shutoff_overlay.dart';

class WirelessIronController extends StatefulWidget {
  const WirelessIronController({super.key});

  @override
  State<WirelessIronController> createState() => _WirelessIronControllerState();
}

class _WirelessIronControllerState extends State<WirelessIronController> {
  late IronWebSocketService _webSocketService;
  bool _isConnected = false;

  // Mirror variables mapping state parameters precisely to firmware targets
  int selectedMode = 0;
  double currentTemp = 25.0;
  bool ironActive = true;
  bool isHeating = false;
  String shutoffReason = "";
  int countdownSeconds = 30;

  @override
  void initState() {
    super.initState();
    // Initialize network interface service layer hooking framework state functions
    _webSocketService = IronWebSocketService(
      onMessageReceived: (data) {
        setState(() {
          currentTemp = data['currentTemp']?.toDouble() ?? 25.0;
          selectedMode = data['selectedMode'] ?? 0;
          ironActive = data['ironActive'] ?? false;
          isHeating = data['isHeating'] ?? false;
          shutoffReason = data['shutoffReason'] ?? "";
          countdownSeconds = data['countdown'] ?? 30;
        });
      },
      onConnectionStatusChanged: (status) {
        setState(() => _isConnected = status);
      },
    );
    _webSocketService.connect();
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFabric = fabricPresets[selectedMode];

    if (!_isConnected) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.cyan),
              SizedBox(height: 20),
              Text("Connecting to Smart Iron Wi-Fi...", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (!ironActive || shutoffReason.isNotEmpty) {
      return ShutoffOverlay(
        shutoffReason: shutoffReason.isEmpty ? "INACTIVITY" : shutoffReason,
        onResume: _webSocketService.sendResumeCommand,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[950],
      appBar: AppBar(
        title: const Text("WIRELESS SMART IRON"),
        centerTitle: true,
        backgroundColor: Colors.indigo[900],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Temperature Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Current Temp", style: TextStyle(color: Colors.cyan, fontSize: 14)),
                            Text("${currentTemp.toStringAsFixed(1)}°C", style: const TextStyle(color: Colors.yellow, fontSize: 36, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Target", style: TextStyle(color: Colors.cyan, fontSize: 14)),
                            Text("${activeFabric.targetTemp}°C", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (currentTemp / activeFabric.maxTemp).clamp(0.0, 1.0),
                        minHeight: 14,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(isHeating ? Colors.red : Colors.green),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isHeating ? "HEATING to ${activeFabric.targetTemp}°C..." : activeFabric.tip,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isHeating ? Colors.red : Colors.green, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Countdown Indicator Banner
          if (countdownSeconds <= 15)
            Container(
              color: Colors.red.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "! Inactivity Auto-Shutoff in ${countdownSeconds}s !",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text("Active Mode: ${activeFabric.name}", style: TextStyle(color: activeFabric.color, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          
          // Selection Input Grid View
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2),
              itemCount: fabricPresets.length,
              itemBuilder: (context, index) {
                final fabric = fabricPresets[index];
                final isSelected = index == selectedMode;
                return InkWell(
                  onTap: () => _webSocketService.sendModeChange(index),
                  child: Container(
                    decoration: BoxDecoration(color: isSelected ? fabric.color : Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fabric.name, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("${fabric.targetTemp}°C", style: TextStyle(color: isSelected ? Colors.black87 : Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}