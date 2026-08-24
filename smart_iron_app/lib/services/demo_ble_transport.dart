import 'dart:async';
import 'dart:convert';

import '../models/iron_device.dart';
import 'ble_transport.dart';

class DemoBleTransport implements BleTransport {
  final _states = StreamController<TransportConnectionState>.broadcast();
  final _statuses = StreamController<String>.broadcast();
  Timer? _timer;
  bool _power = false;
  int _target = 140;
  int _preset = 2;
  double _temperature = 24;

  @override
  Stream<IronDevice> scan() async* {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    yield const IronDevice(
      id: 'demo-smart-iron',
      name: 'SmartIron Demo',
      rssi: -42,
    );
  }

  @override
  Stream<TransportConnectionState> get connectionState => _states.stream;
  @override
  Stream<String> get statusMessages => _statuses.stream;

  @override
  Future<void> connect(String deviceId) async {
    _states.add(TransportConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _states.add(TransportConnectionState.connected);
    _publish('Demo mode — no physical iron is connected');
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_power && _temperature < _target) _temperature += 2.5;
      if (!_power && _temperature > 24) _temperature -= 1;
      _publish('Demo mode');
    });
  }

  @override
  Future<void> write(String command) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (command == 'POWER:ON') _power = true;
    if (command == 'POWER:OFF') _power = false;
    if (command.startsWith('PRESET:')) {
      _preset = int.parse(command.substring(7));
      _target = [110, 125, 140, 155, 170][_preset];
    }
    if (command.startsWith('TARGET:')) {
      _target = int.parse(command.substring(7));
      _preset = -1;
    }
    _publish(
      command == 'PAIRING:CLEAR'
          ? 'Pairings cleared'
          : 'Demo command confirmed',
    );
    if (command == 'PAIRING:CLEAR') await disconnect();
  }

  void _publish(String message) => _statuses.add(
    jsonEncode({
      'power': _power,
      'heating': _power && _temperature < _target,
      'temperature': _temperature,
      'target': _target,
      'preset': _preset,
      'handle': true,
      'countdown': 0,
      'fault': 'NONE',
      'temperatureSensor': true,
      'mpu': true,
      'message': message,
    }),
  );

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _states.add(TransportConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _states.close();
    await _statuses.close();
  }
}
