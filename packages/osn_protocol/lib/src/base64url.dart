import 'dart:convert';
import 'dart:typed_data';

import 'errors.dart';

/// 编码为无填充的 base64url（Ed25519 签名与公钥的协议编码）。
String encodeBase64UrlNoPad(List<int> bytes) {
  final encoded = base64Url.encode(bytes);
  return encoded.replaceAll('=', '');
}

/// 解码无填充的 base64url；拒绝填充与非法字符。
Uint8List decodeBase64UrlNoPad(String value, {required String field}) {
  if (value.isEmpty || value.contains('=')) {
    throw ProtocolException(
      ProtocolErrorCode.invalidSignatureEncoding,
      'base64url 必须非空且不带填充',
      field: field,
    );
  }
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
    throw ProtocolException(
      ProtocolErrorCode.invalidSignatureEncoding,
      'base64url 包含非法字符',
      field: field,
    );
  }
  try {
    return base64Url.decode(base64Url.normalize(value));
  } on FormatException {
    throw ProtocolException(
      ProtocolErrorCode.invalidSignatureEncoding,
      'base64url 解码失败',
      field: field,
    );
  }
}
