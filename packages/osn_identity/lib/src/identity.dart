import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:osn_protocol/osn_protocol.dart';

import 'did_key.dart';

final DartEd25519 _ed25519 = DartEd25519();

/// 本地身份：持有 Ed25519 私钥，并派生 `did:key` 标识。
///
/// 私钥只存在于此对象内部，不提供 getter，也不会被写入日志或 UI。
/// 持久化与加密备份属于 Phase 0.3 / Phase 1，本阶段身份只在内存中。
class PeerIdentity {
  PeerIdentity._(this._keyPair, this._publicKey, this.identityId);

  final SimpleKeyPair _keyPair;
  final Uint8List _publicKey;

  /// `did:key:z...` 身份标识。
  final String identityId;

  /// 32 字节 Ed25519 公钥副本。
  Uint8List get publicKey => Uint8List.fromList(_publicKey);

  /// 生成一个新的随机身份。
  static Future<PeerIdentity> generate() {
    final random = Random.secure();
    final seed = Uint8List(ed25519PublicKeyLength);
    for (var index = 0; index < seed.length; index++) {
      seed[index] = random.nextInt(256);
    }
    return fromSeed(seed);
  }

  /// 从 32 字节种子派生身份；相同种子必须得到相同身份。
  static Future<PeerIdentity> fromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw ArgumentError.value(seed.length, 'seed', 'Ed25519 种子必须是 32 字节');
    }
    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = Uint8List.fromList(publicKey.bytes);
    return PeerIdentity._(
      keyPair,
      publicKeyBytes,
      didKeyFromPublicKey(publicKeyBytes),
    );
  }

  /// 对任意字节签名。
  Future<Uint8List> sign(List<int> message) async {
    final signature = await _ed25519.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// 用本身份的公钥验签。
  Future<bool> verify(List<int> message, List<int> signature) async {
    if (signature.length != 64) {
      return false;
    }
    return _verifyWithPublicKey(message, signature, _publicKey);
  }

  /// 对信封签名。`sent_at` 默认取当前 UTC 毫秒时间。
  Future<Envelope> signEnvelope({
    required MessageType type,
    required Map<String, Object?> payload,
    String? sentAt,
  }) async {
    final effectiveSentAt = sentAt ?? nowUtcTimestamp();
    requireUtcTimestamp(effectiveSentAt, field: r'$.sent_at');

    final unsigned = Envelope(
      type: type,
      payload: Map<String, Object?>.from(payload),
      senderId: identityId,
      sentAt: effectiveSentAt,
      signature: _placeholderSignature,
    );
    final signature = await sign(unsigned.signingBytes());
    return unsigned.withSignature(encodeBase64UrlNoPad(signature));
  }
}

/// 用信封中 `sender_id` 对应的公钥验证签名。
///
/// 不依赖本地身份；任何收到信封的节点都可以独立验证。
Future<bool> verifyEnvelopeSignature(Envelope envelope) async {
  final Uint8List publicKey;
  try {
    publicKey = publicKeyFromDidKey(envelope.senderId);
  } on FormatException {
    return false;
  }

  final Uint8List signatureBytes;
  try {
    signatureBytes = decodeBase64UrlNoPad(
      envelope.signature,
      field: r'$.signature',
    );
  } on ProtocolException {
    return false;
  }
  if (signatureBytes.length != 64) {
    return false;
  }

  final Uint8List signedBytes;
  try {
    signedBytes = envelope.signingBytes();
  } on ProtocolException {
    return false;
  }

  return _verifyWithPublicKey(signedBytes, signatureBytes, publicKey);
}

Future<bool> _verifyWithPublicKey(
  List<int> message,
  List<int> signature,
  List<int> publicKey,
) async {
  final publicKeyObject = SimplePublicKey(publicKey, type: KeyPairType.ed25519);
  final signatureObject = Signature(signature, publicKey: publicKeyObject);
  try {
    return await _ed25519.verify(message, signature: signatureObject);
  } catch (_) {
    // 非法公钥点、截断签名等输入一律按验证失败处理，不向调用方抛出底层异常。
    return false;
  }
}

final String _placeholderSignature = encodeBase64UrlNoPad(Uint8List(64));
