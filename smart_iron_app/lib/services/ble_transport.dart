import '../models/iron_device.dart';

enum TransportConnectionState { disconnected, connecting, connected }

abstract class BleTransport {
  Stream<IronDevice> scan();
  Stream<TransportConnectionState> get connectionState;
  Stream<String> get statusMessages;
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<void> write(String command);
  Future<void> dispose();
}
