import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/iron_device.dart';
import 'ble_json_message_assembler.dart';
import 'ble_transport.dart';
import 'iron_protocol.dart';

class ReactiveBleTransport implements BleTransport {
  ReactiveBleTransport({FlutterReactiveBle? ble})
    : _ble = ble ?? FlutterReactiveBle();
  final FlutterReactiveBle _ble;
  final _states = StreamController<TransportConnectionState>.broadcast();
  final _statuses = StreamController<String>.broadcast();
  final _statusAssembler = BleJsonMessageAssembler();
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _notification;
  String? _deviceId;
  bool _cacheRefreshAttempted = false;
  bool _finishingConnection = false;

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
    _cacheRefreshAttempted = false;
    _states.add(TransportConnectionState.connecting);
    _startConnection(deviceId);
  }

  void _startConnection(String deviceId) {
    final serviceId = Uuid.parse(IronProtocol.serviceUuid);
    _connection = _ble
        .connectToAdvertisingDevice(
          id: deviceId,
          withServices: [serviceId],
          prescanDuration: const Duration(seconds: 5),
          servicesWithCharacteristicsToDiscover: {
            serviceId: [
              Uuid.parse(IronProtocol.commandUuid),
              Uuid.parse(IronProtocol.statusUuid),
            ],
          },
          connectionTimeout: const Duration(seconds: 12),
        )
        .listen(
          (update) {
            if (update.connectionState == DeviceConnectionState.connected &&
                !_finishingConnection) {
              _finishingConnection = true;
              unawaited(_finishConnection(deviceId));
            } else if (update.connectionState ==
                DeviceConnectionState.disconnected) {
              _states.add(TransportConnectionState.disconnected);
            }
          },
          onError: (Object error) {
            _finishingConnection = false;
            _states.add(TransportConnectionState.disconnected);
            _states.addError(error);
          },
        );
  }

  Future<void> _finishConnection(String deviceId) async {
    try {
      try {
        final negotiatedMtu = await _ble.requestMtu(
          deviceId: deviceId,
          mtu: 247,
        );
        debugPrint(
          'Smart Iron BLE negotiated MTU: $negotiatedMtu '
          '(notification payload: ${negotiatedMtu - 3} bytes)',
        );
      } catch (error) {
        // Firmware fragmentation also supports peers that remain at MTU 23.
        debugPrint('Smart Iron BLE MTU request failed; using fragments: $error');
      }

      final missing = await _missingCharacteristics(deviceId);
      if (missing.isNotEmpty) {
        if (!_cacheRefreshAttempted) {
          _cacheRefreshAttempted = true;
          await _ble.clearGattCache(deviceId);
          await _connection?.cancel();
          _connection = null;
          _finishingConnection = false;
          if (_deviceId == deviceId) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            _startConnection(deviceId);
          }
          return;
        }
        throw StateError(
          'The iron is advertising the Smart Iron service, but its GATT '
          'table is missing ${missing.join(' and ')}. Upload the current '
          'firmware to the ESP32, restart it, and reconnect.',
        );
      }

      final characteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse(IronProtocol.serviceUuid),
        characteristicId: Uuid.parse(IronProtocol.statusUuid),
        deviceId: deviceId,
      );
      await _notification?.cancel();
      _statusAssembler.clear();
      _notification = _ble
          .subscribeToCharacteristic(characteristic)
          .listen(
            (bytes) {
              for (final message in _statusAssembler.addFragment(bytes)) {
                _statuses.add(message);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              _statuses.addError('BLE notification failed: $error', stackTrace);
              unawaited(disconnect());
            },
          );
      await write(IronProtocol.status);
      if (_deviceId == deviceId) {
        _states.add(TransportConnectionState.connected);
      }
    } catch (error, stackTrace) {
      _statuses.addError('BLE setup failed: $error', stackTrace);
      await disconnect();
    } finally {
      _finishingConnection = false;
    }
  }

  Future<List<String>> _missingCharacteristics(String deviceId) async {
    await _ble.discoverAllServices(deviceId);
    final services = await _ble.getDiscoveredServices(deviceId);
    final serviceId = Uuid.parse(IronProtocol.serviceUuid);
    final commandId = Uuid.parse(IronProtocol.commandUuid);
    final statusId = Uuid.parse(IronProtocol.statusUuid);
    final service = services.where((item) => item.id == serviceId).firstOrNull;
    if (service == null) return ['Smart Iron service'];

    final characteristicIds = service.characteristics
        .map((item) => item.id)
        .toSet();
    return [
      if (!characteristicIds.contains(commandId)) 'command characteristic',
      if (!characteristicIds.contains(statusId)) 'status characteristic',
    ];
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
    _statusAssembler.clear();
    _finishingConnection = false;
    _states.add(TransportConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _states.close();
    await _statuses.close();
  }
}
