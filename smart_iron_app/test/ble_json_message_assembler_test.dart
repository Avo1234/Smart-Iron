import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_iron_app/services/ble_json_message_assembler.dart';

void main() {
  const status =
      '{"power":false,"heating":false,"temperature":25.0,'
      '"message":"Touch handle"}';

  test('does not emit an incomplete BLE fragment', () {
    final assembler = BleJsonMessageAssembler();

    expect(assembler.addFragment(utf8.encode('{"power":false')), isEmpty);
  });

  test('reassembles a status split into 20-byte notifications', () {
    final assembler = BleJsonMessageAssembler();
    final bytes = utf8.encode(status);
    final messages = <String>[];

    for (var offset = 0; offset < bytes.length; offset += 20) {
      final end = (offset + 20).clamp(0, bytes.length);
      messages.addAll(assembler.addFragment(bytes.sublist(offset, end)));
    }

    expect(messages, [status]);
  });

  test('emits repeated complete statuses independently', () {
    final assembler = BleJsonMessageAssembler();

    expect(assembler.addFragment(utf8.encode('$status$status')), [status, status]);
  });

  test('recovers when a new status follows a lost fragment', () {
    final assembler = BleJsonMessageAssembler();
    assembler.addFragment(utf8.encode('{"power":fal'));

    expect(assembler.addFragment(utf8.encode(status)), [status]);
  });
}
