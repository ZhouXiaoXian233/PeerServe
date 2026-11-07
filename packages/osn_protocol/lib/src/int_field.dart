import 'errors.dart';
import 'json_value.dart';

/// 校验协议字段的整数值。
///
/// Web（dart2js）里 `1` 可能同时满足 `is int` 与 `is double`，所以必须先检查
/// `is int`；只有真正的非整数才按浮点拒绝。这也避免把 `schema_version: 1`
/// 误判为浮点。
int requireProtocolInt(Object? value, {required String field}) {
  if (value is int) {
    if (value < -maxSafeInteger || value > maxSafeInteger) {
      throw ProtocolException(
        ProtocolErrorCode.integerOutOfRange,
        '整数超出安全范围 [-$maxSafeInteger, $maxSafeInteger]',
        field: field,
      );
    }
    return value;
  }
  if (value is double) {
    if (!value.isFinite || value != value.truncateToDouble()) {
      throw ProtocolException(
        ProtocolErrorCode.floatNotAllowed,
        '协议层禁止浮点数',
        field: field,
      );
    }
    final integer = value.toInt();
    if (integer < -maxSafeInteger || integer > maxSafeInteger) {
      throw ProtocolException(
        ProtocolErrorCode.integerOutOfRange,
        '整数超出安全范围 [-$maxSafeInteger, $maxSafeInteger]',
        field: field,
      );
    }
    return integer;
  }
  throw ProtocolException(
    ProtocolErrorCode.invalidField,
    '必须是整数',
    field: field,
  );
}
