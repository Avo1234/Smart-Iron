import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/iron_device.dart';
import '../models/iron_status.dart';
import '../services/alert_service.dart';
import '../services/ble_transport.dart';
import '../services/iron_protocol.dart';
import '../services/settings_service.dart';

class IronController extends ChangeNotifier {
  IronController(
    this._transport, {
    required this.settings,
    required this.alerts,
  }) {
    _bindTransport();
  }
  BleTransport _transport;
  final SettingsService settings;
  final AlertService alerts;
  StreamSubscription? _connectionSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _scanSub;
  Timer? _pendingTimer;
  TransportConnectionState connection = TransportConnectionState.disconnected;
  IronStatus? status;
  final List<IronDevice> devices = [];
  bool scanning = false;
  bool demoMode = false;
  bool alertsEnabled = true;
  String? pendingCommand;
  String? error;
  String? rememberedDeviceId;

  bool get connected => connection == TransportConnectionState.connected;
  bool get controlsEnabled =>
      connected && pendingCommand == null && status?.statusValid == true;

  Future<void> initialize() async {
    alertsEnabled = await settings.alertsEnabled();
    rememberedDeviceId = await settings.rememberedDevice();
    notifyListeners();
    if (rememberedDeviceId != null) await connect(rememberedDeviceId!);
  }

  void _bindTransport() {
    _connectionSub = _transport.connectionState.listen(
      (state) {
        if (state == TransportConnectionState.disconnected &&
            status?.power == true) {
          alerts.disconnectedWhileActive(enabled: alertsEnabled);
        }
        connection = state;
        if (state == TransportConnectionState.disconnected) {
          _clearPending('Connection lost');
        }
        notifyListeners();
      },
      onError: (Object value) {
        error = '$value';
        notifyListeners();
      },
    );
    _statusSub = _transport.statusMessages.listen(
      (value) {
        try {
          final next = IronStatus.fromJsonString(value);
          alerts.evaluate(status, next, enabled: alertsEnabled);
          status = next;
          error = null;
          _confirmPending(next);
        } catch (e) {
          error = 'Invalid status from iron: $e';
        }
        notifyListeners();
      },
      onError: (Object value) {
        error = '$value';
        notifyListeners();
      },
    );
  }

  Future<void> startScan() async {
    devices.clear();
    scanning = true;
    error = null;
    notifyListeners();
    await _scanSub?.cancel();
    _scanSub = _transport.scan().listen(
      (device) {
        final index = devices.indexWhere((item) => item.id == device.id);
        if (index < 0) {
          devices.add(device);
        } else {
          devices[index] = device;
        }
        notifyListeners();
      },
      onError: (Object value) {
        error = '$value';
        scanning = false;
        notifyListeners();
      },
    );
    Future<void>.delayed(const Duration(seconds: 8), () {
      scanning = false;
      _scanSub?.cancel();
      notifyListeners();
    });
  }

  Future<void> connect(String id) async {
    error = null;
    try {
      await _transport.connect(id);
      rememberedDeviceId = id;
      await settings.rememberDevice(id);
    } catch (e) {
      error = 'Could not connect: $e';
    }
    notifyListeners();
  }

  Future<void> useDemo(BleTransport demo) async {
    await _connectionSub?.cancel();
    await _statusSub?.cancel();
    await _transport.dispose();
    _transport = demo;
    demoMode = true;
    _bindTransport();
    await connect('demo-smart-iron');
  }

  Future<void> send(String command) async {
    if (!connected || pendingCommand != null) return;
    pendingCommand = command;
    error = null;
    notifyListeners();
    _pendingTimer = Timer(
      const Duration(seconds: 5),
      () => _clearPending('The iron did not confirm the command.'),
    );
    try {
      await _transport.write(command);
    } catch (e) {
      _clearPending('Command failed: $e');
    }
  }

  void _confirmPending(IronStatus next) {
    final command = pendingCommand;
    if (command == null) return;
    final confirmed =
        command == IronProtocol.status ||
        (command == 'POWER:ON' && next.power) ||
        (command == 'POWER:OFF' && !next.power) ||
        (command.startsWith('TARGET:') &&
            next.target == int.parse(command.substring(7))) ||
        (command.startsWith('PRESET:') &&
            next.preset == int.parse(command.substring(7))) ||
        command == IronProtocol.clearPairings;
    if (confirmed) {
      _clearPending(null);
    } else if (next.message.toLowerCase().contains('reject') ||
        next.message.toLowerCase().contains('blocked')) {
      _clearPending(next.message);
    }
  }

  void _clearPending(String? message) {
    _pendingTimer?.cancel();
    pendingCommand = null;
    if (message != null) error = message;
    notifyListeners();
  }

  Future<void> disconnect() => _transport.disconnect();
  Future<void> forget() async {
    await disconnect();
    await settings.forgetDevice();
    rememberedDeviceId = null;
    status = null;
    notifyListeners();
  }

  Future<void> clearPairings() async {
    await send(IronProtocol.clearPairings);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await forget();
  }

  Future<void> setAlerts(bool enabled) async {
    alertsEnabled = enabled;
    await settings.setAlertsEnabled(enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _statusSub?.cancel();
    _transport.dispose();
    super.dispose();
  }
}
