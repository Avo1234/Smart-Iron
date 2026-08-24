import 'package:flutter_test/flutter_test.dart';
import 'package:smart_iron_app/models/iron_status.dart';
import 'package:smart_iron_app/services/alert_service.dart';

class FakeSink implements AlertSink {
  final calls = <String>[];
  @override
  Future<void> show(String key, String title, String body) async =>
      calls.add(key);
}

IronStatus warning({int countdown = 10}) => IronStatus(
  power: true,
  heating: true,
  temperature: 130,
  target: 140,
  preset: 2,
  handle: false,
  countdown: countdown,
  fault: 'NONE',
  temperatureSensorHealthy: true,
  mpuHealthy: true,
  message: 'warning',
);
void main() {
  test('deduplicates an active safety transition', () async {
    final sink = FakeSink();
    final alerts = AlertService(sink);
    await alerts.evaluate(null, warning(), enabled: true);
    await alerts.evaluate(warning(), warning(countdown: 9), enabled: true);
    expect(sink.calls, ['handle']);
  });
}
