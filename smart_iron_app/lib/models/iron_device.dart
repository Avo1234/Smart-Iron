class IronDevice {
  const IronDevice({required this.id, required this.name, this.rssi = 0});
  final String id;
  final String name;
  final int rssi;
}
