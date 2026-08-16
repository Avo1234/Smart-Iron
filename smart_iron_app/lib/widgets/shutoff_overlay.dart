import 'package:flutter/material.dart';
import '../models/fabric_mode.dart';

class ShutoffOverlay extends StatelessWidget {
  final String shutoffReason;
  final VoidCallback onResume;

  const ShutoffOverlay({
    super.key,
    required this.shutoffReason,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 80),
              const SizedBox(height: 16),
              const Text("!! AUTO SHUTOFF !!", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Reason: $shutoffReason", style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
              const Divider(color: Colors.grey, height: 40),
              const Text("Heating element DISABLED\nIron is cooling down safely...", textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 16, height: 1.4)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                onPressed: onResume,
                icon: const Icon(Icons.refresh),
                label: const Text("Tap to Resume Ironing", style: TextStyle(fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}