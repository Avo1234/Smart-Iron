class IronProtocol {
  static const serviceUuid = '7a1d0001-5a7b-4c6d-8e9f-102030405060';
  static const commandUuid = '7a1d0002-5a7b-4c6d-8e9f-102030405060';
  static const statusUuid = '7a1d0003-5a7b-4c6d-8e9f-102030405060';
  static const minTarget = 110;
  static const maxTarget = 170;
  static const targetStep = 5;

  static String power(bool enabled) => 'POWER:${enabled ? 'ON' : 'OFF'}';
  static String preset(int index) {
    if (index < 0 || index > 4) throw RangeError.range(index, 0, 4);
    return 'PRESET:$index';
  }

  static String target(int value) {
    if (value < minTarget || value > maxTarget || value % targetStep != 0) {
      throw RangeError('Target must be 110-170 in 5°C steps');
    }
    return 'TARGET:$value';
  }

  static const status = 'STATUS?';
  static const clearPairings = 'PAIRING:CLEAR';
}
