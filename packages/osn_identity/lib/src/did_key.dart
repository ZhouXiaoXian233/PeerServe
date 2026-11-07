import 'dart:typed_data';

import 'base58.dart';

/// Ed25519 公钥的 multicodec 前缀（varint 0xed 0x01）。
const List<int> ed25519MulticodecPrefix = <int>[0xed, 0x01];

/// Ed25519 公钥字节长度。
const int ed25519PublicKeyLength = 32;

/// 由 32 字节 Ed25519 公钥派生 `did:key`。
String didKeyFromPublicKey(List<int> publicKey) {
  if (publicKey.length != ed25519PublicKeyLength) {
    throw ArgumentError.value(
      publicKey.length,
      'publicKey',
      'Ed25519 公钥必须是 $ed25519PublicKeyLength 字节',
    );
  }
  final multibase = base58Encode(<int>[
    ...ed25519MulticodecPrefix,
    ...publicKey,
  ]);
  return 'did:key:z$multibase';
}

/// 从 `did:key` 解出 32 字节 Ed25519 公钥。
Uint8List publicKeyFromDidKey(String did) {
  const prefix = 'did:key:z';
  if (!did.startsWith(prefix)) {
    throw const FormatException('did:key 必须以 did:key:z 开头');
  }

  final Uint8List decoded;
  try {
    decoded = base58Decode(did.substring(prefix.length));
  } on FormatException catch (error) {
    throw FormatException('did:key 的 base58btc 部分非法: ${error.message}');
  }

  if (decoded.length !=
      ed25519MulticodecPrefix.length + ed25519PublicKeyLength) {
    throw FormatException('did:key 解码后应为 34 字节，实际 ${decoded.length} 字节');
  }
  for (var index = 0; index < ed25519MulticodecPrefix.length; index++) {
    if (decoded[index] != ed25519MulticodecPrefix[index]) {
      throw const FormatException('did:key 不是 Ed25519 公钥（multicodec 不匹配）');
    }
  }

  return Uint8List.fromList(decoded.sublist(ed25519MulticodecPrefix.length));
}
