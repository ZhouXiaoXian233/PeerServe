import 'dart:typed_data';

const String _alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

final Map<int, int> _alphabetIndexes = <int, int>{
  for (var index = 0; index < _alphabet.length; index++)
    _alphabet.codeUnitAt(index): index,
};

/// Base58btc 编码（比特币字母表，无校验和）。
String base58Encode(List<int> bytes) {
  if (bytes.isEmpty) {
    return '';
  }

  var value = BigInt.zero;
  var leadingZeros = 0;
  var sawNonZero = false;
  for (final byte in bytes) {
    if (byte < 0 || byte > 255) {
      throw ArgumentError.value(byte, 'bytes', '必须是 0..255 的字节');
    }
    if (byte == 0 && !sawNonZero) {
      leadingZeros++;
    } else {
      sawNonZero = true;
    }
    value = (value << 8) | BigInt.from(byte);
  }

  final encoded = StringBuffer();
  while (value > BigInt.zero) {
    final remainder = (value % BigInt.from(58)).toInt();
    encoded.write(_alphabet[remainder]);
    value = value ~/ BigInt.from(58);
  }

  final reversed = encoded.toString().split('').reversed.join();
  return '${List<String>.filled(leadingZeros, '1').join()}$reversed';
}

/// Base58btc 解码。
Uint8List base58Decode(String text) {
  if (text.isEmpty) {
    return Uint8List(0);
  }

  var value = BigInt.zero;
  var leadingOnes = 0;
  var sawNonOne = false;
  for (final codeUnit in text.codeUnits) {
    final digit = _alphabetIndexes[codeUnit];
    if (digit == null) {
      throw FormatException('Base58 包含非法字符: ${String.fromCharCode(codeUnit)}');
    }
    if (codeUnit == 0x31 && !sawNonOne) {
      leadingOnes++;
    } else {
      sawNonOne = true;
    }
    value = value * BigInt.from(58) + BigInt.from(digit);
  }

  final bytes = <int>[];
  while (value > BigInt.zero) {
    bytes.add((value % BigInt.from(256)).toInt());
    value = value ~/ BigInt.from(256);
  }

  return Uint8List.fromList(<int>[
    ...List<int>.filled(leadingOnes, 0),
    ...bytes.reversed,
  ]);
}
