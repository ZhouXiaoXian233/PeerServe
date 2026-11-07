import 'dart:typed_data';

import 'package:osn_identity/osn_identity.dart';
import 'package:test/test.dart';

void main() {
  group('base58btc', () {
    test('空输入与全零前缀', () {
      expect(base58Encode(<int>[]), '');
      expect(base58Encode(<int>[0]), '1');
      expect(base58Encode(<int>[0, 0]), '11');
      expect(base58Encode(<int>[0, 1]), '12');
      expect(base58Decode('11'), <int>[0, 0]);
    });

    test('字节往返', () {
      final bytes = Uint8List.fromList(
        List<int>.generate(256, (index) => index),
      );
      expect(base58Decode(base58Encode(bytes)), bytes);
    });

    test('拒绝非法字符', () {
      expect(() => base58Decode('0OIl'), throwsFormatException);
    });
  });
}
