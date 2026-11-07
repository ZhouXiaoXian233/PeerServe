/// 协议层错误码。
///
/// 错误码是稳定的机器可读标识；`message` 只用于开发诊断，不保证稳定。
enum ProtocolErrorCode {
  messageTooLarge('message_too_large'),
  invalidJson('invalid_json'),
  duplicateKey('duplicate_key'),
  unsupportedSchemaVersion('unsupported_schema_version'),
  unknownMessageType('unknown_message_type'),
  missingField('missing_field'),
  unknownField('unknown_field'),
  invalidField('invalid_field'),
  floatNotAllowed('float_not_allowed'),
  integerOutOfRange('integer_out_of_range'),
  stringTooLong('string_too_long'),
  invalidUnicode('invalid_unicode'),
  invalidTimestamp('invalid_timestamp'),
  invalidSignatureEncoding('invalid_signature_encoding'),
  depthExceeded('depth_exceeded'),
  invalidPayload('invalid_payload');

  const ProtocolErrorCode(this.wire);

  /// 稳定的协议错误字符串。
  final String wire;

  @override
  String toString() => wire;
}

/// 所有协议校验失败的统一异常。
class ProtocolException implements Exception {
  const ProtocolException(this.code, this.message, {this.field});

  final ProtocolErrorCode code;
  final String message;

  /// 出错字段的 JSON 路径（例如 `$.payload.title`），可能为空。
  final String? field;

  @override
  String toString() {
    final location = field == null ? '' : ' at $field';
    return 'ProtocolException(${code.wire})$location: $message';
  }
}
