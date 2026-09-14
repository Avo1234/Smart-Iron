import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/iron_controller.dart';
import '../main.dart';
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
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.brand50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brand200),
        ),
        child: const Text(
          'PAIRING ASSISTANT',
          style: TextStyle(
            color: AppColors.brand700,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Pairing Help'),
                content: const Text(
                  'Make sure your Smart Iron is plugged in and powered on. Ensure Bluetooth is enabled on your phone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.help_outline, color: AppColors.textDark),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const SizedBox(height: 8),

          // Hero Pulsing Graphic
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand200.withOpacity(0.25),
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand200.withOpacity(0.55),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand700.withOpacity(0.12),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.iron, size: 48, color: AppColors.textDark),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.brand700,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand700.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth, size: 14, color: AppColors.brand200),
                        SizedBox(width: 4),
                        Text(
                          'Ready to Pair',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title & Subtitle
          const Text(
            'Connect your Smart Iron',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep the iron nearby and powered. Bluetooth permission is used only to find and monitor your iron.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Error Message Card
          if (controller.error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.error!,
                      style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Reconnect Remembered Device Hero Card
          if (controller.rememberedDeviceId != null) ...[
            Material(
              color: AppColors.brand700,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => controller.connect(controller.rememberedDeviceId!),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.link, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reconnect remembered iron',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            // const SizedBox(height: 2),
                            // Text(
                            //   'Saved Device • ${controller.rememberedDeviceId}',
                            //   maxLines: 1,
                            //   overflow: TextOverflow.ellipsis,
                            //   style: const TextStyle(
                            //     color: AppColors.brand200,
                            //     fontSize: 12,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.brand200),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Scan Button
          OutlinedButton.icon(
            onPressed: controller.scanning ? null : _scan,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.surfaceBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: controller.scanning
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching, color: AppColors.brand700),
            label: Text(
              controller.scanning ? 'Scanning…' : 'Scan for new irons',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Scanned Device Cards List
          ...controller.devices.map(
            (device) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bluetooth, color: AppColors.brand700, size: 20),
                ),
                title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${device.id} • ${device.rssi} dBm'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () => controller.connect(device.id),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Demo Mode Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'DEMO MODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Virtual',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore simulated controls and garment presets. Demo mode never connects to physical hardware.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => controller.useDemo(DemoBleTransport()),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.science_outlined, size: 16, color: AppColors.brand700),
                      SizedBox(width: 6),
                      Text(
                        'Open visible demo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brand700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Center(
            child: TextButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings, size: 14, color: AppColors.textMuted),
              label: const Text(
                'Open permission settings',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
