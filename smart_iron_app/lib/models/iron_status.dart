import 'dart:convert';

class IronStatus {
  const IronStatus({
    required this.power,
    required this.heating,
    required this.temperature,
    required this.target,
    required this.preset,
    required this.handle,
    required this.countdown,
    required this.fault,
    required this.temperatureSensorHealthy,
    required this.mpuHealthy,
    required this.message,
  });

  final bool power;
  final bool heating;
  final double? temperature;
  final int target;
  final int? preset;
  final bool handle;
  final int countdown;
  final String fault;
  final bool temperatureSensorHealthy;
  final bool mpuHealthy;
  final String message;

  bool get hasFault => fault.toUpperCase() != 'NONE';
  bool get statusValid =>
      temperatureSensorHealthy && mpuHealthy && temperature != null;

  factory IronStatus.fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Status must be a JSON object');
    }
    T requiredValue<T>(String key) {
      final value = decoded[key];
      if (value is! T) throw FormatException('Missing or invalid $key');
      return value;
    }

    final rawTemperature = requiredValue<num>('temperature').toDouble();
    final rawPreset = requiredValue<num>('preset').toInt();
    final target = requiredValue<num>('target').toInt();
    final countdown = requiredValue<num>('countdown').toInt();
    if (target < 110 || target > 170 || target % 5 != 0 || countdown < 0) {
      throw const FormatException('Status values outside protocol range');
    }
    return IronStatus(
      power: requiredValue<bool>('power'),
      heating: requiredValue<bool>('heating'),
      temperature: rawTemperature == -999 ? null : rawTemperature,
      target: target,
      preset: rawPreset == -1 ? null : rawPreset,
      handle: requiredValue<bool>('handle'),
      countdown: countdown,
      fault: requiredValue<String>('fault'),
      temperatureSensorHealthy: requiredValue<bool>('temperatureSensor'),
      mpuHealthy: requiredValue<bool>('mpu'),
      message: requiredValue<String>('message'),
    );
  }
}
