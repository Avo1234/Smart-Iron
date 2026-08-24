import 'package:flutter_test/flutter_test.dart';
import 'package:smart_iron_app/models/iron_status.dart';
import 'package:smart_iron_app/services/iron_protocol.dart';

void main() {
  const valid =
      '{"power":true,"heating":false,"temperature":25.4,"target":140,"preset":2,"handle":true,"countdown":0,"fault":"NONE","temperatureSensor":true,"mpu":true,"message":"Ready"}';
  test('parses complete firmware status', () {
    final status = IronStatus.fromJsonString(valid);
    expect(status.power, isTrue);
    expect(status.temperature, 25.4);
    expect(status.preset, 2);
    expect(status.statusValid, isTrue);
  });
  test('maps protocol sentinels', () {
    final status = IronStatus.fromJsonString(
      valid
          .replaceFirst('25.4', '-999')
          .replaceFirst('"preset":2', '"preset":-1'),
    );
    expect(status.temperature, isNull);
    expect(status.preset, isNull);
    expect(status.statusValid, isFalse);
  });
  test('rejects malformed and missing values', () {
    expect(() => IronStatus.fromJsonString('{}'), throwsFormatException);
    expect(() => IronStatus.fromJsonString('not json'), throwsA(anything));
  });
  test('formats and validates commands', () {
    expect(IronProtocol.power(true), 'POWER:ON');
    expect(IronProtocol.preset(4), 'PRESET:4');
    expect(IronProtocol.target(115), 'TARGET:115');
    expect(() => IronProtocol.target(111), throwsRangeError);
    expect(() => IronProtocol.target(175), throwsRangeError);
  });
}
