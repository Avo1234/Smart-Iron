import 'package:flutter/material.dart';
import '../controllers/iron_controller.dart';
import '../main.dart';
import '../models/iron_status.dart';
import '../services/iron_protocol.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.controller});
  final IronController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;
  static const names = ['Casual', 'Kente', 'Suits', 'Jeans', 'Bedding'];
  static const targets = [110, 125, 140, 155, 170];

  @override
  Widget build(BuildContext context) {
    final status = widget.controller.status;
    return Scaffold(
      body: SafeArea(
        child: status == null
            ? const Center(child: CircularProgressIndicator())
            : _buildActiveTab(context, status),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.add_circle_outline, 'Control'),
            _navItem(1, Icons.bar_chart_rounded, 'Heat Log'),
            _navItem(2, Icons.verified_user_outlined, 'Safety'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.brand700 : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.brand700 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, IronStatus status) {
    switch (_selectedTab) {
      case 1:
        return _buildHeatLogTab(context, status);
      case 2:
        return _buildSafetyTab(context, status);
      case 0:
      default:
        return _buildControlTab(context, status);
    }
  }

  // ==========================================
  // TAB 0: CONTROL VIEW
  // ==========================================
  Widget _buildControlTab(BuildContext context, IronStatus status) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Header Section
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.controller.demoMode ? 'Smart Iron' : 'Smart Iron',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.controller.demoMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'DEMO MODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              const Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Sensor telemetry sync active',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          IconButton.filledTonal(
            onPressed: () => _settings(context),
            icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textDark),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Error Banner
      if (widget.controller.error != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
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
                  widget.controller.error!,
                  style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // Thermal Monitor Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'THERMAL MONITOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status.power ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.power ? '● Heating Mode' : '● Standby Mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status.power ? const Color(0xFF047857) : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.surfaceBorder, height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: _metricColumn(
                    'MEASURED',
                    status.temperature == null
                        ? '—'
                        : '${status.temperature!.toStringAsFixed(1)}°C',
                    'Ambient',
                    AppColors.textDark,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.surfaceBorder),
                Expanded(
                  child: _metricColumn(
                    'TARGET',
                    '${status.target}°C',
                    status.preset != null ? 'Preset active' : 'Manual setpoint',
                    AppColors.brand500,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.surfaceBorder),
                Expanded(
                  child: _metricColumn(
                    'HEATER',
                    status.heating ? 'HEATING' : 'OFF',
                    status.heating ? 'Relay Closed' : 'Relay Open',
                    status.heating ? AppColors.brand700 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Countdown Warning Banner
      if (status.countdown > 0) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Handle released — ${status.countdown}s to shutdown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // Hardware Fault Banner
      if (status.hasFault) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.fault,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Safety faults must be acknowledged on the iron.',
                      style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // Power Switch & Sensor Watchdog Card
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: status.power,
              onChanged: widget.controller.pendingCommand == null
                  ? (val) => val
                        ? _confirmPowerOn(context)
                        : widget.controller.send(IronProtocol.power(false))
                  : null,
              title: Text(
                status.power ? 'Iron Powered On' : 'Iron Powered Off',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                widget.controller.pendingCommand ?? status.message,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              secondary: CircleAvatar(
                backgroundColor: AppColors.surfaceBase,
                child: Icon(
                  status.power ? Icons.power : Icons.power_off,
                  color: status.power ? AppColors.brand700 : AppColors.textMuted,
                ),
              ),
            ),
            const Divider(color: AppColors.surfaceBorder, height: 1),
            _sensorTile(
              icon: Icons.pan_tool_outlined,
              title: 'Handle Grip',
              subtitle: null,
              badgeText: status.handle ? '● Held (Capacitive)' : '● Released',
              isHealthy: status.handle,
            ),
            _sensorTile(
              icon: Icons.thermostat_outlined,
              title: 'Temp Probe',
              subtitle: null,
              badgeText: status.temperatureSensorHealthy ? '● Healthy & Calibrated' : '● FAILED',
              isHealthy: status.temperatureSensorHealthy,
            ),
            _sensorTile(
              icon: Icons.sensors_outlined,
              title: 'Impact & Motion',
              subtitle: 'Auto-cutoff watchdog ready',
              badgeText: status.mpuHealthy ? '● Optimal' : '● FAILED',
              isHealthy: status.mpuHealthy,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Fabric Presets Section
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FABRIC PRESETS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 1.0,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Fabric Temperature Guide',
                      '• Casual (110°C): Synthetics & Silks\n• Kente (125°C): Traditional fabrics\n• Suits (140°C): Wool & Formal wear\n• Jeans (155°C): Denim & Heavy cotton\n• Bedding (170°C): Heavy linen',
                    );
                  },
                  child: const Text(
                    'Guide',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Pre-calibrated heat settings for delicate fibers',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: names.length,
              itemBuilder: (context, index) {
                final isSelected = status.preset == index;
                return InkWell(
                  onTap: widget.controller.controlsEnabled
                      ? () => widget.controller.send(IronProtocol.preset(index))
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brand100 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.brand500 : AppColors.surfaceBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check_circle, size: 16, color: AppColors.brand500),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              names[index],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? AppColors.brand700 : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${targets[index]}°',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Manual Target Selector Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MANUAL TARGET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Custom regulation (±5° increments)',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: widget.controller.controlsEnabled && status.target > 110
                      ? () => widget.controller.send(IronProtocol.target(status.target - 5))
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.brand200),
                    ),
                    child: const Icon(Icons.remove, color: AppColors.brand500, size: 28),
                  ),
                ),
                Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        text: '${status.target}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        children: const [
                          TextSpan(
                            text: '°C',
                            style: TextStyle(fontSize: 24, color: AppColors.brand500),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Target setpoint',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                InkWell(
                  onTap: widget.controller.controlsEnabled && status.target < 170
                      ? () => widget.controller.send(IronProtocol.target(status.target + 5))
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.brand200),
                    ),
                    child: const Icon(Icons.add, color: AppColors.brand500, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // POWER OFF NOW Button
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: widget.controller.connected && widget.controller.pendingCommand == null
            ? () => widget.controller.send(IronProtocol.power(false))
            : null,
        icon: const Icon(Icons.power_settings_new),
        label: const Text(
          'POWER OFF NOW',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
    ],
  );

  // ==========================================
  // TAB 1: HEAT LOG VIEW
  // ==========================================
  Widget _buildHeatLogTab(BuildContext context, IronStatus status) {
    final history = widget.controller.telemetryHistory;
    final totalSamples = history.length;
    final heatingSamples = history.where((p) => p.heating).length;
    final dutyCycle = totalSamples == 0 ? 0.0 : (heatingSamples / totalSamples * 100);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Thermal Telemetry Log',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          'Real-time temperature history and heater relay duty cycle',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        // Session Overview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SESSION STATISTICS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brand100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalSamples telemetry points',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricColumn(
                    'CURRENT TEMP',
                    status.temperature == null ? '—' : '${status.temperature!.toStringAsFixed(1)}°C',
                    'Measured',
                    AppColors.textDark,
                  ),
                  Container(width: 1, height: 40, color: AppColors.surfaceBorder),
                  _metricColumn(
                    'TARGET',
                    '${status.target}°C',
                    'Setpoint',
                    AppColors.brand500,
                  ),
                  Container(width: 1, height: 40, color: AppColors.surfaceBorder),
                  _metricColumn(
                    'DUTY CYCLE',
                    '${dutyCycle.toStringAsFixed(0)}%',
                    'Heater Active',
                    AppColors.brand700,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Visual Heat Chart Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE TEMPERATURE TREND',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'Waiting for telemetry stream...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: TemperatureChartPainter(
                      history: history,
                      targetTemp: status.target.toDouble(),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.square, size: 10, color: AppColors.brand500),
                      SizedBox(width: 4),
                      Text('Active', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      SizedBox(width: 10),
                      Icon(Icons.square, size: 10, color: AppColors.brand200),
                      SizedBox(width: 4),
                      Text('Resting', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                  Text('5s Intervals', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent Log Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'RECENT TELEMETRY FEED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceBorder),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No telemetry logged yet.'),
                  ),
                )
              else
                ...history.reversed.take(8).map((point) {
                  final timeStr =
                      '${point.timestamp.hour.toString().padLeft(2, '0')}:${point.timestamp.minute.toString().padLeft(2, '0')}:${point.timestamp.second.toString().padLeft(2, '0')}';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              point.temperature == null ? '—' : '${point.temperature!.toStringAsFixed(1)}°C',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(Target ${point.target}°)',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: point.heating ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            point.heating ? 'HEATING' : 'IDLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: point.heating ? const Color(0xFF047857) : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: SAFETY VIEW
  // ==========================================
  Widget _buildSafetyTab(BuildContext context, IronStatus status) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Safety & Hardware Subsystems',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
      const SizedBox(height: 4),
      const Text(
        'Hardware watchdogs, handle touch sensors, and fault recovery rules',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      const SizedBox(height: 16),

      // Overall Safety Status Banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: status.hasFault
              ? const Color(0xFFFEE2E2)
              : (status.countdown > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: status.hasFault
                ? const Color(0xFFFCA5A5)
                : (status.countdown > 0 ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: status.hasFault
                  ? const Color(0xFFDC2626)
                  : (status.countdown > 0 ? const Color(0xFFD97706) : const Color(0xFF10B981)),
              child: Icon(
                status.hasFault
                    ? Icons.warning_amber
                    : (status.countdown > 0 ? Icons.timer : Icons.verified_user),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.hasFault
                        ? 'SAFETY FAULT DETECTED'
                        : (status.countdown > 0
                            ? 'HANDLE RELEASE WARNING'
                            : 'ALL WATCHDOGS OPTIMAL'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: status.hasFault
                          ? const Color(0xFF991B1B)
                          : (status.countdown > 0
                              ? const Color(0xFF92400E)
                              : const Color(0xFF065F46)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.hasFault
                        ? 'Fault: ${status.fault}. Physical reset required on iron.'
                        : (status.countdown > 0
                            ? 'Auto-shutdown in ${status.countdown}s unless handle is held.'
                            : 'Firmware safety interlocks & hardware thermal fuse active.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: status.hasFault
                          ? const Color(0xFFB91C1C)
                          : (status.countdown > 0
                              ? const Color(0xFFB45309)
                              : const Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Watchdog Cards
      const Text(
        'HARDWARE WATCHDOG SPECIFICATIONS',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
      const SizedBox(height: 10),

      _safetyDetailCard(
        title: '1. Handle Presence (TTP223 Capacitive)',
        statusText: status.handle ? 'Grip Active' : 'Grip Released',
        statusColor: status.handle ? const Color(0xFF047857) : const Color(0xFFD97706),
        description:
            'Continuous capacitive sense with 100ms debounce. Releasing the handle triggers a 30s timer (20s buzzer warning, 30s heater cut).',
      ),
      const SizedBox(height: 10),

      _safetyDetailCard(
        title: '2. Impact & Fall Detection (MPU6050)',
        statusText: status.mpuHealthy ? 'Watchdog Active (2.5g)' : 'MPU FAULT',
        statusColor: status.mpuHealthy ? const Color(0xFF047857) : const Color(0xFFDC2626),
        description:
            '6-axis motion monitoring. Sustained acceleration ≥ 2.5g for 100ms triggers an immediate latched impact shutdown.',
      ),
      const SizedBox(height: 10),

      _safetyDetailCard(
        title: '3. PT100 RTD Sensor (MAX31865)',
        statusText: status.temperatureSensorHealthy ? 'Probe Calibrated' : 'RTD FAULT',
        statusColor: status.temperatureSensorHealthy ? const Color(0xFF047857) : const Color(0xFFDC2626),
        description:
            '3-wire RTD SPI amplifier. Evaluates fault flags & non-finite readings. Overheat threshold set at 200°C emergency cut.',
      ),
      const SizedBox(height: 10),

      _safetyDetailCard(
        title: '4. Relays & Hardware Thermal Protection',
        statusText: '3°C Hysteresis Band',
        statusColor: AppColors.brand700,
        description:
            'Solid-state relay with 3°C hysteresis band. Firmware never replaces hardware grounding, fusing, and thermal cutouts.',
      ),
      const SizedBox(height: 16),

      // Latched Fault Reset Guide
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app_outlined, color: AppColors.brand700),
                SizedBox(width: 10),
                Text(
                  'Safety Fault Clearance Protocol',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'For safety reasons, serious faults cannot be cleared remotely via Bluetooth. To reset a fault:',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 10),
            _guideStep('1', 'Inspect physical hardware and ensure iron is upright & cool.'),
            _guideStep('2', 'Verify MAX31865 & MPU6050 sensors are healthy.'),
            _guideStep('3', 'Wait for 5 consecutive temperature readings below 170°C.'),
            _guideStep('4', 'Press ACK on the iron\'s ILI9341 touchscreen interface.'),
          ],
        ),
      ),
    ],
  );

  Widget _safetyDetailCard({
    required String title,
    required String statusText,
    required Color statusColor,
    required String description,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
        ),
      ],
    ),
  );

  Widget _guideStep(String step, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: AppColors.brand100,
          child: Text(
            step,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brand700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ),
      ],
    ),
  );

  Widget _metricColumn(String label, String value, String badge, Color valueColor) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          badge,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ),
    ],
  );

  Widget _sensorTile({
    required IconData icon,
    required String title,
    required String? subtitle,
    required String badgeText,
    required bool isHealthy,
  }) => ListTile(
    leading: CircleAvatar(
      backgroundColor: isHealthy ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
      child: Icon(
        icon,
        size: 18,
        color: isHealthy ? const Color(0xFF047857) : const Color(0xFFDC2626),
      ),
    ),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    subtitle: subtitle != null
        ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))
        : null,
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHealthy ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isHealthy ? const Color(0xFF047857) : const Color(0xFFDC2626),
        ),
      ),
    ),
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
    if (accepted == true) await widget.controller.send(IronProtocol.power(true));
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
              value: widget.controller.alertsEnabled,
              onChanged: widget.controller.setAlerts,
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
                widget.controller.disconnect();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Forget this device locally'),
              onTap: () {
                Navigator.pop(sheetContext);
                widget.controller.forget();
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
                  await widget.controller.clearPairings();
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class TemperatureChartPainter extends CustomPainter {
  final List<TelemetryPoint> history;
  final double targetTemp;

  TemperatureChartPainter({required this.history, required this.targetTemp});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final minTemp = 80.0;
    final maxTemp = 200.0;
    final tempRange = maxTemp - minTemp;

    double getY(double temp) {
      final normalized = (temp - minTemp) / tempRange;
      return size.height - (normalized * size.height).clamp(0.0, size.height);
    }

    double getX(int index, int total) {
      if (total <= 1) return size.width / 2;
      return (index / (total - 1)) * size.width;
    }

    // 1. Draw Target Line (Dashed)
    final targetY = getY(targetTemp);
    final dashPaint = Paint()
      ..color = AppColors.brand500.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double dashWidth = 5;
    double dashSpace = 4;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(startX + dashWidth, targetY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Target Label
    final tp = TextPainter(
      text: TextSpan(
        text: 'Target ${targetTemp.toStringAsFixed(0)}°C',
        style: const TextStyle(fontSize: 10, color: AppColors.brand500, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width, targetY - 14));

    // 2. Draw Area Gradient & Path (Rolling 30-second window)
    final points = history.length > 30 ? history.sublist(history.length - 30) : history;
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final temp = pt.temperature ?? minTemp;
      final x = getX(i, points.length);
      final y = getY(temp);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevPt = points[i - 1];
        final prevX = getX(i - 1, points.length);
        final prevY = getY(prevPt.temperature ?? minTemp);
        final controlX1 = prevX + (x - prevX) / 2;
        final controlX2 = prevX + (x - prevX) / 2;
        path.cubicTo(controlX1, prevY, controlX2, y, x, y);
        fillPath.cubicTo(controlX1, prevY, controlX2, y, x, y);
      }

      if (i == points.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.brand500.withValues(alpha: 0.25),
          AppColors.brand500.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.brand700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // 3. Draw Dots for Data Points
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final temp = pt.temperature ?? minTemp;
      final x = getX(i, points.length);
      final y = getY(temp);

      final dotPaint = Paint()
        ..color = pt.heating ? AppColors.brand500 : AppColors.brand200
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), pt.heating ? 4.0 : 3.0, dotPaint);

      // Pulse ring for latest reading
      if (i == points.length - 1) {
        final pulsePaint = Paint()
          ..color = AppColors.brand700.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(Offset(x, y), 7.0, pulsePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) => true;
}
