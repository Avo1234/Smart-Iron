import 'package:flutter/material.dart';
import '../controllers/iron_controller.dart';
import '../models/iron_status.dart';
import '../services/iron_protocol.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});
  final IronController controller;
  static const names = ['Casual', 'Kente', 'Suits', 'Jeans', 'Bedding'];
  static const targets = [110, 125, 140, 155, 170];
  @override
  Widget build(BuildContext context) {
    final status = controller.status;
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.demoMode ? 'Smart Iron — DEMO' : 'Smart Iron'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _settings(context),
          ),
        ],
      ),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : _dashboard(context, status),
    );
  }

  Widget _dashboard(BuildContext context, IronStatus status) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (controller.demoMode)
        const Card(
          color: Color(0xffffecb3),
          child: ListTile(
            leading: Icon(Icons.science),
            title: Text('Demo mode'),
            subtitle: Text('No physical iron is connected.'),
          ),
        ),
      if (controller.error != null)
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(controller.error!),
          ),
        ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric(
                'Measured',
                status.temperature == null
                    ? '—'
                    : '${status.temperature!.toStringAsFixed(1)}°C',
              ),
              _metric('Target', '${status.target}°C'),
              _metric('Heater', status.heating ? 'HEATING' : 'OFF'),
            ],
          ),
        ),
      ),
      if (status.countdown > 0)
        Card(
          color: Colors.orange.shade100,
          child: ListTile(
            leading: const Icon(Icons.timer),
            title: Text('Handle released — ${status.countdown}s to shutdown'),
          ),
        ),
      if (status.hasFault)
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.warning_amber),
            title: Text(status.fault),
            subtitle: const Text(
              'Safety faults must be acknowledged on the iron.',
            ),
          ),
        ),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              value: status.power,
              onChanged: controller.pendingCommand == null
                  ? (value) => value
                        ? _confirmPowerOn(context)
                        : controller.send(IronProtocol.power(false))
                  : null,
              title: Text(
                status.power ? 'Iron powered on' : 'Iron powered off',
              ),
              subtitle: Text(controller.pendingCommand ?? status.message),
              secondary: Icon(status.power ? Icons.power : Icons.power_off),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                status.handle ? Icons.pan_tool : Icons.front_hand_outlined,
              ),
              title: Text(
                status.handle ? 'Handle held' : 'Handle not detected',
              ),
            ),
            ListTile(
              leading: Icon(
                status.temperatureSensorHealthy
                    ? Icons.thermostat
                    : Icons.error,
              ),
              title: Text(
                'Temperature sensor: ${status.temperatureSensorHealthy ? 'healthy' : 'FAILED'}',
              ),
            ),
            ListTile(
              leading: Icon(status.mpuHealthy ? Icons.sensors : Icons.error),
              title: Text(
                'Impact sensor: ${status.mpuHealthy ? 'healthy' : 'FAILED'}',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('Fabric preset', style: Theme.of(context).textTheme.titleMedium),
      Wrap(
        spacing: 8,
        children: List.generate(
          names.length,
          (index) => ChoiceChip(
            label: Text('${names[index]} ${targets[index]}°'),
            selected: status.preset == index,
            onSelected: controller.controlsEnabled
                ? (_) => controller.send(IronProtocol.preset(index))
                : null,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text('Manual target', style: Theme.of(context).textTheme.titleMedium),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: controller.controlsEnabled && status.target > 110
                ? () => controller.send(IronProtocol.target(status.target - 5))
                : null,
            icon: const Icon(Icons.remove),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${status.target}°C',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          IconButton.filledTonal(
            onPressed: controller.controlsEnabled && status.target < 170
                ? () => controller.send(IronProtocol.target(status.target + 5))
                : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: controller.connected && controller.pendingCommand == null
            ? () => controller.send(IronProtocol.power(false))
            : null,
        icon: const Icon(Icons.power_settings_new),
        label: const Text('POWER OFF NOW'),
      ),
    ],
  );
  Widget _metric(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      Text(label),
    ],
  );
  Future<void> _confirmPowerOn(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Power on the iron?'),
        content: const Text(
          'Confirm the iron is upright, attended, clear of flammable material, and that you are holding its handle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Power on'),
          ),
        ],
      ),
    );
    if (accepted == true) await controller.send(IronProtocol.power(true));
  }

  Future<void> _settings(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings & security',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SwitchListTile(
              title: const Text('Safety notifications'),
              value: controller.alertsEnabled,
              onChanged: controller.setAlerts,
            ),
            const ListTile(
              leading: Icon(Icons.lock),
              title: Text('Encrypted bonded BLE'),
              subtitle: Text(
                '“Just Works” encrypts the connection, but initial pairing is not protected from an active man-in-the-middle attacker.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Background monitoring is best effort'),
              subtitle: Text(
                'Alerts and reconnection cannot be guaranteed after force-quitting or OS suspension.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Disconnect'),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.disconnect();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Forget this device locally'),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.forget();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phonelink_erase),
              title: const Text('Clear pairings on iron'),
              subtitle: const Text('Only allowed while iron power is off'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear every ESP32 pairing?'),
                    content: const Text(
                      'The iron must be powered off. All phones will need to pair again.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear pairings'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  await controller.clearPairings();
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
