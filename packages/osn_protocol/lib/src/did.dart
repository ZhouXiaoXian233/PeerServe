import 'errors.dart';

/// Ed25519 `did:key`（base58btc）的格式检查。
///
/// 这里只检查字符串形状；真正的公钥解码与曲线上验证由 `osn_identity` 完成。
final RegExp didKeyPattern = RegExp(r'^did:key:z[1-9A-HJ-NP-Za-km-z]{46,64}$');

void validateDidKeyId(String value, {required String field}) {
  if (!didKeyPattern.hasMatch(value)) {
    throw ProtocolException(
      ProtocolErrorCode.invalidField,
      '必须是 did:key（Ed25519, base58btc）',
      field: field,
    );
  }
}
