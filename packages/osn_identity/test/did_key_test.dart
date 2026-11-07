import 'dart:typed_data';

import 'package:osn_identity/osn_identity.dart';
import 'package:test/test.dart';

Uint8List hexToBytes(String hex) {
  if (hex.length.isOdd) {
    throw ArgumentError('hex 长度必须是偶数');
  }
  return Uint8List.fromList(<int>[
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ]);
}

void main() {
  group('did:key', () {
    test('RFC 8032 公钥派生固定 DID', () {
      final publicKey = hexToBytes(
        'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
      );
      expect(
        didKeyFromPublicKey(publicKey),
        'did:key:z6MktwupdmLXVVqTzCw4i46r4uGyosGXRnR3XjN4Zq7oMMsw',
      );
    });

    test('解析 did:key 规范中的公开向量', () {
      const did = 'did:key:z6MkhaXgBZDvotDkL5257faiztiGiC2QtKLGpbnnEGta2doK';
      final publicKey = publicKeyFromDidKey(did);
      expect(
        publicKey,
        hexToBytes(
          '2e6fcce36701dc791488e0d0b1745cc1e33a4c1c9fcc41c63bd343dbbe0970e6',
        ),
      );
      expect(didKeyFromPublicKey(publicKey), did);
    });

    test('拒绝错误前缀、长度与 multicodec', () {
      expect(
        () => publicKeyFromDidKey('did:web:example.com'),
        throwsFormatException,
      );
      expect(() => publicKeyFromDidKey('did:key:z123'), throwsFormatException);
      final wrongMulticodec = base58Encode(<int>[
        0x00,
        0x01,
        ...List<int>.filled(32, 1),
      ]);
      expect(
        () => publicKeyFromDidKey('did:key:z$wrongMulticodec'),
        throwsFormatException,
      );
    });
  });
}
