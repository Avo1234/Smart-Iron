import 'dart:async';
import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/iron_device.dart';
import 'ble_transport.dart';
import 'iron_protocol.dart';

class ReactiveBleTransport implements BleTransport {
  ReactiveBleTransport({FlutterReactiveBle? ble})
    : _ble = ble ?? FlutterReactiveBle();
  final FlutterReactiveBle _ble;
  final _states = StreamController<TransportConnectionState>.broadcast();
  final _statuses = StreamController<String>.broadcast();
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _notification;
  String? _deviceId;

  @override
  Stream<IronDevice> scan() => _ble
      .scanForDevices(withServices: [Uuid.parse(IronProtocol.serviceUuid)])
      .map(
        (device) => IronDevice(
          id: device.id,
          name: device.name.isEmpty ? 'Smart Iron' : device.name,
          rssi: device.rssi,
        ),
      );

  @override
  Stream<TransportConnectionState> get connectionState => _states.stream;
  @override
  Stream<String> get statusMessages => _statuses.stream;

  @override
  Future<void> connect(String deviceId) async {
    await disconnect();
    _deviceId = deviceId;
    _states.add(TransportConnectionState.connecting);
    _connection = _ble
        .connectToDevice(id: deviceId)
        .listen(
          (update) async {
            if (update.connectionState == DeviceConnectionState.connected) {
              _states.add(TransportConnectionState.connected);
              final characteristic = QualifiedCharacteristic(
                serviceId: Uuid.parse(IronProtocol.serviceUuid),
                characteristicId: Uuid.parse(IronProtocol.statusUuid),
                deviceId: deviceId,
              );
              await _notification?.cancel();
              _notification = _ble
                  .subscribeToCharacteristic(characteristic)
                  .listen(
                    (bytes) => _statuses.add(utf8.decode(bytes)),
                    onError: _statuses.addError,
                  );
              await write(IronProtocol.status);
            } else if (update.connectionState ==
                DeviceConnectionState.disconnected) {
              _states.add(TransportConnectionState.disconnected);
            }
          },
          onError: (Object error) {
            _states.add(TransportConnectionState.disconnected);
            _states.addError(error);
          },
        );
  }

  @override
  Future<void> write(String command) async {
    final deviceId = _deviceId;
    if (deviceId == null) throw StateError('No iron connected');
    await _ble.writeCharacteristicWithResponse(
      QualifiedCharacteristic(
        serviceId: Uuid.parse(IronProtocol.serviceUuid),
        characteristicId: Uuid.parse(IronProtocol.commandUuid),
        deviceId: deviceId,
      ),
      value: utf8.encode(command),
    );
  }

  @override
  Future<void> disconnect() async {
    await _notification?.cancel();
    await _connection?.cancel();
    _notification = null;
    _connection = null;
    _deviceId = null;
    _states.add(TransportConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _states.close();
    await _statuses.close();
  }
}
