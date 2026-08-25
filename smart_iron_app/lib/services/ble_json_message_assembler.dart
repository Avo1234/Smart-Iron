import 'dart:convert';

/// Reassembles the flat JSON objects sent by the Smart Iron status
/// characteristic. BLE notification boundaries are not message boundaries.
class BleJsonMessageAssembler {
  static const int _maximumMessageBytes = 512;

  final List<int> _buffer = [];
  bool _insideString = false;
  bool _escaping = false;

  List<String> addFragment(List<int> fragment) {
    final messages = <String>[];
    for (final byte in fragment) {
      if (_buffer.isEmpty) {
        if (byte == _openBrace) _buffer.add(byte);
        continue;
      }

      // Status objects are intentionally flat. A new unquoted opening brace
      // means a fragment was lost, so abandon the incomplete previous frame.
      if (!_insideString && byte == _openBrace) {
        _reset();
        _buffer.add(byte);
        continue;
      }

      _buffer.add(byte);
      if (_insideString) {
        if (_escaping) {
          _escaping = false;
        } else if (byte == _backslash) {
          _escaping = true;
        } else if (byte == _quote) {
          _insideString = false;
        }
      } else if (byte == _quote) {
        _insideString = true;
      } else if (byte == _closeBrace) {
        messages.add(utf8.decode(_buffer));
        _reset();
      }

      if (_buffer.length > _maximumMessageBytes) _reset();
    }
    return messages;
  }

  void clear() => _reset();

  void _reset() {
    _buffer.clear();
    _insideString = false;
    _escaping = false;
  }

  static const int _openBrace = 0x7b;
  static const int _closeBrace = 0x7d;
  static const int _quote = 0x22;
  static const int _backslash = 0x5c;
}
