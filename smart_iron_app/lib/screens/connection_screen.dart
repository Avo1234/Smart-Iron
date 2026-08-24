import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/iron_controller.dart';
import '../services/demo_ble_transport.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key, required this.controller});
  final IronController controller;
  Future<void> _scan() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    await controller.startScan();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connect your Smart Iron')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.iron, size: 72),
          const SizedBox(height: 12),
          const Text(
            'Keep the iron nearby and powered. Bluetooth permission is used only to find and monitor your iron.',
            textAlign: TextAlign.center,
          ),
          if (controller.error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(controller.error!),
              ),
            ),
          if (controller.rememberedDeviceId != null)
            FilledButton.icon(
              onPressed: () =>
                  controller.connect(controller.rememberedDeviceId!),
              icon: const Icon(Icons.link),
              label: const Text('Reconnect remembered iron'),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.scanning ? null : _scan,
            icon: controller.scanning
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
            label: Text(controller.scanning ? 'Scanning…' : 'Scan for irons'),
          ),
          ...controller.devices.map(
            (device) => Card(
              child: ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(device.name),
                subtitle: Text('${device.id} • ${device.rssi} dBm'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => controller.connect(device.id),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const Text(
            'DEMO MODE',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Explore simulated controls. Demo mode never controls physical hardware.',
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: () => controller.useDemo(DemoBleTransport()),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Open visible demo'),
          ),
          TextButton(
            onPressed: openAppSettings,
            child: const Text('Open permission settings'),
          ),
        ],
      ),
    ),
  );
}
